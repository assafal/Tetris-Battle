library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library WORK;
use WORK.top_pack.all;
use WORK.brick_position_pack.all;


entity game_machine is 
port
(	
	CLK	    	: in std_logic ;			
    RST_N 		: in std_logic ;

    CLEAR 		: in std_logic ;

    VIDEO_SYNC  : in t_video_sync;

    GAME_MODE   : in t_game_mode;
    GAME_START  : in std_logic;
    GAME_STOP   : in std_logic;
    INFO_DONE   : in std_logic;
    PLAYER_READY_IN   : in std_logic;

    MILI_SEC_TIC	: in std_logic;
    DROP_TIC	    : in std_logic;
    RAND_VECT       : in std_logic_vector(15 downto 0);

    USR_CMD 	    : in t_usr_cmd_rec ;

    GAME_TILE_X_OFFSET    : in integer range 0 to C_X_TILE_COUNT-1;
    GAME_TILE_Y_OFFSET    : in integer range 0 to C_Y_TILE_COUNT-1;

    --CURRENT_BRICK_IN    : in  t_brick_info;
    --NEXT_BRICK_IN       : in  t_brick_info;
    
    INFO_CMD 	    : out t_update_info_cmnd_rec ;
    SRAM_INTERFACE  : out t_sram_cmnd_rec;
    SRAM_RDADDR     : out std_logic_vector(10 downto 0);
    SRAM_DATA_IN    : in std_logic_vector(15 downto 0);
    LEVEL 		    : out integer range 1 to 10 ;
	
	PLAYER_READY_OUT    : out std_logic;
	GAME_DONE           : out std_logic;

    AI_UPDTAE           : out std_logic;
    AI_NEXT_BRICK       : out  t_brick_info;
    AI_CURRENT_BRICK    : out  t_brick_info
    

);
end game_machine;

architecture game_machine_arch of game_machine is



---------------------------------------------------------------------------
-- Components
---------------------------------------------------------------------------
attribute noprune: boolean;


---------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------- 

constant C_FREE     : std_logic := '1';
constant C_BLOCKED  : std_logic := '0';

constant C_FLASH_FRAME_COUNT    : integer := 6;

type t_game_machine is (s_idle, s_init_done, s_wait, s_new_brick, s_move, s_lines, s_info_update_lines, s_info_update_level, s_info_update_done, s_info_update_round, s_game_over);    
type t_move_machine is (s_idle, s_done, s_wait, s_read, s_write, s_write_next, s_copy, s_move_main, s_lines_main);    
type t_wait_on_src is (i_info, i_move, i_hsync, i_vsync, i_interupt, i_drop, i_player);
type t_move_fsm is (s_read, s_write, s_delete, s_write_next, s_delete_next, s_done);
type t_lines_fsm is (s_lines_loop, s_lines_read, s_lines_delete, s_lines_frames, s_lines_copy_loop, s_lines_done);


---------------------------------------------------------------------------
-- Signals
---------------------------------------------------------------------------

signal fsm 	            :	t_game_machine;
signal next_state       :	t_game_machine;
signal next_brick       :   t_brick_info;
signal current_brick    :   t_brick_info;
signal zero_brick       :   t_brick;

signal wait_on_source   :   t_wait_on_src;   
signal wait_on_source_mm   :   t_wait_on_src;   

signal move_machnie_cmd :   t_usr_cmd_rec;
signal usr_int          :   t_usr_cmd_rec;
signal wait_done        :   std_logic;
signal mm_fsm           :   t_move_machine;
signal mm_next_state    :   t_move_machine;
signal current_process  :   t_move_machine;
signal move_fsm         :   t_move_fsm;
signal read_addr_buf    :   t_game_pos_arr;
signal write_addr_buf   :   t_tile_pos_arr; 
signal mm_return_stat   :   std_logic; 
signal move_machnie_done   :   std_logic; 
signal move_counter     :   integer range 0 to C_GAME_ZONE_X_SIZE;
signal read_counter     :   integer range 0 to C_GAME_ZONE_X_SIZE;
signal write_counter    :   integer range 0 to C_GAME_ZONE_X_SIZE;
signal dealy_counter    :   integer range 0 to C_MEM_DELAY+1;
signal mem_rd_addr      :   std_logic_vector(10 downto 0);
signal mem_wr_addr      :   std_logic_vector(10 downto 0);
signal mem_data         :   std_logic_vector(15 downto 0);
signal mem_data_buf     :   std_logic_vector(0 to C_GAME_ZONE_X_SIZE-1); --t_mem_data_arr; 
signal mem_wen          :   std_logic; 
signal drop_int         :   std_logic;
signal move_dir         :   integer range 0 to C_NUM_OF_MOVES-1;
signal elements_del     :   t_brick_move_pos;
signal lines_fsm        :   t_lines_fsm;
signal frames_count     :   integer range 0 to C_FLASH_FRAME_COUNT-1;
signal current_line     :   integer range 0 to C_GAME_ZONE_Y_SIZE;
signal current_copy_line     :   integer range 0 to C_GAME_ZONE_Y_SIZE;
signal copy_counter     :   integer range 0 to C_GAME_ZONE_X_SIZE;
signal removed_lines_counter    :   integer range 0 to 4;
signal removed_lines    :   integer range 0 to 4;
signal level_int        :   integer range 1 to C_MAX_LEVEL;
signal lines_count      :   integer range 0 to C_LINES_PER_LEVEL;
signal game_over        :   std_logic;
signal drop_flag        :   std_logic;
signal ai_rounds        :   integer range 1 to C_AI_ROUNDS;

