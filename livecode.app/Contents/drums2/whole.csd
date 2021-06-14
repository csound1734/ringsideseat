<CsoundSynthesizer>
<CsOptions>
-odac -d -m195
</CsOptions>
<CsInstruments> 
; These must all match the host as printed when Csound starts.
sr          =           48000
ksmps       =           128
nchnls      =           2
nchnls_i    =           1

/* ======== drum instruments by Istvan Varga, Mar 10 2002 ======== */

	seed 0

/* ----------------------- global variables ----------------------- */

giflen	=  131072	/* table length in samples	*/
giovr	=  4		/* oversample			*/
gibwd	=  24000	/* max. bandwidth in Hz		*/
gitmpfn	=  99		/* tmp ftable number		*/

; spatializer parameters

gisptd	=  0.5		/* unit circle distance (see spat3d manual)  */
gisptf	=  225		/* room table number (0: no room simulation) */
gisptm	=  2		/* spat3di mode (see manual)		     */

gisptx	=  0.2		/* extra time for room echoes		     */

gidsts	=  0.35		/* distance scale			     */

ga0	init 0		; mono output
ga1	init 0		; spat3di out 1
ga2	init 0		; spat3di out 2
ga3	init 0		; spat3di out 3
ga4	init 0		; spat3di out 4

; mono output file name (for external convolve unit)

#define SNDFL_MONO # "mono_out.pcm" #

/* ---------------------- some useful macros ---------------------- */

; spatialize and send output

#define SPAT_OUT #

a1	rnd31 0.000001 * 0.000001 * 0.000001 * 0.000001, 0, 0
a0	=  a0 + a1

iX	=  iX * gidsts
iY	=  iY * gidsts
iZ	=  iZ * gidsts

a1, a2, a3, a4	spat3di a0, iX, iY, iZ, gisptd, gisptf, gisptm

	vincr ga0, a0
	vincr ga1, a1
	vincr ga2, a2
	vincr ga3, a3
	vincr ga4, a4

#

; convert velocity to amplitude

#define VELOC2AMP(VELOCITY'MAXAMP) # (($MAXAMP) * (0.0039 + ($VELOCITY) * ($VELOCITY) / 16192)) #

; convert MIDI note number to frequency

#define MIDI2CPS(NOTNUM) # (440 * exp(log(2) * (($NOTNUM) - 69) / 12)) #

; power of two number greater than x

#define POW2CEIL(P2C_X) # (int(0.5 + exp(log(2) * int(1.01 + log($P2C_X) / log(2))))) #

; semitones to frequency ratio

#define NOTE2FRQ(XNOTE) # (exp(log(2) * ($XNOTE) / 12)) #

; frequency to table number

#define CPS2FNUM(XCPS'BASE_FNUM) # int(69.5 + ($BASE_FNUM) + 12 * log(($XCPS) / 440) / log(2)) #

/* ---------------- constants ---------------- */

#define PI	# 3.14159265 #
#define TWOPI	# (2 * 3.14159265) #

; ---- instr 1: render tables for cymbal instruments ----

	instr 1

ifn	=  p4		/* ftable number		*/
inumh	=  p5		/* number of partials		*/
iscl	=  p6		/* amp. scale			*/
itrns	=  p7		/* transpose (in semitones)	*/
isd	=  p8		/* random seed (1 to 2^31 - 2)	*/
idst	=  p9		/* amplitude distribution	*/

imaxf	=  $NOTE2FRQ(itrns) * gibwd		; max. frequency
itmp	rnd31 1, 0, isd				; initialize seed

; create empty table for parameters

ifln	=  $POW2CEIL(3 * inumh)
itmp	ftgen gitmpfn, 0, ifln, -2, 0

i1	=  0
l01:
iamp	rnd31 1, idst, 0	; amplitude
icps	rnd31 imaxf, 0, 0	; frequency
iphs	rnd31 1, 0, 0		; phase
iphs	=  abs(iphs)
; cut off partials with too high frequency
iamp	=  (icps > (sr * 0.5) ? 0 : iamp)
iphs	=  (icps > (sr * 0.5) ? 0 : iphs)
icps	=  (icps > (sr * 0.5) ? 0 : icps)
; write params to table
	tableiw iamp, i1 * 3 + 0.25, gitmpfn
	tableiw icps, i1 * 3 + 1.25, gitmpfn
	tableiw iphs, i1 * 3 + 2.25, gitmpfn
i1	=  i1 + 1
	if (i1 < (inumh - 0.5)) igoto l01

; render table

ifln	=  giflen * giovr + 0.25	; length with oversample
itmp	ftgen ifn, 0, ifln, -33, gitmpfn, inumh, iscl, -(giovr)

	endin


/* ---- instr 10: cymbal ---- */

	instr 10

ilnth	=  p3		/* note length				     */
ifn	=  p4		/* function table with instrument parameters */
ivel	=  p5		/* velocity (0 - 127)			     */

iscl	table  0, ifn	; amplitude scale
idel	table  1, ifn	; delay
irel	table  2, ifn	; release time
iX	table  3, ifn	; X
iY	table  4, ifn	; Y
iZ	table  5, ifn	; Z
ixfn	table  6, ifn	; input table
iwfn	table  7, ifn	; window table
igdurs	table  8, ifn	; start grain duration in seconds
igdurt	table  9, ifn	; grain druaton envelope half-time
igdure	table 10, ifn	; end grain duration
iovrlp	table 11, ifn	; number of overlaps
iEQfs	table 12, ifn	; EQ start frequency
iEQft	table 13, ifn	; EQ frequency envelope half-time
iEQfe	table 14, ifn	; EQ end frequency
iEQls	table 15, ifn	; EQ start level (Q is level * 0.7071)
iEQlt	table 16, ifn	; EQ level envelope half-time
iEQle	table 17, ifn	; EQ end level
ihpf	table 18, ifn	; highpass frequency
ilpf	table 19, ifn	; lowpass frequency
idec	table 20, ifn	; decay env. half-time (n.a. in reverse mode)
irvmod	table 21, ifn	; reverse cymbal mode (0: on, 1: off)
idel2	table 22, ifn	; delay time for chorus effect
ilvl1	table 23, ifn	; non-delayed signal level
ilvl2	table 24, ifn	; delayed signal level

ixtime	=  gisptx + idel + irel + idel2		; expand note duration
p3	=  p3 + ixtime

; release envelope

aenv1	linseg 1, ilnth, 1, irel, 0, 1, 0
aenv1	=  aenv1 * aenv1

