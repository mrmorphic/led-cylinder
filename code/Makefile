LedCylinder.binary: *.spin
	bstc.linux -b -L lib LedCylinder.spin

run: LedCylinder.binary
	bstl.linux LedCylinder.binary

install: LedCylinder.binary
	bstl.linux -p 3 LedCylinder.binary

