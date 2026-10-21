-- BallyFA_HW2.vhd - board shell for the BallyFA base board HW 2.x on Cyclone IV / Cyclone 10
--
-- 'BallyFa' a Bally MPU on a low cost FPGA
-- Ralf Thelen 'bontango' 04.2020
-- www.lisy.dev
--
-- TOP_LEVEL_ENTITY of hw2_cyclone_iv, hw2_cyclone_iv_v4 and hw2_cyclone_10
-- (variants/<n>/variant.psd1, TopEntity). The shell only declares the ports this board
-- has and passes them to the common core top/Bally_core.vhd - all logic is in the core
-- (HW_GEN => 2: 4049 inversion of six inputs, USB via lisy_api). Compared with HW 1.x:
-- LED_SD_ERR / LED_Bally sit on the former LED_1 / LED_2 pins, the former LED_Bally /
-- LED_SD_ERR pins carry USB_Rx / USB_Tx, and LED_1 / LED_2 do not exist.
--
-- Cyclone II uses top/BallyFA_HW2_cii.vhd instead: same ports minus the four FLASH_*
-- pins, which the EP2C5 does not have as user I/O. Keep both port lists in step.
--
-- The instance name "core" is part of every node name below it - rtl/common/Bally.sdc
-- refers to Bally_core:core|... and all four shells use the same name.

library ieee;
use ieee.std_logic_1164.all;
use work.variant_pkg.all;

entity BallyFA_HW2 is
	port(
	   -- the FPGA board
		clk_50	: in std_logic; 	-- PIN17
		reset_l  : in std_logic; 	-- PIN144 --goes Low on reset(push)
		LED_0 	: out STD_LOGIC;	-- PIN3
		LED_SD_ERR 	: out STD_LOGIC;  -- PIN7
		LED_Bally 	: out STD_LOGIC;	-- PIN9

		-- configuration flash (dual purpose pins), see rtl/common/Flash_ROM.vhd
		FLASH_DCLK	: out std_logic;
		FLASH_NCS	: out std_logic;
		FLASH_ASDO	: out std_logic;
		FLASH_DATA0	: in  std_logic;

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
		LED_ZC	   :  out 	std_logic;

		-- USB serial CH340
		USB_Rx			: 	out 	std_logic;
		USB_Tx			: 	in 	std_logic;

		S1_DIPS	:	in 	std_logic_vector(7 downto 0);
		S2_DIPS	:	in 	std_logic_vector(1 to 6);
		-- S2_DIPS(1) - ZC fake (for testing on the bench)
		-- S2_DIPS(2) - testtrigger eeprom
		-- S2_DIPS(3) - NOT used reduce cpu_clock from 500 to 400KHz
		-- S2_DIPS(4) - NOT used delayed zero cross ( anti flicker for LEDs )
		-- S2_DIPS(5) - activate coin validator
		-- S2_DIPS(6) - init nvram/eeprom for this game at start

		CV_CH		:	in 	std_logic_vector(1 to 6); --channels coin validator (4049 IC9)
		CV_COIN_LOCK		:	out 	std_logic;

		ZERO_CROSS	:	in 	std_logic; -- (4049 IC8)
		DISP_LA_STR	:	out 	std_logic_vector(1 to 5);
		DISP_BLANKING	:	out 	std_logic;

		-- U9 NMI CPU 6800 on bally, looks like it is not working for cpu68.vhd
		S33			:	in 	std_logic; -- (4049 IC8)

		-- U10 PIA
		U10_PA		:	out 	std_logic_vector(7 downto 0):= "ZZZZZZZZ";
		U10_PB		:	in 	std_logic_vector(7 downto 0):= "ZZZZZZZZ"; --(4049 IC7 & IC8)
		U10_CA1		:	in 	std_logic; -- (4049 IC8)
		-- U10_CA2		:	out 	std_logic; --display logic internal
		-- U10_CB1	:	in 	std_logic; --  Zero cross intern
		U10_CB2		:	out 	std_logic:= 'Z';

		-- U11 PIA
		U11_PA		:	out 	std_logic_vector(7 downto 1):= "ZZZZZZZ";
		U11_PB		:	buffer 	std_logic_vector(7 downto 0):= "ZZZZ1111";
		-- U11_CA1		:	in 	std_logic; --display int gen
		U11_CA2		:	out 	std_logic:= 'Z';
		U11_CB1		:	in 	std_logic;		-- (4049 IC8)
		U11_CB2		:	out 	std_logic:= '1'

		);
end;

architecture rtl of BallyFA_HW2 is
begin

core: entity work.Bally_core
generic map(
	HW_GEN        => 2,
	HAS_FLASH_ROM => HAS_FLASH_ROM	-- variants/<n>/variant_pkg.vhd
)
port map(
	clk_50			=> clk_50,
	reset_l			=> reset_l,
	LED_0				=> LED_0,
	LED_1				=> open,
	LED_2				=> open,
	FLASH_DCLK		=> FLASH_DCLK,
	FLASH_NCS		=> FLASH_NCS,
	FLASH_ASDO		=> FLASH_ASDO,
	FLASH_DATA0		=> FLASH_DATA0,
	USB_Rx			=> USB_Rx,
	USB_Tx			=> USB_Tx,
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
