con
'  backgroundSpeed = 1_000_000
'  MAX_DROPS = 20
'  RAIN_RATE = 2   ' smaller value = higher rate, minimum of 1, cannot be zero, 15 quite slow
  ROTATION_SPEED = 2
  MAX_PARTICLES = 8
var
  long Stack[80]
  byte spinnerCog
  long frameBufPtr
  long randomPtr

  long backgroundColour
'  long backgroundChangeTime
'  long backgroundInc

  ' the degree of rotation (0-15) of the rendering display
  long rotation

  ' counter per cycle that is used to determine when to rotate again. Initialised using ROTATION_SPEED
  long rotationCount

  ' data structure for particles
  long numParticles
  long partX[MAX_PARTICLES]                             ' X coordinate of particle
  long partY[MAX_PARTICLES]                             ' Y coordinate of particle
  long partDir[MAX_PARTICLES]
  long partColour[MAX_PARTICLES]

obj
  frame       : "FrameManipulation"

PUB Start(globalBuffersPtr) : success | ci
  Stop

  randomPtr := long[globalBuffersPtr][2]

'  frame.Init(globalBuffersPtr)

  success := (spinnerCog := cognew(Run, @Stack) + 1)

PUB Stop
  if spinnerCog
    cogstop(spinnerCog~ - 1)

PRI Run | i, delay, drop, nextCol, startCnt, c, y
  frame.EnableDoubleBuffering

  rotationCount := ROTATION_SPEED

  backgroundColour := $000010
'  partX[0] := 2
'  partY[0] := 4
'  partX[1] := 4
'  partY[1] := 3
'  partX[2] := 1
'  partY[2] := 2
'  partX[3] := 3
'  partY[3] := 1
'  partX[4] := 0
'  partY[4] := 0
  repeat i from 0 to MAX_PARTICLES - 1
    partX[i] := long[randomPtr] & $0f
    partY[i] := long[randomPtr] & $7f
    partDir[i] := (long[randomPtr] & 7) + 1
    if long[randomPtr] & 1
      partDir[i] := 0 - partDir[i]
'    partDir[i] := (long[randomPtr] & $3) - 2

  repeat i from 0 to MAX_PARTICLES - 1
    partColour[i] := long[randomPtr] & $ffffff
'    if long[randomPtr] & 1
'      partColour[i] := long[randomPtr] & $f00000 ' red primary
'    else
'      if long[randomPtr] & 1
'        partColour[i] := long[randomPtr] & $f000 ' green primary
'      else
'        partColour[i] := long[randomPtr] & $f0   ' blue primary

'    if partColour[i] & $ff < $80
'      partColour[i] := partColour[i] | $80
'  backgroundChangeTime := cnt + backgroundSpeed
'  backgroundInc := 1

  repeat
    startCnt := cnt

    Background

    ' move particles
    rotationCount := rotationCount - 1
    if rotationCount == 0
      rotationCount := ROTATION_SPEED

      ' add 1 to particle X coords, truncated
      repeat i from 0 to MAX_PARTICLES - 1
        partX[i] := (partX[i] + 1) & $0f
        partY[i] := partY[i] + partDir[i]
        if partY[i] < 0 or partY[i] > 112
          partDir[i] := 0 - partDir[i]

    ' draw particles with trails
    repeat i from 0 to MAX_PARTICLES - 1
      y := partY[i] >> 4
      frame.Pixel(partX[i], y, partColour[i])
      frame.PixelAlphaW(partX[i]-1, y, $80000000 | partColour[i])
      frame.PixelAlphaW(partX[i]-2, y, $40000000 | partColour[i])
'      frame.PixelAlphaW(partX[i]-3, y, $20000000 | partColour[i])
'      frame.PixelAlphaW(partX[i]-4, y, $10000000 | partColour[i])
'      frame.Pixel(partX[i]-1, y, partColour[i])
'      frame.Pixel(partX[i]-2, y, partColour[i])
'      frame.Pixel(partX[i]-3, y, partColour[i])
'      c := $20000000 | partColour[i]
'      frame.PixelAlphaW(partX[i]-1, y, c)
'      frame.PixelAlphaW(partX[i]-2, y, c)
'      frame.PixelAlphaW(partX[i]-3, y, c)
'      frame.PixelAlphaW(partX[i]-4, y, c)

    frame.swapBuffers

    delay := 500000 '5_000_000

    waitcnt(delay + cnt) ' gives us a more consistent frame rate

PRI Background
  frame.ShowAll(backgroundColour)
'  if cnt > backgroundChangeTime
'    backgroundChangeTime := cnt + backgroundSpeed
'    if backgroundColour == 0 and backgroundInc < 0
'      backgroundInc := 1
'    if backgroundColour == $20 and backgroundInc > 0
'      backgroundInc := -1
'    backgroundColour += backgroundInc

