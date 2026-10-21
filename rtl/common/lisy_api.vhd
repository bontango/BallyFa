-- LISY API protocol via uart 
--
-- This is free software: you can redistribute
-- it and/or modify it under the terms of the GNU General
-- Public License as published by the Free Software
-- Foundation, either version 3 of the License, or (at your
-- option) any later version.
--
-- This is distributed in the hope that it will
-- be useful, but WITHOUT ANY WARRANTY; without even the
-- implied warranty of MERCHANTABILITY or FITNESS FOR A
-- PARTICULAR PURPOSE. See the GNU General Public License
-- for more details.
--
-- Version 0.1 only parameters for 'mpf hardware scan' implemented
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lisy_api is
    Port ( 
           clk : in  STD_LOGIC; -- 50MHz
           rst : in  STD_LOGIC; --reset_l
           txd : out  STD_LOGIC; --txd pin	
		   rxd : in  STD_LOGIC --rxd pin				  
		);	  
end lisy_api;

architecture Behavioral of lisy_api is

-- RecelFA constants
--constant LISY_API_HW : string :="RECELFA" & NUL;
constant LISY_API_HW : string :="LISY80" & NUL;
constant LISY_API_LISY_VER : string :="5.26 " & NUL;
constant LISY_API_VER : string :="0.09" & NUL;
constant LISY_API_NO_LAMPS : integer := 21;
constant LISY_API_NO_SOL : integer := 10;
constant LISY_API_NO_SOUNDS : integer := 6;
constant LISY_API_NO_DISP : integer := 6;
--constant LISY_API_DISP_DETAIL ???
constant LISY_API_GAME_INFO : integer := 7; --RTH set to game_options
constant LISY_API_NO_SW : integer := 90; --RTH was 40, must be 90?
constant LISY_API_NO_MOD_LIGHTS : integer := 0;

--info, parameter none
constant LISY_G_HW            : integer := 0; --get connected LISY hardware -	return "LISY1" or "LISY80"
constant LISY_G_LISY_VER      : integer := 1; --get LISY Version - return String
constant LISY_G_API_VER       : integer := 2; --get API Version - return String
constant LISY_G_NO_LAMPS      : integer := 3; --get number of lamps - return byte
constant LISY_G_NO_SOL        : integer := 4; --get number of soleneoids - return byte
constant LISY_G_NO_SOUNDS     : integer := 5; --get number of sounds - return byte
constant LISY_G_NO_DISP       : integer := 6; --get number of displays - return byte
constant LISY_G_DISP_DETAIL   : integer := 7; --get display details
constant LISY_G_GAME_INFO     : integer := 8; --get game info - return string 'Gottlieb internal number/char'
constant LISY_G_NO_SW         : integer := 9; --get number of switches - return byte

--lamps, parameter byte
constant LISY_G_STAT_LAMP     : integer := 10; --get status of lamp # - return byte "0=OFF; 1=ON; 2=Error"
constant LISY_S_LAMP_ON       : integer := 11; --set lamp # to ON - return none
constant LISY_S_LAMP_OFF      : integer := 12; --set lamp # to OFF - return none
constant LISY_FADE_MOD_LIGHTS : integer := 13; --fade number of modern lights
constant LISY_G_NO_MOD_LIGHTS : integer := 19; --get number of modern lights ( RTH: 19 is correct)

--solenoids, parameter byte
constant LISY_G_STAT_SOL      : integer := 20; --get status of solenoid # - return byte "0=OFF; 1=ON; 2=Error"
constant LISY_S_SOL_ON        : integer := 21; --set solenoid # to ON - return none
constant LISY_S_SOL_OFF       : integer := 22; --set solenoid # to OFF - return none
constant LISY_S_PULSE_SOL     : integer := 23; --pulse solenoid# - return none
constant LISY_S_PULSE_TIME    : integer := 24; --set pulse time for solenoid# 1-byte integer ( 0 - 255 )
constant LISY_S_RECYCLE_TIME  : integer := 25; --set recycle time for solenoid# 1-byte integer ( 0 - 255 )
constant LISY_S_SOL_PULSE_PWM : integer := 26; --Pulse solenoid and then enable solenoid with PWM

