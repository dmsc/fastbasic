FastBasic - Fast BASIC interpreter for the Atari 8-bit computers
----------------------------------------------------------------

This is a fast interpreter for the BASIC language on the Atari 8-bit computers.

The current features are:
- Support for Atari floating point and 16bit integer variables;
- Support for string arrays, substrings and concatenation;
- Small size (currently the full floating point IDE is 9.3k, the integer IDE is 8k, and the runtime is less than 3k);
- Fast execution (currently, about 43% faster than compiled TurboBasicXL in the "sieve.bas" benchmark, 5 times faster than OSS Integer Basic);
- Modern syntax (no line numbers, many control structures);
- Feels "alike" TurboBasicXL, with many of the extended statements.
- Integrated editor and compiler.
- A cross-compiler is available that directly compiles sources to Atari executables in any modern PC.

For support, use the GitHub bug-tracker or see the AtariAge thread at:
http://atariage.com/forums/topic/275698-fastbasic-summer-release/


Manual
------

There is a full manual with all the supported syntax in the file [manual.md](manual.md).

To use the cross-compiler, download from the releases and see [compiler/USAGE.md](compiler/USAGE.md) for instructions.


Sample files
------------

There are samples for the [integer only compiler](samples/int/) and for the [floating point compiler](samples/fp/), in addition to more test programs in the [tests](tests/) folder.


License
-------

FastBasic is free software under the terms of the GNU General Public License,
either version 2 or lather, see the file [LICENSE](LICENSE) for the full text.

The runtime is also under the following linking exception:

> In addition to the permissions in the GNU General Public License, the authors
> give you unlimited permission to link the compiled version of this file into
> combinations with other programs, and to distribute those combinations without
> any restriction coming from the use of this file. (The General Public License
> restrictions do apply in other respects; for example, they cover modification
> of the file, and distribution when not linked into a combine executable.)

This means that you can distribute the compiled result of any program written
by you under any license of your choosing, either proprietary or copyleft.


Compiling the sources
---------------------

To compile the sources, you need:
- CC65 suite, version 2.16 or later, from http://cc65.github.io/cc65/getting-started.html
- Host build tools (make & gcc) to build the syntax generator
- mkatr, from https://github.com/dmsc/mkatr to build the Atari disk image (ATR) file.

Then, type make to build all sources to a "fastbasic.xex" file and a "fastbasic.atr" disk image.

There is also a test-suite that tests various source files compiled with the
Atari compiler and the cross compilers, you can run the test-suite by typing
`make test`

