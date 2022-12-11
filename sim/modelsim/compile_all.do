transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work


vlog "C:/intelFPGA_lite/17.0/quartus/eda/sim_lib/altera_mf.v"
vlog "C:/intelFPGA_lite/17.0/quartus/eda/sim_lib/altera_primitives.v"
vlog -sv "C:/intelFPGA_lite/17.0/quartus/eda/sim_lib/altera_lnsim.sv"
vlog "C:/intelFPGA_lite/17.0/quartus/eda/sim_lib/fiftyfivenm_atoms.v"

do run_top.do