-- BallyFA_HW1.vhd - board shell for the BallyFA base board HW 1.x
--
-- 'BallyFa' a Bally MPU on a low cost FPGA
-- Ralf Thelen 'bontango' 04.2020
-- www.lisy.dev
--
-- TOP_LEVEL_ENTITY of every hw1_* variant (variants/hw1_*/variant.psd1, TopEntity).
-- It declares exactly the ports this base board has and instantiates the common
-- core top/Bally_core.vhd. What is the same on all boards belongs in the core;
-- this file only holds what makes HW 1.x different from HW 2.x:
--
--   * LED_1 / LED_2 exist only here (PIN7 / PIN9 on the Cyclone II board) and are
--     held at '1', as before.
--   * LED_Bally / LED_SD_ERR sit on the pins HW 2.x uses for USB.
--   * No 4049 inverters on the inputs, so they go to the core unchanged.
--   * No USB / lisy_api.
--
-- Why a shell instead of one top level with VIRTUAL_PIN: the Cyclone II variants are
-- built with Quartus 13.0sp1, where VIRTUAL_PIN has no effect (Warning 292013). An
-- output port without a pin location would then be placed on a real pin and driven.
--
-- The instance name "core" is part of every node name below it - rtl/common/Bally.sdc
-- refers to Bally_core:core|... and HW2 uses the same name.

library ieee;
use ieee.std_logic_1164.all;

entity BallyFA_HW1 is
	port(
	   -- the FPGA board
		clk_50	: in std_logic; 	-- PIN17
		reset_l  : in std_logic; 	-- PIN144 --goes Low on reset(push)
		LED_0 	: out STD_LOGIC;	-- PIN3
		LED_1 	: out STD_LOGIC;  -- PIN7
		LED_2 	: out STD_LOGIC;	-- PIN9

		-- EEProm
		C_EEPROM	:	buffer 	std_logic;
		S_EEPROM	:	buffer 	std_logic;
		Q_EEPROM	:	in 	std_logic;
		D_EEPROM	:	buffer 	std_logic;

		-- SDcard
		SD_CS : buffer 	std_logic;
		SD_MISO : in 	std_logic;
		SD_MOSI : buffer 	std_logic;
		SD_CLK : buffer 	std_logic;

		-- BallayFA Board
		LED_ON   	:  out 	std_logic;
		LED_Bally   :  out 	std_logic;
		LED_ZC	   :  out 	std_logic;
		LED_SD_ERR  :  out 	std_logic;

		S1_DIPS	:	in 	std_logic_vector(7 downto 0);
		S2_DIPS	:	in 	std_logic_vector(1 to 6);
		-- S2_DIPS(1) - ZC fake (for testing on the bench)
		-- S2_DIPS(2) - testtrigger eeprom
		-- S2_DIPS(3) - NOT used reduce cpu_clock from 500 to 400KHz
		-- S2_DIPS(4) - NOT used delayed zero cross ( anti flicker for LEDs )
		-- S2_DIPS(5) - activate coin validator
		-- S2_DIPS(6) - init nvram/eeprom for this game at start

		CV_CH		:	in 	std_logic_vector(1 to 6); --channels coin validator
		CV_COIN_LOCK		:	out 	std_logic;

		ZERO_CROSS	:	in 	std_logic;
		DISP_LA_STR	:	out 	std_logic_vector(1 to 5);
		DISP_BLANKING	:	out 	std_logic;

		-- U9 NMI CPU 6800 on bally, looks like it is not working for cpu68.vhd
		S33			:	in 	std_logic;

		-- U10 PIA
		U10_PA		:	out 	std_logic_vector(7 downto 0):= "ZZZZZZZZ";
		U10_PB		:	in 	std_logic_vector(7 downto 0):= "ZZZZZZZZ";
		U10_CA1		:	in 	std_logic;
		-- U10_CA2		:	out 	std_logic; --display logic internal
		-- U10_CB1	:	in 	std_logic; --  Zero cross intern
		U10_CB2		:	out 	std_logic:= 'Z';

		-- U11 PIA
		U11_PA		:	out 	std_logic_vector(7 downto 1):= "ZZZZZZZ";
		U11_PB		:	buffer 	std_logic_vector(7 downto 0):= "ZZZZ1111";
		-- U11_CA1		:	in 	std_logic; --display int gen
		U11_CA2		:	out 	std_logic:= 'Z';
		U11_CB1		:	in 	std_logic;
		U11_CB2		:	out 	std_logic:= '1'

		);
end;

architecture rtl of BallyFA_HW1 is
begin

LED_1 <= '1';
LED_2 <= '1';

core: entity work.Bally_core
generic map(
	HW_DIGIT => x"F"	-- HW 1.x: no leading digit on the display
)
port map(
	clk_50			=> clk_50,
	reset_l			=> reset_l,
	LED_0				=> LED_0,
	C_EEPROM			=> C_EEPROM,
	S_EEPROM			=> S_EEPROM,
	Q_EEPROM			=> Q_EEPROM,
	D_EEPROM			=> D_EEPROM,
	SD_CS				=> SD_CS,
	SD_MISO			=> SD_MISO,
	SD_MOSI			=> SD_MOSI,
	SD_CLK			=> SD_CLK,
	LED_ON			=> LED_ON,
	LED_Bally		=> LED_Bally,
	LED_ZC			=> LED_ZC,
	LED_SD_ERR		=> LED_SD_ERR,
	S1_DIPS			=> S1_DIPS,
	S2_DIPS			=> S2_DIPS,
	CV_CH				=> CV_CH,
	CV_COIN_LOCK	=> CV_COIN_LOCK,
	ZERO_CROSS		=> ZERO_CROSS,
	DISP_LA_STR		=> DISP_LA_STR,
	DISP_BLANKING	=> DISP_BLANKING,
	S33				=> S33,
	U10_PA			=> U10_PA,
	U10_PB			=> U10_PB,
	U10_CA1			=> U10_CA1,
	U10_CB2			=> U10_CB2,
	U11_PA			=> U11_PA,
	U11_PB			=> U11_PB,
	U11_CA2			=> U11_CA2,
	U11_CB1			=> U11_CB1,
	U11_CB2			=> U11_CB2
);

end rtl;
