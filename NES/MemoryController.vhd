library ieee;
use ieee.std_logic_1164.all;

package PPU_CONTROL_REGS is 
	type PPU_REGS is array(0 to 7) of std_logic_vector(7 downto 0);
	constant PPU_CTRL_IDX 	: integer range 0 to 7 := 0;
	constant PPU_MASK_IDX 	: integer range 0 to 7 := 1;
	constant PPU_STATUS_IDX : integer range 0 to 7 := 2;
	constant OAM_ADDR_IDX 	: integer range 0 to 7 := 3;
	constant OAM_DATA_IDX	: integer range 0 to 7 := 4;
	constant PPU_SCROLL_IDX : integer range 0 to 7 := 5;
	constant PPU_ADDR_IDX 	: integer range 0 to 7 := 6;
	constant PPU_DATA_IDX 	: integer range 0 to 7 := 7;
	
end package;

library ieee;
use ieee.std_logic_1164.all;

package OTHER_CONTROL_REGS is 
	type OTHER_REGS is array(0 to 31) of std_logic_vector(7 downto 0);
	constant OAM_DMA_IDX 	: integer range 0 to 31 := 20;
end package;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;
use WORK.PPU_CONTROL_REGS.all;
use WORK.OTHER_CONTROL_REGS.all;

entity MemoryController is 
	port (
		
		PC_ADDR				: in std_logic_vector(15 downto 0);	
		RAM_ADDR 			: in std_logic_vector(15 downto 0) := x"0000";	
		RAM_DATA_IN 		: in std_logic_vector(7 downto 0);
		
		W						: in std_logic; -- 1 write
		R						: in std_logic; -- 0 PC, 1 RAM
		FCLK 					: in std_logic;
		
		HEX_OUT 				: out std_logic_vector(7 downto 0);
		RAM_DATA_OUT		: out std_logic_vector(7 downto 0);
		PPU_CTRL_OUT 		: out PPU_REGS;
		PPU_UADDR			: out std_logic_vector(7 downto 0);
		PPU_XSCL				: out std_logic_vector(7 downto 0);
		PPU_STATUS_in		: in std_logic_vector(7 downto 0);
		OTHER_CTRL_OUT		: out OTHER_REGS := (others=>(others=>'0'));
		HC_IN					: in std_logic_vector(7 downto 0);
		DMA_WRITE			: out std_logic := '0';
		PPU_WRITE			: out std_logic := '0';
		PPU_CHR_OFFSET 	: out std_logic := '0';
		PPU_CLEAR			: out std_logic := '0';
		PPU_DATA_IN			: in std_logic_vector(7 downto 0)
	
	);
end MemoryController;


