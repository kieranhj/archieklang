; ============================================================================
; Shrinkler loader with embedded data.
; Relocate all data to top of RAM.
; Call Shrinkler and return to app start at 0x8000.
; ============================================================================

.equ _DEBUG, 0

.include "../lib/swis.h.asm"

.ifndef _WIMPSLOT
.equ _WIMPSLOT, 400*1024           ; Assumed RAM - see !Run.txt
.endif

.org 0x8000

main:
    mov r0, #_WIMPSLOT
    mov r1, #0
    swi Wimp_SlotSize

    adr r0, message_text
    swi OS_WriteO

    ; NB. Could calculate this from end of free RAM SWI call.
    ldr r8, reloc_to                ; reloc_to

    ; Relocate decoder.
    mov r9, r8                      ; dst
    adr r11, reloc_start            ; src
    adr r10, reloc_end              ; end
.1:
    ldr r0, [r11], #4
    str r0, [r9], #4
    cmp r11, r10
    blt .1

    ; Relocation offset.
    adr r3, reloc_start
    sub r3, r3, r8

    ; Call decompressor.
    adr r0, compressed_demo_start
    sub r0, r0, r3                  ; source (reloc)

    mov r1, #0x8000                 ; destination

    adr r2, callback
    sub r2, r2, r3                  ; callback fn (reloc)

    mov r3, #0                      ; callback arg

    ; R9 = end of reloc = shrinkler contexts

    mov sp, r8                      ; reset stack top
    mov lr, #0x8000                 ; return address
    mov pc, r8                      ; jump to reloc

message_text:
    .byte "Unshrinkling"
    .byte 0
.p2align 2

reloc_to:
    .long 0x8000 + _WIMPSLOT - (reloc_end - reloc_start) - (NUM_CONTEXTS*4) - 4

reloc_start:
	b ShrinklerDecompress

; R0=bytes written
; R1=callback arg
callback:
    movs r1, r0, lsl #22            ; every 2k
    swieq OS_WriteI+'.'
    mov pc, lr

.include "../lib/arc-shrinkler.asm"

.p2align 2
compressed_demo_start:
.incbin "../build/archieklang.shri"
.p2align 2
compressed_demo_end:

shrinkler_contexts:
    ; .skip (NUM_CONTEXTS*4)

reloc_end:

; ============================================================================
