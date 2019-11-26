library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity boundingbox is
generic(
    	IMG_WIDTH 			: integer := 1920;
	    IMG_HEIGHT			: integer := 1080
);
port(	
		S_AXIS_ACLK	    	: in  std_logic;
        S_AXIS_ARESETN		: in  std_logic;		
        S_AXIS_TREADY		: out std_logic;
		S_AXIS_TVALID		: in  std_logic;
        S_AXIS_TDATA		: in  std_logic_vector(23 downto 0);
	    S_AXIS_TUSER    	: in  std_logic;
        S_AXIS_TLAST		: in  std_logic;
	
		M_AXIS_ACLK			: in std_logic;
		M_AXIS_ARESETN  	: in std_logic;
		M_AXIS_TVALID   	: out std_logic;
		M_AXIS_TDATA    	: out std_logic_vector(23 downto 0);
		M_AXIS_TLAST    	: out std_logic;
		M_AXIS_TUSER    	: out std_logic;
		M_AXIS_TREADY   	: in std_logic;
		
		-- Global Clock Signal
        S_AXI_ACLK          : in  std_logic;
        S_AXI_ARESETN       : in  std_logic;
        -- Write address
        S_AXI_AWADDR        : in  std_logic_vector(6-1 downto 0);
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
        S_AXI_ARADDR        : in  std_logic_vector(6-1 downto 0); -- C_S_AXI_ADDR_WIDTH
        S_AXI_ARPROT        : in  std_logic_vector(2 downto 0);
        S_AXI_ARVALID       : in  std_logic;
        S_AXI_ARREADY       : out std_logic;
        -- Read data
        S_AXI_RDATA         : out std_logic_vector(32-1 downto 0); -- C_S_AXI_DATA_WIDTH
        S_AXI_RRESP         : out std_logic_vector(1 downto 0);
        S_AXI_RVALID        : out std_logic;
        S_AXI_RREADY        : in  std_logic
		
	  
);
end boundingbox;

architecture rtl of boundingbox is

	constant S_AXIS_TDATA_WIDTH : integer := 24;
	constant M_AXIS_TDATA_WIDTH : integer := 24;
	constant C_S_AXI_ADDR_WIDTH : integer := 6;
    constant C_S_AXI_DATA_WIDTH : integer := 32;

	signal b0_xpos, b0_ypos, b0_wdh, b0_hght, 
		b1_xpos, b1_ypos, b1_wdh, b1_hght, 
		b2_xpos, b2_ypos, b2_wdh, b2_hght, 
		b3_xpos, b3_ypos, b3_wdh, b3_hght
		: unsigned(11 downto 0);

	signal b0_prms, b1_prms, b2_prms, b3_prms : std_logic_vector(31 downto 0) := x"000000FF";
	signal box_rst, box_ctrl	: std_logic_vector(31 downto 0);

	type state_t is (reset, init, drawBox, blocking);	
	type reg_bb	is record
	xpos                : unsigned(11 downto 0);
	ypos                : unsigned(11 downto 0);
	wdh                 : unsigned(11 downto 0);
	hght                : unsigned(11 downto 0);
	end record;
    
    type reg_0 is record
    tdata_in				: std_logic_vector(S_AXIS_TDATA_WIDTH-1 downto 0);
    tdata_out				: std_logic_vector(M_AXIS_TDATA_WIDTH-1 downto 0);
    tuser                   : std_logic;
    tlast                   : std_logic;
    m_tvalid                : std_logic;	
    m_tready				: std_logic;
    s_tvalid                 : std_logic;        
    s_tready                 : std_logic;
    state					: state_t;
	xpntr					: unsigned(11 downto 0);
	ypntr					: unsigned(11 downto 0);
    end record;
	
	constant dflt_reg_bb : reg_bb :=( 
	xpos               => to_unsigned(0, 12),
    ypos               => to_unsigned(0, 12),
	wdh                => to_unsigned(0, 12),
	hght               => to_unsigned(0, 12)
	);
    
    constant dflt_reg_0 : reg_0 :=(
    tdata_in			    => (others=> '0'),
    tdata_out	            => (others=> '0'),
    tuser                   => '0',
    tlast        		    => '0',
    m_tvalid       	        => '1',
    m_tready				=> '0',
    s_tvalid                 => '0',
    s_tready                 => '1',
    state					=> reset,
	xpntr					=> to_unsigned(0, 12),
	ypntr 					=> to_unsigned(0, 12)
    );
    
    signal r, rin : reg_0 := dflt_reg_0;	-- set by axi-lite 
	signal box0_r, box0_rin : reg_bb := dflt_reg_bb;
	signal box1_r, box1_rin : reg_bb := dflt_reg_bb;
	signal box2_r, box2_rin : reg_bb := dflt_reg_bb;
	signal box3_r, box3_rin : reg_bb := dflt_reg_bb;


begin

comb : process(r, rin, box_rst, box_ctrl,
		box0_r, box0_rin, box1_r, box1_rin, 
		box2_r, box2_rin, box3_r, box3_rin, 
		b0_xpos, b0_ypos, b0_wdh, b0_hght, 
		b1_xpos, b1_ypos, b1_wdh, b1_hght, 
		b2_xpos, b2_ypos, b2_wdh, b2_hght, 
		b3_xpos, b3_ypos, b3_wdh, b3_hght,
        S_AXIS_TVALID, S_AXIS_TDATA, S_AXIS_TUSER ,   
        S_AXIS_TLAST, M_AXIS_TREADY)
