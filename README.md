# ringsideseat
#livecoding #Cabbage #Csound #generativemusic

# Instructions (Mac OS)

## Preparation
* Make sure you have the current version of Csound installed.

## Start program
* From Finder window, click on `livecode.app` **or**
* To execute from terminal, cd to `livecode.app/Contents/MacOS/`, then run `./livecode`

## Uploading a few files to the server (with netcat on local port 1734)
* `cat beatStructure.orc | nc -u 127.0.0.1 1734`  in other words, the running Csound instance from the cabbage program compiles this file
* `cat notes.orc | nc -u 127.0.0.1 1734`   now compile another file, notes.orc

## Performance, real-time
* First of all, MIDI input is accepted but at start-up there is nopremade MIDI instruments. To resolve this simply use livecoding (more on that in a sec) to input definitions for instr 1, instr 2, instr 3, ... instr 16. The first 16 instr are set to recieve MIDI events on channels 1-16.
* How to livecode: 
* * in a new terminal while the program is running, execute `nc -u 127.0.0.1 1734`. Now you can input UDP packets (whatever you type is transmitted) one line at a time.
* * See Csound manual. The prefix on the packet tells Csound what to do with it. Score events: `&i101 0 1` set channel value: `@tempo 148` etc.
* * Inputting code from the UDP client: in this way the UDP server accepts new orc code one-liners by themselves. For multi-line, enclose w/ curly brackets (`{}`) or use the cat-pipe strategy (see "Uploading", above). E.g. `giSeq ftgen 0,0,8,-2,780,780,780,780,782,781,781,781` generates a new table from the orchestra on-the-fly.
* Read the beatStructure.orc and notes.orc
