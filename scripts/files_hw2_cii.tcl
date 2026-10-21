# files_hw2_cii.tcl - Basisplatine HW 2.x auf Cyclone II (Option hw2_cii in variant.psd1).
#
# Huelle ohne die FLASH-Pins - das EP2C5 hat DCLK/DATA0 nicht als User-I/O.

set_global_assignment -name VHDL_FILE ../../top/BallyFA_HW2_cii.vhd
