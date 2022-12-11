library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_signed.all;
use IEEE.std_logic_arith.all;

library work;

library WORK;
use WORK.top_pack.all;
use WORK.brick_position_pack.all;

entity AI_tb is

end AI_tb;
	

architecture TB of AI_tb is

	type state_type is (s_init, s_decode, s_alu, s_mem,s_mem_1);

	type count_array is array (state_type) of integer;

	-- cur_brick  = 1 # random.randint(1, 7)
	-- cur_rot    = 2 # random.randint(0, 3)
	-- next_brick = [4,2,6,1,7,3,7,5,4,3] # random.randint(1, 7)
	-- next_rot   = [0,1,2,3,2,3,2,0,1,0]  # random.randint(0, 3)

	constant next_index_arr 	: t_int_arr (0 to 10) := (1,4,2,6,1,7,3,7,5,4,3);
	constant next_rot_arr 		: t_int_arr (0 to 10) := (2,0,1,2,3,2,3,2,0,1,0);

	signal clk_50		:	std_logic;
	signal reset_n		:	std_logic:= '0';
	-- signal btn_0		:	std_logic:= '1';
	-- signal sw			:	std_logic_vector	(9 downto 0);
	-- signal button		:	std_logic_vector	(1 downto 0);
	--signal test  		:	std_logic_vector	(11 downto 0);

	signal pclk		:	std_logic;

	-- signal lcd_d_c				:	std_logic;
	-- signal sniffer_strb			:	std_logic;
	-- signal sniffer_in			:	std_logic_vector	(8 downto 0);
	-- signal lcd_db				:	std_logic_vector	(7 downto 0);

	signal update				:	std_logic;
	signal ai_tic				:	std_logic;
	signal drop_tic				:	std_logic;
	signal next_brick       :   t_brick_info;
	signal current_brick    :   t_brick_info;

	signal update_counter 		: integer;
	signal drop_counter 		: integer;
	signal ai_counter 		: integer;
	signal next_ind 		: integer;
	signal usr_cmd			: t_usr_cmd_rec;


	
	
begin

dut_u: entity work.AI_top
port map
(	
	CLK	    	=> clk_50, --: in std_logic ;			
	RST_N 		=> reset_n, --: in std_logic ;

	AI_TIC	    => ai_tic,
    DROP_TIC	=> drop_tic,
	CLEAR		=> '0',


	UPDATE				=> update,
	NEXT_BRICK       	=> next_brick,
	CURRENT_BRICK    	=> current_brick,

	USER_CMD    => usr_cmd

);




	sim_proc: process
	begin	
		clk_50	<=	'0';
		wait for 10 ns;
		clk_50	<=	'1';
		wait for 10 ns;
	end process;
	
	reset_n	<=	'1' after 495 ns;

	--update	<= '0' after 1 ns , '1' after 100 us , '0' after 105 us;



	process (pclk, reset_n)
	begin
		if reset_n = '0' then
			
			update_counter    <= 1024*12-10;
			next_ind		<= 0;
			update			<= '0';

			current_brick.BTYPE	<= 1;
			current_brick.ROT	<= 2;
			current_brick.POS	<=  C_INIT_POS_ARR(current_brick.BTYPE)(current_brick.ROT);
		
			next_brick.BTYPE	<= next_index_arr(0);
			next_brick.ROT		<= next_rot_arr(0);
			next_brick.POS		<=  C_INIT_POS_ARR(next_index_arr(0))(next_rot_arr(0));
		
	
		elsif rising_edge(pclk) then

			update			<= '0';

			if update_counter < 1024*42-1 then

				update_counter <= update_counter + 1;
			else

				update_counter	<= 0;
				update			<= '1';

				if next_ind < 10 then 
					next_ind <= next_ind + 1;

					next_brick.BTYPE	<= next_index_arr(next_ind + 1);
					next_brick.ROT		<= next_rot_arr(next_ind + 1);
					next_brick.POS		<=  C_INIT_POS_ARR(next_index_arr(next_ind + 1))(next_rot_arr(next_ind + 1));

					current_brick.BTYPE	<= next_brick.BTYPE;
					current_brick.ROT	<= next_brick.ROT;
					current_brick.POS	<= next_brick.POS;
							
				end if;
					
			end if;

		end if;
	end process;


	process (pclk, reset_n)
	begin
		if reset_n = '0' then
			
			drop_counter    <= 0;
			ai_counter    	<= 0;
			ai_tic			<= '0';
			drop_tic		<= '0';
			
		elsif rising_edge(pclk) then

			ai_tic			<= '0';
			drop_tic		<= '0';

			if drop_counter < 1024*3-1 then

				drop_counter <= drop_counter + 1;
			else
				drop_counter	<= 0;
				drop_tic		<= '1';
			end if;

			if ai_counter < 1024-1 then

				ai_counter <= ai_counter + 1;
			else
				ai_counter	<= 0;
				ai_tic		<= '1';
			end if;

		end if;
	end process;

	--test <= to_bcd(500);
	

	-- f_click		<=	<< signal .AI_tb.dut_u.ui_u.f_click : std_logic >>;	

 	pclk			<=	<< signal .AI_tb.dut_u.clk : std_logic >>;	
 	-- lcd_clk		<=	<< signal .AI_tb.dut_u.disp_u.clk : std_logic >>;	
 	-- lcd_d_c		<=	<< signal .AI_tb.dut_u.disp_u.lcd_d_c : std_logic >>;	
 	-- lcd_db		<=	<< signal .AI_tb.dut_u.disp_u.lcd_db : std_logic_vector	(7 downto 0) >>;	
-- 	cpu_addr	<=	<< signal .AI_tb.dut_u.cpu_inst.data_addr : std_logic_vector	(9 downto 0) >>;	
-- 	cpu_state <=  << signal .AI_tb.dut_u.cpu_inst.main_fsm : state_type >>;
	
-- 	org_cpu_out_mem	<=	<< signal .AI_tb.dut_u.cpu_org_inst.out_m : std_logic_vector	(15 downto 0) >>;	
-- 	org_cpu_addr	<=	<< signal .AI_tb.dut_u.cpu_org_inst.data_addr : std_logic_vector	(9 downto 0) >>;	

 	-- sniffer_strb		<=	<< signal .AI_tb.dut_u.disp_u.lcd_wr : std_logic >>;
 	-- sniffer_in			<=	lcd_d_c & lcd_db ;

-- 	org_mem_strb		<=	<< signal .AI_tb.dut_u.cpu_org_inst.WRITE_M : std_logic >>;	
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
 