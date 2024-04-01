library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;
use WORK.PPU_CONTROL_REGS.all;
use WORK.ROMS.all;

entity PPU is 
	Port(
		-- input clocks
		clk50 	: in std_logic;
		cpu_clk  : in std_logic;
		-- reset
		rst 		: in std_logic;
		
		-- RGB output
		r	 		: out std_logic_vector(7 downto 0);
		g	 		: out std_logic_vector(7 downto 0);
		b	 		: out std_logic_vector(7 downto 0);
		
		-- VGA synchronization signals
		hsync		: out std_logic;
		vsync 	: out std_logic;
		
		-- VGA output clock
		clk_out	: out std_logic;
		
		
		-- PPU control IO
		DMA_WRITE		: in std_logic;
		DMA_DATA_IN		: in std_logic_vector(7 downto 0);
		--OAM_DMA_IN	 	: in std_logic_vector(7 downto 0);
		PPU_CTRL_IN 	: in PPU_REGS;
		PPU_UADDR		: in std_logic_vector(7 downto 0);
		PPU_XSCL			: in std_logic_vector(7 downto 0);
		PPU_WRITE		: in std_logic;
		PPU_CHR_OFFSET : in unsigned(0 downto 0);
		PPU_CLEAR		: in std_logic;
		PPU_STATUS_OUT : out std_logic_vector(7 downto 0);
		PPU_DATA_OUT   : out std_logic_vector(7 downto 0);
		
		-- Non Maskable Interrupt Enable
		NMIE		: out std_logic;
		
		-- HDMI Data Enable
		DE			: out std_logic
	
	);
end PPU;

