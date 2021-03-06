'' =================================================================================================
''
''   File....... jm_lcd4_ez.spin
''   Purpose.... 4-bit HD44780-compatible LCD driver in SPIN
''   Author..... Jon "JonnyMac" McPhalen (aka Jon Williams)
''               Copyright (c) 2009 Jon McPhalen
''               -- see below for terms of use
''   E-mail..... jon@jonmcphalen.com
''   Started.... 03 JUL 2009
''   Updated.... 19 JUL 2009
''
'' =================================================================================================

{{

  Connections:

    LCD.1  :: Ground
    LCD.2  :: +5v
    LCD.3  :: Contrast; connect to wiper of 10K pot with terminals to +5 and GND
    LCD.4  :: RS
    LCD.5  :: RW
    LCD.6  :: E
    LCD.7  :: DB0 (not used in this driver)
    LCD.8  :: DB1 (not used in this driver)     
    LCD.9  :: DB2 (not used in this driver)
    LCD.10 :: DB3 (not used in this driver)
    LCD.11 :: DB4 (through 4.7K) 
    LCD.12 :: DB5 (through 4.7K)  
    LCD.13 :: DB6 (through 4.7K)  
    LCD.14 :: DB7 (through 4.7K)  
    LCD.15 :: backlight power
    LCD.16 :: backlight ground; connect to transistor circuit controlled by BL pin

               5v
               
               │
            47 
               │ ┌─────────────┐
               └─┤A ┌───────┐  │
               ┌─┤K └───────┘  │
               │ └─────────────┘
          220  │
    BL ──── 2N3904
               │       
                      
    

}}               
                   

con

  US_001 = 80_000_000 / 1_000_000
  MS_001 = 80_000_000 / 1_000


con
  
  CLS     = $01                                                 ' clear the LCD 
  HOME    = $02                                                 ' move cursor home
  CRSR_LF = $10                                                 ' move cursor left 
  CRSR_RT = $14                                                 ' move cursor right 
  DISP_LF = $18                                                 ' shift display left 
  DISP_RT = $1C                                                 ' shift chars right 

  CGRAM   = $40                                                 ' character ram
  DDRAM   = $80                                                 ' display ram

  LINE1   = DDRAM | $00                                         ' cursor positions for col 1
  LINE2   = DDRAM | $40
  LINE3   = DDRAM | $14
  LINE4   = DDRAM | $54

  #0, CRSR_NONE, CRSR_ULINE, CRSR_BLINK, CRSR_UBLNK             ' cursor types


var

  long  inuse                                                   ' pins have previously been defined

  long  bl                                                      ' backlight control (optional)
  long  e
  long  rw
  long  rs
  long  db4
  long  db7
  long  lcdx                                                    ' width of lcd in columns
  long  lcdy                                                    ' height of lcd in rows

  byte  dispCtrl                                                ' display control bits


pub init(blpin, cols, lines) | okay

'' Initializes LCD driver in 4-bit mode
'' -- requires eight contiguous pins (even if backlight control is not used)
'' -- blpin is the backlight control pin; first in group

  if blpin > 20                                                 ' valid? (protect rx, tx, i2c)
    okay := inuse := false
       
  else
    finalize                                                    ' clear existing pins
    bl  := blpin                                                ' lcd backlight control circuit
    e   := blpin + 1                                            ' lcd.6
    rw  := blpin + 2                                            ' lcd.5
    rs  := blpin + 3                                            ' lcd.4
    db4 := blpin + 4                                            ' lcd.11
    db7 := blpin + 7                                            ' lcd.14

    if lookdown(cols : 8, 16, 20, 24, 32, 40)                   ' validate and set columns
      lcdx := cols
    else
      lcdx := 16

    if lookdown(lines : 1, 2, 4)                                ' validate and set rows
      lcdy := lines
    else
      lcdy := 2
    
    outa[db7..bl] := %0000_0000                                 ' clear pins
    dira[db7..bl] := %1111_1110                                 ' set outputs
    lcdinit   
    okay := inuse := true
  
  return okay 


pub finalize

'' Makes LCD buss pins inputs
'' -- works only if LCD has been previously defined

  if inuse
    dira[db7..bl] := %0000_0000
    inuse~


pub cmd(c)

