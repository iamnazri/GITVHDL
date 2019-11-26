----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07.10.2019 09:17:43
-- Design Name: 
-- Module Name: mipi_low_level_tb - Behavioral
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

library std;
use std.textio.all;

library osvvm;
use osvvm.SortListPkg_int.vhd;

entity mipi_tb is
end mipi_tb;


architecture Behavioral of mipi_tb is

	constant IMG_WIDTH		        : natural   := 1920;
    constant IMG_HEIGHT             : natural   := 1080;
    constant C_S_AXIS_TDATA_WIDTH   : integer   := 16;
    constant RAW_BITDEPTH           : integer   := 12;
    type array1d_t is array ( natural range<> ) of std_logic_vector(11 downto 0);

    
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
	signal tb_gen_cnt      : unsigned(11 downto 0);
	signal tb_gen_event    : std_logic;
	signal spkt_cnt        : integer := 1;  
	signal tb_wait_for_gen : std_logic;
	signal start_tnsfer    : std_logic := '0';
	signal tvalid          : unsigned(2 downto 0);
	constant total_packet  : integer := (IMG_WIDTH*RAW_BITDEPTH)/C_S_AXIS_TDATA_WIDTH;      -- current resolution (11 downto 0) = 4095
	                                                                                        -- total packet in a line
	
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
start_tnsfer <= '1' when M_AXIS_TVALID = '1';


gen_Data: process (M_AXIS_ACLK)
begin
    tb_gen_data <= std_logic_vector(to_unsigned(spkt_cnt, 16));

    if ( start_tnsfer = '1') then
        
        if (M_AXIS_ACLK = '0' and M_AXIS_ACLK'event) then
            
            if (M_AXIS_TVALID = '1') then
                spkt_cnt <= spkt_cnt + 1;
                tb_gen_event <= '1';
			else	
				tb_gen_event <= '0';
            end if;
            
            if (M_AXIS_TLAST = '1') then
                spkt_cnt <= 1;
            end if;
        end if;
    end if;
end process;

process		--input
variable pixel         : array1d_t(0 to IMG_WIDTH) ;   
variable lmipi          : integer := 0; 
variable pkt            : integer := 1; -- pixel no indexing
variable newx           : unsigned(11 downto 0) := to_unsigned(0, 12); 

begin

    mipi_hs_valid <= '0';
	mipi_lane_0 <= (others=>'0');
	mipi_lane_1 <= (others=>'0');
	mipi_lane_2 <= (others=>'0');
	mipi_lane_3 <= (others=>'0');
	wait for 200 ns;

    -- how can i write an incrementing numbers to the 4 x mipi lane, 
    -- in a way that the module can rearrage the output correctly according 
    -- to the mipi specs so that an ascending set number is outputted
    
   
   -- Load number of pixel in a line for bit-wise access to said number in the coming loop
    for no in 1 to IMG_WIDTH loop 
        pixel(no)(11 downto 0) := std_logic_vector(to_unsigned(no, 12));
    end loop;
    
        --packet header - frame start
    mipi_lane_0 <= x"00";
    mipi_lane_1 <= x"01";
    mipi_lane_2 <= x"02";
    mipi_lane_3 <= x"03";
    mipi_hs_valid <= '1';
    wait until rising_edge(mipi_hs_clk);            
    mipi_hs_valid <= '0';
    wait until rising_edge(mipi_hs_clk);  
    wait until rising_edge(mipi_hs_clk);  
    
    -- Delay
	for i in 0 to 50 loop
        wait until rising_edge(mipi_hs_clk);
    end loop;
    
    -- Load number into mipi lanes
    for y in 0 to IMG_HEIGHT-1 loop
    --simulate start of line aka. Header
    mipi_lane_0 <= x"2C";
    --mipi_lane_1 <= x"40"; 
    --mipi_lane_2 <= x"0b"
    mipi_lane_1 <= std_logic_vector(to_unsigned(total_packet*2,16)(7 downto 0));
    mipi_lane_2 <= std_logic_vector(to_unsigned(total_packet*2,16)(15 downto 8));
    mipi_lane_3 <= x"55";
    mipi_hs_valid <= '1';
    wait until rising_edge(mipi_hs_clk);   
    
    -- While loop iterates over every three 8 bit mipi slices using pkt.
    -- At the end of a loop, pkt would have been incremented too often. 
    -- This is because pkt does not denote the number of mipi slices, but instead the pixel cnt.
    -- Since the pixel is transmitted in two mipi slices, a convention is needed to apply some sort of algorithm.
    -- In other words, pkt refers to the index of first 8 bits in a series of 4 8 bits pixels.
    -- Packets stream = { P1, P2, (p2|p1), P3, |||| P4, (p4|p3), P5, P6, |||| (p6|p5), P7, P8, (p8|p7) ||||... }
    -- See mipi spec pg 93
    -- lmipi = { 0, 1 , 2} , pkt = { 1 , 4, 7, 9, 12, 15, 17 ...}
        while ( pkt < IMG_WIDTH+1) loop
            case lmipi is
                when 0 => 
                    mipi_lane_0 <= pixel(pkt)(11 downto 4);
                    mipi_lane_1 <= pixel(pkt+1)(11 downto 4);
                    mipi_lane_2(7 downto 4) <= pixel(pkt+1)(3 downto 0); -- Byte values transmitted LS Bit first. see spec pg.93
                    mipi_lane_2(3 downto 0) <= pixel(pkt)(3 downto 0);
                    mipi_lane_3 <= pixel(pkt+2)(11 downto 4);
                when 1 => 
                    mipi_lane_0 <= pixel(pkt)(11 downto 4);
                    mipi_lane_1(7 downto 4) <= pixel(pkt)(3 downto 0);
                    mipi_lane_1(3 downto 0) <= pixel(pkt-1)(3 downto 0);
                    mipi_lane_2 <= pixel(pkt+1)(11 downto 4);
                    mipi_lane_3 <= pixel(pkt+2)(11 downto 4);
                when 2 => 
                    mipi_lane_0(7 downto 4) <= pixel(pkt-1)(3 downto 0);
                    mipi_lane_0(3 downto 0) <= pixel((pkt-2))(3 downto 0);
                    mipi_lane_1 <= pixel(pkt)(11 downto 4);
                    mipi_lane_2 <= pixel(pkt+1)(11 downto 4);
                    mipi_lane_3(7 downto 4) <= pixel(pkt+1)(3 downto 0);
                    mipi_lane_3(3 downto 0) <= pixel(pkt)(3 downto 0);
                    lmipi := -1;
                    pkt := pkt - 1; -- for every loop, index increment over the series reduces to 1
                when others =>
                    assert lmipi < 3 report "Mipi counter corrupt" severity failure;
                end case;
            lmipi := lmipi + 1;          
            pkt := pkt + 3;
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
        
        
        -- Delay
        for i in 0 to 50 loop
            wait until rising_edge(mipi_hs_clk);
        end loop;     
        
        pkt := 1;
        
        -- For testing
        if ( y mod 5 = 0) then 
            mipi_lane_0 <= x"00";
            mipi_lane_1 <= x"01";
            mipi_lane_2 <= x"02";
            mipi_lane_3 <= x"03";
            mipi_hs_valid <= '1';
            wait until rising_edge(mipi_hs_clk);            
            mipi_hs_valid <= '0';
            wait until rising_edge(mipi_hs_clk);  
            wait until rising_edge(mipi_hs_clk);  
        end if;
        
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
    )
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
