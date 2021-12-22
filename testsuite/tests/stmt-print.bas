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

proc print1
 ? "in proc"
endproc
