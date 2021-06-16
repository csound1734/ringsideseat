

; ============ drums.sco - written by Istvan Varga, 2002 ============
/* Ported from score code to orc code by Jim Patalano, 2021 */

; ---- tempo ----

; -- instr 1: render tables for cymbal instruments --

; p3 : note length (should be 0)
; p4 : ftable number
; p5 : number of partials
; p6 : amp. scale
; p7 : transpose (in semitones)
; p8 : random seed (1 to 2^31 - 2)
; p9 : amplitude distribution

; ---- generate cymbal tables ----

event_i, "i", 101, 0, 0, 101, 600, 1, 0, 114, 3		; crash 2
event_i, "i", 101, 0, 0, 101, 600, 1, 0, 4, 6		; hihat
event_i, "i", 101, 0, 0, 101, 600, 1, 0, 213, 3		; crash 1
event_i, "i", 101, 0, 0, 101, 600, 1, 0, 427, 4		; crash 3 (not used)
gi_tab99 ftgen 99, 0, 16, -2,	0.3,	7500,	0,	1,	10500,	0.2,	\ ;parameters to generate tamb waveform
		0.3,	14000,	0.4,	1,	18000,	0.8 
gi_tamb ftgen 105, 0, 524288, -34, 99, 4, 1, -4		; tambourine waveform
event_i, "i", 101, 0, 0, 101, 600, 1, 0, 193, 6		; hihat
event_i, "i", 101, 0, 0, 101, 600, 1, 0, 19, 4		; ride
event_i, "i", 101, 0, 0, 101, 600, 1, 0, 7, 4		; ride 2 (not used)

; ---- misc. tables ----

; square wave

#include "fgen_h.orc" ;TODO: file fgen_h.sco must be ported to .orc code

gi_tab301 ftgen 301, 0, 16384, 7, 1, 8192, 1, 0, -1, 8192, -1
$FGEN128(300'4096'301'1)

; sawtooth wave

gi_tab501 ftgen 501, 0, 16384, 7, 1, 16384, -1
$FGEN128(500'4096'501'1)

; sine

gi_tabSin ftgen 700, 0, 4096, 10, 1

; window for cymbal instruments

gi_tabWn ftgen 100, 0, 16385, 5, 1, 16385, 0.01

; ---- include room parameters ----

#include "room.sco" ;TODO

; ================ instrument definitions ================

/* ---- crash cymbal 1 ---- */

gi_909Cr1 ftgen 10, 0, 32, -2,	900, \	; amplitude scale
		0.015, \	; delay
		0.1, \	; release time
		-1, \	; X
		1.87, \	; Y
		0, \	; Z
		103, \	; input table
		100, \	; window table
		0.225, \	; start grain duration in seconds
		0.10, \	; grain druaton envelope half-time
		0.1, \	; end grain duration
		40, \	; number of overlaps
		10000, \	; EQ start frequency
		1, \	; EQ frequency envelope half-time
		10000, \	; EQ end frequency
		1, \	; EQ start level (Q is level * 0.7071)
		0.14, \	; EQ level envelope half-time
		4, \	; EQ end level
		500, \	; highpass frequency
		20000, \	; lowpass frequency
		0.16, \	; decay env. half-time (n.a. in reverse mode)
		1, \	; reverse cymbal mode (0: on, 1: off)
		0.001, \	; delay time for chorus effect
		1, \	; non-delayed signal level
		0	; delayed signal level

