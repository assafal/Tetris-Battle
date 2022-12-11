library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library WORK;
use WORK.top_pack.all;


entity init_mem is
port
(	
	CLK	    	: in std_logic ;			
    RST_N 		: in std_logic ;

    VIDEO_SYNC  : in t_video_sync;
    CMD 		: in t_init_mem_cmnd_rec ;

	RAND_VECT       : in std_logic_vector(15 downto 0);

    SRAM_INTERFACE  : out t_sram_cmnd_rec;

	DONE		    : out std_logic 

);
end init_mem;

architecture init_mem_arch of init_mem is



---------------------------------------------------------------------------
-- Components
---------------------------------------------------------------------------

component screen_map_rom 
generic 
(
    init_file	: string := "screen_map_rom.mif"	
);    
port
(    
    address		: in std_logic_vector (10 downto 0);
    clock		: in std_logic  := '1';
    q			: out std_logic_vector (15 downto 0)
);
end component;

component splash_rom 
port
(    
    address		: in std_logic_vector (9 downto 0);
    clock		: in std_logic  := '1';
    q			: out std_logic_vector (15 downto 0)
);
end component;
    

---------------------------------------------------------------------------
-- Constants
---------------------------------------------------------------------------

constant C_SPALSH_OFFSET    : integer   :=  484;--227; -- offset to the address space
constant C_MAX_FRAMES_DELAY    : integer   :=  64; 

type t_main_fsm is (s_idle, s_splash, s_game_map, s_ai_game_map);    
type t_map_fsm is (s_idle, s_read_1, s_read_2, s_write, s_done);    
type t_splash_fsm is (s_idle, s_clear_screen, s_read_1, s_read_2, s_add, s_write, s_wait, s_done);    


constant C_DEALY_SECTIONS   : integer   := 5;
type t_delay_c_arr is array (0 to C_DEALY_SECTIONS-1) of integer range 0 to C_SPALSH_OFFSET;
type t_delay_f_arr is array (0 to C_DEALY_SECTIONS-1) of integer range 0 to C_MAX_FRAMES_DELAY-1;

constant C_DEALY_COUNT      : t_delay_c_arr := (1, 10, 80,130, C_SPALSH_OFFSET);
constant C_DEALY_FRAMES     : t_delay_f_arr := (60, 2, 2, 1, 1);

---------------------------------------------------------------------------
-- Signals
---------------------------------------------------------------------------

signal main_fsm 	    :	t_main_fsm;
signal game_map_fsm     :	t_map_fsm;
signal splash_fsm       :	t_splash_fsm;
signal next_state       :	t_splash_fsm;

signal splash_rom_data  :   std_logic_vector (15 downto 0);
signal splash_data      :   std_logic_vector (15 downto 0);
signal map_rom_data     :   std_logic_vector (15 downto 0);
signal ai_map_rom_data  :   std_logic_vector (15 downto 0);
signal selected_data    :   std_logic_vector (15 downto 0);

signal selected_rom_data  :   std_logic_vector (15 downto 0);

signal game_map_add     :   integer range 0 to C_TILE_COUNT-1; -- 2 bytes per tile, 16 bytes in one address
signal game_map_done    :   std_logic;
signal fast_splash      :   std_logic;

signal splash_rom_add   :   integer range 0 to 1023; 
signal splash_ram_add   :   integer range 0 to C_TILE_COUNT-1; 
signal splash_done      :   std_logic;
signal data_counter     :   integer range 0 to C_SPALSH_OFFSET-1; 
signal frame_counter    :   integer range 0 to C_MAX_FRAMES_DELAY-1;
signal delay_section    :   integer range 0 to C_DEALY_SECTIONS-1;


begin

SRAM_INTERFACE.WRADDR <= std_logic_vector(to_unsigned(game_map_add, 11))  when main_fsm=s_game_map or main_fsm=s_ai_game_map else 
                         std_logic_vector(to_unsigned(splash_ram_add, 11)) ; 

SRAM_INTERFACE.WEN    <= '1' when game_map_fsm = s_write or splash_fsm = s_write or splash_fsm = s_clear_screen else '0';
SRAM_INTERFACE.DATA   <= selected_data;     

---------------------------------------------------------------------------
-- Main FSM
---------------------------------------------------------------------------    

process (CLK, RST_N)
begin
	if RST_N = '0' then
		
        main_fsm    <=  s_idle;
        DONE        <= '0';
        fast_splash <= '0';

    elsif rising_edge(CLK) then

        case main_fsm is 

            when s_idle =>
                DONE    <= '0';
                if CMD.STRB = '1' then
                    if CMD.CMD = cmd_splash then                     
                        main_fsm    <=  s_splash;
                                                
                    elsif CMD.CMD = cmd_init_ai then
                        main_fsm    <=  s_ai_game_map;
                    else
                        main_fsm    <=  s_game_map;
                    end if;
                    
                end if;
            
            when s_splash =>                

                if splash_done='1' or C_SIM=1 then 
                    main_fsm    <=  s_idle;
                    fast_splash <= '1';
                    DONE        <= '1';
                end if;

            when s_game_map =>

                if game_map_done='1' then 
                    main_fsm    <=  s_idle;
                    DONE        <= '1';
                end if;

            when s_ai_game_map =>

                if game_map_done='1' then 
                    main_fsm    <=  s_idle;
                    DONE        <= '1';
                end if;                
                                        
        end case;
        
    end if;
end process;

---------------------------------------------------------------------------
-- Game Map FSM
---------------------------------------------------------------------------    

