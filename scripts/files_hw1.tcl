# files_hw1.tcl - Basisplatine HW 1.x auf Cyclone IV / Cyclone 10 (Option hw1 in variant.psd1).
#
# Nur die Platinenhuelle; die Logik steht im Kern (HW_GEN). TOP_LEVEL_ENTITY BallyFA_HW1
# setzt gen_qsf.ps1 aus variant.psd1 (TopEntity).

set_global_assignment -name VHDL_FILE ../../top/BallyFA_HW1.vhd
