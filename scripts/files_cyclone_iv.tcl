# files_cyclone_iv.tcl - die Megafunctions fuer Cyclone IV E (EP4CE6F17C8 und EP4CE6E22C8).
#
# Mit Quartus 22.1 erzeugt (aus dem alten Ordner BallyFA - Cyclone_IV_v4.x). Die F17-Variante hatte
# 13.0-generierte Wrapper mit identischen Parametern - nur der Generator unterschied sich.
#
# Dieselben Entity-Namen und Portlisten in allen rtl/<familie>/ - im VHDL steht kein
# Familien-Konstrukt, die .qsf entscheidet allein ueber RtlFamily in variants/<n>/variant.psd1.
# Die .qip finden ihre .vhd/.cmp selbst ([file join $::quartus(qip_path) ...]).

set_global_assignment -name QIP_FILE ../../rtl/cyclone_iv/U2andU6.qip
set_global_assignment -name QIP_FILE ../../rtl/cyclone_iv/M6810.qip
set_global_assignment -name QIP_FILE ../../rtl/cyclone_iv/SM5101.qip
set_global_assignment -name QIP_FILE ../../rtl/cyclone_iv/R5101.qip
