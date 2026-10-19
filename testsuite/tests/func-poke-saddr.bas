PROC F1
  POKE $600, 1
  RETURN 2
ENDPROC

PROC F2
  RETURN $603
ENDPROC

PROC F3
  POKE $604, 5
  RETURN 6
ENDPROC

PROC F4
  POKE $607, 1
  RETURN 1
ENDPROC

' Function in POKE value: its body clobbers SADDR, so the wrapper must
' preserve the address for $601.
POKE $601, @F1()
? PEEK($600)
? PEEK($601)

' Function in POKE address: no SADDR is pending before the call.
POKE @F2(), 4
? PEEK($603)

' Expression value with a pending SADDR.
POKE $602, 10 + @F1()
? PEEK($602)

' Both address and value are function calls.
POKE @F2(), @F1()
? PEEK($603)

' DPOKE value needs SADDR preservation too.
DPOKE $605, @F3()
? PEEK($604)
? DPEEK($605)

' No pending SADDR: the wrapper can be removed.
IF @F4() THEN ? "YES"
? PEEK($607)
