--
-- generate 100 Hz clock for fake zero cross
-- from 500KHz cpu clock 
-- original low pulse is 5000 4650
--

LIBRARY ieee;
USE ieee.std_logic_1164.all;

	entity zc_clk_gen is
		port(
                dclk_in  : in std_logic;                
                dclk_out : out std_logic
            );
    end zc_clk_gen;
	 
   architecture Behavioral of zc_clk_gen is
	   signal q_cpuClkCount : integer range 0 to 5001;
    begin
		zc_clk_gen: process (dclk_in)
			begin
				if rising_edge(dclk_in) then
					if q_cpuClkCount < 5000 then	
						q_cpuClkCount <= q_cpuClkCount + 1;
					else
						q_cpuClkCount <= 0;
					end if;
					if q_cpuClkCount < 4650 then	
						dclk_out <= '0';
					else
						dclk_out <= '1';
					end if;
				end if;
			end process;
    end Behavioral;				

