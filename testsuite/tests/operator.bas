' Test for logical AND/OR chaining
? "Start"

' First number is converted to boolean, second and third parameters are
' parsed from number to comparisons:
? 1 AND 1<2 AND 3<4
? 1 OR  1<2 AND 3<4
? 1 AND 1<2 OR  4<3

