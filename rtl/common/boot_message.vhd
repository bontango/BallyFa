-- boot message on bally display
-- part of  BallyFA
-- bontango 10.2020
--
-- v 1.0
-- 500KHz input clock
-- v1.1 init integer digit to 1

LIBRARY ieee;
USE ieee.std_logic_1164.all;

package instruction_buffer_type is
	type DISPLAY_T is array (0 to 6) of std_logic_vector(3 downto 0);
end package instruction_buffer_type;

LIBRARY ieee;
USE ieee.std_logic_1164.all;

use work.instruction_buffer_type.all;

    entity boot_message is        
        port(
            clk_in  : in std_logic;               						
			   show		: in std_logic;        
				--output (display control)
				latch_strobe	: out std_logic_vector(4 downto 0);
				digit_enable	: out std_logic_vector(6 downto 0);
				bcd_data			: out std_logic_vector(3 downto 0);
				blanking			: out std_logic;					   
				-- input (display data)
			   display1			: in  DISPLAY_T;
				display2			: in  DISPLAY_T;
				display3			: in  DISPLAY_T;
				display4			: in  DISPLAY_T;
				status_d			: in  DISPLAY_T
            );
    end boot_message;
    ---------------------------------------------------
    architecture Behavioral of boot_message is
	 	type STATE_T is ( Idle, Pulse, Do_Wait); 
		signal state : STATE_T;       		
		signal digit : integer range 0 to 7 := 1;
		signal count : integer range 0 to 2000 := 0;
	begin
	
	 boot_message: process (clk_in, show)
    begin
			if show = '0' then --Reset condidition (reset_l)    
				blanking <= '1';
				latch_strobe <= "00000";
				digit_enable <= "0000000";
				bcd_data <= "0000";
				digit <= 1;
				count <= 0;
			elsif rising_edge(clk_in) then
				-- inc count for next round
				count <= count +1;
				case count is 				--500KHz input we have a clk each 2us
				when 0 => 					-- start refresh cycle
					-- Blank out all the displays
					blanking <= '1';
					latch_strobe <= "00000";
					digit_enable <= "0000000";
					bcd_data <= "0000";
							
				-- send BCD data to display driver by assigning data
				-- and toggle latch strobes
				when 10 =>
					bcd_data <= display1(digit);
					latch_strobe(0) <='1';
				when 20 =>					
					latch_strobe(0) <='0';

				when 30 =>
					bcd_data <= display2(digit);
					latch_strobe(1) <='1';
				when 40 =>					
					latch_strobe(1) <='0';
					
				when 50 =>
					bcd_data <= display3(digit);
					latch_strobe(2) <='1';
				when 60 =>					
					latch_strobe(2) <='0';
								
				when 70 =>
					bcd_data <= display4(digit);
					latch_strobe(3) <='1';
				when 80 =>					
					latch_strobe(3) <='0';
					
				when 90 =>
					bcd_data <= status_d(digit);
					latch_strobe(4) <='1';					
				when 100 =>					
					latch_strobe(4) <='0';
					
				--	activate digit
				when 105 =>					
					digit_enable(digit) <= '1';					
									
			-- all loaded now deactivate blanking	
			-- and prepare for next digit
				when 110 =>					
					blanking <='0';						
					digit <= digit +1;
				
				-- after 3ms look for next digit	
				--check for overflow
				when 1500 =>	
					count <= 0;			
					if digit > 6 then
						digit <= 1;
					end if;
					
				when OTHERS =>
				end case;
			end if; --rising edge		
		end process;
    end Behavioral;