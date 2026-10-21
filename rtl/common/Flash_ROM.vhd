--
-- Flash_ROM.vhd
-- read the game ROMs from the FPGA configuration flash (EPCS16) instead of the SD card
-- fallback for BallyFA, started when SD_Card ends in error (o_no_card)
-- bontango 10.2026
--
-- v01 BallyFA version, derived from WillFA7 Flash_ROM.vhd v02:
--     8 KByte per game (the same image as an SD card slot), 13 bit ROM address,
--     cpu_reset_h active high like SD_Card of BallyFA, generic Slot_Count.
--
-- Flash layout (written by scripts/make_flash_hex.ps1 into a local .jic, see
-- bally_roms.cof of the variant):
--     0x000000 - 0x07FFFF   bitstream plus reserve
--     Base_Addr + n * Slot_Bytes
--                           game n, 8 KByte, byte for byte the SD card slot n
--                           (sector 660 + n * 16). Slots 0 .. Slot_Count - 1.
--
-- No CRC. The flash has no contacts and no file system, and the data is verified by
-- the programmer when it is written. What is left is a check against an EMPTY flash
-- (the released .jic carries no ROMs, erased = FF): the 6800 reset vector of the game,
-- image offset 1FFEh/1FFFh (FFFEh/FFFFh in the U2 mirror), must not read FFFF.
-- Otherwise error code 8 and the CPU is not released. A selection at or above
-- Slot_Count gets the same error without reading - the address would run past the end
-- of the flash and wrap into the bitstream.
--
-- Same output side as SD_Card (address, data, wr_rom, cpu_reset_h, error LED), so the
-- core only has to switch between the two.
--
-- SPI mode 0, READ (03h) with a 24 bit address, then one continuous stream. Own small
-- shifter on purpose - SPI_Master.vhd is shared with SD_Card and EEprom.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

	entity Flash_ROM is
		generic (
			Read_Bytes : integer := 8192;
			-- where game 0 starts in the flash, how far apart the games are, how many fit
			Base_Addr  : integer := 16#080000#;
			Slot_Bytes : integer := 8192;
			Slot_Count : integer := 192;
			-- SPI clock half period in i_Clk cycles. 2 at 50 MHz = 12.5 MHz, the
			-- EPCS16 allows 20 MHz for READ (03h).
			Half_Period : integer := 2
		);
		port(
		i_Clk		: in std_logic;
		i_Rst_L	: in std_logic;     -- '0' holds the loader, '1' starts it
		-- configuration flash, dual purpose pins of the FPGA
		o_Flash_Clk  : out std_logic;   -- DCLK
		o_Flash_CS_n : out std_logic;   -- nCSO
		o_Flash_MOSI : out std_logic;   -- ASDO, data into the flash
		i_Flash_MISO : in std_logic;    -- DATA0, data out of the flash
		-- selection, same as at SD_Card
		selection : in std_logic_vector(7 downto 0);
		-- rom write port, same meaning as at SD_Card
		address_rom	: buffer std_logic_vector(12 downto 0);
		data_rom		: buffer std_logic_vector(7 downto 0);
		wr_rom		: buffer std_logic;
		-- start CPU, active high like SD_Card
		cpu_reset_h : out std_logic;
		-- feedback
		Flash_error : out std_logic;    -- active low, blinks error code 8
		flash_empty : out std_logic     -- '1' = slot empty or beyond Slot_Count
		);
    end Flash_ROM;

   architecture Behavioral of Flash_ROM is
		type STATE_T is ( start, bit_low, bit_high, write_byte, inc_addr, check_vector,
								all_done, error );
		signal state : STATE_T;

		-- error code of this loader
		constant ERR_CODE : integer := 8;

		-- image offsets of the 6800 reset vector (FFFEh/FFFFh)
		constant VEC_HI : integer := 16#1FFE#;
		constant VEC_LO : integer := 16#1FFF#;

		signal tx_sr    : std_logic_vector(31 downto 0); -- command and address
		signal rx_sr    : std_logic_vector(7 downto 0);
		signal bit_cnt  : integer range 0 to 31;
		signal in_cmd   : std_logic;                     -- '1' while the 32 command bits go out
		signal div      : integer range 0 to Half_Period - 1;
		signal vec_ok   : std_logic;                     -- a reset vector byte was not FF
		-- blinking in 250 ms ticks: one counter and one comparator
		constant TICK_CYCLES : integer := 12500000;      -- 250 ms @ 50 MHz
		signal counter  : integer range 0 to TICK_CYCLES - 1;
		signal ticks    : integer range 0 to 7;
		signal blink_remaining : integer range 0 to 15;
	begin

		-- The byte goes to the ROM straight out of the shift register: it does not move
		-- between the last bit and wr_rom, the next bit only starts after inc_addr.
		data_rom <= rx_sr;

		Flash: process (i_Clk)
		begin
		if rising_edge(i_Clk) then
			if i_Rst_L = '0' then
				o_Flash_Clk <= '0';
				o_Flash_CS_n <= '1';
				o_Flash_MOSI <= '0';
				cpu_reset_h <= '1';
				wr_rom <= '0';
				address_rom <= (others => '0');
				Flash_error <= '1'; -- active low
				flash_empty <= '0';
				vec_ok <= '0';
				div <= 0;
				bit_cnt <= 0;
				in_cmd <= '0';
				counter <= 0;
				ticks <= 0;
				blink_remaining <= 0;
				state <= start;
			else
				case state is
				when start =>
					if unsigned(selection) >= to_unsigned(Slot_Count, selection'length + 1) then
						-- not in the flash, see header
						flash_empty <= '1';
						blink_remaining <= ERR_CODE;
						state <= error;
					else
						-- READ (03h) plus 24 bit address of the slot
						tx_sr <= x"03" & std_logic_vector( to_unsigned(Base_Addr, 24)
								 + unsigned(selection) * to_unsigned(Slot_Bytes, 16) );
						o_Flash_CS_n <= '0';
						bit_cnt <= 31;
						in_cmd <= '1';
						div <= 0;
						state <= bit_low;
					end if;

				-- one SPI bit: clock low half, then clock high half. The flash takes
				-- MOSI on the rising edge and shifts its data out on the falling one,
				-- so MISO is sampled together with the rising edge.
				when bit_low =>
					o_Flash_MOSI <= tx_sr(31);
					if div = Half_Period - 1 then
						div <= 0;
						o_Flash_Clk <= '1';
						rx_sr <= rx_sr(6 downto 0) & i_Flash_MISO;
						state <= bit_high;
					else
						div <= div + 1;
					end if;

				when bit_high =>
					if div = Half_Period - 1 then
						div <= 0;
						o_Flash_Clk <= '0';
						tx_sr <= tx_sr(30 downto 0) & '0';
						if bit_cnt = 0 then
							if in_cmd = '1' then
								-- command and address are out, data follows
								in_cmd <= '0';
								bit_cnt <= 7;
								state <= bit_low;
							else
								state <= write_byte;
							end if;
						else
							bit_cnt <= bit_cnt - 1;
							state <= bit_low;
						end if;
					else
						div <= div + 1;
					end if;

				-- address and data are stable here, one clock of wr_rom like SD_Card.
				-- The SPI clock just pauses meanwhile.
				when write_byte =>
					wr_rom <= '1';
					if ( unsigned(address_rom) = to_unsigned(VEC_HI, address_rom'length)
					  or unsigned(address_rom) = to_unsigned(VEC_LO, address_rom'length) )
					  and data_rom /= x"FF" then
						vec_ok <= '1';
					end if;
					state <= inc_addr;

				when inc_addr =>
					wr_rom <= '0';
					if unsigned(address_rom) = to_unsigned(Read_Bytes - 1, address_rom'length) then
						o_Flash_CS_n <= '1';
						state <= check_vector;
					else
						address_rom <= std_logic_vector(unsigned(address_rom) + 1);
						bit_cnt <= 7;
						state <= bit_low;
					end if;

				when check_vector =>
					counter <= 0;
					ticks <= 0;
					if vec_ok = '1' then
						state <= all_done;
					else
						-- empty flash: running FF would be worse than showing the error
						flash_empty <= '1';
						blink_remaining <= ERR_CODE;
						state <= error;
					end if;

				when all_done =>
					-- start the CPU right away, as SD_Card does after its last sector
					cpu_reset_h <= '0';
					Flash_error <= '1'; --active low

				when error =>
					-- Blink ERR_CODE times (LED active low: '0' = on), then 2 s gap,
					-- repeat forever. Per blink: 250 ms ON, 250 ms OFF.
					if blink_remaining /= 0 and ticks = 0 then
						Flash_error <= '0';
					else
						Flash_error <= '1';
					end if;
					if counter < TICK_CYCLES - 1 then
						counter <= counter + 1;
					else
						counter <= 0;
						if blink_remaining = 0 then
							-- gap, eight ticks
							if ticks = 7 then
								ticks <= 0;
								blink_remaining <= ERR_CODE;
							else
								ticks <= ticks + 1;
							end if;
						else
							-- one blink, tick 0 on, tick 1 off
							if ticks = 1 then
								ticks <= 0;
								blink_remaining <= blink_remaining - 1;
							else
								ticks <= ticks + 1;
							end if;
						end if;
					end if;

				end case;
			end if; --rst
		end if; --rising edge
		end process;

    end Behavioral;
