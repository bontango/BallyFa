-- Original file is copyright by Grant Searle 2014
-- Grant Searle's web site http://searle.hostei.com/grant/    
-- Grant Searle's "multicomp" page at http://searle.hostei.com/grant/Multicomp/index.html
--
-- Changes to this code by Doug Gilliland 2020
-- https://github.com/douggilliland/MultiComp/tree/master/MultiComp_On_EP2C5/M6800_MIKBUG_ExtSRAM
--
--
-- 'BallyFa' a Bally MPU on a low cost FPGA
-- Ralf Thelen 'bontango' 04.2020
-- www.lisy.dev
--
--
-- 06.2020
-- version 0.3 Displays
-- version 0.4 4K roms only
-- version 0.5 Solenoids/Sound & Switches
-- Version 0.51 display change (buffer) plus zero_cross fake via dipS1
-- Version 0.6 slow fast clock domain D-Flip-Flops added (to get rid of flickering lamps)
-- Version 0.7 cleanup, removing unused ports
-- Version 0.8 sync display refresh timer with zero cross interrupt
-- Version 0.9 switch Matrix inputs stabilized
-- Version 0.91 LED blinking when zero cross is present
-- Version 0.92 new 5101 ram version (EEprom buffered), zero cross indication stady
-- Version 0.93 NMI input stabilized
-- Version 0.94 NMI fix to '0'
-- Version 0.95 SPI Master 'optimized' saves 4469 - 4380 = 89 logic elements,
				--	 trigger for eeprom write now flipper disable, coin lockout, test switch and dip 4
-- Version 0.96 U2 & U6 now internally are RAM, in order to be able to write content into from SD card
					--first version of SD card read
					--debug is now 7 downto 0
					--U2 & U6 now together in one (RAM)Image to ease SD card read
-- Version 0.97 initial SD card read at start,
					 -- no prepopulated data in u2/U6 ram
					 -- SD card process starts CPU & PIA via reset_h after reading SD
-- Version 0.98 -- EEprom write now byte per byte and respect selection (one ram for each game)	64 games max with HW 0.14
					  --reset input stabilized
-- Version 0.99.1 -- PIA outputs default 'Z';
-- Version 0.99.2 -- address decoding rom adapted (4K roms) bug??
-- Version 0.99.3 -- solved S33 bug by giving only a short pulse, rather then the full S33 signal
-- Version 0.99.4 -- PIA U11 PB default to '1' (Momentary solenoids rest position) plus modified PIA code to prevent solenoid activity at boot
-- Version 1.0    -- new Board Layout
-- Version 1.01    -- updates from 0.99.06
-- Version 1.02    -- coin validator added
-- Version 1.03    -- coin validator need to be activated with option dip 5
-- Version 1.04    -- display output during boot added
-- Version 1.05    -- full decode addressroom
-- Version 1.06    -- decimal view of dip switch at player2
-- Version 1.07    -- shorter boot message as we interfere i  first testing of DIP switches otherwise
-- Version 1.08    -- again short-timed boot message, just to be on the safe side
-- Version 1.09    -- show boot message,then blank displays to prevent highlighted digits during boot
-- Version 1.10    -- dip3 adjusts cpu_clock from 500KHz to 400KHz for games which run too fast (only early games?)
-- Version 1.11    -- dip4 delayed zero cross for LED anti flicker (not working)
-- Version 1.12    -- new SD card routine to support more cards
-- Version 1.13    -- clk tests reverted because of Ghosting
-- Version 1.14    -- display clock shift adapted to 400 for comboboard interrupts
-- Version 1.15    -- solved IRQ bug in pia6821, now display clock without shift and adpated speed
-- Version 1.16    -- CB2 (Soundselect) set to high during boot ( XandO problem with init SB)
-- Version 1.17    -- weak pull-up U10_PB,CV_CH,S33,U10_CA1,U11_CB1,Zero_cross because of 74LVC245A
-- Version 1.18    -- LED_0 activation after boot & SD read. Needed for clean init of Cheap Squeak board. (used in BallFA HW v1.11 )
-- Version 1.19    -- option dip4 activates delayed zero cross for LED anti flicker
-- Version 1.20	 -- sdcard.vhd corrected, save calculation of sectornumbers
--                  (2.20 Cyclone IV EP4CE6F17C8, 3.20 Cyclone IV v4.x EP4CE6E22C8N + Quartus 22.1.2)
-- Version 1.21	 -- Zero cross indicator adjusted to prevent blinking Zero Cross LED with MPU-133
--                  (2_x.21 adapted to BallyFA HW 2.x plus USB MPF beta)
-- Version 1.22	 -- added second range (mirror) for cmos ram as Baby pacman checks this range during selftest (only two flashes without this range)
-- Version 1.23	 -- option DIP2 changed, eeprom v0.3 now when set each second the cmos content is saved to eeprom/fram ( caution: only ativate with fram )
--                  (4.23 / 2_4.23 for Cyclone 10)
-- Version x.23   -- common source tree for all 8 variants (no functional change):
--                   this core is the same for every board, the board shells
--                   top/BallyFA_HW1.vhd and top/BallyFA_HW2.vhd add what differs
--                   between base board HW 1.x and HW 2.x, variants/<n>/variant_pkg.vhd
--                   the FPGA board (BOARD_ID).
--
--                  The base board differences moved into this core afterwards (generic
--                   HW_GEN), so that the shells only declare ports: BallyFA_HW1/HW2 for
--                   Cyclone IV/10 (with the configuration flash pins), BallyFA_HW1_cii/
--                   HW2_cii for Cyclone II (without).
--
-- Displayed version (boot message, display 1): [HW digit] BOARD_ID . SW_SUB1 SW_SUB2
--   HW digit  blank for HW 1.x, "2" for HW 2.x (generic HW_GEN)
--   BOARD_ID  variants/<n>/variant_pkg.vhd: 1 Cyclone II, 2 Cyclone IV, 3 Cyclone IV v4.x, 4 Cyclone 10
--   SW_SUB*   rtl/common/version_pkg.vhd - a release changes ONE digit there
--
-- Base board, generic HW_GEN:
--   1  HW 1.x: LED_1/LED_2 held at '1', inputs direct, no USB
--   2  HW 2.x: 4049 inverters in front of CV_CH, ZERO_CROSS, S33, U10_PB, U10_CA1 and
--      U11_CB1 - inverted back right at the input, so everything below works in HW 1.x
--      polarity (before the common tree every use of these inputs carried a "not");
--      USB serial (CH340) via lisy_api. LED_1/LED_2 do not exist on this board.
-- Ports a board does not have are simply left open by its shell.

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.variant_pkg.all;
use work.version_pkg.all;

