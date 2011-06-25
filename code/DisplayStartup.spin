con
  MAX_PARTICLES = 8
  BACKGROUND_ROWS = 16
  BACKGROUND_SCROLL_SPEED = 10

  BACKGROUND_EASING_RESOLUTION = 4
  BACKGROUND_EASING_STEPS = 16 ' needsto be 2^BACKGROUND_EASING_RESOLUTION
  BACKGROUND_EASING_PRECISION = 8 ' 8 bits binary precision, must be more than the resolution
var
  long Stack[80]
  byte cog
  long frameBufPtr
  long randomPtr

  long backgroundColour
  long backgroundY
  long backgroundScrollCount
  long backgroundEasingCount
'  long backgroundChangeTime
'  long backgroundInc

  ' track where we are up to in the sequence
  long frameCounter

  ' buffer for background calculation
  long bgPartial[128]
  long bgRedInc[128]
  long bgGreenInc[128]
  long bgBlueInc[128]

obj
  frame       : "FrameManipulation"

PUB Start(globalBuffersPtr) : success | ci
  Stop

  randomPtr := long[globalBuffersPtr][2]

  frame.Init(globalBuffersPtr)

  success := (cog := cognew(Run, @Stack) + 1)

PUB Stop
  if cog
    cogstop(cog~ - 1)

PRI Run | i, delay, drop, nextCol, startCnt, c
  frame.EnableDoubleBuffering
  frameCounter := 0

  ' Set up the background colour
  backgroundColour := $40
  backgroundY := 6
  backgroundScrollCount := 1 ' triggers reset
  backgroundEasingCount := 1

  if alphablended == 0
    BlendBackgroundColour

  repeat
    Background

    frame.swapBuffers

'    delay := 2_000

'    waitcnt(delay + cnt) ' gives us a more consistent frame rateBACKGROUND_EASING_PRECISION

' The background is basically a night blue that morphs into a sunrise.
' @TODO: allocate a buffer to render this in, as the calculation is expensive,
'        and use that for rendering plus any alpha manipulation we need
PRI Background | x, y, base, c, ratio, i, r, g, b, dest, p
  ' work the counters. The bigger counter is backgroundScrollCount, which
  ' causes a scroll of the background image. The smaller counter is
  ' backgroundEasingCount, which is used to ease colours from one 'frame'
  ' to the next.
  backgroundEasingCount := backgroundEasingCount - 1
  if backgroundEasingCount == 0
    backgroundEasingCount := BACKGROUND_EASING_STEPS
    backgroundScrollCount := backgroundScrollCount - 1
    if backgroundScrollCount == 0
      if backgroundY > 0
        backgroundY := backgroundY - 1
      backgroundScrollCount := BACKGROUND_SCROLL_SPEED

  if backgroundScrollCount == BACKGROUND_SCROLL_SPEED
    ' ok, if we're starting a new step loop, copy the right part of the data into
    ' our temp buffer. We do the alpha blending at this stage of background color to image
    ' section, since our easing adjustment below is purely incremental, so background colour
    ' shouldn't affect it.
    ' Also, we calculate the easing increments so we can apply them easily

    ' Use backgroundY as an index into 'sun', and copy data from that
    ' row and up.
    base := (BACKGROUND_ROWS - backgroundY - 1) * 16
    dest := 0
    repeat y from 0 to 7
      if base => 0
        ' copy image row backgroundY + y to display row y
        repeat x from 0 to 15
          c := long[@sun][base + x]
          bgPartial[dest + x] := c ' @todo make faster with mem copy
          p := long[@sun][base + x + 16]
          bgRedInc[dest + x] := calcInc((c & $ff0000) >> 16, (p & $ff0000) >> 16)
          bgGreenInc[dest + x] := calcInc((c & $ff00) >> 8, (p & $ff00) >> 8)
          bgBlueInc[dest + x] := calcInc(c & $ff, p & $ff)
        base -= 16
        dest += 16

     ' get the colour at
  ' now apply the easing to that buffer and render it
'  if backgroundEasingCount <> BACKGROUND_EASING_STEPS
  ' apply easing from the
  ' calculate the ratio of how far through the step we are. This determines
  ' how much of the transition is applied this iteration.
  ratio := BACKGROUND_EASING_STEPS - backgroundEasingCount

    ' Iterate over bgPartial, and apply increments, storing this to the frame buffer
  repeat i from 0 to 127
    c := bgPartial[i]
    r := (c & $ff0000) >> 16
    g := (c & $ff00) >> 8
    b := c & $ff
      ' multiply the inc by how far thru we are, and shift down to remove decimal part.
    r += (bgRedInc[i] * ratio) >> BACKGROUND_EASING_PRECISION
    g += (bgGreenInc[i] * ratio) >> BACKGROUND_EASING_PRECISION
    b += (bgBlueInc[i] * ratio) >> BACKGROUND_EASING_PRECISION
'    frame.PixelAbs(i, frame.RGBToColour(r,g,b))
    frame.PixelAbs(i, c)

