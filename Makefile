all: jombloforth

jombloforth.o: jombloforth.asm
	nasm -g -F dwarf -f elf64 -o jombloforth.o jombloforth.asm

jombloforth: jombloforth.o
	ld -o jombloforth jombloforth.o

dump: jombloforth.o
	objdump -j .rodata -j .data -j .text -d -M intel jombloforth.o

clean:
	rm jombloforth.o jombloforth

.PHONY: dump all
