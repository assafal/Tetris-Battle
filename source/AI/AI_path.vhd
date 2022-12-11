library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library WORK;
use WORK.top_pack.all;
use work.brick_position_pack.all;
use work.AI_pack.all;


entity AI_path is
port
(	
	CLK	    	: in std_logic ;			
    RST_N 		: in std_logic ;

    UPDATE          : in std_logic;
 --   READY_IN        : in std_logic;
    BRICK_START     : in  t_brick_info;
    BRICK_TARGET    : in  t_brick_info;
    BOARD_IN        : in  t_game_board;

    READY_OUT       : out std_logic;
    STATUS          : out std_logic;
    PATH_LENGTH     : out integer range 0 to C_MAX_MOVES-1;
    PATH            : out t_path_arr
    -- BOARD_OUT    : out  t_game_board;
    -- RES_BRICK    : out  t_brick_info

);
end AI_path;

architecture AI_path_arch of AI_path is


attribute noprune: boolean;
---------------------------------------------------------------------------
-- Components
---------------------------------------------------------------------------
            

---------------------------------------------------------------------------
-- Constants
---------------------------------------------------------------------------

type t_AI_path is (s_idle, s_test_ops ,s_backtrack , s_test_stop_cond, s_done);    

---------------------------------------------------------------------------
-- Signals
---------------------------------------------------------------------------

signal fsm 	        :	t_AI_path;
signal open_nodes   :   t_path_arr;
signal used_nodes   :   t_path_arr;

signal curr_dist        : integer range 0 to C_MAX_MOVES-1;
signal curr_pos         : t_brick_info ;
signal open_pointer     : integer range 0 to C_MAX_MOVES-1;
signal used_pointer     : integer range 0 to C_MAX_MOVES-1;
signal move_index       : integer range 0 to C_MAX_MOVES-1;
signal op_counter       : integer range 0 to C_MAX_MOVES-1;
signal down_counter     : integer range 0 to C_DOWN_PHASE-1;
signal DeadEnd          : std_logic;

--attribute noprune of test_board_map: signal is true;    
--attribute noprune of top_rows: signal is true;    


begin

---------------------------------------------------------------------------
-- FSM
---------------------------------------------------------------------------    

process (CLK, RST_N)
variable new_pos    : t_brick_info;  
variable var_dist   : integer range 0 to C_MAX_MOVES-1;  
variable var_index  : integer range 0 to C_MAX_MOVES-1;  
variable last_move  : integer range 1 to 4;
variable new_down_counter  : integer range 0 to C_DOWN_PHASE-1;


begin
	if RST_N = '0' then
		
        fsm             <=  s_idle; 
        curr_dist       <= 0;
        open_nodes      <= (others => (C_INIT_POS, 0, 1, 0, 0));
        used_nodes      <= (others => (C_INIT_POS, 0, 1, 0, 0));
        open_pointer    <= 0;
        used_pointer    <= 0;
        curr_pos        <= (1 , C_INIT_POS, 0);
        op_counter      <= 1;
        move_index      <= 0;
        down_counter    <= 0;
        DeadEnd         <= '0';
        READY_OUT       <= '0';
        STATUS          <= '0';

    elsif rising_edge(CLK) then


        case fsm is 

            when s_idle =>

                READY_OUT       <= '0';
    
                if UPDATE = '1' then                 
                    fsm         <=  s_test_ops;                    
                    curr_dist   <=  Dist(BRICK_START, BRICK_TARGET);
                    open_pointer    <= 0;
                    used_pointer    <= 0;
                    curr_pos        <= BRICK_START;
                    DeadEnd         <= '1';
                    move_index      <= 0;
                    down_counter    <= 0;
                    STATUS          <= '0';
        
                end if;
        
            when s_test_ops =>

                --if TestOp(board_map, op_counter, curr_pos, down_counter) then 
                if TestOp(BOARD_IN, op_counter, curr_pos, down_counter) then 

                    new_pos     := DoOp(op_counter, curr_pos, down_counter);
                    var_dist    := Dist(new_pos, BRICK_TARGET);
                    
                    if op_counter = C_DOWN or down_counter + 1 = C_DOWN_PHASE then 
                        new_down_counter:= 1;
                    else
                        --if down_counter + 1 = C_DOWN_PHASE then
                            --new_down_counter := 0;
                        --else
                            new_down_counter := down_counter + 1;
                        --end if;
                    end if;

                    if var_dist <= curr_dist then
                        
                        open_nodes(open_pointer) <= (new_pos.POS, new_pos.ROT, op_counter, new_down_counter, move_index);
                        open_pointer    <= open_pointer + 1;
                        move_index      <= move_index + 1;
                        DeadEnd         <= '0';
                    end if; 
                end if; 

                if op_counter < 4 then
                    op_counter <= op_counter + 1;
                else
                    op_counter  <= 1;
                    fsm         <=  s_backtrack;                    
                end if;

            when s_backtrack =>

                var_index   := open_nodes(open_pointer-1).IDX;

                if DeadEnd='1' then
                    
                    if var_index <  used_nodes(used_pointer-1).IDX then   
                        if used_pointer > 0 then  
                            used_pointer <= used_pointer - 1;
                        else
                            fsm         <=  s_done; -- ERROR!!!
                        end if;
                    else
                        fsm         <=  s_test_stop_cond;
                        move_index  <=  var_index; 
                    end if;
                else
                    fsm         <=  s_test_stop_cond;                                      
                end if;

            when s_test_stop_cond =>

                DeadEnd         <= '1';

                if open_pointer = 0 then              
                    fsm         <=  s_done;--?????
                else

                    new_pos.POS := open_nodes(open_pointer-1).POS;
                    new_pos.ROT := open_nodes(open_pointer-1).ROT;
                    last_move   := open_nodes(open_pointer-1).MOV;
                    new_down_counter   := open_nodes(open_pointer-1).D_COUNT;
                    var_index   := open_nodes(open_pointer-1).IDX;

                    down_counter    <= new_down_counter;
                                        
                    open_pointer    <= open_pointer - 1;

                    var_dist    := Dist(new_pos, BRICK_TARGET);

                    if var_dist = 0 then 
                        fsm         <=  s_done;
                        STATUS      <= '1';
                        used_nodes(used_pointer) <= (new_pos.POS, new_pos.ROT, last_move, new_down_counter, var_index);
                    else
                        curr_pos    <= new_pos;
                        curr_dist   <= var_dist;
                        fsm         <=  s_test_ops;       
                        
                        used_nodes(used_pointer) <= (new_pos.POS, new_pos.ROT, last_move, new_down_counter, var_index);
                        used_pointer    <= used_pointer + 1;
                    end if;

                end if;            

                
            when s_done =>

                READY_OUT       <= '1';
                fsm             <=  s_idle;
                
            when others =>
                    
        end case;
        
    end if;
end process;

PATH            <= used_nodes;
PATH_LENGTH     <= used_pointer;



end AI_path_arch;
 
	
	
	
	
	
