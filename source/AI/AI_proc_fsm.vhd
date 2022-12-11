library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library WORK;
use WORK.top_pack.all;
use work.brick_position_pack.all;
use work.AI_pack.all;


entity AI_proc_fsm is
port
(	
	CLK	    	: in std_logic ;			
    RST_N 		: in std_logic ;

    UPDATE          : in std_logic;
    READY_IN        : in std_logic;
    BRICK_IN        : in  t_brick_info;
    BOARD_IN        : in  t_game_board;

    TOP_ROWS     : in  t_top_rows_arr;

    STATE_OUT    : out t_AI_board_process;
    READY_OUT    : out std_logic;
    VALID_OUT    : out std_logic;
    BOARD_OUT    : out  t_game_board;
    RES_BRICK    : out  t_brick_info;
    DROP_BRICK   : out  t_brick_info

);
end AI_proc_fsm;

architecture AI_proc_fsm_arch of AI_proc_fsm is


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

signal fsm 	        :	t_AI_board_process;

signal rot_counter  : integer range 0 to 3;
signal col_counter  : integer range 0 to C_GAME_ZONE_X_SIZE-1;
signal valid_out_int    : std_logic;

--attribute noprune of test_board_map: signal is true;    
--attribute noprune of top_rows: signal is true;    


begin

STATE_OUT   <= fsm;
VALID_OUT   <= valid_out_int;

fsm_c : process (CLK, RST_N)
variable row_index  : integer range -1 to C_GAME_ZONE_Y_SIZE-1;  
begin
    if RST_N = '0' then
        
        fsm             <=  s_idle;               
        rot_counter     <= 0;
        col_counter     <= 0;

        READY_OUT       <= '1' ;
        valid_out_int   <= '0' ;
        BOARD_OUT       <= (others => (others => '0'));           
        RES_BRICK       <= (1 , C_INIT_POS, 0); 
        DROP_BRICK      <= (1 , C_INIT_POS, 0); 

    elsif rising_edge(CLK) then


        case fsm is 

            when s_idle =>

                READY_OUT       <= '1' ;
                valid_out_int   <= '0';

                if UPDATE = '1' then                 
                    fsm         <=  s_wait_board_map;                                        
                    READY_OUT   <= '0' ;
                    RES_BRICK   <= BRICK_IN;        
                    DROP_BRICK  <= BRICK_IN;        
                end if;
        
            when s_wait_board_map =>

                fsm <=  s_wait_top_rows;

            when s_wait_top_rows =>
                
                fsm <=  s_top_rows;
            
            when s_top_rows =>

                if READY_IN = '1' then 

                    row_index := TOP_ROWS(rot_counter)(col_counter);

                    DROP_BRICK.POS.Y   <= TOP_ROWS(BRICK_IN.ROT)(BRICK_IN.POS.X);

                    if row_index >= 0 then 

                        valid_out_int   <= '1';
                        BOARD_OUT       <= UpdateBoard( BOARD_IN, col_counter, row_index, rot_counter, BRICK_IN.BTYPE); 
                        RES_BRICK.ROT   <= rot_counter;
                        RES_BRICK.POS.X   <= col_counter;
                        RES_BRICK.POS.Y   <= row_index;
                        fsm             <= s_wait;
                    else
                        valid_out_int   <= '0';                            
                    end if;

                    if col_counter < C_GAME_ZONE_X_SIZE-1 then 

                        col_counter <= col_counter + 1;
                    else

                        col_counter <= 0 ;
                        
                        if rot_counter < 3 then 
                            rot_counter <= rot_counter + 1;                            
                        else
                            fsm         <=  s_idle;                                                    
                            rot_counter <= 0;
                        end if;
    
                    end if;

                end if;

            when s_wait =>

                valid_out_int   <= '0';

                if READY_IN = '1' and valid_out_int = '0' then 
                    fsm <= s_top_rows; 
                end if;

            when others =>
                    
        end case;
        
    end if;
end process;
        

end AI_proc_fsm_arch;
 
	
	
	
	
	
