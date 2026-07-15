 
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
# ==============================================================
# LACO 1 - Espera o usuario apertar go pela primeira vez
# ==============================================================
laco1:
    lui  $t0, 0xFFFF            # $t0 = 0xFFFF0000
    lw   $t1, 0($t0)            # $t1 = conteudo de 0xFFFF0000 (go_ff)
    andi $t1, $t1, 0x1          # Isola o bit 0
    beq  $t1, $zero, laco1      # Se 0, go nao apertado, repete

# ==============================================================
# LACO 2 - Espera o periferico terminar a copia do texto
# ==============================================================
laco2:
    lui  $t0, 0xFFFF
    ori  $t0, $t0, 0x0001       # $t0 = 0xFFFF0001 (cp_ed_ff)
    lw   $t1, 0($t0)            # $t1 = conteudo de 0xFFFF0001
    andi $t1, $t1, 0x1          # Isola bit 0 (copia terminou = 1?)
    beq  $t1, $zero, laco2      # Se 0, copia em andamento, repete

# ==============================================================
# LACO 3 - Espera o usuario apertar go de novo e le o modo
# ==============================================================
laco3:
    lui  $t0, 0xFFFF            # $t0 = 0xFFFF0000 (go_ff)
    lw   $t1, 0($t0)            
    andi $t1, $t1, 0x1          
    beq  $t1, $zero, laco3      # Se 0, repete ate apertar go novamente

    # go foi apertado: le o modo de visualizacao
    lui  $t0, 0xFFFF
    ori  $t0, $t0, 0x0002       # $t0 = 0xFFFF0002 (mode_reg)
    lw   $s0, 0($t0)            # $s0 = mode_reg completo
    andi $t5, $s0, 0x1          # $t5 = St_Ed (bit 0): 0 = inicio / 1 = fim
    andi $t6, $s0, 0x2          # $t6 = B_w (bit 1): 0 = byte / 2 = palavra

# ==============================================================
# PREPARACAO DO PONTEIRO (Usado no inicio e no restart)
# ==============================================================
prepara_ponteiro:
    # Inicia o ponteiro na PRIMEIRA letra valida (pulando a var vazia de 4 bytes)
    lui  $s1, 0x1001            
    ori  $s1, $s1, 0x0004       # $s1 = 0x10010004 

    beq  $t5, $zero, laco4      # St_Ed = 0? Ponteiro pronto. Vai pro laco4.

    # St_Ed = 1: comecar do fim do texto
    lui  $t0, 0xFFFF
    ori  $t0, $t0, 0x0004       # $t0 = 0xFFFF0004 (text_size_reg)
    lw   $t7, 0($t0)            # $t7 = tamanho do texto
    andi $t7, $t7, 0x3FFF       # Isola bits 13-0 
    andi $t7, $t7, 0xFFFC       # Alinha para multiplo de 4
    addu $s1, $s1, $t7          # $s1 = base + tamanho (aponta pra FORA do texto)

    # Ajuste: recuar o ponteiro para a ULTIMA posicao valida antes de mostrar
    beq  $t6, $zero, ajusta_byte_fim
    addiu $s1, $s1, -4          # Modo Palavra: recua 4 bytes
    j    laco4
ajusta_byte_fim:
    addiu $s1, $s1, -1          # Modo Byte: recua 1 byte

# ==============================================================
# LACO 4 - Loop de visualizacao no display
# ==============================================================
laco4:
    # --- 1. Le o dado da memoria ---
    beq  $t6, $zero, le_byte    # B_w = 0? le byte
    lw   $t2, 0($s1)            # B_w = 1 (valor 2): le palavra inteira
    j    envia
le_byte:
    lbu  $t2, 0($s1)            # B_w = 0: le 1 byte

envia:
    # --- 2. Envia para o display ---
    lui  $t0, 0xFFFF
    ori  $t0, $t0, 0x0008       # $t0 = 0xFFFF0008 (data_ts_reg)
    sw   $t2, 0($t0)            # escreve o dado

    # --- 3. Seta show_ff = 1 ---
    lui  $t0, 0xFFFF
    ori  $t0, $t0, 0x000C       # $t0 = 0xFFFF000C (show_ff)
    li   $t3, 1
    sw   $t3, 0($t0)            # Liga o display

    # --- 4. Espera apertar next ou restart ---
espera_btn:
    lui  $t0, 0xFFFF
    ori  $t0, $t0, 0x0003       # $t0 = 0xFFFF0003 (nxt_rst_reg)
    lw   $t4, 0($t0)            
    beq  $t4, $zero, espera_btn # Fica travado ate um botao enviar sinal != 0

    # (Laco de debounce removido: confia no hardware!)

    # Apaga show_ff antes de calcular o proximo dado
    lui  $t0, 0xFFFF
    ori  $t0, $t0, 0x000C       # $t0 = 0xFFFF000C (show_ff)
    sw   $zero, 0($t0)          

    # --- 5. Verifica qual botao foi apertado ---
    andi $t3, $t4, 0x1          # Isola bit 0 (restart)
    bne  $t3, $zero, reinicia   # Bit 0 = 1? Vai pro restart

    # Foi NEXT: avanca ou retrocede dependendo da configuracao St_Ed
    bne  $t5, $zero, retrocede  # St_Ed = 1? Modo fim: retrocede

    # Modo inicio: avanca pra frente
    beq  $t6, $zero, avanca_byte
    addiu $s1, $s1, 4           # Modo palavra: soma 4
    j    laco4
avanca_byte:
    addiu $s1, $s1, 1           # Modo byte: soma 1
    j    laco4

retrocede:                      
    # Modo fim: anda de tras pra frente
    beq  $t6, $zero, retro_byte
    addiu $s1, $s1, -4          # Modo palavra: subtrai 4
    j    laco4
retro_byte:
    addiu $s1, $s1, -1          # Modo byte: subtrai 1
    j    laco4

reinicia:
    # --- Foi RESTART ---
    j prepara_ponteiro          # Recalcula do zero usando os mesmos modos
