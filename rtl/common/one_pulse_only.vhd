-- one_pulse_only
-- gives a short low impuls on sig_out when sig_in goes to low
-- ( 50MHz input clock)

LIBRARY ieee;
USE ieee.std_logic_1164.all;

    entity one_pulse_only is        
        port(
            sig_in  : in std_logic;                
            sig_out : out std_logic;
				clk_in  : in std_logic;               
				rst		: in std_logic               
				
            );
    end one_pulse_only;
    ---------------------------------------------------
    architecture Behavioral of one_pulse_only is
		type STATE_T is ( Idle, Pulse, Do_Wait); 
		signal state_A : STATE_T;       
		signal count : integer range 0 to 100000 := 0;
	begin
	
	 one_pulse_only: process (clk_in, rst)
    begin
			if rst = '0' then --Reset condidition (reset_l)    
				sig_out <= '1';
				count <= 0;
				state_A <= Idle;    
			elsif rising_edge(clk_in) then
				case state_A is
				when Idle =>
					if sig_in = '0' then 						
						sig_out <= '0';
						state_A <= Pulse;
					end if;	
				
				when Pulse =>						
						if count < 40 then
							count <= count +1;
						else
							count <= 0;
							sig_out <= '1';
							state_A <= Do_Wait;
						end if;	
				
				when Do_Wait =>
						if count < 100000 then
							count <= count +1;
						else
							count <= 0;
							state_A <= Idle;
						end if;	
					
				end case;	
			end if; --rising edge		
		end process;
    end Behavioral;