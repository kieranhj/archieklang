# akp2arc.py (aka Aklang2Acorn) version 1.0, May 2024.
# Converts AmigaKlang patch data to ARM asm (vasm format) from a Dan table (aka 'script.txt')
# Written by kieran/Bitshifters. (https://bitshifters.github.io/)
# Based on Alcatraz Amigaklang rendering core. (c) Jochen 'Virgill' Feldkötter 2020-2024.
# And Aklang2Asm V1.1, by Dan/Lemon. 2021-2022.
# Please excuse my terrible non-Pythonic code. :D

import argparse
import binascii
import sys
import os
import struct
from parse import *

DEBUG_INSTRUMENT=0  # Set to instrument number to insert breakpoint code.
DEBUG_SAMPLE=0      # Set to sample number for instrument to insert breakpoint code.

DECAY_TABLE = [32767, 32767, 32767, 16384, 10922, 8192, 6553, 4681, 3640, 2978, 2520, 2048, 1724, 1489, 1310, 1129, 992, 885, 799, 712, 642, 585, 537, 489, 448, 414, 385, 356, 330, 309, 289, 270, 254, 239, 225, 212, 201, 190, 181, 171, 163, 155, 148, 141, 134, 129, 123, 118, 113, 108, 104, 100, 96, 93, 89, 86, 83, 80, 77, 75, 72, 70, 68, 65, 63, 61, 60, 58, 56, 54, 53, 51, 50, 49, 47, 46, 45, 44, 43, 41, 40, 39, 38, 38, 37, 36, 35, 34, 33, 33, 32, 31, 30, 30, 29, 29, 28, 27, 27, 26, 26, 25, 25, 24, 24, 23, 23, 22, 22, 22, 21, 21, 20, 20, 20, 19, 19, 19, 18, 18, 18, 17, 17, 17, 17, 16, 16, 16]

