' Test for statement "SOUND"
? "Start"

for i=0 to 30
  sound i & 3, i * 7, 10, i & 15
  ? i; " ";
next i
?

' Sound off 1 channel
for i=0 to 3
  sound i & 3
  ? "Off-"; i; " ";
next i
?

' All off
sound

? "Ok"

