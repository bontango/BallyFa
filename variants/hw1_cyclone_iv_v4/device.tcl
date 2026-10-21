# device.tcl - was fuer DIESES Board gilt, ausser den Pinlagen. Handgepflegt.
# Variante: hw1_cyclone_iv_v4 - BallyFA HW 1.x mit dem Cyclone IV v4.x Board (EP4CE6E22C8N)
# Wird von scripts\gen_qsf.ps1 in Bally.qsf eingesetzt.
# Quartus 22.1std.
set_global_assignment -name FAMILY "Cyclone IV E"
set_global_assignment -name DEVICE EP4CE6E22C8
set_global_assignment -name LAST_QUARTUS_VERSION "22.1std.2 Lite Edition"
set_global_assignment -name EDA_SIMULATION_TOOL "Questa Intel FPGA (VHDL)"
set_global_assignment -name EDA_OUTPUT_DATA_FORMAT VHDL -section_id eda_simulation

# The configuration flash is the second source of the game ROMs (HAS_FLASH_ROM), so its
# pins become regular I/O after configuration. ASDO is released for every board in
# scripts\common_header.tcl; pin 6 is ASDO/DATA1 and needs DATA1 released as well, otherwise
# the fitter keeps ~ALTERA_ASDO_DATA1~ there (Error 176310, seen 10.2026).
set_global_assignment -name RESERVE_DATA0_AFTER_CONFIGURATION "USE AS REGULAR IO"
set_global_assignment -name RESERVE_DATA1_AFTER_CONFIGURATION "USE AS REGULAR IO"
set_global_assignment -name RESERVE_FLASH_NCE_AFTER_CONFIGURATION "USE AS REGULAR IO"
set_global_assignment -name RESERVE_DCLK_AFTER_CONFIGURATION "USE AS REGULAR IO"
