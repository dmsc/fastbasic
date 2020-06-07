' Test for array operations
? "Start"

dim arr1( 19 ) , arr2(9) byte

arr1(0) = 1
for i = 1 to 19
 arr1( i ) = arr1(i-1) * i
next i

for i = 0 to 9
 arr2( i ) = i * i * i
next i

for i=0 to 9
 ? arr1(i), arr2(i), arr1(i+2)
next i

? arr1(15),arr1(16),arr1(17),arr1(18),arr1(19)

