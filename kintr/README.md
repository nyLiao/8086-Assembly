# Keyboard Interrupt

## Functions

* Disable keyboard response for 10 seconds

* Then implement Caesar keyboard (shift = 1) for 10 seconds, i.e. type 'a', display 'b'; type 'b', display 'c'; ...; type 'z', display 'a'

* Repeat two functions above

* Practice assembly coding with ports and interrupts

## Features

* Try to implement with least memory usage as possible

* List out functions of every registers used in segments

* Clear segments, functions and interrupts assignment

* Carefully calculated time counting

## Notes

* Use `DEBUG -g` directly to try the functions

* To solve the problem of masked inputs still staying in buffer, we use a custom flag in memory instead of standard IMR setting, thus this might not be the required optimal solution

* Can add an easy ending input to exit the program
