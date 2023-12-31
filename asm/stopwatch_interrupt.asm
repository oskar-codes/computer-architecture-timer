.equ    RAM, 0x1000
.equ    LEDs, 0x2000
.equ    TIMER, 0x2020
.equ    BUTTON, 0x2030

.equ    LFSR, RAM

br main
br interrupt_handler

main:
    ; Variable initialization for spend_time
    addi t0, zero, 18
    stw t0, LFSR(zero)

; <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
; DO NOT CHANGE ANYTHING ABOVE THIS LINE
; <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

	;addi t0, zero, 0xFFF
	;stw t0, LEDs+4(zero)

	addi sp, zero, LEDs

	# Enables PIE
	addi t0, zero, 1
	wrctl status, t0
	
	# Enables the interrupt for buttons and timer in control register ienable
	addi t0, zero, 0b101
	wrctl ienable, t0
	
	# TODO: find appropriate period equivating 100ms
	# Set the period of the timer to 100ms
	
	;addi t0, zero, 0x4c
	;slli t0, t0, 0x10
	;addi t0, t0, 0x4b40
	addi t0, zero, 1000
	stw t0, TIMER+4(zero)

	# Activate the control bits START, ITO, and CONT of the timer in control
	addi t0, zero, 0b1011
	stw t0, TIMER+8(zero)


	stw zero, RAM+4(zero)

	main_loop:
		br main_loop

    ; WRITE YOUR CONSTANT DEFINITIONS AND main HERE

interrupt_handler:
	addi t0, zero, 0xFFF
	stw t0, LEDs(zero)

	; save the registers to the stack
	addi sp, sp, -24
	stw ra, 0(sp)
	stw at, 4(sp)
	stw t0, 8(sp)
	stw t1, 12(sp)
	stw s0, 16(sp)
	stw ea, 20(sp)

	; read the ipending register to identify the source
	; call (br) the corresponding routine

	# Check for buttons in ipending
	addi t0, zero, 0b100
	rdctl t1, ipending
	and t0, t0, t1
	cmpeqi t0, t0, 0b100
	bne t0, zero, button_service_routine
	button_service_routine_ret:

	# Check for timer in ipending
	addi t0, zero, 0b1
	rdctl t1, ipending
	and t0, t0, t1
	bne t0, zero, timer_service_routine
	timer_service_routine_ret:

	; restore the registers from the stack
	ldw ra, 0(sp)
	ldw at, 4(sp)
	ldw t0, 8(sp)
	ldw t1, 12(sp)
	ldw s0, 16(sp)
	ldw ea, 20(sp)
	addi sp, sp, 24

	addi ea, ea, -4 ; correct the exception return address
	eret ; return from exception

button_service_routine:

	# Call spend_time
	call spend_time

	# Clear edgecapture
	stw zero, BUTTON+4(zero)

	br button_service_routine_ret


timer_service_routine:

	# Increment counter
	ldw t0, RAM+4(zero)
	addi t0, t0, 1
	stw t0, RAM+4(zero)
	
	# Reset TO in status
	ldw t1, TIMER+12(zero)
	xori t1, t1, 0b10
	stw t1, TIMER+12(zero)

	# Assign arguments and call display
	addi a0, t0, 0
	call display

	br timer_service_routine_ret


