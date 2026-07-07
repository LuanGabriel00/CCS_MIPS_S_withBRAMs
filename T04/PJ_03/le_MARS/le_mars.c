/******************************************************************************
*  This is a C program that reads the MARS MIPS simulator Text and Data Memory
*	dumps and generates a VHDL file (memory.vhd) containing 2 or more
*	entity/architecture pairs declarations, which define one Instruction
*   Memory module or more  Data Memory Blocks
*	Observations:
*		1) The dumps are assumed to contain exclusively hexadecimal values
*		for addresses, object code and data. Parameterize MARS to generate
*		dumps adequately for input to this program
*		2) The memory module size are fixed, 1 16-Kbit block for the
*           Instruction Memory and 4 16-Kbit blocks (64 Kbits) for each Data
*           Memory module.
*
*  FERNANDO GEHM MORAES - 16/Nov/2007 - First version (for the PCSPIM sim)
*  NEY LAERT VILAR CALAZANS - 16/Nov/2007
* 		- Software changed to support MARS memory dumps
*  FERNANDO MORAES - 30/Oct/2012
*		- Changed to accept 2 native MARS dump files, without edition
*  FERNANDO MORAES - 01/Jun/2013
*		- Change to use function getline2 instead of getline
*  NEY CALAZANS - 12/Jun/2013
*		- Small documentation bug in the software Help solved
*  NEY CALAZANS - 14-15/Feb/2025
*		- Data Memory organization bug that generated incorrect operation
*			for instruction SB corrected
*       - Data memory organization bug in chip enable signals connections
*			(all modules were connected to w3 only) corrected
*       - Data memory organization bug that wrongly chose the block where
*			to perform a single byte write in SB instruction corrected
*  NEY CALAZANS - 24/Apr/2025
*		- The polarity of the bw signal was changed to adapt to the current
*			revision of the MIPS_S architecture implementation bw='1' now
*			means a single byte is to be written in memory
*		- Minor change: The names of the memory architectures are the same
*			as their entity names
*		- Program comments are now all in English
*  NEY CALAZANS - 1st/Jun/2025
*       - A comment warning was added to remember that in the Data Memory
*           the ce input signal, although  it exists, is currently unused
*  NEY CALAZANS - 23/Nov/2025
*       - The Sw has been enhanced to allow building more than
*           one Data Memory module, currently up to 4 8-Kbytes modules
*           (see the MAX_DATA_MODULES added constant)
*       - Most of the Sw has been translated to English to facilitate
*           distribution and portability, including internal variable names
*       - Instruction Memory char string memoria_dados changed to
*           instruction_mem
*       - ram_i Data Memory block denominations changed to datablock_i
*       - The possibility to create more than one Instruction Memory module
*           is in preparation, (see the MAX_INST_MODULES added constant)
*       - Function search_word renamed to search_token
*       - Variable palavra changed to word
*  NEY CALAZANS - 04/Jun/2026
*       - Small comments revision of the code, no effective code change
*  NEY CALAZANS - 12/Jun/2026
*       - A ridiculous and ridiculously old error in the data memory blocks
*           comments was corrected, changing the wrong "bytes x to y" by
*           "bits x downto y".
******************************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include <time.h>
#include <stdbool.h> // Added in 10/11/2025 - Ney Calazans

#define TAM 250

int separator(char car)
 {
  switch(car)
   { case ' ': case '\n': case '\t': case '\r':   case '/':
     case '*': case '=':  case ',':   case '.':  return 1;
     default: return 0;
   }
}

/******************************************
* Return a string from the file line read *
******************************************/
int search_token(char *word, int *counter, char *token)
{
    int             k = 0;

    while (separator(word[*counter]))
        (*counter)++;
    while (!separator(word[*counter]) && word[*counter] != '\0')
        token[k++] = word[(*counter)++];
    token[k] = '\0';
    return k;
}

/**********************************************************************/
 // Routine to read a line from dump files - Fernando Moraes
/**********************************************************************/
int getline2(word, limit, p1)
    char           *word;
    FILE           *p1;
    int             limit;
