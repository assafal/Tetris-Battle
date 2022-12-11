library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library WORK;
use WORK.top_pack.all;
use WORK.color_pack.all;


entity display_interface is
port
(	
	CLK	    	: in std_logic ;			
	LCD_CLK	  	: in std_logic ;			
    RST_N 		: in std_logic ;

    GAME_MODE   : in t_game_mode;
    BLANK 		: in std_logic ;
    WINNER      : in t_winner;
    
	SCREEN_POS	: in t_pixel_pos ;
	PIXEL_POS	: in t_pixel_pos ;
	TILE_POS	: in t_tile_pos ;

    VIDEO_SYNC      : in t_video_sync;

    ANIMA_VALID     : in std_logic ;
    ANIMA_PIXEL     : in t_color;


    SRAM_RDADDR		: out 	std_logic_vector(10 downto 0) ;
    SRAM_DATA		: in 	std_logic_vector(15 downto 0) ;
    AI_SRAM_DATA	: in 	std_logic_vector(15 downto 0) ;

	--LCD Interface:
	LCD_DB		: out 	std_logic_vector(7 downto 0) ;
	LCD_RESET	: out 	std_logic ;
	LCD_WR		: out 	std_logic ;
	LCD_RD		: out 	std_logic ;
	LCD_D_C		: out 	std_logic ;

	-- VGA Interface
    RED			: out 	std_logic_vector(3 downto 0) ;
	GREEN		: out 	std_logic_vector(3 downto 0) ;
	BLUE		: out 	std_logic_vector(3 downto 0) ;
	H_SYNC		: out	std_logic ;
	V_SYNC		: out	std_logic 

);
end display_interface;

architecture display_interface_arch of display_interface is

---------------------------------------------------------------------------
-- Components
---------------------------------------------------------------------------

component symbol_rom 
port
(    
    address		: in std_logic_vector (7 downto 0);
    clock		: in std_logic  := '1';
    q			: out std_logic_vector (127 downto 0)
);
end component;

component lcd_ctrl 
port
(
	clk_50      : in std_logic; -- 
	clk_25      : in std_logic; -- 
	clk_100     : in std_logic; -- 
	resetN      : in std_logic; -- 
	pxl_x       : in std_logic_vector(31 downto 0); -- 
	pxl_y       : in std_logic_vector(31 downto 0); -- 
	h_sync      : in std_logic; -- 
	v_sync      : in std_logic; -- 
	red_in      : in std_logic_vector(3 downto 0); -- 
	green_in    : in std_logic_vector(3 downto 0); -- 
	blue_in     : in std_logic_vector(3 downto 0); -- 
	sw_0        : in std_logic; -- 
	lcd_db      : out std_logic_vector(7 downto 0); -- 
	lcd_reset   : out std_logic; -- 
	lcd_wr      : out std_logic; -- 
	lcd_d_c     : out std_logic; -- 
	lcd_rd      : out std_logic 
);
end component;

---------------------------------------------------------------------------
-- Constants
---------------------------------------------------------------------------

constant GND            : std_logic :='0';
constant C_DATA_DELAY   : integer := 2*C_MEM_DELAY + 1;

type t_sync_arr is array (0 to C_DATA_DELAY) of t_video_sync;
type t_pix_pos_arr is array (0 to C_DATA_DELAY) of t_pixel_pos;
type t_tile_type_arr is array (0 to C_DATA_DELAY) of t_tile_type;
type t_game_tile_arr is array (0 to C_DATA_DELAY) of std_logic_vector (2 downto 0);

---------------------------------------------------------------------------
-- Signals
---------------------------------------------------------------------------

signal sync_pipe 	    :	t_sync_arr;
signal screen_pos_pipe  :   t_pix_pos_arr;
signal pixel_pos_pipe   :   t_pix_pos_arr;
signal tile_type_pipe   :   t_tile_type_arr;
signal game_tile_pipe   :   t_game_tile_arr;
signal game_score_tile_pipe   :   std_logic_vector (0 to C_DATA_DELAY);
signal ai_score_tile_pipe   :   std_logic_vector (0 to C_DATA_DELAY);

