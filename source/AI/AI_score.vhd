library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library WORK;
use WORK.top_pack.all;
use work.brick_position_pack.all;
use work.AI_pack.all;


entity AI_score is
port
(	
	CLK	    	: in std_logic ;			
    RST_N 		: in std_logic ;

    UPDATE          : in std_logic;    
    BOARD_IN        : in  t_game_board;

    READY_OUT       : out std_logic;
    BOARD_SCORE     : out integer range 0 to 8191

);
end AI_score;

architecture AI_score_arch of AI_score is


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



signal row_counter      :   integer range 0 to C_GAME_ZONE_Y_SIZE-1;
signal score_int        :   integer range 0 to 8191;


begin


---------------------------------------------------------------------------
-- Row Counter
---------------------------------------------------------------------------    

process (CLK, RST_N)
begin
	if RST_N = '0' then

		row_counter     <= 0;
        score_int       <= 0;
        BOARD_SCORE     <= 0;
        READY_OUT       <= '0';
		
		
	elsif rising_edge(CLK) then

        READY_OUT            <= '1';

        if UPDATE = '1'  or  row_counter > 0 then 

            READY_OUT            <= '0';

            if row_counter < C_GAME_ZONE_Y_SIZE-1 then 

                score_int           <= score_int + Score(BOARD_IN, row_counter);
            else
                BOARD_SCORE         <= score_int + Score(BOARD_IN, row_counter);
                score_int           <= 0;
                READY_OUT           <= '1';
            end if;

            if row_counter < C_GAME_ZONE_Y_SIZE-1 then 

                row_counter         <= row_counter + 1;
                
            else
                row_counter    <= 0;
                
            end if;

        end if;
    end if;
end process;
    

end AI_score_arch;
 
	
	
	
	
	
