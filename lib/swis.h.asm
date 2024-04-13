; ============================================================================
; RISCOS defines.
; TODO: Tidy this up into sections and make more comprehensive.
; ============================================================================

.equ OS_WriteC, 0
.equ OS_WriteO, 2
.equ OS_WriteN, 0x46
.equ OS_NewLine, 3
.equ OS_Byte, 6
.equ XOS_Byte, OS_Byte | (1 << 17)
.equ OS_Word, 7
.equ XOS_Word, OS_Word | (1 << 17)
.equ OS_File, 8
.equ OS_Exit, 0x11
.equ OS_IntOn, 0x13
.equ OS_IntOff, 0x14
.equ OS_EnterOS, 0x16
.equ OS_BreakPt, 0x17
.equ OS_Mouse, 0x1c
.equ OS_ChangeDynamicArea, 0x2a
.equ OS_GenerateError, 0x2b
.equ OS_ReadEscapeState, 0x2c
.equ OS_ReadVduVariables, 0x31
.equ OS_ReadMonotonicTime, 0x42
.equ OS_Plot, 0x45
.equ OS_ClaimDeviceVector, 0x4b
.equ OS_ReleaseDeviceVector, 0x4c
.equ OS_ReadDynamicArea, 0x5c
.equ OS_ConvertHex2, 0xd1
.equ OS_ConvertHex4, 0xd2
.equ OS_ConvertHex8, 0xd4
.equ OS_ConvertCardinal1, 0xd5	
.equ OS_ConvertCardinal4, 0xd8
.equ OS_WriteI, 0x100

.equ OSByte_EventEnable, 14
.equ OSByte_EventDisable, 13
.equ OSByte_Vsync, 19
.equ OSByte_WriteVDUBank, 112
.equ OSByte_WriteDisplayBank, 113
.equ OSByte_KeyboardScan, 121
.equ OSByte_ReadKey, 129

.equ OSWord_WritePalette, 12

; BBC compatible Internal Key numbers.
; Found in RISCOS PRMs pp 1-849.
; Values are EOR 0xff for OS_Byte 129 (Read keyboard for information.)
.equ IKey_LeftClick, 0xf6
.equ IKey_RightClick, 0xf4
.equ IKey_Space, 0x9d
.equ IKey_Return, 0xB6
.equ IKey_Escape, 0x8f
.equ IKey_A, 0xbe
.equ IKey_S, 0xae
.equ IKey_D, 0xcd
.equ IKey_R, 0xcc
.equ IKey_Escape, 0x8f
.equ IKey_ArrowUp, 198
.equ IKey_ArrowDown, 214
.equ IKey_ArrowLeft, 230
.equ IKey_ArrowRight, 134
.equ IKey_Return, 0xB6

; Archimedes low-level internal key numbers transmitted by IOC.
; Found in RISCOS PRMs pp 1-156.
; Used by RasterMan and OS_Event Event_KeyPressed (11)
.equ RMKey_ArrowUp, 0x59
.equ RMKey_ArrowLeft, 0x62
.equ RMKey_ArrowDown, 0x63
.equ RMKey_ArrowRight, 0x64
.equ RMKey_Return, 0x47
.equ RMKey_Space, 0x5f
.equ RMKey_LeftClick, 0x70
.equ RMKey_RightClick, 0x72
.equ RMKey_PageUp, 0x21
.equ RMKey_PageDown, 0x36
.equ RMKey_A, 0x3c
.equ RMKey_B, 0x52
.equ RMKey_C, 0x50
.equ RMKey_D, 0x3e
.equ RMKey_E, 0x29
.equ RMKey_F, 0x3f
.equ RMKey_G, 0x40
.equ RMKey_H, 0x41
.equ RMKey_I, 0x2e
.equ RMKey_J, 0x42
.equ RMKey_K, 0x43
.equ RMKey_L, 0x44
.equ RMKey_M, 0x54
.equ RMKey_N, 0x53
.equ RMKey_O, 0x2f
.equ RMKey_P, 0x30
.equ RMKey_Q, 0x27
.equ RMKey_R, 0x2a
.equ RMKey_S, 0x3d
.equ RMKey_T, 0x2b
.equ RMKey_U, 0x2d
.equ RMKey_V, 0x51
.equ RMKey_W, 0x28
.equ RMKey_X, 0x4f
.equ RMKey_Y, 0x2c
.equ RMKey_Z, 0x4e
.equ RMKey_1, 0x11
.equ RMKey_2, 0x12
.equ RMKey_3, 0x13
.equ RMKey_4, 0x14
.equ RMKey_5, 0x15
.equ RMKey_6, 0x16
.equ RMKey_7, 0x17
.equ RMKey_8, 0x18
.equ RMKey_9, 0x19
.equ RMKey_0, 0x1a