entity Bally_core is
	generic(
		HW_GEN        : integer;	-- base board, 1 = HW 1.x, 2 = HW 2.x
		HAS_FLASH_ROM : boolean	-- game ROMs from the configuration flash when no SD card answers
	);
	port(
	   -- the FPGA board
		clk_50	: in std_logic; 	-- PIN17
		reset_l  : in std_logic; 	-- PIN144 --goes Low on reset(push)
		LED_0 	: out STD_LOGIC;	-- PIN3
		LED_1 	: out STD_LOGIC;	-- HW 1.x only
		LED_2 	: out STD_LOGIC;	-- HW 1.x only

		-- configuration flash, second source of the game ROMs (HAS_FLASH_ROM). Dual purpose
		-- pins on Cyclone IV/10, not available on Cyclone II (shell leaves them open).
		FLASH_DCLK	: out std_logic;
		FLASH_NCS	: out std_logic;
		FLASH_ASDO	: out std_logic;	-- data into the flash
		FLASH_DATA0	: in  std_logic;	-- data out of the flash

		-- USB serial CH340, HW 2.x only
		USB_Rx		: out std_logic;
		USB_Tx		: in  std_logic;

		-- EEProm
		C_EEPROM	:	buffer 	std_logic;
		S_EEPROM	:	buffer 	std_logic;
		Q_EEPROM	:	in 	std_logic;
		D_EEPROM	:	buffer 	std_logic;
				
		-- SDcard
		SD_CS : buffer 	std_logic;		
		SD_MISO : in 	std_logic;		
		SD_MOSI : buffer 	std_logic;		
		SD_CLK : buffer 	std_logic;		
				
		-- BallayFA Board
		LED_ON   	:  out 	std_logic;
		LED_Bally   :  out 	std_logic;	-- pin differs between HW 1.x and HW 2.x, see shells
		LED_ZC	   :  out 	std_logic;
		LED_SD_ERR  :  out 	std_logic;	-- pin differs between HW 1.x and HW 2.x, see shells

		S1_DIPS	:	in 	std_logic_vector(7 downto 0);
		S2_DIPS	:	in 	std_logic_vector(1 to 6);
		-- S2_DIPS(1) - ZC fake (for testing on the bench)
		-- S2_DIPS(2) - testtrigger eeprom
		-- S2_DIPS(3) - NOT used reduce cpu_clock from 500 to 400KHz
		-- S2_DIPS(4) - NOT used delayed zero cross ( anti flicker for LEDs )
		-- S2_DIPS(5) - activate coin validator
		-- S2_DIPS(6) - init nvram/eeprom for this game at start
		
		CV_CH		:	in 	std_logic_vector(1 to 6); --channels coin validator
		CV_COIN_LOCK		:	out 	std_logic;
		
		ZERO_CROSS	:	in 	std_logic;
		DISP_LA_STR	:	out 	std_logic_vector(1 to 5);
		DISP_BLANKING	:	out 	std_logic;
		             
		-- U9 NMI CPU 6800 on bally, looks like it is not working for cpu68.vhd
		S33			:	in 	std_logic;
		
		-- U10 PIA
		U10_PA		:	out 	std_logic_vector(7 downto 0):= "ZZZZZZZZ";
		U10_PB		:	in 	std_logic_vector(7 downto 0):= "ZZZZZZZZ";
		U10_CA1		:	in 	std_logic;
		-- U10_CA2		:	out 	std_logic; --display logic internal
		-- U10_CB1	:	in 	std_logic; --  Zero cross intern
		U10_CB2		:	out 	std_logic:= 'Z';
		
		-- U11 PIA
		U11_PA		:	out 	std_logic_vector(7 downto 1):= "ZZZZZZZ"; 
		U11_PB		:	buffer 	std_logic_vector(7 downto 0):= "ZZZZ1111";
		-- U11_CA1		:	in 	std_logic; --display int gen
		U11_CA2		:	out 	std_logic:= 'Z';
		U11_CB1		:	in 	std_logic;
		U11_CB2		:	out 	std_logic:= '1'

		);
