con
  MAX_CHANGE_POINTS = 1
  BG_SPEED = 4

var
  long Stack[200]
  byte cog
  long frameBufPtr
  long randomPtr

  word cells[128]

  byte chgX[MAX_CHANGE_POINTS]
  byte chgY[MAX_CHANGE_POINTS]
  byte chgCount[MAX_CHANGE_POINTS]
OBJ
  frame       : "FrameManipulation"

PUB Start(globalBuffersPtr) : success | ci
  Stop

  randomPtr := long[globalBuffersPtr][2]

  frame.Init(globalBuffersPtr)

  success := (cog := cognew(Run, @Stack) + 1)

PUB Stop
  if cog
    cogstop(cog~ - 1)

PRI Run | c,x,y,size,delay,srcPtr
  frame.EnableDoubleBuffering
  frame.SetPalette(frame#PALETTE_HOTCOLD)

  initialiseCells

  repeat
    displayCells
    updateCells
    waitcnt(cnt + 5_000_000)
    frame.SwapBuffers

' initialise cells with the starting indexes to display
pri initialiseCells | x, y, c
  c := long[randomPtr] & $1ff   ' starting index not always the same, but in lower range
  repeat x from 0 to 127
    cells[x] := c
'  repeat c from 1 to 5
'    x := long[randomPtr] & $f
'    y := long[randomPtr] & 7
    adjustPoint(x, y, 20, (long[randomPtr] & $f + 10))
  repeat c from 0 to MAX_CHANGE_POINTS - 1
    chgX[c] := long[randomPtr] & $f
    chgY[c] := long[randomPtr] & 7
    chgCount[c] := (long[randomPtr] & 7) + 20

' perform incremental updates to cells
pri updateCells | i
  repeat i from 0 to 127
    cells[i] := (cells[i] + BG_SPEED) & 1023
  repeat i from 0 to MAX_CHANGE_POINTS - 1
    adjustPoint(chgX[i], chgY[i], 10, 1)
    chgCount[i] := chgCount[i] - 1
    if chgCount[i] == 0
      chgX[i] := long[randomPtr] & $f
      chgY[i] := long[randomPtr] & 7
      chgCount[i] := (long[randomPtr] & 7) + 20
  

' update the frame buffer from the cells, translating into palette colours
pri displayCells | x, y, c
  repeat y from 0 to 7
    repeat x from 0 to 15
      c := frame.ColourInPalette(cells[y * 16 + x])
      frame.Pixel(x, y, c)

' Adjust a point's colour index up or down for a number of iterations. Also adjusts cells around (x,y), wrapping
' in x but not y.
' @param x             x coord of point
' @param y             y coord of point
' @param inc           a small positive or negative integer which is the adjustment to the cell per iteration
' @param iterations    number of times repeated. Generally 1 for main loop, but initialisation may perform this
'                      multiple times to get an interesting state
pri adjustPoint(x, y, inc, iterations) | c, i
  repeat c from 1 to iterations
    bumpCell(x, y, inc)
    bumpCell(x-1,y, inc-7)
    bumpCell(x+1,y, inc-7)
    bumpCell(x,y-1, inc-7)
    bumpCell(x,y+1, inc-7)

    bumpCell(x-2,y, inc-4)
    bumpCell(x+2,y, inc-4)
    bumpCell(x,y-2, inc-4)
    bumpCell(x,y+2, inc-4)

    bumpCell(x-1,y-1, inc-4)
    bumpCell(x+1,y-1, inc-4)
    bumpCell(x-1,y+1, inc-4)
    bumpCell(x+1,y+1, inc-4)

pri bumpCell(x, y, inc) | i
  if y < 0 or y > 15
    return
  x := x & $f
  i := y * 16 + x
  cells[i] := cells[i] + inc

