
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity can_emv_test is
	Generic (
				RATE				: natural := 20;
				prescaler_g 		: unsigned (7 downto 0) := x"14";
				resync_jw_g 		: unsigned (2 downto 0) := "011";
				phase_seg1_g		: unsigned (3 downto 0) := x"3";
				phase_seg2_g		: unsigned (3 downto 0) := x"3";
				propagation_seg_g 	: unsigned (3 downto 0) := x"3"
				--prescaler_g 		: unsigned (7 downto 0) := x"0a";
				--resync_jw_g 		: unsigned (2 downto 0) := "010";
				--phase_seg1_g 		: unsigned (3 downto 0) := x"2";
				--phase_seg2_g 		: unsigned (3 downto 0) := x"2";
				--propagation_seg_g : unsigned (3 downto 0) := x"5"
			);
    Port ( 
			sys_clk					: in std_logic;
			sys_rst 				: in std_logic;
			rx_i					: in std_logic_vector (1 downto 0);
			
			gpo						: out std_logic_vector (1 downto 0) := "11"		-- leds off at start
	);
end can_emv_test;

architecture Behavioral of can_emv_test is

	component can_and_filter
	Generic (
			prescaler_g : unsigned (7 downto 0) := x"14";
			resync_jw_g : unsigned (2 downto 0) := "011";
			phase_seg1_g : unsigned (3 downto 0) := x"3";
			phase_seg2_g : unsigned (3 downto 0) := x"3";
			propagation_seg_g : unsigned (3 downto 0) := x"3"
			--prescaler_g : unsigned (7 downto 0) := x"0a";
			--resync_jw_g : unsigned (2 downto 0) := "010";
			--phase_seg1_g : unsigned (3 downto 0) := x"2";
			--phase_seg2_g : unsigned (3 downto 0) := x"2";
			--propagation_seg_g : unsigned (3 downto 0) := x"5"
			);
    Port ( 
			clk_100	: in std_logic;
			reset_n : in std_logic;
			rx_i	: in std_logic;
			
			package_o : out std_logic_vector (127 downto 0);
			valid_o : out std_logic;
			can_active_o : out std_logic
			
		);
	end component;
	
	component ila_2
		Port (
				clk : in std_logic;
				probe0 : in std_logic_vector (127 downto 0);
				probe1 : in std_logic_vector (0 downto 0);
				probe2 : in std_logic_vector (7 downto 0);
				probe3 : in std_logic_vector (0 downto 0);
				probe4 : in std_logic_vector (15 downto 0);
				probe5 : in std_logic_vector (0 downto 0)
			);
	end component;

	signal reg_package_of_interest	: std_logic_vector (127 downto 0);
	signal reg_valid_package		: std_logic;
	signal reg_can_active			: std_logic;
	signal reg_package_of_interest2	: std_logic_vector (127 downto 0);
	signal reg_valid_package2		: std_logic;
	signal reg_can_active2			: std_logic;

	signal reg_led_state			: std_logic;
	signal reg_led_state2			: std_logic;

	signal package_count			: integer;
	signal package_count2			: integer;
	
	signal package_count_ila 		: std_logic_vector (7 downto 0);
	signal package_count_ila2 		: std_logic_vector (7 downto 0);
	

begin



process(sys_clk)				-- can0
begin
	if rising_edge(sys_clk) then
		if (sys_rst = '0') then
			--TODO
			reg_led_state <= '0';
			package_count <= 0;
		else
			if (reg_valid_package = '1') then
				
				if (reg_package_of_interest(91 downto 76) = x"fe6c") then
					package_count <= package_count + 1;
					if (package_count = RATE) then
						 if (reg_led_state = '0') then
							gpo(0) <= '0';	-- 0 left
							reg_led_state <= '1';
						 else
							gpo(0) <= '1';	-- 0 left
							reg_led_state <= '0';
						 end if;
						 package_count <= 0;
					end if;
				end if;
				
			end if;
			
		end if;
	end if;
end process;

process(sys_clk)				-- can1		
begin
	if rising_edge(sys_clk) then
		if (sys_rst = '0') then
			--TODO
			reg_led_state2 <= '0';
			package_count2 <= 0;	
		else
			if (reg_valid_package2 = '1') then
				
				if (reg_package_of_interest2(91 downto 76) = x"fe6c") then
					package_count2 <= package_count2 + 1;
					if (package_count2 = RATE) then
						 if (reg_led_state2 = '0') then
							gpo(1) <= '0';	-- 0 right
							reg_led_state2 <= '1';
						 else
							gpo(1) <= '1';	-- 0 right
							reg_led_state2 <= '0';
						 end if;
						 package_count2 <= 0;
					end if;
				end if;
				
			end if;
			
		end if;
	end if;
end process;

package_count_ila <= std_logic_vector(to_unsigned(package_count, 8));
package_count_ila2 <= std_logic_vector(to_unsigned(package_count2, 8));

	i_can_and_filter_0 : can_and_filter
	generic map (
		prescaler_g 		=> prescaler_g,
		resync_jw_g 		=> resync_jw_g,
		phase_seg1_g 		=> phase_seg1_g,
		phase_seg2_g 		=> phase_seg2_g,
		propagation_seg_g 	=> propagation_seg_g
		
	)
	port map (
			clk_100			=> sys_clk,
			reset_n 		=> sys_rst,
			rx_i			=> rx_i(0),
			
			package_o 		=> reg_package_of_interest,
			valid_o 		=> reg_valid_package,
			can_active_o 	=> reg_can_active
	);
	
	i_can_and_filter_1 : can_and_filter
	generic map (
		prescaler_g 		=> prescaler_g,
		resync_jw_g 		=> resync_jw_g,
		phase_seg1_g 		=> phase_seg1_g,
		phase_seg2_g 		=> phase_seg2_g,
		propagation_seg_g 	=> propagation_seg_g
		
	)
	port map (
			clk_100			=> sys_clk,
			reset_n 		=> sys_rst,
			rx_i			=> rx_i(1),
			
			package_o 		=> reg_package_of_interest2,
			valid_o 		=> reg_valid_package2,
			can_active_o 	=> reg_can_active2
	);
	
--	i_ila0 : ila_2
--	port map (
--		clk 	=> sys_clk,
--		probe0 	=> reg_package_of_interest,
--		probe1(0) 	=> reg_valid_package,
--		probe2 	=> package_count_ila,
--		probe3(0)	=> reg_led_state,
--		probe4	=> reg_package_of_interest(91 downto 76),
--		probe5(0)	=>	rx_i(0)
--	);
--	i_ila1 : ila_2
--	port map (
--		clk 	=> sys_clk,
--		probe0 	=> reg_package_of_interest2,
--		probe1(0) 	=> reg_valid_package2,
--		probe2 	=> package_count_ila2,
--		probe3(0)	=> reg_led_state2,
--		probe4	=> reg_package_of_interest2(91 downto 76),
--		probe5(0)	=>	rx_i(1)
--	);

end Behavioral;
