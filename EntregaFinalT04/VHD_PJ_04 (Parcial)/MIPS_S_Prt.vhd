-------------------------------------------------------------------------------
--
--  The MIPS-S Processor (Prototypable)
--		Last Release: 1st/June/2025
--	Authors: 
--		Ney Calazans / Fernando Moraes
--
--  01/11/2007 - Version with Separate Instruction and Data Memories
--  21/06/2010 (Ney Calazans) - Bug fixing:
-- 		- The mux that generates op1 now receives the contents of NPC 
--			and no longer the PC contents.
--  17/11/2010 (Ney Calazans) - Bug fixing:
--		1 - Decoding of BGEZ and BLEZ instructions were incomplete
--		2 - Defining which lines choose the register to write in
--			shift instructions SSLL, SLLV, SSRA, SRAV, SSRL e SRLV
--	01/06/2012 (Ney Calazans) 
--		- Version where the processor is now a single entity-architeture
--			(E/A) pair
--		- Minor changes in signal naming
--  19/11/2015 (Ney Calazans) 
--		- Changes to make the processor sensitive to a single clock 
--			edge, the rising one.
--		- Besides the obvious changes in memory component sensitivity
--			the point from where multiplier and divider take data also
--			changed. It now comes straight from the register bank read 
--			and no longer from the temporary R1 and R2 registers.
--		- Also the structure of the datapath and control unit changed
--			a bit. The Control unit now contains the PC, NPC and IR
--			registers and, naturally, it contains the interface to the 
--			instruction memory.
--		- The old Sidle state in the control FSM is no longer necessary
--			and was accordingly eliminated.
--  04/07/2016 (Ney Calazans)
-- 		- Several signal renaming produced to increase the code
-- 			readability.
-- 		- The name of the processor was changed to MIPS_S, standing for 
--			MIPS ISA Subset (ver annexed dcouemnetation, version 2.0 or
--			later).
--  05/07/2018 (Ney Calazans)
-- 		- Correction and adaptation of signal names to facilitate learning.
--  13/12/2018 (Ney Calazans)
-- 		- Eliminated any mention to an IMED temporary registrador, for
--			coherency reasons.
--  11/12/2019 (Ney) - Bug fixing:
--		- Corrected bug in M6 mux that appeared only when jump addresses 
--			had bits 25-21 differing from 00000. The bug was to pass R1 
--			to the op1 ALU input when computing a jump address for 
--			instructions J e JAL, and not the contents of NPC, which is
--			the correct value.
--  16/06/2020 (Ney) - Bug fixing (in the multiplier/divider modules):
--		- For some reason between today's version and that on 19/11/2015,
-- 			the multiplier/divider inputs went back to be connected to the
--			ouputs of R1 and R2 registers. This was undone.
--		- Another change was to alter the internal logic of the 
--			multiplier/divider modulos to enable reseting them at the same
--			time the procesor is reset. This required initializing 
--			registers RegP and RegB in both modules only when leaving the 
--			initialize state and not on entering it. After this modification,
--			it became simple making the modules reset signal a simple OR
--			of the processor reset and the uins.rst_md. The new signal
--			(the OR output wire) is called rst_muldiv.
--	29/09/2021 (Ney Calazans)
--		- Comments revised.
--	20/10/2021 (Ney Calazans)
--		- Comments revised.
--		- New labels added and identifier regnbits changed to reg32bits.
--		- The processor is now called MIPS_S everywhere, changing also the 
--			processor package to p_MIPS_S.
--	19/10/2022 (Ney Calazans)
-- 		- Several small changes were performed in port ordering, to make 
--			the simulatable and prototipable MIPS_S versions compatible.
--		- Some signal names were changed to English spelling, for
--			coherency reasons, especially in the multiplier and divider 
--			modules interface.
--	15/02/2025 (Ney Calazans) - Bug fixing:
--		- The software le_mars.c was corrected to generate a revised 
--			memory interface in the automatically generated memory.vhd
--		- Required corrections in MIPS_S and in MIPS_S_withBRAMs, to
--			correctly support single-byte read and write instructions
--			(LBU and SB)
--	25/03/2025 (Ney Calazans)
--		- Did some internal signal renaming in MIPS_S and added/enhanced
--			/corrected some comments, all to improve code readability.
--	11/04/2025 (Ney Calazans)
--		- MIPS_S E/A migrated to a separate file from MIPS_S_withBRAMs.
--		- The multiplication and division modules implementations are now
--			also in a separate file (mult_div.vhd).
--		- Alongtime, the MIPS_S (prototypable) implementation evolved
--			separately from the MIPS_Multi (simulatable) implementation.
--			This is very bad practice. A great effort was now made to 
--			merge both implementations into a single design, or to keep both
--			as only slightly different. At the moment, the single point 
--			that will be kept distinct (for now) is that the simulatable 
--			version will keep a single, bidirectional, external data bus,
--			while the prototypable version has two separated data buses,
--			data_in and data_out. There is not really a reason for not
--			making both interfaces identical, since the pin economy 
--			theoretically brought about by a bidirectional bus is not 
--			significant in embedded environments, and since FPGAs, the
--			common target Hw component have not abundant (if any) tristate
--			buffers, synthesis will produce internally multiplexed versions
--			of the data bus anyway. But for now this is the choice taken.
--		- It is assumed here that a basic processor system will have a 2-Kbyte
--			Instruction Memory (512 words starting at address 0x00400000) and
--			an 8-Kbyte Data Memory (byte addressable, assuming an interleaved
--			memory organization, starting at address 0x10010000). This is,
--			of course, easily changeable.
--      - Polarity of the bw signal changed to bw='1' for byte write;
--	25/04/2025 (Ney Calazans) 
--		- The validation of the 11/04/2025 simulatable version by simulation
--			entailed the need for a new modification/correction. The M8 mux 
--			had to be changed for MIPS_S_Sim, to adapt to the non-interleaved
--			memory organization modeling in its testbench. Now, there are two
--			alternative codings for M8, one for interleaved data memory
--			organizations and one for non-interleaved organizations.
--	29/04/2025 (Ney Calazans) 
--		- For coherence reasons, the old Ssalta state had its name changed to
--          Sjump.
--  05/05/2025 (Ney Calazans)
--      - To enable building straightforward input/output interfaces to
--          peripherals a new control signal input (suspend) was added to the 
--          MIPS_S interface. Also a new status output (suspend_ack) was 
--          included. The suspend/suspend_ack operation is as follows:
--          Whenever the control unit is at the Sfetch state, the active-high
--          suspend signal is tested. If it is active, the processor suspends
--          its operation (freezing at the Sfetch state), makes the 
--          active-high suspend_ack='1' and releases the data memory interface
--          for use by external peripherals. Whenever suspend is made 
--          inactive again, the processor resumes operation at the following
--          rising edge of the clock, fetching the instruction pointed by the
--          PC and deactivating the suspend_ack signal.
--      - The suspend_ack is registered to facilitate its synchronous test
--          by peripherals.
--	26/05/2025 (Ney Calazans)
--		- Comments part has been updated
--	1ro/06/2025 (Ney Calazans)
--		- Due to a warning from synthesis, we learned it is better to have
--			the basic 32-bit register definition (reg32bits) to use 
--			synchronous reset (to avoid BRAM corruption).
--		- The simulatable and prototypable versions were revised to become
--			the most similar the possible.
-------------------------------------------------------------------------------

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- The MIPS_S package definitions, containing basic types
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.Std_Logic_1164.all;

