----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06.02.2018 15:14:43
-- Design Name: 
-- Module Name: h264_top - Behavioral
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
use ieee.numeric_std.ALL;

--debug
--use ieee.math_real.ALL;
--use std.textio.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
-- Library UNISIM;
-- use UNISIM.vcomponents.all;

-- Library UNIMACRO;
-- use UNIMACRO.vcomponents.all;

entity mipi_low_level is
generic (BIT_DEPTH 	: integer := 12;
		 IMG_WIDTH 	: integer := 1920;
		 IMG_HEIGHT : integer := 1080
		 );
port(

    M_AXIS_ACLK		: in std_logic;
    M_AXIS_ARESETN  : in std_logic;
    M_AXIS_TVALID   : out std_logic;
    M_AXIS_TDATA    : out std_logic_vector(16-1 downto 0);
    M_AXIS_TLAST    : out std_logic;
	M_AXIS_TUSER    : out std_logic;
    M_AXIS_TREADY   : in std_logic;
	
	mipi_rstn		: in std_logic;
	mipi_hs_clk		: in std_logic;
	mipi_hs_valid	: in std_logic;
	mipi_lane_0		: in std_logic_vector(7 downto 0);
	mipi_lane_1		: in std_logic_vector(7 downto 0);
	mipi_lane_2		: in std_logic_vector(7 downto 0);
	mipi_lane_3		: in std_logic_vector(7 downto 0);
	
	mipi_phy_err	: in std_logic;
	
	dout_debug		: out std_logic_vector(7 downto 0);
	dout_valid		: out std_logic;
	fifo_full		: out std_logic
);
end mipi_low_level;


architecture Behavioral of mipi_low_level is

	COMPONENT fifo_generator_0
	  PORT (
		rst : IN STD_LOGIC;
		wr_clk : IN STD_LOGIC;
		rd_clk : IN STD_LOGIC;
		din : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		wr_en : IN STD_LOGIC;
		rd_en : IN STD_LOGIC;
		dout : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		full : OUT STD_LOGIC;
		empty : OUT STD_LOGIC;
		wr_rst_busy : OUT STD_LOGIC;
		rd_rst_busy : OUT STD_LOGIC
	  );
	END COMPONENT;

	--sync codes for short packages
	constant FRAME_START	:	integer := 0;
	constant FRAME_END		:	integer := 1;
	constant LINE_START		:	integer := 2;
	constant LINE_END		:	integer := 3;

	signal internal_rst		:	std_logic;
	
	signal num_bytes		: 	unsigned(15 downto 0);
	signal byte_ctr			: 	unsigned(15 downto 0);
	
	signal short_packet		:	std_logic;
	signal first_line		:	std_logic;
	
	signal out_reg			: 	std_logic_vector(3*16-1 downto 0);
	signal out_reg_valid	: 	std_logic_vector(2 downto 0);
	signal out_reg_user		: 	std_logic_vector(2 downto 0);
	signal out_reg_last		: 	std_logic_vector(2 downto 0);
	
	signal mipi_rd_en		: 	std_logic;
	signal mipi_data		:	std_logic_vector(7 downto 0);
	signal mifo_empty		: 	std_logic;
	signal mipi_sum			: 	std_logic_vector(31 downto 0);
	signal mifo_empty_n		: 	std_logic;
	
	type state_t is (wait_header, read_header, read_data, read_footer);  
	signal state, next_state : state_t;
begin

internal_rst <= not M_AXIS_ARESETN or mipi_rstn;

M_AXIS_TDATA <= out_reg(3*16-1 downto 2*16);
M_AXIS_TVALID <= out_reg_valid(2);
M_AXIS_TUSER <= out_reg_user(2);
M_AXIS_TLAST <= out_reg_last(2);
dout_debug <= mipi_data;
dout_valid <= not mifo_empty;

