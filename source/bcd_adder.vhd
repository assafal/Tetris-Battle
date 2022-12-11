library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library WORK;
use WORK.top_pack.all;


entity bcd_adder is
generic
(
    G_NUM_DIGITS    : integer := 3    
);    
port
(	
	CLK	    	: in std_logic ;			
    RST_N 		: in std_logic ;

    START 		: in std_logic ;
    OPERATION   : in std_logic ; --'0' Add, '1' Sub
    MAX_LEN     : in integer range 0 to G_NUM_DIGITS;

    NUM_IN_1    : in t_digits_arr;
    NUM_IN_2    : in t_digits_arr;

    NUM_OUT     : out t_digits_arr;

    DONE 	    : out std_logic

);
end bcd_adder;

architecture bcd_adder_arch of bcd_adder is



---------------------------------------------------------------------------
-- Components
---------------------------------------------------------------------------
            

---------------------------------------------------------------------------
-- Constants
---------------------------------------------------------------------------

type t_calc_state is (s_idle, s_calc, s_done);    

---------------------------------------------------------------------------
-- Signals
---------------------------------------------------------------------------

signal calc_fsm         :	t_calc_state;

signal digits_counter   :   integer range 0 to G_NUM_DIGITS-1 ;
signal carry            :   integer range -1 to 1 ;

signal temp_res         :   t_digits_arr;
signal done_int         :   std_logic;


begin

DONE    <= done_int;

---------------------------------------------------------------------------
-- FSM
---------------------------------------------------------------------------    

process (CLK, RST_N)
begin
	if RST_N = '0' then

        calc_fsm        <= s_idle;
        digits_counter  <= 0;
        done_int        <= '0';
        for i in 0 to G_NUM_DIGITS-1  loop
            NUM_OUT(i) <= 0;            
        end loop; 

    elsif rising_edge(CLK) then

        done_int    <= '0';

        case calc_fsm is

            when  s_idle =>

                if START = '1' and done_int = '0' then
                    calc_fsm <= s_calc;
                end if;

            when s_calc =>
                
                if digits_counter < MAX_LEN-1 then

                    digits_counter <= digits_counter + 1;
                else
                    digits_counter  <=  0;
                    calc_fsm        <= s_done;
                end if;
            
            when  s_done =>
                
                if carry /= 0 then
                    for i in 0 to C_MAX_DIGITS-1  loop
                        NUM_OUT(i) <= 9;                                    
                    end loop; 
                else
                    NUM_OUT <= temp_res;
                end if;
                calc_fsm        <= s_idle;
                done_int        <= '1';
                
        end case;

    end if;
end process;


---------------------------------------------------------------------------
--CALC
---------------------------------------------------------------------------       

process (CLK, RST_N)
begin
	if RST_N = '0' then
		        
        carry  <= 0;

        for i in 0 to G_NUM_DIGITS-1  loop
            temp_res(i) <= 0;            
        end loop; 

    elsif rising_edge(CLK) then
    
        if calc_fsm = s_calc then

            if OPERATION = '0' then 
            
                --ADD
                if carry + NUM_IN_1(digits_counter) + NUM_IN_2(digits_counter) > 9 then

                    temp_res(digits_counter) <=  carry + NUM_IN_1(digits_counter) + NUM_IN_2(digits_counter) - 10;
                    carry   <= 1;
                else
                    temp_res(digits_counter) <=  carry + NUM_IN_1(digits_counter) + NUM_IN_2(digits_counter);
                    carry   <= 0;       
                end if;    
            else

                --SUB
                if carry + NUM_IN_1(digits_counter) - NUM_IN_2(digits_counter) >= 0 then

                    temp_res(digits_counter) <=  carry + NUM_IN_1(digits_counter) - NUM_IN_2(digits_counter);
                    carry   <= 0;
                else
                    temp_res(digits_counter) <=  carry + NUM_IN_1(digits_counter) - NUM_IN_2(digits_counter) + 10;
                    carry   <= -1;       
                end if;    
                
            end if;
        else
            carry   <= 0;           
        end if;              
    end if;
end process;

 

end bcd_adder_arch;
 
	
	
	
	
	
