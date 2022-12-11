library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library WORK;
use WORK.top_pack.all;


entity user_interface is
port
(	
	CLK	    	: in std_logic ;			
    RST_N 		: in std_logic ;

    SW			: in std_logic_vector(9 downto 0) ;
	BUTTON		: in std_logic_vector(1 downto 0) ;	

	MILI_SEC_TIC	: in std_logic;

    USER_CMD    : out t_usr_cmd_rec

);
end user_interface;

architecture user_interface_arch of user_interface is


constant C_USER_SW_F    : integer := 0;    
constant C_USER_BTN_R   : integer := 0;    
constant C_USER_BTN_L   : integer := 1;    

constant C_PRESSED      : std_logic := '0' ;
constant C_LEFT         : std_logic := '1' ;


---------------------------------------------------------------------------
-- Components
---------------------------------------------------------------------------

component periphery_control is
port (
	
	clk             : in std_logic;                           -- input	        
	A               : out std_logic;         -- output	
	B               : out std_logic;        -- output	
	Select_out      : out std_logic;           -- output	
	Start           : out std_logic;            -- output	
	Right           : out std_logic;           -- output	
	Left            : out std_logic;           -- output	
	Up              : out std_logic;        -- output	
	Down            : out std_logic;           -- output	
	Wheel           : out std_logic_vector(11 downto 0)        -- output	
	);
end component;

---------------------------------------------------------------------------
-- Signals
---------------------------------------------------------------------------

signal time_counter     :	integer range 0 to C_USER_SAMPLE_T-1;
signal sample_strb      :   std_logic;
signal buttons_vec      :	std_logic_vector(0 to 7);
signal buttons_trig     :	std_logic_vector(0 to 7);

begin
	
---------------------------------------------------------------------------
-- Time;
---------------------------------------------------------------------------

process (CLK, RST_N)
begin
	if RST_N = '0' then

		time_counter    <= 0;
        sample_strb     <= '0';

	elsif rising_edge(CLK) then

        sample_strb     <= '0';

        if MILI_SEC_TIC = '1' then 
        
            if time_counter < C_USER_SAMPLE_T-1 then
            
                time_counter <= time_counter + 1;
            else
                time_counter    <= 0;
                sample_strb     <= '1';
            end if;
	    end if;
	end if;
end process;

gen_u : if C_SIM = 0 generate

    pc_u : periphery_control 
    port map
    (
            
        clk             => CLK, --: in std_logic;                           -- input	        
        A               => buttons_vec(0), --: out std_logic;         -- output	
        B               => buttons_vec(1) , --: out std_logic;        -- output	
        Select_out      => buttons_vec(2) , --: out std_logic;           -- output	
        Start           => buttons_vec(3) , --: out std_logic;            -- output	
        Right           => buttons_vec(4) , --: out std_logic;           -- output	
        Left            => buttons_vec(5) , --: out std_logic;           -- output	
        Up              => buttons_vec(6) , --: out std_logic;        -- output	
        Down            => buttons_vec(7) , --: out std_logic;           -- output	
        Wheel           => open  --: out std_logic_vector(11 downto 0)        -- output	
    );
end generate;
   
---------------------------------------------------------------------------
-- Sample the inputs
---------------------------------------------------------------------------

g_button : for i in 0 to 7 generate

    button_u : entity work.user_button 
    port map
    (	
        CLK	    	=> CLK, --: in std_logic ;			
        RST_N 		=> RST_N, --: in std_logic ;

        TIME_TIC	=> sample_strb, --: in std_logic;
        BUTTON	    => buttons_vec(i), --: in std_logic;

        TRIG        => buttons_trig(i) --: out std_logic

    );
end generate;

---------------------------------------------------------------------------
-- Command
---------------------------------------------------------------------------

process (RST_N, CLK) 
begin
    if RST_N = '0' then 
        
        USER_CMD <= ('0' , cmd_down);

    elsif rising_edge(CLK) then

        USER_CMD.STRB <= '0';

        case buttons_trig is 

            when "10000000" => -- A
                USER_CMD <= ('1' , cmd_cw);
            when "01000000" => -- B
                USER_CMD <= ('1' , cmd_drop); 
            when "00100000" => -- Select_out 
                USER_CMD <= ('1' , cmd_select);
            when "00010000" => -- Start      
                USER_CMD <= ('1' , cmd_start);
            when "00001000" => -- Right      
                USER_CMD <= ('1' , cmd_right);
            when "00000100" => -- Left      
                USER_CMD <= ('1' , cmd_left); 
            when "00000010" => -- Up         
            when "00000001" => -- Down   
                USER_CMD <= ('1' , cmd_down); 
            when others =>   
           
        end case;
        
    end if;
end process;


end user_interface_arch;
 
	
	
	
	
	
