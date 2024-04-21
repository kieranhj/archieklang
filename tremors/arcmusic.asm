; ============================================================================
; akp2arc.py
; input = tremors\script.txt.
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

.equ AK_SMP_LEN,		197536
.equ AK_EXT_SMP_LEN,	2

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
; r9 = 8*2048 word (=65536 byte) Temporary Work Buffer Address (can be freed after sample rendering complete)
; r10 = Base of AK_Vars
; r11 = 36767 (0x7fff)
; r12 = temp
; r14 = temp
; ============================================================================

	adr r10, AK_Vars
	mov r11, #32767	; const

;----------------------------------------------------------------------------
; Instrument 1 - '808 Noise osc'
;----------------------------------------------------------------------------

	; TODO: Delay buffer flag 0.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst1Loop:
	; v1 = osc_pulse(0, 2048, 22, 64);
	ldr r6, [r10, #AK_OPINSTANCE+4*0]
	adds r6, r6, #2048
	mov r6, r6, asl #16
	mov r6, r6, asr #16	; Sign extend word to long.
	str r6, [r10, #AK_OPINSTANCE+4*0]
	mov r4, #512	; (64-63)<<9
	cmp r6, r4
	mvnlt r0, r11	; #-32768
	movge r0, r11	; #32767
	; v1 = vol(v1, 22)
	mov r14, #22
	mul r0, r14, r0
	mov r0, r0, asr #7

	; v2 = osc_pulse(1, 3034, 22, 64);
	ldr r6, [r10, #AK_OPINSTANCE+4*1]
	adds r6, r6, #3034
	mov r6, r6, asl #16
	mov r6, r6, asr #16	; Sign extend word to long.
	str r6, [r10, #AK_OPINSTANCE+4*1]
	mov r4, #512	; (64-63)<<9
	cmp r6, r4
	mvnlt r1, r11	; #-32768
	movge r1, r11	; #32767
	; v2 = vol(v2, 22)
	mov r14, #22
	mul r1, r14, r1
	mov r1, r1, asr #7

	; v3 = osc_pulse(2, 1982, 22, 64);
	ldr r6, [r10, #AK_OPINSTANCE+4*2]
	adds r6, r6, #1982
	mov r6, r6, asl #16
	mov r6, r6, asr #16	; Sign extend word to long.
	str r6, [r10, #AK_OPINSTANCE+4*2]
	mov r4, #512	; (64-63)<<9
	cmp r6, r4
	mvnlt r2, r11	; #-32768
	movge r2, r11	; #32767
	; v3 = vol(v3, 22)
	mov r14, #22
	mul r2, r14, r2
	mov r2, r2, asr #7

	; v4 = osc_pulse(3, 1154, 22, 64);
	ldr r6, [r10, #AK_OPINSTANCE+4*3]
	adds r6, r6, #1154
	mov r6, r6, asl #16
	mov r6, r6, asr #16	; Sign extend word to long.
	str r6, [r10, #AK_OPINSTANCE+4*3]
	mov r4, #512	; (64-63)<<9
	cmp r6, r4
	mvnlt r3, r11	; #-32768
	movge r3, r11	; #32767
	; v4 = vol(v4, 22)
	mov r14, #22
	mul r3, r14, r3
	mov r3, r3, asr #7

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

	; v2 = add(v3, v4);
	mov r2, r2, asl #16
	mov r2, r2, asr #16	; Sign extend word to long.
	mov r3, r3, asl #16
	mov r3, r3, asr #16	; Sign extend word to long.
	add r1, r2, r3
	; v2 = clamp(v2)
	cmp r1, r11		; #32767
	movgt r1, r11	; #32767
	cmn r1, r11		; #-32768
	mvnlt r1, r11	; #-32768

	; v3 = osc_pulse(6, 1402, 22, 64);
	ldr r6, [r10, #AK_OPINSTANCE+4*4]
	adds r6, r6, #1402
	mov r6, r6, asl #16
	mov r6, r6, asr #16	; Sign extend word to long.
	str r6, [r10, #AK_OPINSTANCE+4*4]
	mov r4, #512	; (64-63)<<9
	cmp r6, r4
	mvnlt r2, r11	; #-32768
	movge r2, r11	; #32767
	; v3 = vol(v3, 22)
	mov r14, #22
	mul r2, r14, r2
	mov r2, r2, asr #7

	; v4 = osc_pulse(7, 779, 22, 64);
	ldr r6, [r10, #AK_OPINSTANCE+4*5]
	adds r6, r6, #779
	mov r6, r6, asl #16
	mov r6, r6, asr #16	; Sign extend word to long.
	str r6, [r10, #AK_OPINSTANCE+4*5]
	mov r4, #512	; (64-63)<<9
	cmp r6, r4
	mvnlt r3, r11	; #-32768
	movge r3, r11	; #32767
	; v4 = vol(v4, 22)
	mov r14, #22
	mul r3, r14, r3
	mov r3, r3, asr #7

	; v3 = add(v3, v4);
	mov r2, r2, asl #16
	mov r2, r2, asr #16	; Sign extend word to long.
	mov r3, r3, asl #16
	mov r3, r3, asr #16	; Sign extend word to long.
	add r2, r2, r3
	; v3 = clamp(v3)
	cmp r2, r11		; #32767
	movgt r2, r11	; #32767
	cmn r2, r11		; #-32768
	mvnlt r2, r11	; #-32768

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

	; v1 = add(v1, v3);
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	mov r2, r2, asl #16
	mov r2, r2, asr #16	; Sign extend word to long.
	add r0, r0, r2
	; v1 = clamp(v1)
	cmp r0, r11		; #32767
	movgt r0, r11	; #32767
	cmn r0, r11		; #-32768
	mvnlt r0, r11	; #-32768

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*0]
	cmp r7, r4
	blt Inst1Loop

;----------------------------------------------------------------------------
; Instrument 2 - 'CH'
;----------------------------------------------------------------------------

	; TODO: Delay buffer flag 0.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst2Loop:
	; v1 = clone(smp,0, 0);
	mov r0, r7
	ldr r6, [r10, #AK_SMPADDR+4*0]
	ldr r4, [r10, #AK_SMPLEN+4*0]
	cmp r0, r4
	movge r0, #0
	ldrltb r0, [r6, r0]
	mov r0, r0, asl #24
	mov r0, r0, asr #16

	; v1 = sv_flt_n(1, v1, 127, 127, 2);
	ldr r4, [r10, #AK_OPINSTANCE+4*(0+AK_LPF)]
	ldr r5, [r10, #AK_OPINSTANCE+4*(0+AK_HPF)]
	ldr r6, [r10, #AK_OPINSTANCE+4*(0+AK_BPF)]
	mov r14, r6, asr #7
	mov r12, #127
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
	mov r12, #127
	mla r6, r12, r14, r6
	; r6 = clamp(r6)
	cmp r6, r11		; #32767
	movgt r6, r11	; #32767
	cmn r6, r11		; #-32768
	mvnlt r6, r11	; #-32768
	str r6, [r10, #AK_OPINSTANCE+4*(0+AK_BPF)]
	mov r0, r6

	; v1 = sv_flt_n(2, v1, 127, 127, 2);
	ldr r4, [r10, #AK_OPINSTANCE+4*(3+AK_LPF)]
	ldr r5, [r10, #AK_OPINSTANCE+4*(3+AK_HPF)]
	ldr r6, [r10, #AK_OPINSTANCE+4*(3+AK_BPF)]
	mov r14, r6, asr #7
	mov r12, #127
	mla r4, r14, r12, r4
	; r4 = clamp(r4)
	cmp r4, r11		; #32767
	movgt r4, r11	; #32767
	cmn r4, r11		; #-32768
	mvnlt r4, r11	; #-32768
	str r4, [r10, #AK_OPINSTANCE+4*(3+AK_LPF)]
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
	str r5, [r10, #AK_OPINSTANCE+4*(3+AK_HPF)]
	mov r14, r5, asr #7
	mov r12, #127
	mla r6, r12, r14, r6
	; r6 = clamp(r6)
	cmp r6, r11		; #32767
	movgt r6, r11	; #32767
	cmn r6, r11		; #-32768
	mvnlt r6, r11	; #-32768
	str r6, [r10, #AK_OPINSTANCE+4*(3+AK_BPF)]
	mov r0, r6

	; v1 = sv_flt_n(3, v1, 127, 127, 1);
	ldr r4, [r10, #AK_OPINSTANCE+4*(6+AK_LPF)]
	ldr r5, [r10, #AK_OPINSTANCE+4*(6+AK_HPF)]
	ldr r6, [r10, #AK_OPINSTANCE+4*(6+AK_BPF)]
	mov r14, r6, asr #7
	mov r12, #127
	mla r4, r14, r12, r4
	; r4 = clamp(r4)
	cmp r4, r11		; #32767
	movgt r4, r11	; #32767
	cmn r4, r11		; #-32768
	mvnlt r4, r11	; #-32768
	str r4, [r10, #AK_OPINSTANCE+4*(6+AK_LPF)]
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
	str r5, [r10, #AK_OPINSTANCE+4*(6+AK_HPF)]
	mov r14, r5, asr #7
	mov r12, #127
	mla r6, r12, r14, r6
	; r6 = clamp(r6)
	cmp r6, r11		; #32767
	movgt r6, r11	; #32767
	cmn r6, r11		; #-32768
	mvnlt r6, r11	; #-32768
	str r6, [r10, #AK_OPINSTANCE+4*(6+AK_BPF)]
	mov r0, r5

	; v2 = imported_sample(smp,0);
	mov r1, r7
	ldr r6, [r10, #AK_EXTSMPADDR+4*0]
	ldr r4, [r10, #AK_EXTSMPLEN+4*0]
	cmp r1, r4
	movge r1, #0
	ldrltb r1, [r6, r1]
	mov r1, r1, asl #24
	mov r1, r1, asr #16

	; v2 = add(v3, v2);
	mov r2, r2, asl #16
	mov r2, r2, asr #16	; Sign extend word to long.
	mov r1, r1, asl #16
	mov r1, r1, asr #16	; Sign extend word to long.
	add r1, r2, r1
	; v2 = clamp(v2)
	cmp r1, r11		; #32767
	movgt r1, r11	; #32767
	cmn r1, r11		; #-32768
	mvnlt r1, r11	; #-32768

	; v3 = dly_cyc(7, v2, 3, 127);
	mov r4, r1
	; r4 = vol(r4, 127)
	mov r14, #127
	mul r4, r14, r4
	mov r4, r4, asr #7
	ldr r6, [r10, #AK_OPINSTANCE+4*9]
	str r4, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #3
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*9]
	ldr r2, [r9, r6, lsl #2]
	add r9, r9, #2048*4

	; v3 = mul(v3, 32767);
	mov r14, #32767
	mul r2, r14, r2
	mov r2, r2, asr #15

	; v2 = sh(9, v2, 3);
	ldr r6, [r10, #AK_OPINSTANCE+4*10]
	subs r6, r6, #1
	strlt r1, [r10, #AK_OPINSTANCE+4*11]
	movlt r6, #2
	str r6, [r10, #AK_OPINSTANCE+4*10]
	ldr r1, [r10, #AK_OPINSTANCE+4*11]

	; v1 = mul(v1, v2);
	mul r0, r1, r0
	mov r0, r0, asr #15

	sub r9, r9, #2048*4*1
	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*1]
	cmp r7, r4
	blt Inst2Loop

;----------------------------------------------------------------------------
; Instrument 3 - 'OH'
;----------------------------------------------------------------------------

	; TODO: Delay buffer flag 1.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst3Loop:
	; v1 = clone(smp,0, 0);
	mov r0, r7
	ldr r6, [r10, #AK_SMPADDR+4*0]
	ldr r4, [r10, #AK_SMPLEN+4*0]
	cmp r0, r4
	movge r0, #0
	ldrltb r0, [r6, r0]
	mov r0, r0, asl #24
	mov r0, r0, asr #16

	; v1 = sv_flt_n(1, v1, 127, 127, 2);
	ldr r4, [r10, #AK_OPINSTANCE+4*(0+AK_LPF)]
	ldr r5, [r10, #AK_OPINSTANCE+4*(0+AK_HPF)]
	ldr r6, [r10, #AK_OPINSTANCE+4*(0+AK_BPF)]
	mov r14, r6, asr #7
	mov r12, #127
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
	mov r12, #127
	mla r6, r12, r14, r6
	; r6 = clamp(r6)
	cmp r6, r11		; #32767
	movgt r6, r11	; #32767
	cmn r6, r11		; #-32768
	mvnlt r6, r11	; #-32768
	str r6, [r10, #AK_OPINSTANCE+4*(0+AK_BPF)]
	mov r0, r6

	; v1 = sv_flt_n(2, v1, 127, 127, 2);
	ldr r4, [r10, #AK_OPINSTANCE+4*(3+AK_LPF)]
	ldr r5, [r10, #AK_OPINSTANCE+4*(3+AK_HPF)]
	ldr r6, [r10, #AK_OPINSTANCE+4*(3+AK_BPF)]
	mov r14, r6, asr #7
	mov r12, #127
	mla r4, r14, r12, r4
	; r4 = clamp(r4)
	cmp r4, r11		; #32767
	movgt r4, r11	; #32767
	cmn r4, r11		; #-32768
	mvnlt r4, r11	; #-32768
	str r4, [r10, #AK_OPINSTANCE+4*(3+AK_LPF)]
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
	str r5, [r10, #AK_OPINSTANCE+4*(3+AK_HPF)]
	mov r14, r5, asr #7
	mov r12, #127
	mla r6, r12, r14, r6
	; r6 = clamp(r6)
	cmp r6, r11		; #32767
	movgt r6, r11	; #32767
	cmn r6, r11		; #-32768
	mvnlt r6, r11	; #-32768
	str r6, [r10, #AK_OPINSTANCE+4*(3+AK_BPF)]
	mov r0, r6

	; v1 = sv_flt_n(3, v1, 127, 127, 1);
	ldr r4, [r10, #AK_OPINSTANCE+4*(6+AK_LPF)]
	ldr r5, [r10, #AK_OPINSTANCE+4*(6+AK_HPF)]
	ldr r6, [r10, #AK_OPINSTANCE+4*(6+AK_BPF)]
	mov r14, r6, asr #7
	mov r12, #127
	mla r4, r14, r12, r4
	; r4 = clamp(r4)
	cmp r4, r11		; #32767
	movgt r4, r11	; #32767
	cmn r4, r11		; #-32768
	mvnlt r4, r11	; #-32768
	str r4, [r10, #AK_OPINSTANCE+4*(6+AK_LPF)]
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
	str r5, [r10, #AK_OPINSTANCE+4*(6+AK_HPF)]
	mov r14, r5, asr #7
	mov r12, #127
	mla r6, r12, r14, r6
	; r6 = clamp(r6)
	cmp r6, r11		; #32767
	movgt r6, r11	; #32767
	cmn r6, r11		; #-32768
	mvnlt r6, r11	; #-32768
	str r6, [r10, #AK_OPINSTANCE+4*(6+AK_BPF)]
	mov r0, r5

	; v2 = imported_sample(smp,0);
	mov r1, r7
	ldr r6, [r10, #AK_EXTSMPADDR+4*0]
	ldr r4, [r10, #AK_EXTSMPLEN+4*0]
	cmp r1, r4
	movge r1, #0
	ldrltb r1, [r6, r1]
	mov r1, r1, asl #24
	mov r1, r1, asr #16

	; v2 = add(v3, v2);
	mov r2, r2, asl #16
	mov r2, r2, asr #16	; Sign extend word to long.
	mov r1, r1, asl #16
	mov r1, r1, asr #16	; Sign extend word to long.
	add r1, r2, r1
	; v2 = clamp(v2)
	cmp r1, r11		; #32767
	movgt r1, r11	; #32767
	cmn r1, r11		; #-32768
	mvnlt r1, r11	; #-32768

	; v3 = dly_cyc(7, v2, 3, 127);
	mov r4, r1
	; r4 = vol(r4, 127)
	mov r14, #127
	mul r4, r14, r4
	mov r4, r4, asr #7
	ldr r6, [r10, #AK_OPINSTANCE+4*9]
	str r4, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #3
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*9]
	ldr r2, [r9, r6, lsl #2]
	add r9, r9, #2048*4

	; v3 = mul(v3, 32767);
	mov r14, #32767
	mul r2, r14, r2
	mov r2, r2, asr #15

	; v2 = sh(9, v2, 3);
	ldr r6, [r10, #AK_OPINSTANCE+4*10]
	subs r6, r6, #1
	strlt r1, [r10, #AK_OPINSTANCE+4*11]
	movlt r6, #2
	str r6, [r10, #AK_OPINSTANCE+4*10]
	ldr r1, [r10, #AK_OPINSTANCE+4*11]

	; v2 = dly_cyc(10, v2, 2047, 127);
	mov r4, r1
	; r4 = vol(r4, 127)
	mov r14, #127
	mul r4, r14, r4
	mov r4, r4, asr #7
	ldr r6, [r10, #AK_OPINSTANCE+4*12]
	str r4, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #2047
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*12]
	ldr r1, [r9, r6, lsl #2]
	add r9, r9, #2048*4

	; v2 = dly_cyc(11, v2, 920, 127);
	mov r4, r1
	; r4 = vol(r4, 127)
	mov r14, #127
	mul r4, r14, r4
	mov r4, r4, asr #7
	ldr r6, [r10, #AK_OPINSTANCE+4*13]
	str r4, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #920
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*13]
	ldr r1, [r9, r6, lsl #2]
	add r9, r9, #2048*4

	; v4 = osc_pulse(12, 11, 64, 63);
	ldr r6, [r10, #AK_OPINSTANCE+4*14]
	adds r6, r6, #11
	mov r6, r6, asl #16
	mov r6, r6, asr #16	; Sign extend word to long.
	str r6, [r10, #AK_OPINSTANCE+4*14]
	mov r4, #0	; (63-63)<<9
	cmp r6, r4
	mvnlt r3, r11	; #-32768
	movge r3, r11	; #32767
	; v4 = vol(v4, 64)
	mov r3, r3, asr #1	; val<<6>>7

	; v4 = add(v4, 16384);
	mov r3, r3, asl #16
	mov r3, r3, asr #16	; Sign extend word to long.
	mov r14, #16384
	add r3, r3, r14
	; v4 = clamp(v4)
	cmp r3, r11		; #32767
	movgt r3, r11	; #32767
	cmn r3, r11		; #-32768
	mvnlt r3, r11	; #-32768

	; v2 = add(v4, v2);
	mov r3, r3, asl #16
	mov r3, r3, asr #16	; Sign extend word to long.
	mov r1, r1, asl #16
	mov r1, r1, asr #16	; Sign extend word to long.
	add r1, r3, r1
	; v2 = clamp(v2)
	cmp r1, r11		; #32767
	movgt r1, r11	; #32767
	cmn r1, r11		; #-32768
	mvnlt r1, r11	; #-32768

	; v1 = mul(v1, v2);
	mul r0, r1, r0
	mov r0, r0, asr #15

	sub r9, r9, #2048*4*3
	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*2]
	cmp r7, r4
	blt Inst3Loop

;----------------------------------------------------------------------------
; Instrument 4 - '808 Kick V1'
;----------------------------------------------------------------------------

	; TODO: Delay buffer flag 3.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst4Loop:
	; v1 = envd(0, 5, 0, 94);
	mov r4, #8192
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	movle r6, #0
	mov r0, r6
	; v1 = vol(v1, 94)
	mov r14, #94
	mul r0, r14, r0
	mov r0, r0, asr #7

	; v1 = mul(v1, v1);
	mov r14, r0
	mul r0, r14, r0
	mov r0, r0, asr #15

	; v1 = mul(v1, v1);
	mov r14, r0
	mul r0, r14, r0
	mov r0, r0, asr #15

	; v1 = mul(v1, v1);
	mov r14, r0
	mul r0, r14, r0
	mov r0, r0, asr #15

	; v1 = add(v1, 128);
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	mov r14, #128
	add r0, r0, r14
	; v1 = clamp(v1)
	cmp r0, r11		; #32767
	movgt r0, r11	; #32767
	cmn r0, r11		; #-32768
	mvnlt r0, r11	; #-32768

	; v1 = osc_sine(5, v1, 127);
	ldr r6, [r10, #AK_OPINSTANCE+4*0]
	add r6, r6, r0
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
	; v1 = vol(v1, 127)
	mov r14, #127
	mul r0, r14, r0
	mov r0, r0, asr #7

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*3]
	cmp r7, r4
	blt Inst4Loop

;----------------------------------------------------------------------------
; Instrument 5 - '808 Snare V1'
;----------------------------------------------------------------------------

	; TODO: Delay buffer flag 0.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst5Loop:
	; v2 = envd(0, 7, 0, 127);
	mov r4, #4681
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	movle r6, #0
	mov r1, r6
	; v2 = vol(v2, 127)
	mov r14, #127
	mul r1, r14, r1
	mov r1, r1, asr #7

	; v3 = envd(1, 4, 0, 127);
	mov r4, #10922
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	movle r6, #0
	mov r2, r6
	; v3 = vol(v3, 127)
	mov r14, #127
	mul r2, r14, r2
	mov r2, r2, asr #7

	; v1 = osc_sine(3, 768, 44);
	ldr r6, [r10, #AK_OPINSTANCE+4*0]
	add r6, r6, #768
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
	; v1 = vol(v1, 44)
	mov r14, #44
	mul r0, r14, r0
	mov r0, r0, asr #7

	; v1 = mul(v1, v2);
	mul r0, r1, r0
	mov r0, r0, asr #15

	; v4 = osc_sine(5, 1152, 44);
	ldr r6, [r10, #AK_OPINSTANCE+4*1]
	add r6, r6, #1152
	str r6, [r10, #AK_OPINSTANCE+4*1]
	sub r6, r6, #16384
	mov r6, r6, asl #16
	mov r6, r6, asr #16	; Sign extend word to long.
	movs r4, r6
	rsblt r4, r4, #0
	sub r4, r11, r4	; #32767
	mul r4, r6, r4
	mov r4, r4, asr #16
	mov r3, r4, asl #3
	; v4 = vol(v4, 44)
	mov r14, #44
	mul r3, r14, r3
	mov r3, r3, asr #7

	; v4 = mul(v4, v3);
	mul r3, r2, r3
	mov r3, r3, asr #15

	; v1 = add(v4, v1);
	mov r3, r3, asl #16
	mov r3, r3, asr #16	; Sign extend word to long.
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r0, r3, r0
	; v1 = clamp(v1)
	cmp r0, r11		; #32767
	movgt r0, r11	; #32767
	cmn r0, r11		; #-32768
	mvnlt r0, r11	; #-32768

	; v2 = envd(9, 8, 0, 127);
	mov r4, #3640
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	movle r6, #0
	mov r1, r6
	; v2 = vol(v2, 127)
	mov r14, #127
	mul r1, r14, r1
	mov r1, r1, asr #7

	; v3 = osc_noise(44);
	ldr r4, [r10, #AK_NOISESEEDS+0]
	ldr r6, [r10, #AK_NOISESEEDS+4]
	eor r4, r4, r6
	str r4, [r10, #AK_NOISESEEDS+0]
	ldr r2, [r10, #AK_NOISESEEDS+8]
	add r2, r2, r6
	str r2, [r10, #AK_NOISESEEDS+8]
	add r6, r6, r4
	str r6, [r10, #AK_NOISESEEDS+4]
	mov r2, r2, asl #16
	mov r2, r2, asr #16	; Sign extend word to long.
	; v3 = vol(v3, 44)
	mov r14, #44
	mul r2, r14, r2
	mov r2, r2, asr #7

	; v3 = sv_flt_n(11, v3, 112, 101, 1);
	ldr r4, [r10, #AK_OPINSTANCE+4*(2+AK_LPF)]
	ldr r5, [r10, #AK_OPINSTANCE+4*(2+AK_HPF)]
	ldr r6, [r10, #AK_OPINSTANCE+4*(2+AK_BPF)]
	mov r14, r6, asr #7
	mov r12, #112
	mla r4, r14, r12, r4
	; r4 = clamp(r4)
	cmp r4, r11		; #32767
	movgt r4, r11	; #32767
	cmn r4, r11		; #-32768
	mvnlt r4, r11	; #-32768
	str r4, [r10, #AK_OPINSTANCE+4*(2+AK_LPF)]
	mov r12, #101
	mul r14, r12, r14
	mov r12, r2
	sub r12, r12, r4
	sub r5, r12, r14
	; r5 = clamp(r5)
	cmp r5, r11		; #32767
	movgt r5, r11	; #32767
	cmn r5, r11		; #-32768
	mvnlt r5, r11	; #-32768
	str r5, [r10, #AK_OPINSTANCE+4*(2+AK_HPF)]
	mov r14, r5, asr #7
	mov r12, #112
	mla r6, r12, r14, r6
	; r6 = clamp(r6)
	cmp r6, r11		; #32767
	movgt r6, r11	; #32767
	cmn r6, r11		; #-32768
	mvnlt r6, r11	; #-32768
	str r6, [r10, #AK_OPINSTANCE+4*(2+AK_BPF)]
	mov r2, r5

	; v3 = mul(v2, v3);
	mul r2, r1, r2
	mov r2, r2, asr #15

	; v1 = add(v1, v3);
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	mov r2, r2, asl #16
	mov r2, r2, asr #16	; Sign extend word to long.
	add r0, r0, r2
	; v1 = clamp(v1)
	cmp r0, r11		; #32767
	movgt r0, r11	; #32767
	cmn r0, r11		; #-32768
	mvnlt r0, r11	; #-32768

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*4]
	cmp r7, r4
	blt Inst5Loop

;----------------------------------------------------------------------------
; Instrument 6 - 'Kick+Snare'
;----------------------------------------------------------------------------

	; TODO: Delay buffer flag 0.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst6Loop:
	; v1 = clone(smp,3, 0);
	mov r0, r7
	ldr r6, [r10, #AK_SMPADDR+4*3]
	ldr r4, [r10, #AK_SMPLEN+4*3]
	cmp r0, r4
	movge r0, #0
	ldrltb r0, [r6, r0]
	mov r0, r0, asl #24
	mov r0, r0, asr #16

	; v2 = clone(smp,4, 0);
	mov r1, r7
	ldr r6, [r10, #AK_SMPADDR+4*4]
	ldr r4, [r10, #AK_SMPLEN+4*4]
	cmp r1, r4
	movge r1, #0
	ldrltb r1, [r6, r1]
	mov r1, r1, asl #24
	mov r1, r1, asr #16

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
	ldr r4, [r10, #AK_SMPLEN+4*5]
	cmp r7, r4
	blt Inst6Loop

;----------------------------------------------------------------------------
; Instrument 7 - 'Pad Poly Saw'
;----------------------------------------------------------------------------

	; TODO: Delay buffer flag 0.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst7Loop:
	; v1 = osc_saw(0, 1024, 127);
	ldr r0, [r10, #AK_OPINSTANCE+4*0]
	add r0, r0, #1024
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	str r0, [r10, #AK_OPINSTANCE+4*0]	
	; v1 = vol(v1, 127)
	mov r14, #127
	mul r0, r14, r0
	mov r0, r0, asr #7

	; v2 = osc_saw(1, 1018, 127);
	ldr r1, [r10, #AK_OPINSTANCE+4*1]
	add r1, r1, #1018
	mov r1, r1, asl #16
	mov r1, r1, asr #16	; Sign extend word to long.
	str r1, [r10, #AK_OPINSTANCE+4*1]	
	; v2 = vol(v2, 127)
	mov r14, #127
	mul r1, r14, r1
	mov r1, r1, asr #7

	; v3 = osc_saw(2, 1030, 127);
	ldr r2, [r10, #AK_OPINSTANCE+4*2]
	add r2, r2, #1030
	mov r2, r2, asl #16
	mov r2, r2, asr #16	; Sign extend word to long.
	str r2, [r10, #AK_OPINSTANCE+4*2]	
	; v3 = vol(v3, 127)
	mov r14, #127
	mul r2, r14, r2
	mov r2, r2, asr #7

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

	; v1 = add(v1, v3);
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	mov r2, r2, asl #16
	mov r2, r2, asr #16	; Sign extend word to long.
	add r0, r0, r2
	; v1 = clamp(v1)
	cmp r0, r11		; #32767
	movgt r0, r11	; #32767
	cmn r0, r11		; #-32768
	mvnlt r0, r11	; #-32768

	; v2 = osc_tri(5, 1, 101);
	ldr r6, [r10, #AK_OPINSTANCE+4*3]
	add r6, r6, #1
	mov r6, r6, asl #16
	mov r6, r6, asr #16	; Sign extend word to long.
	str r6, [r10, #AK_OPINSTANCE+4*3]
	cmp r6, #0
	mvnmi r6, r6
	sub r6, r6, #16384
	mov r1, r6, asl #1
	; v2 = vol(v2, 101)
	mov r14, #101
	mul r1, r14, r1
	mov r1, r1, asr #7

	; v2 = add(v2, 1424);
	mov r1, r1, asl #16
	mov r1, r1, asr #16	; Sign extend word to long.
	mov r14, #1424
	add r1, r1, r14
	; v2 = clamp(v2)
	cmp r1, r11		; #32767
	movgt r1, r11	; #32767
	cmn r1, r11		; #-32768
	mvnlt r1, r11	; #-32768

	; v2 = ctrl(v2);
	mov r1, r1, asr #9
	mov r1, r1, asl #16
	mov r1, r1, asr #16	; Sign extend word to long.
	add r1, r1, #64

	; v1 = sv_flt_n(8, v1, v2, 77, 2);
	ldr r4, [r10, #AK_OPINSTANCE+4*(4+AK_LPF)]
	ldr r5, [r10, #AK_OPINSTANCE+4*(4+AK_HPF)]
	ldr r6, [r10, #AK_OPINSTANCE+4*(4+AK_BPF)]
	mov r14, r6, asr #7
	mla r4, r1, r14, r4
	; r4 = clamp(r4)
	cmp r4, r11		; #32767
	movgt r4, r11	; #32767
	cmn r4, r11		; #-32768
	mvnlt r4, r11	; #-32768
	str r4, [r10, #AK_OPINSTANCE+4*(4+AK_LPF)]
	mov r12, #77
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
	mla r6, r1, r14, r6
	; r6 = clamp(r6)
	cmp r6, r11		; #32767
	movgt r6, r11	; #32767
	cmn r6, r11		; #-32768
	mvnlt r6, r11	; #-32768
	str r6, [r10, #AK_OPINSTANCE+4*(4+AK_BPF)]
	mov r0, r6

	; v1 = sv_flt_n(9, v1, 46, 127, 2);
	ldr r4, [r10, #AK_OPINSTANCE+4*(7+AK_LPF)]
	ldr r5, [r10, #AK_OPINSTANCE+4*(7+AK_HPF)]
	ldr r6, [r10, #AK_OPINSTANCE+4*(7+AK_BPF)]
	mov r14, r6, asr #7
	mov r12, #46
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
	mov r12, #46
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
	ldr r4, [r10, #AK_SMPLEN+4*6]
	cmp r7, r4
	blt Inst7Loop

;----------------------------------------------------------------------------
; Instrument 8 - 'CHord 1'
;----------------------------------------------------------------------------

	; TODO: Delay buffer flag 0.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst8Loop:
	; v1 = chordgen(0, 6, 3, 7, 10, 127);
	ldr r4, [r10, #AK_SMPADDR+4*6]
	ldr r12, [r10, #AK_SMPLEN+4*6]
	ldrb r6, [r4, r7]
	mov r6, r6, asl #24
	mov r6, r6, asr #17
	add r4, r4, #127
	sub r12, r12, #127
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

	; v1 = sv_flt_n(1, v1, 5, 127, 2);
	ldr r4, [r10, #AK_OPINSTANCE+4*(3+AK_LPF)]
	ldr r5, [r10, #AK_OPINSTANCE+4*(3+AK_HPF)]
	ldr r6, [r10, #AK_OPINSTANCE+4*(3+AK_BPF)]
	mov r14, r6, asr #7
	mov r12, #5
	mla r4, r14, r12, r4
	; r4 = clamp(r4)
	cmp r4, r11		; #32767
	movgt r4, r11	; #32767
	cmn r4, r11		; #-32768
	mvnlt r4, r11	; #-32768
	str r4, [r10, #AK_OPINSTANCE+4*(3+AK_LPF)]
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
	str r5, [r10, #AK_OPINSTANCE+4*(3+AK_HPF)]
	mov r14, r5, asr #7
	mov r12, #5
	mla r6, r12, r14, r6
	; r6 = clamp(r6)
	cmp r6, r11		; #32767
	movgt r6, r11	; #32767
	cmn r6, r11		; #-32768
	mvnlt r6, r11	; #-32768
	str r6, [r10, #AK_OPINSTANCE+4*(3+AK_BPF)]
	mov r0, r6

	; v1 = add(v1, v1);
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r0, r0, r0
	; v1 = clamp(v1)
	cmp r0, r11		; #32767
	movgt r0, r11	; #32767
	cmn r0, r11		; #-32768
	mvnlt r0, r11	; #-32768

	; v1 = add(v1, v1);
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r0, r0, r0
	; v1 = clamp(v1)
	cmp r0, r11		; #32767
	movgt r0, r11	; #32767
	cmn r0, r11		; #-32768
	mvnlt r0, r11	; #-32768

	; v1 = add(v1, v1);
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r0, r0, r0
	; v1 = clamp(v1)
	cmp r0, r11		; #32767
	movgt r0, r11	; #32767
	cmn r0, r11		; #-32768
	mvnlt r0, r11	; #-32768

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*7]
	cmp r7, r4
	blt Inst8Loop

;----------------------------------------------------------------------------
; Instrument 8 - Loop Generator (Offset: 16384 Length: 16384)
;----------------------------------------------------------------------------

	mov r7, #16384
	ldr r6, [r10, #AK_SMPADDR+4*7]
	add r6, r6, #16384	; src1
	sub r4, r6, r7	; src2
	mov r0, r11, lsl #8	; 32767<<8
	mov r1, r7
	bl divide
	mov r5, r0	; delta = divs.w(32767<<8,repeat_length)
	mov r14, #0	; rampup
	mov r12, r11, lsl #8	; rampdown
LoopGen_7:
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
	bne LoopGen_7

;----------------------------------------------------------------------------
; Instrument 9 - 'Chord2'
;----------------------------------------------------------------------------

	; TODO: Delay buffer flag 0.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst9Loop:
	; v1 = chordgen(0, 6, 2, 7, 9, 0);
	ldr r4, [r10, #AK_SMPADDR+4*6]
	ldr r12, [r10, #AK_SMPLEN+4*6]
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
	add r5, r5, #98048
	str r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD2)]
	mov r14, r14, asl #24
	add r6, r6, r14, asr #17
	ldr r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD3)]
	cmp r12, r5, lsr #15
	ldrgeb r14, [r4, r5, lsr #15]
	movlt r14, #0
	add r5, r5, #55040
	str r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD3)]
	mov r14, r14, asl #24
	add r6, r6, r14, asr #17
	mov r0, r6
	; v1 = clamp(v1)
	cmp r0, r11		; #32767
	movgt r0, r11	; #32767
	cmn r0, r11		; #-32768
	mvnlt r0, r11	; #-32768

	; v1 = sv_flt_n(1, v1, 5, 127, 2);
	ldr r4, [r10, #AK_OPINSTANCE+4*(3+AK_LPF)]
	ldr r5, [r10, #AK_OPINSTANCE+4*(3+AK_HPF)]
	ldr r6, [r10, #AK_OPINSTANCE+4*(3+AK_BPF)]
	mov r14, r6, asr #7
	mov r12, #5
	mla r4, r14, r12, r4
	; r4 = clamp(r4)
	cmp r4, r11		; #32767
	movgt r4, r11	; #32767
	cmn r4, r11		; #-32768
	mvnlt r4, r11	; #-32768
	str r4, [r10, #AK_OPINSTANCE+4*(3+AK_LPF)]
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
	str r5, [r10, #AK_OPINSTANCE+4*(3+AK_HPF)]
	mov r14, r5, asr #7
	mov r12, #5
	mla r6, r12, r14, r6
	; r6 = clamp(r6)
	cmp r6, r11		; #32767
	movgt r6, r11	; #32767
	cmn r6, r11		; #-32768
	mvnlt r6, r11	; #-32768
	str r6, [r10, #AK_OPINSTANCE+4*(3+AK_BPF)]
	mov r0, r6

	; v1 = add(v1, v1);
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r0, r0, r0
	; v1 = clamp(v1)
	cmp r0, r11		; #32767
	movgt r0, r11	; #32767
	cmn r0, r11		; #-32768
	mvnlt r0, r11	; #-32768

	; v1 = add(v1, v1);
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r0, r0, r0
	; v1 = clamp(v1)
	cmp r0, r11		; #32767
	movgt r0, r11	; #32767
	cmn r0, r11		; #-32768
	mvnlt r0, r11	; #-32768

	; v1 = add(v1, v1);
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r0, r0, r0
	; v1 = clamp(v1)
	cmp r0, r11		; #32767
	movgt r0, r11	; #32767
	cmn r0, r11		; #-32768
	mvnlt r0, r11	; #-32768

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*8]
	cmp r7, r4
	blt Inst9Loop

;----------------------------------------------------------------------------
; Instrument 9 - Loop Generator (Offset: 16384 Length: 16384)
;----------------------------------------------------------------------------

	mov r7, #16384
	ldr r6, [r10, #AK_SMPADDR+4*8]
	add r6, r6, #16384	; src1
	sub r4, r6, r7	; src2
	mov r0, r11, lsl #8	; 32767<<8
	mov r1, r7
	bl divide
	mov r5, r0	; delta = divs.w(32767<<8,repeat_length)
	mov r14, #0	; rampup
	mov r12, r11, lsl #8	; rampdown
LoopGen_8:
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
	bne LoopGen_8

;----------------------------------------------------------------------------
; Instrument 10 - 'TEEBEE'
;----------------------------------------------------------------------------

	; TODO: Delay buffer flag 0.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst10Loop:
	; v1 = osc_saw(0, 1024, 58);
	ldr r0, [r10, #AK_OPINSTANCE+4*0]
	add r0, r0, #1024
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	str r0, [r10, #AK_OPINSTANCE+4*0]	
	; v1 = vol(v1, 58)
	mov r14, #58
	mul r0, r14, r0
	mov r0, r0, asr #7

	; v2 = envd(1, 5, 0, 127);
	mov r4, #8192
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	movle r6, #0
	mov r1, r6
	; v2 = vol(v2, 127)
	mov r14, #127
	mul r1, r14, r1
	mov r1, r1, asr #7

	; v2 = add(v2, -22320);
	mov r1, r1, asl #16
	mov r1, r1, asr #16	; Sign extend word to long.
	mvn r14, #22319
	add r1, r1, r14
	; v2 = clamp(v2)
	cmp r1, r11		; #32767
	movgt r1, r11	; #32767
	cmn r1, r11		; #-32768
	mvnlt r1, r11	; #-32768

	; v2 = ctrl(v2);
	mov r1, r1, asr #9
	mov r1, r1, asl #16
	mov r1, r1, asr #16	; Sign extend word to long.
	add r1, r1, #64

	; v1 = sv_flt_n(4, v1, v2, 5, 0);
	ldr r4, [r10, #AK_OPINSTANCE+4*(1+AK_LPF)]
	ldr r5, [r10, #AK_OPINSTANCE+4*(1+AK_HPF)]
	ldr r6, [r10, #AK_OPINSTANCE+4*(1+AK_BPF)]
	mov r14, r6, asr #7
	mla r4, r1, r14, r4
	; r4 = clamp(r4)
	cmp r4, r11		; #32767
	movgt r4, r11	; #32767
	cmn r4, r11		; #-32768
	mvnlt r4, r11	; #-32768
	str r4, [r10, #AK_OPINSTANCE+4*(1+AK_LPF)]
	mov r12, #5
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
	mla r6, r1, r14, r6
	; r6 = clamp(r6)
	cmp r6, r11		; #32767
	movgt r6, r11	; #32767
	cmn r6, r11		; #-32768
	mvnlt r6, r11	; #-32768
	str r6, [r10, #AK_OPINSTANCE+4*(1+AK_BPF)]
	mov r0, r4

	; v2 = envd(5, 9, 0, 127);
	mov r4, #2978
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

	; v2 = reverb(v1, 94, 7);
	ldr r6, [r10, #AK_OPINSTANCE+4*4]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 94)
	mov r14, #94
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
	str r6, [r10, #AK_OPINSTANCE+4*4]
	; r12 = vol(r12, 7)
	mov r14, #7
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r9, r9, #2048*4
	mov r5, r12
	ldr r6, [r10, #AK_OPINSTANCE+4*5]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 94)
	mov r14, #94
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
	str r6, [r10, #AK_OPINSTANCE+4*5]
	; r12 = vol(r12, 7)
	mov r14, #7
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r9, r9, #2048*4
	add r5, r5, r12
	ldr r6, [r10, #AK_OPINSTANCE+4*6]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 94)
	mov r14, #94
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
	str r6, [r10, #AK_OPINSTANCE+4*6]
	; r12 = vol(r12, 7)
	mov r14, #7
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r9, r9, #2048*4
	add r5, r5, r12
	ldr r6, [r10, #AK_OPINSTANCE+4*7]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 94)
	mov r14, #94
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
	str r6, [r10, #AK_OPINSTANCE+4*7]
	; r12 = vol(r12, 7)
	mov r14, #7
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r9, r9, #2048*4
	add r5, r5, r12
	ldr r6, [r10, #AK_OPINSTANCE+4*8]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 94)
	mov r14, #94
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
	str r6, [r10, #AK_OPINSTANCE+4*8]
	; r12 = vol(r12, 7)
	mov r14, #7
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r9, r9, #2048*4
	add r5, r5, r12
	ldr r6, [r10, #AK_OPINSTANCE+4*9]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 94)
	mov r14, #94
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
	str r6, [r10, #AK_OPINSTANCE+4*9]
	; r12 = vol(r12, 7)
	mov r14, #7
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r9, r9, #2048*4
	add r5, r5, r12
	ldr r6, [r10, #AK_OPINSTANCE+4*10]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 94)
	mov r14, #94
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
	str r6, [r10, #AK_OPINSTANCE+4*10]
	; r12 = vol(r12, 7)
	mov r14, #7
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r9, r9, #2048*4
	add r5, r5, r12
	ldr r6, [r10, #AK_OPINSTANCE+4*11]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 94)
	mov r14, #94
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
	str r6, [r10, #AK_OPINSTANCE+4*11]
	; r12 = vol(r12, 7)
	mov r14, #7
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r9, r9, #2048*4
	add r1, r5, r12
	; v2 = clamp(v2)
	cmp r1, r11		; #32767
	movgt r1, r11	; #32767
	cmn r1, r11		; #-32768
	mvnlt r1, r11	; #-32768

	; v3 = enva(9, 13, 0, 127);
	ldr r6, [r10, #AK_OPINSTANCE+4*12]
	mov r2, r6, asr #8
	mov r4, #1489
	add r6, r6, r4
	cmp r6, r11, asl #8
	movgt r6, r11, asl #8
	str r6, [r10, #AK_OPINSTANCE+4*12]
	; v3 = vol(v3, 127)
	mov r14, #127
	mul r2, r14, r2
	mov r2, r2, asr #7

	; v2 = mul(v2, v3);
	mul r1, r2, r1
	mov r1, r1, asr #15

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

	sub r9, r9, #2048*4*8
	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*9]
	cmp r7, r4
	blt Inst10Loop

;----------------------------------------------------------------------------
; Instrument 11 - 'Tom'
;----------------------------------------------------------------------------

	; TODO: Delay buffer flag 8.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst11Loop:
	; v1 = imported_sample(smp,0);
	mov r0, r7
	ldr r6, [r10, #AK_EXTSMPADDR+4*0]
	ldr r4, [r10, #AK_EXTSMPLEN+4*0]
	cmp r0, r4
	movge r0, #0
	ldrltb r0, [r6, r0]
	mov r0, r0, asl #24
	mov r0, r0, asr #16

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

	; v2 = dly_cyc(2, v1, 3, 127);
	mov r4, r0
	; r4 = vol(r4, 127)
	mov r14, #127
	mul r4, r14, r4
	mov r4, r4, asr #7
	ldr r6, [r10, #AK_OPINSTANCE+4*0]
	str r4, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #3
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*0]
	ldr r1, [r9, r6, lsl #2]
	add r9, r9, #2048*4

	; v2 = mul(v2, 32767);
	mov r14, #32767
	mul r1, r14, r1
	mov r1, r1, asr #15

	; v1 = sh(4, v1, 3);
	ldr r6, [r10, #AK_OPINSTANCE+4*1]
	subs r6, r6, #1
	strlt r0, [r10, #AK_OPINSTANCE+4*2]
	movlt r6, #2
	str r6, [r10, #AK_OPINSTANCE+4*1]
	ldr r0, [r10, #AK_OPINSTANCE+4*2]

	; v3 = osc_sine(5, 512, 127);
	ldr r6, [r10, #AK_OPINSTANCE+4*3]
	add r6, r6, #512
	str r6, [r10, #AK_OPINSTANCE+4*3]
	sub r6, r6, #16384
	mov r6, r6, asl #16
	mov r6, r6, asr #16	; Sign extend word to long.
	movs r4, r6
	rsblt r4, r4, #0
	sub r4, r11, r4	; #32767
	mul r4, r6, r4
	mov r4, r4, asr #16
	mov r2, r4, asl #3
	; v3 = vol(v3, 127)
	mov r14, #127
	mul r2, r14, r2
	mov r2, r2, asr #7

	; v1 = mul(v1, v3);
	mul r0, r2, r0
	mov r0, r0, asr #15

	sub r9, r9, #2048*4*1
	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*10]
	cmp r7, r4
	blt Inst11Loop

;----------------------------------------------------------------------------
; Instrument 12 - 'Cowbell'
;----------------------------------------------------------------------------

	; TODO: Delay buffer flag 1.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst12Loop:
	; v2 = imported_sample(smp,0);
	mov r1, r7
	ldr r6, [r10, #AK_EXTSMPADDR+4*0]
	ldr r4, [r10, #AK_EXTSMPLEN+4*0]
	cmp r1, r4
	movge r1, #0
	ldrltb r1, [r6, r1]
	mov r1, r1, asl #24
	mov r1, r1, asr #16

	; v2 = add(v2, v3);
	mov r1, r1, asl #16
	mov r1, r1, asr #16	; Sign extend word to long.
	mov r2, r2, asl #16
	mov r2, r2, asr #16	; Sign extend word to long.
	add r1, r1, r2
	; v2 = clamp(v2)
	cmp r1, r11		; #32767
	movgt r1, r11	; #32767
	cmn r1, r11		; #-32768
	mvnlt r1, r11	; #-32768

	; v3 = dly_cyc(3, v2, 2, 127);
	mov r4, r1
	; r4 = vol(r4, 127)
	mov r14, #127
	mul r4, r14, r4
	mov r4, r4, asr #7
	ldr r6, [r10, #AK_OPINSTANCE+4*0]
	str r4, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #2
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*0]
	ldr r2, [r9, r6, lsl #2]
	add r9, r9, #2048*4

	; v3 = mul(v3, 32606);
	mov r14, #32606
	mul r2, r14, r2
	mov r2, r2, asr #15

	; v1 = sh(5, v2, 2);
	ldr r6, [r10, #AK_OPINSTANCE+4*1]
	subs r6, r6, #1
	strlt r1, [r10, #AK_OPINSTANCE+4*2]
	movlt r6, #1
	str r6, [r10, #AK_OPINSTANCE+4*1]
	ldr r0, [r10, #AK_OPINSTANCE+4*2]

	; v4 = envd(6, 11, 0, 6);
	mov r4, #2048
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	movle r6, #0
	mov r3, r6
	; v4 = vol(v4, 6)
	mov r14, #6
	mul r3, r14, r3
	mov r3, r3, asr #7

	; v2 = add(v4, v2);
	mov r3, r3, asl #16
	mov r3, r3, asr #16	; Sign extend word to long.
	mov r1, r1, asl #16
	mov r1, r1, asr #16	; Sign extend word to long.
	add r1, r3, r1
	; v2 = clamp(v2)
	cmp r1, r11		; #32767
	movgt r1, r11	; #32767
	cmn r1, r11		; #-32768
	mvnlt r1, r11	; #-32768

	; v4 = envd(8, 15, 0, 4);
	mov r4, #1129
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	movle r6, #0
	mov r3, r6
	; v4 = vol(v4, 4)
	mov r3, r3, asr #5	; val<<2>>7

	; v2 = add(v2, v4);
	mov r1, r1, asl #16
	mov r1, r1, asr #16	; Sign extend word to long.
	mov r3, r3, asl #16
	mov r3, r3, asr #16	; Sign extend word to long.
	add r1, r1, r3
	; v2 = clamp(v2)
	cmp r1, r11		; #32767
	movgt r1, r11	; #32767
	cmn r1, r11		; #-32768
	mvnlt r1, r11	; #-32768

	; v1 = osc_pulse(10, 2048, 127, 64);
	ldr r6, [r10, #AK_OPINSTANCE+4*3]
	adds r6, r6, #2048
	mov r6, r6, asl #16
	mov r6, r6, asr #16	; Sign extend word to long.
	str r6, [r10, #AK_OPINSTANCE+4*3]
	mov r4, #512	; (64-63)<<9
	cmp r6, r4
	mvnlt r0, r11	; #-32768
	movge r0, r11	; #32767
	; v1 = vol(v1, 127)
	mov r14, #127
	mul r0, r14, r0
	mov r0, r0, asr #7

	; v4 = osc_pulse(11, 3034, 127, 64);
	ldr r6, [r10, #AK_OPINSTANCE+4*4]
	adds r6, r6, #3034
	mov r6, r6, asl #16
	mov r6, r6, asr #16	; Sign extend word to long.
	str r6, [r10, #AK_OPINSTANCE+4*4]
	mov r4, #512	; (64-63)<<9
	cmp r6, r4
	mvnlt r3, r11	; #-32768
	movge r3, r11	; #32767
	; v4 = vol(v4, 127)
	mov r14, #127
	mul r3, r14, r3
	mov r3, r3, asr #7

	; v1 = add(v1, v4);
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	mov r3, r3, asl #16
	mov r3, r3, asr #16	; Sign extend word to long.
	add r0, r0, r3
	; v1 = clamp(v1)
	cmp r0, r11		; #32767
	movgt r0, r11	; #32767
	cmn r0, r11		; #-32768
	mvnlt r0, r11	; #-32768

	; v1 = mul(v1, v2);
	mul r0, r1, r0
	mov r0, r0, asr #15

	; v1 = sv_flt_n(14, v1, 46, 32, 2);
	ldr r4, [r10, #AK_OPINSTANCE+4*(5+AK_LPF)]
	ldr r5, [r10, #AK_OPINSTANCE+4*(5+AK_HPF)]
	ldr r6, [r10, #AK_OPINSTANCE+4*(5+AK_BPF)]
	mov r14, r6, asr #7
	mov r12, #46
	mla r4, r14, r12, r4
	; r4 = clamp(r4)
	cmp r4, r11		; #32767
	movgt r4, r11	; #32767
	cmn r4, r11		; #-32768
	mvnlt r4, r11	; #-32768
	str r4, [r10, #AK_OPINSTANCE+4*(5+AK_LPF)]
	mov r12, #32
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
	mov r12, #46
	mla r6, r12, r14, r6
	; r6 = clamp(r6)
	cmp r6, r11		; #32767
	movgt r6, r11	; #32767
	cmn r6, r11		; #-32768
	mvnlt r6, r11	; #-32768
	str r6, [r10, #AK_OPINSTANCE+4*(5+AK_BPF)]
	mov r0, r6

	sub r9, r9, #2048*4*1
	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*11]
	cmp r7, r4
	blt Inst12Loop

;----------------------------------------------------------------------------
; Instrument 13 - 'Clap env'
;----------------------------------------------------------------------------

	; TODO: Delay buffer flag 1.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst13Loop:
	; v1 = envd(2, 1, 0, 69);
	mov r4, #32767
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	movle r6, #0
	mov r0, r6
	; v1 = vol(v1, 69)
	mov r14, #69
	mul r0, r14, r0
	mov r0, r0, asr #7

	; v2 = envd(3, 3, 0, 29);
	mov r4, #16384
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	movle r6, #0
	mov r1, r6
	; v2 = vol(v2, 29)
	mov r14, #29
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

	; v3 = dly_cyc(5, v1, 202, 127);
	mov r4, r0
	; r4 = vol(r4, 127)
	mov r14, #127
	mul r4, r14, r4
	mov r4, r4, asr #7
	ldr r6, [r10, #AK_OPINSTANCE+4*0]
	str r4, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #202
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*0]
	ldr r2, [r9, r6, lsl #2]
	add r9, r9, #2048*4

	; v4 = dly_cyc(6, v1, 163, 90);
	mov r4, r0
	; r4 = vol(r4, 90)
	mov r14, #90
	mul r4, r14, r4
	mov r4, r4, asr #7
	ldr r6, [r10, #AK_OPINSTANCE+4*1]
	str r4, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #163
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*1]
	ldr r3, [r9, r6, lsl #2]
	add r9, r9, #2048*4

	; v4 = add(v1, v4);
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	mov r3, r3, asl #16
	mov r3, r3, asr #16	; Sign extend word to long.
	add r3, r0, r3
	; v4 = clamp(v4)
	cmp r3, r11		; #32767
	movgt r3, r11	; #32767
	cmn r3, r11		; #-32768
	mvnlt r3, r11	; #-32768

	; v1 = add(v3, v1);
	mov r2, r2, asl #16
	mov r2, r2, asr #16	; Sign extend word to long.
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r0, r2, r0
	; v1 = clamp(v1)
	cmp r0, r11		; #32767
	movgt r0, r11	; #32767
	cmn r0, r11		; #-32768
	mvnlt r0, r11	; #-32768

	; v4 = dly_cyc(10, v4, 429, 127);
	mov r4, r3
	; r4 = vol(r4, 127)
	mov r14, #127
	mul r4, r14, r4
	mov r4, r4, asr #7
	ldr r6, [r10, #AK_OPINSTANCE+4*2]
	str r4, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #429
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*2]
	ldr r3, [r9, r6, lsl #2]
	add r9, r9, #2048*4

	; v1 = add(v1, v4);
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	mov r3, r3, asl #16
	mov r3, r3, asr #16	; Sign extend word to long.
	add r0, r0, r3
	; v1 = clamp(v1)
	cmp r0, r11		; #32767
	movgt r0, r11	; #32767
	cmn r0, r11		; #-32768
	mvnlt r0, r11	; #-32768

	; v3 = envd(12, 15, 0, 20);
	mov r4, #1129
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	movle r6, #0
	mov r2, r6
	; v3 = vol(v3, 20)
	mov r14, #20
	mul r2, r14, r2
	mov r2, r2, asr #7

	; v3 = dly_cyc(14, v3, 591, 127);
	mov r4, r2
	; r4 = vol(r4, 127)
	mov r14, #127
	mul r4, r14, r4
	mov r4, r4, asr #7
	ldr r6, [r10, #AK_OPINSTANCE+4*3]
	str r4, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #591
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*3]
	ldr r2, [r9, r6, lsl #2]
	add r9, r9, #2048*4

	; v1 = add(v1, v3);
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	mov r2, r2, asl #16
	mov r2, r2, asr #16	; Sign extend word to long.
	add r0, r0, r2
	; v1 = clamp(v1)
	cmp r0, r11		; #32767
	movgt r0, r11	; #32767
	cmn r0, r11		; #-32768
	mvnlt r0, r11	; #-32768

	sub r9, r9, #2048*4*4
	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*12]
	cmp r7, r4
	blt Inst13Loop

;----------------------------------------------------------------------------
; Instrument 14 - 'CP'
;----------------------------------------------------------------------------

	; TODO: Delay buffer flag 4.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst14Loop:
	; v1 = clone(smp,12, 0);
	mov r0, r7
	ldr r6, [r10, #AK_SMPADDR+4*12]
	ldr r4, [r10, #AK_SMPLEN+4*12]
	cmp r0, r4
	movge r0, #0
	ldrltb r0, [r6, r0]
	mov r0, r0, asl #24
	mov r0, r0, asr #16

	; v2 = osc_noise(127);
	ldr r4, [r10, #AK_NOISESEEDS+0]
	ldr r6, [r10, #AK_NOISESEEDS+4]
	eor r4, r4, r6
	str r4, [r10, #AK_NOISESEEDS+0]
	ldr r1, [r10, #AK_NOISESEEDS+8]
	add r1, r1, r6
	str r1, [r10, #AK_NOISESEEDS+8]
	add r6, r6, r4
	str r6, [r10, #AK_NOISESEEDS+4]
	mov r1, r1, asl #16
	mov r1, r1, asr #16	; Sign extend word to long.
	; v2 = vol(v2, 127)
	mov r14, #127
	mul r1, r14, r1
	mov r1, r1, asr #7

	; v2 = sv_flt_n(2, v2, 46, 75, 2);
	ldr r4, [r10, #AK_OPINSTANCE+4*(0+AK_LPF)]
	ldr r5, [r10, #AK_OPINSTANCE+4*(0+AK_HPF)]
	ldr r6, [r10, #AK_OPINSTANCE+4*(0+AK_BPF)]
	mov r14, r6, asr #7
	mov r12, #46
	mla r4, r14, r12, r4
	; r4 = clamp(r4)
	cmp r4, r11		; #32767
	movgt r4, r11	; #32767
	cmn r4, r11		; #-32768
	mvnlt r4, r11	; #-32768
	str r4, [r10, #AK_OPINSTANCE+4*(0+AK_LPF)]
	mov r12, #75
	mul r14, r12, r14
	mov r12, r1
	sub r12, r12, r4
	sub r5, r12, r14
	; r5 = clamp(r5)
	cmp r5, r11		; #32767
	movgt r5, r11	; #32767
	cmn r5, r11		; #-32768
	mvnlt r5, r11	; #-32768
	str r5, [r10, #AK_OPINSTANCE+4*(0+AK_HPF)]
	mov r14, r5, asr #7
	mov r12, #46
	mla r6, r12, r14, r6
	; r6 = clamp(r6)
	cmp r6, r11		; #32767
	movgt r6, r11	; #32767
	cmn r6, r11		; #-32768
	mvnlt r6, r11	; #-32768
	str r6, [r10, #AK_OPINSTANCE+4*(0+AK_BPF)]
	mov r1, r6

	; v1 = mul(v2, v1);
	mul r0, r1, r0
	mov r0, r0, asr #15

	; v1 = add(v1, v1);
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r0, r0, r0
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
; Instrument 15 - 'TB low'
;----------------------------------------------------------------------------

	; TODO: Delay buffer flag 0.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst15Loop:
	; v1 = osc_saw(0, 256, 58);
	ldr r0, [r10, #AK_OPINSTANCE+4*0]
	add r0, r0, #256
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	str r0, [r10, #AK_OPINSTANCE+4*0]	
	; v1 = vol(v1, 58)
	mov r14, #58
	mul r0, r14, r0
	mov r0, r0, asr #7

	; v2 = envd(1, 2, 0, 127);
	mov r4, #32767
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	movle r6, #0
	mov r1, r6
	; v2 = vol(v2, 127)
	mov r14, #127
	mul r1, r14, r1
	mov r1, r1, asr #7

	; v2 = add(v2, -9023);
	mov r1, r1, asl #16
	mov r1, r1, asr #16	; Sign extend word to long.
	mvn r14, #9022
	add r1, r1, r14
	; v2 = clamp(v2)
	cmp r1, r11		; #32767
	movgt r1, r11	; #32767
	cmn r1, r11		; #-32768
	mvnlt r1, r11	; #-32768

	; v2 = ctrl(v2);
	mov r1, r1, asr #9
	mov r1, r1, asl #16
	mov r1, r1, asr #16	; Sign extend word to long.
	add r1, r1, #64

	; v3 = enva(4, 6, 0, 127);
	ldr r6, [r10, #AK_OPINSTANCE+4*1]
	mov r2, r6, asr #8
	mov r4, #6553
	add r6, r6, r4
	cmp r6, r11, asl #8
	movgt r6, r11, asl #8
	str r6, [r10, #AK_OPINSTANCE+4*1]
	; v3 = vol(v3, 127)
	mov r14, #127
	mul r2, r14, r2
	mov r2, r2, asr #7

	; v3 = add(v3, -31818);
	mov r2, r2, asl #16
	mov r2, r2, asr #16	; Sign extend word to long.
	mvn r14, #31817
	add r2, r2, r14
	; v3 = clamp(v3)
	cmp r2, r11		; #32767
	movgt r2, r11	; #32767
	cmn r2, r11		; #-32768
	mvnlt r2, r11	; #-32768

	; v3 = ctrl(v3);
	mov r2, r2, asr #9
	mov r2, r2, asl #16
	mov r2, r2, asr #16	; Sign extend word to long.
	add r2, r2, #64

	; v1 = sv_flt_n(7, v1, v2, v3, 0);
	ldr r4, [r10, #AK_OPINSTANCE+4*(2+AK_LPF)]
	ldr r5, [r10, #AK_OPINSTANCE+4*(2+AK_HPF)]
	ldr r6, [r10, #AK_OPINSTANCE+4*(2+AK_BPF)]
	mov r14, r6, asr #7
	mla r4, r1, r14, r4
	; r4 = clamp(r4)
	cmp r4, r11		; #32767
	movgt r4, r11	; #32767
	cmn r4, r11		; #-32768
	mvnlt r4, r11	; #-32768
	str r4, [r10, #AK_OPINSTANCE+4*(2+AK_LPF)]
	mul r14, r2, r14
	mov r12, r0
	sub r12, r12, r4
	sub r5, r12, r14
	; r5 = clamp(r5)
	cmp r5, r11		; #32767
	movgt r5, r11	; #32767
	cmn r5, r11		; #-32768
	mvnlt r5, r11	; #-32768
	str r5, [r10, #AK_OPINSTANCE+4*(2+AK_HPF)]
	mov r14, r5, asr #7
	mla r6, r1, r14, r6
	; r6 = clamp(r6)
	cmp r6, r11		; #32767
	movgt r6, r11	; #32767
	cmn r6, r11		; #-32768
	mvnlt r6, r11	; #-32768
	str r6, [r10, #AK_OPINSTANCE+4*(2+AK_BPF)]
	mov r0, r4

	; v2 = envd(8, 12, 0, 127);
	mov r4, #1724
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

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*14]
	cmp r7, r4
	blt Inst15Loop

;----------------------------------------------------------------------------
; Instrument 16 - 'TB cutoff increase'
;----------------------------------------------------------------------------

	; TODO: Delay buffer flag 0.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst16Loop:
	; v1 = osc_saw(0, 256, 58);
	ldr r0, [r10, #AK_OPINSTANCE+4*0]
	add r0, r0, #256
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	str r0, [r10, #AK_OPINSTANCE+4*0]	
	; v1 = vol(v1, 58)
	mov r14, #58
	mul r0, r14, r0
	mov r0, r0, asr #7

	; v2 = envd(1, 2, 0, 127);
	mov r4, #32767
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	movle r6, #0
	mov r1, r6
	; v2 = vol(v2, 127)
	mov r14, #127
	mul r1, r14, r1
	mov r1, r1, asr #7

	; v2 = add(v2, 5223);
	mov r1, r1, asl #16
	mov r1, r1, asr #16	; Sign extend word to long.
	mov r14, #5223
	add r1, r1, r14
	; v2 = clamp(v2)
	cmp r1, r11		; #32767
	movgt r1, r11	; #32767
	cmn r1, r11		; #-32768
	mvnlt r1, r11	; #-32768

	; v2 = ctrl(v2);
	mov r1, r1, asr #9
	mov r1, r1, asl #16
	mov r1, r1, asr #16	; Sign extend word to long.
	add r1, r1, #64

	; v3 = enva(4, 6, 0, 127);
	ldr r6, [r10, #AK_OPINSTANCE+4*1]
	mov r2, r6, asr #8
	mov r4, #6553
	add r6, r6, r4
	cmp r6, r11, asl #8
	movgt r6, r11, asl #8
	str r6, [r10, #AK_OPINSTANCE+4*1]
	; v3 = vol(v3, 127)
	mov r14, #127
	mul r2, r14, r2
	mov r2, r2, asr #7

	; v3 = add(v3, -31818);
	mov r2, r2, asl #16
	mov r2, r2, asr #16	; Sign extend word to long.
	mvn r14, #31817
	add r2, r2, r14
	; v3 = clamp(v3)
	cmp r2, r11		; #32767
	movgt r2, r11	; #32767
	cmn r2, r11		; #-32768
	mvnlt r2, r11	; #-32768

	; v3 = ctrl(v3);
	mov r2, r2, asr #9
	mov r2, r2, asl #16
	mov r2, r2, asr #16	; Sign extend word to long.
	add r2, r2, #64

	; v1 = sv_flt_n(7, v1, v2, v3, 0);
	ldr r4, [r10, #AK_OPINSTANCE+4*(2+AK_LPF)]
	ldr r5, [r10, #AK_OPINSTANCE+4*(2+AK_HPF)]
	ldr r6, [r10, #AK_OPINSTANCE+4*(2+AK_BPF)]
	mov r14, r6, asr #7
	mla r4, r1, r14, r4
	; r4 = clamp(r4)
	cmp r4, r11		; #32767
	movgt r4, r11	; #32767
	cmn r4, r11		; #-32768
	mvnlt r4, r11	; #-32768
	str r4, [r10, #AK_OPINSTANCE+4*(2+AK_LPF)]
	mul r14, r2, r14
	mov r12, r0
	sub r12, r12, r4
	sub r5, r12, r14
	; r5 = clamp(r5)
	cmp r5, r11		; #32767
	movgt r5, r11	; #32767
	cmn r5, r11		; #-32768
	mvnlt r5, r11	; #-32768
	str r5, [r10, #AK_OPINSTANCE+4*(2+AK_HPF)]
	mov r14, r5, asr #7
	mla r6, r1, r14, r6
	; r6 = clamp(r6)
	cmp r6, r11		; #32767
	movgt r6, r11	; #32767
	cmn r6, r11		; #-32768
	mvnlt r6, r11	; #-32768
	str r6, [r10, #AK_OPINSTANCE+4*(2+AK_BPF)]
	mov r0, r4

	; v2 = envd(8, 12, 0, 127);
	mov r4, #1724
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

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*15]
	cmp r7, r4
	blt Inst16Loop

;----------------------------------------------------------------------------
; Instrument 17 - 'Instrument_17'
;----------------------------------------------------------------------------

	; TODO: Delay buffer flag 0.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst17Loop:
	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*16]
	cmp r7, r4
	blt Inst17Loop

; ============================================================================

.if AK_CLEAR_FIRST_2_BYTES
	; Clear first 2 bytes of each sample
	adr r4, AK_SmpAddr
	mov r7, #17
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
	.rept 15
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
	.long 0x0000136c	; Instrument 1 Length
	.long 0x000005ec	; Instrument 2 Length
	.long 0x0000136c	; Instrument 3 Length
	.long 0x00000d8a	; Instrument 4 Length
	.long 0x00000d8a	; Instrument 5 Length
	.long 0x00000d8a	; Instrument 6 Length
	.long 0x0000e7fa	; Instrument 7 Length
	.long 0x00008000	; Instrument 8 Length
	.long 0x00008000	; Instrument 9 Length
	.long 0x00001aa6	; Instrument 10 Length
	.long 0x00000578	; Instrument 11 Length
	.long 0x00001c7c	; Instrument 12 Length
	.long 0x00001b76	; Instrument 13 Length
	.long 0x00001bd0	; Instrument 14 Length
	.long 0x000012e2	; Instrument 15 Length
	.long 0x000012e2	; Instrument 16 Length
	.long 0x00002ca0	; Instrument 17 Length
	.long 0x00000000	; Instrument 17 Length
	.long 0x00000000	; Instrument 18 Length
	.long 0x00000000	; Instrument 19 Length
	.long 0x00000000	; Instrument 20 Length
	.long 0x00000000	; Instrument 21 Length
	.long 0x00000000	; Instrument 22 Length
	.long 0x00000000	; Instrument 23 Length
	.long 0x00000000	; Instrument 24 Length
	.long 0x00000000	; Instrument 25 Length
	.long 0x00000000	; Instrument 26 Length
	.long 0x00000000	; Instrument 27 Length
	.long 0x00000000	; Instrument 28 Length
	.long 0x00000000	; Instrument 29 Length
	.long 0x00000000	; Instrument 30 Length
	.long 0x00000000	; Instrument 31 Length
AK_ExtSmpLen:
	.long 0x00000002	; External Sample 1 Length
	.long 0x00000000	; External Sample 2 Length
	.long 0x00000000	; External Sample 3 Length
	.long 0x00000000	; External Sample 4 Length
	.long 0x00000000	; External Sample 5 Length
	.long 0x00000000	; External Sample 6 Length
	.long 0x00000000	; External Sample 7 Length
	.long 0x00000000	; External Sample 8 Length
AK_NoiseSeeds:
	.long 0x67452301
	.long 0xefcdab89
	.long 0x00000000
AK_SmpAddr:
	.skip AK_MaxInstruments*4
AK_ExtSmpAddr:
	.skip AK_MaxExtSamples*4
AK_OpInstance:
	.skip 15*4
AK_EnvDValue:
	; NB. Must follow AK_OpInstance!
	.skip 0*4

; ============================================================================
