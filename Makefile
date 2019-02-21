all: jombloforth

jombloforth.o: jombloforth.asm unistd_64.inc
	nasm -g -F dwarf -f elf64 -o jombloforth.o jombloforth.asm

jombloforth: jombloforth.o
	ld -o jombloforth jombloforth.o

dump: jombloforth
	objdump -z -j .rodata -j .data -j .text -d -M intel jombloforth

dumpall: jombloforth
	objdump -z -D -M intel jombloforth

clean:
	rm jombloforth.o jombloforth

test/%: test/%.o
	gcc -o $@ $<

test/%.o: test/%.asm
	nasm -g -F dwarf -f elf64 -o $@ $<

.PHONY: all dump dumpall clean
