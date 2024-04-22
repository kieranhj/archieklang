; ============================================================================
; akp2arc.py
; input = amigahub\script.txt.
; ============================================================================

.equ AK_MaxInstruments,	31
.equ AK_MaxExtSamples,	8

.equ AK_LPF,			0
.equ AK_HPF,			1
.equ AK_BPF,			2

.equ AK_CHORD1,			0
.equ AK_CHORD2,			1
.equ AK_CHORD3,			2

.equ AK_SMPLEN,			(AK_SmpLen-AK_Vars)
.equ AK_EXTSMPLEN,		(AK_ExtSmpLen-AK_Vars)
.equ AK_NOISESEEDS,		(AK_NoiseSeeds-AK_Vars)
.equ AK_SMPADDR,		(AK_SmpAddr-AK_Vars)
.equ AK_EXTSMPADDR,		(AK_ExtSmpAddr-AK_Vars)
.equ AK_OPINSTANCE,		(AK_OpInstance-AK_Vars)
.equ AK_ENVDVALUE,		(AK_EnvDValue-AK_Vars)

.equ AK_SMP_LEN,		242678
.equ AK_EXT_SMP_LEN,	30896

; ============================================================================
; r8 = Sample Buffer Start Address
; r9 = 32768 Bytes Temporary Work Buffer Address (can be freed after sample rendering complete)
; r10 = External Samples Address (need not be in chip memory, and can be freed after sample rendering complete)
; ============================================================================

AK_Generate:
	str lr, [sp, #-4]!

	; Create sample & external sample base addresses
	adr r4, AK_SmpAddr
	adr r5, AK_SmpLen
	mov r7, #AK_MaxInstruments
	mov r0, r8
SmpAdrLoop:
	str r0, [r4], #4
	ldr r1, [r5], #4
	add r0, r0, r1
	subs r7, r7, #1
	bne SmpAdrLoop
	mov r7, #AK_MaxExtSamples
	adr r4, AK_ExtSmpAddr
	adr r5, AK_ExtSmpLen
	mov r0, r10
ExSmpAdrLoop:
	str r0, [r4], #4
	ldr r1, [r5], #4
	add r0, r0, r1
	subs r7, r7, #1
	bne ExSmpAdrLoop

.if _EXTERNAL_SAMPLES
	; Convert external samples from stored deltas
	mov r7, #AK_EXT_SMP_LEN
	mov r6, r10
	mov r0, #0
DeltaLoop:
	ldrb r1, [r6]
	mov r1, r1, asl #24
	mov r1, r1, asr #24
	add r0, r0, r1
	mov r0, r0, asl #24
	mov r0, r0, asr #24
	strb r0, [r6], #1
	subs r7, r7, #1
	bne DeltaLoop
.endif

; ============================================================================
; r0 = v1 (final sample value)
; r1 = v2
; r2 = v3
; r3 = v4
; r4 = temp
; r5 = temp
; r6 = temp
; r7 = Sample byte count
; r8 = Sample Buffer Start Address
; r9 = 32768 Bytes Temporary Work Buffer Address (can be freed after sample rendering complete)
; r10 = Base of AK_Vars
; r11 = 36767 (0x7fff)
; r12 = temp
; r14 = temp
; ============================================================================

	adr r10, AK_Vars
	mov r11, #32767	; const

;----------------------------------------------------------------------------
; Instrument 1 - 'amigahub-hat'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst1Loop:
	; v1 = imported_sample(smp,0);
	mov r0, r7
	ldr r6, [r10, #AK_EXTSMPADDR+4*0]
	ldr r4, [r10, #AK_EXTSMPLEN+4*0]
	cmp r0, r4
	movge r0, #0
	ldrltb r0, [r6, r0]
	mov r0, r0, asl #24
	mov r0, r0, asr #16

	; v1 = sv_flt_n(1, v1, 79, 127, 1);
	ldr r4, [r10, #AK_OPINSTANCE+4*(0+AK_LPF)]
	ldr r5, [r10, #AK_OPINSTANCE+4*(0+AK_HPF)]
	ldr r6, [r10, #AK_OPINSTANCE+4*(0+AK_BPF)]
	mov r14, r6, asr #7
	mov r12, #79
	mla r4, r14, r12, r4
	; r4 = clamp(r4)
	cmp r4, r11		; #32767
	movgt r4, r11	; #32767
	cmn r4, r11		; #-32768
	mvnlt r4, r11	; #-32768
	str r4, [r10, #AK_OPINSTANCE+4*(0+AK_LPF)]
	mov r12, #127
	mul r14, r12, r14
	mov r12, r0
	sub r12, r12, r4
	sub r5, r12, r14
	; r5 = clamp(r5)
	cmp r5, r11		; #32767
	movgt r5, r11	; #32767
	cmn r5, r11		; #-32768
	mvnlt r5, r11	; #-32768
	str r5, [r10, #AK_OPINSTANCE+4*(0+AK_HPF)]
	mov r14, r5, asr #7
	mov r12, #79
	mla r6, r12, r14, r6
	; r6 = clamp(r6)
	cmp r6, r11		; #32767
	movgt r6, r11	; #32767
	cmn r6, r11		; #-32768
	mvnlt r6, r11	; #-32768
	str r6, [r10, #AK_OPINSTANCE+4*(0+AK_BPF)]
	mov r0, r5

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*0]
	cmp r7, r4
	blt Inst1Loop

;----------------------------------------------------------------------------
; Instrument 2 - 'amigahub-hat2'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst2Loop:
	; v1 = clone(smp,0, 336);
	add r0, r7, #336
	ldr r6, [r10, #AK_SMPADDR+4*0]
	ldr r4, [r10, #AK_SMPLEN+4*0]
	cmp r0, r4
	movge r0, #0
	ldrltb r0, [r6, r0]
	mov r0, r0, asl #24
	mov r0, r0, asr #16

	; v2 = enva(1, 4, 0, 127);
	ldr r6, [r10, #AK_OPINSTANCE+4*0]
	mov r1, r6, asr #8
	mov r4, #10922
	add r6, r6, r4
	cmp r6, r11, asl #8
	movgt r6, r11, asl #8
	str r6, [r10, #AK_OPINSTANCE+4*0]
	; v2 = vol(v2, 127)
	mov r14, #127
	mul r1, r14, r1
	mov r1, r1, asr #7

	; v1 = mul(v1, v2);
	mul r0, r1, r0
	mov r0, r0, asr #15

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*1]
	cmp r7, r4
	blt Inst2Loop

;----------------------------------------------------------------------------
; Instrument 3 - 'amigahub-hatopen'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst3Loop:
	; v1 = imported_sample(smp,1);
	mov r0, r7
	ldr r6, [r10, #AK_EXTSMPADDR+4*1]
	ldr r4, [r10, #AK_EXTSMPLEN+4*1]
	cmp r0, r4
	movge r0, #0
	ldrltb r0, [r6, r0]
	mov r0, r0, asl #24
	mov r0, r0, asr #16

	; v1 = sv_flt_n(1, v1, 40, 127, 1);
	ldr r4, [r10, #AK_OPINSTANCE+4*(0+AK_LPF)]
	ldr r5, [r10, #AK_OPINSTANCE+4*(0+AK_HPF)]
	ldr r6, [r10, #AK_OPINSTANCE+4*(0+AK_BPF)]
	mov r14, r6, asr #7
	mov r12, #40
	mla r4, r14, r12, r4
	; r4 = clamp(r4)
	cmp r4, r11		; #32767
	movgt r4, r11	; #32767
	cmn r4, r11		; #-32768
	mvnlt r4, r11	; #-32768
	str r4, [r10, #AK_OPINSTANCE+4*(0+AK_LPF)]
	mov r12, #127
	mul r14, r12, r14
	mov r12, r0
	sub r12, r12, r4
	sub r5, r12, r14
	; r5 = clamp(r5)
	cmp r5, r11		; #32767
	movgt r5, r11	; #32767
	cmn r5, r11		; #-32768
	mvnlt r5, r11	; #-32768
	str r5, [r10, #AK_OPINSTANCE+4*(0+AK_HPF)]
	mov r14, r5, asr #7
	mov r12, #40
	mla r6, r12, r14, r6
	; r6 = clamp(r6)
	cmp r6, r11		; #32767
	movgt r6, r11	; #32767
	cmn r6, r11		; #-32768
	mvnlt r6, r11	; #-32768
	str r6, [r10, #AK_OPINSTANCE+4*(0+AK_BPF)]
	mov r0, r5

	; v1 = reverb(v1, 107, 13);
	ldr r6, [r10, #AK_OPINSTANCE+4*3]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 107)
	mov r14, #107
	mul r4, r14, r4
	mov r4, r4, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r12, r0, r4
	; r12 = clamp(r12)
	cmp r12, r11		; #32767
	movgt r12, r11	; #32767
	cmn r12, r11		; #-32768
	mvnlt r12, r11	; #-32768
	str r12, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #557
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*3]
	; r12 = vol(r12, 13)
	mov r14, #13
	mul r12, r14, r12
	mov r12, r12, asr #7
	mov r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*4]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 107)
	mov r14, #107
	mul r4, r14, r4
	mov r4, r4, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r12, r0, r4
	; r12 = clamp(r12)
	cmp r12, r11		; #32767
	movgt r12, r11	; #32767
	cmn r12, r11		; #-32768
	mvnlt r12, r11	; #-32768
	str r12, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #593
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*4]
	; r12 = vol(r12, 13)
	mov r14, #13
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*5]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 107)
	mov r14, #107
	mul r4, r14, r4
	mov r4, r4, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r12, r0, r4
	; r12 = clamp(r12)
	cmp r12, r11		; #32767
	movgt r12, r11	; #32767
	cmn r12, r11		; #-32768
	mvnlt r12, r11	; #-32768
	str r12, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #641
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*5]
	; r12 = vol(r12, 13)
	mov r14, #13
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*6]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 107)
	mov r14, #107
	mul r4, r14, r4
	mov r4, r4, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r12, r0, r4
	; r12 = clamp(r12)
	cmp r12, r11		; #32767
	movgt r12, r11	; #32767
	cmn r12, r11		; #-32768
	mvnlt r12, r11	; #-32768
	str r12, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #677
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*6]
	; r12 = vol(r12, 13)
	mov r14, #13
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*7]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 107)
	mov r14, #107
	mul r4, r14, r4
	mov r4, r4, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r12, r0, r4
	; r12 = clamp(r12)
	cmp r12, r11		; #32767
	movgt r12, r11	; #32767
	cmn r12, r11		; #-32768
	mvnlt r12, r11	; #-32768
	str r12, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #709
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*7]
	; r12 = vol(r12, 13)
	mov r14, #13
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*8]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 107)
	mov r14, #107
	mul r4, r14, r4
	mov r4, r4, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r12, r0, r4
	; r12 = clamp(r12)
	cmp r12, r11		; #32767
	movgt r12, r11	; #32767
	cmn r12, r11		; #-32768
	mvnlt r12, r11	; #-32768
	str r12, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #743
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*8]
	; r12 = vol(r12, 13)
	mov r14, #13
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*9]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 107)
	mov r14, #107
	mul r4, r14, r4
	mov r4, r4, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r12, r0, r4
	; r12 = clamp(r12)
	cmp r12, r11		; #32767
	movgt r12, r11	; #32767
	cmn r12, r11		; #-32768
	mvnlt r12, r11	; #-32768
	str r12, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #787
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*9]
	; r12 = vol(r12, 13)
	mov r14, #13
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*10]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 107)
	mov r14, #107
	mul r4, r14, r4
	mov r4, r4, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r12, r0, r4
	; r12 = clamp(r12)
	cmp r12, r11		; #32767
	movgt r12, r11	; #32767
	cmn r12, r11		; #-32768
	mvnlt r12, r11	; #-32768
	str r12, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #809
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*10]
	; r12 = vol(r12, 13)
	mov r14, #13
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r0, r5, r12
	sub r9, r9, #2048*4*7
	; v1 = clamp(v1)
	cmp r0, r11		; #32767
	movgt r0, r11	; #32767
	cmn r0, r11		; #-32768
	mvnlt r0, r11	; #-32768

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*2]
	cmp r7, r4
	blt Inst3Loop

