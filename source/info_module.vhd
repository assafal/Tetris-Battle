library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library WORK;
use WORK.top_pack.all;


entity info_module is
generic 
(    
    G_AI_SCORE_TILE_X   :   integer
);
port
(	
	CLK	    	: in std_logic ;			
    RST_N 		: in std_logic ;

    GAME_MODE   : in t_game_mode;
    VIDEO_SYNC  : in t_video_sync;

    INFO_CMD 	: in t_update_info_cmnd_rec ;

    SCORE           : out t_digits_arr;
    SRAM_INTERFACE  : out t_sram_cmnd_rec;
    DONE 	        : out std_logic

);
end info_module;

architecture info_module_arch of info_module is



---------------------------------------------------------------------------
-- Components
---------------------------------------------------------------------------
            

---------------------------------------------------------------------------
-- Constants
---------------------------------------------------------------------------

type t_update_state is (s_idle, s_wait_screen, s_update_score, s_update_top_score, s_update_lines, s_update_stats, s_mem_update, s_update_level, s_update_rounds, s_update_game,s_update_over);    
type t_update_info is (i_update_score, i_update_top, i_update_stats, i_update_lines, i_update_level, i_update_rounds, i_update_none, i_update_game_over, i_update_all);

type t_stats_arr is array (1 to C_NUM_OF_BRICKS) of t_num_rec;

constant C_MAX_LINES    : integer := 10**4-1;

constant C_BCD_0        : t_digits_arr := (0, 0, 0, 0, 0, 0);
constant C_BCD_1        : t_digits_arr := (1, 0, 0, 0, 0, 0);
constant C_BCD_100      : t_digits_arr := (0, 0, 1, 0, 0, 0);


---------------------------------------------------------------------------
-- Signals
---------------------------------------------------------------------------

signal busy_flag        :	std_logic;
signal update_now       :	std_logic;
signal update_done      :	std_logic;
signal update_info      :   t_update_info;

signal adder_start      :	std_logic;
signal adder_op         :	std_logic;
signal adder_done       :	std_logic;
signal adder_len        :   integer range 1 to C_SCORE_DIGITS;
signal adder_in_1       :   t_digits_arr;
signal adder_in_2       :   t_digits_arr;
signal adder_out        :   t_digits_arr;

signal top_score        :   t_num_rec ;
signal game_score       :   t_num_rec ;
signal lines_count      :   t_num_rec ;
signal level            :   t_num_rec ;
signal rounds           :   t_num_rec ;
signal update_counter   :   integer range 0 to C_SCORE_DIGITS; --C_MAX_LINES ; --!!

signal current_cmd      :   t_update_info_cmnd_rec;
signal stats_arr        :   t_stats_arr;

signal update_fsm       :   t_update_state;
signal next_state       :   t_update_state;
signal mem_tile         :   t_tile_pos;
signal stats_counter    :   t_brick;
signal game_over        :	std_logic;

signal score_tile_x_offset      :   integer range 0 to C_X_TILE_COUNT-1;
signal score_tile_y_offset      :   integer range 0 to C_Y_TILE_COUNT-1;
signal level_tile_x             :   integer range 0 to C_X_TILE_COUNT-1;
signal level_tile_y             :   integer range 0 to C_Y_TILE_COUNT-1;
signal lines_tile_x             :   integer range 0 to C_X_TILE_COUNT-1;
signal lines_tile_y             :   integer range 0 to C_Y_TILE_COUNT-1;
signal stats_tile_x             :   integer range 0 to C_X_TILE_COUNT-1;

begin

score_tile_x_offset <= C_SCORE_TILE_X when GAME_MODE= sp_mode else G_AI_SCORE_TILE_X;   
score_tile_y_offset <= C_GAME_SCORE_TILE_Y when GAME_MODE= sp_mode else C_AI_SCORE_TILE_Y;   
level_tile_x        <= C_LEVEL_TILE_X ;--when GAME_MODE= sp_mode else C_AI_LEVEL_TILE_X; 
level_tile_y        <= C_LEVEL_TILE_Y ;--when GAME_MODE= sp_mode else C_AI_LEVEL_TILE_Y; 
lines_tile_x        <= C_LINES_TILE_X;-- when GAME_MODE= sp_mode else C_PLAYER_LINES_TILE_X; 
lines_tile_y        <= C_LINES_TILE_Y ;--when GAME_MODE= sp_mode else C_AI_LINES_TILE_Y; 
stats_tile_x        <= C_SP_STATS_TILE_X when GAME_MODE= sp_mode else C_AI_STATS_TILE_X; 
    


