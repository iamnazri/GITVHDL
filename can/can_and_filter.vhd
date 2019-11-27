----------------------------------------------------------------------------------
-- Company: AVI Systems GmbH
-- Engineer: René Ulmer <rene.ulmer@avi-systems.eu>
-- 
-- Create Date: 13.11.2019 
-- Design Name: can unit
-- Module Name: can unit - Behavioral
-- Project Name: CanController
-- Target Devices: 
-- Tool Versions: 
-- Description: consits of can_signal_unit + can_clk_prescaler
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity can_and_filter is
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
end can_and_filter;

architecture Structural of can_and_filter is

	component can_unit
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
				
				id_o : out std_logic_vector (28 downto 0);
				dlc_o : out std_logic_vector (3 downto 0);
				data_o : out std_logic_vector(63 downto 0);
				valid_o : out std_logic;
				can_active_o : out std_logic
		);
	end component;
	
	component can_filter
		Port ( 
			clk_100	: in std_logic;
			reset_n : in std_logic;
			
			id_i : in std_logic_vector (28 downto 0);
			dlc_i : in std_logic_vector (3 downto 0);
			data_i : in std_logic_vector(63 downto 0);
			valid_i : in std_logic;
			
			package_o : out std_logic_vector (127 downto 0);
			valid_o : out std_logic			
		);
	end component;
	
	
	signal s_id : std_logic_vector (28 downto 0) := (others => '0');
	signal s_dlc : std_logic_vector (3 downto 0) := (others => '0');
	signal s_data : std_logic_vector (63 downto 0) := (others => '0');
	signal s_valid_intern : std_logic := '0';
	signal s_package_o : std_logic_vector (127 downto 0) := (others => '0');
	signal s_valid_o : std_logic := '0';
	signal s_can_active_o : std_logic := '0';
	
	
begin
	
	package_o <= s_package_o;
	valid_o <= s_valid_o;
	can_active_o <= s_can_active_o;
	
	i_can_unit : can_unit
		generic map (
			prescaler_g 		=> prescaler_g,
			resync_jw_g			=> resync_jw_g,
			phase_seg1_g		=> phase_seg1_g,
			phase_seg2_g		=> phase_seg2_g,
			propagation_seg_g	=> propagation_seg_g		
		)
		port map (
			clk_100				=> clk_100,
			reset_n				=> reset_n,
			rx_i				=> rx_i,
		
			id_o				=> s_id,
			dlc_o				=> s_dlc,
			data_o				=> s_data,
			valid_o				=> s_valid_intern,
			can_active_o		=> s_can_active_o
		);
		
	i_can_filter : can_filter	
		port map (
			clk_100				=> clk_100,
			reset_n				=> reset_n,
			id_i 				=> s_id,
			dlc_i				=> s_dlc,
			data_i				=> s_data,
			valid_i				=> s_valid_intern,
			package_o			=> s_package_o,
			valid_o				=> s_valid_o
		);
		

end Structural;