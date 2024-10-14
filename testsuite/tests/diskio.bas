? "Start"
open #1, 8, 0, "D:XXX"
? #1, "hola"
? #1, "chao";
? ERR()
close #1

? "INPUT"
open #2, 4, 0, "D:XXX"
input #2, A$
? ERR()
? A$
input #2, A$
? ERR()
? A$
close #2
? ERR()

? "BGET 9"
A$ = "XXXXYYYYZZZZ"
open #2, 4, 0, "D:XXX"
bget #2, adr(A$) + 1, 9
? ERR()
close #2
? ERR()
? A$

? "BGET 32"
A$ = "XXXXYYYYZZZZ"
open #2, 4, 0, "D:XXX"
bget #2, adr(A$) + 1, 32
? ERR()
close #2
? ERR()
? A$

' Write a big string
open #1, 8, 0, "D:XXX"
? #1, "Big 1: ";
FOR I=0 TO 19
  ? #1, "<STRING ";I; ">";
NEXT
? #1,
? #1, "Big 2: ";
FOR I=0 TO 25
  ? #1, "<STRING ";I+20; ">";
NEXT
? #1,
close #1

? "BIG INPUT"
open #2, 4, 0, "D:XXX"
input #2, A$
? ERR()
? A$, LEN(A$)
input #2, A$
? ERR()
? A$, LEN(A$)
close #2
? ERR()

