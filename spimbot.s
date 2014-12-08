.data

# movement memory-mapped I/O
VELOCITY             = 0xffff0010
ANGLE                = 0xffff0014
ANGLE_CONTROL        = 0xffff0018

# coordinates memory-mapped I/O
BOT_X                = 0xffff0020
BOT_Y                = 0xffff0024

# planet memory-mapped I/O
LANDING_REQUEST      = 0xffff0050
TAKEOFF_REQUEST      = 0xffff0054
PLANETS_REQUEST      = 0xffff0058

# puzzle memory-mapped I/O
PUZZLE_REQUEST       = 0xffff005c
SOLVE_REQUEST        = 0xffff0064

# debugging memory-mapped I/O
PRINT_INT            = 0xffff0080

# interrupt constants
DELIVERY_MASK        = 0x800
DELIVERY_ACKNOWLEDGE = 0xffff0068

# Zuniverse constants
NUM_PLANETS = 5

# planet_info struct offsets
orbital_radius = 0
planet_radius = 4
planet_x = 8
planet_y = 12
favor = 16
enemy_favor = 20
planet_info_size = 24

# puzzle node struct offsets
str = 0
solution = 8
next = 12


# What am I doing
		.align 2
planet_array: 	.space 120
puzzle_loaded:	.space 4
puzzle0_node:	.space 8192
puzzle1_node:	.space 8192

#for arctan
three:	.float	3.0
five:	.float	5.0
PI:	.float	3.141592
F180:	.float  180.0

.text

main:
	# your code goes here
	# you'll need to copy-paste the puzzle solving functions from Lab 7
	# for the interrupt-related portions, you'll want to
	# refer closely to example.s - it's probably easiest
	# to copy-paste the relevant portions and then modify them
	# keep in mind that example.s has bugs, as discussed in section
		# your code goes here		# t0 = I/O
					# t1 = target planet
					# t2 = target x ( = 150)
					# t3 = target y ( 150 + radius)
					# t4 = bot x
					# t5 = bot y
					# t8 = planet_array
					# t9 = temp
					# a3



					# enable interrupts
	li	$t4, DELIVERY_MASK	# deliv interrupt bit
	or	$t4, $t4, 1		# global interrupt enable
	mtc0	$t4, $12		# set interrupt mask (Status register)
	
	
	li	$t9, 10
	sw	$t9, VELOCITY
	
	sub	$sp, $sp, 4
	sw	$ra, 0($sp)	
	li	$a3, 2
	li	$a0, 4
	jal	beat_opponent 
	li	$a0, 4
	jal	beat_opponent 
	li	$a0, 3
	jal	go_to_planet_x
	li	$a0, 3
	jal	beat_opponent 
	li	$a0, 3
	jal	beat_opponent 
woot_loop:
	move 	$a0, $a3
	jal	go_to_planet_x
	move 	$a0, $a3
	jal	beat_opponent 
	sub	$a3, $a3, 1
	bge	$a3, $0, woot_loop
	li	$a3, 2
	j	woot_loop
	
	lw	$ra, 0($sp)
	add	$sp, $sp, 4
	jr	$ra
	
.globl	go_to_planet_x
go_to_planet_x:
	sub 	$sp, $sp, 28 
	sw 	$ra, 0($sp)
	sw 	$a0, 4($sp)
	sw 	$s0, 8($sp)
	sw 	$s1, 12($sp)
	sw 	$s2, 16($sp)
	sw 	$s3, 20($sp)
	sw 	$s4, 24($sp)

	sw 	$zero, TAKEOFF_REQUEST
	li 	$t0, 10
	sw 	$t0, VELOCITY
