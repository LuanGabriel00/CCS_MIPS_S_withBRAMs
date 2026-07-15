-------------------------------------------------------------------------------
--
--  The MIPS_S Simulatable Processor Testbench (Little Endian) 13/10/2004
--
-- 	Observe that the processor is reset by this testbench (rstCPU <= '1')
--		at the start of the simulation, being activated (rstCPU <= '0') only
--		after the end of the file reading and processing of the program 
--		object code to execute, as well as the processing of the program data.
--
-- 	The testbench employs two separate memories, implying a Harvard 
--	processor organization.
--
-- 	Changes:
--	16/05/2012 (Ney Calazans) - Bug fixing:
--		- A bug was detected and corrected in the process of filling the 
--			during the processor reset. The process induced the processor 
--			to enable its ce signal to the memory filling the Data Memory 
--			with garbage at the same time.
--			To solve this the enabling of the Dce signal to the Data Memory
--			was changed from "ce='1' or go_d='1'" to 
--			"(ce='1' and rstCPU/='1') or go_d='1'"
--		- Besides, there was a problem with with the Memory Data writing 
--			operation in the monocicle MIPS implementations: when multiple SW
--			instruções were program in sequence, the writing took place in
--			two sets of memory positions at the same time after the first SW
--			instruction of the series. To solve this, the data signal was
--			removed from the sensitivity list of the memory write process. 
--	10/10/2015 (Ney Calazans)
--		- Signal bw of the Instruction Memory set to '1', since MIPS_S does
--			not produce it for this memory.
--	28/10/2016 (Ney Calazans)
--		- Definitions regX changed to wiresX, to improve code readability.
--	02/06/2017 (Ney Calazans) - Bug fixing:
--		1 - tmp_address changed to int_address in the memory definition
--		2 - In the writing/reading memory processes
--			"CONV_INTEGER(low_address+3)<=MEMORY_SIZE"
--			was changed to
--			"CONV_INTEGER(low_address)<=MEMORY_SIZE-3". This avoids an error
--			that froze the simulation when the ALU contained a rather large
--			number (>65533) in its output immediately before an LW or SW
--			instruction.
--	07/04/2025 (Ney Calazans)
--		- To modernize RAM definitions, several changes were proposed here.
--		- The main motivation is didactical, since using 0-activated control
--			signals is historically sound, it is not essential today, where
--			interface definitions are much more flexible.
--		- Thus, here and in MIPS_S (see its specification)
--	29/10/2025 (Ney Calazans)
--		- The data RAM was made larger (from 2Kbytes to 16Kbytes), to support
--			larger data sets
--	30/10/2025
--		- Lines containing the suspend activation signal were commented, if
--			testing suspension is needed uncomment lines 296-297 below.  
--	05/06/2026
--		- The Data Memory instantiation was changed to accomodate the new size
--			for simulation purposes: 16Kbytes for the MIPS_S Data Memory + 
--									 16Kbytes for (simulating) the Peripheral
--									 Memory.  
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use std.textio.all;
package aux_functions is  
	subtype wires32  is std_logic_vector(31 downto 0);
	subtype wires16  is std_logic_vector(15 downto 0);
	subtype wires8   is std_logic_vector( 7 downto 0);
	subtype wires4   is std_logic_vector( 3 downto 0);

	constant TAM_LINHA : integer := 200;
   
	function CONV_VECTOR( letra : string(1 to TAM_LINHA);
						pos: integer ) return std_logic_vector;
	
	procedure readFileLine(file in_file: TEXT; outStrLine: out string);

end aux_functions;