.equ DynArea_Screen, 2

.equ VD_ScreenStart, 148 

.equ OS_Claim, 0x1f
.equ OS_Release, 0x20
.equ OS_AddToVector, 0x47

.equ ErrorV, 0x01
.equ EventV, 0x10
.equ Event_VSync, 4
.equ Event_KeyPressed, 11

.equ Font_FindFont, 0x40081
.equ Font_LoseFont, 0x40082
.equ Font_Paint, 0x40086
.equ Font_ConverttoOS, 0x40088
.equ Font_SetFont, 0x4008a
.equ Font_SetColours, 0x40092
.equ Font_SetPalette, 0x40093
.equ Font_ScanString, 0x400a1

.equ Wimp_SlotSize, 0x400EC

.equ Sound_SoundLog,0x40181

.equ QTM_SwiBase, 0x47E40
.equ QTM_Load, 0x47E40
.equ QTM_Start, 0x47E41
.equ QTM_Stop, 0x47E42
.equ QTM_Pause, 0x47E43
.equ QTM_Clear, 0x47E44
.equ QTM_Pos, 0x47E46
.equ QTM_Volume, 0x47E48
.equ QTM_SetSampleSpeed, 0x47E49
.equ QTM_Stereo, 0x47E4D
.equ QTM_VUBarControl, 0x47E50
.equ QTM_ReadVULevels, 0x47E51
.equ QTM_SoundControl, 0x47E58
.equ QTM_MusicOptions, 0x47E5E
.equ QTM_MusicInterrupt, 0x47E5F

.equ MusicInterrupt_SongEnded, 0

.equ RasterMan_Install, 0x47e80
.equ RasterMan_Release, 0x47e81
.equ RasterMan_Wait, 0x47e82
.equ RasterMan_SetTables, 0x47e83
.equ RasterMan_Version, 0x47e84
.equ RasterMan_ReadScanline, 0x47e85
.equ RasterMan_SetVIDCRegister, 0x47e86
.equ RasterMan_SetMEMCRegister, 0x47e87
.equ RasterMan_QTMParamAddr, 0x47e88
.equ RasterMan_ScanKeyboard, 0x47e89
.equ RasterMan_ClearKeyBuffer, 0x47e8a
.equ RasterMan_ReadScanAddr, 0x47e8b
.equ RasterMan_Configure, 0x47e8c

.equ VIDC_Col0, 0x00000000
.equ VIDC_Col1, 0x04000000              ; index << 26
.equ VIDC_Col2, 0x08000000
.equ VIDC_Col3, 0x0c000000
.equ VIDC_Col4, 0x10000000
.equ VIDC_Col5, 0x14000000
.equ VIDC_Col6, 0x18000000
.equ VIDC_Col7, 0x1c000000
.equ VIDC_Col8, 0x20000000
.equ VIDC_Col9, 0x24000000
.equ VIDC_Col10, 0x28000000
.equ VIDC_Col11, 0x2c000000
.equ VIDC_Col12, 0x30000000
.equ VIDC_Col13, 0x34000000
.equ VIDC_Col14, 0x38000000
.equ VIDC_Col15, 0x3c000000
.equ VIDC_Border, 0x40000000

.equ VIDC_Write, 0x03400000
.equ VIDC_HBorderStart, 0x88000000      ; (M-1)/2 pixels << 14 [odd]
.equ VIDC_HDisplayStart, 0x8C000000     ; (M-7)/2 MODE 9 pixels << 14 [x7]
.equ VIDC_HDisplayEnd, 0x90000000       ; (M-7)/2 MODE 9 pixels << 14 [x7]
.equ VIDC_HBorderEnd, 0x94000000        ; (M-1)/2 pixels << 14 [odd]
.equ VIDC_VCycle, 0xA0000000
.equ VIDC_VBorderStart, 0xA8000000      ; N-1 rasters << 14
.equ VIDC_VDisplayStart, 0xAC000000     ; N-1 rasters << 14
.equ VIDC_VDisplayEnd, 0xB0000000       ; N-1 rasters << 14
.equ VIDC_VBorderEnd, 0xB4000000        ; N-1 rasters << 14

.equ MODE9_HCentrePixels, 291
.equ MODE9_VCentreRasters, 166

.equ ASCII_a, 97
.equ ASCII_z, 122
.equ ASCII_A, 65
.equ ASCII_i, 'i'
.equ ASCII_Z, 90
.equ ASCII_0, 48
.equ ASCII_9, 57
.equ ASCII_ExclamationMark, 33
.equ ASCII_Colon, 58
.equ ASCII_Space, 32
.equ ASCII_Minus, 45
.equ ASCII_LessThan, 60
.equ ASCII_MoreThan, 62

.equ VDU_TextColour, 17
.equ VDU_Home, 30
.equ VDU_SetPos, 31
