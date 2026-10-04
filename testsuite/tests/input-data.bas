' Test for statement "INPUT" into DATA arrays
DATA B() BYTE = 1, 2, 3
DATA W() = 1000, 2000
DIM D(2) BYTE
? "Start"
input B(1)
? err(), B(0); B(1); B(2)
input "Word:", W(1)
? err(), W(0), W(1)
input D(1)
? err(), D(1)
