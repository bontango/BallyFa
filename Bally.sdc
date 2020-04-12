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
	# 14.3 MHz needed?
	# create_clock -name {clk_143} -period 69.930 -waveform { 0.000 34.965 } 
	# 3.58 MHz
	#create_clock -name {clk_358} -period 279.720 -waveform { 0.000 139.860 } [get_registers {clk_358}]
	# 895 KHz
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
	# Node: cpu_clk_gen:clock_gen|clk_out was determined to be a clock but was found without an associated clock assignment.

   create_generated_clock -name clk_out -divide_by 94 -source clk_50 cpu_clk_gen:clock_gen|clk_out

   # create_generated_clock -name clk_rom_out -divide_by 24 -source clk_50 clk_rom:rom_Clock_gen|signal_level
	# shifted negated clock same frequency	
	# create_generated_clock -name clk_out_s -divide_by 100 -source clk_50 clk_divider_s:Clock_gen_s|signal_level
	#
	#Warning (332060): Node: clk_divider:Clock_gen|signal_level was determined to be a clock but was found 
	#without an associated clock assignment.
