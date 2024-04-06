short abs(short val) {
	val = val<0?-val:val; 
	return val;
}

inline short clamp (int val){
	val = val>32767?32767:val; val = val<-32768?-32768:val; 
	return val;
}

short distortion(int val, UBYTE gain){
	int temp;
	short res;
	val = clamp(val * gain >> 5);
	val >>= 1;                                 
	temp = mulsw(val, 32767 - abs(val));
	res = temp >> 16;
	res <<= 3;
	return res;
}


inline short vol(short val, UBYTE gain){
	return mulsw(val, gain) >> 7;
}

short osc_saw (BYTE instance, short freq, UBYTE gain){
	counter_saw[instance]+=freq; 
	return vol(counter_saw[instance],gain);		
}
/*
short sh(BYTE instance, short val1, UBYTE step){
	short step2 = mulsw(step, step) >> 2;
	if (counter_sh[instance] == 0) buffer_sh[instance] = val1;
	if (counter_sh[instance] == step2) counter_sh[instance] = -1; 
	counter_sh[instance] += 1;
	return buffer_sh[instance];
}
*/

// new s&h from DAN
short sh(BYTE instance, short val1, UBYTE step)
{
	short step2 = mulsw(step, step) >> 2;
	counter_sh[instance]--;
	if (counter_sh[instance] < 0)
	{
		buffer_sh[instance] = val1;
		counter_sh[instance] = step2;
	}
	return buffer_sh[instance];
}


short osc_tri (BYTE instance, short freq, UBYTE gain){
	short buf = counter_tri[instance]+=freq; if (buf < 0) buf = 65535 - buf;		
	buf -= 16384; buf <<= 1; 
	return vol(buf,gain);								
}

short osc_sine (BYTE instance, short freq, UBYTE gain){
	int temp;
	short res; 
	short buf = counter_sine[instance]+=freq;
	buf -= 16384; 
	temp= mulsw(buf, 32767-abs(buf));	
	res =temp>>16; 
	res<<=3; 
	return vol(res,gain);								
}

short osc_pulse (BYTE instance, short freq, UBYTE gain, UBYTE dutycycle){
	short buf = counter_pulse[instance]+=freq; 	
	if (buf<(dutycycle-63)<<9) buf= -32768;	else buf = 32767; 
	return vol(buf,gain);							
}

short osc_noise (int sample, UBYTE gain) {
	static int g_x1 = 0x67452301; static int g_x2 = 0xefcdab89; static int g_x3 = 0;			
 	g_x1 ^= g_x2; g_x3 += g_x2; g_x2 += g_x1; short buf = g_x3; 
	return vol(buf,gain);	 
}

short enva (int sample, BYTE attack, BYTE sustain, UBYTE gain){
   	short t= decayTable[attack]; 
	//int buf = mulsw(sample, t) >> 8;
	int buf = ((sample* t) >> 8);
	if (buf>32767) buf = 32767; 
	return vol(buf,gain);
}

short envd (int sample, BYTE decay, BYTE sustain, UBYTE gain){
	short sustain16= sustain<<8; short t= decayTable[decay];
	//int buf = 32767 - (mulsw(sample, t) >> 8);
	int buf = 32767 - ((sample * t) >> 8);
   	if (buf <= sustain16) buf= sustain16; 
	return vol(buf,gain); 
}

inline short add (short val1, short val2){
	return clamp(val1 + val2);
}

inline short mul (short val1, short val2){
	return mulsw(val1, val2) >> 15;
}

short dly_cyc(BYTE instance, short val, short delay, UBYTE gain){ 
	if (delay > 2047) delay = 2047;
	static short i[16]; buffern[instance][i[instance]] = vol(val,gain);
	if (++i[instance]>=delay) i[instance]=0; 
	return buffern[instance][i[instance]];	
}

short cmb_flt_n (BYTE instance, short val, short delay, UBYTE feedback, UBYTE gain){
	if (delay > 2047) delay = 2047;
	static short i[24];					
	buffern[instance][i[instance]] = add(val, (vol(buffern[instance][i[instance]], feedback)));
	short output = buffern[instance][i[instance]]; if (++i[instance]>=delay) i[instance]=0; 
	return vol(output, gain);
}

short reverb (short val, UBYTE feedback, UBYTE gain){
	int buf = cmb_flt_n (16, val, 557, feedback,gain); buf += cmb_flt_n (17, val, 593, feedback,gain);		
	buf += cmb_flt_n (18, val, 641, feedback,gain); buf += cmb_flt_n (19, val, 677, feedback,gain);			 
	buf += cmb_flt_n (20, val, 709, feedback,gain); buf += cmb_flt_n (21, val, 743, feedback,gain);			 
	buf += cmb_flt_n (22, val, 787, feedback,gain); buf += cmb_flt_n (23, val, 809, feedback,gain); 
	return clamp(buf);
}

inline BYTE ctrl (short val){
	return (val>>9)+64;
}

short sv_flt_n (BYTE instance, short val, short cutoff, UBYTE resonance, BYTE mode){
   short* buffer = filterBuffer + (instance << 2);
   short lpf = buffer[0]; short hpf = buffer[1]; short bpf = buffer[2];
   lpf= clamp( lpf + (mulsw(bpf>>7, cutoff)) );
   hpf= clamp( val - lpf - (mulsw(bpf>>7, resonance)) );
   bpf= clamp( bpf + (mulsw(hpf>>7, cutoff)) );
   buffer[0] = lpf; buffer[1] = hpf; buffer[2] = bpf;
   switch (mode) {
      case 0: return lpf; break;
      case 1: return hpf; break;
      case 2: return bpf; break;
      case 3: return clamp(hpf + bpf); break;

   }
   return 0;
}