---------------------------------------------------------------------------
-- Get Comand
---------------------------------------------------------------------------    

SCORE   <=  game_score.BCD_NUM;

process (CLK, RST_N)
begin
	if RST_N = '0' then
		        
        busy_flag   <= '0';
        update_now  <= '0';
        update_info <= i_update_none;
        DONE        <= '0';
        game_score.INT_NUM  <= 0;
        top_score.INT_NUM   <= 0;                
        lines_count.INT_NUM <= 0;
        level.INT_NUM <= 1;
        rounds.INT_NUM <= C_AI_ROUNDS;
                 

    elsif rising_edge(CLK) then

        if busy_flag='0' then 

            DONE        <= '0';

            if INFO_CMD.STRB='1' then

                update_now  <= '1' ;                
                busy_flag   <= '1';

                case INFO_CMD.CMD is

                    when cmd_init => 

                        game_score.INT_NUM  <= 0;                                                 
                        lines_count.INT_NUM <= 0;
                        level.INT_NUM       <= 1;
                        rounds.INT_NUM      <= C_AI_ROUNDS;
                       
                        update_info         <= i_update_all;

                    when cmd_score =>

                        if game_score.INT_NUM + INFO_CMD.DATA.INT_NUM <= C_MAX_SCORE then  

                            game_score.INT_NUM  <= game_score.INT_NUM + INFO_CMD.DATA.INT_NUM; 
                            update_info         <= i_update_score;

                            if game_score.INT_NUM + INFO_CMD.DATA.INT_NUM > top_score.INT_NUM then

                                top_score.INT_NUM  <= game_score.INT_NUM + INFO_CMD.DATA.INT_NUM;
                                --update_info        <= i_update_top;
                                                            
                            end if;
                        end if;

                    when  cmd_lines =>

                        if GAME_MODE = sp_mode then 

                            update_info <= i_update_lines;

                            if lines_count.INT_NUM + INFO_CMD.DATA.INT_NUM < C_MAX_LINES - 1 then
                                lines_count.INT_NUM <= lines_count.INT_NUM + INFO_CMD.DATA.INT_NUM;
                            end if;
                        else
                            update_now  <= '0' ;                
                            busy_flag   <= '0';
                            DONE        <= '1';
                        end if;


                    when  cmd_level =>

                        if GAME_MODE = sp_mode then 
                            update_info     <= i_update_level;
                            level.INT_NUM   <= level.INT_NUM + 1;
                        else
                            update_now  <= '0' ;                
                            busy_flag   <= '0';
                            DONE        <= '1';
                        end if;



                    when cmd_rounds =>

                        update_info     <= i_update_rounds;
                        rounds.INT_NUM  <= rounds.INT_NUM - 1;

                    when cmd_stats =>

                        update_info <= i_update_stats;

                    when cmd_game_over =>

                        update_info <= i_update_game_over;                        

                end case;
              
            end if;

        else
            
            update_now      <= '0'; 
            if update_done='1' then 
                busy_flag       <= '0';
                DONE            <= '1';
            end if;
        end if;

    end if;
end process;


---------------------------------------------------------------------------
-- Update SRAM
---------------------------------------------------------------------------    

