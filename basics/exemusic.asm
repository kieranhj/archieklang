;----------------------------------------------------------------------------
;
; Generated with Aklang2Asm V1.1, by Dan/Lemon. 2021-2022.
;
; Based on Alcatraz Amigaklang rendering core. (c) Jochen 'Virgill' Feldkötter 2020.
;
; What's new in V1.1?
; - Instance offsets fixed in ADSR operator
; - Incorrect shift direction fixed in OnePoleFilter operator
; - Loop Generator now correctly interleaved with instrument generation
; - Fine progress includes loop generation, and new AK_FINE_PROGRESS_LEN added
; - Reverb large buffer instance offsets were wrong, causing potential buffer overrun
;
; Call 'AK_Generate' with the following registers set:
; a0 = Sample Buffer Start Address
; a1 = 32768 Bytes Temporary Work Buffer Address (can be freed after sample rendering complete)
; a2 = External Samples Address (need not be in chip memory, and can be freed after sample rendering complete)
; a3 = Rendering Progress Address (2 modes available... see below)
;
; AK_FINE_PROGRESS equ 0 = rendering progress as a byte (current instrument number)
; AK_FINE_PROGRESS equ 1 = rendering progress as a long (current sample byte)
;
;----------------------------------------------------------------------------

AK_USE_PROGRESS			equ 0
AK_FINE_PROGRESS		equ 0
AK_FINE_PROGRESS_LEN	equ 173871
AK_SMP_LEN				equ 171822
AK_EXT_SMP_LEN			equ 0

AK_Generate:

				lea		AK_Vars(pc),a5

				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						move.b	#-1,(a3)
					else
						move.l	#0,(a3)
					endif
				endif

				; Create sample & external sample base addresses
				lea		AK_SmpLen(a5),a6
				lea		AK_SmpAddr(a5),a4
				move.l	a0,d0
				moveq	#31-1,d7
.SmpAdrLoop		move.l	d0,(a4)+
				add.l	(a6)+,d0
				dbra	d7,.SmpAdrLoop
				move.l	a2,d0
				moveq	#8-1,d7
.ExtSmpAdrLoop	move.l	d0,(a4)+
				add.l	(a6)+,d0
				dbra	d7,.ExtSmpAdrLoop

;----------------------------------------------------------------------------
; Instrument 1 - adding_oscillators
;----------------------------------------------------------------------------

				moveq	#8,d0
				bsr		AK_ResetVars
				moveq	#0,d7
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					endif
				endif
.Inst1Loop
				; v1 = osc_saw(0, 500, 77)
				add.w	#500,AK_OpInstance+0(a5)
				move.w	AK_OpInstance+0(a5),d0
				muls	#77,d0
				asr.l	#7,d0

				; v2 = osc_saw(1, 515, 79)
				add.w	#515,AK_OpInstance+2(a5)
				move.w	AK_OpInstance+2(a5),d1
				muls	#79,d1
				asr.l	#7,d1

				; v1 = add(v1, v2)
				add.w	d1,d0
				bvc.s	.AddNoClamp_1_3
				spl		d0
				ext.w	d0
				eor.w	#$7fff,d0
.AddNoClamp_1_3

				asr.w	#8,d0
				move.b	d0,(a0)+
				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif
				addq.l	#1,d7
				cmp.l	AK_SmpLen+0(a5),d7
				blt		.Inst1Loop

;----------------------------------------------------------------------------
; Instrument 2 - adding_more_oscillators
;----------------------------------------------------------------------------

				moveq	#0,d0
				bsr		AK_ResetVars
				moveq	#0,d7
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					endif
				endif
.Inst2Loop
				; v1 = osc_saw(0, 500, 77)
				add.w	#500,AK_OpInstance+0(a5)
				move.w	AK_OpInstance+0(a5),d0
				muls	#77,d0
				asr.l	#7,d0

				; v2 = osc_saw(1, 515, 79)
				add.w	#515,AK_OpInstance+2(a5)
				move.w	AK_OpInstance+2(a5),d1
				muls	#79,d1
				asr.l	#7,d1

				; v1 = add(v1, v2)
				add.w	d1,d0
				bvc.s	.AddNoClamp_2_3
				spl		d0
				ext.w	d0
				eor.w	#$7fff,d0
.AddNoClamp_2_3

				; v2 = osc_saw(3, 1010, 79)
				add.w	#1010,AK_OpInstance+4(a5)
				move.w	AK_OpInstance+4(a5),d1
				muls	#79,d1
				asr.l	#7,d1

				; v1 = add(v1, v2)
				add.w	d1,d0
				bvc.s	.AddNoClamp_2_5
				spl		d0
				ext.w	d0
				eor.w	#$7fff,d0
.AddNoClamp_2_5

				; v2 = osc_saw(5, 750, 57)
				add.w	#750,AK_OpInstance+6(a5)
				move.w	AK_OpInstance+6(a5),d1
				muls	#57,d1
				asr.l	#7,d1

				; v1 = add(v1, v2)
				add.w	d1,d0
				bvc.s	.AddNoClamp_2_7
				spl		d0
				ext.w	d0
				eor.w	#$7fff,d0
.AddNoClamp_2_7

				asr.w	#8,d0
				move.b	d0,(a0)+
				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif
				addq.l	#1,d7
				cmp.l	AK_SmpLen+4(a5),d7
				blt		.Inst2Loop

;----------------------------------------------------------------------------
; Instrument 3 - multiplying_oscillators
;----------------------------------------------------------------------------

				moveq	#0,d0
				bsr		AK_ResetVars
				moveq	#0,d7
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					endif
				endif
