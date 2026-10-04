' Test that DATA arrays in one line are in source order in memory
FOR I=1 TO 2:NEXT I
FOR I=1 TO 2:NEXT I
FOR I=1 TO 2:NEXT I
FOR I=1 TO 2:NEXT I
DATA A() BYTE = 1 : DATA B() BYTE = 2
? ADR(B) > ADR(A)
DA.C()B.=0:DA.D()B.=1:DA.E()B.=2:DA.F()B.=3:DA.G()B.=4:DA.H()B.=5:DA.I()B.=6:DA.J()B.=7:DA.K()B.=8:DA.L()B.=9:DA.M()B.=10:DA.N()B.=11:DA.O()B.=12:DA.P()B.=13:DA.Q()B.=14:DA.R()B.=15:DA.S()B.=16
? (ADR(D)>ADR(C))+(ADR(E)>ADR(D))+(ADR(F)>ADR(E))+(ADR(G)>ADR(F))+(ADR(H)>ADR(G))+(ADR(I)>ADR(H))+(ADR(J)>ADR(I))+(ADR(K)>ADR(J))
? (ADR(L)>ADR(K))+(ADR(M)>ADR(L))+(ADR(N)>ADR(M))+(ADR(O)>ADR(N))+(ADR(P)>ADR(O))+(ADR(Q)>ADR(P))+(ADR(R)>ADR(Q))+(ADR(S)>ADR(R))
