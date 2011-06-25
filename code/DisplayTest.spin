var
  long Stack[60]
  byte cog
  long frameBufPtr
  long randomPtr

OBJ
  frame:        "FrameManipulation"
PUB Start(globalBuffersPtr) : success | ci
  Stop

  frameBufPtr := long[globalBuffersPtr]
  randomPtr := long[globalBuffersPtr][2]

  frame.Init(globalBuffersPtr)
  frame.DisableDoubleBuffering

  success := (cog := cognew(Run, @Stack) + 1)

PUB Stop
  if cog
    cogstop(cog~ - 1)

PRI Run | ci, i, j, delay, m
  frame.DisableDoubleBuffering

  ' all white
  repeat ci from 0 to 127
    long[frameBufPtr][ci] := $ffffff
  waitcnt(150_000_000 + cnt)

  repeat
    delay := 75_000
    repeat 2
      ' go down
      i := 255
      repeat until i == 0
        j := (i << 16) + (i << 8) + i
        repeat ci from 0 to 127
          long[frameBufPtr][ci] := j
        waitcnt(delay + cnt)
        i := i - 1

      ' go up
      i := 0
      repeat until i == 255
        j := (i << 16) + (i << 8) + i
        repeat ci from 0 to 127
          long[frameBufPtr][ci] := j
        waitcnt(delay + cnt)
        i := i + 1

    frame.ShowAll($ff0000)
    waitcnt(150_000_000 + cnt)
    frame.ShowAll($00ff00)
    waitcnt(150_000_000 + cnt)
    frame.ShowAll($0000ff)
    waitcnt(150_000_000 + cnt)
    frame.ShowAll($ff00ff)
    waitcnt(150_000_000 + cnt)

    ' red rows up and down
    i := $ff0000
    repeat 3
      repeat 3
        repeat m from 0 to 7
          showRow(m, i)
          waitcnt(5_000_000 + cnt)
        repeat m from 6 to 1
          showRow(m, i)
          waitcnt(5_000_000 + cnt)
      i >>= 8

PUB showRow(row,colour) | v, k
  repeat v from 0 to 127
    if v => row * 16 and v < (row+1) * 16
      long[frameBufPtr][v] := colour
    else
      long[frameBufPtr][v] := 0
  return

'  repeat
'    delay := long[randomPtr]
'    delay &= $ffffff
'    delay += 1000
'
'    repeat ci from 0 to 127
'      long[frameBufPtr][ci] := long[randomPtr]
'    waitcnt(delay + cnt)