process (CLK, RST_N)
begin
	if RST_N = '0' then
		        
        update_fsm  <= s_idle;
        next_state  <= s_idle;
        mem_tile    <= (0,0);
        adder_len   <= C_SCORE_DIGITS;
        adder_start <= '0';
        adder_op    <= '0';
        update_done <= '0';
        stats_counter   <= 1;
        for i in 0 to C_SCORE_DIGITS-1 loop 
            adder_in_1(i)   <= 0;
            adder_in_2(i)   <= 0;
        end loop;
        game_score.BCD_NUM  <=  (others => 0);
        top_score.BCD_NUM   <=  (others => 0);
        lines_count.BCD_NUM  <=  (others => 0);
        level.BCD_NUM       <= C_BCD_0;
        rounds.BCD_NUM      <= C_BCD_100;
        game_over           <= '0';

        for i in 1 to C_NUM_OF_BRICKS loop            
            stats_arr(i).BCD_NUM     <= (others => 0);
        end loop;
              
    elsif rising_edge(CLK) then

        update_done             <= '0';

        case update_fsm is 

            when s_idle => 
                game_over       <= '0';
                adder_op        <= '0';

                if update_now = '1' then 
                    
                    update_fsm  <= s_wait_screen;
                end if;
            
            when s_wait_screen =>

                if VIDEO_SYNC.VSYNC_TRIG = '1' or C_SIM = 1 then

                    case update_info is 
                        when i_update_all   => 
                            update_fsm              <= s_update_score; 
                            game_score.BCD_NUM      <=  (others => 0);
                            lines_count.BCD_NUM     <=  (others => 0);
                            level.BCD_NUM           <= C_BCD_0;
                            rounds.BCD_NUM          <= C_BCD_100;
                            for i in 1 to C_NUM_OF_BRICKS loop            
                                stats_arr(i).BCD_NUM     <= (others => 0);
                            end loop;

                        when i_update_score => update_fsm  <= s_update_score;
                        when i_update_rounds=> update_fsm  <= s_update_rounds;
                        when i_update_lines => update_fsm  <= s_update_lines;
                        when i_update_level => update_fsm  <= s_update_level;
                        when i_update_stats => update_fsm  <= s_update_stats;
                        when i_update_game_over => update_fsm  <= s_update_game;
                        when others         => update_fsm  <= s_idle;
                    end case;
                                        
                end if;

            when s_update_score =>

                adder_in_1  <= game_score.BCD_NUM;
                adder_in_2  <= INFO_CMD.DATA.BCD_NUM;
                adder_len   <= C_SCORE_DIGITS;
                adder_start <= '1';

                if adder_done='1' then
                    adder_start     <= '0';
                    update_fsm      <= s_mem_update;                   
                    mem_tile        <= (score_tile_x_offset, score_tile_y_offset );       
                    game_score.BCD_NUM <= adder_out;     
                    if game_score.INT_NUM >= top_score.INT_NUM then
                        top_score.BCD_NUM   <= adder_out;
                    end if;       

                    if GAME_MODE = sp_mode then                                        
                        next_state      <= s_update_top_score;
                    else
                        if update_info = i_update_all then
                            next_state      <= s_update_rounds;
                        else
                            next_state      <= s_idle;                        
                        end if;
                    end if;
                end if;

               
            when s_update_top_score =>
                
                adder_in_1      <= top_score.BCD_NUM;
                adder_in_2      <= C_BCD_0;
                adder_len       <= C_SCORE_DIGITS;
                adder_start     <= '1';

                if adder_done='1' then

                    adder_start     <= '0';
                    update_fsm      <= s_mem_update;                   
                    mem_tile        <= (score_tile_x_offset, C_TOP_SCORE_TILE_Y);                                       
                                       
                    if update_info = i_update_all then
                        next_state      <= s_update_level;
                    else
                        next_state      <= s_idle;                        
                    end if;
                end if;

            when s_update_level =>

                adder_len       <= C_LEVEL_DIGITS;                                
                adder_in_1      <= level.BCD_NUM;
                adder_in_2      <= C_BCD_1;
                adder_start     <= '1';
                           
                if adder_done='1' then
                    adder_start     <= '0';
                    update_fsm      <= s_mem_update;       
                    mem_tile        <= (level_tile_x, level_tile_y);  
                    level.BCD_NUM   <= adder_out;   
                        
                    if update_info = i_update_all then
                        -- if GAME_MODE=sp_mode then 
                            next_state      <= s_update_lines;
                        -- else
                            -- next_state      <= s_update_rounds;
                        -- end if;
                    else
                        next_state      <= s_idle;                        
                    end if;  
                    
                end if; 
              
            when s_update_rounds =>

                adder_len       <= C_ROUND_DIGITS;                                
                adder_in_1      <= rounds.BCD_NUM;
                adder_in_2      <= C_BCD_1;
                adder_start     <= '1';
                adder_op        <= '1';
                        
                if adder_done='1' then
                    adder_start     <= '0';
                    update_fsm      <= s_mem_update;       
                    mem_tile        <= (C_AI_ROUNDS_TILE_X, C_AI_ROUNDS_TILE_Y);  
                    rounds.BCD_NUM   <= adder_out;   
                        
                    if update_info = i_update_all then                         
                        next_state      <= s_update_stats;                        
                    else
                        next_state      <= s_idle;                        
                    end if;  
                    
                end if; 

            when s_update_lines =>

                adder_in_1  <= lines_count.BCD_NUM;
                adder_in_2  <= INFO_CMD.DATA.BCD_NUM;
                adder_len   <= C_STATS_DIGITS;
                adder_start <= '1';

                if adder_done='1' then
                    adder_start     <= '0';                    
                    update_fsm      <= s_mem_update;       
                    mem_tile        <= (lines_tile_x, lines_tile_y);  
                    lines_count.BCD_NUM  <= adder_out;         

                    if update_info = i_update_all then
                        next_state      <= s_update_stats; 
                    else
                        next_state      <= s_idle;                        
                    end if;
                  
                end if;                

            when s_update_stats =>

                if update_info = i_update_all then
                    adder_in_1  <= stats_arr(stats_counter).BCD_NUM;
                    adder_in_2  <= C_BCD_0;
                else
                    adder_in_1  <= stats_arr(INFO_CMD.DATA.INT_NUM).BCD_NUM;
                    adder_in_2  <= C_BCD_1;
                end if;
                
                adder_len   <= C_STATS_DIGITS;
                adder_start <= '1';

                if adder_done='1' then
                    adder_start     <= '0';
                    update_fsm      <= s_mem_update;       
                                     
                    if update_info = i_update_all then

                        mem_tile        <= (stats_tile_x, C_STATS_TILE_Y(stats_counter)); 
                         
                        stats_arr(stats_counter).BCD_NUM <= adder_out;
                        if stats_counter < C_NUM_OF_BRICKS then 
                            stats_counter <= stats_counter + 1;
                            next_state      <= s_update_stats;
                            adder_start     <= '1';
                        else
                            next_state      <= s_idle; 
                            stats_counter   <= 1;
                        end if;
                    else
                        mem_tile        <= (stats_tile_x, C_STATS_TILE_Y(INFO_CMD.DATA.INT_NUM));                         
                        next_state      <= s_idle;   
                        stats_arr(INFO_CMD.DATA.INT_NUM).BCD_NUM  <= adder_out;                   
                    end if;                        
                   
                  
                end if;     

            when s_update_game =>     
            
                game_over       <= '1';
                adder_len       <= 4; 
            
                update_fsm      <= s_mem_update;       
                mem_tile        <= (C_END_TILE_X, C_END_TILE_Y); 
                next_state      <= s_update_over;
               

            when s_update_over =>     
                                           
                update_fsm      <= s_mem_update;       
                mem_tile        <= (C_END_TILE_X + 5, C_END_TILE_Y); 
                next_state      <= s_idle;
                                            
            when s_mem_update =>


                if update_counter < adder_len-1 then 
                    update_counter  <= update_counter + 1;
                else
                    update_counter  <= 0;
                    update_fsm      <= next_state; 
                    if next_state = s_idle then
                        update_done     <= '1';
                    end if;                   
                end if;
            
           

               

        end case;

    end if;
