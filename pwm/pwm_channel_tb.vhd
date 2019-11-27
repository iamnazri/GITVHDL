----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07.05.2016 22:14:27
-- Design Name: 
-- Module Name: rgmii_tx - Behavioral
-- Project Name: 
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


entity pwm_channel_tb is

end pwm_channel_tb;

architecture Behavioral of pwm_channel_tb is
	
	component pwm_channel is
    Port ( 
			clk				: in std_logic;
			timer_period	: in std_logic_vector(31 downto 0);
			timer_high_time	: in std_logic_vector(31 downto 0);
			start			: in std_logic;
			pwm_out		 	: out STD_LOGIC := '0'
	);
	end component;

    signal clk 				: std_logic := '0';
	signal start 			: std_logic := '0';
	signal pwm_out 			: std_logic := '0';
	signal timer_period		: std_logic_vector(31 downto 0) := (others=>'0');
	signal timer_high_time	: std_logic_vector(31 downto 0) := (others=>'0');
	
begin

i_pwm_channel: pwm_channel port map (
      clk       		=> clk,
	  timer_period		=> timer_period,
	  timer_high_time	=> timer_high_time,
	  start				=> start,
	  pwm_out			=> pwm_out
);


process
begin
	clk <= '1';
	wait for 5 ns;
	clk <= '0';
	wait for 5 ns;
end process;

process
begin
	wait for 10 us;
	wait until rising_edge(clk);
	timer_period <= std_logic_vector(to_unsigned(10, timer_period'length));
	timer_high_time <= std_logic_vector(to_unsigned(4, timer_period'length));
	start <= '1';
	wait until rising_edge(clk);
	wait for 10 us;
	start <= '0';
end process;
end Behavioral;
