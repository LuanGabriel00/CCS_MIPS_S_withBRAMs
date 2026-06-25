#------------------------------------------------------------------------------
# MIPS_S - a program to test LB and SB instructions
# Autor: Ney Calazans (nlvcalazans@gmail.com)
#
# Operation: This code tries to see how LB and SB work, especially for
# 		accesses to bytes at addresses not multiples of 4
# 		The code is based on the simple_crypto.asm program by the same Author
#
# Last changed in: 22/06/2025
#------------------------------------------------------------------------------
		.data
texto:	.asciiz		"Mother loves me!"	# The text to encrypt and then decrypt
key:	.word		0x7A	# The encrypting key
		.space		12		# Align data for easily running it on MARS
cipher:	.space		14		# Space reserved for encrypted text
		.space		18		# Align data for easily running it on MARS
decipher:	
		.asciiz 	""		# The decrypted text starts at this place 

		.text   
		.globl	scrypt            

scrypt:	la		$t0,texto		# Generates a pointer to the plaintext
		la		$t1,cipher		# Generates a pointer to the encrypted text
		la		$t2,key			# 
		lw		$t2,0($t2)		# Obtains the encrypting key
encryp:		
		lbu		$t3,0($t0)		# Reads chr to encrypt (remember, LBU exists in
								# MIPS_S_x but LB does not)
		beq		$t3,$zero,sdec	# Tests if reached the end of the plaintext
		xor		$t3,$t3,$t2		# Encrypt char
		sb		$t3,0($t1)		# Write as a ciphered char
		addiu	$t0,$t0,1		# Increments pointer to plaintext
		addiu	$t1,$t1,1		# Increments pointer to encrypted text
		j		encryp

sdec:	sb		$t3,0($t1)		# Writes end of text char in the ciphered text
#		This concludes the encrypting process. Let us go to decrypting
		la		$t0,cipher		# Generates a pointer to the ciphered text
		la		$t1,decipher	# Generates a pointer to the deciphered text
		la		$t2,key			# 
		lw		$t2,0($t2)		# Obtains the decrypting key
decryp:	lbu		$t3,0($t0)		# Reads encrypted char
		beq		$t3,$zero,fdec	# Tests if reached the end of the ciphered text
		xor		$t3,$t3,$t2		# Decrypt char
		sb		$t3,0($t1)		# Writes it as deciphered text
		addiu	$t0,$t0,1		# Increments pointer to encrypted text
		addiu	$t1,$t1,1		# Increments pointer to plaintext
		j		decryp

fdec:	sb		$t3,0($t1)		# writes end of text char in the deciphered text
# Uncomment the line below for Hw simulation on MIPS_S_x
end:	j	end			
	
# Uncomment all lines below for MARS simulation 
#end:	li		$v0,4			# Service code to print a string
#		la		$a0,cipher		# Puts pointer to ciphered text in $a0
#		syscall					# and prints it
#		li		$v0,4			# Service code to print a string
#		la		$a0,decipher	# Puts pointer to plaintext in $a0
#		syscall					# and prints it
#		li		$v0,10
#		syscall					# ends the program
		