signal blank_pipe       :   std_logic_vector (0 to C_DATA_DELAY);
signal ai_tile_pipe     :   std_logic_vector (0 to C_DATA_DELAY);

signal rom_addr         :   std_logic_vector (7 downto 0);
signal rom_data         :   std_logic_vector (127 downto 0);
signal tile_type        :   t_tile_type;
signal tile_offset      :   std_logic_vector (5 downto 0);
signal game_tile_select :   std_logic_vector (2 downto 0);
signal pixel_y          :   std_logic_vector (9 downto 0);
signal pixel_y_d        :   std_logic_vector (9 downto 0);
signal selected_line    :   std_logic_vector (31 downto 0);
signal current_color    :   std_logic_vector (1 downto 0);
signal screen_pos_d     :   t_pixel_pos;
signal pixel_pos_d      :   t_pixel_pos;
signal color_out        :   t_color;

signal red_v            :   std_logic_vector (3 downto 0);
signal green_v          :   std_logic_vector (3 downto 0);
signal blue_v           :   std_logic_vector (3 downto 0);

signal pxl_x           :   std_logic_vector (31 downto 0);
signal pxl_y           :   std_logic_vector (31 downto 0);

signal ai_tile          :   std_logic;
signal ai_score_tile    :   std_logic;
signal game_score_tile  :   std_logic;
signal sram_data_select :   std_logic_vector (15 downto 0);



begin

