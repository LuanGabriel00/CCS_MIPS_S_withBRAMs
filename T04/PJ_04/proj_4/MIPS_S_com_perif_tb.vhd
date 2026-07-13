----------------------------------------------------------------------------------
-- Company: UFSC - DEC
-- Engineer: Ney Calazans
-- 
-- Create Date: 28/November/2021
-- Last modified: 28/May/2025
--
-- Design Name: conts_tb
-- Module Name: conts_tb - conts_tb
-- Project Name: A testbench for the memory-mapped peripheral working with
--      MIPS_S_withBRAMs
-- Target Devices: Nexys A7
-- Tool Versions: Vivado 2020.2
-- Description: This is a simple testbench to validate the system formed 
--      by a MIPS_S processor instance, a very simple peripheral, 
--      composed of four 8-bit registers mapped to addresses 
--      0x10008000 - 1008003 of the MIPS_S memory map. The software running
--      on the MIPS_S implements a timer that starts in 000.0 seconds and 
--      ticks at every tenth of second. The peripheral is written with
--      four digits in the range of 0-9, and the register contents are
--      displayed on the seven segment display of the Nexys A7 board.
-- 
----------------------------------------------------------------------------------
library ieee;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;          

entity MIPS_S_com_perif_tb is
end MIPS_S_com_perif_tb;

architecture behavior of MIPS_S_com_perif_tb is

	-- sinais
	signal ucf_clock      : std_logic := '0';
	signal ucf_reset      : std_logic := '1';

	-- Botões e Chaves
	signal ucf_restart    : std_logic := '0';
	signal ucf_next       : std_logic := '0';
	signal ucf_go         : std_logic := '0';
	signal ucf_SW_St_Ed   : std_logic := '0';
	signal ucf_SW_B_W     : std_logic := '0';
	signal ucf_SW_Hhw_Lhw : std_logic := '0';
	
	-- Saídas (Displays e LED)
    signal ucf_LD_Cp_Ed   : std_logic;
    signal ucf_dec_ddp    : std_logic_vector(7 downto 0);
    signal ucf_an         : std_logic_vector(3 downto 0);

    -- Constante do período de Clock (50 MHz = 20 ns)
    constant clock_period : time := 20 ns;
	 
	 begin
		--portmap
		uut: entity work.MIPS_Nexys2_Top
		port map (
			ucf_clock      => ucf_clock,
			ucf_reset      => ucf_reset,
			ucf_restart    => ucf_restart,
			ucf_next       => ucf_next,
			ucf_go         => ucf_go,
			ucf_SW_St_Ed   => ucf_SW_St_Ed,
			ucf_SW_B_W     => ucf_SW_B_W,
			ucf_SW_Hhw_Lhw => ucf_SW_Hhw_Lhw,
			ucf_LD_Cp_Ed   => ucf_LD_Cp_Ed,
			ucf_dec_ddp    => ucf_dec_ddp,
			ucf_an         => ucf_an
		);
		
		--clock
		clk_process :process
    begin
        ucf_clock <= '0';
        wait for clock_period/2;
        ucf_clock <= '1';
        wait for clock_period/2;
    end process;
	 
	 --simulacao
	 stim_proc: process
    begin
        -- Inicia segurando o reset do sistema por um tempinho
        ucf_reset <= '1';
        wait for 100 ns;
        ucf_reset <= '0';

        -- Espera o MIPS rodar a rotina de inicialização dele
        wait for 300 ns;
		  
		  -- APERTA O BOTÃO GO! (Sinal vai para '1', espera um pouco, volta para '0')
        ucf_go <= '1';
        wait for 40 ns;
        ucf_go <= '0';

        -- A partir daqui o Testbench entra em modo de espera infinito.
        -- O seu DMA (Periférico) vai assumir o controle e fazer a cópia.
        wait;
    end process;
end behavior;