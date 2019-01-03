
a% = 0.1
? a%, int(a%), err(), int(-a%), err()
a% = 0.5
? a%, int(a%), err(), int(-a%), err()

a% = 123.499
? a%, int(a%), err(), int(-a%), err()
a% = 123.500
? a%, int(a%), err(), int(-a%), err()
a% = 32767.4999
? a%, int(a%), err(), int(-a%), err()
a% = 32767.5000
? a%, int(a%), err(), int(-a%), err()

