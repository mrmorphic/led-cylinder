con
  SPEED = 10
  FADE_IN_STEPS = 128
  FADE_IN_DELAY = 15
  COLOUR1 = $ff0000
  COLOUR2 = $00ff00
  COLOUR3 = $00ffff

  BG_SPEED = 3
  BG_MAX = 127
  BG_MIN = -200
  BG_DARK_DELAY = 50

  STAGE_2_ROW_HEIGHT = 8

var
  long Stack[80]
  byte cog
  long frameBufPtr
  long randomPtr
  long displayControlPtr

  long Palette[FADE_IN_STEPS * 4]

  long backgroundColour

  long c1a, c1b, c1c, c1d, c2a, c2b, c2c, c2d

  long st2row1y, st2row2y
obj
  frame       : "FrameManipulation"

PUB Start(globalBuffersPtr) : success | ci
  Stop

  randomPtr := long[globalBuffersPtr][2]
  displayControlPtr := long[globalBuffersPtr][4]

  frame.Init(globalBuffersPtr)

  success := (cog := cognew(Run, @Stack) + 1)

PUB Stop
  if cog
    cogstop(cog~ - 1)

PRI Run | count, x, spd, intensity, intcount, bgCount, bgDir, bgColVirt, st2count, running
  frame.EnableDoubleBuffering

  CalcPalette

  ' start off showing nothing
  setPalette(0)

  backgroundColour := $000003
  bgColVirt := backgroundColour

  bgCount := 1000
  bgDir := 1

  count := 0
  x := 0
  spd := SPEED

  intcount := FADE_IN_DELAY
  intensity := 0

  ' stage 2 rows are just off screen
  st2row1y := 8
  st2count := -2850
  running := 1

  repeat while running == 1
    Background

    line(x, c1a)
    line(x-1, c1b)
    line(x-2, c1c)
    line(x-3, c1d)

    line(x+8, c2a)
    line(x+7, c2b)
    line(x+6, c2c)
    line(x+5, c2d)

    spd := spd - 1
    if spd == 0
      spd := SPEED
      x := (x + 1) & $f

    ' check for intensity increase as we ramp up bars to full brightness
    intcount := intcount - 1
    if intcount == 0
      intcount := FADE_IN_DELAY
      intensity := intensity + 1
      if intensity > (FADE_IN_STEPS - 1)
        intensity := FADE_IN_STEPS - 1
      setPalette(intensity)

    ' background pulses in and out
    bgCount := bgCount - 1
    if bgCount < BG_SPEED
      if bgCount == 0
            bgCount := BG_SPEED
            if bgDir == 1
              backgroundColour := backgroundColour + 2
              bgColVirt := backgroundColour
              if backgroundColour => BG_MAX
                bgDir := -1
            else
              backgroundColour := backgroundColour - 2
              bgColVirt := bgColVirt - 2
              if backgroundColour < $3
                backgroundColour := $3
              if bgColVirt =< BG_MIN
                bgDir := 1

    st2count := st2count + 1
    if st2count => 0
      if st2count == 0
        st2row1y := st2row1y + 1

      if (st2count // 8) == 0
        ' adjust the stage 2 bar position
        st2row1y := st2row1y - 1
        if (st2row1y + STAGE_2_ROW_HEIGHT - 1) < 0
          running := 0
          long[displayControlPtr] := 1
      drawStage2Row

    frame.swapBuffers

PRI setPalette(intensity) | m1, m2, m3, offset
  offset := intensity * 4
  c1a := frame.AlphaBlendPixel(backgroundColour, COLOUR1 | palette[offset])
  c1b := frame.AlphaBlendPixel(backgroundColour, COLOUR1 | palette[offset+1])
  c1c := frame.AlphaBlendPixel(backgroundColour, COLOUR1 | palette[offset+2])
  c1d := frame.AlphaBlendPixel(backgroundColour, COLOUR1 | palette[offset+3])
  c2a := frame.AlphaBlendPixel(backgroundColour, COLOUR2 | palette[offset])
  c2b := frame.AlphaBlendPixel(backgroundColour, COLOUR2 | palette[offset+1])
  c2c := frame.AlphaBlendPixel(backgroundColour, COLOUR2 | palette[offset+2])
  c2d := frame.AlphaBlendPixel(backgroundColour, COLOUR2 | palette[offset+3])

PRI line(x, colour)
  frame.Col(x & $f, colour)

PRI Background
  frame.ShowAll(backgroundColour)

' generate 0 to FADE_IN_STEPS-1 entries in Palette, from least to most bright. Each entry is 4 longs,
' the first being the full intensity line, second being lesser and so on.
PRI CalcPalette | i, offset
  offset := 0
  repeat i from 0 to FADE_IN_STEPS - 1
    ' i is the proportion of #steps
    ' when i is 0, palette all zero
    ' when i is FADE_IN_STEPS -1, want maximum intensity for given column
    Palette[offset] := (($ff * i) / FADE_IN_STEPS) << 24
    Palette[offset+1] := (($70 * i) / FADE_IN_STEPS) << 24
    Palette[offset+2] := (($30 * i) / FADE_IN_STEPS) << 24
    Palette[offset+3] := (($10 * i) / FADE_IN_STEPS) << 24
    offset := offset + 4

PRI drawStage2Row | i, j
  repeat i from 0 to STAGE_2_ROW_HEIGHT + 7
    j := st2row1y + i
    frame.Row(j, st2palette[i])

DAT
  ' STAGE_2_ROW_HEIGHT longs decreasing in intensity, plus 8 of black
  st2palette   long   $00ffff
               long   $00dddd
               long   $00bbbb
               long   $009999
               long   $007777
               long   $005555
               long   $003333
               long   $001111

               long   $000000
               long   $000000
               long   $000000
               long   $000000
               long   $000000
               long   $000000
               long   $000000
               long   $000000