;----------------------------------------------------------------------------
; Instrument 4 - 'amigahub-kick'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst4Loop:
	; v1 = imported_sample(smp,2);
	mov r0, r7
	ldr r6, [r10, #AK_EXTSMPADDR+4*2]
	ldr r4, [r10, #AK_EXTSMPLEN+4*2]
	cmp r0, r4
	movge r0, #0
	ldrltb r0, [r6, r0]
	mov r0, r0, asl #24
	mov r0, r0, asr #16

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*3]
	cmp r7, r4
	blt Inst4Loop

;----------------------------------------------------------------------------
; Instrument 5 - 'amigahub_hat+bell'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst5Loop:
	; v1 = clone(smp,0, 0);
	mov r0, r7
	ldr r6, [r10, #AK_SMPADDR+4*0]
	ldr r4, [r10, #AK_SMPLEN+4*0]
	cmp r0, r4
	movge r0, #0
	ldrltb r0, [r6, r0]
	mov r0, r0, asl #24
	mov r0, r0, asr #16

	; v1 = cmb_flt_n(1, v1, 73, 96, 99);
	ldr r6, [r10, #AK_OPINSTANCE+4*0]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 96)
	mov r14, #96
	mul r4, r14, r4
	mov r4, r4, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r0, r0, r4
	; v1 = clamp(v1)
	cmp r0, r11		; #32767
	movgt r0, r11	; #32767
	cmn r0, r11		; #-32768
	mvnlt r0, r11	; #-32768
	str r0, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #73
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*0]
	; v1 = vol(v1, 99)
	mov r14, #99
	mul r0, r14, r0
	mov r0, r0, asr #7

	; v1 = sv_flt_n(2, v1, 17, 0, 1);
	ldr r4, [r10, #AK_OPINSTANCE+4*(1+AK_LPF)]
	ldr r5, [r10, #AK_OPINSTANCE+4*(1+AK_HPF)]
	ldr r6, [r10, #AK_OPINSTANCE+4*(1+AK_BPF)]
	mov r14, r6, asr #7
	mov r12, #17
	mla r4, r14, r12, r4
	; r4 = clamp(r4)
	cmp r4, r11		; #32767
	movgt r4, r11	; #32767
	cmn r4, r11		; #-32768
	mvnlt r4, r11	; #-32768
	str r4, [r10, #AK_OPINSTANCE+4*(1+AK_LPF)]
	mov r12, #0
	mul r14, r12, r14
	mov r12, r0
	sub r12, r12, r4
	sub r5, r12, r14
	; r5 = clamp(r5)
	cmp r5, r11		; #32767
	movgt r5, r11	; #32767
	cmn r5, r11		; #-32768
	mvnlt r5, r11	; #-32768
	str r5, [r10, #AK_OPINSTANCE+4*(1+AK_HPF)]
	mov r14, r5, asr #7
	mov r12, #17
	mla r6, r12, r14, r6
	; r6 = clamp(r6)
	cmp r6, r11		; #32767
	movgt r6, r11	; #32767
	cmn r6, r11		; #-32768
	mvnlt r6, r11	; #-32768
	str r6, [r10, #AK_OPINSTANCE+4*(1+AK_BPF)]
	mov r0, r5

	; v1 = sv_flt_n(3, v1, 17, 0, 1);
	ldr r4, [r10, #AK_OPINSTANCE+4*(4+AK_LPF)]
	ldr r5, [r10, #AK_OPINSTANCE+4*(4+AK_HPF)]
	ldr r6, [r10, #AK_OPINSTANCE+4*(4+AK_BPF)]
	mov r14, r6, asr #7
	mov r12, #17
	mla r4, r14, r12, r4
	; r4 = clamp(r4)
	cmp r4, r11		; #32767
	movgt r4, r11	; #32767
	cmn r4, r11		; #-32768
	mvnlt r4, r11	; #-32768
	str r4, [r10, #AK_OPINSTANCE+4*(4+AK_LPF)]
	mov r12, #0
	mul r14, r12, r14
	mov r12, r0
	sub r12, r12, r4
	sub r5, r12, r14
	; r5 = clamp(r5)
	cmp r5, r11		; #32767
	movgt r5, r11	; #32767
	cmn r5, r11		; #-32768
	mvnlt r5, r11	; #-32768
	str r5, [r10, #AK_OPINSTANCE+4*(4+AK_HPF)]
	mov r14, r5, asr #7
	mov r12, #17
	mla r6, r12, r14, r6
	; r6 = clamp(r6)
	cmp r6, r11		; #32767
	movgt r6, r11	; #32767
	cmn r6, r11		; #-32768
	mvnlt r6, r11	; #-32768
	str r6, [r10, #AK_OPINSTANCE+4*(4+AK_BPF)]
	mov r0, r5

	; v2 = envd(4, 6, 0, 50);
	mov r4, #6553
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	movle r6, #0
	mov r1, r6
	; v2 = vol(v2, 50)
	mov r14, #50
	mul r1, r14, r1
	mov r1, r1, asr #7

	; v1 = mul(v1, v2);
	mul r0, r1, r0
	mov r0, r0, asr #15

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*4]
	cmp r7, r4
	blt Inst5Loop

;----------------------------------------------------------------------------
; Instrument 6 - 'amigahub-snare1'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst6Loop:
	; v1 = imported_sample(smp,3);
	mov r0, r7
	ldr r6, [r10, #AK_EXTSMPADDR+4*3]
	ldr r4, [r10, #AK_EXTSMPLEN+4*3]
	cmp r0, r4
	movge r0, #0
	ldrltb r0, [r6, r0]
	mov r0, r0, asl #24
	mov r0, r0, asr #16

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*5]
	cmp r7, r4
	blt Inst6Loop

;----------------------------------------------------------------------------
; Instrument 7 - 'amigahub-snare2'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst7Loop:
	; v1 = imported_sample(smp,4);
	mov r0, r7
	ldr r6, [r10, #AK_EXTSMPADDR+4*4]
	ldr r4, [r10, #AK_EXTSMPLEN+4*4]
	cmp r0, r4
	movge r0, #0
	ldrltb r0, [r6, r0]
	mov r0, r0, asl #24
	mov r0, r0, asr #16

	; v1 = reverb(v1, 82, 16);
	ldr r6, [r10, #AK_OPINSTANCE+4*0]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 82)
	mov r14, #82
	mul r4, r14, r4
	mov r4, r4, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r12, r0, r4
	; r12 = clamp(r12)
	cmp r12, r11		; #32767
	movgt r12, r11	; #32767
	cmn r12, r11		; #-32768
	mvnlt r12, r11	; #-32768
	str r12, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #557
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*0]
	; r12 = vol(r12, 16)
	mov r12, r12, asr #3	; val<<4>>7
	mov r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*1]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 82)
	mov r14, #82
	mul r4, r14, r4
	mov r4, r4, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r12, r0, r4
	; r12 = clamp(r12)
	cmp r12, r11		; #32767
	movgt r12, r11	; #32767
	cmn r12, r11		; #-32768
	mvnlt r12, r11	; #-32768
	str r12, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #593
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*1]
	; r12 = vol(r12, 16)
	mov r12, r12, asr #3	; val<<4>>7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*2]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 82)
	mov r14, #82
	mul r4, r14, r4
	mov r4, r4, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r12, r0, r4
	; r12 = clamp(r12)
	cmp r12, r11		; #32767
	movgt r12, r11	; #32767
	cmn r12, r11		; #-32768
	mvnlt r12, r11	; #-32768
	str r12, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #641
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*2]
	; r12 = vol(r12, 16)
	mov r12, r12, asr #3	; val<<4>>7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*3]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 82)
	mov r14, #82
	mul r4, r14, r4
	mov r4, r4, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r12, r0, r4
	; r12 = clamp(r12)
	cmp r12, r11		; #32767
	movgt r12, r11	; #32767
	cmn r12, r11		; #-32768
	mvnlt r12, r11	; #-32768
	str r12, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #677
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*3]
	; r12 = vol(r12, 16)
	mov r12, r12, asr #3	; val<<4>>7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*4]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 82)
	mov r14, #82
	mul r4, r14, r4
	mov r4, r4, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r12, r0, r4
	; r12 = clamp(r12)
	cmp r12, r11		; #32767
	movgt r12, r11	; #32767
	cmn r12, r11		; #-32768
	mvnlt r12, r11	; #-32768
	str r12, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #709
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*4]
	; r12 = vol(r12, 16)
	mov r12, r12, asr #3	; val<<4>>7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*5]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 82)
	mov r14, #82
	mul r4, r14, r4
	mov r4, r4, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r12, r0, r4
	; r12 = clamp(r12)
	cmp r12, r11		; #32767
	movgt r12, r11	; #32767
	cmn r12, r11		; #-32768
	mvnlt r12, r11	; #-32768
	str r12, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #743
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*5]
	; r12 = vol(r12, 16)
	mov r12, r12, asr #3	; val<<4>>7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*6]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 82)
	mov r14, #82
	mul r4, r14, r4
	mov r4, r4, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r12, r0, r4
	; r12 = clamp(r12)
	cmp r12, r11		; #32767
	movgt r12, r11	; #32767
	cmn r12, r11		; #-32768
	mvnlt r12, r11	; #-32768
	str r12, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #787
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*6]
	; r12 = vol(r12, 16)
	mov r12, r12, asr #3	; val<<4>>7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*7]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 82)
	mov r14, #82
	mul r4, r14, r4
	mov r4, r4, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r12, r0, r4
	; r12 = clamp(r12)
	cmp r12, r11		; #32767
	movgt r12, r11	; #32767
	cmn r12, r11		; #-32768
	mvnlt r12, r11	; #-32768
	str r12, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #809
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*7]
	; r12 = vol(r12, 16)
	mov r12, r12, asr #3	; val<<4>>7
	add r0, r5, r12
	sub r9, r9, #2048*4*7
	; v1 = clamp(v1)
	cmp r0, r11		; #32767
	movgt r0, r11	; #32767
	cmn r0, r11		; #-32768
	mvnlt r0, r11	; #-32768

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*6]
	cmp r7, r4
	blt Inst7Loop

;----------------------------------------------------------------------------
; Instrument 8 - 'amigahub_snare3'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst8Loop:
	; v1 = imported_sample(smp,4);
	mov r0, r7
	ldr r6, [r10, #AK_EXTSMPADDR+4*4]
	ldr r4, [r10, #AK_EXTSMPLEN+4*4]
	cmp r0, r4
	movge r0, #0
	ldrltb r0, [r6, r0]
	mov r0, r0, asl #24
	mov r0, r0, asr #16

	; v1 = sv_flt_n(1, v1, 37, 55, 2);
	ldr r4, [r10, #AK_OPINSTANCE+4*(0+AK_LPF)]
	ldr r5, [r10, #AK_OPINSTANCE+4*(0+AK_HPF)]
	ldr r6, [r10, #AK_OPINSTANCE+4*(0+AK_BPF)]
	mov r14, r6, asr #7
	mov r12, #37
	mla r4, r14, r12, r4
	; r4 = clamp(r4)
	cmp r4, r11		; #32767
	movgt r4, r11	; #32767
	cmn r4, r11		; #-32768
	mvnlt r4, r11	; #-32768
	str r4, [r10, #AK_OPINSTANCE+4*(0+AK_LPF)]
	mov r12, #55
	mul r14, r12, r14
	mov r12, r0
	sub r12, r12, r4
	sub r5, r12, r14
	; r5 = clamp(r5)
	cmp r5, r11		; #32767
	movgt r5, r11	; #32767
	cmn r5, r11		; #-32768
	mvnlt r5, r11	; #-32768
	str r5, [r10, #AK_OPINSTANCE+4*(0+AK_HPF)]
	mov r14, r5, asr #7
	mov r12, #37
	mla r6, r12, r14, r6
	; r6 = clamp(r6)
	cmp r6, r11		; #32767
	movgt r6, r11	; #32767
	cmn r6, r11		; #-32768
	mvnlt r6, r11	; #-32768
	str r6, [r10, #AK_OPINSTANCE+4*(0+AK_BPF)]
	mov r0, r6

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*7]
	cmp r7, r4
	blt Inst8Loop

;----------------------------------------------------------------------------
; Instrument 9 - 'amigahub_snare_attack'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst9Loop:
	; v1 = imported_sample(smp,3);
	mov r0, r7
	ldr r6, [r10, #AK_EXTSMPADDR+4*3]
	ldr r4, [r10, #AK_EXTSMPLEN+4*3]
	cmp r0, r4
	movge r0, #0
	ldrltb r0, [r6, r0]
	mov r0, r0, asl #24
	mov r0, r0, asr #16

	; v1 = vol(v1, 70);
	; v1 = vol(v1, 70)
	mov r14, #70
	mul r0, r14, r0
	mov r0, r0, asr #7

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*8]
	cmp r7, r4
	blt Inst9Loop

;----------------------------------------------------------------------------
; Instrument 10 - 'amigahub_hat+bell+reverb'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst10Loop:
	; v1 = clone(smp,4, 0);
	mov r0, r7
	ldr r6, [r10, #AK_SMPADDR+4*4]
	ldr r4, [r10, #AK_SMPLEN+4*4]
	cmp r0, r4
	movge r0, #0
	ldrltb r0, [r6, r0]
	mov r0, r0, asl #24
	mov r0, r0, asr #16

	; v1 = reverb(v1, 99, 24);
	ldr r6, [r10, #AK_OPINSTANCE+4*0]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 99)
	mov r14, #99
	mul r4, r14, r4
	mov r4, r4, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r12, r0, r4
	; r12 = clamp(r12)
	cmp r12, r11		; #32767
	movgt r12, r11	; #32767
	cmn r12, r11		; #-32768
	mvnlt r12, r11	; #-32768
	str r12, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #557
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*0]
	; r12 = vol(r12, 24)
	mov r14, #24
	mul r12, r14, r12
	mov r12, r12, asr #7
	mov r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*1]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 99)
	mov r14, #99
	mul r4, r14, r4
	mov r4, r4, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r12, r0, r4
	; r12 = clamp(r12)
	cmp r12, r11		; #32767
	movgt r12, r11	; #32767
	cmn r12, r11		; #-32768
	mvnlt r12, r11	; #-32768
	str r12, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #593
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*1]
	; r12 = vol(r12, 24)
	mov r14, #24
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*2]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 99)
	mov r14, #99
	mul r4, r14, r4
	mov r4, r4, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r12, r0, r4
	; r12 = clamp(r12)
	cmp r12, r11		; #32767
	movgt r12, r11	; #32767
	cmn r12, r11		; #-32768
	mvnlt r12, r11	; #-32768
	str r12, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #641
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*2]
	; r12 = vol(r12, 24)
	mov r14, #24
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*3]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 99)
	mov r14, #99
	mul r4, r14, r4
	mov r4, r4, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r12, r0, r4
	; r12 = clamp(r12)
	cmp r12, r11		; #32767
	movgt r12, r11	; #32767
	cmn r12, r11		; #-32768
	mvnlt r12, r11	; #-32768
	str r12, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #677
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*3]
	; r12 = vol(r12, 24)
	mov r14, #24
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*4]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 99)
	mov r14, #99
	mul r4, r14, r4
	mov r4, r4, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r12, r0, r4
	; r12 = clamp(r12)
	cmp r12, r11		; #32767
	movgt r12, r11	; #32767
	cmn r12, r11		; #-32768
	mvnlt r12, r11	; #-32768
	str r12, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #709
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*4]
	; r12 = vol(r12, 24)
	mov r14, #24
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*5]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 99)
	mov r14, #99
	mul r4, r14, r4
	mov r4, r4, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r12, r0, r4
	; r12 = clamp(r12)
	cmp r12, r11		; #32767
	movgt r12, r11	; #32767
	cmn r12, r11		; #-32768
	mvnlt r12, r11	; #-32768
	str r12, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #743
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*5]
	; r12 = vol(r12, 24)
	mov r14, #24
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*6]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 99)
	mov r14, #99
	mul r4, r14, r4
	mov r4, r4, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r12, r0, r4
	; r12 = clamp(r12)
	cmp r12, r11		; #32767
	movgt r12, r11	; #32767
	cmn r12, r11		; #-32768
	mvnlt r12, r11	; #-32768
	str r12, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #787
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*6]
	; r12 = vol(r12, 24)
	mov r14, #24
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*7]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 99)
	mov r14, #99
	mul r4, r14, r4
	mov r4, r4, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r12, r0, r4
	; r12 = clamp(r12)
	cmp r12, r11		; #32767
	movgt r12, r11	; #32767
	cmn r12, r11		; #-32768
	mvnlt r12, r11	; #-32768
	str r12, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #809
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*7]
	; r12 = vol(r12, 24)
	mov r14, #24
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r0, r5, r12
	sub r9, r9, #2048*4*7
	; v1 = clamp(v1)
	cmp r0, r11		; #32767
	movgt r0, r11	; #32767
	cmn r0, r11		; #-32768
	mvnlt r0, r11	; #-32768

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*9]
	cmp r7, r4
	blt Inst10Loop

