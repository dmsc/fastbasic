' Test optimizations on "POKE" and "DPOKE" statements
? "Start"

' Test using compile time constants, constant numbers
' are tested in stmt-poke.bas

I=$34

POKE @@TMPCHR, 10 : ? PEEK(@@TMPCHR)
POKE @@TMPCHR, I  : ? PEEK(@@TMPCHR)
POKE @RUNAD, 10  : ? PEEK(@RUNAD)
POKE @RUNAD, I   : ? PEEK(@RUNAD)

I=$5432
DPOKE @@TMPCHR, 10  : ? DPEEK(@@TMPCHR)
DPOKE @@TMPCHR, 500 : ? DPEEK(@@TMPCHR)
DPOKE @@TMPCHR, I   : ? DPEEK(@@TMPCHR)
DPOKE @RUNAD, 10   : ? DPEEK(@RUNAD)
DPOKE @RUNAD, 500  : ? DPEEK(@RUNAD)
DPOKE @RUNAD, I    : ? DPEEK(@RUNAD)

