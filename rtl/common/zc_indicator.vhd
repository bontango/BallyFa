--
-- zero cross indicator
-- uses display clock to scan zero cross
-- will set indicator to high if two edges or more missing
-- will set back to low if czeo cross is restored
-- scan clock is cpu clock -> 500KHz
-- part of BallyFA
-- bontango 07.2020
-- v0.2 adjusted to MPU-133 to prevent blinking LED

LIBRARY ieee;
USE ieee.std_logic_1164.all;

	entity zc_indicator is
		port(
					 scan_clock  : in std_logic;                
                zc_in  : in std_logic;                
                zc_flag : out std_logic := '0'
            );
    end zc_indicator;
	 
   architecture Behavioral of zc_indicator is
	   
    begin
		
		zc_indicator: process (scan_clock, zc_in)
			variable q_ZeroCross_Count : integer range 0 to 32000 := 0;
			variable q_Clock_Count : integer range 0 to 32000 := 0;

			begin
				if rising_edge(scan_clock) then
				
					q_Clock_Count := q_Clock_Count +1; -- count scans 
					if zc_in = '1' then
						q_ZeroCross_Count := q_ZeroCross_Count +1; -- count it
					end if;
										
					-- check status of ZeroCrosscount after 11000 scans 
					if q_Clock_Count > 11000 then					
						-- if q_ZeroCross_Count > 7000 or q_ZeroCross_Count = 0 then -- ZC stuck to '1'
						if q_ZeroCross_Count > 10500 or q_ZeroCross_Count < 500 then -- ZC stuck to '1'
						   zc_flag <= '1'; -- -- ZC stuck to '1' or '0'							
						else
							zc_flag <= '0'; -- clock OK or restored, indicator is 0
						end if;		
						q_Clock_Count := 0; -- reset clock counter
						q_ZeroCross_Count := 0; -- reset zero cross counter
					end if;
				end if;	
				

			end process;
    end Behavioral;				


    