package p_MIPS_S is  
    subtype wires32  is std_logic_vector(31 downto 0);

    -- inst_type defines the instructions decodeable by the control unit
    type inst_type is  
            (ADDU, SUBU, AAND, OOR, XXOR, NNOR, SSLL, SLLV, SSRA, SRAV,
			SSRL, SRLV, ADDIU, ANDI, ORI, XORI, LUI, LBU, LW, SB, SW, SLT,
			SLTU, SLTI, SLTIU, BEQ, BGEZ, BLEZ, BNE, J, JAL, JALR, JR, 
			MULTU, DIVU, MFHI, MFLO, invalid_instruction);
 
    type microinstruction is record
            CY1:   std_logic;       -- Identifies the first stage,
									-- the clock cycle 1 of every instruction
            CY2:   std_logic;       -- Identifies the second stage,
									-- the clock cycle 2 of every instruction
            walu:  std_logic;       -- Identifies the third stage
            wmdr:  std_logic;       
			-- Identifies the fourth stage of load instructions
            wpc:   std_logic;       -- PC write enable
            wreg:  std_logic;       -- Register bank write enable
            whilo: std_logic;       -- HI and LO registers write enable
            ce:    std_logic;       -- Data memory chip enable and r/w controls
            rw:    std_logic;
            bw:    std_logic;       -- Byte-word control (mem write only)
            i:     inst_type;       -- Instruction identification
			rst_md:std_logic;       
			-- Signal to start multiplication and division
	end record;
end p_MIPS_S;

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- General purpose 32-bit register - sensitive to the rising edge of the
-- clock (ck), with asynchronous reset (rst) and write enable control (ce)
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use work.p_MIPS_S.all;         

entity reg32bits is
           generic(INIT_VALUE : wires32:=(others=>'0') );
           port(ck, rst, ce : in std_logic;
                D : in  wires32;
                Q : out wires32
               );
end reg32bits;

architecture reg32bits of reg32bits is 
begin
  process(ck)
  begin
       if ck'event and ck = '1' then
            if rst = '1' then
              Q <= INIT_VALUE(31 downto 0);
            elsif ce = '1' then
                    Q <= D; 
            end if;
       end if;
  end process;
end reg32bits;

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- The MIPS Register Bank (R0..R31) - 32 32-bit registers
-- 	This is a memory with three access port, not to be taken as the 
--		processor main memory. 
--		There are two read ports (controlled by signals AdRP1+DataRP1 and
--		AdRP2+DataRP2) and a write port (controlled by the set of signals
--		ck, rst, ce, AdWP and DataWP).
--		The addresses for each port (resp. AdRP1, AdRP2 e AdWP) are 
--		obviously 5-bit signals (since 2^5=32 andf we need a distinct 
--		address for each of the 32 registers), while the data buses for 
--		reading (DataRP1, DataRP2) and writing (DataWP) are 32-bit wide.
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use work.p_MIPS_S.all;         
-- The two lines below may be uncommented for using a LUTRAM approach
--		to implement registers explicitly for Xilinx FPGAs 
--		(more comments below...)
--library UNISIM;
--use UNISIM.vcomponents.all; 

entity reg_bank is
       port( ck, rst, ce		: in std_logic;
             AdRP1, AdRP2, AdWP	: in std_logic_vector(4 downto 0);
             DataWP				: in wires32;
             DataRP1, DataRP2	: out wires32 
           );
end reg_bank;

