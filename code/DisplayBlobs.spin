{
  Blob animation.
  Logic:
  - the LED display is treated as a cell grid
  - each cell has a colour, specified by an index into a palette
  - animation starts from a state where most/all cells have the same colour
  - there are a small number of "active points" (e.g. 3)
  - the active points move slowly over time anywhere on the display
  - an active point can have a positive or negative offset
  - the colour of a cell at an active point has its index adjusted by the active
    point's offset
  - cells around an active point have their offsets adjusted proportionally according
    to their distance from the cell. A cell may be affected by more than one active
    point.

  Implementation:
  - implemented in assembly for speed
  - active points are in cog RAM
  - during calculation of distance between a cell and active point, fixed point integer
    math is used, with 4 bits of decimal place.
  - cell values are fixed binary, with 8 bits decimal part. This allows for more gradual
    increments in colour.
}

VAR
  long Stack[20]
  long buf

  ' contigous blocks for params

  byte cog

obj
  frame       : "FrameManipulation"

PUB Start(globalBuffersPtr) : success | ci
  Stop

  frame.SetPalette(frame#PALETTE_HOTCOLD)

  frame_buf_addr := long[globalBuffersPtr]
  frame_control_addr := long[globalBuffersPtr][1]
  random_addr := long[globalBuffersPtr][2]
  palette_addr := frame.GetPaletteBuffer

  cog := cognew(@blobDisplay, 0) + 1

PUB Stop
  if cog
    cogstop(cog~ - 1)	

DAT
                        org     0
			fit	496			

blobDisplay
			' set display in single-buffer mode
			wrlong	zero, frame_control_addr

			' initialise cells
			mov	r0, #128
			mov	r1, #cells
loop1			movd	:loop1_mov, r1
			nop
:loop1_mov		mov	r1, initial_colour
			add	r1, #1
			djnz	r0, #loop1

			mov	move_count, move_delay





{
  pseudo-code:

  for y = 0 to 7
    for x = 0 to 7
      cell = cellAt(x,y)
      for p in activePoints:
        pointOffset = activePointOffset(p)
        weight = calc weight by distance
        cell += weight * pointOffset
}

			' this is the start of the main loop. It begins with an in-memory
			' recalculation of the new colour indexes.
update_cells
			' calculate new values
			mov	ry, #7

row_loop
			mov	rx, #15

col_loop

			' ok, this is where the per-cell processing happens

			' work out offset for cells based on x and y
			mov	roffset, ry
			shl	roffset, #4
			add	roffset, rx
			add	roffset, #cells
			movs	:get_cell, roffset

			mov	rc, #3

			' get cell into rcell
:get_cell		mov	rcell, dummy

point_loop
			' get point
			mov	r0, rc			' point offset
			add	r0, #points		' address of point
			movs	:get_point, r0

			nop

:get_point		mov	r0, dummy			' gets point into r0

			' calculate point offset. if zero, ignore it
			mov	poffset, r0
			and	poffset, #$ff  WZ
		if_z	jmp	#no_point

			' calc point coords (px, py)
			mov	py, r0
			shr	py, #8
			and	py, #$ff
			mov	px, r0
			shr	px, #16
			and	px, #$ff

			' calculate the absolute difference between py and ry
			mov	ydiff, ry
			sub	ydiff, py
			abs	ydiff, ydiff

			' if y difference is >= 4, don't even bother, they are too far apart
			cmp	ydiff, #4	WC
		if_nc	jmp	#no_point

			' calculate the absolute difference between px and rx. This is more tricky
			' as we have to deal with wrap around.
			mov	xdiff, rx
			sub	xdiff, px
			abs	xdiff, xdiff

			' if the distance is <= 3, then it's clearly within range
			cmp	xdiff, #4	WC
		if_c	jmp	#x_in_range

			' if px is less than rx, recalc xdiff as px+16 - rx
			cmp	px, rx		WC
		if_nc	jmp	#no_point

			mov	xdiff, px
			add	xdiff, #16
			sub	xdiff, rx

			' if y difference is >= 4, don't even bother, they are too far apart
			cmp	xdiff, #4	WC
		if_nc	jmp	#no_point

x_in_range		and	xdiff, #3
			and	ydiff, #3

			' build index into 'influence' array
			mov	r0, ydiff
			shl	r0, #2
			add	r0, xdiff

			' get influence
			mov	r1, #influence
			add	r1, r0
			movs	:get_influence, r1
			nop
:get_influence		mov	r0, dummy

			' adjust rcell by the influence
			add	rcell, r0

			' cap at max colour
			cmp	rcell, max_colour	WC
		if_nc	mov	rcell, max_colour
		if_nc	sub	rcell, #1

			' store back
			movd	:save_cell, roffset
			nop
:save_cell		mov	dummy, rcell

no_point		' sometimes I wonder

			sub	rc,#1		WC
		if_nc	jmp	#point_loop

			sub	rx, #1		WC
		if_nc	jmp	#col_loop

			sub	ry, #1		WC
		if_nc	jmp	#row_loop



			djnz	move_count, #skip_move

			' get point 0
			' get x
			' decrement x
			' put back together
			mov	r0, points
			shr	r0, #16
			add	r0, #1
			and	r0, #15
			and	points, point_mask_clear_x
			shl	r0, #16
			or	points, r0			

			mov	move_count, move_delay

skip_move
'			mov	r0, delay
'			add	r0, cnt
'			waitcnt	r0, #0


			' this is where we update the frame buffer with the correct
			' colours
			mov	r0, frame_buf_addr
			mov	r2, #cells
			mov	rc, #128
update_display
			movs	:update_display_inst,r2
			mov	r1, palette_addr
:update_display_inst	mov	cell, dummy	

			' decrease cells gradually back to initial_colour
			sub	cell, #4
			cmp	cell, initial_colour	WC
		if_c	mov	cell, initial_colour

			movd	:store_decayed_cell, r2
			nop
:store_decayed_cell	mov	dummy, cell

			' there are 8 decimal digits so we shift right 8, and back two
			' because the palette is in main mem and is addressing a long
			shr	cell, #6

			add	r1, cell
			rdlong	cell, r1
			wrlong	cell, r0		' write pixel back

			add	r0, #4
			add	r2, #1
			djnz	rc, #update_display

			' and back to the start
			jmp	#update_cells


frame_buf_addr          long    0			' the frame buffer
frame_control_addr      long    0			' the frame buffer control address
random_addr             long    0			' the random number address
palette_addr		long	0

cell			long	0
rx			long	0
ry			long	0
roffset			long	0
rcell			long	0
r0			long	0
r1			long	0
r2			long	0
rc			long	0
dx			long	0
dy			long	0
px			long	0
py			long	0
xdiff			long	0
ydiff			long	0
poffset			long	0
initial_colour		long	20 * 256
max_colour		long	1024 * 256		' max palette index + 1
zero			long	0
dummy			long	0	' this is used for symbolic reference on movd and movs
					' instructions, so its clear which part of the instruction
					' is being modified.
delay			long	$1000
move_delay		long	4000
move_count		long	0
decay_speed		long	4

' The points. up to 4. Each is 4 bytes: [none:8][x:8][y:8][offset:8]
points			long	$00000440
			long	$00000200
			long	$00010600
			long	$00020500

point_mask_clear_x	long	$ff00ffff

' This is a map indexed by [ydiff:2][xdiff:2] and determines a weight. It is an approximation
' of the distance between two points, but in this case we don't care if the point are separated
' by 4 or more. If both differences are in the range 0..3, we combine those differences and use
' it as an index.
influence		long	$12	' xdiff=0, ydiff=0  points are the same
			long	$0e	' xdiff=1, ydiff=0
			long	$0a	' xdiff=2, ydiff=0
			long	$00     ' xdiff=3, ydiff=0
			long	$0e	' xdiff=0, ydiff=1
			long	$0c	' xdiff=1, ydiff=1
			long	$08	' xdiff=2, ydiff=1
			long	$00	' xdiff=3, ydiff=1
			long	$0a	' xdiff=0, ydiff=2
			long	$08	' xdiff=1, ydiff=2
			long	$00	' xdiff=2, ydiff=2
			long	$00	' xdiff=3, ydiff=2
			long	$00	' xdiff=0, ydiff=3
			long	$00	' xdiff=1, ydiff=3
			long	$00	' xdiff=2, ydiff=3
			long	$00	' xdiff=3, ydiff=3

' this is the cell array, which maps 1-1 with framebuffer cells. Each is a colour
' index 0-1023.
' if space is required this can be compressed into 64 longs, with each being the
' high word and low word. An optimsation if it is required
cells			res	128

