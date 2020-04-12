-- Original file is copyright by Grant Searle 2014
-- Grant Searle's web site http://searle.hostei.com/grant/    
-- Grant Searle's "multicomp" page at http://searle.hostei.com/grant/Multicomp/index.html
--
-- Changes to this code by Doug Gilliland 2020
-- https://github.com/douggilliland/MultiComp/tree/master/MultiComp_On_EP2C5/M6800_MIKBUG_ExtSRAM
--
--
-- 'BallyFa' a Bally MPU on a low cost FPGA
-- Ralf Thelen 'bontango' 04.2020
--
-- initial version 0.1
-- functional design only
-- included outputs for debugging via logic analyzer
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;


entity Bally is
	port(
		-- debugging output
		my_addr	:	out 	std_logic_vector(14 downto 0);
		my_data	:	out 	std_logic_vector(7 downto 0);
		my_debug_1 	: out STD_LOGIC;
		my_debug_2 	: out STD_LOGIC;
		my_debug_3 	: out STD_LOGIC;
		my_debug_4 	: out STD_LOGIC;
		my_debug_5 	: out STD_LOGIC;
		my_debug_6 	: out STD_LOGIC;
		my_debug_7 	: out STD_LOGIC;
		my_debug_8 	: out STD_LOGIC;		
		my_debug_cl 	: out STD_LOGIC;	
		my_debug_phi 	: out STD_LOGIC;	
		my_debug_res 	: out STD_LOGIC;	
		
	   -- the FPGA board
		clk_50	: in std_logic;
		i_n_reset: in std_logic;
		LED_0 	: out STD_LOGIC;						
		LED_1 	: out STD_LOGIC;
		LED_2 	: out STD_LOGIC;				
		-- switchmatrix 8strobe; 8 returns plus slam (17)
		sw_strobe	:	out 	std_logic_vector(7 downto 0);
		sw_return	:	in 	std_logic_vector(7 downto 0)

		);
end;

architecture rtl of Bally is 

signal cpu_clk		: std_logic; -- have to be a 532KHz kHz CPU clock
signal reset_l		: 	std_logic;
signal reset_h		: 	std_logic;


signal cpu_addr	: 	std_logic_vector(15 downto 0);
signal cpu_din		: 	std_logic_vector(7 downto 0) := x"FF";
signal cpu_dout	: 	std_logic_vector(7 downto 0);
signal cpu_rw		: 	std_logic;
signal cpu_vma		: 	std_logic;  --valid memory address
signal cpu_irq		: 	std_logic;
signal cpu_nmi		:	std_logic;

signal rom_U2_dout	:	std_logic_vector(7 downto 0);
signal rom_U2_cs		: 	std_logic;

signal rom_U6_dout	:	std_logic_vector(7 downto 0);
signal rom_U6_cs		: 	std_logic;

signal ram_U7_dout	: 	std_logic_vector(7 downto 0);
signal ram_U7_cs		:	std_logic;

signal ram_U8_dout	: 	std_logic_vector(3 downto 0);
signal ram_U8_cs		:	std_logic;

--signal pia_U10_pa_i	:  std_logic_vector(7 downto 0) := x"FF";
signal pia_U10_pa_o	: 	std_logic_vector(7 downto 0);
--signal pia_U10_pb_i	:	std_logic_vector(7 downto 0) := x"FF";
--signal pia_U10_pb_o	:  std_logic_vector(7 downto 0);
signal pia_U10_dout	:	std_logic_vector(7 downto 0);
signal pia_U10_irq_a	:	std_logic;
signal pia_U10_irq_b	:	std_logic;
-- signal pia_U10_cb1	:  std_logic;
signal pia_U10_cs		:	std_logic;

