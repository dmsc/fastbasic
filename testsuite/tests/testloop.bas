? "Test UNTIL"
' Check REPEAT/UNITL
a=0
repeat
 a=a+1
 ? a,
until a>=10
? "="; a
? "Test WHILE"
' Check WHILE/WEND
a=0
while a<10
 a=a+1
 ? a,
wend
? "="; a
? "Test DO/LOOP"
' Check DO/LOOP with EXIT
a=0
do
 a=a+1
 if a > 10
  exit
 endif
 ? a,
loop
? "="; a
? "Test nested loops"
' Check nested loops with multiple EXIT
b=1
repeat
 a=1
 while a<10
  c= a*a+b*b
  a=a+1
  if c > 50
   ? 1
   exit
  endif
  if a + b > 10
   ? 0
   exit
  endif
  ? c,
 wend
 b=b+1
until b>10

? "Test FOR"
for i=10 to 0 : ? i, : next i
? "="; i
if i <> 10 then ? "--- BAD ---"
for i=10 to 0 step -1: ? i, : next i
? "="; i
if i <> -1 then ? "--- BAD ---"
for i=0 to 10 : ? i, : next i
? "="; i
if i <> 11 then ? "--- BAD ---"
for i=0 to 10 step -1: ? i, : next i
? "="; i
if i <> 0 then ? "--- BAD ---"
for i=10 to -10 step 3: ? i, : next i
? "="; i
if i <> 10 then ? "--- BAD ---"
for i=10 to -10 step -3: ? i, : next i
? "="; i
if i <> -11 then ? "--- BAD ---"
for i=-10 to 10 step 3: ? i, : next i
? "="; i
if i <> 11 then ? "--- BAD ---"
for i=-10 to 10 step -3: ? i, : next i
? "="; i
if i <> -10 then ? "--- BAD ---"

? "Test nested FOR"
a = 0
for i=1 to 10
 for j=i to 10
  ? j,
  a = a + j
 next j
 ? "="; j
next i
? "="; a
? "Test nested FOR with EXIT"
a = 0 : l = 0
for i=1 to 10
 for j=i to 10
  ? j,
  a = a + j
  l = l + 1
  if l >= 7
   l = 0
   exit
  endif
 next j
 ? "="; l
next i
? "="; a

