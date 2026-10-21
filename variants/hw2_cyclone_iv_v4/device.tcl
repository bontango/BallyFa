# device.tcl - was fuer DIESES Board gilt, ausser den Pinlagen. Handgepflegt.
# Variante: hw2_cyclone_iv_v4 - BallyFA HW 2.x mit dem Cyclone IV v4.x Board (EP4CE6E22C8N)
# Wird von scripts\gen_qsf.ps1 in Bally.qsf eingesetzt.
# Quartus 22.1std.
set_global_assignment -name FAMILY "Cyclone IV E"
set_global_assignment -name DEVICE EP4CE6E22C8
set_global_assignment -name LAST_QUARTUS_VERSION "22.1std.2 Lite Edition"
set_global_assignment -name EDA_SIMULATION_TOOL "Questa Intel FPGA (VHDL)"
set_global_assignment -name EDA_OUTPUT_DATA_FORMAT VHDL -section_id eda_simulation