fly:
	lw 	$s0, BOT_X			#bots x
	lw 	$s1, BOT_Y			#bots y
	
	sw 	$a0, 4($sp)
	la	$t8, planet_array		#update planet stuff
	sw	$t8, PLANETS_REQUEST($0)
	mul 	$a0, $a0, 24
	add	$a0, $a0, $t8
	lw 	$s2, planet_x($a0)		#planets x
	lw 	$s3, planet_y($a0)		#planets y
	sub 	$t0, $s2, $s0			#diff x
	sub 	$t1, $s3, $s1			#diff y
	
	ble 	$t0, $zero, turn_more	
	move 	$a0, $t0
	move 	$a1, $t1
	jal 	sb_arctan
	lw 	$a0, 4($sp)
	sw 	$v0, ANGLE
	li 	$t0, 1
	sw 	$t0, ANGLE_CONTROL
	sw 	$t0, LANDING_REQUEST
	lw 	$t0, LANDING_REQUEST
	add 	$t0, $t0, 1
	bne 	$t0, $zero, turn_done
	j		fly
turn_more:

	move 	$a0, $t0
	move  	$a1, $t1
	jal 	sb_arctan
	lw 	$a0, 4($sp)
	add 	$v0, $v0, 180
	sw 	$v0, ANGLE
	li 	$t0 , 1
	sw 	$t0, ANGLE_CONTROL
	sw 	$t0, LANDING_REQUEST
	lw 	$t0, LANDING_REQUEST
	add 	$t0, $t0, 1
	bne 	$t0, $zero, turn_done
	j 	fly

turn_done:
	
	lw 	$ra, 0($sp)
	lw 	$s0, 8($sp)
	lw 	$s1, 12($sp)
	lw 	$s2, 16($sp)
	lw 	$s3, 20($sp)
	lw 	$s4, 24($sp)
	add 	$sp, $sp, 28
	jr 	$ra

.globl sb_arctan
sb_arctan:
	li	$v0, 0		# angle = 0;

	abs	$t0, $a0	# get absolute values
	abs	$t1, $a1
	ble	$t1, $t0, no_TURN_90	  

	## if (abs(y) > abs(x)) { rotate 90 degrees }
	move	$t0, $a1	# int temp = y;
	neg	$a1, $a0	# y = -x;      
	move	$a0, $t0	# x = temp;    
	li	$v0, 90		# angle = 90;  

no_TURN_90:
	bgez	$a0, pos_x 	# skip if (x >= 0)

	## if (x < 0) 
	add	$v0, $v0, 180	# angle += 180;

pos_x:
	mtc1	$a0, $f0
	mtc1	$a1, $f1
	cvt.s.w $f0, $f0	# convert from ints to floats
	cvt.s.w $f1, $f1
	
	div.s	$f0, $f1, $f0	# float v = (float) y / (float) x;

	mul.s	$f1, $f0, $f0	# v^^2
	mul.s	$f2, $f1, $f0	# v^^3
	l.s	$f3, three	# load 5.0
	div.s 	$f3, $f2, $f3	# v^^3/3
	sub.s	$f6, $f0, $f3	# v - v^^3/3

	mul.s	$f4, $f1, $f2	# v^^5
	l.s	$f5, five	# load 3.0
	div.s 	$f5, $f4, $f5	# v^^5/5
	add.s	$f6, $f6, $f5	# value = v - v^^3/3 + v^^5/5

	l.s	$f8, PI		# load PI
	div.s	$f6, $f6, $f8	# value / PI
	l.s	$f7, F180	# load 180.0
	mul.s	$f6, $f6, $f7	# 180.0 * value / PI

	cvt.w.s $f6, $f6	# convert "delta" back to integer
	mfc1	$t0, $f6
	add	$v0, $v0, $t0	# angle += delta

	jr 	$ra
	
	

.globl beat_opponent		#$a0 is the planet we are currently on (0-4)
beat_opponent:
	sub	$sp, $sp, 8
	sw	$ra, 0($sp)
	move	$t6, $a0	#$t6 is the planet we are on
	la	$t4, puzzle_loaded
	sw	$0, 0($t4)
	
	la	$t4, puzzle0_node
	sw	$t4, PUZZLE_REQUEST($0)
	
