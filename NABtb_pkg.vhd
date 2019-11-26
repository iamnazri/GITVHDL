--
--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 
--
--   To use any of the example code shown below, uncomment the lines and modify as necessary
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;
USE ieee.std_logic_textio.ALL;
USE ieee.numeric_std.ALL;
USE std.textio.ALL;

package NABtb_pkg is

   procedure wait_clk(signal clk: std_logic; n: natural);
	
  -- calls "assert false" with the message and incremente err_cnt
    procedure assert_cnt(message: string; signal err_cnt: inout natural);
	
	-- returns true if s contains a value /= '0' or /= '1' 

   procedure lg_report (
    	signal in_pattern : in std_logic_vector(19 downto 0);
	   signal expected : in std_logic_vector(9 downto 0);
	   signal obtained : in std_logic_vector(9 downto 0));
		
   procedure lg1_report (
    	signal in_pattern : in std_logic_vector(7 downto 0);
	   signal expected : in std_logic;
	   signal obtained : in std_logic);
   
	 -- Check equality using XOR gates; fn returns 0 if equal, 1 on inequality
	 impure function eval10_output (
	   signal soll_output : std_logic_vector(9 downto 0);
		signal ist_output  : std_logic_vector(9 downto 0)) return std_logic;
		  
	 impure function eval8_output (
	   signal soll_output : in std_logic_vector(7 downto 0);
		signal ist_output  : in std_logic_vector(7 downto 0)) return std_logic;

   function get10_even( 
	    in_pattern : std_logic_vector(19 downto 0)) return std_logic_vector;
		 
   function get10_odd( 
	    in_pattern : std_logic_vector(19 downto 0)) return std_logic_vector;

   function get8_even( 
	    in_pattern : std_logic_vector(15 downto 0)) return std_logic_vector;
		 
   function get8_odd( 
	    in_pattern : std_logic_vector(15 downto 0)) return std_logic_vector;


end NABtb_pkg;

