# jombloforth

Minimal FORTH interpreter for 64-bit Linux systems. Based on
jonesforth which was written for the 32-bit Linux.

## Compile

You will need `nasm` and `ld` for this. To produce the `jombloforth`
executable, execute this in the command line:

```
nasm -g -F dwarf -f elf64 -o jombloforth.o jombloforth.asm
ld -o jombloforth jombloforth.o
```

It will create a statically linked 64-bit elf executable with
debugging symbol on.

Alternatively, for convenience, the jombloforth make target is provided.
To invoke it, just run:

```
make jombloforth
```

## Running

In FORTH a function is called word. The executable above only provides the barebone
words needed to complete the full system. Everything else will be defined in
the FORTH language itself. The full definition is inside the file jombloforth.f

To run the interpreter using the full set of the words, execute:

```
cat jombloforth.f - | ./jombloforth
```

The cat command above means it takes input from both the jombloforth.f
file and the stdin (`-` part). And then `jombloforth` executable will
wait your input after interpreting (or compiling) the content of
jombloforth.f.

And again, for convenience, you can just run this instead:

```
make run
```

## Quick Forth Tutorial

Using this interpreter, you can start typing any forth program. This
section will gives quick example of it.

Forth is a stack based language. You type a number followed by
whitespace to put those number into the stack. A word (function) is also
typed and separated by whitespace. They takes their input from the
stack and put the result back into them (if there's any). The `+`,
`.`, and `CR` below are example of forth words.

The following example will add the two numbers and then print the
result.

```
42 24 + . CR
```

After typing 42 and 24, we will have two number in the stack. The `+`
will pop those two number, add them, and push the result, 66, back
into the stack. The `.` will pop that 66 and print it. And finally
CR will just print newline.

To quit the program, press CTRL+D.

## License

UNLICENSE. See [UNLICENSE.txt](/UNLICENSE.txt)