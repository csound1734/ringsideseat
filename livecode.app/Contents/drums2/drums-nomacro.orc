
/* ======== drum instruments by Istvan Varga, Mar 10 2002 ======== */

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

; mono output file name (for ext convolve unit)

gS_sndfl_mono = "mono_out.pcm"

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

 opcode Veloc2Amp, i, ii ;macro VELOC2AMP originally
ivel, imaxamp xin
ires = ((imaxamp) * (0.0039 + (ivel) * (ivel) / 16192))
xout ires
 endop

 opcode Midi2Cps, i, i ;macro MIDI2CPS
inotenum xin
ires = (440 * exp(log(2) * ((inotenum) - 69) / 12))
xout ires
 endop

 opcode Pow2Ceil, i, i ;macro POW2CEIL
ip2c_x xin
ires = (int(0.5 + exp(log(2) * int(1.01 + log(ip2c_x) / log(2)))))
xout ires
 endop

 opcode Note2Freq, i, i ;macro NOTE2FREQ
ixnote xin
ires = (exp(log(2) * (ixnote) / 12))
xout ires
 endop

 opcode Cps2Fnum, i, ii ;macro CPS2FNUM
ixcps, ibasefnum xin
ires = int(69.5 + (ibasefnum) + 12 * log((ixcps) / 440) / log(2))
xout ires
 endop

gi_PI = 3.14159265
gi_TWOPI = (2 * 3.14159265)

; ---- instr 1: render tables for cymbal instruments ----

	instr 101

ifn	=  p4		/* ftable number		*/
inumh	=  p5		/* number of partials		*/
iscl	=  p6		/* amp. scale			*/
itrns	=  p7		/* transpose (in semitones)	*/
isd	=  p8		/* random seed (1 to 2^31 - 2)	*/
idst	=  p9		/* amplitude distribution	*/

imaxf	Note2Freq (itrns) * gibwd		; max. frequency
itmp	rnd31 1, 0, isd				; initialize seed

; create empty table for parameters

ifln	Pow2Ceil (3 * inumh)
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

	instr 110

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
iamp	Veloc2Amp (ivel), (iscl)
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