.Inst3Loop
				; v1 = osc_tri(0, 500, 127)
				add.w	#500,AK_OpInstance+0(a5)
				move.w	AK_OpInstance+0(a5),d0
				bge.s	.TriNoInvert_3_1
				not.w	d0
.TriNoInvert_3_1
				sub.w	#16384,d0
				add.w	d0,d0
				muls	#127,d0
				asr.l	#7,d0

				; v2 = osc_tri(1, 598, 127)
				add.w	#598,AK_OpInstance+2(a5)
				move.w	AK_OpInstance+2(a5),d1
				bge.s	.TriNoInvert_3_2
				not.w	d1
.TriNoInvert_3_2
				sub.w	#16384,d1
				add.w	d1,d1
				muls	#127,d1
				asr.l	#7,d1

				; v1 = mul(v1, v2)
				muls	d1,d0
				add.l	d0,d0
				swap	d0

				asr.w	#8,d0
				move.b	d0,(a0)+
				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif
				addq.l	#1,d7
				cmp.l	AK_SmpLen+8(a5),d7
				blt		.Inst3Loop

;----------------------------------------------------------------------------
; Instrument 4 - multiply_with_envelope
;----------------------------------------------------------------------------

				moveq	#0,d0
				bsr		AK_ResetVars
				moveq	#0,d7
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					endif
				endif
.Inst4Loop
				; v1 = osc_sine(0, 500, 127)
				add.w	#500,AK_OpInstance+0(a5)
				move.w	AK_OpInstance+0(a5),d0
				sub.w	#16384,d0
				move.w	d0,d5
				bge.s	.SineNoAbs_4_1
				neg.w	d5
.SineNoAbs_4_1
				move.w	#32767,d6
				sub.w	d5,d6
				muls	d6,d0
				swap	d0
				asl.w	#3,d0
				muls	#127,d0
				asr.l	#7,d0

				; v2 = envd(1, 11, 0, 127)
				move.l	AK_EnvDValue+0(a5),d5
				move.l	d5,d1
				swap	d1
				sub.l	#524288,d5
				bgt.s   .EnvDNoSustain_4_2
				moveq	#0,d5
.EnvDNoSustain_4_2
				move.l	d5,AK_EnvDValue+0(a5)
				muls	#127,d1
				asr.l	#7,d1

				; v1 = mul(v1, v2)
				muls	d1,d0
				add.l	d0,d0
				swap	d0

				asr.w	#8,d0
				move.b	d0,(a0)+
				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif
				addq.l	#1,d7
				cmp.l	AK_SmpLen+12(a5),d7
				blt		.Inst4Loop

;----------------------------------------------------------------------------
; Instrument 5 - envelope_modulates_pitch
;----------------------------------------------------------------------------

				moveq	#0,d0
				bsr		AK_ResetVars
				moveq	#0,d7
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					endif
				endif
.Inst5Loop
				; v2 = enva(0, 20, 0, 127)
				move.l	AK_OpInstance+0(a5),d5
				move.l	d5,d1
				swap	d1
				add.l	#164352,d5
				bvc.s   .EnvANoMax_5_1
				move.l	#32767<<16,d5
.EnvANoMax_5_1
				move.l	d5,AK_OpInstance+0(a5)
				muls	#127,d1
				asr.l	#7,d1

				; v2 = mul(v2, 698)
				muls	#698,d1
				add.l	d1,d1
				swap	d1

				; v2 = add(v2, 442)
				add.w	#442,d1
				bvc.s	.AddNoClamp_5_3
				spl		d1
				ext.w	d1
				eor.w	#$7fff,d1
.AddNoClamp_5_3

				; v1 = osc_tri(3, v2, 127)
				add.w	d1,AK_OpInstance+4(a5)
				move.w	AK_OpInstance+4(a5),d0
				bge.s	.TriNoInvert_5_4
				not.w	d0
.TriNoInvert_5_4
				sub.w	#16384,d0
				add.w	d0,d0
				muls	#127,d0
				asr.l	#7,d0

				asr.w	#8,d0
				move.b	d0,(a0)+
				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif
				addq.l	#1,d7
				cmp.l	AK_SmpLen+16(a5),d7
				blt		.Inst5Loop

;----------------------------------------------------------------------------
; Instrument 6 - frequency_modulation
;----------------------------------------------------------------------------

				moveq	#0,d0
				bsr		AK_ResetVars
				moveq	#0,d7
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					endif
				endif
.Inst6Loop
				; v2 = enva(0, 20, 0, 127)
				move.l	AK_OpInstance+0(a5),d5
				move.l	d5,d1
				swap	d1
				add.l	#164352,d5
				bvc.s   .EnvANoMax_6_1
				move.l	#32767<<16,d5
.EnvANoMax_6_1
				move.l	d5,AK_OpInstance+0(a5)
				muls	#127,d1
				asr.l	#7,d1

				; v2 = mul(v2, 698)
				muls	#698,d1
				add.l	d1,d1
				swap	d1

				; v2 = add(v2, 442)
				add.w	#442,d1
				bvc.s	.AddNoClamp_6_3
				spl		d1
				ext.w	d1
				eor.w	#$7fff,d1
.AddNoClamp_6_3

				; v1 = osc_tri(3, v2, 127)
				add.w	d1,AK_OpInstance+4(a5)
				move.w	AK_OpInstance+4(a5),d0
				bge.s	.TriNoInvert_6_4
				not.w	d0
.TriNoInvert_6_4
				sub.w	#16384,d0
				add.w	d0,d0
				muls	#127,d0
				asr.l	#7,d0

				; v2 = osc_tri(4, 550, 127)
				add.w	#550,AK_OpInstance+6(a5)
				move.w	AK_OpInstance+6(a5),d1
				bge.s	.TriNoInvert_6_5
				not.w	d1
