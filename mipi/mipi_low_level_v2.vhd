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
Library UNISIM;
use UNISIM.vcomponents.all;

Library UNIMACRO;
use UNIMACRO.vcomponents.all;

entity mipi_low_level is
generic (BIT_DEPTH 	: integer := 12;
		 IMG_WIDTH 	: integer := 1920;
		 IMG_HEIGHT : integer := 1080
		 );
port(

    M_AXIS_ACLK		: in std_logic;
    M_AXIS_ARESETN  : in std_logic;
    M_AXIS_TVALID   : out std_logic;
    M_AXIS_TDATA    : out std_logic_vector(47 downto 0);
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
	fifo_full		: out std_logic;
	byte_ctr_o 		: out std_logic_vector(15 downto 0)
);
end mipi_low_level;


architecture Behavioral of mipi_low_level is

	--sync codes for short packages
	constant FRAME_START	:	integer := 0;
	constant FRAME_END		:	integer := 1;
	constant LINE_START		:	integer := 2;
	constant LINE_END		:	integer := 3;

	signal internal_rst		:	std_logic;
	
	signal num_bytes		: 	unsigned(15 downto 0);
	signal word_counter		: 	unsigned(15 downto 0);
	
	signal short_packet		:	std_logic;
	signal first_line		:	std_logic;
	
	signal mipi_rd_en		: 	std_logic;
	signal mipi_data		:	std_logic_vector(7 downto 0);
	signal mifo_empty		: 	std_logic;
	
	signal bytes_expected	: 	unsigned(15 downto 0) := to_unsigned(0, 16);
	signal save_reg_0		: 	std_logic_vector(7 downto 0) := (others=>'0');
	signal save_reg_1		: 	std_logic_vector(7 downto 0) := (others=>'0');
		
	type state_t is (read_header, read_data, read_footer);  
	signal state, next_state : state_t;
begin

byte_ctr_o <= std_logic_vector(word_counter);

internal_rst <= not M_AXIS_ARESETN or not mipi_rstn;

