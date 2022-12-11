library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library WORK;
use WORK.top_pack.all;


entity seven_seg is
port
(	
	CLK	    	: in std_logic ;			
    RST_N 		: in std_logic ;

    MILI_SEC_TIC    : in std_logic ;
    DROP_TIC        : in std_logic ;

    NUMBER 		    : in t_digits_arr ;

	SEVEN_SEG_NUM	: out t_digits_7seg_arr ;
    GPIO		    : out	std_logic_vector(5 downto 0); 
    LED			    : out	std_logic_vector(9 downto 0) 
	
);
end seven_seg;

architecture seven_seg_arch of seven_seg is


constant C_LED_ON   :   std_logic := '1';
constant C_LED_OFF  :   std_logic := '0';

---------------------------------------------------------------------------
-- Components
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- Signals
---------------------------------------------------------------------------

signal leds  : std_logic_vector(9 downto 0);

begin

---------------------------------------------------------------------------
-- 7 Segments
---------------------------------------------------------------------------

	
process (CLK, RST_N)
begin
	if RST_N = '0' then

		SEVEN_SEG_NUM   <= (others => (others => '1'));

	elsif rising_edge(CLK) then

        for i in 0 to C_MAX_DIGITS-1 loop 

            case NUMBER(i) is 

                when 0 =>   SEVEN_SEG_NUM(i)    <= "11000000";
                when 1 =>   SEVEN_SEG_NUM(i)    <= "11111001";
                when 2 =>   SEVEN_SEG_NUM(i)    <= "10100100";
                when 3 =>   SEVEN_SEG_NUM(i)    <= "10110000";
                when 4 =>   SEVEN_SEG_NUM(i)    <= "10011001";
                when 5 =>   SEVEN_SEG_NUM(i)    <= "10010010";
                when 6 =>   SEVEN_SEG_NUM(i)    <= "10000010";
                when 7 =>   SEVEN_SEG_NUM(i)    <= "11111000";
                when 8 =>   SEVEN_SEG_NUM(i)    <= "10000000";
                when 9 =>   SEVEN_SEG_NUM(i)    <= "10011000";
            end case;

        end loop;
        
	end if;
end process;

---------------------------------------------------------------------------
-- LEDs
---------------------------------------------------------------------------

process (CLK, RST_N)
begin
	if RST_N = '0' then

		leds    <= "1010101010";
        
	elsif rising_edge(CLK) then
       

        if DROP_TIC = '1' then 

            leds(0) <= leds(9);
            leds(1) <= leds(0);
            leds(2) <= leds(1);
            leds(3) <= leds(2);
            leds(4) <= leds(3);
            leds(5) <= leds(4);
            leds(6) <= leds(5);
            leds(7) <= leds(6);
            leds(8) <= leds(7);
            leds(9) <= leds(8);
        
	    end if;
	end if;
end process;

LED     <= leds;
GPIO    <= leds(5 downto 0);    

end seven_seg_arch;
 
	
	
	
	
	
