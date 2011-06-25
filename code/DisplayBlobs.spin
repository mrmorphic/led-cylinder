var
  long Stack[60]
  byte cog
  long frameBufPtr
  long randomPtr

  long tempBlob1[65]   ' temporary storage of up to 8x8 for generating coloured blobs, plus
                       ' two words for the size.
  long tempBlob2[65]   ' temporary storage of up to 8x8 for generating coloured blobs, plus
                       ' two words for the size.
  long tempBlob3[65]   ' temporary storage of up to 8x8 for generating coloured blobs, plus
                       ' two words for the size.
  long tempBlob4[65]   ' temporary storage of up to 8x8 for generating coloured blobs, plus
                       ' two words for the size.
  long x1, y1, c1, count1
  long x2, y2, c2, count2
  long x3, y3, c3, count3
  long x4, y4, c4, count4
OBJ
  frame       : "FrameManipulation"

PUB Start(globalBuffersPtr) : success | ci
  Stop

  randomPtr := long[globalBuffersPtr][2]

  frame.Init(globalBuffersPtr)

  success := (cog := cognew(Run, @Stack) + 1)

PUB Stop
  if cog
    cogstop(cog~ - 1)

PRI Run | c,x,y,size,delay,srcPtr
  frame.EnableDoubleBuffering
'  frame.DisableDoubleBuffering
  frame.ShowAll($ff)
  frame.SwapBuffers
  repeat
    ' determine a location, colour and size for blob 1
    x1 := long[randomPtr] & $7 + 8
    y1 := long[randomPtr] // 6
    c1 := long[randomPtr] & $ffffff
    if long[randomPtr] & 1 == 1
      frame.CopyImage(@tempBlob1, @blob3)
    else
      frame.CopyImage(@tempBlob1, @blob5)
    frame.ImageTransateColourAlpha(@tempBlob1, $ffffff, c1)

    x2 := long[randomPtr] & $7 + 8
    y2 := long[randomPtr] // 6
    c2 := long[randomPtr] & $ffffff
    if long[randomPtr] & 1 == 1
      frame.CopyImage(@tempBlob2, @blob3)
    else
      frame.CopyImage(@tempBlob2, @blob5)
    frame.ImageTransateColourAlpha(@tempBlob2, $ffffff, c2)

    x3 := long[randomPtr] & $7
    y3 := long[randomPtr] // 6
    c3 := long[randomPtr] & $ffffff
    if long[randomPtr] & 1 == 1
      frame.CopyImage(@tempBlob3, @blob3)
    else
      frame.CopyImage(@tempBlob3, @blob5)
    frame.ImageTransateColourAlpha(@tempBlob3, $ffffff, c3)

    x4 := long[randomPtr] & $7
    y4 := long[randomPtr] // 6
    c4 := long[randomPtr] & $ffffff
    if long[randomPtr] & 1 == 1
      frame.CopyImage(@tempBlob4, @blob3)
    else
      frame.CopyImage(@tempBlob4, @blob5)
    frame.ImageTransateColourAlpha(@tempBlob1, $ffffff, c4)

    delay := long[randomPtr]
    delay &= $fffff
    delay += 100_000

'    srcPtr := @blob3

    ' generate a new image into tempBlob using the selected image,
    ' and with the white substituted for c
'    frame.CopyImage(@tempBlob1, srcPtr)
'    frame.ImageTransateColourAlpha(@tempBlob1, $ffffff, c)

    ' start with whatever was there
'    frame.CopyDispToDrawingBuffer

    ' draw the blob on the frame buffer
    repeat 20
      frame.CopyDispToDrawingBuffer
      frame.ImageAlpha(@tempBlob1, x1, y1)
      frame.ImageAlpha(@tempBlob2, x2, y2)
      frame.ImageAlpha(@tempBlob3, x3, y3)
      frame.ImageAlpha(@tempBlob4, x4, y4)
      frame.SwapBuffers
      waitcnt(500_000 + cnt)
'    frame.Pixel(x,y,c)
'    frame.Pixel(x+1,y,c)
'    frame.Pixel(x,y+1,c)
'    frame.Pixel(x+1,y+1,c)

'    frame.SwapBuffers

'    waitcnt(delay + cnt)

dat
  blob3       word      3
              word      3

              long      $08ffffff
              long      $80ffffff
              long      $08ffffff

              long      $80ffffff
              long      $80ffffff
              long      $80ffffff

              long      $08ffffff
              long      $80ffffff
              long      $08ffffff

  ' a round semi-transparent blob. Edges have higher transparency values.
  ' The colours are artificial. White is used for all displayed pixels,
  ' but in practice these are replaced by a random colour
  blob5       word      5                       ' width
              word      5                       ' height

              long      $0
              long      $08ffffff
              long      $80ffffff
              long      $08ffffff
              long      $0

              long      $08ffffff
              long      $80ffffff
              long      $80ffffff
              long      $80ffffff
              long      $08ffffff

              long      $80ffffff
              long      $80ffffff
              long      $80ffffff
              long      $80ffffff
              long      $80ffffff

              long      $08ffffff
              long      $80ffffff
              long      $80ffffff
              long      $80ffffff
              long      $08ffffff

              long      $0
              long      $08ffffff
              long      $80ffffff
              long      $08ffffff
              long      $0


