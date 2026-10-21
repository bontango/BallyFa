# pins.tcl - Pinlagen von hw2_cyclone_10: BallyFA HW 2.x mit dem Cyclone 10 Board (10CL006YE144C8G).
# Uebernommen aus der .qsf von 'FPGA_source_alt\BallyFA_HW2.x_Cyclone_10' (Stand vor dem gemeinsamen Sourcebaum).
# Die Portnamen sind die der Huelle top/BallyFA_HW2.vhd.
# Pull-ups und IO-Standard gelten fuer alle Boards gleich: scripts\common_header.tcl.

set_location_assignment PIN_1 -to LED_0
set_location_assignment PIN_23 -to clk_50
set_location_assignment PIN_67 -to U10_CA1
set_location_assignment PIN_53 -to U10_PA[7]
set_location_assignment PIN_54 -to U10_PA[6]
set_location_assignment PIN_55 -to U10_PA[5]
set_location_assignment PIN_51 -to U10_PA[4]
set_location_assignment PIN_50 -to U10_PA[3]
set_location_assignment PIN_49 -to U10_PA[2]
set_location_assignment PIN_46 -to U10_PA[1]
set_location_assignment PIN_52 -to U10_PA[0]
set_location_assignment PIN_72 -to U10_PB[7]
set_location_assignment PIN_73 -to U10_PB[6]
set_location_assignment PIN_74 -to U10_PB[5]
set_location_assignment PIN_69 -to U10_PB[4]
set_location_assignment PIN_70 -to U10_PB[3]
set_location_assignment PIN_71 -to U10_PB[2]
set_location_assignment PIN_65 -to U10_PB[1]
set_location_assignment PIN_66 -to U10_PB[0]
set_location_assignment PIN_120 -to U10_CB2
set_location_assignment PIN_143 -to U11_CA2
set_location_assignment PIN_77 -to U11_CB1
set_location_assignment PIN_119 -to U11_CB2
set_location_assignment PIN_133 -to U11_PA[7]
set_location_assignment PIN_135 -to U11_PA[6]
set_location_assignment PIN_136 -to U11_PA[5]
set_location_assignment PIN_137 -to U11_PA[4]
set_location_assignment PIN_138 -to U11_PA[3]
set_location_assignment PIN_141 -to U11_PA[2]
set_location_assignment PIN_142 -to U11_PA[1]
set_location_assignment PIN_115 -to U11_PB[7]
set_location_assignment PIN_114 -to U11_PB[6]
set_location_assignment PIN_113 -to U11_PB[5]
set_location_assignment PIN_112 -to U11_PB[4]
set_location_assignment PIN_129 -to U11_PB[3]
set_location_assignment PIN_132 -to U11_PB[2]
set_location_assignment PIN_85 -to U11_PB[1]
set_location_assignment PIN_111 -to U11_PB[0]
set_location_assignment PIN_121 -to DISP_BLANKING
set_location_assignment PIN_124 -to DISP_LA_STR[1]
set_location_assignment PIN_125 -to DISP_LA_STR[2]
set_location_assignment PIN_126 -to DISP_LA_STR[3]
set_location_assignment PIN_127 -to DISP_LA_STR[4]
set_location_assignment PIN_128 -to DISP_LA_STR[5]
set_location_assignment PIN_34 -to D_EEPROM
set_location_assignment PIN_39 -to Q_EEPROM
set_location_assignment PIN_42 -to S_EEPROM
set_location_assignment PIN_32 -to C_EEPROM
set_location_assignment PIN_144 -to reset_l
set_location_assignment PIN_68 -to S33
set_location_assignment PIN_87 -to SD_CLK
set_location_assignment PIN_80 -to SD_CS
set_location_assignment PIN_86 -to SD_MISO
set_location_assignment PIN_83 -to SD_MOSI
set_location_assignment PIN_105 -to CV_CH[1]
set_location_assignment PIN_99 -to CV_CH[2]
set_location_assignment PIN_84 -to CV_CH[3]
set_location_assignment PIN_103 -to CV_CH[4]
set_location_assignment PIN_101 -to CV_CH[5]
set_location_assignment PIN_100 -to CV_CH[6]
set_location_assignment PIN_106 -to CV_COIN_LOCK
set_location_assignment PIN_7 -to LED_ON
set_location_assignment PIN_44 -to LED_ZC
set_location_assignment PIN_2 -to S1_DIPS[7]
set_location_assignment PIN_24 -to S1_DIPS[6]
set_location_assignment PIN_22 -to S1_DIPS[5]
set_location_assignment PIN_25 -to S1_DIPS[4]
set_location_assignment PIN_88 -to S1_DIPS[3]
set_location_assignment PIN_89 -to S1_DIPS[2]
set_location_assignment PIN_90 -to S1_DIPS[1]
set_location_assignment PIN_91 -to S1_DIPS[0]
set_location_assignment PIN_59 -to S2_DIPS[1]
set_location_assignment PIN_58 -to S2_DIPS[2]
set_location_assignment PIN_60 -to S2_DIPS[3]
set_location_assignment PIN_75 -to S2_DIPS[4]
set_location_assignment PIN_38 -to S2_DIPS[5]
set_location_assignment PIN_31 -to S2_DIPS[6]
set_location_assignment PIN_76 -to ZERO_CROSS
set_location_assignment PIN_98 -to USB_Tx
set_location_assignment PIN_43 -to USB_Rx
set_location_assignment PIN_3 -to LED_SD_ERR
set_location_assignment PIN_10 -to LED_Bally

# Configuration flash EPCS16 (HAS_FLASH_ROM, rtl/common/Flash_ROM.vhd): the dedicated
# configuration pins of the E22/E144 package, as in WillFA7 (~ALTERA_DCLK~ 12, ~ALTERA_DATA0~ 13,
# ~ALTERA_FLASH_nCE_nCSO~ 8, ~ALTERA_ASDO_DATA1~ 6). Released as regular I/O in device.tcl.
set_location_assignment PIN_12 -to FLASH_DCLK
set_location_assignment PIN_8 -to FLASH_NCS
set_location_assignment PIN_6 -to FLASH_ASDO
set_location_assignment PIN_13 -to FLASH_DATA0
