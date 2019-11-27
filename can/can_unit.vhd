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

entity can_unit is
	Generic (
				prescaler_g : unsigned (7 downto 0) := x"14";
				resync_jw_g : unsigned (2 downto 0) := "011";
				phase_seg1_g : unsigned (3 downto 0) := x"3";
				phase_seg2_g : unsigned (3 downto 0) := x"3";
				propagation_seg_g : unsigned (3 downto 0) := x"3"
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
end can_unit;

architecture Structural of can_unit is

	component can_signal_unit 
		Generic (
				prescaler_g : unsigned (7 downto 0) := x"14";
				resync_jw_g : unsigned (2 downto 0) := "011";
				phase_seg1_g : unsigned (3 downto 0) := x"3";
				phase_seg2_g : unsigned (3 downto 0) := x"3";
				propagation_seg_g : unsigned (3 downto 0) := x"3"
			);
		Port ( 
				clk_100	: in std_logic;
				can_clk_i : in std_logic;
				reset_n : in std_logic;
				
				rx_i	: in std_logic;
				sync_seg_i : in std_logic;
				propagation_seg_i : in std_logic;
				phase_seg1_i : in std_logic;
				phase_seg2_i : in std_logic;
				sample_point_i : in std_logic;
				
				sof_o	: out std_logic;
				eof_o	: out std_logic;
				early_edge_o : out std_logic;
				late_edge_o : out std_logic;
				test_data : out std_logic_vector (83 downto 0);
				id_o : out std_logic_vector (28 downto 0);
				dlc_o : out std_logic_vector (3 downto 0);
				data_o : out std_logic_vector(63 downto 0);
				can_active_o : out std_logic;
				data_valid_o : out std_logic
			);
	end component;
	
	component can_clk_prescaler
		Generic (
					prescaler_g : unsigned (7 downto 0) := x"14";
				resync_jw_g : unsigned (2 downto 0) := "011";
				phase_seg1_g : unsigned (3 downto 0) := x"3";
				phase_seg2_g : unsigned (3 downto 0) := x"3";
				propagation_seg_g : unsigned (3 downto 0) := x"3"
				);
		Port ( 
				clk_100	: in std_logic;
				reset_n : in std_logic;
				sof_i : in std_logic;
				eof_i : in std_logic;
				late_edge_i : in std_logic;
				early_edge_i : in std_logic; 
				
				can_clk_o : out std_logic;
				sync_seg_o : out std_logic; 
				propagation_seg_o : out std_logic;
				phase_seg1_o : out std_logic;
				phase_seg2_o : out std_logic;
				sample_point_o : out std_logic
			);
	end component;
	
	signal s_can_clk : std_logic := '0';
	signal s_sync_seg : std_logic := '0';
	signal s_propagation_seg : std_logic := '0';
	signal s_phase_seg1 : std_logic := '0';
	signal s_phase_seg2 : std_logic := '0';
	signal s_sample_point : std_logic := '0';
	signal s_sof : std_logic := '0';
	signal s_eof : std_logic := '0';
	signal s_late_edge : std_logic := '0';
	signal s_early_edge : std_logic := '0';	
	
begin
	
	i_can_signal_unit : can_signal_unit
		
		generic map (
			prescaler_g 		=> prescaler_g,
			resync_jw_g			=> resync_jw_g,
			phase_seg1_g		=> phase_seg1_g,
			phase_seg2_g		=> phase_seg2_g,
			propagation_seg_g	=> propagation_seg_g		
		)
		port map (
			clk_100				=> clk_100,
			can_clk_i			=> s_can_clk,
			reset_n				=> reset_n,
			rx_i				=> rx_i,
			sync_seg_i			=> s_sync_seg,
			propagation_seg_i	=> s_propagation_seg,
			phase_seg1_i		=> s_phase_seg1,
			phase_seg2_i		=> s_phase_seg2,
			sample_point_i		=> s_sample_point,
			sof_o				=> s_sof,
			eof_o				=> s_eof,
			early_edge_o		=> s_early_edge,
			late_edge_o			=> s_late_edge,
			test_data			=> open,
			id_o				=> id_o,
			dlc_o				=> dlc_o,
			data_o				=> data_o,
			can_active_o		=> can_active_o,
			data_valid_o		=> valid_o
		);
		
	i_can_clk_prescaler : can_clk_prescaler
		
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
			sof_i				=> s_sof,
			eof_i				=> s_eof,
			late_edge_i 		=> s_late_edge,
			early_edge_i		=> s_early_edge,
			can_clk_o			=> s_can_clk,
			sync_seg_o			=> s_sync_seg, 
			propagation_seg_o	=> s_propagation_seg,
			phase_seg1_o		=> s_phase_seg1,
			phase_seg2_o		=> s_phase_seg2,
			sample_point_o		=> s_sample_point
		);
	
end Structural;