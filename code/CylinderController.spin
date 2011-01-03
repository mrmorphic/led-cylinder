{
  CyclinderController is responsible for driving the LED cylinder. It takes input from a
  shared frame buffer, and continually serialises this to the TLC5940 chips that drive
  the LED columns. This process runs in it's own cog.

  There are 3 TLC5940's, one for red, green and blue columns, as each colour requires
  different limiting current.
}

VAR
  long Stack[50]
  long params[10]
  byte cog
  long buf

PUB Start(frameBuffer) : success
  Stop
  buf := frameBuffer
  success := (cog := cognew(@run, buf))

PUB Stop
  if cog
    cogstop(cog~ - 1)

DAT
{
        refresh_layer is continuously entered. On each iteration, it selects an output
        layer on the cylinder, and proceeds to perform the PWM cycle by strobing
        gsclk on the TLC5940's at a fixed rate. This is done in the loop starting
        at pwm_cycle. In the same loop, we also load the next layer's data into the
        chips, clocking in the 192-bits of data per chip. The PWM cycle is 4096
        iterations of pwm_clock. The data load is only done in the first 192 cycles.
        In subsequent cycles, the data load is simulated, so the entire cycle
        is of a fixed length, necessary for ensuring consistent brightness on
        the PWM cycles.
}

                        org     0
run
                        ' par contains the address to an array of 10 pointers into
                        ' main memory. The first is the frame buffer.
                        mov     frame_buffer_addr, par  ' points to the address of the array

                        ' set up the pins
                        mov     dira, all_outs_mask
                        or      outa, #0                ' clear all the output pins

                        ' output 192 0 to initiate clocking
                        mov     data_bits_to_send, data_bits_per_row
:loop
                        or      outa, sclk_pin_mask     ' clock to 1
                        andn    outa, sclk_pin_mask     ' clock to 0
                        djnz    data_bits_to_send, #:loop

refresh_layer
                        ' pulse xlat to latch 192 bits into pwm registers. The data
                        ' will have been loaded in the last iteration
                        or      outa, xlat_pin_mask
                        andn    outa, xlat_pin_mask

                        ' an extra sclk pulse is required, apparently
                   '     or      outa, sclk_pin_mask     ' clock to 1
                    '    andn    outa, sclk_pin_mask     ' clock to 0

                        ' @todo Select output row

                        ' pulse blank to start PWM cycle
                        or      outa, blank_pin_mask
                        andn    outa, blank_pin_mask

                        ' calculate pointer to frame buffer for next row. This is
                        ' frame_buffer_addr + (selected_row + 1) * 16
                        mov     frame_buffer_ptr, selected_row
                        add     frame_buffer_ptr, #1
                        and     frame_buffer_ptr, #7    ' wrap 8 -> 0
                        shl     frame_buffer_ptr, #4    ' x 16
                        add     frame_buffer_ptr, frame_buffer_addr

                        ' read next row data, this is much faster to read in the inner loop
                        rdlong  buf00, frame_buffer_ptr
                        add     frame_buffer_ptr, #1
                        rdlong  buf01, frame_buffer_ptr
                        add     frame_buffer_ptr, #1
                        rdlong  buf02, frame_buffer_ptr
                        add     frame_buffer_ptr, #1
                        rdlong  buf03, frame_buffer_ptr
                        add     frame_buffer_ptr, #1
                        rdlong  buf04, frame_buffer_ptr
                        add     frame_buffer_ptr, #1
                        rdlong  buf05, frame_buffer_ptr
                        add     frame_buffer_ptr, #1
                        rdlong  buf06, frame_buffer_ptr
                        add     frame_buffer_ptr, #1
                        rdlong  buf07, frame_buffer_ptr
                        add     frame_buffer_ptr, #1
                        rdlong  buf08, frame_buffer_ptr
                        add     frame_buffer_ptr, #1
                        rdlong  buf09, frame_buffer_ptr
                        add     frame_buffer_ptr, #1
                        rdlong  buf10, frame_buffer_ptr
                        add     frame_buffer_ptr, #1
                        rdlong  buf11, frame_buffer_ptr
                        add     frame_buffer_ptr, #1
                        rdlong  buf12, frame_buffer_ptr
                        add     frame_buffer_ptr, #1
                        rdlong  buf13, frame_buffer_ptr
                        add     frame_buffer_ptr, #1
                        rdlong  buf14, frame_buffer_ptr
                        add     frame_buffer_ptr, #1
                        rdlong  buf15, frame_buffer_ptr
                        add     frame_buffer_ptr, #1
                        mov     buf00, test_pixel_data
                        mov     buf01, test_pixel_data
                        mov     buf02, test_pixel_data
                        mov     buf03, test_pixel_data
                        mov     buf04, test_pixel_data
                        mov     buf05, test_pixel_data
                        mov     buf06, test_pixel_data
                        mov     buf07, test_pixel_data
                        mov     buf08, test_pixel_data
                        mov     buf09, test_pixel_data
                        mov     buf10, test_pixel_data
                        mov     buf11, test_pixel_data
                        mov     buf12, test_pixel_data
                        mov     buf13, test_pixel_data
                        mov     buf14, test_pixel_data
                        mov     buf15, test_pixel_data
                        mov     frame_buffer_ptr, #buf00      ' now it points to cog RAM

                        mov     pwm_count, pwm_cycles_required
                        mov     pixel_bit_count, #0
                        mov     data_bits_to_send, data_bits_per_row
