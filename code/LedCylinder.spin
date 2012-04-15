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
  - 7: ADC
  Compiler path must include ./lib

  Port usage:
    P0:         TLC5940 BLANK
    P1:         TLC5940 GSCLK
    P2:         TLC5940 XLAT
    P3:         TLC5940 SCLK
    P4:         TLC5940 SIN (red chip top 4 four rows)
    P5:         TLC5940 SIN (green chip top four rows)
    P6:         TLC5940 SIN (blue chip top four rows)
    P7:         TLC5940 SIN (red chip bottom four rows)
    P8:         TLC5940 SIN (green chip bottom four rows)
    P9:         TLC5940 SIN (blue chip bottom four rows)
    P10:        ROWSEL 0
    P11:        ROWSEL 1
    P12:        ROW enable for led cyclinder
    P13:        ADC CLK
    P14:        ADC CS/SHDN
    P15:        ADC Din/Dout
    P16:        ADC DOUT
    P17:        N/C
    P18:        reserved for LCD backlight
    P19:        LCD E
    P20:        LCD RW
    P21:        LCD RS
    P22:        LCD DB4
    P23:        LCD DB5
    P24:        LCD DB6
    P25:        LCD DB7
    P26:        N/C
    P27:        N/C
    P28:        I2C clock
    P29:        I2C data
    P30:        serial TX
    P31:        serial RX



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
  MAX_DISPLAYS      = 11
  #1
  DISPLAY_STARTUP
  DISPLAY_RAIN
  DISPLAY_BLOBS
  DISPLAY_RINGS
  DISPLAY_RAINBOW
  DISPLAY_BARS
  DISPLAY_SPINNER
  DISPLAY_LIFE
  DISPLAY_RANDOM
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

  ADC_DATA_PIN = 15
  ADC_CLK_PIN = 13
  ADC_RSCS_PIN = 14
  ADC_CHANNELS = 2
  ADC_BITCOUNT = 10

  STARTUP_TIME = 1340000000

  MODE_DISPLAY_TIME = 500000000
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
  long keycode

  long calibX
  long calibY
  long adcValue
  long maxAdc
  long minAdc

  ' index of current display, 1..maxDisplays
  long currentDisplay

  byte menuControl

  byte displayTimer
  long displayTimeout
obj
   cylinderPWM     : "CylinderControllerPWM"
   cylinderTrans   : "CylinderControllerTransmitter"
   nunchuck        : "Nunchuck"
'   terminal        : "Parallax Serial Terminal"
   random          : "RealRandom"
   frame           : "FrameManipulation"
   LCD             : "jm_lcd4_ez"
   adc             : "MCP3202"
   displayStartup  : "DisplayStartup"
   displayRandom   : "DisplayRandom"
   displayTest     : "DisplayTest"
   displayBlobs    : "DisplayBlobs"
   displaySelfPong : "DisplaySelfPong"
   displayRain     : "DisplayRain"
   displaySpinner  : "DisplaySpinner"
   displayRings    : "DisplayRings"
   displayRainbow  : "DisplayRainbow"
   displayBars     : "DisplayBars"
   displayLife     : "DisplayLife"
'   displayFade   : "DisplayFade"

pub Main | rpt, newDisplay, startCnt, startupDone
  ' Turn blue light on. Any project worth it's salt has to have a blue light.
  dira[TEST_LED_PIN] := 1
  outa[TEST_LED_PIN] := 1

