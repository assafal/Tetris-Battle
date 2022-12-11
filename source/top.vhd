library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library WORK;
use WORK.top_pack.all;
use WORK.brick_position_pack.all;


entity top is
port
(	
	CLK_50		: in std_logic ;			

	-- DE10 Swithes and Buttons
	SW			: in std_logic_vector(9 downto 0) ;
	BUTTON		: in std_logic_vector(1 downto 0) ;	

	-- DE10 Seven Segment:		
	HEX0		: out std_logic_vector(7 downto 0) ;		
	HEX1		: out std_logic_vector(7 downto 0) ;		
	HEX2		: out std_logic_vector(7 downto 0) ;		
	HEX3		: out std_logic_vector(7 downto 0) ;		
	HEX4		: out std_logic_vector(7 downto 0) ;		
	HEX5		: out std_logic_vector(7 downto 0) ;		
			
	-- DE10 LEDs:
	LED			: out	std_logic_vector(9 downto 0) ;

	-- GPIO LEDs:
	GPIO		: out std_logic_vector(5 downto 0) ;		

	-- LCD Interface (through DE10 Arduino IOs)
	LCD_DB		: out 	std_logic_vector(7 downto 0) ;
	LCD_RESET	: out 	std_logic ;
	LCD_WR		: out 	std_logic ;
	LCD_RD		: out 	std_logic ;
	LCD_D_C		: out 	std_logic ;
	LCD_BUZZER	: out 	std_logic ;
	LCD_LED		: out 	std_logic ;

	-- VGA Interface:
	RED			: out 	std_logic_vector(3 downto 0) ;
	GREEN		: out 	std_logic_vector(3 downto 0) ;
	BLUE		: out 	std_logic_vector(3 downto 0) ;
	H_SYNC		: out	std_logic ;
	V_SYNC		: out	std_logic 
);
end top;

architecture top_arch of top is

---------------------------------------------------------------------------
-- Components
---------------------------------------------------------------------------

component sram is
	port
	(
		clock		: in std_logic  := '1';
		data		: in std_logic_vector (15 downto 0);
		rdaddress	: in std_logic_vector (10 downto 0);
		wraddress	: in std_logic_vector (10 downto 0);
		wren		: in std_logic  := '0';
		q			: out std_logic_vector (15 downto 0)
	);
end component;


---------------------------------------------------------------------------
-- Signals
---------------------------------------------------------------------------

signal prst_n 		:	std_logic;
signal lcd_clk 			:	std_logic;
signal pclk 		:	std_logic;

signal screen_pos	:	t_pixel_pos;
signal pixel_pos	:	t_pixel_pos;
signal tile_pos		:	t_tile_pos;
signal mili_sec_tic	:	std_logic;

signal video_blank	:	std_logic;
signal video_sync	:	t_video_sync;

signal sram_data_in	: 	std_logic_vector (15 downto 0);
signal sram_data_out: 	std_logic_vector (15 downto 0);
signal game_rdaddr	: 	std_logic_vector (10 downto 0);
signal display_rdaddr	: 	std_logic_vector (10 downto 0);
signal ai_rdaddr	: 	std_logic_vector (10 downto 0);
signal sram_rdaddr	: 	std_logic_vector (10 downto 0);
signal sram_wraddr	: 	std_logic_vector (10 downto 0);
signal sram_wen		:	std_logic;

signal ai_sram_data_out: 	std_logic_vector (15 downto 0);
signal ai_sram_rdaddr	: 	std_logic_vector (10 downto 0);
signal ai_sram_data_in	: 	std_logic_vector (15 downto 0);
signal ai_sram_wen		:	std_logic;
signal ai_sram_wraddr	: 	std_logic_vector (10 downto 0);



signal random_vec   :   std_logic_vector(15 downto 0);

signal game_clear	:	std_logic;	
signal info_done	:	std_logic;	
signal ai_info_done	:	std_logic;	
signal init_done	:	std_logic;	
signal init_start	:	std_logic;	
signal player_game_done	:	std_logic;	
signal ai_game_done	:	std_logic;	
signal game_done	:	std_logic;	
signal game_start	:	std_logic;	
signal ai_game_start	:	std_logic;	
signal demo			:	std_logic;	
signal demo_stop	:	std_logic;	
signal game_stop_to_player	:	std_logic;	

