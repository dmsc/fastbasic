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
`fb` or the `fb-int` programs passing the basic source file as the first
parameter.

- On Linux:

      /path/to/fb myprog.bas

  or:

      /path/to/fb-int myprog.bas

- On Windows:

      C:\path\to\fb myprog.bas

  or:

      C:\path\to\fb-int myprog.bas

There are two compilers, one for the full version, used with the `fb` command,
and another for the integer only version `fb-int`. You should only use the
integer version when developing programs to ensure that no floating point
operations are generated, as currently the size difference of the two versions
is only 3 bytes.

The compiler generates various files from the basic source:

- `XEX` file, standard Atari 8-bit executable. By default, the name of this
  file is taken from the name of the first source passed to the compiler,
  removing the original extension.

- `LBL` file, a list of labels, useful for debugging. This file includes a
  label for each line number in the basic source, and the name is the same as
  the `XEX` file but with the `lbl` extension.

- `O` file, the assembled "object" files. Each source file is
  assembled/compiled to one object file, with the same name and the `o`
  extension. The object files are passed to the linker.

- `ASM` file, the assembly source. Each FastBasic source file produces one
  assembly file with the compiled program.

The compilation is a three step process:

- The compiler reads the basic source and produces an assembly file.

- The compiler calls the `CA65` assembler to produce an object file.

- The compiler calls the `LD65` linker to join the object file with the runtime library, generating the `XEX`.

You can execute the three steps separately by telling the compiler to stop after generating the assembly, with the `-c` option:

      fb -c -o myprog.asm myprog.bas
      ca65 -t atari -g -I /maht/to/asminc myprog.asm -o myprog.o
      ld65 -C /path/to/fastbasic.cfg myprog.o -o myprog.xex /path/to/fastbasic-fp.lib

Advanced Usage
==============

Passing options to the compiler
-------------------------------

The compiler accepts the following options, options taking an argument can use
an `:` or an `=` to separate the option from the argument.

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
  `0x` at front.

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

Linking other assembly files
----------------------------

The compiler support linking to external assembly modules, you can pass them to
the `fb` command line:

    fb myprog.bas myasm.asm

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

