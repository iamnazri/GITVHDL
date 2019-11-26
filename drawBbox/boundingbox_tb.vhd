----------------------------------------------------------------------------------
-- Company: avi-systems deutschland
-- Engineer: NAB
-- 
-- Create Date: 22.11.2019 15:30:00
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

library work;
use work.NABtb_pkg.all;

entity boundingbox_tb is
end boundingbox_tb;

architecture behaviour of boundingbox_tb is

	constant IMG_WIDTH		        : natural   := 320;
    constant IMG_HEIGHT             : natural   := 320;
	constant S_AXIS_TDATA_WIDTH : integer := 24;
	constant M_AXIS_TDATA_WIDTH : integer := 24;
	constant C_S_AXI_DATA_WIDTH : integer := 32;
	constant C_S_AXI_ADDR_WIDTH : integer := 6;
	
	signal S_AXIS_ACLK	    	: std_logic;
	signal S_AXIS_ARESETN		: std_logic;		
	signal S_AXIS_TREADY		: std_logic;
	signal S_AXIS_TVALID		: std_logic;
	signal S_AXIS_TDATA			: std_logic_vector(S_AXIS_TDATA_WIDTH-1 downto 0);
	signal S_AXIS_TUSER    		: std_logic;
	signal S_AXIS_TLAST			: std_logic;
	signal M_AXIS_ACLK			: std_logic;
	signal M_AXIS_ARESETN  		: std_logic;
	signal M_AXIS_TVALID   		: std_logic;
	signal M_AXIS_TDATA    		: std_logic_vector(M_AXIS_TDATA_WIDTH-1 downto 0);
	signal M_AXIS_TLAST    		: std_logic;
	signal M_AXIS_TUSER    		: std_logic;
	signal M_AXIS_TREADY   		: std_logic;

	signal S_AXI_ACLK            : std_logic;
	signal S_AXI_ARESETN         : std_logic;
	signal S_AXI_AWADDR          : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
	signal S_AXI_AWVALID         : std_logic;
	signal S_AXI_AWPROT          : std_logic_vector(2 downto 0);
	signal S_AXI_AWREADY         : std_logic;
	signal S_AXI_WDATA           : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal S_AXI_WSTRB           : std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
	signal S_AXI_WVALID          : std_logic;
	signal S_AXI_WREADY          : std_logic;
	signal S_AXI_BRESP           : std_logic_vector(1 downto 0);
	signal S_AXI_BVALID          : std_logic;
	signal S_AXI_BREADY          : std_logic;
	signal S_AXI_ARADDR          : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
	signal S_AXI_ARPROT          : std_logic_vector(2 downto 0); 
	signal S_AXI_ARVALID         : std_logic;
	signal S_AXI_ARREADY         : std_logic;
	signal S_AXI_RDATA           : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal S_AXI_RRESP           : std_logic_vector(1 downto 0);
	signal S_AXI_RVALID          : std_logic;
	signal S_AXI_RREADY          : std_logic;
	
	signal tb_gen_event          : std_logic;                                       
	signal tb_gen_data           : std_logic_vector(M_AXIS_TDATA_WIDTH-1 downto 0); 
	signal tb_wait_for_gen       : std_logic;               
	                          
	
begin

process
begin
	M_AXIS_ACLK <= '0';
	S_AXIS_ACLK <= '0';
	wait for 5 ns;
	M_AXIS_ACLK <= '1';
	S_AXIS_ACLK <= '1';
	wait for 5 ns;	
end process;

process
begin
    
	S_AXI_ACLK <= '0';
	wait for 5 ns;
	S_AXI_ACLK <= '1';
	wait for 5 ns;	
end process;

process 
begin

-----------------------------
                           
-----         INITIALIZATION   
                           
