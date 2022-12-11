library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library WORK;
use WORK.top_pack.all;
use work.brick_position_pack.all;

-------------------------------------------------------------------------------
package AI_pack is
-------------------------------------------------------------------------------

type t_game_board is array (0 to C_GAME_ZONE_Y_SIZE-1) of  std_logic_vector( 0 to C_GAME_ZONE_X_SIZE-1);
type t_board_arr is array (natural range <> ) of t_game_board;

type t_top_rows     is array (0 to C_GAME_ZONE_X_SIZE-1) of integer range -1 to C_GAME_ZONE_Y_SIZE-1;
type t_top_rows_arr is array (0 to 3) of t_top_rows;

type t_AI_board_process is (s_idle, s_wait_board_map, s_wait_top_rows, s_top_rows, s_wait);    

constant C_FULL_LINE    : std_logic_vector( 0 to C_GAME_ZONE_X_SIZE-1) := (others => '1');

constant C_MAX_MOVES    : integer := 32; --19(down) + 5(left/right) + 3(rotation) rounded to power of 2 

constant C_DOWN_PHASE   : integer := 3; -- Force down move every 3 moves.

type t_path_record is record
    POS     :   t_game_tile_pos;    --  Brick Position in game region
    ROT     :   integer range 0 to 3;-- Brick Rotation   
    MOV     :   integer range 1 to 4;
    D_COUNT :   integer range 0 to C_DOWN_PHASE-1;
    IDX     :   integer range 0 to C_MAX_MOVES-1;
end record;

type t_path_arr is array (0 to C_MAX_MOVES-1) of t_path_record;

-------------------------------------------------------------------------------
function GetTopRow( board : t_game_board; 
                    start_row : integer range 0 to C_GAME_ZONE_Y_SIZE-1;
                    col_index : integer range 0 to C_GAME_ZONE_X_SIZE-1)
return integer;

function TestLocation(  board : t_game_board; 
                        col_index : integer range 0 to C_GAME_ZONE_X_SIZE-1;
                        row_index : integer range 0 to C_GAME_ZONE_Y_SIZE-1;
                        rotation  : integer range 0 to 3;
                        brick_type: t_brick)
return std_logic;

function UpdateBoard(   board : t_game_board; 
                        col_index : integer range 0 to C_GAME_ZONE_X_SIZE-1;
                        row_index : integer range 0 to C_GAME_ZONE_Y_SIZE-1;
                        rotation  : integer range 0 to 3;
                        brick_type: t_brick)
return t_game_board ;

-- function Score(   board : t_game_board)        
-- return integer;

function Score(   board : t_game_board; y : integer range 0 to C_GAME_ZONE_Y_SIZE-1 )        
return integer ;

function Dist(start : t_brick_info; target :t_brick_info )
return integer;

function TestOp(board : t_game_board; op : integer range 1 to 4; curr_pos : t_brick_info; down : integer range 0 to C_DOWN_PHASE-1)
return std_logic;

function DoOp(op : integer range 1 to 4; curr_pos : t_brick_info ; down : integer range 0 to C_DOWN_PHASE-1)
return t_brick_info;

-- function ToRamVector(   pos : t_game_tile_pos; 
--                         rotation  : integer range 0 to 3;
--                         op_counter : integer range 1 to 4;
--                         down_counter : integer range 0 to C_GAME_ZONE_Y_SIZE-1;
--                         move_index : integer range 0 to C_GAME_ZONE_Y_SIZE-1
--                     )
-- return std_logic_vector ;

-- function ToPathRecord(vec_in : std_logic_vector  (22 downto 0))
-- return t_path_record;

------------------------------------------------------------------------------- 
end AI_pack;
-------------------------------------------------------------------------------

package body AI_pack is 

------------------------------------------------------------------------------- 
function GetTopRow( board : t_game_board; 
                    start_row : integer range 0 to C_GAME_ZONE_Y_SIZE-1;
                    col_index : integer range 0 to C_GAME_ZONE_X_SIZE-1)
return integer is
variable res : integer := -1 ;
begin

    for i in 0 to C_GAME_ZONE_Y_SIZE-1 loop
        if i >= start_row then
            if board(i)(col_index) = '1' then 
                res := i;
            else
                return res;
            end if;
        end if;
    end loop;

    return res;
end GetTopRow;
------------------------------------------------------------------------------- 

------------------------------------------------------------------------------- 
function TestLocation(  board : t_game_board; 
                        col_index : integer range 0 to C_GAME_ZONE_X_SIZE-1;
                        row_index : integer range 0 to C_GAME_ZONE_Y_SIZE-1;
                        rotation  : integer range 0 to 3;
                        brick_type: t_brick)
