.data   # Three 11-element arrays (or vectors) and their size
V2: .word 0x0       0x0  0x0 0x0  0x0   0x0   0x0  0x0  0x0 0x0  0x0 
V0: .word 0x1000011 0xff 0x3 0x14 0x878 0x31  0x62 0x10 0x5 0x16 0xAB000002
V1: .word 0x2000002 0xf4 0x3 0x14 0x878 0x31  0x62 0x10 0x5 0x16 0x21000020
size: .word 11
 .text   # Add what follows to the text segment of the program
 .globl main           # Declare the label main to be a global one
main:
 la $t0,V0  # generate pointer to V0 source array (pseudo-inst)
 la $t1,V1  # generate pointer to V1 source array (pseudo-inst)
 la $t2,V2  # generate pointer to V2 destination array (pseudo-inst)
 la $t3,size  # get address of size (pseudo-inst)
 lw $t3,0($t3) # here, register $t3 contains the no. of elements to process
loop:
 blez $t3,end  # if no. of elements to process is/becomes 0, end of processing
 lw $t4,0($t0)
 lw $t5,0($t1)
 addu $t4,$t4,$t5 
 sw $t4,0($t2) # update V2 array element in memory
 addiu $t0,$t0,4  # advance pointers
 addiu $t1,$t1,4 
 addiu $t2,$t2,4 
 addiu $t3,$t3,-1 # decrement no. of elements to process
 j loop  # execute the loop another time
 # now, stop
end: j end