package body NABtb_pkg is


  procedure wait_clk(signal clk: std_logic; n: natural) is
  begin
    for i in 0 to n-1 loop
      wait until clk = '1';
    end loop;  
  end procedure;
 

  procedure assert_cnt(message: string; signal err_cnt: inout natural) is
  begin
    assert false report message severity error;
    err_cnt <= err_cnt + 1;
  end procedure;

     procedure lg_report (
    	  signal in_pattern : in std_logic_vector(19 downto 0);
	     signal expected : in std_logic_vector(9 downto 0);
		  signal obtained : in std_logic_vector(9 downto 0) ) is 
	  variable console : line;
	  variable res : std_logic_vector(9 downto 0);
	  variable x : std_logic;
	  begin
		   writeline(output, console);
		   write(console, string'("                  Test Report"));
		   writeline(output, console);
	      write(console, string'("-------------------------------------------------------"));
		   writeline(output, console);
	   	write(console, string'("Tested at t=")); 
	   	write(console, now);
	   	writeline(output, console);
	   	write(console, string'(" with Test Pattern= "));
	   	write(console, in_pattern);
	    	writeline(output, console);
	   	write(console, string'("Expected pattern = "));
	   	write(console, expected); -- to be replaced with pass over variable
	   	writeline(output, console);
	   	write(console, string'("Obtained pattern = "));
	   	write(console, obtained);
	   	writeline(output, console);
	   	write(console, string'("-------------------------------------------------------"));
	   	writeline(output, console);
			
      end lg_report;
		
     procedure lg1_report (
    	  signal in_pattern : in std_logic_vector(7 downto 0);
	     signal expected : in std_logic;
		  signal obtained : in std_logic) is 
	  variable console : line;
	  begin
		   writeline(output, console);
		   write(console, string'("                  Test Report"));
		   writeline(output, console);
	      write(console, string'("-------------------------------------------------------"));
		   writeline(output, console);
	   	write(console, string'("Tested at t=")); 
	   	write(console, now);
	   	writeline(output, console);
	   	write(console, string'(" with Test Pattern= "));
	   	write(console, in_pattern);
	    	writeline(output, console);
	   	write(console, string'("Expected pattern = "));
	   	write(console, expected); -- to be replaced with pass over variable
	   	writeline(output, console);
	   	write(console, string'("Obtained pattern = "));
	   	write(console, obtained);
	   	writeline(output, console);
	   	write(console, string'("-------------------------------------------------------"));
	   	writeline(output, console);
			
      end lg1_report;		


	 impure function eval10_output (
	     signal soll_output :  std_logic_vector(9 downto 0);
		  signal ist_output  : std_logic_vector(9 downto 0)) 
		  return std_logic is
	 variable console: line;
	 variable x : std_logic_vector(9 downto 0);
	 begin
		  x := soll_output XOR ist_output;
		  write(console, string'("-------------------------------------------------------"));
		  writeline(output, console);
	     if x = b"0000000000"  then
--		      write(console, string'("Test success"));
--				writeline(output, console);
				return '0';
		  else 
--		      write(console, string'("Test failed"));
--				writeline(output, console);
				return '1';
        end if;
    end eval10_output; 


	 impure function eval8_output (
	     signal soll_output : in std_logic_vector(7 downto 0);
		  signal ist_output  : in std_logic_vector(7 downto 0)) 
		  return std_logic is
	 variable console: line;
	 variable x : std_logic_vector(7 downto 0);
	 begin
		  x := soll_output XOR ist_output;
		  write(console, string'("-------------------------------------------------------"));
		  writeline(output, console);
	     if x = b"00000000"  then
--		      write(console, string'("Test success"));
--				writeline(output, console);
				return '0';
		  else 
--		      write(console, string'("Test failed"));
--				writeline(output, console);
				return '1';
        end if;
    end eval8_output; 


	 
	 -- returns numbers in a std logic vector that has even number index
	 function get10_even(   
	     in_pattern : std_logic_vector(19 downto 0))
	 return std_logic_vector is
	 variable even_no : std_logic_vector(9 downto 0);
	 begin 
	 
	    for i in 0 to 9 loop  
		   even_no(i) := in_pattern(2*i);
		 end loop;
	 return even_no;
	 end get10_even;
	
	-- returns numbers in a std logic vector that has even number index
	 function get10_odd(   
	     in_pattern : std_logic_vector(19 downto 0))
	 return std_logic_vector is
	 variable odd_no : std_logic_vector(9 downto 0);
	 begin 
	 
	    for i in 0 to 9 loop  
		   odd_no(i) := in_pattern(2*i +1);
		 end loop;
	 return odd_no;
	 end get10_odd;
	 
	 
	 	 function get8_even(   
	     in_pattern : std_logic_vector(15 downto 0))
	 return std_logic_vector is
	 variable even_no : std_logic_vector(7 downto 0);
	 begin 
	 
	    for i in 0 to 7 loop  
		   even_no(i) := in_pattern(2*i);
		 end loop;
	 return even_no;
	 end get8_even;
	
	-- returns numbers in a std logic vector that has even number index
	 function get8_odd(   
	     in_pattern : std_logic_vector(15 downto 0))
	 return std_logic_vector is
	 variable odd_no : std_logic_vector(7 downto 0);
	 begin 
	 
	    for i in 0 to 7 loop  
		   odd_no(i) := in_pattern(2*i +1);
		 end loop;
	 return odd_no;
	 end get8_odd;
		
--		procedure final_report is
--		variable console : line;
--      begin 
--          write(console, err_cnt);	
--			 writeline(output, console);
--		end final_report;
		    
		   
end NABtb_pkg;

-------------------Example from Xilinx (package declaration)
-- type <new_type> is
--  record
--    <type_name>        : std_logic_vector( 7 downto 0);
--    <type_name>        : std_logic;
-- end record;
--
-- Declare constants
--
-- constant <constant_name>		: time := <time_unit> ns;
-- constant <constant_name>		: integer := <value;
--
-- Declare functions and procedure
--
-- function <function_name>  (signal <signal_name> : in <type_declaration>) return <type_declaration>;
-- procedure <procedure_name> (<type_declaration> <constant_name>	: in <type_declaration>);
-- Example from Xilinx (package body)
---- Example 1
--  function <function_name>  (signal <signal_name> : in <type_declaration>  ) return <type_declaration> is
--    variable <variable_name>     : <type_declaration>;
--  begin
--    <variable_name> := <signal_name> xor <signal_name>;
--    return <variable_name>; 
--  end <function_name>;
----------------------------------------

---- -----------------------------------Example 2
--  function <function_name>  (signal <signal_name> : in <type_declaration>;
--                         signal <signal_name>   : in <type_declaration>  ) return <type_declaration> is
--  begin
--    if (<signal_name> = '1') then
--      return <signal_name>;
--    else
--      return 'Z';
--    end if;
--  end <function_name>;



---- Procedure Example
--  procedure <procedure_name>  (<type_declaration> <constant_name>  : in <type_declaration>) is
--    
--  begin
--    
--  end <procedure_name>;


--------------------------------- Code Graveyard
-- Extracts even and odd pattern from in_pattern and returns the result of using an XNOR gate between both signals
--   function check20_XNOR( 
--	    in_pattern : std_logic_vector(19 downto 0);
--		 out_pattern: std_logic_vector(9 downto 0)) return std_logic;

--    function check20_XNOR (     
--    	  in_pattern : in std_logic_vector(19 downto 0);
--	     out_pattern : in std_logic_vector(9 downto 0)) --output signals from UUT 
--		   
--	 return std_logic is
--		  variable ist_pattern, soll_pattern,  even, odd : std_logic_vector(9 downto 0);
--		  variable res : std_logic;
--		  variable console : line;
--    begin
--	     even := get10_even(in_pattern);
--		  odd := get10_odd(in_pattern);
--        soll_pattern := even XNOR odd;
--		  if soll_pattern = out_pattern then 
--		     res := '1';
--		  else 
--		     res := '0';
--		  end if;
--		  
--	     return res;
--	 end function;
	 

