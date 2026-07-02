.data
# A estrutura que você definiu:
dest_text_addr: .word 0x10010000    # Início da área de destino
   .space 9200
after_dest:  .word 0 
   .space 7144 
filename:  .asciiz "Romeo&Juliet_Act2-Scene2.txt"
source_text_addr: .word 0x10014000  # Início da área de fonte
   .space 9200 
after_source:  .word 0 

.text
.globl main

main:
    # Carrega o endereço base da área de destino e fonte
    la $t1, dest_text_addr    # $t1 recebe o endereço de dest_text_addr
    lw $t1, 0($t1)            # $t1 agora tem o valor 0x10010000
    
    la $t0, source_text_addr  # $t0 recebe o endereço de source_text_addr
    lw $t0, 0($t0)            # $t0 agora tem o valor 0x10014000

# Loop de cópia (estilo strcpy)
loop:
    lb   $t2, 0($t0)          # Carrega 1 byte da fonte
    sb   $t2, 0($t1)          # Salva 1 byte no destino
    
    beq  $t2, $zero, fim      # Se o byte for NULL (0), termina a cópia
    
    addi $t0, $t0, 1          # Incrementa ponteiro da fonte
    addi $t1, $t1, 1          # Incrementa ponteiro do destino
    j    loop                 # Volta para o próximo byte

fim:
    li   $v0, 10              # Syscall para encerrar programa
    syscall