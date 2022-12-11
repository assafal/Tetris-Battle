library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library WORK;
use WORK.top_pack.all;
use work.brick_position_pack.all;
use work.AI_pack.all;


entity AI_proc_box is
port
(	
	CLK	    	: in std_logic ;			
    RST_N 		: in std_logic ;

    TEST_BRICK    : in  t_brick_info;
    BOARD_IN        : in  t_game_board;

    TOP_ROWS        : out  t_top_rows_arr

);
end AI_proc_box;

architecture AI_proc_box_arch of AI_proc_box is


attribute noprune: boolean;
---------------------------------------------------------------------------
-- Components
---------------------------------------------------------------------------
            

---------------------------------------------------------------------------
-- Constants
---------------------------------------------------------------------------


---------------------------------------------------------------------------
-- Signals
---------------------------------------------------------------------------

signal test_board_map : t_board_arr (0 to 3);


--attribute noprune of test_board_map: signal is true;    
--attribute noprune of top_rows: signal is true;    


begin

    g_rot : for r in 0 to 3 generate
        g_row : for x in 0 to C_GAME_ZONE_X_SIZE-1 generate
            g_col : for y in 0 to C_GAME_ZONE_Y_SIZE-1 generate
    
                process (CLK, RST_N)
                begin
                    if RST_N = '0' then
                        
                        test_board_map(r)(y)(x)    <= '0';
                
                    elsif rising_edge(CLK) then
    
                        test_board_map(r)(y)(x) <= TestLocation(BOARD_IN , x, y, r, TEST_BRICK.BTYPE); 
    
                    end if;
                end process;
    
            end generate;
        end generate;
    end generate;
    
    g_max_rot : for r in 0 to 3 generate
        g_max_row : for x in 0 to C_GAME_ZONE_X_SIZE-1 generate
    
            process (CLK, RST_N)
            begin
                if RST_N = '0' then
                    
                    TOP_ROWS(r)(x)    <= -1;
            
                elsif rising_edge(CLK) then
    
                    TOP_ROWS(r)(x) <= GetTopRow(test_board_map(r), C_INIT_POS_ARR(TEST_BRICK.BTYPE)(r).Y, x);
    
                end if;
            end process;
    
        end generate;
    end generate;


end AI_proc_box_arch;
 
	
	
	
	
	
