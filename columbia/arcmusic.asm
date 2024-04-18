; ============================================================================
; akp2arc.py
; input = columbia\script.txt.
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

.equ AK_SMP_LEN,		155040
.equ AK_EXT_SMP_LEN,	0

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
; Instrument 1 - 'colombia_kick'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst1Loop:
	; v2 = envd(0, 10, 0, 127);
	mov r4, #2520
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	movle r6, #0
	mov r1, r6
	; v2 = vol(v2, 127)
	mov r14, #127
	mul r1, r14, r1
	mov r1, r1, asr #7

	; v3 = mul(v2, 1024);
	mov r2, r1, asr #5	; val<<10>>15

	; v3 = add(v3, -300);
	mov r2, r2, asl #16
	mov r2, r2, asr #16	; Sign extend word to long.
	mvn r14, #299
	add r2, r2, r14
	; v3 = clamp(v3)
	cmp r2, r11		; #32767
	movgt r2, r11	; #32767
	cmn r2, r11		; #-32768
	mvnlt r2, r11	; #-32768

	; v1 = osc_sine(3, v3, 128);
	ldr r6, [r10, #AK_OPINSTANCE+4*0]
	add r6, r6, r2
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
	; v1 = vol(v1, 128)
	; NOOP -- val<<7>>7

	; v1 = mul(v1, v2);
	mul r0, r1, r0
	mov r0, r0, asr #15

	; v2 = envd(5, 2, 0, 128);
	mov r4, #32767
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	movle r6, #0
	mov r1, r6
	; v2 = vol(v2, 128)
	; NOOP -- val<<7>>7

	; v3 = osc_saw(6, 2304, 128);
	ldr r2, [r10, #AK_OPINSTANCE+4*1]
	add r2, r2, #2304
	mov r2, r2, asl #16
	mov r2, r2, asr #16	; Sign extend word to long.
	str r2, [r10, #AK_OPINSTANCE+4*1]	
	; v3 = vol(v3, 128)
	; NOOP -- val<<7>>7

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
	ldr r4, [r10, #AK_SMPLEN+4*0]
	cmp r7, r4
	blt Inst1Loop

;----------------------------------------------------------------------------
; Instrument 2 - 'colombia_snare'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst2Loop:
	; v3 = envd(0, 16, 8, 128);
	mov r4, #992
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	cmp r6, #2048
	movle r6, #2048
	mov r2, r6
	; v3 = vol(v3, 128)
	; NOOP -- val<<7>>7

	; v4 = envd(1, 9, 24, 128);
	mov r4, #2978
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	cmp r6, #6144
	movle r6, #6144
	mov r3, r6
	; v4 = vol(v4, 128)
	; NOOP -- val<<7>>7

	; v1 = osc_saw(2, v2, 128);
	ldr r0, [r10, #AK_OPINSTANCE+4*0]
	add r0, r0, r1
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	str r0, [r10, #AK_OPINSTANCE+4*0]	
	; v1 = vol(v1, 128)
	; NOOP -- val<<7>>7

	; v1 = mul(v1, v3);
	mul r0, r2, r0
	mov r0, r0, asr #15

	; v1 = sv_flt_n(4, v1, 12, 16, 1);
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

	; v3 = cmb_flt_n(5, v1, 256, 64, 48);
	ldr r6, [r10, #AK_OPINSTANCE+4*4]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 64)
	mov r4, r4, asr #1	; val<<6>>7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	add r2, r0, r4
	; v3 = clamp(v3)
	cmp r2, r11		; #32767
	movgt r2, r11	; #32767
	cmn r2, r11		; #-32768
	mvnlt r2, r11	; #-32768
	str r2, [r9, r6, lsl #2]
	add r6, r6, #1
	mov r14, #256
	cmp r6, r14
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*4]
	; v3 = vol(v3, 48)
	mov r14, #48
	mul r2, r14, r2
	mov r2, r2, asr #7

	; v2 = add(v1, 23269);
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	mov r14, #23269
	add r1, r0, r14
	; v2 = clamp(v2)
	cmp r1, r11		; #32767
	movgt r1, r11	; #32767
	cmn r1, r11		; #-32768
	mvnlt r1, r11	; #-32768

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

	; v2 = mul(v2, v2);
	mov r14, r1
	mul r1, r14, r1
	mov r1, r1, asr #15

	; v1 = mul(v1, v4);
	mul r0, r3, r0
	mov r0, r0, asr #15

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*1]
	cmp r7, r4
	blt Inst2Loop

;----------------------------------------------------------------------------
; Instrument 2 - Loop Generator (Offset: 4724 Length: 3468)
;----------------------------------------------------------------------------

	mov r7, #3468
	ldr r6, [r10, #AK_SMPADDR+4*1]
	add r6, r6, #4724	; src1
	sub r4, r6, r7	; src2
	mov r0, r11, lsl #8	; 32767<<8
	mov r1, r7
	bl divide
	mov r5, r0	; delta = divs.w(32767<<8,repeat_length)
	mov r14, #0	; rampup
	mov r12, r11, lsl #8	; rampdown
LoopGen_1:
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
	bne LoopGen_1

;----------------------------------------------------------------------------
; Instrument 3 - 'colombia_kick+snare'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
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

	; v2 = clone(smp,1, 0);
	mov r1, r7
	ldr r6, [r10, #AK_SMPADDR+4*1]
	ldr r4, [r10, #AK_SMPLEN+4*1]
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
	ldr r4, [r10, #AK_SMPLEN+4*2]
	cmp r7, r4
	blt Inst3Loop

;----------------------------------------------------------------------------
; Instrument 4 - 'colombia_openhat'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst4Loop:
	; v1 = clone(smp,1, 3072);
	add r0, r7, #3072
	ldr r6, [r10, #AK_SMPADDR+4*1]
	ldr r4, [r10, #AK_SMPLEN+4*1]
	cmp r0, r4
	movge r0, #0
	ldrltb r0, [r6, r0]
	mov r0, r0, asl #24
	mov r0, r0, asr #16

	; v1 = sv_flt_n(1, v1, 120, 127, 1);
	ldr r4, [r10, #AK_OPINSTANCE+4*(0+AK_LPF)]
	ldr r5, [r10, #AK_OPINSTANCE+4*(0+AK_HPF)]
	ldr r6, [r10, #AK_OPINSTANCE+4*(0+AK_BPF)]
	mov r14, r6, asr #7
	mov r12, #120
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
	mov r12, #120
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
	ldr r4, [r10, #AK_SMPLEN+4*3]
	cmp r7, r4
	blt Inst4Loop

;----------------------------------------------------------------------------
; Instrument 5 - 'colombia_closedhat'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst5Loop:
	; v2 = envd(0, 4, 24, 128);
	mov r4, #10922
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	cmp r6, #6144
	movle r6, #6144
	mov r1, r6
	; v2 = vol(v2, 128)
	; NOOP -- val<<7>>7

	; v1 = clone(smp,3, 1044);
	add r0, r7, #1044
	ldr r6, [r10, #AK_SMPADDR+4*3]
	ldr r4, [r10, #AK_SMPLEN+4*3]
	cmp r0, r4
	movge r0, #0
	ldrltb r0, [r6, r0]
	mov r0, r0, asl #24
	mov r0, r0, asr #16

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
; Instrument 6 - 'colombia_kick+hat'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst6Loop:
	; v1 = clone(smp,0, 0);
	mov r0, r7
	ldr r6, [r10, #AK_SMPADDR+4*0]
	ldr r4, [r10, #AK_SMPLEN+4*0]
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
; Instrument 7 - 'colombia_ghostsnare'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst7Loop:
	; v2 = envd(0, 4, 24, 100);
	mov r4, #10922
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	cmp r6, #6144
	movle r6, #6144
	mov r1, r6
	; v2 = vol(v2, 100)
	mov r14, #100
	mul r1, r14, r1
	mov r1, r1, asr #7

	; v1 = clone(smp,1, 0);
	mov r0, r7
	ldr r6, [r10, #AK_SMPADDR+4*1]
	ldr r4, [r10, #AK_SMPLEN+4*1]
	cmp r0, r4
	movge r0, #0
	ldrltb r0, [r6, r0]
	mov r0, r0, asl #24
	mov r0, r0, asr #16

	; v1 = mul(v1, v2);
	mul r0, r1, r0
	mov r0, r0, asr #15

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*6]
	cmp r7, r4
	blt Inst7Loop

;----------------------------------------------------------------------------
; Instrument 8 - 'colombia_reversekick'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst8Loop:
	; v1 = clone_reverse(smp,0, 0);
	mov r0, r7
	ldr r6, [r10, #AK_SMPADDR+4*(0+1)]
	ldr r4, [r10, #AK_SMPLEN+4*0]
	cmp r0, r4
	movge r0, #0
	rsblt r0, r0, #0
	ldrltb r0, [r6, r0]
	mov r0, r0, asl #24
	mov r0, r0, asr #16

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*7]
	cmp r7, r4
	blt Inst8Loop

;----------------------------------------------------------------------------
; Instrument 9 - 'colombia_reversesnare'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst9Loop:
	; v1 = clone_reverse(smp,1, 4096);
	add r0, r7, #4096
	ldr r6, [r10, #AK_SMPADDR+4*(1+1)]
	ldr r4, [r10, #AK_SMPLEN+4*1]
	cmp r0, r4
	movge r0, #0
	rsblt r0, r0, #0
	ldrltb r0, [r6, r0]
	mov r0, r0, asl #24
	mov r0, r0, asr #16

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*8]
	cmp r7, r4
	blt Inst9Loop

;----------------------------------------------------------------------------
; Instrument 10 - 'colombia_superbass'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst10Loop:
	; v2 = osc_sine(0, 123, 120);
	ldr r6, [r10, #AK_OPINSTANCE+4*0]
	add r6, r6, #123
	str r6, [r10, #AK_OPINSTANCE+4*0]
	sub r6, r6, #16384
	mov r6, r6, asl #16
	mov r6, r6, asr #16	; Sign extend word to long.
	movs r4, r6
	rsblt r4, r4, #0
	sub r4, r11, r4	; #32767
	mul r4, r6, r4
	mov r4, r4, asr #16
	mov r1, r4, asl #3
	; v2 = vol(v2, 120)
	mov r14, #120
	mul r1, r14, r1
	mov r1, r1, asr #7

	; v3 = osc_tri(1, 252, 120);
	ldr r6, [r10, #AK_OPINSTANCE+4*1]
	add r6, r6, #252
	mov r6, r6, asl #16
	mov r6, r6, asr #16	; Sign extend word to long.
	str r6, [r10, #AK_OPINSTANCE+4*1]
	cmp r6, #0
	mvnmi r6, r6
	sub r6, r6, #16384
	mov r2, r6, asl #1
	; v3 = vol(v3, 120)
	mov r14, #120
	mul r2, r14, r2
	mov r2, r2, asr #7

	; v2 = ctrl(v2);
	mov r1, r1, asr #9
	mov r1, r1, asl #16
	mov r1, r1, asr #16	; Sign extend word to long.
	add r1, r1, #64

	; v1 = osc_pulse(3, 500, v2, 65);
	ldr r6, [r10, #AK_OPINSTANCE+4*2]
	adds r6, r6, #500
	mov r6, r6, asl #16
	mov r6, r6, asr #16	; Sign extend word to long.
	str r6, [r10, #AK_OPINSTANCE+4*2]
	mov r4, #1024	; (65-63)<<9
	cmp r6, r4
	mvnlt r0, r11	; #-32768
	movge r0, r11	; #32767
	; v1 = vol(v1, v2)
	and r14, r1, #0xff
	mul r0, r14, r0
	mov r0, r0, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.

	; v4 = mul(v2, -32768);
	mvn r14, #32767
	mul r3, r14, r1
	mov r3, r3, asr #15

	; v4 = add(v4, 127);
	mov r3, r3, asl #16
	mov r3, r3, asr #16	; Sign extend word to long.
	mov r14, #127
	add r3, r3, r14
	; v4 = clamp(v4)
	cmp r3, r11		; #32767
	movgt r3, r11	; #32767
	cmn r3, r11		; #-32768
	mvnlt r3, r11	; #-32768

	; v1 = sv_flt_n(6, v1, v4, 127, 0);
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
	mla r6, r3, r14, r6
	; r6 = clamp(r6)
	cmp r6, r11		; #32767
	movgt r6, r11	; #32767
	cmn r6, r11		; #-32768
	mvnlt r6, r11	; #-32768
	str r6, [r10, #AK_OPINSTANCE+4*(3+AK_BPF)]
	mov r0, r4

	; v4 = envd(7, 32, 0, 128);
	mov r4, #254
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	movle r6, #0
	mov r3, r6
	; v4 = vol(v4, 128)
	; NOOP -- val<<7>>7

	; v1 = mul(v1, v4);
	mul r0, r3, r0
	mov r0, r0, asr #15

	; v2 = envd(9, 10, 12, 128);
	mov r4, #2520
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	cmp r6, #3072
	movle r6, #3072
	mov r1, r6
	; v2 = vol(v2, 128)
	; NOOP -- val<<7>>7

	; v2 = mul(v2, 128);
	mov r1, r1, asr #8	; val<<7>>15

	; v1 = sv_flt_n(11, v1, v2, 32, 0);
	ldr r4, [r10, #AK_OPINSTANCE+4*(6+AK_LPF)]
	ldr r5, [r10, #AK_OPINSTANCE+4*(6+AK_HPF)]
	ldr r6, [r10, #AK_OPINSTANCE+4*(6+AK_BPF)]
	mov r14, r6, asr #7
	mla r4, r1, r14, r4
	; r4 = clamp(r4)
	cmp r4, r11		; #32767
	movgt r4, r11	; #32767
	cmn r4, r11		; #-32768
	mvnlt r4, r11	; #-32768
	str r4, [r10, #AK_OPINSTANCE+4*(6+AK_LPF)]
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
	str r5, [r10, #AK_OPINSTANCE+4*(6+AK_HPF)]
	mov r14, r5, asr #7
	mla r6, r1, r14, r6
	; r6 = clamp(r6)
	cmp r6, r11		; #32767
	movgt r6, r11	; #32767
	cmn r6, r11		; #-32768
	mvnlt r6, r11	; #-32768
	str r6, [r10, #AK_OPINSTANCE+4*(6+AK_BPF)]
	mov r0, r4

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
	ldr r4, [r10, #AK_SMPLEN+4*9]
	cmp r7, r4
	blt Inst10Loop

;----------------------------------------------------------------------------
; Instrument 10 - Loop Generator (Offset: 8192 Length: 8192)
;----------------------------------------------------------------------------

	mov r7, #8192
	ldr r6, [r10, #AK_SMPADDR+4*9]
	add r6, r6, #8192	; src1
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
; Instrument 11 - 'colombia_superbass_high'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst11Loop:
	; v2 = osc_sine(0, 246, 120);
	ldr r6, [r10, #AK_OPINSTANCE+4*0]
	add r6, r6, #246
	str r6, [r10, #AK_OPINSTANCE+4*0]
	sub r6, r6, #16384
	mov r6, r6, asl #16
	mov r6, r6, asr #16	; Sign extend word to long.
	movs r4, r6
	rsblt r4, r4, #0
	sub r4, r11, r4	; #32767
	mul r4, r6, r4
	mov r4, r4, asr #16
	mov r1, r4, asl #3
	; v2 = vol(v2, 120)
	mov r14, #120
	mul r1, r14, r1
	mov r1, r1, asr #7

	; v3 = osc_tri(1, 252, 120);
	ldr r6, [r10, #AK_OPINSTANCE+4*1]
	add r6, r6, #252
	mov r6, r6, asl #16
	mov r6, r6, asr #16	; Sign extend word to long.
	str r6, [r10, #AK_OPINSTANCE+4*1]
	cmp r6, #0
	mvnmi r6, r6
	sub r6, r6, #16384
	mov r2, r6, asl #1
	; v3 = vol(v3, 120)
	mov r14, #120
	mul r2, r14, r2
	mov r2, r2, asr #7

	; v2 = ctrl(v2);
	mov r1, r1, asr #9
	mov r1, r1, asl #16
	mov r1, r1, asr #16	; Sign extend word to long.
	add r1, r1, #64

	; v1 = osc_pulse(3, 1000, v2, 65);
	ldr r6, [r10, #AK_OPINSTANCE+4*2]
	adds r6, r6, #1000
	mov r6, r6, asl #16
	mov r6, r6, asr #16	; Sign extend word to long.
	str r6, [r10, #AK_OPINSTANCE+4*2]
	mov r4, #1024	; (65-63)<<9
	cmp r6, r4
	mvnlt r0, r11	; #-32768
	movge r0, r11	; #32767
	; v1 = vol(v1, v2)
	and r14, r1, #0xff
	mul r0, r14, r0
	mov r0, r0, asr #7
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.

	; v4 = mul(v2, -32768);
	mvn r14, #32767
	mul r3, r14, r1
	mov r3, r3, asr #15

	; v4 = add(v4, 127);
	mov r3, r3, asl #16
	mov r3, r3, asr #16	; Sign extend word to long.
	mov r14, #127
	add r3, r3, r14
	; v4 = clamp(v4)
	cmp r3, r11		; #32767
	movgt r3, r11	; #32767
	cmn r3, r11		; #-32768
	mvnlt r3, r11	; #-32768

	; v1 = sv_flt_n(6, v1, v4, 127, 0);
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
	mla r6, r3, r14, r6
	; r6 = clamp(r6)
	cmp r6, r11		; #32767
	movgt r6, r11	; #32767
	cmn r6, r11		; #-32768
	mvnlt r6, r11	; #-32768
	str r6, [r10, #AK_OPINSTANCE+4*(3+AK_BPF)]
	mov r0, r4

	; v4 = envd(7, 32, 0, 128);
	mov r4, #254
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	movle r6, #0
	mov r3, r6
	; v4 = vol(v4, 128)
	; NOOP -- val<<7>>7

	; v1 = mul(v1, v4);
	mul r0, r3, r0
	mov r0, r0, asr #15

	; v2 = envd(9, 10, 12, 128);
	mov r4, #2520
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	cmp r6, #3072
	movle r6, #3072
	mov r1, r6
	; v2 = vol(v2, 128)
	; NOOP -- val<<7>>7

	; v2 = mul(v2, 128);
	mov r1, r1, asr #8	; val<<7>>15

	; v1 = sv_flt_n(11, v1, v2, 32, 0);
	ldr r4, [r10, #AK_OPINSTANCE+4*(6+AK_LPF)]
	ldr r5, [r10, #AK_OPINSTANCE+4*(6+AK_HPF)]
	ldr r6, [r10, #AK_OPINSTANCE+4*(6+AK_BPF)]
	mov r14, r6, asr #7
	mla r4, r1, r14, r4
	; r4 = clamp(r4)
	cmp r4, r11		; #32767
	movgt r4, r11	; #32767
	cmn r4, r11		; #-32768
	mvnlt r4, r11	; #-32768
	str r4, [r10, #AK_OPINSTANCE+4*(6+AK_LPF)]
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
	str r5, [r10, #AK_OPINSTANCE+4*(6+AK_HPF)]
	mov r14, r5, asr #7
	mla r6, r1, r14, r6
	; r6 = clamp(r6)
	cmp r6, r11		; #32767
	movgt r6, r11	; #32767
	cmn r6, r11		; #-32768
	mvnlt r6, r11	; #-32768
	str r6, [r10, #AK_OPINSTANCE+4*(6+AK_BPF)]
	mov r0, r4

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
	ldr r4, [r10, #AK_SMPLEN+4*10]
	cmp r7, r4
	blt Inst11Loop

;----------------------------------------------------------------------------
; Instrument 11 - Loop Generator (Offset: 4096 Length: 4096)
;----------------------------------------------------------------------------

	mov r7, #4096
	ldr r6, [r10, #AK_SMPADDR+4*10]
	add r6, r6, #4096	; src1
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
; Instrument 12 - 'colombia_physical_flute'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst12Loop:
	; v1 = osc_noise(66);
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
	; v1 = vol(v1, 66)
	mov r14, #66
	mul r0, r14, r0
	mov r0, r0, asr #7

	; v4 = add(v1, 0);
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	mov r14, #0
	add r3, r0, r14
	; v4 = clamp(v4)
	cmp r3, r11		; #32767
	movgt r3, r11	; #32767
	cmn r3, r11		; #-32768
	mvnlt r3, r11	; #-32768

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

	; v2 = dly_cyc(3, v1, 76, 127);
	mov r1, r0
	; v2 = vol(v2, 127)
	mov r14, #127
	mul r1, r14, r1
	mov r1, r1, asr #7
	ldr r6, [r10, #AK_OPINSTANCE+4*0]
	str r1, [r9, r6, lsl #2]
	add r6, r6, #1
	cmp r6, #76
	movge r6, #0
	str r6, [r10, #AK_OPINSTANCE+4*0]
	ldr r1, [r9, r6, lsl #2]

	; v2 = mul(v2, -32768);
	mvn r14, #32767
	mul r1, r14, r1
	mov r1, r1, asr #15

	; v3 = envd(5, 26, 0, 127);
	mov r4, #385
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	movle r6, #0
	mov r2, r6
	; v3 = vol(v3, 127)
	mov r14, #127
	mul r2, r14, r2
	mov r2, r2, asr #7

	; v3 = ctrl(v3);
	mov r2, r2, asr #9
	mov r2, r2, asl #16
	mov r2, r2, asr #16	; Sign extend word to long.
	add r2, r2, #64

	; v3 = mul(v3, -32768);
	mvn r14, #32767
	mul r2, r14, r2
	mov r2, r2, asr #15

	; v3 = add(v3, 128);
	mov r2, r2, asl #16
	mov r2, r2, asr #16	; Sign extend word to long.
	mov r14, #128
	add r2, r2, r14
	; v3 = clamp(v3)
	cmp r2, r11		; #32767
	movgt r2, r11	; #32767
	cmn r2, r11		; #-32768
	mvnlt r2, r11	; #-32768

	; v2 = sv_flt_n(9, v2, v3, 21, 0);
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
	mov r12, #21
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
	mla r6, r2, r14, r6
	; r6 = clamp(r6)
	cmp r6, r11		; #32767
	movgt r6, r11	; #32767
	cmn r6, r11		; #-32768
	mvnlt r6, r11	; #-32768
	str r6, [r10, #AK_OPINSTANCE+4*(1+AK_BPF)]
	mov r1, r4

	; v4 = mul(v4, -16384);
	mvn r14, #16383
	mul r3, r14, r3
	mov r3, r3, asr #15

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

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*11]
	cmp r7, r4
	blt Inst12Loop

;----------------------------------------------------------------------------
; Instrument 12 - Loop Generator (Offset: 27268 Length: 5500)
;----------------------------------------------------------------------------

	mov r7, #5500
	ldr r6, [r10, #AK_SMPADDR+4*11]
	add r6, r6, #27268	; src1
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
; Instrument 13 - 'colombia_pling1'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst13Loop:
	; v1 = clone(smp,9, 1024);
	add r0, r7, #1024
	ldr r6, [r10, #AK_SMPADDR+4*9]
	ldr r4, [r10, #AK_SMPLEN+4*9]
	cmp r0, r4
	movge r0, #0
	ldrltb r0, [r6, r0]
	mov r0, r0, asl #24
	mov r0, r0, asr #16

	; v1 = sv_flt_n(1, v1, 48, 0, 1);
	ldr r4, [r10, #AK_OPINSTANCE+4*(0+AK_LPF)]
	ldr r5, [r10, #AK_OPINSTANCE+4*(0+AK_HPF)]
	ldr r6, [r10, #AK_OPINSTANCE+4*(0+AK_BPF)]
	mov r14, r6, asr #7
	mov r12, #48
	mla r4, r14, r12, r4
	; r4 = clamp(r4)
	cmp r4, r11		; #32767
	movgt r4, r11	; #32767
	cmn r4, r11		; #-32768
	mvnlt r4, r11	; #-32768
	str r4, [r10, #AK_OPINSTANCE+4*(0+AK_LPF)]
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
	str r5, [r10, #AK_OPINSTANCE+4*(0+AK_HPF)]
	mov r14, r5, asr #7
	mov r12, #48
	mla r6, r12, r14, r6
	; r6 = clamp(r6)
	cmp r6, r11		; #32767
	movgt r6, r11	; #32767
	cmn r6, r11		; #-32768
	mvnlt r6, r11	; #-32768
	str r6, [r10, #AK_OPINSTANCE+4*(0+AK_BPF)]
	mov r0, r5

	; v2 = envd(2, 8, 16, 128);
	mov r4, #3640
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	cmp r6, #4096
	movle r6, #4096
	mov r1, r6
	; v2 = vol(v2, 128)
	; NOOP -- val<<7>>7

	; v1 = mul(v1, v2);
	mul r0, r1, r0
	mov r0, r0, asr #15

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*12]
	cmp r7, r4
	blt Inst13Loop

;----------------------------------------------------------------------------
; Instrument 14 - 'colombia_lead'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst14Loop:
	; v1 = osc_tri(0, 1000, 92);
	ldr r6, [r10, #AK_OPINSTANCE+4*0]
	add r6, r6, #1000
	mov r6, r6, asl #16
	mov r6, r6, asr #16	; Sign extend word to long.
	str r6, [r10, #AK_OPINSTANCE+4*0]
	cmp r6, #0
	mvnmi r6, r6
	sub r6, r6, #16384
	mov r0, r6, asl #1
	; v1 = vol(v1, 92)
	mov r14, #92
	mul r0, r14, r0
	mov r0, r0, asr #7

	; v2 = osc_tri(1, 1007, 92);
	ldr r6, [r10, #AK_OPINSTANCE+4*1]
	add r6, r6, #1007
	mov r6, r6, asl #16
	mov r6, r6, asr #16	; Sign extend word to long.
	str r6, [r10, #AK_OPINSTANCE+4*1]
	cmp r6, #0
	mvnmi r6, r6
	sub r6, r6, #16384
	mov r1, r6, asl #1
	; v2 = vol(v2, 92)
	mov r14, #92
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

	; v2 = osc_saw(3, 2000, 72);
	ldr r1, [r10, #AK_OPINSTANCE+4*2]
	add r1, r1, #2000
	mov r1, r1, asl #16
	mov r1, r1, asr #16	; Sign extend word to long.
	str r1, [r10, #AK_OPINSTANCE+4*2]	
	; v2 = vol(v2, 72)
	mov r14, #72
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

	; v2 = envd(5, 8, 0, 128);
	mov r4, #3640
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	movle r6, #0
	mov r1, r6
	; v2 = vol(v2, 128)
	; NOOP -- val<<7>>7

	; v2 = mul(v2, 64);
	mov r1, r1, asr #9	; val<<6>>15

	; v2 = add(v2, 10);
	mov r1, r1, asl #16
	mov r1, r1, asr #16	; Sign extend word to long.
	mov r14, #10
	add r1, r1, r14
	; v2 = clamp(v2)
	cmp r1, r11		; #32767
	movgt r1, r11	; #32767
	cmn r1, r11		; #-32768
	mvnlt r1, r11	; #-32768

	; v1 = sv_flt_n(8, v1, v2, 127, 2);
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
	ldr r4, [r10, #AK_SMPLEN+4*13]
	cmp r7, r4
	blt Inst14Loop

;----------------------------------------------------------------------------
; Instrument 14 - Loop Generator (Offset: 4096 Length: 4096)
;----------------------------------------------------------------------------

	mov r7, #4096
	ldr r6, [r10, #AK_SMPADDR+4*13]
	add r6, r6, #4096	; src1
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
; Instrument 15 - 'colombia_chord1'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst15Loop:
	; v2 = osc_sine(0, 4, 64);
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
	mov r1, r4, asl #3
	; v2 = vol(v2, 64)
	mov r1, r1, asr #1	; val<<6>>7

	; v2 = ctrl(v2);
	mov r1, r1, asr #9
	mov r1, r1, asl #16
	mov r1, r1, asr #16	; Sign extend word to long.
	add r1, r1, #64

	; v1 = chordgen(2, 13, 3, 7, 10, v2);
	ldr r4, [r10, #AK_SMPADDR+4*13]
	ldr r12, [r10, #AK_SMPLEN+4*13]
	ldrb r6, [r4, r7]
	mov r6, r6, asl #24
	mov r6, r6, asr #17
	add r4, r4, r1
	sub r12, r12, r1
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
	add r5, r5, #98048
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

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*14]
	cmp r7, r4
	blt Inst15Loop

;----------------------------------------------------------------------------
; Instrument 15 - Loop Generator (Offset: 3894 Length: 2250)
;----------------------------------------------------------------------------

	mov r7, #2250
	ldr r6, [r10, #AK_SMPADDR+4*14]
	add r6, r6, #3894	; src1
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
; Instrument 16 - 'colombia_chord2'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst16Loop:
	; v2 = osc_sine(0, 4, 64);
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
	mov r1, r4, asl #3
	; v2 = vol(v2, 64)
	mov r1, r1, asr #1	; val<<6>>7

	; v2 = ctrl(v2);
	mov r1, r1, asr #9
	mov r1, r1, asl #16
	mov r1, r1, asr #16	; Sign extend word to long.
	add r1, r1, #64

	; v1 = chordgen(2, 13, 3, 7, 9, v2);
	ldr r4, [r10, #AK_SMPADDR+4*13]
	ldr r12, [r10, #AK_SMPLEN+4*13]
	ldrb r6, [r4, r7]
	mov r6, r6, asl #24
	mov r6, r6, asr #17
	add r4, r4, r1
	sub r12, r12, r1
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
	add r5, r5, #98048
	str r5, [r10, #AK_OPINSTANCE+4*(1+AK_CHORD2)]
	mov r14, r14, asl #24
	add r6, r6, r14, asr #17
	ldr r5, [r10, #AK_OPINSTANCE+4*(1+AK_CHORD3)]
	cmp r12, r5, lsr #15
	ldrgeb r14, [r4, r5, lsr #15]
	movlt r14, #0
	add r5, r5, #55040
	str r5, [r10, #AK_OPINSTANCE+4*(1+AK_CHORD3)]
	mov r14, r14, asl #24
	add r6, r6, r14, asr #17
	mov r0, r6
	; v1 = clamp(v1)
	cmp r0, r11		; #32767
	movgt r0, r11	; #32767
	cmn r0, r11		; #-32768
	mvnlt r0, r11	; #-32768

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*15]
	cmp r7, r4
	blt Inst16Loop

;----------------------------------------------------------------------------
; Instrument 16 - Loop Generator (Offset: 3894 Length: 2250)
;----------------------------------------------------------------------------

	mov r7, #2250
	ldr r6, [r10, #AK_SMPADDR+4*15]
	add r6, r6, #3894	; src1
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
; Instrument 17 - 'colombia_lead_high'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst17Loop:
	; v1 = osc_tri(0, 2000, 92);
	ldr r6, [r10, #AK_OPINSTANCE+4*0]
	add r6, r6, #2000
	mov r6, r6, asl #16
	mov r6, r6, asr #16	; Sign extend word to long.
	str r6, [r10, #AK_OPINSTANCE+4*0]
	cmp r6, #0
	mvnmi r6, r6
	sub r6, r6, #16384
	mov r0, r6, asl #1
	; v1 = vol(v1, 92)
	mov r14, #92
	mul r0, r14, r0
	mov r0, r0, asr #7

	; v2 = osc_tri(1, 2014, 92);
	ldr r6, [r10, #AK_OPINSTANCE+4*1]
	add r6, r6, #2014
	mov r6, r6, asl #16
	mov r6, r6, asr #16	; Sign extend word to long.
	str r6, [r10, #AK_OPINSTANCE+4*1]
	cmp r6, #0
	mvnmi r6, r6
	sub r6, r6, #16384
	mov r1, r6, asl #1
	; v2 = vol(v2, 92)
	mov r14, #92
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

	; v2 = osc_saw(3, 4000, 72);
	ldr r1, [r10, #AK_OPINSTANCE+4*2]
	add r1, r1, #4000
	mov r1, r1, asl #16
	mov r1, r1, asr #16	; Sign extend word to long.
	str r1, [r10, #AK_OPINSTANCE+4*2]	
	; v2 = vol(v2, 72)
	mov r14, #72
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

	; v2 = envd(5, 8, 0, 128);
	mov r4, #3640
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	movle r6, #0
	mov r1, r6
	; v2 = vol(v2, 128)
	; NOOP -- val<<7>>7

	; v2 = mul(v2, 64);
	mov r1, r1, asr #9	; val<<6>>15

	; v2 = add(v2, 10);
	mov r1, r1, asl #16
	mov r1, r1, asr #16	; Sign extend word to long.
	mov r14, #10
	add r1, r1, r14
	; v2 = clamp(v2)
	cmp r1, r11		; #32767
	movgt r1, r11	; #32767
	cmn r1, r11		; #-32768
	mvnlt r1, r11	; #-32768

	; v1 = sv_flt_n(8, v1, v2, 127, 2);
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
	ldr r4, [r10, #AK_SMPLEN+4*16]
	cmp r7, r4
	blt Inst17Loop

;----------------------------------------------------------------------------
; Instrument 17 - Loop Generator (Offset: 4096 Length: 4096)
;----------------------------------------------------------------------------

	mov r7, #4096
	ldr r6, [r10, #AK_SMPADDR+4*16]
	add r6, r6, #4096	; src1
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
; Instrument 18 - 'colombia_chordstab1'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst18Loop:
	; v1 = clone(smp,14, 0);
	mov r0, r7
	ldr r6, [r10, #AK_SMPADDR+4*14]
	ldr r4, [r10, #AK_SMPLEN+4*14]
	cmp r0, r4
	movge r0, #0
	ldrltb r0, [r6, r0]
	mov r0, r0, asl #24
	mov r0, r0, asr #16

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

	; v2 = envd(2, 8, 0, 128);
	mov r4, #3640
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	movle r6, #0
	mov r1, r6
	; v2 = vol(v2, 128)
	; NOOP -- val<<7>>7

	; v1 = mul(v1, v2);
	mul r0, r1, r0
	mov r0, r0, asr #15

	; v1 = reverb(v1, 100, 16);
	ldr r6, [r10, #AK_OPINSTANCE+4*0]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 100)
	mov r14, #100
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
	; r4 = vol(r4, 100)
	mov r14, #100
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
	; r4 = vol(r4, 100)
	mov r14, #100
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
	; r4 = vol(r4, 100)
	mov r14, #100
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
	; r4 = vol(r4, 100)
	mov r14, #100
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
	; r4 = vol(r4, 100)
	mov r14, #100
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
	; r4 = vol(r4, 100)
	mov r14, #100
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
	; r4 = vol(r4, 100)
	mov r14, #100
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
	ldr r4, [r10, #AK_SMPLEN+4*17]
	cmp r7, r4
	blt Inst18Loop

;----------------------------------------------------------------------------
; Instrument 18 - Loop Generator (Offset: 2048 Length: 2048)
;----------------------------------------------------------------------------

	mov r7, #2048
	ldr r6, [r10, #AK_SMPADDR+4*17]
	add r6, r6, #2048	; src1
	sub r4, r6, r7	; src2
	mov r0, r11, lsl #8	; 32767<<8
	mov r1, r7
	bl divide
	mov r5, r0	; delta = divs.w(32767<<8,repeat_length)
	mov r14, #0	; rampup
	mov r12, r11, lsl #8	; rampdown
LoopGen_17:
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
	bne LoopGen_17

;----------------------------------------------------------------------------
; Instrument 19 - 'colombia_chordstab2'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst19Loop:
	; v1 = clone(smp,15, 0);
	mov r0, r7
	ldr r6, [r10, #AK_SMPADDR+4*15]
	ldr r4, [r10, #AK_SMPLEN+4*15]
	cmp r0, r4
	movge r0, #0
	ldrltb r0, [r6, r0]
	mov r0, r0, asl #24
	mov r0, r0, asr #16

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

	; v2 = envd(2, 8, 0, 128);
	mov r4, #3640
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	movle r6, #0
	mov r1, r6
	; v2 = vol(v2, 128)
	; NOOP -- val<<7>>7

	; v1 = mul(v1, v2);
	mul r0, r1, r0
	mov r0, r0, asr #15

	; v1 = reverb(v1, 100, 16);
	ldr r6, [r10, #AK_OPINSTANCE+4*0]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 100)
	mov r14, #100
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
	; r4 = vol(r4, 100)
	mov r14, #100
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
	; r4 = vol(r4, 100)
	mov r14, #100
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
	; r4 = vol(r4, 100)
	mov r14, #100
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
	; r4 = vol(r4, 100)
	mov r14, #100
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
	; r4 = vol(r4, 100)
	mov r14, #100
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
	; r4 = vol(r4, 100)
	mov r14, #100
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
	; r4 = vol(r4, 100)
	mov r14, #100
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
	ldr r4, [r10, #AK_SMPLEN+4*18]
	cmp r7, r4
	blt Inst19Loop

;----------------------------------------------------------------------------
; Instrument 19 - Loop Generator (Offset: 2048 Length: 2048)
;----------------------------------------------------------------------------

	mov r7, #2048
	ldr r6, [r10, #AK_SMPADDR+4*18]
	add r6, r6, #2048	; src1
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
; Instrument 20 - 'colombia_leadstab'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst20Loop:
	; v1 = clone(smp,16, 0);
	mov r0, r7
	ldr r6, [r10, #AK_SMPADDR+4*16]
	ldr r4, [r10, #AK_SMPLEN+4*16]
	cmp r0, r4
	movge r0, #0
	ldrltb r0, [r6, r0]
	mov r0, r0, asl #24
	mov r0, r0, asr #16

	; v2 = envd(1, 6, 0, 128);
	mov r4, #6553
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	movle r6, #0
	mov r1, r6
	; v2 = vol(v2, 128)
	; NOOP -- val<<7>>7

	; v1 = mul(v1, v2);
	mul r0, r1, r0
	mov r0, r0, asr #15

	; v1 = reverb(v1, 120, 16);
	ldr r6, [r10, #AK_OPINSTANCE+4*0]
	ldr r4, [r9, r6, lsl #2]
	; r4 = vol(r4, 120)
	mov r14, #120
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
	; r4 = vol(r4, 120)
	mov r14, #120
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
	; r4 = vol(r4, 120)
	mov r14, #120
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
	; r4 = vol(r4, 120)
	mov r14, #120
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
	; r4 = vol(r4, 120)
	mov r14, #120
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
	; r4 = vol(r4, 120)
	mov r14, #120
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
	; r4 = vol(r4, 120)
	mov r14, #120
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
	; r4 = vol(r4, 120)
	mov r14, #120
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

	; v2 = mul(v1, 16384);
	mov r1, r0, asr #1	; val<<14>>15

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
	ldr r4, [r10, #AK_SMPLEN+4*19]
	cmp r7, r4
	blt Inst20Loop

;----------------------------------------------------------------------------
; Instrument 20 - Loop Generator (Offset: 2184 Length: 1912)
;----------------------------------------------------------------------------

	mov r7, #1912
	ldr r6, [r10, #AK_SMPADDR+4*19]
	add r6, r6, #2184	; src1
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
; Instrument 21 - 'colombia_pling2'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst21Loop:
	; v1 = clone(smp,9, 1024);
	add r0, r7, #1024
	ldr r6, [r10, #AK_SMPADDR+4*9]
	ldr r4, [r10, #AK_SMPLEN+4*9]
	cmp r0, r4
	movge r0, #0
	ldrltb r0, [r6, r0]
	mov r0, r0, asl #24
	mov r0, r0, asr #16

	; v1 = sv_flt_n(1, v1, 32, 0, 2);
	ldr r4, [r10, #AK_OPINSTANCE+4*(0+AK_LPF)]
	ldr r5, [r10, #AK_OPINSTANCE+4*(0+AK_HPF)]
	ldr r6, [r10, #AK_OPINSTANCE+4*(0+AK_BPF)]
	mov r14, r6, asr #7
	mov r12, #32
	mla r4, r14, r12, r4
	; r4 = clamp(r4)
	cmp r4, r11		; #32767
	movgt r4, r11	; #32767
	cmn r4, r11		; #-32768
	mvnlt r4, r11	; #-32768
	str r4, [r10, #AK_OPINSTANCE+4*(0+AK_LPF)]
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
	str r5, [r10, #AK_OPINSTANCE+4*(0+AK_HPF)]
	mov r14, r5, asr #7
	mov r12, #32
	mla r6, r12, r14, r6
	; r6 = clamp(r6)
	cmp r6, r11		; #32767
	movgt r6, r11	; #32767
	cmn r6, r11		; #-32768
	mvnlt r6, r11	; #-32768
	str r6, [r10, #AK_OPINSTANCE+4*(0+AK_BPF)]
	mov r0, r6

	; v2 = envd(2, 7, 16, 128);
	mov r4, #4681
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	cmp r6, #4096
	movle r6, #4096
	mov r1, r6
	; v2 = vol(v2, 128)
	; NOOP -- val<<7>>7

	; v1 = mul(v1, v2);
	mul r0, r1, r0
	mov r0, r0, asr #15

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*20]
	cmp r7, r4
	blt Inst21Loop

;----------------------------------------------------------------------------
; Instrument 22 - 'colombia_pling3'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst22Loop:
	; v1 = clone(smp,9, 1024);
	add r0, r7, #1024
	ldr r6, [r10, #AK_SMPADDR+4*9]
	ldr r4, [r10, #AK_SMPLEN+4*9]
	cmp r0, r4
	movge r0, #0
	ldrltb r0, [r6, r0]
	mov r0, r0, asl #24
	mov r0, r0, asr #16

	; v1 = sv_flt_n(1, v1, 58, 0, 0);
	ldr r4, [r10, #AK_OPINSTANCE+4*(0+AK_LPF)]
	ldr r5, [r10, #AK_OPINSTANCE+4*(0+AK_HPF)]
	ldr r6, [r10, #AK_OPINSTANCE+4*(0+AK_BPF)]
	mov r14, r6, asr #7
	mov r12, #58
	mla r4, r14, r12, r4
	; r4 = clamp(r4)
	cmp r4, r11		; #32767
	movgt r4, r11	; #32767
	cmn r4, r11		; #-32768
	mvnlt r4, r11	; #-32768
	str r4, [r10, #AK_OPINSTANCE+4*(0+AK_LPF)]
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
	str r5, [r10, #AK_OPINSTANCE+4*(0+AK_HPF)]
	mov r14, r5, asr #7
	mov r12, #58
	mla r6, r12, r14, r6
	; r6 = clamp(r6)
	cmp r6, r11		; #32767
	movgt r6, r11	; #32767
	cmn r6, r11		; #-32768
	mvnlt r6, r11	; #-32768
	str r6, [r10, #AK_OPINSTANCE+4*(0+AK_BPF)]
	mov r0, r4

	; v2 = envd(2, 7, 16, 128);
	mov r4, #4681
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	cmp r6, #4096
	movle r6, #4096
	mov r1, r6
	; v2 = vol(v2, 128)
	; NOOP -- val<<7>>7

	; v1 = mul(v1, v2);
	mul r0, r1, r0
	mov r0, r0, asr #15

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*21]
	cmp r7, r4
	blt Inst22Loop

;----------------------------------------------------------------------------
; Instrument 23 - 'colombia_pling4'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst23Loop:
	; v1 = clone(smp,9, 1024);
	add r0, r7, #1024
	ldr r6, [r10, #AK_SMPADDR+4*9]
	ldr r4, [r10, #AK_SMPLEN+4*9]
	cmp r0, r4
	movge r0, #0
	ldrltb r0, [r6, r0]
	mov r0, r0, asl #24
	mov r0, r0, asr #16

	; v1 = sv_flt_n(1, v1, 10, 1, 0);
	ldr r4, [r10, #AK_OPINSTANCE+4*(0+AK_LPF)]
	ldr r5, [r10, #AK_OPINSTANCE+4*(0+AK_HPF)]
	ldr r6, [r10, #AK_OPINSTANCE+4*(0+AK_BPF)]
	mov r14, r6, asr #7
	mov r12, #10
	mla r4, r14, r12, r4
	; r4 = clamp(r4)
	cmp r4, r11		; #32767
	movgt r4, r11	; #32767
	cmn r4, r11		; #-32768
	mvnlt r4, r11	; #-32768
	str r4, [r10, #AK_OPINSTANCE+4*(0+AK_LPF)]
	mov r12, #1
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
	mov r12, #10
	mla r6, r12, r14, r6
	; r6 = clamp(r6)
	cmp r6, r11		; #32767
	movgt r6, r11	; #32767
	cmn r6, r11		; #-32768
	mvnlt r6, r11	; #-32768
	str r6, [r10, #AK_OPINSTANCE+4*(0+AK_BPF)]
	mov r0, r4

	; v2 = envd(2, 7, 16, 128);
	mov r4, #4681
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	cmp r6, #4096
	movle r6, #4096
	mov r1, r6
	; v2 = vol(v2, 128)
	; NOOP -- val<<7>>7

	; v1 = mul(v1, v2);
	mul r0, r1, r0
	mov r0, r0, asr #15

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*22]
	cmp r7, r4
	blt Inst23Loop

;----------------------------------------------------------------------------
; Instrument 24 - 'colombia_hat_low'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst24Loop:
	; v2 = envd(0, 4, 8, 80);
	mov r4, #10922
	mul r6, r7, r4
	subs r6, r11, r6, asr #8
	cmp r6, #2048
	movle r6, #2048
	mov r1, r6
	; v2 = vol(v2, 80)
	mov r14, #80
	mul r1, r14, r1
	mov r1, r1, asr #7

	; v1 = clone(smp,3, 32);
	add r0, r7, #32
	ldr r6, [r10, #AK_SMPADDR+4*3]
	ldr r4, [r10, #AK_SMPLEN+4*3]
	cmp r0, r4
	movge r0, #0
	ldrltb r0, [r6, r0]
	mov r0, r0, asl #24
	mov r0, r0, asr #16

	; v1 = mul(v1, v2);
	mul r0, r1, r0
	mov r0, r0, asr #15

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*23]
	cmp r7, r4
	blt Inst24Loop

;----------------------------------------------------------------------------
; Instrument 25 - 'colombia_missing_chord'
;----------------------------------------------------------------------------

	; TODO: Delay loop flag.
	bl AK_ResetVars
	mov r7, #0	; Sample byte count
	AK_PROGRESS

Inst25Loop:
	; v1 = osc_saw(0, 2000, 16);
	ldr r0, [r10, #AK_OPINSTANCE+4*0]
	add r0, r0, #2000
	mov r0, r0, asl #16
	mov r0, r0, asr #16	; Sign extend word to long.
	str r0, [r10, #AK_OPINSTANCE+4*0]	
	; v1 = vol(v1, 16)
	mov r0, r0, asr #3	; val<<4>>7

	; v1 = clone_reverse(smp,13, 0);
	mov r0, r7
	ldr r6, [r10, #AK_SMPADDR+4*(13+1)]
	ldr r4, [r10, #AK_SMPLEN+4*13]
	cmp r0, r4
	movge r0, #0
	rsblt r0, r0, #0
	ldrltb r0, [r6, r0]
	mov r0, r0, asl #24
	mov r0, r0, asr #16

	mov r4, r0, asr #8
	strb r4, [r8], #1
	
AK_FINE_PROGRESS

	add r7, r7, #1
	ldr r4, [r10, #AK_SMPLEN+4*24]
	cmp r7, r4
	blt Inst25Loop

;----------------------------------------------------------------------------
; Instrument 25 - Loop Generator (Offset: 5119 Length: 5121)
;----------------------------------------------------------------------------

	mov r7, #5121
	ldr r6, [r10, #AK_SMPADDR+4*24]
	add r6, r6, #5119	; src1
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
	.rept 9
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
	.long 0x00000880	; Instrument 1 Length
	.long 0x00002000	; Instrument 2 Length
	.long 0x00002000	; Instrument 3 Length
	.long 0x00001000	; Instrument 4 Length
	.long 0x00000900	; Instrument 5 Length
	.long 0x00000900	; Instrument 6 Length
	.long 0x00000b00	; Instrument 7 Length
	.long 0x00000880	; Instrument 8 Length
	.long 0x00000900	; Instrument 9 Length
	.long 0x00004000	; Instrument 10 Length
	.long 0x00002000	; Instrument 11 Length
	.long 0x00008000	; Instrument 12 Length
	.long 0x00000b00	; Instrument 13 Length
	.long 0x00002000	; Instrument 14 Length
	.long 0x00001800	; Instrument 15 Length
	.long 0x00001800	; Instrument 16 Length
	.long 0x00002000	; Instrument 17 Length
	.long 0x00001000	; Instrument 18 Length
	.long 0x00001000	; Instrument 19 Length
	.long 0x00001000	; Instrument 20 Length
	.long 0x00000b00	; Instrument 21 Length
	.long 0x00000b00	; Instrument 22 Length
	.long 0x00000b00	; Instrument 23 Length
	.long 0x000002a0	; Instrument 24 Length
	.long 0x00002800	; Instrument 25 Length
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
	.skip 9*4
AK_EnvDValue:
	; NB. Must follow AK_OpInstance!
	.skip 0*4

; ============================================================================
