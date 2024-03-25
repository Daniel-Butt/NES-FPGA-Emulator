library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;

USE WORK.opcodes.all;

entity CPU_6502 is 
	Port(
		-- cpu clock
		CLK 		: in std_logic;
		
		-- reset CPU
		RESET		: in std_logic;
		
		-- hold (pause) CPU
		HOLD		: in std_logic;
		
		-- NMIE non maskable interrupt enable
		NMIE		: in std_logic;
			
		-- program counter
		PC			: inout std_logic_vector(15 downto 0);
		
		-- ram address
		ADDR		: inout std_logic_vector(15 downto 0);
		
		-- ram data out (write)
		DATA_OUT	: out std_logic_vector(7 downto 0);
		
		-- ram data in (write)
		DATA_IN	: in std_logic_vector(7 downto 0);

		-- 1 means write to RAM and read PC addr 
		W	: out std_logic;
		
		-- 0 read PC addr, 1 read ram addr (W takes priority ^);
		R	: out std_logic
	
	);
end CPU_6502;

architecture RTL of CPU_6502 is
	type state_type is
	(
		INIT0,			-- initalization state 
		INIT1,			-- initalization state
		INIT2,			-- initalization state
		FETCH,			-- fetch opcode
		EXECUTE,			-- execute instruction
		WAIT_OAM,		-- wait for OAM DMA register transfer
		HOLD_STATE,		-- hold (pause) cpu execution for debugging purposes
		HALT_STATE		-- permanently stop CPU
	);
	
	type op_addr_mode is
	(
		IMPLIED,			-- implied single byte instruction
		ABSOLUTE,		-- absolute addressed
		ABSOLUTE_X,		-- absolute addressed offset by X
		ABSOLUTE_Y,		-- absolute addressed offset by Y
		IMMEDIATE,		-- immediate value
		INDIRECT,		-- indirect absolute
		X_INDIRECT,		-- indirect absolute address preoffset by X
		INDIRECT_Y,		-- indirect absolute address postoffset by Y
		RELATIVE,		-- relative (branching)
		ZPG,				-- zero page
		ZPG_X,			-- zero page offset by X
		ZPG_Y				-- zero page offset by Y

	);
	
	type nmi_type is (STANDBY, CALLED);
	
	signal CPU_STATE 		: state_type := INIT0;
	signal OP_TYPE			: op_addr_mode	:= IMPLIED;
	signal IR		 		: std_logic_vector(7 downto 0);
	signal M					: std_logic_vector(15 downto 0); -- internal memory address / data register
	signal SP				: std_logic_vector(7 downto 0); 	-- stack pointer offset (stack is x100 - x1FF)
	signal A					: std_logic_vector(7 downto 0);	
	signal X					: std_logic_vector(7 downto 0);
	signal Y					: std_logic_vector(7 downto 0);	
	signal flags			: std_logic_vector(7 downto 0); --Negative(N), Overflow(V), ignored(?), Break(B), Decimal BCD(D), Interrupt(I), Zero (Z), Carry (C) 

	signal EX_CYCLE			: std_logic_vector(2 downto 0); -- at most 7 cycles per instruction, 1 to fetch, 6 to execute
	signal page_crossed  	: std_logic;
	signal page_corrected  	: std_logic;
	
	constant NMI_ADDR : unsigned(15 downto 0) := x"FFFA";
	constant RESET_ADDR : unsigned(15 downto 0) := x"FFFC";
	constant IRQ_ADDR : unsigned(15 downto 0) := x"FFFE";
	signal NMI_STATE : nmi_type := STANDBY;
	
	signal OAM_COUNT : unsigned(9 downto 0) := to_unsigned(0, 10);

	
	-- check if negative and zero flags should be set
	procedure CNZ(variable t : inout std_logic_vector(8 downto 0)) is
	begin
		-- if negative
		flags(7) <= t(7);
			
		-- if zero
		if(t(7 downto 0) = x"00")then
			flags(1) <= '1';
		else
			flags(1) <= '0';
		end if;
	end CNZ;
	
	-- correct upper byte of address
	procedure CORRECT_PAGE(variable t : inout std_logic_vector(8 downto 0)) is
	begin
		t(7 downto 0) := std_logic_vector(unsigned(M(15 downto 8)) + 1);
		M(15 downto 8) <= t(7 downto 0);
		ADDR <= t(7 downto 0) & M(7 downto 0);
		R <= '1';
		page_crossed <= '0';
		page_corrected <= '1';
		EX_CYCLE <= EX_CYCLE;
		
	end CORRECT_PAGE;
	
	--load instruction
	procedure LOAD(signal R1 : out std_logic_vector(7 downto 0); variable t : inout std_logic_vector(8 downto 0)) is
	begin
		R1 <= DATA_IN;
		t(7 downto 0) := DATA_IN;
										
		CNZ(t);
		
		CPU_STATE <= FETCH;
	
	end LOAD;
	
	--Store instruction
	procedure STORE(signal R1 : in std_logic_vector(7 downto 0)) is
	begin
		
		if(page_corrected = '1') then
			page_corrected <= '0';
			ADDR <= ADDR;
		
		else
			W <= '1';
			ADDR <= ADDR;
			DATA_OUT <= R1;
			
			if(ADDR = x"4014") then
				CPU_STATE <= WAIT_OAM;
			else
				CPU_STATE <= FETCH;
			end if;
			
		end if;
	
	end STORE;
	
	
	--logical shift right instruction
	procedure LSR(signal R1 : in std_logic_vector(7 downto 0); signal R2 : out std_logic_vector(7 downto 0); constant F : in std_logic) is
	begin
		R2 <= '0' & R1(7 downto 1);
		
		if(F = '1') then
			W <= '1';
			ADDR <= ADDR;
		end if;
		
		flags(7) <= '0';
		flags(0) <= R1(0);
		
		if(R1(7 downto 1) = "0000000")then
			flags(1) <= '1';
		else
			flags(1) <= '0';
		end if;
		
	end LSR;
	
	--Arithmetic shift left instruction
	procedure ASL(signal R1 : in std_logic_vector(7 downto 0); signal R2 : out std_logic_vector(7 downto 0); constant F : in std_logic) is
	begin
		R2 <= R1(6 downto 0) & '0';
		
		if(F = '1') then
			W <= '1';
			ADDR <= ADDR;
		end if;
		
		flags(7) <= R1(6);
		flags(0) <= R1(7);
		
		if(R1(6 downto 0) = "0000000")then
			flags(1) <= '1';
		else
			flags(1) <= '0';
		end if;
		
	end ASL;
	
	--Rotate left
	procedure RML(signal R1 : in std_logic_vector(7 downto 0); signal R2 : out std_logic_vector(7 downto 0); constant F : in std_logic) is
	begin
		R2 <= R1(6 downto 0) & flags(0);
		
		if(F = '1') then
			W <= '1';
			ADDR <= ADDR;
		end if;
		
		flags(7) <= R1(6);
		flags(0) <= R1(7);
		
		if(R1(6 downto 0) & flags(0) = "0000000")then
			flags(1) <= '1';
		else
			flags(1) <= '0';
		end if;
		
	end RML;
	
	--Rotate right
	procedure RMR(signal R1 : in std_logic_vector(7 downto 0); signal R2 : out std_logic_vector(7 downto 0); constant F : in std_logic) is
	begin
		R2 <= flags(0) & R1(7 downto 1);
		
		if(F = '1') then
			W <= '1';
			ADDR <= ADDR;
		end if;
		
		flags(7) <= flags(0);
		flags(0) <= R1(0);
		
		if(flags(0) & R1(7 downto 1) = "0000000")then
			flags(1) <= '1';
		else
			flags(1) <= '0';
		end if;
		
	end RMR;
	
	-- transfer instruction
	procedure TSF(signal R1 : in std_logic_vector(7 downto 0); signal R2 : out std_logic_vector(7 downto 0); constant F : in std_logic; variable t : inout std_logic_vector(8 downto 0)) is
	begin
		R2 <= R1;
					 
		if(F = '1') then
			t(7 downto 0) := R1;
			CNZ(t);
			
		end if;
		
		CPU_STATE <= FETCH;
	
	end TSF;
	
	-- OR with A instruction
	procedure ORA(signal AA : inout std_logic_vector(7 downto 0); variable t : inout std_logic_vector(8 downto 0)) is
	begin
		t(7 downto 0) := AA OR DATA_IN;
		AA <= t(7 downto 0);
										
		CNZ(t);
		
		CPU_STATE <= FETCH;
	end ORA;
	
	-- EOR with A instruction
	procedure EORA(signal AA : inout std_logic_vector(7 downto 0); variable t : inout std_logic_vector(8 downto 0)) is
	begin
		t(7 downto 0) := AA XOR DATA_IN;
		AA <= t(7 downto 0);
										
		CNZ(t);
		
		CPU_STATE <= FETCH;
	end EORA;
	
	-- AND with A instruction
	procedure ANDA(signal AA : inout std_logic_vector(7 downto 0); variable t : inout std_logic_vector(8 downto 0)) is
	begin
		t(7 downto 0) := AA AND DATA_IN;
		AA <= t(7 downto 0);
										
		CNZ(t);
		
		CPU_STATE <= FETCH;
	end ANDA;
	
	--PUSH to stack
	procedure PUSH(signal R1 : in std_logic_vector(7 downto 0); constant F : in std_logic) is
	begin
		case EX_CYCLE is
			when "000" =>
				W <= '1';
				ADDR <= x"01" & SP;
				
				if(F = '0') then
					DATA_OUT <= R1;
				else
					DATA_OUT <= R1(7 downto 6) & "11" & R1(3 downto 0);
				end if;
				
			when "001" =>
				SP <= std_logic_vector(unsigned(SP) - 1);
				CPU_STATE <= FETCH;
				
			when others =>
			
		end case;
	end PUSH;
	
	--POP from stack
	procedure POP(signal R1 : inout std_logic_vector(7 downto 0); constant F : in std_logic; variable t : inout std_logic_vector(8 downto 0)) is
	begin
		case EX_CYCLE is
			when "000" =>
				SP <= std_logic_vector(unsigned(SP) + 1);
				
			when "001" =>
				R <= '1';
				ADDR <= x"01" & SP;
				
			when "010" =>
				if(F = '0') then
					R1 <= DATA_IN;
					t(7 downto 0) := DATA_IN;
					CNZ(t);
				else
					R1 <= DATA_IN(7 downto 6) & R1(5 downto 4) & DATA_IN(3 downto 0);
				end if;
				
				CPU_STATE <= FETCH;
				
			when others =>
		end case;
	end POP;
	
	-- set flag
	procedure SETFLAG(signal R1 : out std_logic_vector(0 downto 0)) is
	begin
		R1 <= "1";
		CPU_STATE <= FETCH;
	end SETFLAG;
	
	-- clear flag
	procedure CLEARFLAG(signal R1 : out std_logic_vector(0 downto 0)) is
	begin
		R1 <= "0";
		CPU_STATE <= FETCH;
	end CLEARFLAG;
	
	-- check flag for branch, return to fetch if should not branch
	procedure CHECKFLAG(constant R1 : in std_logic_vector(0 downto 0)) is
	begin
		
		if(R1 = "0")then
			
			CPU_STATE <= FETCH;
			
		end if;
		
	end CHECKFLAG;
	
	-- Decrement reg or memory
	procedure DEC(signal R1 : in std_logic_vector(7 downto 0); signal R2 : out std_logic_vector(7 downto 0); constant F : in std_logic; variable t : inout std_logic_vector(8 downto 0)) is
	begin
		t(7 downto 0) := std_logic_vector(signed(R1) - 1);
		R2 <= t(7 downto 0);
		
		if(F = '1') then
			W <= '1';
			ADDR <= ADDR;
		else
			CPU_STATE <= FETCH;
		end if;
		
		CNZ(t);
		
	end DEC;
	
	-- Increment reg or memory
	procedure INC(signal R1 : in std_logic_vector(7 downto 0); signal R2 : out std_logic_vector(7 downto 0); constant F : in std_logic; variable t : inout std_logic_vector(8 downto 0)) is
	begin
		t(7 downto 0) := std_logic_vector(signed(R1) + 1);
		R2 <= t(7 downto 0);
		
		if(F = '1') then
			W <= '1';
			ADDR <= ADDR;
		else
			CPU_STATE <= FETCH;
		end if;
		
		CNZ(t);
		
	end INC;
	
	-- Add to A
	procedure ADD(variable t : inout std_logic_vector(8 downto 0)) is
	begin
		t := std_logic_vector(unsigned("0" & A) + unsigned("0" & DATA_IN) + unsigned(flags(0 downto 0)));
		A <= t(7 downto 0);
		
		flags(0) <= t(8);
		
		flags(6) <= (A(7) AND (DATA_IN(7)) AND (NOT t(7))) OR ((NOT A(7)) AND (NOT DATA_IN(7)) AND t(7));
		
		CNZ(t);
		
		CPU_STATE <= FETCH;
	end ADD;
	
	
	-- Subtract from A
	procedure SUB(variable t : inout std_logic_vector(8 downto 0)) is
	begin
		t := std_logic_vector(unsigned("0" & A) + unsigned("0" & NOT DATA_IN) + unsigned(flags(0 downto 0)));
		A <= t(7 downto 0);
		
		flags(0) <= t(8);
		
		flags(6) <= (A(7) AND (Not DATA_IN(7)) AND (NOT t(7))) OR ((NOT A(7)) AND (DATA_IN(7)) AND t(7));
		
		CNZ(t);
		
		CPU_STATE <= FETCH;
	end SUB;
	
	--Compare
	procedure CMP(signal R1 : in std_logic_vector(7 downto 0); variable t : inout std_logic_vector(8 downto 0)) is
	begin
		t := std_logic_vector(unsigned("0" & R1) + unsigned("0" & NOT DATA_IN) + 1);
		
		flags(0) <= t(8);
		
		CNZ(t);
	
		CPU_STATE <= FETCH;
	end CMP;
	
	-- Bit test
	procedure BT(signal AA : in std_logic_vector(7 downto 0)) is
	begin
		
		flags(7) <= DATA_IN(7);
		flags(6) <= DATA_IN(6);
		
		if ((AA AND DATA_IN) = x"00") then
			flags(1) <= '1';
		else
			flags(1) <= '0';
		end if;
		
		CPU_STATE <= FETCH;
	end BT;
	
	

