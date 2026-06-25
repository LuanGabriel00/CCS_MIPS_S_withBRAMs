#------------------------------------------------------------------------------
# MIPS_S programming basic example: Manipulating arrays
# Autor: Ney Calazans (nlvcalazans@gmail.com)
#
# Operation: This code adds the contents of two arrays, V0 and V1
#		and stores the result in a third array, V2. All arrays have
#		11 elements, each considered an integer.
#
#	- When exercising it in hardware with a 50MHz clock, run simulation 
#		for at least 10.3us.
#
# Last changed in: 26/11/2025
#	- A silly error appeared and was corrected, the position of the
#		end label
#	- A small change in the arrays names was done to facilitate the program
#		understanding. Arrays V1, V2 and V3 are now respectively called 
#		V0, V1, V2 and are pointed to by $t0, $t1 and $t2
#------------------------------------------------------------------------------
	.text				# Add what follows to the text segment of the program
	.globl	main		# Declare the label main to be a global one
main:
	la	$t0,V0			# generate pointer to V0 source array
	la	$t1,V1			# generate pointer to V1 source array
	la	$t2,V2			# generate pointer to V2 destination array

	la	$t3,size		# get address of the arrays´ size
	lw	$t3,0($t3)		# register $t1 contains the size of the arrays

loop:
	blez	$t3,end		# if counter is/becomes 0, end of processing
	lw	$t4,0($t0)
	lw	$t5,0($t1)
	addu	$t4,$t4,$t5 
	sw	$t4,0($t2)		# update V2 array element in memory
	addiu	$t0,$t0,4	# advance pointers
	addiu	$t1,$t1,4	
	addiu	$t2,$t2,4	
	addiu	$t3,$t3,-1	# decrement elements to process counter
	j	loop			# execute the loop another time
	
	# at the end, enter an infinite loop
end:
	j	end

	.data
	# V2 is initially an all 0s array
V2:	.word	0x0       0x0  0x0 0x0  0x0   0x0   0x0  0x0  0x0 0x0  0x0 
	# V0 and V1 initially contain each 11 randomly chosen numbers 
V0:	.word	0x1000011 0xff 0x3 0x14 0x878 0x31  0x62 0x10 0x5 0x16 0xAB000002
V1:	.word	0x2000002 0xf4 0x3 0x14 0x878 0x31  0x62 0x10 0x5 0x16 0x21000020

size:	
	.word	11

