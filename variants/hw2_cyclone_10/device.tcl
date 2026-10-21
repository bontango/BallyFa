# device.tcl - was fuer DIESES Board gilt, ausser den Pinlagen. Handgepflegt.
# Variante: hw2_cyclone_10 - BallyFA HW 2.x mit dem Cyclone 10 Board (10CL006YE144C8G)
# Wird von scripts\gen_qsf.ps1 in Bally.qsf eingesetzt.
# Quartus 22.1std.
set_global_assignment -name FAMILY "Cyclone 10 LP"
set_global_assignment -name DEVICE 10CL006YE144C8G
set_global_assignment -name LAST_QUARTUS_VERSION "22.1std.2 Lite Edition"
set_global_assignment -name EDA_SIMULATION_TOOL "<None>"
set_global_assignment -name EDA_OUTPUT_DATA_FORMAT NONE -section_id eda_simulation
set_global_assignment -name EDA_GENERATE_FUNCTIONAL_NETLIST OFF -section_id eda_board_design_timing
set_global_assignment -name EDA_GENERATE_FUNCTIONAL_NETLIST OFF -section_id eda_board_design_symbol
set_global_assignment -name EDA_GENERATE_FUNCTIONAL_NETLIST OFF -section_id eda_board_design_signal_integrity
set_global_assignment -name EDA_GENERATE_FUNCTIONAL_NETLIST OFF -section_id eda_board_design_boundary_scan