end;

architecture rtl of Bally_core is

-- leading digit of display 1: blank on HW 1.x, "2" on HW 2.x
function hw_digit(gen : integer) return std_logic_vector is
begin
	if gen = 2 then
		return x"2";
	end if;
	return x"F";
end function;

-- inputs in HW 1.x polarity (HW 2.x: 4049 inversion undone, see GEN_HW2)
signal cv_ch_i			:	std_logic_vector(1 to 6);
signal zero_cross_i	:	std_logic;
signal s33_i			:	std_logic;
signal u10_pb_i		:	std_logic_vector(7 downto 0);
signal u10_ca1_i		:	std_logic;
signal u11_cb1_i		:	std_logic;

--internal signals via logic
signal zc_stable			:	std_logic; -- Zero cross stable intern ( we have crossing clock domains)
signal zc_delayed			:	std_logic; -- for LED anti flicker
signal zc_indicator		:	std_logic; -- Zero cross indicator for LED
signal disp_int_clock 	: std_logic; --clock for display interrupt 400 Hz
signal zc_int_clock 		: std_logic; --clock for fake zero cross 100Hz
signal U10_CB1				: std_logic; --zero cross pin on PIA
signal reset_l_stable	:	std_logic; 
signal S33_stable	:	std_logic; 

signal cpu_clk		:  std_logic; 

-- have to be a 500KHz kHz CPU clock
signal reset_h		: 	std_logic;

signal cpu_addr	: 	std_logic_vector(15 downto 0);
signal cpu_din		: 	std_logic_vector(7 downto 0) := x"FF";
signal cpu_dout	: 	std_logic_vector(7 downto 0);
signal cpu_rw		: 	std_logic;
signal cpu_vma		: 	std_logic;  --valid memory address
signal cpu_irq		: 	std_logic;
signal cpu_nmi		:	std_logic;

--signal rom_U2_dout	:	std_logic_vector(7 downto 0);
--signal rom_U2_cs		: 	std_logic;
--signal rom_U6_dout	:	std_logic_vector(7 downto 0);
--signal rom_U6_cs		: 	std_logic;

signal rom_dout				:	std_logic_vector(7 downto 0);
signal rom_first_half		: 	std_logic;
signal rom_second_half		: 	std_logic;
signal u2_mirror				: 	std_logic;
signal rom_U2_or_U6_cs		: 	std_logic;
signal rom_sd_addr			: 	std_logic_vector(1 downto 0);
signal rom_mem_addr			: 	std_logic_vector(1 downto 0);
signal U2U6_address			:	std_logic_vector(12 downto 0);

signal ram_U7_dout	: 	std_logic_vector(7 downto 0);
signal ram_U7_cs		:	std_logic;

signal ram_U8_dout_4bit	: 	std_logic_vector(3 downto 0);
signal ram_U8_dout_8bit	: 	std_logic_vector(7 downto 0);
signal ram_U8_cs			:	std_logic;


-- PIA U10
signal pia_U10_dout	:	std_logic_vector(7 downto 0);
signal pia_U10_irq_a	:	std_logic;
signal pia_U10_irq_b	:	std_logic;
signal pia_U10_cs		:	std_logic;
--------------------
signal pia_U10_pa_o	: 	std_logic_vector(7 downto 0);
signal pia_U10_switches	:  std_logic_vector(7 downto 0);
signal pia_U10_pb_i	:  std_logic_vector(7 downto 0);
signal pia_U10_ca2_o	:  std_logic;
signal pia_U10_cb2_o	:  std_logic;

-- PIA U11
signal pia_U11_dout	:	std_logic_vector(7 downto 0);
signal pia_U11_irq_a	:	std_logic;
signal pia_U11_irq_b	:	std_logic;
signal pia_U11_cs		:	std_logic;
--------------------
signal pia_U11_pa_o	: 	std_logic_vector(7 downto 0); 
signal pia_U11_pb_o	:  std_logic_vector(7 downto 0);
signal pia_U11_ca2_o :  std_logic;

-- SD card
signal address_sd_card	:  std_logic_vector(12 downto 0);
signal data_sd_card	:  std_logic_vector(7 downto 0);
signal wr_rom			:  std_logic;
signal SDcard_error		:  std_logic;

