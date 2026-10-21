-- coin validator
-- simulates switches from inputs of coin validator
-- Bally version
-- Right chute Switch 9 -> Return 0 - Strobe 1
-- left chute Switch 10 -> Return 1 - Strobe 1
-- middle chute Switch 11 -> Return 2 - Strobe 1
-- bontango 02.10.2020

Library IEEE;
USE IEEE.Std_logic_1164.all;

entity coin_validator is 
   port(
		is_active_l : in std_logic;
		Strobe_1 : in std_logic;
      Return_0 :out  std_logic;    
		Return_1 :out  std_logic;    
		Return_2 :out  std_logic;    	   
		channel_1 : in std_logic;
		channel_2 : in std_logic;
		channel_3 : in std_logic  
   );
end coin_validator;
architecture Behavioral of coin_validator is  
	
begin  
 
 process(Strobe_1)
 begin 
    if( Strobe_1 = '1' and (is_active_l = '0')) then
     -- Return is equal to coin validator only when strobe 1 is high 
	  -- and if is_active_l is low (dip switch)
		Return_0 <= Channel_1;
		Return_1 <= Channel_2;
		Return_2 <= Channel_3;
	else	
	 	Return_0 <= '0';
		Return_1 <= '0';
		Return_2 <= '0';
  end if;      
 end process;  
end Behavioral; 