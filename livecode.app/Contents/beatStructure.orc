gkbeatTrig init 0

;call this instrument just once
instr beatTrig
chnset p4, "mainTempo"
ktempo chnget "mainTempo"
gkbeatTrig metro ktempo
endin

;used for instr 799 to schedule a stream of notes
 opcode beatSched, 0, ki
ktrig, itab xin ;tempo and instrument #
kinstr init 0
trigseq ktrig, 0, 16, 0, itab, kinstr
schedkwhen ktrig, 0, 100, kinstr, 0, 0
 endop

;remember to always create your ftable first
instr 799
itab = p4 ;table that gives an instrument number to activate per note
beatSched gkbeatTrig, itab
endin

;========================================================
;==		MASTER OUTPUTS			========
;=======================================================

/* clear all za # 0 thru 16 */
 instr 701
zacl 0, 16
 endin

/* first output whateveer stereo pair of za-spots you want,*/
 instr 700
ainL zar p4
ainR zar p5
outs ainL, ainR
 endin

