----------------------------------------------------------------------------------
-- Company: avi-systems deutschland gmbh
-- Engineer: NAB (nazrizal.abdullah@avi-systems.eu)
-- 
-- Create Date: 09/11/2019 03:01:51 PM
-- Module Name: axis_receiver - rtl

-- Dependencies: Generator-Module

--  Date:    Revision:          Description:
--  09/19    0.1                File Created
--  10/19    0.2                Minor changes, added paket counter
--  
-- Additional Comments:
-- To use  this file, make sure the following ports are connected.
-- generator_data - connects directly to data generator module
-- generator_event - used to count the data/packets sent by data generator module.
--                   axis_rcvr module should compare the number of inbound st packets from
--                   Port S_AXIS_TDATA with a counter which counts the generator_event
--                   ensure that data generator module sets this when data is sent.
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity axis_receiver is
generic(
		IMG_VERTICAL			: integer := 1080;
		IMG_HORIZONTAL			: integer := 1920;
		--C_S_AXIS_TDATA_WIDTH	: integer 	:= 16;
		C_S_AXIS_TDATA_WIDTH	: integer 	:= 32;
		STREAM_TDATA_DELAY 		: integer := 1
);
port(
        S_AXIS_ACLK	    : in  std_logic;
        S_AXIS_ARESETN	: in  std_logic;		
        S_AXIS_TREADY	: out std_logic;
		S_AXIS_TVALID	: in  std_logic;
        S_AXIS_TDATA	: in  std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
      --S_AXIS_TSTRB	: in  std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
      --S_AXIS_TKEEP    : in  std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
	    S_AXIS_TUSER    : in  std_logic;
        S_AXIS_TLAST	: in  std_logic;
      --S_AXIS_TID      : in  ??;
      --S_AXIS_TDEST    : in  ??;
	  
		generator_event : in  std_logic;		
		generator_data	: in  std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
		wait_for_gen	: out std_logic		
	  
);

end entity;

architecture behav of axis_receiver is
	
	type state_type is (reset, idle, waiting, processing);

	signal state 		: state_type := idle;
	signal cnt_delay    : unsigned(7 downto 0);
	signal cnt_data     : unsigned(C_S_AXIS_TDATA_WIDTH-1 downto 0);

begin

inst_rcv : process (S_AXIS_ACLK)
variable cnt_unready 	: unsigned(7 downto 0 ) := to_unsigned(0, 8);
variable cnt_error	    : unsigned(C_S_AXIS_TDATA_WIDTH-1 downto 0) := to_unsigned(0, C_S_AXIS_TDATA_WIDTH);
begin
	if falling_edge(S_AXIS_ACLK) then
		if (S_AXIS_ARESETN = '0') then
			cnt_data		<= to_unsigned(1, C_S_AXIS_TDATA_WIDTH);
	        cnt_delay		<= to_unsigned(0, 8);
	        cnt_error		:= to_unsigned(0, C_S_AXIS_TDATA_WIDTH);
			wait_for_gen	<= '1';
			S_AXIS_TREADY	<= '0';
			state <= reset;
		else
			case (state) is
			when reset => 	
				state <= idle;
			
			when idle =>
			    wait_for_gen <= '0';
			    S_AXIS_TREADY <= '1';
				if (S_AXIS_TVALID = '1') then
					state <= processing;
					-- Increment when valid changes to true, 
					-- when the first data is transmitted
					cnt_data <= cnt_data + 1;
				end if;
			
			
			when processing =>
				S_AXIS_TREADY <= '1';
   			   
				if ( S_AXIS_TVALID = '0') then 
					state <= idle;
					--assert S_AXIS_TVALID = '1' report "No handshake" severity warning;
                else
                    assert S_AXIS_TDATA = generator_data report "Data error" severity warning;
				end if;
				
				if ( generator_event = '1') then
                    cnt_data <= cnt_data + 1;
                    if (S_AXIS_TLAST = '1') then
                        cnt_data <= to_unsigned(1, cnt_data'length);
                    end if;
                end if;

				
			---- This state waits for data to pass through the module
			---- The delay from arrival of generator event and arrival of actual data 
			---- from the module is the STREAM_TDATA_DELAY in clock
			when waiting =>		
                S_AXIS_TREADY <= '0';
			    cnt_unready := cnt_unready + 1;
                if cnt_unready = 5 then
			         state <= processing;
			         cnt_unready := to_unsigned(0,8);
                 end if; 
			
				--if (generator_event = '1') then
				--	cnt_error := cnt_error + 1;
				--	assert generator_data = S_AXIS_TDATA report "Data mismatch" severity warning;
				--else 
--                if cnt_delay >= STREAM_TDATA_DELAY then
--                    assert cnt_delay = STREAM_TDATA_DELAY report "Delay counter exceed expected value" severity warning;
--                    assert generator_data = S_AXIS_TDATA report "Data mismatch at expected clock" severity failure;
--                    wait_for_gen <= '0';
--                    state <= idle;
--                elsif cnt_delay < STREAM_TDATA_DELAY then
--                    cnt_delay <= cnt_delay + 1;
--                end if;
--				--end if;
				
			end case;
		end if;
	end if;
end process;

end architecture;
				
                                      