pwm_cycle
                        ' pulse gsclk
                        or      outa, gsclk_pin_mask    ' GSCLK => 1
                        andn    outa, gsclk_pin_mask    ' GSCLK => 0

                        ' load a pixel if required
                        cmp     pixel_bit_count, #0     WZ
              if_z      mov     pixel_bit_count, #12
              if_z      mov     pixel_data, frame_buffer_ptr
              if_z      add     frame_buffer_ptr, #1

' @todo if_z load pixel data from memory and advance buffer pointer.
' @todo if_nz, slight delay to simulate memory load

                        ' shift out bits of the pixel
                        test    pixel_data, red_mask    WZ
                        muxnz   outa, sin_red_pin_mask
 '                       or      outa, sin_red_pin_mask ' force high

                        ' green
                        test    pixel_data, green_mask  WZ
                        muxnz   outa, sin_green_pin_mask
                       ' or      outa, sin_green_pin_mask

                        ' blue
                        test    pixel_data, blue_mask   WZ
                        muxnz   outa, sin_blue_pin_mask
                       ' or      outa, sin_blue_pin_mask

                        shl     pixel_data, #1
                        sub     pixel_bit_count, #1

                        ' data clock, but only if there are bits to send
                        cmp     data_bits_to_send, #0   WZ
              if_nz     or      outa, sclk_pin_mask     ' clock to 1
              if_nz     andn    outa, sclk_pin_mask     ' clock to 0
                        sub     data_bits_to_send, #1

                        djnz    pwm_count, #pwm_cycle

                        ' next row
                        add     selected_row, #1
                        and     selected_row, #7        ' Number of rows is 8, masks selected_row to 0-7

                        jmp     #refresh_layer

' Total number of clocks of GSCLK in a pwm cycle. Constant.
pwm_cycles_required     long    4096

' Where we're up to
pwm_count               long    0

' The selected row that we are displaying. During refresh of a layer,
' the data for the next layer (selected_row+1) & $7 is loaded.
' We start with layer 1, since the first time around whatever is in
' the TLC5940 register is considered layer 0, displayed only
' momentarily.
selected_row            long    1

' The current pixel value that is being shifted out for the next row.
pixel_data              long    0

test_pixel_data         long    $ffffff

' Number of bits to shift out per row. Constant.
data_bits_per_row       long    192

' Initialised at the start of sending data to 192, once this reaches
' zero we no longer clock data out in the pwm loop.
data_bits_to_send       long    0

' The current pixel bit being shifted. This starts at 12 and decreases
' for each pixel. When 12 thru 4, a bit of pixel colour is shifted out.
' When 3 thru 0, a zero is shifted out, because we only use 8 bits per
' colour per pixel, whereas the TLC5940 uses 12 bits.
pixel_bit_count         long    0

' The address in main memory of the start of the frame buffer. Constant within
' cog execution.
frame_buffer_addr       long    0

' Variable pointer that points to the current pixel
frame_buffer_ptr        long    0

' Pins and masks for pins. Constant. Should probably be calculated on
' init.
blank_pin_mask          long    1 << 4
gsclk_pin_mask          long    1 << 5
xlat_pin_mask           long    1 << 6
sclk_pin_mask           long    1 << 7
sin_red_pin_mask        long    1 << 8
sin_green_pin_mask      long    1 << 9
sin_blue_pin_mask       long    1 << 10
sin_rgb_mask            long    $700            ' sin_*_pin_masks OR'd together
all_outs_mask           long    $7FF
'gsclks_required         long    4096            ' number of pulse of GSCLK per PWM-cycle
red_mask                long    $800000
green_mask              long    $8000
blue_mask               long    $80

buf00                    long    $ffffff
buf01                    long    $ffffff
buf02                    long    $ffffff
buf03                    long    $ffffff
buf04                    long    $ffffff
buf05                    long    $ffffff
buf06                    long    $ffffff
buf07                    long    $ffffff
buf08                    long    $ffffff
buf09                    long    $ffffff
buf10                    long    $ffffff
buf11                    long    $ffffff
buf12                    long    $ffffff
buf13                    long    $ffffff
buf14                    long    $ffffff
buf15                    long    $ffffff

{                        mov     colour_count, #0
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
}
