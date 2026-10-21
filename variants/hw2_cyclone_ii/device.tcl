# device.tcl - was fuer DIESES Board gilt, ausser den Pinlagen. Handgepflegt.
# Variante: hw2_cyclone_ii - BallyFA HW 2.x mit dem Cyclone II Board (EP2C5T144C8)
# Wird von scripts\gen_qsf.ps1 in Bally.qsf eingesetzt.
# Cyclone II kennt nur Quartus 13.0sp1 (C:\altera\13.0sp1) - check.ps1 waehlt die Version ueber FAMILY.
set_global_assignment -name FAMILY "Cyclone II"
set_global_assignment -name DEVICE EP2C5T144C8
set_global_assignment -name LAST_QUARTUS_VERSION "13.0 SP1"
set_global_assignment -name EDA_SIMULATION_TOOL "ModelSim-Altera (VHDL)"
set_global_assignment -name EDA_OUTPUT_DATA_FORMAT VHDL -section_id eda_simulation