architecture reg_bank of reg_bank is
   type wirebank is array(0 to 31) of wires32;
   signal reg : wirebank ;                            
   signal wen : wires32;
-- Line below  to use for the LUTRAM option  
--   signal address1, address2 : std_logic_vector(4 downto 0) ;
begin            
	g1: for i in 0 to 31 generate
        -- Remember that MIPS register $0 ($zero) is the constant 0, 
		-- 	not a real register. It is described as a register which ce is
		-- 	never activated. Signal wen is a vector of control signals that 
		-- 	enables writing in each of the 32 (really 31) registers: wen(0) 
		-- 	is the register $0 write enable (as mentioned above, wen(0)='0',
		--	always).
		-- The remaining wen(i) depend on the value of AdWP and on the global
		-- 	enable of the bank, the ce pin.
        wen(i) <= '1' when i/=0 and adWP=i and ce='1' else '0';
		
		-- Remember that register $29, by software convention, is the stack 
		-- It initially points to a place distinct from the value used by the
		-- MARS simulator. The stack is thought here as using the final 
		-- portion of the external data memory, address 0x10012000, assuming 
		-- an 8-Kbyte data memory mapped as starting at address 0x10010000.
		-- SP - 0x10010000 + 0x2000 - the top of stack position corresponds
		--	to the first position not containing memory, 0x10012000
		g2: if i=29 generate
			r29: entity work.reg32bits generic map(INIT_VALUE=>x"10012000")    
				port map(ck=>ck, rst=>rst, ce=>wen(i), D=>DataWP, Q=>reg(i));
		end generate g2;  
                
		g3: if i/=29 generate 
			rx: entity work.reg32bits 
				port map(ck=>ck, rst=>rst, ce=>wen(i), D=>DataWP, Q=>reg(i));
		end generate g3;
   end generate g1;   
        
    DataRP1 <= reg(CONV_INTEGER(AdRP1));    -- source1 multiplexer

    DataRP2 <= reg(CONV_INTEGER(AdRP2));    -- source2 multiplexer

-- Lines below: use them the LUTRAM option for creating the Register bank
--	address1 <=  adRD when wreg='1' else AdRt; -- 1st port address definition
--	address2 <=  adRD when wreg='1' else AdRs; -- 2nd port address definition
--
--	When possible, investigate the following implementation and answer: 
--		1) Do this implementation is complete and compatible with the rest of
--			the reg_bank description (just using Xilinx FPGAs LUTRAM 
--			structures)?
--		2) If answer to 1) above is yes, do this improve the performance of
--			the processor?
--		bank: for i in 0 to 31 generate
--		M1: RAM32X1S
--			port map(	WCLK=>ck,
--						WE=>wreg,
--						D=>RD(i),
--						A0=>address1(0), A1=>address1(1), 
--						A2=>address1(2), A3=>address1(3),
--						A4=>address1(4), O => R2(i));
--		M2: RAM32X1S
--			port map(	WCLK=>ck,
--						WE=>wreg,
--						D=>RD(i),
--						A0=>address2(0), A1=>address2(1),
--						A2=>address2(2), A3=>address2(3),
--						A4=>address2(4), O => R1(i));
--								
--		end generate bank;
end reg_bank;

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- ALU - This is an arithmetic-logic unity, made up of purely combinational
--		logic, which output depends on values in its data inputs op1 and
--		op2, each with 32 bits, and on the instruction under execution by
--		the processor, informed through the op_alu control signal.
--
-- 	22/11/2004 (Ney Calazans) - Bug fix:
--		- A subtle error was detected while executing instruction J.
-- 		- Remember that part of the job of executing J (the address 
--		computation), has been started before the ALU, displacing 
--		IR(25 downto 0) 2 bits to the left, before writing data to the
--		temporary register R3.
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
use work.p_MIPS_S.all;

entity alu is
       port( op1, op2	: in wires32;
             outalu		: out wires32;   
             op_alu		: in inst_type   
           );
end alu;

architecture alu of alu is 
   signal menorU, menorS : std_logic;
begin
	-- Comparing op1 and op2 as Natural numbers
    menorU <=  '1' when op1 < op2 else '0';
	-- Comparing op1 and op2 as Integer numbers
    menorS <=  '1' when ieee.Std_Logic_signed."<"(op1,  op2) else '0' ;
    
    outalu <=
		op1 - op2					when  op_alu=SUBU                  else
        op1 and op2					when  op_alu=AAND  or op_alu=ANDI  else
        op1 or  op2					when  op_alu=OOR   or op_alu=ORI   else
        op1 xor op2					when  op_alu=XXOR  or op_alu=XORI  else
        op1 nor op2					when  op_alu=NNOR                  else
        op2(15 downto 0) & x"0000"	when  op_alu=LUI                   else
        (0=>menorU, others=>'0')	when  op_alu=SLTU or op_alu=SLTIU  else
        (0=>menorS, others=>'0')	when  op_alu=SLT  or op_alu=SLTI   else
        op1(31 downto 28) & op2(27 downto 0)
									when  op_alu=J    or op_alu=JAL    else
        op1							when  op_alu=JR   or op_alu=JALR   else
        to_StdLogicVector(to_bitvector(op1) sll CONV_INTEGER(op2(10 downto 6)))
									when  op_alu=SSLL                  else
        to_StdLogicVector(to_bitvector(op2) sll CONV_INTEGER(op1(5 downto 0)))
									when  op_alu=SLLV                  else
        to_StdLogicVector(to_bitvector(op1) sra CONV_INTEGER(op2(10 downto 6)))
									when  op_alu=SSRA                  else
        to_StdLogicVector(to_bitvector(op2) sra CONV_INTEGER(op1(5 downto 0)))
									when  op_alu=SRAV                  else
        to_StdLogicVector(to_bitvector(op1) srl CONV_INTEGER(op2(10 downto 6)))
									when  op_alu=SSRL                  else 
        to_StdLogicVector(to_bitvector(op2) srl CONV_INTEGER(op1(5 downto 0)))
									when  op_alu=SRLV                  else
		op1 + op2;
		-- The default operation is used for ADDU,ADDIU,LBU,LW,SW,SB,
		--	BEQ,BGEZ,BLEZ,BNE    
