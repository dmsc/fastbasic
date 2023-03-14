' Test SIO statement
? "Start"
DIM buf1(128) byte, buf2(128) byte
' Write some data into buffer
FOR i=0 TO 128 : buf1(i)=255-i : NEXT

' Try reading buf1 from sector 0 (invalid)
SIO $31, 1, $52, 64, &buf1, 15, 128, 0, 0
? SERR()
' Write buf1 to emulated sector 719
SIO $31, 1, $50, 128, &buf1, 15, 128, 719 & 255, 719/256
? SERR()
' Write buf2 to emulated sector 720
SIO $31, 1, $50, 128, &buf2, 15, 128, 720 & 255, 720/256
? SERR()
' Read buf2 from emulated sector 719
SIO $31, 1, $52, 64, &buf2, 15, 128, 719 & 255, 719/256
? SERR()
' Read buf1 from emulated sector 720
SIO $31, 1, $52, 64, &buf1, 15, 128, 720 & 255, 720/256
? SERR()

' Check values of buf1
? "1:";
FOR i=0 TO 127
    If buf1(i) <> 0
        ? " "; i; "="; buf1(i);
    Endif
NEXT
?

' Check values of buf2
? "2:";
FOR i=0 TO 127
    If buf2(i) <> 255-i
        ? " "; i; "="; buf2(i);
    Endif
NEXT
?
