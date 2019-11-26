-- Motivation
	-- For good analysis, waveform should dislay a series of numbers, in which its validity 
	-- is easily discernable by one glance. For example an icreasing set of numbers from 1 to x 
	-- can easily tell, whether the transmission has occured correctly.
	-- 
	-- (STIMULI) path: gen_tb -> Module -> axis_rcv
    -- How can i write an incrementing numbers to the 4 x mipi lane, 
    -- in a way that the module-under-test can rearrage the output correctly according 
    -- to the mipi specs.
	--  Requirements:
	
	
	
	
	-- (CONTROL) path: gen_tb -> axis_rcv
	-- How do I make sure that the module-under-test outputs the correct value and number 
	-- of packets over the streaming axis
	-- Requirements:
	
-- This testbench was written under several assumptions
	-- 1. Data input and data output has an indefinite no of delays (FIFO lol)
	-- 2. Mipi_lane has 8 bit of width
	-- 3. 4x Mipi_Lane
	-- 4. User has >120 IQ lol jk 
	-- 5. Data on 4x mipi_lanes are rearranged according to mipi csi-2  RAW12 format pg 93
	-- 6. No delay during the read process
	
-- Refer to tb_notes
-- Summary: 
	-- Since the pixel information has a width of 12-bits, the mipi spec packs the information
	-- into 8 bit and 4 bit slices. Refer to image in tb_notes. 
	-- After every 2x 8-bit slices, 2x slice of 4 bits appear. It sums to 24 bits of data. 
	-- This pattern repeats itself until all information is transmitted.
	-- For every 3 Mipi packets, 2 pixels are transmitted. 
	-- 
	-- My solution for data input in tb:
	-- tdata has 16 bits of width. 24 is not divisible by 16. 
	-- It is therefore useful to choose a number which is divisible by both numbers 
	-- for the algorithm of the data input. Furthermore, the streaming data is constructed from 
	-- 4 x mipi lanes, in which the sum of bits transmitted per mipi clock amounts to 32.
	-- Therefore, I chose to group the mipi slices into 32 bits of information. In this case,
	-- the group has three different structure. This structure repeats itself every 32*3= 96 bits. 
	-- count the index of of the first mipi packets for each 4 mipi packets
	-- One group is further divided into 8 bit slices, which carry different bits of the 12 bit pixel data
	-- See code for more detailed information
	