signal ai_cmd		: 	t_usr_cmd_rec;
signal user_cmd		: 	t_usr_cmd_rec;
signal player_user_cmd		: 	t_usr_cmd_rec;

signal init_cmd		: 	t_init_mem_cmnd_rec;

signal info_cmd 			: t_update_info_cmnd_rec ;
signal ai_info_cmd 			: t_update_info_cmnd_rec ;
signal ai_info_sram_interface 	: t_sram_cmnd_rec;
signal info_sram_interface 	: t_sram_cmnd_rec;
signal init_sram_interface	: t_sram_cmnd_rec;
signal game_sram_interface	: t_sram_cmnd_rec;
signal ai_sram_interface	: t_sram_cmnd_rec;

signal level		:	integer range 1 to 10;
signal ai_tic		:	std_logic;	
signal drop_tic		:	std_logic;	
signal score        :  t_digits_arr;
signal seven_seg_num	:  t_digits_7seg_arr ;
signal game_mode	: t_game_mode;

signal player_game_tile_x_offset    : integer range 0 to C_X_TILE_COUNT-1;
signal player_game_tile_y_offset    : integer range 0 to C_Y_TILE_COUNT-1;

signal ai_player_ready  : std_logic;
signal player_ready     : std_logic;
signal ai_update        : std_logic;
signal winner      		: t_winner;        	
signal next_brick       : t_brick_info;
signal current_brick    : t_brick_info;

signal anima_valid    : std_logic;
signal anima_pixel    : t_color;

begin

HEX0	<=	seven_seg_num(0)	;
HEX1	<=	seven_seg_num(1)	;
HEX2	<=	seven_seg_num(2)	;
HEX3	<=	seven_seg_num(3)	;
HEX4	<=	seven_seg_num(4)	;
HEX5	<=	seven_seg_num(5)	;

LCD_LED	<= '0'; 

---------------------------------------------------------------------------
-- PLL and Reset
---------------------------------------------------------------------------

gen2_u : if C_SIM = 0 generate

	clk_and_rst_u :  entity work.clk_and_rst 
	port map
	(	
		CLK_IN		=> CLK_50,		
		RST_IN		=> BUTTON(0), 

		LCD_CLK 	=> lcd_clk, --clk,
		PCLK		=> pclk,

		PRST_N		=> prst_n
	);
end generate;


---------------------------------------------------------------------------
-- Timers
---------------------------------------------------------------------------

timer_u: entity work.timers 
port map
(	
	CLK	    		=> pclk,	
	RST_N 			=> prst_n,

	LEVEL			=> level,

	SCREEN_POS		=> screen_pos, 
	PIXEL_POS		=> pixel_pos,
	TILE_POS		=> tile_pos,
	
    VIDEO_SYNC      => video_sync,

	MILI_SEC_TIC	=> mili_sec_tic,
	DROP_TIC		=> drop_tic,
	AI_TIC			=> ai_tic,
	PWM				=> LCD_BUZZER,
	RAND_VECT		=> random_vec
);

---------------------------------------------------------------------------
-- Main FSM
---------------------------------------------------------------------------

fsm_u : entity work.main_fsm 
port map
(	
	CLK	    	=>	pclk,		--: in std_logic ;			
	RST_N 		=>	prst_n,		--: in std_logic ;

	USR_CMD		=>  user_cmd, 
	INIT_DONE   =>	init_done,	--: in std_logic;
	GAME_DONE	=> 	game_done,
	GAME_CLEAR 	=>  game_clear,

	PLAYER_INFO_CMD 	=> info_cmd, 
	AI_INFO_CMD 		=> ai_info_cmd, 

	INIT_CMD 	=>	init_cmd, 
	GAME_MODE	=>  game_mode, 
	GAME_START	=> 	game_start,	
	WINNER      => 	winner,
	DEMO		=>  demo,
	DEMO_STOP	=>  demo_stop,
	
	BLANK		=> 	video_blank

);

---------------------------------------------------------------------------
--Game Machine
---------------------------------------------------------------------------

player_game_tile_x_offset <= C_SP_GAME_TILE_X_OFFSET when game_mode=sp_mode else C_PLAYER_GAME_TILE_X_OFFSET;
player_game_tile_y_offset <= C_SP_GAME_TILE_Y_OFFSET when game_mode=sp_mode else C_PLAYER_GAME_TILE_Y_OFFSET;

player_user_cmd 	<= user_cmd when demo='0' else ai_cmd;
game_stop_to_player <= ai_game_done when demo='0' else demo_stop;
		

