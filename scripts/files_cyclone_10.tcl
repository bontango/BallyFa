# files_cyclone_10.tcl - die Megafunctions fuer Cyclone 10 LP (10CL006YE144C8G).
#
# Mit Quartus 22.1 erzeugt. Gegenueber rtl/cyclone_iv unterscheidet sich nur intended_device_family.
#
# Dieselben Entity-Namen und Portlisten in allen rtl/<familie>/ - im VHDL steht kein
# Familien-Konstrukt, die .qsf entscheidet allein ueber RtlFamily in variants/<n>/variant.psd1.
# Die .qip finden ihre .vhd/.cmp selbst ([file join $::quartus(qip_path) ...]).

set_global_assignment -name QIP_FILE ../../rtl/cyclone_10/U2andU6.qip
set_global_assignment -name QIP_FILE ../../rtl/cyclone_10/M6810.qip
set_global_assignment -name QIP_FILE ../../rtl/cyclone_10/SM5101.qip
set_global_assignment -name QIP_FILE ../../rtl/cyclone_10/R5101.qip
