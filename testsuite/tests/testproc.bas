' Test PROC/EXEC

' Calls a PROC defined after use
for i=0 to 10
    exec printLoop
next i

proc printLoop
    if i = 5
      ? "Skipping 5!"
      exit
    endif
    ? "Loop: "; i
endproc

' Now, define PROC first
proc before
    ? "-- test --"
endproc

exec before

exec param 123, i * i * i

' Proc with a parameter
proc param x y
   ? "X="; x
   ? "Y="; y
endproc

' Proc with a parameter
proc param3 x y z
   ? "P="; x, y, z
endproc

exec param3 1, 2, 3