.TriNoInvert_6_5
				sub.w	#16384,d1
				add.w	d1,d1
				muls	#127,d1
				asr.l	#7,d1

				; v1 = mul(v1, v2)
				muls	d1,d0
				add.l	d0,d0
				swap	d0

				asr.w	#8,d0
				move.b	d0,(a0)+
				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif
				addq.l	#1,d7
				cmp.l	AK_SmpLen+20(a5),d7
				blt		.Inst6Loop

;----------------------------------------------------------------------------
; Instrument 7 - noise_in_lowpass_filter
;----------------------------------------------------------------------------

				moveq	#0,d0
				bsr		AK_ResetVars
				moveq	#0,d7
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					endif
				endif
.Inst7Loop
				; v1 = osc_noise(127)
				move.l	AK_NoiseSeeds+0(a5),d4
				move.l	AK_NoiseSeeds+4(a5),d5
				eor.l	d5,d4
				move.l	d4,AK_NoiseSeeds+0(a5)
				add.l	d5,AK_NoiseSeeds+8(a5)
				add.l	d4,AK_NoiseSeeds+4(a5)
				move.w	AK_NoiseSeeds+10(a5),d0
				muls	#127,d0
				asr.l	#7,d0

				; v1 = sv_flt_n(1, v1, 18, 0, 0)
				move.w	AK_OpInstance+AK_BPF+0(a5),d5
				asr.w	#7,d5
				move.w	d5,d6
				muls	#18,d5
				move.w	AK_OpInstance+AK_LPF+0(a5),d4
				add.w	d5,d4
				bvc.s	.NoClampLPF_7_2
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.NoClampLPF_7_2
				move.w	d4,AK_OpInstance+AK_LPF+0(a5)
				muls	#0,d6
				move.w	d0,d5
				ext.l	d5
				ext.l	d4
				sub.l	d4,d5
				sub.l	d6,d5
				cmp.l	#32767,d5
				ble.s	.NoClampMaxHPF_7_2
				move.w	#32767,d5
				bra.s	.NoClampMinHPF_7_2
.NoClampMaxHPF_7_2
				cmp.l	#-32768,d5
				bge.s	.NoClampMinHPF_7_2
				move.w	#-32768,d5
.NoClampMinHPF_7_2
				move.w	d5,AK_OpInstance+AK_HPF+0(a5)
				asr.w	#7,d5
				muls	#18,d5
				add.w	AK_OpInstance+AK_BPF+0(a5),d5
				bvc.s	.NoClampBPF_7_2
				spl		d5
				ext.w	d5
				eor.w	#$7fff,d5
.NoClampBPF_7_2
				move.w	d5,AK_OpInstance+AK_BPF+0(a5)
				move.w	AK_OpInstance+AK_LPF+0(a5),d0

				asr.w	#8,d0
				move.b	d0,(a0)+
				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif
				addq.l	#1,d7
				cmp.l	AK_SmpLen+24(a5),d7
				blt		.Inst7Loop

;----------------------------------------------------------------------------
; Instrument 8 - lfo_filter_modulation
;----------------------------------------------------------------------------

				moveq	#0,d0
				bsr		AK_ResetVars
				moveq	#0,d7
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					endif
				endif
.Inst8Loop
				; v2 = osc_sine(0, 21, 127)
				add.w	#21,AK_OpInstance+0(a5)
				move.w	AK_OpInstance+0(a5),d1
				sub.w	#16384,d1
				move.w	d1,d5
				bge.s	.SineNoAbs_8_1
				neg.w	d5
.SineNoAbs_8_1
				move.w	#32767,d6
				sub.w	d5,d6
				muls	d6,d1
				swap	d1
				asl.w	#3,d1
				muls	#127,d1
				asr.l	#7,d1

				; v2 = ctrl(v2)
				moveq	#9,d4
				asr.w	d4,d1
				add.w	#64,d1

				; v1 = osc_saw(2, 500, 127)
				add.w	#500,AK_OpInstance+2(a5)
				move.w	AK_OpInstance+2(a5),d0
				muls	#127,d0
				asr.l	#7,d0

				; v1 = sv_flt_n(3, v1, v2, 35, 0)
				move.w	AK_OpInstance+AK_BPF+4(a5),d5
				asr.w	#7,d5
				move.w	d5,d6
				muls	d1,d5
				move.w	AK_OpInstance+AK_LPF+4(a5),d4
				add.w	d5,d4
				bvc.s	.NoClampLPF_8_4
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.NoClampLPF_8_4
				move.w	d4,AK_OpInstance+AK_LPF+4(a5)
				muls	#35,d6
				move.w	d0,d5
				ext.l	d5
				ext.l	d4
				sub.l	d4,d5
				sub.l	d6,d5
				cmp.l	#32767,d5
				ble.s	.NoClampMaxHPF_8_4
				move.w	#32767,d5
				bra.s	.NoClampMinHPF_8_4
.NoClampMaxHPF_8_4
				cmp.l	#-32768,d5
				bge.s	.NoClampMinHPF_8_4
				move.w	#-32768,d5
.NoClampMinHPF_8_4
				move.w	d5,AK_OpInstance+AK_HPF+4(a5)
				asr.w	#7,d5
				muls	d1,d5
				add.w	AK_OpInstance+AK_BPF+4(a5),d5
				bvc.s	.NoClampBPF_8_4
				spl		d5
				ext.w	d5
				eor.w	#$7fff,d5