game_u : entity work.game_machine 
port map
(	
	CLK	    		=> pclk,	--: in std_logic ;			
	RST_N 			=> prst_n,	--: in std_logic ;

	CLEAR			=> game_clear,

	VIDEO_SYNC		=> video_sync,
	GAME_MODE		=> game_mode,
	LEVEL			=> level,

	GAME_START  	=> game_start,	--: in std_logic;
	GAME_STOP		=> game_stop_to_player,
	INFO_DONE   	=> info_done,	--: in std_logic;
	PLAYER_READY_IN	=> ai_player_ready,
	MILI_SEC_TIC	=> mili_sec_tic,	--	: in std_logic;
	DROP_TIC		=> drop_tic,
	RAND_VECT		=> random_vec,

	USR_CMD 		=> player_user_cmd,	--: in t_usr_cmd_rec ;

	GAME_TILE_X_OFFSET    => player_game_tile_x_offset   ,
	GAME_TILE_Y_OFFSET    => player_game_tile_y_offset   ,	         

	INFO_CMD 		=> info_cmd,	--: out t_update_info_cmnd_rec ;

	SRAM_INTERFACE	=> game_sram_interface, 
	SRAM_RDADDR		=> game_rdaddr,
	SRAM_DATA_IN	=> sram_data_out,
		
	GAME_DONE   		=> player_game_done,	--: out std_logic
	PLAYER_READY_OUT	=> player_ready,

    AI_UPDTAE           => ai_update , --: out std_logic;
    AI_NEXT_BRICK       => next_brick, --: out  t_brick_info;
    AI_CURRENT_BRICK    => current_brick --: out  t_brick_info

	
);

game_done	<=	player_game_done when game_mode = sp_mode else player_game_done and ai_game_done;

---------------------------------------------------------------------------
--AI Game Machine
---------------------------------------------------------------------------

ai_u : entity work.AI_top 
port map
(	
	CLK	    		=> pclk, --: in std_logic ;			
	RST_N 			=> prst_n, --: in std_logic ;

	AI_TIC	        => ai_tic,--: in std_logic;
    DROP_TIC	    => drop_tic,--: in std_logic;
	CLEAR			=> game_clear,
	UPDATE          => ai_update, --	: in std_logic;
	NEXT_BRICK      => next_brick,	 -- : in  t_brick_info;
	CURRENT_BRICK   => current_brick, -- : in  t_brick_info

	USER_CMD    	=> ai_cmd --: out t_usr_cmd_rec

);

ai_game_start	<=	 '0' when game_mode = sp_mode or demo='1' else game_start;

ai_game_u : entity work.game_machine 
port map
(	
	CLK	    		=> pclk,	--: in std_logic ;			
	RST_N 			=> prst_n,	--: in std_logic ;

	CLEAR			=> game_clear,

	VIDEO_SYNC		=> video_sync,
	GAME_MODE		=> game_mode,
	LEVEL			=> open,
	PLAYER_READY_IN	=> player_ready,

	GAME_START  	=> ai_game_start,	--: in std_logic;
	GAME_STOP		=> player_game_done,	--: in std_logic;
	INFO_DONE   	=> ai_info_done,	--: in std_logic;
	MILI_SEC_TIC	=> mili_sec_tic,	--	: in std_logic;
	DROP_TIC		=> drop_tic,
	RAND_VECT		=> random_vec,

	USR_CMD 		=> ai_cmd,	--: in t_usr_cmd_rec ;

	GAME_TILE_X_OFFSET    => C_AI_GAME_TILE_X_OFFSET   ,
	GAME_TILE_Y_OFFSET    => C_AI_GAME_TILE_Y_OFFSET   ,

	INFO_CMD 		=> ai_info_cmd,	--: out t_update_info_cmnd_rec ;
	PLAYER_READY_OUT=> ai_player_ready,

	SRAM_INTERFACE	=> ai_sram_interface, 
	SRAM_RDADDR		=> ai_rdaddr,
	SRAM_DATA_IN	=> ai_sram_data_out,
		
	GAME_DONE   	=> ai_game_done	--: out std_logic
	
);

---------------------------------------------------------------------------
-- User Interface
---------------------------------------------------------------------------