'' Write command byte to LCD

  waitbusy                                                      ' wait for LCD to be ready
  outa[rs] := 0                                                 ' command mode
  wrlcd(c)
  

pub out(c)

'' Print character byte to LCD

  waitbusy                                                      ' wait for LCD to be ready
  outa[rs] := 1                                                 ' data mode 
  wrlcd(c)
 

pub str(pntr)

'' Print z-string at pntr

  repeat strsize(pntr)
    out(byte[pntr++])


pub dec(value) | i

'' Print a decimal number

  if value < 0
    -value
    out("-")

  i := 1_000_000_000

  repeat 10
    if value => i
      out(value / i + "0")
      value //= i
      result~~
    elseif result or (i == 1)
      out("0")
    i /= 10

 
pub hex(value, digits)

'' Print a hexadecimal number

  value <<= (8 - digits) << 2
  repeat digits
    out(lookupz((value <-= 4) & $F : "0".."9", "A".."F"))


pub bin(value, digits)

'' Print a binary number

  value <<= (32 - digits)
  repeat digits
    out((value <-= 1) & 1 + "0")


pub in | b

'' Reads byte at LCD cursor position

  waitbusy                                                      ' wait for LCD to be ready
  outa[rs] := 1                                                 ' data mode
  outa[rw] := 1                                                 ' read mode

  outa[e] := 1                                                  ' request high nibble
  waitcnt((5 * US_001) + cnt)                                   ' let buss settle
  b := ina[db7..db4] << 4                                       ' read high nibble
  outa[e] := 0                                                  ' finish nib read
  waitcnt((5 * US_001) + cnt)
  outa[e] := 1                                                  ' request low nibble                                                 
  waitcnt((5 * US_001) + cnt)
  b |= ina[db7..db4]                                            ' read low nibble
  outa[e] := 0

  return (b & $FF)


pub waitbusy | addr

'' Reads busy flag and cursor address
'' -- returns cursor address when busy flag has cleared

  dira[db7..db4] := %0000                                       ' make buss pins inputs
  outa[rs] := 0                                                 ' command mode
  outa[rw] := 1                                                 ' read

  repeat
    outa[e] := 1                                                ' request bf + high nib
    waitcnt((5 * US_001) + cnt)                                 ' let buss settle
    addr := ina[db7..db4] << 4                                  ' bf + high nib of address
    outa[e] := 0                                                ' finish nib read
    waitcnt((5 * US_001) + cnt)
    outa[e] := 1                                                ' request low nibble
    waitcnt((5 * US_001) + cnt)
    addr |= ina[db7..db4]                                       ' low nib of address
    outa[e] := 0
  while (addr & %1000_0000)                                     ' check busy flag

  return (addr & $7F)  


pub setchar(c, pntr) | okay

'' Write character map data to CGRAM
'' -- c is the custom character # (0..7)
'' -- pntr is the address of the bytes that define the cahracter

  if (c < 8)                                                    ' legal char # (0..7)?
    cmd(CGRAM + (c << 3))                                       ' move cursor
    repeat 8                                                    ' output character data
      out(byte[pntr++])
    okay := true
  else
    okay := false

  return okay


pub blon

'' Turn backlight control pin on
'' -- forces bl pin to output state

  outa[bl] := 1
  dira[bl] := 1


pub bloff

'' Turn backlight control pin off
'' -- returns bl pin to input state to allow monitoring of external control
''    (e.g., jm_oneshot)

  outa[bl] := 0
  dira[bl] := 0


pub setbl(state)

'' Set backlight control pin to state

  if state
    blon
  else
    bloff


pub display(ison)

  if ison
    dispCtrl := dispCtrl | %0000_0100                           ' display bit on
  else
    dispCtrl := dispCtrl & !%0000_0100                          ' display bit off

  cmd(dispCtrl)
  

pub cursor(mode) | okay, cbits

'' Sets LCD cursor style: off (0), underline (1), blinking bkg (2), uline+bkg (3)

  if (mode => CRSR_NONE) and (mode =< CRSR_UBLNK)
    cbits := lookupz(mode : %0000_1000, %0000_1010, %0000_1001, %0000_1011)
    dispCtrl := dispCtrl & %0000_1100 | cbits
    cmd(dispCtrl)
    okay := true

  else
    okay := false  

  return okay 


