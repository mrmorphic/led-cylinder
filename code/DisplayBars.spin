con
  backgroundSpeed = 1_000_000
  ROW_DIFF = 100
  SAMPLE_RING_SIZE = 25
  SHRINK_COUNT = 20
  DECAY_SPEED = 1
  ROTATE_SPEED = 1

  ' ring=10, shrink=50 not bad
var
  long Stack[100]
  byte cog
  long frameBufPtr
  long adcPtr

  long adcValue
  long baseColour
  long colourInc

  long sampleRing[SAMPLE_RING_SIZE]
  long sampleIndex
obj
  frame       : "FrameManipulation"

PUB Start(globalBuffersPtr) : success | ci
  Stop

  adcPtr := long[globalBuffersPtr][3]

 ' frame.Init(globalBuffersPtr)

  success := (cog := cognew(Run, @Stack) + 1)

PUB Stop
  if cog
    cogstop(cog~ - 1)

PRI Run | i, x, c, delay, p, minA, maxA, range, stepA, midA, shrinkCount, aveSample, rawSample, displayLevel, decayCount, rc
  frame.DisableDoubleBuffering
  frame.SetPalette(frame#PALETTE_HOTCOLD)

  minA := 1024
  maxA := 0
  delay := 1000
  ' starting state
  baseColour := 0
  colourInc := 127

  ' load sample ring
  repeat i from 0 to SAMPLE_RING_SIZE - 1
    sampleRing[i] := long[adcPtr]
  sampleIndex := 0

  shrinkCount := SHRINK_COUNT
  decayCount := DECAY_SPEED

  x := 0
  rc := ROTATE_SPEED

  repeat
'    frame.ShowAll(0)

    rawSample := long[adcPtr]
    sampleRing[sampleIndex] := rawSample
    sampleIndex := sampleIndex + 1
    if sampleIndex => SAMPLE_RING_SIZE
      sampleIndex := 0

    ' sample is the average of the last SAMPLE_RING_SIZE samples
    aveSample := 0
    repeat i from 0 to SAMPLE_RING_SIZE - 1
      aveSample := aveSample + sampleRing[i]
    aveSample := aveSample / SAMPLE_RING_SIZE

    adcValue := rawSample - aveSample
    
    ' update max and min
    shrinkCount := shrinkCount - 1
    if adcValue < minA
      minA := adcValue
    else
      if shrinkCount == 0
        minA := minA + 1

    if adcValue > maxA
      maxA := adcValue
    else
      if shrinkCount == 0
        maxA := maxA - 1

    if shrinkCount == 0
      shrinkCount := SHRINK_COUNT
    
    if (maxA - minA) < 25
      minA := minA - (maxA - minA)

    midA := (maxA + minA) / 2
'    midA := ave
    range := maxA - midA
    stepA := range >> 3    ' divide by 8

    decayCount := decayCount - 1
    if adcValue > displayLevel
      displayLevel := adcValue
    else
      displayLeveL := displayLevel - 1
    if decayCount == 0
      decayCount := DECAY_SPEED

    if displayLeveL > (midA + stepA)
      c := frame.ColourInPalette(baseColour)
    else
      c := 0
    draw(0, x, c)

    if displayLeveL > (midA + (stepA * 2))
      c := frame.ColourInPalette(baseColour + colourInc)
    else
      c := 0
    draw(1, x, c)

    if displayLeveL > (midA + (stepA * 3))
      c := frame.ColourInPalette(baseColour + (colourInc * 2))
    else
      c := 0
    draw(2, x, c)

    if displayLeveL > (midA + (stepA * 4))
      c := frame.ColourInPalette(baseColour + (colourInc * 3))
    else
      c := 0
    draw(3, x, c)

    if displayLeveL > (midA + (stepA * 5))
      c := frame.ColourInPalette(baseColour + (colourInc * 4))
    else
      c := 0
    draw(4, x, c)

    if displayLeveL > (midA + (stepA * 6))
      c := frame.ColourInPalette(baseColour + (colourInc * 5))
    else
      c := 0
    draw(5, x, c)

    if displayLeveL > (midA + (stepA * 7))
      c := frame.ColourInPalette(baseColour + (colourInc * 6))
    else
      c := 0
    draw(6, x, c)

    if displayLeveL > (midA + (stepA * 8))
      c := frame.ColourInPalette(baseColour + (colourInc * 7))
    else
      c := 0
    draw(7, x, c)

    rc := rc - 1
    if rc == 0
      x := x + 1
      x := x & $f
      rc := ROTATE_SPEED

'    waitcnt(delay + cnt) ' gives us a more consistent frame rate
'    frame.swapBuffers

PRI draw(row, col, colour)
  frame.Pixel(col, row, colour)
'  frame.Row(row, colour)