--signal pia_U11_pa_i	:  std_logic_vector(7 downto 0) := x"FF";
--signal pia_U11_pa_o	: 	std_logic_vector(7 downto 0);
--signal pia_U11_pb_i	:	std_logic_vector(7 downto 0) := x"FF";
--signal pia_U11_pb_o	:  std_logic_vector(7 downto 0);
signal pia_U11_dout	:	std_logic_vector(7 downto 0);
signal pia_U11_irq_a	:	std_logic;
signal pia_U11_irq_b	:	std_logic;
signal pia_U11_ca2_o :  std_logic;
--signal pia_U11_cb1	:  std_logic;
signal pia_U11_cs		:	std_logic;

begin
reset_h <= (not reset_l);

-- Debounce the reset line
	DebounceResetSwitch	: entity work.Debounce
	port map (
		clk	=> clk_50,
		x 		=> i_n_reset,
		DBx	=> reset_l
	);
	

-- Debug
my_debug_res <= pia_U11_ca2_o;
my_addr <= cpu_addr(14 downto 0);
my_data <= cpu_din when cpu_rw = '1'  else cpu_dout;
my_debug_1 <=	pia_U10_cs;
my_debug_2 <=	pia_U11_cs;
my_debug_3 <=	ram_U7_cs;
my_debug_4 <=	ram_U8_cs;
my_debug_5 <= rom_U2_cs;
my_debug_6 <= rom_U6_cs;
my_debug_7 <=	cpu_rw;
my_debug_8 <= cpu_irq;
--my_debug_cl <= cpu_vma;
--my_debug_phi <= cpu_clk;

-- LEDs
LED_0 <= '0'; --ON
LED_1 <= reset_l; -- reset
LED_2 <= not pia_U11_ca2_o; -- Bally Green LED

-- PIA port IO mapping
sw_strobe <= pia_U10_pa_o;

-- IRQ signals ( should be '0')
cpu_irq <= pia_U10_irq_a or pia_U10_irq_b or pia_U11_irq_a or pia_U11_irq_b;
cpu_nmi <= '0'; -- will be connected to a switch on the board 'S33'

-- address decoding - westart with a -17 bally MPU which has only 13 Adresslines
-- need to be adapted to -35 Bally and Stern!
--
-- U7 Memory 6810 (128 x 8 Zero-Page) 0x0000 - 0x007F
ram_U7_cs    <= '1' when cpu_addr(12 downto 7) = "000000" and cpu_vma='1' else '0';
-- PIA U10 0x0088 - 0x008F
pia_U10_cs   <= '1' when cpu_addr(12 downto 3) = "00000010001" and cpu_vma='1' else '0';
-- PIA U10 0x0090 - 0x0097
pia_U11_cs   <= '1' when cpu_addr(12 downto 3) = "00000010010" and cpu_vma='1' else '0';
-- U8 Memory 5101 (256 x 4) 0x0100 - 0x01FF
ram_U8_cs    <= '1' when cpu_addr(12 downto 8) = "00010" and cpu_vma='1' else '0';
-- U2 ROM 0x5000 - 0x57FF - 1x10
rom_U2_cs <= cpu_addr(12) and not cpu_addr(11) and cpu_vma;
-- U6 ROM 0x5800 - 0x5FFF - 1x11
rom_U6_cs <= cpu_addr(12) and cpu_addr(11) and cpu_vma;


-- Bus control
 cpu_din <= 
   pia_U10_dout when pia_U10_cs = '1' else
	pia_U11_dout when pia_U11_cs = '1' else
	rom_U2_dout when rom_U2_cs = '1' else
	rom_U6_dout when rom_U6_cs = '1' else
	ram_U7_dout when ram_U7_cs = '1' else
	"1111" & ram_U8_dout when ram_U8_cs = '1' else
	x"FF";


U2: entity work.U2_ROM
port map(
	address => cpu_addr(10 downto 0),
	clock => clk_50,
	q	=> rom_U2_dout
	);

U6: entity work.U6_ROM
port map(
	address => cpu_addr(10 downto 0),
	clock => clk_50,
	q	=> rom_U6_dout
	);

U7: entity work.M6810 -- 56810 Ram 128Byte (128*8bit)
port map(
	address	=> cpu_addr(7 DOWNTO 0),
	clock		=> clk_50, 
	data		=>  cpu_dout (7 DOWNTO 0),
	wren 		=> ram_U7_cs and not cpu_rw and not cpu_clk,
	q			=> ram_U7_dout
);	

