.data 
    dest_text_addr: .word 0
        .space 8188      # Fill the rest of the first 8KB module (8192 - 4 bytes for .word)
        
    source_text_addr: .word 0 # This will now land exactly at 0x10012000 (start of second module)
        .space 8188      # Fill the second 8KB module
        
    filename: .asciiz "Romeo&Juliet_Act2-Scene2.txt"									# to enable visualizing the end of the data segment window
.text
	.globl	main

main:
	la	$t1, source_text_addr	# $t1 = 0x10012000
	addiu $t1, $t1, 4           # Skip the .word, point to text start
	
	la	$s1, dest_text_addr	    # $s1 = 0x10010000
	addiu $s1, $s1, 4           # Skip the .word, point to text start
	
loop:
	lbu	$t2, 0($t1)		
	beq	$zero, $t2, fim			
	
	sb	$t2, 0($s1)		
	
	addiu	$t1, $t1, 1		
    addiu	$s1, $s1, 1		
	
	j		loop

fim:
	j	fim			
	nop