con
  SPEED = 10
  FADE_IN_STEPS = 128
  FADE_IN_DELAY = 15
  COLOUR1 = $ff0000
  COLOUR2 = $00ff00
  BG_SPEED = 3
  BG_MAX = 127
  BG_MIN = -200
  BG_DARK_DELAY = 50

var
  long Stack[80]
  byte cog
  long frameBufPtr
  long randomPtr

  long Palette[FADE_IN_STEPS * 4]

  long backgroundColour

  long c1a, c1b, c1c, c1d, c2a, c2b, c2c, c2d
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

PRI Run | stage, count, x, spd, intensity, intcount, bgCount, bgDir, bgColVirt
  frame.EnableDoubleBuffering

  CalcPalette

  ' start off showing nothing
  setPalette(0)

  backgroundColour := $000003
  bgColVirt := backgroundColour

  bgCount := 1000
  bgDir := 1

  stage := 1
  count := 0
  x := 0
  spd := SPEED

  intcount := FADE_IN_DELAY
  intensity := 0

  repeat
    Background

    case stage
      1:
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
        intcount := intcount - 1
        if intcount == 0
          intcount := FADE_IN_DELAY
          intensity := intensity + 1
          if intensity > (FADE_IN_STEPS - 1)
            intensity := FADE_IN_STEPS - 1
          setPalette(intensity)

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

