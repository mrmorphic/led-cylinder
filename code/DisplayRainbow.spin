con
  backgroundSpeed = 1_000_000
  MAX_DROPS = 20
  RAIN_RATE = 2   ' smaller value = higher rate, minimum of 1, cannot be zero, 15 quite slow
  ROW_DIFF = 100
var
  long Stack[80]
  byte cog
  long frameBufPtr
  long randomPtr

  long current[8]
  long dir[8]

obj
  frame       : "FrameManipulation"

PUB Start(globalBuffersPtr) : success | ci
  Stop

  randomPtr := long[globalBuffersPtr][2]

 ' frame.Init(globalBuffersPtr)

  success := (cog := cognew(Run, @Stack) + 1)

PUB Stop
  if cog
    cogstop(cog~ - 1)

PRI Run | y, x, c, delay, p
  'frame.EnableDoubleBuffering
  frame.DisableDoubleBuffering
  frame.SetPalette(frame#PALETTE_HOTCOLD)

  ' starting state
  c := 0
  repeat y from 0 to 7
    current[y] := (7-y) * ROW_DIFF
    dir[y] := 1

  repeat
    repeat y from 0 to 7
      p := current[y]
      c := frame.ColourInPalette(p)
      frame.Row(y,c)

      p := p + dir[y]
      if p == 1024
        p := 1023
        dir[y] := -1
      elseif p < 0
        p := 0
        dir[y] := 1
      current[y] := p
   ' frame.swapBuffers
'
' '   delay := 100
'

''    waitcnt(delay + cnt) ' gives us a more consistent frame rate

