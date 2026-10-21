--
-- generate 500KHz clock for Bally CPU from 50Mhz system clock
--

LIBRARY ieee;
USE ieee.std_logic_1164.all;

	entity cpu_clk_gen is
		port(
                clk_in  : in std_logic;                
                clk_out : out std_logic
            );
    end cpu_clk_gen;
	 
   architecture Behavioral of cpu_clk_gen is
	   signal q_cpuClkCount : integer range 0 to 160;
		--signal q_cpuClkCount	: std_logic_vector(6 downto 0); 
    begin
		cpu_clk_gen: process (clk_in)
			begin
				if rising_edge(clk_in) then
					if q_cpuClkCount < 100 then		-- 4 = 10MHz, 3 = 12.5MHz, 2=16.6MHz, 1=25MHz
						q_cpuClkCount <= q_cpuClkCount + 1;
					else
						q_cpuClkCount <= 0;
					end if;
					if q_cpuClkCount < 50 then		-- 2 when 10MHz, 2 when 12.5MHz, 2 when 16.6MHz, 1 when 25MHz
						clk_out <= '0';
					else
						clk_out <= '1';
					end if;
				end if;
			end process;
    end Behavioral;				

-- CPU Clock

-- CPU frequency 	Counter top 	Counter half-way
-- 400KHz 125 72
-- 532Khz 93 47 
--1MHz 	49 25 

    