-----------------------------
    S_AXI_ARESETN  <= '0';
	S_AXIS_ARESETN <= '0';
	M_AXIS_ARESETN <= '0';
	
	S_AXI_ARADDR  <= (others=> '0');
	S_AXI_AWADDR  <= (others=> '0');
	S_AXI_AWPROT  <= (others=> '0');
	S_AXI_WSTRB   <= (others=> '0');
	S_AXI_RRESP   <= (others=> '0');
	S_AXI_BRESP   <= (others=> '0');
	S_AXI_WDATA   <= (others=> '0');
	S_AXI_RDATA   <= (others=> '0');
	
	-- Testbench does not read or write
	S_AXI_AWVALID <= '0';
	S_AXI_ARVALID <= '0';
	S_AXI_RREADY  <= '0'; 
	S_AXI_WVALID  <= '0';
	S_AXIS_TUSER  <= '0';
	S_AXIS_TLAST  <= '0';
	S_AXI_BREADY <= '0';
	S_AXI_ARPROT <= b"000";
	S_AXI_AWPROT <= b"000";
	S_AXIS_TDATA <= (others=> '0');
	--S_AXI_ARADDR  <= (others => '0');
	--S_AXIS_TVALID <= '0';
   --M_AXIS_TREADY <= '0';
	
-----------------------------
                               
-----         TEST START   
                               
-----------------------------	
	
	
	wait for 100 ns;
	wait until rising_edge(S_AXIS_ACLK);
	S_AXI_ARESETN  <= '1';
	S_AXIS_ARESETN <= '1';
	M_AXIS_ARESETN <= '1';
	wait_clk(S_AXI_ACLK, 7);    
	
    -- Load axi-lite register
    -- S_AXI_WDATA = x"00000001" to turn on decompanding
    S_AXI_AWPROT <= b"000"; -- awp[0] = 0 inpriviledged access
                            -- awp[1] = 0 secure access
                           -- awp[2] = data access
    

    -- Write XPOS
	S_AXI_AWADDR <= b"000000";
    S_AXI_AWVALID <= '1';
    S_AXI_WVALID <= '1';
    S_AXI_WSTRB <= b"1111"; 
    S_AXI_WDATA <= x"00000020";
    S_AXI_BREADY <= '1'; -- expect response from axilite
    wait_clk(S_AXI_ACLK, 2);
    S_AXI_AWVALID <= '0';
    S_AXI_WVALID  <= '0';
    S_AXI_WSTRB <= b"0000"; 
    wait_clk(S_AXI_ACLK, 1);
    S_AXI_BREADY <= '0';
    wait_clk(S_AXI_ACLK, 15);
    
    -- Write ypos
	S_AXI_AWADDR <= b"000100";
    S_AXI_AWVALID <= '1';
    S_AXI_WVALID <= '1';
    S_AXI_WSTRB <= b"1111"; 
    S_AXI_WDATA <= x"00000025";
    S_AXI_BREADY <= '1'; -- expect response from axilite
    wait_clk(S_AXI_ACLK, 2);
    S_AXI_AWVALID <= '0';
    S_AXI_WVALID  <= '0';
    S_AXI_WSTRB <= b"0000"; 
    wait_clk(S_AXI_ACLK, 1);
    S_AXI_BREADY <= '0';
    wait_clk(S_AXI_ACLK, 15);
    
    -- Write width
    S_AXI_AWADDR <= b"001000";
    S_AXI_AWVALID <= '1';
    S_AXI_WVALID <= '1';
    S_AXI_WSTRB <= b"1111"; 
    S_AXI_WDATA <= x"00000010"; -- 
    S_AXI_BREADY <= '1'; -- expect response from axilite
    wait_clk(S_AXI_ACLK, 2);
    S_AXI_AWVALID <= '0';
    S_AXI_WVALID  <= '0';
    S_AXI_WSTRB <= b"0000"; 
    wait_clk(S_AXI_ACLK, 1);
    S_AXI_BREADY <= '0';
    wait_clk(S_AXI_ACLK, 15);
    
    -- Write height
    S_AXI_AWADDR <= b"001100";
    S_AXI_AWVALID <= '1';
    S_AXI_WVALID <= '1';
    S_AXI_WSTRB <= b"1111"; 
    S_AXI_WDATA <= x"00000005";
    S_AXI_BREADY <= '1'; -- expect response from axilite
    wait_clk(S_AXI_ACLK, 2);
    S_AXI_AWVALID <= '0';
    S_AXI_WVALID  <= '0';
    S_AXI_WSTRB <= b"0000"; 
    wait_clk(S_AXI_ACLK, 1);
    S_AXI_BREADY <= '0';
    wait_clk(S_AXI_ACLK, 15);
    
	
	-- Handshake 
	S_AXIS_TVALID <= '1';
	M_AXIS_TREADY <= '1';
	wait_clk(S_AXI_ACLK, 2);
	
	
	
	for i in 1 to IMG_HEIGHT loop
	   S_AXIS_TUSER  <= '1';
	   
	   for j in 1 to IMG_WIDTH loop
	       S_AXIS_TDATA <= std_logic_vector(to_unsigned(j,24));
	       wait_clk(S_AXIS_ACLK, 1);
	       if (j = 1 ) then
	           S_AXIS_TUSER  <= '0';
           end if;
	   end loop;
	   
        S_AXIS_TLAST  <= '1';
        wait_clk(S_AXIS_ACLK, 1);
        S_AXIS_TLAST  <= '0';
   end loop;
	
	wait until rising_edge(S_AXIS_ACLK);
	S_AXIS_TUSER  <= '0';
	
	-- 
	
	wait;