return std_logic is
variable pos_diff   : t_pos_diff ;
variable res        : std_logic := '1';
begin

    -- if row_index < 0 then
    --     return '0';
    -- else

    res := '1';

        for i in 0 to 3 loop

            if res then
                pos_diff.DX := C_MOVE_MAP(brick_type)(rotation)(0).elements_rw(i).DX;
                pos_diff.DY := C_MOVE_MAP(brick_type)(rotation)(0).elements_rw(i).DY;

                if col_index+pos_diff.DX < 0 or col_index+pos_diff.DX > C_GAME_ZONE_X_SIZE-1 or row_index+pos_diff.DY < 0 or row_index+pos_diff.DY > C_GAME_ZONE_Y_SIZE-1  then
                    res := '0';                
                else
                    if board(row_index+pos_diff.DY)(col_index+pos_diff.DX) = '1' then 
                        res := '0';                
                    end if;
                end if;
            end if;
        end loop;
--        end if;

    return res;
end TestLocation;
------------------------------------------------------------------------------- 

------------------------------------------------------------------------------- 
function UpdateBoard(   board : t_game_board; 
                        col_index : integer range 0 to C_GAME_ZONE_X_SIZE-1;
                        row_index : integer range 0 to C_GAME_ZONE_Y_SIZE-1;
                        rotation  : integer range 0 to 3;
                        brick_type: t_brick)
return t_game_board is
variable pos_diff   : t_pos_diff ;
variable res        : t_game_board;
begin

    res := board;

    for i in 0 to 3 loop

        pos_diff.DX := C_MOVE_MAP(brick_type)(rotation)(0).elements_rw(i).DX;
        pos_diff.DY := C_MOVE_MAP(brick_type)(rotation)(0).elements_rw(i).DY;

        res(row_index+pos_diff.DY)(col_index+pos_diff.DX) := '1';
        
    end loop;

    -- Remove empty lines
    for y in 1 to C_GAME_ZONE_Y_SIZE-1 loop
        
        if res(y) = C_FULL_LINE then     
            for k in y downto 1 loop
                res(k) := res(k-1);                            
            end loop;
            res(0) := (others => '0');
        end if;

    end loop;  

    return res;
end UpdateBoard;
------------------------------------------------------------------------------- 


------------------------------------------------------------------------------- 
-- function Score(   board : t_game_board)        
-- return integer is
-- variable edge       : integer ;
-- variable val        : integer;
-- variable res        : integer;
-- begin

--     res := 0;

--     for y in 0 to C_GAME_ZONE_Y_SIZE-1 loop
--         for x in 0 to C_GAME_ZONE_X_SIZE-1 loop

--             if board(y)(x) = '1' then 

--                 val := 2*(C_GAME_ZONE_Y_SIZE - y);

--                 if x=0 or x = C_GAME_ZONE_X_SIZE-1 then 
--                     edge := 1;
--                 else
--                     edge := 0;
--                 end if;

--                 if y < C_GAME_ZONE_Y_SIZE-1 then
--                     if board(y+1)(x) = '0' then 
--                         val := val * (2+edge*2);
--                     end if;
--                 end if;

--                 res := res + val - 1*edge;
--             end if;

--         end loop;  
--     end loop;  

--     return res;
-- end Score;

------------------------------------------------------------------------------- 
function Score(   board : t_game_board; y : integer range 0 to C_GAME_ZONE_Y_SIZE-1 )        
return integer is
variable edge       : integer ;
variable val        : integer;
variable res        : integer;
begin

    res := 0;

    --for y in 0 to C_GAME_ZONE_Y_SIZE-1 loop
        for x in 0 to C_GAME_ZONE_X_SIZE-1 loop

            if board(y)(x) = '1' then 

                val := 2*(C_GAME_ZONE_Y_SIZE - y);

                if x=0 or x = C_GAME_ZONE_X_SIZE-1 then 
                    edge := 1;
                else
                    edge := 0;
                end if;

                if y < C_GAME_ZONE_Y_SIZE-1 then
                    if board(y+1)(x) = '0' then 
                        val := val * (2+edge*2);
                    end if;
                end if;

                res := res + val - 1*edge;
            end if;

        end loop;  
    --end loop;  

    return res;
end Score;
------------------------------------------------------------------------------- 

function Dist(start : t_brick_info; target :t_brick_info )
return integer is
variable res :integer;
begin

    if start.ROT > target.ROT then
        res := 4 + target.ROT - start.ROT;
    else
        res := target.ROT - start.ROT;
    end if;
    
    if start.POS.X > target.POS.X then
        res := res + start.POS.X - target.POS.X;
    else
        res := res + target.POS.X - start.POS.X;
    end if;

    return res;
    
end Dist;

------------------------------------------------------------------------------- 

function DoOp(op : integer range 1 to 4; curr_pos : t_brick_info; down : integer range 0 to C_DOWN_PHASE-1)
return t_brick_info is
variable res :t_brick_info;    
variable down_offset : integer range 0 to 1;    
begin

    down_offset := 0;

    if down=C_DOWN_PHASE-1 then
        --if curr_pos.POS.Y+1 <= C_GAME_ZONE_Y_SIZE-1 then
            down_offset := 1;
        --end if;
    end if;

    res := curr_pos;
    case op is

        when C_DOWN => 
            res.POS.Y :=  res.POS.Y+1;

        when C_LEFT => 
            res.POS.X :=  res.POS.X-1;
            res.POS.Y :=  res.POS.Y + down_offset ;

        when C_RIGHT => 
            res.POS.X :=  res.POS.X+1;
            res.POS.Y :=  res.POS.Y + down_offset ;

        when C_CW => 
            
            if curr_pos.ROT + 1 < 4 then
                res.ROT := curr_pos.ROT + 1;
            else
                res.ROT := curr_pos.ROT + 1 - 4;
            end if;            
            res.POS.Y :=  res.POS.Y + down_offset ;
    end case;

    return res;