ui_u : entity work.user_interface
port map
(	
	CLK	    		=> pclk, 			--: in std_logic ;			
	RST_N 			=> prst_n, 			--: in std_logic ;

	SW				=> SW, 				--: in std_logic_vector(9 downto 0) ;
	BUTTON			=> BUTTON, 			--: in std_logic_vector(1 downto 0) ;	

	MILI_SEC_TIC	=> mili_sec_tic, 	--: in std_logic;

	USER_CMD    	=> user_cmd 		--: out t_usr_cmd_rec

);

---------------------------------------------------------------------------
-- MEM Init
---------------------------------------------------------------------------

init_u: entity work.init_mem 
port map
(	
	CLK	    	=>	pclk,	--: in std_logic ;			
	RST_N 		=>	prst_n,	--: in std_logic ;

	VIDEO_SYNC	=>  video_sync,
	CMD 		=>	init_cmd,	

	RAND_VECT   =>	random_vec, 	--    : in std_logic_vector(15 downto 0);

	SRAM_INTERFACE	=> init_sram_interface ,

	DONE		=>	init_done			--: out	std_logic 

);

---------------------------------------------------------------------------
-- SRAM
---------------------------------------------------------------------------
sram_wen		<=	info_sram_interface.WEN or init_sram_interface.WEN or game_sram_interface.WEN;

sram_data_in	<=	info_sram_interface.DATA 	when info_sram_interface.WEN='1' else 
					init_sram_interface.DATA	when init_sram_interface.WEN='1' else
					game_sram_interface.DATA;
sram_wraddr		<=	info_sram_interface.WRADDR 	when info_sram_interface.WEN='1' else 
					init_sram_interface.WRADDR	when init_sram_interface.WEN='1' else
					game_sram_interface.WRADDR;

sram_rdaddr		<=	game_rdaddr or display_rdaddr;


ram_u : sram 
port map
(
	clock		=>	pclk, 				--: in std_logic  := '1';
	data		=>	sram_data_in,			--: in std_logic_vector (15 downto 0);
	rdaddress	=>	sram_rdaddr,		--: in std_logic_vector (10 downto 0);
	wraddress	=>	sram_wraddr,		--: in std_logic_vector (10 downto 0);
	wren		=>	sram_wen,		 	--: in std_logic  := '0';
	q			=>	sram_data_out		--: out std_logic_vector (15 downto 0)
);

ai_sram_wen		<=	ai_info_sram_interface.WEN or init_sram_interface.WEN or ai_sram_interface.WEN;

ai_sram_wraddr	<= 	ai_info_sram_interface.WRADDR 	when ai_info_sram_interface.WEN='1' else
					init_sram_interface.WRADDR	when init_sram_interface.WEN='1' else
					ai_sram_interface.WRADDR;

ai_sram_data_in	<=	ai_info_sram_interface.DATA 	when ai_info_sram_interface.WEN='1' else 
					init_sram_interface.DATA	when init_sram_interface.WEN='1' else
					ai_sram_interface.DATA;

ai_sram_rdaddr		<=	ai_rdaddr or display_rdaddr;

ai_ram_u : sram 
port map
(
	clock		=>	pclk, 				--: in std_logic  := '1';
	data		=>	ai_sram_data_in,			--: in std_logic_vector (15 downto 0);
	rdaddress	=>	ai_sram_rdaddr,		--: in std_logic_vector (10 downto 0);
	wraddress	=>	ai_sram_wraddr,		--: in std_logic_vector (10 downto 0);
	wren		=>	ai_sram_wen ,		 	--: in std_logic  := '0';
	q			=>	ai_sram_data_out		--: out std_logic_vector (15 downto 0)
);

---------------------------------------------------------------------------
-- INFO Display
---------------------------------------------------------------------------

info_u : entity work.info_module 
generic	map
(
	G_AI_SCORE_TILE_X => C_AI_PLAYER_SCORE_TILE_X
)
port map
(	
	CLK	    		=> pclk, 	--: in std_logic ;			
	RST_N 			=> prst_n, 	--: in std_logic ;
	
	VIDEO_SYNC  	=> video_sync, 				--: in t_video_sync;
	GAME_MODE		=> game_mode,
	
	INFO_CMD 		=> info_cmd, 				--: in t_update_info_cmnd_rec ;
	SCORE           => score, 					--: out t_digits_arr;

	SRAM_INTERFACE  => info_sram_interface, 	--: out t_sram_cmnd_rec;
	DONE 	        => info_done 					--: out std_logic
);

