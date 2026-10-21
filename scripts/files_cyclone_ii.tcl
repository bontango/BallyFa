# files_cyclone_ii.tcl - die Megafunctions fuer Cyclone II (EP2C5T144C8).
#
# Mit Quartus 13.0sp1 erzeugt (altera_mf mit eigener COMPONENT-Deklaration). Gegenueber Cyclone IV/10 steht in
# allen vier Wrappern kein read_during_write_mode_port_a/_b (dort NEW_DATA_NO_NBE_READ) - der Default dieses
# Generators, keine bewusste Abweichung; die Synthese-Zahlen der alten Cyclone-II-Projekte sind die Abnahme.
#
# Dieselben Entity-Namen und Portlisten in allen rtl/<familie>/ - im VHDL steht kein
# Familien-Konstrukt, die .qsf entscheidet allein ueber RtlFamily in variants/<n>/variant.psd1.
# Die .qip finden ihre .vhd/.cmp selbst ([file join $::quartus(qip_path) ...]).

set_global_assignment -name QIP_FILE ../../rtl/cyclone_ii/U2andU6.qip
set_global_assignment -name QIP_FILE ../../rtl/cyclone_ii/M6810.qip
set_global_assignment -name QIP_FILE ../../rtl/cyclone_ii/SM5101.qip
set_global_assignment -name QIP_FILE ../../rtl/cyclone_ii/R5101.qip