architecture behav of PPU is
	
	-- horizontal VGA constants,
	--	display size, front porch, sync pulse, back porch
	constant hd 	: unsigned(9 downto 0) := to_unsigned(639, 10);
	constant hfp	: unsigned(4 downto 0) := to_unsigned(16, 5);
	constant hsp	: unsigned(6 downto 0) := to_unsigned(96, 7);
	constant hbp	: unsigned(5 downto 0) := to_unsigned(48, 6);
	
	-- vertical VGA constants,
	--	display size, front porch, sync pulse, back porch
	constant vd 	: unsigned(9 downto 0) := to_unsigned(479, 10);
	constant vfp	: unsigned(3 downto 0) := to_unsigned(10, 4);
	constant vsp	: unsigned(1 downto 0) := to_unsigned(2, 2);
	constant vbp	: unsigned(5 downto 0) := to_unsigned(33, 6);
	
	-- side bar size, VGA is 640x480, but the NES output will be 512x480
	-- 640x480 = (64 + 512 + 64)x480
	constant sb 	: unsigned(6 downto 0) := to_unsigned(64, 7);
	
	-- current row/col pointer for VGA
	signal row 		: unsigned(9 downto 0) := to_unsigned(0, 10);
	signal col 		: unsigned(9 downto 0) := to_unsigned(0, 10);
	
	-- CLK signals (differ from input clock)
	signal VGA_CLK : std_logic := '0'; -- 25 MHZ
	signal CLK_CNT : unsigned(1 downto 0) := to_unsigned(0, 2);
	
	signal OAM_COUNT 		: unsigned(7 downto 0) := to_unsigned(0, 8);
	
	signal FRAME_COUNTER : unsigned(7 downto 0) := to_unsigned(0, 8);
	
	
	-- PPU RAM/ROM data and initialization
	attribute ram_init_file : string;
	
	-- sprite OAM (Object Attribute Memory) registers
	--type OAM_REG_ARRAY is array (0 to 255) of std_logic_vector(7 downto 0); -- 64 sprite registers, 4 bytes each
	signal OAM_REGS : OAM_REG_ARRAY := OAM_REGS_TEST;
	
	--attribute ram_init_file of OAM_REGS : signal is "PPUtest2OAM.mif";
	
	-- registers for sprites that will be displayed this scan line 
	type SPRITE_REG_ARRAY is array (0 to 31) of std_logic_vector(7 downto 0);
	signal SPRITE_REGS : SPRITE_REG_ARRAY := (others=>(others=>'0'));
	
	signal SPRITE_CNT : unsigned(3 downto 0) := to_unsigned(0, 4);
	
	-- character rom (stores the game sprites)
	constant CHR_ROM : CHR_ROM_ARRAY := DONKEY_KONG_CHR_ROM;
	--attribute ram_init_file of CHR_ROM : signal is "games/test/nes_test_chr.mif";
	
	-- palette rom (stores the games color palettes)
	type PALETTE_ROM_ARRAY is array (0 to 31) of std_logic_vector(7 downto 0);
	signal PALETTE_ROM:PALETTE_ROM_ARRAY;-- := (others=>(others=>'0'));
	attribute ram_init_file of PALETTE_ROM : signal is "games/default_palette.mif"; --"PPUtestPALETTE_ROM.mif";
	
	-- stores the currently displayed background tiles (effectively VRAM)
	type NAME_TBL_ARRAY is array (0 to 3839) of std_logic_vector(7 downto 0);
	signal NAME_TBL:NAME_TBL_ARRAY := (others=>(others=>'0'));
	--attribute ram_init_file of NAME_TBL : signal is "PPUmultiTestNAME_TBL.mif";
	
	-- stores what palette to use for each background tile (effectively VRAM)
	type ATR_TBL_ARRAY is array (0 to 255) of std_logic_vector(7 downto 0);
	signal ATR_TBL:ATR_TBL_ARRAY := (others=>(others=>'0'));
	--attribute ram_init_file of ATR_TBL : signal is "PPUmultiTestATR_TBL.mif";
	
	-- conversion lookup table to convert the 6 bit NES color codes to 24 bit RGB
	type paletteLUT is array (0 to 63) of std_logic_vector(23 downto 0);
	constant RGB_CODES : paletteLUT := (x"7C7C7C",x"0000FC",x"0000BC",x"4428BC",x"940084",x"A80020",x"A81000",x"881400",x"503000",x"007800",x"006800",x"005800",x"004058",x"000000",x"000000",x"000000",
													x"BCBCBC",x"0078F8",x"0058F8",x"6844FC",x"D800CC",x"E40058",x"F83800",x"E45C10",x"AC7C00",x"00B800",x"00A800",x"00A844",x"008888",x"000000",x"000000",x"000000",
													x"F8F8F8",x"3CBCFC",x"6888FC",x"9878F8",x"F878F8",x"F85898",x"F87858",x"FCA044",x"F8B800",x"B8F818",x"58D854",x"58F898",x"00E8D8",x"787878",x"000000",x"000000",
													x"FCFCFC",x"A4E4FC",x"B8B8F8",x"D8B8F8",x"F8B8F8",x"F8A4C0",x"F0D0B0",x"FCE0A8",x"F8D878",x"D8F878",x"B8F8B8",x"B8F8D8",x"00FCFC",x"F8D8F8",x"000000",x"000000");
	
	signal NAME_DATA 	: std_logic_vector(7 downto 0) := x"00";
	signal ATR_DATA 	: std_logic_vector(7 downto 0) := x"00";
	signal YSCL			: std_logic_vector(7 downto 0) := x"00";
	
	type PIXEL_DATA is record
		PALETTE_IDX : std_logic_vector(2 downto 0);
		COLOR_IDX 	: std_logic_vector(1 downto 0);
	end record;
	
	
	impure function GET_BACKGROUND_PIXEL(constant X : in unsigned(7 downto 0); constant Y : in unsigned(7 downto 0)) return PIXEL_DATA is
	
		variable Y4X4			  : std_logic_vector(1 downto 0);
		variable COLOR_H_BYTE  : std_logic_vector(7 downto 0);
		variable COLOR_L_BYTE  : std_logic_vector(7 downto 0);
		variable BGRN_PTN_IDX  : unsigned(0 downto 0);
		variable BGRN_PIXEL    : PIXEL_DATA;
		
	begin
		BGRN_PTN_IDX := unsigned(PPU_CTRL_IN(PPU_CTRL_IDX)(4 downto 4));
		
		-- get the palette index (which color palette to use)
		Y4X4 := Y(4) & X(4);
		
		case Y4X4 is
			when "00" 	=> BGRN_PIXEL.PALETTE_IDX := "0" & ATR_DATA(1 downto 0);
			when "01" 	=> BGRN_PIXEL.PALETTE_IDX := "0" & ATR_DATA(3 downto 2);
			when "10" 	=> BGRN_PIXEL.PALETTE_IDX := "0" & ATR_DATA(5 downto 4);
			when "11" 	=> BGRN_PIXEL.PALETTE_IDX := "0" & ATR_DATA(7 downto 6);
			when others => BGRN_PIXEL.PALETTE_IDX := "0" & ATR_DATA(1 downto 0);
		end case;

		-- get the color data for the current pixel based on the associated tile
		COLOR_L_BYTE := CHR_ROM(to_integer(PPU_CHR_OFFSET & BGRN_PTN_IDX & unsigned(NAME_DATA) & "0" & Y(2 downto 0)));
		COLOR_H_BYTE := CHR_ROM(to_integer(PPU_CHR_OFFSET & BGRN_PTN_IDX & unsigned(NAME_DATA) & "1" & Y(2 downto 0)));
		
		BGRN_PIXEL.COLOR_IDX := COLOR_H_BYTE(to_integer(not X(2 downto 0))) & COLOR_L_BYTE(to_integer(not X(2 downto 0))); -- not x(2 downto 0) = 7 - x(2 downto 0)
		
		return BGRN_PIXEL;
	
	end GET_BACKGROUND_PIXEL;
	
	
	impure function GET_SPRITE_PIXEL(constant X : in unsigned(7 downto 0); constant Y : in unsigned(7 downto 0); constant IDX : integer range 0 to 31) return PIXEL_DATA is
		variable SPRITE_PIXEL : PIXEL_DATA;
	
		variable SPRITE_PTN_IDX   	: unsigned(0 downto 0);
		variable CHR_ROM_IDX   		: unsigned(7 downto 0);
		variable COLOR_H_BYTE  		: std_logic_vector(7 downto 0);
		variable COLOR_L_BYTE  		: std_logic_vector(7 downto 0);
		variable PIXEL_X		 		: unsigned(7 downto 0);
		variable PIXEL_Y		 		: unsigned(7 downto 0);
	
	begin
		SPRITE_PTN_IDX := unsigned(PPU_CTRL_IN(PPU_CTRL_IDX)(3 downto 3));
	
		SPRITE_PIXEL.PALETTE_IDX := "1" & SPRITE_REGS(IDX + 2)(1 downto 0);
		
		CHR_ROM_IDX := unsigned(SPRITE_REGS(IDX + 1)); -- change for 8x16 sprites
		
		PIXEL_X := X - unsigned(SPRITE_REGS(IDX + 3));
		PIXEL_Y := (Y - 1) - unsigned(SPRITE_REGS(IDX));
		
		-- flip horizontal 
		if (SPRITE_REGS(IDX + 2)(6 downto 6) = "1") then
			PIXEL_X(2 downto 0) := not PIXEL_X(2 downto 0);
		end if;
		
		-- flip vertical
		if (SPRITE_REGS(IDX + 2)(7 downto 7) = "1") then
			PIXEL_Y(2 downto 0) := not PIXEL_Y(2 downto 0);
		end if;
		
		-- get the color data for the current pixel based on the associated tile
		COLOR_L_BYTE := CHR_ROM(to_integer(PPU_CHR_OFFSET & SPRITE_PTN_IDX & CHR_ROM_IDX & "0" & PIXEL_Y(2 downto 0)));
		COLOR_H_BYTE := CHR_ROM(to_integer(PPU_CHR_OFFSET & SPRITE_PTN_IDX & CHR_ROM_IDX & "1" & PIXEL_Y(2 downto 0)));
		
		SPRITE_PIXEL.COLOR_IDX := COLOR_H_BYTE(to_integer(not unsigned(PIXEL_X(2 downto 0)))) & COLOR_L_BYTE(to_integer(not unsigned(PIXEL_X(2 downto 0))));
		
		return SPRITE_PIXEL;
	
	end GET_SPRITE_PIXEL;
	
	
	-- procedure to draw the required pixel to the VGA A/D based on values in VRAM/ROM
	procedure DRAW_PIXEL(constant CL : in unsigned(9 downto 0); constant RW : in unsigned(9 downto 0)) is
	
		--intermediate variable used to brake down the process into simpler steps
		variable X0				  : unsigned(9 downto 0);
		variable X				  : unsigned(7 downto 0);
		variable Y				  : unsigned(7 downto 0);
      variable COLOR_CODE	  : std_logic_vector(7 downto 0);
		variable COLOR			  : std_logic_vector(23 downto 0);
		
		variable PIXEL 	  		: PIXEL_DATA;
		variable BGRN_PIXEL 	  	: PIXEL_DATA;
		variable SPRITE_PIXEL 	: PIXEL_DATA;
		
		variable SPRITE_X				: unsigned(7 downto 0);
		variable FOUND_SPRITE		: std_logic := '0';
		variable CURRENT_SPRITE		: integer range 0 to 31 := 0;
		variable BGRN_PRIORITY		: std_logic;
	
	begin
		
		-- offset by sb to convert from 640x480 to 512x480 pixels
		X0 := CL - sb;
	
		-- convert from 512x480 -> 256x240 pixels, and offset by scroll registers
		-- X, Y are the location of the current pixel
		X := X0(8 downto 1);
		Y := RW(8 downto 1) + unsigned(YSCL);
		
		
		-- is there a sprite at this x,y pixel?
		for i in 0 to 7 loop
		
			if (SPRITE_CNT > i and X >= unsigned(SPRITE_REGS(4*i + 3)) and X < (unsigned(SPRITE_REGS(4*i + 3)) + 8)) then
			
				FOUND_SPRITE := '1';
				CURRENT_SPRITE := 4*i;
				
				EXIT;
				
			end if;
		
		end loop;
		
		X := X + unsigned(PPU_XSCL);
		
		-- get background pixel at this x,y
		BGRN_PIXEL := GET_BACKGROUND_PIXEL(X, Y);
		
		-- if no sprite use background pixel
		if(FOUND_SPRITE = '0') then
		
			PIXEL := BGRN_PIXEL;
			
		else
		
			-- determine priority of background vs sprite and choose the prioritised pixel
			BGRN_PRIORITY := SPRITE_REGS(CURRENT_SPRITE + 2)(5);
			SPRITE_PIXEL := GET_SPRITE_PIXEL(X, RW(8 downto 1), CURRENT_SPRITE);
			
			if (CURRENT_SPRITE = 0 and SPRITE_PIXEL.COLOR_IDX /= "00" and BGRN_PIXEL.COLOR_IDX /= "00" and PPU_CTRL_IN(PPU_MASK_IDX)(4 downto 3) = "11") then
				PPU_STATUS_OUT(6) <= '1';
			end if;
			
			if((BGRN_PRIORITY = '0' and SPRITE_PIXEL.COLOR_IDX /= "00") or (BGRN_PRIORITY = '1' and BGRN_PIXEL.COLOR_IDX = "00")) then
				PIXEL := SPRITE_PIXEL;
			else
				PIXEL := BGRN_PIXEL;
			end if;
		
		end if;
		
		-- use color index and palette index to get the pixel color code
		COLOR_CODE := PALETTE_ROM(to_integer(unsigned(PIXEL.PALETTE_IDX) & unsigned(PIXEL.COLOR_IDX)));
		
		-- convert color code to rgb color
		COLOR := RGB_CODES(to_integer(unsigned(COLOR_CODE(5 downto 0))));
		
		
		-- write color to VGA output
		r <= COLOR(23 downto 16);
		g <= COLOR(15 downto 8);
		b <= COLOR(7 downto 0);
		
	end DRAW_PIXEL;
	
	
	procedure SETUP_SPRITE_LINE(constant IDX : in unsigned(9 downto 0); constant RW : in unsigned(9 downto 0)) is
		variable SPRITE_IDX 	: unsigned(5 downto 0);
		variable Y				: unsigned(7 downto 0);
		variable OAM_Y			: unsigned(7 downto 0);
	
	begin
		SPRITE_IDX := IDX(5 downto 0); -- OAM sprite 0 - 63
		
		Y := RW(8 downto 1); -- sprite are offset by 1 in memory, so this is really checking the next line, not the current line
		
		OAM_Y := unsigned(OAM_REGS(to_integer(SPRITE_IDX & "00")));
		
		if (SPRITE_CNT < 8) then
		
			-- if sprite is on next line
			if(Y >= OAM_Y and Y < (OAM_Y + 8)) then
				
				SPRITE_REGS(to_integer(SPRITE_CNT(2 downto 0) & "00")) <= OAM_REGS(to_integer(SPRITE_IDX & "00"));
				SPRITE_REGS(to_integer(SPRITE_CNT(2 downto 0) & "01")) <= OAM_REGS(to_integer(SPRITE_IDX & "01"));
				SPRITE_REGS(to_integer(SPRITE_CNT(2 downto 0) & "10")) <= OAM_REGS(to_integer(SPRITE_IDX & "10"));
				SPRITE_REGS(to_integer(SPRITE_CNT(2 downto 0) & "11")) <= OAM_REGS(to_integer(SPRITE_IDX & "11"));
			
				SPRITE_CNT <= SPRITE_CNT + 1;
				
			end if;
		
		end if;
		
	
	end SETUP_SPRITE_LINE;
	
	

