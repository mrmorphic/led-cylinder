CON
  _clkmode = XTAL1 + PLL16X
  _xinfreq = 4_000_000

  REDPIN = 0
  GREENPIN = 1
  BLUEPIN = 2

  BLANK_PIN = 4   { blank all outputs if high }
  GSCLK_PIN = 5   { clock for PWM }
  XLAT_PIN = 6    { copy shifted data to output latches }
  SCLK_PIN = 7    { rising edge clocks data in on SIN_PIN }
  SIN_PIN = 8     { data clocked in, MSB first }

  COLOR = $6ff    { max colour value }
  STROBE_LENGTH = 400  { 6: just under 90ns at 4MHz xtal }
  BLANK_LENGTH = 2
VAR
  long  colorShift
  long  c
  long resetCount
OBJ

  pst    : "Parallax Serial Terminal"
PUB Toggle
  pst.Start(115200)
  pst.Str(String("PWM test"))
  dira[BLANK_PIN] := 1
  dira[GSCLK_PIN] := 1
  dira[XLAT_PIN] := 1
  dira[SCLK_PIN] := 1
  dira[SIN_PIN] := 1

  dira[REDPIN] := 1
  dira[GREENPIN] := 1
  dira[BLUEPIN] := 1

  outa[BLUEPIN] := 1

  {initialise}
  outa[SCLK_PIN] := 0
  outa[GSCLK_PIN] := 0
  outa[XLAT_PIN] := 0
  outa[BLANK_PIN] := 0
  waitcnt(STROBE_LENGTH + cnt)
  outa[BLUEPIN] := 0
  outa[REDPIN] := 1

  repeat
    outa[REDPIN] := !outa[REDPIN]

    { load data }
    repeat 16
      colorShift := COLOR
      c := 11
      repeat 12 {c from 11 to 0 step -1}
        { shift in a bit, MSB first }
        if COLOR & (1<<c)
          outa[SIN_PIN] := 1
        else
          outa[SIN_PIN] := 0
        c := c - 1
  {      waitcnt(STROBE_LENGTH + cnt)}

        { SCLK pulse }
        outa[SCLK_PIN] := 1
        outa[SCLK_PIN] := 0
{        waitcnt(STROBE_LENGTH + cnt)}

{    waitcnt(STROBE_LENGTH + cnt)}

    { XLAT pulse to load the PWM data }
    outa[XLAT_PIN] := 1
{    waitcnt(STROBE_LENGTH + cnt)}
    outa[XLAT_PIN] := 0
{    waitcnt(STROBE_LENGTH + cnt)}

    outa[SCLK_PIN] := 1
{    waitcnt(STROBE_LENGTH + cnt)}
    outa[SCLK_PIN] := 0
{    waitcnt(STROBE_LENGTH + cnt)}

    { set BLANK low }
    outa[BLANK_PIN] := 1
    outa[BLANK_PIN] := 0
{    waitcnt(STROBE_LENGTH + cnt)}

    { 4096 gsclocks }
    repeat 4096
      outa[GSCLK_PIN] := 1
      outa[GSCLK_PIN] := 0


  { clock in 192 bits of data (16 * 12-bits) }
  repeat 16
{    outa[SIN_PIN] := 0}
{    colorShift := COLOR}
    c := 11
    repeat 12
      colorShift := (COLOR >> c) & 1
{      if (colorShift & (1<<c)) <> 0 }
      if colorShift > 0
        outa[SIN_PIN] := 1
      else
        outa[SIN_PIN] := 0
      c := c - 1
      waitcnt(STROBE_LENGTH + cnt)

{      colorShift <<= 1}
      outa[SCLK_PIN] := 1
{      waitcnt(STROBE_LENGTH + cnt)}
      outa[SCLK_PIN] := 0
{      waitcnt(STROBE_LENGTH + cnt)}

  outa[BLANK_PIN] := 1
  waitcnt(BLANK_LENGTH + cnt)
  outa[XLAT_PIN] := 1
  waitcnt(STROBE_LENGTH + cnt)
  outa[XLAT_PIN] := 0
  waitcnt(STROBE_LENGTH + cnt)
  outa[BLANK_PIN] := 0
{  repeat 3000
    !outa[GSCLK_PIN]}

  dira[REDPIN]~~
  dira[GREENPIN]~~
  dira[BLUEPIN]~~

  outa[GSCLK_PIN] := 0
  outa[BLANK_PIN] := 1
  outa[BLANK_PIN] := 0
  resetCount := 0
  repeat
    outa[GSCLK_PIN] := 1
    waitcnt(STROBE_LENGTH + cnt)
    outa[GSCLK_PIN] := 0
{    !outa[GSCLK_PIN]}
    waitcnt(STROBE_LENGTH + cnt)
    resetCount++
    if resetCount == 4096
      resetCount := 0
      outa[BLANK_PIN] := 1
      waitcnt(BLANK_LENGTH + cnt)
      outa[BLANK_PIN] := 0
      waitcnt(BLANK_LENGTH + cnt)
   {   waitcnt(STROBE_LENGTH + cnt)}

{    !outa[REDPIN]
    waitcnt(DELAY + cnt)
    !outa[GREENPIN]
    waitcnt(DELAY + cnt)
    !outa[BLUEPIN]
    waitcnt(DELAY + cnt)}
