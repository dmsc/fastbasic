---
title: "FastBasic Cross Compiler - Fast BASIC interpreter for the Atari 8-bit computers"
---

FastBasic Cross Compiler
========================

This is the FastBasic cross compiler. It takes a basic sources and compiles to
an assembly file, and then uses the CA65 assembler and LD65 linker (from the
CC65 tools) to build an Atari executable.


Installation
------------

Extract the FastBasic compiler on any folder. The CC65 tools are already
included in the archive.


Basic Usage
===========

For simple compilation of BAS files to XEX (Atari DOS executable), use the
included `fb` and `fb-int` scripts.

- On Linux:

      /path/to/fb myprog.bas

  or:

      /path/to/fb-int myprog.bas

- On Windows:

      C:\path\to\fb myprog.bas

  or:

      C:\path\to\fb-int myprog.bas

There are two compilers, one for the full version `fastbasic-fp`, used with the
`fb` script, and another for the integer only version `fastbasic-int`, used
with the `fb-int` script. The advantage of the integer only version is that it
produces smaller executables.

The script generates three files from the basic source:

- XEX file, standard Atari 8-bit executable.

- ASM file, the assembly source.

- LBL file, a list of labels, useful for debugging. This file includes a label
  for each line number in the basic source.

The compilation is a three step process, the included script does each step in
turn:

- The included compiler reads the basic source and produces an assembly file:

      fastbasic-fp myprog.bas myprog.asm

- The `CA65` assembler is used to assemble to an object file:

      ca65 -t atari -g myprog.asm -o myprog.o

- The `LD65` linker joins the object file with the runtime library to generate the XEX:

      ld65 -C /path/to/fastbasic.cfg myprog.o -o myprog.xex /path/to/fastbasic-fp.lib

Advanced Usage
==============

Passing options to the compiler
-------------------------------

The compiler scripts `fb` and `fb-int` allows passing options to the compiler,
allowed options are:

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


Linking other assembly files
----------------------------

The compiler support linking to external assembly modules, you can pass them to
the `fb` command line:

    fb myprog.bas myasm.asm

This will compile `myprog.bas` to `myprog.asm` and then assemble the two files
together using CA65 and LD65. You can pass multiple `.asm` (or `.o`) files to the
command line, but only one basic file.

From the FastBasic source, you can reference any symbol via `@name`, for example:

    ' FastBasic code
    '
    ? "External USR sample:"
    ? USR( @Add_10, 25 )

The ASM file must export the `ADD_10` (always uppercase) symbol, for example:

    ; Assembly module
      .export ADD_10

    .proc ADD_10
      pla   ; Parameters are pased over the stack, in reverse order
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

