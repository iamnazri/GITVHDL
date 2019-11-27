----------------------------------------------------------------------------------
-- Company: avi-systems deutschland gmbh c 2019
-- Engineer: NAB
-- 
-- Create Date: 27.11.2019 14:00:43
-- Design Name: 
-- Module Name: bbox - Behavioral
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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity boundingbox_wrapper is
generic(
		S_AXIS_TDATA_WIDTH : integer := 24
);
port(	
		S_AXIS_ACLK	    	: in  std_logic;
        S_AXIS_ARESETN		: in  std_logic;		
        S_AXIS_TREADY		: out std_logic;
		S_AXIS_TVALID		: in  std_logic;
        S_AXIS_TDATA		: in  std_logic_vector(S_AXIS_TDATA_WIDTH-1 downto 0);
	    S_AXIS_TUSER    	: in  std_logic;
        S_AXIS_TLAST		: in  std_logic;
	
		M_AXIS_ACLK			: in std_logic;
		M_AXIS_ARESETN  	: in std_logic;
		M_AXIS_TVALID   	: out std_logic;
		M_AXIS_TDATA    	: out std_logic_vector(S_AXIS_TDATA_WIDTH-1 downto 0);
		M_AXIS_TLAST    	: out std_logic;
		M_AXIS_TUSER    	: out std_logic;
		M_AXIS_TREADY   	: in std_logic;
		
		-- Global Clock Signal
        S_AXI_ACLK          : in  std_logic;
        S_AXI_ARESETN       : in  std_logic;
        -- Write address
        S_AXI_AWADDR        : in  std_logic_vector(8-1 downto 0);
        S_AXI_AWVALID       : in  std_logic;
        S_AXI_AWPROT        : in  std_logic_vector(2 downto 0);
        S_AXI_AWREADY       : out std_logic;
        -- Write data
        S_AXI_WDATA         : in  std_logic_vector(32-1 downto 0);
        S_AXI_WSTRB         : in  std_logic_vector((32/8)-1 downto 0);
        S_AXI_WVALID        : in  std_logic;
        S_AXI_WREADY        : out std_logic;
        -- Write response.
        S_AXI_BRESP         : out std_logic_vector(1 downto 0);
        S_AXI_BVALID        : out std_logic;
        S_AXI_BREADY        : in  std_logic;

        -- Read address
        S_AXI_ARADDR        : in  std_logic_vector(8-1 downto 0); -- C_S_AXI_ADDR_WIDTH
        S_AXI_ARPROT        : in  std_logic_vector(2 downto 0);
        S_AXI_ARVALID       : in  std_logic;
        S_AXI_ARREADY       : out std_logic;
        -- Read data
        S_AXI_RDATA         : out std_logic_vector(32-1 downto 0); -- C_S_AXI_DATA_WIDTH
        S_AXI_RRESP         : out std_logic_vector(1 downto 0);
        S_AXI_RVALID        : out std_logic;
        S_AXI_RREADY        : in  std_logic
	    
);
end boundingbox_wrapper;

architecture rtl of boundingbox_wrapper is


	constant M_AXIS_TDATA_WIDTH : integer := 24;
	constant C_S_AXI_ADDR_WIDTH : integer := 8;
    constant C_S_AXI_DATA_WIDTH : integer := 32;

	signal b0_xpos, b0_ypos, b0_wdh, b0_hght, 
		b1_xpos, b1_ypos, b1_wdh, b1_hght, 
		b2_xpos, b2_ypos, b2_wdh, b2_hght, 
		b3_xpos, b3_ypos, b3_wdh, b3_hght
		: unsigned(11 downto 0);

	signal b0_prms, b1_prms, b2_prms, b3_prms : unsigned(31 downto 0);
	--signal box_rst, box_ctrl	: std_logic_vector(31 downto 0);		 
	signal img_width, img_height			: unsigned(15 downto 0);
	
	signal M_AXIS_TO_SECOND_BOX_TVALID   : std_logic;
	signal M_AXIS_TO_SECOND_BOX_TDATA    : std_logic_vector(S_AXIS_TDATA_WIDTH-1 downto 0);
    signal M_AXIS_TO_SECOND_BOX_TLAST    : std_logic; 
    signal M_AXIS_TO_SECOND_BOX_TUSER    : std_logic;
    signal M_AXIS_TO_SECOND_BOX_TREADY   : std_logic;
	signal M_AXIS_TO_THIRD_BOX_TVALID    : std_logic; 
	signal M_AXIS_TO_THIRD_BOX_TDATA     : std_logic_vector(S_AXIS_TDATA_WIDTH-1 downto 0);
	signal M_AXIS_TO_THIRD_BOX_TLAST     : std_logic;  
	signal M_AXIS_TO_THIRD_BOX_TUSER     : std_logic; 
	signal M_AXIS_TO_THIRD_BOX_TREADY    : std_logic; 
	signal M_AXIS_TO_FOURTH_BOX_TVALID   : std_logic; 
	signal M_AXIS_TO_FOURTH_BOX_TDATA    : std_logic_vector(S_AXIS_TDATA_WIDTH-1 downto 0);
	signal M_AXIS_TO_FOURTH_BOX_TLAST    : std_logic;  
	signal M_AXIS_TO_FOURTH_BOX_TUSER    : std_logic; 
	signal M_AXIS_TO_FOURTH_BOX_TREADY   : std_logic; 
	
	