sequ_top : process (mipi_hs_clk) begin
if rising_edge(mipi_hs_clk) then

	M_AXIS_TUSER <= '0';
	M_AXIS_TVALID <= '0';
	M_AXIS_TLAST <= '0';
	if (M_AXIS_ARESETN = '0') then
		bytes_expected <= to_unsigned(0, bytes_expected'length);
		word_counter <= to_unsigned(0, word_counter'length);
		first_line <= '0';
		state <= read_header;
		
	else
		-- we can only do somethiing when there is data in the mifo
		if (mipi_hs_valid = '1') then
			--mipi_rd_en <= '1';
			case state is 
				when read_header =>
					word_counter <= to_unsigned(0, word_counter'length);

					--wait for packet header
					case to_integer(unsigned(mipi_lane_0)) is
						when FRAME_START 		=>
							first_line <= '1'; --needed to generate TUSER later
						when 16#01# to 16#0F# 	=> 	
							-- no payload in a short package
						when 16#28# to 16#30# 	=>
							-- this is a long packet with raw image data
							bytes_expected <= unsigned(mipi_lane_2 & mipi_lane_1);
							state <= read_data;
						when others				=>
							state <= read_header; -- no valid header. wait on.
					end case;									
				when read_data => 
					--read payload
					word_counter <= word_counter + 4;

					-- payload is complete
					if (word_counter = bytes_expected - 4) then
						word_counter <= to_unsigned(0, word_counter'length);
						M_AXIS_TLAST <= '1';
						state <= read_footer;
					end if;
								
					-- see mipi standard 11.4.5
					if (word_counter mod 12 = 0) then
						M_AXIS_TDATA(11 downto 4) <= mipi_lane_0;--P0[11:4]
						M_AXIS_TDATA(23 downto 16) <= mipi_lane_1;--P1[11:4]
						M_AXIS_TDATA(3 downto 0) <= mipi_lane_2(3 downto 0);--P0[3:0]
						M_AXIS_TDATA(15 downto 12) <= mipi_lane_2(7 downto 4);--P1[3:0]
						M_AXIS_TDATA(35 downto 28) <= mipi_lane_3;--P2[11:4]
					elsif (word_counter mod 12 = 4) then
						M_AXIS_TDATA(47 downto 40) <= mipi_lane_0;--P3[11:4]
						M_AXIS_TDATA(27 downto 24) <= mipi_lane_1(3 downto 0);
						M_AXIS_TDATA(39 downto 36) <= mipi_lane_1(7 downto 4);
						M_AXIS_TVALID <= '1';
						if (first_line = '1') then
							first_line <= '0';
							M_AXIS_TUSER <= '1';
						end if;
						save_reg_0 <= mipi_lane_2;
						save_reg_1 <= mipi_lane_3;
					elsif (word_counter mod 12 = 8) then
						M_AXIS_TDATA(11 downto 4) <= save_reg_0;--P4[11:4]
						M_AXIS_TDATA(23 downto 16) <= save_reg_1;--P5[11:4]
						M_AXIS_TDATA(3 downto 0) <= mipi_lane_0(3 downto 0);--P4[3:0]
						M_AXIS_TDATA(15 downto 12) <= mipi_lane_0(7 downto 4);--P5[3:0]
						M_AXIS_TDATA(35 downto 28) <= mipi_lane_1;--P6[11:4]
						M_AXIS_TDATA(47 downto 40) <= mipi_lane_2;--P7[11:4]
						M_AXIS_TDATA(27 downto 24) <= mipi_lane_3(3 downto 0);
						M_AXIS_TDATA(39 downto 36) <= mipi_lane_3(7 downto 4);
						M_AXIS_TVALID <= '1';				
                    end if;
				when read_footer =>
					--the footer has a length of 2 bytes but since data is aligned to 4 byte we need to read 2 more bytes
					state <= read_header;
			end case;
		end if;
	end if;
end if;
end process;

  
                                     -- `,;*########+*:.                                                                                                   
                               -- `,*##+i::,,,,,:::;*##+,                                                                                                
                            -- `:+#+**:,,,,,,,,,:**:,,,;+#;                                                                                              
                          -- .*#*:,+nni,,,,,,,,,;z#:,,,,,:*#.                                                                                            
                        -- :#+;,,,,*#*:,,,,,,,,,,::,,,,,,,,:#;                                                                                           
                      -- ;#*:,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,:+*                                                                                          
                    -- :#*:,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,+*                                                                                         
                  -- ,zn;,,,,,,,,,,,,,,,,,,:ii:,,,,,,,,,,,,,,,,+*                                                                                        
                -- `*xnz;,,,,,,,,,,,,,,,,,:#nn+,,,,,,,,;i,,,,,,,+;                                                                                       
               -- ,#i##;,,,,,:i*i:,,,,,,,,:+#+:,,,,,,,:zz;,,,,,,:z,                                                                                      
              -- i#:,,,,,,,,:#nnz:,,,,,,,,,,:,,,,,,,,,:+*:,,,,,,,:z`                                                                                     
            -- `#i,,,,,,,,,,;znzi,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,i*                                                                                     
           -- .#;,,,,,,,,,,,,;;:,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,#.                                                                                    
          -- ,#:,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,;+                                                                                    
         -- :#:,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,#`                                                                                   
        -- :#:,,,,::,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,ii                                                                                   
       -- ,+:,,,,;#+,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,:#                                                                                   
      -- .n;,,,,:#n#,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,z`                                                                                  
     -- `nn;,,,,;z#:,,,,,,,:;*+#*:,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,#,                                                                                  
     -- +n#:,,,,,;:,,,,,,;+z#*;::,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,*;                                                                                  
    -- :+i:,,,,,,,,,,,,;##;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,;i                                                                             `;;: 
   -- `#:,,,,,,,,,,,,:+#;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,;*                                                                          `:++;,i,
   -- ii,,,,,,,,,,,,:z*,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,:+                                                                    `.,;*+#*:,,,:*
  -- `#,,,,,,,,,,,,;z;,,,,,,,,,,,:;ii,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,:+                                                             .:;*++##+*i::,,,,,,,+
  -- ii,,,,,,,,,,,:z:,,,,,,,,:i#zz#*;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,;*                                                        .;*##+*i:::,,,,,,,,,,,,,,+
  -- #,,,,,,,,,,,:z;,,,,,,,;#z+;:,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,;*                                                     `i#+i:,,,,,,,,,,,,,,,,,,,,,:*
 -- .+,,,,**,,,,,+i,,,,,,:##;,,,,,,,,,,,,,,,,:::,,,,,,,,,,,,,,,,,,,,,ii                                                   `*#;:,,,,,,,,,,,,,,,,,,,,,,,:;;
 -- *;,,,inz:,,,:#,,,,,,*z;,,,,,,,,,,,,,,:i#zz#i,,,,,,,,,,,,,,,,,,,,,+,                                                  .#;,,,,,,,,,,,,,,,,,,,,,,,,:;;#`
 -- #:,,,#n#,,,,;;,,,,:#+,,,,,,,,,,,,:i#z#*;:,,,,,,,,,,,,,,,,,,,,,,,,z`                                                 ,#:,,,,,,,,,,,,,,,,,,,,,,,,:;;** 
-- `#,,,:zz;,,,,,,,,,:zi,,,,,,,,,,,;+z+;:,,,,,,,,,,,,,,,,,,,,,,,,,,,:#                                                 ,#:,,,,,,,,,,,,,,,,,,,,,,,,:;;*z` 
-- :*,,,,i;,,,,,,,,,:z;,,,,,,,,,:iz#;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,*;                                                `#:,,,,,,,,,,,,,,,,,,,,,,,:;;;zM,  
-- i;,,,,,,,,,,,,,,:z;,,,,,,,,,*z+:,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,z`                                                +;,,,,,,,,,,,,,,,,,,,,,,,:;;;#Mi   
-- *:,,,,,,,,,,,,,,#i,,,,,,,,iz*:,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,;*                                                ;*,,,,,,,,,,,,,,,,,,,,,,:;;;;*Wi    
-- #*,,,,,,,,,,,,,i+,,,,,,,:##:,,,,,,,;+####+;,,,,,,,,,,,,,,,,,,,,,#.                                                #:,,,,,,,,,,,,,,,,,,,,:;ii;;;zi     
-- zz,,,,,,,,,,,,:#:,,,,,,iz;,,,,,,,:#+:,,,,;+#:,,,,,,,,,,,,,,,,,,i*                                                ,*,,,,,,,,,,,,,,,,,,::;+nxx*;#;      
-- zz,,,,,,,,,,,,*i,,,,,,*#:,,,,,,,,#;........:#*,,,,,,,,,,,,,,,,:z`                                               .z:,,,,,,,,,,,,,,::;;;inn##x*z:       
-- #*,,,,,,,,,,,,i,,,,,,++,,,,,,,,,i+..........,++:,,,,,,,,,,,,,,+;                                               :#+,,,,,,,,,,,,,::;;;;;zz+#xn#.        
-- +;,,,,,,,,,,,,,,,,,,+*,,,,,,,,,,#,............i#,,,,,,,,,,,,,;#                                              `**;:,,,,,,,,,,,,:;;;;;;;xnnxn;          
-- ii,,:i:,,,,,,,,,,,,+*,,,,,,,,,,:z..............i+,,,,,,,,,,,:#.                                             ,#;,,,,,,,,,,,,,,:;;;;;;;;i*z+`           
-- :*,,ini,,,,,,,,,,,i+,,,,,,,,,,,;#...............**,,,,,,,,,,*i                                            `*+:,,,,,,,,,,,,,,:;;;;*#z#*#+.             
-- .#,,+n*,,,,,,,,,,:z:,,,,,,,,,,,;#................#;,,,,,,,,;#                                            ,#i,,,,,,,,,,,,,,,:;;;inn#zx#,               
-- `#,,+ni,,,,,,,,,,#;,,,,,,,,,,,,:#................,z:,,,,,,iz.                                          `*+:,,,,,,,,,,,,,,,,:;;;nzzn+.                 
 -- #:,;i:,,,,,,,,,;#,,,,,,,::::,,,#.................i*,,,,,,**                                          ,#i,,,,,,,,,,,,,:::,,:;;+Mzi`                   
 -- ii,,,,,,,,,,,,,#:,,,,,;##++##i:#,......,:.........#:,,,,,:#                                        `*+:,,,,,,,,,,,,,;####++++i.                      
 -- .#,,,,,,,,,,,,:#,,,,,*#,....,*z#i.....*nx;........;+,,,,,,*;   `:i++++i.                          :#;,,,,,,,,,,,,,;#*.                               
  -- #:,,,,,,,,,,,i*,,,,;#,.......,+n....,nxxz,.......,#:,,,,,,+.i++i;:,,,;++`                      `++:,,,,,,,,,,,,i#i`                                 
  -- ;*,,,,,,,,,,,+;,,,,#:..........#;....zxxxi........ii,,,,,:##;,,,,,,,,,,;#`                    ;#;,,,,,,,,,,,,i#i`                                   
  -- `#,,,,,,,,,,,::,,,:z...........:#....ixxxn,.......,#,,,,iz;,,,,,,,,,,,,,:#`                 .+*,,,,,,,,,,,,i#i`                                     
   -- ii,,,,,,,,,,,,,,,:+............+:...,nxxx#,.......#:,,:i,,,,,,,,,,::::,,i;                ;+:,,,,,,,,,,:i#;`                                       
   -- `#:,,,,,,,,,,,,,,:+............,#,...*xxxxi.......+;,,,,,,,,,,:i#####z#ii;              .+i,,,,,,,,,,,i#i`                                         
    -- :+,,,,,,,,,,,,,,:+.............*i...,zxxxxi......ii,,,,,,,,;##*:,,,,,:*n#,`           i+:,,,,,,,,,,izi`                                           
     -- +i,,,,,,,,,,,,,:#.............,#,...:nxxxx;.....ii,,,,,,:##;,,,,,,,,,,:;+##*;.`    .#i,,,,,,,,,,i#*`                                             
     -- `#;,,,,,,,,,,,,,z......:;,.....;+....;xxxxx:....+;,,,,,iz;,,,,,,,,,,,,,,,,::i+##*;i#:,,,,,,,,,;#i`                                               
      -- `#;,,,,,,,,,,,,#:....*xx*......+i....;nxxx:...,z,,,,:#+:,,,,,,,,,,,,,,,,,,,,,,,:i+z;,,,,,,,;#*`                                                 
       -- `+*:,,,,,,,,,,i*...,xxxx:.....,#;....:zx*....i*,,,:zi,,,,,,,,,,,,,,,,,,,,,,,,,,,,:z,,,,,;#*`                                                   
         -- ;#i,,,,,,,,,:z,...#xxxz,....ii#*....,:....:z:,,;z;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,#,,,;#*`                                                     
          -- `i#+i;:::;iizi...:nxxx+,...#:,*#:.......:z:,,*#:,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,:#,;#*`                                                       
             -- .;*++*i;:,#,...*xxxx*..,#,,,:##i,.,:+#:,,++:,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,:#*#*`                                                         
                       -- ;*...,zxxxx*.:+,,,,,:*#nz+;,,:#*,,,,,,,,,:::;::::::::,,,,,,,,::;zM*`                                                           
                        -- +:...:nxxxx#ii,,,,,,,,i+,,,:z;,,,,,,,,:;;;;;;;;i**i;;;;;;;;;;in+.                                                             
                        -- `#,...;nxxxxx;,,,,,,,,,z;,;z;,,,,,,,,;;;;;;;;;zxnxxni;;;i#nz##,                                                               
                         -- .#,...:nxxxM:,,,,,,,,,:z*z:,,,,,,;+;;;iii;;;*n##++z+;;ixznz,                                                                 
                          -- ,#,...,#xnx:,,,,,,,,,,*z:,,,,,,:z,z*znnnni;*x###nxi;;zxz;                                                                   
                           -- .#:....;,#:,,,,,,,,,*+,,,,,,,:#, `*x##+#xi;*zzz+ii+nx,                                                                     
                            -- `+*,....z:,,,,,,,,++,,,,,,,,+:    ,xMnnM+*+++#znnn#n:                                                                     
                             -- ,zz#++#x:,,,,,,:#*,,,,,,,,*nn+` ;xz##zznnnzz#######i                                                                     
                            -- :#:,:;;:z:,,,,,:#i,,,,,,,,in##zn#n##################*                                                                     
                           -- .#:,,,,,,z:,,,,:zi,,,,,,,,;xx####Mz#################zi                                                                     
                          -- `#:,,,,,,,+;,,,:z;,,,,,,,,:z:*x####M#################n:                                                                     
                          -- ;i,,,,,,,,**,,:z;,,,,,,,,:z;,,;n###zx##############n#.                                                                      
                         -- `#,,,,,,,,;##,:z;,,,,,,,,,#i,,,,:n###x############zn:                                                                        
                         -- :*,,,,,,:+#;z:z;,,,,,,,,,+*,,,,,,;n##zn#########nn;`                                                                         
                         -- +:,,,,,:#i,,#z:,,,,,,,,,i+,,,,,,,,z###x#######nz;`                                                                           
                         -- #,,,,,:z;,,:z;,,,,,,,,,;#:,,,,,,,,;Mn#x###n#nz:                                                                              
                        -- `#,,,,:z:,,:z;,,,,,,,,,:z:,,,,,,,,,,nzxM###zM+                                                                                
                        -- `#,,,,#;,,:z;,,,,,,,,,,#;,,,,,,,,,,,z##n#####ni                                                                               
                        -- `#,,,i*,,:#;,,,,,,,,,,**,,,,,,,,,,,,+#########ni                                                                              
                         -- #,,,:,,,+i,,,,,,,,,,;#,,,,,,,,,,,,,+##########n:                                                                             
                         -- *:,,,,,**,,,,,,,,,,:#:,,,,,,,,,,,,,############n.                                                                            
                         -- ,+,,,,;#,,,,,,,,,,,+i,,,,,,,,,,,,,,n#############                                                                            
                          -- i#i;iz:,,,,,,,,,,;#,,,,,,,,,,,,,,;n############n:                                                                           
                           -- .;*ni,,,,,,,,,,:#:,,,,,,,,,,,,,,z##############n`                                                                          
                             -- .+,,,,,,,,,,,**,,,,,,,,,,,,,,*n##############z*                                                                          
                             -- +:,,,,,,,,,,:nz:,,,,,,,,,,,,+n################n.                                                                         
                            -- .+,,,,,,,,,,,##zz;,,,,,,,,,;zn##################+                                                                         
                            -- *:,,,,,,,,,,;x###nz+;::::i#xz###################n,                                                                        
                           -- `+,,,,,,,,,,:zz#####znnnxn;.,z####################+                                                                        
                           -- :i,,,,,,,,,:#z########zni`   #####################x,                                                                       
                           -- *:,,,,,,,,,+n########n+`     :n####################+                                                                       
                           -- +:,,,,,,,:+n#######nz,       `n####################n`                                                                      
                           -- zz:,,,,,inz######nz:          #####################z;                                                                      
                           -- znn+ii+nn#####zn#,            i######################                                                                      
                           -- ,zzznnz####znz*.              :z####################n`                                                                     
                            -- `*znnnnnz+;.                 ,n####################n:                                                                     
                               -- ....                      .n#####################*                                                                     
                                                         -- .n#####################z                                                                     
                                                         -- .n#####################n`                                                                    
                                                         -- :z#####################n,                                                                    
                                                         -- *z#####################z;                                                                    
                                                         -- ########################+                                                                    
                                                        -- `n#######################z                                                                    
                                                        -- ,n#######################n                                                                    
                                                        -- *########################n`                                                                   
                                                        -- n########################x,                                                                   
                                                       -- ,n########################n,                                                                   
                                                       -- +#########################n:                                                                   
                                                      -- `n#########################z;                                                                   
                                                      -- ;z########znxxxxxxnzz######z;                                                                   
                                                      -- z######nnz+i;:::::;*#nxz###z:                                                                   
                                                     -- ,n###zxz;:,,,,,,,,,,,,,:*nn#n,                                                                   
                                                     -- ,n#zx#:,,,,,,,,,,,,,,,,,,:*nn`                                                                   
                                                      -- znz;,,,,,,,,,,,,,,,,,,,,,,;+                                                                    
                                                      -- .#,,,,,,,,,,,,,,,,,,,,,,,,+:                                                                    
                                                      -- .*,,,,,,,,,,,,,,,,,,,,,,,,+.                                                                    
                                                      -- i;,,,,,,,,,,,,,,,,,,,,,,,,#                                                                     
                                                     -- `#,,,,,,,,,,,,,,,,,,,,,,,,:+                                                                     
                                                     -- ;i,,,,,,,,,,,,,,,,,,,,,,,,i:                                                                     
                                                     -- #:,,,,,,,,,,,,,,,,,,,,,,,:z`                                                                     
                                                    -- ,+,,,,,,,,,,,,,,,,,,,,,,,,z;                                                                      
                                                    -- +:,,,,,,,,,,,,,,,,,,,,,,:#n`                                                                      
                                                   -- .#,,,,:i,,,,,,,,,,,,,,,,:#i#                                                                       
                                                   -- *;,,,,*ni,,,,,,,,i:,,,;iz;,#                                                                       
                                                  -- `#,,,,:z:+#i:,,,,,#:,,,#*:,,+                                                                       
                                                  -- i;,,,,**,,:+##z##*z,,,,#:,,,+                                                                       
                                                 -- `+,,,,:z,,,,,,,#. `#,,,,#:,,,+                                                                       
                                                 -- :;,,,,*i,,,,,,ii  ,*,,,,+:,,,:                                                                       
                                                 -- .`````:```````.   `.``` `                                                                            

end Behavioral;
