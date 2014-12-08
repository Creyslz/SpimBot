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
planet0_array: 	.space 120
puzzle0_loaded:	.space 4
puzzle0_node:	.space 8192
		.align 2
planet1_array: 	.space 120
puzzle1_loaded:	.space 4
puzzle1_node:	.space 8192
		.align 2
planet2_array: 	.space 120
puzzle2_loaded:	.space 4
puzzle2_node:	.space 8192
		.align 2
planet3_array: 	.space 120
puzzle3_loaded:	.space 4
puzzle3_node:	.space 8192
		.align 2
planet4_array: 	.space 120
puzzle4_loaded:	.space 4
puzzle4_node:	.space 8192


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



					# enable interrupts
	li	$t4, DELIVERY_MASK	# deliv interrupt bit
	or	$t4, $t4, 1		# global interrupt enable
	mtc0	$t4, $12		# set interrupt mask (Status register)
					
	sub	$sp, $sp, 8
	sw	$ra, 0($sp)				
	
	la	$t8, planet_array
	li	$t0, PLANETS_REQUEST
	sw	$t8, 0($t0) 
					
	li	$t0, LANDING_REQUEST
	
	li	$t9, -1
	beq	$t0, $t9, ad_landed
	
	lw	$t0, 0($t0)
	li	$t1, 0
	bne	$t1, $t0, it_skip
	add	$t1, $t1, 1
it_skip:
	li	$t0, TAKEOFF_REQUEST
	sw	$t0, 0($t0)
	
	li	$t9, 0
	li	$t0, VELOCITY
	sw	$t9, 0($t0)
	
	mul 	$t9, $t1, 24
	add	$t9, $t9, $t8
	lw	$t3, orbital_radius($t9)
	add	$t3, $t3, 150
	li	$t2, 150
	
it_movex_loop:
	li	$t4, BOT_X
	lw	$t4, 0($t4)
	beq	$t4, $t2, it_movex_end
	li	$t9, 180
	bgt	$t4, $t2, it_movex_continue
	li	$t9, 0
	
it_movex_continue:
	li	$t0, ANGLE
	sw	$t9, 0($t0)
	li	$t9, 1
	li	$t0, ANGLE_CONTROL
	sw	$t9, 0($t0)
	
	li	$t9, 10
	li	$t0, VELOCITY
	sw	$t9, 0($t0)
	j	it_movex_loop
	
it_movex_end:
	li	$t9, 0
	li	$t0, VELOCITY
	sw	$t9, 0($t0)
	
it_movey_loop:
	li	$t5, BOT_Y
	lw	$t5, 0($t5)
	beq	$t5, $t3, it_movey_end
	li	$t9, -90
	bgt	$t5, $t3, it_movey_continue
	li	$t9, 90
	
it_movey_continue:
	li	$t0, ANGLE
	sw	$t9, 0($t0)
	li	$t9, 1
	li	$t0, ANGLE_CONTROL
	sw	$t9, 0($t0)
	
	li	$t9, 10
	li	$t0, VELOCITY
	sw	$t9, 0($t0)
	j	it_movey_loop
	
it_movey_end:
	li	$t9, 0
	li	$t0, VELOCITY
	sw	$t9, 0($t0)
	
it_land_loop:
	li	$t0, LANDING_REQUEST
	sw	$t0, 0($t0)
	lw	$t0, 0($t0)
	li	$t9, -1
	bne	$t0, $t9, it_end
	j	it_land_loop
it_end:

	
	
ad_favor_loop:
	la	$t8, planet_array		#update planet stuff
	sw	$t8, PLANETS_REQUEST($0)
	
	lw	$t7, LANDING_REQUEST($0)
	
	mul	$t7, $t7, 24
	add	$t7, $t7, $t8
	lw	$t0, favor($t7)
	li	$t1, 10
	bge	$t0, $t1, ad_end
	
		
	
	
ad_landed:	
	la	$t4, puzzle_loaded
	sw	$0, 0($t4)
	
	la	$t4, puzzle_node
	sw	$t4, PUZZLE_REQUEST($0)
	

ad_wait_loop:
	la	$t4, puzzle_loaded
	lw	$t4, 0($t4)
	bne	$t4, $0, ad_delivered
	j	ad_wait_loop
ad_delivered:
	la	$t1, puzzle_node
					# t1 = current node

ad_puzzle_loop: 	
	beq	$t1, $0, ad_puzzle_end
	sw	$t1, 4($sp)
	lw	$a0, 0($t1)
	lw	$a1, 4($t1)
	jal	puzzle_solve
	lw	$t1, 4($sp)
	sw	$v0, 8($t1)
	lw	$t1, 12($t1)
	j	ad_puzzle_loop
	
ad_puzzle_end:
	la	$t1, puzzle_node
	sw	$t1, SOLVE_REQUEST($0)
	
	j	ad_favor_loop
	
	
ad_end:

	li	$t7, 134
	lw	$ra, 0($sp)
	add	$sp, $sp, 8

	jr	$ra

	

.globl beat_opponent
beat_opponent:

	
	
	
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
go_to_planet_x:
	sub 	$sp, $sp, 16
	sw 		$ra, 0($sp)
	sw 		$s0, 4($sp)
	sw 		$s1, 8($sp)
	sw 		$s2, 12($sp)





	lw 		$ra, 0($sp)
	lw 		$s0, 4($sp)
	lw 		$s1, 8($sp)
	lw 		$s2, 12($sp)
	jr 		$ra