architecture rtl of MemoryController is	

	attribute ram_init_file : string;
	
	type CPU_MEM_Array is array (0 to 8191) of std_logic_vector(7 downto 0); 
   signal CPU_MEM : CPU_MEM_Array := (others=>(others=>'0'));
	--attribute ram_init_file of CPU_MEM : signal is "multi_frame_test_vidor_cpu.mif"; 
	
   type MEM_Array is array (0 to 32767) of std_logic_vector(7 downto 0); 
   signal MEM : MEM_Array;
	attribute ram_init_file of MEM : signal is "games/Super Mario.mif"; -- replace with game ROM
	

	signal mainMem		: std_logic := '0';
	signal readAddr 	: unsigned(15 downto 0) := to_unsigned(0, 16);
	
	signal PPU_CTRL 	: PPU_REGS := (others=>(others=>'0'));
	signal OTHER_CTRL	: OTHER_REGS := (others=>(others=>'0'));
	
	signal OAM_TRANSFER 	: std_logic := '0';
	signal OAM_COUNT 		: unsigned (8 downto 0) := to_unsigned(0, 9);
	
	signal W_LATCH		: std_logic := '0';
	signal PW			: std_logic := '0';
	signal PR			: std_logic := '0';
	
	signal UADDR		: std_logic_vector(7 downto 0) := x"00";
	signal XSCL			: std_logic_vector(7 downto 0) := x"00";
	signal UPDATE_ADDR : std_logic := '0';
	signal CLEAR_DELAY : std_logic := '0';
	signal HC			: std_logic_vector(7 downto 0) := X"00";
	signal HC_BIT		: std_logic := '0';
	
	signal PPU_READ_FRONT_BUFFER : std_logic_vector(7 downto 0) := x"00";
	signal PPU_READ_BACK_BUFFER : std_logic_vector(7 downto 0) := x"00";
	
	
	procedure writeMem(signal addr : in std_logic_vector(15 downto 0)) is	
	begin
		
		if (addr < x"2000") then
			-- CPU RAM
			CPU_MEM(to_integer(unsigned(addr(10 downto 0)))) <= RAM_DATA_IN;
			
			if(addr = x"0007") then
				HEX_OUT <= RAM_DATA_IN;
			end if;
			
		elsif (addr < x"4000") then
			-- PPU registers
			
			if (addr(2 downto 0) = "111") then
				PW <= '1';
			end if;
			
			if (addr(2 downto 0) = "110" and W_LATCH = '0') then
				W_LATCH <= '1';
				UADDR <= RAM_DATA_IN;
				
			elsif (addr(2 downto 0) = "110" and W_LATCH = '1') then
				W_LATCH <= '0';
				PPU_CTRL(to_integer(unsigned(addr(2 downto 0)))) <= RAM_DATA_IN;
				
			elsif (addr(2 downto 0) = "101" and W_LATCH = '0') then
				W_LATCH <= '1';
				XSCL <= RAM_DATA_IN;

			elsif (addr(2 downto 0) = "101" and W_LATCH = '1') then
				W_LATCH <= '0';
				PPU_CTRL(to_integer(unsigned(addr(2 downto 0)))) <= RAM_DATA_IN;
				
			else
				PPU_CTRL(to_integer(unsigned(addr(2 downto 0)))) <= RAM_DATA_IN;
			end if;
			
			
		elsif (addr < x"4020") then
			-- IO/APU registers
			
			if (addr = x"4014") then
				OAM_TRANSFER <= '1';
			end if;
			
			if (addr = x"4016") then
				HC <= HC_IN;
			else
				OTHER_CTRL(to_integer(unsigned(addr(4 downto 0)))) <= RAM_DATA_IN;
			end if;
		
		else
			-- Cartridge space
			--PPU_CHR_OFFSET <= RAM_DATA_IN(0);
			MEM(to_integer(unsigned(addr) - x"8000")) <= RAM_DATA_IN;
			
		end if;
		

	end writeMem;
	
	
	procedure readMem(constant addr : in std_logic_vector(15 downto 0)) is
	begin
	
		mainMem <= '0';
		
		if (addr < x"2000") then
			-- CPU RAM
			readAddr <= "00000" & unsigned(addr(10 downto 0));
			
		elsif	(addr < x"4000") then
		-- PPU registers
		
			if (addr(2 downto 0) = "111") then
				PPU_READ_BACK_BUFFER <= PPU_DATA_IN;
				PPU_READ_FRONT_BUFFER <= PPU_READ_BACK_BUFFER;
				PR <= '1';
			end if;
		
			if (addr(2 downto 0) = "010") then
				W_LATCH <= '0';
			end if;
			
			if (addr(2 downto 0) = "010" and PPU_STATUS_in(7) = '1') then
				CLEAR_DELAY <= '1';
			end if;
		
			readAddr <= x"200" & "0" & unsigned(addr(2 downto 0));
			
		elsif (addr < x"4020") then
			-- IO/APU registers
			
			if (addr = x"4016") then
				HC_BIT <= HC(0);
				HC <= "0" & HC(7 downto 1);
			end if;
			
			readAddr <= x"40" & "000" & unsigned(addr(4 downto 0));
			
		else
			-- Cartridge space
			readAddr <= unsigned(addr) - x"8000";
			mainMem <= '1';
		
		end if;
	
	end readMem;
	
	
