con
  backgroundSpeed = 1_000_000
  ROW_DIFF = 100
  SAMPLE_RING_SIZE = 25
  SHRINK_COUNT = 20
  DECAY_SPEED = 1

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

PRI Run | y, x, c, delay, p, minA, maxA, range, stepA, midA, shrinkCount, aveSample, rawSample, displayLevel, decayCount
  frame.EnableDoubleBuffering
  frame.SetPalette(frame#PALETTE_HOTCOLD)

  minA := 1024
  maxA := 0
  delay := 1000
  ' starting state
  baseColour := 0
  colourInc := 127

  ' load sample ring
  repeat x from 0 to SAMPLE_RING_SIZE - 1
    sampleRing[x] := long[adcPtr]
  sampleIndex := 0

  shrinkCount := SHRINK_COUNT
  decayCount := DECAY_SPEED

  repeat
    frame.ShowAll(0)

    rawSample := long[adcPtr]
    sampleRing[sampleIndex] := rawSample
    sampleIndex := sampleIndex + 1
    if sampleIndex => SAMPLE_RING_SIZE
      sampleIndex := 0

    ' sample is the average of the last SAMPLE_RING_SIZE samples
    aveSample := 0
    repeat x from 0 to SAMPLE_RING_SIZE - 1
      aveSample := aveSample + sampleRing[x]
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
      frame.Row(0, c)
    if displayLeveL > (midA + (stepA * 2))
      c := frame.ColourInPalette(baseColour + colourInc)
      frame.Row(1, c)
    if displayLeveL > (midA + (stepA * 3))
      c := frame.ColourInPalette(baseColour + (colourInc * 2))
      frame.Row(2, c)
    if displayLeveL > (midA + (stepA * 4))
      c := frame.ColourInPalette(baseColour + (colourInc * 3))
      frame.Row(3, c)
    if displayLeveL > (midA + (stepA * 5))
      c := frame.ColourInPalette(baseColour + (colourInc * 4))
      frame.Row(4, c)
    if displayLeveL > (midA + (stepA * 6))
      c := frame.ColourInPalette(baseColour + (colourInc * 5))
      frame.Row(5, c)
    if displayLeveL > (midA + (stepA * 7))
      c := frame.ColourInPalette(baseColour + (colourInc * 6))
      frame.Row(6, c)
    if displayLeveL > (midA + (stepA * 8))
      c := frame.ColourInPalette(baseColour + (colourInc * 7))
      frame.Row(7, c)

'    waitcnt(delay + cnt) ' gives us a more consistent frame rate
    frame.swapBuffers