;----------------------------------------------------------------------------
; Instrument 10 - Loop Generator (Offset: 3952 Length: 3952)
;----------------------------------------------------------------------------

	mov r7, #3952
	ldr r6, [r10, #AK_SMPADDR+4*9]
	add r6, r6, #3952	; src1
	sub r4, r6, r7	; src2
	mov r0, r11, lsl #8	; 32767<<8
	mov r1, r7
	bl divide
	mov r5, r0	; delta = divs.w(32767<<8,repeat_length)
	mov r14, #0	; rampup
	mov r12, r11, lsl #8	; rampdown
LoopGen_9:
	mov r3, r14, lsr #8
	mov r2, r12, lsr #8
	ldrb r1, [r6]
	mov r1, r1, asl #24
	mov r1, r1, asr #24
	ldrb r0, [r4], #1
	mov r0, r0, asl #24
	mov r0, r0, asr #24
	mul r0, r3, r0
	mla r0, r1, r2, r0
	mov r0, r0, lsr #15
	strb r0, [r6], #1
	add r14, r14, r5
	sub r12, r12, r5
	; TODO: Fine progress.
	subs r7, r7, #1
	bne LoopGen_9

;----------------------------------------------------------------------------
; Instrument 11 - 'amigahub_organ_lead'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst11Loop:
	; v1 = imported_sample(smp,6);
	mov r0, r7
	ldr r6, [r10, #AK_EXTSMPADDR+4*6]
	ldr r4, [r10, #AK_EXTSMPLEN+4*6]
	cmp r0, r4
	movge r0, #0
	ldrltb r0, [r6, r0]
	mov r0, r0, asl #24
	mov r0, r0, asr #16

	; v2 = envd(1, 11, 0, 127);
	mov r4, #2048
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	movle r6, #0
	mov r1, r6
	; v2 = vol(v2, 127)
	mov r14, #127
	mul r1, r14, r1
	mov r1, r1, asr #7

	; v1 = mul(v1, v2);
	mul r0, r1, r0
	mov r0, r0, asr #15

	; v1 = reverb(v1, 126, 60);
	ldr r6, [r10, #AK_OPINSTANCE+4*0]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 126)
	mov r14, #126
	mul r4, r14, r4
	mov r4, r4, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r12, r0, r4
	; r12 = clamp(r12)
	cmp r12, r11		; #32767
	movgt r12, r11	; #32767
	cmn r12, r11		; #-32768
	mvnlt r12, r11	; #-32768
	str r12, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #557
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*0]
	; r12 = vol(r12, 60)
	mov r14, #60
	mul r12, r14, r12
	mov r12, r12, asr #7
	mov r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*1]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 126)
	mov r14, #126
	mul r4, r14, r4
	mov r4, r4, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r12, r0, r4
	; r12 = clamp(r12)
	cmp r12, r11		; #32767
	movgt r12, r11	; #32767
	cmn r12, r11		; #-32768
	mvnlt r12, r11	; #-32768
	str r12, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #593
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*1]
	; r12 = vol(r12, 60)
	mov r14, #60
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*2]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 126)
	mov r14, #126
	mul r4, r14, r4
	mov r4, r4, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r12, r0, r4
	; r12 = clamp(r12)
	cmp r12, r11		; #32767
	movgt r12, r11	; #32767
	cmn r12, r11		; #-32768
	mvnlt r12, r11	; #-32768
	str r12, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #641
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*2]
	; r12 = vol(r12, 60)
	mov r14, #60
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*3]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 126)
	mov r14, #126
	mul r4, r14, r4
	mov r4, r4, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r12, r0, r4
	; r12 = clamp(r12)
	cmp r12, r11		; #32767
	movgt r12, r11	; #32767
	cmn r12, r11		; #-32768
	mvnlt r12, r11	; #-32768
	str r12, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #677
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*3]
	; r12 = vol(r12, 60)
	mov r14, #60
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*4]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 126)
	mov r14, #126
	mul r4, r14, r4
	mov r4, r4, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r12, r0, r4
	; r12 = clamp(r12)
	cmp r12, r11		; #32767
	movgt r12, r11	; #32767
	cmn r12, r11		; #-32768
	mvnlt r12, r11	; #-32768
	str r12, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #709
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*4]
	; r12 = vol(r12, 60)
	mov r14, #60
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*5]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 126)
	mov r14, #126
	mul r4, r14, r4
	mov r4, r4, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r12, r0, r4
	; r12 = clamp(r12)
	cmp r12, r11		; #32767
	movgt r12, r11	; #32767
	cmn r12, r11		; #-32768
	mvnlt r12, r11	; #-32768
	str r12, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #743
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*5]
	; r12 = vol(r12, 60)
	mov r14, #60
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*6]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 126)
	mov r14, #126
	mul r4, r14, r4
	mov r4, r4, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r12, r0, r4
	; r12 = clamp(r12)
	cmp r12, r11		; #32767
	movgt r12, r11	; #32767
	cmn r12, r11		; #-32768
	mvnlt r12, r11	; #-32768
	str r12, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #787
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*6]
	; r12 = vol(r12, 60)
	mov r14, #60
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*7]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 126)
	mov r14, #126
	mul r4, r14, r4
	mov r4, r4, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r12, r0, r4
	; r12 = clamp(r12)
	cmp r12, r11		; #32767
	movgt r12, r11	; #32767
	cmn r12, r11		; #-32768
	mvnlt r12, r11	; #-32768
	str r12, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #809
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*7]
	; r12 = vol(r12, 60)
	mov r14, #60
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r0, r5, r12
	sub r9, r9, #2048*4*7
	; v1 = clamp(v1)
	cmp r0, r11		; #32767
	movgt r0, r11	; #32767
	cmn r0, r11		; #-32768
	mvnlt r0, r11	; #-32768

	; v2 = osc_sine(4, 900, 24);
	ldr r6, [r10, #AK_OPINSTANCE+4*8]
	add r6, r6, #900
	str r6, [r10, #AK_OPINSTANCE+4*8]
	sub r6, r6, #16384
	mov r6, r6, asl #16
	mov r6, r6, asr #16	; Sign extend word to long.
	movs r4, r6
	rsblt r4, r4, #0
	sub r4, r11, r4	; #32767
	mul r4, r6, r4
	mov r4, r4, asr #16
	mov r1, r4, asl #3
	; v2 = vol(v2, 24)
	mov r14, #24
	mul r1, r14, r1
	mov r1, r1, asr #7

	; v1 = add(v1, v2);
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	mov r1, r1, asl #16
	mov r1, r1, asr #16	; Sign extend word to long.
	add r0, r0, r1
	; v1 = clamp(v1)
	cmp r0, r11		; #32767
	movgt r0, r11	; #32767
	cmn r0, r11		; #-32768
	mvnlt r0, r11	; #-32768

	; v2 = osc_sine(6, 1788, 16);
	ldr r6, [r10, #AK_OPINSTANCE+4*9]
	add r6, r6, #1788
	str r6, [r10, #AK_OPINSTANCE+4*9]
	sub r6, r6, #16384
	mov r6, r6, asl #16
	mov r6, r6, asr #16	; Sign extend word to long.
	movs r4, r6
	rsblt r4, r4, #0
	sub r4, r11, r4	; #32767
	mul r4, r6, r4
	mov r4, r4, asr #16
	mov r1, r4, asl #3
	; v2 = vol(v2, 16)
	mov r1, r1, asr #3	; val<<4>>7

	; v1 = add(v1, v2);
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	mov r1, r1, asl #16
	mov r1, r1, asr #16	; Sign extend word to long.
	add r0, r0, r1
	; v1 = clamp(v1)
	cmp r0, r11		; #32767
	movgt r0, r11	; #32767
	cmn r0, r11		; #-32768
	mvnlt r0, r11	; #-32768

	; v1 = vol(v1, 110);
	; v1 = vol(v1, 110)
	mov r14, #110
	mul r0, r14, r0
	mov r0, r0, asr #7

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*10]
	cmp r7, r4
	blt Inst11Loop

;----------------------------------------------------------------------------
; Instrument 11 - Loop Generator (Offset: 14848 Length: 14848)
;----------------------------------------------------------------------------

	mov r7, #14848
	ldr r6, [r10, #AK_SMPADDR+4*10]
	add r6, r6, #14848	; src1
	sub r4, r6, r7	; src2
	mov r0, r11, lsl #8	; 32767<<8
	mov r1, r7
	bl divide
	mov r5, r0	; delta = divs.w(32767<<8,repeat_length)
	mov r14, #0	; rampup
	mov r12, r11, lsl #8	; rampdown
LoopGen_10:
	mov r3, r14, lsr #8
	mov r2, r12, lsr #8
	ldrb r1, [r6]
	mov r1, r1, asl #24
	mov r1, r1, asr #24
	ldrb r0, [r4], #1
	mov r0, r0, asl #24
	mov r0, r0, asr #24
	mul r0, r3, r0
	mla r0, r1, r2, r0
	mov r0, r0, lsr #15
	strb r0, [r6], #1
	add r14, r14, r5
	sub r12, r12, r5
	; TODO: Fine progress.
	subs r7, r7, #1
	bne LoopGen_10

;----------------------------------------------------------------------------
; Instrument 12 - 'amigahub_chord1'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst12Loop:
	; v1 = osc_sine(0, 4, 54);
	ldr r6, [r10, #AK_OPINSTANCE+4*0]
	add r6, r6, #4
	str r6, [r10, #AK_OPINSTANCE+4*0]
	sub r6, r6, #16384
	mov r6, r6, asl #16
	mov r6, r6, asr #16	; Sign extend word to long.
	movs r4, r6
	rsblt r4, r4, #0
	sub r4, r11, r4	; #32767
	mul r4, r6, r4
	mov r4, r4, asr #16
	mov r0, r4, asl #3
	; v1 = vol(v1, 54)
	mov r14, #54
	mul r0, r14, r0
	mov r0, r0, asr #7

	; v1 = ctrl(v1);
	mov r0, r0, asr #9
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r0, r0, #64

	; v1 = chordgen(2, 10, 3, 5, 10, v1);
	ldr r4, [r10, #AK_SMPADDR+4*10]
	ldr r12, [r10, #AK_SMPLEN+4*10]
	ldrb r6, [r4, r7]
	mov r6, r6, asl #24
	mov r6, r6, asr #17
	add r4, r4, r0
	sub r12, r12, r0
	ldr r5, [r10, #AK_OPINSTANCE+4*(1+AK_CHORD1)]
	cmp r12, r5, lsr #16
	ldrgeb r14, [r4, r5, lsr #16]
	movlt r14, #0
	add r5, r5, #77824
	str r5, [r10, #AK_OPINSTANCE+4*(1+AK_CHORD1)]
	mov r14, r14, asl #24
	add r6, r6, r14, asr #17
	ldr r5, [r10, #AK_OPINSTANCE+4*(1+AK_CHORD2)]
	cmp r12, r5, lsr #16
	ldrgeb r14, [r4, r5, lsr #16]
	movlt r14, #0
	add r5, r5, #87552
	str r5, [r10, #AK_OPINSTANCE+4*(1+AK_CHORD2)]
	mov r14, r14, asl #24
	add r6, r6, r14, asr #17
	ldr r5, [r10, #AK_OPINSTANCE+4*(1+AK_CHORD3)]
	cmp r12, r5, lsr #15
	ldrgeb r14, [r4, r5, lsr #15]
	movlt r14, #0
	add r5, r5, #58368
	str r5, [r10, #AK_OPINSTANCE+4*(1+AK_CHORD3)]
	mov r14, r14, asl #24
	add r6, r6, r14, asr #17
	mov r0, r6
	; v1 = clamp(v1)
	cmp r0, r11		; #32767
	movgt r0, r11	; #32767
	cmn r0, r11		; #-32768
	mvnlt r0, r11	; #-32768

	; v2 = osc_tri(3, 450, 52);
	ldr r6, [r10, #AK_OPINSTANCE+4*4]
	add r6, r6, #450
	mov r6, r6, asl #16
	mov r6, r6, asr #16	; Sign extend word to long.
	str r6, [r10, #AK_OPINSTANCE+4*4]
	cmp r6, #0
	mvnmi r6, r6
	sub r6, r6, #16384
	mov r1, r6, asl #1
	; v2 = vol(v2, 52)
	mov r14, #52
	mul r1, r14, r1
	mov r1, r1, asr #7

	; v1 = add(v1, v2);
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	mov r1, r1, asl #16
	mov r1, r1, asr #16	; Sign extend word to long.
	add r0, r0, r1
	; v1 = clamp(v1)
	cmp r0, r11		; #32767
	movgt r0, r11	; #32767
	cmn r0, r11		; #-32768
	mvnlt r0, r11	; #-32768

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*11]
	cmp r7, r4
	blt Inst12Loop

;----------------------------------------------------------------------------
; Instrument 12 - Loop Generator (Offset: 8192 Length: 8192)
;----------------------------------------------------------------------------

	mov r7, #8192
	ldr r6, [r10, #AK_SMPADDR+4*11]
	add r6, r6, #8192	; src1
	sub r4, r6, r7	; src2
	mov r0, r11, lsl #8	; 32767<<8
	mov r1, r7
	bl divide
	mov r5, r0	; delta = divs.w(32767<<8,repeat_length)
	mov r14, #0	; rampup
	mov r12, r11, lsl #8	; rampdown
LoopGen_11:
	mov r3, r14, lsr #8
	mov r2, r12, lsr #8
	ldrb r1, [r6]
	mov r1, r1, asl #24
	mov r1, r1, asr #24
	ldrb r0, [r4], #1
	mov r0, r0, asl #24
	mov r0, r0, asr #24
	mul r0, r3, r0
	mla r0, r1, r2, r0
	mov r0, r0, lsr #15
	strb r0, [r6], #1
	add r14, r14, r5
	sub r12, r12, r5
	; TODO: Fine progress.
	subs r7, r7, #1
	bne LoopGen_11

;----------------------------------------------------------------------------
; Instrument 13 - 'amigahub_chord2'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst13Loop:
	; v1 = chordgen(0, 10, 3, 7, 10, 0);
	ldr r4, [r10, #AK_SMPADDR+4*10]
	ldr r12, [r10, #AK_SMPLEN+4*10]
	ldrb r6, [r4, r7]
	mov r6, r6, asl #24
	mov r6, r6, asr #17
	add r4, r4, #0
	sub r12, r12, #0
	ldr r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD1)]
	cmp r12, r5, lsr #16
	ldrgeb r14, [r4, r5, lsr #16]
	movlt r14, #0
	add r5, r5, #77824
	str r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD1)]
	mov r14, r14, asl #24
	add r6, r6, r14, asr #17
	ldr r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD2)]
	cmp r12, r5, lsr #16
	ldrgeb r14, [r4, r5, lsr #16]
	movlt r14, #0
	add r5, r5, #98048
	str r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD2)]
	mov r14, r14, asl #24
	add r6, r6, r14, asr #17
	ldr r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD3)]
	cmp r12, r5, lsr #15
	ldrgeb r14, [r4, r5, lsr #15]
	movlt r14, #0
	add r5, r5, #58368
	str r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD3)]
	mov r14, r14, asl #24
	add r6, r6, r14, asr #17
	mov r0, r6
	; v1 = clamp(v1)
	cmp r0, r11		; #32767
	movgt r0, r11	; #32767
	cmn r0, r11		; #-32768
	mvnlt r0, r11	; #-32768

	; v2 = osc_tri(1, 337, 52);
	ldr r6, [r10, #AK_OPINSTANCE+4*3]
	add r6, r6, #337
	mov r6, r6, asl #16
	mov r6, r6, asr #16	; Sign extend word to long.
	str r6, [r10, #AK_OPINSTANCE+4*3]
	cmp r6, #0
	mvnmi r6, r6
	sub r6, r6, #16384
	mov r1, r6, asl #1
	; v2 = vol(v2, 52)
	mov r14, #52
	mul r1, r14, r1
	mov r1, r1, asr #7

	; v1 = add(v1, v2);
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	mov r1, r1, asl #16
	mov r1, r1, asr #16	; Sign extend word to long.
	add r0, r0, r1
	; v1 = clamp(v1)
	cmp r0, r11		; #32767
	movgt r0, r11	; #32767
	cmn r0, r11		; #-32768
	mvnlt r0, r11	; #-32768

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*12]
	cmp r7, r4
	blt Inst13Loop

;----------------------------------------------------------------------------
; Instrument 13 - Loop Generator (Offset: 7560 Length: 6264)
;----------------------------------------------------------------------------

	mov r7, #6264
	ldr r6, [r10, #AK_SMPADDR+4*12]
	add r6, r6, #7560	; src1
	sub r4, r6, r7	; src2
	mov r0, r11, lsl #8	; 32767<<8
	mov r1, r7
	bl divide
	mov r5, r0	; delta = divs.w(32767<<8,repeat_length)
	mov r14, #0	; rampup
	mov r12, r11, lsl #8	; rampdown
LoopGen_12:
	mov r3, r14, lsr #8
	mov r2, r12, lsr #8
	ldrb r1, [r6]
	mov r1, r1, asl #24
	mov r1, r1, asr #24
	ldrb r0, [r4], #1
	mov r0, r0, asl #24
	mov r0, r0, asr #24
	mul r0, r3, r0
	mla r0, r1, r2, r0
	mov r0, r0, lsr #15
	strb r0, [r6], #1
	add r14, r14, r5
	sub r12, r12, r5
	; TODO: Fine progress.
	subs r7, r7, #1
	bne LoopGen_12

;----------------------------------------------------------------------------
; Instrument 14 - 'amigahub_chord3'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst14Loop:
	; v1 = chordgen(0, 10, 3, 7, 8, 0);
	ldr r4, [r10, #AK_SMPADDR+4*10]
	ldr r12, [r10, #AK_SMPLEN+4*10]
	ldrb r6, [r4, r7]
	mov r6, r6, asl #24
	mov r6, r6, asr #17
	add r4, r4, #0
	sub r12, r12, #0
	ldr r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD1)]
	cmp r12, r5, lsr #16
	ldrgeb r14, [r4, r5, lsr #16]
	movlt r14, #0
	add r5, r5, #77824
	str r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD1)]
	mov r14, r14, asl #24
	add r6, r6, r14, asr #17
	ldr r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD2)]
	cmp r12, r5, lsr #16
	ldrgeb r14, [r4, r5, lsr #16]
	movlt r14, #0
	add r5, r5, #98048
	str r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD2)]
	mov r14, r14, asl #24
	add r6, r6, r14, asr #17
	ldr r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD3)]
	cmp r12, r5, lsr #15
	ldrgeb r14, [r4, r5, lsr #15]
	movlt r14, #0
	add r5, r5, #51968
	str r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD3)]
	mov r14, r14, asl #24
	add r6, r6, r14, asr #17
	mov r0, r6
	; v1 = clamp(v1)
	cmp r0, r11		; #32767
	movgt r0, r11	; #32767
	cmn r0, r11		; #-32768
	mvnlt r0, r11	; #-32768

	; v2 = osc_tri(1, 360, 52);
	ldr r6, [r10, #AK_OPINSTANCE+4*3]
	add r6, r6, #360
	mov r6, r6, asl #16
	mov r6, r6, asr #16	; Sign extend word to long.
	str r6, [r10, #AK_OPINSTANCE+4*3]
	cmp r6, #0
	mvnmi r6, r6
	sub r6, r6, #16384
	mov r1, r6, asl #1
	; v2 = vol(v2, 52)
	mov r14, #52
	mul r1, r14, r1
	mov r1, r1, asr #7

	; v1 = add(v1, v2);
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	mov r1, r1, asl #16
	mov r1, r1, asr #16	; Sign extend word to long.
	add r0, r0, r1
	; v1 = clamp(v1)
	cmp r0, r11		; #32767
	movgt r0, r11	; #32767
	cmn r0, r11		; #-32768
	mvnlt r0, r11	; #-32768

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*13]
	cmp r7, r4
	blt Inst14Loop

;----------------------------------------------------------------------------
; Instrument 14 - Loop Generator (Offset: 6720 Length: 6720)
;----------------------------------------------------------------------------

	mov r7, #6720
	ldr r6, [r10, #AK_SMPADDR+4*13]
	add r6, r6, #6720	; src1
	sub r4, r6, r7	; src2
	mov r0, r11, lsl #8	; 32767<<8
	mov r1, r7
	bl divide
	mov r5, r0	; delta = divs.w(32767<<8,repeat_length)
	mov r14, #0	; rampup
	mov r12, r11, lsl #8	; rampdown
LoopGen_13:
	mov r3, r14, lsr #8
	mov r2, r12, lsr #8
	ldrb r1, [r6]
	mov r1, r1, asl #24
	mov r1, r1, asr #24
	ldrb r0, [r4], #1
	mov r0, r0, asl #24
	mov r0, r0, asr #24
	mul r0, r3, r0
	mla r0, r1, r2, r0
	mov r0, r0, lsr #15
	strb r0, [r6], #1
	add r14, r14, r5
	sub r12, r12, r5
	; TODO: Fine progress.
	subs r7, r7, #1
	bne LoopGen_13

;----------------------------------------------------------------------------
; Instrument 15 - 'amigahub_chord4'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst15Loop:
	; v1 = chordgen(0, 10, 2, 5, 10, 0);
	ldr r4, [r10, #AK_SMPADDR+4*10]
	ldr r12, [r10, #AK_SMPLEN+4*10]
	ldrb r6, [r4, r7]
	mov r6, r6, asl #24
	mov r6, r6, asr #17
	add r4, r4, #0
	sub r12, r12, #0
	ldr r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD1)]
	cmp r12, r5, lsr #16
	ldrgeb r14, [r4, r5, lsr #16]
	movlt r14, #0
	add r5, r5, #73472
	str r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD1)]
	mov r14, r14, asl #24
	add r6, r6, r14, asr #17
	ldr r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD2)]
	cmp r12, r5, lsr #16
	ldrgeb r14, [r4, r5, lsr #16]
	movlt r14, #0
	add r5, r5, #87552
	str r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD2)]
	mov r14, r14, asl #24
	add r6, r6, r14, asr #17
	ldr r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD3)]
	cmp r12, r5, lsr #15
	ldrgeb r14, [r4, r5, lsr #15]
	movlt r14, #0
	add r5, r5, #58368
	str r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD3)]
	mov r14, r14, asl #24
	add r6, r6, r14, asr #17
	mov r0, r6
	; v1 = clamp(v1)
	cmp r0, r11		; #32767
	movgt r0, r11	; #32767
	cmn r0, r11		; #-32768
	mvnlt r0, r11	; #-32768

	; v2 = osc_tri(1, 400, 52);
	ldr r6, [r10, #AK_OPINSTANCE+4*3]
	add r6, r6, #400
	mov r6, r6, asl #16
	mov r6, r6, asr #16	; Sign extend word to long.
	str r6, [r10, #AK_OPINSTANCE+4*3]
	cmp r6, #0
	mvnmi r6, r6
	sub r6, r6, #16384
	mov r1, r6, asl #1
	; v2 = vol(v2, 52)
	mov r14, #52
	mul r1, r14, r1
	mov r1, r1, asr #7

	; v1 = add(v1, v2);
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	mov r1, r1, asl #16
	mov r1, r1, asr #16	; Sign extend word to long.
	add r0, r0, r1
	; v1 = clamp(v1)
	cmp r0, r11		; #32767
	movgt r0, r11	; #32767
	cmn r0, r11		; #-32768
	mvnlt r0, r11	; #-32768

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*14]
	cmp r7, r4
	blt Inst15Loop

;----------------------------------------------------------------------------
; Instrument 15 - Loop Generator (Offset: 5248 Length: 5248)
;----------------------------------------------------------------------------

	mov r7, #5248
	ldr r6, [r10, #AK_SMPADDR+4*14]
	add r6, r6, #5248	; src1
	sub r4, r6, r7	; src2
	mov r0, r11, lsl #8	; 32767<<8
	mov r1, r7
	bl divide
	mov r5, r0	; delta = divs.w(32767<<8,repeat_length)
	mov r14, #0	; rampup
	mov r12, r11, lsl #8	; rampdown
LoopGen_14:
	mov r3, r14, lsr #8
	mov r2, r12, lsr #8
	ldrb r1, [r6]
	mov r1, r1, asl #24
	mov r1, r1, asr #24
	ldrb r0, [r4], #1
	mov r0, r0, asl #24
	mov r0, r0, asr #24
	mul r0, r3, r0
	mla r0, r1, r2, r0
	mov r0, r0, lsr #15
	strb r0, [r6], #1
	add r14, r14, r5
	sub r12, r12, r5
	; TODO: Fine progress.
	subs r7, r7, #1
	bne LoopGen_14

;----------------------------------------------------------------------------
; Instrument 16 - 'amigahub_kickbass'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst16Loop:
	; v1 = clone(smp,3, 0);
	mov r0, r7
	ldr r6, [r10, #AK_SMPADDR+4*3]
	ldr r4, [r10, #AK_SMPLEN+4*3]
	cmp r0, r4
	movge r0, #0
	ldrltb r0, [r6, r0]
	mov r0, r0, asl #24
	mov r0, r0, asr #16

	; v1 = cmb_flt_n(1, v1, 450, 87, 127);
	ldr r6, [r10, #AK_OPINSTANCE+4*0]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 87)
	mov r14, #87
	mul r4, r14, r4
	mov r4, r4, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r0, r0, r4
	; v1 = clamp(v1)
	cmp r0, r11		; #32767
	movgt r0, r11	; #32767
	cmn r0, r11		; #-32768
	mvnlt r0, r11	; #-32768
	str r0, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #450
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*0]
	; v1 = vol(v1, 127)
	mov r14, #127
	mul r0, r14, r0
	mov r0, r0, asr #7

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*15]
	cmp r7, r4
	blt Inst16Loop

;----------------------------------------------------------------------------
; Instrument 17 - 'amigahub_bass1'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst17Loop:
	; v1 = osc_saw(0, 153, 96);
	ldr r0, [r10, #AK_OPINSTANCE+4*0]
	add r0, r0, #153
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	str r0, [r10, #AK_OPINSTANCE+4*0]	
	; v1 = vol(v1, 96)
	mov r14, #96
	mul r0, r14, r0
	mov r0, r0, asr #7

	; v2 = osc_saw(1, 147, 83);
	ldr r1, [r10, #AK_OPINSTANCE+4*1]
	add r1, r1, #147
	mov r1, r1, asl #16
	mov r1, r1, asr #16	; Sign extend word to long.
	str r1, [r10, #AK_OPINSTANCE+4*1]	
	; v2 = vol(v2, 83)
	mov r14, #83
	mul r1, r14, r1
	mov r1, r1, asr #7

	; v1 = add(v1, v2);
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	mov r1, r1, asl #16
	mov r1, r1, asr #16	; Sign extend word to long.
	add r0, r0, r1
	; v1 = clamp(v1)
	cmp r0, r11		; #32767
	movgt r0, r11	; #32767
	cmn r0, r11		; #-32768
	mvnlt r0, r11	; #-32768

	; v2 = osc_pulse(3, 150, 68, 63);
	ldr r6, [r10, #AK_OPINSTANCE+4*2]
	adds r6, r6, #150
	mov r6, r6, asl #16
	mov r6, r6, asr #16	; Sign extend word to long.
	str r6, [r10, #AK_OPINSTANCE+4*2]
	mov r4, #0	; (63-63)<<9
	cmp r6, r4
	mvnlt r1, r11	; #-32768
	movge r1, r11	; #32767
	; v2 = vol(v2, 68)
	mov r14, #68
	mul r1, r14, r1
	mov r1, r1, asr #7

	; v1 = add(v1, v2);
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	mov r1, r1, asl #16
	mov r1, r1, asr #16	; Sign extend word to long.
	add r0, r0, r1
	; v1 = clamp(v1)
	cmp r0, r11		; #32767
	movgt r0, r11	; #32767
	cmn r0, r11		; #-32768
	mvnlt r0, r11	; #-32768

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*16]
	cmp r7, r4
	blt Inst17Loop

;----------------------------------------------------------------------------
; Instrument 17 - Loop Generator (Offset: 3072 Length: 3072)
;----------------------------------------------------------------------------

	mov r7, #3072
	ldr r6, [r10, #AK_SMPADDR+4*16]
	add r6, r6, #3072	; src1
	sub r4, r6, r7	; src2
	mov r0, r11, lsl #8	; 32767<<8
	mov r1, r7
	bl divide
	mov r5, r0	; delta = divs.w(32767<<8,repeat_length)
	mov r14, #0	; rampup
	mov r12, r11, lsl #8	; rampdown
LoopGen_16:
	mov r3, r14, lsr #8
	mov r2, r12, lsr #8
	ldrb r1, [r6]
	mov r1, r1, asl #24
	mov r1, r1, asr #24
	ldrb r0, [r4], #1
	mov r0, r0, asl #24
	mov r0, r0, asr #24
	mul r0, r3, r0
	mla r0, r1, r2, r0
	mov r0, r0, lsr #15
	strb r0, [r6], #1
	add r14, r14, r5
	sub r12, r12, r5
	; TODO: Fine progress.
	subs r7, r7, #1
	bne LoopGen_16

;----------------------------------------------------------------------------
; Instrument 18 - 'amigahub_bass2'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst18Loop:
	; v1 = clone(smp,16, 0);
	mov r0, r7
	ldr r6, [r10, #AK_SMPADDR+4*16]
	ldr r4, [r10, #AK_SMPLEN+4*16]
	cmp r0, r4
	movge r0, #0
	ldrltb r0, [r6, r0]
	mov r0, r0, asl #24
	mov r0, r0, asr #16

	; v2 = envd(1, 12, 16, 127);
	mov r4, #1724
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	cmp r6, #4096
	movle r6, #4096
	mov r1, r6
	; v2 = vol(v2, 127)
	mov r14, #127
	mul r1, r14, r1
	mov r1, r1, asr #7

	; v3 = mul(v2, 110);
	mov r14, #110
	mul r2, r14, r1
	mov r2, r2, asr #15

	; v1 = sv_flt_n(3, v1, v3, 16, 0);
	ldr r4, [r10, #AK_OPINSTANCE+4*(0+AK_LPF)]
	ldr r5, [r10, #AK_OPINSTANCE+4*(0+AK_HPF)]
	ldr r6, [r10, #AK_OPINSTANCE+4*(0+AK_BPF)]
	mov r14, r6, asr #7
	mla r4, r2, r14, r4
	; r4 = clamp(r4)
	cmp r4, r11		; #32767
	movgt r4, r11	; #32767
	cmn r4, r11		; #-32768
	mvnlt r4, r11	; #-32768
	str r4, [r10, #AK_OPINSTANCE+4*(0+AK_LPF)]
	mov r12, #16
	mul r14, r12, r14
	mov r12, r0
	sub r12, r12, r4
	sub r5, r12, r14
	; r5 = clamp(r5)
	cmp r5, r11		; #32767
	movgt r5, r11	; #32767
	cmn r5, r11		; #-32768
	mvnlt r5, r11	; #-32768
	str r5, [r10, #AK_OPINSTANCE+4*(0+AK_HPF)]
	mov r14, r5, asr #7
	mla r6, r2, r14, r6
	; r6 = clamp(r6)
	cmp r6, r11		; #32767
	movgt r6, r11	; #32767
	cmn r6, r11		; #-32768
	mvnlt r6, r11	; #-32768
	str r6, [r10, #AK_OPINSTANCE+4*(0+AK_BPF)]
	mov r0, r4

	; v1 = mul(v2, v1);
	mul r0, r1, r0
	mov r0, r0, asr #15

	; v2 = osc_tri(5, 152, 110);
	ldr r6, [r10, #AK_OPINSTANCE+4*3]
	add r6, r6, #152
	mov r6, r6, asl #16
	mov r6, r6, asr #16	; Sign extend word to long.
	str r6, [r10, #AK_OPINSTANCE+4*3]
	cmp r6, #0
	mvnmi r6, r6
	sub r6, r6, #16384
	mov r1, r6, asl #1
	; v2 = vol(v2, 110)
	mov r14, #110
	mul r1, r14, r1
	mov r1, r1, asr #7

	; v1 = add(v1, v2);
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	mov r1, r1, asl #16
	mov r1, r1, asr #16	; Sign extend word to long.
	add r0, r0, r1
	; v1 = clamp(v1)
	cmp r0, r11		; #32767
	movgt r0, r11	; #32767
	cmn r0, r11		; #-32768
	mvnlt r0, r11	; #-32768

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*17]
	cmp r7, r4
	blt Inst18Loop

;----------------------------------------------------------------------------
; Instrument 19 - 'amigahub_bass3'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst19Loop:
	; v1 = clone(smp,16, 0);
	mov r0, r7
	ldr r6, [r10, #AK_SMPADDR+4*16]
	ldr r4, [r10, #AK_SMPLEN+4*16]
	cmp r0, r4
	movge r0, #0
	ldrltb r0, [r6, r0]
	mov r0, r0, asl #24
	mov r0, r0, asr #16

	; v2 = envd(1, 9, 22, 127);
	mov r4, #2978
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	cmp r6, #5632
	movle r6, #5632
	mov r1, r6
	; v2 = vol(v2, 127)
	mov r14, #127
	mul r1, r14, r1
	mov r1, r1, asr #7

	; v3 = mul(v2, 110);
	mov r14, #110
	mul r2, r14, r1
	mov r2, r2, asr #15

	; v1 = sv_flt_n(3, v1, v3, 16, 0);
	ldr r4, [r10, #AK_OPINSTANCE+4*(0+AK_LPF)]
	ldr r5, [r10, #AK_OPINSTANCE+4*(0+AK_HPF)]
	ldr r6, [r10, #AK_OPINSTANCE+4*(0+AK_BPF)]
	mov r14, r6, asr #7
	mla r4, r2, r14, r4
	; r4 = clamp(r4)
	cmp r4, r11		; #32767
	movgt r4, r11	; #32767
	cmn r4, r11		; #-32768
	mvnlt r4, r11	; #-32768
	str r4, [r10, #AK_OPINSTANCE+4*(0+AK_LPF)]
	mov r12, #16
	mul r14, r12, r14
	mov r12, r0
	sub r12, r12, r4
	sub r5, r12, r14
	; r5 = clamp(r5)
	cmp r5, r11		; #32767
	movgt r5, r11	; #32767
	cmn r5, r11		; #-32768
	mvnlt r5, r11	; #-32768
	str r5, [r10, #AK_OPINSTANCE+4*(0+AK_HPF)]
	mov r14, r5, asr #7
	mla r6, r2, r14, r6
	; r6 = clamp(r6)
	cmp r6, r11		; #32767
	movgt r6, r11	; #32767
	cmn r6, r11		; #-32768
	mvnlt r6, r11	; #-32768
	str r6, [r10, #AK_OPINSTANCE+4*(0+AK_BPF)]
	mov r0, r4

	; v1 = mul(v2, v1);
	mul r0, r1, r0
	mov r0, r0, asr #15

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*18]
	cmp r7, r4
	blt Inst19Loop

;----------------------------------------------------------------------------
; Instrument 19 - Loop Generator (Offset: 3584 Length: 2560)
;----------------------------------------------------------------------------

	mov r7, #2560
	ldr r6, [r10, #AK_SMPADDR+4*18]
	add r6, r6, #3584	; src1
	sub r4, r6, r7	; src2
	mov r0, r11, lsl #8	; 32767<<8
	mov r1, r7
	bl divide
	mov r5, r0	; delta = divs.w(32767<<8,repeat_length)
	mov r14, #0	; rampup
	mov r12, r11, lsl #8	; rampdown
LoopGen_18:
	mov r3, r14, lsr #8
	mov r2, r12, lsr #8
	ldrb r1, [r6]
	mov r1, r1, asl #24
	mov r1, r1, asr #24
	ldrb r0, [r4], #1
	mov r0, r0, asl #24
	mov r0, r0, asr #24
	mul r0, r3, r0
	mla r0, r1, r2, r0
	mov r0, r0, lsr #15
	strb r0, [r6], #1
	add r14, r14, r5
	sub r12, r12, r5
	; TODO: Fine progress.
	subs r7, r7, #1
	bne LoopGen_18

;----------------------------------------------------------------------------
; Instrument 20 - 'amigahub_bass4'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst20Loop:
	; v1 = clone_reverse(smp,16, 0);
	mov r0, r7
	ldr r6, [r10, #AK_SMPADDR+4*(16+1)]
	ldr r4, [r10, #AK_SMPLEN+4*16]
	cmp r0, r4
	movge r0, #0
	rsblt r0, r0, #0
	ldrltb r0, [r6, r0]
	mov r0, r0, asl #24
	mov r0, r0, asr #16

	; v2 = envd(1, 6, 16, 127);
	mov r4, #6553
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	cmp r6, #4096
	movle r6, #4096
	mov r1, r6
	; v2 = vol(v2, 127)
	mov r14, #127
	mul r1, r14, r1
	mov r1, r1, asr #7

	; v3 = mul(v2, 110);
	mov r14, #110
	mul r2, r14, r1
	mov r2, r2, asr #15

	; v1 = sv_flt_n(3, v1, v3, 16, 0);
	ldr r4, [r10, #AK_OPINSTANCE+4*(0+AK_LPF)]
	ldr r5, [r10, #AK_OPINSTANCE+4*(0+AK_HPF)]
	ldr r6, [r10, #AK_OPINSTANCE+4*(0+AK_BPF)]
	mov r14, r6, asr #7
	mla r4, r2, r14, r4
	; r4 = clamp(r4)
	cmp r4, r11		; #32767
	movgt r4, r11	; #32767
	cmn r4, r11		; #-32768
	mvnlt r4, r11	; #-32768
	str r4, [r10, #AK_OPINSTANCE+4*(0+AK_LPF)]
	mov r12, #16
	mul r14, r12, r14
	mov r12, r0
	sub r12, r12, r4
	sub r5, r12, r14
	; r5 = clamp(r5)
	cmp r5, r11		; #32767
	movgt r5, r11	; #32767
	cmn r5, r11		; #-32768
	mvnlt r5, r11	; #-32768
	str r5, [r10, #AK_OPINSTANCE+4*(0+AK_HPF)]
	mov r14, r5, asr #7
	mla r6, r2, r14, r6
	; r6 = clamp(r6)
	cmp r6, r11		; #32767
	movgt r6, r11	; #32767
	cmn r6, r11		; #-32768
	mvnlt r6, r11	; #-32768
	str r6, [r10, #AK_OPINSTANCE+4*(0+AK_BPF)]
	mov r0, r4

	; v1 = mul(v2, v1);
	mul r0, r1, r0
	mov r0, r0, asr #15

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*19]
	cmp r7, r4
	blt Inst20Loop

;----------------------------------------------------------------------------
; Instrument 20 - Loop Generator (Offset: 3584 Length: 2560)
;----------------------------------------------------------------------------

	mov r7, #2560
	ldr r6, [r10, #AK_SMPADDR+4*19]
	add r6, r6, #3584	; src1
	sub r4, r6, r7	; src2
	mov r0, r11, lsl #8	; 32767<<8
	mov r1, r7
	bl divide
	mov r5, r0	; delta = divs.w(32767<<8,repeat_length)
	mov r14, #0	; rampup
	mov r12, r11, lsl #8	; rampdown
LoopGen_19:
	mov r3, r14, lsr #8
	mov r2, r12, lsr #8
	ldrb r1, [r6]
	mov r1, r1, asl #24
	mov r1, r1, asr #24
	ldrb r0, [r4], #1
	mov r0, r0, asl #24
	mov r0, r0, asr #24
	mul r0, r3, r0
	mla r0, r1, r2, r0
	mov r0, r0, lsr #15
	strb r0, [r6], #1
	add r14, r14, r5
	sub r12, r12, r5
	; TODO: Fine progress.
	subs r7, r7, #1
	bne LoopGen_19

;----------------------------------------------------------------------------
; Instrument 21 - 'amigahub_bass+hat'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst21Loop:
	; v1 = clone(smp,0, 0);
	mov r0, r7
	ldr r6, [r10, #AK_SMPADDR+4*0]
	ldr r4, [r10, #AK_SMPLEN+4*0]
	cmp r0, r4
	movge r0, #0
	ldrltb r0, [r6, r0]
	mov r0, r0, asl #24
	mov r0, r0, asr #16

	; v2 = clone(smp,17, 0);
	mov r1, r7
	ldr r6, [r10, #AK_SMPADDR+4*17]
	ldr r4, [r10, #AK_SMPLEN+4*17]
	cmp r1, r4
	movge r1, #0
	ldrltb r1, [r6, r1]
	mov r1, r1, asl #24
	mov r1, r1, asr #16

	; v1 = add(v2, v1);
	mov r1, r1, asl #16
	mov r1, r1, asr #16	; Sign extend word to long.
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r0, r1, r0
	; v1 = clamp(v1)
	cmp r0, r11		; #32767
	movgt r0, r11	; #32767
	cmn r0, r11		; #-32768
	mvnlt r0, r11	; #-32768

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*20]
	cmp r7, r4
	blt Inst21Loop

;----------------------------------------------------------------------------
; Instrument 22 - 'amigahub_vocal'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst22Loop:
	; v1 = imported_sample(smp,5);
	mov r0, r7
	ldr r6, [r10, #AK_EXTSMPADDR+4*5]
	ldr r4, [r10, #AK_EXTSMPLEN+4*5]
	cmp r0, r4
	movge r0, #0
	ldrltb r0, [r6, r0]
	mov r0, r0, asl #24
	mov r0, r0, asr #16

	; v1 = reverb(v1, 118, 15);
	ldr r6, [r10, #AK_OPINSTANCE+4*0]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 118)
	mov r14, #118
	mul r4, r14, r4
	mov r4, r4, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r12, r0, r4
	; r12 = clamp(r12)
	cmp r12, r11		; #32767
	movgt r12, r11	; #32767
	cmn r12, r11		; #-32768
	mvnlt r12, r11	; #-32768
	str r12, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #557
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*0]
	; r12 = vol(r12, 15)
	mov r14, #15
	mul r12, r14, r12
	mov r12, r12, asr #7
	mov r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*1]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 118)
	mov r14, #118
	mul r4, r14, r4
	mov r4, r4, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r12, r0, r4
	; r12 = clamp(r12)
	cmp r12, r11		; #32767
	movgt r12, r11	; #32767
	cmn r12, r11		; #-32768
	mvnlt r12, r11	; #-32768
	str r12, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #593
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*1]
	; r12 = vol(r12, 15)
	mov r14, #15
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*2]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 118)
	mov r14, #118
	mul r4, r14, r4
	mov r4, r4, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r12, r0, r4
	; r12 = clamp(r12)
	cmp r12, r11		; #32767
	movgt r12, r11	; #32767
	cmn r12, r11		; #-32768
	mvnlt r12, r11	; #-32768
	str r12, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #641
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*2]
	; r12 = vol(r12, 15)
	mov r14, #15
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*3]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 118)
	mov r14, #118
	mul r4, r14, r4
	mov r4, r4, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r12, r0, r4
	; r12 = clamp(r12)
	cmp r12, r11		; #32767
	movgt r12, r11	; #32767
	cmn r12, r11		; #-32768
	mvnlt r12, r11	; #-32768
	str r12, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #677
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*3]
	; r12 = vol(r12, 15)
	mov r14, #15
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*4]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 118)
	mov r14, #118
	mul r4, r14, r4
	mov r4, r4, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r12, r0, r4
	; r12 = clamp(r12)
	cmp r12, r11		; #32767
	movgt r12, r11	; #32767
	cmn r12, r11		; #-32768
	mvnlt r12, r11	; #-32768
	str r12, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #709
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*4]
	; r12 = vol(r12, 15)
	mov r14, #15
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*5]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 118)
	mov r14, #118
	mul r4, r14, r4
	mov r4, r4, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r12, r0, r4
	; r12 = clamp(r12)
	cmp r12, r11		; #32767
	movgt r12, r11	; #32767
	cmn r12, r11		; #-32768
	mvnlt r12, r11	; #-32768
	str r12, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #743
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*5]
	; r12 = vol(r12, 15)
	mov r14, #15
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*6]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 118)
	mov r14, #118
	mul r4, r14, r4
	mov r4, r4, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r12, r0, r4
	; r12 = clamp(r12)
	cmp r12, r11		; #32767
	movgt r12, r11	; #32767
	cmn r12, r11		; #-32768
	mvnlt r12, r11	; #-32768
	str r12, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #787
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*6]
	; r12 = vol(r12, 15)
	mov r14, #15
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*7]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 118)
	mov r14, #118
	mul r4, r14, r4
	mov r4, r4, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r12, r0, r4
	; r12 = clamp(r12)
	cmp r12, r11		; #32767
	movgt r12, r11	; #32767
	cmn r12, r11		; #-32768
	mvnlt r12, r11	; #-32768
	str r12, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #809
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*7]
	; r12 = vol(r12, 15)
	mov r14, #15
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r0, r5, r12
	sub r9, r9, #2048*4*7
	; v1 = clamp(v1)
	cmp r0, r11		; #32767
	movgt r0, r11	; #32767
	cmn r0, r11		; #-32768
	mvnlt r0, r11	; #-32768

	; v1 = vol(v1, 138);
	; v1 = vol(v1, 138)
	mov r14, #138
	mul r0, r14, r0
	mov r0, r0, asr #7

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*21]
	cmp r7, r4
	blt Inst22Loop

;----------------------------------------------------------------------------
; Instrument 22 - Loop Generator (Offset: 14216 Length: 14218)
;----------------------------------------------------------------------------

	mov r7, #14218
	ldr r6, [r10, #AK_SMPADDR+4*21]
	add r6, r6, #14216	; src1
	sub r4, r6, r7	; src2
	mov r0, r11, lsl #8	; 32767<<8
	mov r1, r7
	bl divide
	mov r5, r0	; delta = divs.w(32767<<8,repeat_length)
	mov r14, #0	; rampup
	mov r12, r11, lsl #8	; rampdown
LoopGen_21:
	mov r3, r14, lsr #8
	mov r2, r12, lsr #8
	ldrb r1, [r6]
	mov r1, r1, asl #24
	mov r1, r1, asr #24
	ldrb r0, [r4], #1
	mov r0, r0, asl #24
	mov r0, r0, asr #24
	mul r0, r3, r0
	mla r0, r1, r2, r0
	mov r0, r0, lsr #15
	strb r0, [r6], #1
	add r14, r14, r5
	sub r12, r12, r5
	; TODO: Fine progress.
	subs r7, r7, #1
	bne LoopGen_21

;----------------------------------------------------------------------------
; Instrument 23 - 'amigahub_vocal2'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst23Loop:
	; v1 = imported_sample(smp,7);
	mov r0, r7
	ldr r6, [r10, #AK_EXTSMPADDR+4*7]
	ldr r4, [r10, #AK_EXTSMPLEN+4*7]
	cmp r0, r4
	movge r0, #0
	ldrltb r0, [r6, r0]
	mov r0, r0, asl #24
	mov r0, r0, asr #16

	; v1 = reverb(v1, 112, 26);
	ldr r6, [r10, #AK_OPINSTANCE+4*0]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 112)
	mov r14, #112
	mul r4, r14, r4
	mov r4, r4, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r12, r0, r4
	; r12 = clamp(r12)
	cmp r12, r11		; #32767
	movgt r12, r11	; #32767
	cmn r12, r11		; #-32768
	mvnlt r12, r11	; #-32768
	str r12, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #557
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*0]
	; r12 = vol(r12, 26)
	mov r14, #26
	mul r12, r14, r12
	mov r12, r12, asr #7
	mov r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*1]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 112)
	mov r14, #112
	mul r4, r14, r4
	mov r4, r4, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r12, r0, r4
	; r12 = clamp(r12)
	cmp r12, r11		; #32767
	movgt r12, r11	; #32767
	cmn r12, r11		; #-32768
	mvnlt r12, r11	; #-32768
	str r12, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #593
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*1]
	; r12 = vol(r12, 26)
	mov r14, #26
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*2]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 112)
	mov r14, #112
	mul r4, r14, r4
	mov r4, r4, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r12, r0, r4
	; r12 = clamp(r12)
	cmp r12, r11		; #32767
	movgt r12, r11	; #32767
	cmn r12, r11		; #-32768
	mvnlt r12, r11	; #-32768
	str r12, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #641
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*2]
	; r12 = vol(r12, 26)
	mov r14, #26
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*3]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 112)
	mov r14, #112
	mul r4, r14, r4
	mov r4, r4, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r12, r0, r4
	; r12 = clamp(r12)
	cmp r12, r11		; #32767
	movgt r12, r11	; #32767
	cmn r12, r11		; #-32768
	mvnlt r12, r11	; #-32768
	str r12, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #677
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*3]
	; r12 = vol(r12, 26)
	mov r14, #26
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*4]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 112)
	mov r14, #112
	mul r4, r14, r4
	mov r4, r4, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r12, r0, r4
	; r12 = clamp(r12)
	cmp r12, r11		; #32767
	movgt r12, r11	; #32767
	cmn r12, r11		; #-32768
	mvnlt r12, r11	; #-32768
	str r12, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #709
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*4]
	; r12 = vol(r12, 26)
	mov r14, #26
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*5]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 112)
	mov r14, #112
	mul r4, r14, r4
	mov r4, r4, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r12, r0, r4
	; r12 = clamp(r12)
	cmp r12, r11		; #32767
	movgt r12, r11	; #32767
	cmn r12, r11		; #-32768
	mvnlt r12, r11	; #-32768
	str r12, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #743
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*5]
	; r12 = vol(r12, 26)
	mov r14, #26
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*6]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 112)
	mov r14, #112
	mul r4, r14, r4
	mov r4, r4, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r12, r0, r4
	; r12 = clamp(r12)
	cmp r12, r11		; #32767
	movgt r12, r11	; #32767
	cmn r12, r11		; #-32768
	mvnlt r12, r11	; #-32768
	str r12, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #787
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*6]
	; r12 = vol(r12, 26)
	mov r14, #26
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*7]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 112)
	mov r14, #112
	mul r4, r14, r4
	mov r4, r4, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r12, r0, r4
	; r12 = clamp(r12)
	cmp r12, r11		; #32767
	movgt r12, r11	; #32767
	cmn r12, r11		; #-32768
	mvnlt r12, r11	; #-32768
	str r12, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #809
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*7]
	; r12 = vol(r12, 26)
	mov r14, #26
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r0, r5, r12
	sub r9, r9, #2048*4*7
	; v1 = clamp(v1)
	cmp r0, r11		; #32767
	movgt r0, r11	; #32767
	cmn r0, r11		; #-32768
	mvnlt r0, r11	; #-32768

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*22]
	cmp r7, r4
	blt Inst23Loop

