'-------------------------------------
' Joyas: A match-three pieces game
'

' Character set redefinition
data charset() byte = $FE,$82,$82,$82,$82,$82,$FE,$00, ' 1: Cursor
data           byte = $00,$38,$44,$54,$44,$38,$00,$00, ' 2: Ball with dot
data           byte = $10,$38,$7C,$FE,$7C,$38,$10,$00, ' 3: Diamond
data           byte = $00,$7C,$7C,$7C,$7C,$7C,$00,$00, ' 4: Square
data           byte = $00,$10,$10,$7C,$10,$10,$00,$00, ' 5: Cross
data           byte = $38,$7C,$FE,$FE,$FE,$7C,$38,$00, ' 6: Big ball
data           byte = $00,$28,$54,$28,$54,$28,$00,$00, ' 7: Flag
data           byte = $00,$00,$00,$00,$00,$00,$00,$00  ' 8: Explosion

data explode() byte = $00,$00,$00,$38,$54,$38,$00,$00,
data           byte = $00,$00,$24,$40,$12,$08,$44,$00,
data           byte = $00,$42,$00,$80,$00,$01,$00,$82,
data           byte = $00,$00,$00,$00,$00,$00,$00,$00

' Our board pieces:
data pieces() byte = $02, $43, $84, $C5, $06, $47

' Our empty board (two lines)
data eboard() byte = $80,$40,$01,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$01,$40,$80,
data          byte = $40,$80,$41,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$41,$80,$40

' Set graphics mode and narrow screen
graphics 18
poke 559, 33

' Redefine character set
move $E000, $7C00, 512
move adr(charset), $7C08, 64
poke 756, $7C

' Set colors
se. 0,4,8
se. 1,12,10
se. 2,9,6
se. 3,2,14

' Memory area for the board
mainBoard = $7000 + 19
fullBoard = $7000 + 16

hiScore = 0
screen = dpeek(88)
screenBoard = screen + 3
C = mainBoard - screenBoard

' Loop forever
do

  ' Clear board
  for i=0 to 4
    move adr(eboard), fullBoard+i*32, 32
  next i

  ' Init game variables
  score = 0     ' Score
  nmoves = 15   ' Remaining moves
  addMove = 16  ' Points to bonus
  crsPos = 0    ' Cursor pos

  ' Clear the screen
  mset screen, 160, 0
  position 0, 0

  ' Show game info
  print #6, , , " joyas", , , "HI SCORE:"; hiScore
  print #6, "BUTTON: game    ANY KEY: exit"

  ' Wait for button press and release
  repeat : until not strig(0) or key()
  repeat : until strig(0) or key()

  ' Exit on any key pressed
  if key() then end

  ' Call game loop
  while nmoves > 0
    exec GameLoop
  wend

  if hiScore < score then hiScore = score

loop

'-------------------------------------
' Move the cursor and wait for play
proc MoveCursor

  ' Loop
  do

    ' Wait for valid move
    repeat
      ' Show cursor
      poke crsPos+screenBoard, 193
      pause 1
      ' Remove cursor
      poke crsPos+screenBoard, peek(crsPos+mainBoard)
      pause 1
      ' Move cursor
      i = stick(0)
      nxtPos = (i=7) - (i=11) + 16 * ((i=13) - (i=14)) + crsPos
    until nxtPos <> crsPos and peek(nxtPos + mainBoard) & 63 > 1

    ' If button is pressed, return
    if not strig(0) then Exit

    ' Move cursor
    crsPos = nxtPos
  loop

endproc


'-------------------------------------
' Make pieces fall in the board
proc FallPieces

  ' Loop until there are holes in the board
  repeat

    endFall = 1

    ' Move board to screen
    move fullBoard, screen, 160

    ' Search for holes in the board
    for A=mainBoard to mainBoard + 151 step 16
      for P=A to A+9
        if peek(P) = 8
          ' If we found a hole, fall pieces!
          i = P
          while i > mainBoard + 15
            poke i, peek(i-16)
            i = i-16
          wend
          ' Set new piece and set A to exit outer loop
          poke i, pieces(rand(6))
          A = mainBoard + 152
          endFall = 0
        endif
      next P
    next A
  until endFall

endproc

'-------------------------------------
' Search matching pieces and remove
proc MatchPieces

  ' Number of matches found
  lsize = 0

  ' Go through each line
  for A = screenBoard to screenBoard + 151 step 16
    ' And through each column
    for X=A to A+9
      P = peek(X)
      ' Test if equal to the next two pieces
      if P = peek(X+1) and P = peek(X+2)
        ' Transform screen pointer to board pointer
        Y = X + C
        ' Clean the three pieces found
        poke Y, 8
        poke Y+1, 8
        poke Y+2, 8
        inc lsize
      endif

      ' Test if equal to the two pieces bellow
      IF P = peek(X + 16) and P = peek(X + 32)
        ' Transform screen pointer to board pointer
        Y = X + C
        ' Clean the three pieces found
        poke Y, 8
        poke Y + 16, 8
        poke Y + 32, 8
        inc lsize
      endif
    next X
  next A

  if lsize
    ' Found a line, add to score and show a little animation
    score = score + lsize * lsize
    move fullBoard, screen, 160

    for i = 0 to 3
      sound 1, 80, 0, 10 - i * 3
      ' Set animation frame
      move i*8 + adr(explode), $7C40, 8
      pause 4
    next i
  endif

  ' Add one move at 16, 32, 64, etc. points
  if score >= addMove
    inc nmoves
    addMove = addMove * 2
  endif

  ' Print current score and moves left
  position 18, 8
  print #6, "score "; score; "/"; nmoves,
  sound

endproc

'-------------------------------------
' Our main game loop
proc GameLoop

  ' Update number of moves
  dec nmoves

  ' Loop until no pieces are left to move
  repeat
    exec FallPieces
    exec MatchPieces
  until not lsize

  ' Game over if no more moves
  if nmoves < 1 then exit

  exec MoveCursor

  ' Perform an exchange
  poke crsPos + mainBoard, peek(nxtPos + screenBoard)
  poke nxtPos + mainBoard, peek(crsPos + screenBoard)
  sound 0, 100, 10, 10
  pause 2
  sound

endproc

