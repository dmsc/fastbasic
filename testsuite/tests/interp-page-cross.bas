' Regression test for page-crossing bugs in immediate-operand tokens.
' The companion interp-page-cross.asm builds a chain of token handlers with
' each operand at $xxFF.  Every handler must carry into cptr+1 to reach
' the next page; otherwise execution wraps to the start of the current
' page and loops.
DIM A
A = 0
A = USR(@PAGE_TEST)
