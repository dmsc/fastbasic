FastBasic - Fast BASIC interpreter for the Atari 8-bit computers
----------------------------------------------------------------

This is a fast interpreter for the BASIC language on the Atari 8-bit computers.

The current features are:
- Support for 16bit integer variables;
- Small size (currently the IDE is less than 9k, and the runtime is less than 2k);
- Fast execution (currently, about 15% faster than compiled TurboBasicXL in the "sieve.bas" benchmark, 3.5 times faster than OSS Integer Basic);
- Modern syntax (no line numbers, many control structures);
- Feels "alike" TurboBasicXL, with many of the extended statements.
- Integrated editor and compiler.

For more support, see the AtariAge thread at:
http://atariage.com/forums/topic/267929-fastbasic-beta-version-available/

Manual
------

There is information of the supported syntax in the file [manual.md](manual.md).

Sample files
------------

In the "tests" folder there are some samples of the language.


Compiling the sources
---------------------

To compile the sources, you need:
- CC65 suite, from http://cc65.github.io/cc65/getting-started.html
- Host build tools (make & gcc) to build the syntax generator
- mkatr, from https://github.com/dmsc/mkatr to build the Atari disk image (ATR) file.

Then, type make to build all sources to a "fastbasic.xex" file and a "fastbasic.atr" disk image.

