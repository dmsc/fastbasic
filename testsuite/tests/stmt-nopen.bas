' Test NOPEN SIO parameters and URL termination
'
' The URL is first made longer and then shorter, so the end of the
' shorter string contains a stale nonzero byte.  NOPEN must write a
' zero terminator at the new end.
URL$="N:http://example.com/bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb/"
URL$="N:http://example.com/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/"
NOPEN 3,4,2,URL$

P=DPEEK($304)
L=LEN(URL$)
A=PEEK(P)
B=PEEK(P+L-1)
Z=PEEK(P+L)
DEV=PEEK($300)
UNIT=PEEK($301)
CMD=PEEK($302)
TIM=PEEK($306)
MODE=PEEK($30A)
TRANS=PEEK($30B)
BLEN=DPEEK($308)
ERR=SERR()

? "dev="; DEV=$71
? "unit="; UNIT=3
? "cmd="; CMD=$4F
? "tim="; TIM=$1F
? "mode="; MODE=4
? "trans="; TRANS=2
? "len="; BLEN=256
? "first="; A=78
? "last="; B=47
? "nul="; Z=0
? "serr="; ERR=138

' Constant-string path: get_str_eol appends ATASCII EOL ($9B).
NOPEN 3,4,2,"N:http://www.textfiles.com/"
P=DPEEK($304)
L=LEN("N:http://www.textfiles.com/")
A=PEEK(P)
B=PEEK(P+L-1)
Z=PEEK(P+L)
ERR=SERR()

? "cfirst="; A=78
? "clast="; B=47
? "ceol="; Z=$9B
? "cserr="; ERR=138
