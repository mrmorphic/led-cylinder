{
  CyclinderController is responsible for driving the LED cylinder. It takes input from a
  shared frame buffer, and continually serialises this to the TLC5940 chips that drive
  the LED columns. This process runs in it's own cog.

  There are 3 TLC5940's, one for red, green and blue columns, as each colour requires
  different limiting current.
}

CON
  BLANK_PIN = 1 << 4   { blank all outputs if high }
  GSCLK_PIN = 1 << 5   { clock for PWM }
  XLAT_PIN = 1 << 6    { copy shifted data to output latches }
  SCLK_PIN = 1 << 7    { rising edge clocks data in on SIN_PIN }
  SIN_PIN = 1 << 8     { data clocked in, MSB first }
  OUTPUTPINS = BLANK_PIN | GSCLK_PIN
VAR
  long Stack[50]
  long params[10]
  byte cog

PUB Start(frameBuffer) : success
  Stop
  success := (cog := cognew(@run, 0))

PUB Stop
  if cog
    cogstop(cog~ - 1)

DAT
                        org     0
run
                        ' set up the pins
                        mov     dira, all_outs_mask
                        or      outa, #0                ' clear all the output pins

                        mov     colour_count, #0
                        mov     colour_inc, #1

                        ' this is the start of the ongoing refresh process.
refresh_row
                        ' @todo select the row

                       ' xor     outa, #1
                        ' calculate address of MSB pixel of current line
                        mov     pixel_addr, #0  ' @todo calculate. buffer base + 64*line (bytes)

                        mov     col_count, #16  ' 16 pixels to process
pixel_loop
                        ' get colour
    '                    rdlong  pixel_data, pixel_addr
' <-- start of test
             '           mov     pixel_data, test_pixel ' test only
                        mov     pixel_data, colour_count
                        mov     t1, colour_count
                        shl     t1, #8
                        or      pixel_data, t1
                        shl     t1, #8
                        or      pixel_data, t1

                        djnz    colour_speed, #done_colour_adj
                        mov     colour_speed, #50
                        add     colour_count, colour_inc
                        cmps    colour_count, #0 wc
             if_c       mov     colour_count, #0
             if_c       mov     colour_inc, #1
                        cmps    max_colour, colour_count wc
             if_c       mov     colour_count, #255
             if_c       mov     colour_inc, negative_one
done_colour_adj
' end of test -->
                        add     pixel_addr, #4
                        mov     pixel_bit_count, #8
                        mov     pixel_data, test_pixel
:pixel_bit_loop
                        ' pixel_data has a 32-bit RGB value. Highest byte is unused.
                        ' We need to shift the R, G and B components (8 bits each) out
                        ' to the different TLC5940's. Each will be augmented by
                        ' 4 bits of zeroes, to make up the 12 bits that the TLC5940 takes.

                        ' hack to set pixel_data to zero if not row 1
                        cmp     selected_row, #0  WZ
              if_nz     mov     pixel_data, #0

                        ' red
                        test    pixel_data, red_mask   WZ
                        muxnz   outa, sin_red_pin_mask

                        ' green
                        test    pixel_data, green_mask   WZ
                        muxnz   outa, sin_green_pin_mask

                        ' blue
                        test    pixel_data, blue_mask   WZ
                        muxnz   outa, sin_blue_pin_mask

                        shl     pixel_data, #1

                        ' clock out 3 bits of data
                        or      outa, sclk_pin_mask     ' clock to 1
                        andn    outa, sclk_pin_mask     ' clock to 0

                        djnz    pixel_bit_count, #:pixel_bit_loop

                        mov     pixel_bit_count, #4     WZ
                        andn    outa, sin_rgb_mask      ' set them to zero.

                        'Z will be 0 at this point
                       ' or      pixel_bit_count, #1 WZ
:pixel_clear_loop
                        ' 4 bits of 0
                        or      outa, sclk_pin_mask     ' clock to 1
                        andn    outa, sclk_pin_mask     ' clock to 0
                        djnz    pixel_bit_count, #:pixel_clear_loop

                        ' once we reach this point, we have shifted out the whole pixel

                        ' so go and do another pixel
                        djnz    col_count, #pixel_loop

                        ' ok, when we get here we've shift out all 192 bits of colour data for the 16 pixels
                        ' across 3 TLC5940s.

                        ' pulse xlat to latch 192 bits into pwm registers
                        or      outa, xlat_pin_mask
                        andn    outa, xlat_pin_mask

                        ' an extra sclk pulse is required, apparently
                        or      outa, sclk_pin_mask     ' clock to 1
                        andn    outa, sclk_pin_mask     ' clock to 0

                        ' pulse blank to high and then back low again
                        or      outa, blank_pin_mask
                        andn    outa, blank_pin_mask

                        ' at this point, everything is set to start PWM clock

                        mov     gsclk_counter, gsclks_required         ' load 4096, Z will be cleared
:loop                   or      outa, gsclk_pin_mask    ' GSCLK => 1
                        andn    outa, gsclk_pin_mask    ' GSCLK => 0
                        djnz    gsclk_counter, #:loop

                        ' advance to the next row, and start again
                        add     selected_row, #1
                        cmp     selected_row, #4 wz
               if_z     mov     selected_row, #0

                        jmp     #refresh_row

' "constants" to make life easier
blank_pin_mask          long    1 << 4
gsclk_pin_mask          long    1 << 5
xlat_pin_mask           long    1 << 6
sclk_pin_mask           long    1 << 7
sin_red_pin_mask        long    1 << 8
sin_green_pin_mask      long    1 << 9
sin_blue_pin_mask       long    1 << 10
selected_row            long    0
row_count               long    8
sin_rgb_mask            long    $700            ' sin_*_pin_masks OR'd together
all_outs_mask           long    $7FF
gsclks_required         long    4096            ' number of pulse of GSCLK per PWM-cycle
red_mask                long    $800000
green_mask              long    $8000
blue_mask               long    $80

' test variables
test_pixel              long    $ffffff         ' white
colour_count            long    0
colour_inc              long    0
max_colour              long    255
negative_one            long    $ffffffff
colour_speed            long    100
' end-test

pixel_addr              res     1               ' stores current main ram pixel being rendered
pixel_data              res     1
col_count               res     1
pixel_bit_count         res     1
gsclk_counter           res     1

' for test
t1                      res     1
' end test

