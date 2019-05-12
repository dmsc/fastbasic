' Test for statements "MOVE" and "-MOVE"
? "Start"
s1$ = "initial string number 1, all lowercase"

' Nondestructive moves
? s1$
move adr(s1$)+8, adr(s1$)+5, 7
? s1$
-move adr(s1$)+5, adr(s1$)+8, 7
? s1$

' Destructive moves
s1$ = "initial string number 1, all lowercase"
? s1$
move adr(s1$)+5, adr(s1$)+8, 7
? s1$
s1$ = "initial string number 1, all lowercase"
-move adr(s1$)+8, adr(s1$)+5, 7
? s1$

' Fill big areas
dim a(519) byte

exec sum_a

' Test lengths about 256 / MOVE
for x=249 to 260
  mset adr(a), 519, 0
  a(0) = 12
  move adr(a), adr(a)+1, x
  exec sum_a
next

' Test addresses about 256 / MOVE
ad = ((adr(a) + 265) & $FF00) - adr(a)
for x=ad-3 to ad+3
  mset adr(a), 519, 0
  a(x+1) = 1
  move adr(a)+x, adr(a)+2+x, 32
  for i=ad-10 to ad+42 : ? a(i); : next
  ?
next

' Test lengths about 256 / -MOVE
for x=249 to 260
  mset adr(a), 519, 0
  a(x) = 12
  -move adr(a)+1, adr(a), x
  exec sum_a
next

' Test addresses about 256 / -MOVE
ad = ((adr(a) + 265) & $FF00) - adr(a)
for x=ad-3 to ad+3
  mset adr(a), 519, 0
  a(x+33) = 1
  -move adr(a)+2+x, adr(a)+x, 32
  for i=ad-10 to ad+42 : ? a(i); : next
  ?
next


proc sum_a
  s = 0
  for i=0 to 519
    s = s + a(i)
  next
  ? s
endproc
