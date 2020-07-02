.text
input1:
	lw	$t0, 0x2000($zero)	#0
	beq	$t0, $zero, input1	#4
	lw	$s1, 0x2004($zero)	#8
input2:
	lw	$t0, 0x2000($zero)	#12
	beq	$t0, $zero, input2	#16
	lw	$s2, 0x2004($zero)	#20
check:
	beq	$s1, $zero, end		#24
	beq	$s2, $zero, s2zero	#28
	j	begin			#32
s2zero:
	add	$s2, $s1, $zero		#36
	j	end			#40
begin:
	slt	$t0, $s1, $s2		#44
	beq	$t0, $zero, mod		#48
switch:
	add	$t1, $s1, $zero		#52
	add	$s1, $s2, $zero		#56
	add	$s2, $t1, $zero		#60
mod:
	sub	$s1, $s1, $s2		#64
	slt	$t0, $s1, $zero		#68
	beq	$t0, $zero, mod		#72
	add	$s1, $s1, $s2		#76
	beq	$s1, $zero, end		#80
	j	switch			#84
end:
output:
	sw	$s2, 0x200c($zero)	#88
	j	input1			#92
