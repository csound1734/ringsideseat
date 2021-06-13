
;========== NOTE ABSTRACTIONS
instr 1180
event_i "i", 781, 0, 0
event_i "i", 659, 0, 0.30, 20000, 454, 0
event_i "i", 659, 0, 0.30, 20000, 454, 1
endin

instr 1181
event_i "i", 659, 0, 0.10, 10000, 1834, 0
event_i "i", 659, 0, 0.10, 10000, 1834, 1
endin

instr 1182
event_i "i", 781, 0, 0
event_i "i", 659, 0, 0.60, 20000, 780, 0
event_i "i", 659, 0, 0.60, 20000, 780, 1
endin

;=========== SYNTHS ===========
instr 659
ares oscil p4, p5
aenv expon 1, p3, 0.05
ares *= aenv
zawm ares, p6
endin

;============= EFFECTS ==========
instr 671
ainL zar p4
ainR zar p5
ainL *= 1/0dbfs
ainR *= 1/0dbfs
ainL = tanh(2*ainL)
ainR = tanh(2*ainR)
ainL *= 0dbfs/2
ainR *= 0dbfs/2
zaw ainL, p4
zaw ainR, p5
endin

