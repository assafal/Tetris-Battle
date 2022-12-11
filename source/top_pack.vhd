----------------------
-- Standard libraries 
-----------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


-------------------------------------------------------------------------------
package top_pack is
-------------------------------------------------------------------------------

type t_int_arr is array (natural range <> ) of integer;

constant C_SIM          : integer := 0;

constant C_SEED         : std_logic_vector(15 downto 0) :=  "1001101001101010";

constant C_CLK_RATE     : integer   :=  25; -- MHz
constant C_ONE_MILI_SEC : integer   :=  C_CLK_RATE * 1000/(1+C_SIM*9);
constant C_ONE_SEC      : integer   :=  1000 / (1+C_SIM*9) ; --mili secs

constant C_ERROR        : std_logic := '0';
constant C_OK           : std_logic := '1';
constant C_MEM_DELAY    : integer := 2;

---------------------------------------------------------------------------
-- Video
-- Video Parameters for VGA display
-- Taken from the DE-10 Manual, page 36
---------------------------------------------------------------------------

constant C_VIDEO_HSYNC_CLKS     : integer   :=  96;
constant C_VIDEO_HB_CLKS        : integer   :=  48;
constant C_VIDEO_HD_CLKS        : integer   :=  16;
constant C_VIDEO_HACTIVE        : integer   :=  800;

constant C_VIDEO_FULL_H         : integer   :=  C_VIDEO_HACTIVE ;
                                                

constant C_VIDEO_VSYNC_LINES    : integer   :=  2;
constant C_VIDEO_VB_LINES       : integer   :=  33;
constant C_VIDEO_VD_LINES       : integer   :=  10;
constant C_VIDEO_VACTIVE        : integer   :=  480;

constant C_VIDEO_FULL_V         : integer   :=  C_VIDEO_VSYNC_LINES +
                                                C_VIDEO_VB_LINES +
                                                C_VIDEO_VACTIVE +
                                                C_VIDEO_VD_LINES;
type t_video_sync is record
    ACTIVE      : std_logic;
    HSYNC       : std_logic;
    HSYNC_TRIG  : std_logic;
    VSYNC       : std_logic;
    VSYNC_TRIG  : std_logic;
end record;

---------------------------------------------------------------------------
-- Position 
---------------------------------------------------------------------------
                                                
constant C_TILE_SIZE        : integer   :=  16;
constant C_X_TILE_COUNT     : integer   :=  (C_VIDEO_HACTIVE) / (C_TILE_SIZE);
constant C_Y_TILE_COUNT     : integer   :=  (C_VIDEO_VACTIVE) / (C_TILE_SIZE);
constant C_TILE_COUNT       : integer   :=  C_X_TILE_COUNT * C_Y_TILE_COUNT;

type t_pixel_pos is record
    X       :   integer range 0 to C_VIDEO_FULL_H-1;
    Y       :   integer range 0 to C_VIDEO_FULL_V-1;    
end record;

type t_tile_pos is record
    X       :   integer range 0 to C_X_TILE_COUNT-1;
    Y       :   integer range 0 to C_Y_TILE_COUNT-1;    
end record;

constant C_GAME_ZONE_X_SIZE     : integer   :=  10;
constant C_GAME_ZONE_Y_SIZE     : integer   :=  20;


type t_game_tile_pos is record
    X       :   integer range 0 to C_GAME_ZONE_X_SIZE-1;
    Y       :   integer range 0 to C_GAME_ZONE_Y_SIZE-1;    
end record;

-- Offset of the top left corner of the game region: t_game_tile_pos (0,0)
constant C_SP_GAME_TILE_X_OFFSET        : integer   :=  20;
constant C_SP_GAME_TILE_Y_OFFSET        : integer   :=  7;
--AI Mode
constant C_PLAYER_GAME_TILE_X_OFFSET        : integer   :=  14;
constant C_PLAYER_GAME_TILE_Y_OFFSET        : integer   :=  7;
constant C_AI_GAME_TILE_X_OFFSET            : integer   :=  26;
constant C_AI_GAME_TILE_Y_OFFSET            : integer   :=  7;