'  terminal.Start(115200)
'  terminal.Str(String("Started"))
'  terminal.NewLine

  random.start

  ' set up global buffers
  globalBuffers[0] := @frameBuffer
  globalBuffers[1] := @frameBufferControl
  globalBuffers[2] := random.random_ptr
  globalBuffers[3] := @adcValue

  ' initialise frame buffer
  frameBufferControl := 0
  frame.Init(@globalBuffers)
  frame.SetDrawingBuffer(1)  ' clear both frame buffers
  frame.ShowAll(0)
  frame.SetDrawingBuffer($ff0000)
  frame.ShowAll(0)

  ' start the assembly-base cog that gives faster frame manipulation functions
  frame.Start

  LCD.init(LCDBasePin, 2, 16)
  LCD.display(1)
  LCD.cmd(LCD#HOME)
  LCD.str(string(" Welcome human  "))
  LCD.cmd(LCD#LINE2)
  LCD.str(string("                "))

  ' nunchuck init on standard i2c pins
  nunchuck.init(28,29)

  ' calibrate x and y
  nunchuck.readNunchuck 'read data from Nunchuck
  calibX := nunchuck.joyX
  calibY := nunchuck.joyY
  waitcnt(clkfreq/64 + cnt) 'wait for a short period (important when using nunchuck, or will return bad data)

  ' start cylinder
  currentLedRow := 3
  cylinderTrans.Start(@currentLedRow, @frameBuffer, @frameBufferControl)
  cylinderPWM.Start(@currentLedRow)

  ' start ADC
  adc.start(ADC_DATA_PIN, ADC_CLK_PIN, ADC_RSCS_PIN, 0)

  ' Set the enable pin low, which enables physical refresh. By default this pin is an
  ' input and pulled high, which disables the 74HC139 that drives row anodes. When
  ' the propeller gets reset, it goes back to input, effectively blanking the output.
  ' This allows us to overdrive the current in the LEDs. Without this explicit enabling,
  ' a random row will be driven by the TLC5940's, with no multiplexing, which could burn
  ' the LEDs out on that row.
  dira[ENABLE_DISPLAY_PIN] := 1
  outa[ENABLE_DISPLAY_PIN] := 0

  ' initialise, which triggers change in display
  currentDisplay := 0
  newDisplay := DISPLAY_STARTUP
  rpt := 0

  displayTimer := 0

  menuControl := 0

  startCnt := CNT
  startupDone := 0

  minAdc := 1024
  maxAdc := 0
  ' This is the main control loop.
  repeat
    ' ping the ADC
    adcValue := adc.in(0)
    if adcValue < minAdc
      minAdc := adcValue
    if adcValue > maxAdc
      maxAdc := adcValue
'    LCD.cmd(LCD#HOME)
'    LCD.dec(adcValue)
'    LCD.str(String("   "))
'    LCD.dec(minAdc)
'    LCD.str(String(" "))
'    LCD.dec(maxAdc)
'    LCD.str(String(" "))

    if currentDisplay <> 0
      newDisplay := currentDisplay

    ' read data from nunchuck, with a short delay afterwards, or it will return bad data.
    nunchuck.readNunchuck
    waitcnt(clkfreq/64 + cnt)

    calcMenuControl

'    LCD.cmd(LCD#HOME)
'    LCD.str(String("x="))
'    LCD.dec(nunchuck.joyX - calibX)
'    LCD.str(String(" y="))
'    LCD.dec(nunchuck.joyY - calibY)
'    LCD.str(String("     "))

'    LCD.cmd(LCD#LINE2)
'    LCD.str(String("bz="))
'    LCD.dec(nunchuck.buttonZ)
'    LCD.str(String(" "))
'    LCD.str(String("bc="))
'    LCD.dec(nunchuck.buttonC)
'    LCD.str(String("   "))

    ' Work out changes selected by user, if any
    if menuControl == MENU_STATE_RIGHT_FINAL
      newDisplay := newDisplay + 1
      if newDisplay > MAX_DISPLAYS
        newDisplay := 2        ' skips startup
      menuControl := MENU_STATE_NONE
    if menuControl == MENU_STATE_LEFT_FINAL
      newDisplay := newDisplay - 1
      if newDisplay < 2        ' skips startup
        newDisplay := MAX_DISPLAYS
      menuControl := MENU_STATE_NONE

    if CNT > (startCnt + STARTUP_TIME) and startupDone == 0
      startupDone := 1
      newDisplay := DISPLAY_RAIN

    'output data read to serial port
'    uart.dec(Nun.joyX)
'    uart.dec(Nun.joyY)
'    uart.dec(Nun.accelX)
'    uart.dec(Nun.accelY)
'    uart.dec(Nun.accelZ)
'    uart.dec(Nun.pitch)
'    uart.dec(Nun.roll)
'    uart.dec(Nun.buttonC)
'    uart.dec(Nun.buttonZ)

    if newDisplay <> currentDisplay and rpt == 0
      ' stop old display, if there is one
      case currentDisplay
        DISPLAY_STARTUP:
          displayStartup.Stop

        DISPLAY_RAIN:
          displayRain.Stop

        DISPLAY_BLOBS:
          displayBlobs.Stop

        DISPLAY_RINGS:
          displayRings.Stop

        DISPLAY_RAINBOW:
          displayRainbow.Stop

        DISPLAY_BARS:
          displayBars.Stop

        DISPLAY_SPINNER:
          displaySpinner.Stop

        DISPLAY_LIFE:
          displayLife.Stop

        DISPLAY_RANDOM:
          displayRandom.Stop

        DISPLAY_SELFPONG:
          displaySelfPong.Stop

        DISPLAY_TEST:
          displayTest.Stop

      currentDisplay := newDisplay
      startupDone := 1

      ' start new display
      case currentDisplay
        DISPLAY_STARTUP:
          startupDone := 0
          displayStartup.Start(@globalBuffers)

        DISPLAY_RAIN:
          setName(string("Rain    "))
          displayRain.Start(@globalBuffers)

        DISPLAY_BLOBS:
          setName(string("Blobs   "))
          displayBlobs.Start(@globalBuffers)

        DISPLAY_RINGS:
          setName(string("Rings   "))
          displayRings.Start(@globalBuffers)

        DISPLAY_RAINBOW:
          setName(string("Rainbow "))
          displayRainbow.Start(@globalBuffers)

        DISPLAY_BARS:
          setName(string("VU Meter"))
          displayBars.Start(@globalBuffers)

        DISPLAY_SPINNER:
          setName(string("Spinner "))
          displaySpinner.Start(@globalBuffers)

        DISPLAY_LIFE:
          setName(string("Life "))
          displayLife.Start(@globalBuffers)

        DISPLAY_RANDOM:
          setName(string("Random  "))
          displayRandom.Start(@globalBuffers)

        DISPLAY_SELFPONG:
          setName(string("SelfPong"))
          displaySelfPong.Start(@globalBuffers)

        DISPLAY_TEST:
          setName(string("Test    "))
          displayTest.Start(@globalBuffers)
    if displayTimer == 1 and displayTimeout < CNT
      displayRandomStuff
      displayTimer := 0

' set menu control based on nunchuck inputs and prior state
pub calcMenuControl
  ' first, both C but not Z must be pressed
  if nunchuck.buttonC <> 1 and nunchuck.buttonZ <> 0
    menuControl := MENU_STATE_NONE
    return

  if menuControl == MENU_STATE_NONE and nunchuck.joyX > 80
    menuControl := MENU_STATE_RIGHT_1
    return
  if menuControl == MENU_STATE_RIGHT_1
    if nunchuck.joyX < 81
      menuControl := MENU_STATE_RIGHT_FINAL
    return
  if menuControl == MENU_STATE_NONE and nunchuck.joyX < -80
    menuControl := MENU_STATE_LEFT_1
    return
  if menuControl == MENU_STATE_LEFT_1
    if nunchuck.joyX > -80
      menuControl := MENU_STATE_LEFT_FINAL
    return

  menuControl := MENU_STATE_NONE
'  Nun.buttonC
 ' MENU_STATE_NONE               = 0
'  MENU_STATE_LEFT_1             = 1
'  MENU_STATE_LEFT_FINAL         = 2
'  MENU_STATE_RIGHT_1            = 3
'  MENU_STATE_RIGHT_FINAL        = 4
'  MENU_STATE_UP_1               = 5
'  MENU_STATE_UP_FINAL           = 6
'  MENU_STATE_DOWN_1             = 7
'  MENU_STATE_DOWN_FINAL         = 8

pub setName(str)
  LCD.cmd(LCD#HOME)
  LCD.str(string("mode: "))
  LCD.str(str)
  LCD.str(string("   "))
  LCD.cmd(LCD#LINE2)
  LCD.str(string("                "))
  LCD.cursor(2)
  displayTimeout := CNT + MODE_DISPLAY_TIME
  displayTimer := 1

PUB displayRandomStuff
  LCD.cmd(LCD#HOME)
  LCD.str(string("use nunchuck L/R"))
  LCD.cmd(LCD#LINE2)
  LCD.str(string("    to change   "))

