
' Tests error in comparison of two sub-strings,
' as both uses the same memory area!
A$="Dont Work"
IF A$[2,2] = A$[3,3] THEN ? "ERROR - EXPECTED"

B$=A$[2,2]
IF B$ = A$[3,3] THEN ? "ERROR - UNEXPECTED"

