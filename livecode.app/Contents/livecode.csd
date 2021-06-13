<Cabbage>
form caption("Untitled") bundle("reserveInstruments.txt") size(1200, 200), colour(58, 110, 182), pluginId("def1") guiMode("queue")
csoundoutput bounds(600, 010, 580, 180)
</Cabbage>
<CsoundSynthesizer>
<CsOptions>
-+rtmidi=NULL -M0 --midi-key-cps=4 --midi-velocity-amp=5 --port=1734
</CsOptions>
<CsInstruments>
;  set global constants
sr = 48000
ksmps = 32
nchnls = 2

;  Compile "blank" instruments (no code).
;these will be default MIDI instruments
;(with livecoding, of course, we can re-
;define these instruments later onthefly).
#include "reserveInstruments.txt" ;see text file in directory

;  instr 599 is a one-time setup instrument.
;it runs at program init time to generate 
;"beatmatcher    panels" which are unused,
;invisible, and inactive at performance - but
;they do exist. We'll make use of them later
;on-the-fly using the cabbageSet opcode.
event_i "i", 599, 0, 0 
instr 599      ; 
    icount = 0
    iN     = 128 ; number of beatmatcher panels
    continue:   ;this is a control flow loop, C-style.
        if (icount<iN) goto newPanel ;iN new panels will be made
        goto skip
    
    newPanel: ;create a new beatmatcher
        Sgroupchn sprintf "\"bm%d\"", icount+1 ;useful generated string
        iX = ((icount%2==0) ? 200 : 400) ;iX = left/right position for each panel in pixels\
        ;  generating the cabbage code as string variables.
        ;each line creates the code for an element (widget) within one beatmatcher panel.
        ;the following lines could be placed into their own opcode.
        Sgroupbox sprintf "bounds(%d, 10, 180, 180) channel(%s) visible(0) ", iX, Sgroupchn
        SencoderL sprintf "bounds(80,60,80,80), parent(%s) channel(\"%sLarge\") colour(60,60,60) trackerColour(255,255,255)", Sgroupchn, Sgroupchn
        SencoderS sprintf "bounds(20,30,30,30), parent(%s) channel(\"%sSmall\") colour(60,60,60) trackerColour(255,255,255)", Sgroupchn, Sgroupchn
        ;  each line in the next section actually communicates from Csound to cabbage 
        cabbageCreate "groupbox", Sgroupbox
        cabbageCreate "encoder", SencoderL
        cabbageCreate "encoder", SencoderS
        ;  back to loop control flow
        icount += 1
        igoto continue
    
    skip: ;if the above is finished, end up here. everything is done in at i-time.
endin

;  Instrument prints the names of all channels
;used by Cabbage widgets, by storing them in an
;array.
instr 598    
    Swidgets[] cabbageGetWidgetChannels 
    icount lenarray Swidgets
    ii = 0
    printf_i "\nWidget Channel Names:\n", 1
    continue:
	if ii<icount goto printnow
        goto skip
    printnow:
    	printf_i "%s\n", 1, Swidgets[ii] 
 	ii += 1
	goto continue
    skip:
endin

 opcode seeBeatmatcher, 0, ii
iN, ivis xin ;which beatmatcher and visibility
iN = p4
ivis = p5
Scode sprintf "visible(%d)", ivis
Schan sprintf "bm%d", iN
cabbageSet Schan, Scode
 endop


    

</CsInstruments>
<CsScore>
;causes Csound to run for about 7000 years...
f0 z
                                                                                          ;
</CsScore>
</CsoundSynthesizer>