-- the two ROM sources: SD card (sd_), configuration flash (fl_, HAS_FLASH_ROM only).
-- The signals above carry whichever is in use (use_flash), see GEN_FLASH.
signal game_slot			:  std_logic_vector(7 downto 0); -- selected game, DIPs S1 inverted
signal sd_address			:  std_logic_vector(12 downto 0);
signal sd_data				:  std_logic_vector(7 downto 0);
signal sd_wr_rom			:  std_logic;
signal sd_reset_h			:  std_logic;
signal sd_error			:  std_logic;
signal sd_no_card			:  std_logic;
signal fl_address			:  std_logic_vector(12 downto 0);
signal fl_data				:  std_logic_vector(7 downto 0);
signal fl_wr_rom			:  std_logic;
signal fl_reset_h			:  std_logic;
signal fl_error			:  std_logic;
signal fl_empty			:  std_logic; -- flash slot empty or beyond the flash, error 8
signal use_flash			:  std_logic;
signal slot_dig0			:  std_logic_vector(3 downto 0);
signal slot_dig1			:  std_logic_vector(3 downto 0);
signal slot_dig2			:  std_logic_vector(3 downto 0);
signal d4_lead				:  std_logic_vector(3 downto 0); -- display 4 during boot
signal d4_2					:  std_logic_vector(3 downto 0);
signal d4_1					:  std_logic_vector(3 downto 0);
signal d4_0					:  std_logic_vector(3 downto 0);

-- EEprom we use 128Bytes
signal address_eeprom	:  std_logic_vector(6 downto 0);
signal data_eeprom	:  std_logic_vector(7 downto 0);
signal wr_ram			:  std_logic;

-- coin validator helper
signal CV_Return_0	:  std_logic;
signal CV_Return_1	:  std_logic;
signal CV_Return_2	:  std_logic;

-- boot message (bm_) helper
signal bm_show				:  std_logic :='1'; -- show boot message
signal bm_latch_strobe	:  std_logic_vector(4 downto 0);
signal bm_digit_enable	:  std_logic_vector(6 downto 0);
signal bm_bcd_data		:  std_logic_vector(3 downto 0);
signal bm_blanking		: 	std_logic;
signal boot_blanking		: 	std_logic; -- to disable displays during boot of ballyFA
signal bally_led_count	:  std_logic_vector(3 downto 0) :=x"F";
signal dig0					:  std_logic_vector(3 downto 0);
signal dig1					:  std_logic_vector(3 downto 0);
signal dig2					:  std_logic_vector(3 downto 0);

begin
-- reset_h <= (not reset_l); --now conrolled by SD card read process

----------------------
-- base board (HW_GEN), two complementary generates - VHDL-93 has no else generate
----------------------
GEN_HW1: if HW_GEN = 1 generate
	cv_ch_i      <= CV_CH;
	zero_cross_i <= ZERO_CROSS;
	s33_i        <= S33;
	u10_pb_i     <= U10_PB;
	u10_ca1_i    <= U10_CA1;
	u11_cb1_i    <= U11_CB1;
	LED_1 <= '1';
	LED_2 <= '1';
	USB_Rx <= '1';
end generate;

GEN_HW2: if HW_GEN = 2 generate
	-- 4049 inverters (IC7, IC8, IC9) on the HW 2.x base board
	cv_ch_i      <= not CV_CH;
	zero_cross_i <= not ZERO_CROSS;
	s33_i        <= not S33;
	u10_pb_i     <= not U10_PB;
	u10_ca1_i    <= not U10_CA1;
	u11_cb1_i    <= not U11_CB1;
	-- not on this board, the shell leaves them open
	LED_1 <= '1';
	LED_2 <= '1';

	--lisy api (USB MPF beta)
	mpf: entity work.lisy_api
	port map(   
		clk => clk_50,
		rst => reset_l,
		txd => USB_Rx,	
		rxd => USB_Tx
	);
end generate;

----------------------
-- configuration flash: idle while HAS_FLASH_ROM is off (chip select high)
----------------------
GEN_NO_FLASH: if not HAS_FLASH_ROM generate
	FLASH_DCLK <= '0';
	FLASH_NCS  <= '1';
	FLASH_ASDO <= '0';
	-- the SD card is the only source
	address_sd_card <= sd_address;
	data_sd_card    <= sd_data;
	wr_rom          <= sd_wr_rom;
	reset_h         <= sd_reset_h;
	SDcard_error    <= sd_error;
	-- display 4 stays blank (use_flash is constant '0' here)
	d4_lead   <= x"F";
	slot_dig0 <= x"F";
	slot_dig1 <= x"F";
	slot_dig2 <= x"F";
end generate;

----------------------
-- configuration flash as second source of the game ROMs (HAS_FLASH_ROM, x.30)
----------------------
-- No card answered (SD_Card ended in error, o_no_card) -> read the same 8 KByte slot
-- from the configuration flash and take over ROM write port, CPU reset and SD LED.
-- Layout and the empty-slot check (error 8): rtl/common/Flash_ROM.vhd.
-- Outside the generates, so that sd_no_card is read on every board. Constant '0'
-- without HAS_FLASH_ROM.
use_flash <= sd_no_card when HAS_FLASH_ROM else '0';

-- selected game: DIPs S1 inverted (DIP ON = '0'), as SD_Card always took it
game_slot <= not S1_DIPS;

