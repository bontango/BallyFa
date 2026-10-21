-- variant_pkg.vhd - was dieses Board ist, als VHDL-Konstante.
-- Variante: hw1_cyclone_iv_v4 (BallyFA HW 1.x mit dem Cyclone IV v4.x Board (EP4CE6E22C8N))
--
-- Diese Datei liegt im Variantenordner, nicht in rtl/common/, und ist der ERSTE
-- Eintrag der erzeugten .qsf. Alles uebrige am Design ist gemeinsam.
library ieee;
use ieee.std_logic_1164.all;

package variant_pkg is
	-- Ziffer des FPGA-Boards in der Boot-Anzeige ([HW_DIGIT] BOARD_ID . SW_SUB1 SW_SUB2,
	-- siehe rtl/common/version_pkg.vhd): 1 Cyclone II, 2 Cyclone IV, 3 Cyclone IV v4.x, 4 Cyclone 10.
	-- Dieselbe Ziffer steht im Releasenamen BallyFA_3xx.jic.
	constant BOARD_ID : std_logic_vector(3 downto 0) := x"3";
end package variant_pkg;
