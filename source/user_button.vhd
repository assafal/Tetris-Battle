library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library WORK;
use WORK.top_pack.all;


entity user_button is
port
(	
	CLK	    	: in std_logic ;			
    RST_N 		: in std_logic ;

	TIME_TIC	: in std_logic;
	BUTTON	    : in std_logic;

    TRIG        : out std_logic

);
end user_button;

architecture user_button_arch of user_button is

---------------------------------------------------------------------------
-- Components
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- Signals
---------------------------------------------------------------------------

signal long_push_counter        :	integer range 0 to C_LONG_PUSH-1;
signal button_s                 :   std_logic;

begin
	
---------------------------------------------------------------------------
-- Sample the inputs
---------------------------------------------------------------------------
	
process (CLK, RST_N)
begin
	if RST_N = '0' then

        button_s            <= not(C_PRESSED) ;        
        TRIG                <= '0' ;        
        long_push_counter   <= 0;
       
		
	elsif rising_edge(CLK) then

        TRIG   <= '0' ;
       
        if TIME_TIC = '1' then            
            button_s   <= BUTTON;
                    
            if BUTTON = C_PRESSED then

                if long_push_counter < C_LONG_PUSH-1 then
                    long_push_counter <= long_push_counter + 1;
                else
                    long_push_counter <= 0;
                end if;
            else
                long_push_counter <= 0;
            end if;
           
            if (BUTTON = C_PRESSED and button_s = not(C_PRESSED))  or (long_push_counter = C_LONG_PUSH-1) then
                TRIG   <= '1' ;
            end if; 
            
    	end if;
	end if;
end process;



end user_button_arch;
 
	
	
	
	
	