end DoOp;

------------------------------------------------------------------------------- 

function TestOp(board : t_game_board; op : integer range 1 to 4; curr_pos : t_brick_info; down : integer range 0 to C_DOWN_PHASE-1)
return std_logic is
variable test        : std_logic;    
variable r           : integer range 0 to 3;    
variable down_offset : integer range 0 to 1;    
begin

    down_offset := 0;

    if down=C_DOWN_PHASE-1 then
        if curr_pos.POS.Y+1 <= C_GAME_ZONE_Y_SIZE-1 then
            down_offset := 1;
        else
            return '0';            
        end if;
    end if;

    case op is

        when C_DOWN => 
            if curr_pos.POS.Y+1 <= C_GAME_ZONE_Y_SIZE-1 then 

                test := TestLocation(board , curr_pos.POS.X, curr_pos.POS.Y+1, curr_pos.ROT, curr_pos.BTYPE); --board_map(curr_pos.ROT)(curr_pos.POS.Y+1)(curr_pos.POS.X)
                if test = '1' then 
                    return '1';
                else
                    return '0';
                end if;
            else
                return '0';
            end if;

        when C_LEFT => 
            if curr_pos.POS.X-1 >= 0 then 

                test := TestLocation(board , curr_pos.POS.X-1, curr_pos.POS.Y+down_offset, curr_pos.ROT, curr_pos.BTYPE); --board_map(curr_pos.ROT)(curr_pos.POS.Y+down_offset)(curr_pos.POS.X-1)

                if test = '1' then 
                    return '1';
                else
                    return '0';
                end if;
            else
                return '0';
            end if;

        when C_RIGHT => 
            if curr_pos.POS.X+1 <= C_GAME_ZONE_X_SIZE-1 then 

                test := TestLocation(board , curr_pos.POS.X+1, curr_pos.POS.Y+down_offset, curr_pos.ROT, curr_pos.BTYPE); --board_map(curr_pos.ROT)(curr_pos.POS.Y+down_offset)(curr_pos.POS.X+1)

                if test = '1' then 
                    return '1';
                else
                    return '0';
                end if;
            else
                return '0';
            end if;

        when C_CW => 
            
            if curr_pos.ROT + 1 < 4 then
                r := curr_pos.ROT + 1;
            else
                r := curr_pos.ROT + 1 - 4;
            end if;
            
            test := TestLocation(board , curr_pos.POS.X, curr_pos.POS.Y+down_offset, r, curr_pos.BTYPE); --board_map(r)(curr_pos.POS.Y+down_offset)(curr_pos.POS.X)
            
            if test = '1' then 
                return '1';
            else
                return '0';
            end if;
            

    end case;

end TestOp;

------------------------------------------------------------------------------- 

-- function ToRamVector(   pos : t_game_tile_pos; 
--                         rotation  : integer range 0 to 3;
--                         op_counter : integer range 1 to 4;
--                         down_counter : integer range 0 to C_GAME_ZONE_Y_SIZE-1;
--                         move_index : integer range 0 to C_GAME_ZONE_Y_SIZE-1
--                     )
-- return std_logic_vector is
-- variable res  : std_logic_vector  (22 downto 0);
-- begin    

--     res :=  std_logic_vector(to_unsigned( pos.Y , 5)) &  
--             std_logic_vector(to_unsigned( pos.X , 4)) &
--             std_logic_vector(to_unsigned( rotation , 2)) &
--             std_logic_vector(to_unsigned( op_counter-1 , 2)) &
--             std_logic_vector(to_unsigned( down_counter , 5)) &
--             std_logic_vector(to_unsigned( move_index , 5)) ;
    
--     return res;
-- end ToRamVector;
-- ------------------------------------------------------------------------------- 

-- function ToPathRecord(vec_in : std_logic_vector  (22 downto 0))
-- return t_path_record is
-- variable res  : t_path_record;
-- begin    

--     res.POS.Y   :=  to_integer(unsigned(vec_in(22 downto 18)));
--     res.POS.X   :=  to_integer(unsigned(vec_in(17 downto 14)));
--     res.ROT     :=  to_integer(unsigned(vec_in(13 downto 12)));
--     res.MOV     :=  1+to_integer(unsigned(vec_in(11 downto 10)));
--     res.D_COUNT :=  to_integer(unsigned(vec_in(9 downto 5)));
--     res.IDX     :=  to_integer(unsigned(vec_in(4 downto 0)));

--     return res;
-- end ToPathRecord;

-------------------------------------------------------------------------------

end AI_pack;
-------------------------------------------------------------------------------
