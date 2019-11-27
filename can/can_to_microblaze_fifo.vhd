
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity can_to_microblaze_fifo is
	Generic (
				FIFO_DEPTH		: natural := 32
			);
	Port (
				clk_100			: in std_logic;
				reset_n 		: in std_logic;
				
				package_i 		: in std_logic_vector (127 downto 0);
				valid_i 		: in std_logic;
				can_active_i 	: in std_logic;
				
				rd_en_i			: in std_logic;
				package_o 		: out std_logic_vector (127 downto 0);
				can_active_o 	: out std_logic;
				
				flag_full_o		: out std_logic;
				flag_empty_o	: out std_logic
		 );
end can_to_microblaze_fifo;

architecture Behavioral of can_and_filter is
	
	type package_fifo_t is array (0 to FIFO_DEPTH) of std_logic_vector(127 downto 0);
	type can_active_fifo_t is array (0 to FIFO_DEPTH) of std_logic;
	
    signal write_pointer		: integer;
    signal read_pointer			: integer;
	signal memory_count			: integer;

	signal data_in_reg			: std_logic_vector(127 downto 0);
	signal can_active_in_reg	: std_logic;
	signal valid_in_reg			: std_logic;

	signal flag_full			: std_logic;
	signal flag_empty			: std_logic;

	signal package_fifo			: package_fifo_t;
	signal can_active_fifo		: can_active_fifo_t;

begin

flag_full_o	<= flag_full;
flag_empty_o <= flag_empty;

flag_full <= '1' when memory_count = FIFO_DEPTH-1 else '0';
flag_empty <= '1' when memory_count = 0 else '0';

process(clk)
begin
	if rising_edge(clk) then
		if (reset_n = '1') then
			write_pointer 			<= 0;
			read_pointer 			<= 0;
			memory_count			<= 0;
			data_in_reg 			<= (others => '0');
			can_active_in_reg 		<= '0';
			valid_in_reg 			<= '0';
			for I in 0 to FIFO_DEPTH loop
				package_fifo(I) 	<= (others => '0');
				can_active_fifo(I) 	<= (others => '0');
			end loop;
			flag_full				<= '0';
			flag_empty				<= '1';
		else
			if (valid_i = '1' and rd_en_i = '0') then
				memory_count = memory_count + 1;
			elsif (valid_i = '0' and rd_en_i = '1') then
				memory_count = memory_count - 1;
			end if;
		
			if (valid_i = '1' and flag_full = '0') then
				if (write_pointer = FIFO_DEPTH-1) then
					write_pointer = '0';
				else
					write_pointer = write_pointer + 1;
				end if;
			end if;
			
			if (rd_en_i = '1' and flag_empty = '0') then
				if (read_pointer = FIFO_DEPTH-1) then
					read_pointer = '0';
				else
					read_pointer = read_pointer + 1;
				end if;
			end if;
			
			if (valid_i = '1') then
				package_fifo(write_pointer) <= package_i;
				can_active_fifo(write_pointer) <= can_active_i;
			end if;
			
			if (rd_en_i = '1') then
				package_o <= package_fifo(read_pointer);
				can_active_o <= can_active_fifo(read_pointer);
			end if;
		end if;
	end if;
end process;
end Behavioral;