process (CLK, RST_N)
begin
	if RST_N = '0' then
		
        game_map_fsm    <=  s_idle;
        game_map_add    <= 0;
        game_map_done   <= '0';

    elsif rising_edge(CLK) then

        game_map_done   <= '0';

        case game_map_fsm is 

            when s_idle =>

                if (C_SIM = 1 or VIDEO_SYNC.VSYNC_TRIG = '1') and (main_fsm = s_game_map or main_fsm = s_ai_game_map) then
                    game_map_fsm    <=  s_read_1;
                end if;
            
            when s_read_1 =>
                game_map_fsm    <=  s_read_2;

            when s_read_2 =>
                game_map_fsm    <=  s_write;

            when s_write =>
                                 
                if game_map_add < C_TILE_COUNT-1 then 
                    game_map_add    <= game_map_add + 1;
                    game_map_fsm    <=  s_read_1;
                else
                    game_map_add    <= 0;
                    game_map_fsm    <=  s_done;
                    game_map_done   <= '1';

                end if;            

            when s_done =>
                
                game_map_fsm    <=  s_idle;
                    
        end case;
        
    end if;
end process;

---------------------------------------------------------------------------
-- Splash FSM
---------------------------------------------------------------------------    


process (CLK, RST_N)
begin
	if RST_N = '0' then
		
        splash_fsm      <=  s_idle;
        next_state      <= s_idle;
        splash_rom_add  <= 0;
        splash_ram_add  <= 0;
        data_counter    <= 0;
        delay_section    <= 0;
        frame_counter    <= 0;
        splash_done     <= '0';


    elsif rising_edge(CLK) then

        splash_done   <= '0';

        case splash_fsm is 

            when s_idle =>

                if main_fsm = s_splash then
                    splash_fsm    <=  s_clear_screen;
                end if;   
                delay_section   <= 0;    
                splash_ram_add  <= 0;     
            
            when s_clear_screen =>

                if splash_ram_add < C_TILE_COUNT-1 then 
                    splash_ram_add    <= splash_ram_add + 1;
                else
                    splash_ram_add  <= 0;
                    splash_fsm      <=  s_wait;
                    splash_rom_add  <= C_SPALSH_OFFSET;  
                    next_state      <= s_read_1;
                end if;        


            when s_read_1 =>
                splash_fsm    <=  s_read_2;

            when s_read_2 =>
                if next_state = s_read_1 then
                    splash_fsm      <=  s_add;                      
                else
                    splash_fsm      <=  s_write;
                end if;

            when s_add =>

                splash_fsm      <=  s_read_1;
                splash_ram_add  <=  to_integer(unsigned(splash_rom_data));  
                splash_rom_add  <=  data_counter;  
                next_state      <= s_write; 

            when s_write =>
                                
                if data_counter < C_SPALSH_OFFSET-1 then 
                    data_counter    <= data_counter + 1;
                    splash_rom_add  <=  C_SPALSH_OFFSET + data_counter + 1;
                    splash_fsm      <=  s_wait;
                    next_state      <=  s_read_1;
                else
                    data_counter    <= 0;
                    splash_fsm      <=  s_done;
                    splash_done     <= '1';

                end if;   

            when s_wait =>

                if VIDEO_SYNC.VSYNC_TRIG = '1' or fast_splash='1' then 

                                    
                    if frame_counter < C_DEALY_FRAMES(delay_section)-1 then
                        frame_counter   <= frame_counter + 1;
                    else
                        frame_counter   <=  0;
                        splash_fsm      <=  s_read_1;

                        if data_counter = C_DEALY_COUNT(delay_section)-1 then

                            if delay_section < C_DEALY_SECTIONS-1 then
                                delay_section <= delay_section + 1;
                            end if;
    
                        end if;

                    end if;
                end if;
                        


            when s_done =>
                
                splash_fsm    <=  s_idle;                
                          
                    
        end case;
        
    end if;
end process;

---------------------------------------------------------------------------
-- ROM
---------------------------------------------------------------------------

map_rom_u : screen_map_rom 
generic map
(
    init_file	=> "screen_map_rom.mif" 
)
port map
(   
    address		=>  std_logic_vector(to_unsigned(game_map_add, 11)),  
    clock		=>  CLK,       
    q			=>  map_rom_data   
);

ai_map_rom_u : screen_map_rom 
generic map
(
    init_file	=> "ai_screen_map_rom.mif" 
)
port map
(   
    address		=>  std_logic_vector(to_unsigned(game_map_add, 11)),  
    clock		=>  CLK,       
    q			=>  ai_map_rom_data   
);

splash_rom_u : splash_rom 
port map
(   
    address		=>  std_logic_vector(to_unsigned(splash_rom_add, 10)),  
    clock		=>  CLK,       
    q			=>  splash_rom_data  
);

splash_data <= C_BLACK_TILE when main_fsm=s_splash and splash_fsm=s_clear_screen else splash_rom_data;


selected_rom_data <= splash_data when main_fsm=s_splash else 
                     map_rom_data when main_fsm=s_game_map else
                     ai_map_rom_data     ;

--rom_word <= selected_rom_data((word_counter+1)*16-1 downto word_counter*16);

selected_data <= "00000" & RAND_VECT(1 downto 0) & "000000000"  when (main_fsm=s_ai_game_map or main_fsm=s_game_map) and selected_rom_data(15 downto 14)="00"  and selected_rom_data(12)='1' else 
                selected_rom_data; 

end init_mem_arch;
 
	
	
	
	
	