sequ_top : process (M_AXIS_ACLK) begin
if rising_edge(M_AXIS_ACLK) then

	
	mipi_rd_en <= '0';
		
	if (M_AXIS_ARESETN = '0') then
		num_bytes <= to_unsigned(0, num_bytes'length);
		byte_ctr <= to_unsigned(0, byte_ctr'length);
		first_line <= '0';
		state <= wait_header;
		short_packet <= '0';
			
		out_reg			<= (others=>'0');
		out_reg_valid	<= (others=>'0');
		out_reg_user	<= (others=>'0');
		out_reg_last	<= (others=>'0');
	else
		-- we can only do somethiing when there is data in the mifo
		if (mifo_empty = '0') then
			--mipi_rd_en <= '1';
			case state is 
				when wait_header =>
					short_packet <= '0';
					byte_ctr <= to_unsigned(0, byte_ctr'length);

					--wait for packet header
					case to_integer(unsigned(mipi_data)) is
						when FRAME_START 		=>
							short_packet <= '1';
							first_line <= '1'; --needed to generate TUSER later
						when 16#01# to 16#0F# 	=> 	
							-- no payload in a short package
							short_packet <= '1';
						when 16#28# to 16#30# 	=>
							-- this is a long packet with raw image data
						when others				=>
					end case;
					
					state <= read_header;
				when read_header =>
					--read header (expected number of bytes + checksum)				
					if (byte_ctr = 0) then
						num_bytes(7 downto 0) <= unsigned(mipi_data);
					end if;
					
					if (byte_ctr = 1) then
						num_bytes(15 downto 8) <= unsigned(mipi_data);
					end if;
					
					byte_ctr <= byte_ctr + 1;
					
					-- header is only 2 bytes
					if (byte_ctr = 2) then
						byte_ctr <= to_unsigned(0, byte_ctr'length);
						-- short packet does not have a payload
						if (short_packet = '1') then
							state <= wait_header;
						else
							state <= read_data;
						end if;
					end if;
										
				when read_data => 
					--read payload
                   
					byte_ctr <= byte_ctr + 1;

					-- payload is complete
					if (byte_ctr = num_bytes - 1) then
						byte_ctr <= to_unsigned(0, byte_ctr'length);
						
						state <= read_footer;
					end if;
					
					-- shift data and control signals into shift registers
					out_reg <= out_reg(2*16-1 downto 0) & x"0000";
					out_reg_valid <= out_reg_valid(1 downto 0) & '0';
					out_reg_last <= out_reg_last(1 downto 0) & '0';
					out_reg_user <= out_reg_user(1 downto 0) & '0';
					
					-- see mipi standard 11.4.5
					case to_integer(byte_ctr mod 3) is
						when 0 =>
							out_reg(11 downto 4) <= mipi_data;
							out_reg_valid(0) <= '1';
							if (byte_ctr = 0 and first_line = '1') then
								out_reg_user(0) <= '1';
							end if;
						when 1 =>
							out_reg(11 downto 4) <= mipi_data;
							out_reg_valid(0) <= '1';
							if (byte_ctr = num_bytes - 2) then
								out_reg_last(0) <= '1';
							end if;
						when 2 =>
							--lsbs
							out_reg(19 downto 16) <= mipi_data(7 downto 4);
							out_reg(35 downto 32) <= mipi_data(3 downto 0);
						when others =>
					end case;
					

				when read_footer =>
					out_reg <= out_reg(2*16-1 downto 0) & x"0000";
					out_reg_valid <= out_reg_valid(1 downto 0) & '0';
					out_reg_last <= out_reg_last(1 downto 0) & '0';
					out_reg_user <= out_reg_user(1 downto 0) & '0';
					--the footer has a length of 2 bytes but since data is aligned to 4 byte we need to read 2 more bytes
					if (byte_ctr = 3) then
						byte_ctr <= to_unsigned(0, byte_ctr'length);
						state <= wait_header;
					else
						byte_ctr <= byte_ctr + 1;
					end if;
					first_line <= '0';
			end case;
		end if;
	end if;
end if;
end process;

mipi_sum <= (mipi_lane_0 & mipi_lane_1 & mipi_lane_2 & mipi_lane_3);
mifo_empty_n <= not mifo_empty;

--mifo does clock domain crossing and converts 32 bit input to 8 bit output
mifo : fifo_generator_0 -- MIPI + FIFO :D LOL . Ja Lol xd xd xd
  PORT MAP (
    rst => internal_rst,
    wr_clk => mipi_hs_clk,
    rd_clk => M_AXIS_ACLK,
    din => mipi_sum,
    wr_en => mipi_hs_valid,
    rd_en => mifo_empty_n, -- Pipapo
    dout => mipi_data,
    full => fifo_full,
    empty => mifo_empty,
    wr_rst_busy => open,
    rd_rst_busy => open
  );
  
end Behavioral;
