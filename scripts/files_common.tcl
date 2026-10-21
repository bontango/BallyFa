# files_common.tcl - die Quellen, die JEDE BallyFA-Variante baut.
# Wird von scripts\gen_qsf.ps1 in variants\<n>\Bally.qsf eingesetzt.
#
# ALLE Pfade sind relativ zum QUARTUS-PROJEKTVERZEICHNIS, und das ist variants\<n>\ -
# daher ../../. Derselbe Bezug gilt fuer init_file in rtl/<familie>/U2andU6.vhd
# (../../rom/elektra.hex). Ausnahme: die .qip benutzen $::quartus(qip_path) und sind
# ortsunabhaengig - die nicht anfassen.
#
# Kein SEARCH_PATH. Jede Datei steht genau einmal explizit in einer Liste; nur so kann
# eine neue .vhd nicht in einer von acht Varianten fehlen - und genau das war der Grund
# fuer den Umbau.
#
# Packages zuerst: variant_pkg liefert BOARD_ID, version_pkg die Softwareziffern.
# variant_pkg.vhd steht ohne Pfad, weil es IM Projektverzeichnis liegt.
#
# lisy_api (nur HW 2.x) steht trotzdem hier: der Kern instanziiert es in einem generate,
# und Quartus loest Entity-Referenzen auch im NICHT genommenen Zweig auf (Error 10481).
# Die Platinenhuelle steht in files_hw<n>[_cii].tcl. Debounce.vhd stand in sieben der alten .qsf, wurde aber nirgends
# instanziiert - es ist nicht mitgekommen (liegt im Backup-ZIP unter Archive\).

set_global_assignment -name VHDL_FILE variant_pkg.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/version_pkg.vhd

set_global_assignment -name VHDL_FILE ../../rtl/common/signal_delay.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/boot_delay.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/clk_400Hz_gen.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/cpu_clk_gen.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/byte_to_decimal.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/boot_message.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/coin_validator.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/EEprom.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/one_pulse_only.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/SD_Card.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/zc_indicator.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/SPI_Master.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/slow_to_fast_clock_bus.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/slow_to_fast_clock.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/zero_cross_clk_gen.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/pia6821.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/cpu68.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/uart_tx.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/uart_rx.vhd
set_global_assignment -name VHDL_FILE ../../rtl/common/lisy_api.vhd
set_global_assignment -name VHDL_FILE ../../top/Bally_core.vhd

# Initialisierungsdaten fuer U2andU6. Vorher stand im Wrapper "../ROMs/elektra.hex" - das
# zeigte ins Leere und wurde nur ueber Quartus' "Auto-Found" im Projektordner gefunden.
# Der Inhalt ist ohnehin nur Vorbelegung: beim Start laedt SD_Card das Spiel-ROM.
set_global_assignment -name HEX_FILE ../../rom/elektra.hex

# Eine gemeinsame .sdc: sie nennt nur clk_50 und Bally_core:core|cpu_clk_gen:clock_gen|clk_out,
# und beide Huellen instanziieren den Kern unter demselben Namen "core".
set_global_assignment -name SDC_FILE ../../rtl/common/Bally.sdc
