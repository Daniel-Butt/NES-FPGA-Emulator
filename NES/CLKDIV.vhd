library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;

entity CLKDIV is 
	port (
		
		CLK_IN : in std_logic;
		DIV	: in unsigned(4 downto 0);
		CLK_OUT: inout std_logic

	);
end CLKDIV;


architecture rtl of CLKDIV is
	signal CNT : unsigned(4 downto 0) := "00000";

begin

	process(CLK_IN)
	begin
		
		if(rising_edge(CLK_IN)) then
			
			CNT <= CNT + 1;
			
			if (CNT = DIV) then
				CNT <= "00000";
				
				CLK_OUT <= not CLK_OUT;
				
			end if;
		
		end if;
		
	end process;


end rtl;