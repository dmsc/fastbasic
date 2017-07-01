' Example of USR calls

' Define a Machine Language routine:
'  PLA / EOR $FF / TAX  / PLA / EOR $FF / RTS
data ml() byte = $68,$49,$FF,$AA,$68,$49,$FF,$60

' Calls the routine with different values
for i=0 to 1000 step 100
    ? i, usr(adr(ml),i)
next i

