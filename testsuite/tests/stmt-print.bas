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
? "->5"
' Test combinations of separators
? ,1,2;;;3;,;,4
?
? ,
? ;
? "-"