signal next_offsets_arr :   t_bricks_next_pos_arr;



attribute noprune of fsm: signal is true;    
attribute noprune of mm_fsm: signal is true;    
attribute noprune of move_fsm: signal is true;    

begin

SRAM_INTERFACE.WRADDR   <= mem_wr_addr;
SRAM_INTERFACE.DATA     <= mem_data;
SRAM_INTERFACE.WEN      <= mem_wen;

LEVEL                   <=  level_int ;

next_offsets_arr        <=  C_AI_NEXT_POS_ARR when GAME_MODE = ai_mode else C_NEXT_POS_ARR;
 
---------------------------------------------------------------------------
-- GAME FSM
---------------------------------------------------------------------------    

process (CLK, RST_N)
variable rand_brick     : integer range 0 to C_NUM_OF_BRICKS;
variable rand_pos_arr   : t_init_pos_arr;
variable rand_rot       : integer range 0 to 3;
variable var_score      : integer range 0 to 511;
variable var_score_bcd  : std_logic_vector (11 downto 0);
begin
	if RST_N = '0' then
		
        fsm                     <=  s_idle;
        next_state              <=  s_idle;        
        INFO_CMD                <= ('0' , cmd_init, (0, (others => 0)));
        usr_int                 <= ('0' , cmd_down);
        next_brick              <=  (1 , C_INIT_POS, 0) ;
        current_brick           <=  (1 , C_INIT_POS, 0) ;        
        move_dir                <=  C_INSERT;
       
        wait_on_source          <=  i_info;
        move_machnie_cmd        <=  ('0', cmd_down); -- == Test position
        level_int               <=  1 ;
        zero_brick              <=  1;
        lines_count             <= 0;
        ai_rounds               <= C_AI_ROUNDS;
        drop_flag               <= '0';

        wait_done                <= '0';
        drop_int                 <= '0';
        game_over                <= '0';
        
        GAME_DONE               <= '0';
        PLAYER_READY_OUT        <= '0';

        AI_UPDTAE               <= '0' ;
        AI_NEXT_BRICK           <= (1 , C_INIT_POS, 0) ;
        AI_CURRENT_BRICK        <= (1 , C_INIT_POS, 0) ;

    elsif rising_edge(CLK) then

       
        rand_brick  := to_integer(unsigned(RAND_VECT(2 downto 0)));
        if rand_brick = 0 then
            rand_brick := zero_brick;
            if zero_brick < C_NUM_OF_BRICKS then
                zero_brick <= zero_brick + 1;
            else
                zero_brick <= 1;
            end if;
        end if;
        rand_rot    := to_integer(unsigned(RAND_VECT(4 downto 3)));
    

        move_machnie_cmd.STRB   <= '0';                
        AI_UPDTAE               <= '0' ;     

        if (DROP_TIC = '1' or drop_flag='1') and fsm /= s_idle then 
            drop_int <= '1';  -- Latch the drop interupt.
        end if;

        if USR_CMD.STRB = '1' and fsm /= s_idle then
            usr_int <= USR_CMD;
        end if;

        if CLEAR = '1' then

            fsm                     <=  s_idle;
            next_state              <=  s_idle;        
            INFO_CMD                <= ('0' , cmd_init, (0, (others => 0)));
            usr_int                 <= ('0' , cmd_down);
            next_brick              <=  (1 , C_INIT_POS, 0) ;
            current_brick           <=  (1 , C_INIT_POS, 0) ;        
            move_dir                <=  C_INSERT;
           
            wait_on_source          <=  i_info;
            move_machnie_cmd        <=  ('0', cmd_down); -- == Test position
            level_int               <=  1 ;
            zero_brick              <=  1;
            lines_count             <= 0;
            ai_rounds               <= C_AI_ROUNDS;
            drop_flag               <= '0';
    
            wait_done                <= '0';
            drop_int                 <= '0';
            game_over                <= '0';
            
            GAME_DONE               <= '0';
            PLAYER_READY_OUT        <= '0';
    
            AI_UPDTAE               <= '0' ;
            AI_NEXT_BRICK           <= (1 , C_INIT_POS, 0) ;
            AI_CURRENT_BRICK        <= (1 , C_INIT_POS, 0) ;
        else            


            case fsm is 

                when s_idle =>

                    if game_over = '1' then 
                        GAME_DONE           <= '1';
                        game_over           <= '0';
                        
                    
                    elsif GAME_START = '1' then

                        if GAME_MODE = sp_mode then
                            level_int       <= 1;
                        else
                            level_int       <= 3;
                        end if;
                        lines_count     <= 0;
                        ai_rounds       <= C_AI_ROUNDS;
                        GAME_DONE       <= '0';
                    
                        wait_on_source  <=  i_info;
                        fsm             <=  s_wait;                
                        next_state      <=  s_init_done; -- s_new_brick;                                            
                        INFO_CMD        <= ('1' , cmd_init, (0, (others => 0)));                     
                    
                        -- The first Brick                    
                        rand_pos_arr        := C_INIT_POS_ARR(rand_brick);
                        next_brick.BTYPE    <= rand_brick;
                        next_brick.ROT      <= rand_rot;
                        next_brick.POS      <= rand_pos_arr(rand_rot); 
                        current_brick.BTYPE    <= rand_brick;
                        current_brick.ROT      <= rand_rot;
                        current_brick.POS      <= rand_pos_arr(rand_rot);                                                          
                                        
                    end if;
            

                when s_init_done =>

                    wait_on_source      <=  i_drop;
                    fsm                 <=  s_wait;                
                    next_state          <=  s_new_brick;         
                    PLAYER_READY_OUT    <= '1';                                   
    
                when s_new_brick =>

                    if GAME_MODE = ai_mode and ai_rounds = 1 then   
                        fsm <=  s_game_over;
                    else
                        -- Randomize a new Next brick                                                       
                        next_brick.BTYPE    <= rand_brick;
                        next_brick.ROT      <= rand_rot;
                        rand_pos_arr        := C_INIT_POS_ARR(rand_brick);
                        next_brick.POS      <= rand_pos_arr(rand_rot);
                        current_brick       <= next_brick;
                                        
                        -- Update the info tab
                        INFO_CMD.CMD            <= cmd_stats;
                        INFO_CMD.DATA.INT_NUM   <= next_brick.BTYPE;
                        INFO_CMD.DATA.BCD_NUM   <=(1,0,0,0,0,0);
                        INFO_CMD.STRB           <= '1';
                        wait_on_source          <=  i_info;
                        fsm                     <=  s_wait;                
                        next_state              <=  s_move; 
                        move_dir                <=  C_INSERT;

                        usr_int.STRB            <= '0'; --Clear user interupt

                        AI_UPDTAE               <= '1' ;
                        AI_NEXT_BRICK.BTYPE    <= rand_brick;
                        AI_NEXT_BRICK.ROT      <= rand_rot;                
                        AI_NEXT_BRICK.POS      <= rand_pos_arr(rand_rot);
                        AI_CURRENT_BRICK        <= next_brick ;
                    end if;
            
                
                when s_move =>
                -- Test and insert 
                    --PLAYER_READY_OUT        <= '0';
                if wait_done = '0' then
                        wait_on_source          <=  i_move; 
                        fsm                     <=  s_wait;
                        move_machnie_cmd.STRB   <=  '1';
                        move_machnie_cmd.CMD    <=  cmd_move; 
                        next_state              <=  s_move; 
                    else
                        wait_done   <= '0';
                        -- Check the move_machine result
                        if mm_return_stat then
                            --Update position and rotation
                            current_brick.POS   <= UpdatePos(current_brick.POS, move_dir);
                            current_brick.ROT   <= UpdateRot(current_brick.ROT, move_dir);
                            --Move on...
                            wait_on_source          <=  i_interupt; 
                            fsm                     <=  s_wait;
                        else
                            drop_flag <= '0';
                            drop_int  <= '0';

                            if move_dir = C_INSERT then 
                                --TODO Game Over!
                                fsm             <=  s_game_over;
                            else
                                if move_dir = C_DOWN then 
                                    -- Test if lines can be removed
                                    fsm                     <=  s_lines;
                                else
                                    wait_on_source          <=  i_interupt; 
                                    fsm                     <=  s_wait;
                                end if;
                            end if;
                        end if;
                    end if;

                when s_lines =>

                    if wait_done = '0' then
                        wait_on_source          <=  i_move; 
                        fsm                     <=  s_wait;
                        move_machnie_cmd.STRB   <=  '1';
                        move_machnie_cmd.CMD    <=  cmd_lines; 
                        next_state              <=  s_lines;
                    else
                        wait_done   <= '0';
                        if removed_lines > 0 then 
                            
                            -- Scoring method:
                            -- 1 line : 4*(level)
                            -- 2 line : 8*(level)
                            -- 3 line : 16*(level)
                            -- 4 line : 32*(level)
                            -- Update the info tab
                            var_score               := level_int*(2**(removed_lines+1));
                            var_score_bcd           := to_bcd(var_score);
                            INFO_CMD.CMD            <= cmd_score;
                            INFO_CMD.DATA.INT_NUM   <= var_score; 
                            INFO_CMD.DATA.BCD_NUM   <=(to_digit(var_score_bcd(3 downto 0)), to_digit(var_score_bcd(7 downto 4)),
                                                        to_digit(var_score_bcd(11 downto 8)),0,0,0);
                            INFO_CMD.STRB           <= '1';
                            wait_on_source          <=  i_info;
                            fsm                     <=  s_wait;                
                            
                            if lines_count + removed_lines < C_LINES_PER_LEVEL then
                                lines_count <= lines_count + removed_lines;
                                next_state              <=  s_info_update_lines;
                            else
                                lines_count <= 0;
                                if level_int <= C_MAX_LEVEL-1 and GAME_MODE=sp_mode then
                                    level_int <= level_int + 1;
                                    next_state              <=  s_info_update_level;
                                else
                                    next_state              <=  s_info_update_lines;
                                end if;
                            end if;

                            if GAME_MODE = ai_mode then 
                                if ai_rounds > 1 then   
                                    ai_rounds   <= ai_rounds - 1;
                                end if;
                            end if;
                
                        else
                            -- done
                            
                            wait_on_source          <=  i_drop; 
                            --PLAYER_READY_OUT        <= '1';                       
                            fsm                     <=  s_wait;
                            next_state              <=  s_new_brick;    
                            drop_flag               <= '0';                            
                            drop_int                <= '0'; 
                            if GAME_MODE = ai_mode then 
                                fsm                 <=  s_info_update_round; 
                                PLAYER_READY_OUT    <= '0';
                                if ai_rounds > 1 then   
                                    ai_rounds   <= ai_rounds - 1;
                                end if;
                            else
                                PLAYER_READY_OUT        <= '1';                        
                            end if;

                        end if;

                    end if;

                when s_info_update_level =>
                
                    -- Update the info tab
                    INFO_CMD.CMD            <= cmd_level;
                    INFO_CMD.DATA.INT_NUM   <= level_int; --move_lines ;
                    INFO_CMD.DATA.BCD_NUM   <= (1,0,0,0,0,0);
                    INFO_CMD.STRB           <= '1';
                    wait_on_source          <=  i_info;
                    fsm                     <=  s_wait;                
                    next_state              <=  s_info_update_lines;                 
                
                when s_info_update_lines =>
                
                    -- Update the info tab
                    INFO_CMD.CMD            <= cmd_lines;
                    INFO_CMD.DATA.INT_NUM   <= removed_lines; --move_lines ;
                    INFO_CMD.DATA.BCD_NUM   <=(removed_lines,0,0,0,0,0);
                    INFO_CMD.STRB           <= '1';
                    wait_on_source          <=  i_info; 
                    fsm                     <=  s_wait;                
                    if GAME_MODE = ai_mode then 
                        next_state         <=  s_info_update_round; 
                    else
                        next_state         <=  s_info_update_done;                                        
                    end if; 
                            
                when s_info_update_done =>

                    fsm                     <=  s_wait;                
                    wait_on_source          <=  i_drop; 
                    next_state              <=  s_new_brick; 
                    drop_flag               <=  '0';                
                    drop_int                <=  '0';                
                    PLAYER_READY_OUT        <= '1';

                when s_info_update_round =>

                    -- Update the info tab
                    INFO_CMD.CMD            <= cmd_rounds;
                    INFO_CMD.DATA.INT_NUM   <= ai_rounds; 
                    INFO_CMD.DATA.BCD_NUM   <= (0,0,0,0,0,0);
                    INFO_CMD.STRB           <= '1';
                    wait_on_source          <=  i_info; 
                    fsm                     <=  s_wait;                
                    next_state              <=  s_info_update_done; 
                
                when s_game_over =>

                    INFO_CMD.CMD            <= cmd_game_over;
                    INFO_CMD.STRB           <= '1';
                    wait_on_source          <=  i_info;
                    fsm                     <=  s_wait;                
                    next_state              <=  s_idle;    
                    game_over               <= '1';  
                    PLAYER_READY_OUT        <= '1';                       


                when s_wait =>
            
                    case wait_on_source is 
                        
                        when i_info =>  
                            INFO_CMD.STRB   <= '0';
                            if INFO_DONE='1' then 
                                fsm         <=  next_state; 
                            end if;
                        
                        when i_move =>  
                            move_machnie_cmd.STRB   <= '0';
                            if move_machnie_done ='1' then 
                                fsm         <=  next_state;   
                                wait_done   <=  '1';                          
                            end if;
                        
                        when i_interupt =>
                            --Wait for user command, drop interupt or game end from other player

                            if GAME_STOP = '1' then -- and GAME_MODE = ai_mode then 
                                fsm         <=  s_game_over;
                            elsif drop_int='1' then 
                                drop_int    <= '0';
                                fsm         <=  s_move;
                                move_dir    <=  C_DOWN;
                            elsif usr_int.STRB='1' then 
                                usr_int.STRB <= '0';
                                fsm         <=  s_move;
                                move_dir    <=  UsrCmnd2Move(usr_int.CMD);
                                if usr_int.CMD = cmd_drop then
                                    drop_flag <= '1';
                                end if;

                            end if;

                        when i_drop =>  --Wait for drop event before inerting a new brick
                            if drop_int='1' then 
                                drop_int    <= '0';
                                if PLAYER_READY_IN='1' or GAME_MODE = sp_mode then
                                    fsm                 <=  next_state;
                                    PLAYER_READY_OUT    <= '0';
                                else
                                    drop_int    <= '0'; --Stay until other player is ready
                                end if;

                            end if;

                
                        when others =>  
                            fsm         <=  next_state;
                    end case;
                        
            end case;
        
        end if;
    end if;
