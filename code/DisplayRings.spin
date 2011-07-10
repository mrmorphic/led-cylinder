con
  MAX_RINGS = 10
  NUM_INITIAL_RINGS = 3

var
  long Stack[80]
  byte cog
  long randomPtr
  long framePtr

  ' current set of rings:
  '    bit 7 is 0 for not used, 1 for in-use.
  '    bit 6 is direction, 0=increase, 1=decrease
  '    bit 5 is orientation, 0=horizontal, 1=vertical
  '      if vertical bits 3..0 are X
  '      if horizontal bits 2..0 are Y
  byte ringData[MAX_RINGS]
  word ringLifetime[MAX_RINGS]
  long ringColour[MAX_RINGS]

obj
  frame       : "FrameManipulation"

PUB Start(globalBuffersPtr) : success | ci
  Stop

  randomPtr := long[globalBuffersPtr][2]
  framePtr := long[globalBuffersPtr][0]

  success := (cog := cognew(Run, @Stack) + 1)

PUB Stop
  if cog
    cogstop(cog~ - 1)

PRI Run | i, b, r, pos, ori, dir
  frame.EnableDoubleBuffering

  ' initialise the rings
  repeat i from 10 to MAX_RINGS-1
    ringData[i] := 0 ' clear all rings
  repeat i from 0 to NUM_INITIAL_RINGS-1
    b := long[randomPtr] & $7F
    b |= $80 ' enable
    ringData[i] := b
    ringLifetime[i] := (long[randomPtr] & $7f) + 20
    ringColour[i] := long[randomPtr] & $ffffff

  repeat
    Background

    repeat r from 0 to MAX_RINGS-1
      b := ringData[r]
      if b & $80
        if b & $40
          dir := -1
        else
          dir := 1
        if b & $20
          ori := 1
          pos := b & $f
          DrawVerticalLine(pos, ringColour[r])
        else
          ori := 0
          pos := b & $7
          DrawHorizontalLine(pos, ringColour[r])

        ' adjust positions
        pos += dir
        b := b & $f0
        pos := pos & $f
        b := b | pos
        ringData[r] := b

        ' determine expiry
        ringLifetime[r] := ringLifetime[r] - 1
        if ringLifetime[r] == 0
          b := long[randomPtr] & $7F
          b |= $80 ' enable
          ringData[i] := b
          ringLifetime[i] := (long[randomPtr] & $7f) + 20
          ringColour[i] := long[randomPtr] & $ffffff

    frame.SwapBuffers
    waitcnt(7500000 + cnt)

pri Background
  frame.ShowAll($000020)

pri DrawVerticalLine(x,colour) | y
  repeat y from 0 to 7
    frame.Pixel(x,y,colour)

pri DrawHorizontalLine(y,colour) | x
  repeat x from 0 to 15
    frame.Pixel(x,y,colour)