ai_info_u : entity work.info_module 
generic map
(
	G_AI_SCORE_TILE_X => C_AI_AI_SCORE_TILE_X
)
port map
(	
	CLK	    		=> pclk, 	--: in std_logic ;			
	RST_N 			=> prst_n, 	--: in std_logic ;
	
	VIDEO_SYNC  	=> video_sync, 				--: in t_video_sync;
	GAME_MODE		=> game_mode,
	
	INFO_CMD 		=> ai_info_cmd, 				--: in t_update_info_cmnd_rec ;
	SCORE           => open, 					--: out t_digits_arr;

	SRAM_INTERFACE  => ai_info_sram_interface, 	--: out t_sram_cmnd_rec;
	DONE 	        => ai_info_done 					--: out std_logic

);


---------------------------------------------------------------------------
-- Seven Seg
---------------------------------------------------------------------------

gen_7u : if C_SIM = 0 generate

	seg7_u: entity work.seven_seg 
	port map
	(	
		CLK	    		=> pclk, 	--: in std_logic ;			
		RST_N 			=> prst_n, 	--: in std_logic ;
		MILI_SEC_TIC	=> mili_sec_tic,
		DROP_TIC		=> drop_tic,
		NUMBER 		    => score,

		SEVEN_SEG_NUM	=> seven_seg_num,
		GPIO			=> GPIO,
		LED 			=> LED	
	);

end generate;

---------------------------------------------------------------------------
-- Display Intreface
---------------------------------------------------------------------------

gen_u : if C_SIM = 0 generate

	disp_u : entity work.display_interface
	port map
	(	
		CLK	    		=>	pclk, 		--: in std_logic ;			
		LCD_CLK	   		=>	lcd_clk, 		--: in std_logic ;			
		RST_N 			=>	prst_n, 	--: in std_logic ;

		GAME_MODE		=> 	game_mode,
		WINNER      	=> 	winner,
		
		BLANK 			=>	video_blank,	--: in std_logic ;
		SCREEN_POS		=>	screen_pos,
		PIXEL_POS		=>	pixel_pos,		--: in t_pixel_pos ;
		TILE_POS		=>	tile_pos,		--: in t_tile_pos ;
		
		VIDEO_SYNC  	=>	video_sync,		--    : in t_video_sync;

		ANIMA_VALID 	=> anima_valid,
		ANIMA_PIXEL 	=> anima_pixel,
			
		SRAM_RDADDR		=>	display_rdaddr,	--	: out 	std_logic_vector(10 downto 0) ;
		SRAM_DATA		=>	sram_data_out,	--	: in 	std_logic_vector(15 downto 0) ;
		AI_SRAM_DATA	=> 	ai_sram_data_out, 

		--LCD Interface:

		LCD_DB			=>	LCD_DB	,			--: out 	std_logic_vector(7 downto 0) ;
		LCD_RESET		=>	LCD_RESET,			--: out 	std_logic ;
		LCD_WR			=>	LCD_WR	,			--: out 	std_logic ;
		LCD_RD			=>	LCD_RD	,			--: out 	std_logic ;
		LCD_D_C			=>	LCD_D_C	,			--: out 	std_logic ;

		-- VGA Interface
		RED				=>	RED	,			--: out 	std_logic_vector(3 downto 0) ;
		GREEN			=>	GREEN,			--: out 	std_logic_vector(3 downto 0) ;
		BLUE			=>	BLUE,			--: out 	std_logic_vector(3 downto 0) ;
		H_SYNC			=>	H_SYNC,			--: out	std_logic ;
		V_SYNC			=>	V_SYNC			--: out	std_logic 

	);

	else generate

		display_rdaddr <= (others => '0');

end generate;

anima_u: entity work.anima_display_interface 
port map
(	
	CLK	    	=> pclk, --: in std_logic ;			
	RST_N 		=> prst_n, --: in std_logic ;

	VIDEO_SYNC  => video_sync, --: in t_video_sync;
	ANIMA_TIC   => drop_tic, --: in std_logic ;

	GAME_MODE   => game_mode, --: in t_game_mode;

	PIXEL_POS	=> pixel_pos, --: in t_pixel_pos ;
	TILE_POS	=> tile_pos, --: in t_tile_pos ;

	ANIMA_VALID => anima_valid, --: out std_logic ;
	ANIMA_PIXEL => anima_pixel


);
	
	
end top_arch;