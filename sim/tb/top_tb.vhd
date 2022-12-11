library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_signed.all;
use IEEE.std_logic_arith.all;

library work;

library WORK;
use WORK.top_pack.all;

entity top_tb is

end top_tb;
	

architecture TB of top_tb is

  type state_type is (s_init, s_decode, s_alu, s_mem,s_mem_1);

  type count_array is array (state_type) of integer;

	signal clk_50		:	std_logic;
	signal reset_n		:	std_logic:= '0';
	signal btn_0		:	std_logic:= '1';
	signal sw			:	std_logic_vector	(9 downto 0);
	signal button		:	std_logic_vector	(1 downto 0);
	--signal test  		:	std_logic_vector	(11 downto 0);
	
	signal pclk		:	std_logic;
	-- --signal cpu_we		:	std_logic;
	-- signal cpu_out_mem	:	std_logic_vector	(15 downto 0);
	-- --signal cpu_in_mem	:	std_logic_vector	(15 downto 0);
	-- signal cpu_addr		:	std_logic_vector	(9 downto 0);
	-- --signal cpu_pc		:	std_logic_vector	(14 downto 0);
  	-- signal cpu_state  : state_type;
	
	-- --signal sniffer_in	:	std_logic_vector	(16*4-1 downto 0);
	
	
	-- --signal org_cpu_strb		:	std_logic;
	-- --signal org_cpu_we		:	std_logic;
	-- --signal org_cpu_in_mem	:	std_logic_vector	(15 downto 0);
	-- signal org_cpu_out_mem	:	std_logic_vector	(15 downto 0);
	-- signal org_cpu_addr		:	std_logic_vector	(9 downto 0);
	-- --signal org_cpu_pc		:	std_logic_vector	(14downto 0);
	
	-- --signal org_sniffer_in	:	std_logic_vector	(16*4-1 downto 0);
	
	signal buttons_vec				:	std_logic_vector	(0 to 7);

	--signal f_click				:	std_logic;

	
	-- signal org_mem_strb		:	std_logic;
	-- signal org_mem_sniffer_in	:	std_logic_vector	(16*2-1 downto 0);
	
	-- signal state_counters : count_array;
	
begin

sw(8 downto 0)	<=	(others => '0');

button(0)	<=	btn_0;
button(1)	<=	'1';

sw(9)		<= reset_n;

dut_u: entity work.top 
	port map
	(
        clk_50	=> '0',
        SW		=> sw,
        BUTTON  => button,
        HEX0    => OPEN,
        HEX1    => OPEN,
        HEX2    => OPEN,
        LED     => OPEN,
        RED     => OPEN,
        GREEN   => OPEN,
        BLUE    => OPEN,
        h_sync  => OPEN,
        v_sync  => OPEN
    );


	sim_proc: process
	begin	
		pclk	<=	'0';
		wait for 20 ns;
		pclk	<=	'1';
		wait for 20 ns;
	end process;
	
	reset_n	<=	'1' after 495 ns;

	buttons_vec(2)	<=  '1' after 1 ns , '0' after 1000 us , '1' after 1005 us;
	buttons_vec(0)	<=  '1';
	--buttons_vec(1)	<=  '1';-- Drop
	buttons_vec(3)	<=  '1';
	buttons_vec(4)	<=  '1';
	buttons_vec(5)	<=  '1';
	buttons_vec(6)	<=  '1';
	buttons_vec(7)	<=  '1';

	drop_proc: process
	begin	
		buttons_vec(1)	<=	'1';
		wait for 20 ms;
		buttons_vec(1)	<= '0';
		wait for 100 us;
	end process;

	--test <= to_bcd(500);
	

	--f_click		<=	<< signal .top_tb.dut_u.ui_u.f_click : std_logic >>;	

	<< signal .top_tb.dut_u.prst_n : std_logic >> <= reset_n;
 	<< signal .top_tb.dut_u.pclk : std_logic >> <= pclk;
 	<< signal .top_tb.dut_u.ui_u.buttons_vec : std_logic_vector (0 to 7) >> <= buttons_vec;

 	--lcd_db		<=	<< signal .top_tb.dut_u.disp_u.lcd_db : std_logic_vector	(7 downto 0) >>;	
-- 	cpu_addr	<=	<< signal .top_tb.dut_u.cpu_inst.data_addr : std_logic_vector	(9 downto 0) >>;	
-- 	cpu_state <=  << signal .top_tb.dut_u.cpu_inst.main_fsm : state_type >>;
	
-- 	org_cpu_out_mem	<=	<< signal .top_tb.dut_u.cpu_org_inst.out_m : std_logic_vector	(15 downto 0) >>;	
-- 	org_cpu_addr	<=	<< signal .top_tb.dut_u.cpu_org_inst.data_addr : std_logic_vector	(9 downto 0) >>;	

 	-- sniffer_in			<=	lcd_d_c & lcd_db ;

-- 	org_mem_strb		<=	<< signal .top_tb.dut_u.cpu_org_inst.WRITE_M : std_logic >>;	
-- 	org_mem_sniffer_in	<=	org_cpu_out_mem & "000000" & org_cpu_addr ;


-- count_proc: process(cpu_clk,reset_n)
-- 	begin	
-- 	if reset_n = '0' then
		
-- 		state_counters	<=	(0,0,0,0,0);		
		
		
-- 	elsif rising_edge(cpu_clk) then
	
--     state_counters(cpu_state) <=  state_counters(cpu_state) + 1;
    
-- 	end if;
	
-- 	end process;
-------
-- snf_u: entity work.sniffer 
  
--   generic map
--   (
--     G_FILE_PATH             => "./",
--     G_DAT_FILE_NAME         => "lcd_out.txt",
--     G_PRINT_HEX             => true,                                    
--     G_DAT_NUM_CHNLS   		=> 1, 
--     G_DAT_CHNL_WDTH   		=> 9
--     )
--   port map
--   (

--     MODULE_CLK 		=> sniffer_strb, --lcd_clk,
--     DAT_DAT 		=> sniffer_in,
--     DAT_STB 		=> '1', --sniffer_strb,
--     DAT_END 		=> '0',
--     DAT_ACK 		=> '1'
--     );   


-- org_snf_mem_u: entity work.sniffer 
  
--   generic map
--   (
--     G_FILE_PATH             => "./",
--     G_DAT_FILE_NAME         => "out_mem_org.txt",
--     G_PRINT_HEX             => true,                                    
--     G_DAT_NUM_CHNLS   		=> 2, 
--     G_DAT_CHNL_WDTH   		=> 16
--     )
--   port map
--   (

--     MODULE_CLK 		=> cpu_clk,
--     DAT_DAT 		=> org_mem_sniffer_in,
--     DAT_STB 		=> org_mem_strb,
--     DAT_END 		=> '0',
--     DAT_ACK 		=> '1'
--     ); 
	
end TB;
 