{
  Testbed for testing queueing. This starts a new cog which adds elements to a queue that is then read by
  the core controller, which sends them to the debug controller.
}
VAR
  long stack[20]
  byte cog

OBJ
  debug : "DebugController"

PUB Start(globalBuffers, semaphores, timer) : success
  Stop
  success := (cog := cognew(TestTransmit(globalBuffers, semaphores, timer), @stack) + 1)

PUB Stop
  if cog
    cogstop(cog~ - 1)

PUB TestTransmit(globalBuffers, semaphores, timer) | c
  c := 0
  repeat
    waitcnt(cnt + timer)
    debug.send(long[globalBuffers][9], byte[semaphores], c)
    c++