.NoClampBPF_8_4
				move.w	d5,AK_OpInstance+AK_BPF+4(a5)
				move.w	AK_OpInstance+AK_LPF+4(a5),d0

				asr.w	#8,d0
				move.b	d0,(a0)+
				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif
				addq.l	#1,d7
				cmp.l	AK_SmpLen+28(a5),d7
				blt		.Inst8Loop

;----------------------------------------------------------------------------
; Instrument 9 - lfo_filter_modulation_hpf
;----------------------------------------------------------------------------

				moveq	#0,d0
				bsr		AK_ResetVars
				moveq	#0,d7
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					endif
				endif
.Inst9Loop
				; v2 = osc_sine(0, 9, 127)
				add.w	#9,AK_OpInstance+0(a5)
				move.w	AK_OpInstance+0(a5),d1
				sub.w	#16384,d1
				move.w	d1,d5
				bge.s	.SineNoAbs_9_1
				neg.w	d5
.SineNoAbs_9_1
				move.w	#32767,d6
				sub.w	d5,d6
				muls	d6,d1
				swap	d1
				asl.w	#3,d1
				muls	#127,d1
				asr.l	#7,d1

				; v2 = ctrl(v2)
				moveq	#9,d4
				asr.w	d4,d1
				add.w	#64,d1

				; v1 = osc_saw(2, 500, 72)
				add.w	#500,AK_OpInstance+2(a5)
				move.w	AK_OpInstance+2(a5),d0
				muls	#72,d0
				asr.l	#7,d0

				; v3 = osc_saw(3, 509, 72)
				add.w	#509,AK_OpInstance+4(a5)
				move.w	AK_OpInstance+4(a5),d2
				muls	#72,d2
				asr.l	#7,d2

				; v1 = add(v1, v3)
				add.w	d2,d0
				bvc.s	.AddNoClamp_9_5
				spl		d0
				ext.w	d0
				eor.w	#$7fff,d0
.AddNoClamp_9_5

				; v1 = sv_flt_n(5, v1, v2, 11, 1)
				move.w	AK_OpInstance+AK_BPF+6(a5),d5
				asr.w	#7,d5
				move.w	d5,d6
				muls	d1,d5
				move.w	AK_OpInstance+AK_LPF+6(a5),d4
				add.w	d5,d4
				bvc.s	.NoClampLPF_9_6
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.NoClampLPF_9_6
				move.w	d4,AK_OpInstance+AK_LPF+6(a5)
				muls	#11,d6
				move.w	d0,d5
				ext.l	d5
				ext.l	d4
				sub.l	d4,d5
				sub.l	d6,d5
				cmp.l	#32767,d5
				ble.s	.NoClampMaxHPF_9_6
				move.w	#32767,d5
				bra.s	.NoClampMinHPF_9_6
.NoClampMaxHPF_9_6
				cmp.l	#-32768,d5
				bge.s	.NoClampMinHPF_9_6
				move.w	#-32768,d5
.NoClampMinHPF_9_6
				move.w	d5,AK_OpInstance+AK_HPF+6(a5)
				asr.w	#7,d5
				muls	d1,d5
				add.w	AK_OpInstance+AK_BPF+6(a5),d5
				bvc.s	.NoClampBPF_9_6
				spl		d5
				ext.w	d5
				eor.w	#$7fff,d5
.NoClampBPF_9_6
				move.w	d5,AK_OpInstance+AK_BPF+6(a5)
				move.w	AK_OpInstance+AK_HPF+6(a5),d0

				asr.w	#8,d0
				move.b	d0,(a0)+
				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif
				addq.l	#1,d7
				cmp.l	AK_SmpLen+32(a5),d7
				blt		.Inst9Loop

;----------------------------------------------------------------------------
; Instrument 10 - reverb
;----------------------------------------------------------------------------

				moveq	#0,d0
				bsr		AK_ResetVars
				moveq	#0,d7
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					endif
				endif
.Inst10Loop
				; v1 = osc_saw(0, 500, 98)
				add.w	#500,AK_OpInstance+0(a5)
				move.w	AK_OpInstance+0(a5),d0
				muls	#98,d0
				asr.l	#7,d0

				; v2 = envd(1, 9, 0, 127)
				move.l	AK_EnvDValue+0(a5),d5
				move.l	d5,d1
				swap	d1
				sub.l	#762368,d5
				bgt.s   .EnvDNoSustain_10_2
				moveq	#0,d5
.EnvDNoSustain_10_2
				move.l	d5,AK_EnvDValue+0(a5)
				muls	#127,d1
				asr.l	#7,d1

				; v1 = mul(v1, v2)
				muls	d1,d0
				add.l	d0,d0
				swap	d0

				; v2 = reverb(v1, 117, 20)
				move.l	d7,-(sp)
				sub.l	a6,a6
				move.l	a1,a4
				move.w	AK_OpInstance+2(a5),d5
				move.w	(a4,d5.w),d4
				muls	#117,d4
				asr.l	#7,d4
				add.w	d0,d4
				bvc.s	.ReverbAddNoClamp_10_4_0
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_10_4_0
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#557<<1,d5
				ble.s	.NoReverbReset_10_4_0
				moveq	#0,d5
.NoReverbReset_10_4_0
				move.w  d5,AK_OpInstance+2(a5)
				move.w	d4,d7
				muls	#20,d7
				asr.l	#7,d7
				add.w	d7,a6
				lea		4096(a1),a4
				move.w	AK_OpInstance+4(a5),d5
				move.w	(a4,d5.w),d4
				muls	#117,d4
				asr.l	#7,d4
				add.w	d0,d4
				bvc.s	.ReverbAddNoClamp_10_4_1
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_10_4_1
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#593<<1,d5
				ble.s	.NoReverbReset_10_4_1
				moveq	#0,d5
