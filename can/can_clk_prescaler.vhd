----------------------------------------------------------------------------------
-- Company: AVI Systems GmbH
-- Engineer: René Ulmer <rene.ulmer@avi-systems.eu>
-- 
-- Create Date: 05.11.2019 
-- Design Name: can_clk_prescaler
-- Module Name: can_clk_prescaler - Behavioral
-- Project Name: CanController
-- Target Devices: 
-- Tool Versions: 
-- Description: 
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

entity can_clk_prescaler is

	Generic (
				prescaler_g : unsigned (7 downto 0) := x"01";
				resync_jw_g : unsigned (2 downto 0) := "100";
				phase_seg1_g : unsigned (3 downto 0) := x"4";
				phase_seg2_g : unsigned (3 downto 0) := x"4";
				propagation_seg_g : unsigned (3 downto 0) := x"4"
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
end can_clk_prescaler;

architecture Behavioral of can_clk_prescaler is
	signal s_clk_cnt : unsigned (7 downto 0) := (others =>'0');
	signal s_prop_delay_cnt : unsigned (3 downto 0) := (others => '0');
	signal s_can_clk : std_logic := '0';
	signal s_sync_seq : std_logic := '0';
	signal s_prop_delay : std_logic := '0';
	signal s_phase_seg1 : std_logic := '0';
	signal s_phase_seg1_cnt : unsigned (3 downto 0) := (others => '0');
	signal s_phase_seg2 : std_logic := '0';
	signal s_phase_seg2_cnt : unsigned (3 downto 0) := (others => '0');
	signal s_sample_point : std_logic := '0';
	signal s_sof : std_logic := '0';
	signal s_eof : std_logic := '0';
	signal s_late_edge : std_logic := '0';
	signal s_early_edge : std_logic := '0';
	signal s_late_cnt : unsigned (3 downto 0) := (others => '0');
	

begin

-- Prescaler Process
process(clk_100, reset_n)
begin
	if reset_n = '0' then
		s_can_clk <= '0';
		s_clk_cnt <= (others => '0');
	elsif rising_edge (clk_100) then 
		s_clk_cnt <= s_clk_cnt + 1;
		if s_clk_cnt >= (prescaler_g) then
			s_can_clk <= '1';
			s_clk_cnt <= "00000001";
		else
			s_can_clk <= '0';
		end if;
		
	end if;
end process;

can_clk_o <= s_can_clk;


-- Detect SyncSequence
process (clk_100, reset_n)
	variable v_first_run : std_logic := '1';
begin
	if reset_n = '0' then
		s_sync_seq <= '0';
		--v_first_run := '1';
	elsif rising_edge (clk_100) then 
		if ((s_can_clk = '1' and s_phase_seg2 = '1' and s_phase_seg2_cnt >= phase_seg2_g) 
			or (s_can_clk = '1' and s_phase_seg2 = '1' and s_phase_seg2_cnt >= (phase_seg2_g - resync_jw_g) and s_early_edge = '1') 
			or (s_can_clk = '1' and s_sof = '1')) and s_eof = '0' then 
				s_sync_seq <= '1';
		else 
			if s_sync_seq = '1' and s_can_clk = '0' then 
				s_sync_seq <= '1';
			else
				s_sync_seq <= '0';
			end if;
		end if;
	end if;
end process;
sync_seg_o <= s_sync_seq;

-- Detect Propagation Delay 
process (clk_100, reset_n)
	variable v_prop_delay : std_logic := '0';
begin 
	if reset_n = '0' or sof_i = '1' then 
		s_prop_delay <= '0';
		s_prop_delay_cnt <= (others => '0');
		v_prop_delay := '0';
	elsif rising_edge (clk_100) then
		if s_sync_seq = '1' and s_can_clk = '1' then 
			s_prop_delay <= '1';
			v_prop_delay := '1';
		end if;
		if (v_prop_delay = '1' and s_can_clk = '1') then 
			s_prop_delay_cnt <= s_prop_delay_cnt + 1;
			if s_prop_delay_cnt >= propagation_seg_g then 
				s_prop_delay_cnt <= (others => '0');
				v_prop_delay := '0';
				s_prop_delay <= '0';
			end if;
		end if;		
	end if;
end process;
propagation_seg_o <= s_prop_delay;

-- Detect Phase Segment 1 
process (clk_100, reset_n)
	variable v_phase_seg1 : std_logic := '0';
begin 
	if reset_n = '0' or sof_i = '1' then 
		s_phase_seg1 <= '0';
		s_phase_seg1_cnt <= (others => '0');
		v_phase_seg1 := '0';
	elsif rising_edge (clk_100) then
		if s_prop_delay = '1' and s_prop_delay_cnt >= propagation_seg_g and s_can_clk = '1' then 
			s_phase_seg1 <= '1';
			v_phase_seg1 := '1';
		end if;
		if (v_phase_seg1 = '1' and s_can_clk = '1') then 
			s_phase_seg1_cnt <= s_phase_seg1_cnt + 1;
				if (s_phase_seg1_cnt >= phase_seg1_g and s_late_edge = '0') or (s_phase_seg1_cnt >= (phase_seg1_g + resync_jw_g)) or (s_phase_seg1_cnt >= (phase_seg1_g + s_late_cnt))  then 
					s_phase_seg1_cnt <= (others => '0');
					v_phase_seg1 := '0';
					s_phase_seg1 <= '0';
				end if;
		end if;	
	end if;
end process;
phase_seg1_o <= s_phase_seg1;

-- Detect Phase Segment 2 
process (clk_100, reset_n)
	variable v_phase_seg2 : std_logic := '0';
begin 
	if reset_n = '0' or sof_i = '1' then 
		s_phase_seg2 <= '0';
		s_phase_seg2_cnt <= (others => '0');
		v_phase_seg2 := '0';
	elsif rising_edge (clk_100) then
		if (s_phase_seg1 = '1' and s_phase_seg1_cnt >= phase_seg1_g and s_can_clk = '1' and s_late_edge = '0') 
			or (s_phase_seg1 = '1' and s_phase_seg1_cnt >= (phase_seg1_g + resync_jw_g) and s_can_clk = '1') 
			or (s_phase_seg1 = '1' and s_phase_seg1_cnt >= (phase_seg1_g + s_late_cnt) and s_can_clk = '1') then 
				s_phase_seg2 <= '1';
				v_phase_seg2 := '1';
		end if;
		if (v_phase_seg2 = '1' and s_can_clk = '1') then 
			s_phase_seg2_cnt <= s_phase_seg2_cnt + 1;
			if (s_phase_seg2_cnt >= (phase_seg2_g - resync_jw_g) and s_early_edge = '1') or (s_phase_seg2_cnt >= phase_seg2_g) then 
				s_phase_seg2_cnt <= (others => '0');
				v_phase_seg2 := '0';
				s_phase_seg2 <= '0';
			end if;
		end if;		
	end if;
end process;
phase_seg2_o <= s_phase_seg2;

-- Detect Sample Point
process (clk_100, reset_n)
begin
	if reset_n = '0' or sof_i = '1' then 
		s_sample_point <= '0';
	elsif rising_edge(clk_100) then 
		if s_late_edge = '1' then 
			if (s_phase_seg1 = '1' and s_phase_seg1_cnt >= (phase_seg1_g + resync_jw_g) and s_can_clk = '1')
				or (s_phase_seg1 = '1' and s_phase_seg1_cnt >= (phase_seg1_g + s_late_cnt) and s_can_clk = '1')then 
				s_sample_point <= '1';
			else
				s_sample_point <= '0';
			end if;
		else
			if s_phase_seg1 = '1' and s_phase_seg1_cnt >= phase_seg1_g and s_can_clk = '1' then 
				s_sample_point <= '1';
			else
				s_sample_point <= '0';
			end if;
		end if;
	end if;
end process; 
sample_point_o <= s_sample_point;

-- Start of Frame Sync (Hardsync)
process (clk_100, reset_n) 
	variable v_sof : std_logic := '0';
begin 
	if reset_n = '0' then 
		s_sof <= '0';
		v_sof := '0';
	elsif rising_edge (clk_100) then 
		if sof_i = '1' then 
			s_sof <= '1';
			v_sof := '1';
		end if;
		if s_can_clk = '1' and sof_i = '0' then 		-- hier noch "and sof_i = '0'" hinzufügen damit auch der Fall abgedeckt ist wenn SOF zufällig auf can_clk fällt 
			s_sof <= '0';
		end if;
	end if;
end process;

-- EOF Signal 
process (clk_100, reset_n)
begin 
	if reset_n = '0' then 
		s_eof <= '0';
	elsif rising_edge(clk_100) then 
		if eof_i = '1' then 
			s_eof <= '1';
		end if;
		if s_sof = '1' then 
			s_eof <= '0';
		end if;
	end if;
end process;

-- Late Edge Process
process (clk_100, reset_n)
begin 
	if reset_n = '0' then 
		s_late_edge <= '0';
	elsif rising_edge(clk_100) then 
		if late_edge_i = '1' then 
			s_late_edge <= '1';
			if s_prop_delay = '1' then 
				s_late_cnt <= s_prop_delay_cnt; 
			elsif s_phase_seg1 = '1' then 
				s_late_cnt <= s_phase_seg1_cnt + propagation_seg_g;
			end if;
		end if;
		if s_sample_point = '1' then 
			s_late_cnt <= (others => '0');
		end if;
		if (phase_seg1_g + s_late_cnt) > (phase_seg1_g + resync_jw_g) then 
			if s_phase_seg1_cnt >= (phase_seg1_g + resync_jw_g) and s_can_clk = '1'  then 
				s_late_edge <= '0';
			end if;
		else
			if s_phase_seg1_cnt >= (phase_seg1_g + s_late_cnt) and s_can_clk = '1'  then 
				s_late_edge <= '0';
			end if;
		end if;
	end if;
end process;

-- Early Edge Process
process (clk_100, reset_n)
begin
	if reset_n = '0' then 
		s_early_edge <= '0';
	elsif rising_edge (clk_100) then 
		if early_edge_i = '1' and s_phase_seg2 = '1' then 		--hier eventuell noch s_phase_seg2 entfernen da die Bedingung schon vorher überprüft werdne muss ob es eine Early edge ist oder nicht
			s_early_edge <= '1';
		end if;
		if s_phase_seg2_cnt >= (phase_seg2_g - resync_jw_g) and s_can_clk = '1' then 
			s_early_edge <= '0';
		end if;		
	end if;
end process;


end Behavioral;

	
		
		
	

