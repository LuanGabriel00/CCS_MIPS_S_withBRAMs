#------------------------------------------------------------------------------
# MIPS_S - a program to test all instructions in this architecture
# Autor: Ney Calazans (nlvcalazans@gmail.com)
#
# Operation: This test is exhaustive asto the architecture intruction total, 
#	but not necessarily covers all possible test cases for each instruction.
#
# To simulate this program in the MIPS_S_x (x=Sim or x=Prt) Hw 
#	execute for 13,76 microseconds (assuming a 50MHz clock) or
# 	execute for 15,86 microseconds (assuming the same clock but when using
#									a TB that tests the suspend MIPS_S_x pins)
#
# Last changed in: 22/06/2025
#------------------------------------------------------------------------------
		.text			# Declares the start of the code or text segment
		.globl	main	# Declares that the main label is the global entry point
#------------------------------------------------------------------------------
# First, individual instruction tests
#------------------------------------------------------------------------------
main:	
	lui		$t0,0xf3		#
	ori		$t0,$t0,0x23	# $t0<= 0x00f30023
	lui		$t1,0x52		#
	ori		$t1,$t1,0xe2	# $t1<= 0x005200e2
	lui		$t2,0x00		#
	ori		$t2,$t2,0x8f	# $t2<= 0x0000008f
	beq		$t1,$t2,loop	# This instruction must never jump
	bne		$t1,$t2,next_i	# This instruction must always jump
	addiu	$t2,$t2,0x8f	# This instruction must never execute
next_i:	
	addu	$t3,$t0,$t1		# $t3<= 0x00f30023 + 0x005200e2 = 0x01450105
	subu	$t4,$t0,$t1		# $t4<= 0x00f30023 - 0x005200e2 = 0x00a0ff41
	subu	$t5,$t1,$t1		# $t5<= 0x0
	and		$t6,$t0,$t1		# $t6<= 0x00f30023 and 0x005200e2 = 0x00520022
	or		$t7,$t0,$t1		# $t7<= 0x00f30023 or  0x005200e2 = 0x00f300e3
	xor		$t8,$t0,$t1		# $t8<= 0x00f30023 xor 0x005200e2 = 0x00a100c1
	nor		$t9,$t0,$t1		# $t9<= 0x00f30023 nor 0x005200e2 = 0xff0cff1c
	multu	$t0,$t1			# Hi&Lo<=0x00f30023*0x005200e2=0x00004dd6e1bc1ee6
	mfhi	$s0				# $s0<= 0x00004dd6
	mflo	$s1				# $s1<= 0xe1bc1ee6
	divu	$t0,$t1			
				# Hi,Lo<=0x00f30023/0x005200e2=0x4efe5f(mod),0x00000002(/)
	addiu	$t0,$t0,0x00ab	# $t0<= 0x00f30023  +  0x000000ab = 0x00f300ce
	andi	$t0,$t0,0x00ab	# $t0<= 0x00f300ce and 0x000000ab = 0x0000008a
	xori	$t0,$t0,0xffab	# $t0<= 0x0000008a xor 0x0000ffab = 0x0000ff21
	sll		$t0,$t0,4		# $t0<= 0x000ff210 (shifts 4 bits to the left)
	srl		$t0,$t0,9		# $t0<= 0x000007f9 (shifts 9 bits to the right)
	addiu	$s2,$zero,8		# $s2<= 0x00000008
	sllv	$t0,$t0,$s2		
			# $t0<= 0x0007f900 - shifts $t0 8 bits to the left, inserting 0s
	sllv	$t0,$t0,$s2		
			# $t0<= 0x07f90000 - shifts $t0 8 bits to the left, inserting 0s
	sllv	$t0,$t0,$s2		
			# $t0<= 0xf9000000 - shifts $t0 8 bits to the left, inserting 0s
	sra		$t0,$t0,4		
			# $t0<= 0xff900000 - shifts $t0 4 bits to the right, keeping sign
	srav	$t0,$t0,$s2		
			# $t0<= 0xffff9000 - shifts $t0 8 bits to the right, keeping sign
	srlv	$t0,$t0,$s2		
			# $t0<= 0x00ffff90 - shifts $t0 8 bits to the right, inserting 0s
	la		$t0,array		
			# outs in $t0 the array start vector address (0x10010000)
	lbu		$t1,6($t0)		
			# $t1<= 0x000000ef - LSB of $t1 is 3rd byte (from right) 
			# of array 2nd element
	xori	$t1,$t1,0xff	# $t1<= 0x00000010, invert the LSB of $t1
	sb		$t1,6($t0)		
			# 2nd byte of array's 2nd element <= 0x10 over previous value 0xEF
			# BEWARE, an element of array to be processed by soma_ct changed
	addiu	$t0,$zero,0x1	# $t0<= 0x00000001
	subu	$t0,$zero,$t0	# $t0<= 0xffffffff
	bgez	$t0,loop		
				# This instruction must never jump, since here $t0 = -1
	slt		$t3,$t0,$t1		# $t3<= 0x00000001, since as integers -1 < 10
	sltu	$t3,$t0,$t1		# $t3<= 0x00000000, since as naturals (2^32)-1 > 10
	slti	$t3,$t0,0x1		# $t3<= 0x00000001, since as integers -1 < 1
	sltiu	$t3,$t0,0x1		# $t3<= 0x00000000, since as naturals (2^32)-1 > 1
