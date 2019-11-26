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
use IEEE.numeric_std.ALL;


--debug
--use ieee.math_real.ALL;
library std;
use std.textio.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity h264_top_tb is
end h264_top_tb;


architecture Behavioral of h264_top_tb is

    constant IMG_WIDTH		        : natural   := 1920;
    constant IMG_HEIGHT             : natural   := 1080;
    constant C_S_AXIS_TDATA_WIDTH   : integer   := 16;
    constant RAW_BITDEPTH           : integer   := 12;
    constant MIPI_LANE_WIDTH        : integer   := 8;
    type array_t_mipi is array ( natural range<> ) of unsigned(MIPI_LANE_WIDTH-1 downto 0);
    signal mipi_lane_arr            : array_t_mipi(3 downto 0); -- 4 MiPi lanes

	
	signal M_AXIS_ACLK	    : std_logic;
	signal M_AXIS_ARESETN   : std_logic := '0';
	signal M_AXIS_TVALID    : std_logic;
	signal M_AXIS_TDATA     : std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
	signal M_AXIS_TUSER     : std_logic;
	signal M_AXIS_TLAST     : std_logic;
	signal M_AXIS_TREADY    : std_logic := '0';
	
	
	signal mipi_rstn		: std_logic := '1';
	signal mipi_hs_clk		: std_logic;
	signal mipi_hs_valid	: std_logic;
	signal mipi_lane_0		: std_logic_vector(7 downto 0);
	signal mipi_lane_1		: std_logic_vector(7 downto 0);
	signal mipi_lane_2		: std_logic_vector(7 downto 0);
	signal mipi_lane_3		: std_logic_vector(7 downto 0);
	

	
	-- 12 bit/20 bit Raw data is put into a 16 bit container
	type arrayAXIS_T is array ( 0 to IMG_WIDTH*RAW_BITDEPTH/C_S_AXIS_TDATA_WIDTH, 0 to IMG_HEIGHT) of unsigned(C_S_AXIS_TDATA_WIDTH-1 downto 0);
	
	
	signal image_array     : arrayAXIS_t;
	signal tb_gen_data     : std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
	signal tb_gen_event    : std_logic;
	signal tb_wait_for_gen : std_logic;
	
begin

-- mipi hs clk (200Mhz)
process
begin
	mipi_hs_clk <= '0';
	wait for 2500 ps;
	mipi_hs_clk <= '1';
	wait for 2500 ps;
	mipi_hs_clk <= '0';
end process;

-- 100 mhz clk
process
begin
	M_AXIS_ACLK <= '0';
	wait for 5 ns;
	M_AXIS_ACLK <= '1';
	wait for 5 ns;	
end process;

M_AXIS_ARESETN <= '1' after 100 ns;
mipi_rstn <= '0' after 100 ns;

process		--input
begin

    -- Save 16 bit Streaming packet data in an array
    for y in 0 to IMG_HEIGHT-1 loop
        for x in 0 to ((IMG_WIDTH*RAW_BITDEPTH)/C_S_AXIS_TDATA_WIDTH)-1 loop -- IMG_WIDTH * 12 = Size of Line in Bits, /16 = Size of Line in AXI S packets
            -- Fill every half byte with decrementing data. For 16 bit packet => loops 4 times
            -- 4 bit * 4 loops = 16 bits
            for bit in 0 to (C_S_AXIS_TDATA_WIDTH/4)-1 loop
                image_array(x, y)(((bit+1)*4)-1 downto bit*4) <= to_unsigned(16#FF#-x, 4);
            end loop;
        end loop;
    end loop;

	mipi_hs_valid <= '0';
	mipi_lane_0 <= (others=>'0');
	mipi_lane_1 <= (others=>'0');
	mipi_lane_2 <= (others=>'0');
	mipi_lane_3 <= (others=>'0');
	wait for 200 ns;
	M_AXIS_TREADY <= '1';
	
	-- simulates one line of data
	
	--packet header - frame start
	mipi_lane_0 <= x"00";
	mipi_lane_1 <= x"01";
	mipi_lane_2 <= x"02";
	mipi_lane_3 <= x"03";
	mipi_hs_valid <= '1';
	wait until rising_edge(mipi_hs_clk);			
	mipi_hs_valid <= '0';
	
	-- simulate delay
	for i in 0 to 50 loop
		wait until rising_edge(mipi_hs_clk);
	end loop;

			
    -- Data feed for one frame
    for y in 0 to IMG_HEIGHT-1 loop
    	--simulate start of line aka. Header
        mipi_lane_0 <= x"2C";
        mipi_lane_1 <= x"40"; 
        mipi_lane_2 <= x"0b";
        mipi_lane_3 <= x"55";
        mipi_hs_valid <= '1';
        wait until rising_edge(mipi_hs_clk);   
        
        -- Data Feed for one line
        -- IMG_WIDTH *12 Bits = Size of Line in bits, 
        -- 16 bit width is maintained to ease the transfer of reference data tb -> axis rcver
        -- image_array(line coordinate, column coordinate)(12 Raw data from packet x, 4 bit Raw data of packet x+1)
        for x in 0 to ((IMG_WIDTH*RAW_BITDEPTH)/C_S_AXIS_TDATA_WIDTH)-1 loop 
            -- 
            for i in 0 to 3 loop
                mipi_lane_arr(i) <=  image_array(x,y)((i+1)*8-1 downto i*8);
            end loop;
            mipi_lane_0 <= std_logic_vector(mipi_lane_arr(0));
            mipi_lane_1 <= std_logic_vector(mipi_lane_arr(1));
            mipi_lane_2 <= std_logic_vector(mipi_lane_arr(2));
            mipi_lane_3 <= std_logic_vector(mipi_lane_arr(3));
            mipi_hs_valid <= '1';
            -- tb_compare_data is generated by logic. see port out_debug
            
--            -- tb_compare data is delayed by one clock 
--            if (y > 0) then -- if not first line
--                if ( x = 0 ) then 
--                    -- when first packet is outputted, 
--                    -- the last packet from previous line still have to be outputted              
--                    tb_gen_data <= std_logic_vector(image_array((IMG_WIDTH*RAW_BITDEPTH)/C_S_AXIS_TDATA_WIDTH)-1, y-1));
--                else 
--                    tb_gen_data <= std_logic_vector(image_array(x, y -1));
--                end if;
            
