#------------------------------------------------------------------------------
# MIPS_S - a program to test the MULTU and the DIVU instructions
# Autor: Ney Calazans (nlvcalazans@gmail.com)
#
# Operation: This is a very simple code that reads two natural numbers stored
#		in memory positions M1 and M2 and perform a multiplication M1*M2 and
#		a division M1/M2. The results are stored in Hi&Lo for the 
#		multiplication, and then are brought to $s0 (the Hi part of the result)
#		and to $s1 (The Lo part of the result). Then, the division is 
#		executed, and again, results are stored in Hi (the remainder) and in
#		Lo (the quotient). Finally, the remainder is copied to $s2 and the
#		quotient to $s3.
#
# Last changed in: 22/06/2025
#------------------------------------------------------------------------------
		.text                   
		.globl	main            
main:	la			$t0,M1
		lw			$t0,0($t0)

		la			$t1,M2       
		lw			$t1,0($t1)  

		multu		$t0,$t1 
		mfhi		$s0				# Result is Hi=0x00000001 Lo=ox41EFF6DE
		mflo		$s1

		divu		$t0,$t1  
		mfhi 		$s2  			# Result is Hi(remainder)=0x0000123F Lo(quotient)=0x0000001D 
		mflo		$s3

# Uncomment the line below for Hw simulation on MIPS_S_x
end:	j	end			
	
# Uncomment all lines below for MARS simulation 
#end:	li			$v0,10
#		syscall					# ends the program

		.data                   
M1:		.word		0x61322 
M2:		.word		0x34ff 
                               
 