end alu;

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- Datapath structural description
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_signed.all; -- needed for comparison instructions SLTx
use IEEE.std_logic_arith.all;  -- needed for comparison instructions SLTxU
use work.p_MIPS_S.all;
   
entity datapath is
      port(	ck, rst						: in std_logic;
            suspend_ack					: in std_logic;
			d_address					: out wires32;
			data_in						: in wires32;  
			data_out					: out wires32;  
			uins						: in microinstruction;
			IR_IN						: in wires32;
			NPC_IN						: in wires32;
			end_mul, end_div			: out std_logic;
			inst_Bgroup_out, jump_out	: out std_logic;
			RESULT_OUT					: out wires32
          );
end datapath;

architecture datapath of datapath is
    signal	inst_Bgroup, inst_Rgroup, inst_Igroup, rst_muldiv : std_logic;
    signal	R1_in, R2_in, sign_extension, R3_in, R1, R2, R3, op1, op2,
			outalu, RALU, Quotient, Remainder, D_Hi, D_Lo, HI, LO,
			MDR_in, MDR, RESULT, RIN : wires32;
	
	
    signal	Product : std_logic_vector(63 downto 0);
    signal	adD, adS : std_logic_vector(4 downto 0);

    signal jump : std_logic;

begin
	-- Auxiliary signals to reduce Hw computations in the datapath. These
	-- 	generate Boolean values to detect some of the most common 
	-- 	instruction groups
	-- inst_Bgroup is a wire that identifies when the instruction in
	-- 	execution is a conditional branch
	inst_Bgroup  <=	'1' when uins.i=BEQ or uins.i=BGEZ or uins.i=BLEZ 
										or uins.i=BNE else 
					'0'; -- (Conditional) Branch Group instructions
	inst_Bgroup_out <= inst_Bgroup;
   
	-- inst_Rgroup is a wire that identifies when the instruction in
	--	execution is one of a subset of R-type instructions 
	--	(arithmetic or logical)
	inst_Rgroup  <= '1' when uins.i=ADDU or uins.i=SUBU or uins.i=AAND
										 or uins.i=OOR or uins.i=XXOR 
										 or uins.i=NNOR else
					'0'; -- Rgroup: Arithmetic/Logic instructions with only
						 -- 	register operands

	-- inst_Igroup is a wire that identifies when the instruction in 
	-- 	execution is one of a subset of I-type instructions
	--	(arithmetic or logical)
	inst_Igroup  <= '1' when uins.i=ADDIU or uins.i=ANDI or uins.i=ORI 
										  or uins.i=XORI else
					'0'; -- Igroup: Arithmetic/Logic instructions
						 -- with an immediate operand

	--=========================================================================
	-- Second stage
	--	- This is the operand fetch stage. Here also takes place the
	--		generation of immediate data for instruction execution
	--	- Remember, the First stage is in the Control unit
	--=========================================================================

	-- M2 is a mux that chooses source address for the Read Port 1.
	--	The first choice is only used for logic/arithmetic shifts 
	--	with a shamt field.
	M2:	adS <=	IR_IN(20 downto 16) when uins.i=SSLL or uins.i=SSRA 
				or uins.i=SSRL else IR_IN(25 downto 21)   ;               

	-- Here is instantiated REGS, the Register bank, and its connections
	REGS: entity work.reg_bank port map
            (ck=>ck, rst=>rst, ce=>uins.wreg, AdRP1=>adS, DataRP1=>R1_in, 
			AdRP2=> IR_IN(20 downto 16), DataRP2=>R2_in, AdWP=>adD, 
			DataWP=>RIN);

	-- Sign extension computation 
	sign_extension <=	x"FFFF" & IR_IN(15 downto 0) when IR_IN(15)='1' else
						x"0000" & IR_IN(15 downto 0);

	-- M3 is a mux that defines the immediate constant value to employ, if any
	M3: R3_in <= sign_extension(29 downto 0) & "00" when inst_Bgroup='1' else
			-- Branch address adjustment for word frontier.
			-- 	Multiply the instruction operand by 4
            "0000" & IR_IN(25 downto 0) & "00" when uins.i=J or uins.i=JAL else
			-- J/JAL are word addressed. The most significant 4 bits are
			-- 	defined in the ALU, not here!
            x"0000" & IR_IN(15 downto 0) when uins.i=ANDI	
											or uins.i=ORI or uins.i=XORI else
			-- logic instructions with immediate operand are zero extended
            sign_extension;
			-- The default case is used by ADDIU, LBU, LW, SBU, SW
			-- 	instructions, and also by those instructions not 
			--	using the ALU (such as MULTU and DIVU)

   -- Here are instantiated the Second stage registers
   R1reg: entity work.reg32bits   
			port map(ck=>ck, rst=>rst, ce=>uins.CY2, D=>R1_in, Q=>R1);

   R2reg: entity work.reg32bits
			port map(ck=>ck, rst=>rst, ce=>uins.CY2, D=>R2_in, Q=>R2);
  
   R3reg: entity work.reg32bits  
			port map(ck=>ck, rst=>rst, ce=>uins.CY2, D=>R3_in, Q=>R3);

	--=========================================================================
	-- Third stage
	--	- This is the operation stage. Either the ALU or the Multiplier or the
	--		Divider execute here, producing the final data or an address of
	--		data or instruction to be used.
	--=========================================================================

	-- M4 is the mux that selects the first ALU operand                           
	-- Use the line below for code generated with the PCSPIM simulator
	-- op1 <= pc  when (inst_Bgroup='1' or uins.i=J or uins.i=JAL) else R1; 
	-- -- Note the PC register is now on the Control Unit...
	-- Use the line below for code generated with the MARS simulator
	-- op1 <= NPC_IN  when (inst_branch='1' or uins.i=J or uins.i=JAL) else R1;
	M4: op1 <= NPC_IN when (inst_Bgroup='1' or uins.i=J or uins.i=JAL) else R1;
     
	-- M5 is the mux that selects the second ALU operand
	-- R2 for R-type instructions, SLT/SLTU, JR or shifts with no shamt field
	M5: op2 <= 	R2 when inst_Rgroup='1' or uins.i=SLTU or uins.i=SLT 
										or uins.i=JR or uins.i=SLLV 
										or uins.i=SRAV or uins.i=SRLV else 
				R3; 
                 
	-- The ALU instantiation
	DALU: entity work.alu port map (op1=>op1, op2=>op2, outalu=>outalu,
									op_alu=>uins.i);

	-- The ALU output register
	REG_alu: entity work.reg32bits port map(ck=>ck, rst=>rst, ce=>uins.walu,
											D=>outalu, Q=>RALU);               
 
	-- The Comparator evaluates if conditions to take branches hold
	jump <=	'1' when ( (R1=R2  and uins.i=BEQ)  or (R1>=0  and uins.i=BGEZ) or
                       (R1<=0  and uins.i=BLEZ) or (R1/=R2 and uins.i=BNE)
                        )  else
			'0';
	jump_out <= jump;

	-- Signal that resets the Divider and the Multiplier; both are reset by
	--	either the global reset (rst) ou by signal rst_md, produced by the 
	--	MIPS_S control finite state machine at the second cycle of DIVU or
	--	MULTU instructions.
	rst_muldiv <= rst or uins.rst_md; 
	
	-- The Divider and Multiplier instantiations
	inst_Divd: entity work.divider port map (clock=>ck, start=>rst_muldiv, 
											 Dvdend=>R1_in, Dvsor=>R2_in,
											 endop=>end_div, Quot=>Quotient,
											 Remaind=>Remainder);

	inst_Mult: entity work.multiplier port map (clock=>ck, start=>rst_muldiv,
												Mpland=>R1_in, Mplier=>R2_in,
												endop=>end_mul, 
												Product=>Product);

	-- M6 is the mux that selects the data to put in the LO architectural reg
	M6: D_Lo <= Product(31 downto 0) when uins.i=MULTU else Quotient; 

	-- M7 is the mux that selects the data to put in the HI architectural reg
	M7: D_Hi <= Product(63 downto 32) when uins.i=MULTU else Remainder; 

 	-- Instantiation of the HI and LO registers
	LOreg: entity work.reg32bits  port map(ck=>ck, rst=>rst, ce=>uins.whilo, 
			D=>D_Lo, Q=>LO);               

	HIreg: entity work.reg32bits  port map(ck=>ck, rst=>rst, ce=>uins.whilo, 
			D=>D_Hi, Q=>HI);               

	--=========================================================================
	-- Fourth stage
	--	- This is the data memory read or write stage. If any access to the
	--		data is to occur (instructions LW, SW, LBU, SB), it happens here
	--		in the fourth clock cycle of the pertinent instruction.
	--	- MIPS_S releases the address and data buses if not writing data to
	--		memory, or if the processor is suspended.
	--=========================================================================
	d_address <= RALU when (suspend_ack='0') else (others=>'Z');

	-- The prototypable processor outputs R2 contents straight to data_out bus
	--	when MIPS_S is not suspended
	data_out <= R2 when (uins.ce='1' and uins.rw='0' and suspend_ack='0')
	           else (others=>'Z');  

	-- M8 is a mux that chooses what to pass to the input of the MDR register.
	--	This is either the straight 32-bit value coming from memory, or
	--	selecting as least significant byte one of the bytes coming from 
	--	memory, providing a 24-bit 0-extension. See details below. The
	--	processor is assumed to be	"little endian".
	-- Single byte reading from memory (using instruction LBU)
	-- 15/02/2025 - This assignment adapts MIPS_S behavior to the way
	--              an interleaved, 4-bank data memory works. Such an
	--				organization always accesses data in a 4-byte aligned
	--				frontier, ignoring the last 2 bits of d_address (RALU). 
	--				Thus, to keep byte reading operations correct according
	--				to the MIPS specification, MIPS_S uses 
	--				d_address(1 downto 0) to displace the expected byte to
	--				always be the least significant byte (LSB).
	--
	--	There are then two alternative codings:
    -- When using interleaved memory use the code below
	M8: MDR_in <= data_in when uins.i=LW  else
              x"000000" & data_in( 7 downto  0) when RALU(1 downto 0)="00" else
              x"000000" & data_in(15 downto  8) when RALU(1 downto 0)="01" else
              x"000000" & data_in(23 downto 16)	when RALU(1 downto 0)="10" else
              x"000000" & data_in(31 downto 24) -- when RALU(1 downto 0)="11"
              ;
    --	When using non-interleaved, directly byte addressable memory
	--		organization, use the code below (e.g. for MIPS_S_Sim)
	--M8: MDR_in <= data when uins.i=LW  else	x"000000" & data(7 downto 0);

 	-- Instantiation of the Memory Data Register (MDR)
	RMDR: entity work.reg32bits port map(ck=>ck, rst=>rst, ce=>uins.wmdr, 
										 D=>MDR_in, Q=>MDR);                 

	--=========================================================================
	-- Fifth stage
	--	- This is the write-back stage. It writes computed results to the 
	--		register bank and updates the PC for memory read operations.
	--	- Otherwise, (in instructions other than LW or LBU) this is used as
	--		the fourth execution cycle where either the register bank and the 
	--		PC are written, or just the PC is written (for branchs, J, MULTU
	--		and DIVU) 
	--=========================================================================

	-- M9 is the mux that chooses what data to forward to the bank write port
	M9: RESULT <=	MDR when uins.i=LW or uins.i=LBU else
                    HI when uins.i=MFHI else
                    LO when uins.i=MFLO else
                    RALU; 

	-- M10 is the mux that chooses the address of the register to write
	--	in the register bank
	M10: adD <= "11111" when uins.i=JAL else 
		-- JAL always writes to reg $31
		IR_IN(15 downto 11) when (inst_Rgroup='1' 
			or uins.i=SLTU or uins.i=SLT 
			or uins.i=JALR
			or uins.i=MFHI or uins.i=MFLO 
			or uins.i=SSLL or uins.i=SLLV
			or uins.i=SSRA or uins.i=SRAV
			or uins.i=SSRL or uins.i=SRLV) else
		IR_IN(20 downto 16)
		-- when inst_Igroup='1' or uins.i=SLTIU or uins.i=SLTI 
		--	or uins.i=LW or uins.i=LBU or uins.i=LUI, or default
		;

	-- M11 is the mux that chooses the data to write in the register bank
	M11: RIN <= NPC_IN when (uins.i=JALR or uins.i=JAL) else RESULT;

	RESULT_OUT <= RESULT;

