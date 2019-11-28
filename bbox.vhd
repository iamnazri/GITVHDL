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

entity boundingbox is
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
		
		img_width_i			: in unsigned(15 downto 0);
		img_height_i		: in unsigned(15 downto 0);
		box_xpos_i          : in unsigned(11 downto 0);
		box_ypos_i          : in unsigned(11 downto 0);
		box_wdh_i           : in unsigned(11 downto 0);
		box_hgt_i           : in unsigned(11 downto 0);
		box_prms_i          : in unsigned(31 downto 0)
	  
);
end boundingbox;

architecture rtl of boundingbox is

	constant S_AXIS_TDATA_WIDTH : integer := 24;
	constant M_AXIS_TDATA_WIDTH : integer := 24;
	constant C_S_AXI_ADDR_WIDTH : integer := 6;
    constant C_S_AXI_DATA_WIDTH : integer := 32;

	type state_t is (reset, init, drawBox, blocking, newline);
	
	type reg_bb	is record
	xpos                : unsigned(11 downto 0);
	ypos                : unsigned(11 downto 0);
	wdh                 : unsigned(11 downto 0);
	hght                : unsigned(11 downto 0);
	prms				: unsigned(31 downto 0);	
	end record;
    
    type reg_0 is record
    tdata_in				: std_logic_vector(S_AXIS_TDATA_WIDTH-1 downto 0);
    tdata_out				: std_logic_vector(M_AXIS_TDATA_WIDTH-1 downto 0);
    tuser                   : std_logic;
    tlast                   : std_logic;
    m_tvalid                : std_logic;	
    m_tready				: std_logic;
    s_tvalid                : std_logic;        
    s_tready                : std_logic;
    state					: state_t;
	xpntr					: unsigned(11 downto 0);
	ypntr					: unsigned(11 downto 0);
	img_width 				: unsigned(15 downto 0);
	img_height              : unsigned(15 downto 0);
	simple_cnt              : unsigned(7 downto 0);
    end record;
	
	constant dflt_reg_bb : reg_bb :=( 
	xpos               => to_unsigned(0, 12),
    ypos               => to_unsigned(0, 12),
	wdh                => to_unsigned(0, 12),
	hght               => to_unsigned(0, 12),
	prms			   => to_unsigned(0, 32)
	);
    
    constant dflt_reg_0 : reg_0 :=(
    tdata_in			    => (others=> '0'),
    tdata_out	            => (others=> '0'),
    tuser                   => '0',
    tlast        		    => '0',
    m_tvalid       	        => '0',
    m_tready				=> '0',
    s_tvalid                 => '0',
    s_tready                 => '1',
    state					=> reset,
	xpntr					=> to_unsigned(0, 12),
	ypntr 					=> to_unsigned(0, 12),
	img_width 				=> to_unsigned(1920, 16),
	img_height              => to_unsigned(1080, 16),
	simple_cnt              => to_unsigned(0, 8)
    );
    
    signal r, rin : reg_0 := dflt_reg_0;	-- set by axi-lite 
	signal box0_r, box0_rin : reg_bb := dflt_reg_bb;


begin

comb : process(r, rin, 
		box0_r, box0_rin, img_width_i, img_height_i,
		box_xpos_i, box_ypos_i, box_wdh_i, box_hgt_i, box_prms_i,
        S_AXIS_TVALID, S_AXIS_TDATA, S_AXIS_TUSER ,   
        S_AXIS_TLAST, M_AXIS_TREADY)
