library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library WORK;
use WORK.top_pack.all;


-------------------------------------------------------------------------------
package color_pack is
-------------------------------------------------------------------------------
    


constant C_BLACK    :   t_color := (0,0,0);   
constant C_WHITE    :   t_color := (15,15,15);   
constant C_GREY     :   t_color := (12,12,12);   
constant C_BLUE     :   t_color := (0,0,15);   
constant C_GREEN    :   t_color := (0,15,0);   
constant C_RED      :   t_color := (15,0,0);   
constant C_YELLOW   :   t_color := (15,15,0);   
constant C_PINK     :   t_color := (15,8,12);   
constant C_PURPLE   :   t_color := (8,0,8);   
constant C_BROWN    :   t_color := (8,4,0);   
constant C_CYAN     :   t_color := (0,15,15);   

constant C_TEXT_PALETTE :  t_palette(0 to 3)            := ( C_BLACK, (8,8,8), (12,12,12), C_WHITE);
constant C_WINNER_TEXT_PALETTE :  t_palette(0 to 3)     := ( C_BLACK, HalfTone(HalfTone(C_RED)), HalfTone(C_RED), C_RED);
constant C_BACK_PALETTE :  t_palette(0 to 3)            := ( (3,2,3), (0,8,8), C_BLACK, HalfTone(C_BLUE));
constant C_ANIMA_PALETTE :  t_palette(0 to 15)            := (  C_BLACK, C_WHITE, HalfTone(C_GREY), C_YELLOW, C_RED, C_BLUE, C_CYAN,C_GREEN,C_PURPLE,
                                                                C_BROWN,C_BROWN,C_BROWN, C_BROWN,C_BROWN,C_BROWN,C_BROWN );
constant C_GAME_PALETTE :  t_palette_arr(0 to 7)(0 to 1)    := ((C_BLACK, C_BLACK) ,
                                                                (C_RED,     HalfTone(C_RED)) , 
                                                                (C_GREEN,   HalfTone(C_GREEN)) ,
                                                                (C_BLUE,    HalfTone(C_BLUE)) ,
                                                                (C_YELLOW,  HalfTone(C_YELLOW)) ,
                                                                (C_PINK,    HalfTone(C_PINK)) ,
                                                                (C_PURPLE,  HalfTone(C_PURPLE)) ,                                                               
                                                                (C_BROWN,   HalfTone(C_BROWN)) );

------------------------------------------------------------------------------- 
end color_pack;
-------------------------------------------------------------------------------
