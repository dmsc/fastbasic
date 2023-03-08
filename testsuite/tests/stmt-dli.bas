' Test for "DLI" statements
? "Start"

DLI SET d1 = $24 INTO $D01A
DLI SET d2 = $12 INTO $D018 INTO $D019 INTO $D01A
DLI SET d3 = $12 INTO $D018 WSYNC INTO $D019 WSYNC WSYNC WSYNC INTO $D01A
DLI SET d4 = $12 INTO $D018, $23 WSYNC INTO $D019

DATA var() BYTE = 1, 2, 3, 4
DLI SET d5 = var INTO $D01A
DLI SET d6 = var WSYNC INTO $D01A
DLI SET d7 = var INTO $D01A,
DLI        = $12 WSYNC INTO $D018

' Write contents of generated DLI machine code - should not change between versions
for i=0 to 18
    ? d1(i);",";
next
?
for i=0 to 24
    ? d2(i);",";
next
?
for i=0 to 36
    ? d3(i);",";
next
?
