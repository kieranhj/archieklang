; ============================================================================
; akp2arc.py
; input = cream\script.txt.
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

; ============================================================================
; r8 = Sample Buffer Start Address
; r9 = 32768 Bytes Temporary Work Buffer Address (can be freed after sample rendering complete)
; r10 = External Samples Address (need not be in chip memory, and can be freed after sample rendering complete)
; ============================================================================

AK_Generate:
	str lr, [sp, #-4]!

	; Create sample & external sample base addresses
	adr r5, AK_SmpLen
	adr r4, AK_SmpAddr
	mov r7, #AK_MaxInstruments
	mov r0, r8
SmpAdrLoop:
	str r0, [r4], #4
	ldr r1, [r5], #4
	add r0, r0, r1
	subs r7, r7, #1
	bne SmpAdrLoop
	mov r7, #AK_MaxExtSamples
	mov r0, r10
ExSmpAdrLoop:
	str r0, [r4], #4
	ldr r1, [r5], #4
	add r0, r0, r1
	subs r7, r7, #1
	bne ExSmpAdrLoop

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
; Instrument 1 - 'JosSs_Lead_01'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst1Loop:
	; v1 = osc_saw(0, 1310, 127);
	ldr r0, [r10, #AK_OPINSTANCE+4*0]
	add r0, r0, #1310
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	str r0, [r10, #AK_OPINSTANCE+4*0]	
	; v1 = vol(127)
	mov r14, #127
	mul r0, r14, r0
	mov r0, r0, asr #7

	; v2 = envd(1, 11, 0, 127);
	mov r4, #2048
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	movle r6, #0
	mov r1, r6
	; v2 = vol(127)
	mov r14, #127
	mul r1, r14, r1
	mov r1, r1, asr #7

	; v1 = mul(v1, v2);
	mul r0, r1, r0
	mov r0, r0, asr #15

	; v1 = sv_flt_n(3, v1, 85, 63, 0);
	ldr r4, [r10, #AK_OPINSTANCE+4*(1+AK_LPF)]
	ldr r5, [r10, #AK_OPINSTANCE+4*(1+AK_HPF)]
	ldr r6, [r10, #AK_OPINSTANCE+4*(1+AK_BPF)]
	mov r14, r6, asr #7
	mov r12, #85
	mla r4, r14, r12, r4
	; r4 = clamp(r4)
	cmp r4, r11		; #32767
	movgt r4, r11	; #32767
	cmn r4, r11		; #-32768
	mvnlt r4, r11	; #-32768
	str r4, [r10, #AK_OPINSTANCE+4*(1+AK_LPF)]
	mov r12, #63
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
	mov r12, #85
	mla r6, r12, r14, r6
	; r6 = clamp(r6)
	cmp r6, r11		; #32767
	movgt r6, r11	; #32767
	cmn r6, r11		; #-32768
	mvnlt r6, r11	; #-32768
	str r6, [r10, #AK_OPINSTANCE+4*(1+AK_BPF)]
	mov r0, r4

	; v1 = reverb(v1, 85, 53);
	ldr r6, [r10, #AK_OPINSTANCE+4*4]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(85)
	mov r14, #85
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
	; r12 = vol(53)
	mov r14, #53
	mul r12, r14, r12
	mov r12, r12, asr #7
	mov r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*5]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(85)
	mov r14, #85
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
	; r12 = vol(53)
	mov r14, #53
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*6]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(85)
	mov r14, #85
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
	; r12 = vol(53)
	mov r14, #53
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*7]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(85)
	mov r14, #85
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
	; r12 = vol(53)
	mov r14, #53
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*8]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(85)
	mov r14, #85
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
	; r12 = vol(53)
	mov r14, #53
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*9]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(85)
	mov r14, #85
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
	; r12 = vol(53)
	mov r14, #53
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*10]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(85)
	mov r14, #85
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
	; r12 = vol(53)
	mov r14, #53
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*11]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(85)
	mov r14, #85
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
	; r12 = vol(53)
	mov r14, #53
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r0, r5, r12
	sub r9, r9, #2048*4*7
	; v1 = clamp(v1)
	cmp r0, r11		; #32767
	movgt r0, r11	; #32767
	cmn r0, r11		; #-32768
	mvnlt r0, r11	; #-32768

	; v3 = osc_saw(6, 1306, 11);
	ldr r2, [r10, #AK_OPINSTANCE+4*12]
	add r2, r2, #1306
	mov r2, r2, asl #16
	mov r2, r2, asr #16	; Sign extend word to long.
	str r2, [r10, #AK_OPINSTANCE+4*12]	
	; v3 = vol(11)
	mov r14, #11
	mul r2, r14, r2
	mov r2, r2, asr #7

	; v2 = osc_sine(7, v3, 26);
	ldr r6, [r10, #AK_OPINSTANCE+4*13]
	add r6, r6, r2
	str r6, [r10, #AK_OPINSTANCE+4*13]
	sub r6, r6, #16384
	mov r6, r6, asl #16
	mov r6, r6, asr #16	; Sign extend word to long.
	movs r4, r6
	rsblt r4, r4, #0
	sub r4, r11, r4	; #32767
	mul r4, r6, r4
	mov r4, r4, asr #16
	mov r1, r4, asl #3
	; v2 = vol(26)
	mov r14, #26
	mul r1, r14, r1
	mov r1, r1, asr #7

	; v2 = sv_flt_n(8, v2, 88, 9, 0);
	ldr r4, [r10, #AK_OPINSTANCE+4*(14+AK_LPF)]
	ldr r5, [r10, #AK_OPINSTANCE+4*(14+AK_HPF)]
	ldr r6, [r10, #AK_OPINSTANCE+4*(14+AK_BPF)]
	mov r14, r6, asr #7
	mov r12, #88
	mla r4, r14, r12, r4
	; r4 = clamp(r4)
	cmp r4, r11		; #32767
	movgt r4, r11	; #32767
	cmn r4, r11		; #-32768
	mvnlt r4, r11	; #-32768
	str r4, [r10, #AK_OPINSTANCE+4*(14+AK_LPF)]
	mov r12, #9
	mul r14, r12, r14
	mov r12, r1
	sub r12, r12, r4
	sub r5, r12, r14
	; r5 = clamp(r5)
	cmp r5, r11		; #32767
	movgt r5, r11	; #32767
	cmn r5, r11		; #-32768
	mvnlt r5, r11	; #-32768
	str r5, [r10, #AK_OPINSTANCE+4*(14+AK_HPF)]
	mov r14, r5, asr #7
	mov r12, #88
	mla r6, r12, r14, r6
	; r6 = clamp(r6)
	cmp r6, r11		; #32767
	movgt r6, r11	; #32767
	cmn r6, r11		; #-32768
	mvnlt r6, r11	; #-32768
	str r6, [r10, #AK_OPINSTANCE+4*(14+AK_BPF)]
	mov r1, r4

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
	ldr r4, [r10, #AK_SMPLEN+4*0]
	cmp r7, r4
	blt Inst1Loop

;----------------------------------------------------------------------------
; Instrument 1 - Loop Generator (Offset: 6152 Length: 6152)
;----------------------------------------------------------------------------

	mov r7, #6152
	ldr r6, [r10, #AK_SMPADDR+4*0]
	add r6, r6, #6152	; src1
	sub r4, r6, r7	; src2
	mov r0, r11, lsl #8	; 32767<<8
	mov r1, r7
	bl divide
	mov r5, r0	; delta = divs.w(32767<<8,repeat_length)
	mov r14, #0	; rampup
	mov r12, r11, lsl #8	; rampdown
LoopGen_0:
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
	bne LoopGen_0

;----------------------------------------------------------------------------
; Instrument 2 - 'JosSs_Chord_A_02_(Lead_01)'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst2Loop:
	; v1 = chordgen(0, 0, 4, 7, 12, 0);
	ldr r4, [r10, #AK_SMPADDR+4*0]
	ldr r12, [r10, #AK_SMPLEN+4*0]
	ldrb r6, [r4, r7]
	mov r6, r6, asl #24
	mov r6, r6, asr #17
	add r4, r4, #0
	sub r12, r12, #0
	ldr r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD1)]
	ldrb r14, [r4, r5, lsr #16]
	cmp r12, r5, lsr #16
	movlt r14, #0
	add r5, r5, #82432
	str r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD1)]
	mov r14, r14, asl #24
	add r6, r6, r14, asr #17
	ldr r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD2)]
	ldrb r14, [r4, r5, lsr #16]
	cmp r12, r5, lsr #16
	movlt r14, #0
	add r5, r5, #98048
	str r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD2)]
	mov r14, r14, asl #24
	add r6, r6, r14, asr #17
	ldr r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD3)]
	ldrb r14, [r4, r5, lsr #8]
	cmp r12, r5, lsr #8
	movlt r14, #0
	add r5, r5, #512
	str r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD3)]
	mov r14, r14, asl #24
	add r6, r6, r14, asr #17
	mov r0, r6
	; v1 = clamp(v1)
	cmp r0, r11		; #32767
	movgt r0, r11	; #32767
	cmn r0, r11		; #-32768
	mvnlt r0, r11	; #-32768

	; v2 = envd(1, 12, 0, 127);
	mov r4, #1724
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	movle r6, #0
	mov r1, r6
	; v2 = vol(127)
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
; Instrument 3 - 'JosSs_Chord_A_03_(Lead_01)'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst3Loop:
	; v1 = chordgen(0, 0, 3, 5, 8, 0);
	ldr r4, [r10, #AK_SMPADDR+4*0]
	ldr r12, [r10, #AK_SMPLEN+4*0]
	ldrb r6, [r4, r7]
	mov r6, r6, asl #24
	mov r6, r6, asr #17
	add r4, r4, #0
	sub r12, r12, #0
	ldr r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD1)]
	ldrb r14, [r4, r5, lsr #16]
	cmp r12, r5, lsr #16
	movlt r14, #0
	add r5, r5, #77824
	str r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD1)]
	mov r14, r14, asl #24
	add r6, r6, r14, asr #17
	ldr r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD2)]
	ldrb r14, [r4, r5, lsr #16]
	cmp r12, r5, lsr #16
	movlt r14, #0
	add r5, r5, #87552
	str r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD2)]
	mov r14, r14, asl #24
	add r6, r6, r14, asr #17
	ldr r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD3)]
	ldrb r14, [r4, r5, lsr #15]
	cmp r12, r5, lsr #15
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

	; v2 = envd(1, 12, 0, 127);
	mov r4, #1724
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	movle r6, #0
	mov r1, r6
	; v2 = vol(127)
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
	ldr r4, [r10, #AK_SMPLEN+4*2]
	cmp r7, r4
	blt Inst3Loop

;----------------------------------------------------------------------------
; Instrument 4 - 'JosSs_Lead_02'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst4Loop:
	; v1 = osc_sine(0, 1316, 127);
	ldr r6, [r10, #AK_OPINSTANCE+4*0]
	add r6, r6, #1316
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
	; v1 = vol(127)
	mov r14, #127
	mul r0, r14, r0
	mov r0, r0, asr #7

	; v2 = osc_saw(1, 1310, 98);
	ldr r1, [r10, #AK_OPINSTANCE+4*1]
	add r1, r1, #1310
	mov r1, r1, asl #16
	mov r1, r1, asr #16	; Sign extend word to long.
	str r1, [r10, #AK_OPINSTANCE+4*1]	
	; v2 = vol(98)
	mov r14, #98
	mul r1, r14, r1
	mov r1, r1, asr #7

	; v3 = osc_sine(2, 1322, 110);
	ldr r6, [r10, #AK_OPINSTANCE+4*2]
	add r6, r6, #1322
	str r6, [r10, #AK_OPINSTANCE+4*2]
	sub r6, r6, #16384
	mov r6, r6, asl #16
	mov r6, r6, asr #16	; Sign extend word to long.
	movs r4, r6
	rsblt r4, r4, #0
	sub r4, r11, r4	; #32767
	mul r4, r6, r4
	mov r4, r4, asr #16
	mov r2, r4, asl #3
	; v3 = vol(110)
	mov r14, #110
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

	; v1 = sv_flt_n(6, v1, 85, 110, 2);
	ldr r4, [r10, #AK_OPINSTANCE+4*(3+AK_LPF)]
	ldr r5, [r10, #AK_OPINSTANCE+4*(3+AK_HPF)]
	ldr r6, [r10, #AK_OPINSTANCE+4*(3+AK_BPF)]
	mov r14, r6, asr #7
	mov r12, #85
	mla r4, r14, r12, r4
	; r4 = clamp(r4)
	cmp r4, r11		; #32767
	movgt r4, r11	; #32767
	cmn r4, r11		; #-32768
	mvnlt r4, r11	; #-32768
	str r4, [r10, #AK_OPINSTANCE+4*(3+AK_LPF)]
	mov r12, #110
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
	mov r12, #85
	mla r6, r12, r14, r6
	; r6 = clamp(r6)
	cmp r6, r11		; #32767
	movgt r6, r11	; #32767
	cmn r6, r11		; #-32768
	mvnlt r6, r11	; #-32768
	str r6, [r10, #AK_OPINSTANCE+4*(3+AK_BPF)]
	mov r0, r6

	; v1 = reverb(v1, 24, 59);
	ldr r6, [r10, #AK_OPINSTANCE+4*6]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(24)
	mov r14, #24
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
	str r6, [r10, #AK_OPINSTANCE+4*6]
	; r12 = vol(59)
	mov r14, #59
	mul r12, r14, r12
	mov r12, r12, asr #7
	mov r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*7]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(24)
	mov r14, #24
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
	str r6, [r10, #AK_OPINSTANCE+4*7]
	; r12 = vol(59)
	mov r14, #59
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*8]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(24)
	mov r14, #24
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
	str r6, [r10, #AK_OPINSTANCE+4*8]
	; r12 = vol(59)
	mov r14, #59
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*9]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(24)
	mov r14, #24
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
	str r6, [r10, #AK_OPINSTANCE+4*9]
	; r12 = vol(59)
	mov r14, #59
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*10]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(24)
	mov r14, #24
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
	str r6, [r10, #AK_OPINSTANCE+4*10]
	; r12 = vol(59)
	mov r14, #59
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*11]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(24)
	mov r14, #24
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
	str r6, [r10, #AK_OPINSTANCE+4*11]
	; r12 = vol(59)
	mov r14, #59
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*12]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(24)
	mov r14, #24
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
	str r6, [r10, #AK_OPINSTANCE+4*12]
	; r12 = vol(59)
	mov r14, #59
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*13]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(24)
	mov r14, #24
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
	str r6, [r10, #AK_OPINSTANCE+4*13]
	; r12 = vol(59)
	mov r14, #59
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
	ldr r4, [r10, #AK_SMPLEN+4*3]
	cmp r7, r4
	blt Inst4Loop

;----------------------------------------------------------------------------
; Instrument 4 - Loop Generator (Offset: 17475 Length: 17477)
;----------------------------------------------------------------------------

	mov r7, #17477
	ldr r6, [r10, #AK_SMPADDR+4*3]
	add r6, r6, #17475	; src1
	sub r4, r6, r7	; src2
	mov r0, r11, lsl #8	; 32767<<8
	mov r1, r7
	bl divide
	mov r5, r0	; delta = divs.w(32767<<8,repeat_length)
	mov r14, #0	; rampup
	mov r12, r11, lsl #8	; rampdown
LoopGen_3:
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
	bne LoopGen_3

;----------------------------------------------------------------------------
; Instrument 5 - 'JosSs_Chord_B_01_(Lead_02)'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst5Loop:
	; v1 = chordgen(0, 3, 4, 7, 10, 0);
	ldr r4, [r10, #AK_SMPADDR+4*3]
	ldr r12, [r10, #AK_SMPLEN+4*3]
	ldrb r6, [r4, r7]
	mov r6, r6, asl #24
	mov r6, r6, asr #17
	add r4, r4, #0
	sub r12, r12, #0
	ldr r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD1)]
	ldrb r14, [r4, r5, lsr #16]
	cmp r12, r5, lsr #16
	movlt r14, #0
	add r5, r5, #82432
	str r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD1)]
	mov r14, r14, asl #24
	add r6, r6, r14, asr #17
	ldr r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD2)]
	ldrb r14, [r4, r5, lsr #16]
	cmp r12, r5, lsr #16
	movlt r14, #0
	add r5, r5, #98048
	str r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD2)]
	mov r14, r14, asl #24
	add r6, r6, r14, asr #17
	ldr r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD3)]
	ldrb r14, [r4, r5, lsr #15]
	cmp r12, r5, lsr #15
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

	; v2 = envd(1, 8, 0, 127);
	mov r4, #3640
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	movle r6, #0
	mov r1, r6
	; v2 = vol(127)
	mov r14, #127
	mul r1, r14, r1
	mov r1, r1, asr #7

	; v2 = mul(v2, 96);
	mov r14, #96
	mul r1, r14, r1
	mov r1, r1, asr #15

	; v1 = sv_flt_n(4, v1, v2, 99, 2);
	ldr r4, [r10, #AK_OPINSTANCE+4*(3+AK_LPF)]
	ldr r5, [r10, #AK_OPINSTANCE+4*(3+AK_HPF)]
	ldr r6, [r10, #AK_OPINSTANCE+4*(3+AK_BPF)]
	mov r14, r6, asr #7
	mla r4, r1, r14, r4
	; r4 = clamp(r4)
	cmp r4, r11		; #32767
	movgt r4, r11	; #32767
	cmn r4, r11		; #-32768
	mvnlt r4, r11	; #-32768
	str r4, [r10, #AK_OPINSTANCE+4*(3+AK_LPF)]
	mov r12, #99
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
	mla r6, r1, r14, r6
	; r6 = clamp(r6)
	cmp r6, r11		; #32767
	movgt r6, r11	; #32767
	cmn r6, r11		; #-32768
	mvnlt r6, r11	; #-32768
	str r6, [r10, #AK_OPINSTANCE+4*(3+AK_BPF)]
	mov r0, r6

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*4]
	cmp r7, r4
	blt Inst5Loop

;----------------------------------------------------------------------------
; Instrument 6 - 'JosSs_Chord_B_02_(Lead_02)'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst6Loop:
	; v1 = chordgen(0, 3, 3, 5, 8, 0);
	ldr r4, [r10, #AK_SMPADDR+4*3]
	ldr r12, [r10, #AK_SMPLEN+4*3]
	ldrb r6, [r4, r7]
	mov r6, r6, asl #24
	mov r6, r6, asr #17
	add r4, r4, #0
	sub r12, r12, #0
	ldr r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD1)]
	ldrb r14, [r4, r5, lsr #16]
	cmp r12, r5, lsr #16
	movlt r14, #0
	add r5, r5, #77824
	str r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD1)]
	mov r14, r14, asl #24
	add r6, r6, r14, asr #17
	ldr r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD2)]
	ldrb r14, [r4, r5, lsr #16]
	cmp r12, r5, lsr #16
	movlt r14, #0
	add r5, r5, #87552
	str r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD2)]
	mov r14, r14, asl #24
	add r6, r6, r14, asr #17
	ldr r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD3)]
	ldrb r14, [r4, r5, lsr #15]
	cmp r12, r5, lsr #15
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

	; v2 = envd(1, 8, 0, 127);
	mov r4, #3640
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	movle r6, #0
	mov r1, r6
	; v2 = vol(127)
	mov r14, #127
	mul r1, r14, r1
	mov r1, r1, asr #7

	; v2 = mul(v2, 96);
	mov r14, #96
	mul r1, r14, r1
	mov r1, r1, asr #15

	; v1 = sv_flt_n(4, v1, v2, 99, 2);
	ldr r4, [r10, #AK_OPINSTANCE+4*(3+AK_LPF)]
	ldr r5, [r10, #AK_OPINSTANCE+4*(3+AK_HPF)]
	ldr r6, [r10, #AK_OPINSTANCE+4*(3+AK_BPF)]
	mov r14, r6, asr #7
	mla r4, r1, r14, r4
	; r4 = clamp(r4)
	cmp r4, r11		; #32767
	movgt r4, r11	; #32767
	cmn r4, r11		; #-32768
	mvnlt r4, r11	; #-32768
	str r4, [r10, #AK_OPINSTANCE+4*(3+AK_LPF)]
	mov r12, #99
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
	mla r6, r1, r14, r6
	; r6 = clamp(r6)
	cmp r6, r11		; #32767
	movgt r6, r11	; #32767
	cmn r6, r11		; #-32768
	mvnlt r6, r11	; #-32768
	str r6, [r10, #AK_OPINSTANCE+4*(3+AK_BPF)]
	mov r0, r6

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*5]
	cmp r7, r4
	blt Inst6Loop

;----------------------------------------------------------------------------
; Instrument 7 - 'JosSs_Chord_B_03_(Lead_02)'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst7Loop:
	; v1 = chordgen(0, 3, 3, 5, 10, 0);
	ldr r4, [r10, #AK_SMPADDR+4*3]
	ldr r12, [r10, #AK_SMPLEN+4*3]
	ldrb r6, [r4, r7]
	mov r6, r6, asl #24
	mov r6, r6, asr #17
	add r4, r4, #0
	sub r12, r12, #0
	ldr r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD1)]
	ldrb r14, [r4, r5, lsr #16]
	cmp r12, r5, lsr #16
	movlt r14, #0
	add r5, r5, #77824
	str r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD1)]
	mov r14, r14, asl #24
	add r6, r6, r14, asr #17
	ldr r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD2)]
	ldrb r14, [r4, r5, lsr #16]
	cmp r12, r5, lsr #16
	movlt r14, #0
	add r5, r5, #87552
	str r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD2)]
	mov r14, r14, asl #24
	add r6, r6, r14, asr #17
	ldr r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD3)]
	ldrb r14, [r4, r5, lsr #15]
	cmp r12, r5, lsr #15
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

	; v2 = envd(1, 8, 0, 127);
	mov r4, #3640
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	movle r6, #0
	mov r1, r6
	; v2 = vol(127)
	mov r14, #127
	mul r1, r14, r1
	mov r1, r1, asr #7

	; v2 = mul(v2, 96);
	mov r14, #96
	mul r1, r14, r1
	mov r1, r1, asr #15

	; v1 = sv_flt_n(4, v1, v2, 99, 2);
	ldr r4, [r10, #AK_OPINSTANCE+4*(3+AK_LPF)]
	ldr r5, [r10, #AK_OPINSTANCE+4*(3+AK_HPF)]
	ldr r6, [r10, #AK_OPINSTANCE+4*(3+AK_BPF)]
	mov r14, r6, asr #7
	mla r4, r1, r14, r4
	; r4 = clamp(r4)
	cmp r4, r11		; #32767
	movgt r4, r11	; #32767
	cmn r4, r11		; #-32768
	mvnlt r4, r11	; #-32768
	str r4, [r10, #AK_OPINSTANCE+4*(3+AK_LPF)]
	mov r12, #99
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
	mla r6, r1, r14, r6
	; r6 = clamp(r6)
	cmp r6, r11		; #32767
	movgt r6, r11	; #32767
	cmn r6, r11		; #-32768
	mvnlt r6, r11	; #-32768
	str r6, [r10, #AK_OPINSTANCE+4*(3+AK_BPF)]
	mov r0, r6

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*6]
	cmp r7, r4
	blt Inst7Loop

;----------------------------------------------------------------------------
; Instrument 8 - 'JosSs_BD_01'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst8Loop:
	; v2 = envd(0, 7, 0, 127);
	mov r4, #4681
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	movle r6, #0
	mov r1, r6
	; v2 = vol(127)
	mov r14, #127
	mul r1, r14, r1
	mov r1, r1, asr #7

	; v2 = mul(v2, 830);
	mov r14, #830
	mul r1, r14, r1
	mov r1, r1, asr #15

	; v1 = osc_sine(2, v2, 127);
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
	; v1 = vol(127)
	mov r14, #127
	mul r0, r14, r0
	mov r0, r0, asr #7

	; v2 = envd(4, 1, 0, 127);
	mov r4, #32767
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	movle r6, #0
	mov r1, r6
	; v2 = vol(127)
	mov r14, #127
	mul r1, r14, r1
	mov r1, r1, asr #7

	; v2 = mul(v2, 128);
	mov r1, r1, asr #8	; val<<7>>15

	; v3 = osc_saw(6, 2127, v2);
	ldr r2, [r10, #AK_OPINSTANCE+4*1]
	add r2, r2, #2127
	mov r2, r2, asl #16
	mov r2, r2, asr #16	; Sign extend word to long.
	str r2, [r10, #AK_OPINSTANCE+4*1]	
	; v3 = vol(v2)
	and r14, r1, #0xff
	mul r2, r14, r2
	mov r2, r2, asr #7
	mov r2, r2, asl #16
	mov r2, r2, asr #16	; Sign extend word to long.

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
	ldr r4, [r10, #AK_SMPLEN+4*7]
	cmp r7, r4
	blt Inst8Loop

;----------------------------------------------------------------------------
; Instrument 9 - 'JosSs_Claps_01'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst9Loop:
	; v2 = envd(0, 6, 0, 101);
	mov r4, #6553
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	movle r6, #0
	mov r1, r6
	; v2 = vol(101)
	mov r14, #101
	mul r1, r14, r1
	mov r1, r1, asr #7

	; v2 = mul(v2, 528);
	mov r14, #528
	mul r1, r14, r1
	mov r1, r1, asr #15

	; v1 = osc_noise(v2);
	ldr r4, [r10, #AK_NOISESEEDS+0]
	ldr r6, [r10, #AK_NOISESEEDS+4]
	eor r4, r4, r6
	str r4, [r10, #AK_NOISESEEDS+0]
	ldr r0, [r10, #AK_NOISESEEDS+8]
	add r0, r0, r6
	str r0, [r10, #AK_NOISESEEDS+8]
	add r6, r6, r4
	str r6, [r10, #AK_NOISESEEDS+4]
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	; v1 = vol(v2)
	and r14, r1, #0xff
	mul r0, r14, r0
	mov r0, r0, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.

	; v1 = sv_flt_n(5, v1, 64, 35, 1);
	ldr r4, [r10, #AK_OPINSTANCE+4*(0+AK_LPF)]
	ldr r5, [r10, #AK_OPINSTANCE+4*(0+AK_HPF)]
	ldr r6, [r10, #AK_OPINSTANCE+4*(0+AK_BPF)]
	mov r14, r6, asr #7
	mov r12, #64
	mla r4, r14, r12, r4
	; r4 = clamp(r4)
	cmp r4, r11		; #32767
	movgt r4, r11	; #32767
	cmn r4, r11		; #-32768
	mvnlt r4, r11	; #-32768
	str r4, [r10, #AK_OPINSTANCE+4*(0+AK_LPF)]
	mov r12, #35
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
	mov r12, #64
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
	ldr r4, [r10, #AK_SMPLEN+4*8]
	cmp r7, r4
	blt Inst9Loop

;----------------------------------------------------------------------------
; Instrument 10 - 'JosSs_Hh_01'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst10Loop:
	; v2 = envd(0, 8, 0, 60);
	mov r4, #3640
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	movle r6, #0
	mov r1, r6
	; v2 = vol(60)
	mov r14, #60
	mul r1, r14, r1
	mov r1, r1, asr #7

	; v2 = mul(v2, 128);
	mov r1, r1, asr #8	; val<<7>>15

	; v1 = osc_noise(v2);
	ldr r4, [r10, #AK_NOISESEEDS+0]
	ldr r6, [r10, #AK_NOISESEEDS+4]
	eor r4, r4, r6
	str r4, [r10, #AK_NOISESEEDS+0]
	ldr r0, [r10, #AK_NOISESEEDS+8]
	add r0, r0, r6
	str r0, [r10, #AK_NOISESEEDS+8]
	add r6, r6, r4
	str r6, [r10, #AK_NOISESEEDS+4]
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	; v1 = vol(v2)
	and r14, r1, #0xff
	mul r0, r14, r0
	mov r0, r0, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.

	; v1 = sv_flt_n(5, v1, 122, 127, 1);
	ldr r4, [r10, #AK_OPINSTANCE+4*(0+AK_LPF)]
	ldr r5, [r10, #AK_OPINSTANCE+4*(0+AK_HPF)]
	ldr r6, [r10, #AK_OPINSTANCE+4*(0+AK_BPF)]
	mov r14, r6, asr #7
	mov r12, #122
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
	mov r12, #122
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
	ldr r4, [r10, #AK_SMPLEN+4*9]
	cmp r7, r4
	blt Inst10Loop

;----------------------------------------------------------------------------
; Instrument 11 - 'JosSs_Snare_01'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst11Loop:
	; v3 = envd(0, 7, 16, 127);
	mov r4, #4681
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	cmp r6, #4096
	movle r6, #4096
	mov r2, r6
	; v3 = vol(127)
	mov r14, #127
	mul r2, r14, r2
	mov r2, r2, asr #7

	; v3 = mul(v3, 128);
	mov r2, r2, asr #8	; val<<7>>15

	; v4 = envd(2, 8, 10, 127);
	mov r4, #3640
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	cmp r6, #2560
	movle r6, #2560
	mov r3, r6
	; v4 = vol(127)
	mov r14, #127
	mul r3, r14, r3
	mov r3, r3, asr #7

	; v1 = osc_saw(3, v2, v3);
	ldr r0, [r10, #AK_OPINSTANCE+4*0]
	add r0, r0, r1
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	str r0, [r10, #AK_OPINSTANCE+4*0]	
	; v1 = vol(v3)
	and r14, r2, #0xff
	mul r0, r14, r0
	mov r0, r0, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.

	; v1 = sv_flt_n(5, v1, 12, 8, 1);
	ldr r4, [r10, #AK_OPINSTANCE+4*(1+AK_LPF)]
	ldr r5, [r10, #AK_OPINSTANCE+4*(1+AK_HPF)]
	ldr r6, [r10, #AK_OPINSTANCE+4*(1+AK_BPF)]
	mov r14, r6, asr #7
	mov r12, #12
	mla r4, r14, r12, r4
	; r4 = clamp(r4)
	cmp r4, r11		; #32767
	movgt r4, r11	; #32767
	cmn r4, r11		; #-32768
	mvnlt r4, r11	; #-32768
	str r4, [r10, #AK_OPINSTANCE+4*(1+AK_LPF)]
	mov r12, #8
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
	mov r12, #12
	mla r6, r12, r14, r6
	; r6 = clamp(r6)
	cmp r6, r11		; #32767
	movgt r6, r11	; #32767
	cmn r6, r11		; #-32768
	mvnlt r6, r11	; #-32768
	str r6, [r10, #AK_OPINSTANCE+4*(1+AK_BPF)]
	mov r0, r5

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

	; v2 = add(v1, -12823);
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	mvn r1, #12822
	add r1, r0, r1
	; v2 = clamp(v2)
	cmp r1, r11		; #32767
	movgt r1, r11	; #32767
	cmn r1, r11		; #-32768
	mvnlt r1, r11	; #-32768

	; v1 = mul(v1, v4);
	mul r0, r3, r0
	mov r0, r0, asr #15

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*10]
	cmp r7, r4
	blt Inst11Loop

;----------------------------------------------------------------------------
; Instrument 12 - 'JosSs_BD_01 + Snare_01'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst12Loop:
	; v1 = clone(smp,7, 0);
	mov r0, r7
	ldr r6, [r10, #AK_SMPADDR+4*7]
	ldr r4, [r10, #AK_SMPLEN+4*7]
	cmp r0, r4
	movge r0, #0
	ldrltb r0, [r6, r0]
	mov r0, r0, asl #24
	mov r0, r0, asr #16

	; v2 = clone(smp,10, 0);
	mov r1, r7
	ldr r6, [r10, #AK_SMPADDR+4*10]
	ldr r4, [r10, #AK_SMPLEN+4*10]
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
	ldr r4, [r10, #AK_SMPLEN+4*11]
	cmp r7, r4
	blt Inst12Loop

;----------------------------------------------------------------------------
; Instrument 13 - 'JosSs_Bass_01'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst13Loop:
	; v1 = osc_sine(0, 1310, 127);
	ldr r6, [r10, #AK_OPINSTANCE+4*0]
	add r6, r6, #1310
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
	; v1 = vol(127)
	mov r14, #127
	mul r0, r14, r0
	mov r0, r0, asr #7

	; v2 = osc_sine(1, 1318, 127);
	ldr r6, [r10, #AK_OPINSTANCE+4*1]
	add r6, r6, #1318
	str r6, [r10, #AK_OPINSTANCE+4*1]
	sub r6, r6, #16384
	mov r6, r6, asl #16
	mov r6, r6, asr #16	; Sign extend word to long.
	movs r4, r6
	rsblt r4, r4, #0
	sub r4, r11, r4	; #32767
	mul r4, r6, r4
	mov r4, r4, asr #16
	mov r1, r4, asl #3
	; v2 = vol(127)
	mov r14, #127
	mul r1, r14, r1
	mov r1, r1, asr #7

	; v1 = mul(v1, v2);
	mul r0, r1, r0
	mov r0, r0, asr #15

	; v1 = cmb_flt_n(3, v1, v2, 72, 94);
	ldr r6, [r10, #AK_OPINSTANCE+4*2]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(72)
	mov r14, #72
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
	cmp r6, r1
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*2]
	; v1 = vol(94)
	mov r14, #94
	mul r0, r14, r0
	mov r0, r0, asr #7

	; v2 = osc_saw(4, 1309, 85);
	ldr r1, [r10, #AK_OPINSTANCE+4*3]
	add r1, r1, #1309
	mov r1, r1, asl #16
	mov r1, r1, asr #16	; Sign extend word to long.
	str r1, [r10, #AK_OPINSTANCE+4*3]	
	; v2 = vol(85)
	mov r14, #85
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
; Instrument 13 - Loop Generator (Offset: 5698 Length: 4612)
;----------------------------------------------------------------------------

	mov r7, #4612
	ldr r6, [r10, #AK_SMPADDR+4*12]
	add r6, r6, #5698	; src1
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
; Instrument 14 - 'JosSs_Chord_Loop_C_01_(Bass_01)'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst14Loop:
	; v1 = chordgen(0, 12, 4, 7, 10, 127);
	ldr r4, [r10, #AK_SMPADDR+4*12]
	ldr r12, [r10, #AK_SMPLEN+4*12]
	ldrb r6, [r4, r7]
	mov r6, r6, asl #24
	mov r6, r6, asr #17
	add r4, r4, #127
	sub r12, r12, #127
	ldr r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD1)]
	ldrb r14, [r4, r5, lsr #16]
	cmp r12, r5, lsr #16
	movlt r14, #0
	add r5, r5, #82432
	str r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD1)]
	mov r14, r14, asl #24
	add r6, r6, r14, asr #17
	ldr r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD2)]
	ldrb r14, [r4, r5, lsr #16]
	cmp r12, r5, lsr #16
	movlt r14, #0
	add r5, r5, #98048
	str r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD2)]
	mov r14, r14, asl #24
	add r6, r6, r14, asr #17
	ldr r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD3)]
	ldrb r14, [r4, r5, lsr #15]
	cmp r12, r5, lsr #15
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

	; v2 = enva(1, 20, 0, 127);
	ldr r6, [r10, #AK_OPINSTANCE+4*3]
	mov r1, r6, asr #8
	mov r4, #642
	add r6, r6, r4
	cmp r6, r11, asl #8
	movgt r6, r11, asl #8
	str r6, [r10, #AK_OPINSTANCE+4*3]
	; v2 = vol(127)
	mov r14, #127
	mul r1, r14, r1
	mov r1, r1, asr #7

	; v1 = mul(v1, v2);
	mul r0, r1, r0
	mov r0, r0, asr #15

	; v1 = reverb(v1, 6, 23);
	ldr r6, [r10, #AK_OPINSTANCE+4*4]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(6)
	mov r14, #6
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
	; r12 = vol(23)
	mov r14, #23
	mul r12, r14, r12
	mov r12, r12, asr #7
	mov r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*5]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(6)
	mov r14, #6
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
	; r12 = vol(23)
	mov r14, #23
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*6]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(6)
	mov r14, #6
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
	; r12 = vol(23)
	mov r14, #23
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*7]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(6)
	mov r14, #6
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
	; r12 = vol(23)
	mov r14, #23
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*8]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(6)
	mov r14, #6
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
	; r12 = vol(23)
	mov r14, #23
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*9]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(6)
	mov r14, #6
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
	; r12 = vol(23)
	mov r14, #23
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*10]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(6)
	mov r14, #6
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
	; r12 = vol(23)
	mov r14, #23
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*11]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(6)
	mov r14, #6
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
	; r12 = vol(23)
	mov r14, #23
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r0, r5, r12
	sub r9, r9, #2048*4*7
	; v1 = clamp(v1)
	cmp r0, r11		; #32767
	movgt r0, r11	; #32767
	cmn r0, r11		; #-32768
	mvnlt r0, r11	; #-32768

	; v1 = sv_flt_n(4, v1, 28, 20, 0);
	ldr r4, [r10, #AK_OPINSTANCE+4*(12+AK_LPF)]
	ldr r5, [r10, #AK_OPINSTANCE+4*(12+AK_HPF)]
	ldr r6, [r10, #AK_OPINSTANCE+4*(12+AK_BPF)]
	mov r14, r6, asr #7
	mov r12, #28
	mla r4, r14, r12, r4
	; r4 = clamp(r4)
	cmp r4, r11		; #32767
	movgt r4, r11	; #32767
	cmn r4, r11		; #-32768
	mvnlt r4, r11	; #-32768
	str r4, [r10, #AK_OPINSTANCE+4*(12+AK_LPF)]
	mov r12, #20
	mul r14, r12, r14
	mov r12, r0
	sub r12, r12, r4
	sub r5, r12, r14
	; r5 = clamp(r5)
	cmp r5, r11		; #32767
	movgt r5, r11	; #32767
	cmn r5, r11		; #-32768
	mvnlt r5, r11	; #-32768
	str r5, [r10, #AK_OPINSTANCE+4*(12+AK_HPF)]
	mov r14, r5, asr #7
	mov r12, #28
	mla r6, r12, r14, r6
	; r6 = clamp(r6)
	cmp r6, r11		; #32767
	movgt r6, r11	; #32767
	cmn r6, r11		; #-32768
	mvnlt r6, r11	; #-32768
	str r6, [r10, #AK_OPINSTANCE+4*(12+AK_BPF)]
	mov r0, r4

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*13]
	cmp r7, r4
	blt Inst14Loop

;----------------------------------------------------------------------------
; Instrument 14 - Loop Generator (Offset: 2784 Length: 2782)
;----------------------------------------------------------------------------

	mov r7, #2782
	ldr r6, [r10, #AK_SMPADDR+4*13]
	add r6, r6, #2784	; src1
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
; Instrument 15 - 'JosSs_Chord_Loop_C_02_(Bass_01)'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst15Loop:
	; v1 = chordgen(0, 12, 3, 5, 8, 116);
	ldr r4, [r10, #AK_SMPADDR+4*12]
	ldr r12, [r10, #AK_SMPLEN+4*12]
	ldrb r6, [r4, r7]
	mov r6, r6, asl #24
	mov r6, r6, asr #17
	add r4, r4, #116
	sub r12, r12, #116
	ldr r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD1)]
	ldrb r14, [r4, r5, lsr #16]
	cmp r12, r5, lsr #16
	movlt r14, #0
	add r5, r5, #77824
	str r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD1)]
	mov r14, r14, asl #24
	add r6, r6, r14, asr #17
	ldr r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD2)]
	ldrb r14, [r4, r5, lsr #16]
	cmp r12, r5, lsr #16
	movlt r14, #0
	add r5, r5, #87552
	str r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD2)]
	mov r14, r14, asl #24
	add r6, r6, r14, asr #17
	ldr r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD3)]
	ldrb r14, [r4, r5, lsr #15]
	cmp r12, r5, lsr #15
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

	; v2 = enva(1, 20, 0, 127);
	ldr r6, [r10, #AK_OPINSTANCE+4*3]
	mov r1, r6, asr #8
	mov r4, #642
	add r6, r6, r4
	cmp r6, r11, asl #8
	movgt r6, r11, asl #8
	str r6, [r10, #AK_OPINSTANCE+4*3]
	; v2 = vol(127)
	mov r14, #127
	mul r1, r14, r1
	mov r1, r1, asr #7

	; v1 = mul(v1, v2);
	mul r0, r1, r0
	mov r0, r0, asr #15

	; v1 = reverb(v1, 6, 27);
	ldr r6, [r10, #AK_OPINSTANCE+4*4]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(6)
	mov r14, #6
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
	; r12 = vol(27)
	mov r14, #27
	mul r12, r14, r12
	mov r12, r12, asr #7
	mov r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*5]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(6)
	mov r14, #6
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
	; r12 = vol(27)
	mov r14, #27
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*6]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(6)
	mov r14, #6
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
	; r12 = vol(27)
	mov r14, #27
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*7]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(6)
	mov r14, #6
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
	; r12 = vol(27)
	mov r14, #27
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*8]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(6)
	mov r14, #6
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
	; r12 = vol(27)
	mov r14, #27
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*9]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(6)
	mov r14, #6
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
	; r12 = vol(27)
	mov r14, #27
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*10]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(6)
	mov r14, #6
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
	; r12 = vol(27)
	mov r14, #27
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*11]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(6)
	mov r14, #6
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
	; r12 = vol(27)
	mov r14, #27
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r0, r5, r12
	sub r9, r9, #2048*4*7
	; v1 = clamp(v1)
	cmp r0, r11		; #32767
	movgt r0, r11	; #32767
	cmn r0, r11		; #-32768
	mvnlt r0, r11	; #-32768

	; v1 = sv_flt_n(4, v1, 28, 20, 0);
	ldr r4, [r10, #AK_OPINSTANCE+4*(12+AK_LPF)]
	ldr r5, [r10, #AK_OPINSTANCE+4*(12+AK_HPF)]
	ldr r6, [r10, #AK_OPINSTANCE+4*(12+AK_BPF)]
	mov r14, r6, asr #7
	mov r12, #28
	mla r4, r14, r12, r4
	; r4 = clamp(r4)
	cmp r4, r11		; #32767
	movgt r4, r11	; #32767
	cmn r4, r11		; #-32768
	mvnlt r4, r11	; #-32768
	str r4, [r10, #AK_OPINSTANCE+4*(12+AK_LPF)]
	mov r12, #20
	mul r14, r12, r14
	mov r12, r0
	sub r12, r12, r4
	sub r5, r12, r14
	; r5 = clamp(r5)
	cmp r5, r11		; #32767
	movgt r5, r11	; #32767
	cmn r5, r11		; #-32768
	mvnlt r5, r11	; #-32768
	str r5, [r10, #AK_OPINSTANCE+4*(12+AK_HPF)]
	mov r14, r5, asr #7
	mov r12, #28
	mla r6, r12, r14, r6
	; r6 = clamp(r6)
	cmp r6, r11		; #32767
	movgt r6, r11	; #32767
	cmn r6, r11		; #-32768
	mvnlt r6, r11	; #-32768
	str r6, [r10, #AK_OPINSTANCE+4*(12+AK_BPF)]
	mov r0, r4

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*14]
	cmp r7, r4
	blt Inst15Loop

;----------------------------------------------------------------------------
; Instrument 15 - Loop Generator (Offset: 2782 Length: 2784)
;----------------------------------------------------------------------------

	mov r7, #2784
	ldr r6, [r10, #AK_SMPADDR+4*14]
	add r6, r6, #2782	; src1
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
; Instrument 16 - 'JosSs_Chord_Loop_C_03_(Bass_01)'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst16Loop:
	; v1 = chordgen(0, 12, 4, 7, 12, 116);
	ldr r4, [r10, #AK_SMPADDR+4*12]
	ldr r12, [r10, #AK_SMPLEN+4*12]
	ldrb r6, [r4, r7]
	mov r6, r6, asl #24
	mov r6, r6, asr #17
	add r4, r4, #116
	sub r12, r12, #116
	ldr r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD1)]
	ldrb r14, [r4, r5, lsr #16]
	cmp r12, r5, lsr #16
	movlt r14, #0
	add r5, r5, #82432
	str r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD1)]
	mov r14, r14, asl #24
	add r6, r6, r14, asr #17
	ldr r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD2)]
	ldrb r14, [r4, r5, lsr #16]
	cmp r12, r5, lsr #16
	movlt r14, #0
	add r5, r5, #98048
	str r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD2)]
	mov r14, r14, asl #24
	add r6, r6, r14, asr #17
	ldr r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD3)]
	ldrb r14, [r4, r5, lsr #8]
	cmp r12, r5, lsr #8
	movlt r14, #0
	add r5, r5, #512
	str r5, [r10, #AK_OPINSTANCE+4*(0+AK_CHORD3)]
	mov r14, r14, asl #24
	add r6, r6, r14, asr #17
	mov r0, r6
	; v1 = clamp(v1)
	cmp r0, r11		; #32767
	movgt r0, r11	; #32767
	cmn r0, r11		; #-32768
	mvnlt r0, r11	; #-32768

	; v2 = enva(1, 20, 0, 127);
	ldr r6, [r10, #AK_OPINSTANCE+4*3]
	mov r1, r6, asr #8
	mov r4, #642
	add r6, r6, r4
	cmp r6, r11, asl #8
	movgt r6, r11, asl #8
	str r6, [r10, #AK_OPINSTANCE+4*3]
	; v2 = vol(127)
	mov r14, #127
	mul r1, r14, r1
	mov r1, r1, asr #7

	; v1 = mul(v1, v2);
	mul r0, r1, r0
	mov r0, r0, asr #15

	; v1 = reverb(v1, 6, 29);
	ldr r6, [r10, #AK_OPINSTANCE+4*4]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(6)
	mov r14, #6
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
	; r12 = vol(29)
	mov r14, #29
	mul r12, r14, r12
	mov r12, r12, asr #7
	mov r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*5]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(6)
	mov r14, #6
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
	; r12 = vol(29)
	mov r14, #29
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*6]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(6)
	mov r14, #6
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
	; r12 = vol(29)
	mov r14, #29
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*7]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(6)
	mov r14, #6
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
	; r12 = vol(29)
	mov r14, #29
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*8]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(6)
	mov r14, #6
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
	; r12 = vol(29)
	mov r14, #29
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*9]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(6)
	mov r14, #6
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
	; r12 = vol(29)
	mov r14, #29
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*10]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(6)
	mov r14, #6
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
	; r12 = vol(29)
	mov r14, #29
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r5, r5, r12
	add r9, r9, #2048*4
	ldr r6, [r10, #AK_OPINSTANCE+4*11]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(6)
	mov r14, #6
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
	; r12 = vol(29)
	mov r14, #29
	mul r12, r14, r12
	mov r12, r12, asr #7
	add r0, r5, r12
	sub r9, r9, #2048*4*7
	; v1 = clamp(v1)
	cmp r0, r11		; #32767
	movgt r0, r11	; #32767
	cmn r0, r11		; #-32768
	mvnlt r0, r11	; #-32768

	; v1 = sv_flt_n(4, v1, 28, 20, 0);
	ldr r4, [r10, #AK_OPINSTANCE+4*(12+AK_LPF)]
	ldr r5, [r10, #AK_OPINSTANCE+4*(12+AK_HPF)]
	ldr r6, [r10, #AK_OPINSTANCE+4*(12+AK_BPF)]
	mov r14, r6, asr #7
	mov r12, #28
	mla r4, r14, r12, r4
	; r4 = clamp(r4)
	cmp r4, r11		; #32767
	movgt r4, r11	; #32767
	cmn r4, r11		; #-32768
	mvnlt r4, r11	; #-32768
	str r4, [r10, #AK_OPINSTANCE+4*(12+AK_LPF)]
	mov r12, #20
	mul r14, r12, r14
	mov r12, r0
	sub r12, r12, r4
	sub r5, r12, r14
	; r5 = clamp(r5)
	cmp r5, r11		; #32767
	movgt r5, r11	; #32767
	cmn r5, r11		; #-32768
	mvnlt r5, r11	; #-32768
	str r5, [r10, #AK_OPINSTANCE+4*(12+AK_HPF)]
	mov r14, r5, asr #7
	mov r12, #28
	mla r6, r12, r14, r6
	; r6 = clamp(r6)
	cmp r6, r11		; #32767
	movgt r6, r11	; #32767
	cmn r6, r11		; #-32768
	mvnlt r6, r11	; #-32768
	str r6, [r10, #AK_OPINSTANCE+4*(12+AK_BPF)]
	mov r0, r4

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*15]
	cmp r7, r4
	blt Inst16Loop

;----------------------------------------------------------------------------
; Instrument 16 - Loop Generator (Offset: 2782 Length: 2784)
;----------------------------------------------------------------------------

	mov r7, #2784
	ldr r6, [r10, #AK_SMPADDR+4*15]
	add r6, r6, #2782	; src1
	sub r4, r6, r7	; src2
	mov r0, r11, lsl #8	; 32767<<8
	mov r1, r7
	bl divide
	mov r5, r0	; delta = divs.w(32767<<8,repeat_length)
	mov r14, #0	; rampup
	mov r12, r11, lsl #8	; rampdown
LoopGen_15:
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
	bne LoopGen_15

;----------------------------------------------------------------------------
; Instrument 17 - 'JosSs_303_01'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst17Loop:
	; v2 = envd(0, 3, 0, 127);
	mov r4, #16384
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	movle r6, #0
	mov r1, r6
	; v2 = vol(127)
	mov r14, #127
	mul r1, r14, r1
	mov r1, r1, asr #7

	; v1 = osc_saw(1, 1310, 127);
	ldr r0, [r10, #AK_OPINSTANCE+4*0]
	add r0, r0, #1310
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	str r0, [r10, #AK_OPINSTANCE+4*0]	
	; v1 = vol(127)
	mov r14, #127
	mul r0, r14, r0
	mov r0, r0, asr #7

	; v3 = mul(v2, -288);
	mvn r14, #287
	mul r2, r14, r1
	mov r2, r2, asr #15

	; v1 = sv_flt_n(3, v1, v3, 0, 2);
	ldr r4, [r10, #AK_OPINSTANCE+4*(1+AK_LPF)]
	ldr r5, [r10, #AK_OPINSTANCE+4*(1+AK_HPF)]
	ldr r6, [r10, #AK_OPINSTANCE+4*(1+AK_BPF)]
	mov r14, r6, asr #7
	mla r4, r2, r14, r4
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
	mla r6, r2, r14, r6
	; r6 = clamp(r6)
	cmp r6, r11		; #32767
	movgt r6, r11	; #32767
	cmn r6, r11		; #-32768
	mvnlt r6, r11	; #-32768
	str r6, [r10, #AK_OPINSTANCE+4*(1+AK_BPF)]
	mov r0, r6

	; v1 = mul(v2, v1);
	mul r0, r1, r0
	mov r0, r0, asr #15

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*16]
	cmp r7, r4
	blt Inst17Loop

;----------------------------------------------------------------------------
; Instrument 18 - 'JosSs_303_02'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst18Loop:
	; v2 = envd(0, 3, 0, 127);
	mov r4, #16384
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	movle r6, #0
	mov r1, r6
	; v2 = vol(127)
	mov r14, #127
	mul r1, r14, r1
	mov r1, r1, asr #7

	; v1 = osc_saw(1, 1310, 127);
	ldr r0, [r10, #AK_OPINSTANCE+4*0]
	add r0, r0, #1310
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	str r0, [r10, #AK_OPINSTANCE+4*0]	
	; v1 = vol(127)
	mov r14, #127
	mul r0, r14, r0
	mov r0, r0, asr #7

	; v3 = mul(v2, -81);
	mvn r14, #80
	mul r2, r14, r1
	mov r2, r2, asr #15

	; v1 = sv_flt_n(3, v1, v3, 0, 2);
	ldr r4, [r10, #AK_OPINSTANCE+4*(1+AK_LPF)]
	ldr r5, [r10, #AK_OPINSTANCE+4*(1+AK_HPF)]
	ldr r6, [r10, #AK_OPINSTANCE+4*(1+AK_BPF)]
	mov r14, r6, asr #7
	mla r4, r2, r14, r4
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
	mla r6, r2, r14, r6
	; r6 = clamp(r6)
	cmp r6, r11		; #32767
	movgt r6, r11	; #32767
	cmn r6, r11		; #-32768
	mvnlt r6, r11	; #-32768
	str r6, [r10, #AK_OPINSTANCE+4*(1+AK_BPF)]
	mov r0, r6

	; v1 = mul(v2, v1);
	mul r0, r1, r0
	mov r0, r0, asr #15

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*17]
	cmp r7, r4
	blt Inst18Loop

;----------------------------------------------------------------------------
; Instrument 19 - 'JosSs_303_03'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst19Loop:
	; v2 = envd(0, 3, 0, 127);
	mov r4, #16384
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	movle r6, #0
	mov r1, r6
	; v2 = vol(127)
	mov r14, #127
	mul r1, r14, r1
	mov r1, r1, asr #7

	; v1 = osc_saw(1, 1310, 127);
	ldr r0, [r10, #AK_OPINSTANCE+4*0]
	add r0, r0, #1310
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	str r0, [r10, #AK_OPINSTANCE+4*0]	
	; v1 = vol(127)
	mov r14, #127
	mul r0, r14, r0
	mov r0, r0, asr #7

	; v3 = mul(v2, 96);
	mov r14, #96
	mul r2, r14, r1
	mov r2, r2, asr #15

	; v1 = sv_flt_n(3, v1, v3, 0, 2);
	ldr r4, [r10, #AK_OPINSTANCE+4*(1+AK_LPF)]
	ldr r5, [r10, #AK_OPINSTANCE+4*(1+AK_HPF)]
	ldr r6, [r10, #AK_OPINSTANCE+4*(1+AK_BPF)]
	mov r14, r6, asr #7
	mla r4, r2, r14, r4
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
	mla r6, r2, r14, r6
	; r6 = clamp(r6)
	cmp r6, r11		; #32767
	movgt r6, r11	; #32767
	cmn r6, r11		; #-32768
	mvnlt r6, r11	; #-32768
	str r6, [r10, #AK_OPINSTANCE+4*(1+AK_BPF)]
	mov r0, r6

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
; Instrument 20 - 'JosSs_Lead_05'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst20Loop:
	; v2 = envd(0, 52, 0, 127);
	mov r4, #96
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	movle r6, #0
	mov r1, r6
	; v2 = vol(127)
	mov r14, #127
	mul r1, r14, r1
	mov r1, r1, asr #7

	; v4 = mul(v2, 128);
	mov r3, r1, asr #8	; val<<7>>15

	; v3 = osc_saw(3, 1310, 127);
	ldr r2, [r10, #AK_OPINSTANCE+4*0]
	add r2, r2, #1310
	mov r2, r2, asl #16
	mov r2, r2, asr #16	; Sign extend word to long.
	str r2, [r10, #AK_OPINSTANCE+4*0]	
	; v3 = vol(127)
	mov r14, #127
	mul r2, r14, r2
	mov r2, r2, asr #7

	; v1 = osc_saw(5, 1313, 127);
	ldr r0, [r10, #AK_OPINSTANCE+4*1]
	add r0, r0, #1313
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	str r0, [r10, #AK_OPINSTANCE+4*1]	
	; v1 = vol(127)
	mov r14, #127
	mul r0, r14, r0
	mov r0, r0, asr #7

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

	; v3 = osc_saw(7, 1307, 127);
	ldr r2, [r10, #AK_OPINSTANCE+4*2]
	add r2, r2, #1307
	mov r2, r2, asl #16
	mov r2, r2, asr #16	; Sign extend word to long.
	str r2, [r10, #AK_OPINSTANCE+4*2]	
	; v3 = vol(127)
	mov r14, #127
	mul r2, r14, r2
	mov r2, r2, asr #7

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

	; v1 = sv_flt_n(10, v1, v4, 13, 0);
	ldr r4, [r10, #AK_OPINSTANCE+4*(3+AK_LPF)]
	ldr r5, [r10, #AK_OPINSTANCE+4*(3+AK_HPF)]
	ldr r6, [r10, #AK_OPINSTANCE+4*(3+AK_BPF)]
	mov r14, r6, asr #7
	mla r4, r3, r14, r4
	; r4 = clamp(r4)
	cmp r4, r11		; #32767
	movgt r4, r11	; #32767
	cmn r4, r11		; #-32768
	mvnlt r4, r11	; #-32768
	str r4, [r10, #AK_OPINSTANCE+4*(3+AK_LPF)]
	mov r12, #13
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
	mla r6, r3, r14, r6
	; r6 = clamp(r6)
	cmp r6, r11		; #32767
	movgt r6, r11	; #32767
	cmn r6, r11		; #-32768
	mvnlt r6, r11	; #-32768
	str r6, [r10, #AK_OPINSTANCE+4*(3+AK_BPF)]
	mov r0, r4

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*19]
	cmp r7, r4
	blt Inst20Loop

;----------------------------------------------------------------------------
; Instrument 20 - Loop Generator (Offset: 18015 Length: 18017)
;----------------------------------------------------------------------------

	mov r7, #18017
	ldr r6, [r10, #AK_SMPADDR+4*19]
	add r6, r6, #18015	; src1
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
; Instrument 21 - 'JosSs_Bass_05_02'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst21Loop:
	; v1 = osc_sine(0, 650, 127);
	ldr r6, [r10, #AK_OPINSTANCE+4*0]
	add r6, r6, #650
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
	; v1 = vol(127)
	mov r14, #127
	mul r0, r14, r0
	mov r0, r0, asr #7

	; v2 = osc_sine(1, 658, 127);
	ldr r6, [r10, #AK_OPINSTANCE+4*1]
	add r6, r6, #658
	str r6, [r10, #AK_OPINSTANCE+4*1]
	sub r6, r6, #16384
	mov r6, r6, asl #16
	mov r6, r6, asr #16	; Sign extend word to long.
	movs r4, r6
	rsblt r4, r4, #0
	sub r4, r11, r4	; #32767
	mul r4, r6, r4
	mov r4, r4, asr #16
	mov r1, r4, asl #3
	; v2 = vol(127)
	mov r14, #127
	mul r1, r14, r1
	mov r1, r1, asr #7

	; v1 = mul(v1, v2);
	mul r0, r1, r0
	mov r0, r0, asr #15

	; v1 = cmb_flt_n(4, v1, v2, 33, 127);
	ldr r6, [r10, #AK_OPINSTANCE+4*2]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(33)
	mov r14, #33
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
	cmp r6, r1
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*2]
	; v1 = vol(127)
	mov r14, #127
	mul r0, r14, r0
	mov r0, r0, asr #7

	; v2 = osc_saw(6, 642, 85);
	ldr r1, [r10, #AK_OPINSTANCE+4*3]
	add r1, r1, #642
	mov r1, r1, asl #16
	mov r1, r1, asr #16	; Sign extend word to long.
	str r1, [r10, #AK_OPINSTANCE+4*3]	
	; v2 = vol(85)
	mov r14, #85
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

	; v1 = sv_flt_n(10, v1, 10, 127, 0);
	ldr r4, [r10, #AK_OPINSTANCE+4*(4+AK_LPF)]
	ldr r5, [r10, #AK_OPINSTANCE+4*(4+AK_HPF)]
	ldr r6, [r10, #AK_OPINSTANCE+4*(4+AK_BPF)]
	mov r14, r6, asr #7
	mov r12, #10
	mla r4, r14, r12, r4
	; r4 = clamp(r4)
	cmp r4, r11		; #32767
	movgt r4, r11	; #32767
	cmn r4, r11		; #-32768
	mvnlt r4, r11	; #-32768
	str r4, [r10, #AK_OPINSTANCE+4*(4+AK_LPF)]
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
	str r5, [r10, #AK_OPINSTANCE+4*(4+AK_HPF)]
	mov r14, r5, asr #7
	mov r12, #10
	mla r6, r12, r14, r6
	; r6 = clamp(r6)
	cmp r6, r11		; #32767
	movgt r6, r11	; #32767
	cmn r6, r11		; #-32768
	mvnlt r6, r11	; #-32768
	str r6, [r10, #AK_OPINSTANCE+4*(4+AK_BPF)]
	mov r0, r4

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*20]
	cmp r7, r4
	blt Inst21Loop

;----------------------------------------------------------------------------
; Instrument 21 - Loop Generator (Offset: 5698 Length: 4612)
;----------------------------------------------------------------------------

	mov r7, #4612
	ldr r6, [r10, #AK_SMPADDR+4*20]
	add r6, r6, #5698	; src1
	sub r4, r6, r7	; src2
	mov r0, r11, lsl #8	; 32767<<8
	mov r1, r7
	bl divide
	mov r5, r0	; delta = divs.w(32767<<8,repeat_length)
	mov r14, #0	; rampup
	mov r12, r11, lsl #8	; rampdown
LoopGen_20:
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
	bne LoopGen_20

; ============================================================================

.if AK_CLEAR_FIRST_2_BYTES
	; Clear first 2 bytes of each sample
	adr r4, AK_SmpAddr
	mov r7, #21
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
	.rept 17
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
	.long 0x00003010	; Instrument 1 Length
	.long 0x00001476	; Instrument 2 Length
	.long 0x00001476	; Instrument 3 Length
	.long 0x00008888	; Instrument 4 Length
	.long 0x00000900	; Instrument 5 Length
	.long 0x00000900	; Instrument 6 Length
	.long 0x00000900	; Instrument 7 Length
	.long 0x000006fc	; Instrument 8 Length
	.long 0x00000574	; Instrument 9 Length
	.long 0x000008d0	; Instrument 10 Length
	.long 0x000006c0	; Instrument 11 Length
	.long 0x0000071a	; Instrument 12 Length
	.long 0x00002846	; Instrument 13 Length
	.long 0x000015be	; Instrument 14 Length
	.long 0x000015be	; Instrument 15 Length
	.long 0x000015be	; Instrument 16 Length
	.long 0x000001fe	; Instrument 17 Length
	.long 0x000001fe	; Instrument 18 Length
	.long 0x000001fe	; Instrument 19 Length
	.long 0x00008cc0	; Instrument 20 Length
	.long 0x00002846	; Instrument 21 Length
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
	.long 0x00000000	; External Sample 1 Length
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
	.skip 17*4
AK_EnvDValue:
	; NB. Must follow AK_OpInstance!
	.skip 0*4

; ============================================================================

.equ AK_SampleTotalBytes,	148510
