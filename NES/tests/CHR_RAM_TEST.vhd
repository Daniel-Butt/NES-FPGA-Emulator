
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;

entity CHR_RAM_TEST is

	generic 
	(
		DATA_WIDTH : natural := 8;
		ADDR_WIDTH : natural := 10
	);

	port 
	(
		clk		: in std_logic;
		addr_a	: in natural range 0 to 2**ADDR_WIDTH - 1;
		addr_b	: in natural range 0 to 2**ADDR_WIDTH - 1;
		data_a	: in std_logic_vector((DATA_WIDTH-1) downto 0);
		data_b	: in std_logic_vector((DATA_WIDTH-1) downto 0);
		we_a	: in std_logic := '1';
		q_a		: out std_logic_vector((DATA_WIDTH -1) downto 0);
		q_b		: out std_logic_vector((DATA_WIDTH -1) downto 0)
	);

end CHR_RAM_TEST;

architecture rtl of CHR_RAM_TEST is

	-- Build a 2-D array type for the RAM
	subtype word_t is std_logic_vector((DATA_WIDTH-1) downto 0);
	type memory_t is array(2**ADDR_WIDTH-1 downto 0) of word_t;

	-- Declare the RAM 
	shared variable ram : memory_t;
	
	signal clk2 : std_logic := '0';
	
	signal tempA : std_logic_vector((DATA_WIDTH -1) downto 0);
	signal tempB : natural range 0 to 2**ADDR_WIDTH - 1;

begin

	process(clk)
	begin
	
		if(falling_edge(clk)) then
		
			clk2 <= not clk2;
		
		end if;
	
	
	end process;
	

--	process(clk)
--	begin
--	
--		if(rising_edge(clk)) then
--		
--			if (clk2 = '0') then
--				tempA <= addr_a - 5;
--				tempB <= addr_b + 7;
--			end if;
--			
--		end if;
--	
--	
--	end process;

	q_a <= tempA;

	-- Port A
	process(clk)
	begin
	
		if(rising_edge(clk)) then	
		
			if(we_a = '1') then
					ram(addr_a) := data_a;
				end if;
		
			if (clk2 = '0') then
				
				tempA <= ram(addr_a + 7);
				
			else
				tempA <= ram(addr_b - 5);
			
			end if;
			
		end if;	
		
	end process;

		-- Port B 
--	process(clk)
--	begin
--	
--		if(rising_edge(clk)) then 
--			
--			if (clk2 = '1') then
--			
--				q_b <= ram(addr_b + 7);
--				
--			else
--				
--			end if;
--			 
--		end if;
--		
--	end process;

end rtl;