GEN_FLASH: if HAS_FLASH_ROM generate
	FLASH_ROM: entity work.Flash_ROM
	port map(
		i_Clk => clk_50,
		i_Rst_L => sd_no_card,
		o_Flash_Clk  => FLASH_DCLK,
		o_Flash_CS_n => FLASH_NCS,
		o_Flash_MOSI => FLASH_ASDO,
		i_Flash_MISO => FLASH_DATA0,
		selection => game_slot,
		address_rom => fl_address,
		data_rom => fl_data,
		wr_rom => fl_wr_rom,
		cpu_reset_h => fl_reset_h,
		Flash_error => fl_error,
		flash_empty => fl_empty
	);

	address_sd_card <= fl_address when use_flash = '1' else sd_address;
	data_sd_card    <= fl_data    when use_flash = '1' else sd_data;
	wr_rom          <= fl_wr_rom  when use_flash = '1' else sd_wr_rom;
	reset_h         <= fl_reset_h when use_flash = '1' else sd_reset_h;
	SDcard_error    <= fl_error   when use_flash = '1' else sd_error;

	-- display 4 during boot: the slot number when the ROMs came from the flash - that is
	-- how you tell a flash boot -, with an 8 in front for an empty slot (error 8)
	CONVS: entity work.byte_to_decimal
	port map(
		clk_in	=> clk_50,
		mybyte	=> game_slot,
		dig0 => slot_dig0,
		dig1 => slot_dig1,
		dig2 => slot_dig2
		);
	d4_lead <= x"8" when fl_empty = '1' else x"F";
end generate;

-- display 4 digits: outside the generates, so that use_flash is read on every board
d4_2 <= slot_dig2 when use_flash = '1' else x"F";
d4_1 <= slot_dig1 when use_flash = '1' else x"F";
d4_0 <= slot_dig0 when use_flash = '1' else x"F";
----------------------
-- boot message
----------------------
BM: entity work.boot_message
port map(
	clk_in		=> cpu_clk, 	
	-- Control/Data Signals,
   show  => bm_show,    
	-- output
	latch_strobe	=> bm_latch_strobe,
	digit_enable => bm_digit_enable,
	bcd_data	=> bm_bcd_data,
	blanking	=> bm_blanking,
	-- input (display data)
	display1	=> ( x"F",x"F",hw_digit(HW_GEN),x"F",BOARD_ID,SW_SUB1,SW_SUB2 ),
	display2	=> ( x"F",x"F",x"F",x"F", dig2, dig1, dig0),
	display3	=> ( x"F",x"0",x"5",x"0",x"9",x"6",x"3" ),
	display4	=> ( d4_lead,x"F",x"F",x"F",d4_2,d4_1,d4_0 ),	-- flash boot, see GEN_FLASH
	status_d	=> ( x"F",x"F",x"F",x"F",x"F",x"F",bally_led_count )
	);

-- count pulses
-- close boot message
-- disable displays
COUNT_PULSE: process(pia_U11_ca2_o)
 begin 
    if(rising_edge(pia_U11_ca2_o)) then	  
	  --show boot message for first five blinks of test and countdown
	  if ( bally_led_count > 10) then
	    bally_led_count <= bally_led_count - 1;
		 boot_blanking <= '0';
	 -- then blank diplays	 
	 elsif ( bally_led_count > 0) then
		 bally_led_count <= bally_led_count - 1;
		 bm_show <= '0';
		 boot_blanking <= '1';
	 -- until test finished	 
	 else 
		 bally_led_count <= x"0";		 
		 boot_blanking <= '0';
	  end if;
  end if;      
 end process;  
 
CONVB: entity work.byte_to_decimal
port map(
	clk_in	=> clk_50, 	
	mybyte	=> S1_DIPS,
	dig0 => dig0,
	dig1 => dig1,
	dig2 => dig2
	);
 
----------------------
-- SD card stuff
----------------------
SD_CARD: entity work.SD_Card
port map(
	i_clk		=> clk_50, 	
	-- Control/Data Signals,
   i_Rst_L  => reset_l_stable,     -- FPGA Reset   
	-- PMOD SPI Interface
   o_SPI_Clk  => SD_CLK,
   i_SPI_MISO => SD_MISO,
   o_SPI_MOSI => SD_MOSI,
   o_SPI_CS_n => SD_CS,	
	-- selection
	selection => game_slot,
	-- data
	address_sd_card => sd_address,
	data_sd_card => sd_data,
	wr_rom => sd_wr_rom,
	-- control CPU
	cpu_reset_h => sd_reset_h,
	-- feedback
	SDcard_error => sd_error,
	o_no_card => sd_no_card
	);

----------------------
-- 5101 ram (dual port)
----------------------
U8: entity work.R5101 -- 5101 RAM 128Byte (256 * 4bit) 
	port map(
		address_a	=> cpu_addr(7 downto 0),
		address_b   => address_eeprom,
		clock			=> clk_50,
		data_a		=> cpu_dout (7 DOWNTO 4), -- Bally use the upper 4 bits
		data_b		=> data_eeprom, --8bit
		wren_a 		=> ram_U8_cs and not cpu_rw and not cpu_clk,
		wren_b 		=> wr_ram,
		q_a			=> ram_U8_dout_4bit,
		q_b			=> ram_U8_dout_8bit
);


