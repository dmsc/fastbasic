' Test for statement "SETCOLOR"
? "Start"

' Simple tests, test optimizer
setcolor 2,7,6
? peek($2C6)

j = 0
for col=0 to 4
  for i=col to 15 step 4
    ? col;" ";i;" ";j;": ";
    setcolor col, i, j
    ? peek($2C4+col)
    j = (j + 3) & 15
  next
next