-- Signal Checklist (besides the typical ones like clk and stuff)
	-- 1. A set of numbers as data input (STIMULI
	-- 		variable pixel         : array1d_t(0 to IMG_WIDTH) ;   
	--		type array1d_t is array ( natural range<> ) of std_logic_vector(11 downto 0);
	
	-- 1a. A counter to iterate the pixel array to load the correct number into the mipi slices
	--		variable pkt            : integer := 1;
	
	-- 2. A counter for the 32 bit group
	--		variable lmipi          : integer := 0; 
	
	-- 3. The same set of numbers as control to the data input.
	--		signal tb_gen_data     : std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
	

-- Algorithm (VHDL)

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity dein_NTT is
end dein_NTT;

architecture testbench of dein_NTT is

	-- MIPI Signals
	-- M_AXIS_Signals
	
	-- Constants
	constant IMG_WIDTH				: integer 		:= 	
	constant IMG_HEIGHT             : integer 		:= 	
	constant AXIS_TDATA_WIDTH       : integer 		:= 	
	constant RAW12_BIT              : integer 		:= 	
	
	-- alg signals
	variable pixel         : array1d_t(0 to IMG_WIDTH) ;   
	type array1d_t is array ( natural range<> ) of std_logic_vector(11 downto 0);	
	
	signal tb_gen_data     : std_logic_vector(AXIS_TDATA_WIDTH-1 downto 0);
	signal start_tnsfer    : std_logic := '0';

begin

--mipi clk process 
-- axi aclock process

start_tnsfer <= '1' when M_AXIS_TVALID = '1';


-- CONTROL Data Generation
gen_Data: process (M_AXIS_ACLK)
begin
    tb_gen_data <= std_logic_vector(to_unsigned(spkt_cnt, 16));

    if ( start_tnsfer = '1') then
        
        if (M_AXIS_ACLK = '0' and M_AXIS_ACLK'event) then
            
            if (M_AXIS_TVALID = '1') then
                spkt_cnt <= spkt_cnt + 1;   -- counter aka. data from generator module for comparison 
                tb_gen_event <= '1';		-- used by rcvr module to 
			else	
				tb_gen_event <= '0';
            end if;
			
			-- Reset counter here
			
			-- reset counter here
        end if;
    end if;
end process;


-- STIMULI Data Generation
    for no in 1 to IMG_WIDTH loop 
        pixel(no)(11 downto 0) := std_logic_vector(to_unsigned(no, 12));
    end loop;
	
-- STIMULI Data Input
	
	-- First, input header
	-- Calculate WC in header ( WC is the official name but practically it is 
	-- a counter for no of bytes (8 bit)
	-- with the following formula:
	-- WC = ((No.of.Pixel.in.a.line * No.of.bits.in.one.pixel)/Width.of.tdata)*2
	-- (No.of.Pixel.in.a.line * No.of.bits.in.one.pixel) = Sum number of bits in a line
	-- (Sum.no.of.bits.in.a.line/Width.of.tdata) = Sum.no.of.SAXI.packets.to.be.transmitted.in.a.line
	-- No.of.SAXI.packets.to.be.transmitted.in.a.line*2 = Sum.No.of.byte.to.be.transmitted
	
		mipi_lane_0 <= x"2C";
		mipi_lane_1 <= std_logic_vector(to_unsigned(WC,16)(7 downto 0));
		mipi_lane_2 <= std_logic_vector(to_unsigned(WC,16)(15 downto 8));
		mipi_lane_3 <= x"55";
		mipi_hs_valid <= '1';
		wait until rising_edge(mipi_hs_clk); 
	
	
	-- Second, actual data input. Nest this into a for-loop to test further lines.
    -- While loop iterates over every three 8 bit mipi slices using pkt.
	-- At the end of a loop, pkt would have been incremented too often. 
	-- This is because pkt does not denote the number of mipi slices, but instead the pixel cnt.
	-- Since the pixel is transmitted in two mipi slices, a convention is needed to apply some sort of algorithm.
    -- pkt refers to the index of first 8 bits in a series of 4 8 bits pixels~ thus !!!!!byte count!!!!! (important)
    -- Packets stream = { P1, P2, (p2|p1), P3, |||| P4, (p4|p3), P5, P6, |||| (p6|p5), P7, P8, (p8|p7) ||||... }

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
                    pkt := pkt - 1; -- for every loop, byte count index reduces to 1
                when others =>
                    assert lmipi < 3 report "Mipi counter corrupt" severity failure;
                end case;
            lmipi := lmipi + 1;          
            pkt := pkt + 3;
            wait until rising_edge(mipi_hs_clk);
            
        end loop;

	-- Footer ( should contain checksum but not implemented by the module soooooo 
		mipi_lane_0 <= x"2C"; -- LSB 16 Bit CRC
        mipi_lane_1 <= x"40"; -- MSB 
        mipi_lane_2 <= x"00"; -- Nothing i guess?
        mipi_lane_3 <= x"00";
        mipi_hs_valid <= '1';
		wait until rising_edge(mipi_hs_clk);
        mipi_hs_valid <= '0';
		
		
	-- After one line has ended, prepare for repeated input of tdata 
		-- Therefore, reset tdata counter for STIMULI directly after footer
		pkt := 1; 
		
		-- Also reset tdata counter for CONTROL
		-- Reset strt_trnsfer 
		if (M_AXIS_TLAST = '1') then
			spkt_cnt <=  1;
		end if;
		
		-- Ensure that the counter on the receiving side is also resetted
		if (S_AXIS_TLAST = '1') then
			cnt_data <= to_unsigned(1, cnt_data'length);
		end if;
		
		
