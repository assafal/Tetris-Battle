library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library WORK;
use WORK.top_pack.all;

entity clk_and_rst is
port
(	
	CLK_IN		: in std_logic ;			
	RST_IN		: in std_logic ;

	LCD_CLK 	: out	std_logic ;
	PCLK		: out	std_logic ;
	--RST_N		: out	std_logic ;
	PRST_N		: out	std_logic 
);
end clk_and_rst;

architecture clk_and_rst_arch of clk_and_rst is

---------------------------------------------------------------------------
-- Components
---------------------------------------------------------------------------

component alt_pll is
	port (
		 
	areset 	: in std_logic;
	inclk0	: in std_logic;
	c0		: out std_logic;
	c1		: out std_logic;
	locked	: out std_logic		
	);
end component;	

---------------------------------------------------------------------------
-- Signals
---------------------------------------------------------------------------

signal reset_in 	:	std_logic;
signal reset_in_s 	:	std_logic;
signal preset_in_s 	:	std_logic;
signal lcd_clk_int	:	std_logic;
signal pclk_int	 	:	std_logic;
signal pll_locked	:	std_logic;
  
begin

	
---------------------------------------------------------------------------
-- PLL and Reset
---------------------------------------------------------------------------

reset_in    <= not(RST_IN);
LCD_CLK     <= lcd_clk_int;
PCLK        <= pclk_int;

pll_u :  alt_pll
port map
(
			
	areset 	=> reset_in,
	inclk0	=> CLK_IN,
	c0		=> pclk_int,
	c1		=> lcd_clk_int,
	locked	=> pll_locked
);


process (pclk_int, reset_in)
begin
	if reset_in = '1' then
		PRST_N 	    <= '0';
		preset_in_s	<= '0';

	elsif rising_edge(pclk_int) then
        if pll_locked='1' then
		    PRST_N		 	<= preset_in_s;
		    preset_in_s 	<= '1';
        else
            PRST_N 	    <= '0';
            preset_in_s	<= '0';
        end if;
               
	end if;
end process;
	



end clk_and_rst_arch;
 
	
	
	
	
	