ad_wait_loop:
	#la	$t4, puzzle_loaded
	#lw	$t4, 0($t4)
	lw	$t4, puzzle_loaded
	bne	$t4, $0, ad_delivered
	j	ad_wait_loop
ad_delivered:
	#la	$t4, puzzle_loaded
	sw	$0, puzzle_loaded
	la	$t4, puzzle1_node
	sw	$t4, PUZZLE_REQUEST($0)
	
	la	$t5, puzzle0_node	# t5 = current node

ad_puzzle_loop: 	
	beq	$t5, $0, ad_puzzle_end
	lw	$a0, 0($t5)
	lw	$a1, 4($t5)
	jal	puzzle_solve
	sw	$v0, 8($t5)
	lw	$t5, 12($t5)
	j	ad_puzzle_loop
	
ad_puzzle_end:
	la	$t5, puzzle0_node
	sw	$t5, SOLVE_REQUEST($0)
	
	la	$t8, planet_array		#update planet stuff
	sw	$t8, PLANETS_REQUEST($0)
	
	mul 	$t9, $t6, 24
	add	$t9, $t9, $t8
	lw	$t3, favor($t9)
	lw	$t2, enemy_favor($t9)
	bgt	$t3, $t2, ad_finish_1
	
ad_wait1_loop:
	#la	$t4, puzzle_loaded
	#lw	$t4, 0($t4)
	lw	$t4, puzzle_loaded
	bne	$t4, $0, ad_delivered1
	j	ad_wait1_loop
ad_delivered1:
	#la	$t4, puzzle_loaded
	sw	$0, puzzle_loaded
	la	$t4, puzzle0_node
	sw	$t4, PUZZLE_REQUEST($0)
	
	la	$t5, puzzle1_node	# t5 = current node

ad_puzzle1_loop: 	
	beq	$t5, $0, ad_puzzle1_end
	lw	$a0, 0($t5)
	lw	$a1, 4($t5)
	jal	puzzle_solve
	sw	$v0, 8($t5)
	lw	$t5, 12($t5)
	j	ad_puzzle1_loop
	
ad_puzzle1_end:
	la	$t5, puzzle1_node
	sw	$t5, SOLVE_REQUEST($0)
	
	la	$t8, planet_array		#update planet stuff
	sw	$t8, PLANETS_REQUEST($0)
	
	mul 	$t9, $t6, 24
	add	$t9, $t9, $t8
	lw	$t3, favor($t9)
	lw	$t2, enemy_favor($t9)
	bgt	$t3, $t2, ad_finish_0

	j	ad_wait_loop
	
ad_finish_0:
ad_wait0f_loop:
	#la	$t4, puzzle_loaded
	#lw	$t4, 0($t4)
	lw	$t4, puzzle_loaded
	bne	$t4, $0, ad_delivered0f
	j	ad_wait0f_loop
ad_delivered0f:
	la	$t5, puzzle0_node
					# t5 = current node

ad_puzzle0f_loop: 	
	beq	$t5, $0, ad_puzzle0f_end
	lw	$a0, 0($t5)
	lw	$a1, 4($t5)
	jal	puzzle_solve
	sw	$v0, 8($t5)
	lw	$t5, 12($t5)
	j	ad_puzzle0f_loop
	
ad_puzzle0f_end:
	la	$t5, puzzle0_node
	sw	$t5, SOLVE_REQUEST($0)
	
	bgt	$t3, $t2, ad_end
	
	
ad_finish_1:
ad_wait1f_loop:
	#la	$t4, puzzle_loaded
	#lw	$t4, 0($t4)
	lw	$t4, puzzle_loaded
	bne	$t4, $0, ad_delivered1f
	j	ad_wait0f_loop
ad_delivered1f:
	la	$t5, puzzle1_node
					# t5 = current node

