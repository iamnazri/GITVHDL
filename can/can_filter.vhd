----------------------------------------------------------------------------------
-- Company: AVI Systems GmbH
-- Engineer: René Ulmer <rene.ulmer@avi-systems.eu>
-- 
-- Create Date: 14.11.2019 
-- Design Name: can filter
-- Module Name: can filter - Behavioral
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

entity can_filter is
	
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
end can_filter;


architecture Behavioral of can_filter is
	
	signal s_pgn : unsigned (15 downto 0) := (others => '0');  
	signal s_valid : std_logic := '0';
	signal s_valid_o : std_logic := '0';
	signal s_clk_cnt : unsigned (15 downto 0) := (others => '0');
begin 

process (clk_100, reset_n)
begin 
	if reset_n = '0' then 
		s_pgn <= (others => '0');
		package_o <= (others => '0');
		s_valid_o <= '0';
		s_clk_cnt <= x"000a";
	elsif rising_edge (clk_100) then 
		s_clk_cnt <= s_clk_cnt + 1;
		
		if valid_i = '1' then 
			s_pgn <= unsigned(id_i(23 downto 8));
			s_clk_cnt <= (others => '0');
		end if;
		
		if s_clk_cnt = 1 then 
			case s_pgn is 
				when x"d000" => 		-- 53248 Cab Illumination Message
					package_o <= "0000000000000000000000000000000" & id_i & dlc_i & data_i;
					s_valid <= '1'; 
				when x"f005" => 		-- 61445 Electronic Transmission Controller (actual Gear)
					package_o <= "0000000000000000000000000000000" & id_i & dlc_i & data_i;
					s_valid <= '1'; 
				when x"f009" => 		-- 61449 Vehicle Dynamic Stability Control 2 (steering wheel angle)
					package_o <= "0000000000000000000000000000000" & id_i & dlc_i & data_i;
					s_valid <= '1'; 
				when x"f00b" =>			-- 61451 Electronic Steering Control (actual inner wheel steering angle)
					package_o <= "0000000000000000000000000000000" & id_i & dlc_i & data_i;
					s_valid <= '1'; 
				when x"f01d" =>			-- 61469 Steering Angle Sensor Information 
					package_o <= "0000000000000000000000000000000" & id_i & dlc_i & data_i;
					s_valid <= '1'; 
				when x"fdcc" => 		-- 64972 Operators External Light Controls (turn signal switch, operators desired backlight)
					package_o <= "0000000000000000000000000000000" & id_i & dlc_i & data_i;
					s_valid <= '1'; 
				when x"fe40" => 		-- 65088 Lightning Data (turn signal)
					package_o <= "0000000000000000000000000000000" & id_i & dlc_i & data_i;
					s_valid <= '1'; 
				when x"fe41" => 		-- 65089 Lightning Command (turn signal)
					package_o <= "0000000000000000000000000000000" & id_i & dlc_i & data_i;
					s_valid <= '1'; 
				when x"fe6c" => 		-- 65132 Tachograph (vehicle speed)
					package_o <= "0000000000000000000000000000000" & id_i & dlc_i & data_i;
					s_valid <= '1'; 
				when x"fe6e" => 		-- 65134 High Resolution Wheel Speed
					package_o <= "0000000000000000000000000000000" & id_i & dlc_i & data_i;
					s_valid <= '1'; 
				when x"feab" => 		-- 65195 Electronic Transmission Controller 6 (gear)
					package_o <= "0000000000000000000000000000000" & id_i & dlc_i & data_i;
					s_valid <= '1'; 
				when x"fee6" => 		-- 65254 Time/Date
					package_o <= "0000000000000000000000000000000" & id_i & dlc_i & data_i;
					s_valid <= '1'; 
				when x"fee8" => 		-- 65256 Vehicle Direction/Speed (navigation-based vehicle speed)
					package_o <= "0000000000000000000000000000000" & id_i & dlc_i & data_i;
					s_valid <= '1'; 
				when x"fef1" => 		-- 65265 Cruise Control/Vehicle Speed (wheel-based vehicle speed)
					package_o <= "0000000000000000000000000000000" & id_i & dlc_i & data_i;
					s_valid <= '1'; 
				when others =>
					s_valid <= '0';
			end case;
		elsif s_clk_cnt = 2 and s_valid = '1' then 		-- for delayed valid signal
			s_valid_o <= '1';
			s_pgn <= (others => '0');
		else
			s_valid_o <= '0';
		end if;
		
		
	end if;
end process;
valid_o <= s_valid_o;

end Behavioral;