package body aux_functions is

  --
  -- This function converts a character depicting an hexadecimal value 
  --	in a given text line into the equivalent 4-bit std_logic_vector
  --
	function CONV_VECTOR(letra:string(1 to TAM_LINHA);  pos: integer )
	return std_logic_vector is
	
	variable bin: wires4;
	
	begin
		case (letra(pos)) is  
			when '0' => bin := "0000";
			when '1' => bin := "0001";
			when '2' => bin := "0010";
			when '3' => bin := "0011";
			when '4' => bin := "0100";
			when '5' => bin := "0101";
			when '6' => bin := "0110";
			when '7' => bin := "0111";
			when '8' => bin := "1000";
			when '9' => bin := "1001";
			when 'A' | 'a' => bin := "1010";
			when 'B' | 'b' => bin := "1011";
			when 'C' | 'c' => bin := "1100";
			when 'D' | 'd' => bin := "1101";
			when 'E' | 'e' => bin := "1110";
			when 'F' | 'f' => bin := "1111";
			when others =>  bin := "0000";  
	end case;
	return bin;
	end CONV_VECTOR;

	procedure readFileLine(file in_file: TEXT;  outStrLine: out string) is
		
		variable localLine	: line;
		variable localChar	: character;
		variable isString	: boolean;
			
	begin
		readline(in_file, localLine);

		for i in outStrLine'range loop
			outStrLine(i) := ' ';
		end loop;   

		for i in outStrLine'range loop
			read(localLine, localChar, isString);
			outStrLine(i) := localChar;
			if not isString then -- encontrou o fim da linha
				exit;
			end if;   
		end loop; 	 
	end readFileLine;
end aux_functions;     

-------------------------------------------------------------------------------
-- This is a module that implements a behavioral RAM model with an asynchronous
--	communication interface (i.e. without clock control)
--	- The memory has a single 32-bit, bidirectional data bus.
--	- Also it has a 32-bit address bus, although not all these bits will
--		usually be employed.
--  - The memory is byte addressable, non-interleaved
--  - The memory assumes the processor employs little-endian addressing, i.e.
--      the least significant byte of a 32-bit word is stored/retrieved 
--      to/from the position given in the address bus+0 and the most
--      significant byte is stored/retrieved to/from the position given by
--      address bus+3.
--	- All control signals are active-high
-------------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use std.textio.all;
use work.aux_functions.all;

entity RAM_mem is 
	generic(START_ADDRESS : wires32 := (others=>'0');
			MEMORY_LENGTH : integer := 2048 -- Default size
			);
	port(ce, we, oe, bw	: in std_logic;
			address		: in wires32; data: inout wires32);
end RAM_mem;

architecture RAM_mem of RAM_mem is 
	-- Definition of the type "memory", to use for creating the
	--	Instruction and Data memories
	type memory is array (0 to MEMORY_LENGTH) of wires8;
    signal RAM			: memory;
	signal tmp_address	: wires32;
	-- Signal low_addres has less bits, with width 16, 
	--	due to CONV_INTEGER limitations (?)
	alias  low_address	: wires16 is tmp_address(15 downto 0);    

	begin     
	-- This line provides the address offset adjustment for both,
	--	Instruction and Data memories
	tmp_address <= address - START_ADDRESS;
   
	-- The memory writing process
	-- Asynchronous write to memory - Little Endian
	process(ce, we, low_address)-- Modification here in 16/05/2012 for use
									-- in monocycle MIPS implementations only
	begin
		if ce='1' and we='1' then
			if CONV_INTEGER(low_address)>=0 
				and CONV_INTEGER(low_address)<=MEMORY_LENGTH-3 then
				if bw='0' then -- if it is not byte write, it is word write
					RAM(CONV_INTEGER(low_address+3)) <= data(31 downto 24);
					RAM(CONV_INTEGER(low_address+2)) <= data(23 downto 16);
					RAM(CONV_INTEGER(low_address+1)) <= data(15 downto  8);
				end if;
				RAM(CONV_INTEGER(low_address  )) <= data( 7 downto  0); 
			end if;
		end if;   
	end process;   
    
	-- The memory reading process - always reads 32 bits
	process(ce, oe, low_address)
	begin
		if (ce='1' and oe='1' and
			(CONV_INTEGER(low_address)>=0 and CONV_INTEGER(low_address)<=MEMORY_LENGTH-3)) then
				data(31 downto 24) <= RAM(CONV_INTEGER(low_address+3));
				data(23 downto 16) <= RAM(CONV_INTEGER(low_address+2));
				data(15 downto  8) <= RAM(CONV_INTEGER(low_address+1));
				data( 7 downto  0) <= RAM(CONV_INTEGER(low_address  ));
		else
			data(31 downto 24) <= (others=>'Z');
			data(23 downto 16) <= (others=>'Z');
			data(15 downto  8) <= (others=>'Z');
			data( 7 downto  0) <= (others=>'Z');
		end if;
	end process;   

