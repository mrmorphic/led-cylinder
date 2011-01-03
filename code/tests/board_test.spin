' primitive test that just blinks the LED. Tests that serial works, clock speed
' set correctly.
CON
  _clkmode = XTAL1 + PLL16X  { case-insensitive constants }
  _xinfreq = 5_000_000

'VAR
'  long counter

OBJ
  terminal    : "Parallax Serial Terminal"

PUB Toggle
  terminal.Start(115200)
  terminal.Str(String("Debugging started"))
'  counter := 0
  dira[27]~~
  repeat
    !outa[27]
    waitcnt(10_000_000 + cnt)
    terminal.Str(String("."))
