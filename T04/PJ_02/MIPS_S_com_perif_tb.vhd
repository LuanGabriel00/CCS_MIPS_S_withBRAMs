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

entity conts_tb is
end conts_tb;

architecture conts_tb of conts_tb is
  signal ck, rst, sel_CPU : std_logic :='0';      	  
  signal an: std_logic_vector(7 downto 0);
  signal dec_ddp: std_logic_vector(7 downto 0);
begin
		
	inst_top_conts:
		entity work.top_conts
			port map (ck=>ck, reset=>rst, sel_CPU=>sel_CPU, an=>an, dec_ddp=>dec_ddp);

	sel_CPU <= '0';
	 
	rst <='1', '0' after 120 ns, '1' after 1ms, '0' after 1.000125ms;       -- generates the reset signal 

	ck <= not ck  after 5 ns;
    
end conts_tb;