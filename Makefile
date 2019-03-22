all: jombloforth

jombloforth.o: jombloforth.asm unistd_64.inc
	nasm -g -F dwarf -f elf64 -o jombloforth.o jombloforth.asm

jombloforth: jombloforth.o
	ld -o jombloforth jombloforth.o

slim: jombloforth.asm unistd_64.inc
	nasm -f elf64 -o jombloforth.o jombloforth.asm
	ld -o jombloforth jombloforth.o

dump: jombloforth
	objdump -z -j .rodata -j .data -j .text -d -M intel jombloforth

dumpall: jombloforth
	objdump -z -D -M intel jombloforth

jombloforth.lst: jombloforth.asm
	nasm -E jombloforth.asm -o jombloforth.lst

experiment/%: experiment/%.o
	gcc -o $@ $<

experiment/%.o: experiment/%.asm
	nasm -g -F dwarf -f elf64 -o $@ $<

run: jombloforth
	cat jombloforth.f - | ./jombloforth

check: jombloforth
	./jombloforth < jombloforth.f

clean:
	rm jombloforth.o jombloforth

.PHONY: all slim dump dumpall run check clean