pub moveto(col, line) | okay, pos

'' Moves DDRAM cursor to column, row position
'' -- home position is indexed as 1, 1

  okay := false

  if (line => 1) & (line =< lcdy)                               ' valid line?
    if (col => 1) & (col =< lcdx)                               ' valid column?
      pos := lookup(line : LINE1, LINE2, LINE3, LINE4)          ' convert line to DDRAM pos
      pos := pos + col - 1                                      ' add column
      cmd(pos)                                                  ' move  
      okay := true

  return okay


pub scrollstr(col, line, width, ms, pntr) | okay, p, len

'' Scrolls string at pntr in window (width characters wide) at col/line
'' -- scroll direction is right-to-left 
'' -- delay between character scrolls in milliseconds
'' -- scroll direction is right to left
'' -- strings should be padded with spaces for clean entry/exit

  okay := false

  if (col => 1) & (col =< (lcdx + 1 - width))                   ' will scroll window fit?
    if (line => 1) & (line =< lcdy)                             ' on a valid line?
      len := strsize(pntr)                                      ' get length of string 
      if (len => width)                                         ' scrollable? 
        repeat (len - width + 1)
          p := pntr                                             ' start of new window
          moveto(col, line)                                     ' move to col 1 of window
          repeat width                                          ' print it
            out(byte[p++])
          waitcnt((ms * MS_001) + cnt) 
          pntr++                                                ' scroll string
       okay := true              
         
  return okay


pub rscrollstr(col, line, width, ms, pntr) | okay, p, len

'' Scrolls string at pntr in window (width characters wide) at col/line
'' -- scroll direction is right-to-left 
'' -- delay between character scrolls in milliseconds
'' -- scroll direction is right to left
'' -- strings should be padded with spaces for clean entry/exit

  okay := false

  if (col => 1) & (col =< (lcdx + 1 - width))                   ' will scroll window fit?
    if (line => 1) & (line =< lcdy)                             ' on a valid line?
      len := strsize(pntr)                                      ' get length of string 
      if (len => width)                                         ' scrollable? 
        pntr += width                                           ' move to right side of string
        repeat (len - width + 1)
          p := pntr                                             ' start of new window
          moveto(col, line)                                     ' move to col 1 of window
          repeat width                                          ' print it
            out(byte[p++])
          waitcnt((ms * MS_001) + cnt) 
          pntr--                                                ' scroll string (reverse)
       okay := true              
         
  return okay  


pri lcdinit

' Initializes LCD using 4-bit interface

  waitcnt((20 * MS_001) + cnt)                                  ' let LCD power up
  outa[db7..bl] := %0011_0000                                   ' 8-bit mode
  blipe
  waitcnt((5 * MS_001) + cnt)
  blipe
  waitcnt((150 * US_001) + cnt)
  blipe
  outa[db7..bl] := %0010_0000                                   ' 4-bit mode
  blipe
  if (lcdy > 1)
    cmd(%0010_1000)                                             ' multi-line
  cmd(%0000_0110)                                               ' auto-increment cursor
  dispCtrl := %0000_1100                                        ' display on, no cursor
  cmd(dispCtrl)
  cmd(CLS)


pri blipe

' "Blips" LCD.E pin to transfed data from buss to LCD

  outa[e] := 1
  waitcnt((5 * US_001) + cnt) 
  outa[e] := 0
  

pri wrlcd(b)

' Writes byte b to LCD buss using 4-bit interface

  dira[db7..db4] := %1111                                       ' set buss to outputs
  outa[rw] := 0                                                 ' write mode
  
  outa[db7..db4] := (b & $F0) >> 4                              ' output high nibble                             
  blipe
  outa[db7..db4] := b & $0F                                     ' output low nibble
  blipe


dat

{{

  Copyright (c) 2009 Jon McPhalen (aka Jon Williams)  

  Permission is hereby granted, free of charge, to any person obtaining a copy of this
  software and associated documentation files (the "Software"), to deal in the Software
  without restriction, including without limitation the rights to use, copy, modify,
  merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
  permit persons to whom the Software is furnished to do so, subject to the following
  conditions:

  The above copyright notice and this permission notice shall be included in all copies
  or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
  INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
  PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
  CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
  OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. 

}}                   