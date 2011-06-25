{
  This is the main entry point to the core controller of the LED cylinder. This handles start-up and
  ongoing overall control, which includes:
  - polling the command queue that takes instructions from the user.
  - holding and executing the process schedule.

  Cog usage:
  - 0: main device control, including I2C, nunchuck (no floating point) and LCD objects
  - 1: random number generator
  - 2: cylinder data transmitter
  - 3: cylinder PWM controller
  - 4: frame buffer routines (assembly optimised versions for speed)
  - 5: parallel serial terminal (debugging only)
  - 6: display function
  Compiler path must include ./lib

  User interaction is via the nunchuck. Holding C button indicates a control function:
  - left and right pulses on joystick move between displays

  @todo on user interaction:
  - speed (per function, as some functions may not scale in speed, or N/A)
  - overall rotation rate (handled at PWM driver level)

  @todo This is a list of displays to implement, in this order, plus what is left to do on them:
    - STARTUP:
    - BLOBS:
        - constantly morphing colour
        - smoother and less jerky that current
        - perhaps defined a fixed colour path and initial state
    - RAIN:
        - speed control
        - colour control (esp green to be like matrix)
    - PULSER:
        - responds with bars to music
        - cooler bars for lower volume
        - hotter colours for higher volume
    - DROPS:
        - generates randomly concentric drop animations, triggered by sounds
    - RINGS:
        - coloured rings horizontally, vertically and both.
        - multiple lines
        - changing background colour
    - RAINBOW:
        - coloured horizontal bands moving up from bottom
    - SPINNER
        - implement
        - particles rotating at speed, like of CERN
        - accelerated using nunchuck
    - FLASHER:
        - rapidly flash between different colours
        - 2 or 3 different streams, rapidly alternating
    - LIFE:
        - cellular automaton, random start pattern
    - RANDOM:
        - current random implementation
    - TEST
        - solid colour for each colour
        - horiz rings colour
        - vert rings each colour
        - controllable with nunchuck (Z to pause?)
}

con
  _clkmode = XTAL1 + PLL16X
  _xinfreq = 5_000_000

  ' On-board test LED, to let us know things are working.
  TEST_LED_PIN = 27

  ' This pin controls the active low enable pin on the display board's
  ' 74HC139, which selects rows to display.
  ENABLE_DISPLAY_PIN = 12

  ' Constants for IR receiver
'  _irrpin         = 26          'ir receiver module on this pin

  ' Constants for display handling
  MAX_DISPLAYS      = 14
  #1
  DISPLAY_STARTUP
  DISPLAY_BLOBS
  DISPLAY_RAIN
  DISPLAY_PULSER
  DISPLAY_DROPS
  DISPLAY_RINGS
  DISPLAY_RAINBOW
  DISPLAY_SPINNER
  DISPLAY_FLASHER
  DISPLAY_LIFE
  DISPLAY_RANDOM
  DISPLAY_IMAGE
  DISPLAY_SELFPONG
  DISPLAY_TEST

  ' Constants used by LCD display.
  LCDBasePin        = 18

  ' menu states
  #0
  MENU_STATE_NONE
  MENU_STATE_LEFT_1
  MENU_STATE_LEFT_FINAL
  MENU_STATE_RIGHT_1
  MENU_STATE_RIGHT_FINAL
  MENU_STATE_UP_1
  MENU_STATE_UP_FINAL
  MENU_STATE_DOWN_1
  MENU_STATE_DOWN_FINAL

var
  ' cylinder frame buffers, 2 of 128 longs etc. Each long is an RGB value.
  long frameBuffer[256]

  ' The next 4 bytes need to be contiguous and in this order. These are understood
  ' by FrameManipulation and also the CylinderController, which reference them via
  ' the reference to globalBuffers

  ' Used by CylinderController and FrameManipulation to control buffering and rendering.
  ' This is a bit mask. The constants FRAME_CTL_* in FrameManipulation define the meanings.
  long frameBufferControl

  ' cylinder row currently being displayed. Coordinates between
  ' CylinderControllerPWM and CylinderControllerTransmitter.
  long currentLedRow

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

