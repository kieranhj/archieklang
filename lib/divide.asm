; ============================================================================
; Division routines.
; ============================================================================

; Divide R0 by R1
; Parameters:
;  R0=numerator  [s15.16]       ; (a<<16)
;  R1=divisor    [s15.16]       ; (b<<16)
; Trashes:
;  R8-R10
divide:
    stmfd sp!, {r8-r10,lr}

    ; Signed division - any better way to do this?
    eor r10, r0, r1             ; R0 eor R1 indicates sign of result
    cmp r0, #0
    rsbmi r0, r0, #0            ; make positive
    cmp r1, #0
    rsbmi r1, r1, #0            ; make positive  

    CMP R1,#0                   ; Test for division by zero
    ADREQ R0,divbyzero          ; and flag an error
    SWIEQ OS_GenerateError      ; when necessary

    cmp r0, #0                  ; Test if result is zero
    ldmeqfd sp!, {r8-r10,pc}

    ; Taken from Archimedes Operating System, page 28.
    MOV R8, #1
    MOV R9, #0
    CMP R1, #0
    .1:                         ; raiseloop
    BMI .3
    CMP R1,R0
    BHI .2
    MOVS R1,R1,LSL #1
    MOV R8,R8,LSL #1
    B .1  
    .3:                         ; raisedone
    CMP R0,R1
    SUBCS R0,R0,R1
    ADDCS R9,R9,R8              ; Accumulate result
    .2:                         ; nearlydone
    MOV R1,R1,LSR #1
    MOVS R8,R8,LSR #1
    BCC .3

    mov r1, r0                  ; Move MODULO result into R1
    mov r0, r9                  ; Move positive result into R0*
    movs r10, r10               ; get sign back
    rsbmi r0, r0, #0            ; Neative result into R0*
    ldmfd sp!, {r8-r10,pc}

    ; * Remove the lines marked with asterisks to
    ; return R0 MOD R1 instead of R0 DIV R1

    divbyzero: ;The error block
    .long 18
	.byte "Divide by Zero"
	.align 4
	.long 0

    divrange: ;The error block
    .long 18
	.byte "Division out of range"
	.align 4
	.long 0
