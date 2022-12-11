library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library WORK;
use WORK.top_pack.all;


entity timers is
port
(	
	CLK	    	: in std_logic ;			
    RST_N 		: in std_logic ;

    LEVEL 		: in integer range 1 to 10 ;

	SCREEN_POS	: out t_pixel_pos ;
	PIXEL_POS	: out t_pixel_pos ;
	TILE_POS	: out t_tile_pos ;
    
    VIDEO_SYNC      : out t_video_sync;

	MILI_SEC_TIC	: out std_logic;
	DROP_TIC	    : out std_logic;
	AI_TIC	        : out std_logic;
	PWM	            : out std_logic;

    RAND_VECT       : out std_logic_vector(15 downto 0)

);
end timers;

architecture timers_arch of timers is

---------------------------------------------------------------------------
-- Components
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- Signals
---------------------------------------------------------------------------

signal mili_sec 	    :	integer range 0 to C_ONE_MILI_SEC-1;
signal drop_counter     :	integer range 0 to C_ONE_SEC-1;
signal ai_counter       :	integer range 0 to C_ONE_SEC-1;
signal pixel_counters 	:	t_pixel_pos;
signal screen_counters 	:	t_pixel_pos;
signal active_pixel_pos	:	t_pixel_pos;
signal random_vec       :   std_logic_vector(15 downto 0);
signal xbit             :   std_logic;

begin
	
---------------------------------------------------------------------------
-- Pixel and Tile Position:
---------------------------------------------------------------------------
SCREEN_POS  <= screen_counters; --screen_counters;
PIXEL_POS   <= active_pixel_pos;
TILE_POS.X  <= active_pixel_pos.X / C_TILE_SIZE;
TILE_POS.Y  <= active_pixel_pos.Y / C_TILE_SIZE;


process (CLK, RST_N)
begin
	if RST_N = '0' then
		pixel_counters.X    <= 0;
		pixel_counters.Y    <= 0;
        active_pixel_pos.X  <= 0;
        active_pixel_pos.Y  <= 0;
	elsif rising_edge(CLK) then
        if pixel_counters.X < C_VIDEO_FULL_H-1 then

            pixel_counters.X    <= pixel_counters.X + 1;


            if pixel_counters.X >= 0 then --C_VIDEO_HSYNC_CLKS + C_VIDEO_HB_CLKS then

                if active_pixel_pos.X < C_VIDEO_HACTIVE-1 then
                    active_pixel_pos.X <= active_pixel_pos.X + 1;
                end if;

            end if;
        else
            pixel_counters.X    <= 0;
            active_pixel_pos.X  <= 0;

            if pixel_counters.Y < C_VIDEO_FULL_V-1 then
                pixel_counters.Y    <= pixel_counters.Y + 1;
                if pixel_counters.Y >= C_VIDEO_VSYNC_LINES + C_VIDEO_VB_LINES then

                    if active_pixel_pos.Y < C_VIDEO_VACTIVE-1 then
                        active_pixel_pos.Y <= active_pixel_pos.Y + 1;
                    end if;
                    
                end if;
            else
                pixel_counters.Y    <= 0;
                active_pixel_pos.Y  <= 0;
	        end if;
	    end if;
	end if;
end process;


process (CLK, RST_N)
begin
	if RST_N = '0' then

		screen_counters.X   <= 0;
		screen_counters.Y   <= 0;
       
	elsif rising_edge(CLK) then

        if pixel_counters.X = 0 then --79 then

            screen_counters.X <= 0;

            if pixel_counters.Y = C_VIDEO_VSYNC_LINES + C_VIDEO_VB_LINES - 1 then

                screen_counters.Y <= 0;
            
            else
                screen_counters.Y <= screen_counters.Y + 1;

            end if;            
        else
            screen_counters.X <= screen_counters.X + 1;
        end if;

	end if;
end process;

VIDEO_SYNC.ACTIVE   <= '1' when pixel_counters.X >= 0 and
                                pixel_counters.X < C_VIDEO_HACTIVE and
                                pixel_counters.Y >= C_VIDEO_VSYNC_LINES +C_VIDEO_VB_LINES and
                                pixel_counters.Y < C_VIDEO_VSYNC_LINES +C_VIDEO_VB_LINES + C_VIDEO_VACTIVE else '0';

VIDEO_SYNC.VSYNC        <= '1' when RST_N = '1' and pixel_counters.Y < C_VIDEO_VSYNC_LINES else '0';
VIDEO_SYNC.VSYNC_TRIG   <= '1' when RST_N = '1' and pixel_counters.Y = 0 and pixel_counters.X = 0 else '0';
VIDEO_SYNC.HSYNC        <= '1' when RST_N = '1' and pixel_counters.X < C_VIDEO_HSYNC_CLKS else '0';
VIDEO_SYNC.HSYNC_TRIG   <= '1' when RST_N = '1' and pixel_counters.X = 0 else '0';

---------------------------------------------------------------------------
-- Time:
---------------------------------------------------------------------------
	
process (CLK, RST_N)
begin
	if RST_N = '0' then
		mili_sec        <= 0;
        MILI_SEC_TIC    <= '0';
		
	elsif rising_edge(CLK) then
        if mili_sec < C_ONE_MILI_SEC-1 then
            mili_sec        <= mili_sec + 1;
            MILI_SEC_TIC    <= '0';
        else
            mili_sec        <= 0;
            MILI_SEC_TIC    <= '1';
	    end if;
	end if;
end process;

---------------------------------------------------------------------------
-- DROP:
---------------------------------------------------------------------------

process (CLK, RST_N)
begin
	if RST_N = '0' then
		drop_counter    <= 0;
		ai_counter      <= 0;
        DROP_TIC        <= '0';
        AI_TIC          <= '0';
		
	elsif rising_edge(CLK) then
        if mili_sec = C_ONE_MILI_SEC-1 then 

            if drop_counter < C_GRAVITY(LEVEL)-1 then 
                drop_counter        <= drop_counter + 1;
                DROP_TIC    <= '0';
            else
                drop_counter    <= 0;
                DROP_TIC        <= '1';
            end if;

            if ai_counter < C_AI_GRAVITY(LEVEL)-1 then 
                ai_counter        <= ai_counter + 1;
                AI_TIC    <= '0';
            else
                ai_counter    <= 0;
                AI_TIC        <= '1';
            end if;

        else
            DROP_TIC    <= '0';
            AI_TIC      <= '0';
        end if;
    end if;
end process;

PWM <= '0'; --'1' when mili_sec < C_ONE_MILI_SEC/2 else '0';


---------------------------------------------------------------------------
-- Random Number Generator:
---------------------------------------------------------------------------

process (RST_N, CLK)
begin
    if RST_N = '0' then 
        random_vec <= C_SEED;
    elsif rising_edge(CLK) then
        
        random_vec <= random_vec(14 downto 0) & xbit; 
        
    end if;
end process;

xbit <= random_vec(15) xor random_vec(13) xor random_vec(11) xor random_vec(10) ;

RAND_VECT <= random_vec;

end timers_arch;
 
	
	
	
	
	