U8: entity work.SM5101 -- 5101 RAM 128Byte (256*4bit) RTH: test only need to be buffered!
port map(
	address	=> cpu_addr(7 downto 0),
	clock		=> clk_50, 
	data		=>  cpu_dout (3 DOWNTO 0),
	wren 		=> ram_U8_cs and not cpu_rw and not cpu_clk,
	q			=> ram_U8_dout
);	

U9: entity work.cpu68
port map(
	clk => cpu_clk,
	rst => reset_h,
	rw => cpu_rw,
	vma => cpu_vma,
	address => cpu_addr,
	data_in => cpu_din,
	data_out => cpu_dout,
	hold => '0',
	halt => '0',
	irq => cpu_irq,
	nmi => cpu_nmi
);

U10: entity work.PIA6821
port map(
	clk => cpu_clk,   
   rst => reset_h,     
   cs => pia_U10_cs,     
   rw => cpu_rw,    
   addr => cpu_addr(1 downto 0),     
   data_in => cpu_dout,  
	data_out => pia_U10_dout, 
	irqa => pia_U10_irq_a,   
	irqb => pia_U10_irq_b,    
	pa_i => x"FF",    
	pa_o => pia_U10_pa_o,    
	ca1 => '1',
	ca2_i => '1',    
	ca2_o => open,    
	pb_i => x"FF",    
	pb_o => open,    
	cb1 => '0',    
	cb2_i => '0',  
	cb2_o => open   
);

U11: entity work.PIA6821
port map(
	clk => cpu_clk,   
   rst => reset_h,     
   cs => pia_U11_cs,     
   rw => cpu_rw,    
   addr => cpu_addr(1 downto 0),     
   data_in => cpu_dout,  
	data_out => pia_U11_dout, 
	irqa => pia_U11_irq_a,   
	irqb => pia_U11_irq_b,    
	pa_i => x"FF",    
	pa_o => open,    
	ca1 => '1',
	ca2_i => '1',    
	ca2_o => pia_U11_ca2_o,    
	pb_i => x"FF",    
	pb_o => open,    
	cb1 => '0',    
	cb2_i => '0',  
	cb2_o => open   
);
	 
-- cpu clock 532Khz
clock_gen: entity work.cpu_clk_gen 
port map(   
	clk_in => clk_50,
	clk_out	=> cpu_clk
);

-- CPU Clock
--cpu_clk_gen: process (clk_50)
	--begin
		--if rising_edge(clk_50) then
			--if q_cpuClkCount < 93 then		-- 4 = 10MHz, 3 = 12.5MHz, 2=16.6MHz, 1=25MHz
				--q_cpuClkCount <= q_cpuClkCount + 1;
		--	else
			--	q_cpuClkCount <= (others=>'0');
			--end if;
			--if q_cpuClkCount < 47 then		-- 2 when 10MHz, 2 when 12.5MHz, 2 when 16.6MHz, 1 when 25MHz
				--cpu_clk <= '0';
			--else
				--cpu_clk <= '1';
			--end if;
		--end if;
	--end process;

-- CPU frequency 	Counter top 	Counter half-way
-- 532Khz if cpuClkCount < 93 then 	if cpuClkCount < 47 then
--1MHz 	if cpuClkCount < 49 then 	if cpuClkCount < 25 then
--2MHz 	if cpuClkCount < 24 then 	if cpuClkCount < 12 then
--5MHz 	if cpuClkCount < 9 then 	if cpuClkCount < 4 then
--10MHz 	if cpuClkCount < 4 then 	if cpuClkCount < 2 then
--12.5MHz 	if cpuClkCount < 3 then 	if cpuClkCount < 2 then
--16.6MHz 	if cpuClkCount < 2 then 	if cpuClkCount < 2 then
--25MHz 	if cpuClkCount < 1 then 	if cpuClkCount < 1 then	

	
end rtl;


		