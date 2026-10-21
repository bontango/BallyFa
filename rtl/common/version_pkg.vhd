-- version_pkg.vhd - the software version, shared by all BallyFA variants.
--
-- The version shown on display 1 during boot is
--
--     [HW_DIGIT] BOARD_ID . SW_SUB1 SW_SUB2        e.g.  3.23  or  2 3.23
--
-- HW_DIGIT comes from the board shell (top/BallyFA_HW1.vhd: blank, top/BallyFA_HW2.vhd: 2),
-- BOARD_ID from variants/<name>/variant_pkg.vhd (1 Cyclone II, 2 Cyclone IV,
-- 3 Cyclone IV v4.x, 4 Cyclone 10). A release changes ONE digit here and all eight
-- boards follow. Before the common source tree these digits were typed into eight
-- copies of Bally.vhd.
library ieee;
use ieee.std_logic_1164.all;

package version_pkg is
	constant SW_SUB1 : std_logic_vector(3 downto 0) := x"2";
	constant SW_SUB2 : std_logic_vector(3 downto 0) := x"3";
end package version_pkg;