--            else -- First line
--                if (y = 0) then
--                    -- first packet, first line
--                    -- do nothing
--                else 
--                    tb_gen_data <= std_logic_vector(image_array(x, y -1));
--                end if;
            wait until rising_edge(mipi_hs_clk);
            			
        end loop;

        -- Footer
        mipi_lane_0 <= x"2C"; -- LSB 16 Bit CRC
        mipi_lane_1 <= x"40"; -- MSB 
        mipi_lane_2 <= x"00"; -- Nothing i guess?
        mipi_lane_3 <= x"00";
        mipi_hs_valid <= '1';
        
        wait until rising_edge(mipi_hs_clk);
        mipi_hs_valid <= '0';
        wait until rising_edge(mipi_hs_clk);      
    end loop;
    
	mipi_hs_valid <= '1';
	wait until rising_edge(mipi_hs_clk);		
	mipi_hs_valid <= '0';
	wait until rising_edge(mipi_hs_clk);		
	
	
	
	wait for 1000 ms;
end process;

	-- Instantiation of Axi Bus Interface S00_AXI
	dut : entity work.mipi_low_level
	generic map ( 
        BIT_DEPTH       => RAW_BITDEPTH,
        IMG_WIDTH       => IMG_WIDTH,
        IMG_HEIGHT      => IMG_HEIGHT
	port map (

		M_AXIS_ACLK		=> M_AXIS_ACLK,
		M_AXIS_ARESETN  => M_AXIS_ARESETN,
		M_AXIS_TVALID   => M_AXIS_TVALID,
		M_AXIS_TDATA    => M_AXIS_TDATA,
		M_AXIS_TUSER    => M_AXIS_TUSER,
		M_AXIS_TLAST    => M_AXIS_TLAST,
		M_AXIS_TREADY   => M_AXIS_TREADY,
	
		mipi_rstn		=> mipi_rstn,
		mipi_hs_clk		=> mipi_hs_clk,
		mipi_hs_valid	=> mipi_hs_valid,
		mipi_lane_0		=> mipi_lane_0,
		mipi_lane_1		=> mipi_lane_1,
		mipi_lane_2		=> mipi_lane_2,
		mipi_lane_3		=> mipi_lane_3,	
		mipi_phy_err	=> '0'
	);
	
	axi_rcv: entity work.axis_receiver
    generic map(
        IMG_VERTICAL            => IMG_HEIGHT            ,       
        IMG_HORIZONTAL            => IMG_WIDTH            ,     
        C_S_AXIS_TDATA_WIDTH    => C_S_AXIS_TDATA_WIDTH     ,     
        STREAM_TDATA_DELAY         => 1
    )
    port map(
        S_AXIS_ACLK               => M_AXIS_ACLK,
        S_AXIS_ARESETN           => M_AXIS_ARESETN,
        S_AXIS_TREADY           => M_AXIS_TREADY,
        S_AXIS_TVALID           => M_AXIS_TVALID,
        S_AXIS_TDATA           => M_AXIS_TDATA,
        --S_AXIS_TSTRB           =>
        --S_AXIS_TKEEP           =>
        S_AXIS_TUSER           => M_AXIS_TUSER,
        S_AXIS_TLAST           => M_AXIS_TLAST,
        --S_AXIS_TID             =>
        --S_AXIS_TDEST           =>
        generator_event        => tb_gen_event,
        generator_data         => tb_gen_data,
        wait_for_gen           => tb_wait_for_gen
       );  

end Behavioral;
