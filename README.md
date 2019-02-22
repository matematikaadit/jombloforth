# JombloForth

An x86-64 Linux NASM Port of JonesForth.

# Compile

```
nasm -g -F dwarf -f elf64 -o jombloforth.o jombloforth.asm
ld -o jombloforth jombloforth.o
```

# Running

```
./jombloforth
```

# Known Issue

Currently broken. It segfault whenever the interpreter enter the compile mode.

# License

UNLICENSE