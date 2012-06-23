' self-pong
con
  batColour = $ffffff
  ballColour = $ff00ff
var
  long Stack[60]
  byte cog
  long frameBufPtr
  long randomPtr
  long nunchuckPtr

  long ballDir   ' 0 for backwards, 1 forwards
  long ballAngle
  long batX
  long batY     ' in 1/10 pixel
  long ballX
  long ballY    ' ball vertical position measured in 1/10 pixel
  long ballYInc ' increment of ballY in 1/10 pixel
obj
  frame       : "FrameManipulation"

pub Start(globalBuffersPtr) : success | ci
  Stop

  randomPtr := long[globalBuffersPtr][2]
  nunchuckPtr := long[globalBuffersPtr][5]

  frame.Init(globalBuffersPtr)

  success := (cog := cognew(Run, @Stack) + 1)

pub Stop
  if cog
    cogstop(cog~ - 1)

pri Run | nx,ny
  frame.EnableDoubleBuffering

  batX := 0
  batY := 30
  ballDir := 1
  ballYInc := 4
  ballX := 7
  ballY := 10

  repeat
    frame.ShowAll(0) ' clear frame

    MoveBat
    DrawBat

    ' calculate ball's next pos
    nx := CalcNewBallX
    ny := CalcNewBallY

    ' if the ball is going to hit the bat, change direction and angle
    ' we need to recalc the new ball pos
    if nx == batX and ny => batY and ny =< (batY + 29)
      ballDir *= -1
      nx := CalcNewBallX

    ballX := nx
    ballY := ny

    ' move the ball

    ' finally, draw the ball
    frame.pixel(ballX, ballY / 10, ballColour)

    frame.SwapBuffers

    waitcnt(10_000_000 + cnt)

PRI MoveBat | nx, ny
  nx := long[nunchuckPtr]
  ny := long[nunchuckPtr][1]

  if ny > 80 and batY < 79
    batY += 10
  if ny < -80 and batY > 0
    batY -= 10

  if nx > 80
    batX += 1
  if nx < -80
    batX -= 1
  batX := batX & $f

PRI DrawBat
   frame.pixel(batX, batY / 10, batColour)
   frame.pixel(batX, (batY / 10) +1, batColour)
   frame.pixel(batX, (batY / 10) +2, batColour)

PRI calcNewBallX : x
  if ballDir == 1
    x := (ballX + 1) & $f
  else
    x := (ballX - 1) & $f

PRI calcNewBallY : y
  y := ballY
  y += ballYInc

  ' bounce ball if at top or bottom
  if y < 10
    y := 20
    ballYInc *= -1
  elseif y > 70
    y := 60
    ballYInc *= -1

