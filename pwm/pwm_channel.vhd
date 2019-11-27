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


entity pwm_channel is
    Port ( 
			clk				: in std_logic;						-- if you dont know what a clock signal is you probably shouldnt work here
			timer_period	: in std_logic_vector(31 downto 0); -- duration of a timer period
			timer_high_time	: in std_logic_vector(31 downto 0); -- how long within a period the output shall the output stay 1 (eg the duty cycle)
			start			: in std_logic;						-- start the timer
			pwm_out		 	: out STD_LOGIC := '1'				-- pwm output signals
	);
end pwm_channel;
architecture Behavioral of pwm_channel is

	signal started				: std_logic := '0';
	signal counter_period 		: unsigned(31 downto 0) := to_unsigned(0, 32);
begin

process(clk)
begin
    if rising_edge(clk) then
		-- only work when the timer is started
		if (started = '1') then
			-- increment timer
			counter_period <= counter_period + 1;
			-- check if the output within this period should be high
			if (counter_period <= unsigned(timer_high_time)) then
				pwm_out <= '0';
			else
				pwm_out <= '1';
			end if;
			-- reset the counter if the period is reached
			if (counter_period = unsigned(timer_period)) then
				counter_period <= to_unsigned(0, 32);
				-- check if we need to be high at the beginning of the next period
				if (unsigned(timer_high_time) > 0) then
					pwm_out <= '0';
				end if;
			end if;
		else
			-- reset everything if the timer is not running
			counter_period <= to_unsigned(0, 32);
			pwm_out <= '1';
		end if;
		-- load start bit
		started <= start;
	end if;
 end process;
	
end Behavioral;
