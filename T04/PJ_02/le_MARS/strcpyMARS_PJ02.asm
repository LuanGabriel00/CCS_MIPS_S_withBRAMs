.data
.data
dest_text_addr: .word 0
   .space 9200 # This completes the reserved quasi-9Kbytes space for the source string

after_dest:  .word 0 # After the string end, put a label, to enable visualizing the end of the data segment window
   .space 7176 # jump to align to address 0x10014000

source_text_addr: .word 0 # After the string end, put a label, to enable visualizing the end of the data segment window
   .space 9200 # This completes the reserved quasi-9Kbytes for the destination string

after_source:  .word 0 # After the string end, put a label, to enable visualizing the end of the data segment window

filename:  .asciiz "/Users/luan/Desktop/PJ_02/le_MARS/RomeoJuliet_Act2-Scene2.txt" # filename at the end, to facilitate

.text
.globl main

main:
    # 1. Chama a sub-rotina para carregar o arquivo na memoria 
    jal carrega_arquivo

    # 2. Prepara argumentos para a funcao strcpy
    la $a0, source_text_addr  # $a0 = Ponteiro da Fonte (Garante o endere�o 0x10014000)
    la $a1, dest_text_addr    # $a1 = Ponteiro do Destino (Garante o endere�o 0x10010000)
    jal strcpy

    # --- TRECHO DE DEBUG: Imprimir o que foi lido na tela ---
    # li $v0, 4                 # Syscall 4: Print String
    # la $a0, source_text_addr  # Endere�o de onde o texto foi salvo (0x10014000)
    # syscall
    # --------------------------------------------------------

    # 3. Fim da execu��o (Projeto 2)
    # Nota: No Projeto 3, isso dever� ser trocado por um "j aqui" (loop eterno).
    li $v0, 10
    syscall

# =========================================================
# SUB-ROTINA: carrega_arquivo
# =========================================================
carrega_arquivo:
    # Salva o endere�o de retorno na pilha
    addu $sp, $sp, -4
    sw   $ra, 0($sp)

    # Syscall 13: Abrir arquivo
    la $a0, filename          # Endere�o da string com o nome do arquivo
    li $a1, 0                 # Flag 0 = Somente leitura
    li $a2, 0                 # Mode (ignorado no MARS)
    li $v0, 13
    syscall
    move $s0, $v0             # Salva o File Descriptor em $s0

    # Evita ler se o arquivo n�o existir (File Descriptor < 0)
    bltz $s0, fim_carrega

    # Syscall 14: Ler do arquivo
    move $a0, $s0             # Argumento 1: File Descriptor
    la   $a1, source_text_addr# Argumento 2: Endere�o do buffer (0x10014000)
    li   $a2, 9200            # Argumento 3: Tamanho m�ximo a ser lido
    li   $v0, 14
    syscall

    # Syscall 16: Fechar arquivo
    move $a0, $s0
    li   $v0, 16
    syscall

fim_carrega:
    # Restaura o endere�o de retorno e volta para a main
    lw   $ra, 0($sp)
    addu $sp, $sp, 4
    jr   $ra

# =========================================================
# SUB-ROTINA: strcpy
# =========================================================
strcpy:
loop_strcpy:
    lb   $t0, 0($a0)          # L� 1 byte do endere�o Fonte
    sb   $t0, 0($a1)          # Escreve esse byte no endere�o Destino
    
    beq  $t0, $zero, fim_strcpy # Verifica fim da string (NULL / 0x00)
    
    addu $a0, $a0, 1          # Incrementa ponteiro da Fonte
    addu $a1, $a1, 1          # Incrementa ponteiro do Destino
    j    loop_strcpy          # Repete
    
fim_strcpy:
    jr   $ra 

    
