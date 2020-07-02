.data
num1:	40
num2:	28
gcd:	0

.text
input:
	lw	$s1 num1
	lw	$s2 num2
check:
	beq	$s1, $zero, end
	beq	$s2, $zero, s2zero
	j	begin
s2zero:
	add	$s2, $s1, $zero
	j	end
begin:
	slt	$t0, $s1, $s2
	beq	$t0, $zero, mod
switch:
	add	$t1, $s1, $zero
	add	$s1, $s2, $zero
	add	$s2, $t1, $zero
mod:
	sub	$s1, $s1, $s2
	slt	$t0, $s1, $zero
	beq	$t0, $zero, mod
	add	$s1, $s1, $s2
	beq	$s1, $zero, end
	j	switch
end:
output:
	sw	$s2, gcd
