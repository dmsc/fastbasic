' Test for DATA/PROC inside PROC
? "Start"
exec x

' Define a DATA inside the PROC
proc x
  data y() = 1,2
  ? y(0)
endproc

' Define a PROC and call twice
proc z
  proc a
    ? y(1)
  endproc
  exec a
  exec a
endproc

exec z