--displays, parameter string
constant LISY_S_DISP_0        : integer := 30; --set display 0 (status) to sequence of bytes, second arg is length - return none
constant LISY_S_DISP_1        : integer := 31; --set display 1 to sequence of bytes, second arg is length - return none
constant LISY_S_DISP_2        : integer := 32; --set display 2 to sequence of bytes, second arg is length - return none
constant LISY_S_DISP_3        : integer := 33; --set display 3 to sequence of bytes, second arg is length - return none
constant LISY_S_DISP_4        : integer := 34; --set display 4 to sequence of bytes, second arg is length - return none
constant LISY_S_DISP_5        : integer := 35; --set display 5 to sequence of bytes, second arg is length - return none
constant LISY_S_DISP_6        : integer := 36; --set display 6 to sequence of bytes, second arg is length - return none
constant LISY_S_DISP_PROT     : integer := 37; --set the protocoll for the display, first arg is display no, second arg is display no

--switches, parameter byte/none
constant LISY_G_STAT_SW       : integer := 40; --get status of switch# - return byte "0=OFF; 1=ON; 2=Error"
constant LISY_G_CHANGED_SW    : integer := 41; --get changed switches - return byte "bit7 is status; 0..6 is number" "127 means no change since last call"

--Sound (Hardware), parameter byte/none
constant LISY_S_PLAY_SOUND     : integer := 50; --play sound#
constant LISY_S_STOP_SOUND     : integer := 51; --stop all sounds ( same as play sound 0 )
constant LISY_S_PLAY_FILE      : integer := 52; --play a file (in ./hardware_sounds) - option(1byte) + string 'filename'
constant LISY_S_TEXT_TO_SPEECH : integer := 53; --say the text - option(1byte) + string 'text'
constant LISY_S_SET_VOLUME     : integer := 54; --sound volume in percent

--special rules
constant LISY_S_SET_HWRULE     : integer := 16#3C#; --Configure Hardware Rule for Solenoid

--read/write APC settings
constant LISY_G_APC_SETTING     : integer := 16#40#; --get APC settings - parameter 1 below - parameter 2 is setting# - return byte is value
constant LISY_S_APC_SETTING     : integer := 16#41#; --set APC settings - parameter 1 below - parameter 2 is setting# - parameter 3 (byte) is value
--parameter 1 for APC settings
constant LISY_APC_SYSTEM_SETTING  : integer := 0;
constant LISY_APC_GAME_SETTING    : integer := 1;

--general, parameter none
constant LISY_INIT             : integer := 100; --init/reset LISY - return byte 0=OK, >0 Errornumber Errornumbers TBD
constant LISY_WATCHDOG         : integer := 101; --watchdog - return byte 0=OK, >0 Errornumber Errornumbers TBD
constant LISY_BACK_WHEN_READY  : integer := 102; --get back when ready, call blocks until answer received - if Arduino needs more time (e.g. for sound) - return byte 0=OK(continue), >0 Errornumber Errornumbers TBD

  
signal uart_data_tx : std_logic_vector (7 downto 0);   
signal uart_data_rx : std_logic_vector (7 downto 0);   
 
type STATE_T is ( get_opcode, get_parameter, Execute_op_code, Execute_parameter,
						wait_finish_rx, Send_byte, Check_byte, check_char, send_char, send_string,
						Finish_byte, Finish_char); 
signal state : STATE_T;        --State
  
signal string_to_send : string (1 to 12);
signal string_length : integer range 0 to 15;
signal tx_index : integer range 0 to 15 := 0;


signal r_TX_DV : std_logic := '0';
signal r_TX_ACTIVE : std_logic;
signal uart_rx_flag : std_logic;
signal op_code     : integer range 0 to 255; -- current opcode
signal parameter     : integer range 0 to 255; -- current parameter

begin


UART_TX_INST : entity work.uart_tx 
--  generic map (
--    g_CLKS_PER_BIT => c_CLKS_PER_BIT 434 for 50MHz default
--      )
    port map (
      i_clk       => clk,
      i_tx_dv     => r_TX_DV,
      i_tx_byte   => uart_data_tx,
      o_tx_active => r_TX_ACTIVE,
      o_tx_serial => txd,
      o_tx_done   => open
      );


UART_RX_INST : entity work.uart_rx
    port map (
      i_clk       => clk,
      i_rx_serial => rxd,
      o_rx_dv     => uart_rx_flag,
      o_rx_byte   => uart_data_rx
      );

lisy_api : process (clk, rst, uart_rx_flag) is
  
