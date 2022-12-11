library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library WORK;
use WORK.top_pack.all;
use work.brick_position_pack.all;
use work.AI_pack.all;


entity AI_board_process is
port
(	
	CLK	    	: in std_logic ;			
    RST_N 		: in std_logic ;

    UPDATE          : in std_logic;
    READY_IN        : in std_logic;
    CURRENT_BRICK   : in  t_brick_info;
    NEXT_BRICK      : in  t_brick_info;
    BOARD_IN        : in  t_game_board;

    READY_OUT    : out std_logic;
    VALID_OUT    : out std_logic;
    BOARD_OUT    : out  t_game_board;
    RES_BRICK    : out  t_brick_info;
    DROP_BRICK   : out  t_brick_info

);
end AI_board_process;

architecture AI_board_process_arch of AI_board_process is


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

--signal cur_fsm      :	t_AI_board_process;
signal nxt_fsm      :	t_AI_board_process;

signal top_rows     :   t_top_rows_arr;

signal test_board   : t_game_board;
signal test_brick   : t_brick_info;

signal cur_valid_out : std_logic;
signal cur_board_out : t_game_board;
--signal cur_res_brick : t_brick_info;
--signal cur_drop_brick : t_brick_info;

signal nxt_ready_out : std_logic;
signal cur_ready_out : std_logic;


--attribute noprune of test_board_map: signal is true;    
--attribute noprune of top_rows: signal is true;    


begin


---------------------------------------------------------------------------
-- Processing unit
---------------------------------------------------------------------------    

box_u: entity work.AI_proc_box 
port map
(	
    CLK	    	=> CLK, 			
    RST_N 		=> RST_N, --

    TEST_BRICK  => test_brick, --  : in  t_brick_info;
    BOARD_IN    => test_board, --    : in  t_game_board;

    TOP_ROWS    => top_rows--    : out  t_top_rows_arr

);


---------------------------------------------------------------------------
-- FSM
---------------------------------------------------------------------------    

test_brick  <= CURRENT_BRICK when nxt_fsm = s_idle else NEXT_BRICK;
test_board  <= BOARD_IN      when nxt_fsm = s_idle else cur_board_out;

cur_fsm_u: entity work.AI_proc_fsm 
port map
(	
    CLK	    	    => CLK , 
    RST_N 		    => RST_N ,
    
    UPDATE          => UPDATE , 
    READY_IN        => nxt_ready_out ,
    BRICK_IN        => CURRENT_BRICK, 
    BOARD_IN        => BOARD_IN  , 
    
    TOP_ROWS        => top_rows  , 
    
    STATE_OUT       => open , --cur_fsm  , 
    READY_OUT       => cur_ready_out  , -- : out std_logic;
    VALID_OUT       => cur_valid_out , -- : out std_logic;
    BOARD_OUT       => cur_board_out , -- : out  t_game_board;
    RES_BRICK       => RES_BRICK , -- : out  t_brick_info;
    DROP_BRICK      => DROP_BRICK  -- : out  t_brick_info

);

nxt_fsm_u: entity work.AI_proc_fsm 
port map
(	
    CLK	    	    => CLK , 
    RST_N 		    => RST_N , 
    
    UPDATE          => cur_valid_out ,
    READY_IN        => READY_IN , 
    BRICK_IN        => NEXT_BRICK , 
    BOARD_IN        => cur_board_out  , 
    
    TOP_ROWS        => top_rows  , 

    STATE_OUT       => nxt_fsm  , 
    READY_OUT       => nxt_ready_out  , -- : out std_logic;
    VALID_OUT       => VALID_OUT , -- : out std_logic;
    BOARD_OUT       => BOARD_OUT , -- : out  t_game_board;
    RES_BRICK       => open , -- : out  t_brick_info;
    DROP_BRICK      => open  -- : out  t_brick_info

);

READY_OUT   <= nxt_ready_out and cur_ready_out;

end AI_board_process_arch;
 
	
	
	
	
	
