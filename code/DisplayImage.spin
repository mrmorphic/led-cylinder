var
  long Stack[60]
  byte cog
  long frameBufPtr
  long randomPtr

OBJ
  frame       : "FrameManipulation"

PUB Start(globalBuffersPtr) : success | ci
  Stop

  frameBufPtr := long[globalBuffersPtr]
  randomPtr := long[globalBuffersPtr][2]

  frame.Init(globalBuffersPtr)
  frame.DisableDoubleBuffering

  success := (cog := cognew(Run, @Stack) + 1)

PUB Stop
  if cog
    cogstop(cog~ - 1)

PRI Run | ci, i, j, delay, m
  longmove(frameBufPtr, @smiley, 128)

DAT

        ' row 0
smiley
        long  $f7f7f7
        long  $f7f7f7
        long  $f7f7f7
        long  $f7f7f7
        long  $13639a
        long  $a1c0d4
        long  $f5f6f7
        long  $f5f6f7

        long  $000000
        long  $000000
        long  $000000
        long  $000000
        long  $000000
        long  $000000
        long  $000000
        long  $000000

        ' row 1

        long  $faf8f7
        long  $eef1f3
        long  $eef1f3
        long  $faf8f7
        long  $6599bc
        long  $005792
        long  $5990b6
        long  $dce5ec

        long  $000000
        long  $000000
        long  $000000
        long  $000000
        long  $000000
        long  $000000
        long  $000000
        long  $000000

        ' row 2

        long  $bed2df
        long  $397caa
        long  $3479a8
        long  $adc7d9
        long  $fefbf9
        long  $a0bed4
        long  $14659b
        long  $3c7eab

        long  $000000
        long  $000000
        long  $000000
        long  $000000
        long  $000000
        long  $000000
        long  $000000
        long  $000000

        ' row 3

        long  $1b699d
        long  $2b72a4
        long  $3378a7
        long  $2871a2
        long  $8fb4cc
        long  $eaeef1
        long  $8cb2cb
        long  $045a94

        long  $000000
        long  $000000
        long  $000000
        long  $000000
        long  $000000
        long  $000000
        long  $000000
        long  $000000

        ' row 4

        long  $065b95
        long  $7ba6c3
        long  $fdfaf8
        long  $bbd0de
        long  $3d7eab
        long  $095d96
        long  $0e6198
        long  $2971a3

        long  $000000
        long  $000000
        long  $000000
        long  $000000
        long  $000000
        long  $000000
        long  $000000
        long  $000000

        ' row 5

        long  $6195b9
        long  $035994
        long  $709fbf
        long  $e6ebee
        long  $d1dee6
        long  $578fb5
        long  $5990b6
        long  $d6e0e8

        long  $000000
        long  $000000
        long  $000000
        long  $000000
        long  $000000
        long  $000000
        long  $000000
        long  $000000

        ' row 6

        long  $e9ecee
        long  $86adc8
        long  $055a94
        long  $367aa8
        long  $fcf9f7
        long  $fcf9f7
        long  $fcf9f7
        long  $fcf9f7

        long  $000000
        long  $000000
        long  $000000
        long  $000000
        long  $000000
        long  $000000
        long  $000000
        long  $000000

        ' row 7

        long  $f2f2f2
        long  $f1f1f2
        long  $cad9e2
        long  $3378a7
        long  $f8f5f5
        long  $f3f2f3
        long  $f3f2f3
        long  $f3f2f3

        long  $000000
        long  $000000
        long  $000000
        long  $000000
        long  $000000
        long  $000000
        long  $000000
        long  $000000

