' This is an object that can be included by another spin module,
' including for use by another cog.
'
' Double buffering:
'
' Images:
' - image functions typically take an image pointer, with the first two words
'   being the width and height, followed by rows of longs for the specified size.
con
  ' Bit masks for the frame buffer control word.
  FRAME_CTL_DRAW_BUFFER         = 1                     ' drawing buffer if double buffering is enabled. 0 means
                                                        ' drawing is to first 128 longs of frame buffer. 1 means drawing
                                                        ' to second 128 longs. When double buffering, cylinder displays the
                                                        ' part of the buffer that is not being drawn to.
  FRAME_CTL_DOUBLE_BUFFER       = 2                     ' 0 = double buffering disabled. 1 = double buffering enabled.

  ' Commands understood by the assembly component of the frame manipulation object
  CMD_NONE                      = 0                     ' no command executing
  CMD_PIXEL_ALPHA_CART          = 1                     ' alpha blended pixel by cartesian coords
  CMD_COLOUR_IN_PAL_1           = 2

  PALETTE_HOTCOLD               = 1                     ' palette ranging from cold (0) to hot (1023)

var
  long cog

' initialise
pub Init(globalBuffersPtr)
  frameBufPtr := long[globalBuffersPtr]
  frameControlPtr := long[globalBuffersPtr][1]
  randomPtr := long[globalBuffersPtr][2]

pub Start
  Stop
  frameParamCmd := CMD_NONE
'  frameParams[5] := frameBufPtr
'  frameParams[6] := frameControlPtr

  ' only start the frame buffer cog once, even if there are multiple instances of the frame manipulation
  ' object
  if cog == 0
    cog := cognew(@frameDriver, @frameParamCmd) + 1

pub Stop
  if cog <> 0
    cogstop(cog - 1)
  cog := 0

' Executes a command synchronously in the frame cog.
pri exec(command, p1, p2, p3, p4)
  ' wait until current has finished
  repeat until frameParamCmd == CMD_NONE

  frameParamP1 := p1
  frameParamP2 := p2
  frameParamP3 := p3
  frameParamP4 := p4
  frameParamCmd := command

  repeat until frameParamCmd == CMD_NONE
  return frameParamP1

pub EnableDoubleBuffering
  long[frameControlPtr] |= FRAME_CTL_DOUBLE_BUFFER
  long[frameControlPtr] &= !FRAME_CTL_DRAW_BUFFER

pub DisableDoubleBuffering
  long[frameControlPtr] &= !FRAME_CTL_DOUBLE_BUFFER

pub GetDrawingBuffer : buf | fc
  buf := frameBufPtr
  fc := long[frameControlPtr]
  if (fc & FRAME_CTL_DOUBLE_BUFFER) and (fc & FRAME_CTL_DRAW_BUFFER)
    buf += 512

pub GetDisplayBuffer : buf | fc
  buf := frameBufPtr
  fc := long[frameControlPtr]
  if (fc & FRAME_CTL_DOUBLE_BUFFER) and (fc & FRAME_CTL_DRAW_BUFFER == 0)
    buf += 512

' Set the frame buffer to all one colour
pub ShowAll(colour) | i,buf
  buf := GetDrawingBuffer
  repeat i from 0 to 127
    long[buf][i] := colour

pub Pixel(x,y,c) | buf
  if x < 0 or x > 15 or y < 0 or y > 7
    return  ' clip out of bounds pixels
  buf := GetDrawingBuffer
  long[buf][y * 16 + x] := c

pub PixelAbs(rel,c) | buf
  rel &= 127
  buf := GetDrawingBuffer
  long[buf][rel] := c

' draw the pixel to the frame buffer, with the high byte of the pixel being the alpha value (0-255)
pub PixelAlpha(x,y,c) | buf, alpha, merged,r,g,b
  if x < 0 or x > 15 or y < 0 or y > 7
    return  ' clip out of bounds pixels
  buf := GetDrawingBuffer
  merged := long[buf][y * 16 + x]
  alpha := (c & $ff000000) >> 24
  r := AlphaBlend((merged & $ff0000) >> 16, (c & $ff0000) >> 16, alpha)
  g := AlphaBlend((merged & $ff00) >> 8, (c & $ff00) >> 8, alpha)
  b := AlphaBlend(merged & $ff, c & $ff, alpha)

  long[buf][y * 16 + x] := (r << 16) | (g << 8) | b

  ' draw the pixel to the frame buffer, with the high byte of the pixel being the alpha value (0-255).
  ' wrapped variant