type t_pos_calc_res is record
    res     : t_tile_pos;
    stat    : boolean;
end record;

---------------------------------------------------------------------------
-- Animation
---------------------------------------------------------------------------

constant C_ANIMATION_TILE_SIZE          : integer   :=  64;
constant C_ANIMATION_ZONE_X_SIZE        : integer   :=  4;
constant C_ANIMATION_ZONE_Y_SIZE        : integer   :=  4;

-- AI SCREEN
constant C_ANIMATION_AI_TILE_X_OFFSET      : integer   :=  40;
constant C_ANIMATION_AI_TILE_Y_1_OFFSET      : integer   :=  15;
constant C_ANIMATION_AI_TILE_Y_2_OFFSET      : integer   :=  22;

---------------------------------------------------------------------------
-- Bricks
---------------------------------------------------------------------------

constant C_NUM_OF_BRICKS    : integer := 7;

constant C_INIT_POS         :   t_game_tile_pos  := (5,0); 
--constant C_NEXT_POS         :   t_tile_pos       := (35,15); 

constant C_INSERT   :   integer := 0;
constant C_DOWN     :   integer := 1;
constant C_LEFT     :   integer := 2;
constant C_RIGHT    :   integer := 3;
constant C_CW       :   integer := 4;
constant C_CCW      :   integer := 5;
constant C_NUM_OF_MOVES :   integer := 6;

subtype t_brick is integer range 1 to C_NUM_OF_BRICKS;

type t_pos_diff is record
    DX  : integer range -4 to 4; 
    DY  : integer range -4 to 4; 
end record;

type t_game_pos_arr is array (0 to C_GAME_ZONE_X_SIZE-1) of t_game_tile_pos;
type t_tile_pos_arr is array (0 to C_GAME_ZONE_X_SIZE-1) of t_tile_pos;

type t_brick_info is record
    BTYPE   :   t_brick;            --  Brick type
    POS     :   t_game_tile_pos;    --  Brick Position in game region
    ROT     :   integer range 0 to 3;-- Brick Rotation   
end record;


---------------------------------------------------------------------------
-- Color types
---------------------------------------------------------------------------

type t_tile_type is (t_background, t_text, t_game);

constant C_GAME_TILE    :  std_logic_vector(1 downto 0) := "01";
constant C_GRID_TILE    :  std_logic_vector(15 downto 0) := "0000111000000000";
constant C_BLACK_TILE   :  std_logic_vector(15 downto 0) := "0100000000000000";


type t_color is record
    RED     :   integer range 0 to 15;
    GREEN   :   integer range 0 to 15;
    BLUE    :   integer range 0 to 15;    
end record;

type t_palette is array (natural range <> ) of t_color;
type t_palette_arr is array (natural range <> ) of t_palette;

---------------------------------------------------------------------------
-- Commands
---------------------------------------------------------------------------
constant C_MAX_DIGITS   : integer := 6;

subtype t_digit is integer range 0 to 9;
type t_digits_arr is array (0 to C_MAX_DIGITS-1) of t_digit;
type t_digits_7seg_arr is array (0 to C_MAX_DIGITS-1) of std_logic_vector(7 downto 0);


type t_usr_cmnd is (cmd_left, cmd_right, cmd_cw, cmd_ccw, cmd_down, cmd_move, cmd_lines, cmd_drop, cmd_start, cmd_select);

type t_usr_cmd_rec is record
    STRB    :   std_logic;
    CMD     :   t_usr_cmnd;
end record;

type t_init_mem_cmnd is (cmd_splash, cmd_init, cmd_init_ai, cmd_update);

type t_init_mem_cmnd_rec is record
    STRB    :   std_logic;
    CMD     :   t_init_mem_cmnd;
end record;

type t_update_info_cmnd is (cmd_init, cmd_score, cmd_stats, cmd_lines, cmd_level, cmd_rounds, cmd_game_over);

type t_num_rec is record    
    INT_NUM : integer range 0 to 10**C_MAX_DIGITS - 1;
    BCD_NUM : t_digits_arr;
