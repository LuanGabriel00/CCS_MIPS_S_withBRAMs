library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.p_MIPS_S.all; -- Necessário para carregar o tipo wires32 usado pelo MIPS

-- Renomeamos a entidade para refletir que ela é o TOPO do projeto
entity MIPS_Nexys2_Top is
    generic ( CLOCK_FREQ : integer := 50_000_000 ); -- 50MHz da Nexys 2
    port(
        -- Sinais de Relógio e Reset
        ucf_clock           : IN  STD_LOGIC;
        ucf_reset           : IN  STD_LOGIC;
        
        -- Botões da Placa
        ucf_restart         : IN  STD_LOGIC;
        ucf_next            : IN  STD_LOGIC; 
        ucf_go              : IN  STD_LOGIC;
        
        -- Chaves de Configuração (Switches)
        ucf_SW_St_Ed        : IN  STD_LOGIC;
        ucf_SW_B_W          : IN  STD_LOGIC;
        ucf_SW_Hhw_Lhw      : IN  STD_LOGIC;
        
        -- Led
        ucf_LD_Cp_Ed        : OUT STD_LOGIC;
        
        -- Saídas para os Displays de 7 Segmentos 
        ucf_dec_ddp         : OUT STD_LOGIC_VECTOR(7 downto 0); -- Segmentos + Ponto
        ucf_an              : OUT STD_LOGIC_VECTOR(3 downto 0)  -- Anodos
    );
end MIPS_Nexys2_Top;

architecture Behavioral of MIPS_Nexys2_Top is

    -- DECLARAÇÃO DE SINAIS 
    
    -- Fios entre o MIPS e o Periférico
    signal w_suspend, w_suspend_ack, w_ce_Per, w_rw_Per, w_bw_Per : std_logic;
    signal w_ce_CPU, w_rw_CPU, w_bw_CPU : std_logic;
    signal w_d_address_Per, w_data_out_Per : wires32;
    signal w_d_address_CPU, w_data_out_CPU, w_data_out_RAM : wires32;

    -- Fios entre o Periférico e a Placa/Display
    signal w_copy_done   : std_logic;
    signal w_B_w_out     : std_logic;
    signal w_Showing_out : std_logic;
    signal w_data_ts     : std_logic_vector(15 downto 0);
    
    -- Sinais formatados para o Driver de Display (6 bits cada)
    signal digit3, digit2, digit1, digit0 : std_logic_vector(5 downto 0);

begin

    
    --  LÓGICA DE CONEXÃO E FORMATAÇÃO  
    -- Conectando o sinal de "cópia terminada" diretamente ao LED
    ucf_LD_Cp_Ed <= w_copy_done;

    -- Formatação dos dígitos para o Driver do Display
	 digit3 <= w_Showing_out & w_data_ts(15 downto 12) & '1';
    digit2 <= w_Showing_out & w_data_ts(11 downto 8)  & '1';
    digit1 <= w_Showing_out & w_data_ts(7 downto 4)   & '1';
    digit0 <= w_Showing_out & w_data_ts(3 downto 0)   & '1';

    --INSTANCIAMENTO DOS MÓDULOS (Os chips na placa)
    -- O Módulo Principal (Processador + Memórias)
    Inst_MIPS: entity work.MIPS_S_withBRAMs
        port map (
            clock         => ucf_clock,
            reset         => ucf_reset,
				sel_cpu		  => '0',
            
            -- Recebendo os pedidos de acesso do Periférico (DMA)
            suspend       => w_suspend,
            ce_Per        => w_ce_Per,
            rw_Per        => w_rw_Per,
            bw_Per        => w_bw_Per,
            d_address_Per => w_d_address_Per,
            data_out_Per  => w_data_out_Per,
            
            -- Enviando o status da CPU de volta para o Periférico
            suspend_ack   => w_suspend_ack,
            ce_CPU        => w_ce_CPU,
            rw_CPU        => w_rw_CPU,
            bw_CPU        => w_bw_CPU,
            d_address_CPU => w_d_address_CPU,
            data_out_CPU  => w_data_out_CPU,
            data_out_RAM  => w_data_out_RAM
        );

    -- O Controlador e Máquina de Estados
    Inst_Periferico: entity work.Periferico
        port map (
            clock         => ucf_clock,
            reset         => ucf_reset,
            
            -- Sinais de saída
            copy_done     => w_copy_done,
            B_w_out       => w_B_w_out,
            Showing_out   => w_Showing_out,
            data_ts       => w_data_ts,
            
            -- Botões e Switches
            go            => ucf_go,
            next_d        => ucf_next,
            restart       => ucf_restart,
            B_w           => ucf_SW_B_W,
            St_Ed         => ucf_SW_St_Ed,
            Hhw_Lhw       => ucf_SW_Hhw_Lhw,
            
            -- Sinais do barramento de comunicação com o MIPS
            suspend       => w_suspend,
            ce_Per        => w_ce_Per,
            rw_Per        => w_rw_Per,
            bw_Per        => w_bw_Per,
            d_address_Per => w_d_address_Per,
            data_out_Per  => w_data_out_Per,
            
            suspend_ack   => w_suspend_ack,
            ce_CPU        => w_ce_CPU,
            rw_CPU        => w_rw_CPU,
            bw_CPU        => w_bw_CPU,
            d_address_CPU => w_d_address_CPU,
            data_out_CPU  => w_data_out_CPU,
            data_out_RAM  => w_data_out_RAM
        );

    -- O Multiplexador dos Displays de 7 Segmentos
    Inst_Display: entity work.dspl_drv
        port map (
            clock   => ucf_clock,
            reset   => ucf_reset,
            d3      => digit3,
            d2      => digit2,
            d1      => digit1,
            d0      => digit0,
            
            -- Vai direto para os pinos físicos mapeados no arquivo .ucf
            an      => ucf_an,
            dec_ddp => ucf_dec_ddp
        );

end Behavioral;