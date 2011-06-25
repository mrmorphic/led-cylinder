VAR
  long Stack[50]
  long params
  byte cog

PUB Start(currentLedRowPtr) : success
  Stop

  current_row_addr := currentLedRowPtr
  success := (cog := cognew(@run, 0))

PUB Stop
  if cog
    cogstop(cog~ - 1)

DAT
                        org     0
run
                        ' par contains the address to an array of 10 pointers into
                        ' main memory. The first is the frame buffer.
                      '  rdlong  current_row_addr, par  ' points to the address of the array

                        ' set up the pins
                        mov     dira, all_outs_mask
                        or      outa, #0                ' clear all the output pins

refresh_layer
                        ' pulse blank to start PWM cycle
                        or      outa, blank_pin_mask
                        andn    outa, blank_pin_mask

                        mov     pwm_count, pwm_cycles_required
pwm_cycle
                        ' pulse gsclk
                        or      outa, gsclk_pin_mask    ' GSCLK => 1
                        andn    outa, gsclk_pin_mask    ' GSCLK => 0

                        djnz    pwm_count, #pwm_cycle

                        ' next row
                        rdlong  selected_row, current_row_addr
                        add     selected_row, #1
                        and     selected_row, #3        ' Number of rows per bank is 4, masks selected_row to 0-3
                        wrlong  selected_row, current_row_addr

                        ' set the row selector pins
                        andn    outa, row_select_mask
                        mov     row_sel, selected_row
                        shl     row_sel, #10
                        or      outa, row_sel

                        ' pulse xlat to latch 192 bits into pwm registers. The data
                        ' will have been loaded in the last iteration
                        or      outa, xlat_pin_mask
                        andn    outa, xlat_pin_mask

                        ' an extra sclk pulse is required, apparently
                   '     or      outa, sclk_pin_mask     ' clock to 1
                    '    andn    outa, sclk_pin_mask     ' clock to 0

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

' temp, for calculating the value to output to the row selector pins
row_sel                 long    $C00

' holds the address in main memory where the shared selected_row value is kept.
current_row_addr        long    0

' Pins and masks for pins. Constant. Should probably be calculated on
' init.
blank_pin_mask          long    1 << 0
gsclk_pin_mask          long    1 << 1
xlat_pin_mask           long    1 << 2
sclk_pin_mask           long    1 << 3
sin_red_pin_mask        long    1 << 4
sin_green_pin_mask      long    1 << 5
sin_blue_pin_mask       long    1 << 6
sin_rgb_mask            long    $70            ' sin_*_pin_masks OR'd together
row_select_mask         long    $C00
row1_select             long    1 << 11
all_outs_mask           long    $FFF
red_mask                long    $800000
green_mask              long    $8000
blue_mask               long    $80

