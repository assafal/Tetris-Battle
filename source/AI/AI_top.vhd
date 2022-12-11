library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library WORK;
use WORK.top_pack.all;
use work.brick_position_pack.all;
use work.AI_pack.all;


entity AI_top is
port
(	
	CLK	    	: in std_logic ;			
    RST_N 		: in std_logic ;

    AI_TIC	        : in std_logic;
    DROP_TIC	    : in std_logic;

    CLEAR            : in std_logic;
    UPDATE           : in std_logic;
    NEXT_BRICK       : in  t_brick_info;
    CURRENT_BRICK    : in  t_brick_info;

    USER_CMD    : out t_usr_cmd_rec

);
end AI_top;

architecture AI_top_arch of AI_top is


attribute noprune: boolean;
---------------------------------------------------------------------------
-- Components
---------------------------------------------------------------------------
            

---------------------------------------------------------------------------
-- Constants
---------------------------------------------------------------------------

type t_AI_top is (s_idle, s_wait_process, s_wait_path, s_path, s_wait_drop_tic, s_wait_ai_tic);    

---------------------------------------------------------------------------
-- Signals
---------------------------------------------------------------------------

signal fsm 	        :	t_AI_top;

signal board        :   t_game_board;

signal board_score    : integer range 0 to 8191;
signal best_score     : integer range 0 to 8191;

signal bp_next_ready_out    : std_logic;
signal bp_next_valid_out    : std_logic;
signal score_ready            : std_logic;
signal score_ready_d1       : std_logic;
signal process_start        : std_logic;
signal process_done         : std_logic;

signal bp_curr_board_out    :   t_game_board;
signal bp_next_board_out    :   t_game_board;
signal bp_curr_res_brick    :   t_brick_info;
signal best_brick           :   t_brick_info;
signal drop_brick           :   t_brick_info;

signal path_ready           :   std_logic;
signal path_status          :   std_logic;
signal path                 :   t_path_arr;
signal path_length          :   integer range 0 to C_MAX_MOVES-1;
signal move_pointer         :   integer range 0 to C_MAX_MOVES-1;
signal wait_done            :   std_logic;

-- attribute noprune of test_board_map: signal is true;    
-- attribute noprune of top_rows: signal is true;    


begin

bp_u: entity work.AI_board_process
port map
(	
        CLK	    	=> CLK, --: in std_logic ;			
        RST_N 		=> RST_N, --: in std_logic ;

        UPDATE      => process_start,
        READY_IN    => score_ready,
        CURRENT_BRICK  => CURRENT_BRICK, 
        NEXT_BRICK  => NEXT_BRICK, 
        BOARD_IN    => board, 

        READY_OUT   => bp_next_ready_out,
        VALID_OUT   => bp_next_valid_out,
        BOARD_OUT   => bp_next_board_out,
        RES_BRICK   => bp_curr_res_brick,
        DROP_BRICK  => drop_brick
);

---------------------------------------------------------------------------
-- Score
---------------------------------------------------------------------------    

score_u : entity work.AI_score
port map
(	
    CLK	    	=>  CLK,--: in std_logic ;			
    RST_N 		=>  RST_N,--: in std_logic ;

    UPDATE      =>  bp_next_valid_out,--    : in std_logic;    
    BOARD_IN    =>  bp_next_board_out,--    : in  t_game_board;

    READY_OUT   =>  score_ready, --    : out std_logic;
    BOARD_SCORE =>  board_score     --    : out integer range 0 to 2047

);


process (CLK, RST_N)
begin
	if RST_N = '0' then
		
        best_brick      <= (1 , C_INIT_POS, 0) ;
        best_score     <= 8191;
        score_ready_d1    <= '0';

    elsif rising_edge(CLK) then

        score_ready_d1    <= score_ready;

        if process_start = '1' then

            best_score     <= 8191;

        elsif score_ready ='1' and score_ready_d1 = '0' then --bp_next_valid_out_d1 = '1' then

            if board_score < best_score then 

                best_score  <= board_score;
                best_brick  <= bp_curr_res_brick;
            end if;

        end if;        
    end if;
