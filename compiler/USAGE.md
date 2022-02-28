---
title: "FastBasic Cross Compiler - Fast BASIC interpreter for the Atari 8-bit computers"
---

FastBasic Cross Compiler
========================

This is the FastBasic cross compiler. It takes a BASIC source, compiling to
an assembly file, and then via the CA65 assembler and LD65 linker (from the
CC65 tools) builds an Atari executable.


Installation
------------

Extract the FastBasic compiler on any folder. The CC65 tools are already
included in the archive.


Basic Usage
===========

For simple compilation of BAS files to XEX (Atari DOS executable), call the
`fastbasic` program, passing the basic source file as the first parameter.

- On Linux:

      /path/to/fastbasic myprog.bas

- On Windows:

      C:\path\to\fastbasic myprog.bas


The compiler supports multiple possible targets, with different capabilities,
you can select between the target with the `-t:` compiler option, between the
following:

- `atari-fp`: Compile to an Atari 8-bit executable (`.xex`) with floating-point
  support. This is the default if no other target is selected.

- `atari-int`: Compile to an Atari 8-bit executable with only integer support.
  The compiled program will be a little smaller using this target, as no
  floating-point initialization is done.

- `atari-cart-fp`: Compile to an Atari 8-bit cartridge image (`.rom`), with
  floating point support. Currently, the cartridge support is limited to 8kB.

- `atari-cart-int`: Compile to an Atari 8-bit cartridge image (`.rom`), with
  only integer support.

- `atari-5200`: Compile to an Atari 5200 cartridge image (`.bin`), with only
  integer support. Note that not all statements are supported in the Atari
  5200, as the console lacks any file I/O.

This example produces a cartridge image for the Atari 8-bit computers:

     fastbasic -t:atari-cart-fp myprog.bas


The compiler generates various files from the basic source:

- `XEX` file, standard Atari 8-bit executable. By default, the name of this
  file is taken from the name of the first source passed to the compiler,
  removing the original extension.

- `ROM` file, standard Atari 8-bit cartridge image.

- `BIN` file, standard Atari 5200 cartridge image.

- `LBL` file, a list of labels, useful for debugging. This file includes a
  label for each line number in the basic source, and the name is the same as
  the `XEX` / `ROM` file but with the `lbl` extension.

- `O` file, the assembled "object" files. Each source file is
  assembled/compiled to one object file, with the same name and the `o`
  extension. The object files are passed to the linker.

- `ASM` file, the assembly source. Each FastBasic source file produces one
  assembly file with the compiled program.

The compilation is a three step process:

- The compiler reads the basic source and produces an assembly file.

- The compiler calls the `CA65` assembler to produce an object file.

- The compiler calls the `LD65` linker to join the object file with the runtime library, generating the `XEX`, `ROM` or `BIN` depending on the target.


Advanced Usage
==============

Passing options to the compiler
-------------------------------

The compiler accepts the following options, options taking an argument can use
an `:` or an `=` to separate the option from the argument.

- **-t**:*target*  
  Selects the compilation target. The target definitions are searched in the
  compiler installation folder, with an `.tgt` extension.

  If this option is not given, the `default.tgt` file is loaded, currently this
  file simply includes the `atari-fp.tgt` file.

- **-v**  
  Shows the compiler version.

- **-n**  
  Disable all the optimizations, the produced code will be the same as the
  native IDE. This is useful to debug problems with the optimizations passes,
  should not be used normally.

- **-prof**  
  Helps profiling the compiler generated code. Outputs statistics of the most
  used tokens and token pairs.

- **-d**  
  Enable parser debug options. This is only useful to debug parser, as it
  writes the full parsing tree with all the tried constructs.

- **-l**  
  In addition to compiling the file, also write to standard output a prettified
  version of the input program, with all abbreviations expanded, one statement
  per line and indented code. This is useful to examine compiler errors in heavily
  abbreviated code.

- **-h**  
  Shows available compiler options.

- **-C**:*linker-file.cfg*  
  Use a different linker configuration file than the default.

- **-S**:*address*  
  Sets the start address of the compiled binary. The default value is `$2000`,
  set in the configuration file `fastbasic.cfg`. You can specify a different
  address to allow for a bigger DOS, or to have more memory available if you
  don't use a DOS. The address can be specified as decimal or hexadecimal with
  `0x` at front. This option is ignored when producing cartridge images.