variable v 						: reg_0;
variable box0, box1, box2, box3 : reg_bb;
begin

	v := r;
	box0 := box0_r;
	box1 := box1_r;
	box2 := box2_r;
	box3 := box3_r;
	
	-- Forward ready and valid signals. 
	v.tdata_in := S_AXIS_TDATA; 
	v.tuser := S_AXIS_TUSER;
	v.tlast := S_AXIS_TLAST;
	v.m_tready := M_AXIS_TREADY;
	v.s_tvalid := S_AXIS_TVALID;
	
	-- Get box coordinates and size
	box0.xpos := b0_xpos;
	box0.ypos := b0_ypos; 
	box0.wdh  := b0_wdh;
	box0.hght := b0_hght;
	box1.xpos := b1_xpos;
	box1.ypos := b1_ypos; 
	box1.wdh  := b1_wdh;
	box1.hght := b1_hght;
	box2.xpos := b2_xpos;
	box2.ypos := b2_ypos; 
	box2.wdh  := b2_wdh;
	box2.hght := b2_hght;
	box3.xpos := b3_xpos;
	box3.ypos := b3_ypos; 
	box3.wdh  := b3_wdh;
	box3.hght := b3_hght;
	
	
	case v.state is
	when reset =>
		v.state := init;	
	
	when init =>
		if (v.s_tvalid = '1' and v.m_tready = '1') then
			if v.tuser = '1' then
				v.state := drawBox;
				v.tdata_out := v.tdata_in;
				-- Start from zero-th line
				v.xpntr := to_unsigned(0, 12);
				v.ypntr := to_unsigned(0, 12); 
                v.m_tvalid := '1';
                v.s_tready := '1';
			else 
			end if;
        else 
            v.m_tvalid := '0';
            v.s_tready := '0';
		end if;
	
	when drawBox =>
		if (v.s_tvalid = '1' and v.m_tready = '1') then
			-- pixel per pixel transmission
			-- Pixel substitution. First determine top line pos
			if v.tlast = '0' then
				 
				-- Draw along the top/bottom line
				if ((v.ypntr = box0.ypos) or (v.ypntr = box0.ypos + box0.hght))  then
					if (v.xpntr >= box0.xpos) AND (v.xpntr <= box0.xpos + box0.wdh) then
						-- Replace pixels in the top line 
						v.tdata_out := b0_prms(7 downto 0) & b0_prms(7 downto 0) & b0_prms(7 downto 0);
					else 
						v.tdata_out := v.tdata_in;
					end if;
					
				-- Draw along the left and right vertical line
				elsif ((v.ypntr >= box0.ypos) AND (v.ypntr <= box0.ypos + box0.hght)) then
					if ((v.xpntr = box0.xpos) or (v.xpntr = box0.xpos + box0.wdh)) then
						v.tdata_out := b0_prms(7 downto 0) & b0_prms(7 downto 0) & b0_prms(7 downto 0);
					else 
						v.tdata_out := v.tdata_in;
					end if;
				
				else 
					v.tdata_out := v.tdata_in;
				end if;
				
				-- Increment pointer to the next pixel
				v.xpntr := v.xpntr + 1;
				
			-- last pixel
			elsif v.tlast = '1' then
				v.xpntr := to_unsigned(0, 12);
				v.ypntr := v.ypntr + 1;
				v.tdata_out := v.tdata_in;

			end if;
			
		else 
			v.state := blocking;
            v.m_tvalid := '0';
            v.s_tready := '0';
        end if;
		
	when blocking =>
		if (v.s_tvalid = '1' and v.m_tready = '1') then
            if (v.tuser = '1') then
			    v.state := drawBox;
				v.m_tvalid := '1';
                v.s_tready := '1';
			end if;
		else 
			-- what to do in the blockng state
		end if;
	
	end case;
	
	
	
	rin <= v;
	box0_rin <= box0; 
	box1_rin <= box1; 
	box2_rin <= box2; 
	box3_rin <= box3; 
	
	
	M_AXIS_TVALID <= r.m_tvalid;
	S_AXIS_TREADY <= r.s_tready;
	M_AXIS_TLAST  <= r.tlast;
	M_AXIS_TUSER  <= r.tuser;
	M_AXIS_TDATA  <= r.tdata_out;

end process;

seq: process(S_AXIS_ACLK, S_AXIS_ARESETN)
begin
    if rising_edge(S_AXIS_ACLK) then
	   if (S_AXIS_ARESETN = '0') then
            r <= dflt_reg_0;
            box0_r <= dflt_reg_bb;
            box1_r <= dflt_reg_bb;
            box2_r <= dflt_reg_bb;
            box3_r <= dflt_reg_bb;
	   else 
            r <= rin;
            box0_r <= box0_rin ; 
            box1_r <= box1_rin ; 
            box2_r <= box2_rin ; 
            box3_r <= box3_rin ; 
	   end if;	
   end if;
end process;

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
		box_ctrl		=> box_ctrl,
		box_rst			=> box_rst,
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
        box2_h          => b2_hght
		
	);
	
end rtl;
-- box0_x, box0_y,box0_w, box0_h, box1_x, box1_y, box1_w, box1_h, box2_x, box2_y, box2_w, box2_h
-- b0_xpos, b0_ypos, b0_wdh, b0_hght, b1_xpos, b1_ypos, b1_wdh, b1_hght, b2_xpos, b2_ypos, b2_wdh, b2_hght, b3_xpos, b3_ypos, b3_wdh, b3_hght, 

-- box0_r, box0_rin, box1_r, box1_rin, box2_r, box2_rin, box3_r, box3_rin, 