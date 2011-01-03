{
  This is the main entry point to the core controller of the LED cylinder. This handles start-up and
  ongoing overall control, which includes:
  - polling the command queue that takes instructions from the user.
  - polling the debug queue and dispatching debugging info to the DebugController.
  - holding and executing the process schedule.
}

CON
  _clkmode = XTAL1 + PLL16X
  _xinfreq = 5_000_000

  TEST_LED_PIN = 27
VAR
  ' debug message queue
  long debugBuffer[20]

  ' cylinder frame buffers, 2 of 128 longs etc. Each long is an RGB value.
  long frameBuffer[256]

  ' cylinder row currently being displayed. Coordinates between
  ' CylinderControllerPWM and CylinderControllerTransmitter.
  long currentLedRow



  ' frame control. Low byte is $0 or $1, determining the currently displaying
  ' frame.
  long frameControl

  ' global buffers that can be given to all processes
  long globalBuffers[10]

  ' semaphores:
  ' 0: debug
  byte semaphores[8]


  long delay
  long i
  long j
  long m
  long y
  long r
  long dir
OBJ
 '  debug         : "DebugController"
   cylinderPWM   : "CylinderControllerPWM"
   cylinderTrans : "CylinderControllerTransmitter"
'  testdebug     : "TestQueueDebug"
   nunchuck      : "Nunchuck"
   terminal      : "Parallax Serial Terminal"
   random        : "RealRandom"
PUB Main
'  clkset(%01101101, 64_000_000) ' 16MHz crystal with x4 multipler

  ' Turn blue light on
  dira[TEST_LED_PIN] := 1
  outa[TEST_LED_PIN] := 1

  ' set up global buffers
  globalBuffers[0] := @frameBuffer
  globalBuffers[2] := @frameControl
  globalBuffers[9] := @debugBuffer

  ' start debugging
'  debug.Start
'  semaphores[0] := locknew
'  debugBuffer[0] := 0
'  testdebug.Start(@globalBuffers, @semaphores, 5000000)
  terminal.Start(115200)
  terminal.Str(String("Cylinder started"))

  random.start

  ' start cylinder
  currentLedRow := 3
  cylinderTrans.Start(@currentLedRow, @frameBuffer)
  cylinderPWM.Start(@currentLedRow)

  repeat
    showAll($ffffff)
    waitcnt(150_000_000 + cnt)

    delay := 100_100
    repeat 5
      ' go down
      i := 255
      repeat until i == 0
        j := (i << 16) + (i << 8) + i
        showAll(j)
        waitcnt(delay + cnt)
        i := i - 1

      ' go up
      i := 0
      repeat until i == 255
        j := (i << 16) + (i << 8) + i
        showAll(j)
        waitcnt(delay + cnt)
        i := i + 1

      delay := delay - 20_000

    showAll($ff0000)
    waitcnt(150_000_000 + cnt)
    showAll($00ff00)
    waitcnt(150_000_000 + cnt)
    showAll($0000ff)
    waitcnt(150_000_000 + cnt)

    ' red rows up and down
    i := $ff0000
    repeat 3
      repeat m from 0 to 7
        showRow(m, i)
        waitcnt(5_000_000 + cnt)
      repeat m from 6 to 1
        showRow(m, i)
        waitcnt(5_000_000 + cnt)
      i >>= 8

    repeat 100
      r := random.random
      r &= $ffffff
      r += 1000
      showRandom
      waitcnt(r + cnt)

PRI showAll(colour) | ci
  repeat ci from 0 to 255
    frameBuffer[ci] := colour

PRI showRandom | v
  repeat v from 0 to 255
    frameBuffer[v] := random.random

PUB showRow(row,colour) | v, k
  repeat v from 0 to 255
    if v => row * 16 and v < (row+1) * 16
      frameBuffer[v] := colour
    else
      frameBuffer[v] := 0
  return

'  nunchuck.init(26,27)
  repeat
'    terminal.Char("X")
'    outa[BLUEPIN] := 1
'    nunchuck.readNunchuck
 '   outa[REDPIN] := 1
'    terminal.Dec(nunchuck.buttonZ)
'    if nunchuck.buttonZ
'      frameBuffer[0] := $ffffff
 '   else
'      frameBuffer[0] := 0
'    y := nunchuck.joyX ' 0-255
'    frameBuffer[0] := y << 16

'    waitcnt(cnt + 5_000_000)
'    outa[GREENPIN] := 0