.NoReverbReset_10_4_1
				move.w  d5,AK_OpInstance+4(a5)
				move.w	d4,d7
				muls	#20,d7
				asr.l	#7,d7
				add.w	d7,a6
				lea		8192(a1),a4
				move.w	AK_OpInstance+6(a5),d5
				move.w	(a4,d5.w),d4
				muls	#117,d4
				asr.l	#7,d4
				add.w	d0,d4
				bvc.s	.ReverbAddNoClamp_10_4_2
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_10_4_2
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#641<<1,d5
				ble.s	.NoReverbReset_10_4_2
				moveq	#0,d5
.NoReverbReset_10_4_2
				move.w  d5,AK_OpInstance+6(a5)
				move.w	d4,d7
				muls	#20,d7
				asr.l	#7,d7
				add.w	d7,a6
				lea		12288(a1),a4
				move.w	AK_OpInstance+8(a5),d5
				move.w	(a4,d5.w),d4
				muls	#117,d4
				asr.l	#7,d4
				add.w	d0,d4
				bvc.s	.ReverbAddNoClamp_10_4_3
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_10_4_3
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#677<<1,d5
				ble.s	.NoReverbReset_10_4_3
				moveq	#0,d5
.NoReverbReset_10_4_3
				move.w  d5,AK_OpInstance+8(a5)
				move.w	d4,d7
				muls	#20,d7
				asr.l	#7,d7
				add.w	d7,a6
				lea		16384(a1),a4
				move.w	AK_OpInstance+10(a5),d5
				move.w	(a4,d5.w),d4
				muls	#117,d4
				asr.l	#7,d4
				add.w	d0,d4
				bvc.s	.ReverbAddNoClamp_10_4_4
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_10_4_4
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#709<<1,d5
				ble.s	.NoReverbReset_10_4_4
				moveq	#0,d5
.NoReverbReset_10_4_4
				move.w  d5,AK_OpInstance+10(a5)
				move.w	d4,d7
				muls	#20,d7
				asr.l	#7,d7
				add.w	d7,a6
				lea		20480(a1),a4
				move.w	AK_OpInstance+12(a5),d5
				move.w	(a4,d5.w),d4
				muls	#117,d4
				asr.l	#7,d4
				add.w	d0,d4
				bvc.s	.ReverbAddNoClamp_10_4_5
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_10_4_5
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#743<<1,d5
				ble.s	.NoReverbReset_10_4_5
				moveq	#0,d5
.NoReverbReset_10_4_5
				move.w  d5,AK_OpInstance+12(a5)
				move.w	d4,d7
				muls	#20,d7
				asr.l	#7,d7
				add.w	d7,a6
				lea		24576(a1),a4
				move.w	AK_OpInstance+14(a5),d5
				move.w	(a4,d5.w),d4
				muls	#117,d4
				asr.l	#7,d4
				add.w	d0,d4
				bvc.s	.ReverbAddNoClamp_10_4_6
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_10_4_6
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#787<<1,d5
				ble.s	.NoReverbReset_10_4_6
				moveq	#0,d5
.NoReverbReset_10_4_6
				move.w  d5,AK_OpInstance+14(a5)
				move.w	d4,d7
				muls	#20,d7
				asr.l	#7,d7
				add.w	d7,a6
				lea		28672(a1),a4
				move.w	AK_OpInstance+16(a5),d5
				move.w	(a4,d5.w),d4
				muls	#117,d4
				asr.l	#7,d4
				add.w	d0,d4
				bvc.s	.ReverbAddNoClamp_10_4_7
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.ReverbAddNoClamp_10_4_7
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#809<<1,d5
				ble.s	.NoReverbReset_10_4_7
				moveq	#0,d5
.NoReverbReset_10_4_7
				move.w  d5,AK_OpInstance+16(a5)
				move.w	d4,d7
				muls	#20,d7
				asr.l	#7,d7
				add.w	d7,a6
				move.l	a6,d7
				cmp.l	#32767,d7
				ble.s	.NoReverbMax_10_4
				move.w	#32767,d7
				bra.s	.NoReverbMin_10_4
.NoReverbMax_10_4
				cmp.l	#-32768,d7
				bge.s	.NoReverbMin_10_4
				move.w	#-32768,d7
.NoReverbMin_10_4
				move.w	d7,d1
				move.l	(sp)+,d7

				; v1 = add(v1, v2)
				add.w	d1,d0
				bvc.s	.AddNoClamp_10_5
				spl		d0
				ext.w	d0
				eor.w	#$7fff,d0
.AddNoClamp_10_5

				asr.w	#8,d0
				move.b	d0,(a0)+
				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif
				addq.l	#1,d7
				cmp.l	AK_SmpLen+36(a5),d7
				blt		.Inst10Loop

;----------------------------------------------------------------------------
; Instrument 11 - clone_sample_backward
;----------------------------------------------------------------------------

				moveq	#8,d0
				bsr		AK_ResetVars
				moveq	#0,d7
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					endif
				endif
.Inst11Loop
				; v1 = clone_reverse(smp,3, 0)
				move.l	d7,d6
				moveq	#0,d0
				cmp.l	AK_SmpLen+12(a5),d6
				bge.s	.NoClone_11_1
				move.l	AK_SmpAddr+12+4(a5),a4
				neg.l	d6
				move.b	-1(a4,d6.l),d0
				asl.w	#8,d0
