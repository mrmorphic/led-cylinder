
VAR
  long Stack[50]
  long params[10]
  byte cog
  long buf

  ' contigous blocks for params
  long p0 ' frameBufPtr
  long p1 ' curLedRowPtr

PUB Start(currentLedRowPtr, frameBufferPtr) : success
  Stop
  frame_buffer_addr := frameBufferPtr
  current_row_addr := currentLedRowPtr
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

refresh_layer
                        rdlong  t, current_row_addr     ' get selected row

                        ' wait until the selected_row is changed. The PWM cog will change
                        ' this to the next row at the end of each PWM cycle.
                        cmp     t, selected_row   WZ
              if_z      jmp     #refresh_layer
                        mov     selected_row, t

                        ' calculate pointer to frame buffer for next row. This is
                        ' frame_buffer_addr + (selected_row + 1) * 16 * 4
                        mov     pixel_addr_top, selected_row
                        add     pixel_addr_top, #1          ' populate next row
                        and     pixel_addr_top, #3          ' wrap 4 -> 0
                        shl     pixel_addr_top, #6          ' x 16 (pixels per row) * 4 (bytes per pixel)
                        add     pixel_addr_top, frame_buffer_addr
                        mov     pixel_addr_bottom, pixel_addr_top
                        add     pixel_addr_top, bytes_per_bank

                        mov     col_count, #16  ' 16 pixels to process
pixel_loop
                        ' get colour
                        rdlong  pixel_data_top, pixel_addr_top
                        rdlong  pixel_data_bottom, pixel_addr_bottom
                        add     pixel_addr_top, #4
                        add     pixel_addr_bottom, #4

                        mov     pixel_bit_count, #8

:pixel_bit_loop
                        ' pixel_data has a 32-bit RGB value. Highest byte is unused.
                        ' We need to shift the R, G and B components (8 bits each) out
                        ' to the different TLC5940's. Each will be augmented by
                        ' 4 bits of zeroes, to make up the 12 bits that the TLC5940 takes.

                        ' red top
                        test    pixel_data_top, red_mask   WZ
                        muxnz   outa, sin_top_red_pin_mask

                        ' green top
                        test    pixel_data_top, green_mask   WZ
                        muxnz   outa, sin_top_green_pin_mask

                        ' blue top
                        test    pixel_data_top, blue_mask   WZ
                        muxnz   outa, sin_top_blue_pin_mask

                        shl     pixel_data_top, #1

                        ' red bottom
                        test    pixel_data_bottom, red_mask   WZ
                        muxnz   outa, sin_btm_red_pin_mask

                        ' green bottom
                        test    pixel_data_bottom, green_mask   WZ
                        muxnz   outa, sin_btm_green_pin_mask

                        ' blue bottom
                        test    pixel_data_bottom, blue_mask   WZ
                        muxnz   outa, sin_btm_blue_pin_mask

                        shl     pixel_data_bottom, #1

                        ' clock out 3 bits of data
                        or      outa, sclk_pin_mask     ' clock to 1
                        andn    outa, sclk_pin_mask     ' clock to 0

                        djnz    pixel_bit_count, #:pixel_bit_loop

                        mov     pixel_bit_count, #4     WZ
                        andn    outa, sin_top_rgb_mask      ' set them to zero.
                        andn    outa, sin_btm_rgb_mask

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


                        ' @todo Select output row
'stop_here
'                        jmp     #stop_here
                        jmp     #refresh_layer

' The selected row that we are displaying. During refresh of a layer,
' the data for the next layer (selected_row+1) & $7 is loaded.
' We start with layer 1, since the first time around whatever is in
' the TLC5940 register is considered layer 0, displayed only
' momentarily.
selected_row            long    8               ' invalid, forces us to start sending straight away

' The difference in address in the frame buffer between the top bank and the
' the bottom bank.
bytes_per_bank          long    256

' holds the address in main memory where the shared selected_row value is kept.
current_row_addr        long    0

' The current pixel value that is being shifted out for the next row.
pixel_data_top          long    0
pixel_data_bottom       long    0

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

' Variable pointer that points to the current pixel (address of long in main memory)
pixel_addr_top          long    0
pixel_addr_bottom       long    0

t                       long    0

' Pins and masks for pins. Constant. Should probably be calculated on
' init.
blank_pin_mask          long    1 << 0
gsclk_pin_mask          long    1 << 1
xlat_pin_mask           long    1 << 2
sclk_pin_mask           long    1 << 3
sin_top_red_pin_mask    long    1 << 4
sin_top_green_pin_mask  long    1 << 5
sin_top_blue_pin_mask   long    1 << 6
sin_btm_red_pin_mask    long    1 << 7
sin_btm_green_pin_mask  long    1 << 8
sin_btm_blue_pin_mask   long    1 << 9
sin_top_rgb_mask        long    $70            ' sin_*_pin_masks OR'd together
sin_btm_rgb_mask        long    $380
all_outs_mask           long    $3FF
'gsclks_required         long    4096            ' number of pulse of GSCLK per PWM-cycle
red_mask                long    $800000
green_mask              long    $8000
blue_mask               long    $80

col_count               res     1

