library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;

entity VGA_ADAPTER is 
	Port(
		clk 		: in std_logic;
		rst 		: in std_logic;
		r	 		: out std_logic_vector(7 downto 0);
		g	 		: out std_logic_vector(7 downto 0);
		b	 		: out std_logic_vector(7 downto 0);
		hsync		: out std_logic;
		vsync 	: out std_logic;
		clk_out	: out std_logic
	
	);
end VGA_ADAPTER;

architecture behav of VGa_ADAPTER is

	signal row : integer := 0;
	signal col : integer := 0;
	
	signal color : std_logic_vector(7 downto 0) := x"70";
	
	constant hd 	: integer := 639;
	constant hfp	: integer := 16;
	constant hsp	: integer := 96;
	constant hbp	: integer := 48;
	
	constant vd 	: integer := 479;
	constant vfp	: integer := 10;
	constant vsp	: integer := 2;
	constant vbp	: integer := 33;
	
	constant sb 	: integer := 64;

begin

--	reset:process(rst)
--	begin
--	
--		if(rst = '1')then
--			row <= 0;
--			col <= 0;
--			r <= X"00";
--			g <= X"00";
--			b <= X"00";
--			hsync <= '1';
--			vsync <= '1';
--		end if;
--		
--	end process;

	clk_out <= clk;
	
	
	update_horizontal:process(clk)
	begin
	
		if(rising_edge(clk)) then
			if(col < hd + hfp + hsp + hbp) then
				col <= col + 1;
			else
				col <= 0;
			end if;
		end if;
		
	end process;
	
	
	update_vertical:process(clk, col)
	begin
	
		if(rising_edge(clk)) then
		
			if(col = hd + hfp + hsp + hbp) then
				if(row < vd + vfp + vsp + vbp) then
					row <= row + 1;
				else
					row <= 0;
					color <= std_logic_vector(unsigned(color) + 1);
				end if;
			end if;
			
		end if;
		
	end process;
	
	
	update_sync:process(clk, col, row)
	begin
	
		if(rising_edge(clk)) then
			
			if(col <= (hd + hfp) or col > (hd + hfp + hsp)) then
				hsync <= '1';
			else
				hsync <= '0';
			end if;
			
			if(row <= (vd + vfp) or row > (vd + vfp + vsp)) then
				vsync <= '1';
			else
				vsync <= '0';
			end if;
			
		end if;
	
	end process;
	
	
	output_rgb:process(clk, col, row)
	begin
		if(rising_edge(clk)) then
		
			if(col >= sb and col <= hd - sb and row <= vd) then
				r <= color;
				g <= X"00";
				b <= color;
			else
				r <= X"00";
				g <= X"00";
				b <= X"00";
			end if;
			
		end if;
	
	end process;


end behav;