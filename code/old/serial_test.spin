CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 4_000_000

  REDPIN = 0
  GREENPIN = 1
  BLUEPIN = 2

  DELAY = 9_000_000
OBJ

  pst    : "Parallax Serial Terminal"
PUB Toggle
  pst.Start(115200)
  pst.Str(String("hello there"))
  dira[REDPIN] := 1
  dira[GREENPIN] := 1
  dira[BLUEPIN] := 1

  repeat
    outa[REDPIN] := 1
    waitcnt(cnt + DELAY)
    outa[REDPIN] := 0
    waitcnt(cnt + DELAY)
    pst.Str(String("x "))
