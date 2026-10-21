-- byte to decimal
-- converts input byte
-- to 3 digit decimal in BCD decoding
-- ( 50MHz input clock)

LIBRARY ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

    entity byte_to_decimal is        
        port(
            clk_in  : in std_logic;               
				mybyte  : in std_logic_vector(7 downto 0);
				dig0	: out std_logic_vector(3 downto 0);
				dig1	: out std_logic_vector(3 downto 0);
				dig2	: out std_logic_vector(3 downto 0)
            );
    end byte_to_decimal;
    ---------------------------------------------------
    architecture Behavioral of byte_to_decimal is
		type STATE_T is ( INIT, HUND1, HUND2,TEN1, TEN2, ONE1, ONE2); 
		signal state : STATE_T := INIT;     
		signal bytetoconvert : integer range 0 to 255;
		signal hundreds : integer range 0 to 15;
		signal tens : integer range 0 to 15;
		signal ones : integer range 0 to 15;
	begin
	
	 byte_to_decimal: process (clk_in, mybyte)
    begin
			if rising_edge(clk_in) then
				case state is
				when INIT =>
					bytetoconvert <= to_integer(unsigned(not mybyte));
					state <= HUND1;
					
				when HUND1 =>
					hundreds <= bytetoconvert / 100;					
					state <= HUND2;
					
				when HUND2 =>						
					bytetoconvert <= bytetoconvert- ( 100 * hundreds);
					state <= TEN1;
				
				when TEN1 =>
					tens <= bytetoconvert / 10;					
					state <= TEN2;

				when TEN2 =>						
					bytetoconvert <= bytetoconvert- ( 10 * tens);
					state <= ONE1;

				when ONE1 =>
					ones <= bytetoconvert;					
					state <= ONE2;
					
				when ONE2 =>
					dig0 <= std_logic_vector(to_unsigned(ones, dig0'length));
					dig1 <= std_logic_vector(to_unsigned(tens, dig1'length));
					dig2 <= std_logic_vector(to_unsigned(hundreds, dig2'length));									
					state <= INIT;
					
				end case;	
			end if; --rising edge		
		end process;
    end Behavioral;