' @refactor to use AlphaBlendPixel
pub PixelAlphaW(x,y,c) | buf, alpha, merged,r,g,b
  if y < 0 or y > 7
    return  ' clip out of bounds pixels
  x := x & $0f
  buf := GetDrawingBuffer
  merged := long[buf][y * 16 + x]
  alpha := (c & $ff000000) >> 24
  r := AlphaBlend((merged & $ff0000) >> 16, (c & $ff0000) >> 16, alpha)
  g := AlphaBlend((merged & $ff00) >> 8, (c & $ff00) >> 8, alpha)
  b := AlphaBlend(merged & $ff, c & $ff, alpha)

  long[buf][y * 16 + x] := (r << 16) | (g << 8) | b

pub AlphaBlendPixel(opaque, colour) : blended | alpha, r, g, b
  alpha := (colour & $ff000000) >> 24
  r := AlphaBlend((opaque & $ff0000) >> 16, (colour & $ff0000) >> 16, alpha)
  g := AlphaBlend((opaque & $ff00) >> 8, (colour & $ff00) >> 8, alpha)
  b := AlphaBlend(opaque & $ff, colour & $ff, alpha)

  blended := (r << 16) | (g << 8) | b

' Draw an image from imagePtr at the position starting at x and y, with wrapping
' and using alpha values from the image.
pub ImageAlpha(imagePtr, x, y) | x1, y1, w, h, p
  w := word[imagePtr][0]
  h := word[imagePtr][1]
  p := imagePtr + 4
  repeat y1 from 0 to h-1
    repeat x1 from 0 to w-1
      PixelAlpha(x+x1,y+y1,long[p])
      p += 4

pub Row(y,c) | i, j, buf
  if y < 0 or y > 7
    return
  buf := GetDrawingBuffer
  i := y * 16
  repeat j from i to i + 15
    long[buf][j] := c

pub Col(x,c) | offset, j, buf
  if x < 0 or x > 15
    return
  buf := GetDrawingBuffer
  offset := x
  repeat j from 0 to 7
    long[buf][offset] := c
    offset := offset + 16

pub CopyImage(destImagePtr, srcImagePtr) | count, w, h
  w := word[srcImagePtr][0]
  h := word[srcImagePtr][1]
  count := (w * h) + 1
  longmove(destImagePtr, srcImagePtr, count)

' Substitute any occurence of fromColour with toColour in the given image.
' Leaves the alpha values in the image alone (doesn't use an alpha value from toColour)
pub ImageTransateColourAlpha(imagePtr, fromColour, toColour) | w, h, x, y, p
  w := word[imagePtr][0]
  h := word[imagePtr][1]
  p := imagePtr + 4
  repeat x from 0 to h-1
    repeat y from 0 to w-1
      if (long[p] & $ffffff) == fromColour
        long[p] := (long[p] & $ff000000) | (toColour & $ffffff)
      p += 4

' Alpha blend v0 (opaque) and v1 with alpha. All are assumed to be 8 bit values. Returns
' a new 8-bit value
pub AlphaBlend(v0, v1, alpha) : c | c1, c2
'  c1 := ((255 - alpha) * v0) / 256   ' fractional multiplication of 8 bit * 8 bit is 16 bit.
'  c2 := (alpha * v1) / 256
  c1 := ((255 - alpha) * v0) >> 8   ' fractional multiplication of 8 bit * 8 bit is 16 bit.
  c2 := (alpha * v1) >> 8
  c := c1 + c2

pub RGBToColour(r,g,b) : colour
  colour := (r & $ff) << 16
  colour |= (g & $ff) << 8
  colour |= b & $ff

' Explicitly the drawing buffer
pub SetDrawingBuffer(buffer)
  long[frameControlPtr] := (long[frameControlPtr] & $ffffff00) | (buffer & $ff)

' Swap the drawing and display buffers.
pub SwapBuffers
  long[frameControlPtr] := long[frameControlPtr] ^ 1 ' toggle the least significant bit

' return an RGB colour from the current palette.
' value is a long between 0 and 1023, and represents a linear index into the palette.
' This makes it easy to linearly move through a palette.
' Returns 0 if the palette is not defined
pub ColourInPalette(value) : colour
  return paletteBuffer[value]

' Set up the palette buffer to a specific palette. Palette constants are defined at the top.
pub SetPalette(palette) | value, c
  case palette
    PALETTE_HOTCOLD:
'      return exec(CMD_COLOUR_IN_PAL_1, value, 0, 0, 0)
      repeat value from 0 to 1023
        if value < 256
          ' all blue, increasing green, no red
          c := RGBToColour(0, value, 255)
        elseif value < 512
          ' all green, decreasing blue, no red
          c := RGBToColour(0, 255, 512 - value)
        elseif value < 768
          ' all green, increasing red, no blue
          c := RGBToColour(value - 512, 255, 0)
        ' all red, decreasing green, no blue
        else
          c := RGBToColour(255, 1024 - value, 0)
        paletteBuffer[value] := c
  return 0

