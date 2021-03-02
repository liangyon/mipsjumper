

.data
	displayAddress: .word 0x10008000
	platform1: .word 0x10008FC0
	platform2: .word 0x10008BD0
	platform3: .word 0x100087A8
	platform4: .word 0x100083C8
	enemy: .word 0x100083E0
	player: .word 0x10008A40
	blank: .word 0x10009000
	red: .word 0xff0000 
	green: .word 0x00ff00 
	blue: .word 0x0000ff 
	
	replayMessage:	.asciiz "Game over! Would you like to replay?"
.text

Init: 	
	lw $s0, displayAddress # $s0 stores the base address for display
	lw $s7 blank		# stores screen size in s7
	

	li $s6, 0xFFFFFFF	# $s6 stores black colour code
	li $s4, 4		# constant 4
	li $s5, 128		# constant 128
	
	addi $t0, $0, 0x10008FC0 #restores original position of platform and players
	sw $t0, platform1
	addi $t0, $0, 0x10008BD0
	sw $t0, platform2
	addi $t0, $0, 0x100087A8
	sw $t0, platform3
	addi $t0, $0, 0x100083C8
	sw $t0, platform4
	
	addi $t0, $0, 0x10008208
	sw $t0, enemy
	addi $t0, $0, 0x10008A40
	sw $t0, player
	
	jal Clear		# in case reset
	
	addi $t5, $0, 1024		# platform recoil, starts counting down to zero after every new platform step
	addi $t7, $0, 0		# vertical direction variable, 0 = down, 1 = up
	addi $t8, $0, 0		# horizontal direction variable, 0 = neutral, 1 = left, 2 = right
	addi $t9, $0, 1024		# jump vector, will go up to 2048 and count back down in another function, 

	addi $t6, $0, 0 		# the score, goes up by 1 for each platform

Main:	

	jal Keychecker #checks for keystrokes and acts accordingly
	
	jal Update	#updates all coordinates based on collision etc....
	
	lw $t0, platform1 #loads platform coordinates and draws accordingly
	jal DrawPlatform
	lw $t0, platform2
	jal DrawPlatform
	lw $t0, platform3
	jal DrawPlatform
	lw $t0, platform4
	jal DrawPlatform
	
	lw $t0, enemy	#draw enemy and players
	jal DrawEnemy
	lw $t0, player
	jal DrawPlayer
	
	li $v0, 32 #sleep
	li $a0, 160
	syscall
	
	jal Clear #redraw screen
	
	j Main # cause main to loop
#######################################
# Gameover!
#######################################
Gameover: 
	jal Clear
	addi $t0, $s0, 0 #add (0,0) to t0
	addi $t2, $0, 0 #increment t2 until same as score
	addi $t3, $s0, 0 #horizontal increment
	j scorecheck
scorecheck:	
	bge $t2, $t6, next #checks if t0 is at score
	jal DrawPlatform 
	addi $t0, $t0, 256
	addi $t2, $t2, 1
	bge $t0, $s7, nextline
	j scorecheck
nextline:
	addi $t3, $t3, 20
	add $t0, $0, $t3
	j scorecheck
	
next:	li $v0, 50 #syscall for yes/no dialog
	la $a0, replayMessage #get message
	syscall
	
	beqz $a0, Init #jump back to start of program
	#end program
	li $v0, 10
	syscall

	
#######################################
# Function to draw update coordinates
#######################################
Update:
	j checkvert		#jump to checking vertical movmeent
checkvert:			#checks up or down
	beq $t7, 0, movedown
	beq $t7, 1, moveup
checkplatform:
	blt $t5, 1024, moveplatform
	j checkhoriz
moveplatform:
	addi $t5, $t5, 256     #add 256 to counter
	
	lw $t1, platform1	#adjust location of platforms
	addi $t1, $t1, 256
	sw $t1, platform1
	
	lw $t2, platform2
	addi $t2, $t2, 256
	sw $t2, platform2
	
	lw $t3, platform3
	addi $t3, $t3, 256
	sw $t3, platform3 
	
	lw $t4, platform4
	addi $t4, $t4, 256
	sw $t4, platform4
	
	lw $a1, enemy
	addi $a1, $a1, 256
	sw $a1, enemy
	
	j checkhoriz

checkhoriz:			#checks left or right
	beq $t8, 1, moveleft
	beq $t8, 2, moveright
	jr $ra
moveup:				
	lw $t0, player
	subi $t0, $t0, 128	#move player coordinate down
	subi $t9, $t9, 128	#move current velocity down
	sw $t0, player
	beq $t9, 0, godown #change direction if hit max jump height
	j checkcollision
godown:
	addi $t7, $0, 0 #change direction from up to down 
	j checkplatform

movedown:
	lw $t0, player
	addi $t0, $t0, 128	#move player coordinate down
	addi $t9, $t9, 128	#move current velocity down
	sw $t0, player
	#beq $t9, 2048, goup # go up if lowest jump height reached
	j checkcollision
goup: 
	addi $t6, $t6, 1 #add1 to score
	addi $t7, $0, 1 #change direction from up to down 
	addi $t9, $0, 1024 #reset player jump velocity
	addi $t5, $0, 0#begin platform movement
	j checkplatform
	