end RAM_mem;

-------------------------------------------------------------------------------
--  The testbench in itself, to simulate MIPS_S
-------------------------------------------------------------------------------
library ieee;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;          
use std.textio.all;
use work.aux_functions.all;

entity CPU_tb is
end CPU_tb;

architecture cpu_tb of cpu_tb is

    signal Dadress, Ddata, Iaddress, Idata, i_cpu_address, d_cpu_address, 
           data_cpu, tb_add, tb_data	: wires32 := (others => '0' );

    signal Dce, Dwe, Doe, Ice, Iwe, Ioe, ck, rst, rstCPU, 
           go_i, go_d, ce, rw, bw, suspend, suspend_ack	: std_logic;

	-- If the name of the file containing the program/data text is distinct
	--	change the name in the line below 
    file ARQ : TEXT open READ_MODE is "strcpy_large-strs.txt";

begin
           
    Data_mem:  entity work.RAM_mem 
				generic map(START_ADDRESS => x"10010000", 
							MEMORY_LENGTH => 32768)	-- New in 05/06/2026 32K+1bytes
				port map (ce=>Dce, we=>Dwe, oe=>Doe, 
							bw=>bw, address=>Dadress, data=>Ddata);

    Instr_mem: entity work.RAM_mem 
               generic map(START_ADDRESS => x"00400000")
               port map (ce=>Ice, we=>Iwe, oe=>Ioe,
							bw=>'0', address=>Iaddress, data=>Idata);

    -- Signals and glue logic to adapt the Data Memory
	--	to the MIPS_S interface
	---------------------------------------------------------------------------
    Dce <= '1' when (ce='1' and rstCPU/='1') or go_d='1'	else '0'; 
	-- Bug corrected here in 16/05/2012
    Doe <= '1' when (ce='1' and rw='1')						else '0';       
    Dwe <= '1' when (ce='1' and rw='0') or go_d='1'			else '0';    

    Dadress <= tb_add  when rstCPU='1' else d_cpu_address;
    Ddata   <= tb_data when rstCPU='1' 
				else data_cpu when (ce='1' and rw='0') 
				else (others=>'Z'); 
    
    data_cpu <= Ddata when (ce='1' and rw='1') else (others=>'Z');
    
    -- Signals and glue logic to adapt the Instruction Memory
	--	to the MIPS_S interface
	---------------------------------------------------------------------------
    Ice <= '1';                                 
    Ioe <= '0' when rstCPU='1' else '1';
	-- Avoids reading to occur while writing in memory                             
    Iwe <= '1' when go_i='1'   else '0';
	-- Writing during file reading 
    
    Iaddress 	<= tb_add  when rstCPU='1' else i_cpu_address;
    Idata   	<= tb_data when rstCPU='1' else (others => 'Z'); 

    cpu: entity work.MIPS_S  port map(
				clock=>ck, reset=>rstCPU,
				ce=>ce,  rw=>rw,  bw=>bw,
				suspend => suspend, suspend_ack => suspend_ack,
				i_address => i_cpu_address,
				instruction => Idata,
				d_address => d_cpu_address,
				data => data_cpu
		); 

	-- Generates the global reset signal 
	rst <='1', '0' after 15 ns;       

	-- Generates the global clock signal 
	process
	begin
		ck <= '1', '0' after 10 ns;
		wait for 20 ns;
    end process;

    -- Suspension tests, 
    suspend <=  '0'