end process;

SRAM_INTERFACE.WRADDR   <= std_logic_vector(to_unsigned(mem_tile.Y * C_X_TILE_COUNT + mem_tile.X + update_counter, SRAM_INTERFACE.WRADDR'length));
SRAM_INTERFACE.WEN      <= '1' when update_fsm = s_mem_update else '0' ;
SRAM_INTERFACE.DATA     <=  "1000000" & std_logic_vector(to_unsigned(C_BCD_TO_TEXT(adder_out(adder_len-1 - update_counter)),6)) & "000" when game_over='0' else
                            "1000000" & std_logic_vector(to_unsigned(C_GAME_TEXT(update_counter),6)) & "000" when next_state = s_update_over else
                            "1000000" & std_logic_vector(to_unsigned(C_OVER_TEXT(update_counter),6)) & "000" ;


---------------------------------------------------------------------------
--BCD ADDER
---------------------------------------------------------------------------    

addr_u : entity work.bcd_adder
generic map
(
    G_NUM_DIGITS    => C_SCORE_DIGITS   
)   
port map
(	
    CLK	    	=> CLK ,    --  : in std_logic ;			
    RST_N 		=> RST_N,    --  : in std_logic ;

    START 		=> adder_start,    --  : in std_logic ;
    OPERATION   => adder_op,
    MAX_LEN     => adder_len, 

    NUM_IN_1    => adder_in_1,    --  : in t_digits_arr( 0 to G_NUM_DIGITS-1);
    NUM_IN_2    => adder_in_2,    --  : in t_digits_arr( 0 to G_NUM_DIGITS-1);

    NUM_OUT     => adder_out ,    --  : out t_digits_arr( 0 to G_NUM_DIGITS-1);

    DONE 	    => adder_done    --  : out std_logic

);

end info_module_arch;
 
	
	
	
	
	
