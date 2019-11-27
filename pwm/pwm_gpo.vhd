library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity pwm_gpo is
	generic (
		-- Users to add parameters here

		-- User parameters ends
		-- Do not modify the parameters beyond this line

		-- Width of S_AXI data bus
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		-- Width of S_AXI address bus
		C_S_AXI_ADDR_WIDTH	: integer	:= 8
	);
    Port ( 			
			S_AXI_ACLK		: in std_logic;
			S_AXI_ARESETN	: in std_logic;
			S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
			S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
			S_AXI_AWVALID	: in std_logic;
			S_AXI_AWREADY	: out std_logic;
			S_AXI_WDATA		: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
			S_AXI_WSTRB		: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
			S_AXI_WVALID	: in std_logic;
			S_AXI_WREADY	: out std_logic;
			S_AXI_BRESP		: out std_logic_vector(1 downto 0);
			S_AXI_BVALID	: out std_logic;
			S_AXI_BREADY	: in std_logic;
			S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
			S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
			S_AXI_ARVALID	: in std_logic;
			S_AXI_ARREADY	: out std_logic;
			S_AXI_RDATA		: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
			S_AXI_RRESP		: out std_logic_vector(1 downto 0);
			S_AXI_RVALID	: out std_logic;
			S_AXI_RREADY	: in std_logic;
			pwm_out		 	: out std_logic_vector(7 downto 0)
	);
end pwm_gpo;
architecture Behavioral of pwm_gpo is

	component pwm_axi is
	generic (
		-- Users to add parameters here

		-- User parameters ends
		-- Do not modify the parameters beyond this line

		-- Width of S_AXI data bus
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		-- Width of S_AXI address bus
		C_S_AXI_ADDR_WIDTH	: integer	:= 8
	);
	port (
		S_AXI_ACLK					: in std_logic;
		S_AXI_ARESETN				: in std_logic;
		S_AXI_AWADDR				: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_AWPROT				: in std_logic_vector(2 downto 0);
		S_AXI_AWVALID				: in std_logic;
		S_AXI_AWREADY				: out std_logic;
		S_AXI_WDATA					: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_WSTRB					: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		S_AXI_WVALID				: in std_logic;
		S_AXI_WREADY				: out std_logic;
		S_AXI_BRESP					: out std_logic_vector(1 downto 0);
		S_AXI_BVALID				: out std_logic;
		S_AXI_BREADY				: in std_logic;
		S_AXI_ARADDR				: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_ARPROT				: in std_logic_vector(2 downto 0);
		S_AXI_ARVALID				: in std_logic;
		S_AXI_ARREADY				: out std_logic;
		S_AXI_RDATA					: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_RRESP					: out std_logic_vector(1 downto 0);
		S_AXI_RVALID				: out std_logic;
		S_AXI_RREADY				: in std_logic;
        
        timers_period  				: out std_logic_vector(8*C_S_AXI_DATA_WIDTH-1 downto 0);
		timers_high					: out std_logic_vector(8*C_S_AXI_DATA_WIDTH-1 downto 0);
		timer_config				: out std_logic_vector(8*C_S_AXI_DATA_WIDTH-1 downto 0)
	);
	end component;
	
    signal timers_period  			: std_logic_vector(8*C_S_AXI_DATA_WIDTH-1 downto 0);
	signal timers_high				: std_logic_vector(8*C_S_AXI_DATA_WIDTH-1 downto 0);
	signal timer_config				: std_logic_vector(8*C_S_AXI_DATA_WIDTH-1 downto 0);
	
	component pwm_channel is
    Port ( 
			clk				: in std_logic;						-- if you dont know what a clock signal is you probably shouldnt work here
			timer_period	: in std_logic_vector(31 downto 0); -- duration of a timer period
			timer_high_time	: in std_logic_vector(31 downto 0); -- how long within a period the output shall the output stay 1 (eg the duty cycle)
			start			: in std_logic;						-- start the timer
			pwm_out		 	: out std_logic						-- pwm output signals
	);
	end component;
	
begin

GEN_PWM: 
for I in 0 to 8-1 generate
pwm_channel_i: pwm_channel 
Port map (
	clk				=> S_AXI_ACLK,
	timer_period	=> timers_period((i+1)*C_S_AXI_DATA_WIDTH-1 downto i*C_S_AXI_DATA_WIDTH),
	timer_high_time	=> timers_high((i+1)*C_S_AXI_DATA_WIDTH-1 downto i*C_S_AXI_DATA_WIDTH),
	start			=> timer_config(i*32),
	pwm_out		 	=> pwm_out(i)
);
end generate GEN_PWM;

	i_pwm_axi : pwm_axi 
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
		S_AXI_ARPROT	=> S_AXI_ARPROT,
		S_AXI_ARVALID	=> S_AXI_ARVALID,
		S_AXI_ARREADY	=> S_AXI_ARREADY,
		S_AXI_RDATA		=> S_AXI_RDATA,
		S_AXI_RRESP		=> S_AXI_RRESP,
		S_AXI_RVALID	=> S_AXI_RVALID,
		S_AXI_RREADY	=> S_AXI_RREADY,
        
		timers_period	=> timers_period,
		timers_high		=> timers_high,
		timer_config	=> timer_config
	);
	
end Behavioral;

	
	