end record;

type t_update_info_cmnd_rec is record
    STRB    :   std_logic;
    CMD     :   t_update_info_cmnd;
    DATA    :   t_num_rec;
end record;

type t_sram_cmnd_rec is record
    WRADDR		:  	std_logic_vector(10 downto 0) ;
    DATA		:  	std_logic_vector(15 downto 0) ;   
    WEN		    : 	std_logic ;
end record;


---------------------------------------------------------------------------
-- USER Interface
---------------------------------------------------------------------------

constant C_USER_SAMPLE_T: integer := 80 / (1+C_SIM*99); --mili secs
constant C_LONG_PUSH    : integer := 5;
constant C_PRESSED      : std_logic := '0' ;

---------------------------------------------------------------------------
-- INFO
---------------------------------------------------------------------------


constant C_SCORE_DIGITS         :   integer := 5;
constant C_STATS_DIGITS         :   integer := 3;
constant C_LEVEL_DIGITS         :   integer := 2;
constant C_ROUND_DIGITS         :   integer := 3;

--Single Player mode:
constant C_GAME_SCORE_TILE_Y    :   integer := 10;
constant C_TOP_SCORE_TILE_Y     :   integer := 6;
constant C_SCORE_TILE_X         :   integer := 34; 
constant C_LINES_TILE_Y         :   integer := 4;
constant C_LINES_TILE_X         :   integer := 27; 
constant C_LEVEL_TILE_Y         :   integer := 23;
constant C_LEVEL_TILE_X         :   integer := 34; 
constant C_NEXT_TILE_Y          :   integer := 16;

--AI Mode:
constant C_AI_SCORE_TILE_Y              :   integer := 5;
constant C_AI_PLAYER_SCORE_TILE_X       :   integer := 17; 
constant C_AI_AI_SCORE_TILE_X           :   integer := 29; 

constant C_AI_NEXT_TILE_Y           :   integer := 10;

constant C_AI_ROUNDS_TILE_Y          :   integer := 5;
constant C_AI_ROUNDS_TILE_X          :   integer := 41;

constant C_END_TILE_Y           :   integer := 14;
constant C_END_TILE_X           :   integer := 21; 
--GAME_OVER
constant C_GAME_TEXT           :   t_int_arr (0 to 3) := (6, 0, 12,4); 
constant C_OVER_TEXT           :   t_int_arr (0 to 3) := (14,21,4,17); 


constant C_STATS_TILE_Y             :   t_int_arr (1 to 7) := (7, 10, 13, 16, 19, 22, 25);
constant C_SP_STATS_TILE_X          :   integer := 15; 
constant C_AI_STATS_TILE_X          :   integer := 9; 
constant C_BCD_TO_TEXT           :   t_int_arr (0 to 9) := (26, 27,28,29,30,31,32,33,34,35);

constant C_MAX_SCORE    : integer := 10**C_SCORE_DIGITS-1;



---------------------------------------------------------------------------
-- GAMEPLAY
---------------------------------------------------------------------------

type t_game_mode is (ai_mode, sp_mode);
type t_winner is (player, ai, none);

constant C_LINES_PER_LEVEL      :   integer := 10;
constant C_MAX_LEVEL            :   integer := 20;
constant C_AI_ROUNDS            :   integer := 100;

type t_level_arr is array (1 to C_MAX_LEVEL) of integer range 0 to 1023;

constant C_AI_GRAVITY           :   t_level_arr := (332/(1+C_SIM*9),267,200/(1+C_SIM*9),167,150,134,117,100,83,67,60,54,47,40,34,30,27,20,17,14);
constant C_GRAVITY              :   t_level_arr := (996/(1+C_SIM*9),801,600/(1+C_SIM*9),501,450,402,351,300,249,201,180,162,141,120,102,90,81,60,51,42);

---------------------------------------------------------------------------
-- Functions
---------------------------------------------------------------------------

-- function TilePos(pixel_pos : t_pixel_pos)
-- return  t_tile_pos;

