#**************************************************************
# This .sdc file is created by Terasic Tool.
# Users are recommended to modify this file to match users logic.
#**************************************************************

#**************************************************************
# Create Clock
#**************************************************************
#create_clock -period "10.0 MHz" [get_ports ADC_CLK_10]
create_clock -period "50.0 MHz" [get_ports CLK_50]
#create_clock -period "50.0 MHz" [get_ports MAX10_CLK2_50]

#**************************************************************
# Create Generated Clock
#**************************************************************
derive_pll_clocks



#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************
derive_clock_uncertainty



#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************
#set_false_path -from {perf_counter:perf_counter_inst|*} -to {perf_counter:perf_counter_inst|*}
#set_false_path -from {perf_counter:perf_counter_inst|*} -to {vga:vga_inst|*}
#set_false_path -from [get_clocks {pll_inst|altpll_component|auto_generated|pll1|clk[0]}] -to [get_clocks {CLK_50}]
#set_false_path -from {cpu:cpu_inst|*} -to {clkctrl:clkctrl|clkctrl_altclkctrl_0:altclkctrl_0|clkctrl_altclkctrl_0_sub:clkctrl_altclkctrl_0_sub_component|clkctrl1~ena_reg}

#**************************************************************
# Set Multicycle Path
#**************************************************************
#set_multicycle_path -from {rom:rom_inst|altsyncram:altsyncram_component|altsyncram_1rb1:auto_generated|altsyncram_1fd2:altsyncram1|ram_block3a*~porta_address_reg0} -to {cpu:cpu_inst|zero} -setup -end 2


#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************



#**************************************************************
# Set Load
#**************************************************************