ad_puzzle1f_loop: 	
	beq	$t5, $0, ad_puzzle1f_end
	lw	$a0, 0($t5)
	lw	$a1, 4($t5)
	jal	puzzle_solve
	sw	$v0, 8($t5)
	lw	$t5, 12($t5)
	j	ad_puzzle1f_loop
	
ad_puzzle1f_end:
	la	$t5, puzzle1_node
	sw	$t5, SOLVE_REQUEST($0)
	
	bgt	$t3, $t2, ad_end
	
ad_end:
	lw	$ra, 0($sp)
	add	$sp, $sp, 8
	jr	$ra
	
	
	
	
.globl puzzle_solve
puzzle_solve:	
	move	$t0, $0		#$t0 is offset
ps_outer_loop:
	add	$t1, $a0, $t0
	lbu	$t1, 0($t1)
	beq	$t1, $0, ps_outer_end
	move	$t2, $0		#$t2 is index for char checking on $a0
	add	$t3, $t0, $t2	#$t3 is index for char checking on $a1
ps_inner_loop:
	add	$t1, $a0, $t2	#$t1 is char of $a0
	lbu	$t1, 0($t1)
	beq	$t1, $0, ps_success
	
	add	$t4, $a1, $t3	#$t4 is char of $a1
	lbu	$t4, 0($t4)
	bne	$t4, $0, ps_cont
	move	$t3, $0
	add	$t4, $a1, $t3	
	lbu	$t4, 0($t4)
ps_cont:
	
	bne	$t1, $t4, ps_inner_end
	
	add	$t2, $t2, 1
	add	$t3, $t3, 1
	j	ps_inner_loop
	
ps_inner_end:
	add	$t0, $t0, 1
	j	ps_outer_loop


ps_outer_end:			#Only reachable on fail
	add	$v0, $0, -1
	jr	$ra
	
	
ps_success:
	move	$v0, $t0
	jr	$ra
	
	
	
	
	
.kdata				# interrupt handler data (separated just for readability)
chunkIH:	.space 8	# space for two registers
non_intrpt_str:	.asciiz "Non-interrupt exception\n"
unhandled_str:	.asciiz "Unhandled interrupt type\n"


.ktext 0x80000180
interrupt_handler:
.set noat
	move	$k1, $at		# Save $at                               
.set at
	la	$k0, chunkIH
	sw	$a0, 0($k0)		# Get some free registers                  
	sw	$a1, 4($k0)		# by storing them to a global variable     

	mfc0	$k0, $13		# Get Cause register                       
	srl	$a0, $k0, 2                
	and	$a0, $a0, 0xf		# ExcCode field                            
	bne	$a0, 0, non_intrpt         

interrupt_dispatch:			# Interrupt:                             
	mfc0	$k0, $13		# Get Cause register, again                 
	beq	$k0, 0, done		# handled all outstanding interrupts     

	and	$a0, $k0, DELIVERY_MASK	# is there a delivery interrupt?                
	bne	$a0, 0, delivery_interrupt   

	# add dispatch for other interrupt types here.

	li	$a1, PRINT_INT	# Unhandled interrupt types
	la	$a0, unhandled_str
	syscall 
	j	done

delivery_interrupt:
	la	$a0, puzzle_loaded
	li	$a1, 5
	sw	$a1, 0($a0)
	sw	$a1, DELIVERY_ACKNOWLEDGE	# acknowledge interrupt

	j	interrupt_dispatch	# see if other interrupts are waiting


non_intrpt:				# was some non-interrupt
	li	$a1, PRINT_INT
	la	$a0, non_intrpt_str
	syscall				# print out an error message
	# fall through to done

done:
	la	$k0, chunkIH
	lw	$a0, 0($k0)		# Restore saved registers
	lw	$a1, 4($k0)
.set noat
	move	$at, $k1		# Restore $at
.set at 
	eret
	