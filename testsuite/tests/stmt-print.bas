' Test for statement "PRINT"
? "Start"
' Tests print to I/O channel and return to channel 0 afterwards
gr.1
? "->1"
? #6,
? "->2"
? #6,"a"
? "->3"
? #6,"b";
? "->4"
? #6,"c",
exec print1
? "->5"
' Test combinations of separators
? ,1,2;;;3;,;,4
?
? ,
? ;
? "-"

? "A",1
? "AB",1
? "ABC",1
? "ABCD",1
? "ABCDE",1
? "ABCDEF",1
? "ABCDEFG",1
? "ABCDEFGH",1
? "ABCDEFGHI",1
? "ABCDEFGHIJ",1
? "ABCDEFGHIJK",1

? "A" tab(4) 1
? "AB" tab(4) 1
? "ABC" tab(4) 1
? "ABCD" tab(4) 1
? "ABCDE" tab(4) 1
? "ABCDEF" tab(4) 1
? "ABCDEFG" tab(4) 1
? "ABCDEFGH" tab(4) 1
? "ABCDEFGHI" tab(4) 1

? "A" rtab(4) 1
? "A" rtab(4) 12
? "A" rtab(4) 123
? "A" rtab(4) 1234
? "AB" rtab(4) 1
? "AB" rtab(4) 12
? "AB" rtab(4) 123
? "AB" rtab(4) 1234
? "ABC" rtab(4) 1
? "ABC" rtab(4) 12
? "ABC" rtab(4) 123
? "ABC" rtab(4) 1234
? "ABCD" rtab(4) 1
? "ABCD" rtab(4) 12
? "ABCD" rtab(4) 123
? "ABCD" rtab(4) 1234
? "ABCDE" rtab(4) 1
? "ABCDE" rtab(4) 12
? "ABCDE" rtab(4) 123
? "ABCDE" rtab(4) 1234
? "ABCDEF" rtab(4) 1
? "ABCDEF" rtab(4) 12
? "ABCDEF" rtab(4) 123
? "ABCDEF" rtab(4) 1234
? "ABCDEFG" rtab(4) 1
? "ABCDEFG" rtab(4) 12
? "ABCDEFG" rtab(4) 123
? "ABCDEFG" rtab(4) 1234
? "ABCDEFGH" rtab(4) 1
? "ABCDEFGH" rtab(4) 12
? "ABCDEFGH" rtab(4) 123
? "ABCDEFGH" rtab(4) 1234
? "ABCDEFGHI" rtab(4) 1
? "ABCDEFGHI" rtab(4) 12
? "ABCDEFGHI" rtab(4) 123
? "ABCDEFGHI" rtab(4) 1234
? "ABCDEFGHI" rtab(4) 12345
? "ABCDEFGHI" rtab(4) "123456"

? rtab(4) "x"; rtab(4) "yy";
? "e"

' Test without separators (extension)
?1"-"2
A=123
?1A
?"x"A"y"

proc print1
 ? "in proc"
endproc