begin

	PPU_UADDR <= UADDR;
	PPU_XSCL  <= XSCL;

	process(FCLK, PPU_STATUS_in)
		variable addr : std_logic_vector(15 downto 0);
		variable temp : unsigned (15 downto 0);
	begin
		
		if(falling_edge(FCLK)) then
		
			PPU_CLEAR <= '0';
			
			if (CLEAR_DELAY = '1') then
				PPU_CLEAR <= '1';
				CLEAR_DELAY <= '0';
			end if;
			
		
			if (PW = '1') then
				UPDATE_ADDR <= '1';
				PW <= '0';
			end if;
			
			if (PR = '1') then
				UPDATE_ADDR <= '1';
				PR <= '0';
			end if;
			
			if (UPDATE_ADDR = '1') then
			
				UPDATE_ADDR <= '0';
			
				if (PPU_CTRL(PPU_CTRL_IDX)(2) = '0') then
					
					temp := (unsigned(UADDR) & unsigned(PPU_CTRL(PPU_ADDR_IDX))) + 1;
					
				else
					temp := (unsigned(UADDR) & unsigned(PPU_CTRL(PPU_ADDR_IDX))) + 32;
				
				end if;
				
				UADDR <= std_logic_vector(temp(15 downto 8));
				PPU_CTRL(PPU_ADDR_IDX) <= std_logic_vector(temp(7 downto 0));
			
			end if;
			
			if (OAM_TRANSFER = '1') then
				OAM_COUNT <= OAM_COUNT + 1;
				addr := OTHER_CTRL(OAM_DMA_IDX) & PPU_CTRL(OAM_ADDR_IDX);
				
				if (OAM_COUNT = x"FF") then
					OAM_TRANSFER <= '0';
				end if;
				
				if (OAM_COUNT(0) = '0') then
					DMA_WRITE <= '0';
					
				else
					PPU_CTRL(OAM_ADDR_IDX) <= std_logic_vector(unsigned(PPU_CTRL(OAM_ADDR_IDX) + 1));
					addr := OTHER_CTRL(OAM_DMA_IDX) & std_logic_vector(unsigned(PPU_CTRL(OAM_ADDR_IDX) + 1));
					DMA_WRITE <= '1';			
				end if;
				
			else
			
				DMA_WRITE <= '0';
			
				addr := PC_ADDR;
				
				-- Write
				if(W = '1') then
				
					writeMem(RAM_ADDR);
					
				-- Read
				elsif (R = '1') then
				
					addr := RAM_ADDR;
					
				end if;
				
			end if;
			
			readMem(addr);
		
		end if;
		
	end process;
	
	process(readAddr, mainMem, MEM, PPU_CTRL, OTHER_CTRL, HC_BIT)
	begin
		
		if(mainMem = '1') then
			-- Cartridge space
			RAM_DATA_OUT <= MEM(to_integer(readAddr));
		
		elsif (readAddr < x"2000") then
			-- CPU RAM
			RAM_DATA_OUT <= CPU_MEM(to_integer(readAddr(10 downto 0)));
			
		elsif	(readAddr < x"4000") then
			-- PPU registers
			
			if (readAddr(2 downto 0) = "010") then
			
				RAM_DATA_OUT <= PPU_STATUS_in;
			
			elsif(readAddr(2 downto 0) = "111") then
			
				RAM_DATA_OUT <= PPU_READ_FRONT_BUFFER;
			
			else
				RAM_DATA_OUT <= PPU_CTRL(to_integer(readAddr(2 downto 0)));
			
			end if;
			
		elsif (readAddr < x"4020") then
			-- IO/APU registers
			
			if (readAddr = x"4016") then
				RAM_DATA_OUT <= "0000000" & HC_BIT;
			else
				RAM_DATA_OUT <= OTHER_CTRL(to_integer(readAddr(4 downto 0)));
			end if;
		
		else
			RAM_DATA_OUT <= x"00";
		
		end if;
			
	end process;
	
	PPU_WRITE <= PW;
	PPU_CTRL_OUT <= PPU_CTRL;
	OTHER_CTRL_OUT <= OTHER_CTRL;
	
end rtl;




























