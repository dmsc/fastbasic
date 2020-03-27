' Test PROC in same line with other code
? "Start"
proc x: ? "x" : endproc : exec x : proc y : ? "y" : endproc : exec y

