' Graphics sample
gr. 8+16
color 1

' Sample line drawing
for i=0 to 100 step 3
 plot 100-i,0
 dr. 0,i
next i

' Plotting a function (in FP)
for i=120 to 300
 plot i, @Curve(i)
next i

' A user function returns an integer, and is called as @name(...)
PROC Curve X
 Y% = X * 0.05 - 11
 RETURN 160 - INT(Y% * Y% * (Y% + 5))
ENDPROC
