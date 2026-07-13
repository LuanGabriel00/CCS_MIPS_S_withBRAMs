--
--  File: dspl_drv_NexysA7.vhd
--  created by Ney Calazans 15/06/2021 16:20:00
--

--
-- This module implements the interface hardware needed to drive some 
-- Digilent boards 8-digit seven segment displays. This 
-- display is multiplexed (see the specific board Reference Manual for details)
-- requiring that just one digit be displayed at any moment.
-- Example board for which this design is useful is the Nexys A7
-- 
-- The inputs of the module are:
--		clock - the 100MHz system board clock
--		reset - the active-high system reset signal
--    di vectors - 8 vectors, each with 6 bits, where each vector is:
--		di(0) is the decimal point (active-low)
--		di(4 downto 1) is the binary value of the digit
--		di(5) is the (active-high) enable signal of the digit
--      here, i varies from 4 to 1 (8 to 5), 4(8) corresponds to the rightmost
--		  digit of the display and 1(5) corresponds to the leftmost digit
-- 
-- The outputs of the module are:
--		an (8 downto 1) - the 8-wire active-low anode vector.
-- 			In this circuit, exactly one of these 8 wires is at logic 0
--			at any moment. The wire in 0 lights up one of the 4 7-segment
--			displays. 8 is the rightmost display while 1 is the leftmost.
--		dec_ddp (7 downto 0) - is the decoded value of the digit to show
--			at the current instant. dec_ddp(7 downto 1)  corresponds
--			respectively to the segments a b c d e f g, and dec_ddp(0) is
--			the decimal point of that display.
--
-- Functional description: The 100MHz is divided to obtain the
--		1KHz display refresh clock. Upon reset all displays are turned
--		off. The 1KHz clock feeds a 3-bit counter. This counter
--		generates a signal to select one of the eight di vectors. This
--		vector is in turn used to enable or not to show the digit in
--		question (through di(5)) and furnishes the digit value for the
--		single multiplexed 7-segment decoder. All outputs are registered
--		using the 1KHz clock.
--
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity dspl_drv_8dig is
    generic (HALF_MS_COUNT : integer :=50000);
	port (
		clock: in STD_LOGIC;
		reset: in STD_LOGIC;
		d8: in STD_LOGIC_VECTOR (5 downto 0);
		d7: in STD_LOGIC_VECTOR (5 downto 0);
		d6: in STD_LOGIC_VECTOR (5 downto 0);
		d5: in STD_LOGIC_VECTOR (5 downto 0);
		d4: in STD_LOGIC_VECTOR (5 downto 0);
		d3: in STD_LOGIC_VECTOR (5 downto 0);
		d2: in STD_LOGIC_VECTOR (5 downto 0);
		d1: in STD_LOGIC_VECTOR (5 downto 0);
		an: out STD_LOGIC_VECTOR (7 downto 0);
		dec_ddp: out STD_LOGIC_VECTOR (7 downto 0)
	);
end dspl_drv_8dig;

--}} End of automatically maintained section

architecture dspl_drv_8dig of dspl_drv_8dig is
signal ck_1KHz: std_logic;
signal dig_selection: std_logic_vector (2 downto 0);
signal selected_dig: std_logic_vector (4 downto 0);

begin
	-- 1KHz clock generation
	process (reset, clock)
	variable count_50K: integer range 0 to HALF_MS_COUNT; -- change HALF_MS_COUNT to 5 for simulation 
	begin
		if reset='1' then
			count_50K := 0;
			ck_1KHz <= '0';
		elsif (clock'event and clock='1') then
			count_50K := count_50K + 1;
			if (count_50K = 49999) then
				count_50K := 0;
				ck_1KHz <= not ck_1KHz;
			end if;
		end if;
	end process;
	
	-- 1KHz counter to select digit and register output
	process (reset, ck_1KHz)
	begin
		if reset='1' then
			dig_selection <= (others => '0'); 
			an <= (others => '1'); 					-- Disable all displays
		elsif (ck_1KHz'event and ck_1KHz='1') then
			-- a 3-bit binary counter
			if dig_selection="111" then
			     dig_selection <= (others => '0');
			else dig_selection <= dig_selection+1;
			end if;
			
			if dig_selection="000" then
			    selected_dig <= d1(4 downto 0);
			    an <= "1111111"  & (not d1(5));
			elsif dig_selection="001" then
			    selected_dig <= d2(4 downto 0);
			    an <= "111111" & (not d2(5)) & "1";
			elsif dig_selection="010" then
			    selected_dig <= d3(4 downto 0);
			    an <= "11111"  & (not d3(5)) & "11";
			elsif dig_selection="011" then
			    selected_dig <= d4(4 downto 0);
			    an <= "1111"  & (not d4(5)) & "111";
			elsif dig_selection="100" then
			    selected_dig <= d5(4 downto 0);
			    an <= "111"  & (not d5(5)) & "1111";
			elsif dig_selection="101" then
			    selected_dig <= d6(4 downto 0);
			    an <= "11"  & (not d6(5)) & "11111";
			elsif dig_selection="110" then
			    selected_dig <= d7(4 downto 0);
			    an <= "1"  & (not d7(5)) & "111111";
			else
			    selected_dig <= d8(4 downto 0);
			    an <= (not d8(5)) & "1111111";
			end if;
		end if; 
	end process;
	
	-- digit 4-to-hex decoder
	with selected_dig (4 downto 1) select
	dec_ddp(7 downto 1) <=
		"0000001" when "0000", --0
		"1001111" when "0001", --1
		"0010010" when "0010", --2
		"0000110" when "0011", --3
		"1001100" when "0100", --4
		"0100100" when "0101", --5
		"0100000" when "0110", --6
		"0001111" when "0111", --7
		"0000000" when "1000", --8
		"0000100" when "1001", --9
		"0001000" when "1010", --A
		"1100000" when "1011", --b
		"0110001" when "1100", --C
		"1000010" when "1101", --d
		"0110000" when "1110", --E
		"0111000" when others; --F
	-- and the decimal point
	dec_ddp(0) <= selected_dig(0);
											  
end dspl_drv_8dig;
