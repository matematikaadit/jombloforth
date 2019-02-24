all: jombloforth jombloforth.lst

jombloforth.o: jombloforth.asm unistd_64.inc
	nasm -g -F dwarf -f elf64 -o jombloforth.o jombloforth.asm

jombloforth: jombloforth.o
	ld -o jombloforth jombloforth.o

dump: jombloforth
	objdump -z -j .rodata -j .data -j .text -d -M intel jombloforth

dumpall: jombloforth
	objdump -z -D -M intel jombloforth

jombloforth.lst: jombloforth.asm
	nasm -E jombloforth.asm -o jombloforth.lst

test/%: test/%.o
	gcc -o $@ $<

test/%.o: test/%.asm
	nasm -g -F dwarf -f elf64 -o $@ $<

run: jombloforth
	cat jombloforth.f - | ./jombloforth

runcheck: jombloforth
	./jombloforth < jombloforth.f

clean:
	rm jombloforth.o jombloforth

.PHONY: all dump dumpall run runcheck clean
