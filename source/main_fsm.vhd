library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library WORK;
use WORK.top_pack.all;


entity main_fsm is
port
(	
	CLK	    	: in std_logic ;			
    RST_N 		: in std_logic ;

	INIT_DONE   : in std_logic;
	GAME_DONE   : in std_logic;
	GAME_CLEAR  : out std_logic;
    USR_CMD 	: in t_usr_cmd_rec ;

    PLAYER_INFO_CMD 	: in t_update_info_cmnd_rec ;
    AI_INFO_CMD 	    : in t_update_info_cmnd_rec ;

    INIT_CMD 	: out t_init_mem_cmnd_rec ;

    GAME_MODE   : out t_game_mode;
    GAME_START  : out std_logic;
    WINNER      : out t_winner;
    DEMO 	    : out std_logic;
    DEMO_STOP   : out std_logic;
    BLANK 	    : out std_logic

);
end main_fsm;

architecture main_fsm_arch of main_fsm is



---------------------------------------------------------------------------
-- Components
---------------------------------------------------------------------------
            

---------------------------------------------------------------------------
-- Constants
---------------------------------------------------------------------------

type t_main_fsm is (s_idle, s_splash, s_init, s_game, s_demo, s_wait_press, s_wait_press_select);    

---------------------------------------------------------------------------
-- Signals
---------------------------------------------------------------------------

signal fsm 	            :	t_main_fsm;
signal player_score     :   integer range 0 to C_MAX_SCORE - 1;
signal ai_score         :   integer range 0 to C_MAX_SCORE - 1;
signal demo_int         :   std_logic;
begin

WINNER  <= player   when player_score > ai_score else
            ai      when player_score < ai_score else
            none;

DEMO <= demo_int;            
---------------------------------------------------------------------------
-- FSM
---------------------------------------------------------------------------    

process (CLK, RST_N)
begin
	if RST_N = '0' then
		
        fsm         <=  s_idle;
        BLANK       <= '0';
        INIT_CMD    <= ('0', cmd_splash);
        GAME_START  <= '0';
        GAME_MODE   <= sp_mode;
        demo_int        <= '0';
        player_score    <= 0;
        ai_score        <= 0;
        DEMO_STOP   <= '0';
        GAME_CLEAR  <= '0';

    elsif rising_edge(CLK) then


        case fsm is 

            when s_idle =>
                
                fsm         <=  s_splash;                
                BLANK       <= '0';
                INIT_CMD    <= ('1', cmd_splash);
                GAME_MODE   <= sp_mode;
                player_score    <= 0;
                ai_score        <= 0;
                demo_int        <= '0';  
                DEMO_STOP       <= '0';   
                GAME_CLEAR      <= '1';           
                
            when s_splash =>

                INIT_CMD.STRB   <= '0';
                GAME_CLEAR      <= '0';

                if INIT_DONE = '1' then
                    fsm         <=  s_wait_press_select;
                end if;

            when s_init =>
    
                INIT_CMD.STRB   <= '0';                
            
                if INIT_DONE = '1' then
                    if  demo_int='1' then
                        fsm         <=  s_demo;
                    else
                        fsm         <=  s_game;
                    end if;
                    BLANK       <= '0';
                    GAME_START  <= '1';
                end if;

            when s_demo =>
                
                GAME_START  <= '0';  
                if USR_CMD.STRB = '1' then                                                             
                    fsm         <=  s_game; 
                    DEMO_STOP   <= '1'; 
                end if;   

            when s_game =>
                
                GAME_START  <= '0';                
                if (GAME_DONE = '1' and GAME_START='0')  then
                    fsm         <=  s_wait_press;                                         
                end if;

                if PLAYER_INFO_CMD.STRB='1' and PLAYER_INFO_CMD.CMD = cmd_score  then 

                    if player_score + PLAYER_INFO_CMD.DATA.INT_NUM <= C_MAX_SCORE then  

                        player_score  <= player_score + PLAYER_INFO_CMD.DATA.INT_NUM;
                    end if;
                end if;

                if AI_INFO_CMD.STRB='1' and AI_INFO_CMD.CMD = cmd_score  then 

                    if ai_score + AI_INFO_CMD.DATA.INT_NUM <= C_MAX_SCORE then  

                        ai_score  <= ai_score + AI_INFO_CMD.DATA.INT_NUM;
                    end if;
                end if;

            when s_wait_press =>

                if USR_CMD.STRB = '1' then                      
                    fsm         <=  s_idle;                                                                                            
                end if;

            when s_wait_press_select =>

                DEMO_STOP   <= '0';
                if USR_CMD.STRB = '1' then 
                    if USR_CMD.CMD = cmd_select then
                        INIT_CMD    <= ('1', cmd_init_ai);
                        GAME_MODE   <= ai_mode;
                        demo_int        <= '0';
                    elsif USR_CMD.CMD = cmd_drop then 
                        INIT_CMD    <= ('1', cmd_init);
                        GAME_MODE   <= sp_mode; 
                        demo_int        <= '1';
                    else
                        INIT_CMD    <= ('1', cmd_init);
                        GAME_MODE   <= sp_mode;
                        demo_int        <= '0';
                    end if;

                    fsm         <=  s_init;
                    
                end if; 
  
                    
        end case;
        
    end if;
end process;



end main_fsm_arch;
 
	
	
	
	
	
