# files_hw2.tcl - was nur die Basisplatine HW 2.x braucht (Option hw2 in variant.psd1).
#
# Die Platinenhuelle plus lisy_api (USB MPF beta, CH340) mit seinen beiden UARTs.
# HW 1.x hat keinen USB-Anschluss und hat diese Dateien nie gebaut.

set_global_assignment -name VHDL_FILE ../../rtl/common/uart_tx.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/uart_rx.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/lisy_api.vhd
set_global_assignment -name VHDL_FILE ../../top/BallyFA_HW2.vhd
