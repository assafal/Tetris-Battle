transcript on
#if {[file exists rtl_work]} {
#	vdel -lib rtl_work -all
#}
#vlib rtl_work
#vmap work rtl_work


#vlog "C:/intelFPGA_lite/17.0/quartus/eda/sim_lib/altera_mf.v"
#vlog "C:/intelFPGA_lite/17.0/quartus/eda/sim_lib/altera_primitives.v"
#vlog -sv "C:/intelFPGA_lite/17.0/quartus/eda/sim_lib/altera_lnsim.sv"
#vlog "C:/intelFPGA_lite/17.0/quartus/eda/sim_lib/fiftyfivenm_atoms.v"


vlog -vlog01compat -work work +incdir+../../source/ips {../../source/ips/alt_pll.v}
vlog -vlog01compat -work work +incdir+../../source/ips {../../source/ips/cossack_rom.v}
vcom -2008 -work work {../../source/ips/sram.vhd}
vcom -2008 -work work {../../source/ips/symbol_rom.vhd}
vcom -2008 -work work {../../source/ips/screen_map_rom.vhd}
vcom -2008 -work work {../../source/ips/splash_rom.vhd}
#vlog -vlog01compat -work work +incdir+../../source {../../source/lcd_cmd.v}
#vlog -sv -work work +incdir+../../source {../../source/lcd_ctrl.sv}


vcom -2008 -work work {../../source/top_pack.vhd}
vcom -2008 -work work {../../source/color_pack.vhd}
vcom -2008 -work work {../../source/brick_position_pack.vhd}
vcom -2008 -work work {../../source/ai/ai_pack.vhd}
vcom -2008 -work work {../../source/clk_and_rst.vhd}
vcom -2008 -work work {../../source/timers.vhd}
vcom -2008 -work work {../../source/seven_seg.vhd}
vcom -2008 -work work {../../source/user_button.vhd}
vcom -2008 -work work {../../source/user_interface.vhd}
vcom -2008 -work work {../../source/bcd_adder.vhd}
vcom -2008 -work work {../../source/info_module.vhd}
vcom -2008 -work work {../../source/init_mem.vhd}
vcom -2008 -work work {../../source/main_fsm.vhd}
vcom -2008 -work work {../../source/game_machine.vhd}
vcom -2008 -work work {../../source/ai/ai_score.vhd}
vcom -2008 -work work {../../source/ai/ai_proc_box.vhd}
vcom -2008 -work work {../../source/ai/ai_proc_fsm.vhd}
vcom -2008 -work work {../../source/ai/ai_board_process.vhd}
vcom -2008 -work work {../../source/ai/ai_path.vhd}
vcom -2008 -work work {../../source/ai/ai_top.vhd}
vcom -2008 -work work {../../source/anima_display_interface.vhd}
vcom -2008 -work work {../../source/display_interface.vhd}
vcom -2008 -work work {../../source/top.vhd}

# Test:
vcom -2008 -work work {../tb/top_tb.vhd}
vcom -2008 -work work {../tb/AI_tb.vhd}

#vsim work.top_tb


