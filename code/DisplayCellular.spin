' Belousov-Zhabotinsky cellular automaton described on
' www.fractaldesign.net/AutomataAlgorithm.aspx

con
  CONST_K1 = 10
  CONST_K2 = 1
  CONST_G = 50

  ' algorithm defines healthy as 0, ill as the maximum cell value, and everything in between is
  ' infected.
  CELL_HEALTHY = 0     ' in algorithm, defined as 'healthy'
  CELL_ILL = 1023  ' in algorithm, defined as 'ill'

var
  long Stack[80]
  byte cog
  long randomPtr
  long framePtr

  long counts[128]
  long loopCount
  long cells[128]
  long old[128]

  ' these are calculated by GetNeighbourCounts
  long infected
  long ill
  long sumCells
  long nextReset

  long k1
  long k2
  long g

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

PRI Run | i, v, c
  frame.EnableDoubleBuffering
  frame.SetPalette(frame#PALETTE_HOTCOLD)

  ' initialise
  repeat i from 0 to 127
    cells[i] := long[randomPtr] & 1023   ' random colour in the palette
  nextReset := cnt

  repeat
    if cnt > nextReset
      k1 := long[randomPtr] & 15 + 5
      k2 := long[randomPtr] & 7 + 1
      g := long[randomPtr] & 31 + 10
      nextReset := cnt + 25000000

      ' set some cells random
      repeat i from 0 to 5
        cells[long[randomPtr] & 127] := long[randomPtr] & 1023

'    CalculateNeighbourCounts
    CopyState
    CalculateNewCellStates
    DisplayCells

    waitcnt(1000 + cnt)

pri CopyState | i
  repeat i from 0 to 127
    old[i] := cells[i]

pri CalculateNewCellStates | x, y, c, i
  repeat y from 0 to 7
    repeat x from 0 to 15
      i := y * 16 + x
      c := old[i]
      if c == CELL_HEALTHY
        GetNeighbourCounts(x, y, i)
        cells[i] := (infected / k1) + (ill / k2)
      elseif c == CELL_ILL
        cells[i] := CELL_HEALTHY
      else
        GetNeighbourCounts(x, y, i)
        cells[i] := (sumCells / (infected + ill + 1)) + g
        if cells[i] > CELL_ILL
          cells[i] := CELL_ILL

' Look at the neighbours of cell at x,y (in 'old'), and calculate:
'  - # infected
'  - # ill
'  - sum of states of this cell and all neighbours
pri GetNeighbourCounts(x, y, i)
  infected := 0
  ill := 0
  sumCells := 0
  AddCellCounts(x-1, y-1)
  AddCellCounts(x,   y-1)
  AddCellCounts(x+1, y-1)
  AddCellCounts(x-1, y)
  AddCellCounts(x+1, y)
  AddCellCounts(x-1, y+1)
  AddCellCounts(x,   y+1)
  AddCellCounts(x+1, y+1)
  sumCells := sumCells + old[i]

pri AddCellCounts(x, y) | i
  if y < 0 or y > 7
    return  ' out of range
  x := x & 15 ' wrap x
  i := y * 16 + x
  if old[i] == CELL_ILL
    ill := ill + 1
  elseif old[i] > CELL_HEALTHY
    infected := infected + 1
  sumCells := sumCells + old[i]

pri DisplayCells | x, y, c
  repeat y from 0 to 7
    repeat x from 0 to 15
      c := frame.ColourInPalette(cells[(y * 16) + x])
      frame.Pixel(x, y, c)
  frame.SwapBuffers

