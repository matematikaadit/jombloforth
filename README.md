# jombloforth

Minimal FORTH interpreter for 64-bit Linux systems. Based on
jonesforth tutorial.

## Compile

You needs make, nasm, and ld to build the executable. Runs the following to build them

```
make jombloforth
```

## Running

For a full forth system, runs:

```
make run
```

The interpreter will starts accepting input from stdin.

## Quick Forth Tutorial

After the interpreter starts, you can execute any forth command defined in the system. For example, adding two number and display it.

```
42 24 + . CR
```

Will print 66 followed by newline.

Defining new word and runs it:

```
: double DUP + ;
100 double . CR
```

Will print 200.

To exit the program, press CTRL+D

## License

UNLICENSE. See [UNLICENSE.txt](/UNLICENSE.txt)