end process;

---------------------------------------------------------------------------
-- Move Machine FSM
---------------------------------------------------------------------------    

SRAM_RDADDR <= mem_rd_addr;

process (CLK, RST_N)
variable var_delta_res      : t_pos_calc_res;
variable var_stat           : std_logic;
variable var_addr           : t_tile_pos;
variable rand_pos_arr       : t_next_pos_arr;

variable var_brick_map           : t_brick_move_arr; 
variable var_brick_move          : t_brick_move_map; 
variable var_brick_move_rot      : t_brick_move_rec; 

begin
    if RST_N = '0' then

        mm_fsm          <= s_idle;
        mm_next_state   <=  s_idle;
        current_process <= s_move_main;
        move_fsm        <= s_read; 
        wait_on_source_mm   <= i_vsync;
        read_addr_buf   <= (others => (0,0));
        write_addr_buf  <= (others => (0,0));
        mem_rd_addr     <= (others => '0');
        mem_wr_addr     <= (others => '0');
        mem_data        <= (others => '0');
        mem_wen         <= '0';
        move_counter    <= 0;
        read_counter    <= 0;
        write_counter   <= 0;
        dealy_counter   <= 0;
        copy_counter    <= 0;
        frames_count    <= 0;
        current_line    <= 0;
        removed_lines   <= 0;
        removed_lines_counter   <= 0;
        current_copy_line <= 0;
        mm_return_stat  <= C_OK;
        move_machnie_done   <=  '0'; 
        elements_del    <= (others => (0,0));

    elsif rising_edge(CLK) then

        if CLEAR = '1' then

            mm_fsm          <= s_idle;
            mm_next_state   <=  s_idle;
            current_process <= s_move_main;
            move_fsm        <= s_read; 
            wait_on_source_mm   <= i_vsync;
            read_addr_buf   <= (others => (0,0));
            write_addr_buf  <= (others => (0,0));
            mem_rd_addr     <= (others => '0');
            mem_wr_addr     <= (others => '0');
            mem_data        <= (others => '0');
            mem_wen         <= '0';
            move_counter    <= 0;
            read_counter    <= 0;
            write_counter   <= 0;
            dealy_counter   <= 0;
            copy_counter    <= 0;
            frames_count    <= 0;
            current_line    <= 0;
            removed_lines   <= 0;
            removed_lines_counter   <= 0;
            current_copy_line <= 0;
            mm_return_stat  <= C_OK;
            move_machnie_done   <=  '0'; 
            elements_del    <= (others => (0,0));
        
        else
            case mm_fsm is 

                when s_idle =>

                    move_machnie_done   <=  '0';                                 
                    mem_rd_addr         <= (others => '0');
                    move_fsm            <= s_read;
                    lines_fsm            <= s_lines_loop;
                    removed_lines_counter   <= 0;


                    if move_machnie_cmd.STRB = '1' then

                        case move_machnie_cmd.CMD is 

                            when cmd_move =>

                                current_process <= s_move_main;
                                mm_fsm          <= s_move_main;
                            
                            when cmd_lines =>

                                current_process <= s_lines_main;
                                mm_fsm          <= s_lines_main;
                                current_line    <= C_GAME_ZONE_Y_SIZE;

                            when others =>

                                mm_fsm          <= s_done;

                        end case;
                    end if;

                when s_move_main => 


                    case move_fsm is

                        when s_read => 
                            var_brick_map           := C_MOVE_MAP(current_brick.BTYPE); 
                            var_brick_move          := var_brick_map(current_brick.ROT);
                            var_brick_move_rot      := var_brick_move(move_dir);

                            read_counter            <= var_brick_move_rot.count;  
                            move_counter            <= var_brick_move_rot.count;                        
                            elements_del            <= var_brick_move_rot.elements_del;

                            var_stat         := '1';
                            
                            for i in 0 to 3 loop

                                if i < var_brick_move_rot.count then 

                                    var_delta_res := AddDelta(var_brick_move_rot.elements_rw(i), current_brick.POS);

                                    if var_delta_res.stat = true then

                                        read_addr_buf(i)  <= ToGameTile(var_delta_res.res);    
                                        write_addr_buf(i) <= var_delta_res.res;  
                                    else
                                        var_stat         := '0';                                                      
                                    end if;
                                end if;
                            end loop;

                            if var_stat='1' then
                                mm_fsm          <= s_wait;
                                mm_next_state   <= s_read;
                                wait_on_source_mm   <= i_vsync;
                                move_fsm        <= s_write;
                            else
                                mm_return_stat  <= C_ERROR ; 
                                mm_fsm          <= s_done;
                                move_fsm        <= s_read;
                            end if;

                        when s_write =>
                            
                            if mm_return_stat = C_OK then
                                --Read was OK
                                write_counter       <= move_counter;
                                mm_fsm              <= s_wait;
                                mm_next_state       <= s_write;
                                wait_on_source_mm   <= i_vsync;
                                if move_dir = C_INSERT then
                                    move_fsm            <= s_delete_next; 
                                else
                                    move_fsm            <= s_delete;
                                end if;

                                mem_data <= C_GAME_TILE & "00000000000" & std_logic_vector(to_unsigned(current_brick.BTYPE,3));                                    
                            else

                                move_fsm            <= s_done;
                                
                            end if;

                        when s_delete =>

                            write_counter       <= move_counter;
                            
                            for i in 0 to 3 loop

                                if i < move_counter then 

                                    var_delta_res := AddDelta(elements_del(i), current_brick.POS);

                                    write_addr_buf(i) <= var_delta_res.res;  
                                end if;
                            end loop;                                

                            mm_fsm              <= s_wait;
                            mm_next_state       <= s_write;
                            wait_on_source_mm   <= i_vsync;
                            move_fsm            <= s_done;

                            mem_data <= C_GRID_TILE;

                        when s_delete_next =>

                            var_brick_map           := C_MOVE_MAP(current_brick.BTYPE); 
                            var_brick_move          := var_brick_map(current_brick.ROT);
                            var_brick_move_rot      := var_brick_move(C_INSERT);

                            write_counter    <= 4;                                                        

                            rand_pos_arr := next_offsets_arr(current_brick.BTYPE); -- Add Offsets for ai mode

                            for i in 0 to 3 loop
                                var_delta_res := AddDelta(var_brick_move_rot.elements_rw(i), rand_pos_arr(current_brick.ROT));
                                write_addr_buf(i) <= var_delta_res.res;                                          
                            end loop;

                            mem_data <= C_GAME_TILE & "00000000000000" ;

                            mm_fsm          <= s_wait;
                            mm_next_state   <= s_write_next; 
                            wait_on_source_mm   <= i_vsync;
                            move_fsm        <= s_write_next;  



                        when s_write_next =>

                            var_brick_map           := C_MOVE_MAP(next_brick.BTYPE); 
                            var_brick_move          := var_brick_map(next_brick.ROT);
                            var_brick_move_rot      := var_brick_move(C_INSERT);

                            write_counter    <= 4;                                                        

                            rand_pos_arr := next_offsets_arr(next_brick.BTYPE);
                            
                            for i in 0 to 3 loop
                                var_delta_res := AddDelta(var_brick_move_rot.elements_rw(i), rand_pos_arr(next_brick.ROT));
                                write_addr_buf(i) <= var_delta_res.res;                                          
                            end loop;
                            mem_data <= C_GAME_TILE & "00000000000" & std_logic_vector(to_unsigned(next_brick.BTYPE,3));

                            mm_fsm          <= s_wait;
                            mm_next_state   <= s_write_next; 
                            wait_on_source_mm   <= i_vsync;
                            move_fsm        <= s_done;                                    

                        when s_done =>
                            mm_fsm              <= s_done;
                            move_fsm            <= s_read;
                    end case;            

                when s_lines_main => 

                            --  For current_line in bottom (19) to top (0):
                            --      For each line, read all the tiles (0..9). 
                            --      If all are not empty:
                            --          (for display)
                            --              Delete all tiles in the line. 
                            --              wait a few frames                        
                            --      
                            --      For all lines in current_line to top line-1:
                            --          Copy down             
                            --      Delete the top line (19)

                    case lines_fsm is

                        when s_lines_loop =>

                            if current_line > 0 then 
                                lines_fsm       <= s_lines_read;                            
                                current_line    <= current_line - 1;
                            else
                                lines_fsm       <= s_lines_done;
                            end if;                        

                        when s_lines_read =>

                            read_counter <= C_GAME_ZONE_X_SIZE;
                            move_counter <= C_GAME_ZONE_X_SIZE;

                            for i in 0 to C_GAME_ZONE_X_SIZE-1 loop

                                read_addr_buf(i)  <= ToGameTile((i, current_line));    
                                write_addr_buf(i) <=(i, current_line);                                                  
                            end loop;          
                            
                            mm_fsm          <= s_wait;
                            mm_next_state   <= s_read;
                            wait_on_source_mm   <= i_vsync;
                            lines_fsm           <= s_lines_delete;


                        when s_lines_delete =>

                            if mm_return_stat = C_OK then 
                                -- Line is full -> Remove line:
                                write_counter       <= C_GAME_ZONE_X_SIZE;
                                mm_fsm              <= s_wait;
                                mm_next_state       <= s_write;
                                wait_on_source_mm   <= i_vsync;
                                lines_fsm           <= s_lines_frames;

                                mem_data <= C_GRID_TILE;
                                removed_lines_counter       <= removed_lines_counter + 1;
                            else
                                -- Line is not full:
                                lines_fsm            <= s_lines_loop;
                                
                            end if;

                        when s_lines_frames =>

                            if frames_count < C_FLASH_FRAME_COUNT-1 then
                                mm_fsm              <= s_wait;
                                mm_next_state       <= current_process;
                                wait_on_source_mm   <= i_vsync;
                                
                                frames_count    <= frames_count + 1;
                            else
                                frames_count    <= 0;
                                lines_fsm       <= s_lines_copy_loop;
                                current_copy_line   <= current_line + 1;
                            end if;

                        when s_lines_copy_loop =>

                            if current_copy_line > 1 then                             
                                mm_fsm              <= s_wait;
                                mm_next_state       <= s_copy;
                                wait_on_source_mm   <= i_vsync;                            
                                current_copy_line   <= current_copy_line - 1;
                            else
                                -- delete the top row:                            
                                write_counter       <= C_GAME_ZONE_X_SIZE;
                                
                                for i in 0 to C_GAME_ZONE_X_SIZE-1 loop                                   
                                    write_addr_buf(i) <=(i, 0);                                                  
                                end loop;          
                                mem_data <= C_GRID_TILE;
                                
                                mm_fsm              <= s_wait;
                                mm_next_state       <= s_write;
                                wait_on_source_mm   <= i_vsync;
                                lines_fsm           <= s_lines_loop;
                                current_line        <= current_line + 1; --Repeat the current line
                            end if;   

                        when s_lines_done =>
                                
                            mm_fsm              <= s_done;
                            lines_fsm           <= s_lines_loop;

                        --when others =>
                    end case; 

                when s_read =>

                    if read_counter > 0 then

                        var_addr.X := read_addr_buf(read_counter-1).X + GAME_TILE_X_OFFSET;
                        var_addr.Y := read_addr_buf(read_counter-1).Y + GAME_TILE_Y_OFFSET;

                        mem_rd_addr    <= std_logic_vector(to_unsigned(var_addr.Y * C_X_TILE_COUNT + var_addr.X , SRAM_INTERFACE.WRADDR'length));

                        read_counter <= read_counter - 1;
                    else
                        mem_rd_addr         <= (others => '0');
                        if dealy_counter < C_MEM_DELAY+1 then
                            dealy_counter <= dealy_counter + 1;
                        else
                            dealy_counter <= 0;
                            var_stat := '1';
                            for i in 0 to C_GAME_ZONE_X_SIZE-1 loop 
                                if i < move_counter then 
                                    if current_process = s_move_main then
                                        if mem_data_buf(i) = C_BLOCKED then 
                                            var_stat := '0';
                                        end if;
                                    else -- lines process:
                                        if mem_data_buf(i) = C_FREE then 
                                            var_stat := '0';
                                        end if;                                    
                                    end if;                                    

                                end if;
                            end loop;
                            mm_return_stat  <= var_stat ; 
                            mm_fsm          <= current_process; 
                        end if;
                    end if;
                                    
                when s_write =>

                    if write_counter > 0 then

                        var_addr.X := write_addr_buf(write_counter-1).X + GAME_TILE_X_OFFSET;
                        var_addr.Y := write_addr_buf(write_counter-1).Y + GAME_TILE_Y_OFFSET;

                        mem_wr_addr    <= std_logic_vector(to_unsigned(var_addr.Y * C_X_TILE_COUNT + var_addr.X , SRAM_INTERFACE.WRADDR'length));
                        mem_wen        <= '1';

                        write_counter <= write_counter - 1;
                    else
                        mm_fsm          <= current_process;
                        mem_wen        <= '0';
                    end if;

                when s_copy =>

                    if copy_counter < C_GAME_ZONE_X_SIZE then

                        var_addr.X := copy_counter + GAME_TILE_X_OFFSET;
                        var_addr.Y := current_copy_line + GAME_TILE_Y_OFFSET;

                        mem_rd_addr    <= std_logic_vector(to_unsigned((var_addr.Y-1) * C_X_TILE_COUNT + var_addr.X , SRAM_INTERFACE.WRADDR'length));
                        mem_wr_addr    <= std_logic_vector(to_unsigned(var_addr.Y * C_X_TILE_COUNT + var_addr.X , SRAM_INTERFACE.WRADDR'length));

                        if dealy_counter < C_MEM_DELAY+1 then
                            dealy_counter   <= dealy_counter + 1;
                            mem_wen         <= '0';
                        else
                            dealy_counter <= 0;
                            mem_data        <= SRAM_DATA_IN;
                            mem_wen         <= '1';
                            copy_counter    <= copy_counter + 1;
                        end if;
                    else
                        mem_rd_addr         <= (others => '0');
                        mem_wen         <= '0';
                        copy_counter    <= 0;
                        mm_fsm          <= current_process;
                    end if;


                when s_write_next =>

                    if write_counter > 0 then

                        var_addr.X := write_addr_buf(write_counter-1).X ;
                        var_addr.Y := write_addr_buf(write_counter-1).Y ;

                        mem_wr_addr    <= std_logic_vector(to_unsigned(var_addr.Y * C_X_TILE_COUNT + var_addr.X , SRAM_INTERFACE.WRADDR'length));
                        mem_wen        <= '1';

                        write_counter <= write_counter - 1;
                    else
                        if move_fsm = s_write_next then
                            mm_fsm          <= current_process; 
                        else
                            mm_fsm          <= s_done; 
                        end if;
                        mem_wen        <= '0';
                    end if;                


                when s_wait =>

                    case wait_on_source_mm is 
                            
                        -- when i_hsync =>                          
                        --     if VIDEO_SYNC.HSYNC_TRIG='1' then 
                        --         mm_fsm <=  mm_next_state; 
                        --     end if;

                        when i_vsync =>                          
                            if VIDEO_SYNC.VSYNC_TRIG='1' or C_SIM = 1 then 
                                mm_fsm <=  mm_next_state; 
                            end if;

                        when others =>                          
                            mm_fsm <=  mm_next_state;                             
                    end case;

                when s_done =>

                    mm_fsm              <= s_idle;
                    move_machnie_done   <=  '1'; 
                    removed_lines       <= removed_lines_counter;

                when others =>

                    mm_fsm              <= s_idle;


            end case;
        
        end if;
    end if;
end process;

---------------------------------------------------------------------------
-- Data In Buffer
---------------------------------------------------------------------------

process (RST_N, CLK) 
begin
    if RST_N = '0' then 

        mem_data_buf <= (others => '0');

    elsif rising_edge(CLK) then

        if CLEAR = '1' then
            mem_data_buf <= (others => '0');
        else

            if IsGameTileFree(SRAM_DATA_IN) then

                mem_data_buf(0) <= C_FREE;
            else
                mem_data_buf(0) <= C_BLOCKED;
            end if;

            for i in 1 to C_GAME_ZONE_X_SIZE-1 loop

                mem_data_buf(i)        <= mem_data_buf(i-1) ;
            
            end loop;        
        end if;
    end if;
end process;



end game_machine_arch;
 
	
	
	
	
	