end datapath;

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- Control Unit mixed (structural/behavioral) description
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use work.p_MIPS_S.all;

entity control_unit is
        port(	ck, rst						: in std_logic;
                suspend                     : in std_logic;
                suspend_ack                 : out std_logic;
				i_address					: out wires32;
				instruction					: in wires32;
				IR_OUT						: out wires32;
				uins						: out microinstruction;
				NPC_OUT						: out wires32;
				inst_Bgroup_in, jump_in		: in std_logic;
				end_mul, end_div			: in std_logic;
				RESULT_IN					: in wires32
             );
end control_unit;

architecture control_unit of control_unit is
	type type_state is (Sfetch, Sreg, Salu, Swbk, Sld, Sst, Sjump); 
   -- Only 7 states are required in the control FSM
	signal PS, NS : type_state; -- PS = present state; NS = next state
	signal i : inst_type;
	signal uins_int : microinstruction;
	signal PC_in, PC, incpc, NPC, IR : wires32;
	signal suspend_ack_intcu : std_logic;

begin
	---------------------------------------------------------------------------
	-- First stage of MIPS_S - Control Unit Block 1 of 4
	--	- This is Control Unit Block 1 of 4, which implements the MIPS_S main
	--		control registers.
	--	- This stage performs the instruction fetch from Instruction Memory,
	--		stores it in IR and increments the PC, storing it in NPC register.
	---------------------------------------------------------------------------

	-- M1 is the mux that selects what to input to the PC register 
	M1: PC_in <= RESULT_IN when (inst_Bgroup_in='1' and jump_in='1') 
			or uins_int.i=J or uins_int.i=JAL 
			or uins_int.i=JALR or uins_int.i=JR	else
   		NPC;
   
	NPC_OUT <= NPC;
	
	-- Instruction Memory starting address: beware of the OFFSET, initially
	--	loaded into the PC register!
	-- Use line below for code generated with the PCSPIM simulator
	-- PC_reg: entity work.reg32bits generic map(INIT_VALUE => x"00400020")
	-- Use line below for code generated with the MARS simulator
	-- PC_reg: entity work.reg32bits generic map(INIT_VALUE => x"00400000")   
	PC_reg: entity work.reg32bits generic map(INIT_VALUE=>x"00400000")   
		port map(ck=>ck, rst=>rst, ce=>uins_int.wpc, D=>PC_in, Q=>PC);

	incpc <= PC + 4;
  
	NPC_reg: entity work.reg32bits 
			port map(ck=>ck, rst=>rst, ce=>uins_int.CY1, D=>incpc, Q=>NPC);
           
	IR_reg:	entity work.reg32bits  
			port map(ck=>ck, rst=>rst, ce=>uins_int.CY1, 
					 D=>instruction, Q=>IR);

	IR_OUT <= IR ;    	-- IR is the instruction register 
             
	i_address <= PC;	-- Connect the contents of the PC register to the 
						-- address bus of the Instruction Memory

	---------------------------------------------------------------------------
	-- 	This is the Control Unit Block 2 of 4
	--	- Instruction Decoding (& info enabling the ALU operation definition).
    --	- This block generates 1 Output Function of the Control Unit, signal i.
	--	- Signal i identifies which of the 37 distinct instructions of MIPS_S
	--		is loaded currently in the IR register.
	--	- Signal i is part of the MIPS_S output function control state machine.
	---------------------------------------------------------------------------
    i <=   ADDU   when IR(31 downto 26)="000000" 
						and IR(10 downto 0)="00000100001" else
           SUBU   when IR(31 downto 26)="000000" 
						and IR(10 downto 0)="00000100011" else
           AAND   when IR(31 downto 26)="000000" 
						and IR(10 downto 0)="00000100100" else
           OOR    when IR(31 downto 26)="000000" 
						and IR(10 downto 0)="00000100101" else
           XXOR   when IR(31 downto 26)="000000" 
						and IR(10 downto 0)="00000100110" else
           NNOR   when IR(31 downto 26)="000000" 
						and IR(10 downto 0)="00000100111" else
           SSLL   when IR(31 downto 21)="00000000000" 
						and IR(5 downto 0)="000000" else
           SLLV   when IR(31 downto 26)="000000" 
						and IR(10 downto 0)="00000000100" else
           SSRA   when IR(31 downto 21)="00000000000" 
						and IR(5 downto 0)="000011" else
           SRAV   when IR(31 downto 26)="000000" 
						and IR(10 downto 0)="00000000111" else
           SSRL   when IR(31 downto 21)="00000000000" 
						and IR(5 downto 0)="000010" else
           SRLV   when IR(31 downto 26)="000000" 
						and IR(10 downto 0)="00000000110" else
           ADDIU  when IR(31 downto 26)="001001" else
           ANDI   when IR(31 downto 26)="001100" else
           ORI    when IR(31 downto 26)="001101" else
           XORI   when IR(31 downto 26)="001110" else
           LUI    when IR(31 downto 26)="001111" else
           LW     when IR(31 downto 26)="100011" else
           LBU    when IR(31 downto 26)="100100" else
           SW     when IR(31 downto 26)="101011" else
           SB     when IR(31 downto 26)="101000" else
           SLTU   when IR(31 downto 26)="000000" 
						and IR(5 downto 0)="101011" else
           SLT    when IR(31 downto 26)="000000" 
						and IR(5 downto 0)="101010" else
           SLTIU  when IR(31 downto 26)="001011" else
           SLTI   when IR(31 downto 26)="001010" else
           BEQ    when IR(31 downto 26)="000100" else
           BGEZ   when IR(31 downto 26)="000001" 
						and IR(20 downto 16)="00001" else
           BLEZ   when IR(31 downto 26)="000110" 
						and IR(20 downto 16)="00000" else
           BNE    when IR(31 downto 26)="000101" else
           J      when IR(31 downto 26)="000010" else
           JAL    when IR(31 downto 26)="000011" else
           JALR   when IR(31 downto 26)="000000"  
						and IR(20 downto 16)="00000" 
						and IR(10 downto 0) = "00000001001" else
           JR     when IR(31 downto 26)="000000" 
						and IR(20 downto 0)="000000000000000001000" else
           MULTU  when IR(31 downto 26)="000000" 
						and IR(15 downto 0)="0000000000011001" else
           DIVU   when IR(31 downto 26)="000000" 
						and IR(15 downto 0)="0000000000011011" else
           MFHI   when IR(31 downto 16)=x"0000" 
						and IR(10 downto 0)="00000010000" else
           MFLO   when IR(31 downto 16)=x"0000" 
						and IR(10 downto 0)="00000010010" else
           invalid_instruction ;
		   -- IMPORTANT: the default condition is invalid instruction;
        
    assert i /= invalid_instruction
          report "******************* INVALID INSTRUCTION *************"
          severity error;
                   
    uins_int.i <= i;    
	-- This signal instructs the ALU to execute its operation
	-- It also controls the operation of most multiplexers in the Datapath and
	--	Control Unit, which define the paths to use for every instruction
	--	execution.

	---------------------------------------------------------------------------
	-- 	This is the Control Unit Block 3 of 4
	--		- Two VHDL processes respectively generate:
	--			1) The state register of the MIPS_S Control FSM
	--			2) The state transition function of the MIPS_S Control FSM
	--     - A third VHDL process command was added  in 05/05/2025 to 
	--          register the suspend_ack signal  
	---------------------------------------------------------------------------