SRAM_RDADDR <= std_logic_vector(to_unsigned(TILE_POS.Y * C_X_TILE_COUNT + TILE_POS.X, SRAM_RDADDR'length)) when VIDEO_SYNC.ACTIVE='1' else (others =>'0');

H_SYNC  <= sync_pipe(C_DATA_DELAY-1).HSYNC;
V_SYNC  <= sync_pipe(C_DATA_DELAY-1).VSYNC;

game_score_tile     <= '1' when GAME_MODE=ai_mode and (TILE_POS.Y = C_AI_SCORE_TILE_Y and TILE_POS.X >= C_AI_PLAYER_SCORE_TILE_X and TILE_POS.X < C_AI_PLAYER_SCORE_TILE_X+C_SCORE_DIGITS ) else '0';
ai_score_tile       <= '1' when GAME_MODE=ai_mode and (TILE_POS.Y = C_AI_SCORE_TILE_Y and TILE_POS.X >= C_AI_AI_SCORE_TILE_X and TILE_POS.X < C_AI_AI_SCORE_TILE_X+C_SCORE_DIGITS ) else '0';

ai_tile <= '1' when GAME_MODE=ai_mode and ((
                                            TILE_POS.Y >= C_AI_GAME_TILE_Y_OFFSET and TILE_POS.Y < C_AI_GAME_TILE_Y_OFFSET + C_GAME_ZONE_Y_SIZE and
                                            TILE_POS.X >= C_AI_GAME_TILE_X_OFFSET and TILE_POS.X < C_AI_GAME_TILE_X_OFFSET + C_GAME_ZONE_X_SIZE) 
                                            or ai_score_tile='1') else '0';
	
---------------------------------------------------------------------------
-- ROM
---------------------------------------------------------------------------

symbol_rom_u : symbol_rom 
port map
(   
    address		=>  rom_addr,   --: in std_logic_vector (7 downto 0);
    clock		=>  CLK,        --: in std_logic  := '1';
    q			=>  rom_data    --: out std_logic_vector (127 downto 0)
);

-- Decoding the Tile code:

sram_data_select <= AI_SRAM_DATA when ai_tile_pipe(C_MEM_DELAY)='1' else SRAM_DATA;

with sram_data_select(15 downto 14) select tile_type  <=   t_background when "00",
                                                    t_game       when "01",
                                                    t_text       when "10",
                                                    t_text       when others; -- Not used

with tile_type select tile_offset   <= sram_data_select(8 downto 3)          when t_text,
                                    "110" & sram_data_select(11 downto 9)   when t_background,
                                    "111000"                                when t_game;

game_tile_select <= sram_data_select(2 downto 0);               

pixel_y <= std_logic_vector(to_unsigned( pixel_pos_pipe(C_MEM_DELAY-1).Y, 10));   
--pixel_x <= std_logic_vector(to_unsigned( pixel_pos_pipe(C_MEM_DELAY-1).X, 10));   

rom_addr    <= tile_offset &  pixel_y(3 downto 2) ;

pixel_pos_d     <=  pixel_pos_pipe(2*C_MEM_DELAY-1);
screen_pos_d    <=  screen_pos_pipe(2*C_MEM_DELAY+1);

---------------------------------------------------------------------------
-- COLOR
---------------------------------------------------------------------------


selected_line   <= rom_data( (Mod4(pixel_pos_d.Y) + 1 )*32-1 downto (Mod4(pixel_pos_d.Y))*32 );

current_color   <= selected_line ( (Mod16(pixel_pos_d.X) + 1 )*2-1 downto (Mod16(pixel_pos_d.X))*2 );                                                   


process (CLK, RST_N)
variable temp : integer range 0 to 1;
begin
    if RST_N = '0' then
        color_out   <= C_BLACK;

    elsif rising_edge(CLK) then

        if current_color(0)='0' then
            temp := 0;
        else 
            temp := 1; 
        end if;

        if sync_pipe(C_DATA_DELAY-2).ACTIVE='0' or blank_pipe(C_DATA_DELAY-2)='1' then 

            color_out   <= C_BLACK;
        else
            case tile_type_pipe(C_MEM_DELAY-1) is 
                when t_background   => color_out <= C_BACK_PALETTE( to_integer(unsigned(current_color)) );
                when t_game         => color_out <= C_GAME_PALETTE( to_integer(unsigned(game_tile_pipe(C_MEM_DELAY-1))))(temp ); 
                when t_text         => 
                
                    if (WINNER = player and game_score_tile_pipe(C_MEM_DELAY-1)='1') or (WINNER = ai and ai_score_tile_pipe(C_MEM_DELAY-1)='1')then
                            color_out <= C_WINNER_TEXT_PALETTE( to_integer(unsigned(current_color) ));
                    else
                            color_out <= C_TEXT_PALETTE( to_integer(unsigned(current_color) ));
                    end if;
            end case;

        end if;
    end if;
end process;   

-- red_v     <= std_logic_vector(to_unsigned( ANIMA_PIXEL.RED , 4)) when ANIMA_VALID='1' and GAME_MODE = ai_mode else std_logic_vector(to_unsigned( color_out.RED , 4)); 
-- green_v   <= std_logic_vector(to_unsigned( ANIMA_PIXEL.GREEN , 4)) when ANIMA_VALID='1' and GAME_MODE = ai_mode else std_logic_vector(to_unsigned( color_out.GREEN , 4)); 
-- blue_v    <= std_logic_vector(to_unsigned( ANIMA_PIXEL.BLUE , 4)) when ANIMA_VALID='1' and GAME_MODE = ai_mode else std_logic_vector(to_unsigned( color_out.BLUE , 4)); 

process (CLK, RST_N)
begin
    if RST_N = '0' then

        red_v   <= (others => '0');
        green_v   <= (others => '0');
        blue_v   <= (others => '0');

    elsif rising_edge(CLK) then

        if ANIMA_VALID='1' and GAME_MODE = ai_mode then

            red_v     <= std_logic_vector(to_unsigned( ANIMA_PIXEL.RED , 4)) ;
            green_v   <= std_logic_vector(to_unsigned( ANIMA_PIXEL.GREEN , 4));
            blue_v    <= std_logic_vector(to_unsigned( ANIMA_PIXEL.BLUE , 4));

                    
        else
            red_v     <= std_logic_vector(to_unsigned( color_out.RED , 4)); 
            green_v   <= std_logic_vector(to_unsigned( color_out.GREEN , 4)); 
            blue_v    <= std_logic_vector(to_unsigned( color_out.BLUE , 4)); 
            
        end if;
    end if;
end process;          
    


RED     <=  red_v   when pixel_pos_d.X >= C_VIDEO_HSYNC_CLKS +C_VIDEO_HB_CLKS and pixel_pos_d.X < C_VIDEO_HSYNC_CLKS +C_VIDEO_HB_CLKS + C_VIDEO_HACTIVE else (others => '0');
GREEN   <=  green_v when pixel_pos_d.X >= C_VIDEO_HSYNC_CLKS +C_VIDEO_HB_CLKS and pixel_pos_d.X < C_VIDEO_HSYNC_CLKS +C_VIDEO_HB_CLKS + C_VIDEO_HACTIVE else (others => '0');
BLUE    <=  blue_v  when pixel_pos_d.X >= C_VIDEO_HSYNC_CLKS +C_VIDEO_HB_CLKS and pixel_pos_d.X < C_VIDEO_HSYNC_CLKS +C_VIDEO_HB_CLKS + C_VIDEO_HACTIVE else (others => '0');


---------------------------------------------------------------------------
-- LCD
---------------------------------------------------------------------------    

pxl_x   <= std_logic_vector(to_unsigned(screen_pos_d.X,32));
pxl_y   <= std_logic_vector(to_unsigned(screen_pos_d.Y,32));

lcd_u : lcd_ctrl 
port map
(
	clk_50      =>  '0',        --(0), // not used
	clk_25      =>  CLK,        --(clk_25),
	clk_100     =>  LCD_CLK,    --(clk_100),
	resetN      =>  RST_N,      --(1),
	pxl_x       =>  pxl_x,           --(Pxl_x_i),
	pxl_y       =>  pxl_y,           --(Pxl_y_i),
	h_sync      =>  '0',        --(0), // not used
	v_sync      =>  '0',        --(0), // not used
	red_in      =>  red_v,      --(Red_i),
	green_in    =>  green_v,    --(Green_i),
	blue_in     =>  blue_v,     --(Blue_i),
	sw_0        =>  '1',        --(1), // used for reset
	lcd_db      =>  LCD_DB,           --(lcd_db),
	lcd_reset   =>  LCD_RESET,           --t(lcd_reset),
	lcd_wr      =>  LCD_WR,           --(lcd_wr),
	lcd_d_c     =>  LCD_D_C,           --(lcd_d_c),
	lcd_rd      =>  LCD_RD            --(lcd_rd)
);




---------------------------------------------------------------------------
-- Misc Delay
---------------------------------------------------------------------------    


process (CLK, RST_N)
begin
	if RST_N = '0' then

        blank_pipe              <= (others => '0');
        ai_tile_pipe             <= (others => '0');
        game_score_tile_pipe    <= (others => '0');
        ai_score_tile_pipe      <= (others => '0');
		
        for i in 0 to C_DATA_DELAY loop

            sync_pipe(i)        <= (others => '0');
            screen_pos_pipe(i)  <= (0,0);   
            pixel_pos_pipe(i)   <= (0,0);   
            tile_type_pipe(i)   <= t_background;        
            game_tile_pipe(i)   <= (others => '0');
            
        end loop;
    elsif rising_edge(CLK) then

        sync_pipe(0)        <= VIDEO_SYNC;
        screen_pos_pipe(0)  <= SCREEN_POS;
        pixel_pos_pipe(0)   <= PIXEL_POS;
        blank_pipe(0)       <= BLANK;
        tile_type_pipe(0)   <= tile_type;
        game_tile_pipe(0)   <= game_tile_select;
        game_score_tile_pipe(0) <= game_score_tile;
        ai_score_tile_pipe(0) <= ai_score_tile;
        ai_tile_pipe(0)     <= ai_tile;

        for i in 1 to C_DATA_DELAY loop

            sync_pipe(i)        <= sync_pipe(i-1) ;
            screen_pos_pipe(i)  <= screen_pos_pipe(i-1);
            pixel_pos_pipe(i)   <= pixel_pos_pipe(i-1);
            blank_pipe(i)       <= blank_pipe(i-1);
            tile_type_pipe(i)   <= tile_type_pipe(i-1);
            game_tile_pipe(i)   <= game_tile_pipe(i-1)  ;
            game_score_tile_pipe(i) <= game_score_tile_pipe(i-1);
            ai_score_tile_pipe(i) <= ai_score_tile_pipe(i-1);
            ai_tile_pipe(i)         <= ai_tile_pipe(i-1);
            
        end loop;
        
    end if;
end process;

end display_interface_arch;
 
	
	
	
	
	
