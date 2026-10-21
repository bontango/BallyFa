-- signal delay
-- delays sig_in 
-- cpu clk, 1 clock is 2uS

LIBRARY ieee;
USE ieee.std_logic_1164.all;

    entity signal_delay is        
        port(
                sig_in  : in std_logic;                
                sig_out : out std_logic;
					 clk_in  : in std_logic               
				
            );
    end signal_delay;
	 
	 architecture Behavioral of signal_delay is
	 constant DELAY    : positive := 800;  -- fix 1,6mS Delay
	 signal delay_line : std_logic_vector(DELAY-1 downto 0);
	 begin
		process(clk_in)
		begin
			if rising_edge(clk_in) then
				delay_line <= delay_line(DELAY-2 downto 0) & sig_in;
			end if;
		end process;

	sig_out <= delay_line(DELAY-1);
end Behavioral;