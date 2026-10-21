-- BallyFA_HW2.vhd - board shell for the BallyFA base board HW 2.x
--
-- 'BallyFa' a Bally MPU on a low cost FPGA
-- Ralf Thelen 'bontango' 04.2020
-- www.lisy.dev
--
-- TOP_LEVEL_ENTITY of every hw2_* variant (variants/hw2_*/variant.psd1, TopEntity).
-- It declares exactly the ports this base board has and instantiates the common
-- core top/Bally_core.vhd. Compared with HW 1.x (top/BallyFA_HW1.vhd):
--
--   * 4049 inverters (IC7, IC8, IC9) in front of CV_CH, ZERO_CROSS, S33, U10_PB,
--     U10_CA1 and U11_CB1. They are inverted back here, so the core sees HW 1.x
--     polarity. Before the common tree every use of these inputs in Bally.vhd
--     carried a "not" - all of them, so inverting once at the input is the same logic.
--   * LED_SD_ERR / LED_Bally moved to the former LED_1 / LED_2 pins (PIN7 / PIN9
--     on the Cyclone II board); LED_1 / LED_2 do not exist.
--   * The former LED_Bally / LED_SD_ERR pins carry the CH340 USB serial line,
--     driven by lisy_api (USB MPF beta). lisy_api only needs clk_50 and reset_l,
--     which are ports here, so it lives in this shell and the core stays the same
--     for both base boards. Its node name lisy_api:mpf is unchanged.
--
-- The instance name "core" is part of every node name below it - rtl/common/Bally.sdc
-- refers to Bally_core:core|... and HW1 uses the same name.

library ieee;
use ieee.std_logic_1164.all;

entity BallyFA_HW2 is
	port(
	   -- the FPGA board
		clk_50	: in std_logic; 	-- PIN17
		reset_l  : in std_logic; 	-- PIN144 --goes Low on reset(push)
		LED_0 	: out STD_LOGIC;	-- PIN3
		LED_SD_ERR 	: out STD_LOGIC;  -- PIN7
		LED_Bally 	: out STD_LOGIC;	-- PIN9

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
		USB_Rx			: 	buffer 	std_logic;
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

-- inputs after undoing the 4049 inversion (HW 1.x polarity)
signal cv_ch_i			:	std_logic_vector(1 to 6);
signal zero_cross_i	:	std_logic;
signal s33_i			:	std_logic;
signal u10_pb_i		:	std_logic_vector(7 downto 0);
signal u10_ca1_i		:	std_logic;
signal u11_cb1_i		:	std_logic;

begin

cv_ch_i			<= not CV_CH;
zero_cross_i	<= not ZERO_CROSS;
s33_i				<= not S33;
u10_pb_i			<= not U10_PB;
u10_ca1_i		<= not U10_CA1;
u11_cb1_i		<= not U11_CB1;

core: entity work.Bally_core
generic map(
	HW_DIGIT => x"2"	-- HW 2.x: leading "2" on the display
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
	CV_CH				=> cv_ch_i,
	CV_COIN_LOCK	=> CV_COIN_LOCK,
	ZERO_CROSS		=> zero_cross_i,
	DISP_LA_STR		=> DISP_LA_STR,
	DISP_BLANKING	=> DISP_BLANKING,
	S33				=> s33_i,
	U10_PA			=> U10_PA,
	U10_PB			=> u10_pb_i,
	U10_CA1			=> u10_ca1_i,
	U10_CB2			=> U10_CB2,
	U11_PA			=> U11_PA,
	U11_PB			=> U11_PB,
	U11_CA2			=> U11_CA2,
	U11_CB1			=> u11_cb1_i,
	U11_CB2			=> U11_CB2
);

--lisy api
mpf: entity work.lisy_api
port map(
	clk => clk_50,
	rst => reset_l,
	txd => USB_Rx,
	rxd => USB_Tx
);

end rtl;
