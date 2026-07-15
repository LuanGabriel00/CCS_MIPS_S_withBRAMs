--------------------------------------------------------------------------
--  Multiplication and Division of Natural numbers 
--		by successive additions and subtractions, respectively
--		Last Release: 26/May/2025
--	Authors: 
--		Ney Calazans / Fernando Moraes
--
--	Multiplier:
--  	Mpland, Mplier		- Multiplicand and Multiplier, with N bits
--  	start, endop 		- Start and end of the multiplication
--  	Product      		- Result, with 2N bits
--
--	Divisor:
--  	Dvdend, Dvsor		- Dividend and Divisor, with N bits
--  	start, endop 		- Start and end of the division
--  	Quot, Remaind		- Results, each with N bits
--
--  05/07/2018 (Ney Calazans)
--		- Initialization of external signals, to avoid they remain 
--			undefined
--  16/06/2020 (Ney Calazans) - Bug fix:
--		- The internal logic of the multiplier and divisor changed to
--			enable reseting them together with the external processor.
--			This required initializing registers RegP and RegB in both
--			modules only when leaving state initialize and not when 
--			entering this state.
--	19/10/2022 (Ney Calazans)
--		- Module names changed to "multiplier" and "divider".
--		- Some signal names changed to English spelling to keep coherency, 
--			especially at the module interfaces.
--	26/05/2025 (Ney Calazans)
--		- Comments part has been updated
--------------------------------------------------------------------------

--------------------------------------------------------------------------
-- Multiplier
--	- This is an implementation of a 32-bit serial multiplier as proposed
--		in Hennessy & Patterson textbook.
--  - The multiplier waits for a 1-clock cycle initialization input 
--		control signal (start), then it computes the multiplication in
--		the next 64 clock cycles, in the last of these generating a
--		1-clock cycle output signal (endop) to indicate the end of the
--		operation, which result is then available at the data output
--		(Product).
--	- Attention: the operation of this module complies with the MIPS
--		processor expected specification for instruction MULTU, assuming 
--		inputs to be Natural numbers.
--------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity multiplier is
	generic(N: integer := 32);
	port(clock, start	: in  std_logic; 
		Mpland			: in  std_logic_vector((N-1) downto 0);
		Mplier			: in  std_logic_vector((N-1) downto 0);
		endop			: out std_logic;
		Product			: out std_logic_vector(2*N-1 downto 0));
end multiplier;

architecture multiplier of multiplier is   
	type State_type is (initialize, shift, add, finish, endm);
	signal EA: State_type;
	signal regP :	std_logic_vector( N*2 downto 0); 
	signal regB :	std_logic_vector( N   downto 0);
	signal count:	integer;

begin
	--
	-- registers regP, regB, product, endop e control counter
	--
	process(start, clock)
	begin
		if (start='0' and EA=initialize) then 
			-- Inicializa-se os registradores na saída do estado
			-- e não na entrada
			regP( N*2 downto N)	<= (others=>'0');
			regP( N-1 downto 0) 	<= Mplier;         
			regB					<= '0' & Mpland;
			count					<= 1;
			endop					<= '0';
			Product 				<= (others=>'0');
		elsif clock'event and clock='1' then
			if EA=add and regP(0)='1' then
				regP(N*2 downto N) <= regP(N*2 downto N) + regB;
			elsif EA=shift then
				regP <= '0' & regP(N*2 downto 1);
				count <= count + 1;
			elsif EA=finish then
				Product	<= regP( N*2-1 downto 0);
				endop	<= '1';
			elsif EA=endm then
				endop <= '0';
			end if;
		end if;       
	end process;

	-------------------------------------------------
	-- State Machine to control the multiplication
	-------------------------------------------------
	process (start, clock)
	begin
		if start='1' then
			EA <= initialize;
		elsif clock'event and clock='1' then  
			case EA is
				when initialize	=>  EA <= add;   
				when add		=>  EA <= shift;
				when shift		=>  if count=N then 
										EA <= finish; 
									else 
										EA <= add;
									end if;             
		-- The finish state serves only to generate a single pulse at endop  
				when finish		=>	EA <= endm;
				when endm		=>	EA <= endm;    
			end case;
		end if;
	end process;

end multiplier;

--------------------------------------------------------------------------
-- Divider
--		- This is an implementation of a 32-bit serial restoring divider,
--			as proposed in Hennessy & Patterson textbook.
--		- The implementation waits for a 1 clock cycle initialization 
--			input control signal (start), then it computes the division
--			in the next 64 clock cycles, in the last of these generating
--			a 1 clock cycle output signal (endop) to indicate the end of
--			the operation, which result is then available at its data 
--			(Quot and Remains) outputs
--	- Attention: the operation of this module complies with the MIPS
--		processor expected specification for instruction DIVU, assuming 
--		inputs to be Natural numbers.
--------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity divider is
	generic(N: integer := 32);
	port(clock,start	: in  std_logic;
		Dvdend	 		: in  std_logic_vector((N-1) downto 0);
		Dvsor			: in  std_logic_vector((N-1) downto 0); 
		endop 			: out std_logic;
		Quot			: out std_logic_vector(N-1 downto 0);
		Remaind			: out std_logic_vector(N-1 downto 0));
end divider;

architecture divider of divider is   
	type State_type is (initialize, shift, addsub, finish, endd);
	signal EA :			State_type;
	signal regP :		std_logic_vector(N*2 downto 0); 
	signal regB :		std_logic_vector(N   downto 0);
	signal difference :	std_logic_vector(N   downto 0);
	signal count:		integer;

begin
	difference <=  regP( N*2 downto N) -  regB( N downto 0);   

	process(start, clock)
	begin    
		if (start='0' and EA=initialize) then
			-- Initialize registers on leaving the state
			-- not on entering it
			regP(N*2 downto N)	<= (others=>'0');
			regP(N-1 downto 0)	<= Dvdend;
			regB				<= '0' & Dvsor;
			count				<= 1;
			endop				<= '0';
			Remaind				<= (others=>'0');
			Quot				<= (others=>'0');
		elsif clock'event and clock='1' then
			if EA=shift then
				regP <= regP(N*2-1 downto 0) & regP(N*2);
			elsif EA=addsub then  
				if difference(N)='1' then  
					regP(0)<='0';
				else
					regP(0)<='1';
					regP(N*2 downto N) <= difference;
				end if;
				count <= count + 1;
			elsif EA=finish then
				Remaind		<= regP(N*2-1 downto N);
				Quot 		<= regP(N-1   downto 0);
				endop		<= '1';
			elsif EA=endd then
					endop <= '0';
			end if;
		end if;
	end process;
	
	-------------------------------------------------
	-- State Machine to control the division
	-------------------------------------------------
	process (start, clock)
		begin
			if start='1'then
				EA <= initialize;
			elsif clock'event and clock='1' then  
				case EA is
					when initialize => EA <= shift; 
					when shift		=> EA <= addsub;
					when addsub		=> if count=N then 
											EA <= finish; 
										else 
											EA <= shift;  
										end if;
			-- State finish serves only to generate a single pulse in endop  
					when finish		=> EA <= endd;
					when endd		=> EA <= endd;
				end case; 
			end if;
	end process;

end divider;