' Copy whatever is in the current display buffer into the drawing buffer.
pub CopyDispToDrawingBuffer | dispBuf, drawBuf
  dispBuf := GetDisplayBuffer
  drawBuf := GetDrawingBuffer
  longmove(drawBuf, dispBuf, 128)

dat

  ' An array of parameters passed to assembly. Indexes are as follows:
  ' 0 - command
  ' 1 - param 1
  ' 2 - param 2
  ' 3 - param 3
  ' 4 - param 4
  ' 5 - address of start of frame buffer
  ' 6 - address of frame control word
frameParamCmd           long    0
frameParamP1            long    0
frameParamP2            long    0
frameParamP3            long    0
frameParamP4            long    0
frameBufPtr             long    0
frameControlPtr         long    0
randomPtr               long    0

paletteBuffer           long    0[1024]

                        org     0
                        fit     496
frameDriver
                        ' grab values from parameter array
                        mov     cmd_addr, par
                        add     p1_addr, par
                        add     p2_addr, par
                        add     p3_addr, par
                        add     p4_addr, par    ' think about removal
                        add     frame_buf_addr, par
                        add     frame_control_addr, par
                        ' The last two are addresses of addresses in main memory, so lets dereference these
                        rdlong  frame_buf_addr, frame_buf_addr
                        rdlong  frame_control_addr, frame_control_addr

wait_cmd
                        rdlong  cmd, cmd_addr   WZ
              if_z      jmp     #wait_cmd

                        ' get params p1-p3, leave p4 for now as nothing uses it yet, so can be fetched on demand
                        rdlong  p1_val, p1_addr
                        rdlong  p2_val, p2_addr
                        rdlong  p3_val, p3_addr

cmd_dispatch
                        jmp     #do_colour_in_pal_1
'                        jmp     #do_pixel_alpha_cart

' all commands should jump back here after execution. Here we zero out the command
' buffer, and go back and wait for another.
done
                        wrlong  null_command, cmd_addr
                        jmp     #wait_cmd

' Compute a colour in the hot/cold palette
do_colour_in_pal_1
                        call    #sync_buffer_pointers

                        mov     r1,c512                 ' r1 is 512-p1_val
                        sub     r1,p1_val
                        mov     r2,c1024                ' r2 is 1024-p1_val
                        sub     r2,p2_val
                        mov     r3,p1_val
                        sub     r3,c512

                        cmp     p1_val, #256    WC
              if_c      shl     p1_val, #8
              if_c      or      p1_val, #255
              if_c      jmp     #do_col_pal_1_done
                        cmp     p1_val, c512    WC
              if_c      mov     p1_val, #255
              if_c      shl     p1_val, #8
              if_c      or      p1_val, r1
              if_c      jmp     #do_col_pal_1_done
                        cmp     p1_val, c768    WC
              if_c      shl     r3,#16
              if_c      mov     p1_val, #255
              if_c      shl     p1_val, #8
              if_c      or      p1_val,r3
              if_c      jmp     #do_col_pal_1_done
                        mov     p1_val, #255
                        shl     p1_val, #16
                        shl     r2,#8
                        or      p1_val, r2
do_col_pal_1_done
                        wrlong  p1_val, p1_addr
                        jmp     #done

