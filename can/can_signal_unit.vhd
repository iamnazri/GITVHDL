----------------------------------------------------------------------------------
-- Company: AVI Systems GmbH
-- Engineer: René Ulmer <rene.ulmer@avi-systems.eu>
-- 
-- Create Date: 07.11.2019 
-- Design Name: can signal unit
-- Module Name: can signal unit - Behavioral
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

entity can_signal_unit is
	Generic (
				prescaler_g : unsigned (7 downto 0) := x"0a";
				resync_jw_g : unsigned (2 downto 0) := "010";
				phase_seg1_g : unsigned (3 downto 0) := x"2";
				phase_seg2_g : unsigned (3 downto 0) := x"2";
				propagation_seg_g : unsigned (3 downto 0) := x"5"
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
end can_signal_unit;

architecture Behavioral of can_signal_unit is
	
	signal s_sof : std_logic := '0';
	signal s_sof_cnt : unsigned (15 downto 0) := (others => '0');
    signal s_eof : std_logic := '0';
    signal s_eof_cnt : unsigned (7 downto 0) := (others => '0');
	signal s_ntb : unsigned (6 downto 0) := ("000" & propagation_seg_g) + ("000" & phase_seg1_g) + ("000" & phase_seg2_g) + 1;
	signal s_early_edge : std_logic := '0';
	signal s_sp_data : std_logic := '0';	--sample point data
	signal s_sp_data_q : std_logic := '0'; --old sample point data
	signal s_bit_cnt : unsigned (7 downto 0) := (others => '0');
	signal s_bit_de_stuff_cnt : unsigned (2 downto 0) := (others => '0');
	signal s_stuffing_area : std_logic := '0';
	signal s_dlc : unsigned (3 downto 0) := (others => '0');
	signal s_test : unsigned (7 downto 0) := "11010110";
	signal s_crc_area : std_logic := '0';
	signal s_crc : unsigned (14 downto 0) := (others => '0');
	signal s_nxt_bit : std_logic := '0';
	signal s_crc_err : std_logic := '1';
	signal s_data_valid : std_logic := '0'; 
	signal s_id : std_logic_vector (28 downto 0) := (others => '0');
	signal s_data_o : unsigned (63 downto 0) := (others => '0');
	signal s_crc_o : unsigned (14 downto 0) := (others => '0');
	signal s_rx_q : std_logic := '0';
	signal s_late_edge : std_logic := '0';
	signal s_fe : std_logic := '0';
	signal s_ide : std_logic := '0';
	signal s_rerror_cnt : unsigned (15 downto 0) := (others => '0');
	signal s_dominant_cnt : unsigned (15 downto 0) := (others => '0');
	signal s_can_active : std_logic := '0';
	signal s_frame_error : std_logic := '0';
	signal s_frame_error_d : std_logic := '0';
	signal s_frame_error_cnt : unsigned (8 downto 0) := (others => '0');
		 

begin


--i_ila_cansignalunit : ila_1
--	port map (
--		clk		=> clk_100,
--		probe0(0)	=> can_clk_i, 
--		probe1(0)	=> sync_seg_i,
--		probe2(0)	=> propagation_seg_i, 
--		probe3(0)	=> phase_seg1_i,
--		probe4(0)	=> phase_seg2_i, 
--		probe5(0)	=> sample_point_i,
--		probe6(0)	=> s_sof,
--		probe7(0)	=> s_eof
--	);

--Find EOF Sequence Process
process(clk_100, reset_n)
	variable v_sof_det : std_logic := '0';
begin
	if reset_n = '0' then
		s_eof_cnt <= (others => '0');
		s_eof <= '0';
		v_sof_det := '0';
	elsif rising_edge (clk_100) then 
		if s_sof = '1' then 
			v_sof_det := '1'; 
		end if;
		if can_clk_i = '1' and rx_i = '1' and v_sof_det = '1' then
			s_eof_cnt <= s_eof_cnt + 1;
		elsif can_clk_i = '1' and rx_i = '0' then 
			s_eof_cnt <= (others => '0');
		end if;
		if s_eof_cnt >= (7 * s_ntb - 1) and rx_i = '1' then 
			s_eof <= '1';
			v_sof_det := '0';
		end if;
		if s_eof = '1' then 
			s_eof <= '0';
			s_eof_cnt <= (others => '0');
		end if;
	end if;
end process;
eof_o <= s_eof;


-- Find SOF Process
process(clk_100, reset_n)
	variable v_sof_det : std_logic := '0';
begin
	if reset_n = '0' then 
		s_sof <= '0';
		s_sof_cnt <= (others => '0');
		v_sof_det := '0';
	elsif rising_edge (clk_100) then
		if can_clk_i = '1' and rx_i = '1' and v_sof_det = '0' then 
			s_sof_cnt <= s_sof_cnt + 1;
		end if;
		if s_sof_cnt >= (7 * s_ntb - 1 ) and rx_i = '0' then 
			v_sof_det := '1';										
			s_sof <= '1';
		end if;
		if s_sof = '1'  then   
			s_sof <= '0';
			s_sof_cnt <= (others => '0');			
		end if;
		if s_eof = '1' then 
			v_sof_det := '0';
		end if;
	end if;
end process;
sof_o <= s_sof;

s_nxt_bit <= rx_i xor s_crc(14);
-- Signal Sample
process (clk_100, reset_n)
	
begin 
	if reset_n = '0' then 
		s_sp_data <= '0';
		s_bit_de_stuff_cnt <= (others => '0');
		s_bit_cnt <= (others => '0');
		s_dlc <= (others => '0');
		s_crc_err <= '0';
		--s_rerror_cnt <= (others => '0');
	elsif rising_edge (clk_100) then 
		--s_test <= s_test xor "11010110";
		--if s_test = 0 then 
		--	s_crc_err <= '0';
		--else
		--	s_crc_err <= '1';
		--end if;
		
		if s_sof = '1' then 
			s_crc <= (others => '0');
			s_crc_o <= (others => '0');
			s_dlc <= (others => '0');
			s_id <= (others => '0');
			s_data_o <= (others => '0');
			s_bit_cnt <= (others => '0');
			s_ide <= '0';
			
		end if;
		
		if s_dlc > 8 then 			-- check if bit error in dlc (otherwise data will be signaled as valid)
			s_dlc <= "1000";
		end if;
		
		if sample_point_i = '1' then 
			if s_sp_data = rx_i and s_stuffing_area = '1' then 
				s_bit_de_stuff_cnt <= s_bit_de_stuff_cnt + 1;
			else
				s_bit_de_stuff_cnt <= (others => '0');
			end if;
			if s_bit_de_stuff_cnt < 4 and s_stuffing_area = '1' then			-- let out stuff bits
				s_sp_data <= rx_i;
				s_sp_data_q <= s_sp_data;
				s_bit_cnt <= s_bit_cnt + 1;
				--if s_rerror_cnt > 0 then 
				--	s_rerror_cnt <= s_rerror_cnt - 1;
				--end if;
				if s_crc_area = '1' then 
					if s_nxt_bit = '1' then										--crc calculation
						s_crc <= (s_crc(13 downto 0) & '0') xor "100010110011001";
					else
						s_crc <= (s_crc(13 downto 0) & '0');
					end if;
				end if;
				if  (s_bit_cnt >= 1 and s_bit_cnt < 12) 
						or (s_bit_cnt >= 14 and s_bit_cnt < 32 and s_ide = '1') then 		--id detection
					s_id (28 downto 1) <= s_id (27 downto 0);
					s_id(0) <= rx_i;
				elsif s_bit_cnt >= 13 and s_bit_cnt < 14 then 								--ide detection
					s_ide <= rx_i;
				elsif (s_bit_cnt >= 15 and s_bit_cnt < 19 and s_ide = '0') 
						or (s_bit_cnt >= 35 and s_bit_cnt < 39 and s_ide = '1') then 		--dlc detection
					s_dlc(3 downto 1) <= s_dlc (2 downto 0);
					s_dlc(0) <= rx_i;
				elsif (s_bit_cnt >= 19 and s_bit_cnt < (19 + s_dlc * 8) and s_ide = '0')
						or (s_bit_cnt >= 39 and s_bit_cnt < (39 + s_dlc * 8) and s_ide = '1') then					--data detection
					s_data_o (63 downto 1) <= s_data_o (62 downto 0);
					s_data_o(0) <= rx_i;
				elsif (s_bit_cnt >= (19 + s_dlc * 8) and s_bit_cnt < (34 + s_dlc * 8) and s_ide = '0')
						or (s_bit_cnt >= (39 + s_dlc * 8) and s_bit_cnt < (54 + s_dlc * 8) and s_ide = '1') then 	-- crc detection
					s_crc_o(14 downto 1) <= s_crc_o(13 downto 0);
					s_crc_o(0) <= rx_i;
				end if;
			--elsif s_bit_de_stuff_cnt >= 5 and s_stuffing_area = '1' then 						-- bit stuffing error detection
			--	s_sp_data <= rx_i;
			--	s_sp_data_q <= s_sp_data;
			--	s_rerror_cnt <= s_rerror_cnt + 1;
			elsif s_stuffing_area = '0' then 														
				s_sp_data <= rx_i;
				s_sp_data_q <= s_sp_data;
				s_bit_cnt <= s_bit_cnt + 1;
			else
				s_sp_data <= rx_i;												-- if after stuff bit is a bit with same level than before stuff bit
				s_sp_data_q <= s_sp_data;
			end if;
			
			if (s_bit_cnt >= (34 + s_dlc * 8) and s_bit_cnt < (35 + s_dlc * 8) and s_ide = '0')
					or (s_bit_cnt >= (54 + s_dlc * 8) and s_bit_cnt < (55 + s_dlc * 8) and s_ide = '1') then 	--check crc and shift data
				s_data_o <= shift_left(s_data_o, to_integer((8-s_dlc)*8));
				if ((s_crc_o xor s_crc) = 0) then 
					s_crc_err <= '0';
				else
					s_crc_err <= '1';
				end if;					
			end if;
		end if;
				
		if s_eof = '1' then 
			s_bit_cnt <= (others => '0');
			s_bit_de_stuff_cnt <= (others => '0');
			s_crc_err <= '0';
		end if;
		
		
		if s_eof = '1' and s_crc_err = '0' and s_frame_error = '0' then 
			s_data_valid <= '1';
		else
			s_data_valid <= '0';
		end if;
	end if;
end process;
id_o <= s_id;
dlc_o <= std_logic_vector(s_dlc);
data_o <= std_logic_vector(s_data_o);
data_valid_o <= s_data_valid;


-- Area detection (Id, DLC, Data) 
process (clk_100, reset_n)
	
begin
	if reset_n = '0' then 
		s_stuffing_area <= '0';
		s_crc_area <= '0'; 
	elsif rising_edge (clk_100) then 
		if s_sof = '1' then 
			s_stuffing_area <= '1';
			s_crc_area <= '1';
		end if;
		if (s_bit_cnt >= (19 + s_dlc * 8) and s_ide = '0')  
				or (s_bit_cnt >= (39 + s_dlc * 8) and s_ide = '1') then 		--19: SOF+ID+ControlField+Data
			s_crc_area <= '0';
		end if;
		if (s_bit_cnt >= (34 + s_dlc * 8) and s_ide = '0') 
				or (s_bit_cnt >= (54 + s_dlc * 8) and s_ide = '1') then 		--34: SOF+ID+ControlField+Data+CRC				
			s_stuffing_area <= '0';
		end if;
	end if;
end process;

-- dlc process
--process (clk_100, reset_n)
--begin
--	if reset_n = '0' then 
--		s_dlc <= (others => '0');
--	elsif rising_edge (clk_100) then
--		if s_bit_cnt >= 14 and s_bit_cnt < 18 and sample_point_i = '1' then 
--			s_dlc(3 downto 1) <= s_dlc (2 downto 0);
--			s_dlc(0) <= rx_i;
--		end if;
--	end if;
--end process;



-- Detect Early Edge
process (clk_100, reset_n) 
begin 
	if reset_n = '0' then 
		s_early_edge <= '0';
	elsif rising_edge (clk_100) then
		s_rx_q <= rx_i;
		if phase_seg2_i = '1' and rx_i = '0' and s_rx_q = '1' then 
			s_early_edge <= '1';
		else
			s_early_edge <= '0';
		end if;
	end if;	
end process;

early_edge_o <= s_early_edge;


-- Detect Late Edge
process (clk_100, reset_n)
begin 
	if reset_n = '0' then 
		s_late_edge <= '0';
	elsif rising_edge (clk_100) then 
		if (propagation_seg_i = '1' or phase_seg1_i = '1') and phase_seg2_i = '0' and sync_seg_i = '0' and rx_i = '0' and s_rx_q = '1' then 
			s_late_edge <= '1';
		else
			s_late_edge <= '0';
		end if;			
	end if;
end process;

late_edge_o <= s_late_edge;
s_fe <= s_rx_q and not rx_i;

-- detect errors process
process (clk_100, reset_n)
	begin 
	if reset_n = '0' then 
		s_dominant_cnt <= (others => '0');
		s_can_active <= '1';
		s_frame_error_cnt <= (others => '0');
	elsif rising_edge (clk_100) then 
		s_frame_error_d <= s_frame_error;
		if s_crc_err = '1' then 
			s_frame_error <= '1';
		end if;
		if s_frame_error = '1' and s_frame_error_d = '0' then 
			s_frame_error_cnt <= s_frame_error_cnt + 1;
		end if;
		if sample_point_i = '1' and rx_i = '0' then 
			s_dominant_cnt <= s_dominant_cnt + 1;
		elsif sample_point_i = '1' and rx_i = '1' then 
			s_dominant_cnt <= (others => '0');
		end if;
		if s_dominant_cnt >= 6 then 
			s_frame_error <= '1';
		end if;
		if s_eof = '1' then 
			s_frame_error <= '0';
		end if;
		if s_eof = '1' and s_frame_error = '0' then 
			s_frame_error_cnt <= (others => '0');
		end if;
		if s_dominant_cnt >= 50 or s_frame_error_cnt >= 200 then 
			s_can_active <= '0';
		else
			s_can_active <= '1';
		end if;
	end if;
end process;

can_active_o <= s_can_active;


end Behavioral;
	
		
		
	