cu_st_reg:
    process(rst, ck)
    begin
       if rst='1' then
            PS <= Sfetch;      
				-- Sfetch is the state the FSM stays during processor reset
       elsif ck'event and ck='1' then
				PS <= NS;
       end if;
    end process;

cu_nxtst_func:
    process(PS, i, end_mul, end_div, suspend, suspend_ack_intcu)
	-- The next state function: it depends on the Present State (PS), on
	--	the current instruction and on the end_mul/end_div signals, 
	--	which unlock the control unit at the end of division or
	--	multiplication instructions
	begin
       case PS is         
            -- Sfetch activates the First stage: if suspend is not active
            --  the instruction pointed to by the PC is fetched and the
            --  incremented PC is saved in NPC
            when Sfetch=>	if (suspend='1') then
                                NS <= Sfetch;
                            else
                                NS <= Sreg;
                            end if;
            -- SReg activates the Second stage: instruction operands
			--	are produced for most instructions, data register contents,
			--	immediate data and values to compute jump/branch addresses
            when Sreg=>		NS <= Salu;
            -- Salu activates the Third stage: ALU executes its operation,
			--	if any, the Comparator acts and/or Divider of Multiplier act
            when Salu =>	if (i=LBU or i=LW) then 
								NS <= Sld;  
							elsif (i=SB or i=SW) then 
								NS <= Sst;
							elsif (i=J or i=JAL or i=JALR or i=JR or i=BEQ
									or i=BGEZ or i=BLEZ  or i=BNE) then 
								NS <= Sjump;
							elsif ((i=DIVU and end_div='0') 
									or (i=MULTU and end_mul='0')) then
								NS <= Salu;
							elsif ((i=DIVU and end_div='1') 
									or (i=MULTU and end_mul='1')) then
								NS <= Sfetch;
							else 
								NS <= Swbk; 
							end if;
            -- Sld activates the Fourth stage: Operation occurs at the 
			--	Data Memory, if any
            when Sld=>  	NS <= Swbk;
            -- Sst/Sjump/ Swbk activate the Fourth or the Fifth stage,
			--	which are the last stage for most instructions
            when Sst | Sjump | Swbk=> NS <= Sfetch;
       end case;
    end process;