checkcollision: 		#checks if player's foot has hit a platform
	lw $t1, platform1
	subi $t1, $t1, 0x100
	lw $t2, platform2
	subi $t2, $t2, 0x100
	lw $t3, platform3
	subi $t3, $t3, 0x100
	lw $t4, platform4
	subi $t4, $t4, 0x100
	lw $a1, enemy
	
	beq $t1, $t0, goup
	beq $t2, $t0, goup
	beq $t3, $t0, goup
	beq $t4, $t0, goup
	
	#out of bounds checks
	beq $t0, 0, Exit 		#player is above screen somehow
	bgt $t0, 0x10008FFC, Gameover	#player falls to their death
	beq $t0, $a1, Gameover		#player has been killed by enemy
	
	bgt $t1, 0x10008FFC, Spawn1	#platform1-4 exiting stage, needs to reenter
	bgt $t2, 0x10008FFC, Spawn2
	bgt $t3, 0x10008FFC, Spawn3
	bgt $t4, 0x10008FFC, Spawn4
	bgt $a1, 0x10008FFC, SpawnEnemy

	
	j checkplatform
Spawn1:
	li $v0, 42
	li $a0, 0
	li $a1, 28
	syscall
	
	mul $a0, $a0, $s4
	add $t1, $s0, $a0
	#addi $t4, $t4, 128
	sw $t1, platform1 
	addi $t6, $t6, 1
	j checkplatform
Spawn2:
	li $v0, 42
	li $a0, 0
	li $a1, 28
	syscall	
	
	mul $a0, $a0, $s4
	add $t2, $s0, $a0
	#addi $t4, $t4, 128
	sw $t2, platform2
	addi $t6, $t6, 1
	j checkplatform
Spawn3:
	li $v0, 42
	li $a0, 0
	li $a1, 28
	syscall
	
	mul $a0, $a0, $s4
	add $t3, $s0, $a0
	#addi $t4, $t4, 128	
	sw $t3, platform3
	addi $t6, $t6, 1
	j checkplatform

Spawn4:
	li $v0, 42
	li $a0, 0
	li $a1, 28
	syscall
	
	mul $a0, $a0, $s4
	add $t4, $s0, $a0
	#addi $t4, $t4, 128
	sw $t4, platform4
	addi $t6, $t6, 1
	j checkplatform

SpawnEnemy:
	li $v0, 42
	li $a0, 0
	li $a1, 28
	syscall
	
	mul $a0, $a0, $s4
	add $t4, $s0, $a0
	#addi $t4, $t4, 128
	sw $t4, enemy
	j checkplatform

moveleft:
	lw $t0, player
	subi $t0, $t0, 4
	sw $t0, player
	jr $ra
moveright:
	lw $t0, player
	addi $t0, $t0, 4
	sw $t0, player
	jr $ra


#######################################
# Function to check keys
#######################################

Keychecker: 			#checks keypresses for j or k
	lw $t8, 0xffff0000
	beq $t8, 1, keyboardinput
	jr $ra
keyboardinput: 			#checks for j, k or s
	lw $t2, 0xffff0004
	beq $t2, 0x6a, respondtoJ
	beq $t2, 0x6b, respondtoK
	beq $t2, 0x73, respondtoS
	jr $ra
respondtoJ:			#sets direction to left, or neutral if currently right
	addi $t8, $0, 1
	jr $ra
respondtoK:			#sets direction to right, or neutral if currently left
	addi $t8, $0, 2
	jr $ra
respondtoS:			#reset the game
	j Init

	

#######################################
# Function to draw platform	
#######################################
DrawPlatform: 			#draws a platform at register t0
	addi $a0, $t0, 16	#set goalpost
	addi $a1, $t0, 0	#set increment
	lw $t1, green
PLATLOOP:	
	beq $a0, $a1, DONEPLAT	#for loop statement
	sw $t1, 0($a1) 		# Draw the first platform
	addi $a1, $a1, 4	#increment by 4
	j PLATLOOP
DONEPLAT: jr $ra

#######################################
# Function to draw player
#######################################
DrawPlayer:		  	#draws a player at t0
	addi $a0, $s0, 0 	#load player coordinate
	lw $t1, green
	sw $t1, 4($t0) 
	sw $t1, 8($t0) 
	sw $t1, 128($t0) 
	sw $t1, 140($t0) 
	sw $t1, 260($t0) 
	sw $t1, 264($t0) 
	sw $t1, 384($t0) 
	sw $t1, 396($t0) 
	jr $ra
	
#######################################
# Function to draw player
#######################################
DrawEnemy:		  	#draws a enemy at t0
	addi $a0, $s0, 0 	#load enemycoordinate
	lw $t1, red
	lw $t2, blue
	sw $t1, 0($t0) 
	sw $t1, 12($t0) 
	sw $t1, 132($t0) 
	sw $t1, 136($t0) 
	sw $t1, 256($t0) 
	sw $t2, 260($t0) 
	sw $t2, 264($t0) 
	sw $t1, 268($t0) 
	sw $t1, 388($t0) 
	sw $t1, 392($t0) 
	jr $ra
	
#######################################
# Function to clear screen
#######################################
Clear:				#clears screen byy drawing black over all
	addi $a0, $s0, 0 	#set a0 to display address
	addi $a1, $s7, 0 	#set a0 to blank
clearLoop:
	beq $a0, $a1, doneClear 
	sw $s6, 0($a0) 		# draw pixel black
	addi $a0, $a0, 4 	#increment by 4 
	j clearLoop
doneClear: jr $ra
	
	
#######################################
# Function to end the game
#######################################
	
Exit:
	li $v0, 10 		# terminate the program gracefully
	syscall
