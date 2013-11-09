# About

This is the code for an electronics project I built, an LED cylinder. The hardware is basically a grid of 16x8 RGB LEDs arranged in vertical cylinder,
with ping-pong balls over each LED. It has a nintendo nunchuck for input and a small LCD display for mode selection. The cylinder hardware and
build can be found [on stuffwemade.net](http://stuffwemade.net/led-cylinder "LED cylinder build").

The cylinder is driven by custom circuitry, based around the very flexible Parallax Propeller, supplemented with a display driver board consisting
of 6 TLC5940 ICs and supporting circuits. The circuit diagram is in this repository, as an Eagle schematic under the "circuit" folder.

The code is a mix of spin and assembly. The Propeller has 8 "cogs", which are effectively processors with a small amount of RAM each, and then sharing
32K RAM on chip. Each cog can run a spin program (spin interpreter is loaded into cog RAM, and spin byte code executed from shared RAM), or can run
assembly directly. Spin is a easier to write than assembly, but assembly is considerably faster. Code was written before the Propeller C compiler
was available, which might have saved some grief.

There are some old artifacts here as well, such as early effect implementations that didn't work out and test code while the circuit was still being
designed and made to work. There is also a little bit of Arduino code, as the original circuit design had a Atmel ATMega328 as well for driving the LCD,
until I could easily support that on the Propeller as well.
