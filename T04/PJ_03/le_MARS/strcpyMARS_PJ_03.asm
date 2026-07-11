.data
.data
dest_text_addr: .word 0
   .space 9200 

after_dest:  .word 0 
   .space 7176 

source_text_addr: .word 0 
   .space 9200 

after_source:  .word 0 

filename:  .asciiz "/Users/luan/Desktop/PJ_02/le_MARS/RomeoJuliet_Act2-Scene2.txt" 

.text
.globl main

main:
    jal carrega_arquivo

    la $a0, source_text_addr  
    la $a1, dest_text_addr    
    jal strcpy

    # --- TRECHO DE DEBUG: Imprimir o que foi lido na tela ---
    # li $v0, 4                 # Syscall 4: Print String
    # la $a0, source_text_addr  # Endere�o de onde o texto foi salvo (0x10014000)
    # syscall
    # --------------------------------------------------------
aqui: j aqui

carrega_arquivo:
    addu $sp, $sp, -4
    sw   $ra, 0($sp)

    
    la $a0, filename          
    li $a1, 0                 
    li $a2, 0                 
    li $v0, 13
    syscall
    move $s0, $v0             
    
    bltz $s0, fim_carrega

    move $a0, $s0             
    la   $a1, source_text_addr
    li   $a2, 9200            
    li   $v0, 14
    syscall

    move $a0, $s0
    li   $v0, 16
    syscall

fim_carrega:

    lw   $ra, 0($sp)
    addu $sp, $sp, 4
    jr   $ra


strcpy:
loop_strcpy:
    lb   $t0, 0($a0)          
    sb   $t0, 0($a1)          
    
    beq  $t0, $zero, fim_strcpy 
    
    addu $a0, $a0, 1          
    addu $a1, $a1, 1          
    j    loop_strcpy        
    
fim_strcpy:
    jr   $ra 

    