;----------------------------------------------------------------------------
; Instrument 23 - Loop Generator (Offset: 8698 Length: 6918)
;----------------------------------------------------------------------------

	mov r7, #6918
	ldr r6, [r10, #AK_SMPADDR+4*22]
	add r6, r6, #8698	; src1
	sub r4, r6, r7	; src2
	mov r0, r11, lsl #8	; 32767<<8
	mov r1, r7
	bl divide
	mov r5, r0	; delta = divs.w(32767<<8,repeat_length)
	mov r14, #0	; rampup
	mov r12, r11, lsl #8	; rampdown
LoopGen_22:
	mov r3, r14, lsr #8
	mov r2, r12, lsr #8
	ldrb r1, [r6]
	mov r1, r1, asl #24
	mov r1, r1, asr #24
	ldrb r0, [r4], #1
	mov r0, r0, asl #24
	mov r0, r0, asr #24
	mul r0, r3, r0
	mla r0, r1, r2, r0
	mov r0, r0, lsr #15
	strb r0, [r6], #1
	add r14, r14, r5
	sub r12, r12, r5
	; TODO: Fine progress.
	subs r7, r7, #1
	bne LoopGen_22

;----------------------------------------------------------------------------
; Instrument 24 - 'amigahub_tom'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst24Loop:
	; v2 = envd(0, 19, 0, 7);
	mov r4, #712
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	movle r6, #0
	mov r1, r6
	; v2 = vol(v2, 7)
	mov r14, #7
	mul r1, r14, r1
	mov r1, r1, asr #7

	; v3 = envd(1, 15, 0, 127);
	mov r4, #1129
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	movle r6, #0
	mov r2, r6
	; v3 = vol(v3, 127)
	mov r14, #127
	mul r2, r14, r2
	mov r2, r2, asr #7

	; v4 = envd(2, 15, 0, 127);
	mov r4, #1129
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	movle r6, #0
	mov r3, r6
	; v4 = vol(v4, 127)
	mov r14, #127
	mul r3, r14, r3
	mov r3, r3, asr #7

	; v3 = mul(v3, v4);
	mul r2, r3, r2
	mov r2, r2, asr #15

	; v1 = osc_sine(4, v2, 79);
	ldr r6, [r10, #AK_OPINSTANCE+4*0]
	add r6, r6, r1
	str r6, [r10, #AK_OPINSTANCE+4*0]
	sub r6, r6, #16384
	mov r6, r6, asl #16
	mov r6, r6, asr #16	; Sign extend word to long.
	movs r4, r6
	rsblt r4, r4, #0
	sub r4, r11, r4	; #32767
	mul r4, r6, r4
	mov r4, r4, asr #16
	mov r0, r4, asl #3
	; v1 = vol(v1, 79)
	mov r14, #79
	mul r0, r14, r0
	mov r0, r0, asr #7

	; v2 = clone(smp,6, 0);
	mov r1, r7
	ldr r6, [r10, #AK_SMPADDR+4*6]
	ldr r4, [r10, #AK_SMPLEN+4*6]
	cmp r1, r4
	movge r1, #0
	ldrltb r1, [r6, r1]
	mov r1, r1, asl #24
	mov r1, r1, asr #16

	; v2 = sv_flt_n(6, v2, 20, 28, 1);
	ldr r4, [r10, #AK_OPINSTANCE+4*(1+AK_LPF)]
	ldr r5, [r10, #AK_OPINSTANCE+4*(1+AK_HPF)]
	ldr r6, [r10, #AK_OPINSTANCE+4*(1+AK_BPF)]
	mov r14, r6, asr #7
	mov r12, #20
	mla r4, r14, r12, r4
	; r4 = clamp(r4)
	cmp r4, r11		; #32767
	movgt r4, r11	; #32767
	cmn r4, r11		; #-32768
	mvnlt r4, r11	; #-32768
	str r4, [r10, #AK_OPINSTANCE+4*(1+AK_LPF)]
	mov r12, #28
	mul r14, r12, r14
	mov r12, r1
	sub r12, r12, r4
	sub r5, r12, r14
	; r5 = clamp(r5)
	cmp r5, r11		; #32767
	movgt r5, r11	; #32767
	cmn r5, r11		; #-32768
	mvnlt r5, r11	; #-32768
	str r5, [r10, #AK_OPINSTANCE+4*(1+AK_HPF)]
	mov r14, r5, asr #7
	mov r12, #20
	mla r6, r12, r14, r6
	; r6 = clamp(r6)
	cmp r6, r11		; #32767
	movgt r6, r11	; #32767
	cmn r6, r11		; #-32768
	mvnlt r6, r11	; #-32768
	str r6, [r10, #AK_OPINSTANCE+4*(1+AK_BPF)]
	mov r1, r5

	; v1 = add(v1, v2);
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	mov r1, r1, asl #16
	mov r1, r1, asr #16	; Sign extend word to long.
	add r0, r0, r1
	; v1 = clamp(v1)
	cmp r0, r11		; #32767
	movgt r0, r11	; #32767
	cmn r0, r11		; #-32768
	mvnlt r0, r11	; #-32768

	; v1 = mul(v1, v3);
	mul r0, r2, r0
	mov r0, r0, asr #15

	; v1 = cmb_flt_n(9, v1, 267, 59, 127);
	ldr r6, [r10, #AK_OPINSTANCE+4*4]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 59)
	mov r14, #59
	mul r4, r14, r4
	mov r4, r4, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r0, r0, r4
	; v1 = clamp(v1)
	cmp r0, r11		; #32767
	movgt r0, r11	; #32767
	cmn r0, r11		; #-32768
	mvnlt r0, r11	; #-32768
	str r0, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #267
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*4]
	; v1 = vol(v1, 127)
	mov r14, #127
	mul r0, r14, r0
	mov r0, r0, asr #7

	; v1 = sv_flt_n(10, v1, 24, 42, 1);
	ldr r4, [r10, #AK_OPINSTANCE+4*(5+AK_LPF)]
	ldr r5, [r10, #AK_OPINSTANCE+4*(5+AK_HPF)]
	ldr r6, [r10, #AK_OPINSTANCE+4*(5+AK_BPF)]
	mov r14, r6, asr #7
	mov r12, #24
	mla r4, r14, r12, r4
	; r4 = clamp(r4)
	cmp r4, r11		; #32767
	movgt r4, r11	; #32767
	cmn r4, r11		; #-32768
	mvnlt r4, r11	; #-32768
	str r4, [r10, #AK_OPINSTANCE+4*(5+AK_LPF)]
	mov r12, #42
	mul r14, r12, r14
	mov r12, r0
	sub r12, r12, r4
	sub r5, r12, r14
	; r5 = clamp(r5)
	cmp r5, r11		; #32767
	movgt r5, r11	; #32767
	cmn r5, r11		; #-32768
	mvnlt r5, r11	; #-32768
	str r5, [r10, #AK_OPINSTANCE+4*(5+AK_HPF)]
	mov r14, r5, asr #7
	mov r12, #24
	mla r6, r12, r14, r6
	; r6 = clamp(r6)
	cmp r6, r11		; #32767
	movgt r6, r11	; #32767
	cmn r6, r11		; #-32768
	mvnlt r6, r11	; #-32768
	str r6, [r10, #AK_OPINSTANCE+4*(5+AK_BPF)]
	mov r0, r5

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*23]
	cmp r7, r4
	blt Inst24Loop

;----------------------------------------------------------------------------
; Instrument 25 - 'amigahub_lead'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst25Loop:
	; v1 = osc_saw(0, 1800, 63);
	ldr r0, [r10, #AK_OPINSTANCE+4*0]
	add r0, r0, #1800
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	str r0, [r10, #AK_OPINSTANCE+4*0]	
	; v1 = vol(v1, 63)
	mov r14, #63
	mul r0, r14, r0
	mov r0, r0, asr #7

	; v2 = osc_saw(1, 1810, 50);
	ldr r1, [r10, #AK_OPINSTANCE+4*1]
	add r1, r1, #1810
	mov r1, r1, asl #16
	mov r1, r1, asr #16	; Sign extend word to long.
	str r1, [r10, #AK_OPINSTANCE+4*1]	
	; v2 = vol(v2, 50)
	mov r14, #50
	mul r1, r14, r1
	mov r1, r1, asr #7

	; v1 = add(v1, v2);
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	mov r1, r1, asl #16
	mov r1, r1, asr #16	; Sign extend word to long.
	add r0, r0, r1
	; v1 = clamp(v1)
	cmp r0, r11		; #32767
	movgt r0, r11	; #32767
	cmn r0, r11		; #-32768
	mvnlt r0, r11	; #-32768

	; v2 = osc_pulse(3, 900, 64, v3);
	ldr r6, [r10, #AK_OPINSTANCE+4*2]
	adds r6, r6, #900
	mov r6, r6, asl #16
	mov r6, r6, asr #16	; Sign extend word to long.
	str r6, [r10, #AK_OPINSTANCE+4*2]
	sub r4, r2, #63
	mov r4, r4, asl #9
	cmp r6, r4
	mvnlt r1, r11	; #-32768
	movge r1, r11	; #32767
	; v2 = vol(v2, 64)
	mov r1, r1, asr #1	; val<<6>>7

	; v1 = add(v1, v2);
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	mov r1, r1, asl #16
	mov r1, r1, asr #16	; Sign extend word to long.
	add r0, r0, r1
	; v1 = clamp(v1)
	cmp r0, r11		; #32767
	movgt r0, r11	; #32767
	cmn r0, r11		; #-32768
	mvnlt r0, r11	; #-32768

	; v2 = osc_sine(5, 3, 112);
	ldr r6, [r10, #AK_OPINSTANCE+4*3]
	add r6, r6, #3
	str r6, [r10, #AK_OPINSTANCE+4*3]
	sub r6, r6, #16384
	mov r6, r6, asl #16
	mov r6, r6, asr #16	; Sign extend word to long.
	movs r4, r6
	rsblt r4, r4, #0
	sub r4, r11, r4	; #32767
	mul r4, r6, r4
	mov r4, r4, asr #16
	mov r1, r4, asl #3
	; v2 = vol(v2, 112)
	mov r14, #112
	mul r1, r14, r1
	mov r1, r1, asr #7

	; v3 = ctrl(v2);
	mov r2, r1, asr #9
	mov r2, r2, asl #16
	mov r2, r2, asr #16	; Sign extend word to long.
	add r2, r2, #64

	; v1 = sv_flt_n(7, v1, v3, 46, 2);
	ldr r4, [r10, #AK_OPINSTANCE+4*(4+AK_LPF)]
	ldr r5, [r10, #AK_OPINSTANCE+4*(4+AK_HPF)]
	ldr r6, [r10, #AK_OPINSTANCE+4*(4+AK_BPF)]
	mov r14, r6, asr #7
	mla r4, r2, r14, r4
	; r4 = clamp(r4)
	cmp r4, r11		; #32767
	movgt r4, r11	; #32767
	cmn r4, r11		; #-32768
	mvnlt r4, r11	; #-32768
	str r4, [r10, #AK_OPINSTANCE+4*(4+AK_LPF)]
	mov r12, #46
	mul r14, r12, r14
	mov r12, r0
	sub r12, r12, r4
	sub r5, r12, r14
	; r5 = clamp(r5)
	cmp r5, r11		; #32767
	movgt r5, r11	; #32767
	cmn r5, r11		; #-32768
	mvnlt r5, r11	; #-32768
	str r5, [r10, #AK_OPINSTANCE+4*(4+AK_HPF)]
	mov r14, r5, asr #7
	mla r6, r2, r14, r6
	; r6 = clamp(r6)
	cmp r6, r11		; #32767
	movgt r6, r11	; #32767
	cmn r6, r11		; #-32768
	mvnlt r6, r11	; #-32768
	str r6, [r10, #AK_OPINSTANCE+4*(4+AK_BPF)]
	mov r0, r6

	; v1 = sv_flt_n(8, v1, 37, 127, 2);
	ldr r4, [r10, #AK_OPINSTANCE+4*(7+AK_LPF)]
	ldr r5, [r10, #AK_OPINSTANCE+4*(7+AK_HPF)]
	ldr r6, [r10, #AK_OPINSTANCE+4*(7+AK_BPF)]
	mov r14, r6, asr #7
	mov r12, #37
	mla r4, r14, r12, r4
	; r4 = clamp(r4)
	cmp r4, r11		; #32767
	movgt r4, r11	; #32767
	cmn r4, r11		; #-32768
	mvnlt r4, r11	; #-32768
	str r4, [r10, #AK_OPINSTANCE+4*(7+AK_LPF)]
	mov r12, #127
	mul r14, r12, r14
	mov r12, r0
	sub r12, r12, r4
	sub r5, r12, r14
	; r5 = clamp(r5)
	cmp r5, r11		; #32767
	movgt r5, r11	; #32767
	cmn r5, r11		; #-32768
	mvnlt r5, r11	; #-32768
	str r5, [r10, #AK_OPINSTANCE+4*(7+AK_HPF)]
	mov r14, r5, asr #7
	mov r12, #37
	mla r6, r12, r14, r6
	; r6 = clamp(r6)
	cmp r6, r11		; #32767
	movgt r6, r11	; #32767
	cmn r6, r11		; #-32768
	mvnlt r6, r11	; #-32768
	str r6, [r10, #AK_OPINSTANCE+4*(7+AK_BPF)]
	mov r0, r6

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*24]
	cmp r7, r4
	blt Inst25Loop

;----------------------------------------------------------------------------
; Instrument 25 - Loop Generator (Offset: 16400 Length: 16402)
;----------------------------------------------------------------------------

	mov r7, #16402
	ldr r6, [r10, #AK_SMPADDR+4*24]
	add r6, r6, #16400	; src1
	sub r4, r6, r7	; src2
	mov r0, r11, lsl #8	; 32767<<8
	mov r1, r7
	bl divide
	mov r5, r0	; delta = divs.w(32767<<8,repeat_length)
	mov r14, #0	; rampup
	mov r12, r11, lsl #8	; rampdown
LoopGen_24:
	mov r3, r14, lsr #8
	mov r2, r12, lsr #8
	ldrb r1, [r6]
	mov r1, r1, asl #24
	mov r1, r1, asr #24
	ldrb r0, [r4], #1
	mov r0, r0, asl #24
	mov r0, r0, asr #24
	mul r0, r3, r0
	mla r0, r1, r2, r0
	mov r0, r0, lsr #15
	strb r0, [r6], #1
	add r14, r14, r5
	sub r12, r12, r5
	; TODO: Fine progress.
	subs r7, r7, #1
	bne LoopGen_24

; ============================================================================

.if AK_CLEAR_FIRST_2_BYTES
	; Clear first 2 bytes of each sample
	adr r4, AK_SmpAddr
	mov r7, #25
	mov r0, #0
.1:
	ldr r6, [r4], #4
	strb r0, [r6]
	strb r0, [r6, #1]
	subs r7, r7, #1
	bne .1
.endif

	ldr pc, [sp], #4

; ============================================================================

AK_ResetVars:
	mov r0, #0
	mov r1, #0
	mov r2, #0
	mov r3, #0
; TODO: Make ClearDelayLoop conditional.
	mov r6, r9	; Clear scratch space (delay loop).
	mov r4, #65536/16
.1:
	stmia r6!, {r0-r3}
	subs r4, r4, #1
	bne .1
	add r6, r10, #AK_OPINSTANCE
	.rept 11
	str r0, [r6], #4
	.endr
	mov r4, r11, lsl #16	; 32767<<16
	.rept 0
	str r4, [r6], #4
	.endr
	mov pc, lr

; ============================================================================

AK_Vars:
AK_SmpLen:
	.long 0x00000740	; Instrument 1 Length
	.long 0x00000740	; Instrument 2 Length
	.long 0x00002500	; Instrument 3 Length
	.long 0x00000e48	; Instrument 4 Length
	.long 0x00000510	; Instrument 5 Length
	.long 0x00001010	; Instrument 6 Length
	.long 0x00001200	; Instrument 7 Length
	.long 0x000008d4	; Instrument 8 Length
	.long 0x00000200	; Instrument 9 Length
	.long 0x00001ee0	; Instrument 10 Length
	.long 0x00007400	; Instrument 11 Length
	.long 0x00004000	; Instrument 12 Length
	.long 0x00003600	; Instrument 13 Length
	.long 0x00003480	; Instrument 14 Length
	.long 0x00002900	; Instrument 15 Length
	.long 0x00001de6	; Instrument 16 Length
	.long 0x00001800	; Instrument 17 Length
	.long 0x00001800	; Instrument 18 Length
	.long 0x00001800	; Instrument 19 Length
	.long 0x00001800	; Instrument 20 Length
	.long 0x00001800	; Instrument 21 Length
	.long 0x00006f12	; Instrument 22 Length
	.long 0x00003d00	; Instrument 23 Length
	.long 0x000017c0	; Instrument 24 Length
	.long 0x00008022	; Instrument 25 Length
	.long 0x00000000	; Instrument 25 Length
	.long 0x00000000	; Instrument 26 Length
	.long 0x00000000	; Instrument 27 Length
	.long 0x00000000	; Instrument 28 Length
	.long 0x00000000	; Instrument 29 Length
	.long 0x00000000	; Instrument 30 Length
	.long 0x00000000	; Instrument 31 Length
AK_ExtSmpLen:
	.long 0x00000776	; External Sample 1 Length
	.long 0x00000e7c	; External Sample 2 Length
	.long 0x00000e48	; External Sample 3 Length
	.long 0x00001010	; External Sample 4 Length
	.long 0x0000090e	; External Sample 5 Length
	.long 0x00001674	; External Sample 6 Length
	.long 0x00000fa8	; External Sample 7 Length
	.long 0x0000153c	; External Sample 8 Length
AK_NoiseSeeds:
	.long 0x67452301
	.long 0xefcdab89
	.long 0x00000000
AK_SmpAddr:
	.skip AK_MaxInstruments*4
AK_ExtSmpAddr:
	.skip AK_MaxExtSamples*4
AK_OpInstance:
	.skip 11*4
AK_EnvDValue:
	; NB. Must follow AK_OpInstance!
	.skip 0*4

; ============================================================================
