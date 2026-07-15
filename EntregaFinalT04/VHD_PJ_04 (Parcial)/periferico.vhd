-- A peripheral skeleton to connect to

-- the MIPS_S_withBRAMs Processing Subsystem

--

-- Last Release: 23/June/2026

-- Author: Ney Calazans

--

-- This peripheral implements a state machine controlling a datapath,

-- with the following tasks:

-- 1) Interact with the user to start execution of its expected functions,

-- using the go button

-- 2) Perform like a strcpy software but made in hardware, suspending

-- the MIPS_S processor operation and transfering data already loaded

-- in its internal memory to the processor Data Memory

-- 3) Interact on one side with the user, and on the other side with the

-- MIPS_S processor Sw, to show the copied text

--

-- Last updates:

-- 23/06/2026 - (Ney Calazans)

-- - Initial version of the Peripheral Skeleton

-------------------------------------------------------------------------------



-- Before the Peripheral entity/architecture pair, the multi-module

-- Peripheral Data Memory

library IEEE;

use IEEE.Std_Logic_1164.all;

use IEEE.Numeric_std.all;

-- Remember: do not use IEEE.std_logic_unsigned or IEEE.std_logic_arith,

-- they are deprecated

use work.p_MIPS_S.all;



entity Data_Memory_Per is

    generic( FIRST_D_ADDRESS : wires32:= x"10014000";

    LAST_D_ADDRESS : wires32:= x"10017FFF");

    port( clock: in std_logic;

    ce, rw, bw: in std_logic;

    address: in std_logic_vector(13 downto 0);

    data_in: in wires32;

    data_out: out wires32

    );

end Data_Memory_Per;



architecture Data_Memory_Per of Data_Memory_Per is

    signal ce_mem2, ce_mem3: std_logic;

    signal data_out_mem2, data_out_mem3: wires32;

    begin

    -- The modules ces generation, based on address Most Significant Bit (MSB)

    ce_mem2 <= '1'

    when ce= '1' and address(address'left)='0' else '0';

    ce_mem3 <= '1'

    when ce= '1' and address(address'left)='1' else '0';


    mod2: entity work.data_mem_mod2

    port map (clock=>clock, ce=>ce_mem2, we=>rw, bw=>bw,

    address=>address(12 downto 2),

    byte_choice=>address(1 downto 0),

    data_in=>data_in, data_out=>data_out_mem2

    );



    mod3: entity work.data_mem_mod3

    port map (clock=>clock, ce=>ce_mem3, we=>rw, bw=>bw,

    address=>address(12 downto 2),

    byte_choice=>address(1 downto 0),

    data_in=>data_in, data_out=>data_out_mem3

    );



    -- The Data Memory data output choice, based on the ce signal ce_mem1

    data_out <= data_out_mem3 when ce_mem3='1' else data_out_mem2;



end Data_Memory_Per;



library IEEE;

use IEEE.std_logic_1164.all;

use IEEE.Numeric_std.all;

-- Remember: do not use IEEE.std_logic_unsigned or IEEE.std_logic_arith,

-- they are deprecated

use work.p_MIPS_S.all;



-- Uncomment the following library declaration if instantiating

-- any Xilinx primitives in this code.

--library UNISIM;

--use UNISIM.VComponents.all;



entity Periferico is

generic( FIRST_D_ADDRESS : wires32:= x"10014000";

    LAST_D_ADDRESS : wires32:= x"10017FFF");

    port ( -- Global controls

        clock, reset : in std_logic;

        -- To User

        copy_done : out std_logic;

        -- The mode register bit 1 (B_w) controls if the display

        -- shows data byte by byte or half-word by half-word

        -- The showing ff in '1' enables some or all of the

        -- display light up or not

        B_w_out, Showing_out : out std_logic;

        data_ts : out std_logic_vector (15 downto 0);

        -- From User

        go, next_d, restart, B_w, St_Ed, Hhw_Lhw : in std_logic;

        -- To MIPS_S

        suspend, ce_Per, rw_Per, bw_Per : out std_logic;

        d_address_Per, data_out_Per : out wires32;

        -- From MIPS_S

        suspend_ack, ce_CPU, rw_CPU, bw_CPU : in std_logic;

        d_address_CPU, data_out_CPU, data_out_RAM : in wires32

);

end Periferico;



architecture Periferico of Periferico is

    -- Remember to declare your signals here, e.g. the FSM state type and the

    -- the FSM State register output/input



    signal IDMem_clock, ce_RAM_Per, rw_RAM_Per, bw_RAM_Per : std_logic;

    signal d_address_RAM_Per, data_in_RAM_Per, data_out_RAM_Per : wires32;

    signal source_addr_counter, dest_addr_counter,

    data_out_Per_int : std_logic_vector (31 downto 0);

    -- Usually several other signals will have to be declared, see to it.

    --



    begin

    -- 1) Create the Peripheral FSM below, for example



    -- 2) The Peripheral Data Path goes next, including:

    -- A) the 16-Kbyte Data Memory, furnished in this Skeleton



    -- Signal to drive Local RAM Data Memory

    -- The basic idea is just to invert the clock phase.

    Mem_Clock: IDMem_clock <= not clock;



    -- The Peripheral Data Memory and some required glue logic

    -- 8 BRAMs (128 Kbits, 16 Kbytes) that will contain the Peripheral local data

    inst_DataMem_Per: entity work.Data_Memory_Per

    port map (clock=>IDMem_clock, ce=>ce_RAM_Per, rw=>rw_RAM_Per, bw=>bw_RAM_Per,

    address=>d_address_RAM_Per(13 downto 0),

    data_in=>data_in_RAM_per, data_out=>data_out_RAM_Per

    );


    d_address_Per <= dest_addr_counter;

    d_address_RAM_Per <= source_addr_counter;

    -- Small operation needed to put the byte to write in the least significant position

    data_out_Per_int <=

    to_StdLogicVector(to_bitvector(data_out_RAM_Per)

    ror (to_integer(unsigned(d_address_RAM_Per(1 downto 0))) * 8));



    -- B) The required registers -- see documentation on how many

    -- and the nature of the registers. Also, ensure how these are

    -- readable or writable by the MIPS_S Sw (MMIO)

    --

    -- C) Create anything else that might be necessary, like muxes,

    -- address decoders, etc.

--



end Periferico; 

Excelente