begin

	
	-- during the fetch cycle, also decode the instructions addressing type 
	decode:process(CLK)
	begin
		if(rising_edge(CLK)) then
		
			if(CPU_STATE = FETCH) then
				
				-- This is probably not the cleanest way of decoding 6502 instructions, but one could also argue the 6502
				-- has less than straight forward opcode assignments when compared to something like RISC-V processors.
				-- See the 6502 instruction set for more information
				
				-- Implied single byte instruction
				if(NMI_STATE = CALLED or DATA_IN(7 downto 0) = x"00" or DATA_IN(7 downto 0) = x"40" or DATA_IN(7 downto 0) = x"60" or DATA_IN(3 downto 0) = x"8" or DATA_IN(3 downto 0) = x"A") then
					OP_TYPE <= IMPLIED;
					
				-- Zero page
				elsif(DATA_IN(3 downto 0) = x"4" or DATA_IN(3 downto 0) = x"5" or DATA_IN(3 downto 0) = x"6") then
				
					--Zero page Y indexed
					if (DATA_IN(7 downto 0) = x"96" or DATA_IN(7 downto 0) = x"B6") then
					
						OP_TYPE <= ZPG_Y;
						
					-- Zero page X indexed
					elsif(DATA_IN(4) = '1') then
					
						OP_TYPE <= ZPG_X;
						
					-- Zero page
					else
					
						OP_TYPE <= ZPG;

					end if;
					
				-- Indirect indexed
				elsif(DATA_IN(3 downto 0) = x"1") then
				
					if(DATA_IN(4) = '0') then
					
						OP_TYPE <= X_INDIRECT;
						
					else
					
						OP_TYPE <= INDIRECT_Y;
						
					end if;
				
				-- Relative
				elsif(DATA_IN(4 downto 0) = "10000") then
					OP_TYPE <= RELATIVE;
				
				-- Indirect
				elsif(DATA_IN(7 downto 0) = x"6C") then
					OP_TYPE <= INDIRECT;
				
				-- Immediate
				elsif(DATA_IN(4 downto 0) = x"9" or DATA_IN(7 downto 0) = x"A0" or DATA_IN(7 downto 0) = x"A2" or DATA_IN(7 downto 0) = x"C0" or DATA_IN(7 downto 0) = x"E0") then
					OP_TYPE <= IMMEDIATE;
					
				--absolute
				else
					-- Y indexed
					if(DATA_IN(3 downto 0) = x"9" or DATA_IN(7 downto 0) = x"BE") then
					
						OP_TYPE <= ABSOLUTE_Y;

					--X indexed
					elsif(DATA_IN(4) = '1') then
					
						OP_TYPE <= ABSOLUTE_X;
						
					else
					
						OP_TYPE <= ABSOLUTE;
					end if;	
				
				end if;
				
			end if;
		end if;
	end process;
	

	--state execution process
	process(CLK, RESET, NMIE)
		variable temp : std_logic_vector(8 downto 0); --9 bit temporary variable to store intermediate values
	Begin
	
		if (NMIE = '1') then
			NMI_STATE <= CALLED;
	
		--reset CPU
		elsif (RESET = '1') then
			CPU_STATE <= INIT0;
	
		elsif (rising_edge(CLK)) then
			
			case CPU_STATE is
					
					when INIT0 =>
						IR <= x"00";
						M <= x"0000";
						A <= x"00";
						X <= x"00";
						Y <= x"00";
						flags <= x"00";
						PC <= x"0000"; -- use RESET vector to set cartridge start addr on NES
						SP <= x"00";   -- remember this is only an offset (stack is 0x100 - 0x1FF)
						ADDR <= std_logic_vector(RESET_ADDR);
						R <= '1';
						W <= '0'; 
						page_crossed <= '0';

						CPU_STATE <= INIT1;
						
					when INIT1 =>
						ADDR <= std_logic_vector(RESET_ADDR + 1);
						PC(7 downto 0) <= DATA_IN;
						CPU_STATE <= INIT2;
					
					when INIT2 =>
						PC(15 downto 8) <= DATA_IN;
						R <= '0';
						ADDR <= x"0000";
						CPU_STATE <= FETCH;
						
					when WAIT_OAM =>
						W <= '0';
						OAM_COUNT <= OAM_COUNT + 1;
						
						if (OAM_COUNT = 512) then
							OAM_COUNT <= to_unsigned(0, 10);
							CPU_STATE <= FETCH;
						end if;
								
					when FETCH =>
						R <= '0';
						W <= '0';
						M <= x"0000";
						EX_CYCLE <= "000";
						page_corrected <= '0';
						
						
						if (HOLD = '1') then
							CPU_STATE <= HOLD_STATE;
							
						elsif (NMI_STATE = CALLED) then
							--NMI_CALLED <= '0';
							--CPU_STATE <= HANDLE_NMI0;
							IR <= BRK_IMPL;
							CPU_STATE <= EXECUTE;
							--OP_TYPE <= IMPLIED;
							
						else
							IR <= DATA_IN;
							PC <= std_logic_vector(unsigned(PC) + 1);
							CPU_STATE <= EXECUTE;
						end if;
						
					
					when EXECUTE =>
						R <= '0'; -- by default, read from PC
						W <= '0'; -- by default, don't write to RAM
						EX_CYCLE <= std_logic_vector(unsigned(EX_CYCLE) + 1); --by default increment 

						case OP_TYPE is
						
							when IMPLIED =>	
								case IR is
									when ASL_A =>
										ASL(A,A,'0');	
										CPU_STATE <= FETCH;
									
									when ROL_A =>
										RML(A, A, '0');
										CPU_STATE <= FETCH;
									
									when LSR_A =>
										LSR(A,A,'0');	
										CPU_STATE <= FETCH;
									
									when ROR_A =>
										RMR(A, A, '0');
										CPU_STATE <= FETCH;
									
									when TXA_IMPL =>
										TSF(X,A,'1',temp);
												
									when TXS_IMPL =>
										TSF(X,SP,'0',temp);
									
									when TAX_IMPL =>
										TSF(A,X,'1',temp);
									
									when TSX_IMPL =>
										TSF(SP,X,'1',temp);
									
									when TYA_IMPL =>
										TSF(Y,A,'1',temp);
									
									when TAY_IMPL =>
										TSF(A,Y,'1',temp);
									
									when DEX_IMPL =>
										DEC(X,X,'0',temp);
									
									when DEY_IMPL =>
										DEC(Y,Y,'0',temp);
									
									when INX_IMPL =>
										INC(X,X,'0',temp);
									
									when INY_IMPL =>
										INC(Y,Y,'0',temp);
									
									when PHA_IMPL =>
										PUSH(A, '0');
									
									when PHP_IMPL =>
										PUSH(flags, '1');
									
									when PLA_IMPL =>
										POP(A, '0',temp);
									
									when PLP_IMPL =>
										POP(flags, '1',temp); 

									when SEC_IMPL =>
										SETFLAG(flags(0 downto 0));
										
									when SEI_IMPL =>
										SETFLAG(flags(2 downto 2));
										
									when SED_IMPL =>
										SETFLAG(flags(3 downto 3));
										
									when CLC_IMPL =>
										CLEARFLAG(flags(0 downto 0));

									when CLI_IMPL =>
										CLEARFLAG(flags(2 downto 2));

									when CLV_IMPL =>
										CLEARFLAG(flags(6 downto 6));

									when CLD_IMPL =>
										CLEARFLAG(flags(3 downto 3));
									
									when BRK_IMPL =>
									
										case EX_CYCLE is
											when "000" =>
												W <= '1';
												ADDR <= x"01" & SP;
												DATA_OUT <= PC(15 downto 8);
												SP <= std_logic_vector(unsigned(SP) - 1);
												
											when "001" =>
												W <= '1';
												ADDR <= x"01" & SP;
												DATA_OUT <= PC(7 downto 0);
												SP <= std_logic_vector(unsigned(SP) - 1);
												
											when "010" =>
												W <= '1';
												ADDR <= x"01" & SP;
												DATA_OUT <= flags(7 downto 5) & '1' & flags(3) & '1' & flags(1 downto 0);
												SP <= std_logic_vector(unsigned(SP) - 1);
												
											when "011" =>
												R <= '1';
												
												if(NMI_STATE = CALLED) then
													ADDR <= std_logic_vector(NMI_ADDR);
												else
													ADDR <= std_logic_vector(IRQ_ADDR);
												end if;
											
											when "100" =>
												R <= '1';
												
												if(NMI_STATE = CALLED) then
													ADDR <= std_logic_vector(NMI_ADDR + 1);
													NMI_STATE <= STANDBY;
												else
													ADDR <= std_logic_vector(IRQ_ADDR + 1);
												end if;
												
												PC(7 downto 0) <= DATA_IN;
												
											when others =>
												PC(15 downto 8) <= DATA_IN;
												CPU_STATE <= FETCH;
										end case;
									
									when RTI_IMPL =>
										case EX_CYCLE is
											when "000" =>
												SP <= std_logic_vector(unsigned(SP) + 1);
												
											when "001" =>
												R <= '1';
												ADDR <= x"01" & SP;
												SP <= std_logic_vector(unsigned(SP) + 1);
												
											when "010" =>
												R <= '1';
												ADDR <= x"01" & SP;
												SP <= std_logic_vector(unsigned(SP) + 1);
												flags <= DATA_IN(7 downto 6) & flags(5 downto 4) & DATA_IN(3 downto 0);
												
											when "011" =>
												R <= '1';
												ADDR <= x"01" & SP;
												PC(7 downto 0) <= DATA_IN;
											
											when "100" =>
												PC(15 downto 8) <= DATA_IN;
												CPU_STATE <= FETCH;
												
											when others =>
										end case;
									
									when RTS_IMPL =>
										case EX_CYCLE is
											when "000" =>
												SP <= std_logic_vector(unsigned(SP) + 1);
												
											when "001" =>
												R <= '1';
												ADDR <= x"01" & SP;
												SP <= std_logic_vector(unsigned(SP) + 1);
												
											when "010" =>
												R <= '1';
												ADDR <= x"01" & SP;
												PC(7 downto 0) <= DATA_IN;
												
											when "011" =>
												PC(15 downto 8) <= DATA_IN;
												
											when "100" =>
												PC <= std_logic_vector(unsigned(PC) + 1);
												CPU_STATE <= FETCH;
												
											when others =>
										end case;

									when NOP_IMPL =>
										CPU_STATE <= FETCH;

									when others =>
										CPU_STATE <= FETCH;
								end case;

							when IMMEDIATE => -- DATA_IN is the immediate value
								PC <= std_logic_vector(unsigned(PC) + 1);

								case IR is
									when LDA_IMM =>
										LOAD(A,temp);

									when LDY_IMM =>
										LOAD(Y,temp);

									when LDX_IMM =>
										LOAD(X,temp);

									when ORA_IMM =>
										ORA(A,temp);

									when AND_IMM =>
										ANDA(A,temp);

									when EOR_IMM =>
										EORA(A,temp);

									when ADC_IMM =>
										ADD(temp);

									when CPY_IMM =>
										CMP(Y,temp);

									when CMP_IMM =>
										CMP(A,temp);

									when CPX_IMM =>
										CMP(X,temp);

									when SBC_IMM =>
										SUB(temp);
									
									when others =>
										CPU_STATE <= FETCH;
								end case;

							when RELATIVE =>
								case EX_CYCLE is
									when "000" => -- check branch condition, goto fetch if false
										PC <= std_logic_vector(unsigned(PC) + 1);
										M(7 downto 0) <= DATA_IN; -- branch offset is in DATA_IN

										case IR is
											when BCS_REL =>
												CHECKFLAG(flags(0 downto 0));

											when BPL_REL =>
												CHECKFLAG(NOT flags(7 downto 7));

											when BMI_REL =>
												CHECKFLAG(flags(7 downto 7));

											when BVC_REL =>
												CHECKFLAG(NOT flags(6 downto 6));

											when BVS_REL =>
												CHECKFLAG(flags(6 downto 6));

											when BCC_REL =>
												CHECKFLAG(NOT flags(0 downto 0));

											when BNE_REL =>
												CHECKFLAG(NOT flags(1 downto 1));

											when BEQ_REL =>
												CHECKFLAG(flags(1 downto 1));
											
											when others =>
												CPU_STATE <= FETCH;
										end case;

									when "001" => -- branch if condition true PC (if page not crossed goto fetch)
										temp := std_logic_vector(unsigned('0' & PC(7 downto 0)) + unsigned(M(7 downto 0)));
										PC(7 downto 0) <= temp(7 downto 0);

										if((temp(8) XNOR M(7)) = '1')then
											CPU_STATE <= FETCH;
										end if;

									when "010" => -- if page crossed, fix upper byte of PC
									
										-- negative offset
										if(M(7) = '1')then
											PC(15 downto 8) <= std_logic_vector(unsigned(PC(15 downto 8)) - 1);
										
										-- positive offset
										else
											PC(15 downto 8) <= std_logic_vector(unsigned(PC(15 downto 8)) + 1);
										end if;
									
										CPU_STATE <= FETCH;
									
									when others =>
										CPU_STATE <= FETCH;
								end case;

							when ZPG =>
								case EX_CYCLE is
									when "000" => -- setup read from zero page
										M(7 downto 0) <= DATA_IN;
										ADDR <= x"00" & DATA_IN;
										R <= '1';

										PC <= std_logic_vector(unsigned(PC) + 1);

									when others =>
										case IR is
											when ORA_ZPG =>
												ORA(A,temp);

											when BIT_ZPG =>
												BT(A);

											when AND_ZPG =>
												ANDA(A,temp);
												
											when ROL_ZPG =>
												case EX_CYCLE is
													when "001" =>
														RML(DATA_IN,DATA_OUT,'1');
													
													when "010" =>
													
													when others =>
														CPU_STATE <= FETCH;
												end case;
												
											when ROR_ZPG =>
												case EX_CYCLE is
													when "001" =>
														RMR(DATA_IN,DATA_OUT,'1');
													
													when "010" =>
													
													when others =>
														CPU_STATE <= FETCH;
												end case;
												
											when ASL_ZPG =>
												case EX_CYCLE is
													when "001" =>
														ASL(DATA_IN,DATA_OUT,'1');
													
													when "010" =>
													
													when others =>
														CPU_STATE <= FETCH;
												end case;
												
											when LSR_ZPG =>
												case EX_CYCLE is
													when "001" =>
														LSR(DATA_IN,DATA_OUT,'1');
													
													when "010" =>
													
													when others =>
														CPU_STATE <= FETCH;
												end case;

											when EOR_ZPG =>
												EORA(A,temp);

											when ADC_ZPG =>
												ADD(temp);

											when STY_ZPG =>
												STORE(Y);

											when STA_ZPG =>
												STORE(A);

											when STX_ZPG =>
												STORE(X);

											when LDY_ZPG =>
												LOAD(Y,temp);

											when LDA_ZPG =>
												LOAD(A,temp);

											when LDX_ZPG =>
												LOAD(X,temp);

											when CPY_ZPG =>
												CMP(Y,temp);

											when CMP_ZPG =>
												CMP(A,temp);
											
											when CPX_ZPG =>
												CMP(X,temp);

											when DEC_ZPG =>
												case EX_CYCLE is
													when "001" =>
														DEC(DATA_IN,DATA_OUT,'1',temp);
													
													when "010" =>
													
													when others =>
														CPU_STATE <= FETCH;
												end case;
											
											when INC_ZPG =>
												case EX_CYCLE is
													when "001" =>
														INC(DATA_IN,DATA_OUT,'1',temp);
													
													when "010" =>
													
													when others =>
														CPU_STATE <= FETCH;
												end case;

											when SBC_ZPG =>
												SUB(temp);

											when others =>
												CPU_STATE <= FETCH;
										end case;
								end case;
								
							when ZPG_X =>
								case EX_CYCLE is
									when "000" => -- compute zero page, X indexed
										M(7 downto 0) <= std_logic_vector(unsigned(DATA_IN) + unsigned(X));
										
										PC <= std_logic_vector(unsigned(PC) + 1);
										
									when "001" => -- setup read from zero page, X indexed
										ADDR <= x"00" & M(7 downto 0);
										R <= '1';

									when others =>
										case IR is
											when SBC_ZPG_X =>
												SUB(temp);

											when INC_ZPG_X =>
												case EX_CYCLE is
													when "010" =>
														INC(DATA_IN,DATA_OUT, '1',temp);
													
													when "011" =>
													
													when others =>
														CPU_STATE <= FETCH;
												end case;
											
											when DEC_ZPG_X =>
												case EX_CYCLE is
													when "010" =>
														DEC(DATA_IN,DATA_OUT, '1',temp);
													
													when "011" =>
													
													when others =>
														CPU_STATE <= FETCH;
												end case;
											
											when CMP_ZPG_X =>
												CMP(A,temp);

											when LDY_ZPG_X =>
												LOAD(Y,temp);

											when LDA_ZPG_X =>
												LOAD(A,temp);

											when STY_ZPG_X =>
												STORE(Y);

											when STA_ZPG_X =>
												STORE(A);

											when ADC_ZPG_X =>
												ADD(temp);

											when EOR_ZPG_X =>
												EORA(A,temp);
											
											when ROR_ZPG_X =>
												case EX_CYCLE is
													when "010" =>
														RMR(DATA_IN,DATA_OUT,'1');
													
													when "011" =>
													
													when others =>
														CPU_STATE <= FETCH;
												end case;
											
											when ROL_ZPG_X =>
												case EX_CYCLE is
													when "010" =>
														RML(DATA_IN,DATA_OUT,'1');
													
													when "011" =>
													
													when others =>
														CPU_STATE <= FETCH;
												end case;
											
											when ASL_ZPG_X =>
												case EX_CYCLE is
													when "010" =>
														ASL(DATA_IN,DATA_OUT,'1');
													
													when "011" =>
													
													when others =>
														CPU_STATE <= FETCH;
												end case;

											when LSR_ZPG_X =>
												case EX_CYCLE is
													when "010" =>
														LSR(DATA_IN,DATA_OUT,'1');
													
													when "011" =>
													
													when others =>
														CPU_STATE <= FETCH;
												end case;

											when AND_ZPG_X =>
												ANDA(A,temp);

											when ORA_ZPG_X =>
												ORA(A,temp);

											when others =>
												CPU_STATE <= FETCH;
										end case;
								end case;
								
							when ZPG_Y => 
								case EX_CYCLE is
									when "000" => -- compute zero page, Y indexed
										M(7 downto 0) <= std_logic_vector(unsigned(DATA_IN) + unsigned(Y));
										
										PC <= std_logic_vector(unsigned(PC) + 1);
										
									when "001" => -- setup read from zero page, Y indexed
										ADDR <= x"00" & M(7 downto 0);
										R <= '1';

									when others =>
										case IR is
											when LDX_ZPG_Y =>
												LOAD(X,temp);
												
											when STX_ZPG_Y =>
												STORE(X);

											when others =>
												CPU_STATE <= FETCH;
										end case;
								end case;
								
							when ABSOLUTE =>
								case EX_CYCLE is
									when "000" => -- fetch low byte of address
										M(7 downto 0) <= DATA_IN;
									
										PC <= std_logic_vector(unsigned(PC) + 1);

									when "001" => -- fetch high byte and setup read from address
										
										if(IR = JMP_ABS) then
											PC <= DATA_IN & M(7 downto 0);
											CPU_STATE <= FETCH;
											
										else
											M(15 downto 8) <= DATA_IN;
											ADDR <= DATA_IN & M(7 downto 0);
											R <= '1';
											--PC <= std_logic_vector(unsigned(PC) + 1);
											
											if(IR /= JSR_ABS) then
												PC <= std_logic_vector(unsigned(PC) + 1);
											
											end if;

										end if;
										
									when others =>
										case IR is
											when ORA_ABS =>
												ORA(A,temp);

											when JSR_ABS =>
											
												case EX_CYCLE is
												
													when "010" => --push
														W <= '1';
														ADDR <= x"01" & SP;
														DATA_OUT <= PC(15 downto 8);
														SP <= std_logic_vector(unsigned(SP) - 1);
													
													when "011" => -- decrement SP
														W <= '1';
														ADDR <= x"01" & SP;
														DATA_OUT <= PC(7 downto 0);
														SP <= std_logic_vector(unsigned(SP) - 1);
													
													when "100" => -- JMP to absolute addr
														PC <= M;
														CPU_STATE <= FETCH;
														
													when others =>
												
												end case;

											when BIT_ABS =>
												BT(A);

											when AND_ABS =>
												ANDA(A,temp);

											when EOR_ABS =>
												EORA(A,temp);
											
											when ROR_ABS =>
												case EX_CYCLE is
													when "010" =>
														RMR(DATA_IN,DATA_OUT,'1');
													
													when "011" =>
													
													when others =>
														CPU_STATE <= FETCH;
												end case;
											
											when ROL_ABS =>
												case EX_CYCLE is
													when "010" =>
														RML(DATA_IN,DATA_OUT,'1');
													
													when "011" =>
													
													when others =>
														CPU_STATE <= FETCH;
												end case;
											
											when ASL_ABS =>
												case EX_CYCLE is
													when "010" =>
														ASL(DATA_IN,DATA_OUT,'1');
													
													when "011" =>
													
													when others =>
														CPU_STATE <= FETCH;
												end case;

											when LSR_ABS =>
												case EX_CYCLE is
													when "010" =>
														LSR(DATA_IN,DATA_OUT,'1');
													
													when "011" =>
													
													when others =>
														CPU_STATE <= FETCH;
												end case;

											when ADC_ABS =>
												ADD(temp);

											when STY_ABS =>
												STORE(Y);

											when STA_ABS =>
												STORE(A);

											when STX_ABS =>
												STORE(X);

											when LDY_ABS =>
												LOAD(Y,temp);

											when LDA_ABS =>
												LOAD(A,temp);

											when LDX_ABS =>
												LOAD(X,temp);

											when CPY_ABS =>
												CMP(Y,temp);

											when CMP_ABS =>
												CMP(A,temp);
												
											when CPX_ABS =>
												CMP(X,temp);

											when DEC_ABS =>
												case EX_CYCLE is
													when "010" =>
														DEC(DATA_IN,DATA_OUT, '1',temp);
													
													when "011" =>
													
													when others =>
														CPU_STATE <= FETCH;
												end case;
												
											when INC_ABS =>
												case EX_CYCLE is
													when "010" =>
														INC(DATA_IN,DATA_OUT, '1',temp);
													
													when "011" =>
													
													when others =>
														CPU_STATE <= FETCH;
												end case;

											when SBC_ABS =>
												SUB(temp);

											when others =>
												CPU_STATE <= FETCH;
										end case;
								end case;
								
							when ABSOLUTE_X =>
								case EX_CYCLE is
									when "000" => -- fetch low byte of address
										M(7 downto 0) <= DATA_IN;
									
										PC <= std_logic_vector(unsigned(PC) + 1);

									when "001" => -- fetch high byte, add X with carry to low byte, and setup read from address if page not crossed
										temp := std_logic_vector(unsigned('0' & M(7 downto 0)) + unsigned(X)); --  + unsigned(flags(0 downto 0))
										M(15 downto 8) <= DATA_IN;
										M(7 downto 0) <= temp(7 downto 0);
										
										-- if page crossed
										if(temp(8) = '1') then
										
											page_crossed <= '1';
											
										else
										
											ADDR <= DATA_IN & temp(7 downto 0);
											R <= '1';
											
										end if;
										
										PC <= std_logic_vector(unsigned(PC) + 1);

									when others=>

										if(page_crossed = '1') then -- correct high byte of address and setup read from address
											CORRECT_PAGE(temp);

										else
											case IR is
												when SBC_ABS_X =>
													SUB(temp);

												when INC_ABS_X =>
													case EX_CYCLE is
														when "010" =>
															INC(DATA_IN,DATA_OUT, '1',temp);
														
														when "011" | "100" =>
														
														when others =>
															CPU_STATE <= FETCH;
													end case;
												
												when DEC_ABS_X =>
													case EX_CYCLE is
														when "010" =>
															DEC(DATA_IN,DATA_OUT, '1',temp);
														
														when "011" | "100" =>
														
														when others =>
															CPU_STATE <= FETCH;
													end case;

												when CMP_ABS_X =>
													CMP(A,temp);

												when LDY_ABS_X =>
													LOAD(Y,temp);

												when LDA_ABS_X =>
													LOAD(A,temp);

												when STA_ABS_X =>
													STORE(A);

												when ADC_ABS_X =>
													ADD(temp);

												when EOR_ABS_X =>
													EORA(A,temp);

												when ROR_ABS_X =>
													case EX_CYCLE is
														when "010" =>
															RMR(DATA_IN,DATA_OUT,'1');
														
														when "011" | "100" =>
														
														when others =>
															CPU_STATE <= FETCH;
													end case;

												when ROL_ABS_X =>
													case EX_CYCLE is
														when "010" =>
															RML(DATA_IN,DATA_OUT,'1');
														
														when "011" | "100" =>
														
														when others =>
															CPU_STATE <= FETCH;
													end case;

												when ASL_ABS_X =>
													case EX_CYCLE is
														when "010" =>
															ASL(DATA_IN,DATA_OUT,'1');
														
														when "011" | "100" =>
														
														when others =>
															CPU_STATE <= FETCH;
													end case;

												when LSR_ABS_X =>
													case EX_CYCLE is
														when "010" =>
															LSR(DATA_IN,DATA_OUT,'1');
														
														when "011" | "100" =>
														
														when others =>
															CPU_STATE <= FETCH;
													end case;

												when ORA_ABS_X =>
													ORA(A,temp);
													
												when AND_ABS_X =>
													ANDA(A,temp);
													
												when others =>
													CPU_STATE <= FETCH;
											end case;
										end if;
								end case;
								
							when ABSOLUTE_Y =>
								case EX_CYCLE is
									when "000" => -- fetch low byte of address
										M(7 downto 0) <= DATA_IN;
									
										PC <= std_logic_vector(unsigned(PC) + 1);

									when "001" => -- fetch high byte, add Y with carry to low byte, and setup read from address if page not crossed
										temp := std_logic_vector(unsigned('0' & M(7 downto 0)) + unsigned(Y)); -- + unsigned(flags(0 downto 0))
										M(15 downto 8) <= DATA_IN;
										M(7 downto 0) <= temp(7 downto 0);
										
										-- if page crossed
										if(temp(8) = '1') then
										
											page_crossed <= '1';
											
										else
										
											ADDR <= DATA_IN & temp(7 downto 0);
											R <= '1';
											
										end if;
										
										PC <= std_logic_vector(unsigned(PC) + 1);

									when others=>

										if(page_crossed = '1') then -- correct high byte of address and setup read from address
											CORRECT_PAGE(temp);

										else
											case IR is
												when AND_ABS_Y =>
													ANDA(A,temp);

												when ORA_ABS_Y =>
													ORA(A,temp);

												when EOR_ABS_Y =>
													EORA(A,temp);

												when ADC_ABS_Y =>
													ADD(temp);

												when LDX_ABS_Y =>
													LOAD(X,temp);

												when LDA_ABS_Y =>
													LOAD(A,temp);
													
												when STA_ABS_Y =>
													STORE(A);

												when CMP_ABS_Y =>
													CMP(A,temp);

												when SBC_ABS_Y =>
													SUB(temp);
													
												when others =>
													CPU_STATE <= FETCH;
											end case;
										end if;
								end case;

							when INDIRECT =>
								case IR is
									when JMP_IND =>
										case EX_CYCLE is
											when "000" => -- read low byte of address
												M(7 downto 0) <= DATA_IN;

												PC <= std_logic_vector(unsigned(PC) + 1);

											when "001" => -- read high byte of address setup read from indirect address
												ADDR <= DATA_IN & M(7 downto 0);
												R <= '1';

												PC <= std_logic_vector(unsigned(PC) + 1);

											when "010" => -- read low byte of indirect and setup read from indirect address + 1
												M(7 downto 0) <= DATA_IN;
												ADDR <= ADDR(15 downto 8) & std_logic_vector(unsigned(ADDR(7 downto 0)) + 1);
												R <= '1';

											when "011" => -- read high byte of indirect and set PC to indirect word
												
												PC <= DATA_IN & M(7 downto 0);

												CPU_STATE <= FETCH;

											when others =>
										end case;

									when others =>
										CPU_STATE <= FETCH;
								end case;

							when X_INDIRECT =>
								case EX_CYCLE is
									when "000" => -- fetch zero page address
										M(7 downto 0) <= DATA_IN;

										PC <= std_logic_vector(unsigned(PC) + 1);

									when "001" => -- index by X, and setup read from address
										temp(7 downto 0) := std_logic_vector(unsigned(M(7 downto 0)) + unsigned(X));
										M(7 downto 0) <= temp(7 downto 0);
										ADDR <= x"00" & temp(7 downto 0);
										R <= '1';

									when "010" => -- read from address and setup read from address + 1
										temp(7 downto 0) := std_logic_vector(unsigned(M(7 downto 0)) + 1);
										M(7 downto 0) <= DATA_IN;
										ADDR <= x"00" & temp(7 downto 0);
										R <= '1';

									when "011" => -- read from address + 1 and setup read from indirect address
										M(15 downto 8) <= DATA_IN;
										ADDR <= DATA_IN & M(7 downto 0);
										R <= '1';

									when others =>
										case IR is
											when EOR_X_IND =>
												EORA(A,temp);

											when ADC_X_IND =>
												ADD(temp);

											when STA_X_IND =>
												STORE(A);

											when LDA_X_IND =>
												LOAD(A,temp);
										
											when CMP_X_IND =>
												CMP(A,temp);

											when SBC_X_IND =>
												SUB(temp);

											when ORA_X_IND =>
												ORA(A,temp);

											when AND_X_IND =>
												ANDA(A,temp);

											when others =>
												CPU_STATE <= FETCH;
										end case;
								end case;

							when INDIRECT_Y =>
								case EX_CYCLE is
									when "000" => -- fetch zero page address and setup read from address
										M(7 downto 0) <= DATA_IN;
										ADDR <= x"00" & DATA_IN;
										R <= '1';

										PC <= std_logic_vector(unsigned(PC) + 1);

									when "001" => -- read from address and setup read from address + 1
										temp(7 downto 0) := std_logic_vector(unsigned(M(7 downto 0)) + 1);
										M(7 downto 0) <= DATA_IN;
										ADDR <= x"00" & temp(7 downto 0);
										R <= '1';

									when "010" => -- read from address + 1, index by Y + carry and setup read from indirect address if page not crossed
										temp := std_logic_vector(unsigned('0' & M(7 downto 0)) + unsigned(Y)); --  + unsigned(flags(0 downto 0))
										M(15 downto 8) <= DATA_IN;
										M(7 downto 0) <= temp(7 downto 0);
										
										-- if page crossed
										if(temp(8) = '1') then
										
											page_crossed <= '1';
											
										else
										
											ADDR <= DATA_IN & temp(7 downto 0);
											R <= '1';
											
										end if;

									when others =>
										if(page_crossed = '1') then -- correct high byte of address and setup read from address
											CORRECT_PAGE(temp);

										else
											case IR is
												when ORA_IND_Y =>
													ORA(A,temp);

												when SBC_IND_Y =>
													SUB(temp);

												when CMP_IND_Y =>
													CMP(A,temp);

												when STA_IND_Y =>
													STORE(A);

												when ADC_IND_Y =>
													ADD(temp);

												when EOR_IND_Y =>
													EORA(A,temp);

												when AND_IND_Y =>
													ANDA(A,temp);

												when LDA_IND_Y =>
													LOAD(A,temp);

												when others =>
													CPU_STATE <= FETCH;
											end case;
										end if;
								end case;

							when others => 
						end case;
					
					when HOLD_STATE =>
				
						if(HOLD = '1') then
							CPU_STATE <= HOLD_STATE;
						else
							CPU_STATE <= EXECUTE;
						end if;
				
					when HALT_STATE =>
						CPU_STATE <= HALT_STATE;
					
					when others =>
						CPU_STATE <= HALT_STATE;
					
				end case;
		end if;
	end process;

end RTL;
































