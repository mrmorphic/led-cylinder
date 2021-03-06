con
  backgroundSpeed = 1_000_000
  MAX_DROPS = 20
  RAIN_RATE = 2   ' smaller value = higher rate, minimum of 1, cannot be zero, 15 quite slow
var
  long Stack[80]
  byte cog
  long frameBufPtr
  long randomPtr
  long nunchuckPtr

  long backgroundColour
  long backgroundAlpha
  long backgroundChangeTime
  long backgroundInc

  long rainColourIndex
  long rainColour

  long countDrops
  long dropColumn[MAX_DROPS]    ' array indexed by drop of which column the drop is in. If -1, this drop is not being displayed yet
  long dropHeight[MAX_DROPS]    ' array indexed by drop of the y coordinate of the drop, in 1/100ths of a pixel
  long dropSpeed[MAX_DROPS]     ' array indexed by drop of the negative y delta
obj
  frame       : "FrameManipulation"

PUB Start(globalBuffersPtr) : success | ci
  Stop

  randomPtr := long[globalBuffersPtr][2]
  nunchuckPtr := long[globalBuffersPtr][5]

'  frame.Init(globalBuffersPtr)

  success := (cog := cognew(Run, @Stack) + 1)

PUB Stop
  if cog
    cogstop(cog~ - 1)

PRI Run | i, delay, drop, nextCol, startCnt
  frame.EnableDoubleBuffering
  frame.SetPalette(frame#PALETTE_HOTCOLD)

  backgroundColour := 00
  backgroundAlpha := 0
  rainColourIndex := 0
  rainColour := frame.ColourInPalette(rainColourIndex)

  backgroundChangeTime := cnt + backgroundSpeed
  backgroundInc := 1

  ' initialise drops
  repeat i from 0 to MAX_DROPS - 1
    dropColumn[i] := -1
    dropHeight[i] := 0
    dropSpeed[i] := 0

  dropColumn[0] := 1
  dropHeight[0] := 700
  dropSpeed[0] := long[randomPtr] & $3 + $f

  repeat
    startCnt := cnt

    CheckRainColourAdjust

    Background

    ' move current drops
    repeat i from 0 to MAX_DROPS - 1
      if dropColumn[i] => 0
        dropHeight[i] -= dropSpeed[i]
        if dropHeight[i] < 0
          dropColumn[i] := -1   ' drop has finished

    ' determine if we need to start some drops
    if long[randomPtr] // RAIN_RATE == 0
      ' locate a spare slot
      drop := -1
      repeat i from 0 to MAX_DROPS - 1
        if drop < 0 and dropColumn[i] < 0
          drop := i
      if drop => 0
        nextCol := long[randomPtr] & $f
        repeat i from 0 to MAX_DROPS - 1
          if dropColumn[i] == nextCol and dropHeight[i] > 40
            drop := -1
        if drop => 0
          dropColumn[drop] := nextCol
          dropHeight[drop] := 700
          dropSpeed[drop] := long[randomPtr] & $3 + $1f

    ' render drops
    repeat i from 0 to MAX_DROPS - 1
      if dropColumn[i] => 0
        frame.Pixel(dropColumn[i], dropHeight[i] / 100, rainColour)
        frame.PixelAlpha(dropColumn[i], (dropHeight[i] / 100) + 1, $60000000 | rainColour)
        frame.PixelAlpha(dropColumn[i], (dropHeight[i] / 100) + 2, $30000000 | rainColour)

    frame.swapBuffers

    delay := 600_000

    waitcnt(delay + cnt) ' gives us a more consistent frame rate

PRI Background | c
  frame.ShowAll(backgroundColour)
  if cnt > backgroundChangeTime
    backgroundChangeTime := cnt + backgroundSpeed
    if backgroundAlpha == 0 and backgroundInc < 0
      backgroundInc := 1
    if backgroundAlpha == $20 and backgroundInc > 0
      backgroundInc := -1
    backgroundAlpha += backgroundInc
    c := (backgroundAlpha << 24) | rainColour
    backgroundColour := frame.AlphaBlendPixel(0, c)

PRI CheckRainColourAdjust | nunY, orig
  nunY := long[nunchuckPtr][1]
  orig := rainColourIndex
  if nunY > 80
    rainColourIndex := rainColourIndex + 4
  if nunY < -80
    rainColourIndex := rainColourIndex - 4
  if rainColourIndex <> orig
    if rainColourIndex > 1023
      rainColourIndex := 1023
    if rainColourIndex < 0
      rainColourIndex := 0
    rainColour := frame.ColourInPalette(rainColourIndex)