cu_susp_ack_reg:
    process(rst, ck)
    begin
       if rst='1' then
            suspend_ack_intcu <= '0';      
				-- suspend_ack is made inactive at reset
       elsif ck'event and ck='1' then
				if (PS=Sfetch and suspend='1') then
				    suspend_ack_intcu <= '1';
				else
				    suspend_ack_intcu <= '0';
				end if;
       end if;
    end process;
    
    suspend_ack <= suspend_ack_intcu;

	---------------------------------------------------------------------------
	-- This is the Control Unit Block 4 of 4
    --	- Output function of the MIPS_S Control FSM
	--	- Generates 11 control signals. Most of these are write enable signals
	--		for registers on the Datapath and Control Unit. 
    -- 	- Also, this Block generates the control signals to access the Data 
	-- 		Memory and the Divider and Multiplier initialization controls.
	--	- Overall, there are 11 Boolean functions, one for each control signal
	---------------------------------------------------------------------------
	uins_int.CY1	<= '1' when PS=Sfetch			else '0';

	uins_int.CY2	<= '1' when PS=Sreg				else '0';

	uins_int.rst_md	<= '1' when PS=Sreg and (i=MULTU or i=DIVU)
													else '0';

	uins_int.walu	<= '1' when PS=Salu				else '0';

	uins_int.ce		<= '1' when PS=Sld or PS=Sst	else '0';

	uins_int.rw		<= '0' when PS=Sst				else '1';

	uins_int.bw		<= '1' when PS=Sst and i=SB		else '0';

	uins_int.wmdr	<= '1' when PS=Sld				else '0';

	uins_int.wreg	<= '1' when PS=Swbk or (PS=Sjump and (i=JAL or i=JALR)) 
													else   '0';

	uins_int.wpc	<= '1' when PS=Swbk or PS=Sst or PS=Sjump 
								or (PS=Salu and ((i=MULTU and end_mul='1')
												or (i=DIVU and end_div='1')))
													else  '0';

	uins_int.whilo	<= '1' when PS=Salu and ((end_mul='1' and i=MULTU)
											or (end_div='1' and i=DIVU))
													else  '0';

	uins <= uins_int;