function Mod4(inp : integer)
return  integer;

function Mod16(inp : integer)
return  integer;

function Mod32(inp : integer)
return  integer;

function HalfTone(inp : t_color)
return  t_color;

function AddDelta(delta : t_pos_diff; pos : t_game_tile_pos)
return t_pos_calc_res;

function AddDelta(delta : t_pos_diff; pos : t_tile_pos)
return t_pos_calc_res;

function IsGameTileFree(tile : std_logic_vector(15 downto 0))
return boolean;

function ToScreenTile( pos : t_game_tile_pos)
return t_tile_pos;

function ToGameTile( pos : t_tile_pos)
return t_game_tile_pos;

function UpdatePos( pos : t_game_tile_pos; dir : integer range 0 to C_NUM_OF_MOVES-1)
return t_game_tile_pos;

function UpdateRot( rot : integer range 0 to 3; dir : integer range 0 to C_NUM_OF_MOVES-1)
return integer;

function UsrCmnd2Move(cmnd : t_usr_cmnd)
return integer;

function Move2Cmnd(move : integer range 0 to  C_NUM_OF_MOVES-1)
return t_usr_cmnd;

function to_bcd ( num : integer range 0 to 511 ) -- 0 to 511
return std_logic_vector ;

function to_digit(bin : std_logic_vector(3 downto 0))
return t_digit;

-- function SpritePosRot(arr  : t_sprite_pos_arr)
-- return t_sprite_pos_arr ;

-- function SpritePointerRot(arr  : t_sprite_pointer_arr)
-- return t_sprite_pointer_arr ;

------------------------------------------------------------------------------- 
end top_pack;
-------------------------------------------------------------------------------

package body top_pack is 

-----------------------------------------------------------------------------
-- function TilePos(pixel_pos : t_pixel_pos)   
-- return  t_tile_pos is
-- variable temp_x : std_logic_vector(9 downto 0);
-- variable temp_y : std_logic_vector(9 downto 0);
-- variable result : t_tile_pos;
-- begin
--     temp_x := std_logic_vector(to_unsigned( pixel_pos.X, 10));
--     temp_y := std_logic_vector(to_unsigned( pixel_pos.Y, 10));

--     result.X := to_integer(unsigned(temp_x(9 downto 4))) ;
--     result.Y := to_integer(unsigned(temp_y(9 downto 4))) ;

--     return result;
-- end TilePos;
-----------------------------------------------------------------------------

function Mod4(inp : integer )   
return  integer is
variable temp : std_logic_vector(9 downto 0);
variable result : integer range 0 to 3;
begin

    temp := std_logic_vector(to_unsigned( inp, 10));

    result := to_integer(unsigned(temp(1 downto 0))) ;

    return result;

end Mod4;
-----------------------------------------------------------------------------

function Mod16(inp : integer )   
return  integer is
variable temp : std_logic_vector(9 downto 0);
variable result : integer range 0 to 15;
begin

    temp := std_logic_vector(to_unsigned( inp, 10));

    result := to_integer(unsigned(temp(3 downto 0))) ;

    return result;

end Mod16;

-----------------------------------------------------------------------------

function Mod32(inp : integer )   
return  integer is
variable temp : std_logic_vector(9 downto 0);
variable result : integer range 0 to 31;
begin

    temp := std_logic_vector(to_unsigned( inp, 10));

    result := to_integer(unsigned(temp(4 downto 0))) ;

    return result;

end Mod32;

-----------------------------------------------------------------------------
function HalfTone(inp : t_color)
return  t_color is
variable result : t_color;
begin

    result.RED      := inp.RED/2;
    result.GREEN    := inp.GREEN/2;
    result.BLUE     := inp.BLUE/2;

    return result;

end HalfTone;