begin


-- Instantiate 4 boxes
bbox_i0 : entity work.boundingbox
port map(
        S_AXIS_ACLK	     => S_AXIS_ACLK                  ,
		S_AXIS_ARESETN	 => S_AXIS_ARESETN               ,
		S_AXIS_TREADY	 => S_AXIS_TREADY	 ,
        S_AXIS_TVALID	 => S_AXIS_TVALID	            ,
        S_AXIS_TDATA	 => S_AXIS_TDATA	              ,
        S_AXIS_TUSER     => S_AXIS_TUSER                ,
        S_AXIS_TLAST	 => S_AXIS_TLAST	              ,
        M_AXIS_ACLK		 => M_AXIS_ACLK                  ,
        M_AXIS_ARESETN   => S_AXIS_ARESETN               ,
        M_AXIS_TVALID    => M_AXIS_TO_SECOND_BOX_TVALID  ,  
        M_AXIS_TDATA     => M_AXIS_TO_SECOND_BOX_TDATA   ,  
        M_AXIS_TLAST     => M_AXIS_TO_SECOND_BOX_TLAST   ,  
        M_AXIS_TUSER     => M_AXIS_TO_SECOND_BOX_TUSER   ,  
        M_AXIS_TREADY    => M_AXIS_TO_SECOND_BOX_TREADY  , 
		img_width_i		 => img_width,
		img_height_i	 => img_height,		
        box_xpos_i       => b0_xpos                      ,
        box_ypos_i       => b0_ypos                      ,
        box_wdh_i        => b0_wdh                       ,
        box_hgt_i        => b0_hght                      ,
        box_prms_i       => b0_prms                      
);

bbox_i1 : entity work.boundingbox
port map(
        S_AXIS_ACLK	     => S_AXIS_ACLK                   ,
		S_AXIS_ARESETN	 => S_AXIS_ARESETN                ,
		S_AXIS_TVALID 	 => M_AXIS_TO_SECOND_BOX_TVALID   , 
        S_AXIS_TDATA	 => M_AXIS_TO_SECOND_BOX_TDATA    , 
        S_AXIS_TLAST 	 => M_AXIS_TO_SECOND_BOX_TLAST    , 
        S_AXIS_TUSER     => M_AXIS_TO_SECOND_BOX_TUSER    ,   
        S_AXIS_TREADY 	 => M_AXIS_TO_SECOND_BOX_TREADY   ,
        M_AXIS_ACLK		 => M_AXIS_ACLK                   ,
        M_AXIS_ARESETN   => S_AXIS_ARESETN                ,
        M_AXIS_TVALID    => M_AXIS_TVALID     ,
        M_AXIS_TDATA     => M_AXIS_TDATA      ,
        M_AXIS_TLAST     => M_AXIS_TLAST      ,
        M_AXIS_TUSER     => M_AXIS_TUSER      ,
        M_AXIS_TREADY    => M_AXIS_TREADY     ,
		img_width_i		 => img_width,
		img_height_i	 => img_height,		
        box_xpos_i       => b1_xpos                       ,
        box_ypos_i       => b1_ypos                       ,
        box_wdh_i        => b1_wdh                        ,
        box_hgt_i        => b1_hght                       ,
        box_prms_i       => b1_prms                       
);

--bbox_i2 : entity work.boundingbox
--port map(
--        S_AXIS_ACLK	     => S_AXIS_ACLK                  ,
--		S_AXIS_ARESETN	 => S_AXIS_ARESETN               ,
--		S_AXIS_TVALID 	 => M_AXIS_TO_THIRD_BOX_TVALID   ,    
--        S_AXIS_TDATA	 => M_AXIS_TO_THIRD_BOX_TDATA    ,    
--        S_AXIS_TLAST 	 => M_AXIS_TO_THIRD_BOX_TLAST    ,    
--        S_AXIS_TUSER     => M_AXIS_TO_THIRD_BOX_TUSER    ,      
--        S_AXIS_TREADY 	 => M_AXIS_TO_THIRD_BOX_TREADY   ,   
--        M_AXIS_ACLK		 => M_AXIS_ACLK                  ,
--        M_AXIS_ARESETN   => S_AXIS_ARESETN               ,
--        M_AXIS_TVALID    => M_AXIS_TO_FOURTH_BOX_TVALID  ,  
--        M_AXIS_TDATA     => M_AXIS_TO_FOURTH_BOX_TDATA   ,  
--        M_AXIS_TLAST     => M_AXIS_TO_FOURTH_BOX_TLAST   ,  
--        M_AXIS_TUSER     => M_AXIS_TO_FOURTH_BOX_TUSER   ,  
--        M_AXIS_TREADY    => M_AXIS_TO_FOURTH_BOX_TREADY  , 
--		img_width_i		 => img_width,
--		img_height_i	 => img_height,		
--        box_xpos_i       => b2_xpos                      ,
--        box_ypos_i       => b2_ypos                      ,
--        box_wdh_i        => b2_wdh                       ,
--        box_hgt_i        => b2_hght                      ,
--        box_prms_i       => b2_prms                      
--);

