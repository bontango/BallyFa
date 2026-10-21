# device.tcl - was fuer DIESES Board gilt, ausser den Pinlagen. Handgepflegt.
# Variante: hw2_cyclone_iv - BallyFA HW 2.x mit dem Cyclone IV Board (EP4CE6F17C8)
# Wird von scripts\gen_qsf.ps1 in Bally.qsf eingesetzt.
# Quartus 22.1std.
# Bis 10.2026 mit Quartus 13.0sp1 gebaut, seit dem gemeinsamen Sourcebaum mit 22.1 wie die
# v4.x-Variante (ein Wrapper-Satz in rtl/cyclone_iv). EDA-Zeilen deshalb aus der v4.x-.qsf.
set_global_assignment -name FAMILY "Cyclone IV E"
set_global_assignment -name DEVICE EP4CE6F17C8
set_global_assignment -name LAST_QUARTUS_VERSION "22.1std.2 Lite Edition"
set_global_assignment -name EDA_SIMULATION_TOOL "Questa Intel FPGA (VHDL)"
set_global_assignment -name EDA_OUTPUT_DATA_FORMAT VHDL -section_id eda_simulation
