FastBasic Cross Compiler
------------------------

This is the FastBasic cross compiler. It takes a basic sources and compiles
to an assembly file for CC65.

Requisites
----------

To use, you need CC65 (preferable the 2.16 version or newer) installed, the
scripts assume that it's available, in the path (on Linux / macOS) or in the
"C:\CC65\" folder (on Windows).

Download CC65 from http://cc65.github.io/cc65/getting-started.html

Linux & macOS installation
--------------------------

Install CC65 and place it into the PATH. Extract the FastBasic compiler on any
folder.

Windows installation
--------------------

Install CC65 to the "C:\cc65\" path and then extract the FastBasic compiler on
the "C:\cc65\fb\" folder.


Usage
-----

The compilation is a two step process:

- The included compiler reads the basic source and produces an assembly file:

      fastbasic-fp myprog.bas myprog.asm

- The CL65 tool is used to assemble and link with the runtime library.

      cl65 -t atari -C /path/to/fastbasic.cfg myprog.asm -o myprog.xex /path/to/fastbasic-fp.lib

There are two compilers, one for the full version (fastbasic-fp) and another
for the integer only version (fastbasic-int). The advantage of the integer only
version is that it produces smaller executables.

For simple compilation of BAS files to XEX (Atari DOS executable), use the included
"fb" and "fb-int" scripts.

- On Linux:

      /path/to/fb.sh myprog.bas

  or:

      /path/to/fb-int.sh myprog.bas

- On Windows:

      C:\cc65\fb\fb myprog.bas

  or:

      C:\cc65\fb\fb myprog.bas


Advanced Usage
--------------

The compiler support linking to external assembly modules, you can pass them to
the "cl65" command line:

    fastbasic-fp myprog.bas myprog.asm
    cl65 -t atari -C /path/to/fastbasic.cfg myprog.asm myasm.asm -o myprog.xex /path/to/fastbasic-fp.lib

From the FastBasic source, you can reference any symbol via "@name", for example:

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

You can also export ZP symbols, to import them use "@@name".