----------------------
-- read eeprom, read/write to ram
----------------------
EEprom: entity work.EEprom
port map(
								   
	i_clk => clk_50,
	address_eeprom	=> address_eeprom,
	data_eeprom	=> data_eeprom,
	wr_ram => wr_ram,
	q_ram => ram_U8_dout_8bit,
	-- Control/Data Signals,
   i_Rst_L  => reset_l_stable,     -- FPGA Reset   
	-- PMOD SPI Interface
   o_SPI_Clk  => C_EEPROM,
   i_SPI_MISO => Q_EEPROM,
   o_SPI_MOSI => D_EEPROM,
   o_SPI_CS_n => S_EEPROM,
	-- selection
	selection => not S1_DIPS,	
	-- write trigger
	w_trigger(3) => u10_ca1_i,	-- self Test switch
	w_trigger(2) => U11_PB(5), -- coin lockout
	w_trigger(1) => U11_PB(6), -- flipper disable
	w_trigger(0) => not S2_DIPS(2), -- as trigger for testing	
	-- init trigger (no read, RAM will be zero)
	i_init_Flag => S2_DIPS(6), -- 0 if Dip is set 
	-- fram option
	cont_save => not S2_DIPS(2)
	-- signal to outside
	--outside => LED_1
	);	



-- LEDs
LED_0 <= reset_h; -- used for activating 74HC244
LED_Bally <= not pia_U11_ca2_o; -- Bally Green LED
LED_SD_ERR <= SDcard_error;

-- BallyFA LEDs
LED_ON <= not cpu_irq;
LED_ZC <= zc_indicator; -- zero cross indicator


----------------------
-- coin validator
----------------------
cv_COIN_LOCK <= not U11_PB(5); -- coin lockout

CV:  entity work.coin_validator
port map(
		is_active_l => S2_DIPS(5),
		Strobe_1 => pia_U10_pa_o(1),
      Return_0 => CV_Return_0,    -- #9 right chute
		Return_1 => CV_Return_1,    -- #10 left chute
		Return_2 => CV_Return_2,	 -- #11 middle
		channel_1 => cv_ch_i(6), --2,-
		channel_2 => cv_ch_i(4), -- 0,50cent
		channel_3 => cv_ch_i(5)  -- 1.-
	);

pia_U10_pb_i(0) <= pia_U10_switches(0) or CV_Return_0 when S2_DIPS(5) = '0' else pia_U10_switches(0);
pia_U10_pb_i(1) <= pia_U10_switches(1) or CV_Return_1 when S2_DIPS(5) = '0' else pia_U10_switches(1);
pia_U10_pb_i(2) <= pia_U10_switches(2) or CV_Return_2 when S2_DIPS(5) = '0' else pia_U10_switches(2);
pia_U10_pb_i(7 downto 3) <= pia_U10_switches(7 downto 3);

----------------------
-- Cross domain clock stuff
-- for zero cross and S33
----------------------	
META1: entity work.Cross_Slow_To_Fast_Clock
port map(
   i_D => zero_cross_i,
	o_Q => zc_stable,
   i_Fast_Clk => cpu_clk
	);

META3: entity work.Cross_Slow_To_Fast_Clock
port map(
   i_D => reset_l,
	o_Q => reset_l_stable,
   i_Fast_Clk => cpu_clk
	);

META4: entity work.Cross_Slow_To_Fast_Clock
port map(
   i_D => s33_i,
	o_Q => S33_stable,
   i_Fast_Clk => cpu_clk
	);
	
PULSE: entity work.one_pulse_only
port map(
   sig_in => S33_stable,
	sig_out => cpu_nmi,
   clk_in => cpu_clk,
	rst => reset_l
	);

ZC_DELAY: entity work.signal_delay
port map(
  sig_in => zc_stable,
  sig_out => zc_delayed,
  clk_in => cpu_clk
	);


----------------------
-- PIA port IO mapping
----------------------

-- Fakes for testing when S1 is ON
--U10_CB1 <= zc_int_clock when S2_DIPS(1) = '0' else zc_stable; -- Zero Cross Detector 
U10_CB1 <= zc_int_clock when S2_DIPS(1) = '0' -- fake zero cross for testing on the bench
				else zc_delayed when S2_DIPS(4) = '0' -- delayed zero cross (LED anti flicker)
				else zc_stable; -- Zero Cross Detector 

----------------------
-- Displays, controled by FPGA at boot time
----------------------

-- Display Digit Enable
U11_PA( 7 downto 1) <= pia_U11_pa_o( 7 downto 1) when bm_show = '0' else bm_digit_enable; 
							  