class AkpParser:
    def __init__(self, akp_file, legacy_bugs) -> None:
        self._akp_file = akp_file
        self._legacy_bugs = legacy_bugs

    def sign_extend(self, asm_file, reg):
        asm_file.write(f'\tmov r{reg}, r{reg}, asl #16\n')
        asm_file.write(f'\tmov r{reg}, r{reg}, asr #16\t; Sign extend word to long.\n')

    def clamp(self, asm_file, var):
        if var>4:
            asm_file.write(f'\t; r{var-1} = clamp(r{var-1})\n')
        else:
            asm_file.write(f'\t; v{var} = clamp(v{var})\n')

        asm_file.write(f'\tcmp r{var-1}, r11\t\t; #32767\n')
        asm_file.write(f'\tmovgt r{var-1}, r11\t; #32767\n')
        asm_file.write(f'\tcmn r{var-1}, r11\t\t; #-32768\n')
        asm_file.write(f'\tmvnlt r{var-1}, r11\t; #-32768\n')

    def vol_var(self, asm_file, dst_var, src_var, gain_V, gain_C):
        if gain_V is not None:
            if src_var == gain_V[0]:
                print('Warning: Volume gain var using src var!\n')

            if dst_var>4:
                asm_file.write(f'\t; r{dst_var-1} = vol(r{src_var-1}, v{gain_V[0]})\n')
            else:
                asm_file.write(f'\t; v{dst_var} = vol(v{src_var}, v{gain_V[0]})\n')

            asm_file.write(f'\tand r14, r{gain_V[0]-1}, #0xff\n')

            asm_file.write(f'\tmul r{dst_var-1}, r14, r{src_var-1}\n')
            asm_file.write(f'\tmov r{dst_var-1}, r{dst_var-1}, asr #7\n')
            self.sign_extend(asm_file, dst_var-1)
        else:
            if dst_var>4:
                asm_file.write(f'\t; r{dst_var-1} = vol(r{src_var-1}, {gain_C[0]})\n')
            else:
                asm_file.write(f'\t; v{dst_var} = vol(v{src_var}, {gain_C[0]})\n')

            shift_val=gain_C[0]
            shift_bit=shift_val & (shift_val-1)

            if shift_bit==0:
                # Shift for 2^N muls.
                shift_left=-1
                while shift_val!=0:
                    shift_val>>=1
                    shift_left+=1

                shift_left-=7
                if shift_left==0:
                    if src_var==dst_var:
                        asm_file.write(f'\t; NOOP -- val<<{shift_left+7}>>7\n')
                    else:
                        asm_file.write(f'\tmov r{dst_var-1}, r{src_var-1}\t; NOOP -- val<<{shift_left+7}>>7\n')
                elif shift_left<0:
                    asm_file.write(f'\tmov r{dst_var-1}, r{src_var-1}, asr #{-shift_left}\t; val<<{shift_left+7}>>7\n')
                else:
                    asm_file.write(f'\tmov r{dst_var-1}, r{src_var-1}, asl #{shift_left}\t; val<<{shift_left+7}>>7\n')

            else:
                asm_file.write(f'\tmov r14, #{gain_C[0]}\n')
                asm_file.write(f'\tmul r{dst_var-1}, r14, r{src_var-1}\n')
                asm_file.write(f'\tmov r{dst_var-1}, r{dst_var-1}, asr #7\n')
                self.sign_extend(asm_file, dst_var-1)

    def vol(self, asm_file, var, gain_V, gain_C):
        self.vol_var(asm_file, var, var, gain_V, gain_C)

    def func_add(self, asm_file, var, param_string):
        params_V=parse("v{:d}, v{:d}", param_string)
        params_C=parse("v{:d}, {:d}", param_string)

        if params_V is not None:
            self.sign_extend(asm_file, params_V[0]-1)
            self.sign_extend(asm_file, params_V[1]-1)
            asm_file.write(f'\tadd r{var-1}, r{params_V[0]-1}, r{params_V[1]-1}\n')
        else:
            self.sign_extend(asm_file, params_C[0]-1)
            if params_C[1]<0:
                asm_file.write(f'\tmvn r14, #{-params_C[1]-1}\n')
            else:
                asm_file.write(f'\tmov r14, #{params_C[1]}\n')
            asm_file.write(f'\tadd r{var-1}, r{params_C[0]-1}, r14\n')

        self.clamp(asm_file, var)

    def func_vol(self, asm_file, var, param_string):
        vol_params=parse("v{:d}, {:S}", param_string)
        gain_V=parse("v{:d}", vol_params[1])
        gain_C=parse("{:d}", vol_params[1])
        self.vol_var(asm_file, var, vol_params[0], gain_V, gain_C)

    def func_mul(self, asm_file, var, param_string):
        params_V=parse("v{:d}, v{:d}", param_string)
        params_C=parse("v{:d}, {:d}", param_string)

        if params_V is not None:
            if params_V[0]==params_V[1]:
                asm_file.write(f'\tmov r14, r{params_V[1]-1}\n')
                asm_file.write(f'\tmul r{var-1}, r14, r{params_V[0]-1}\n')
            elif var == params_V[0]:
                asm_file.write(f'\tmul r{var-1}, r{params_V[1]-1}, r{params_V[0]-1}\n')
            else:
                asm_file.write(f'\tmul r{var-1}, r{params_V[0]-1}, r{params_V[1]-1}\n')

            asm_file.write(f'\tmov r{var-1}, r{var-1}, asr #15\n')
            self.sign_extend(asm_file, var-1)
        else:
            shift_val=params_C[1]
            shift_bit=shift_val & (shift_val-1)

            if shift_bit==0:
                # Shift for 2^N muls.
                shift_left=-1
                while shift_val!=0:
                    shift_val>>=1
                    shift_left+=1

                shift_left-=15
                if shift_left==0:
                    asm_file.write(f'\t; NOOP -- val<<{shift_left+15}>>15\n')
                elif shift_left < 0:
                    asm_file.write(f'\tmov r{var-1}, r{params_C[0]-1}, asr #{-shift_left}\t; val<<{shift_left+15}>>15\n')
                else:
                    asm_file.write(f'\tmov r{var-1}, r{params_C[0]-1}, asl #{shift_left}\t; val<<{shift_left+15}>>15\n')

            else:
                if params_C[1]<0:
                    asm_file.write(f'\tmvn r14, #{-params_C[1]-1}\n')
                else:
                    asm_file.write(f'\tmov r14, #{params_C[1]}\n')

                asm_file.write(f'\tmul r{var-1}, r14, r{params_C[0]-1}\n')
                asm_file.write(f'\tmov r{var-1}, r{var-1}, asr #15\n')
                self.sign_extend(asm_file, var-1)

    def func_osc_saw(self, asm_file, var, param_string):
        param_strings=parse("{:d}, {}, {}", param_string)

        freq_V=parse("v{:d}", param_strings[1])
        freq_C=parse("{:d}", param_strings[1])
        gain_V=parse("v{:d}", param_strings[2])
        gain_C=parse("{:d}", param_strings[2])

        asm_file.write(f'\tldr r4, [r10, #AK_OPINSTANCE+4*{self._instance}]\n')

        if freq_V is not None:
            asm_file.write(f'\tadd r4, r4, r{freq_V[0]-1}\n')
        else:
            asm_file.write(f'\tadd r4, r4, #{freq_C[0]}\n')

        self.sign_extend(asm_file, 4)
        asm_file.write(f'\tstr r4, [r10, #AK_OPINSTANCE+4*{self._instance}]\t\n')

        self.vol_var(asm_file, var, 5, gain_V, gain_C)
        self._instance+=1

    def func_sh(self, asm_file, var, param_string):
        param_strings=parse("{:d}, {}, {}", param_string)

        value_V=parse("v{:d}", param_strings[1])
        value_C=parse("{:d}", param_strings[1])
        step_V=parse("v{:d}", param_strings[2])
        step_C=parse("{:d}", param_strings[2])

        asm_file.write(f'\tldr r6, [r10, #AK_OPINSTANCE+4*{self._instance+0}]\n')
        asm_file.write(f'\tsubs r6, r6, #1\n')

        # buffer=val
        if value_V is not None:
            asm_file.write(f'\tstrlt r{value_V[0]-1}, [r10, #AK_OPINSTANCE+4*{self._instance+1}]\n')
        else:
            asm_file.write(f'\tmovlt r14, #{value_C[0]}\n')
            asm_file.write(f'\tstrlt r14, [r10, #AK_OPINSTANCE+4*{self._instance+1}]\n')

        # counter=step2
        if step_V is not None:
            asm_file.write(f'\tmovlt r14, r{step_V[0]-1}, asl #24\n')
            asm_file.write(f'\tmovlt r14, r14, asr #24\n')
            asm_file.write(f'\tmovlt r4, r14\n')
            asm_file.write(f'\tmullt r14, r4, r14\n')
            asm_file.write(f'\tmovlt r6, r14, asr #2\n')
        else:
            asm_file.write(f'\tmovlt r6, #{(step_C[0]*step_C[0])>>2}\n')
            

        asm_file.write(f'\tstr r6, [r10, #AK_OPINSTANCE+4*{self._instance+0}]\n')
        asm_file.write(f'\tldr r{var-1}, [r10, #AK_OPINSTANCE+4*{self._instance+1}]\n')

        self._instance+=2


    def func_osc_sine(self, asm_file, var, param_string):
        param_strings=parse("{:d}, {}, {}", param_string)

        freq_V=parse("v{:d}", param_strings[1])        
        freq_C=parse("{:d}", param_strings[1])        
        gain_V=parse("v{:d}", param_strings[2])        
        gain_C=parse("{:d}", param_strings[2])        

        asm_file.write(f'\tldr r6, [r10, #AK_OPINSTANCE+4*{self._instance}]\n')

        if freq_V is not None:
            asm_file.write(f'\tadd r6, r6, r{freq_V[0]-1}\n')
        else:
            asm_file.write(f'\tadd r6, r6, #{freq_C[0]}\n')

        asm_file.write(f'\tstr r6, [r10, #AK_OPINSTANCE+4*{self._instance}]\n')

        asm_file.write(f'\tsub r6, r6, #16384\n')
        self.sign_extend(asm_file, 6)

        asm_file.write(f'\tmovs r4, r6\n')
        asm_file.write(f'\trsblt r4, r4, #0\n')

        asm_file.write(f'\tsub r4, r11, r4\t; #32767\n')
        asm_file.write(f'\tmul r4, r6, r4\n')
        asm_file.write(f'\tmov r4, r4, asr #16\n')
        asm_file.write(f'\tmov r4, r4, asl #3\n')

        self.vol_var(asm_file, var, 5, gain_V, gain_C)
        self._instance+=1

    def func_osc_tri(self, asm_file, var, param_string):
        param_strings=parse("{:d}, {}, {}", param_string)

        freq_V=parse("v{:d}", param_strings[1])
        freq_C=parse("{:d}", param_strings[1])
        gain_V=parse("v{:d}", param_strings[2])
        gain_C=parse("{:d}", param_strings[2])

        asm_file.write(f'\tldr r6, [r10, #AK_OPINSTANCE+4*{self._instance}]\n')

        if freq_V is not None:
            asm_file.write(f'\tadd r6, r6, r{freq_V[0]-1}\n')
        else:
            asm_file.write(f'\tadd r6, r6, #{freq_C[0]}\n')

        self.sign_extend(asm_file, 6)
        asm_file.write(f'\tstr r6, [r10, #AK_OPINSTANCE+4*{self._instance}]\n')
        asm_file.write(f'\tcmp r6, #0\n')
        asm_file.write(f'\tmvnmi r6, r6\n')
        asm_file.write(f'\tsub r6, r6, #16384\n')
        asm_file.write(f'\tmov r{var-1}, r6, asl #1\n')
  
        self.vol(asm_file, var, gain_V, gain_C)
        self._instance+=1

    def func_osc_pulse(self, asm_file, var, param_string):
        param_strings=parse("{:d}, {}, {}, {}", param_string)

        freq_V=parse("v{:d}", param_strings[1])
        freq_C=parse("{:d}", param_strings[1])
        gain_V=parse("v{:d}", param_strings[2])
        gain_C=parse("{:d}", param_strings[2])
        duty_V=parse("v{:d}", param_strings[3])
        duty_C=parse("{:d}", param_strings[3])

        asm_file.write(f'\tldr r6, [r10, #AK_OPINSTANCE+4*{self._instance}]\n')

        if freq_V is not None:
            asm_file.write(f'\tadds r6, r6, r{freq_V[0]-1}\n')
        else:
            asm_file.write(f'\tadds r6, r6, #{freq_C[0]}\n')

        self.sign_extend(asm_file, 6)
        asm_file.write(f'\tstr r6, [r10, #AK_OPINSTANCE+4*{self._instance}]\n')

        if duty_V is not None:
            asm_file.write(f'\tsub r4, r{duty_V[0]-1}, #63\n')
            asm_file.write(f'\tmov r4, r4, asl #9\n')
        else:
            const=(duty_C[0]-63)<<9
            if const<0:
                asm_file.write(f'\tmvn r4, #{-const-1}\t; ({duty_C[0]}-63)<<9\n')
            else:
                asm_file.write(f'\tmov r4, #{const}\t; ({duty_C[0]}-63)<<9\n')

        asm_file.write(f'\tcmp r6, r4\n')
        asm_file.write(f'\tmvnlt r{var-1}, r11\t; #-32768\n')
        asm_file.write(f'\tmovge r{var-1}, r11\t; #32767\n')

        self.vol(asm_file, var, gain_V, gain_C)
        self._instance+=1

    def func_osc_noise(self, asm_file, var, param_string):
        gain_V=parse("v{:d}", param_string)
        gain_C=parse("{:d}", param_string)

        asm_file.write(f'\tldr r4, [r10, #AK_NOISESEEDS+0]\n')
        asm_file.write(f'\tldr r6, [r10, #AK_NOISESEEDS+4]\n')
        asm_file.write(f'\teor r4, r4, r6\n')
        asm_file.write(f'\tstr r4, [r10, #AK_NOISESEEDS+0]\n')

        asm_file.write(f'\tldr r12, [r10, #AK_NOISESEEDS+8]\n')
        asm_file.write(f'\tadd r12, r12, r6\n')
        asm_file.write(f'\tstr r12, [r10, #AK_NOISESEEDS+8]\n')

        asm_file.write(f'\tadd r6, r6, r4\n')
        asm_file.write(f'\tstr r6, [r10, #AK_NOISESEEDS+4]\n')

        self.sign_extend(asm_file, 12)
        self.vol_var(asm_file, var, 13, gain_V, gain_C)

    def func_enva(self, asm_file, var, param_string):
        params=parse("{:d}, {:d}, {:d}, {}", param_string)

        gain_V=parse("v{:d}", params[3])
        gain_C=parse("{:d}", params[3])

        asm_file.write(f'\tldr r6, [r10, #AK_OPINSTANCE+4*{self._instance}]\n')
        asm_file.write(f'\tmov r{var-1}, r6, asr #8\n')
        asm_file.write(f'\tmov r4, #{DECAY_TABLE[params[1]]}\n')    # attack
        asm_file.write(f'\tadd r6, r6, r4\n')
        asm_file.write(f'\tcmp r6, r11, asl #8\n')
        asm_file.write(f'\tmovgt r6, r11, asl #8\n')
        asm_file.write(f'\tstr r6, [r10, #AK_OPINSTANCE+4*{self._instance}]\n')

        self.vol(asm_file, var, gain_V, gain_C)
        self._instance+=1

    def func_envd(self, asm_file, var, param_string):
        params=parse("{:d}, {:d}, {:d}, {}", param_string)

        gain_V=parse("v{:d}", params[3])
        gain_C=parse("{:d}", params[3])

        asm_file.write(f'\tmov r4, #{DECAY_TABLE[params[1]]}\n')
        asm_file.write(f'\tmul r6, r7, r4\n')
        asm_file.write(f'\tsubs r6, r11, r6, asr #8\n')
        if params[2] != 0:
            asm_file.write(f'\tcmp r6, #{params[2]<<8}\n')
            asm_file.write(f'\tmovle r6, #{params[2]<<8}\n')
        else:
            asm_file.write(f'\tmovle r6, #0\n')
        asm_file.write(f'\tmov r{var-1}, r6\n')

        self.vol(asm_file, var, gain_V, gain_C)

    def func_clone(self, asm_file, var, param_string):
        params=parse("{},{:d}, {:d}", param_string)
        if params[0] != 'smp':
            print('WARNING: Expected "smp"?')

        if params[2] !=0 :
            asm_file.write(f'\tadd r{var-1}, r7, #{params[2]}\n')
        else:
            asm_file.write(f'\tmov r{var-1}, r7\n')
            
        asm_file.write(f'\tldr r6, [r10, #AK_SMPADDR+4*{params[1]}]\n')
        asm_file.write(f'\tldr r4, [r10, #AK_SMPLEN+4*{params[1]}]\n')
        asm_file.write(f'\tcmp r{var-1}, r4\n')
        asm_file.write(f'\tmovge r{var-1}, #0\n')
        asm_file.write(f'\tldrltb r{var-1}, [r6, r{var-1}]\n')
        asm_file.write(f'\tmov r{var-1}, r{var-1}, asl #24\n')
        asm_file.write(f'\tmov r{var-1}, r{var-1}, asr #16\n')

    def func_imported_sample(self, asm_file, var, param_string):
        params=parse("{},{:d}", param_string)
        if params[0] != 'smp':
            print('WARNING: Expected "smp"?')

        asm_file.write(f'\tmov r{var-1}, r7\n')
        asm_file.write(f'\tldr r6, [r10, #AK_EXTSMPADDR+4*{params[1]}]\n')
        asm_file.write(f'\tldr r4, [r10, #AK_EXTSMPLEN+4*{params[1]}]\n')
        asm_file.write(f'\tcmp r{var-1}, r4\n')
        asm_file.write(f'\tmovge r{var-1}, #0\n')
        asm_file.write(f'\tldrltb r{var-1}, [r6, r{var-1}]\n')
        asm_file.write(f'\tmov r{var-1}, r{var-1}, asl #24\n')
        asm_file.write(f'\tmov r{var-1}, r{var-1}, asr #16\n')

    def func_clone_reverse(self, asm_file, var, param_string):
        params=parse("{},{:d}, {:d}", param_string)
        if params[0] != 'smp':
            print('WARNING: Expected "smp"?')

        if params[2] !=0 :
            asm_file.write(f'\tadds r{var-1}, r7, #{params[2]}\n')
        else:
            asm_file.write(f'\tmovs r{var-1}, r7\n')

        if self._legacy_bugs:
            asm_file.write(f'\tldreqb r{var-1}, [r10, #AK_OVERFLOWSAMPLES+{params[1]+1}]\n')
            asm_file.write(f'\tbeq CloneReverse_Overflow_{self._inst_nr}\n')

        asm_file.write(f'\tldr r6, [r10, #AK_SMPADDR+4*{params[1]}]\n')
        asm_file.write(f'\tldr r4, [r10, #AK_SMPLEN+4*{params[1]}]\n')
        asm_file.write(f'\tcmp r{var-1}, r4\n')
        asm_file.write(f'\tmovge r{var-1}, #0\n')
        asm_file.write(f'\tsublt r{var-1}, r4, r{var-1}\n')

        if self._legacy_bugs is False:
            asm_file.write(f'\tsublt r{var-1}, r{var-1}, #1\t; BUG FIX: -1 from length to avoid reading beyond end of sample\n')

        asm_file.write(f'\tldrltb r{var-1}, [r6, r{var-1}]\n')

        if self._legacy_bugs:
            asm_file.write(f'CloneReverse_Overflow_{self._inst_nr}:\n')

        asm_file.write(f'\tmov r{var-1}, r{var-1}, asl #24\n')
        asm_file.write(f'\tmov r{var-1}, r{var-1}, asr #16\n')

    def func_ctrl(self, asm_file, var, param_string):
        src_var=parse("v{:d}", param_string)
        asm_file.write(f'\tmov r{var-1}, r{src_var[0]-1}, asr #9\n')
        self.sign_extend(asm_file, var-1)
        asm_file.write(f'\tadd r{var-1}, r{var-1}, #64\n')

    def func_dly_cyc(self, asm_file, var, param_string):
        param_strings=parse("{:d}, {}, {}, {}", param_string)

        dly_count=param_strings[0]

        val_V=parse("v{:d}", param_strings[1])
        if val_V is None:
            print('WARNING: Expected a var not a const!')
        delay_V=parse("v{:d}", param_strings[2])
        delay_C=parse("{:d}", param_strings[2])
        gain_V=parse("v{:d}", param_strings[3])
        gain_C=parse("{:d}", param_strings[3])

        asm_file.write(f'\tmov r4, r{val_V[0]-1}\n')
        self.vol(asm_file, 5, gain_V, gain_C)

        if self._legacy_bugs:
            asm_file.write(f'\tldr r6, [r10, #AK_DLYCOUNTS+4*{dly_count}]\n')
        else:
            asm_file.write(f'\tldr r6, [r10, #AK_OPINSTANCE+4*{self._instance}]\n')

        asm_file.write(f'\tstr r4, [r9, r6, lsl #2]\n')
        asm_file.write(f'\tadd r6, r6, #1\n')

        if delay_V is not None:
            asm_file.write(f'\tcmp r6, r{delay_V[0]-1}\n')
        else:
            asm_file.write(f'\tmov r14, #{delay_C[0]}\n')
            asm_file.write(f'\tcmp r6, r14\n')

        asm_file.write(f'\tmovge r6, #0\n')

        if self._legacy_bugs:
            asm_file.write(f'\tstr r6, [r10, #AK_DLYCOUNTS+4*{dly_count}]\n')
        else:
            asm_file.write(f'\tstr r6, [r10, #AK_OPINSTANCE+4*{self._instance}]\n')
            self._instance+=1

        asm_file.write(f'\tldr r{var-1}, [r9, r6, lsl #2]\n')

        asm_file.write(f'\tadd r9, r9, #2048*4\t; next temp buffer.\n')
        self._buffers+=1

    def func_reverb(self, asm_file, var, param_string):
        param_strings=parse("{}, {}, {}", param_string)

        self.func_cmb_flt_n(asm_file, 13, f'16, {param_strings[0]}, 557, {param_strings[1]}, {param_strings[2]}')
        asm_file.write(f'\tmov r5, r12\n')
        self.func_cmb_flt_n(asm_file, 13, f'17, {param_strings[0]}, 593, {param_strings[1]}, {param_strings[2]}')
        asm_file.write(f'\tadd r5, r5, r12\n')
        self.func_cmb_flt_n(asm_file, 13, f'18, {param_strings[0]}, 641, {param_strings[1]}, {param_strings[2]}')
        asm_file.write(f'\tadd r5, r5, r12\n')
        self.func_cmb_flt_n(asm_file, 13, f'19, {param_strings[0]}, 677, {param_strings[1]}, {param_strings[2]}')
        asm_file.write(f'\tadd r5, r5, r12\n')
        self.func_cmb_flt_n(asm_file, 13, f'20, {param_strings[0]}, 709, {param_strings[1]}, {param_strings[2]}')
        asm_file.write(f'\tadd r5, r5, r12\n')
        self.func_cmb_flt_n(asm_file, 13, f'21, {param_strings[0]}, 743, {param_strings[1]}, {param_strings[2]}')
        asm_file.write(f'\tadd r5, r5, r12\n')
        self.func_cmb_flt_n(asm_file, 13, f'22, {param_strings[0]}, 787, {param_strings[1]}, {param_strings[2]}')
        asm_file.write(f'\tadd r5, r5, r12\n')
        self.func_cmb_flt_n(asm_file, 13, f'23, {param_strings[0]}, 809, {param_strings[1]}, {param_strings[2]}')
        asm_file.write(f'\tadd r{var-1}, r5, r12\n')

        self.clamp(asm_file, var)

    def func_cmb_flt_n(self, asm_file, var, param_string):
        param_strings=parse("{:d}, {}, {}, {}, {}", param_string)

        cmb_count=param_strings[0]

        val_V=parse("v{:d}", param_strings[1])
        if val_V is None:
            print('WARNING: Expected a var not a const!')
        delay_V=parse("v{:d}", param_strings[2])
        delay_C=parse("{:d}", param_strings[2])
        feedback_V=parse("v{:d}", param_strings[3])
        feedback_C=parse("{:d}", param_strings[3])
        gain_V=parse("v{:d}", param_strings[4])
        gain_C=parse("{:d}", param_strings[4])

        if self._legacy_bugs:
            asm_file.write(f'\tldr r6, [r10, #AK_CMBCOUNTS+4*{cmb_count}]\n')
        else:
            asm_file.write(f'\tldr r6, [r10, #AK_OPINSTANCE+4*{self._instance}]\n')

        asm_file.write(f'\tldr r4, [r9, r6, lsl #2]\n')

        self.vol(asm_file, 5, feedback_V, feedback_C)

        self.sign_extend(asm_file, val_V[0]-1)
        asm_file.write(f'\tadd r{var-1}, r{val_V[0]-1}, r4\n')
        self.clamp(asm_file, var)
        asm_file.write(f'\tstr r{var-1}, [r9, r6, lsl #2]\n')
        asm_file.write(f'\tadd r6, r6, #1\n')

        if delay_V is not None:
            asm_file.write(f'\tcmp r6, r{delay_V[0]-1}\n')
        else:
            asm_file.write(f'\tmov r14, #{delay_C[0]}\n')
            asm_file.write(f'\tcmp r6, r14\n')

        asm_file.write(f'\tmovge r6, #0\n')

        if self._legacy_bugs:
            asm_file.write(f'\tstr r6, [r10, #AK_CMBCOUNTS+4*{cmb_count}]\n')
        else:
            asm_file.write(f'\tstr r6, [r10, #AK_OPINSTANCE+4*{self._instance}]\n')
            self._instance+=1
        
        self.vol(asm_file, var, gain_V, gain_C)

        asm_file.write(f'\tadd r9, r9, #2048*4\t; next temp buffer.\n')
        self._buffers+=1

    def func_sv_flt_n(self, asm_file, var, param_string):
        param_strings=parse("{:d}, {}, {}, {}, {}", param_string)

        val_V=parse("v{:d}", param_strings[1])
        if val_V is None:
            print('WARNING: Expected a var not a const!')
        cutoff_V=parse("v{:d}", param_strings[2])
        cutoff_C=parse("{:d}", param_strings[2])
        resonance_V=parse("v{:d}", param_strings[3])
        resonance_C=parse("{:d}", param_strings[3])
        mode=parse("{:d}", param_strings[4])[0]

        # asm_file.write(f'\tldr r4, [r10, #AK_OPINSTANCE+4*({self._instance}+AK_LPF)]\n')
        # asm_file.write(f'\tldr r5, [r10, #AK_OPINSTANCE+4*({self._instance}+AK_HPF)]\n')    # redundant?
        # asm_file.write(f'\tldr r6, [r10, #AK_OPINSTANCE+4*({self._instance}+AK_BPF)]\n')
        asm_file.write(f'\tadd r14, r10, #AK_OPINSTANCE+4*({self._instance}+AK_LPF)\n')
        asm_file.write('\tldmia r14, {r4-r6}\n')

        asm_file.write(f'\tmov r14, r6, asr #7\n')

        if cutoff_V is not None:
            asm_file.write(f'\tmla r4, r{cutoff_V[0]-1}, r14, r4\n')
        else:
            asm_file.write(f'\tmov r12, #{cutoff_C[0]}\n')
            asm_file.write(f'\tmla r4, r14, r12, r4\n')

        self.clamp(asm_file, 5) # r4
        asm_file.write(f'\tstr r4, [r10, #AK_OPINSTANCE+4*({self._instance}+AK_LPF)]\n')

        if resonance_V is not None:
            asm_file.write(f'\tmul r14, r{resonance_V[0]-1}, r14\n')
        else:
            # TODO: Shift for 2^N.
            asm_file.write(f'\tmov r12, #{resonance_C[0]}\n')
            asm_file.write(f'\tmul r14, r12, r14\n')

        asm_file.write(f'\tmov r12, r{val_V[0]-1}\n')
        asm_file.write(f'\tsub r12, r12, r4\n')
        asm_file.write(f'\tsub r5, r12, r14\n')

        self.clamp(asm_file, 6) # r5
        asm_file.write(f'\tstr r5, [r10, #AK_OPINSTANCE+4*({self._instance}+AK_HPF)]\n')
    
        asm_file.write(f'\tmov r14, r5, asr #7\n')

        if cutoff_V is not None:
            asm_file.write(f'\tmla r6, r{cutoff_V[0]-1}, r14, r6\n')
        else:
            # TODO: Shift for 2^N.
            asm_file.write(f'\tmov r12, #{cutoff_C[0]}\n')
            asm_file.write(f'\tmla r6, r12, r14, r6\n')

        self.clamp(asm_file, 7) # r6
        asm_file.write(f'\tstr r6, [r10, #AK_OPINSTANCE+4*({self._instance}+AK_BPF)]\n')

        if mode==0:
            asm_file.write(f'\tmov r{var-1}, r4\n')
        elif mode==1:
            asm_file.write(f'\tmov r{var-1}, r5\n')
        elif mode==2:
            asm_file.write(f'\tmov r{var-1}, r6\n')
        elif mode==3:
            asm_file.write(f'\tadd r{var-1}, r5, r6\n')
            self.clamp(asm_file, var)

        self._instance+=3

    def chord_note(self, asm_file, note1, note2, note3, note_num, mult_val, mult_shift):
        if note1==note_num:
            chord_var='AK_CHORD1'
        elif note2==note_num:
            chord_var='AK_CHORD2'
        elif note3==note_num:
            chord_var='AK_CHORD3'
        else:
            return

        asm_file.write(f'\tldr r5, [r10, #AK_OPINSTANCE+4*({self._instance}+{chord_var})]\n')

        asm_file.write(f'\tcmp r12, r5, lsr #{8+mult_shift}\n')
        asm_file.write(f'\tldrgtb r14, [r4, r5, lsr #{8+mult_shift}]\n')
        asm_file.write(f'\tmovle r14, #0\n')

        asm_file.write(f'\tadd r5, r5, #{mult_val<<8}\n')
        asm_file.write(f'\tstr r5, [r10, #AK_OPINSTANCE+4*({self._instance}+{chord_var})]\n')

        asm_file.write(f'\tmov r14, r14, asl #24\n')
        asm_file.write(f'\tadd r6, r6, r14, asr #{24-7}\n')

    def func_chordgen(self, asm_file, var, param_string):
        param_strings=parse("{:d}, {:d}, {:d}, {:d}, {:d}, {}", param_string)

        sample_nr=param_strings[1]
        note1=param_strings[2]
        note2=param_strings[3]
        note3=param_strings[4]
        shift_V=parse("v{:d}", param_strings[5])
        shift_C=parse("{:d}", param_strings[5])

        asm_file.write(f'\tldr r4, [r10, #AK_SMPADDR+4*{sample_nr}]\n')
        asm_file.write(f'\tldr r12, [r10, #AK_SMPLEN+4*{sample_nr}]\n')
        asm_file.write(f'\tcmp r7, r12\n')
        asm_file.write(f'\tldrltb r6, [r4, r7]\n')
        asm_file.write(f'\tmovge r6, #0\n')
        asm_file.write(f'\tmov r6, r6, asl #24\n')
        asm_file.write(f'\tmov r6, r6, asr #{24-7}\n')

        if shift_V is not None:
            asm_file.write(f'\tadd r4, r4, r{shift_V[0]-1}\n')
            asm_file.write(f'\tsub r12, r12, r{shift_V[0]-1}\n')
        else:
            if shift_C[0]!=0:
                asm_file.write(f'\tadd r4, r4, #{shift_C[0]}\n')
                asm_file.write(f'\tsub r12, r12, #{shift_C[0]}\n')

        self.chord_note(asm_file, note1, note2, note3, 1, 271, 8)
        self.chord_note(asm_file, note1, note2, note3, 2, 287, 8)
        self.chord_note(asm_file, note1, note2, note3, 3, 304, 8)
        self.chord_note(asm_file, note1, note2, note3, 4, 322, 8)
        self.chord_note(asm_file, note1, note2, note3, 5, 342, 8)
        self.chord_note(asm_file, note1, note2, note3, 6, 362, 8)
        self.chord_note(asm_file, note1, note2, note3, 7, 383, 8)
        self.chord_note(asm_file, note1, note2, note3, 8, 203, 7)
        self.chord_note(asm_file, note1, note2, note3, 9, 215, 7)
        self.chord_note(asm_file, note1, note2, note3, 10, 228, 7)
        self.chord_note(asm_file, note1, note2, note3, 11, 483, 8)
        self.chord_note(asm_file, note1, note2, note3, 12, 2, 0)

        asm_file.write(f'\tmov r{var-1}, r6\n')
        self.clamp(asm_file, var)
        self._instance+=3

    def func_distortion(self, asm_file, var, param_string):
        param_strings=parse("{}, {}", param_string)

        val_V=parse("v{:d}", param_strings[0])        
        if val_V is None:
            print('WARNING: Expected a var not a const!')
        gain_V=parse("v{:d}", param_strings[1])        
        gain_C=parse("{:d}", param_strings[1])        

        if gain_V is not None:
            # TODO: Potential register clash.
            asm_file.write(f'\tmul r14, r{val_V[0]-1}, r{gain_V[0]-1}\n')
        else:
            asm_file.write(f'\tmov r14, #{gain_C[0]}\n')
            asm_file.write(f'\tmul r14, r{val_V[0]-1}, r14\n')

        asm_file.write(f'\tmov r14, r14, asr #5\n')
        self.clamp(asm_file, 15)
        asm_file.write(f'\tmov r14, r14, asr #1\n')

        asm_file.write(f'\tmovs r4, r14\n')
        asm_file.write(f'\trsbmi r4, r4, #0\t; abs(val)\n')
        asm_file.write(f'\tsub r4, r11, r4\n')
        asm_file.write(f'\tmul r4, r14, r4\n')
        asm_file.write(f'\tmov r4, r4, asr #16\n')
        asm_file.write(f'\tmov r{var-1}, r4, asl #3\n')

    def func_onepole_flt(self, asm_file, var, param_string):
        param_strings=parse("{:d}, {}, {}, {}", param_string)

        val_V=parse("v{:d}", param_strings[1])
        if val_V is None:
            print('WARNING: Expected a var not a const!')
        cutoff_V=parse("v{:d}", param_strings[2])
        cutoff_C=parse("{:d}", param_strings[2])
        mode=parse("{:d}", param_strings[3])[0]

        asm_file.write(f'\tldr r4, [r10, #AK_OPINSTANCE+4*{self._instance}]\t; pole\n')
        asm_file.write(f'\tmov r6, r4, asr #7\n')
        asm_file.write(f'\tmov r14, r{val_V[0]-1}, asr #7\n')

        if cutoff_V is not None:
            asm_file.write(f'\tmul r5, r{cutoff_V[0]-1}, r14\n')
            asm_file.write(f'\tmul r6, r{cutoff_V[0]-1}, r6\n')
        else:
            asm_file.write(f'\tmov r12, #{cutoff_C[0]}\n')
            asm_file.write(f'\tmul r5, r12, r14\n')
            asm_file.write(f'\tmul r6, r12, r6\n')
    
        asm_file.write(f'\tsub r4, r4, r6\n')
        asm_file.write(f'\tadd r4, r4, r5\n')
        self.clamp(asm_file, 5)
        asm_file.write(f'\tstr r4, [r10, #AK_OPINSTANCE+4*{self._instance}]\t; pole\n')

        if mode==0:
            asm_file.write(f'\tmov r{var-1}, r4\n')
        elif mode==1:
            asm_file.write(f'\tsub r{var-1}, r{val_V[0]-1}, r4\n')
            self.clamp(asm_file, var)
        else:
            asm_file.write(f'\tmov r{var-1}, #0\n')

        self._instance+=1

    def func_adsr(self, asm_file, var, param_string):
        params=parse("{:d}, {:d}, {:d}, {:d}, {:d}, {:d}, {:d}", param_string)

        self._adsr_values.append(params)

        attackAmount=params[1]
        decayAmount=params[2]
        sustainLevel=params[3]
        sustainLength=params[4]
        releaseAmount=params[5]
        peak=params[6]

        adsr_instance=len(self._adsr_values)-1

        asm_file.write(f'\tldr r4, [r10, #AK_OPINSTANCE+4*{self._instance}]\t; val\n')
        asm_file.write(f'\tldrb r14, [r10, #AK_OPINSTANCE+4*{self._instance+1}]\t; mode\n')

        asm_file.write(f'\tcmp r14, #ADSR_Decay\n')
        asm_file.write(f'\tbeq ADSR_D_{self._inst_nr}_{self._instance}\n')
        asm_file.write(f'\tcmp r14, #ADSR_Sustain\n')
        asm_file.write(f'\tbeq ADSR_S_{self._inst_nr}_{self._instance}\n')
        asm_file.write(f'\tcmp r14, #ADSR_Release\n')
        asm_file.write(f'\tbeq ADSR_R_{self._inst_nr}_{self._instance}\n\n')

        asm_file.write(f'ADSR_A_{self._inst_nr}_{self._instance}:\t; Attack\n')
        # asm_file.write(f'\tmov r5, #{attackAmount}\n')
        asm_file.write(f'\tldr r5, [r10, #AK_ADSRVALUES+24*{adsr_instance}+4*0]\t; attackAmount\n')
        asm_file.write(f'\tadd r4, r4, r5\n')
        # asm_file.write(f'\tmov r6, #{peak}\n')
        asm_file.write(f'\tldr r6, [r10, #AK_ADSRVALUES+24*{adsr_instance}+4*5]\t; peak\n')
        asm_file.write(f'\tcmp r4, r6\n')
        asm_file.write(f'\tmovge r4, r6\n')
        asm_file.write(f'\tmovge r14, #ADSR_Decay\n')
        asm_file.write(f'\tb ADSR_End_{self._inst_nr}_{self._instance}\n\n')

        asm_file.write(f'ADSR_D_{self._inst_nr}_{self._instance}:\t; Decay\n')
        # asm_file.write(f'\tmov r5, #{decayAmount}\n')
        asm_file.write(f'\tldr r5, [r10, #AK_ADSRVALUES+24*{adsr_instance}+4*1]\t; decayAmount\n')
        asm_file.write(f'\tsub r4, r4, r5\n')
        # asm_file.write(f'\tmov r6, #{sustainLevel}\n')
        asm_file.write(f'\tldr r6, [r10, #AK_ADSRVALUES+24*{adsr_instance}+4*2]\t; sustainLevel\n')
        asm_file.write(f'\tcmp r4, r6\n')
        asm_file.write(f'\tmovle r4, r6\n')
        asm_file.write(f'\tmovle r14, #ADSR_Sustain\n')
        asm_file.write(f'\tb ADSR_End_{self._inst_nr}_{self._instance}\n\n')

        asm_file.write(f'ADSR_S_{self._inst_nr}_{self._instance}:\t; Sustain\n')
        asm_file.write(f'\tldr r5, [r10, #AK_OPINSTANCE+4*{self._instance+2}]\t; SustainCounter\n')
        asm_file.write(f'\tadd r5, r5, #1\n')
        asm_file.write(f'\tstr r5, [r10, #AK_OPINSTANCE+4*{self._instance+2}]\t; SustainCounter\n')
        # asm_file.write(f'\tmov r6, #{sustainLength}\n')
        asm_file.write(f'\tldr r6, [r10, #AK_ADSRVALUES+24*{adsr_instance}+4*3]\t; sustainLength\n')
        asm_file.write(f'\tcmp r5, r6\n')
        asm_file.write(f'\tmovgt r14, #ADSR_Release\n')
        asm_file.write(f'\tb ADSR_End_{self._inst_nr}_{self._instance}\n\n')

        asm_file.write(f'ADSR_R_{self._inst_nr}_{self._instance}:\t; Release\n')
        # asm_file.write(f'\tmov r5, #{releaseAmount}\n')
        asm_file.write(f'\tldr r5, [r10, #AK_ADSRVALUES+24*{adsr_instance}+4*4]\t; releaseAmount\n')
        asm_file.write(f'\tsubs r4, r4, r5\n')
        asm_file.write(f'\tmovle r4, #0\n\n')

        asm_file.write(f'ADSR_End_{self._inst_nr}_{self._instance}:\n')
        asm_file.write(f'\tstr r4, [r10, #AK_OPINSTANCE+4*{self._instance}]\t; val\n')
        asm_file.write(f'\tstrb r14, [r10, #AK_OPINSTANCE+4*{self._instance+1}]\t; mode\n')
        asm_file.write(f'\tmov r{var-1}, r4, asr #8\n')

        self._instance+=3


    def ParseHeader(self):
        while True:
            header=self._akp_file.readline()
            if header != '\n':
                break

        self._extsample_lens=parse("{:d}, {:d}, {:d}, {:d}, {:d}, {:d}, {:d}, {:d}\n", header)
        
        if self._extsample_lens is None:
            print('WARNING: Failed to parse external sample length values.')
        else:
            self._total_ext_smp_len=self._extsample_lens[0]+self._extsample_lens[1]+self._extsample_lens[2]+self._extsample_lens[3]+self._extsample_lens[4]+self._extsample_lens[5]+self._extsample_lens[6]+self._extsample_lens[7]

        self._total_smp_len=0
        self._num_instruments=0
        
        while self._num_instruments < 32:
            def_line=self._akp_file.readline()
            name_delimiter=def_line.find(",")
            name_string=def_line[2:name_delimiter]
            inst_string=def_line[name_delimiter+1:]
            # inst_def=parse("$ {name:S}, {len:d}, {rep_off:d}, {rep_len:d}, {loop:S}\n", def_line)
            inst_def=parse("{len:d}, {rep_off:d}, {rep_len:d}, {loop:S}\n", inst_string)

            if inst_def is None:
                break

            self._num_instruments+=1
            self._total_smp_len+=inst_def['len']

            self._akp_file.readline()       # swallow hash line

            while True:
                cmd_line=self._akp_file.readline()
                cmd_def=parse("v{:d} = {}({});\n", cmd_line)

                if cmd_def is None:
                    break


    def WriteInstruments(self, asm_file):
        while True:
            header=self._akp_file.readline()
            if header != '\n':
                break

        self._inst_nr=0
        self._max_instances=0
        self._max_dvalues=0
        self._max_buffers=0
        self._buffers=0

        self._instruments=[]
        self._adsr_values=[]
        
        while self._inst_nr < 32:
            def_line=self._akp_file.readline()
            #print(def_line)
            name_delimiter=def_line.find(",")
            name_string=def_line[2:name_delimiter]
            inst_string=def_line[name_delimiter+1:]
            # inst_def=parse("$ {name:S}, {len:d}, {rep_off:d}, {rep_len:d}, {loop:S}\n", def_line)
            inst_def=parse("{len:d}, {rep_off:d}, {rep_len:d}, {loop:S}\n", inst_string)

            if inst_def is None:
                break

            self._inst_nr+=1

            self._instruments.append([inst_def['len']])
       
            print(f"Instrument {self._inst_nr} '{name_string}'")  #{inst_def['name']}'")

            asm_file.write(f';----------------------------------------------------------------------------\n')
            asm_file.write(f"; Instrument {self._inst_nr} - '{name_string}'\n") # inst_def['name']}\n")
            asm_file.write(f';----------------------------------------------------------------------------\n\n')

            self._akp_file.readline()       # swallow hash line

            if self._inst_nr==1:
                asm_file.write(f'\tmov r4, #AK_MaxTempBuffers\t; buffers to clear\n')
            else:
                asm_file.write(f'\tmov r4, #{self._buffers}\t; buffers to clear\n')
            asm_file.write(f'\tbl AK_ResetVars\n')
            asm_file.write(f'\tmov r7, #0\t; Sample byte count\n')

            if self._legacy_bugs:
                asm_file.write(f'\tldrb r4, [r8]\n')
                asm_file.write(f'\tstrb r4, [r10, #AK_OVERFLOWSAMPLES+{self._inst_nr-1}]\t; store overflow byte.\n')

            asm_file.write(f'\n\tAK_PROGRESS\n\n')
            asm_file.write(f'Inst{self._inst_nr}Loop:\n')

            if DEBUG_INSTRUMENT==self._inst_nr:
                asm_file.write(f'\tmov r14, #{DEBUG_SAMPLE}\n')
                asm_file.write(f'\tcmp r7, r14\n')
                asm_file.write(f'\tbne .1\n')
                asm_file.write(f'\tmov r7, r7\t; BREAK HERE!\n')
                asm_file.write(f'\t.1:\n')

            self._instance=0
            self._dvalue=0
            self._buffers=0

            while True:
                cmd_line=self._akp_file.readline()
                cmd_def=parse("v{:d} = {}({});\n", cmd_line)

                if cmd_def is None:
                    break

                asm_file.write(f'\t; {cmd_line}')
                if cmd_def[1]=='add':
                    self.func_add(asm_file, cmd_def[0], cmd_def[2])
                elif cmd_def[1]=='mul':
                    self.func_mul(asm_file, cmd_def[0], cmd_def[2])
                elif cmd_def[1]=='osc_saw':
                    self.func_osc_saw(asm_file, cmd_def[0], cmd_def[2])
                elif cmd_def[1]=='sh':
                    self.func_sh(asm_file, cmd_def[0], cmd_def[2])
                elif cmd_def[1]=='osc_tri':
                    self.func_osc_tri(asm_file, cmd_def[0], cmd_def[2])
                elif cmd_def[1]=='enva':
                    self.func_enva(asm_file, cmd_def[0], cmd_def[2])
                elif cmd_def[1]=='envd':
                    self.func_envd(asm_file, cmd_def[0], cmd_def[2])
                elif cmd_def[1]=='osc_sine':
                    self.func_osc_sine(asm_file, cmd_def[0], cmd_def[2])
                elif cmd_def[1]=='osc_pulse':
                    self.func_osc_pulse(asm_file, cmd_def[0], cmd_def[2])
                elif cmd_def[1]=='osc_noise':
                    self.func_osc_noise(asm_file, cmd_def[0], cmd_def[2])
                elif cmd_def[1]=='clone':
                    self.func_clone(asm_file, cmd_def[0], cmd_def[2])
                elif cmd_def[1]=='clone_reverse':
                    self.func_clone_reverse(asm_file, cmd_def[0], cmd_def[2])
                elif cmd_def[1]=='ctrl':
                    self.func_ctrl(asm_file, cmd_def[0], cmd_def[2])
                elif cmd_def[1]=='dly_cyc':
                    self.func_dly_cyc(asm_file, cmd_def[0], cmd_def[2])
                elif cmd_def[1]=='cmb_flt_n':
                    self.func_cmb_flt_n(asm_file, cmd_def[0], cmd_def[2])
                elif cmd_def[1]=='sv_flt_n':
                    self.func_sv_flt_n(asm_file, cmd_def[0], cmd_def[2])
                elif cmd_def[1]=='chordgen':
                    self.func_chordgen(asm_file, cmd_def[0], cmd_def[2])
                elif cmd_def[1]=='reverb':
                    self.func_reverb(asm_file, cmd_def[0], cmd_def[2])
                elif cmd_def[1]=='imported_sample':
                    self.func_imported_sample(asm_file, cmd_def[0], cmd_def[2])
                elif cmd_def[1]=='vol':
                    self.func_vol(asm_file, cmd_def[0], cmd_def[2])
                elif cmd_def[1]=='distortion':
                    self.func_distortion(asm_file, cmd_def[0], cmd_def[2])
                elif cmd_def[1]=='onepole_flt':
                    self.func_onepole_flt(asm_file, cmd_def[0], cmd_def[2])
                elif cmd_def[1]=='adsr':
                    self.func_adsr(asm_file, cmd_def[0], cmd_def[2])
                else:
                    print(f"WARNING: Unimplemented node command '{cmd_def[1]}'")
                    asm_file.write(f"; TODO: Implement node command '{cmd_def[1]}'.\n")
                
                asm_file.write('\n')

            if self._instance > self._max_instances:
                self._max_instances = self._instance

            if self._dvalue > self._max_dvalues:
                self._max_dvalues = self._dvalue

            if self._buffers > self._max_buffers:
                self._max_buffers = self._buffers

            if self._buffers > 0:
                asm_file.write(f'\tsub r9, r9, #2048*4*{self._buffers}\t; reset temp buffer base.\n')

            asm_file.write(f'\tmov r4, r0, asr #8\n')
            asm_file.write(f'\tstrb r4, [r8], #1\n')
            asm_file.write(f'\n\tAK_FINE_PROGRESS\n\n')
            asm_file.write(f'\tadd r7, r7, #1\n')
            asm_file.write(f'\tldr r4, [r10, #AK_SMPLEN+4*{self._inst_nr-1}]\n')
            asm_file.write(f'\tcmp r7, r4\n')
            asm_file.write(f'\tblt Inst{self._inst_nr}Loop\n\n')

            if inst_def['loop']=='Y':
                asm_file.write(f';----------------------------------------------------------------------------\n')
                asm_file.write(f"; Instrument {self._inst_nr} - Loop Generator (Offset: {inst_def['rep_off']} Length: {inst_def['rep_len']})\n")
                asm_file.write(f';----------------------------------------------------------------------------\n\n')

                if inst_def['rep_len'] <= 2:
                    print(f'WARNING: Expected loopgen length to be > 2!\n')

                if self._legacy_bugs:
                    asm_file.write(f"\tmov r7, #{inst_def['rep_len']}\n")
                else:
                    asm_file.write(f"\tmov r7, #{inst_def['rep_len'] - 2}\t; BUG FIX: -2 from length to avoid reading beyond end of buffer\n")
                
                asm_file.write(f'\tldr r6, [r10, #AK_SMPADDR+4*{self._inst_nr-1}]\n')
                asm_file.write(f"\tadd r6, r6, #{inst_def['rep_off']+2}\t; src1 (additional +2 offset in AmigaKlangGUI because Amiga)\n\n")

                asm_file.write(f'\tsub r4, r6, r7\t; src2\n')
                # asm_file.write(f'\tmov r0, r11, lsl #8\t; 32767<<8\n')
                # asm_file.write(f'\tmov r1, r7\n')
                # asm_file.write(f'\tbl divide\n')
                # asm_file.write(f'\tmov r5, r0\t; delta = divs.w(32767<<8,repeat_length)\n')
                delta=int((32767<<8)/(inst_def['rep_len']-2))
                asm_file.write(f"\tmov r5, #{delta}\t; (32767<<8)/{inst_def['rep_len']-2}\n")
                asm_file.write(f'\tmov r14, #0\t; rampup\n')
                asm_file.write(f'\tmov r12, r11, lsl #8\t; rampdown\n')
                asm_file.write(f"LoopGen_{self._inst_nr}:\n")

                if DEBUG_INSTRUMENT==self._inst_nr:
                    asm_file.write(f"\tmov r2, #{inst_def['rep_len'] - (DEBUG_SAMPLE-inst_def['rep_off']-2)}\n")
                    asm_file.write(f'\tcmp r7, r2\n')
                    asm_file.write(f'\tbne .1\n')
                    asm_file.write(f'\tmov r7, r7\t; BREAK HERE!\n')
                    asm_file.write(f'\t.1:\n')

                asm_file.write(f'\tmov r3, r14, lsr #8\n')
                asm_file.write(f'\tmov r2, r12, lsr #8\n')

                asm_file.write(f'\tldrb r1, [r6]\n')
                asm_file.write(f'\tmov r1, r1, asl #24\n')
                asm_file.write(f'\tmov r1, r1, asr #24\n')

                asm_file.write(f'\tldrb r0, [r4], #1\n')
                asm_file.write(f'\tmov r0, r0, asl #24\n')
                asm_file.write(f'\tmov r0, r0, asr #24\n')

                # Actual loopgen code in synthnodes.c:
                # asm_file.write(f'\tmul r0, r3, r0\n')
                # asm_file.write(f'\tmla r0, r1, r2, r0\n')
                # asm_file.write(f'\tmov r0, r0, lsr #15\n')
                # TODO: Make this a script option?

                # Actual loopgen code in AmigaKlangGUI:
                asm_file.write(f'\tmul r0, r3, r0\n')
                asm_file.write(f'\tmov r0, r0, asr #7\n')
                asm_file.write(f'\tmul r1, r2, r1\n')
                asm_file.write(f'\tadd r0, r0, r1, asr #7\n')
                asm_file.write(f'\tmov r0, r0, asr #8\n')

                asm_file.write(f'\tstrb r0, [r6], #1\n')

                asm_file.write(f'\tadd r14, r14, r5\n')
                asm_file.write(f'\tsub r12, r12, r5\n')
                asm_file.write(f'\n\tAK_FINE_PROGRESS\n\n')
                asm_file.write(f'\tsubs r7, r7, #1\n')
                asm_file.write(f"\tbne LoopGen_{self._inst_nr}\n\n")

        print(f'{self._inst_nr} total instruments.')
        assert(self._inst_nr==self._num_instruments)

        print(f'{self._total_smp_len} total sample size.')
        print(f'{self._total_ext_smp_len} external sample size.')

        asm_file.write('; ============================================================================\n\n')

        asm_file.write(f'.if AK_CLEAR_FIRST_2_BYTES\n')
        asm_file.write(f'\t; Clear first 2 bytes of each sample\n')
        asm_file.write(f'\tadr r4, AK_SmpAddr\n')
        asm_file.write(f'\tmov r7, #{self._num_instruments}\t; Num instruments.\n')
        asm_file.write(f'\tmov r0, #0\n')
        asm_file.write(f'.0:\n')
        asm_file.write(f'\tldr r6, [r4], #4\n')
        asm_file.write(f'\tstrb r0, [r6]\n')
        asm_file.write(f'\tstrb r0, [r6, #1]\n')
        asm_file.write(f'\tsubs r7, r7, #1\n')
        asm_file.write(f'\tbne .0\n')
        asm_file.write(f'.endif\n\n')

        asm_file.write('\tldr pc, [sp], #4\n\n')


    def WriteVars(self, asm_file):
        asm_file.write('; ============================================================================\n\n')

        asm_file.write('AK_ResetVars:\n')

        asm_file.write(f'\tmov r0, #0\n')
        asm_file.write(f'\tmov r1, #0\n')
        asm_file.write(f'\tmov r2, #0\n')
        asm_file.write(f'\tmov r3, #0\n')

        asm_file.write(f'\tmovs r4, r4, lsl #9\t; num_buffers * 2048 * 4 / 16 = num_buffers * 512\n')
        asm_file.write(f'\tbeq .2\n')
        asm_file.write(f'\tmov r6, r9\t; Clear temp buffers (delay loop).\n')
        asm_file.write(f'.1:\n')
        asm_file.write('\tstmia r6!, {r0-r3}\n')
        asm_file.write('\tsubs r4, r4, #1\n')
        asm_file.write('\tbne .1\n')

        asm_file.write(f'.2:\n')
        asm_file.write(f'\tadd r6, r10, #AK_OPINSTANCE\n')
        asm_file.write(f'\t.rept {self._max_instances}\t; Max OpInstance values.\n')
        asm_file.write(f'\tstr r0, [r6], #4\n')
        asm_file.write(f'\t.endr\n')
        if self._max_dvalues > 0:
            asm_file.write(f'\tmov r4, r11, lsl #16\t; 32767<<16\n')
            asm_file.write(f'\t.rept {self._max_dvalues}\t; Max envd values.\n')
            asm_file.write(f'\tstr r4, [r6], #4\n')
            asm_file.write(f'\t.endr\n')
        else:
            asm_file.write(f'\t; No envd values to reset.\n')
        asm_file.write(f'\tmov pc, lr\n\n')

        asm_file.write('; ============================================================================\n\n')

        asm_file.write('AK_Vars:\n')
        asm_file.write('AK_SmpLen:\n')
        i=1
        for inst in self._instruments:
            asm_file.write(f'\t.long 0x{inst[0]:08x}\t; Instrument {i} Length\n')
            i+=1

        for i in range(len(self._instruments)+1,32):
            asm_file.write(f'\t.long 0x00000000\t; Instrument {i} Length\n')

        asm_file.write('AK_ExtSmpLen:\n')
        for i in range(1,9):
            asm_file.write(f'\t.long 0x{self._extsample_lens[i-1]:08x}\t; External Sample {i} Length\n')

        asm_file.write('AK_NoiseSeeds:\n')
        asm_file.write('\t.long 0x67452301\n\t.long 0xefcdab89\n\t.long 0x00000000\n')

        asm_file.write('AK_SmpAddr:\n')
        asm_file.write('\t.skip AK_MaxInstruments*4\n')

        asm_file.write('AK_ExtSmpAddr:\n')
        asm_file.write('\t.skip AK_MaxExtSamples*4\n')

        asm_file.write('AK_OpInstance:\n')
        asm_file.write(f'\t.skip {self._max_instances}*4\n')

        asm_file.write('AK_EnvDValue:\n\t; NB. Must follow AK_OpInstance!\n')
        if self._max_dvalues > 0:
            asm_file.write(f'\t.skip {self._max_dvalues}*4\n')

        asm_file.write('AK_ADSRValues:\n')
        if len(self._adsr_values) > 0:
            for params in self._adsr_values:
                attackAmount=params[1]
                decayAmount=params[2]
                sustainLevel=params[3]
                sustainLength=params[4]
                releaseAmount=params[5]
                peak=params[6]
                asm_file.write(f'\t.long {attackAmount}\t; attackAmount\n')
                asm_file.write(f'\t.long {decayAmount}\t; decayAmount\n')
                asm_file.write(f'\t.long {sustainLevel}\t; sustainLevel\n')
                asm_file.write(f'\t.long {sustainLength}\t; sustainLength\n')
                asm_file.write(f'\t.long {releaseAmount}\t; releaseAmount\n')
                asm_file.write(f'\t.long {peak}\t; peak\n')

        if self._legacy_bugs:
            asm_file.write('AK_CmbCounts:\n')
            asm_file.write(f'\t.skip 24*4\n')

            asm_file.write('AK_DlyCounts:\n')
            asm_file.write(f'\t.skip 16*4\n')

            asm_file.write('AK_OverflowSamples:\n')
            asm_file.write('\t.skip AK_MaxInstruments\n')
            asm_file.write('\t.p2align 2\n')

        asm_file.write('\n; ============================================================================\n\n')

        asm_file.write(f'.equ AK_MaxTempBuffers, {self._max_buffers}\n')
        asm_file.write(f'.equ AK_TempBufferSize, {self._max_buffers*2048*4}\n')

        asm_file.write('\n; ============================================================================\n')


    def WriteHeader(self, asm_file):
        # Standard header.
        asm_file.write('; ============================================================================\n')
        asm_file.write('; Generated with Aklang2Acorn.py v1.0, by kieran/Bitshifters 2024.\n')
        asm_file.write(f"; Based on Alcatraz Amigaklang rendering core. (c) Jochen 'Virgill' Feldkötter 2020-2024.\n")
        asm_file.write("; And Aklang2Asm by Dan/Lemon. 2021-2022.\n")
        asm_file.write(f"; Input Aklang script = '{src}'\n")
        if self._legacy_bugs:
            asm_file.write(f'; => Implements workarounds for legacy bugs (buffer overrun and loopgen).\n')
        asm_file.write(';\n')
        asm_file.write("; Define macro 'AK_PROGRESS' for whatever per-instrument progress callback you require (if any).\n")
        asm_file.write("; Define macro 'AK_FINE_PROGRESS' for whatever per-byte progress callback you require (if any).\n")
        asm_file.write("; Define symbol 'AK_CLEAR_FIRST_2_BYTES' to true to zero out the first two bytes of each sample, Amiga style.\n")
        asm_file.write("; Call 'AK_Generate' with the registers listed below.\n")
        asm_file.write('; ============================================================================\n\n')

        asm_file.write('.equ AK_MaxInstruments,\t\t31\n')
        asm_file.write('.equ AK_MaxExtSamples,\t\t8\n\n')

        asm_file.write('.equ AK_LPF,\t\t\t\t0\n')
        asm_file.write('.equ AK_HPF,\t\t\t\t1\n')
        asm_file.write('.equ AK_BPF,\t\t\t\t2\n\n')

        asm_file.write('.equ AK_CHORD1,\t\t\t\t0\n')
        asm_file.write('.equ AK_CHORD2,\t\t\t\t1\n')
        asm_file.write('.equ AK_CHORD3,\t\t\t\t2\n\n')

        asm_file.write('.equ ADSR_Attack,\t\t\t0\n')
        asm_file.write('.equ ADSR_Decay,\t\t\t1\n')
        asm_file.write('.equ ADSR_Sustain,\t\t\t2\n')
        asm_file.write('.equ ADSR_Release,\t\t\t3\n\n')

        asm_file.write('.equ AK_SMPLEN,\t\t\t\t(AK_SmpLen-AK_Vars)\n')
        asm_file.write('.equ AK_EXTSMPLEN,\t\t\t(AK_ExtSmpLen-AK_Vars)\n')
        asm_file.write('.equ AK_NOISESEEDS,\t\t\t(AK_NoiseSeeds-AK_Vars)\n')
        asm_file.write('.equ AK_SMPADDR,\t\t\t(AK_SmpAddr-AK_Vars)\n')
        asm_file.write('.equ AK_EXTSMPADDR,\t\t\t(AK_ExtSmpAddr-AK_Vars)\n')
        asm_file.write('.equ AK_OPINSTANCE,\t\t\t(AK_OpInstance-AK_Vars)\n')
        asm_file.write('.equ AK_ENVDVALUE,\t\t\t(AK_EnvDValue-AK_Vars)\n')
        asm_file.write('.equ AK_ADSRVALUES,\t\t\t(AK_ADSRValues-AK_Vars)\n\n')

        if self._legacy_bugs:
            asm_file.write('.equ AK_CMBCOUNTS,\t\t\t(AK_CmbCounts-AK_Vars)\n')
            asm_file.write('.equ AK_DLYCOUNTS,\t\t\t(AK_DlyCounts-AK_Vars)\n')
            asm_file.write('.equ AK_OVERFLOWSAMPLES,\t(AK_OverflowSamples-AK_Vars)\t\n\n')

        asm_file.write(f'.equ AK_SMP_LEN,\t\t\t{self._total_smp_len}\n')
        asm_file.write(f'.equ AK_EXT_SMP_LEN,\t\t{self._total_ext_smp_len}\n\n')

        asm_file.write('; ============================================================================\n')
        asm_file.write('; R8 = Sample Buffer Start Address (AK_SMP_LEN bytes)\n')
        asm_file.write('; R9 = Temporary Work Buffer Address (AK_MaxTempBuffers * 2048 * 4 = AK_TempBufferSize bytes) (can be freed after sample rendering complete)\n')
        asm_file.write('; R10 = External Samples Address (can be freed after sample rendering complete)\n')
        asm_file.write('; ============================================================================\n\n')
        asm_file.write('AK_Generate:\n')
        asm_file.write('\tstr lr, [sp, #-4]!\n\n')

        asm_file.write(f'\t; Create sample & external sample base addresses\n')
        asm_file.write(f'\tadr r4, AK_SmpAddr\n')
        asm_file.write(f'\tadr r5, AK_SmpLen\n')
        asm_file.write(f'\tmov r7, #AK_MaxInstruments\n')
        asm_file.write(f'\tmov r0, r8\n')
        asm_file.write(f'SmpAdrLoop:\n')
        asm_file.write(f'\tstr r0, [r4], #4\n')
        asm_file.write(f'\tldr r1, [r5], #4\n')
        asm_file.write(f'\tadd r0, r0, r1\n')
        asm_file.write(f'\tsubs r7, r7, #1\n')
        asm_file.write(f'\tbne SmpAdrLoop\n')
        asm_file.write(f'\tmov r7, #AK_MaxExtSamples\n')
        asm_file.write(f'\tadr r4, AK_ExtSmpAddr\n')
        asm_file.write(f'\tadr r5, AK_ExtSmpLen\n')
        asm_file.write(f'\tmov r0, r10\n')
        asm_file.write(f'ExSmpAdrLoop:\n')
        asm_file.write(f'\tstr r0, [r4], #4\n')
        asm_file.write(f'\tldr r1, [r5], #4\n')
        asm_file.write(f'\tadd r0, r0, r1\n')
        asm_file.write(f'\tsubs r7, r7, #1\n')
        asm_file.write(f'\tbne ExSmpAdrLoop\n\n')

        asm_file.write(f'.if AK_EXT_SMP_LEN > 0\n')
        asm_file.write(f'\t; Convert external samples from stored deltas\n')
        asm_file.write(f'\tmov r7, #AK_EXT_SMP_LEN\n')
        asm_file.write(f'\tmov r6, r10\n')
        asm_file.write(f'\tmov r0, #0\n')
        asm_file.write(f'DeltaLoop:\n')
        asm_file.write(f'\tldrb r1, [r6]\n')
        asm_file.write(f'\tmov r1, r1, asl #24\n')
        asm_file.write(f'\tmov r1, r1, asr #24\n')
        asm_file.write(f'\tadd r0, r0, r1\n')
        asm_file.write(f'\tmov r0, r0, asl #24\n')
        asm_file.write(f'\tmov r0, r0, asr #24\n')
        asm_file.write(f'\tstrb r0, [r6], #1\n')
        asm_file.write(f'\tsubs r7, r7, #1\n')
        asm_file.write(f'\tbne DeltaLoop\n')
        asm_file.write(f'.endif\n\n')

        asm_file.write('; ============================================================================\n')
        asm_file.write('; r0 = v1 (final sample value)\n')
        asm_file.write('; r1 = v2\n')
        asm_file.write('; r2 = v3\n')
        asm_file.write('; r3 = v4\n')
        asm_file.write('; r4 = temp\n')
        asm_file.write('; r5 = temp\n')
        asm_file.write('; r6 = temp\n')
        asm_file.write('; r7 = Sample byte count\n')
        asm_file.write('; r8 = Sample Buffer Start Address\n')
        asm_file.write('; r9 = AK_MaxTempBuffers*2048 word (>=65536 byte) Temporary Work Buffer Address (can be freed after sample rendering complete)\n')
        asm_file.write('; r10 = Base of AK_Vars\n')
        asm_file.write('; r11 = 36767 (0x7fff)\n')
        asm_file.write('; r12 = temp\n')
        asm_file.write('; r14 = temp\n')
        asm_file.write('; ============================================================================\n\n')

        asm_file.write(f'\tadr r10, AK_Vars\n')
        asm_file.write(f'\tmov r11, #32767\t; const\n\n')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("input", help="Amigaklang exe script.")
    parser.add_argument("-o", "--output", metavar="<output>", help="Write ARM asm file to <output> (default is 'archieklang.asm')")
    parser.add_argument("-v", "--verbose", action="store_true", help="Print all the debugs")
    parser.add_argument("-b", "--bugs", action="store_true", help="Support legacy bugs")
    args = parser.parse_args()

    global g_verbose
    g_verbose=args.verbose

    src = args.input
    # check for missing files
    if not os.path.isfile(src):
        print(f"ERROR: File '{src}' not found")
        sys.exit(1)

    dst = args.output
    if dst == None:
        dst = "archieklang.asm"

    akp_file = open(src, 'r')
    asm_file = open(dst, 'w')

    # Output Archie ARM asm.
    parser = AkpParser(akp_file, args.bugs)
    parser.ParseHeader()
    parser.WriteHeader(asm_file)
    akp_file.seek(0)
    parser.WriteInstruments(asm_file)
    parser.WriteVars(asm_file)

    print(f"Wrote {asm_file.tell()} bytes of ASM to '{dst}'.\n")

    asm_file.close()