end process;

	dut : entity work.boundingbox
	generic map(
	       IMG_WIDTH           =>  IMG_WIDTH,
	       IMG_HEIGHT          =>  IMG_HEIGHT
	)
	port map(   
            
            S_AXIS_ACLK	       =>   S_AXIS_ACLK	   ,
            S_AXIS_ARESETN	   =>   S_AXIS_ARESETN	,
            S_AXIS_TREADY	   =>   S_AXIS_TREADY	,	
            S_AXIS_TVALID	   =>   S_AXIS_TVALID	,	
            S_AXIS_TDATA	   =>   S_AXIS_TDATA	,		
            S_AXIS_TUSER       =>   S_AXIS_TUSER   ,
            S_AXIS_TLAST	   =>   S_AXIS_TLAST	,		
            M_AXIS_ACLK		   =>   M_AXIS_ACLK		,	
            M_AXIS_ARESETN     =>   M_AXIS_ARESETN ,
            M_AXIS_TVALID      =>   M_AXIS_TVALID  ,
            M_AXIS_TDATA       =>   M_AXIS_TDATA   ,
            M_AXIS_TLAST       =>   M_AXIS_TLAST   ,
            M_AXIS_TUSER       =>   M_AXIS_TUSER   ,
            M_AXIS_TREADY      =>   M_AXIS_TREADY  ,
                                                     
            S_AXI_ACLK         =>   S_AXI_ACLK     ,
            S_AXI_ARESETN      =>   S_AXI_ARESETN  ,
            S_AXI_AWADDR       =>   S_AXI_AWADDR   ,
            S_AXI_AWVALID      =>   S_AXI_AWVALID  ,
            S_AXI_AWPROT       =>   S_AXI_AWPROT   ,
            S_AXI_AWREADY      =>   S_AXI_AWREADY  ,
            S_AXI_WDATA        =>   S_AXI_WDATA    ,
            S_AXI_WSTRB        =>   S_AXI_WSTRB    ,
            S_AXI_WVALID       =>   S_AXI_WVALID   ,
            S_AXI_WREADY       =>   S_AXI_WREADY   ,
            S_AXI_BRESP        =>   S_AXI_BRESP    ,
            S_AXI_BVALID       =>   S_AXI_BVALID   ,
            S_AXI_BREADY       =>   S_AXI_BREADY   ,
            S_AXI_ARADDR       =>   S_AXI_ARADDR   ,
            S_AXI_ARPROT       =>   S_AXI_ARPROT   ,
            S_AXI_ARVALID      =>   S_AXI_ARVALID  ,
            S_AXI_ARREADY      =>   S_AXI_ARREADY  ,
            S_AXI_RDATA        =>   S_AXI_RDATA    ,
            S_AXI_RRESP        =>   S_AXI_RRESP    ,
            S_AXI_RVALID       =>   S_AXI_RVALID   ,
            S_AXI_RREADY       =>   S_AXI_RREADY   
            
);


	axi_rcv: entity work.axis_receiver
    generic map(
        IMG_VERTICAL            => IMG_HEIGHT            ,       
        IMG_HORIZONTAL            => IMG_WIDTH            ,     
        C_S_AXIS_TDATA_WIDTH    => S_AXIS_TDATA_WIDTH     ,     
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
	   
end behaviour;