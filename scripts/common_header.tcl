# common_header.tcl - globale Assignments, die fuer JEDE BallyFA-Variante gelten.
# Wird von scripts\gen_qsf.ps1 in variants\<n>\Bally.qsf eingesetzt.
#
# NICHT hierher gehoeren:
#   FAMILY / DEVICE / LAST_QUARTUS_VERSION / EDA-Simulation -> variants\<n>\device.tcl
#   TOP_LEVEL_ENTITY                                         -> schreibt gen_qsf.ps1 selbst
#   Pinlagen                                                 -> variants\<n>\pins.tcl
#
# Die Pull-ups haengen an PORTNAMEN, und die sind in beiden Huellen und auf allen
# FPGA-Boards gleich - deshalb stehen sie hier und nicht je Variante (Version 1.17:
# "weak pull-up U10_PB,CV_CH,S33,U10_CA1,U11_CB1,Zero_cross because of 74LVC245A").
# Vor dem gemeinsamen Baum stand dieser Block byte-gleich in allen acht .qsf.

set_global_assignment -name ORIGINAL_QUARTUS_VERSION "13.0 SP1"
set_global_assignment -name PROJECT_CREATION_TIME_DATE "09:31:09  APRIL 07, 2020"
set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files
set_global_assignment -name MIN_CORE_JUNCTION_TEMP 0
set_global_assignment -name MAX_CORE_JUNCTION_TEMP 85
set_global_assignment -name ERROR_CHECK_FREQUENCY_DIVISOR 1
set_global_assignment -name USE_CONFIGURATION_DEVICE ON
set_global_assignment -name RESERVE_ALL_UNUSED_PINS "AS INPUT TRI-STATED WITH WEAK PULL-UP"
set_global_assignment -name PARTITION_NETLIST_TYPE SOURCE -section_id Top
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id Top
set_global_assignment -name PARTITION_COLOR 16764057 -section_id Top
set_global_assignment -name STRATIX_DEVICE_IO_STANDARD "3.3-V LVTTL"
set_global_assignment -name CYCLONEII_RESERVE_NCEO_AFTER_CONFIGURATION "USE AS REGULAR IO"
set_global_assignment -name RESERVE_ASDO_AFTER_CONFIGURATION "USE AS REGULAR IO"
set_global_assignment -name POWER_PRESET_COOLING_SOLUTION "23 MM HEAT SINK WITH 200 LFPM AIRFLOW"
set_global_assignment -name POWER_BOARD_THERMAL_MODEL "NONE (CONSERVATIVE)"
set_global_assignment -name SYNTH_TIMING_DRIVEN_SYNTHESIS OFF
set_global_assignment -name AUTO_RAM_RECOGNITION OFF
set_instance_assignment -name PARTITION_HIERARCHY root_partition -to | -section_id Top

set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to reset_l
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to S2_DIPS[1]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to S2_DIPS[2]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to S2_DIPS[3]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to S2_DIPS[4]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to S2_DIPS[5]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to S2_DIPS[6]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to S1_DIPS[7]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to U10_PB[0]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to U10_PB[1]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to U10_PB[2]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to U10_PB[3]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to U10_PB[4]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to U10_PB[5]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to U10_PB[6]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to U10_PB[7]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to CV_CH[1]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to CV_CH[2]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to CV_CH[4]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to CV_CH[3]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to CV_CH[5]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to CV_CH[6]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to S33
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to U11_CB1
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to U10_CA1
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to ZERO_CROSS
