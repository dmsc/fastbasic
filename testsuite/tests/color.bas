
' Simulates graphics mode!
open #6, 12, 0, "E:"

? "Start"
color 65
plot 0,0
plot 1,0
plot 500,3
x = peek($54)
y = dpeek($55)
?
? x, y

pos. 500,7
x = peek($54)
y = dpeek($55)
?
? x, y

fcolor 123
? peek($02FD)

