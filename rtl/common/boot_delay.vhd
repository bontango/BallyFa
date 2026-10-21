-- control output for first  5ms to low
-- for 5mS ( 50MHz input clock)

LIBRARY ieee;
USE ieee.std_logic_1164.all;

    entity boot_delay is        
        port(
                sig1_out : out std_logic_vector(7 downto 0);
					 sig2_out : out std_logic;
					 clk_in  : in std_logic               
				
            );
    end boot_delay;
    ---------------------------------------------------
    architecture Behavioral of boot_delay is
		signal count : integer range 0 to 500000 := 0;		
    begin
	  boot_delay: process (clk_in)
	  begin
			if rising_edge(clk_in) then	 
							if count < 500000 then
									count <= count + 1;
									sig1_out <= "00000000";
									sig2_out <= '0';
							else	
								sig1_out <= "11111111";
								sig2_out <= '1';
							end if;	
					end if;	
        end process;        
    end Behavioral;