.NoClone_11_1

				asr.w	#8,d0
				move.b	d0,(a0)+
				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif
				addq.l	#1,d7
				cmp.l	AK_SmpLen+40(a5),d7
				blt		.Inst11Loop

;----------------------------------------------------------------------------
; Instrument 12 - chord_generator
;----------------------------------------------------------------------------

				moveq	#0,d0
				bsr		AK_ResetVars
				moveq	#0,d7
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					endif
				endif
.Inst12Loop
				; v1 = chordgen(0, 0, 10, 7, 12, 61)
				move.l	AK_SmpAddr+0(a5),a4
				move.b	(a4,d7.l),d6
				ext.w	d6
				add.w	#61,a4
				moveq	#0,d4
				move.w	AK_OpInstance+AK_CHORD1+0(a5),d4
				add.l	#116736,AK_OpInstance+AK_CHORD1+0(a5)
				move.b	(a4,d4.l),d5
				ext.w	d5
				add.w	d5,d6
				move.w	AK_OpInstance+AK_CHORD2+0(a5),d4
				add.l	#98048,AK_OpInstance+AK_CHORD2+0(a5)
				move.b	(a4,d4.l),d5
				ext.w	d5
				add.w	d5,d6
				move.w	AK_OpInstance+AK_CHORD3+0(a5),d4
				add.l	#131072,AK_OpInstance+AK_CHORD3+0(a5)
				move.b	(a4,d4.l),d5
				ext.w	d5
				add.w	d5,d6
				move.w	#255,d5
				cmp.w	d5,d6
				blt.s	.NoClampMaxChord_12_1
				move.w	d5,d6
				bra.s	.NoClampMinChord_12_1
.NoClampMaxChord_12_1
				not.w	d5
				cmp.w	d5,d6
				bge.s	.NoClampMinChord_12_1
				move.w	d5,d6
.NoClampMinChord_12_1
				asl.w	#7,d6
				move.w	d6,d0

				; v2 = envd(1, 15, 0, 127)
				move.l	AK_EnvDValue+0(a5),d5
				move.l	d5,d1
				swap	d1
				sub.l	#289024,d5
				bgt.s   .EnvDNoSustain_12_2
				moveq	#0,d5
.EnvDNoSustain_12_2
				move.l	d5,AK_EnvDValue+0(a5)
				muls	#127,d1
				asr.l	#7,d1

				; v1 = mul(v1, v2)
				muls	d1,d0
				add.l	d0,d0
				swap	d0

				asr.w	#8,d0
				move.b	d0,(a0)+
				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif
				addq.l	#1,d7
				cmp.l	AK_SmpLen+44(a5),d7
				blt		.Inst12Loop

;----------------------------------------------------------------------------
; Instrument 13 - perfect_loop_generator
;----------------------------------------------------------------------------

				moveq	#0,d0
				bsr		AK_ResetVars
				moveq	#0,d7
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					endif
				endif
.Inst13Loop
				; v1 = clone(smp,3, 0)
				moveq	#0,d0
				cmp.l	AK_SmpLen+12(a5),d7
				bge.s	.NoClone_13_1
				move.l	AK_SmpAddr+12(a5),a4
				move.b	(a4,d7.l),d0
				asl.w	#8,d0
.NoClone_13_1

				asr.w	#8,d0
				move.b	d0,(a0)+
				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif
				addq.l	#1,d7
				cmp.l	AK_SmpLen+48(a5),d7
				blt		.Inst13Loop

				movem.l a0-a1,-(sp)	;Stash sample base address & large buffer address for loop generator