begin

	-- divide clk, 50MHz -> 25MHz
	clK_div:process(clk50)
	
	begin
		if(rising_edge(clk50)) then
					
			VGA_CLK <= not VGA_CLK;
			clk_out <= not VGA_CLK;
			
		end if;
	end process;
	
	
	vram:process(clk50)
	
		variable X0				: unsigned(9 downto 0);
		variable XTEMP			: unsigned(8 downto 0);
		variable YTEMP			: unsigned(8 downto 0);
		variable X				: unsigned(7 downto 0);
		variable Y				: unsigned(7 downto 0);
		variable NAME_IDX 	: unsigned(1 downto 0);
		variable NAME_OFFSET	: unsigned(11 downto 0);
		variable NAME_OFFSET2: unsigned(11 downto 0);
		variable addr 			: unsigned(13 downto 0);
		variable NAME_TBL_IDX : unsigned(11 downto 0);
		variable ATR_TBL_IDX : unsigned(7 downto 0);
		
	begin
		if (rising_edge(clk50)) then
			
			if (VGA_CLK = '1') then
				
				-- offset by sb to convert from 640x480 to 512x480 pixels
				X0 := col - sb;
			
				-- convert from 512x480 -> 256x240 pixels, and offset by scroll registers
				-- X, Y are the location of the current pixel
				XTEMP := ("0" & X0(8 downto 1)) + ("0" & unsigned(PPU_XSCL));
				YTEMP := ("0" & row(8 downto 1)) + ("0" & unsigned(YSCL));
				
				NAME_IDX := unsigned(PPU_CTRL_IN(PPU_CTRL_IDX)(1 downto 0));
				
				if (YTEMP > 239) then
					YTEMP := YTEMP - 240;
					NAME_IDX(1) := not NAME_IDX(1);
				end if;
				
				Y := YTEMP(7 downto 0);
				X := XTEMP(7 downto 0);
				
				if (XTEMP(8) = '1') then
					NAME_IDX(0) := not NAME_IDX(0);
				end if;
				
				case NAME_IDX is
					when "00" 	=> NAME_OFFSET := x"000";
					when "01" 	=> NAME_OFFSET := x"3C0"; -- 960
					when "10" 	=> NAME_OFFSET := x"780"; -- 2x960
					when "11" 	=> NAME_OFFSET := x"B40"; -- 3x960
					when others => NAME_OFFSET := x"000";
				end case;
				
				NAME_TBL_IDX := NAME_OFFSET + (Y(7 downto 3) & X(7 downto 3));
				ATR_TBL_IDX := NAME_IDX & Y(7 downto 5) & X(7 downto 5);
				
				--if (row > vd) then
				addr := unsigned(PPU_UADDR(5 downto 0)) & unsigned(PPU_CTRL_IN(PPU_ADDR_IDX));
						
				if (addr < x"2000") then
					PPU_DATA_OUT <= CHR_ROM(to_integer(addr(12 downto 0)));
				
