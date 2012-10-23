' Ping is a simple effect. At a set rate, a random pixel is chosen. It is set to
' a colour on a palette, and quickly faded.

con
  BACKGROUND_COLOUR = $000010
  MAX_CELLS = 128
  DECAY_RATE = 5

var
  long Stack[80]
  byte cog
  long randomPtr
  long framePtr

  ' managed cells
  long cellAlpha[MAX_CELLS]
  long cellColour[MAX_CELLS]

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

PRI Run | i, v, c, loopCount
  frame.EnableDoubleBuffering
  frame.SetPalette(frame#PALETTE_HOTCOLD)

  Initialise

  loopCount := 0

  repeat
    DecayCells

    if long[randomPtr] & 1 == 0
      MakeCell

    DrawCells

    waitcnt(75000 + cnt)

pri Initialise | i
  ' set initial cell positions
  repeat i from 0 to MAX_CELLS-1
    cellAlpha[i] := 0
    cellColour[i] := BACKGROUND_COLOUR

pri DecayCells | i
  repeat i from 0 to MAX_CELLS-1
    if cellAlpha[i] > 0
      cellAlpha[i] := cellAlpha[i] - DECAY_RATE
      if cellAlpha[i] < DECAY_RATE
        cellAlpha[i] := 0

' find an empty cell space we can make live
pri MakeCell | i, r
  i := long[randomPtr] & 127  ' a random pixel
  cellColour[i] := frame.ColourInPalette(long[randomPtr] & 1023)
  cellAlpha[i] := 255

pri DrawCells | i, buf, r, g, b, alpha, merged, c
  buf := frame.GetDrawingBuffer
  repeat i from 0 to MAX_CELLS-1
    alpha := cellAlpha[i]
    if alpha == 0
      long[buf][i] := BACKGROUND_COLOUR
    else
      merged := BACKGROUND_COLOUR
      c := cellColour[i]
      r := frame.AlphaBlend((merged & $ff0000) >> 16, (c & $ff0000) >> 16, alpha)
      g := frame.AlphaBlend((merged & $ff00) >> 8, (c & $ff00) >> 8, alpha)
      b := frame.AlphaBlend(merged & $ff, c & $ff, alpha)

      long[buf][i] := (r << 16) | (g << 8) | b
  frame.SwapBuffers