-----------------------------------------------------------------------------
function AddDelta(delta : t_pos_diff; pos : t_game_tile_pos)
return t_pos_calc_res is
variable result :  t_pos_calc_res;
begin

    if  pos.X + delta.DX >= 0 and pos.X + delta.DX < C_GAME_ZONE_X_SIZE and 
        pos.Y + delta.DY >= 0 and pos.Y + delta.DY < C_GAME_ZONE_Y_SIZE then
            result.res.X := pos.X + delta.DX;
            result.res.Y := pos.Y + delta.DY;
            result.stat := true;
    else
        result.res.X := 0;
        result.res.Y := 0;
        result.stat := false;
    end if;
    return result;

end AddDelta;

function AddDelta(delta : t_pos_diff; pos : t_tile_pos)
return t_pos_calc_res is
variable result :  t_pos_calc_res;
begin

    if  pos.X + delta.DX >= 0 and pos.X + delta.DX < C_VIDEO_HACTIVE / C_TILE_SIZE and 
        pos.Y + delta.DY >= 0 and pos.Y + delta.DY < C_VIDEO_VACTIVE / C_TILE_SIZE then
            result.res.X := pos.X + delta.DX;
            result.res.Y := pos.Y + delta.DY;
            result.stat := true;
    else
        result.res.X := 0;
        result.res.Y := 0;
        result.stat := false;
    end if;
    return result;

end AddDelta;

-----------------------------------------------------------------------------

function IsGameTileFree(tile : std_logic_vector(15 downto 0)) 
return boolean is 
begin

    if tile = C_GRID_TILE then
        return true;
    else
        return false; 
    end if; 


end IsGameTileFree;
------------------------------------------------------------------------------- 

function ToScreenTile( pos : t_game_tile_pos)
return t_tile_pos is 
variable result :  t_tile_pos;
begin 

    result.X := pos.X;
    result.Y := pos.Y;


    return result;
end ToScreenTile;

------------------------------------------------------------------------------ 

function ToGameTile( pos : t_tile_pos)
return t_game_tile_pos is 
variable result :  t_game_tile_pos;
begin 

    if pos.X < 10 then
        result.X := pos.X;
    else
        result.X := C_GAME_ZONE_X_SIZE-1;
    end if;

    if pos.Y < 20 then
        result.Y := pos.Y;
    else
        result.Y := C_GAME_ZONE_Y_SIZE-1;
    end if;

    return result;
end ToGameTile;

-------------------------------------------------------------------------------

function UpdatePos( pos : t_game_tile_pos; dir : integer range 0 to C_NUM_OF_MOVES-1)
return t_game_tile_pos is
variable result :  t_game_tile_pos;
begin
    result := pos; 
    case dir is 

        when C_DOWN => 
            result.Y := pos.Y + 1; 
        when C_LEFT => 
            result.X := pos.X - 1; 
        when C_RIGHT => 
            result.X := pos.X + 1; 
        when others => 
            -- do nothing
    end case;

    return result;    
end UpdatePos;

-------------------------------------------------------------------------------

function UpdateRot( rot : integer range 0 to 3; dir : integer range 0 to C_NUM_OF_MOVES-1)
return integer is
variable result :  integer;
begin
    result := rot; 
    case dir is 

        when C_CW => 
            if rot < 3 then
                result := rot + 1; 
            else
                result := 0;
            end if;
        when C_CCW => 
        if rot > 0 then
            result := rot - 1; 
        else
            result := 3;
        end if; 
        
        when others => 
            -- do nothing
    end case;

    return result;    
end UpdateRot;    

-------------------------------------------------------------------------------

function UsrCmnd2Move(cmnd : t_usr_cmnd)
return integer is
begin
    case cmnd is 
        when cmd_drop =>
            return 1;
        when cmd_down =>
            return 1;
        when cmd_left =>
            return 2;
        when cmd_right =>
            return 3;
        when cmd_cw =>
            return 4;
        when cmd_ccw =>
            return 5;
        when others =>
            return 1;
    end case;

end UsrCmnd2Move;

-------------------------------------------------------------------------------

function Move2Cmnd(move : integer range 0 to  C_NUM_OF_MOVES-1)
return t_usr_cmnd is

