' Test DATA FILE inclusion
? "Start"

DATA fb() bytefile "data-file.bas"
DATA fw() wordfile "data-file.bas"

' Test data segments
DATA d1() byte [aligndata] = 1, 2, 3

? fb(0), fb(1)
? fw(0)
? d1(0), adr(d1) & 255
