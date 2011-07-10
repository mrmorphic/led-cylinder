con
  LIVE_COLOUR = $FF00FF
  DEAD_COLOUR = $000080
  BACKGROUND_COLOUR = $000020

  LOOPS_PER_GEN = 10
var
  long Stack[80]
  byte cog
  long randomPtr
  long framePtr

  long counts[128]
  long loopCount

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
  frame.DisableDoubleBuffering

  loopCount := 0

  repeat i from 0 to 127
    v := long[randomPtr] & 3
    if v == 0
      long[framePtr][i] := LIVE_COLOUR
    else
      long[framePtr][i] := BACKGROUND_COLOUR

  repeat
    if loopCount == 0
      loopCount := LOOPS_PER_GEN
      CalculateNeighbourCounts
      CalculateNewCellStates
    else
      loopCount := loopCount - 1

    DecayDeadCells
    waitcnt(5000000 + cnt)

pri CalculateNewCellStates | i, newLive, oldLive
  ' recalculate the display
  repeat i from 0 to 127
    newLive := 0
    if long[framePtr][i] == LIVE_COLOUR
      ' cell is currently live, calc new live or dead
      oldLive := 1
      if counts[i] == 2 or counts[i] == 3
        newLive := 1
    else
      ' cell is currently dead
      oldLive := 0
      if counts[i] == 3
        newLive := 1

    if newLive == 1
      long[framePtr][i] := LIVE_COLOUR
    else
      if oldLive == 1
        long[framePtr][i] := DEAD_COLOUR

pri DecayDeadCells | i, c
  repeat i from 0 to 127
    c := long[framePtr][i]

    if c <> LIVE_COLOUR
      if c > BACKGROUND_COLOUR
        long[framePtr][i] := c - 4
      else
        long[framePtr][i] := BACKGROUND_COLOUR

pri CalculateNeighbourCounts | i, c
  ' calculate counts
  repeat i from 0 to 127
    c := 0
    c := c + IsLive(i-17)
    c := c + IsLive(i-16)
    c := c + IsLive(i-15)
    c := c + IsLive(i-1)
    c := c + IsLive(i+1)
    c := c + IsLive(i+15)
    c := c + IsLive(i+16)
    c := c + IsLive(i+17)
    counts[i] := c

' Return 0 if the cell at index i is dead, or 1 if it's live
pri IsLive(i)
  if long[framePtr][i] == LIVE_COLOUR
    return 1
  return 0
