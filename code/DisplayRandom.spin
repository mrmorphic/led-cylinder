var
  long Stack[60]
  byte cog
  long frameBufPtr
  long randomPtr
OBJ
  frame       : "FrameManipulation"

PUB Start(globalBuffersPtr) : success | ci
  Stop

  frameBufPtr := long[globalBuffersPtr]
  randomPtr := long[globalBuffersPtr][2]

  frame.Init(globalBuffersPtr)

  success := (cog := cognew(Run, @Stack) + 1)

PUB Stop
  if cog
    cogstop(cog~ - 1)

PRI Run | ci, delay
  frame.DisableDoubleBuffering
  repeat
    delay := long[randomPtr]
    delay &= $ffffff
    delay += 1000

'    frame.ShowAll(long[randomPtr])
    repeat ci from 0 to 127
      long[frameBufPtr][ci] := long[randomPtr]
    waitcnt(delay + cnt)