; <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
; DO NOT CHANGE ANYTHING BELOW THIS LINE
; <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
; ----------------- Common functions --------------------
; a0 = tenths of second
display:
    addi   sp, sp, -20
    stw    ra, 0(sp)
    stw    s0, 4(sp)
    stw    s1, 8(sp)
    stw    s2, 12(sp)
    stw    s3, 16(sp)
    add    s0, a0, zero
    add    a0, zero, s0
    addi   a1, zero, 600
    call   divide
    add    s0, zero, v0
    add    a0, zero, v1
    addi   a1, zero, 100
    call   divide
    add    s1, zero, v0
    add    a0, zero, v1
    addi   a1, zero, 10
    call   divide
    add    s2, zero, v0
    add    s3, zero, v1

    slli   s3, s3, 2
    slli   s2, s2, 2
    slli   s1, s1, 2
    ldw    s3, font_data(s3)
    ldw    s2, font_data(s2)
    ldw    s1, font_data(s1)

    xori   t4, zero, 0x8000
    slli   t4, t4, 16
    add    t5, zero, zero
    addi   t6, zero, 4
    minute_loop_s3:
    beq    zero, s0, minute_end
    beq    t6, t5, minute_s2
    or     s3, s3, t4
    srli   t4, t4, 8
    addi   s0, s0, -1
    addi   t5, t5, 1
    br minute_loop_s3

    minute_s2:
    xori   t4, zero, 0x8000
    slli   t4, t4, 16
    add    t5, zero, zero
    minute_loop_s2:
    beq    zero, s0, minute_end
    beq    t6, t5, minute_s1
    or     s2, s2, t4
    srli   t4, t4, 8
    addi   s0, s0, -1
    addi   t5, t5, 1
    br minute_loop_s2

    minute_s1:
    xori   t4, zero, 0x8000
    slli   t4, t4, 16
    add    t5, zero, zero
    minute_loop_s1:
    beq    zero, s0, minute_end
    beq    t6, t5, minute_end
    or     s1, s1, t4
    srli   t4, t4, 8
    addi   s0, s0, -1
    addi   t5, t5, 1
    br minute_loop_s1

    minute_end:
    stw    s1, LEDs(zero)
    stw    s2, LEDs+4(zero)
    stw    s3, LEDs+8(zero)

    ldw    ra, 0(sp)
    ldw    s0, 4(sp)
    ldw    s1, 8(sp)
    ldw    s2, 12(sp)
    ldw    s3, 16(sp)
    addi   sp, sp, 20

    ret

flip_leds:
    addi t0, zero, -1
    ldw t1, LEDs(zero)
    xor t1, t1, t0
    stw t1, LEDs(zero)
    ldw t1, LEDs+4(zero)
    xor t1, t1, t0
    stw t1, LEDs+4(zero)
    ldw t1, LEDs+8(zero)
    xor t1, t1, t0
    stw t1, LEDs+8(zero)
    ret

spend_time:
    addi sp, sp, -4
    stw  ra, 0(sp)
    call flip_leds
    ldw t1, LFSR(zero)
    add t0, zero, t1
    srli t1, t1, 2
    xor t0, t0, t1
    srli t1, t1, 1
    xor t0, t0, t1
    srli t1, t1, 1
    xor t0, t0, t1
    andi t0, t0, 1
    slli t0, t0, 7
    srli t1, t1, 1
    or t1, t0, t1
    stw t1, LFSR(zero)
    slli t1, t1, 15
    addi t0, zero, 1
    slli t0, t0, 22
    add t1, t0, t1

spend_time_loop:
    addi   t1, t1, -1
    bne    t1, zero, spend_time_loop
    
    call flip_leds
    ldw ra, 0(sp)
    addi sp, sp, 4

    ret

; v0 = a0 / a1
; v1 = a0 % a1
divide:
    add    v0, zero, zero
divide_body:
    add    v1, a0, zero
    blt    a0, a1, end
    sub    a0, a0, a1
    addi   v0, v0, 1
    br     divide_body
end:
    ret



font_data:
    .word 0x7E427E00 ; 0
    .word 0x407E4400 ; 1
    .word 0x4E4A7A00 ; 2
    .word 0x7E4A4200 ; 3
    .word 0x7E080E00 ; 4
    .word 0x7A4A4E00 ; 5
    .word 0x7A4A7E00 ; 6
    .word 0x7E020600 ; 7
    .word 0x7E4A7E00 ; 8
    .word 0x7E4A4E00 ; 9
    .word 0x7E127E00 ; A
    .word 0x344A7E00 ; B
    .word 0x42423C00 ; C
    .word 0x3C427E00 ; D
    .word 0x424A7E00 ; E
    .word 0x020A7E00 ; F