;----------------------------------------------------------------------------
; Instrument 13 - Loop Generator (Offset: 2047 Length: 2049
;----------------------------------------------------------------------------

				move.l	#2049,d7
				move.l	AK_SmpAddr+48(a5),a0
				lea		2047(a0),a0
				move.l	a0,a1
				sub.l	d7,a1
				moveq	#0,d4
				move.l	#32767<<8,d5
				move.l	d5,d0
				divs	d7,d0
				bvc.s	.LoopGenVC_12
				moveq	#0,d0
.LoopGenVC_12
				moveq	#0,d6
				move.w	d0,d6
.LoopGen_12
				move.l	d4,d2
				asr.l	#8,d2
				move.l	d5,d3
				asr.l	#8,d3
				move.b	(a0),d0
				move.b	(a1)+,d1
				ext.w	d0
				ext.w	d1
				muls	d3,d0
				muls	d2,d1
				add.l	d1,d0
				add.l	d0,d0
				swap	d0
				move.b	d0,(a0)+
				add.l	d6,d4
				sub.l	d6,d5

				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif

				subq.l	#1,d7
				bne.s	.LoopGen_12

				movem.l (sp)+,a0-a1	;Restore sample base address & large buffer address after loop generator

;----------------------------------------------------------------------------
; Instrument 14 - clone_inst1
;----------------------------------------------------------------------------

				moveq	#0,d0
				bsr		AK_ResetVars
				moveq	#0,d7
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					endif
				endif
.Inst14Loop
				; v1 = clone(smp,0, 0)
				moveq	#0,d0
				cmp.l	AK_SmpLen+0(a5),d7
				bge.s	.NoClone_14_1
				move.l	AK_SmpAddr+0(a5),a4
				move.b	(a4,d7.l),d0
				asl.w	#8,d0
.NoClone_14_1

				asr.w	#8,d0
				move.b	d0,(a0)+
				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif
				addq.l	#1,d7
				cmp.l	AK_SmpLen+52(a5),d7
				blt		.Inst14Loop

;----------------------------------------------------------------------------
; Instrument 15 - test_osc_tri
;----------------------------------------------------------------------------

				moveq	#0,d0
				bsr		AK_ResetVars
				moveq	#0,d7
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					endif
				endif
.Inst15Loop
				; v1 = osc_tri(0, 300, 127)
				add.w	#300,AK_OpInstance+0(a5)
				move.w	AK_OpInstance+0(a5),d0
				bge.s	.TriNoInvert_15_1
				not.w	d0
.TriNoInvert_15_1
				sub.w	#16384,d0
				add.w	d0,d0
				muls	#127,d0
				asr.l	#7,d0

				asr.w	#8,d0
				move.b	d0,(a0)+
				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif
				addq.l	#1,d7
				cmp.l	AK_SmpLen+56(a5),d7
				blt		.Inst15Loop

;----------------------------------------------------------------------------
; Instrument 16 - test_osc_sine
;----------------------------------------------------------------------------

				moveq	#0,d0
				bsr		AK_ResetVars
				moveq	#0,d7
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					endif
				endif
.Inst16Loop
				; v1 = osc_sine(0, 200, 64)
				add.w	#200,AK_OpInstance+0(a5)
				move.w	AK_OpInstance+0(a5),d0
				sub.w	#16384,d0
				move.w	d0,d5
				bge.s	.SineNoAbs_16_1
				neg.w	d5
.SineNoAbs_16_1
				move.w	#32767,d6
				sub.w	d5,d6
				muls	d6,d0
				swap	d0
				asl.w	#3,d0
				asr.w	#1,d0

				asr.w	#8,d0
				move.b	d0,(a0)+
				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif
				addq.l	#1,d7
				cmp.l	AK_SmpLen+60(a5),d7
				blt		.Inst16Loop

;----------------------------------------------------------------------------
; Instrument 17 - test_osc_pulse
;----------------------------------------------------------------------------

				moveq	#0,d0
				bsr		AK_ResetVars
				moveq	#0,d7
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					endif
				endif
.Inst17Loop
				; v1 = osc_pulse(0, 200, 96, 40)
				add.w	#200,AK_OpInstance+0(a5)
				cmp.w	#((40-63)<<9),AK_OpInstance+0(a5)
				slt		d0
				ext.w	d0
				eor.w	#$7fff,d0
				muls	#96,d0
				asr.l	#7,d0

				asr.w	#8,d0
				move.b	d0,(a0)+
				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif
				addq.l	#1,d7
				cmp.l	AK_SmpLen+64(a5),d7
				blt		.Inst17Loop

;----------------------------------------------------------------------------
; Instrument 18 - test_osc_noise
;----------------------------------------------------------------------------

				moveq	#0,d0
				bsr		AK_ResetVars
				moveq	#0,d7
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					endif
				endif
.Inst18Loop
				; v1 = osc_noise(33)
				move.l	AK_NoiseSeeds+0(a5),d4
				move.l	AK_NoiseSeeds+4(a5),d5
				eor.l	d5,d4
				move.l	d4,AK_NoiseSeeds+0(a5)
				add.l	d5,AK_NoiseSeeds+8(a5)
				add.l	d4,AK_NoiseSeeds+4(a5)
				move.w	AK_NoiseSeeds+10(a5),d0
				muls	#33,d0
				asr.l	#7,d0

				asr.w	#8,d0
				move.b	d0,(a0)+
				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif
				addq.l	#1,d7
				cmp.l	AK_SmpLen+68(a5),d7
				blt		.Inst18Loop

;----------------------------------------------------------------------------
; Instrument 19 - test_chord_only
;----------------------------------------------------------------------------

				moveq	#0,d0
				bsr		AK_ResetVars
				moveq	#0,d7
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					endif
				endif
.Inst19Loop
				; v1 = chordgen(0, 0, 8, 2, 12, 37)
				move.l	AK_SmpAddr+0(a5),a4
				move.b	(a4,d7.l),d6
				ext.w	d6
				add.w	#37,a4
				moveq	#0,d4
				move.w	AK_OpInstance+AK_CHORD1+0(a5),d4
				add.l	#103936,AK_OpInstance+AK_CHORD1+0(a5)
				move.b	(a4,d4.l),d5
				ext.w	d5
				add.w	d5,d6
				move.w	AK_OpInstance+AK_CHORD2+0(a5),d4
				add.l	#73472,AK_OpInstance+AK_CHORD2+0(a5)
				move.b	(a4,d4.l),d5
				ext.w	d5
				add.w	d5,d6
				move.w	AK_OpInstance+AK_CHORD3+0(a5),d4
				add.l	#131072,AK_OpInstance+AK_CHORD3+0(a5)
				move.b	(a4,d4.l),d5
				ext.w	d5
				add.w	d5,d6
				move.w	#255,d5
				cmp.w	d5,d6
				blt.s	.NoClampMaxChord_19_1
				move.w	d5,d6
				bra.s	.NoClampMinChord_19_1
.NoClampMaxChord_19_1
				not.w	d5
				cmp.w	d5,d6
				bge.s	.NoClampMinChord_19_1
				move.w	d5,d6
.NoClampMinChord_19_1
				asl.w	#7,d6
				move.w	d6,d0

				asr.w	#8,d0
				move.b	d0,(a0)+
				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif
				addq.l	#1,d7
				cmp.l	AK_SmpLen+72(a5),d7
				blt		.Inst19Loop

;----------------------------------------------------------------------------
; Instrument 20 - test_cmb_flt
;----------------------------------------------------------------------------

				moveq	#0,d0
				bsr		AK_ResetVars
				moveq	#0,d7
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					endif
				endif
.Inst20Loop
				; v1 = clone(smp,0, 0)
				moveq	#0,d0
				cmp.l	AK_SmpLen+0(a5),d7
				bge.s	.NoClone_20_1
				move.l	AK_SmpAddr+0(a5),a4
				move.b	(a4,d7.l),d0
				asl.w	#8,d0
.NoClone_20_1

				; v1 = cmb_flt_n(1, v1, 356, 68, 128)
				move.l	a1,a4
				move.w	AK_OpInstance+0(a5),d5
				move.w	(a4,d5.w),d4
				muls	#68,d4
				asr.l	#7,d4
				add.w	d0,d4
				bvc.s	.CombAddNoClamp_20_2
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.CombAddNoClamp_20_2
				move.w	d4,(a4,d5.w)
				addq.w	#2,d5
				cmp.w	#356<<1,d5
				blt.s	.NoCombReset_20_2
				moveq	#0,d5
.NoCombReset_20_2
				move.w  d5,AK_OpInstance+0(a5)
				move.w	d4,d0

				asr.w	#8,d0
				move.b	d0,(a0)+
				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif
				addq.l	#1,d7
				cmp.l	AK_SmpLen+76(a5),d7
				blt		.Inst20Loop


;----------------------------------------------------------------------------

				; Clear first 2 bytes of each sample
				lea		AK_SmpAddr(a5),a6
				moveq	#0,d0
				moveq	#31-1,d7
.SmpClrLoop		move.l	(a6)+,a4
				move.b	d0,(a4)+
				move.b	d0,(a4)+
				dbra	d7,.SmpClrLoop

				rts

;----------------------------------------------------------------------------

AK_ResetVars:
				moveq   #0,d1
				moveq   #0,d2
				moveq   #0,d3
				move.w  d0,d7
				beq.s	.NoClearDelay
				lsl.w	#8,d7
				subq.w	#1,d7
				move.l  a1,a6
.ClearDelayLoop
				move.l  d1,(a6)+
				move.l  d1,(a6)+
				move.l  d1,(a6)+
				move.l  d1,(a6)+
				dbra	d7,.ClearDelayLoop
.NoClearDelay
				moveq   #0,d0
				lea		AK_OpInstance(a5),a6
				move.l	d0,(a6)+
				move.l	d0,(a6)+
				move.l	d0,(a6)+
				move.l	d0,(a6)+
				move.l	d0,(a6)+
				move.l  #32767<<16,(a6)+
				rts

;----------------------------------------------------------------------------

				rsreset
AK_LPF			rs.w	1
AK_HPF			rs.w	1
AK_BPF			rs.w	1
				rsreset
AK_CHORD1		rs.l	1
AK_CHORD2		rs.l	1
AK_CHORD3		rs.l	1
				rsreset
AK_SmpLen		rs.l	31
AK_ExtSmpLen	rs.l	8
AK_NoiseSeeds	rs.l	3
AK_SmpAddr		rs.l	31
AK_ExtSmpAddr	rs.l	8
AK_OpInstance	rs.w    10
AK_EnvDValue	rs.l	1
AK_VarSize		rs.w	0

AK_Vars:
				dc.l	$000026a0		; Instrument 1 Length 
				dc.l	$000026a0		; Instrument 2 Length 
				dc.l	$00001c98		; Instrument 3 Length 
				dc.l	$00001000		; Instrument 4 Length 
				dc.l	$00003600		; Instrument 5 Length 
				dc.l	$00003600		; Instrument 6 Length 
				dc.l	$00003f8a		; Instrument 7 Length 
				dc.l	$00002488		; Instrument 8 Length 
				dc.l	$00002e10		; Instrument 9 Length 
				dc.l	$0000444e		; Instrument 10 Length 
				dc.l	$00001000		; Instrument 11 Length 
				dc.l	$00001b00		; Instrument 12 Length 
				dc.l	$00001000		; Instrument 13 Length 
				dc.l	$000026a0		; Instrument 14 Length 
				dc.l	$0000180e		; Instrument 15 Length 
				dc.l	$0000180e		; Instrument 16 Length 
				dc.l	$000012e6		; Instrument 17 Length 
				dc.l	$0000112e		; Instrument 18 Length 
				dc.l	$00001350		; Instrument 19 Length 
				dc.l	$000019c6		; Instrument 20 Length 
				dc.l	$00000000		; Instrument 21 Length 
				dc.l	$00000000		; Instrument 22 Length 
				dc.l	$00000000		; Instrument 23 Length 
				dc.l	$00000000		; Instrument 24 Length 
				dc.l	$00000000		; Instrument 25 Length 
				dc.l	$00000000		; Instrument 26 Length 
				dc.l	$00000000		; Instrument 27 Length 
				dc.l	$00000000		; Instrument 28 Length 
				dc.l	$00000000		; Instrument 29 Length 
				dc.l	$00000000		; Instrument 30 Length 
				dc.l	$00000000		; Instrument 31 Length 
				dc.l	$00000000		; External Sample 1 Length 
				dc.l	$00000000		; External Sample 2 Length 
				dc.l	$00000000		; External Sample 3 Length 
				dc.l	$00000000		; External Sample 4 Length 
				dc.l	$00000000		; External Sample 5 Length 
				dc.l	$00000000		; External Sample 6 Length 
				dc.l	$00000000		; External Sample 7 Length 
				dc.l	$00000000		; External Sample 8 Length 
				dc.l	$67452301		; AK_NoiseSeed1
				dc.l	$efcdab89		; AK_NoiseSeed2
				dc.l	$00000000		; AK_NoiseSeed3
				ds.b	AK_VarSize-AK_SmpAddr

;----------------------------------------------------------------------------
