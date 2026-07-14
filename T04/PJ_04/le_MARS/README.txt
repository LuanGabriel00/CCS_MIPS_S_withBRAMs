-------------------------------------------------------------------------------
--	Autor: 	Ney Laert Vilar Calazans (nlvcalazans@gmail.com)
--
--	Título:	Material Introdutório para Emprego da Arquitetura do Conjunto de 
--		Instruções MIPS_S 
--			
--	Data de início do documento:	14/02/2025
--	Revisado a última vez em:		16/06/2026

--	Sobre as necessidades da especificação do trabalho - 
--		Processador MIPS_S_withBRAMs
-------------------------------------------------------------------------------

Em 1ro/04/2025, iniciou-se o processo de tornar as especificações do MIPS_S e do MIPS_S_withBRAMs mais genéricas. Os principais focos deste trabalho são (inicialmente):

1) Produzir um sistema computacional adequado para dar suporte ao desenvolvimento de aplicações compostas de Hw+Sw capaz de realizar operações de Entrada e Saída em geral, ainda que de forma simples (com suporte a entrada e saída programada). No momento de iniciar este processo, a versão corrente da MIPS_S_withBRAMs dá suporte apenas a criar periféricos que realizem operações de saída da memória, ressetando o processador para tanto no processo;

2) Traduzir toda a definição dos sistemas computacionais envolvidos (MIPS_S e MIPS_S_withBRAMs) para inglês, desde a definição de identificadores nos códigos-fonte até os comentários e arquivos do tipo README.txt;

3) Preparar uma distribuição da MIPS_S e da MIPS_S_withBRAMs para eventual disponibilização no github, dotada de documentação abundante e de fácil uso.


Em 14/02/2025, constataram-se problemas de implementação que exigiram correção:

1) O software le_mars.c estava gerando código VHDL com erros lógicos para a memória de dados operar corretamente em conjunção com o processador MIPS_S;
	1.1) Todos os 4 bancos de BRAM da memória de dados estavam usando apenas o sinal we3 para ativar escrita, ficando os sinais we2, we1 e we0 não usados. Agora todos os 4 wes são usados de forma correta;
	1.2) Toda escrita a byte (devida à execução de uma instrução SB) era feita sempre no byte menos significativo de um endereço múltiplo de 4. Isto estava errado. A interface da memória de dados foi alterada para receber os 2 bits menos significativos do barramento de endereços do processador. Estes 2 bits são agora usados para selecionar o banco de memória onde escrever o byte (atendendo aos requisitos da instrução SB). Isto foi feito alterando a lógica que computa os write enables de cada banco (we3 a we0) para considerar os bits 1 e 0 do barramento de endereço no cáculo do banco de BRAM onde escrever o byte, quando bw='0' (escrita a byte, ativado ao executar instrução SB no MIPS_S).
	1.3) Vários comentários no le_mars.c e no memory.vhd gerado foram atualizados, ora traduzidos para inglês, ora corrigidos em alguns casos. 

2) 2.1) No módulo MIPS_S_withBRAMs foi modificada a instanciação da memória de dados (D_mem) para acrescentar o novo sinal de interface desta, conectado aos pinos do barramento de endereços relevantes (byte_choice(1 downto 0)=>addressRAM(1 downto 0)).
	2.2) Vários comentários foram atualizados no módulo MIPS_S_withBRAMs, para atualizá-los, corrigi-los ou traduzi-los para inglês.
	
3) Um programa de teste (SBLB_Tests.asm) foi adicionado à distribuição, junto com novos arquivos de configuração de formas de onda mais completos para os dois exemplos. Isto ajuda a testar as instruções SB e LB de forma explícita. O novo programa baseou-se no programa simple_crypto.asm de Ney Calazans. Neste programa, instruções LB (de simple_crypto.asm, inexistentes no MIPS_S) foram trocadas por LBU (que exite no MIPS_S). Várias outras alterações foram feitas para melhorar o processo de teste da interface entre o MIPS_S e a sua memória de dados entrelaçada. 

4) Foi necessário também alterar o processador MIPS_S, para que ele, quando executar instruções LBU, receba corretamente os dados lidos da memória de dados entrelaçada em 4 níveis de BRAMs (1 byte por bloco) e armazene o byte no local correto (LSByte do registrador destino no MIPS_S). Note-se que esta alteração não é necessária (e talvez nem seja estritamente correta, do ponto de vista da especificação do MIPS, isto ainda será investigado...) para a versão simulável do MIPS, uma vez que o endereçamento de memória no testbench usa vetores lineares ordinários e não blocos de memória entrelaçada. 

5) Outro problema foi detectado ao simular o programa de teste SBLB_Tests.asm, que mesmo com as alterações realizadas como descrito nos itens 1) a 4) acima ainda não executou corretamente de forma consistente com a execução do programa no MARS. O problema ocorre porque toda instrução SB deve enviar para a memória o dado a escrever dentro do byte menos significativo do barramento de dados de saída do processador ao executar a instrução SB, e o endereço de escrita define em qual bloco de memória este LSByte deve ser escrito (ver item 1.2 acima). Contudo, na estrutura da memória de dados, cada bloco da memória entrelaçada, quando escrito, o era (na versão anterior) com o byte de uma posição fixa do barramento de dados de entrada da memória (bits 7 a 0 para o bloco mem0, bits 15 a 8 para o bloco mem1, bits 23 a 16 para o bloco mem2 e bits 31 a 24 para o bloco mem0). Isto funciona perfeitamente para a instrução SW, mas não para a instrução SB. Assim, novos sinais internos foram criados para selecionar corretamente o byte data_in(7 downto 0) para entrar no barramento de dados da BRAM escolhida pelo endereço em byte_choice (1 downto 0), ao executar uma instrução SB.

Em 11/11/2025, o software le_mars foi expandido para permitir especificar mais de um módulo de Memória de Dados, por enquanto até um limite de 4 módulos (valor parametrizável alterando o programa) de 8Kbytes.

1) Nos comentários acrescentados como cabeçalhos para cada módulo de Memória de Dados, acrescentou-se o endereço original de memória ocupado pelo módulo.

2) Ainda não é possível ter mais memória para armazenar instruções (além da atual capacidade de criar um módulo com capacidade para armazenar um máximo de 512 instruções do MIPS). Isto é trabalho futuro.

Em 06/06/2026, concluiu-se melhoria da organização do módulo MIPS_S_withBRAMs para permitir que o MIPS_S não apenas leia e escreva de sua Memória de Dados e escreva dados para em periférico, mas que também possa ler dados deste usando E/S mapeada em memória. Isto foi feito acrescentando um multiplexador que gera a entrada de dados do MIPS_S seja a partir da Memória de Dados deste, seja a partir de dados provenientes de um periférico. O controle do multiplexador lê do periférico sempre que o valor do endereço de leitura estiver fora da faixa de endereços da Memória de Dados. Também se alterou o valor básico do tamanho da memória de dados de 8Kbytes (1 módulo de memória entrelaçada de 4 BRAMs) para 16Kbytes (2 módulos de memória entrelaçada de 4 BRAMs cada). A lógica de decodificação foi adapatada, conforme fez-se necessário.

Em 16/06/2026, corrigiu-se um bug de comentáruos no programa le_mars.