short onepole_flt(BYTE instance, short val, BYTE cutoff, BYTE mode){
	short* buffer = filterBuffer + (instance << 2);
	short pole = buffer[3]; 
	pole           = clamp(pole - (mulsw(pole >> 7, cutoff)) + (mulsw(val >> 7, cutoff)));
	buffer[3] = pole;
	switch (mode) {
	case 0: return pole; break;
	case 1: return (val-pole); break;
	}
	return 0;
}

short adsr(BYTE instance, int attackAmount, int decayAmount, int sustainLevel, int sustainLength, int releaseAmount, int peak){
	int val = ADSR_Value[instance];
	switch (ADSR_Mode[instance]){
	case 0:			// Attack
		val += attackAmount; if (val >= peak) { val = peak; ADSR_Mode[instance] = 1; } break;
	case 1:			// Decay
		val -= decayAmount; if (val <= sustainLevel) { val = sustainLevel; ADSR_Mode[instance] = 2; } break;
	case 2:			// Sustain
		ADSR_SustainCounter[instance]++; if (ADSR_SustainCounter[instance] > sustainLength) { ADSR_Mode[instance] = 3; } break;
	case 3:			// Release
		val -= releaseAmount; if (val < 0) { val = 0; } break;
	}
	ADSR_Value[instance] = val;
	return val >> 8;
}

short chordgen (int sample, void* BaseAdr, BYTE n1, BYTE n2, BYTE n3, UBYTE shift){
	int buf = 							*(BYTE*)(BaseAdr+sample)<<7;				
	if(n1==1 ||n2==1 ||n3==1) 	buf += 	*(BYTE*)(shift+BaseAdr+((mulsw(sample,271))>>8))<<7;			
	if(n1==2 ||n2==2 ||n3==2) 	buf += 	*(BYTE*)(shift+BaseAdr+((mulsw(sample,287))>>8))<<7;
	if(n1==3 ||n2==3 ||n3==3) 	buf += 	*(BYTE*)(shift+BaseAdr+((mulsw(sample,304))>>8))<<7;				
	if(n1==4 ||n2==4 ||n3==4) 	buf += 	*(BYTE*)(shift+BaseAdr+((mulsw(sample,322))>>8))<<7;
	if(n1==5 ||n2==5 ||n3==5) 	buf += 	*(BYTE*)(shift+BaseAdr+((mulsw(sample,342))>>8))<<7;			
	if(n1==6 ||n2==6 ||n3==6) 	buf += 	*(BYTE*)(shift+BaseAdr+((mulsw(sample,362))>>8))<<7;
	if(n1==7 ||n2==7 ||n3==7) 	buf += 	*(BYTE*)(shift+BaseAdr+((mulsw(sample,383))>>8))<<7;
	if(n1==8 ||n2==8 ||n3==8) 	buf += 	*(BYTE*)(shift+BaseAdr+((mulsw(sample,203))>>7))<<7;				
	if(n1==9 ||n2==9 ||n3==9) 	buf += 	*(BYTE*)(shift+BaseAdr+((mulsw(sample,215))>>7))<<7;				
	if(n1==10||n2==10||n3==10) 	buf += 	*(BYTE*)(shift+BaseAdr+((mulsw(sample,228))>>7))<<7;			
	if(n1==11||n2==11||n3==11) 	buf += 	*(BYTE*)(shift+BaseAdr+((mulsw(sample,483))>>8))<<7;
	if(n1==12||n2==12||n3==12) 	buf += 	*(BYTE*)(shift+BaseAdr+(sample<<1))<<7;			
	return clamp(buf);
}	




void loopgen(WORD repeat_length, WORD repeat_offset, void* BaseAdr)
{
	int smp;
	BYTE* src1 = BaseAdr + repeat_offset;
	BYTE* src2 = BaseAdr + repeat_offset - repeat_length;
	int delta = divsw((32767 << 8), repeat_length);
	int rampup = 0;
	int rampdown = 32767<<8;
	for (smp = 0; smp<repeat_length; smp++)
	{
		short a = (rampup >> 8);  
		short b = (rampdown >> 8);	
		BYTE s1 = src1[smp];
		BYTE s2 = src2[smp];
		BYTE blend = (mulsw(s1, b) + mulsw(s2, a)) >> 15;
		src1[smp] = blend;
		rampup += delta;
		rampdown -= delta;
	}
}


__attribute__((optimize("no-tree-loop-distribute-patterns"))) 
void clr_buf(){
	for (short l=0;l<16;l++)
	{
		buffer_sh[l]=0;
		counter_saw[l]=0;
		counter_sh[l]=0;
		counter_tri[l]=0;
		counter_sine[l]=0;
		counter_pulse[l]=0;
		ADSR_Value[l]=0;
		ADSR_Mode[l]=0;
		ADSR_SustainCounter[l]=0;
	}
	for (short l = 0; l < 64; l++)
	{
		filterBuffer[l]=0;
	}
	for (short l = 0; l < 24; l++)
	{
		for (short j = 0; j < 2048; j++)
		{
			buffern[l][j] = 0;
		}
	}

}