end process;

---------------------------------------------------------------------------
-- Path
---------------------------------------------------------------------------    

u_path: entity work.AI_path 
port map
(	
    CLK	    	    => CLK,    --: in std_logic ;			
    RST_N 		    => RST_N,    --: in std_logic ;

    UPDATE          => process_done,    --: in std_logic;
    BRICK_START     => CURRENT_BRICK ,    --: in  t_brick_info;
    BRICK_TARGET    => best_brick,    --: in  t_brick_info;
    BOARD_IN        => board,    --: in  t_game_board

    READY_OUT       => path_ready, --: out std_logic;
    STATUS          => path_status, --: out std_logic;
    PATH_LENGTH     => path_length,
    PATH            => path           --: out t_path_arr    
);

---------------------------------------------------------------------------
-- FSM
---------------------------------------------------------------------------    

process (CLK, RST_N)
begin
	if RST_N = '0' then

        fsm             <= s_idle;		
        board           <= (others => (others => '0'));
        USER_CMD        <= ('0', cmd_down);
        
        process_done    <= '0';
        process_start   <= '0';
        wait_done       <= '0';
        move_pointer    <= 0 ;

    elsif rising_edge(CLK) then

        if CLEAR = '1' then 

            fsm             <= s_idle;		
            board           <= (others => (others => '0'));
            USER_CMD        <= ('0', cmd_down);
            
            process_done    <= '0';
            process_start   <= '0';
            wait_done       <= '0';
            move_pointer    <= 0 ;
        else
            case fsm is

                when s_idle => 

                    move_pointer    <= 0 ;
                    USER_CMD.STRB   <= '0';
                    wait_done       <= '0';

                    if UPDATE = '1' then 

                        process_start   <= '1';
                        fsm <= s_wait_process;
                    end if;

                when s_wait_process => 

                    process_start   <= '0';

                    if process_start='0' and bp_next_ready_out='1' then --bp_next_ready_out='1' and bp_curr_ready_out='1' then 

                        process_done    <= '1';
                        fsm             <= s_wait_path;
                    end if;

                when s_wait_path => 

                    process_done    <= '0';

                    if path_ready = '1' then

                        fsm             <= s_wait_ai_tic; 
                    end if;

                when s_path => 

                    wait_done   <= '0';
                    

                    if wait_done='1' then                     

                        if path_status = '1' then

                            if move_pointer <= path_length then

                                move_pointer    <= move_pointer + 1 ;

                                USER_CMD <= ('1' , Move2Cmnd(path(move_pointer).MOV));

                                if path(move_pointer).D_COUNT = 2 then

                                    fsm             <= s_wait_drop_tic;
                                else
                                    fsm             <= s_wait_ai_tic;
                                end if;

                            else

                                USER_CMD    <= ('1' , cmd_drop);
                                fsm         <= s_idle;     
                                board   <= UpdateBoard( board, best_brick.POS.X, best_brick.POS.Y, best_brick.ROT, best_brick.BTYPE);                       
                                
                            end if;
                        else
                            --Do Drop 
                            board   <= UpdateBoard( board, drop_brick.POS.X, drop_brick.POS.Y, drop_brick.ROT, drop_brick.BTYPE); 
                            fsm     <= s_idle;

                        end if;
                        
                    end if;
                
                when s_wait_drop_tic => 

                    USER_CMD.STRB <= '0';

                    if DROP_TIC='1' then
                        fsm         <= s_wait_ai_tic;
                        wait_done   <= '1';
                    end if;            
                    
                when s_wait_ai_tic => 

                    USER_CMD.STRB <= '0';

                    if AI_TIC='1' then
                        fsm         <= s_path;
                        wait_done   <= '1';
                    end if;

            end case;
        end if;
    end if;
end process;

-------------
end AI_top_arch;
 
	
	
	
	
	