variable v 					 : reg_0;
variable box0				 : reg_bb;
begin

	v := r;
	box0 := box0_r;

	-- Forward ready and valid signals. 
	v.tdata_in := S_AXIS_TDATA; 
	v.tuser := S_AXIS_TUSER;
	v.tlast := S_AXIS_TLAST;
	v.m_tready := M_AXIS_TREADY;
	v.s_tvalid := S_AXIS_TVALID;
	v.img_width := img_width_i;
	v.img_height := img_height_i;

	-- stvalid --> mtvalid
	-- stready <-- mtready

	-- Get box coordinates and size
	box0.xpos := box_xpos_i;
	box0.ypos := box_ypos_i;
	box0.wdh  := box_wdh_i ;
	box0.hght := box_hgt_i ;
	box0.prms := box_prms_i;
	
	case v.state is
	when reset =>
		v.state := init;	
	    
	when init =>
		-- When there is a handshake, there is data
		-- Thus there is 1 clk delay between input and output
		if (v.s_tvalid = '1' and v.m_tready = '1') then
			
			v.state := drawBox;
			v.tdata_out := v.tdata_in;
			-- Start from zero-th line
			v.xpntr := to_unsigned(0, 12);
			v.ypntr := to_unsigned(0, 12); 
            v.s_tready := '1'; 
            v.m_tvalid := '1';
		else 
			v.m_tvalid := '0';
		end if;
    
	when drawBox =>
		-- AT FRAME Start
		-- No checking handshake, which means
		-- if either side blocks, the data will be lost
		
		if (v.m_tready = '1' and v.s_tvalid = '1') then 
		    -- talid is set during frame change. but in between lines, mtvalid might be reset
			v.m_tvalid := '1';
		
    			-- Draw along the top/bottom line
			if ((v.ypntr = box0.ypos) or (v.ypntr = box0.ypos + box0.hght))  then
        			if (v.xpntr >= box0.xpos) AND (v.xpntr <= box0.xpos + box0.wdh) then
                		-- Replace pixels in the top line 
            			v.tdata_out := x"00" & x"00" & std_logic_vector(box0.prms(7 downto 0));
            		else 
            			v.tdata_out := v.tdata_in;
            		end if;
                        
                    -- Draw along the left and right vertical line
            elsif ((v.ypntr >= box0.ypos) AND (v.ypntr <= box0.ypos + box0.hght)) then
            		if ((v.xpntr = box0.xpos) or (v.xpntr = box0.xpos + box0.wdh)) then
            			v.tdata_out :=  x"00" & x"00" & std_logic_vector(box0.prms(7 downto 0));
            		else 
            			v.tdata_out := v.tdata_in;
            		end if;
                    
			else 
	        		v.tdata_out := v.tdata_in;
        		end if;
                    
            	-- Increment pointer to the next pixel
			v.xpntr := v.xpntr + 1;
                    
			if v.tlast = '1' then
                v.xpntr := to_unsigned(0, 12);
                v.ypntr := v.ypntr + 1;
                v.state := newline;
                --v.m_tvalid := '0';
                if v.ypntr = v.img_height(11 downto 0) then 
                    v.state := init;
                    
                    --v.m_tvalid := '0';
                end if;
            end if;
 
		-- lost handshake due to eol or new frame
		elsif (r.s_tvalid = '0') then
			-- No valid data or 
			v.m_tvalid := '0';
            v.tdata_out := v.tdata_in;
            If (v.ypntr = v.img_height(11 downto 0)) then
            		V.state := init;
            	End if;
            	
		elsif (v.m_tready = '0') then
			
            
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
	
	when newline =>
	   if (v.s_tvalid = '1' AND v.m_tready = '1') then
	       v.state := drawBox;
	       v.tdata_out := v.tdata_in;
	       --v.m_tvalid := '1';
	       
	       v.m_tvalid := v.s_tvalid;
	       v.s_tready := v.m_tready;
	       v.simple_cnt := to_unsigned(0, 8);
       else 
           v.simple_cnt := v.simple_cnt + 1;
           --v.m_tvalid := '0';
           
           	v.m_tvalid := v.s_tvalid;
	        v.s_tready := v.m_tready;
            if (v.simple_cnt = 100) then
                v.state := init;
            end if;
	   end if;
	end case;
	
	rin <= v;
	box0_rin <= box0; 
	
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
	   else 
            r <= rin;
            box0_r <= box0_rin ; 
	   end if;	
   end if;
end process;



end rtl;
-- box0_x, box0_y,box0_w, box0_h, box1_x, box1_y, box1_w, box1_h, box2_x, box2_y, box2_w, box2_h
-- b0_xpos, b0_ypos, b0_wdh, b0_hght, b1_xpos, b1_ypos, b1_wdh, b1_hght, b2_xpos, b2_ypos, b2_wdh, b2_hght, b3_xpos, b3_ypos, b3_wdh, b3_hght, 

-- box0_r, box0_rin, box1_r, box1_rin, box2_r, box2_rin, box3_r, box3_rin, 