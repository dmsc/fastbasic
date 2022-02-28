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


### Syntax of the Target files

The target files (with `.tgt` extension) allows changing many aspects of the
compilation process.

The syntax of the files is line oriented, with one command per line. The list
of commands is the following:

- `#`: A line that starts with a sharp symbol is a comment. The rest of the
       line is ignored.

- `include`: Includes all the target definitions for the named file. If the
             file name given does not have an extension, `.tgt` is added.

- `library`: Gives the name of the library to link with a compiled FastBasic
             program for this target. Only one library file is alowed, the last
             one read takes precendence.

- `config`: Gives the name of the linker configuration file used for this
            target.

- `extension`: Gives the extension of the compiled file for this target.

- `ca65`: Gives a list of options to pass to the `CA65` assembler. Multiple
          options are simply added after the previous.

- `syntax`: Gives a list of syntax files to read, defining the syntax of all
            the language. Multiple files are read in the order given, and
            all definitions are merged together.


### Understanding the Syntax files

The syntax files (with `.syn` extension) define the full parsing rules of the
FastBasic language - there are no predefined rules in the parser, all the
language is defined in the included `.syn` files.

In the top level, the syntax files are composed of *tokens*, *symbols*,
*external routines* and *rules*.

The *tokens* are a list of bytecode language instructions available to the
parser for the compiled code. The FastBasic interpreter supports up to 128
tokens, mos implements core functionality (like adding two numbers, or loading
the value of a variable, etc.). The tokens are listed in a special `TOKENS`
section:

    TOKENS {
       token-1, token-2
       token-3
       ...
    }

The *external routines* are routines that can be called from the parser to
parse special constructs, or modify compiler state outside the parser, examples
are adding a variable to the list of variables, checking if a variable name is
already defined, parsing a number or string, etc. The external routines are
listed in a special `EXTERN` section:

    EXTERN {
       name_1, name_2
       name-4
       ...
    }

There is an important external rule `E_EOL` that matches at the end of the
input line.

All external routines used in the parser needs to be implemented in the
compiler in C++ and in the 6502 compiler in assembly, or the parser will fail.

The *symbols* are a list of symbols available to the parser to use for the
compiled code, this allows the parser to include names instead of numeric
constants for the compiled code, and allows using symbols from the library.

The named *rules* define a part of the syntax that the parser understand, and
are defined using a name followed by a colon:

    NAME: rule description
        pattern-1
        pattern-2
        ...

The *NAME* of the rule must start with a letter, and can contain any number of
letters, numbers or underscores, on the other hand the *rule description* is
one line of any text that is shown when the parser encounters a syntax error
when expecting this rule.

Each *pattern* define a posible parsing for this rule. Each pattern is tried
from the first to the last, and the first pattern that matches allows the rule
to match. If after trying all the patterns, the last one does not match, the
rule fails to match.

The patterns must be in one line, and must begin with at least one space to
differentiate from a rule definition.

The patterns can contain the following:

- Text enclosed in double quotes (`"`). The rule matches if all the text in the
  quotes matches the input, ignoring case - the parser is case insensitive.

  The FastBasic parser also supports abbreviations: Any lower-case letter in the
  quoted text is optional, if in that place of the input is a dot, the rest of
  the quoted text is skipped.

  For example, the pattern `"HEllo!!"` matches the text `HELLO!!`, `HE.`,
  `HEL.` or `HELL.`.

- The name of a rule. This matches if the rule matches here.

- The name of an external rule. This matches if called code returns true.

- The word `emit` followed by a token, symbol or number. This instructs the
  parser to output the given token, symbol or number to the compiler. The
  symbols and numbers produces one byte in the output, except when the symbol
  is prepended with an ampersand (`&`) that produces two bytes (a `word`).

  You can also follow the `emit` with a list of symbols enclosed in curly
  braces ( `{` and `}` ).

The last pattern in a rule can also be the special word `pass`, this makes the
parser to accept the rule even if no other pattern matched, effectively making
the rule optional.

Finally, there is a special rule named `PARSE_START` that the parser calls for
each line in the input.

The parsing rules are based in the PEG grammar syntax, but simplified to make
the 6502 parser simpler and faster. You can convert PEG rules to FastBasic
syntax rules by simple replacing:

- An optional rule `RULE ?`:

      RULE_OPT:
        RULE
        pass

- An optional and repeatable rule `RULE *`:

      RULE_OPT_REP:
        RULE RULE_OPT_REP
        pass

- A repeatable rule `RULE +`:

      RULE_REP:
        RULE RULE_MORE

      RULE_MORE:
        RULE RULE_MORE
        pass


