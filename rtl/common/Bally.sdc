# Bally.sdc - gemeinsam fuer alle BallyFA-Varianten (rtl/common, eingetragen in scripts\files_common.tcl).
# Sie nennt nur clk_50 und den Teiler im Kern. Seit dem gemeinsamen Sourcebaum liegt der Kern
# eine Ebene tiefer (Instanz 'core' in top/BallyFA_HW1.vhd und top/BallyFA_HW2.vhd), daher der
# Praefix Bally_core:core| - beide Huellen benutzen denselben Instanznamen.
#
    # 
	# https://forums.intel.com/s/question/0D50P00003yyTEnSAM/getting-timing-requirements-not-met-as-critical-warning?language=de
	#
    #  Design Timing Constraints Definitions
    # 
    set_time_format -unit ns -decimal_places 3
    # #############################################################################
    #  Create Input reference clocks
    create_clock -name {clk_50} -period 20.000 -waveform { 0.000 10.000 } [get_ports {clk_50}]	
    # #############################################################################
	#Here I create a clock called "clkin_50" (you can name it whatever you like), 
	#specify that it is 50MHz (20ns period), specify it is 50% duty cycle
	#(rising edge at 0ns, falling edge at 10ns), and instruct that the port 
	#that the clock is located at (e.g. FPGA pin) is called "clkin_50" via the "[get_ports ]" command. 
	#The clock name doesn't have to match the port name, but I find it useful to do so.
	#
	# generated clocks
	#
	# cpu_clk = clk_out aus cpu_clk_gen: der Zaehler laeuft 0..100, also 101 clk_50-Takte je
	# Periode, 50 low (Zaehler 0..49) und 51 high (50..100). -edges zaehlt Flanken von clk_50
	# (1 = erste steigende): steigend bei 1, fallend 51 Takte spaeter (1+2*51 = 103), naechste
	# steigende nach 101 Takten (1+2*101 = 203). Bis 10.2026 stand hier -divide_by 100 - die
	# Periode war 1 % zu kurz und die fallende Flanke (cpu68 und PIA takten auch dort) 10 ns daneben.
	create_generated_clock -name clk_out -source [get_ports {clk_50}] -edges {1 103 203} [get_registers {Bally_core:core|cpu_clk_gen:clock_gen|clk_out}]
	#
	# clk_50 -> clk_out: Hold eine clk_50-Periode entspannen.
	#
	# clk_out ist ein Registerausgang (Ripple-Takt). Sein Taktbaum kommt ~2,6 ns (Cyclone II,
	# Slow Model) nach clk_50 an; die Standard-Hold-Pruefung verlangt dann, dass Daten, die die
	# MIT der clk_out-Flanke zusammenfallende clk_50-Flanke erzeugt, nicht schon vorher ankommen.
	# Fuer die Pfade, die es hier gibt, aendert diese Flanke aber nichts:
	#   - U2andU6/M6810/R5101 (getaktet mit clk_50) -> cpu68/PIA: die Adresse kommt aus der CPU,
	#     sie aendert sich erst NACH der clk_out-Flanke und wird eine clk_50-Periode spaeter
	#     uebernommen - an der zusammenfallenden Flanke ist der RAM-Ausgang stabil.
	#   - byte_to_decimal (DIP-Anzeige) -> boot_message: aendert sich nur, wenn jemand einen
	#     DIP-Schalter umlegt, also asynchron; eine Hold-Pruefung sagt dafuer nichts aus.
	#   - SD_Card cpu_reset_h -> Reset von cpu68/PIA (Removal): einmal beim Booten.
	# Ohne diese Zeile meldete Cyclone II Slow Model Hold -1,665 / -1,829 ns und Fast Model
	# Removal -0,068 ns; Cyclone IV/10 bestanden mit nur ~+0,1 ns.
	# Setup bleibt unveraendert (naechste Flanke, 20 ns).
	set_multicycle_path -hold -start 1 -from [get_clocks {clk_50}] -to [get_clocks {clk_out}]
	#create_generated_clock -name clk_out_1 -divide_by 125 -source clk_50 cpu_400KHz_gen:clock_gen_1|clk_out_1	
	#create_generated_clock -name clk_out_2 -divide_by 100 -source clk_50 cpu_500KHz_gen:clock_gen_2|clk_out_2	
	
	
	#create_clock -name {cpu_clk} -period 1118.880 -waveform { 0.000 559.440 } [get_registers {cpu_clk}]
    #  Now that we have created the custom clocks which will be base clocks,
    #  derive_pll_clock is used to calculate all remaining clocks for PLLs
    
	derive_pll_clocks -create_base_clocks
   derive_clock_uncertainty
	
	#
	# example second clock
	#create_clock -name {clk} -period 400.000 -waveform { 0.000 200.000 } [get_registers {clk}]
	#
	# if output clock pins exist
	#
	# Create a generated clock: -name = name of new clock, -divide_by = output frequency is input divided by this, 
	# -source = original clock, then end of line is the target signal where output clock is.
	#
	