-- Display Segment (BCD) Data
-- Latch strobes ( via strobed hex inverter, inhibit is pia_U10_ca2_o)
DISP_LA_STR(1) <= ( not  pia_U10_ca2_o ) and (not pia_U10_pa_o(0)) when bm_show = '0' else bm_latch_strobe(0);
DISP_LA_STR(2) <= ( not  pia_U10_ca2_o ) and (not pia_U10_pa_o(1)) when bm_show = '0' else bm_latch_strobe(1);
DISP_LA_STR(3) <= ( not  pia_U10_ca2_o ) and (not pia_U10_pa_o(2)) when bm_show = '0' else bm_latch_strobe(2);
DISP_LA_STR(4) <= ( not  pia_U10_ca2_o ) and (not pia_U10_pa_o(3)) when bm_show = '0' else bm_latch_strobe(3);
DISP_LA_STR(5) <= ( not  pia_U10_ca2_o ) and (not pia_U11_pa_o(0)) when bm_show = '0' else bm_latch_strobe(4);
-- Blanking
-- RTH possibly need to be adjusted: 
-- BLANKING has a 4uS delay L->H when ca2_o goes H->L
-- BLANKING goes L immidiatly when ca2_o goes H
-- show boot message,then blank displays to prevent highlighted digits during boot
DISP_BLANKING <= bm_blanking when bm_show = '1'
					  else '1' when boot_blanking = '1'					  					
					  else not (pia_U10_ca2_o);

----------------------
-- Solenoids & Sound
----------------------
-- xx_oe = '1' output enabled
--U11_PB(0) <= pia_U11_pb_o(0) when pia_U11_pb_oe(0) = '1'  else 'Z';
-- duirect
----------------------
-- Switches
----------------------
META2: entity work.Cross_Slow_To_Fast_Clock_Bus
port map(
   i_D => u10_pb_i,
	o_Q => pia_U10_switches,
   i_Fast_Clk => cpu_clk
	);

-- Strobes
U10_PA <= pia_U10_pa_o when bm_show = '0' else bm_bcd_data & pia_U10_pa_o(3 downto 0);

----------------------
-- Lamps
----------------------
-- address and data DIRECT via U10_PA
U10_CB2 <= pia_U10_cb2_o;  --Lampstrobe #1
U11_CA2 <= pia_U11_ca2_o;  --Lampstrobe #2

-- IRQ signals ( should be '0')
cpu_irq <= pia_U10_irq_a or pia_U10_irq_b or pia_U11_irq_a or pia_U11_irq_b;
--cpu_nmi <= '0'; -- as NMI seem to do not work with cpu68 ?

------------------
-- address decoding 
------------------
-- -17 bally MPU use only 13 Adresslines (12 downto 0)
-- -35 Bally and Stern have 15 Adresslines (14 downto 0)
------------------
--
-- U7 Memory 6810 (128 x 8 Zero-Page) 0x0000 - 0x007F
ram_U7_cs    <= '1' when cpu_addr(14 downto 7) = "00000000" and cpu_vma='1' else '0';
-- PIA U10 0x0088 - 0x008F
pia_U10_cs   <= '1' when cpu_addr(14 downto 3) = "0000000010001" and cpu_vma='1' else '0';
-- PIA U10 0x0090 - 0x0097
pia_U11_cs   <= '1' when cpu_addr(14 downto 3) = "0000000010010" and cpu_vma='1' else '0';
-- U8 Memory 5101 (256 x 4) 0x0200 - 0x02FF, D7..D4
--ram_U8_cs <= '1' when cpu_addr(14 downto 8) = "0000010" and cpu_vma='1' else '0';
ram_U8_cs <= not cpu_addr(12) and cpu_addr(9) and cpu_vma;

------------------
-- optional clock adjustment
------------------
--cpu_clk <= clk_500KHz when S2_DIPS(3) = '1' else clk_400KHz;

------------------
-- ROMs ----------
------------------
-- moved to RAM, initial read from SD
-- one file of 8Kbyte for all bally Variants
-- upper half for old games (2KBYTE Roms) are duplicated
-- need to be mapped to MPU memory  address range
------------------


-- U2 ROM first half   		0x1000 - 0x17FF
-- U2 ROM second half  		0x5000 - 0x57FF
-- U6 ROM first half   		0x1800 - 0x1FFF 
-- U6 ROM second half  		0x5800 - 0x5FFF
-- U2 Mirror (sys vectors)	0xF800 - 0xFFFF
rom_first_half <= '1' when cpu_addr(14 downto 12) = "001" and cpu_vma='1' else '0';
rom_second_half <= '1' when cpu_addr(14 downto 12) = "101" and cpu_vma='1' else '0';
u2_mirror <= '1' when cpu_addr(14 downto 12) = "111" and cpu_vma='1' else '0';
rom_U2_or_U6_cs <= rom_first_half or rom_second_half or u2_mirror;
--rom_U2_or_U6_cs <= cpu_addr(12) and cpu_vma;

-- Bus control
 cpu_din <= 
   rom_dout when rom_U2_or_U6_cs = '1' else
   pia_U10_dout when pia_U10_cs = '1' else
	pia_U11_dout when pia_U11_cs = '1' else	
	ram_U7_dout when ram_U7_cs = '1' else
	ram_U8_dout_4bit & "1111" when ram_U8_cs = '1' else		
	x"FF";

