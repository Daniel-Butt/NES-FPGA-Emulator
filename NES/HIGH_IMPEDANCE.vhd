
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity HIGH_IMPEDANCE is

	generic
	(
		DATA_WIDTH : natural := 2
	);

	port 
	(
		Z : out std_logic_vector ((DATA_WIDTH-1) downto 0)
	);

end entity;

architecture rtl of HIGH_IMPEDANCE is
begin

	Z <= (others=>'Z');

end rtl;