begin
  if rst = '0' then --Reset condidition (reset_l)
	 r_TX_DV <= '0';
    state <= get_opcode;    
  elsif rising_edge(clk)then
    case state is
	   when get_opcode => 
        if uart_rx_flag = '1' then -- rx flag is true, start decoding
			 op_code <= to_integer(unsigned(uart_data_rx)); -- Load the op-code						 
			 -- new state
          state <= Execute_op_code;
        end if;		    

  	   when wait_finish_rx => 
        if uart_rx_flag = '0' then -- wait for reset flag
			state <= get_parameter;
		  end if;
		  		  
  	   when get_parameter => 
        if uart_rx_flag = '1' then -- rx flag is true, start decoding
			 parameter <= to_integer(unsigned(uart_data_rx)); -- Load the parameter for this op_code					 
			 -- new state
          state <= Execute_parameter;
        end if;		    

		  
		when Execute_op_code =>   
			case op_code is
				when LISY_G_HW =>
					string_to_send(1 to LISY_API_HW'length) <= LISY_API_HW;
					string_length <= LISY_API_HW'length;
					tx_index <= 0;
					state <= Send_string;
				when LISY_G_LISY_VER =>
					string_to_send(1 to LISY_API_LISY_VER'length) <= LISY_API_LISY_VER;
					string_length <= LISY_API_LISY_VER'length;
					tx_index <= 0;
					state <= Send_string;
				when LISY_G_API_VER =>
					string_to_send(1 to LISY_API_VER'length) <= LISY_API_VER;
					string_length <= LISY_API_VER'length;
					tx_index <= 0;
					state <= Send_string;														
				when LISY_G_NO_LAMPS =>
					uart_data_tx <= std_logic_vector(to_unsigned(LISY_API_NO_LAMPS, uart_data_tx'length));					
					state <= Send_byte;
				when LISY_G_NO_SOL =>
					uart_data_tx <= std_logic_vector(to_unsigned(LISY_API_NO_SOL, uart_data_tx'length));					
					state <= Send_byte;
				when LISY_G_NO_SOUNDS =>
					uart_data_tx <= std_logic_vector(to_unsigned(LISY_API_NO_SOUNDS, uart_data_tx'length));					
					state <= Send_byte;
				when LISY_G_NO_DISP =>
					uart_data_tx <= std_logic_vector(to_unsigned(LISY_API_NO_DISP, uart_data_tx'length));					
					state <= Send_byte;
				--TBD RTH LISY_G_DISP_DETAIL/LISY_API_DISP_DETAIL
				when LISY_G_GAME_INFO =>
					uart_data_tx <= std_logic_vector(to_unsigned(LISY_API_GAME_INFO, uart_data_tx'length));					
					state <= Send_byte;
				when LISY_G_NO_SW =>
					uart_data_tx <= std_logic_vector(to_unsigned(LISY_API_NO_SW, uart_data_tx'length));					
					state <= Send_byte;
				when LISY_G_NO_MOD_LIGHTS =>
					uart_data_tx <= std_logic_vector(to_unsigned(LISY_API_NO_MOD_LIGHTS, uart_data_tx'length));					
					state <= Send_byte;
					
				when LISY_G_STAT_SW =>					
					state <= wait_finish_rx;									
					
				when LISY_INIT =>
					uart_data_tx <= "00000000";
					state <= Send_byte;
										
				when others => 	-- send '0'
					uart_data_tx <= "00000000"; --std_logic_vector(to_unsigned(0, uart_data_tx'length));					
					state <= Send_byte;
			end case;

		when Execute_parameter =>   
			case op_code is
				when LISY_G_STAT_SW => --RTH todo: send real state
					uart_data_tx <= "00000000";
					state <= Send_byte;
				
				when others =>
					uart_data_tx <= "00000000";
					state <= Send_byte;
				
			end case;	
			
			
			
		when Send_byte =>
        r_tx_DV <= '1';
		  state <= Check_byte;	
		  			
      when Check_byte =>   -- wait for active
        r_tx_DV <= '0';
		  if r_TX_ACTIVE = '1' then
			state <= Finish_byte;	
		  end if;
	
      when Finish_byte =>   -- wait in this state until flag to go down
			if r_TX_ACTIVE = '0' then
				state <= get_opcode;
			end if;
			
		when Send_string =>
		   if tx_index < string_length then			 
			 uart_data_tx <=   std_logic_vector(to_unsigned(character'pos(string_to_send(tx_index + 1)), 8));
		    -- next index
			 tx_index <= tx_index + 1;
			 state <= Send_char;
			else
			 state <= get_opcode;
			end if;

		when Send_char =>
        r_tx_DV <= '1';
		  state <= Check_char;	

      when Check_char =>   -- wait for active
        r_tx_DV <= '0';
		  if r_TX_ACTIVE = '1' then
			state <= Finish_char;	 -- next char
		  end if;

      when Finish_char =>   -- wait in this state until flag to go down
			if r_TX_ACTIVE = '0' then
				state <= Send_string;
			end if;
	  
      end case;
  end if;
end process;
end architecture;

