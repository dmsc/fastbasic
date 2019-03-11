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

proc print1
 ? "in proc"
endproc