/**********************************************************************/
{   int             i = 0;
    char            c;

    while ((c = getc(p1)) != '\n') {
        if (c == EOF)
            return 0;
        word[i] = c;
        if(++i==TAM)
             { printf("\ERROR: line too large %s %d\n", word,
                      (int) strlen(word));
               fflush(stdout);
               exit(1);
             }
    }

    word[i] = 0x00;   // takes the \n char from the string
    return 1;
}

//-----------------------------------------------------------------------------
int main(int argc, char *argv[])
//-----------------------------------------------------------------------------
{
  FILE *fp, *out;
  int i, j, k, word, offset, b, DEBUG;
  int no_inst_modules=1; // Number of Inst Memory Inst modules, defaults to 1
        // variable no_inst_modules is here for future use...
  int no_data_modules=1; // Number of Data Memory Inst modules, defaults to 1
  bool mod_startadd_set;

  // Preparing to support more than one 2-Kbyte Instruction Memory module
  const int MAX_INST_MODULES = 4;
  // For now, each Instruction memory module is 2-Kbyte
  //    (up to 512 32-bit instructions)
  char line[TAM], wd[TAM], instruction_mem[MAX_INST_MODULES][64][65];

  // Up to 4 8-Kbyte Data Memory modules, for now
  const int MAX_DATA_MODULES = 4;
  int mod_startadd[MAX_DATA_MODULES];
    /// The start addresses for Data Memory modules
  // Every Data Memory module relies on four BRAM blocks produced after
  //    filling datablock0 to datablock3 strings with data read from
  //    the Mars Data Memory dumps
  char  datablock0[MAX_DATA_MODULES][64][65],
        datablock1[MAX_DATA_MODULES][64][65],
        datablock2[MAX_DATA_MODULES][64][65],
        datablock3[MAX_DATA_MODULES][64][65];
  time_t clock;

  clock = time(NULL);

  if (argc<2) {
     puts("*************************************************************");
     puts("* This program reads two files: one with MIPS_S object code *");
     puts("*   instructions for the program to execute and one         *");
     puts("*   containing the data for the program                     *");
   printf("* usage: %12s <InstrFile> <DataFile> [ni] [nd] [d]  *\n",argv[0]);
     puts("*   [ni] is the optional number of 2Kbytes Instruction      *");
     puts("*        Memory modules to generate. It defaults to 1.      *");
     puts("*   [nd] is the optional number of 8Kbytes Data Memory      *");
     puts("*        modules to generate. It defaults to 1.             *");
     puts("*       [ni] must be present if [nd] is to be specified     *");
     puts("*   [d] can be any optional printable char. If it exists,   *");
     puts("*        indicates debugging. [ni] and [nd] must be present *");
     puts("*       (use e.g. ni=nd=1) when requesting debug.           *");
     puts("*   Report bugs to nlvcalazans@gmail.com and/or             *");
     puts("*               to fernando.moraes@pucrs.br                 *");
     puts("*************************************************************\n");
     return(0);
  }

	// Initializes all char strings related to Instruction Memory modules
	// 	- Each module is a 1-BRAM block with 512 32-bit words
	//  - Access is word aligned in addresses multiple of 4
  for (k=0; k<MAX_INST_MODULES; k++)
    for(i=0; i<64; i++)
        for(j=0; j<65; j++)
            if (j==64)
                instruction_mem[k][i][j]='\0';
                // in all modules, at the end of each line,
                //      put an end of string character
// Debug code
//            {
//                printf("Inserted end of string in k=%d, i=%d, j=%d!\n", k, i, j);
//            }
            else instruction_mem[k][i][j]='0';
            // all 64 nibbles in each line initially set to 0

//  // Debug code, to see if strings are OK
//  for (k=0; k<MAX_INST_MODULES; k++)
//    { printf("Module %d:\n", k);
//      for (i=0; i<64; i++)
//        printf("Linha %d: %s\n", i, instruction_mem[k][i]);
//    }

	// Initializes all char strings related to Data Memory modules
	//	- Each Data Memory module contains 4 BRAMs, which are
	//      interleaved to create a 2-Kbytes chunk, accessible as
	//      - 32-bit words aligned at multiple-of-4 memory addresses
	//      - single 8-bit bytes at each memory module address
  for (k=0; k<MAX_DATA_MODULES; k++)
    for(i=0; i<64; i++)
      for(j=0; j<65; j++)
        if (j==64)
        {
            datablock0[k][i][j]='\0';
            datablock1[k][i][j]='\0';
            datablock2[k][i][j]='\0';
            datablock3[k][i][j]='\0';
            // in all blocks of all modules, at the end of each line,
            //      put an end of string character
        }
        else
        {
            datablock0[k][i][j]='0';
            datablock1[k][i][j]='0';
            datablock2[k][i][j]='0';
            datablock3[k][i][j]='0';
                // all 64 nibbles in each line initially set to 0
        }

  out = fopen("memory.vhd", "w");

  if (argc>5)  DEBUG=1;  else  DEBUG=0;

  if (DEBUG)
  {
      for (i=0; i<argc; i++)
        printf("Argv[%d]=%s, ", i, argv[i]);
      printf("\nArgc=%d\n", argc);
  }

  //////////////////
  ///////////////// Reads input file containing Instruction contents
  /////////////////
  if ((fp = fopen(argv[1], "r")) == NULL) {
            printf("Error while opening file %s !\n", argv[1]);
            printf("The file memory.vhd will not be produced\n");
            return 0;
        }

  if (argc>3 && atoi(argv[3])!=1) {
            // For now we can only generate a single Inst Memory module
            printf("\nMore than 1 Instruction Memory module (%s)\n", argv[3]);
            printf("generation is not yet supported!!!\n");
            printf("The file memory.vhd will not be produced\n");
            return 0;
        }

  puts("---------------------- PROCESSING INSTRUCTIONS ");

  offset = 56;
  word = 0;

  // verifies if the MARS Instruction Memory dump file has the expected format
  getline2(line, TAM, fp);
  i = 0;
  search_token(line, &i, wd);
  if( strcmp(wd,"Address")) {
  	 printf("\nThe first word of the instruction file is %s and not Address", wd);
  	 printf("\nMaybe you changed the input file order... - REVIEW!\n");
     printf("The file memory.vhd will not be produced\n");
  	 return(0);
   }

  // When here, header seems fine, process next lines
  // For now, it is assumed the text segment contains at most 512 instructions,
  //    this limitation shall be removed in later versions of this software
  while (getline2(line, TAM, fp))
    {
      i = 0;                         // points to the line start
      search_token(line, &i, wd);     // wd is a pointer to the next token

      if (wd[0]=='0' &&  wd[1]=='x' )
		  // the program line starts with "0x" ==> valid address
           {
             if (DEBUG) printf("Program memory address %10s ", wd);
             search_token(line, &i, wd);      // code
             if (DEBUG) printf("with opcode %10s\n", wd);
             // Transfer to the Data Memory (Output generation)
             for(b=0; b<8; b++)
                  instruction_mem[0][word][offset+b] = wd[b+2];
					// "+2" passes over "0x"
              offset = offset - 8;
              if( offset < 0 )
                { offset = 56 ;
				//	Displacement inside the string relative to the memory
				//	The string goes from 0 to 63
                  word ++ ;
                }
            }
     }
  fclose(fp);

  //////////////////
  /////////////////    READ DATA FILE
  /////////////////
  if ((fp = fopen(argv[2], "r")) == NULL) {
            printf("Error while opening file %s !\n", argv[2]);
            printf("The file memory.vhd will not be produced\n");
            return 0;
        }

  if (argc>4 && (no_data_modules=atoi(argv[4]))>MAX_DATA_MODULES) {
            printf("\nGenerating more than %d Data Memory modules (%s)",
                   MAX_DATA_MODULES, argv[4]);
            printf("\n is not yet supported!!!\n");
            printf("The file memory.vhd will not be produced\n");
            return 0;
        }

  puts("---------------------- PROCESSING DATA ");
  word = 0;

  // The number of Data Memory modules to produce is now determined
  //    It is smaller of equal to MAX_DATA_MODULES and defaults to 1
  k = 0;    // k is the module number being processed, at least one exists
  mod_startadd_set = false; // Boolean to ensure that the module start
                            //  address will only be computed the first time
                            // around the loop
  if (DEBUG)
    printf("\nNumber of Data Modules to generate: %d\n", no_data_modules);

      while (getline2(line, TAM, fp))
        {
          i = 0;    // points to the line start
          search_token(line, &i, wd);   // wd is the pointer to the next token

          if (wd[0]=='0' &&  wd[1]=='x' )
              // the program line starts with "0x" ==> valid address
               {
                 wd[10] = '\0';                     //  puts a newline char after the last digit
                 /// Now, compute the Data Memory module start address, if required
                 if (!mod_startadd_set)
                    {   // Code executed just once, in the beginning of processing
                        mod_startadd[k] = strtol(&wd[2], NULL, 16);
                        if (DEBUG)
                            printf("\nStart address of Data Module %d: %#010x\n", k, mod_startadd[k]);
                        mod_startadd_set = true;
                    }
                 else   // test if last turn of the loop finished a module
                        //  and another one is to be started
                    {
                        if (strtol(&wd[2], NULL, 16) == mod_startadd[k]+8192)
                        // Find first line of a new Data Memory module,
                        //  see if is a valid one
                        if (++k<no_data_modules)
                           {   // Yes, it is valid new Data Memory module
                               mod_startadd[k] = strtol(&wd[2], NULL, 16);
                               if (DEBUG)
                                printf("\nStart address of Data Module %d: %#010x\n", k,
                                        mod_startadd[k]);
                           }
                        else    // No, there is too much data, flag it!
                           {
                               printf("Error: data after module %d.\n", argv[2]);
                               printf("The file memory.vhd will not be produced\n");
                               return 0;
                           }
                    }
                    // Arriving here, there is a valid line of a valid module to  treat
                 if (DEBUG) printf("\nLine Address %10s\n", wd);
                 /// Every token has a format	0 x 1 2 3 4 5 6 7 8 - it is a 10-byte string
                 /// indices            		0 1 2 3 4 5 6 7 8 9

                 sscanf(wd+6, "%X", &offset);       //	convert to int from the 4th char on
                 offset = offset - (8192*k);                  //  offset computed considering the block
                                                    //      under treatment now
                 offset /= 4;                       //	divide by 4 to obtain word addressing
                 word = offset / 32;             // The address division gives the memory index

                 if (DEBUG)
                    printf ("wd: %s; offset: %d; word: %d\n", wd, offset, word);

                 if( word > 63 ) continue;       // Avoids that matrix incurs in overflow
                    offset -= word*32; // The remainder
                    //	wd indices:   2 3 4 5 6 7 8 9     example: 12345678
                    while ( search_token(line, &i, wd))     // reads the rest of the line
                       if (wd[0]=='0' &&  wd[1]=='x')
                        {
                            if (DEBUG) printf("p%d o%d %s\n", word, offset, wd);
                            datablock3[k][word][63-offset*2-1] = wd[2];       // if offset=0   62
                            datablock3[k][word][63-offset*2]   = wd[3];       //               63
                            datablock2[k][word][63-offset*2-1] = wd[4];
                            datablock2[k][word][63-offset*2]   = wd[5];
                            datablock1[k][word][63-offset*2-1] = wd[6];
                            datablock1[k][word][63-offset*2]   = wd[7];
                            datablock0[k][word][63-offset*2-1] = wd[8];
                            datablock0[k][word][63-offset*2]   = wd[9];
                            offset += 1;
                        }
               }
        }

   fclose(fp);

   puts("---------------------- Generating the VHDL file memory.vhd\n");

   fprintf(out,"--\n--  Automatically Generated");
   fprintf(out,"--  Authors: Fernando Moraes & Ney Calazans");
   fprintf(out,"\n--  Generation date: %s--\n\n", ctime(&clock) );
   fprintf(out,"--------------------------------------------------------\n");
   fprintf(out,"--  Instruction Memory Module %d\n", k);
   fprintf(out,"--    512 32-bit words (2KBytes, 16Kbits, 1 BRAM)\n");
   fprintf(out,"--------------------------------------------------------\n");
   fprintf(out,"library IEEE;\n");
   fprintf(out,"use IEEE.Std_Logic_1164.all;\n");
   fprintf(out,"library UNISIM;\n");
   fprintf(out,"use UNISIM.vcomponents.all; \n");
   fprintf(out,"\n");
   fprintf(out,"entity program_memory is\n");
   fprintf(out,"    port( clock: in std_logic;\n");
   fprintf(out,"          address: in std_logic_vector(8 downto 0);\n");
   fprintf(out,"          instruction: out std_logic_vector(31 downto 0));\n");
   fprintf(out,"end program_memory;\n");
   fprintf(out,"\n");
   fprintf(out,"architecture program_memory of program_memory is     \n");
   fprintf(out,"begin\n");
   fprintf(out,"           \n");
   fprintf(out,"   inst_mem : RAMB16_S36\n");
   fprintf(out,"   generic map (\n");
   for(i=0 ; i<16; i++)
         fprintf(out,"        INIT_0%X => X\"%s\",\n", i, instruction_mem[0][i]);
   for(i=16 ; i<63; i++)
         fprintf(out,"        INIT_%X => X\"%s\",\n", i, instruction_mem[0][i]);
   fprintf(out,"        INIT_%X => X\"%s\")\n", i, instruction_mem[0][i]);
   fprintf(out,"   port map (\n");
   fprintf(out,"            CLK     => clock,\n");
   fprintf(out,"            ADDR    => address,\n");
   fprintf(out,"            EN      => '1',\n");
   fprintf(out,"            WE      => '0',\n");
   fprintf(out,"            DI      => x\"00000000\",\n");
   fprintf(out,"            DIP     => x\"0\",\n");
   fprintf(out,"            DO      => instruction,\n");
   fprintf(out,"            SSR     => '0'\n");
   fprintf(out,"            );\n");
   fprintf(out,"\n");
   fprintf(out,"end program_memory;\n");

   for (k=0; k<no_data_modules; k++)
   {
       fprintf(out,"\n----------------------------------------------------------\n");
       fprintf(out,"--  Data Memory Module %d - Four 2048 8-bit bytes blocks,\n",k);
       fprintf(out,"--      interleaved (8KBytes, 64Kbits, 4 BRAMs)\n");
       fprintf(out,"--  This module start address is %#010x\n", mod_startadd[k]);
       fprintf(out,"--  Possible data access methods for read/write operations:\n");
       fprintf(out,"--      * byte, at any address\n");
       fprintf(out,"--      * 32-bit words at addresses multiple of 4\n");
       fprintf(out,"--  When using more than one Memory Module beware:\n");
       fprintf(out,"--      1) Modules are independent of each other,\n");
       fprintf(out,"--          i.e. external decoding will define their\n");
       fprintf(out,"--          relative position in the memory map\n");
       fprintf(out,"--      2) Modules have 13-bit address lines in the\n");
       fprintf(out,"--          range 0x0000 - 0x1FFF. The most significant\n");
       fprintf(out,"--          11 bits are the signal named address. The 2\n");
       fprintf(out,"--          least significant bits are signal byte_choice.\n");
       fprintf(out,"--          In fact, the latter specify in which memory\n");
       fprintf(out,"--          block resides the byte in byte access. For\n");
       fprintf(out,"--          word access, byte_choice must be 00.\n");
       fprintf(out,"--\n");
       fprintf(out,"--  Interleaved memory Example: A memory with contents:\n");
       fprintf(out,"--  00 00 00 00\n");
       fprintf(out,"--  10 00 00 AA\n");
       fprintf(out,"--  20 00 BB 00\n");
       fprintf(out,"--  30 CC 00 00\n");
       fprintf(out,"--  \n");
       fprintf(out,"--  Will result in BRAM data memory first lines filled as:\n");
       fprintf(out,"--  \n");
       fprintf(out,"-- mem 3-  INIT_00 => X\"...000000000000000000030201000\",\n");
       fprintf(out,"-- mem 2-  INIT_00 => X\"...0000000000000000000CC000000\",\n");
       fprintf(out,"-- mem 1-  INIT_00 => X\"...000000000000000000000BB0000\",\n");
       fprintf(out,"-- mem 0-  INIT_00 => X\"...00000000000000000000000AA00\",\n");
       fprintf(out,"--\n");
       fprintf(out,"----------------------------------------------------------\n");
       fprintf(out,"library IEEE;\n");
       fprintf(out,"use IEEE.Std_Logic_1164.all;\n");
       fprintf(out,"library UNISIM;\n");
       fprintf(out,"use UNISIM.vcomponents.all; \n");
       fprintf(out,"\n");
       fprintf(out,"entity data_mem_mod%d is\n", k);
       fprintf(out,"    port( clock, ce, -- For now, ce is unused in module,\n");
       fprintf(out,"    	             -- The EN input of all blocks is '1'.\n");
       fprintf(out,"          we, bw: in std_logic;\n");
       fprintf(out,"          address: in std_logic_vector(10 downto 0);    -- 11 bits - 2048 addressable words\n");
       fprintf(out,"          byte_choice: in std_logic_vector(1 downto 0); -- 2 bits  - 1 of 4 addressable bytes\n");
       fprintf(out,"          data_in: in std_logic_vector(31 downto 0);\n");
       fprintf(out,"          data_out: out std_logic_vector(31 downto 0));\n");
       fprintf(out,"end data_mem_mod%d;\n", k);
       fprintf(out,"\n");
       fprintf(out,"architecture data_mem_mod%d of data_mem_mod%d is \n", k, k);
       fprintf(out,"    signal we3, we2, we1, we0 : std_logic;\n");
       fprintf(out,"    signal d_in_mem3, d_in_mem2, d_in_mem1, d_in_mem0 : std_logic_vector(7 downto 0);\n");
       fprintf(out,"begin\n");
       fprintf(out,"\n");
       fprintf(out,"    we3 <= '1' when (we='0' and ((bw='0') or (bw='1' and byte_choice=\"11\"))) else '0';\n");
       fprintf(out,"    we2 <= '1' when (we='0' and ((bw='0') or (bw='1' and byte_choice=\"10\"))) else '0';\n");
       fprintf(out,"    we1 <= '1' when (we='0' and ((bw='0') or (bw='1' and byte_choice=\"01\"))) else '0';\n");
       fprintf(out,"    we0 <= '1' when (we='0' and ((bw='0') or (bw='1' and byte_choice=\"00\"))) else '0';\n");
       fprintf(out,"    d_in_mem3 <= data_in(7 downto 0) when bw='1' else data_in(31 downto 24);\n");
       fprintf(out,"    d_in_mem2 <= data_in(7 downto 0) when bw='1' else data_in(23 downto 16);\n");
       fprintf(out,"    d_in_mem1 <= data_in(7 downto 0) when bw='1' else data_in(15 downto 8);\n");
       fprintf(out,"    d_in_mem0 <= data_in(7 downto 0);\n\n");
       fprintf(out,"   ----------------------------------------------------------------------------------\n");
       fprintf(out,"   -- bits 31 downto 24\n");
       fprintf(out,"   ----------------------------------------------------------------------------------\n");
       fprintf(out,"    block_3: RAMB16_S9\n");
       fprintf(out,"         generic map (\n");
       for(i=0 ; i<16; i++)
             fprintf(out,"        INIT_0%X => X\"%s\",\n", i, datablock3[k][i]);
       for(i=16 ; i<63; i++)
             fprintf(out,"        INIT_%X => X\"%s\",\n", i, datablock3[k][i]);
       fprintf(out,"        INIT_%X => X\"%s\")\n", i, datablock3[k][i]);
       fprintf(out,"  port map (\n");
       fprintf(out,"         CLK     => clock,\n");
       fprintf(out,"         ADDR    => address,\n");
       fprintf(out,"         EN      => '1',\n");
       fprintf(out,"         WE      => we3,\n");
       fprintf(out,"         DI      => d_in_mem3,\n");
       fprintf(out,"         DIP     => \"0\",\n");
       fprintf(out,"         DO      => data_out(31 downto 24),\n");
       fprintf(out,"         SSR     => '0'\n");
       fprintf(out,"         );\n\n");
       fprintf(out,"   ----------------------------------------------------------------------------------\n");
       fprintf(out,"   -- bits 23 downto 16\n");
       fprintf(out,"   ----------------------------------------------------------------------------------\n");
       fprintf(out,"    block_2: RAMB16_S9\n");
       fprintf(out,"         generic map (\n");
       for(i=0 ; i<16; i++)
             fprintf(out,"        INIT_0%X => X\"%s\",\n", i, datablock2[k][i]);
       for(i=16 ; i<63; i++)
             fprintf(out,"        INIT_%X => X\"%s\",\n", i, datablock2[k][i]);
       fprintf(out,"        INIT_%X => X\"%s\")\n", i, datablock2[k][i]);
       fprintf(out,"  port map (\n");
       fprintf(out,"         CLK     => clock,\n");
       fprintf(out,"         ADDR    => address,\n");
       fprintf(out,"         EN      => '1',\n");
       fprintf(out,"         WE      => we2,\n");
       fprintf(out,"         DI      => d_in_mem2,\n");
       fprintf(out,"         DIP     => \"0\",\n");
       fprintf(out,"         DO      => data_out(23 downto 16),\n");
       fprintf(out,"         SSR     => '0'\n");
       fprintf(out,"         );\n\n");
       fprintf(out,"   ----------------------------------------------------------------------------------\n");
       fprintf(out,"   -- bits 15 downto 8\n");
       fprintf(out,"   ----------------------------------------------------------------------------------\n");
       fprintf(out,"    block_1: RAMB16_S9\n");
       fprintf(out,"         generic map (\n");
       for(i=0 ; i<16; i++)
             fprintf(out,"        INIT_0%X => X\"%s\",\n", i, datablock1[k][i]);
       for(i=16 ; i<63; i++)
             fprintf(out,"        INIT_%X => X\"%s\",\n", i, datablock1[k][i]);
       fprintf(out,"        INIT_%X => X\"%s\")\n", i, datablock1[k][i]);
       fprintf(out,"  port map (\n");
       fprintf(out,"         CLK     => clock,\n");
       fprintf(out,"         ADDR    => address,\n");
       fprintf(out,"         EN      => '1',\n");
       fprintf(out,"         WE      => we1,\n");
       fprintf(out,"         DI      => d_in_mem1,\n");
       fprintf(out,"         DIP     => \"0\",\n");
       fprintf(out,"         DO      => data_out(15 downto 8),\n");
       fprintf(out,"         SSR     => '0'\n");
       fprintf(out,"         );\n\n");
       fprintf(out,"   ----------------------------------------------------------------------------------\n");
       fprintf(out,"   -- bits 7 downto 0\n");
       fprintf(out,"   ----------------------------------------------------------------------------------\n");
       fprintf(out,"    block_0: RAMB16_S9\n");
       fprintf(out,"         generic map (\n");
       for(i=0 ; i<16; i++)
             fprintf(out,"        INIT_0%X => X\"%s\",\n", i, datablock0[k][i]);
       for(i=16 ; i<63; i++)
             fprintf(out,"        INIT_%X => X\"%s\",\n", i, datablock0[k][i]);
       fprintf(out,"        INIT_%X => X\"%s\")\n", i, datablock0[k][i]);
       fprintf(out,"  port map (\n");
       fprintf(out,"         CLK     => clock,\n");
       fprintf(out,"         ADDR    => address,\n");
       fprintf(out,"         EN      => '1',\n");
       fprintf(out,"         WE      => we0,\n");
       fprintf(out,"         DI      => d_in_mem0,\n");
       fprintf(out,"         DIP     => \"0\",\n");
       fprintf(out,"         DO      => data_out(7 downto 0),\n");
       fprintf(out,"         SSR     => '0'\n");
       fprintf(out,"         );\n");
       fprintf(out,"\n");
       fprintf(out,"end data_mem_mod%d;\n", k);
   }

   fclose(out);

   return(1);
}