--					elsif (addr >= x"2000" and addr < x"3F00") then
--					
--						case addr(11 downto 10) is
--							when "00" 	=> NAME_OFFSET2 := x"000";
--							when "01" 	=> NAME_OFFSET2 := x"3C0"; -- 960
--							when "10" 	=> NAME_OFFSET2 := x"000"; -- 2x960
--							when "11" 	=> NAME_OFFSET2 := x"3C0"; -- 3x960
--							when others => NAME_OFFSET2 := x"000";
--						end case;
--					
--					
--						if (addr(9 downto 0) < 960) then
--							-- Name table
--							PPU_DATA_OUT <= NAME_DATA;
--							NAME_TBL_IDX := NAME_OFFSET2 + addr(9 downto 0);
--							
--						else
--							-- Attribute table
--							PPU_DATA_OUT <= ATR_DATA;
--							ATR_TBL_IDX := addr(11 downto 10) & addr(5 downto 0);
--							
--						end if;
--					
--					elsif (addr >= x"3F00") then
--						PPU_DATA_OUT <= PALETTE_ROM(to_integer(addr(4 downto 0)));
						
				end if;
					
				--end if;
				
				
				-- lookup the tile idx for current pixel in the name table
				NAME_DATA <= NAME_TBL(to_integer(NAME_TBL_IDX));
				
				-- get the attribute data for the current pixel
				ATR_DATA <= ATR_TBL(to_integer(ATR_TBL_IDX));	
				
				
				if (PPU_WRITE = '1') then
				
					addr := unsigned(PPU_UADDR(5 downto 0)) & unsigned(PPU_CTRL_IN(PPU_ADDR_IDX));
								
					if (addr >= x"2000" and addr < x"3F00") then
					
						case addr(11 downto 10) is
							when "00" 	=> NAME_OFFSET2 := x"000";
							when "01" 	=> NAME_OFFSET2 := x"3C0"; -- 960
							when "10" 	=> NAME_OFFSET2 := x"780"; -- 2x960
							when "11" 	=> NAME_OFFSET2 := x"B40"; -- 3x960
							when others => NAME_OFFSET2 := x"000";
						end case;
					
					
						if (addr(9 downto 0) < 960) then
							-- Name table
							NAME_TBL(to_integer(NAME_OFFSET2 + addr(9 downto 0))) <= PPU_CTRL_IN(PPU_DATA_IDX);
							
						else
							-- Attribute table
							ATR_TBL(to_integer(addr(11 downto 10) & addr(5 downto 0))) <= PPU_CTRL_IN(PPU_DATA_IDX);
							
						end if;
					
					elsif (addr >= x"3F00") then
						PALETTE_ROM(to_integer(addr(4 downto 0))) <= PPU_CTRL_IN(PPU_DATA_IDX);
						
					end if;
					
					
				end if;
				
			end if;
				
		end if;
	end process;
	

	-- scroll the col pointer
	update_horizontal:process(VGA_CLK)
	begin
	
		if(rising_edge(VGA_CLK)) then
			if(col < hd + hfp + hsp + hbp) then
				col <= col + 1;
			else
				col <= to_unsigned(0, 10);
			end if;
			
		end if;
		
	end process;
	
	-- scroll the row pointer
	update_vertical:process(VGA_CLK)
	begin
	
		if(rising_edge(VGA_CLK)) then
		
			if(col = hd + hfp + hsp + hbp) then
				if(row < vd + vfp + vsp + vbp) then
					row <= row + 1;
				else
					row <= to_unsigned(0, 10);
				end if;
			end if;
			
		end if;
		
	end process;
	
	-- output horizontal and vertical sync signals according to VGA protocol
	update_sync:process(VGA_CLK)
	begin
	
		if(rising_edge(VGA_CLK)) then
			
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
	
	
	-- process to output rgb values to the VGA A/D
	output_rgb:process(VGA_CLK)
	begin
		if(rising_edge(VGA_CLK)) then			
		
			DE <= '0';
			
			if (PPU_CLEAR = '1') then
				PPU_STATUS_OUT(7) <= '0';
			end if;
		
			-- if drawing to the screen
			if(col <= hd and row <= vd) then
			
				if (col = 0 and row = 0) then
					PPU_STATUS_OUT(7 downto 5) <= "000";
				
				end if;
			
				DE <= '1';

				-- if inside the NES screen
				if (col >= sb and col <= hd - sb) then
					DRAW_PIXEL(col, row);

				-- if on the side bars 640x480 = (64 + 512 + 64)x480
				-- some VGA compatible montiors sample and calibrate their reference '0' voltage
				-- based on the value when not actively drawing, so the side bars can be any 
				-- value, as long as its not close to all "00". (i.e. you can't have black side bars)
				else
					r <= X"00";
					g <= X"00";
					b <= X"00";
				
				end if;

			-- not actively drawing, output all "00"
			else
			
				if(col = hd + 1 and row(0 downto 0) = 1) then
					SPRITE_CNT <= "0000";
					SPRITE_REGS <= (others=>(others=>'0'));
				end if;
				
				-- setup sprite to render on next scanline
				if(col > hd + 1 and col <= hd + 65 and row <= vd and row(0 downto 0) = 1) then
					SETUP_SPRITE_LINE((col - hd) - 2, row);
				end if;
			
				-- V-blank started
				if (row = vd + 1 and col < 28) then
					
					NMIE <= PPU_CTRL_IN(PPU_CTRL_IDX)(7);
					PPU_STATUS_OUT(7) <= '1';
						
				else
					
					if (row = vd + vfp + vsp + vbp and col < 28) then
						YSCL <= PPU_CTRL_IN(PPU_SCROLL_IDX);
					end if;
					
					NMIE <= '0';
				end if;
			
				r <= X"00";
				g <= X"00";
				b <= X"00";
			end if;
			
		end if;
	
	end process;
	
	
	oam_reg_update:process(cpu_clk, DMA_WRITE)
	begin
	
		if(falling_edge(cpu_clk)) then
		
			if (DMA_WRITE = '1') then
			
				OAM_REGS(to_integer(unsigned(PPU_CTRL_IN(OAM_ADDR_IDX)))) <= DMA_DATA_IN;
			
				OAM_COUNT <= OAM_COUNT + 1;
				
			end if;
		
		end if;
	
	end process;


end behav;




















