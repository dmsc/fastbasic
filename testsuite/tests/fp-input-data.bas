' Test for statement "INPUT" into floating point DATA arrays
DATA F%() = 1.5, 2.5
? "Start"
input F%(1)
? err(), F%(0), F%(1)
