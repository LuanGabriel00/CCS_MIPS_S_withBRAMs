 
# Segmento de Dados (Copiado exatamente do enunciado)
.data
MIPS_S_text_start: .word 0
.space 9200                 # This completes the reserved quasi-9Kbytes space for the destination string
after_dest: .word 0         # After the string end, put a label
.space 7144                 # jump to align close to address 0x10014000

# MMIO Addresses
go_ff_addr: .word 0xFFFF0000           # Address where to read the go ff store (bit 0)
cp_finished_ff_addr: .word 0xFFFF0001  # Address where to read the copy finished ff store (bit 0)
mode_reg: .word 0xFFFF0002             # Address where to read the mode (bits 1-0)
nxt_rst_reg: .word 0xFFFF0003          # Address of peripheral register containing info about nxt_rst
text_size_reg: .word 0xFFFF0004        # Address where to read the text size (14 bits 13-0)
data_ts_reg_addr: .word 0xFFFF0008     # Address where to write value of the text data (32 bits)
show_ff_addr: .word 0xFFFF000C         # Address where to write value of the show ff store (bit 0)

adjust_line: .word 0                   # Unused data to align the start of the text

source_text_addr: .word 0              # Here starts the 2nd half the memory (second 16Kbytes chunk)
.space 9200                 # This completes the reserved quasi-9Kbytes for the source string
after_source: .word 0       # After the string end, put a label


 
# Segmento de Texto (A Lógica dos Laços)
.text
.globl main

main:
    # Prepara os ponteiros para os registradores na memória
    li $s0, 0xFFFF0000         # Endereço do botão 'go'
    li $s1, 0xFFFF0001         # Endereço da flag Cp_Ed (Cópia finalizada)
    li $s2, 0xFFFF0002         # Endereço do Mode
    li $s3, 0xFFFF0003         # Endereço dos botões next/restart
    li $s4, 0xFFFF0004         # Endereço do tamanho do texto
    li $s5, 0xFFFF0008         # Endereço do dado do display
    li $s6, 0xFFFF000C         # Endereço da flag Show

# LAÇO 1: Aguarda o primeiro aperto do botão 'go'
Laco1:
    lw $t0, 0($s0)          # Lê o status do botão 'go'
    beq $t0, $zero, Laco1   # Se for 0, continua esperando no Laço 1

# LAÇO 2: Aguarda o término da cópia pelo Periférico
# O Periférico vai suspender a CPU durante este laço.
Laco2:
    lw $t1, 0($s1)          # Lê a flag Cp_Ed (Cópia finalizada)
    beq $t1, $zero, Laco2   # Se for 0, a cópia não acabou, continua esperando

# LAÇO 3: Aguarda o segundo aperto do botão 'go' e lê o Mode
Laco3:
    lw $t0, 0($s0)          # Lê o status do botão 'go' novamente
    beq $t0, $zero, Laco3   # Se for 0, continua esperando o usuário apertar go
    
    lw $t2, 0($s2)          # Quando 'go' for apertado, lê o valor de 'Mode'

# PREPARAÇÃO PARA O DISPLAY
    # Ativa a flag 'Show' para habilitar o display
    li $t7, 1
    sw $t7, 0($s6)

    # Exemplo simples: Envia um caractere teste (ex: 'A' = 0x41) para o display
    # (A lógica completa de buscar o texto copiado ficará para a próxima etapa)
    li $t6, 0x41
    sw $t6, 0($s5)

# LAÇO 4: Controle de Visualização (next / restart)
Laco4:
    lw $t3, 0($s3)          # Lê os botões next/restart
    # Aqui entrará a lógica de navegação pelo texto.
    # Por enquanto, mantemos a CPU presa aqui para estabilizar a simulação.
    j Laco4