- **-X**:*ca65-option*  
  Passes the given option to the CA65 assembler. See the CA65 documentation for
  valid options, some useful options are listed bellow:

  - **-X:-I***path*  
    Adds a path to search for assembly included files, used in your custom ASM
    sources.

  - **-X:-D***symbol*  
    Define an assembly symbol, used in custom ASM sources.

  When using `-X:` you can't leave spaces for the option, use multiple `-X:`
  for each space separated argument. For example, you can use `-X:-I -X:path `
  as two options or `-X:-Ipath`, as both will pass the same option and value.

- **-s:**:*segment_name*  
  Sets the name of the "section" where the compiler will place the generated
  code. The default segment is `BYTECODE`, if you change the segment you must
  ensure that there is a segment with that name in the linker configuration.

- **-target-path**:*path*  
  Sets the path where the target definition files are searched. The default is
  to search in the same folder as the compiler executable.

- **-syntax-path**:*path*  
  Sets the path where the syntax grammar files are searched.


Linking other assembly files
----------------------------

The compiler support linking to external assembly modules, you can pass them to
the `fastbasic` command line:

    fastbasic myprog.bas myasm.asm

This will compile `myprog.bas` to `myprog.asm` and then assemble the two files
together using CA65 and LD65. You can pass multiple `.asm` (or `.o`) files to the
command line, all the files will be assembled and linked together.

From the FastBasic source, you can reference any symbol via `@name`, for example:

    ' FastBasic code
    '
    ? "External USR sample:"
    ? USR( @Add_10, 25 )

The ASM file must export the `ADD_10` (always uppercase) symbol, for example:

    ; Assembly module
      .export ADD_10

    .proc ADD_10
      pla   ; Parameters are pased in the stack, in reverse order
      tax
      pla
      clc
      adc #10
      bcc no
      inx
    no:
      ; Return value in A/X registers
      rts
    .endproc

You can also export ZP symbols, to import them use `@@name`.


Extending the language
----------------------

The FastBasic compiler is extensible, the syntax is read at compilation time
from various files with the grammar and compilation rules (the `.syn` files in
the `syntax` folder).

The following sections show how to add simple functions and statements to the
language, you can look at the existing syntax files for more advanced usage.


### Adding new functions

Suppose you want to add new functions to the language, to check if a console
key is pressed:

- `CSTART()`  : Returns 1 if the *START* key is pressed,
- `CSELECT()` : Returns 1 if the *SELECT* key is pressed,
- `COPTION()` : Returns 1 if the *OPTION* key is pressed,

To implement the functions above, the following FastBasic code could be used:

|Function| Equivalent Code           |
| ------ | ------------------------- |
| CSTART | `NOT (PEEK(53279) & 1)` |
| CSELECT| `NOT (PEEK(53279) & 4)` |
| COPTION| `NOT (PEEK(53279) & 4)` |

#### 1. Create a new target

First, you need to create a new target, let's call it `atari-extra`. Create a
file in the FastBasic compiler folder named `atari-extra.tgt`, with the
following contents:

    include atari-fp
    syntax console.syn

The first line simply reads the `atari-fp` target, so the new target will have
all the definitions already in the standard target.

The second line, adds a new syntax, from the file `console.syn`, this will be
appended to the syntax in the standard `atari-fp`.

#### 2. Create a new syntax file

Now, create a `console.syn` file inside the syntax folder, with the following
content inside:

    INT_FUNCTIONS:
         "CSTART()"
         "CSELECT()"
         "COPTION()"

This defines three new functions, without parameters, and without any coed
generated. You could now compile a simple program, but the resulting executable
will not run because the code for the functions is missing.

To add the code, you need to use the `emit` keyword, and inspect the code
generated for our test examples.

#### 3. Adding code for the new functions

Compile to assembler a simple basic source:

    PRINT NOT (PEEK(53279) & 1)

Using `fastbasic -c simple.bas`, and examine the generated assembly file, you
will see the following bytecode at the end:

    TOK_NUM
    53279
    TOK_PEEK
    TOK_PUSH_1
    TOK_BIT_AND
    TOK_COMP_0
    TOK_L_NOT
    TOK_INT_STR
    TOK_PRINT_STR

You can see that the code is similar to the basic source:

- Load number `53279`
- `PEEK` from that location
- Load number `1`
- Perform the `&` operation
- Compare the result with `0`
- Negate the result.
- Convert to string and `PRINT`.

