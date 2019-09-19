# 8086-Assembly

**Two implementations by x86 masm language for 8086 chip (and its simulator).**

The `qsort` folder is quick sort. The `kintr` folder is keyboard interrupt. See README in each folder for more detail. 

*This work is a part of course project of IS224, spring, 2019. Sincerely thanks to Professor Lu.*


## Installation

1. Get DosBox environment and masm tool

2. Move `.asm` file to masm installation directory

3. Compile assembly code (in masm installation directory): `MASM <file>.asm`

4. Link objects: `LINK <file>.obj`

5. Direct run: `<file>.exe`;

   Debug run (recommended): `DEBUG <file>.exe`. Frequently used commands:

    `-u`: see codes  
    `-r`: see registers   
    `-d <address>`: see storage  
    `-g`: run all  
    `-t <address>`: run step  
    `-p`: run block


## Requirements

Tested on DosBox v0.74, masm 5.


## License

See [`LICENSE`](LICENSE) for licensing information.
