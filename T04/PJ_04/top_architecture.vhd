library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
-- A biblioteca NUMERIC_STD é a norma oficial (ARITH e UNSIGNED são obsoletas)
use IEEE.NUMERIC_STD.ALL;

-- Renomeamos a entidade para refletir que ela é o TOPO do projeto
entity MIPS_Nexys2_Top is
    generic ( CLOCK_FREQ : integer := 50_000_000 ); -- 50MHz da Nexys 2
    port(
        -- Sinais de Relógio e Reset
        ucf_clock           : IN  STD_LOGIC;
        ucf_reset           : IN  STD_LOGIC;
        
        -- Botões da Placa
        ucf_restart         : IN  STD_LOGIC;
        ucf_next            : IN  STD_LOGIC; -- O nome correto do pino
        ucf_go              : IN  STD_LOGIC;
        
        -- Chaves de Configuração (Switches)
        ucf_SW_St_Ed        : IN  STD_LOGIC;
        ucf_SW_B_W          : IN  STD_LOGIC;
        ucf_SW_Hhw_Lhw      : IN  STD_LOGIC;
        
        -- Led
        ucf_LD_Cp_Ed        : OUT STD_LOGIC;
        
        -- Saídas para os Displays de 7 Segmentos (Faltavam no seu código)
        ucf_dec_ddp         : OUT STD_LOGIC_VECTOR(7 downto 0); -- Segmentos + Ponto
        ucf_an              : OUT STD_LOGIC_VECTOR(3 downto 0)  -- Anodos
    );
end MIPS_Nexys2_Top;

architecture Behavioral of MIPS_Nexys2_Top is
    -- É aqui que você vai declarar os sinais internos e instanciar
    -- o MIPS_S, o Periferico (DMA) e os drivers de Display!
begin

    -- O mapeamento de portas das instâncias acontecerá aqui

end Behavioral;