; output amplitude
iamp	=  $VELOC2AMP(ivel'iscl)
; grain duration
kgdur	port igdure, igdurt, igdurs
; 4 * sr = 192000Hz (sample rate of input file)
a1	grain3	giovr * sr / ftlen(ixfn), 0.5, 0, 0.5,		      \
		kgdur, iovrlp / kgdur, iovrlp + 2,		      \
		ixfn, iwfn, 0, 0, 0, 16

; filters

kEQf	port iEQfe, iEQft, iEQfs
kEQl	port iEQle, iEQlt, iEQls
a1	pareq a1, kEQf, kEQl, kEQl * 0.7071, 0
a1	butterhp a1, ihpf
a1	butterlp a1, ilpf

; amp. envelope

aenv2	expon 1, idec, 1 - 0.5 * irvmod
aenv3	linseg irvmod, ilnth, 1, 1, 1
a1	=  a1 * iamp * aenv1 * aenv2 * (aenv3 * aenv3)

; delays

a2	delay a1 * ilvl2, idel2
a0	delay a2 + a1 * ilvl1, idel

$SPAT_OUT

	endin

/* ---------------------- instr 20: bass drum ---------------------- */

	instr 20

; +------------+             +------------+     +------------+
; | oscillator |--->---+-->--| highpass 1 |-->--| bandpass 1 |-->--+
; +------------+       |     +------------+     +------------+     |
;                      |                                           V
;          +-----<-----+                        +-------------+    |
;          |           |              +----<----| "allpass" 1 |----+
;          |           V              |         +-------------+
;          |           |              |
;          |    +------------+      +---+       +-----------------+
;          |    | highpass 2 |      | + |--->---| output highpass |--+
;          |    +------------+      +---+       +-----------------+  |
;          |           |              |                              V
;          |           V              ^         +----------------+   |
;          |           |              |         | output lowpass |-<-+
;          |         +---+     +------------+   +----------------+
;          +---->----| + |-->--| highpass 3 |           |
;                    +---+     +------------+           +---->-----+
;                                                                  |
; +-----------------+   +----------------+   +---------------+   +---+ output
; | noise generator |->-| noise bandpass |->-| noise lowpass |->-| + |-------->
; +-----------------+   +----------------+   +---------------+   +---+

ilnth	=  p3		; note length
ifn	=  p4		; table number
ivel	=  p5		; velocity

iscl	table  0, ifn	; volume
idel	table  1, ifn	; delay (in seconds)
irel	table  2, ifn	; release time (sec.)
iX	table  3, ifn	; X
iY	table  4, ifn	; Y
iZ	table  5, ifn	; Z

ibpm	table  6, ifn	; tempo

ibsfrq	table  7, ifn	; base frequency (MIDI note number)
ifrqs	table  8, ifn	; oscillator start frequency / base frequency
ifrqt	table  9, ifn	; oscillator freq. envelope half-time in beats

ibw01	table 10, ifn	; bandpass 1 bandwidth / oscillator frequency
ihp1	table 11, ifn	; highpass 1 freq. / oscillator frequency
iapf1	table 12, ifn	; "allpass" 1 start freq. / oscillator frq.
iapdx	table 13, ifn	; "allpass" 1 envelope half-time in beats
iapf2	table 14, ifn	; "allpass" 1 end frq. / oscillator frequency

ihp2	table 15, ifn	; highpass 2 frequency / base frequency
imx2	table 16, ifn	; highpass 2 output gain
ihp3	table 17, ifn	; highpass 3 freq. / base frequency
imx3	table 18, ifn	; highpass 3 output gain

ihpx	table 19, ifn	; output highpass frequency / base frequency
iq0x	table 20, ifn	; output highpass resonance

ifr1	table 21, ifn	; output lowpass start freq 1 / oscillator frq.
ifdx1	table 22, ifn	; output lowpass frequency 1 half-time in beats
ifr2	table 23, ifn	; output lowpass start freq 2 / oscillator frq.
ifdx2	table 24, ifn	; output lowpass frequency 2 half-time in beats

insbp1	table 25, ifn	; noise bandpass start frequency in Hz
insbp2	table 26, ifn	; noise bandpass end frequency in Hz
insbw	table 27, ifn	; noise bandpass bandwidth / frequency
inslp1	table 28, ifn	; noise lowpass start frequency (Hz)
inslp2	table 29, ifn	; noise lowpass end frequency (Hz)
insht	table 30, ifn	; noise filter envelope half-time in beats
insatt	table 31, ifn	; noise attack time (in seconds)
insdec	table 32, ifn	; noise decay half-time (in beats)
insmx	table 33, ifn	; noise mix

ixtim	=  gisptx + idel + irel		; expand note length
p3	=  p3 + ixtim
; note amplitude
iamp	=  $VELOC2AMP(ivel'iscl)
; release envelope
aenv	linseg 1, ilnth, 1, irel, 0, 1, 0
aenv	=  aenv * aenv
; beat time
ibtime	=  60 / ibpm

; ---- noise generator ----

a_ns	rnd31 32768 * insmx, 0, 0
k_nsf	expon 1, ibtime * insht, 0.5
k_nsbp	=  insbp2 + (insbp1 - insbp2) * k_nsf
k_nslp	=  inslp2 + (inslp1 - inslp2) * k_nsf
; noise bandpass
a_ns	butterbp a_ns, k_nsbp, k_nsbp * insbw
; noise lowpass
a_ns	pareq a_ns, k_nslp, 0, 0.7071, 2
; noise amp. envelope
a_nse1	linseg 0, insatt, 1, 1, 1
a_nse2	expon 1, ibtime * insdec, 0.5
a_ns	=  a_ns * a_nse1 * a_nse2

; ---- oscillator ----

; base frequency
icps	=  $MIDI2CPS(ibsfrq)
; oscillator frequency
kfrq	expon 1, ibtime * ifrqt, 0.5
kfrq	=  icps * (1 + (ifrqs - 1) * kfrq)
; table number
kfn	=  $CPS2FNUM(kfrq'300)
a1	phasor kfrq
a2	tablexkt a1, kfn, 0, 2, 1, 0, 1
a1	=  a2 * 16384
a2	=  a1				; a1 = a2 = osc. signal

; ---- filters ----

; highpass 1
a1	butterhp a1, ihp1 * kfrq
; bandpass 1
a1	butterbp a1, kfrq, ibw01 * kfrq
; "allpass" 1
k_apf	expon 1, ibtime * iapdx, 0.5
k_apf	=  (iapf2 + (iapf1 - iapf2) * k_apf) * kfrq
atmp	tone a1, k_apf
a1	=  2 * atmp - a1
; highpass 2
a3	butterhp a2, ihp2 * icps
; highpass 3
a2	butterhp a2 + a3 * imx2, ihp3 * icps
a1	=  a1 + a2 * imx3
; output highpass
a1	pareq a1, ihpx * icps, 0, iq0x, 1
; output lowpass
k1	expon 1, ibtime * ifdx1, 0.5
k2	expon 1, ibtime * ifdx2, 0.5
kfrx	limit (k1 * ifr1 + k2 * ifr2) * kfrq, 10, sr * 0.48
a1	pareq a1, kfrx, 0, 0.7071, 2

a0	delay (a1 + a_ns) * iamp * aenv, idel

$SPAT_OUT

	endin

/* ------------------ instr 21: TR-808 bass drum ------------------ */

	instr 21

ilnth	=  p3		; note length
ifn	=  p4		; table number
ivel	=  p5		; velocity

iscl	table  0, ifn	; amp. scale
idel	table  1, ifn	; delay
irel	table  2, ifn	; release time
iX	table  3, ifn	; X
iY	table  4, ifn	; Y
iZ	table  5, ifn	; Z
ibsfrq	table  6, ifn	; base frequency (MIDI note)
ifrqs	table  7, ifn	; start frequency / base frq
ifrqt	table  8, ifn	; frequency envelope half-time
iphs	table  9, ifn	; start phase (0..1)
ilpfrq	table 10, ifn	; lowpass filter frequency
idect	table 11, ifn	; decay half-time

ixtim	=  gisptx + idel + irel		; expand note length
p3	=  p3 + ixtim
; note amplitude
iamp	=  $VELOC2AMP(ivel'iscl)

icps	=  $MIDI2CPS(ibsfrq)
kcps	port 1, ifrqt, ifrqs
kcps	=  icps * kcps

a1	oscili 1, kcps, 700, iphs
a1	butterlp a1, ilpfrq

aenv	expon 1, idect, 0.5
aenv2	linseg 1, ilnth, 1, irel, 0, 1, 0

a0	delay a1 * iamp * aenv * (aenv2 * aenv2), idel

$SPAT_OUT

	endin

/* ---------------------- instr 30: hand clap ---------------------- */

	instr 30

ilnth	=  p3		; note length
ifn	=  p4		; table number
ivel	=  p5		; velocity

iscl	table  0, ifn	; amp. scale
idel	table  1, ifn	; delay
irel	table  2, ifn	; release time
iX	table  3, ifn	; X
iY	table  4, ifn	; Y
iZ	table  5, ifn	; Z
ibpfrq	table  6, ifn	; bandpass frequency
ibws	table  7, ifn	; bandwidth envelope start
ibwt	table  8, ifn	; bw. envelope half-time
ibwe	table  9, ifn	; bandwidth envelope end
idel2	table 10, ifn	; delay 2
idel3	table 11, ifn	; delay 3
idel4	table 12, ifn	; delay 4
idec1	table 13, ifn	; decay 1
idec2	table 14, ifn	; decay 2
idec3	table 15, ifn	; decay 3
idec4	table 16, ifn	; decay 4

ixtim	=  gisptx + idel + irel		; expand note length
p3	=  p3 + ixtim
; note amplitude
iamp	=  $VELOC2AMP(ivel'iscl)
; bandwidth envelope
kbwd	port ibwe, ibwt, ibws
; amp. envelope
a1	=  1
a2	delay1 a1
a1	=  a1 - a2
a2	delay a1, idel2
a3	delay a1, idel3
a4	delay a1, idel4
a1	tone a1 * idec1, 1 / idec1
a2	tone a2 * idec2, 1 / idec2
a3	tone a3 * idec3, 1 / idec3
a4	tone a4 * idec4, 1 / idec4
; noise generator with bandpass filter
a0	rnd31 iamp, 0, 0
a0	butterbp a0 * (a1 + a2 + a3 + a4), ibpfrq, kbwd
; release envelope and delay
a1	linseg 1, ilnth, 1, irel, 0, 1, 0
a1	=  a1 * a1 * a0
a0	delay a1, idel

$SPAT_OUT

	endin

/* ------------------- instr 31: TR-808 cowbell ------------------- */

	instr 31

ilnth	=  p3		; note length
ifn	=  p4		; table number
ivel	=  p5		; velocity

iscl	table  0, ifn	; amp. scale
idel	table  1, ifn	; delay
irel	table  2, ifn	; release time
iX	table  3, ifn	; X
iY	table  4, ifn	; Y
iZ	table  5, ifn	; Z
ifrq1	table  6, ifn	; frequency 1
ifrq2	table  7, ifn	; frequency 2
iffrqs	table  8, ifn	; lowpass filter start frequency
iffrqt	table  9, ifn	; lowpass filter envelope half-time
iffrqe	table 10, ifn	; lowpass filter end frequency
iatt	table 11, ifn	; attack time
idect1	table 12, ifn	; decay time 1
idecl1	table 13, ifn	; decay level 1
idect2	table 14, ifn	; decay 2 half-time
iresn	table 15, ifn	; resonance at osc2 frequency

ixtim	=  gisptx + idel + irel		; expand note length
p3	=  p3 + ixtim
; note amplitude
iamp	=  $VELOC2AMP(ivel'iscl)

ifrq1	=  $MIDI2CPS(ifrq1)
ifn1	=  $CPS2FNUM(ifrq1'500)
ifrq2	=  $MIDI2CPS(ifrq2)
ifn2	=  $CPS2FNUM(ifrq2'500)

a1	oscili 1, ifrq1, ifn1
a2	oscili 1, ifrq2, ifn2

kffrq	port iffrqe, iffrqt, iffrqs
kffrq	limit kffrq, 10, sr * 0.48

aenv1	linseg 0, iatt, 1, 1, 1				; attack
aenv2	expseg 1, idect1, idecl1, idect2, idecl1 * 0.5	; decay
aenv3	linseg 1, ilnth, 1, irel, 0, 1, 0		; release

a0	tone a1 + a2, kffrq
a1	pareq a0, ifrq2, iresn, iresn, 0

a0	delay a1 * iamp * aenv1 * aenv2 * (aenv3 * aenv3), idel

$SPAT_OUT

	endin

/* -------------------- instr 40: TR-808 hi-hat -------------------- */

	instr 40

ilnth	=  p3		; note length
ifn	=  p4		; table number
ivel	=  p5		; velocity

iscl	table  0, ifn	; amp. scale
idel	table  1, ifn	; delay
irel	table  2, ifn	; release time
iX	table  3, ifn	; X
iY	table  4, ifn	; Y
iZ	table  5, ifn	; Z
ibsfrq	table  6, ifn	; base frequency (MIDI note)
ifrq2	table  7, ifn	; osc 2 frequency / base frq
ifrq3	table  8, ifn	; osc 3 frequency / base frq
ifrq4	table  9, ifn	; osc 4 frequency / base frq
ifrq5	table 10, ifn	; osc 5 frequency / base frq
ifrq6	table 11, ifn	; osc 6 frequency / base frq
idsts	table 12, ifn	; distortion start
idstt	table 13, ifn	; distortion envelope half-time
idste	table 14, ifn	; distortion end
ihpfrq	table 15, ifn	; highpass frequency
ihpres	table 16, ifn	; highpass resonance
iatt	table 17, ifn	; attack time
idect1	table 18, ifn	; decay time 1
idecl1	table 19, ifn	; decay level 1
idect2	table 20, ifn	; decay 2 half-time

ixtim	=  gisptx + idel + irel		; expand note length
p3	=  p3 + ixtim
; note amplitude
iamp	=  $VELOC2AMP(ivel'iscl)

ifrq1	=  $MIDI2CPS(ibsfrq)		; oscillator frequencies
ifrq2	=  ifrq1 * ifrq2
ifrq3	=  ifrq1 * ifrq3
ifrq4	=  ifrq1 * ifrq4
ifrq5	=  ifrq1 * ifrq5
ifrq6	=  ifrq1 * ifrq6

ifn1	=  $CPS2FNUM(ifrq1'300)		; table numbers
ifn2	=  $CPS2FNUM(ifrq2'300)
ifn3	=  $CPS2FNUM(ifrq3'300)
ifn4	=  $CPS2FNUM(ifrq4'300)
ifn5	=  $CPS2FNUM(ifrq5'300)
ifn6	=  $CPS2FNUM(ifrq6'300)

iphs1	unirand 1			; start phase
iphs2	unirand 1
iphs3	unirand 1
iphs4	unirand 1
iphs5	unirand 1
iphs6	unirand 1

a1	oscili 1, ifrq1, ifn1, iphs1	; oscillator
a2	oscili 1, ifrq2, ifn2, iphs2
a3	oscili 1, ifrq3, ifn3, iphs3
a4	oscili 1, ifrq4, ifn4, iphs4
a5	oscili 1, ifrq5, ifn5, iphs5
a6	oscili 1, ifrq6, ifn6, iphs6

a0	=  a1 + a2 + a3 + a4 + a5 + a6

a1	limit a0 * 1000000, -1, 1			; distort
a0	limit abs(a0), 0.000001, 1000000
adst	expon 1, idstt, 0.5
a0	=  a1 * exp(log(a0) * (idste + (idsts - idste) * adst))

a0	pareq a0, ihpfrq, 0, sqrt(ihpres), 1		; highpass
a0	pareq a0, ihpfrq, 0, sqrt(ihpres), 1

aenv1	linseg 0, iatt, 1, 1, 1				; envelopes
aenv2	expseg 1, idect1, idecl1, idect2, 0.5 * idecl1
aenv3	linseg 1, ilnth, 1, irel, 0, 1, 0

a1	=  a0 * iamp * aenv1 * aenv2 * (aenv3 * aenv3)

a0	delay a1, idel

$SPAT_OUT

	endin

/* ------------------ instr 50: TR-909 snare drum ------------------ */

	instr 50

ilnth	=  p3		/* note length				     */
ifn	=  p4		/* function table with instrument parameters */
ivel	=  p5		/* velocity (0 - 127)			     */

iscl	table  0, ifn	; amplitude scale
idel	table  1, ifn	; delay
irel	table  2, ifn	; release time
iX	table  3, ifn	; X
iY	table  4, ifn	; Y
iZ	table  5, ifn	; Z
ibsfrq	table  6, ifn	; base freq. (MIDI note)
ifrqs	table  7, ifn	; start freq. / base frq.
ifrqt	table  8, ifn	; frequency env. half-time
ifmds	table  9, ifn	; FM depth start
ifmdt	table 10, ifn	; FM depth envelope half-time
ifmde	table 11, ifn	; FM depth end
ifrq2	table 12, ifn	; osc 2 frq. / osc 1 frq.
iamp2s	table 13, ifn	; osc 2 amplitude start
iamp2t	table 14, ifn	; osc 2 amplitude envelope half-time
iamp2e	table 15, ifn	; osc 2 amplitude end
insbpf	table 16, ifn	; noise BP frequency
insbpb	table 17, ifn	; noise BP bandwidth
insamps	table 18, ifn	; noise amplitude start
insampt	table 19, ifn	; noise amplitude env. half-time
insampe	table 20, ifn	; noise amplitude end
idect	table 21, ifn	; decay half-time

ixtime	=  gisptx + idel + irel			; expand note duration
p3	=  p3 + ixtime

; release envelope

aenv1	linseg 1, ilnth, 1, irel, 0, 1, 0
aenv1	=  aenv1 * aenv1

; output amplitude
iamp	=  $VELOC2AMP(ivel'iscl)

icps0	=  $MIDI2CPS(ibsfrq)	; frequency envelope
icps1	=  ifrqs * icps0
acps	expon 1, ifrqt, 0.5
acps	=  icps0 + (icps1 - icps0) * acps	; osc 1 frequency
acps2	=  acps * ifrq2				; osc 2 frequency

afmd	expon 1, ifmdt, 0.5		; FM depth
afmd	=  ifmde + (ifmds - ifmde) * afmd

afm1	oscili afmd, acps, 700		; FM
afm2	oscili afmd, acps2, 700

aamp2	expon 1, iamp2t, 0.5		; osc 2 amplitude
aamp2	=  iamp2e + (iamp2s - iamp2e) * aamp2

a1	oscili 1, acps * (1 + afm1), 700	; oscillators
a2	oscili aamp2, acps2 * (1 + afm2), 700

a3	rnd31 1, 0, 0			; noise
aamp3	expon 1, insampt, 0.5
a3	butterbp a3, insbpf, insbpb
a3	=  a3 * (insampe + (insamps - insampe) * aamp3)

aenv2	expon 1, idect, 0.5
a1	=  iamp * aenv1 * aenv2 * (a1 + a2 + a3)

a0	delay a1, idel

$SPAT_OUT

	endin

/* ------------------------- instr 51: tom ------------------------- */

	instr 51

ilnth	=  p3		/* note length				     */
ifn	=  p4		/* function table with instrument parameters */
ivel	=  p5		/* velocity (0 - 127)			     */

iscl	table  0, ifn	; amplitude scale
idel	table  1, ifn	; delay
irel	table  2, ifn	; release time
iX	table  3, ifn	; X
iY	table  4, ifn	; Y
iZ	table  5, ifn	; Z
ibsfrq	table  6, ifn	; base freq. (MIDI note)
ifrqs	table  7, ifn	; start freq. / base frq.
ifrqt	table  8, ifn	; frequency env. half-time
ifrq2	table  9, ifn	; osc 2 frq. / osc 1 frq.
iamp2s	table 10, ifn	; osc 2 amplitude start
iamp2t	table 11, ifn	; osc 2 amplitude envelope half-time
iamp2e	table 12, ifn	; osc 2 amplitude end
iphs	table 13, ifn	; osc 1 and 2 start phase
idel_1	table 14, ifn	; invert 1 delay * base frequency
idel_2	table 15, ifn	; invert 2 delay * base frequency
ilpfrq	table 16, ifn	; lowpass frequency
insbpf	table 17, ifn	; noise BP frequency
insbpb	table 18, ifn	; noise BP bandwidth
inscfr	table 19, ifn	; noise comb frequency / base frequency
inscfb	table 20, ifn	; noise comb feedback
inslpf	table 21, ifn	; noise lowpass frequency
insamps	table 22, ifn	; noise amplitude start
insampt	table 23, ifn	; noise amplitude env. half-time
insampe	table 24, ifn	; noise amplitude end
idect	table 25, ifn	; decay half-time

ixtime	=  gisptx + idel + irel			; expand note duration
p3	=  p3 + ixtime

; release envelope

aenv1	linseg 1, ilnth, 1, irel, 0, 1, 0
aenv1	=  aenv1 * aenv1

; output amplitude
iamp	=  $VELOC2AMP(ivel'iscl)

icps0	=  $MIDI2CPS(ibsfrq)	; frequency envelope
icps1	=  ifrqs * icps0
acps	expon 1, ifrqt, 0.5
acps	=  icps0 + (icps1 - icps0) * acps	; osc 1 frequency
acps2	=  acps * ifrq2				; osc 2 frequency

aamp2	expon 1, iamp2t, 0.5		; osc 2 amplitude
aamp2	=  iamp2e + (iamp2s - iamp2e) * aamp2

a1	oscili 1, acps, 700, iphs	; oscillators
a2	oscili aamp2, acps2, 700, iphs

a3	rnd31 1, 0, 0			; noise
aamp3	expon 1, insampt, 0.5
a3	butterbp a3, insbpf, insbpb
a3	=  a3 * (insampe + (insamps - insampe) * aamp3)

ax1	=  1		; invert amplitude to add click
ax2	delay ax1, (int(idel_1 * sr / icps0 + 0.5) + 0.01) / sr
ax3	delay ax1, (int(idel_2 * sr / icps0 + 0.5) + 0.01) / sr

a1	=  (a1 + a2) * (ax1 - 2 * ax2 + 2 * ax3)

a1	butterlp a1, ilpfrq		; lowpass

a3x	delayr (int(sr / (inscfr * icps0) + 0.5) + 0.01) / sr
a3	=  a3 - a3x * inscfb
	delayw a3

a3	butterlp a3, inslpf

aenv2	expon 1, idect, 0.5
a1	=  iamp * aenv1 * aenv2 * (a1 + a3)

a0	delay a1, idel

$SPAT_OUT

	endin

/* ---------------------- instr 52: rim shot ---------------------- */

	instr 52

ilnth	=  p3		/* note length				     */
ifn	=  p4		/* function table with instrument parameters */
ivel	=  p5		/* velocity (0 - 127)			     */

iscl	table  0, ifn	; amplitude scale
idel	table  1, ifn	; delay
irel	table  2, ifn	; release time
iX	table  3, ifn	; X
iY	table  4, ifn	; Y
iZ	table  5, ifn	; Z
ibsfrq	table  6, ifn	; base freq. (MIDI note)
ifrqs	table  7, ifn	; start freq. / base frq.
ifrqt	table  8, ifn	; frequency env. half-time
ifmds	table  9, ifn	; FM depth start
ifmdt	table 10, ifn	; FM depth envelope half-time
ifmde	table 11, ifn	; FM depth end
insamp	table 12, ifn	; noise amplitude
inslpf	table 13, ifn	; noise lowpass frequency
idecs	table 14, ifn	; amplitude (before distortion) start
idect	table 15, ifn	; amplitude envelope half-time
idece	table 16, ifn	; amplitude end
ihpamp	table 17, ifn	; HP filtered signal (after distortion) gain
ihpfrq	table 18, ifn	; highpass frequency
ihpdel	table 19, ifn	; highpass filtered signal delay
ilpfs	table 20, ifn	; output lowpass frequency start
ilpft	table 21, ifn	; lowpass envelope half-time
ilpfe	table 22, ifn	; output lowpass frequency end

ixtime	=  gisptx + idel + irel		; expand note duration
p3	=  p3 + ixtime

; release envelope

aenv1	linseg 1, ilnth, 1, irel, 0, 1, 0
aenv1	=  aenv1 * aenv1

iamp	=  $VELOC2AMP(ivel'1)		; velocity

icps	=  $MIDI2CPS(ibsfrq)		; base frequency
acps	expon 1, ifrqt, 0.5
acps	=  icps * (1 + (ifrqs - 1) * acps)

a1a	phasor acps, 0			; square wave
a1b	phasor acps, 0.5

afmd	expon 1, ifmdt, 0.5		; FM envelope
afmd	=  ifmde + (ifmds - ifmde) * afmd

a1	=  (a1a - a1b) * 2 * afmd
acps	=  acps * (1 + a1)		; frequency with FM

a0	oscili 1, acps, 700		; sine oscillator

a1	rnd31 insamp, 0, 0		; add some noise
a1	tone a1, inslpf
	vincr a0, a1

aenv	expon 1, idect, 0.5		; amp. envelope
aenv	=  idece + (idecs - idece) * aenv

a0	limit aenv * iamp * a0, -1, 1	; distortion
a0	tablei a0 * 0.25, 700, 1, 0, 1

a2	tone a0, ihpfrq			; highpass filter
a2	=  a0 - a2
a1	delay a2, ihpdel
	vincr a0, a1 * ihpamp

klpfr	port ilpfe, ilpft, ilpfs	; output lowpass
a1	pareq a0, klpfr, 0, 0.7071, 2

a0	delay a1 * iscl * aenv1, idel

$SPAT_OUT

	endin

/* ------------ instr 99: decoder and output instrument ------------ */

	instr 99

iamp	=  0.000001 * 0.000001 * 0.000001 * 0.000001

a0	rnd31 iamp, 0, 0	; low level noise to avoid denormals
a1	rnd31 iamp, 0, 0
a2	rnd31 iamp, 0, 0
a3	rnd31 iamp, 0, 0
a4	rnd31 iamp, 0, 0

	vincr a0, ga0 * p4	; get input from global variables
	vincr a1, ga1 * p4
	vincr a2, ga2 * p4
	vincr a3, ga3 * p4
	vincr a4, ga4 * p4

	clear ga0	; clear global vars
	clear ga1
	clear ga2
	clear ga3
	clear ga4

; decode to 2 chnls with phase shift

a1re, a1im	hilbert a1
a2re, a2im	hilbert a2
a3re, a3im	hilbert a3

aL	=  0.7071 * (a1re - a1im) + 0.5 * (a2re + a2im + a3re - a3im)
aR	=  0.7071 * (a1re + a1im) + 0.5 * (a2re - a2im - a3re - a3im)

	outs aL, aR

; mono output

	outs a0, a0

	endin

</CsInstruments>
<CsScore>


; ============ drums.sco - written by Istvan Varga, 2002 ============

; ---- tempo ----

t 0 132

; -- instr 1: render tables for cymbal instruments --

; p3 : note length (should be 0)
; p4 : ftable number
; p5 : number of partials
; p6 : amp. scale
; p7 : transpose (in semitones)
; p8 : random seed (1 to 2^31 - 2)
; p9 : amplitude distribution

; ---- generate cymbal tables ----

i 1 0 0 101 600 1 0 114 3		; crash 2
i 1 0 0 102 600 1 0 4 6			; hihat
i 1 0 0 103 600 1 0 213 3		; crash 1
;i 1 0 0 104 600 1 0 427 4		; crash 3 (not used)
f 99 0 16 -2	0.3	7500	0	1	10500	0.2	\
		0.3	14000	0.4	1	18000	0.8
f 105 0 524288 -34 99 4 1 -4		; tambourine
i 1 0 0 106 600 1 0 193 6		; hihat 2
i 1 0 0 107 600 1 2 19 4		; ride
;i 1 0 0 108 600 1 0 7 4			; ride 2 (not used)

; ---- misc. tables ----

; square wave

;#include "fgen_h.sco"

/* Generate a set of band-limited function tables.		*/
/* TABLE:	first output table number. One table is		*/
/*		generated for each MIDI note number (0 - 127),	*/
/*		the last table is (TABLE + 127).		*/
/* SIZE:	length of output ftables (in samples)		*/
/* SRC:		source table number (may not be equal to TABLE)	*/
/* MINH:	lowest harmonic partial number			*/

#define FGEN128(TABLE'SIZE'SRC'MINH) #

f [ $TABLE + 0 ] 0 $SIZE -30	$SRC	$MINH	2935.49		48000
f [ $TABLE + 1 ] 0 $SIZE -30	$TABLE	$MINH	2770.74		48000
f [ $TABLE + 2 ] 0 $SIZE -30	$TABLE	$MINH	2615.23		48000
f [ $TABLE + 3 ] 0 $SIZE -30	$TABLE	$MINH	2468.45		48000
f [ $TABLE + 4 ] 0 $SIZE -30	$TABLE	$MINH	2329.90		48000
f [ $TABLE + 5 ] 0 $SIZE -30	$TABLE	$MINH	2199.13		48000
f [ $TABLE + 6 ] 0 $SIZE -30	$TABLE	$MINH	2075.71		48000
f [ $TABLE + 7 ] 0 $SIZE -30	$TABLE	$MINH	1959.21		48000
f [ $TABLE + 8 ] 0 $SIZE -30	$TABLE	$MINH	1849.24		48000
f [ $TABLE + 9 ] 0 $SIZE -30	$TABLE	$MINH	1745.45		48000
f [ $TABLE + 10 ] 0 $SIZE -30	$TABLE	$MINH	1647.49		48000
f [ $TABLE + 11 ] 0 $SIZE -30	$TABLE	$MINH	1555.02		48000
f [ $TABLE + 12 ] 0 $SIZE -30	$TABLE	$MINH	1467.75		48000
f [ $TABLE + 13 ] 0 $SIZE -30	$TABLE	$MINH	1385.37		48000
f [ $TABLE + 14 ] 0 $SIZE -30	$TABLE	$MINH	1307.61		48000
f [ $TABLE + 15 ] 0 $SIZE -30	$TABLE	$MINH	1234.22		48000
f [ $TABLE + 16 ] 0 $SIZE -30	$TABLE	$MINH	1164.95		48000
f [ $TABLE + 17 ] 0 $SIZE -30	$TABLE	$MINH	1099.57		48000
f [ $TABLE + 18 ] 0 $SIZE -30	$TABLE	$MINH	1037.85		48000
f [ $TABLE + 19 ] 0 $SIZE -30	$TABLE	$MINH	 979.60		48000
f [ $TABLE + 20 ] 0 $SIZE -30	$TABLE	$MINH	 924.62		48000
f [ $TABLE + 21 ] 0 $SIZE -30	$TABLE	$MINH	 872.73		48000
f [ $TABLE + 22 ] 0 $SIZE -30	$TABLE	$MINH	 823.74		48000
f [ $TABLE + 23 ] 0 $SIZE -30	$TABLE	$MINH	 777.51		48000
f [ $TABLE + 24 ] 0 $SIZE -30	$TABLE	$MINH	 733.87		48000
f [ $TABLE + 25 ] 0 $SIZE -30	$TABLE	$MINH	 692.68		48000
f [ $TABLE + 26 ] 0 $SIZE -30	$TABLE	$MINH	 653.81		48000
f [ $TABLE + 27 ] 0 $SIZE -30	$TABLE	$MINH	 617.11		48000
f [ $TABLE + 28 ] 0 $SIZE -30	$TABLE	$MINH	 582.48		48000
f [ $TABLE + 29 ] 0 $SIZE -30	$TABLE	$MINH	 549.78		48000
f [ $TABLE + 30 ] 0 $SIZE -30	$TABLE	$MINH	 518.93		48000
f [ $TABLE + 31 ] 0 $SIZE -30	$TABLE	$MINH	 489.80		48000
f [ $TABLE + 32 ] 0 $SIZE -30	$TABLE	$MINH	 462.31		48000
f [ $TABLE + 33 ] 0 $SIZE -30	$TABLE	$MINH	 436.36		48000
f [ $TABLE + 34 ] 0 $SIZE -30	$TABLE	$MINH	 411.87		48000
f [ $TABLE + 35 ] 0 $SIZE -30	$TABLE	$MINH	 388.76		48000
f [ $TABLE + 36 ] 0 $SIZE -30	$TABLE	$MINH	 366.94		48000
f [ $TABLE + 37 ] 0 $SIZE -30	$TABLE	$MINH	 346.34		48000
f [ $TABLE + 38 ] 0 $SIZE -30	$TABLE	$MINH	 326.90		48000
f [ $TABLE + 39 ] 0 $SIZE -30	$TABLE	$MINH	 308.56		48000
f [ $TABLE + 40 ] 0 $SIZE -30	$TABLE	$MINH	 291.24		48000
f [ $TABLE + 41 ] 0 $SIZE -30	$TABLE	$MINH	 274.89		48000
f [ $TABLE + 42 ] 0 $SIZE -30	$TABLE	$MINH	 259.46		48000
f [ $TABLE + 43 ] 0 $SIZE -30	$TABLE	$MINH	 244.90		48000
f [ $TABLE + 44 ] 0 $SIZE -30	$TABLE	$MINH	 231.16		48000
f [ $TABLE + 45 ] 0 $SIZE -30	$TABLE	$MINH	 218.18		48000
f [ $TABLE + 46 ] 0 $SIZE -30	$TABLE	$MINH	 205.94		48000
f [ $TABLE + 47 ] 0 $SIZE -30	$TABLE	$MINH	 194.38		48000
f [ $TABLE + 48 ] 0 $SIZE -30	$TABLE	$MINH	 183.47		48000
f [ $TABLE + 49 ] 0 $SIZE -30	$TABLE	$MINH	 173.17		48000
f [ $TABLE + 50 ] 0 $SIZE -30	$TABLE	$MINH	 163.45		48000
f [ $TABLE + 51 ] 0 $SIZE -30	$TABLE	$MINH	 154.28		48000
f [ $TABLE + 52 ] 0 $SIZE -30	$TABLE	$MINH	 145.62		48000
f [ $TABLE + 53 ] 0 $SIZE -30	$TABLE	$MINH	 137.45		48000
f [ $TABLE + 54 ] 0 $SIZE -30	$TABLE	$MINH	 129.73		48000
f [ $TABLE + 55 ] 0 $SIZE -30	$TABLE	$MINH	 122.45		48000
f [ $TABLE + 56 ] 0 $SIZE -30	$TABLE	$MINH	 115.58		48000
f [ $TABLE + 57 ] 0 $SIZE -30	$TABLE	$MINH	 109.09		48000
f [ $TABLE + 58 ] 0 $SIZE -30	$TABLE	$MINH	 102.97		48000
f [ $TABLE + 59 ] 0 $SIZE -30	$TABLE	$MINH	  97.19		48000
f [ $TABLE + 60 ] 0 $SIZE -30	$TABLE	$MINH	  91.73		48000
f [ $TABLE + 61 ] 0 $SIZE -30	$TABLE	$MINH	  86.59		48000
f [ $TABLE + 62 ] 0 $SIZE -30	$TABLE	$MINH	  81.73		48000
f [ $TABLE + 63 ] 0 $SIZE -30	$TABLE	$MINH	  77.14		48000
f [ $TABLE + 64 ] 0 $SIZE -30	$TABLE	$MINH	  72.81		48000
f [ $TABLE + 65 ] 0 $SIZE -30	$TABLE	$MINH	  68.72		48000
f [ $TABLE + 66 ] 0 $SIZE -30	$TABLE	$MINH	  64.87		48000
f [ $TABLE + 67 ] 0 $SIZE -30	$TABLE	$MINH	  61.23		48000
f [ $TABLE + 68 ] 0 $SIZE -30	$TABLE	$MINH	  57.79		48000
f [ $TABLE + 69 ] 0 $SIZE -30	$TABLE	$MINH	  54.55		48000
f [ $TABLE + 70 ] 0 $SIZE -30	$TABLE	$MINH	  51.48		48000
f [ $TABLE + 71 ] 0 $SIZE -30	$TABLE	$MINH	  48.59		48000
f [ $TABLE + 72 ] 0 $SIZE -30	$TABLE	$MINH	  45.87		48000
f [ $TABLE + 73 ] 0 $SIZE -30	$TABLE	$MINH	  43.29		48000
f [ $TABLE + 74 ] 0 $SIZE -30	$TABLE	$MINH	  40.86		48000
f [ $TABLE + 75 ] 0 $SIZE -30	$TABLE	$MINH	  38.57		48000
f [ $TABLE + 76 ] 0 $SIZE -30	$TABLE	$MINH	  36.40		48000
f [ $TABLE + 77 ] 0 $SIZE -30	$TABLE	$MINH	  34.36		48000
f [ $TABLE + 78 ] 0 $SIZE -30	$TABLE	$MINH	  32.43		48000
f [ $TABLE + 79 ] 0 $SIZE -30	$TABLE	$MINH	  30.61		48000
f [ $TABLE + 80 ] 0 $SIZE -30	$TABLE	$MINH	  28.89		48000
f [ $TABLE + 81 ] 0 $SIZE -30	$TABLE	$MINH	  27.27		48000
f [ $TABLE + 82 ] 0 $SIZE -30	$TABLE	$MINH	  25.74		48000
f [ $TABLE + 83 ] 0 $SIZE -30	$TABLE	$MINH	  24.30		48000
f [ $TABLE + 84 ] 0 $SIZE -30	$TABLE	$MINH	  22.93		48000
f [ $TABLE + 85 ] 0 $SIZE -30	$TABLE	$MINH	  21.65		48000
f [ $TABLE + 86 ] 0 $SIZE -30	$TABLE	$MINH	  20.43		48000
f [ $TABLE + 87 ] 0 $SIZE -30	$TABLE	$MINH	  19.28		48000
f [ $TABLE + 88 ] 0 $SIZE -30	$TABLE	$MINH	  18.20		48000
f [ $TABLE + 89 ] 0 $SIZE -30	$TABLE	$MINH	  17.18		48000
f [ $TABLE + 90 ] 0 $SIZE -30	$TABLE	$MINH	  16.22		48000
f [ $TABLE + 91 ] 0 $SIZE -30	$TABLE	$MINH	  15.31		48000
f [ $TABLE + 92 ] 0 $SIZE -30	$TABLE	$MINH	  14.45		48000
f [ $TABLE + 93 ] 0 $SIZE -30	$TABLE	$MINH	  13.64		48000
f [ $TABLE + 94 ] 0 $SIZE -30	$TABLE	$MINH	  12.87		48000
f [ $TABLE + 95 ] 0 $SIZE -30	$TABLE	$MINH	  12.15		48000
f [ $TABLE + 96 ] 0 $SIZE -30	$TABLE	$MINH	  11.47		48000
f [ $TABLE + 97 ] 0 $SIZE -30	$TABLE	$MINH	  10.82		48000
f [ $TABLE + 98 ] 0 $SIZE -30	$TABLE	$MINH	  10.22		48000
f [ $TABLE + 99 ] 0 $SIZE -30	$TABLE	$MINH	   9.64		48000
f [ $TABLE + 100 ] 0 $SIZE -30	$TABLE	$MINH	   9.10		48000
f [ $TABLE + 101 ] 0 $SIZE -30	$TABLE	$MINH	   8.59		48000
f [ $TABLE + 102 ] 0 $SIZE -30	$TABLE	$MINH	   8.11		48000
f [ $TABLE + 103 ] 0 $SIZE -30	$TABLE	$MINH	   7.65		48000
f [ $TABLE + 104 ] 0 $SIZE -30	$TABLE	$MINH	   7.22		48000
f [ $TABLE + 105 ] 0 $SIZE -30	$TABLE	$MINH	   6.82		48000
f [ $TABLE + 106 ] 0 $SIZE -30	$TABLE	$MINH	   6.44		48000
f [ $TABLE + 107 ] 0 $SIZE -30	$TABLE	$MINH	   6.07		48000
f [ $TABLE + 108 ] 0 $SIZE -30	$TABLE	$MINH	   5.73		48000
f [ $TABLE + 109 ] 0 $SIZE -30	$TABLE	$MINH	   5.41		48000
f [ $TABLE + 110 ] 0 $SIZE -30	$TABLE	$MINH	   5.11		48000
f [ $TABLE + 111 ] 0 $SIZE -30	$TABLE	$MINH	   4.82		48000
f [ $TABLE + 112 ] 0 $SIZE -30	$TABLE	$MINH	   4.55		48000
f [ $TABLE + 113 ] 0 $SIZE -30	$TABLE	$MINH	   4.30		48000
f [ $TABLE + 114 ] 0 $SIZE -30	$TABLE	$MINH	   4.05		48000
f [ $TABLE + 115 ] 0 $SIZE -30	$TABLE	$MINH	   3.83		48000
f [ $TABLE + 116 ] 0 $SIZE -30	$TABLE	$MINH	   3.61		48000
f [ $TABLE + 117 ] 0 $SIZE -30	$TABLE	$MINH	   3.41		48000
f [ $TABLE + 118 ] 0 $SIZE -30	$TABLE	$MINH	   3.22		48000
f [ $TABLE + 119 ] 0 $SIZE -30	$TABLE	$MINH	   3.04		48000
f [ $TABLE + 120 ] 0 $SIZE -30	$TABLE	$MINH	   2.87		48000
f [ $TABLE + 121 ] 0 $SIZE -30	$TABLE	$MINH	   2.71		48000
f [ $TABLE + 122 ] 0 $SIZE -30	$TABLE	$MINH	   2.55		48000
f [ $TABLE + 123 ] 0 $SIZE -30	$TABLE	$MINH	   2.41		48000
f [ $TABLE + 124 ] 0 $SIZE -30	$TABLE	$MINH	   2.28		48000
f [ $TABLE + 125 ] 0 $SIZE -30	$TABLE	$MINH	   2.15		48000
f [ $TABLE + 126 ] 0 $SIZE -30	$TABLE	$MINH	   2.03		48000
f [ $TABLE + 127 ] 0 $SIZE -30	$TABLE	$MINH	   1.91		48000

#


f 301 0 16384 7 1 8192 1 0 -1 8192 -1
$FGEN128(300'4096'301'1)

; sawtooth wave

f 501 0 16384 7 1 16384 -1
$FGEN128(500'4096'501'1)

; sine

f 700 0 4096 10 1

; window for cymbal instruments

f 100 0 16385 5 1 16385 0.01

; ---- include room parameters ----

;#include "room.sco"

/* room parameters are set in this table (see spat3d.README) */

;		depth1, depth2, max. delay, IR length, idist, seed
f 225 0 64 -2	2 60 -1 0.005 -1 123
		1 13.000 0.05 0.91 20000.0 0.0 0.50 2	; ceil
		1  2.000 0.05 0.91 20000.0 0.0 0.25 2	; floor
		1 16.000 0.05 0.91 20000.0 0.0 0.35 2	; front
		1  9.000 0.05 0.91 20000.0 0.0 0.35 2	; back
		1 12.000 0.05 0.91 20000.0 0.0 0.35 2	; right
		1  8.000 0.05 0.91 20000.0 0.0 0.35 2	; left


; ================ instrument definitions ================

/* ---- crash cymbal 1 ---- */

f 10 0 32 -2	900	; amplitude scale
		0.015	; delay
		0.1	; release time
		-1	; X
		1.87	; Y
		0	; Z
		103	; input table
		100	; window table
		0.225	; start grain duration in seconds
		0.10	; grain druaton envelope half-time
		0.1	; end grain duration
		40	; number of overlaps
		10000	; EQ start frequency
		1	; EQ frequency envelope half-time
		10000	; EQ end frequency
		1	; EQ start level (Q is level * 0.7071)
		0.14	; EQ level envelope half-time
		4	; EQ end level
		500	; highpass frequency
		20000	; lowpass frequency
		0.16	; decay env. half-time (n.a. in reverse mode)
		1	; reverse cymbal mode (0: on, 1: off)
		0.001	; delay time for chorus effect
		1	; non-delayed signal level
		0	; delayed signal level

/* ---- crash cymbal 2 ---- */

f 11 0 32 -2	900	; amplitude scale
		0.015	; delay
		0.1	; release time
		0.5	; X
		1.9	; Y
		0	; Z
		101	; input table
		100	; window table
		0.225	; start grain duration in seconds
		0.10	; grain druaton envelope half-time
		0.1	; end grain duration
		40	; number of overlaps
		11000	; EQ start frequency
		1	; EQ frequency envelope half-time
		11000	; EQ end frequency
		1	; EQ start level (Q is level * 0.7071)
		0.16	; EQ level envelope half-time
		3	; EQ end level
		500	; highpass frequency
		20000	; lowpass frequency
		0.18	; decay env. half-time (n.a. in reverse mode)
		1	; reverse cymbal mode (0: on, 1: off)
		0.001	; delay time for chorus effect
		1	; non-delayed signal level
		0	; delayed signal level

/* ---- reverse cymbal ---- */

f 12 0 32 -2	400	; amplitude scale
		0.016	; delay
		0.03	; release time
		-1.5	; X
		-1.7	; Y
		0	; Z
		103	; input table
		100	; window table
		0.1	; start grain duration in seconds
		0.2	; grain druaton envelope half-time
		0.1	; end grain duration
		50	; number of overlaps
		10000	; EQ start frequency
		1	; EQ frequency envelope half-time
		10000	; EQ end frequency
		2	; EQ start level (Q is level * 0.7071)
		0.2	; EQ level envelope half-time
		2	; EQ end level
		500	; highpass frequency
		18000	; lowpass frequency
		0.2	; decay env. half-time (n.a. in reverse mode)
		0	; reverse cymbal mode (0: on, 1: off)
		0.001	; delay time for chorus effect
		1	; non-delayed signal level
		0	; delayed signal level

/* ---- open hi-hat ---- */

f 13 0 32 -2	700	; amplitude scale
		0.012	; delay
		0.02	; release time
		1.5	; X
		1.5	; Y
		0	; Z
		102	; input table
		100	; window table
		0.001	; start grain duration in seconds
		0.05	; grain druaton envelope half-time
		0.1	; end grain duration
		50	; number of overlaps
		10000	; EQ start frequency
		1	; EQ frequency envelope half-time
		10000	; EQ end frequency
		2	; EQ start level (Q is level * 0.7071)
		1	; EQ level envelope half-time
		2	; EQ end level
		1000	; highpass frequency
		22000	; lowpass frequency
		0.1	; decay env. half-time (n.a. in reverse mode)
		1	; reverse cymbal mode (0: on, 1: off)
		0.015	; delay time for chorus effect
		0.2	; non-delayed signal level
		1	; delayed signal level

/* ---- closed hi-hat ---- */

f 14 0 32 -2	700	; amplitude scale
		0.0035	; delay
		0.02	; release time
		2.0	; X
		0.7	; Y
		0	; Z
		102	; input table
		100	; window table
		0.0001	; start grain duration in seconds
		0.01	; grain druaton envelope half-time
		0.1	; end grain duration
		50	; number of overlaps
		10000	; EQ start frequency
		1	; EQ frequency envelope half-time
		10000	; EQ end frequency
		2	; EQ start level (Q is level * 0.7071)
		1	; EQ level envelope half-time
		2	; EQ end level
		500	; highpass frequency
		22000	; lowpass frequency
		0.02	; decay env. half-time (n.a. in reverse mode)
		1	; reverse cymbal mode (0: on, 1: off)
		0.015	; delay time for chorus effect
		0	; non-delayed signal level
		1	; delayed signal level

/* ---- tambourine ---- */

f 15 0 32 -2	6500	; amplitude scale
		0.018	; delay
		0.02	; release time
		1.75	; X
		-1.2	; Y
		0	; Z
		105	; input table
		100	; window table
		0.002	; start grain duration in seconds
		0.01	; grain druaton envelope half-time
		0.03	; end grain duration
		20	; number of overlaps
		1000	; EQ start frequency
		1	; EQ frequency envelope half-time
		1000	; EQ end frequency
		1	; EQ start level (Q is level * 0.7071)
		1	; EQ level envelope half-time
		1	; EQ end level
		100	; highpass frequency
		22000	; lowpass frequency
		0.03	; decay env. half-time (n.a. in reverse mode)
		1	; reverse cymbal mode (0: on, 1: off)
		0.001	; delay time for chorus effect
		1	; non-delayed signal level
		0	; delayed signal level

/* ---- hi-hat 2 ---- */

f 16 0 32 -2	400	; amplitude scale
		0.008	; delay
		0.02	; release time
		-1.75	; X
		1.2	; Y
		0	; Z
		106	; input table
		100	; window table
		0.08	; start grain duration in seconds
		0.05	; grain druaton envelope half-time
		0.08	; end grain duration
		50	; number of overlaps
		8000	; EQ start frequency
		1	; EQ frequency envelope half-time
		8000	; EQ end frequency
		2	; EQ start level (Q is level * 0.7071)
		1	; EQ level envelope half-time
		2	; EQ end level
		1000	; highpass frequency
		14000	; lowpass frequency
		0.25	; decay env. half-time (n.a. in reverse mode)
		1	; reverse cymbal mode (0: on, 1: off)
		0.015	; delay time for chorus effect
		0.3	; non-delayed signal level
		1	; delayed signal level

/* ---- ride cymbal ---- */

f 17 0 32 -2	450	; amplitude scale
		0.02	; delay
		0.05	; release time
		-1.2	; X
		-1.75	; Y
		0	; Z
		107	; input table
		100	; window table
		0.0005	; start grain duration in seconds
		0.01	; grain druaton envelope half-time
		0.4	; end grain duration
		50	; number of overlaps
		12000	; EQ start frequency
		1	; EQ frequency envelope half-time
		12000	; EQ end frequency
		2	; EQ start level (Q is level * 0.7071)
		1	; EQ level envelope half-time
		2	; EQ end level
		1000	; highpass frequency
		22000	; lowpass frequency
		0.1	; decay env. half-time (n.a. in reverse mode)
		1	; reverse cymbal mode (0: on, 1: off)
		0.001	; delay time for chorus effect
		1	; non-delayed signal level
		0	; delayed signal level

/* ---- bass drum ---- */

f 20 0 64 -2	0.6	; volume
		0.020	; delay (in seconds)
		0.03	; release time (sec.)
		0	; X
		1	; Y
		0	; Z
		140	; tempo
		31	; base frequency (MIDI note number)
		5.3333	; oscillator start frequency / base frequency
		0.0714	; oscillator freq. envelope half-time in beats
		0.5	; bandpass 1 bandwidth / oscillator frequency
		0.0625	; highpass 1 freq. / oscillator frequency
		0.5	; "allpass" 1 start freq. / oscillator frq.
		0.125	; "allpass" 1 envelope half-time in beats
		1.0	; "allpass" 1 end frq. / oscillator frequency
		8	; highpass 2 frequency / base frequency
		-3	; highpass 2 output gain
		0.5	; highpass 3 freq. / base frequency
		-0.4	; highpass 3 output gain
		1.5	; output highpass frequency / base frequency
		2	; output highpass resonance
		16	; output lowpass start freq 1 / oscillator frq.
		0.01	; output lowpass frequency 1 half-time in beats
		16	; output lowpass start freq 2 / oscillator frq.
		0.08	; output lowpass frequency 2 half-time in beats
		7040	; noise bandpass start frequency in Hz
		7040	; noise bandpass end frequency in Hz
		2	; noise bandpass bandwidth / frequency
		3520	; noise lowpass start frequency (Hz)
		55	; noise lowpass end frequency (Hz)
		0.0833	; noise filter envelope half-time in beats
		0.01	; noise attack time (in seconds)
		0.3333	; noise decay half-time (in beats)
		0.5	; noise mix

/* ---- TR-808 bass drum ---- */

f 25 0 16 -2	30000			/* amplitude scale	     */
		0.0215			/* delay		     */
		0.08			/* release time		     */
		0	1	0	/* X, Y, Z coordinates	     */
		32			/* base freq. (MIDI note)    */
		4			/* start freq. / base frq.   */
		0.007			/* frq. envelope half-time   */
		0.25			/* start phase (0..1)	     */
		3000			/* lowpass filter frequency  */
		0.25			/* decay half-time	     */

/* ---- hand clap ---- */

f 30 0 32 -2	550000000		/* amplitude scale	     */
		0.010			/* delay		     */
		0.02			/* release time		     */
		-0.5	2	0	/* X, Y, Z coordinates	     */
		1046.5			/* bandpass frequency	     */
		4186	0.03	261.63	/* bandwidth envelope start, */
					/* half-time, and end value  */
		0.011	0.023	0.031	/* delay 2, 3, and 4	     */
		0.0167	0.0167	0.0167	/* decay 1, 2, and 3	     */
		0.5			/* decay 4		     */

/* ---- TR-808 cowbell ---- */

f 35 0 16 -2	10000			/* amplitude scale	     */
		0.018			/* delay		     */
		0.05			/* release time		     */
		1.3	-1.5	0	/* X, Y, Z coordinates	     */
		73	80		/* osc 1, 2 freq (MIDI note) */
		20000			/* lowpass filter start frq. */
		0.025			/* filter envelope half-time */
		4000			/* lowpass filter end freq.  */
		0.002			/* attack time		     */
		0.03	0.3		/* decay time 1, level 1     */
		0.05			/* decay 2 half-time	     */
		4			/* resonance at osc 2 freq.  */

/* ---- TR-808 hi-hat (open) ---- */

; oscillator frequencies taken from Steven Cook's 808HiHat.orc

f 40 0 32 -2	20000			/* amplitude scale	     */
		0.02			/* delay		     */
		0.04			/* release time		     */
		-0.7	-2	0	/* X, Y, Z coordinates	     */
		73			/* base freq. (MIDI note)    */
		1.4471	1.6170		/* osc 2, 3 freq. / base frq */
		1.9265	2.5028	2.6637	/* osc 4, 5, 6 frq / base f. */
		0.25			/* distort start (see orc)   */
		1			/* distortion env. half-time */
		0.25			/* distort end		     */
		5400	1.0		/* highpass freq, resonance  */
		0.0005			/* attack time		     */
		0.2	0.5		/* decay time 1, level 1     */
		0.2			/* decay 2 half-time	     */

/* ---- TR-808 hi-hat (closed) ---- */

f 41 0 32 -2	20000			/* amplitude scale	     */
		0.02			/* delay		     */
		0.04			/* release time		     */
		-1.87	-1	0	/* X, Y, Z coordinates	     */
		73			/* base freq. (MIDI note)    */
		1.4471	1.6170		/* osc 2, 3 freq. / base frq */
		1.9265	2.5028	2.6637	/* osc 4, 5, 6 frq / base f. */
		0.25			/* distort start (see orc)   */
		1			/* distortion env. half-time */
		0.25			/* distort end		     */
		5400	1.0		/* highpass freq, resonance  */
		0.0005			/* attack time		     */
		0.025	0.5		/* decay time 1, level 1     */
		0.025			/* decay 2 half-time	     */

/* ---- TR-808 cymbal ---- */

f 42 0 32 -2	22000			/* amplitude scale	     */
		0.018			/* delay		     */
		0.1			/* release time		     */
		0.7	2.5	0	/* X, Y, Z coordinates	     */
		73			/* base freq. (MIDI note)    */
		1.4471	1.6170		/* osc 2, 3 freq. / base frq */
		1.9265	2.5028	2.6637	/* osc 4, 5, 6 frq / base f. */
		1.0			/* distort start (see orc)   */
		0.2			/* distortion env. half-time */
		0.0625			/* distort end		     */
		5400	0.7071		/* highpass freq, resonance  */
		0.0005			/* attack time		     */
		0.04	0.5		/* decay time 1, level 1     */
		0.4			/* decay 2 half-time	     */

/* ---- TR-909 snare drum 1 ---- */

f 50 0 32 -2	20000			/* amplitude scale	     */
		0.02			/* delay		     */
		0.04			/* release time		     */
		-0.5	1.25	0	/* X, Y, Z coordinates	     */
		49			/* base freq. (MIDI note)    */
		3			/* start freq. / base frq.   */
		0.005			/* frequency env. half-time  */
		0.5	0.005	0.2	/* FM depth start, envelope  */
					/*   half-time, end	     */
		1.4983			/* osc 2 frq. / osc 1 frq.   */
		1.0	0.01	0	/* osc 2 amp. start, env.    */
					/*   half-time, end	     */
		2500	10000		/* noise BP freq., bandwidth */
		0	0.01	0.7	/* noise amp. start, env.    */
					/*   half-time, end	     */
		0.04			/* decay envelope half-time  */

/* ---- TR-909 snare drum 2 ---- */

f 51 0 32 -2	20000			/* amplitude scale	     */
		0.02			/* delay		     */
		0.04			/* release time		     */
		1	0.25	0	/* X, Y, Z coordinates	     */
		52			/* base freq. (MIDI note)    */
		2			/* start freq. / base frq.   */
		0.005			/* frequency env. half-time  */
		1.0	0.002	0	/* FM depth start, envelope  */
					/*   half-time, end	     */
		1.4983			/* osc 2 frq. / osc 1 frq.   */
		1	0.02	0	/* osc 2 amp. start, env.    */
					/*   half-time, end	     */
		5000	7500		/* noise BP freq., bandwidth */
		0	0.008	0.35	/* noise amp. start, env.    */
					/*   half-time, end	     */
		0.03			/* decay envelope half-time  */

/* ---- TR-909 snare drum 3 ---- */

f 52 0 32 -2	17000			/* amplitude scale	     */
		0.02			/* delay		     */
		0.04			/* release time		     */
		0.75	1	0	/* X, Y, Z coordinates	     */
		52			/* base freq. (MIDI note)    */
		2.0			/* start freq. / base frq.   */
		0.005			/* frequency env. half-time  */
		0.2	0.01	0	/* FM depth start, envelope  */
					/*   half-time, end	     */
		1.4983			/* osc 2 frq. / osc 1 frq.   */
		1	0.04	0	/* osc 2 amp. start, env.    */
					/*   half-time, end	     */
		5000	7500		/* noise BP freq., bandwidth */
		0	0.005	1	/* noise amp. start, env.    */
					/*   half-time, end	     */
		0.03			/* decay envelope half-time  */

/* ---- TR-909 snare drum 4 ---- */

f 53 0 32 -2	15000			/* amplitude scale	     */
		0.02			/* delay		     */
		0.04			/* release time		     */
		-0.75	0.75	0	/* X, Y, Z coordinates	     */
		56			/* base freq. (MIDI note)    */
		2			/* start freq. / base frq.   */
		0.0015			/* frequency env. half-time  */
		2.0	0.001	0	/* FM depth start, envelope  */
					/*   half-time, end	     */
		1.4983			/* osc 2 frq. / osc 1 frq.   */
		1	0.02	0	/* osc 2 amp. start, env.    */
					/*   half-time, end	     */
		5000	7500		/* noise BP freq., bandwidth */
		0	0.005	1	/* noise amp. start, env.    */
					/*   half-time, end	     */
		0.03			/* decay envelope half-time  */

/* ---- hi tom ---- */

f 57 0 32 -2	25000			/* amplitude scale	     */
		0.018			/* delay		     */
		0.04			/* release time		     */
		2	-1	0	/* X, Y, Z coordinates	     */
		49			/* base freq. (MIDI note)    */
		1.3333			/* start freq. / base frq.   */
		0.135			/* frequency env. half-time  */
		2.0			/* osc 2 frq. / osc 1 frq.   */
		1	0.01	0	/* osc 2 amp. start, env.    */
					/*   half-time, end	     */
		0			/* osc 1 and 2 phase (0 - 1) */
		0.083			/* invert 1 delay * base frq */
		0.135			/* invert 2 delay * base frq */
		10000			/* lowpass frequency	     */
		208	208		/* noise BP freq., bandwidth */
		1			/* noise comb freq / base f. */
		0.4			/* noise comb feedback	     */
		6000			/* noise lowpass frequency   */
		5	0.08	0	/* noise amp. start, env.    */
					/*   half-time, end	     */
		0.18			/* decay envelope half-time  */

/* ---- mid tom ---- */

f 58 0 32 -2	25000			/* amplitude scale	     */
		0.018			/* delay		     */
		0.04			/* release time		     */
		1	-2	0	/* X, Y, Z coordinates	     */
		44			/* base freq. (MIDI note)    */
		1.3333			/* start freq. / base frq.   */
		0.135			/* frequency env. half-time  */
		2.0			/* osc 2 frq. / osc 1 frq.   */
		1	0.01	0	/* osc 2 amp. start, env.    */
					/*   half-time, end	     */
		0			/* osc 1 and 2 phase (0 - 1) */
		0.083			/* invert 1 delay * base frq */
		0.135			/* invert 2 delay * base frq */
		10000			/* lowpass frequency	     */
		208	208		/* noise BP freq., bandwidth */
		1			/* noise comb freq / base f. */
		0.4			/* noise comb feedback	     */
		6000			/* noise lowpass frequency   */
		5	0.08	0	/* noise amp. start, env.    */
					/*   half-time, end	     */
		0.18			/* decay envelope half-time  */

/* ---- low tom ---- */

f 59 0 32 -2	25000			/* amplitude scale	     */
		0.018			/* delay		     */
		0.04			/* release time		     */
		-2	-1	0	/* X, Y, Z coordinates	     */
		37			/* base freq. (MIDI note)    */
		1.3333			/* start freq. / base frq.   */
		0.135			/* frequency env. half-time  */
		2.0			/* osc 2 frq. / osc 1 frq.   */
		1	0.01	0	/* osc 2 amp. start, env.    */
					/*   half-time, end	     */
		0			/* osc 1 and 2 phase (0 - 1) */
		0.083			/* invert 1 delay * base frq */
		0.135			/* invert 2 delay * base frq */
		10000			/* lowpass frequency	     */
		208	208		/* noise BP freq., bandwidth */
		1			/* noise comb freq / base f. */
		0.4			/* noise comb feedback	     */
		6000			/* noise lowpass frequency   */
		5	0.08	0	/* noise amp. start, env.    */
					/*   half-time, end	     */
		0.18			/* decay envelope half-time  */

/* ---- rim shot ---- */

f 56 0 32 -2	10000			/* amplitude scale	     */
		0.0195			/* delay		     */
		0.04			/* release time		     */
		-1.5	0.5	0	/* X, Y, Z coordinates	     */
		56			/* base freq. (MIDI note)    */
		2			/* start freq. / base frq.   */
		0.0025			/* frequency env. half-time  */
		3	0.02	0	/* FM depth start, envelope  */
					/*   half-time, end	     */
		0.1	2000		/* noise amp., lowpass frq.  */
		4	0.006	0	/* amplitude (before	     */
					/*   distortion) start, env. */
					/*   half-time, end	     */
		-4	4000	0.0002	/* highpass filtered signal  */
					/*   (after distortion) amp, */
					/*   cutoff frequency, delay */
		20000	0.009	100	/* output lowpass start frq, */
					/*   env. half-time, end frq */

; ======== list of available instruments ========

; p-fields for all instruments:
;
;   p2: start time
;   p3: duration
;   p5: velocity
;
; instruments are selected by p1 and p4:
;
;   +------------------+------+------+
;   |    instrument    |  p1  |  p4  |
;   +------------------+------+------+
;   | crash cymbal 1   |  10  |  10  |
;   +------------------+------+------+
;   | crash cymbal 2   |  10  |  11  |
;   +------------------+------+------+
;   | reverse cymbal   |  10  |  12  |
;   +------------------+------+------+
;   | open hi-hat      |  10  |  13  |
;   +------------------+------+------+
;   | closed hi-hat    |  10  |  14  |
;   +------------------+------+------+
;   | tambourine       |  10  |  15  |
;   +------------------+------+------+
;   | open hi-hat 2    |  10  |  16  |
;   +------------------+------+------+
;   | ride cymbal      |  10  |  17  |
;   +------------------+------+------+
;   | bass drum        |  20  |  20  |
;   +------------------+------+------+
;   | TR-808 bass drum |  21  |  25  |
;   +------------------+------+------+
;   | hand clap        |  30  |  30  |
;   +------------------+------+------+
;   | TR-808 cowbell   |  31  |  35  |
;   +------------------+------+------+
;   | TR-808 open      |  40  |  40  |
;   | hi-hat           |      |      |
;   +------------------+------+------+
;   | TR-808 closed    |  40  |  41  |
;   | hi-hat           |      |      |
;   +------------------+------+------+
;   | TR-808 cymbal    |  40  |  42  |
;   +------------------+------+------+
;   | TR-909 snare 1   |  50  |  50  |
;   +------------------+------+------+
;   | TR-909 snare 2   |  50  |  51  |
;   +------------------+------+------+
;   | TR-909 snare 3   |  50  |  52  |
;   +------------------+------+------+
;   | TR-909 snare 4   |  50  |  53  |
;   +------------------+------+------+
;   | high tom         |  51  |  57  |
;   +------------------+------+------+
;   | mid tom          |  51  |  58  |
;   +------------------+------+------+
;   | low tom          |  51  |  59  |
;   +------------------+------+------+
;   | rim shot         |  52  |  56  |
;   +------------------+------+------+

; ---------------------------------------------------------------------

;#include "score.sco"

i 21	    0.0000	    2.0007	 25	127
i 40	    0.0051	    0.2448	 41	127
i 40	    0.0000	    3.9974	 42	127
i 31	    0.4947	    0.7124	 35	127
i 30	    1.0143	    0.9931	 30	127
i 40	    1.0062	    0.2550	 41	127
i 31	    1.2572	    0.4379	 35	127
i 10	    1.7534	    0.2203	 15	127
i 31	    1.7574	    1.0008	 35	127
i 52	    1.7493	    0.1942	 56	120
i 10	    2.0024	    0.2250	 15	127
i 40	    2.0036	    0.2569	 41	127
i 52	    1.9992	    0.2067	 56	120
i 52	    2.2536	    0.1974	 56	120
i 52	    2.4990	    0.2129	 56	120
i 30	    3.0170	    0.9817	 30	127
i 40	    3.0051	    0.2532	 41	127
i 21	    3.5011	    0.2040	 25	127
i 40	    3.5064	    0.4986	 40	127
i 21	    4.0091	    0.1958	 25	127
i 40	    4.0013	    0.2517	 41	127
i 31	    4.5072	    0.7002	 35	127
i 30	    5.0141	    0.9863	 30	127
i 40	    5.0079	    0.2568	 41	127
i 31	    5.2533	    0.4524	 35	127
i 10	    5.7583	    0.2150	 15	127
i 31	    5.7480	    1.0054	 35	127
i 52	    5.7491	    0.1959	 56	120
i 10	    5.9970	    0.2255	 15	127
i 40	    5.9995	    0.2539	 41	127
i 52	    5.9995	    0.2004	 56	120
i 52	    6.5055	    0.1974	 56	120
i 30	    7.0188	    0.9841	 30	127
i 40	    7.0114	    0.2397	 41	127
i 52	    7.2579	    0.1964	 56	120
i 40	    7.4996	    0.5026	 40	127
i 21	    8.0015	    4.0056	 25	127
i 40	    8.0031	    3.9937	 42	127
i 10	   12.0076	    3.8617	 12	127
i 10	   16.0051	    0.1018	 14	127
i 10	   16.0059	    3.9877	 10	127
i 20	   16.0001	    0.4075	 20	127
i 10	   16.5089	    0.3038	 16	127
i 10	   17.0149	    0.0934	 14	127
i 20	   17.0198	    0.3849	 20	127
i 30	   17.0048	    0.9969	 30	127
i 10	   17.5044	    0.2955	 16	127
i 52	   17.7508	    0.1993	 56	120
i 10	   17.9964	    0.1113	 14	127
i 20	   17.9952	    0.4045	 20	127
i 52	   18.0032	    0.2023	 56	120
i 52	   18.2547	    0.1925	 56	120
i 10	   18.5033	    0.3030	 16	127
i 52	   18.5081	    0.1994	 56	120
i 10	   19.0073	    0.0995	 14	127
i 20	   19.0179	    0.3923	 20	127
i 30	   19.0133	    0.9934	 30	127
i 10	   19.5064	    0.2956	 16	127
i 10	   19.9940	    0.1088	 14	127
i 20	   19.9985	    0.3984	 20	127
i 10	   20.4955	    0.3148	 16	127
i 10	   21.0005	    0.1056	 14	127
i 20	   21.0101	    0.3935	 20	127
i 30	   21.0175	    0.9774	 30	127
i 10	   21.4967	    0.3017	 16	127
i 50	   21.7525	    0.2221	 51	127
i 10	   21.9939	    0.1061	 14	127
i 20	   22.0022	    0.4032	 20	127
i 50	   22.0029	    0.4934	 51	127
i 10	   22.5061	    0.3088	 16	127
i 10	   23.0077	    0.1099	 14	127
i 20	   23.0074	    0.3985	 20	127
i 30	   23.0099	    0.9865	 30	127
i 10	   23.4962	    0.3099	 16	127
i 10	   24.0014	    0.0974	 14	127
i 20	   23.9968	    0.4062	 20	127
i 50	   24.2538	    0.2200	 50	127
i 10	   24.4982	    0.3145	 16	127
i 50	   24.5032	    0.2226	 50	127
i 10	   25.0138	    0.0948	 14	127
i 20	   25.0113	    0.3908	 20	127
i 30	   25.0122	    0.9823	 30	127
i 50	   25.0017	    0.2264	 50	127
i 10	   25.4990	    0.2975	 16	127
i 50	   25.5022	    0.2174	 50	127
i 52	   25.7467	    0.2036	 56	120
i 10	   26.0005	    0.0953	 14	127
i 20	   25.9927	    0.4066	 20	127
i 50	   25.9950	    0.2286	 50	127
i 52	   26.0053	    0.2001	 56	120
i 50	   26.2551	    0.2203	 50	127
i 52	   26.2521	    0.2082	 56	120
i 10	   26.5066	    0.3033	 16	127
i 50	   26.5007	    0.2339	 50	127
i 50	   26.7595	    0.2198	 50	127
i 52	   26.7550	    0.2020	 56	120
i 10	   27.0137	    0.1018	 14	127
i 20	   27.0150	    0.3869	 20	127
i 30	   27.0097	    0.9942	 30	127
i 50	   27.0125	    0.2151	 50	127
i 50	   27.2564	    0.2215	 50	127
i 10	   27.5024	    0.3001	 16	127
i 50	   27.5017	    0.2231	 50	127
i 50	   27.7563	    0.2173	 50	127
i 10	   28.0005	    4.0018	 10	127
i 51	   28.7616	    0.6988	 57	127
i 30	   29.0125	    0.9860	 30	127
i 51	   29.5018	    0.4537	 57	127
i 50	   29.7520	    0.2231	 51	127
i 50	   30.0049	    0.4977	 51	127
i 51	   30.0066	    0.6979	 58	127
i 51	   30.7608	    0.6857	 58	127
i 30	   31.0146	    0.9882	 30	127
i 51	   31.5007	    0.4546	 59	127
i 10	   31.9945	    0.1144	 14	127
i 10	   31.9993	    0.4729	 17	100
i 10	   31.9974	    3.9964	 10	127
i 20	   32.0026	    0.4096	 20	127
i 10	   32.5036	    0.3077	 16	127
i 10	   32.5042	    0.4085	 13	127
i 10	   32.5019	    0.4806	 17	 90
i 10	   33.0127	    0.0960	 14	127
i 10	   33.0120	    0.4559	 17	100
i 20	   33.0100	    0.3891	 20	127
i 30	   33.0139	    0.9899	 30	127
i 10	   33.4927	    0.3003	 16	127
i 10	   33.5013	    0.4052	 13	127
i 10	   33.5042	    0.4687	 17	 90
i 10	   34.0044	    0.1017	 14	127
i 10	   34.0011	    0.4708	 17	100
i 20	   34.0046	    0.4045	 20	127
i 10	   34.5030	    0.2987	 16	127
i 10	   34.5076	    0.4060	 13	127
i 10	   34.4971	    0.4774	 17	 90
i 10	   35.0104	    0.1015	 14	127
i 10	   35.0178	    0.4633	 17	100
i 20	   35.0062	    0.3941	 20	127
i 30	   35.0083	    0.9932	 30	127
i 10	   35.2569	    0.1958	 13	127
i 10	   35.4990	    0.2991	 16	127
i 10	   35.4969	    0.3958	 13	127
i 10	   35.4969	    0.4824	 17	 90
i 10	   35.9949	    0.1125	 14	127
i 10	   35.9937	    0.4813	 17	100
i 20	   35.9978	    0.4064	 20	127
i 10	   36.5084	    0.3013	 16	127
i 10	   36.5114	    0.3997	 13	127
i 10	   36.5037	    0.4767	 17	 90
i 10	   37.0112	    0.0965	 14	127
i 10	   37.0145	    0.4578	 17	100
i 20	   37.0145	    0.3894	 20	127
i 30	   37.0082	    0.9898	 30	127
i 10	   37.4949	    0.3056	 16	127
i 10	   37.4972	    0.4062	 13	127
i 10	   37.5008	    0.4631	 17	 90
i 10	   38.0051	    0.0997	 14	127
i 10	   38.0033	    0.4671	 17	100
i 20	   37.9957	    0.4058	 20	127
i 10	   38.5032	    0.3064	 16	127
i 10	   38.4995	    0.4095	 13	127
i 10	   38.5082	    0.4751	 17	 90
i 10	   39.0149	    0.0966	 14	127
i 10	   39.0037	    0.4669	 17	100
i 10	   39.0117	    0.8689	 12	127
i 20	   39.0130	    0.3887	 20	127
i 30	   39.0114	    0.9907	 30	127
i 50	   39.0122	    0.2130	 53	127
i 50	   39.2550	    0.2146	 53	127
i 10	   39.4978	    0.2978	 16	127
i 10	   39.5045	    0.3985	 13	127
i 10	   39.5007	    0.4681	 17	 90
i 50	   39.5055	    0.2162	 53	127
i 50	   39.7578	    0.2124	 53	127
i 10	   39.9968	    0.1046	 14	127
i 10	   40.0018	    0.4737	 17	100
i 10	   40.0031	    3.9951	 10	127
i 20	   40.0023	    0.3987	 20	127
i 10	   40.5024	    0.3002	 16	127
i 10	   40.5068	    0.4048	 13	127
i 10	   40.5057	    0.4773	 17	 90
i 10	   41.0159	    0.0851	 14	127
i 10	   41.0115	    0.4659	 17	100
i 20	   41.0133	    0.3991	 20	127
i 30	   41.0114	    0.9968	 30	127
i 10	   41.5038	    0.3050	 16	127
i 10	   41.5070	    0.3973	 13	127
i 10	   41.5015	    0.4691	 17	 90
i 10	   41.9940	    0.1123	 14	127
i 10	   41.9984	    0.4710	 17	100
i 20	   41.9976	    0.4042	 20	127
i 10	   42.5116	    0.3017	 16	127
i 10	   42.5040	    0.4044	 13	127
i 10	   42.4966	    0.4833	 17	 90
i 10	   43.0070	    0.1031	 14	127
i 10	   43.0040	    0.4688	 17	100
i 20	   43.0153	    0.3885	 20	127
i 30	   43.0125	    0.9783	 30	127
i 10	   43.2558	    0.1953	 13	127
i 10	   43.4951	    0.3109	 16	127
i 10	   43.4987	    0.3976	 13	127
i 10	   43.5046	    0.4638	 17	 90
i 10	   44.0042	    0.1022	 14	127
i 10	   43.9973	    0.4769	 17	100
i 10	   44.0057	    1.0004	 11	127
i 20	   43.9983	    0.4066	 20	127
i 10	   44.4935	    0.3159	 16	127
i 10	   44.5056	    0.4029	 13	127
i 10	   44.4972	    0.4830	 17	 90
i 10	   45.0026	    0.1079	 14	127
i 10	   45.0085	    0.4603	 17	100
i 10	   45.0022	    0.9947	 11	127
i 20	   45.0068	    0.4015	 20	127
i 30	   45.0067	    0.9872	 30	127
i 10	   45.4978	    0.3109	 16	127
i 10	   45.5008	    0.4043	 13	127
i 10	   45.5068	    0.4655	 17	 90
i 10	   46.0003	    0.1014	 14	127
i 10	   45.9974	    0.4658	 17	100
i 10	   46.0062	    1.0039	 11	127
i 20	   45.9961	    0.4099	 20	127
i 50	   45.9976	    0.2303	 52	127
i 50	   46.2514	    0.2246	 52	127
i 10	   46.4944	    0.3079	 16	127
i 10	   46.5024	    0.4083	 13	127
i 10	   46.5044	    0.4793	 17	 90
i 50	   46.5003	    0.2209	 52	127
i 50	   46.7556	    0.2323	 52	127
i 10	   47.0120	    0.1037	 14	127
i 10	   47.0099	    0.4586	 17	100
i 10	   47.0113	    0.9852	 11	127
i 20	   47.0157	    0.3963	 20	127
i 30	   47.0049	    0.9938	 30	127
i 50	   47.0145	    0.2167	 52	127
i 50	   47.2595	    0.2180	 52	127
i 10	   47.4959	    0.3080	 16	127
i 10	   47.5031	    0.4019	 13	127
i 10	   47.4933	    0.4715	 17	 90
i 50	   47.5062	    0.2136	 52	127
i 50	   47.7535	    0.2214	 52	127
i 10	   47.9961	    4.0098	 11	127
i 20	   48.0006	    1.0092	 20	127

; ---------------------------------------------------------------------

; output instrument (p6: volume)

i 99 0 53 0.3

e	; end of score

</CsScore>
</CsoundSynthesizer>    

