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

' Consecutive constant word-address pokes with the same low byte share one
' value load.  The high byte of the first value must not affect the result.
POKE 1000, 1 : POKE 1001, 1
? PEEK(1000); " "; PEEK(1001)
POKE 1002, 257 : POKE 1003, 1
? PEEK(1002); " "; PEEK(1003)
POKE 1004, 1 : POKE 1005, 2
? PEEK(1004); " "; PEEK(1005)

' Comparing a variable with a constant byte read reverses the comparison so
' that PUSH+VAR_LOAD folds to PUSH_VAR_LOAD.
I = 3
POKE @@TMPCHR, 5
? I < PEEK(@@TMPCHR)
? I > PEEK(@@TMPCHR)
? I = PEEK(@@TMPCHR)
? I <> PEEK(@@TMPCHR)