{
  '------------------ old code after this
  ' Use backgroundY as an index into 'sun', and copy data from that
  ' row and up.
  base := (BACKGROUND_ROWS - backgroundY - 1) * 16
  repeat y from 0 to 7
    if base => 0
      ' copy image row backgroundY + y to display row y
      repeat x from 0 to 15
        c := long[@sun][base + x]
        frame.PixelAlpha(x, y, c)
      base := base - 16
    else
      ' simulate the delay of a row render so that the pace is the same
      waitcnt(cnt + 1000)

  backgroundCount := backgroundCount - 1
  if backgroundCount == 0
    if backgroundY > 0
      backgroundY := backgroundY - 1
    backgroundCount := BACKGROUND_SCROLL_SPEED
}
' given a component of colour (8-bit), determine the increment. This is basically just
' the increase on each easing function by which the colour change. The increment is
' a fractional number, so is multiplied by 32 (5 binary points)
pri calcInc(fromColour, toColour) : inc | delta
  delta := toColour - fromColour
  inc := (delta << BACKGROUND_EASING_PRECISION) >> BACKGROUND_EASING_RESOLUTION

pri BlendBackgroundColour | i, c
  repeat i from 0 to ((BACKGROUND_ROWS - 1) * 16) - 1
    c := frame.AlphaBlendPixel(backgroundColour, long[@sun][i])
    long[@sun][i] := c
  alphablended := 1
DAT

' this is set to non-zero once the background colour has been alpha-blended into
' the data below, which saves quite a bit of computation.
alphablended  long      0

' Sun is a long image which is slowly scrolled up as part of the background.
' The background function keeps track of the lowest y coord, which starts high
' and goes down.
' @todo add extra blank rows at the top so we always
sun
        ' row 15
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000

        ' row 14
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000

        ' row 13
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000

        ' row 12
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000

        ' row 11
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000

        ' row 10
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000

        ' row 9
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000

        ' row 8
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000
        long            $00000000

        ' row 7
        long            $01ffff00
        long            $01ffff00
        long            $01ffff00
        long            $01ffff00
        long            $02ffff00
        long            $02ffff00
        long            $04ffff00
        long            $04ffff00
        long            $04ffff00
        long            $04ffff00
        long            $02ffff00
        long            $02ffff00
        long            $01ffff00
        long            $01ffff00
        long            $01ffff00
        long            $01ffff00

        ' row 6
        long            $02ffff00
        long            $02ffff00
        long            $02ffff00
        long            $02ffff00
        long            $04ffff00
        long            $04ffff00
        long            $08ffff00
        long            $08ffff00
        long            $08ffff00
        long            $08ffff00
        long            $04ffff00
        long            $04ffff00
        long            $02ffff00
        long            $02ffff00
        long            $02ffff00
        long            $02ffff00

        ' row 5
        long            $04ffff00
        long            $04ffff00
        long            $04ffff00
        long            $04ffff00
        long            $08ffff00
        long            $08ffff00
        long            $10ffff00
        long            $10ffff00
        long            $10ffff00
        long            $10ffff00
        long            $08ffff00
        long            $08ffff00
        long            $04ffff00
        long            $04ffff00
        long            $04ffff00
        long            $04ffff00

        ' row 4
        long            $08ffff00
        long            $08ffff00
        long            $08ffff00
        long            $08ffff00
        long            $10ffff00
        long            $10ffff00
        long            $20ffff00
        long            $20ffff00
        long            $20ffff00
        long            $20ffff00
        long            $10ffff00
        long            $10ffff00
        long            $08ffff00
        long            $08ffff00
        long            $08ffff00
        long            $08ffff00

        ' row 3
        long            $10ffff00
        long            $10ffff00
        long            $10ffff00
        long            $10ffff00
        long            $20ffff00
        long            $20ffff00
        long            $40ffff00
        long            $40ffff00
        long            $40ffff00
        long            $40ffff00
        long            $20ffff00
        long            $20ffff00
        long            $10ffff00
        long            $10ffff00
        long            $10ffff00
        long            $10ffff00

        ' row 2
        long            $20ffff00
        long            $20ffff00
        long            $20ffff00
        long            $20ffff00
        long            $40ffff00
        long            $40ffff00
        long            $80ffff40
        long            $80ffff40
        long            $80ffff40
        long            $80ffff40
        long            $40ffff00
        long            $40ffff00
        long            $20ffff00
        long            $20ffff00
        long            $20ffff00
        long            $20ffff00

        ' row 1
        long            $40ffff00
        long            $40ffff00
        long            $40ffff00
        long            $40ffff00
        long            $80ffff00
        long            $c0ffff40
        long            $ffffff80
        long            $ffffff80
        long            $ffffff80
        long            $ffffff80
        long            $c0ffff40
        long            $80ffff00
        long            $40ffff00
        long            $40ffff00
        long            $40ffff00
        long            $40ffff00

        ' row 0
        long            $80ffff00
        long            $80ffff00
        long            $80ffff00
        long            $80ffff00
        long            $c0ffff40
        long            $ffffff80
        long            $ffffffff
        long            $ffffffff
        long            $ffffffff
        long            $ffffffff
        long            $ffffff80
        long            $c0ffff40
        long            $80ffff00
        long            $80ffff00
        long            $80ffff00
        long            $80ffff00

