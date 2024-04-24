;============================================================================
; ArchieKlang test harness.
; ============================================================================

.equ _VERIFY_SAMPLES,           1
.equ _PLAY_SONG,                1
.equ _SAVE_GEN_SAMPLES,         1
.equ _EMBED_QTM,                (_PLAY_SONG && 1)
.equ _LOG_SAMPLES,              0
;.equ _EXTERNAL_SAMPLES,        1  ; Now provided by make.bat

.equ AK_CLEAR_FIRST_2_BYTES,    1

.include "lib/swis.h.asm"

.if _EMBED_QTM
.macro QTMSWI swi_no
stmfd sp!, {r11,lr}
mov r11, #\swi_no - QTM_SwiBase
mov lr, pc
ldr pc, QtmEmbedded_Swi
ldmfd sp!, {r11,lr}
.endm
.else
.macro QTMSWI swi_no
swi \swi_no
.endm
.endif

; ============================================================================
; Stack
; ============================================================================

.org 0x8000

Start:
    adrl sp, stack_base
	B main

.skip 1024
stack_base:

; ============================================================================
; Main
; ============================================================================

generated_samples_p:
    .long Generated_Samples

total_sample_size:
    .long AK_SMP_LEN

.if _EXTERNAL_SAMPLES
external_samples_p:
    .long External_Samples
.endif

.if _EMBED_QTM
QtmEmbedded_Init:
    .long QtmEmbedded_Base + 52

QtmEmbedded_Swi:
    .long QtmEmbedded_Base + 56

QtmEmbedded_Service:
    .long QtmEmbedded_Base + 60

QtmEmbedded_Exit:
    .long QtmEmbedded_Base + 64
.endif

mod_data_p:
    .long MOD_data

main:
    adr r0, generating_msg
    swi OS_WriteO

    ; ============================================================================
    ; r8 = Sample Buffer Start Address
    ; r9 = 32768 Bytes Temporary Work Buffer Address (can be freed after sample rendering complete)
    ; r10 = External Samples Address (need not be in chip memory, and can be freed after sample rendering complete)
    ; ============================================================================

    ldr r8, generated_samples_p
    ldr r9, total_sample_size
    add r9, r9, #0xff
    add r9, r9, r8
    bic r9, r9, #0xff
    .if _EXTERNAL_SAMPLES
    ldr r10, external_samples_p
    .else
    mov r10, #0
    .endif
    bl AK_Generate
    ; R8=end of generated sample buffer.

    swi OS_WriteI+13
    swi OS_WriteI+10

    ldr r7, generated_samples_p
    sub r0, r8, r7
    bl write_num

    adr r0, total_msg
    swi OS_WriteO

    ; ============================================================================
    ; Save generated samples.
    ; ============================================================================

    .if _SAVE_GEN_SAMPLES
    adr r0, saving_msg
    swi OS_WriteO

    mov r0, #10 ; save block w/ type
    adr r1, save_filename
    mov r2, #0xffd
    ldr r4, generated_samples_p     ; start address of data
    mov r5, r8                      ; end address of data
    swi OS_File
    .endif

    ; ============================================================================
    ; Verify generated samples.
    ; ============================================================================

    .if _VERIFY_SAMPLES
    ; Verify samples..
    ldr r8, generated_samples_p
    adr r9, Reference_Samples
    mov r11, #0                 ; sample nr