' Draw pixel at (x:p1, y:p2) with colour p3, which may have an alpha value.
' Pixel is clipped
do_pixel_alpha_cart
                        '  if x < 0 or x > 15 or y < 0 or y > 7
                        '    return  ' clip out of bounds pixels

                        '  buf := GetDrawingBuffer
                        call    #sync_buffer_pointers

                        '  merged := long[buf][y * 16 + x]
                        mov     ptr, p2_val     ' y
                        shl     ptr, #4         ' y * 16
                        add     ptr, p1_val     ' y * 16 + x
                        shl     ptr, #2         ' address of longs rather than bytes
                        add     ptr, drawing_buffer_addr   ' plus base address of drawing buffer
                        rdlong  r1, ptr         ' get pixel

                        '  alpha := (c & $ff000000) >> 24
                        mov     ab_alpha, r1
                        shr     ab_alpha, #24   ' get at alpha value, top 8 bits

                        ' blend red components
                        '  r := AlphaBlend((merged & $ff0000) >> 16, (c & $ff0000) >> 16, alpha)
                        mov     ab_blend0, r1   ' get red component of pixel
                        shr     ab_blend0, #16  ' get to red
                        and     ab_blend0, $ff  ' just red
                        mov     ab_blend1, p3_val   ' get red component of colour being blended
                        shr     ab_blend1, #16
                        and     ab_blend1, $ff
                        call    #alpha_blend
                        mov     r3, ab_blend0   ' put in merged red result
                        shl     r3, #16         ' red component in r3, the resulting pixel

                        ' blend green components
                        ' g := AlphaBlend((merged & $ff00) >> 8, (c & $ff00) >> 8, alpha)
                        mov     ab_blend0, r1
                        shr     ab_blend0, #8
                        and     ab_blend0, $ff
                        mov     ab_blend1, p3_val
                        shr     ab_blend1, #8
                        and     ab_blend1, $ff
                        call    #alpha_blend
                        shl     ab_blend0, #8
                        or      r3, ab_blend0       ' or green component back into result

                        ' blend blue components
                        ' b := AlphaBlend(merged & $ff, c & $ff, alpha)
                        mov     ab_blend0, r1
                        and     ab_blend0, $ff
                        mov     ab_blend1, p3_val
                        and     ab_blend1, $ff
                        call    #alpha_blend
                        or      r3, ab_blend0

                        '  long[buf][y * 16 + x] := (r << 16) | (g << 8) | b
                        wrlong  r3, ptr

                        jmp     #done

' Alpha blend 'ab_blend0' (which is opaque) and 'ab_blend1' with ab_blend1 having alpha value 'ab_alpha'.
' All are assumed to be 8 bit values. Returns a new 8-bit value in ab_blend0
alpha_blend
' c1 := ((255 - alpha) * v0) >> 8   ' fractional multiplication of 8 bit * 8 bit is 16 bit.
                        mov     mx, #$ff
                        sub     mx, ab_alpha
                        mov     my, ab_blend0
                        call    #multiply
                        shr     my, #8
                        mov     ab_blend0, my

'  c2 := (alpha * v1) >> 8
                        mov     mx, ab_alpha
                        mov     my, ab_blend1
                        call    #multiply
                        shr     my, #8

'  c := c1 + c2
                        add     ab_blend0, my
                        and     ab_blend0, #$ff
alpha_blend_ret
                        ret

' multiple 16-bit X (mx) with 16-bit Y (top 16 bits = 0) (my) to produce 32-bit Y, unsigned
' (from propeller guts doc)
multiply                shl     mx,#16          'get multiplicand into mx[31..16]
                        mov     mt,#16          'ready for 16 multiplier bits
                        shr     my,#1    wc     'get initial multiplier bit into c
:loop
              if_c      add     my,mx     wc    'if c set, add multiplicand into product
                        rcr     my,#1    wc     'get next multiplier bit into c, shift product
                        djnz    mt,#:loop       'loop until done
multiply_ret            ret                     'return with product in my[31..0]


' Works out the current buffers based on the frame control word. Sets
' drawing_buffer_addr to the start of the current drawing buffer. Honours
' single or double buffering.
sync_buffer_pointers
                        mov     drawing_buffer_addr, frame_buf_addr
                        rdlong  frame_control_word, frame_control_addr
                        ' if double buffering is set, and drawing buffer is zero,
                        test    frame_control_word, $2                          ' test double buffer
              if_z      jmp     #sync_buffer_pointers_ret
                        test    frame_control_word, $1                          ' test display buffer
              if_z      add     drawing_buffer_addr, frame_buf_size

sync_buffer_pointers_ret
                        ret

cmd                     long    0               ' Command we read

' We read the current frame control word into here from frame_control_addr, when we need it.
frame_control_word      long    0

drawing_buffer_addr     long    0

' These capture the addresses of the frameParams values. Note that these must
' be defined contigiously, and must increment by 4 for the init to work.
cmd_addr                long    0
p1_addr                 long    4
p2_addr                 long    8
p3_addr                 long    12
p4_addr                 long    16
frame_buf_addr          long    20
frame_control_addr      long    24

p1_val                  long    0
p2_val                  long    0
p3_val                  long    0
p4_val                  long    0

' general purpose variables
ptr                     long    0
r1                      long    0
r2                      long    0
r3                      long    0
r4                      long    0

' used by alpha_blend
ab_alpha                long    0               ' used by alpha blending
ab_blend0               long    0               ' used by alpha blending
ab_blend1               long    0               ' used by alpha blending

' used by multiply
mx                      long    0
my                      long    0
mt                      long    0

' constant, number of bytes in one 128-long buffer
frame_buf_size          long    512

null_command            long    0
c512                    long    512
c768                    long    768
c1024                   long    1024