We need to generate similar code for the `CSTART()` function. To do that, edit
the `console.syn` file, and add the emitted code:

    INT_FUNCTIONS:
         "CSTART()"   emit { TOK_NUM, &53279, TOK_PEEK, TOK_PUSH_1, TOK_BIT_AND, TOK_COMP_0, TOK_L_NOT }
         "CSELECT()"  emit { TOK_NUM, &53279, TOK_PEEK, TOK_PUSH, TOK_BYTE, 2, TOK_BIT_AND, TOK_COMP_0, TOK_L_NOT }
         "COPTION()"  emit { TOK_NUM, &53279, TOK_PEEK, TOK_PUSH, TOK_BYTE, 4, TOK_BIT_AND, TOK_COMP_0, TOK_L_NOT }

Note that the `emit` code needs to be in one line, and the `&` symbol before
the `53279` indicates a word value (two bytes) instead of a simple byte.

#### 4. Testing the new language extensions

Now, you can compile this simple test program:

    ? "Press console keys,"
    ? "or any other key to exit:"
    REPEAT
     MSG$=""
     IF CSTART()  THEN MSG$=+"START "
     IF CSELECT() THEN MSG$=+"SELECT "
     IF COPTION() THEN MSG$=+"OPTION"
     IF MSG$ <> "" THEN ? MSG$
    UNTIL KEY()

Compile with:

    fastbasic -t:atari-extra myprog.bas

#### 5. Factorizing the code

Instead of writing the full code for each function, you can rearrange the code
to make the syntax smaller, and use constants to make it more generic, by
defining a new syntax table:

    SYMBOLS {
        CONSOL = $D01F
    }

    READ_CONSOLE:
         "()" emit { TOK_PUSH, TOK_NUM, &CONSOL, TOK_PEEK, TOK_BIT_AND, TOK_COMP_0, TOK_L_NOT }

    INT_FUNCTIONS:
         "CSTART"   emit { TOK_1 }       READ_CONSOLE
         "CSELECT"  emit { TOK_BYTE, 2 } READ_CONSOLE
         "COPTION"  emit { TOK_BYTE, 4 } READ_CONSOLE

Note the use of the symbol `CONSOL` instead of the number, and the rearranging
of the code to allow factorization.


### Adding new statements

To add new statements, instead of expanding the table `INT_FUNCTIONS`, you need
to expand the table `STATEMENT`, but the logic is the same.

Also, to interface the interpreter with new assembly functions, you can emit
code similar to an `USR()` call, and process the parameters in the assembly.

Let's implement a new statement, `WAIT` that can wait for a vertical line in
the screen.

The simple assembly version of this statement would be:

    .export DO_WAIT
    .include "atari.inc"

    DO_WAIT:
        ; Line number is in accumulator already
    loop:
        cmp VCOUNT
        bcc loop
        rts

Save this file as `wait.asm`.

Now, we can edit our `atari-extra.tgt` target file, and add a new syntax file
to it:

    include atari-fp
    syntax console.syn wait.syn

And same as the first example, just add a new syntax file, `wait.syn`, with
this content:

    SYMBOLS {
        DO_WAIT = import
    }

    STATEMENT:
        "WAit" emit { TOK_NUM, &DO_WAIT, TOK_USR_ADDR} EXPR emit { TOK_USR_CALL }

Now, you can compile this simple example:

    DO
      WAIT 40
      POKE $D018, $36
      WAIT 80
      POKE $D018, $C8
    LOOP

The command line to compile should be:

    fastbasic -t:atari-extra testw.bas wait.asm

Testing the resulting file, you should be three color zones in the screen.

There some parts of the syntax file that needs explanation:

- The `"WAit"` string is specified with mixed case. The lower-case characters
  denote "optional" part of the name, so you can abbreviate this new statement
  as "WA." or "WAI.".

- We are loafing the `DO_WAIT` address into the `USR` calling address as the
  first step in the generated code. This is needed to be able to call the
  assembly code with out parameter in the accumulator.

- To get the value of the symbol `DO_WAIT`, we need to specify `import` as the
  symbol value, this means the value will be filled by the linker.

- Then, we are expecting an `EXPR`. This syntax specifies an integer
  expression, the parser will parse any expresion that gives am integer number
  here, and the result will be placed in the `A` and `X` registers.


