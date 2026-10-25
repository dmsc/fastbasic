' Test DCB setup of the other FujiNet statements
DIM BUF(4) BYTE

URL$="N:http://example.com/"
NOPEN 3,4,2,URL$

NCLOSE 3
? "cdev="; PEEK($300)=$71
? "cunit="; PEEK($301)=3
? "ccmd="; PEEK($302)=$43
? "cstat="; PEEK($303)=138
? "ctim="; PEEK($306)=$1F
? "clen="; DPEEK($308)=0

NSTATUS 3
? "sdev="; PEEK($300)=$71
? "sunit="; PEEK($301)=3
? "scmd="; PEEK($302)=$53
? "sstat="; PEEK($303)=138
? "stime="; PEEK($306)=$1F
? "sbuf="; DPEEK($304)=$2EA
? "slen="; DPEEK($308)=4

NGET 3,&BUF,4
? "gdev="; PEEK($300)=$71
? "gunit="; PEEK($301)=3
? "gcmd="; PEEK($302)=$52
? "gstat="; PEEK($303)=138
? "gtime="; PEEK($306)=$1F
? "gbuf="; DPEEK($304)=ADR(BUF)
? "glen="; DPEEK($308)=4
? "gaux="; DPEEK($30A)=4

NPUT 3,&BUF,4
? "pdev="; PEEK($300)=$71
? "punit="; PEEK($301)=3
? "pcmd="; PEEK($302)=$57
? "pstat="; PEEK($303)=138
? "ptime="; PEEK($306)=$1F
? "pbuf="; DPEEK($304)=ADR(BUF)
? "plen="; DPEEK($308)=4
? "paux="; DPEEK($30A)=4