--				,	'1' after 690ns,  '0' after 1790ns,
--					'1' after 2330ns, '0' after 4730ns
			;
    ---------------------------------------------------------------------------
    -- This process loads the Instruction Memory and the Data Memory
    -- during the time the global reset is active
    --
    --   The process below is a parser to read the code generated by e.g. the
	--		MARS simulator in the following text format:
    --      Text Segment
    --      0x00400000        0x3c011001  lui $1, 4097 [d2]   ;16:la $t0, d2
    --      0x00400004        0x34280004  ori $8, $1, 4 [d2]
	--      0x00400008        0x8d080000  lw $8, 0($8)        ;17:lw $t0,0($t0)
    --      .....
    --      0x00400048        0x0810000f  j 0x0040003c [loop] ;30:j loop
    --      0x0040004c        0x01284821  addu $9, $9, $8  ;32:addu $t1,$t1,$t0
    --      0x00400050        0x08100014  j 0x00400050 [x]    ;34:j x
    --      Data Segment
    --      0x10010000        0x0000faaa  0x00000083  0x00000000  0x00000000
    --
    ---------------------------------------------------------------------------
    process
        variable ARQ_LINE : LINE;
        variable line_arq : string(1 to TAM_LINHA);
        variable code     : boolean;
        variable i, address_flag : integer;
    begin  
        go_i 	<= '0';
        go_d 	<= '0';
        rstCPU 	<= '1';           
		-- Holds the processor under reset during the file reading process
        code:=true;              
		-- Default value for de code is true (standing for instruction reading)
		
        wait until rst = '1';
        
        while NOT (endfile(ARQ)) loop
		-- Start of the process of reading the file containg 
		--	the instructions and data especification.
			readFileLine(ARQ, line_arq);            
			if line_arq(1 to 12)="Text Segment" then 
				code:=true; 			-- Signals instruction reading process.
            elsif line_arq(1 to 12)="Data Segment" then
                   code:=false;			-- Signals data reading process.
            else 
               i := 1;
			   -- Line reading - see the loop below.
               address_flag := 0; 	-- for instructions there is just one pair
									--	(address,instruction) per line.
									-- for data, it accepts one or several 
									--	(address,data) per line.
				loop                                     
					if line_arq(i) = '0' and line_arq(i+1) = 'x' then
						-- Found prefix of a hexadecimal numeral: "0x".
						i := i + 2;
						if address_flag=0 then
							for w in 0 to 7 loop
								tb_add((31-w*4) downto (32-(w+1)*4))
									<= CONV_VECTOR(line_arq,i+w);
							end loop;    
							i := i + 8; 
							address_flag := 1;
						else
							for w in 0 to 7 loop
								tb_data((31-w*4) downto (32-(w+1)*4))
									<= CONV_VECTOR(line_arq,i+w);
							end loop;    
							i := i + 8;
							wait for 0.1 ns;
							if code=true then go_i <= '1';    
											-- Signal go_i enables writing
											-- 	in the Instruction Memory.
								else go_d <= '1';    
								-- Signal go_d enables writing
								-- 	in the Data Memory.
							end if; 
							wait for 0.1 ns;

							tb_add <= tb_add + 4; 
							-- OK, it is possible to read more than
							-- 	one pair (address,data) per line!
							go_i <= '0';
							go_d <= '0'; 

							address_flag := 2;    
							-- Signas that the address was already read.

						end if;
					end if;
					i := i + 1;
					-- Leaves line processing when reached the end of line
					-- 	character, or after having read the pair 
					--	(address, instruction), in case it is processing
					-- 	instructions.
					exit when i=TAM_LINHA or (code=true and address_flag=2);
				end loop;
			end if;
        end loop; 	-- When here, reached the end of the file containing 
					-- instructions and data

		rstCPU <= '0' after 2 ns;   -- Free MIPS_S to execute the program.
		wait for 4 ns;              -- Wait a little time before awaiting 
									--	for a new reset.
		wait until rst = '1';       -- If this ever happens, start all
									--	over again (read instructions 
									--	and data)!!
    end process;

end cpu_tb;