------------------
-- ROMs ----------
-- moved to RAM, initial read from SD
-- one file of 8Kbyte for all bally Variants
-- upper half for old games (2KBYTE Roms) are duplicated
-- need to be mapped to MPU memory  address range
------------------
rom_mem_addr <= cpu_addr(14) & cpu_addr(11);
rom_sd_addr <= "00" when rom_mem_addr = "00" else 	--00 U2 First half:
					"01" when rom_mem_addr = "10" else	--10 U2 Second half: !!
					"10" when rom_mem_addr = "01" else	--01 First half:		!!
					"11";											--11 U6 Second half:
					
-- address selection	
-- read from SD when wr_rom == 1
-- else map to addrtess room
U2U6_address <=
	address_sd_card when wr_rom = '1' else
	rom_sd_addr & cpu_addr(10 downto 0);
	
--U2 and U6 combined
U2andU6: entity work.U2andU6
port map(
	address => U2U6_address,	
	clock => clk_50,
	data => data_sd_card,
	wren => wr_rom,
	q	=> rom_dout
	);
	

U7: entity work.M6810 -- 56810 Ram 128Byte (128*8bit)
port map(
	address	=> cpu_addr(7 DOWNTO 0),	
	clock => clk_50,
	data		=>  cpu_dout (7 DOWNTO 0),
	wren 		=> ram_U7_cs and not cpu_rw and not cpu_clk,
	q			=> ram_U7_dout
);	


U9: entity work.cpu68
port map(
	clk => cpu_clk,
	rst => reset_h,
	rw => cpu_rw,
	vma => cpu_vma,
	address => cpu_addr,
	data_in => cpu_din,
	data_out => cpu_dout,
	hold => '0',
	halt => '0',
	irq => cpu_irq,
	--nmi => '0'
	nmi => not cpu_nmi
);

U10: entity work.PIA6821
port map(
	clk => cpu_clk,   
   rst => reset_h,     
   cs => pia_U10_cs,     
   rw => cpu_rw,    
   addr => cpu_addr(1 downto 0),     
   data_in => cpu_dout,  
	data_out => pia_U10_dout, 
	irqa => pia_U10_irq_a,   
	irqb => pia_U10_irq_b,    
	pa_i => x"FF",  			-- not used, output only  
	pa_o => pia_U10_pa_o,   -- strobes, display data 
	ca1 => u10_ca1_i,			-- self Test switch
	ca2_i => '1',    			-- not used, output only  
	ca2_o => pia_U10_ca2_o, -- Display CTRL   
	pb_i => pia_U10_pb_i,   -- Switch Returns (stabilized)	
	pb_o => open,    			-- not used, input only  
	cb1 => U10_CB1,    		-- Zero Cross
	cb2_i => '0',  			-- not used, output only  
	cb2_o => pia_U10_cb2_o,  -- Lampstrobe#1 & DIP Strobe
	default_pb_level => '0'  -- output level when configured as input
);

U11: entity work.PIA6821
port map(
	clk => cpu_clk,   
   rst => reset_h,     
   cs => pia_U11_cs,     
   rw => cpu_rw,    
   addr => cpu_addr(1 downto 0),     
   data_in => cpu_dout,  
	data_out => pia_U11_dout, 
	irqa => pia_U11_irq_a,   
	irqb => pia_U11_irq_b,    
	pa_i => x"FF",    		-- not used, output only  
	pa_o => pia_U11_pa_o,   -- display digits, latch#5,sound E 
	ca1 => disp_int_clock,  -- input 400Hz display int gen	
	ca2_i => '1',    			-- not used, output only  
	ca2_o => pia_U11_ca2_o, -- Lamp Strobe #2, Green LED   
	pb_i => x"FF",    		-- not used, output only  
	pb_o => U11_PB,  	-- Solenoids	
	cb1 => u11_cb1_i,    		-- J5 Pin32 plus Stern Lamp Int
	cb2_i => '0',  			-- not used, output only  
	cb2_o => U11_CB2,   		-- Solenoid/Sound Select
	default_pb_level => '1'  -- output level when configured as input (solenoids)
);
	 
-- cpu clock
clock_gen: entity work.cpu_clk_gen
port map(   
	clk_in => clk_50,
	clk_out	=> cpu_clk
);


-- display interrupt generator 400 Hz
disp_int: entity work.clk_400Hz_gen 
port map(   
	clk_in => cpu_clk,	
	clk_out	=> disp_int_clock
);

-- fake zero cross 60Hz
zc_int: entity work.zc_clk_gen 
port map(   
	dclk_in => cpu_clk,
	dclk_out	=> zc_int_clock
);

-- zero cross indicator
-- uses display clock to scan zero cross
-- will set indicator to high if two edges or more missing
-- will set back to low if czeo cross is restored
zc_indi: entity work.zc_indicator 
port map(   
	scan_clock => cpu_clk,
	zc_in => U10_CB1, --either from zc or from internal fake
	zc_flag	=> zc_indicator
);

	
end rtl;


  