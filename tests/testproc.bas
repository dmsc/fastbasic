' Test PROC/EXEC

' Calls a PROC defined after use
for i=0 to 10
    exec printLoop
next i

proc printLoop
    ? "Loop: "; i
endproc

' Now, define PROC first
proc before
    ? "-- test --"
endproc

exec before

