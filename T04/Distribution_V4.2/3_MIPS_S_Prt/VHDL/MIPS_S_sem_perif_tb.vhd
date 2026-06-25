-------------------------------------------------------------------------------
--  Top MIPS_S_withBRAMs Simulation Testbench
--		Last Release: 26/May/2025
--	Authors: 
--		Ney Calazans / Fernando Moraes
--
--  - This TB just instantiates the MIPS_S_withBRAMs subsystem and
--      generates all basic stimuli for it, with no active Peripheral
--
--	26/05/2025 (Ney Calazans)
--		- Comments part has been updated
-------------------------------------------------------------------------------
library ieee;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;          
use work.p_MIPS_S.all;  

entity MIPS_S_withBRAMs_noPer_tb is
end MIPS_S_withBRAMs_noPer_tb;

architecture MIPS_S_withBRAMs_noPer_tb of MIPS_S_withBRAMs_noPer_tb is
  signal clock: std_logic := '1';      	  
  signal reset, sel_CPU: std_logic := '0';      	  
  signal reset_CPU, suspend, ce_Per, rw_Per, bw_Per: std_logic;      	  
  signal suspend_ack, ce_CPU, rw_CPU, bw_CPU: std_logic;      	  
  signal d_address_Per, data_out_Per: wires32;
  signal d_address_CPU, data_out_CPU, data_out_RAM: wires32;
begin

  	top: 
		entity work.MIPS_S_withBRAMs 
			port map (clock=>clock, reset=>reset, sel_CPU=>sel_CPU, 
					reset_CPU=>reset_CPU, suspend=>suspend, 
					ce_Per=>ce_Per, rw_Per=>rw_Per, bw_Per=>bw_Per,
					d_address_Per=>d_address_Per, data_out_Per=>data_out_Per,
					suspend_ack=>suspend_ack, ce_CPU=>ce_CPU, 
					rw_CPU=>rw_CPU, bw_CPU=>bw_CPU,
					d_address_CPU=>d_address_CPU, 
					data_out_CPU=>data_out_CPU,
					data_out_RAM=>data_out_RAM
					);
			
	clock <= not clock after 10 ns;
	reset <= '1', '0' after 22.40 ns;       
    sel_CPU <= '0';  
	
	d_address_Per <= (others=>'0');
	ce_Per <= '0';
	rw_Per <= '0';
	bw_Per <= '0';
	data_out_Per <= (others=>'0');
	suspend <= '0';

end MIPS_S_withBRAMs_noPer_tb;
