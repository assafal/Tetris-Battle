library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library WORK;
use WORK.top_pack.all;
use WORK.color_pack.all;


entity anima_display_interface is
port
(	
	CLK	    	: in std_logic ;			
    RST_N 		: in std_logic ;

    VIDEO_SYNC  : in t_video_sync;
    ANIMA_TIC   : in std_logic ;

    GAME_MODE   : in t_game_mode;
    
	PIXEL_POS	: in t_pixel_pos ;
	TILE_POS	: in t_tile_pos ;

    ANIMA_VALID : out std_logic ;
    ANIMA_PIXEL : out t_color


);
end anima_display_interface;

architecture anima_display_interface_arch of anima_display_interface is

---------------------------------------------------------------------------
-- Components
---------------------------------------------------------------------------

component cossack_rom 
port
(    
    address		: in std_logic_vector (8 downto 0);
    clock		: in std_logic  := '1';
    q			: out std_logic_vector (127 downto 0)
);
end component;



---------------------------------------------------------------------------
-- Constants
---------------------------------------------------------------------------

constant GND            : std_logic :='0';
constant C_DATA_DELAY   : integer := 2*C_MEM_DELAY + 1;

---------------------------------------------------------------------------
-- Signals
---------------------------------------------------------------------------


signal anima_active_1     :   std_logic;
signal anima_active_2     :   std_logic;
signal anima_tic_event  :   std_logic;

signal anima_pixel_pos  : t_pixel_pos;
signal pixel_pos_d1  : t_pixel_pos;
signal pixel_pos_d2  : t_pixel_pos;

signal line_offset      :   integer range 0 to 1;

signal tile_pointer     :   integer range 0 to 3;

signal rom_addr_int     :   integer range 0 to 511;
signal rom_addr         :   std_logic_vector (8 downto 0);
signal rom_data         :   std_logic_vector (127 downto 0);
signal current_color    :   std_logic_vector (3 downto 0);
signal color_out        :   t_color;




begin

anima_active_1 <= '1' when      TILE_POS.Y >= C_ANIMATION_AI_TILE_Y_1_OFFSET and 
                                TILE_POS.Y  < C_ANIMATION_AI_TILE_Y_1_OFFSET + C_ANIMATION_ZONE_Y_SIZE and
                                TILE_POS.X >= C_ANIMATION_AI_TILE_X_OFFSET and 
                                TILE_POS.X  < C_ANIMATION_AI_TILE_X_OFFSET + C_ANIMATION_ZONE_X_SIZE else '0';

anima_active_2 <= '1' when      TILE_POS.Y >= C_ANIMATION_AI_TILE_Y_2_OFFSET and 
                                TILE_POS.Y  < C_ANIMATION_AI_TILE_Y_2_OFFSET + C_ANIMATION_ZONE_Y_SIZE and
                                TILE_POS.X >= C_ANIMATION_AI_TILE_X_OFFSET and 
                                TILE_POS.X  < C_ANIMATION_AI_TILE_X_OFFSET + C_ANIMATION_ZONE_X_SIZE else '0';


anima_pixel_pos.X     <=  PIXEL_POS.X - C_ANIMATION_AI_TILE_X_OFFSET*C_TILE_SIZE when anima_active_1='1' or anima_active_2='1' else 0;   
anima_pixel_pos.Y     <=  PIXEL_POS.Y - C_ANIMATION_AI_TILE_Y_1_OFFSET*C_TILE_SIZE when anima_active_1='1' else  
                          PIXEL_POS.Y - C_ANIMATION_AI_TILE_Y_2_OFFSET*C_TILE_SIZE when anima_active_2='1' else 0;

ANIMA_VALID <= anima_active_1 or anima_active_2;

process (CLK, RST_N)    
begin
    if RST_N = '0' then

        pixel_pos_d1 <= (0,0);
        pixel_pos_d2 <= (0,0);
       

    elsif rising_edge(CLK) then

        pixel_pos_d1 <= anima_pixel_pos; 
        pixel_pos_d2 <= pixel_pos_d1; 


    end if;
end process;   

	
---------------------------------------------------------------------------
-- ROM
---------------------------------------------------------------------------

line_offset <= 1 when anima_pixel_pos.X >= 32 else 0;

rom_addr_int    <= tile_pointer*C_ANIMATION_TILE_SIZE*2+ 2*anima_pixel_pos.Y + line_offset ;

rom_addr  <= std_logic_vector(to_unsigned( rom_addr_int, 9));

anima_rom_u : cossack_rom 
port map
(   
    address		=>  rom_addr,   
    clock		=>  CLK,        
    q			=>  rom_data    
);

current_color <= rom_data((Mod32(pixel_pos_d2.X)+1)*4-1 downto Mod32(pixel_pos_d2.X)*4);


---------------------------------------------------------------------------
-- COLOR
---------------------------------------------------------------------------


process (CLK, RST_N)
variable temp : integer range 0 to 1;
begin
    if RST_N = '0' then

        anima_tic_event     <= '0';
        tile_pointer <= 0;


    elsif rising_edge(CLK) then

        if ANIMA_TIC='1' then 
            anima_tic_event <= '1';
        end if;

        if (anima_tic_event ='1' or ANIMA_TIC='1') and VIDEO_SYNC.VSYNC_TRIG='1' then 

            anima_tic_event <= '0';

            
            if tile_pointer < 4-1 then 
                tile_pointer <= tile_pointer + 1 ;
            else
                tile_pointer <= 0;
            end if;

        end if;

    end if;
end process;   

color_out <= C_ANIMA_PALETTE( to_integer(unsigned(current_color)) );

ANIMA_PIXEL <= color_out;

end anima_display_interface_arch;
 
	
	
	
	
	
