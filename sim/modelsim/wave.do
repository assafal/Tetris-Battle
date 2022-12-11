onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /top_tb/dut_u/fsm_u/CLK
add wave -noupdate /top_tb/dut_u/fsm_u/RST_N
add wave -noupdate /top_tb/dut_u/fsm_u/INIT_DONE
add wave -noupdate -expand /top_tb/dut_u/fsm_u/USR_CMD
add wave -noupdate -expand /top_tb/dut_u/fsm_u/INIT_CMD
add wave -noupdate /top_tb/dut_u/fsm_u/BLANK
add wave -noupdate /top_tb/dut_u/fsm_u/fsm
add wave -noupdate -divider Init
add wave -noupdate /top_tb/dut_u/init_u/CLK
add wave -noupdate /top_tb/dut_u/init_u/RST_N
add wave -noupdate /top_tb/dut_u/init_u/CMD
add wave -noupdate /top_tb/dut_u/init_u/RAND_VECT
add wave -noupdate /top_tb/dut_u/init_u/DONE
add wave -noupdate /top_tb/dut_u/init_u/init_fsm
add wave -noupdate /top_tb/dut_u/init_u/rom_counter
add wave -noupdate /top_tb/dut_u/init_u/word_counter
add wave -noupdate /top_tb/dut_u/init_u/rom_addr
add wave -noupdate /top_tb/dut_u/init_u/splash_rom_data
add wave -noupdate /top_tb/dut_u/init_u/map_rom_data
add wave -noupdate /top_tb/dut_u/init_u/selected_data
add wave -noupdate /top_tb/dut_u/init_u/rom_word
add wave -noupdate /top_tb/dut_u/init_u/current_cmd
add wave -noupdate /top_tb/dut_u/init_u/selected_rom_data
add wave -noupdate -divider Game
add wave -noupdate /top_tb/dut_u/game_u/CLK
add wave -noupdate /top_tb/dut_u/game_u/RST_N
add wave -noupdate /top_tb/dut_u/game_u/GAME_START
add wave -noupdate /top_tb/dut_u/game_u/INFO_DONE
add wave -noupdate /top_tb/dut_u/game_u/MILI_SEC_TIC
add wave -noupdate -expand /top_tb/dut_u/game_u/USR_CMD
add wave -noupdate -expand -subitemconfig {/top_tb/dut_u/game_u/INFO_CMD.DATA -expand /top_tb/dut_u/game_u/INFO_CMD.DATA.BCD_NUM -expand} /top_tb/dut_u/game_u/INFO_CMD
add wave -noupdate /top_tb/dut_u/game_u/GAME_DONE
add wave -noupdate /top_tb/dut_u/game_u/fsm
add wave -noupdate /top_tb/dut_u/game_u/next_state
add wave -noupdate -divider Info
add wave -noupdate -expand -group Info /top_tb/dut_u/info_u/CLK
add wave -noupdate -expand -group Info /top_tb/dut_u/info_u/RST_N
add wave -noupdate -expand -group Info -expand /top_tb/dut_u/info_u/VIDEO_SYNC
add wave -noupdate -expand -group Info -expand -subitemconfig {/top_tb/dut_u/info_u/INFO_CMD.DATA -expand} /top_tb/dut_u/info_u/INFO_CMD
add wave -noupdate -expand -group Info -expand /top_tb/dut_u/info_u/SRAM_INTERFACE
add wave -noupdate -expand -group Info /top_tb/dut_u/info_u/DONE
add wave -noupdate -expand -group Info /top_tb/dut_u/info_u/busy_flag
add wave -noupdate -expand -group Info /top_tb/dut_u/info_u/update_now
add wave -noupdate -expand -group Info /top_tb/dut_u/info_u/update_done
add wave -noupdate -expand -group Info /top_tb/dut_u/info_u/update_info
add wave -noupdate -expand -group Info /top_tb/dut_u/info_u/adder_start
add wave -noupdate -expand -group Info /top_tb/dut_u/info_u/adder_done
add wave -noupdate -expand -group Info /top_tb/dut_u/info_u/adder_len
add wave -noupdate -expand -group Info /top_tb/dut_u/info_u/adder_in_1
add wave -noupdate -expand -group Info /top_tb/dut_u/info_u/adder_in_2
add wave -noupdate -expand -group Info -expand /top_tb/dut_u/info_u/adder_out
add wave -noupdate -expand -group Info /top_tb/dut_u/info_u/top_score
add wave -noupdate -expand -group Info -expand -subitemconfig {/top_tb/dut_u/info_u/game_score.BCD_NUM -expand} /top_tb/dut_u/info_u/game_score
add wave -noupdate -expand -group Info /top_tb/dut_u/info_u/lines_count
add wave -noupdate -expand -group Info /top_tb/dut_u/info_u/stats_counter
add wave -noupdate -expand -group Info /top_tb/dut_u/info_u/update_counter
add wave -noupdate -expand -group Info /top_tb/dut_u/info_u/current_cmd
add wave -noupdate -expand -group Info /top_tb/dut_u/info_u/stats_arr
add wave -noupdate -expand -group Info /top_tb/dut_u/info_u/next_brick
add wave -noupdate -expand -group Info /top_tb/dut_u/info_u/update_fsm
add wave -noupdate -expand -group Info /top_tb/dut_u/info_u/next_state
add wave -noupdate -expand -group Info /top_tb/dut_u/info_u/mem_tile
add wave -noupdate -divider UI
add wave -noupdate /top_tb/dut_u/ui_u/CLK
add wave -noupdate /top_tb/dut_u/ui_u/RST_N
add wave -noupdate /top_tb/dut_u/ui_u/SW
add wave -noupdate /top_tb/dut_u/ui_u/BUTTON
add wave -noupdate /top_tb/dut_u/ui_u/MILI_SEC_TIC
add wave -noupdate /top_tb/dut_u/ui_u/time_counter
add wave -noupdate /top_tb/dut_u/ui_u/sample_strb
add wave -noupdate /top_tb/dut_u/ui_u/lr_sw
add wave -noupdate /top_tb/dut_u/ui_u/rt_button
add wave -noupdate /top_tb/dut_u/ui_u/mv_button
add wave -noupdate -expand /top_tb/dut_u/ui_u/USER_CMD
add wave -noupdate -divider {New Divider}
add wave -noupdate /top_tb/dut_u/disp_u/BLANK
add wave -noupdate -expand /top_tb/dut_u/disp_u/PIXEL_POS
add wave -noupdate -expand /top_tb/dut_u/disp_u/TILE_POS
add wave -noupdate -expand -subitemconfig {/top_tb/dut_u/disp_u/VIDEO_SYNC.ACTIVE {-color Yellow -height 15}} /top_tb/dut_u/disp_u/VIDEO_SYNC
add wave -noupdate -radix unsigned /top_tb/dut_u/disp_u/SRAM_RDADDR
add wave -noupdate -radix hexadecimal /top_tb/dut_u/disp_u/SRAM_DATA
add wave -noupdate /top_tb/dut_u/disp_u/tile_type
add wave -noupdate -radix unsigned -childformat {{/top_tb/dut_u/disp_u/tile_offset(5) -radix unsigned} {/top_tb/dut_u/disp_u/tile_offset(4) -radix unsigned} {/top_tb/dut_u/disp_u/tile_offset(3) -radix unsigned} {/top_tb/dut_u/disp_u/tile_offset(2) -radix unsigned} {/top_tb/dut_u/disp_u/tile_offset(1) -radix unsigned} {/top_tb/dut_u/disp_u/tile_offset(0) -radix unsigned}} -subitemconfig {/top_tb/dut_u/disp_u/tile_offset(5) {-height 15 -radix unsigned} /top_tb/dut_u/disp_u/tile_offset(4) {-height 15 -radix unsigned} /top_tb/dut_u/disp_u/tile_offset(3) {-height 15 -radix unsigned} /top_tb/dut_u/disp_u/tile_offset(2) {-height 15 -radix unsigned} /top_tb/dut_u/disp_u/tile_offset(1) {-height 15 -radix unsigned} /top_tb/dut_u/disp_u/tile_offset(0) {-height 15 -radix unsigned}} /top_tb/dut_u/disp_u/tile_offset
add wave -noupdate -radix hexadecimal /top_tb/dut_u/disp_u/rom_addr
add wave -noupdate -radix hexadecimal /top_tb/dut_u/disp_u/rom_data
add wave -noupdate -color Cyan /top_tb/dut_u/disp_u/current_color
add wave -noupdate -radix unsigned /top_tb/dut_u/disp_u/pixel_y
add wave -noupdate -expand /top_tb/dut_u/disp_u/color_out
add wave -noupdate -divider {New Divider}
add wave -noupdate /top_tb/dut_u/disp_u/V_SYNC
add wave -noupdate /top_tb/dut_u/disp_u/H_SYNC
add wave -noupdate -radix unsigned /top_tb/dut_u/disp_u/RED
add wave -noupdate -radix unsigned /top_tb/dut_u/disp_u/GREEN
add wave -noupdate -radix unsigned /top_tb/dut_u/disp_u/BLUE
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {16802083371 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits us
update
WaveRestoreZoom {16801546352 ps} {16803435820 ps}
