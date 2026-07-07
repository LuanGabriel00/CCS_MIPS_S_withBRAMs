.data
dest_text_addr: .word 0x10010000 
   .space 9200 
after_dest:  .word 0 
   .space 7144 
source_text_addr: .word 0x10014000 
   .space 9200 
after_source:  .word 0 

.text
.globl main

main:
    la $a0, source_text_addr  
    la $a1, dest_text_addr    
    jal strcpy

aqui: 
    j aqui 

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
