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
 y% = i * 0.05 - 11
 y% = y% * y% * (y% + 5)
 plot i, 160 - int(y%)
next i
