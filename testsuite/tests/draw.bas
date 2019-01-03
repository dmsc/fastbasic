' Simmulate graphics mode
open #6,12,0,"E:"
color 65

for i=0 to 100 step 3
 plot 100-i,0
 dr. 0,i
next i
?