#------------------------------------------------------------------------------
# Add a constant (const) to a every element of a vector (array)
#------------------------------------------------------------------------------
soma_ct:	
	la		$t0,array	# puts in $t0 the vector address (0x10010000)
	la		$t1,size	# puts in $t1 the address of the vector size 0x10010020
	lw		$t1,0($t1)	# puts in $t1 the vector size (0x8)
	la		$t2,const	# puts in $t2 the address of the constant (0x10010024)
	lw		$t2,0($t2)	# puts in $t2 the constant (0xFFFFFFFF) (integer -1)
loop:	
	blez	$t1,end_add	# if/when $t2 becomes 0, end of processing
	lw		$t3,0($t0)	# puts in $t3 the next vector element
	addu	$t3,$t3,$t2	# adds constant to element and puts it back in $t3
	sw		$t3,0($t0)	# updates the value of the element in the vector
	addiu	$t0,$t0,4	# updates the vector pointer. 
				# Remember 1 word = 4 memory addresses
	addiu	$t1,$t1,-1	# decrements number of elements to treat in vector
	j		loop		# proceed with execution
#------------------------------------------------------------------------------
# Nested subroutine call test
#------------------------------------------------------------------------------
end_add:	
	li		$sp,0x10012000	# To enable Hw simulation, initialize $sp with an 
				# adequate value. Here, assumption is that the data memory is
				# an 8Kbytes long RAM, and $sp is made to point to the first
				# memory position after the RAM end.
	addiu	$sp,$sp,-4	# After $sp is initialized, alocate 4bytes in stack
	sw		$ra,0($sp)	# saves return address from whom called this program
				# (should be the SO, if/when it exists) (0x00000000)
	jal		sum_tst		# jumps to the sum_tst subroutine
	lw		$ra,0($sp)	# after returning from sum_tst, retrieves the return
				# address from the stack to the $ra register, (0x00000000)
	addiu	$sp,$sp,4	# destroys stack previously alocated using $sp
end:jr		$ra	# THIS PROGRAM ENDS HERE. Go back to the "SO" ( at 0x00000000)
#------------------------------------------------------------------------------
# Start of non-leaf subroutine: sum_tst
#------------------------------------------------------------------------------
sum_tst:
	la		$t0,var_a	# takes address of a first variable (0x10010028)
	lw		$t0,0($t0)	# takes value of var_a and puts it in $t0 (0x000000FF)
	la		$t1,var_b	# takes address of a second variable (0x1001002C)
	lw		$t1,0($t1)	# takes value of var_b and puts it in $t1 0x00000100
	addu	$t2,$t1,$t0	# $t2 <= var_a + var_b (0x000001FF)
	addiu	$sp,$sp,-8	# alocate 8-byte stack space. $sp goes to 0x100107F4
	sw		$ra,4($sp)	# puts the return address in the stack (0x00400100)
	sw		$t2,0($sp)	# puts the sum result in the stack top (0X000001FF)
	la		$t3,ver_ev	# takes address of ver_ev subroutine (0x0040014C)
	jalr	$ra,$t3		# calls ver_ev subroutina which tests if sum is even
	lw		$ra,4($sp)	# on return, retrieve return address (0x00400100)
	addiu	$sp,$sp,8	# destroys un-needed alocated stack (0x100107FC)
	jr		$ra			# subroutine ends HERE. Return to caller (0x00400100)
#------------------------------------------------------------------------------
# Start of the leaf subroutine: ver_ev. Stack is only read here, not written.
#------------------------------------------------------------------------------
ver_ev:	
	lw		$t3,0($sp)	# takes data from top of the stack (parameter) 
				# (0x000001FF), and puts it in $t3
	andi	$t3,$t3,1	# $t3 <= 1 if parameter odd, 0 otherwise (0x00000001)
	jr		$ra			# and returns to 0x00400140
#------------------------------------------------------------------------------
		.data	# Static data memory
#------------------------------------------------------------------------------
# data for sum_ct loop test
array:		.word	0xABCDEF03 0xCDEFAB18 0xEFABCD35 0xBADCFEAB 0xDCFEBACD 
			.word	0xFEBADC77 0xDEFABC53 0xCBAFED45
				# 3rd byte of the second word (0xEF) will become 0x10 before
				# executing code after soma_ct label
size:		.word	0x8
const:		.word	0xffffffff	# constant -1 in 2's complement
# data for nested subroutine call test
var_a:		.word	0xff		#
var_b:	.	word	0x100		#