--bbox_i3 : entity work.boundingbox
--port map(
--        S_AXIS_ACLK	     => S_AXIS_ACLK                  ,
--		S_AXIS_ARESETN	 => S_AXIS_ARESETN               ,
--		S_AXIS_TVALID 	 => M_AXIS_TO_FOURTH_BOX_TVALID  ,   
--        S_AXIS_TDATA	 => M_AXIS_TO_FOURTH_BOX_TDATA   ,   
--        S_AXIS_TLAST 	 => M_AXIS_TO_FOURTH_BOX_TLAST   ,   
--        S_AXIS_TUSER     => M_AXIS_TO_FOURTH_BOX_TUSER   ,     
--        S_AXIS_TREADY 	 => M_AXIS_TO_FOURTH_BOX_TREADY  ,  
--        M_AXIS_ACLK		 => M_AXIS_ACLK                  ,
--        M_AXIS_ARESETN   => S_AXIS_ARESETN               ,
--        M_AXIS_TVALID    => M_AXIS_TVALID                ,
--        M_AXIS_TDATA     => M_AXIS_TDATA                 ,
--        M_AXIS_TLAST     => M_AXIS_TLAST                 ,
--        M_AXIS_TUSER     => M_AXIS_TUSER                 ,
--        M_AXIS_TREADY    => M_AXIS_TREADY                ,
--		img_width_i		 => img_width,
--		img_height_i	 => img_height,		
--        box_xpos_i       => b3_xpos                      ,
--        box_ypos_i       => b3_ypos                      ,
--        box_wdh_i        => b3_wdh                       ,
--        box_hgt_i        => b3_hght                      ,
--        box_prms_i       => b3_prms                      
--);

axil_inst : entity work.boundingbox_axil
	generic map (
		C_S_AXI_DATA_WIDTH	=> C_S_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S_AXI_ADDR_WIDTH
	)
	port map (
		S_AXI_ACLK		=> S_AXI_ACLK,
		S_AXI_ARESETN	=> S_AXI_ARESETN,
		S_AXI_AWADDR	=> S_AXI_AWADDR,
		S_AXI_AWPROT	=> S_AXI_AWPROT,
		S_AXI_AWVALID	=> S_AXI_AWVALID,
		S_AXI_AWREADY	=> S_AXI_AWREADY,
		S_AXI_WDATA		=> S_AXI_WDATA,
		S_AXI_WSTRB		=> S_AXI_WSTRB,
		S_AXI_WVALID	=> S_AXI_WVALID,
		S_AXI_WREADY	=> S_AXI_WREADY,
		S_AXI_BRESP		=> S_AXI_BRESP,
		S_AXI_BVALID	=> S_AXI_BVALID,
		S_AXI_BREADY	=> S_AXI_BREADY,
		S_AXI_ARADDR	=> S_AXI_ARADDR,
		S_AXI_ARPROT    => S_AXI_ARPROT,
		S_AXI_ARVALID	=> S_AXI_ARVALID,
		S_AXI_ARREADY	=> S_AXI_ARREADY,
		S_AXI_RDATA		=> S_AXI_RDATA,
		S_AXI_RRESP		=> S_AXI_RRESP,
		S_AXI_RVALID	=> S_AXI_RVALID,
		S_AXI_RREADY	=> S_AXI_RREADY,
		in_pic_wdh	    => img_width,
        in_pic_hght	    => img_height,
		box0_x          => b0_xpos,
        box0_y          => b0_ypos,
        box0_w          => b0_wdh ,
        box0_h          => b0_hght,
        box1_x          => b1_xpos,
        box1_y          => b1_ypos,
        box1_w          => b1_wdh ,
        box1_h          => b1_hght,
        box2_x          => b2_xpos,
        box2_y          => b2_ypos,
        box2_w          => b2_wdh ,
        box2_h          => b2_hght,
		box3_x			=> b3_xpos,
		box3_y	        => b3_ypos,
		box3_w	        => b3_wdh ,
		box3_h	        => b3_hght,
		box0_prms       => b0_prms ,
		box1_prms       => b1_prms ,
		box2_prms       => b2_prms ,
		box3_prms       => b3_prms
		
	);
	
	
	
end rtl;
-- box0_x, box0_y,box0_w, box0_h, box1_x, box1_y, box1_w, box1_h, box2_x, box2_y, box2_w, box2_h
-- b0_xpos, b0_ypos, b0_wdh, b0_hght, b1_xpos, b1_ypos, b1_wdh, b1_hght, b2_xpos, b2_ypos, b2_wdh, b2_hght, b3_xpos, b3_ypos, b3_wdh, b3_hght, 

-- box0_r, box0_rin, box1_r, box1_rin, box2_r, box2_rin, box3_r, box3_rin, 