.1:
    adr r10, AK_SmpLen
    ldr r7, [r10, r11, lsl #2]  ; sample len
    cmp r7, #0
    beq .2

    ; Verify sample N.
    adr r0, verifying_msg
    swi OS_WriteO

    mov r0, r11
    bl write_num

    adr r0, length_msg
    swi OS_WriteO

    mov r0, r7
    bl write_num

    adr r0, off_msg
    swi OS_WriteO

    ldr r0, generated_samples_p
    sub r0, r8, r0
    bl write_hex8

    swi OS_WriteI+')'
    swi OS_WriteI+'.'
    swi OS_WriteI+'.'

    mov r12, #0         ; max error
    mov r5, #0          ; num errors
    .if AK_CLEAR_FIRST_2_BYTES
    mov r6, #2
    add r8, r8, #2
    add r9, r9, #2
    .else
    mov r6, #0          ; sample idx
    .endif
.3:
    ldrb r3, [r8], #1
    ldrb r4, [r9], #1

    cmp r3, r4
    beq .4

    add r5, r5, #1      ; errors
    cmp r5, #1
    bgt .4

    adr r0, byte_num_msg
    swi OS_WriteO

    mov r0, r6
    bl write_num

    adr r0, mismatch_msg
    swi OS_WriteO

    mov r0, r3
    bl write_hex

    adr r0, vs_msg
    swi OS_WriteO

    mov r0, r4
    bl write_hex

.4:
    ; Max error.
    mov r3, r3, asl #24
    mov r3, r3, asr #24
    mov r4, r4, asl #24
    mov r4, r4, asr #24
    eors r0, r3, r4          ; sign same or different?
    bmi .41

    ; Signs same.
    cmp r3, #0
    rsbmi r3, r3, #0        ; abs(r3)
    cmp r4, #0
    rsbmi r4, r4, #0        ; abs(r4)
    subs r1, r3, r4
    rsbmi r1, r1, #0        ; abs(abs(r3)-abs(r4))
    cmp r1, r12
    movgt r12, r1

    cmp r1, #1
    ble .42
    mov r1, r1

    b .42

.41:
    ; Signs different.
    cmp r3, #0
    rsbmi r3, r3, #0        ; abs(r3)
    cmp r4, #0
    rsbmi r4, r4, #0        ; abs(r4)
    add r1, r3, r4          ; abs(r3)+abs(r4)
    cmp r1, r12
    movgt r12, r1

    cmp r1, #1
    ble .42
    mov r1, r1

.42:
    add r6, r6, #1
    cmp r6, r7
    blt .3

    cmp r5, #0
    beq .5

    ; Errors!
    adr r0, errors_msg
    swi OS_WriteO

    mov r0, r5
    bl write_num

    adr r0, max_err_msg
    swi OS_WriteO

    mov r0, r12
    bl write_num

    b .6
.5:
    ; Passed!
    adr r0, passed_msg
    swi OS_WriteO

.6:
    swi OS_WriteI+10
    swi OS_WriteI+13
    
.2:
    add r11, r11, #1
    cmp r11, #AK_MaxInstruments
    blt .1
    .endif

    ; ============================================================================
    ; Convert samples to log.
    ; ============================================================================

    .if _LOG_SAMPLES
    adr r0, logconv_msg
    swi OS_WriteO

    ldr r8, generated_samples_p
    ldr r9, total_sample_size
    add r9, r9, r8
    .20:
    ldrb r0, [r8]
    mov r0, r0, asl #24
    swi Sound_SoundLog
    strb r0, [r8], #1
    movs r1, r8, lsl #20            ; every 8k
    swieq OS_WriteI+'.'
    cmp r8, r9
    blt .20

    swi OS_WriteI+13
    swi OS_WriteI+10
    .endif

    ; ============================================================================
    ; Play the MOD.
    ; ============================================================================

    .if _PLAY_SONG
    adr r0, playing_msg
    swi OS_WriteO

    .if _EMBED_QTM
    adr lr, .10
    ldr pc, QtmEmbedded_Init
    .10:
    .endif

    mov r0, #0
    ldr r1, mod_data_p

    .if _LOG_SAMPLES
    ldr r2, qtm4
    str r2, [r1, #1080]
    .endif

    QTMSWI QTM_Load
    QTMSWI QTM_Start
    .endif

    .if _EMBED_QTM
    .11:
  	swi OS_ReadEscapeState
    bcc .11

    adr lr, .12
    ldr pc, QtmEmbedded_Exit
    .12:
    .endif

	swi OS_Exit

; ============================================================================
; Text strings and helpers.
; ============================================================================

; R0=num
write_num:
	adr r1, string_buffer
	mov r2, #16
	swi OS_ConvertCardinal4
	adr r0, string_buffer
	swi OS_WriteO
    mov pc, lr

.if _VERIFY_SAMPLES
write_hex:
	adr r1, string_buffer
	mov r2, #16
	swi OS_ConvertHex2
	adr r0, string_buffer
	swi OS_WriteO
    mov pc, lr

write_hex8:
	adr r1, string_buffer
	mov r2, #16
	swi OS_ConvertHex8
	adr r0, string_buffer
	swi OS_WriteO
    mov pc, lr
.endif

string_buffer:
	.skip 16

generating_msg:
    .byte 13,10
    .include "build/modname.i"
    .byte 13,10
    .byte "Generating samples",0
    .p2align 2

total_msg:
    .byte " bytes total!",13,10
    .p2align 2

.if _SAVE_GEN_SAMPLES
saving_msg:
    .byte "Saving samples...",13,10,0
    .p2align 2

save_filename:
    .byte "gen_smp",0
    .p2align 2
.endif

.if _PLAY_SONG
playing_msg:
    .byte "Playing MOD...",13,10,0
    .p2align 2
.endif

.if _LOG_SAMPLES
logconv_msg:
    .byte "Converting to log samples",0
    .p2align 2
.endif

.if _VERIFY_SAMPLES
verifying_msg:
    .byte "Verifying ",0
    .p2align 2

length_msg:
    .byte " (len ",0
    .p2align 2

off_msg:
    .byte " off ",0
    .p2align 2

errors_msg:
    .byte " errs=",0
    .p2align 2

max_err_msg:
    .byte " max=",0
    .p2align 2

passed_msg:
    .byte "Passed!",0
    .p2align 2

byte_num_msg:
    .byte "idx:",0
    .p2align 2

mismatch_msg:
    .byte " was:",0
    .p2align 2

vs_msg:
    .byte " ref:",0
    .p2align 2
.endif

.if _LOG_SAMPLES
qtm4:
    .byte "QTM4"
.endif

; ============================================================================
; Support routines.
; ============================================================================

.include "lib/divide.asm"

; ============================================================================
; Instrument generation code.
; ============================================================================

.macro AK_PROGRESS
    swi OS_WriteI+'.'
.endm

.macro AK_FINE_PROGRESS
.endm

.include "build/arcmusic.asm"

; ============================================================================
; Data.
; ============================================================================

.if _EMBED_QTM
QtmEmbedded_Base:
    .if _LOG_SAMPLES
    .incbin "lib/tinyQ149t2,ffa"
    .else
    .incbin "lib/tinyQTM149,ffa"
    .endif
.endif
.p2align 2

; ============================================================================
; BSS.
; ============================================================================

.if _VERIFY_SAMPLES
Reference_Samples:
.incbin "build/music.mod.smp"
.p2align 2
.endif

.if _EXTERNAL_SAMPLES
.p2align 2
External_Samples:
.incbin "build/Isamp.raw"
.endif

.p2align 8
MOD_data:
.incbin "build/music.mod.trk"

Generated_Samples:
