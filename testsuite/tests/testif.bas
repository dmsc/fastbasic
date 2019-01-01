? "Test 1"
a=1
if a=0
 ? 0
else
? "Test 2"
endif
? "Test 3"
if a=1
 ? "Test 4"
else
 ? 0
endif
? "Test 5"
if a=1
 ? "Test 6"
endif
? "Test 7"
if a=0
 ? 0
endif
? "Test 8"
if a=0 then ? 2
if a=1 then ? "Test 9"
' Test ELIF
for a=10 to 14
 if a=10
  ? "Test 10"
 elif a=11
  ? "Test 11"
 elif a=12
  ? "Test 12"
 else
  ? "Test 13/14"
 endif
next a
' Test ELIF 2
for a=15 to 17
 if a=15
  ? "Test 15"
 elif a=16
  ? "Test 16"
 endif
next a
