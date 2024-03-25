library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use WORK.ROMS.all;

entity audio_test is

	port 
	(
		CLK			: in std_logic;
		AUDIO_OUT1	: out unsigned(15 downto 0);
		AUDIO_OUT2	: out unsigned(15 downto 0)
	);

end audio_test;

architecture rtl of audio_test is

	signal a1 : unsigned(15 downto 0) := x"0000";
	signal a2 : unsigned(15 downto 0) := x"0000";
	signal delay  : unsigned(2 downto 0) := "000";
	signal count  : unsigned (13 downto 0) := to_unsigned(0, 14);
	signal flip   : std_logic := '1';

begin

	AUDIO_OUT1 <= a1;
	AUDIO_OUT2 <= a2;

	
	process(CLK)
	begin
	
		if(rising_edge(CLK)) then
		
			delay <= delay + 1;
			
			if (delay = 7) then
				count <= count + 1;
			
			elsif(delay = 0) then
				
				if (count < 3492 or count > 12891) then
					a1 <= x"0000";
					a2 <= x"0000";
				else
					a1 <= AUDIO_ROM(to_integer(count)) & x"00";
					a2 <= AUDIO_ROM(to_integer(count)) & x"00";
					
				end if;
			
			end if;
		
		end if;
	
	end process;
	
	
	
--	process(CLK)
--	begin
--	
--		if(rising_edge(CLK)) then
--		
--			if (count1 = x"FFFF" or count1 = x"0000") then
--				flip <= not flip;
--				
--				if (flip = '1') then
--					count1 <= count1 - 255;
--					count2 <= count2 - 255;
--				else
--					count1 <= count1 + 255;
--					count2 <= count2 + 255;
--				end if;
--				
--			elsif (flip = '1') then
--				count1 <= count1 + 255;
--				count2 <= count2 + 255;
--			else
--				count1 <= count1 - 255;
--				count2 <= count2 - 255;
--			end if;
--		
--		end if;
--	
--	end process;

end rtl;