begin
    case move is 
        when 1 =>
            return cmd_down;
        when 2 =>
            return cmd_left;
        when 3 =>
            return cmd_right;
        when 4 =>
            return cmd_cw;
        when 5 =>
            return cmd_ccw;
        when others =>
            return cmd_lines;
    end case;

end Move2Cmnd;


-------------------------------------------------------------------------------

function to_bcd ( num : integer range 0 to 511 ) 
return std_logic_vector is
    --variable i : integer:=0;
    variable bcd : std_logic_vector(11 downto 0) := (others => '0');
    variable bint : std_logic_vector(8 downto 0) := std_logic_vector(to_unsigned( num, 9));
    
    begin
        for i in 0 to 8 loop  
            bcd(11 downto 1) := bcd(10 downto 0);  --shifting the bits.
            bcd(0) := bint(8);
            bint(8 downto 1) := bint(7 downto 0);
            bint(0) :='0';
            
            
            if(i < 8 and bcd(3 downto 0) > "0100") then --add 3 if BCD digit is greater than 4.
                bcd(3 downto 0) := std_logic_vector(unsigned(bcd(3 downto 0)) + 3); --"0011";
            end if;
            
            if(i < 8 and bcd(7 downto 4) > "0100") then --add 3 if BCD digit is greater than 4.
                bcd(7 downto 4) := std_logic_vector(unsigned(bcd(7 downto 4)) + 3);--"0011";
            end if;
            
            if(i < 8 and bcd(11 downto 8) > "0100") then  --add 3 if BCD digit is greater than 4.
                bcd(11 downto 8) := std_logic_vector(unsigned(bcd(11 downto 8)) + 3);--"0011";
            end if;
        
        end loop;
    return bcd;
    end to_bcd;
-------------------------------------------------------------------------------

function to_digit(bin : std_logic_vector(3 downto 0))
return t_digit is
variable dig : t_digit;
begin

    dig := to_integer(unsigned(bin));


return dig;
end to_digit;


-------------------------------------------------------------------------------

-- function SpritePosRot(arr  : t_sprite_pos_arr)
-- return t_sprite_pos_arr is
-- variable res : t_sprite_pos_arr;
-- begin

--     for i in 0 to 8 loop
--         if arr(i).Y = 0 then 
--             if arr(i).X < C_ANIMATION_ZONE_X_SIZE/2-1 then 
--                 res(i).X := arr(i).X + 1;
--                 res(i).Y := 0;
--             else
--                 res(i).Y := 1;
--                 res(i).X := C_ANIMATION_ZONE_X_SIZE/2-1;
--             end if;
--         elsif arr(i).Y = C_ANIMATION_ZONE_Y_SIZE/2-1 then
--             if arr(i).X > 0 then 
--                 res(i).X := arr(i).X - 1;
--                 res(i).Y := C_ANIMATION_ZONE_Y_SIZE/2-1;
--             else
--                 res(i).Y := C_ANIMATION_ZONE_Y_SIZE/2-2;
--                 res(i).X := 0;
--             end if;
--         elsif arr(i).X = 0 then
--             if arr(i).Y > 0 then 
--                 res(i).X := 0;
--                 res(i).Y := arr(i).Y - 1;
--             end if;
--         elsif arr(i).X = C_ANIMATION_ZONE_X_SIZE/2-1 then
--             if arr(i).Y < C_ANIMATION_ZONE_Y_SIZE/2-1 then 
--                 res(i).X := C_ANIMATION_ZONE_X_SIZE/2-1;
--                 res(i).Y := arr(i).Y + 1;
--             end if;
--         end if;
--     end loop;            
-- return res;
-- end SpritePosRot;


-- -------------------------------------------------------------------------------

-- function SpritePointerRot(arr  : t_sprite_pointer_arr)
-- return t_sprite_pointer_arr is
-- variable res : t_sprite_pointer_arr;
-- begin
--     res(8) := arr(0);

--     for i in 0 to 7 loop
--         res(i) := arr(i+1);
--     end loop;

-- return res;
-- end SpritePointerRot;



-------------------------------------------------------------------------------

end top_pack;
-------------------------------------------------------------------------------



