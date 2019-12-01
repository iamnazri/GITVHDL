----------------------------------------------------------------------------------
-- Company: avi-systems deutschland gmbh c 2019
-- Engineer: NAB
-- 
-- Create Date: 01.12.2019 14:00:43
-- Design Name: 
-- Module Name: bbox - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: This packages takes the output of can_and_filter and assess whether
-- the signals fulfil the condition of an alarm according to Montagehandbuch s.40
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alarm_condition is
generic
		BUS_POLLING_RATE	: natural := 20
		
);
port(
		clk_i				: in std_logic;
		aresetn_i			: in std_logic;
		can_pkg_i			: in std_logic_vector(127 downto 0);
		can_valid_i			: in std_logic;
		can_active_i		: in std_logic;
		gpio_data_i			: in std_logic_vector(31 downto 0); -- if can is inactive, get data from gpio_data_i
	
		pwm_start_tmr_o		: out std_logic_vector(7 downto 0)
		

);
end entity;

architecture rtl of alarm_condition is

	signal s_can_pkg 				: std_logic_vector(127 downto 0);
	signal s_can_valid				: std_logic;
	signal s_can_active				: std_logic;
	signal s_gpio_data				: std_logic_vector(31 downto 0); 
	signal s_start_timer			: std_logic_vector(7 downto 0);
	
	signal package_cnt0				: unsigned(7 downto 0);
	signal package_cnt1				: unsigned(7 downto 0);
	signal package_cnt2				: unsigned(7 downto 0);
	signal can_speed				: std_logic;	
	signal can_curve				: std_logic;	
	signal can_blink				: std_logic;	
	
	
begin 

s_can_pkg 		<= can_pkg_i	;
s_can_valid	    <= can_valid_i	;
s_can_active	<= can_active_i;
s_gpio_data	    <= gpio_data_i	;
pwm_start_tmr_o <= s_start_timer ;

process(clk_i, aresetn_i)
begin
		if rising_edge(clk_i) then
				if (aresetn_i = '0') then
						s_start_timer <= (others => '0');
				        can_speed     <= (others => '0');
				        can_curve_rd  <= (others => '0');
				        can_blink     <= (others => '0');
						package_cnt     <= (others => '0');
				else
						-- TODO: Support gpio input 
						-- package_o <= "0000000000000000000000000000000" & id_i(7 downto 0) & dlc_i(3 downto 0) & data_i(63 downto 0);
						if s_can_valid = '1' then
								case s_can_pkg(91 downto 76) is
								
										-- -- 65088 Lightning Data (turn signal) 
										when x"fe40" =>
												package_cnt0 <= package_cnt0 + 1;
												if (package_count0 >= BUS_POLLING_RATE) then
														if s_can_pkg(1 downto 0) = b"10" then		-- Left = 01 ; Right = 10 ???
																can_blink <= '1';
														else	
																can_blink <= '0';
														end if;
														package_count0 <= to_unsigned(0,8);
												end if;			
										
										-- 65132 Tachograph (vehicle speed)
										when x"fe6c" => 
												package_cnt1 <= package_cnt1 + 1;
												if (package_count1 >= BUS_POLLING_RATE) then
														if s_can_pkg(63 downto 0) <= x"32" then		-- 1 to 1 calculation 
																can_speed <= '1';
														else	
																can_speed <= '0';
														end if;
														package_count1 <= to_unsigned(0,8);
												end if;
												
										-- 61451 Electronic Steering Control (actual inner wheel steering angle)
										when x"f00b" =>
												package_cnt2 <= package_cnt2 + 1;
												if (package_count1 >= BUS_POLLING_RATE) then
														if unsigned(s_can_pkg(63 downto 0)) >= 200 and unsigned(s_can_pkg(63 downto 0)) <= 400 then		-- how to do calculation ???
																can_curve <= '1';
														else	
																can_curve <= '0';
														end if;
														package_count2 <= to_unsigned(0,8);
												end if;
												
										when others =>
												
										end case;
										
						end if;
						
						if s_can_active = '1' then
								if can_curve = '1' OR can_blink = '1' then
										if can_speed = '1' then
												s_start_timer <= '1';
										else 
												s_start_timer <= '0';
										end if;
								end if;
						-- else -- TODO for GPIO Input
						end if; 
				end if;
				
end process;
												
												
											
							
				
				




end rtl;

