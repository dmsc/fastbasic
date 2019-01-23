' Test for function "CHR$"
? "Start"
? " ->";CHR$(65);CHR$(66);CHR$(67);"<- "
? " ->";CHR$(65);CHR$(66),CHR$(67);"<- "
A$=CHR$(65)
? A$="A", A$=CHR$(65), CHR$(65)=CHR$(65)
? A$="B", A$=CHR$(66), CHR$(65)=CHR$(66)
