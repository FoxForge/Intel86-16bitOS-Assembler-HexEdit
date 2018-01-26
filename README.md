# Intel86-16bitOS-Assembler-HexEdit
Basic Intel86 16 bit OS running in BOCHS emulator with a personal "hex edit" to view disk sectors

## How To Run

Using Cygwin64 terminal, run the command "make" when in the specified director with this containing folder.
It will then produce the binaries ready for you to run it with BOCHS emulator.

The program I have written allows you to read disk sectors.
It will then display them in the terminal in a similar fashion to HexEdit.

The assembler code takes care of input control and prompts the user for some values.
After inputing the values you want, it will print the sector number in hex, then it's contents in hex, and then contents in ASCII per line.

The code is thoroughly commented and every step is explained in order to achieve the results.

Feel free to use the code provided however you like. 
It would be nice to be referenced in any work but is not essential.