end control_unit;

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--	MIPS_S (Prototypable) Top Level entity
--		It instantiates the Datapath and Control units
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use work.p_MIPS_S.all;

entity MIPS_S is
    port( clock, reset		: in std_logic;
          ce, rw, bw		: out std_logic;
          suspend			: in std_logic;
		  suspend_ack		: out std_logic;
          i_address			: out wires32;
          instruction		: in wires32;
          d_address			: out wires32;
          data_in			: in wires32;
		  data_out			: out wires32
		);
end MIPS_S;

architecture MIPS_S of MIPS_S is
	signal IR, NPC, RESULT 						: wires32;
	signal uins 								: microinstruction;  
	signal inst_Bgroup, jump, end_mul, end_div	: std_logic;
	signal suspend_ack_int						: std_logic;
begin

	cu: entity work.control_unit port map(ck=>clock, rst=>reset,
	    suspend=>suspend, suspend_ack=>suspend_ack_int, 
		i_address=>i_address, instruction=>instruction,
		IR_OUT=>IR, uins=>uins, NPC_OUT=>NPC,
		inst_Bgroup_in=>inst_Bgroup, jump_in=>jump, 
		end_mul=>end_mul, end_div=>end_div,
		RESULT_IN=>RESULT
		);

    -- MIPS_S status suspend_ack output pin is generated by cu and passed
    --  to the datapath and to the outside world
    suspend_ack <= suspend_ack_int; 

	dp: entity work.datapath port map(ck=>clock, rst=>reset,
	    suspend_ack=>suspend_ack_int,
		d_address=>d_address, data_in=>data_in, data_out=>data_out,
		uins=>uins, IR_IN=>IR, NPC_IN=>NPC,
		end_mul=>end_mul, end_div=>end_div,
		inst_Bgroup_out=>inst_Bgroup, jump_out=>jump,
		RESULT_OUT=>RESULT		
		);

    ce <= uins.ce when suspend_ack_int='0' else 'Z';
    rw <= uins.rw when suspend_ack_int='0' else 'Z';
    bw <= uins.bw when suspend_ack_int='0' else 'Z';

end MIPS_S;