
A$="TEST.STRING INDEXING"

? A$[2]
? A$[2,10][3]
? A$[2,2][4]
? A$[2][3]

? A$
? A$[1]
? A$[1,5]
? A$[2]
? A$[2,5]
? A$[10]
for i=1 to 22 : ? i, ">"; A$[i] ; "<" : next i

for i=1 to 22 : ? i, ">"; A$[i,2] ; "<" : next i

for i=0 to 22 : ? i, ">"; A$[2,i] ; "<" : next i

for i=1 to 20 : ? i, i*i, str$(i*i)[2,1] : next i

 A$ = "Test Sub String"[6,3]
 ? ">";A$;"<"
 A$ = STR$(31415)[3,2]
 ? ">";A$;"<"

 A$="Hola"      : ? A$
 A$=+" y "      : ? A$
 A$ =+ "chao"   : ? A$

for i=1 to 25 : A$ =+ "-abcde->" : A$ =+ STR$(i*i) : ? A$ : next i
