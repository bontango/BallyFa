-- from https://www.nandland.com/articles/crossing-clock-domains-in-an-fpga.html
-- adapted by bontango

Library IEEE;
USE IEEE.Std_logic_1164.all;

entity Cross_Slow_To_Fast_Clock is 
   port(
      i_D :in  std_logic;    
	  o_Q : out std_logic;    
      i_Fast_Clk :in std_logic      
   );
end Cross_Slow_To_Fast_Clock;
architecture Behavioral of Cross_Slow_To_Fast_Clock is  

	signal r1_Data : std_logic := '0';
	signal r2_Data : std_logic := '0';	
	
begin  
 -- crossing data from slow to fast domain
 process(i_Fast_Clk)
 begin 
    if(rising_edge(i_Fast_Clk)) then
     -- r1_data is METASTABLE, r2_Data is stable
	 r1_Data <= i_D;
	 r2_Data <= r1_Data;
	
	 
	 -- Can use r2_Data now
	 o_Q <= r2_Data;
	 -- This is useful for bringing data into your FPGA from
	 -- external source and removing metastability problems
	 	 	 
  end if;      
 end process;  
end Behavioral; 