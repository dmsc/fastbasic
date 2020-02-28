' Test for statement "DATA"
? "Start"

data arr1() byte = 1,2,3,4,254,255,0,
data        byte = 123,134,65,$ff,$0A


data arr2() word = -7,-5,-3,-1,0,7,
data             = 123,$5678,65535

data arr3() = 1,2,3,4

? "1: "; arr1(0);
for i=1 to 11 : ? ", "; arr1(i); : next
? : ? "2: "; arr2(0);
for i=1 to 8 : ? ", "; arr2(i); : next

a = adr(arr1)
? : ? "1: "; peek(a);
for i=1 to 11 : a = a + 1 : ? ", "; peek(a); : next
a = adr(arr2)
? : ? "2: "; dpeek(a);
for i=1 to 8 : a = a + 2:  ? ", "; dpeek(a); : next
?

data arr4() b. = "String", arr1, "Code"
? $(ADR(arr4))
? adr(arr1) - dpeek(ADR(arr4)+1+LEN($(ADR(arr4))))

