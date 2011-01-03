{
  The core responsbility of DebugController is to provide abstractions for debugging via
  the serial terminal. The controller itself doesn't run in a separate cog, but
  the serial terminal interface does.
}
OBJ
  terminal    : "Parallax Serial Terminal"

{
  Start the debugging process. This should only be done once by the core controller
}
PUB Start
  terminal.Start(115200)
  terminal.Str(String("Debugging started"))

{
  Send a value to the debug queue. Any process can do this.
}
PUB Send(bufferptr, semaphore, value) | c
  repeat until long[bufferptr] < 20  ' wait if buffer overrun
  repeat until not lockset(semaphore)
  c := long[bufferptr] + 1  ' get the current pointer
  long[bufferptr][c] := value
  long[bufferptr] += 1
  lockclr(semaphore)
{
  Transmit all messages on the debug queue, clearing the queue.
}
PUB clearQueue(bufferptr, semaphore) | c, i
  repeat until not lockset(semaphore)
  c := long[bufferptr]   ' get count of queue items
  i := 1
  repeat while c > 0
    terminal.Dec(long[bufferptr][i])
    terminal.NewLine
    c--
  long[bufferptr] := 0
  lockclr(semaphore)

