% FastBasic %VERSION% - Fast BASIC interpreter for the Atari 8-bit computers

Introduction
============

`FastBasic` is a fast interpreter for
the BASIC language on the Atari 8-bit
computers.

One big difference from other BASIC
interpreters in 1980s era 8-bit
computers is the lack of line numbers,
as well as an integrated full-screen
editor. This is similar to newer
programming environments, giving the
programmer a higher degree of
flexibility.

Another big difference is that default
variables and operations are done using
integer numbers; this is one of the
reasons that the programs run so fast
relative to its peers from the 1980s.

The other reason is that the program is
parsed on run, generating optimized
code for very fast execution.

Currently, FastBasic supports:

- Integer and floating point variables,
  including all standard arithmetic
  operators.
- All graphic, sound, and color
  commands from Atari BASIC, plus some
  extensions from TurboBASIC XL.
- All control flow structures from
  Atari BASIC and TurboBASIC XL.
- Automatic string variables of up to
  255 characters.
- Arrays of "word", "byte", floating
  point and strings.
- User defined procedures, with integer
  parameters.
- Compilation to binary loadable files.
- Available as a full version `FB.COM`,
  as a smaller integer-only `FBI.COM`,
  and as a command-line compiler
  `FBC.COM` and `FBCI.COM`.


First Steps
===========

To run FastBasic from the included disk
image, simply type `FB` at the DOS
prompt. This will load the IDE and
present you with a little help text:

    --D:HELP.TXT-------------------0--
    '  FastBasic %VERSION% - (c) 2025 dmsc
    '
    ' Editor Help
    ' -----------
    '  Ctrl-A : Move to beginning of line
    '  Ctrl-E : Move to end of line
    '  Ctrl-U / Ctrl-I : Page up / down
    '  Ctrl-Z : Undo (only current line)
    '  Ctrl-C : Set Mark to current line
    '  Ctrl-V : Paste from Mark to here
    '  Ctrl-Q : Exit to DOS
    '  Ctrl-S : Save file
    '  Ctrl-L : Load file
    '  Ctrl-N : New file
    '  Ctrl-R : Parse and run program
    '  Ctrl-W : Compile to binary file
    '  Ctrl-G : Go to line number
    '
    '- Press CONTROL-N to begin -

You are now in the integrated editor.
On the first line of the screen the
name of the currently edited file is
shown, and at the right the line on
which the cursor is located.  Please
note that lines that show an arrow
pointing to the top-left are empty
lines beyond the last line of the
current file.

In this example, the cursor is in the
first column of the first line of the
file being edited.

As the help text says, just press the
`CONTROL` key and the letter `N` (at
the same time) to begin editing a new
file.  If the text was changed, the
editor asks if you want to save the
current file to disk; to skip saving
simply type `CONTROL-C`; to cancel the
New File command type `ESC`.

Now you are ready to start writing your
own BASIC program. Try the following
example, pressing `RETURN` after each
line to advance to the next:

    INPUT "WHAT IS YOUR NAME?";NAME$
    ?
    ? "HELLO", NAME$

The parser will let you know if you 
made any mistakes.  To make corrections 
move back using the cursor keys, this 
is `CONTROL` and `-`, `=`, `+` or `*`,
then press `BACKSPACE` key to delete
the character before the cursor or
press `DELETE` (`CONTROL` and
`BACKSPACE`) to delete the character
below the cursor.  To join two lines,
go to the end of the first line and
press `DELETE`.

After typing the last line, you can run
the program by pressing `CONTROL` and
`R`.

If there are no errors with your
program, it will be run now:  the
computer screen will show `WHAT IS YOUR
NAME?`, type anything and press
`RETURN`, the computer will reply with
a greeting and the program will end.

After this, the IDE waits for any key
press before returning to the editor,
so you have a chance to see your
program's output.

If you press the `BREAK` key when the
program is running, it will terminate,
wait for a key press and return to the
IDE.

If you made a mistake typing in the
program code, instead of the program
running, the cursor will move to the
line and column of the error so you can
correct it and retry.

Remember to save often by pressing the
`CONTROL` and `S` keys and entering a
filename. Type the name and press
`ENTER` to save.  As with any prompt,
you can press `ESC` to cancel the save
operation.  Use the `BACKSPACE` over
the proposed file name if you want to
change it.


Compiling The Program To Disk
=============================

Once you are satisfied with your
program, you can compile to a disk
file, producing a program that can be
run directly from DOS.

Press the `CONTROL` and `W` key and
type a filename for your compiled
program.  It is common practice to name
your compiled programs with an
extension of ".COM" or ".XEX." With
".COM" extension files you don't need
to type the extension in some versions
of DOS on the Atari.  The ".XEX" name is
common in modern times to distinguish
Atari executables from MSDOS/Windows
programs (which are usually ".EXE" or
sometimes ".COM")

Compiled programs include the full
FastBasic runtime, so you can
distribute them alone without the IDE.

You can also compile a program directly
from DOS by using the included command
line compiler `FBC.COM`. You can provide
the BASIC source and the compiled output
file names in the command line; if not
given the compiler will prompt you to
input a file name.

If you don't use floating point, using
the integer versions (`FBI` and `FBCI`)
will compile to a smaller file.


Advanced Editor Usage
=====================

The editor includes a few commands,
most of those are already explainded
above.

- `CONTROL-A` and `CONTROL-E`
  Moves the cursor ro the beginning or
  the end of the line respectively.

- `CONTROL-U` and `CONTROL-I`
  Moves the cursor 19 lines up or down
  respectively.

- `CONTROL-G`
  Moves the cursor to a specific line.

- `CONTROL-Z`
  Reverts all editing of the current
  line. Note that changing the line
  clears the undo buffer, so you can't
  undo more than one line.

- `CONTROL-C`
  Sets the current line as the source
  for a copy operation.

- `CONTROL-V`
  Copy one line from the source marked
  with the `CONTROL-C` to the current
  cursor position.
  After the copy, the source line is
  advanced, so by pressing `CONTROL-V`
  multiple times you can copy multiple
  consecutive lines.

- `CONTROL-L` and `CONTROL-S`
  Loads a file, or Saves the file being
  edited, respectively.

- `CONTROL-Q`
  Returns to DOS, abandoning the
  changes in the current file.

- `CONTROL-R`
  Parses the current program and runs
  it.

- `CONTROL-W`
  Compiles the current program and
  saves it to a binary file.


Making the Editor Faster
========================

The FastBasic IDE uses the Atari screen
handler for writing text, so it is
compatible with all 80 column and other
expansions available.

As the original screen handler in the
Atari OS is slow, there is a screen
accelerator included on the FastBasic
disk.

To use the accelerator, just type
`EFAST` in the DOS prompt, before
loading the IDE, and enjoy editing
programs faster.


About The Syntax
================

The syntax of FastBasic language is
similar to many BASIC dialects, with
the following main rules:

1. A program line must be of 4 types:
   - a comment line, starting with a
     dot `.` or an apostrophe `'`,
   - a statement followed by its
     parameters,
   - a variable assignment, this is a
     name followed by `=` and a the
     expression for the new value.
     For string variables, there is
     also a concatenation operator,
     `=+`.
   - an empty line.

2. All statements and variable names
   can be lower or uppercase, the
   language is case insensitive.

3. Statements can be abbreviated to
   reduce typing; each statement has a
   different abbreviation.

4. Multiple statements can be put on
   the same line by placing a colon `:`
   between statements.

5. After any statement a comment can be
   included by starting it with an
   apostrophe `'`.

6. No line numbers are allowed.

7. Spaces after statements and between
   operators are optional and ignored.

In the following chapters, whenever a
value can take any numeric expression,
it is written as "_value_", and
whenever you can use a string it is
written as "*text*".


Expressions
===========

Expressions are used to perform
calculations in the language.

There are numeric expressions (integer
and floating point), boolean
expressions, and string expressions.

In FastBasic, standard numeric
expressions are evaluated as integers
from -32768 to 32767, this is called 16
bit signed integer values.

Floating point expressions are used
*only* if numbers have a decimal point.
Floating point numbers are stored with
standard Atari binary-coded decimal
(BCD) representation, with a range from
1E-98 to 1E+98.

Boolean expressions are "true" or
"false", represented as the numbers 1
and 0, respectively.

String expressions contain arbitrary
text. In FastBasic strings can have up
to 255 characters of length. (This is
similar to Microsoft BASICs found on
other 8-bit microcomputers, and in
contrast to the 32K limit found in
Atari BASIC and TurboBASIC XL.)


Numeric Values
--------------

Integer values can be written as decimal
numbers (like `123`, `1000`, etc.), as
hexadecimal numbers with a $ sign
before (like `$1C0`, `$A00`, etc.) or
by using the name of a variable.

Floating point values are written with
a decimal dot and an optional exponent
(like `3.14159`, `-3.2`, or `1.0E+10`).


Numeric Variables
-----------------

Variable names must begin with a letter
or the symbol `_`, and can contain any
letter, number or the symbol `_`.
Examples of valid integer variable names
are `COUNTER`, `My_Var`, `num1`.

Floating point variables have an `%` as
last character in the name.  Examples of
valid floating point variable names are
`MyNum%`, `x1%`.

In FastBasic, variables can't be used
in an expression before being assigned
a value; the first assignment declares
the new variable.


Numeric Operators
-----------------

There are various "operators" that
perform calculations in expressions. The
operators with higher precedence always
executed first.

The order of precedence for *integer*
operators are:

- `+` `-`      : addition, subtraction,
                 from left to right.
- `*` `/` `MOD`: multiplication,
                 division, modulus,
                 from left to right.
- `&` `!` `EXOR`: binary 'and', 'or',
                  'exclusive or',
                  from left to right.
- `+` `-`      : positive / negative.

For example, an expression like:
`1 + 2 * 3 - 4 * -5` is evaluated in
the following order:

- First, the unary `-` before the `5`,
  giving the number `-5`.
- The first multiplication, giving
  `2*3` = `6`.
- The second multiplication, giving
  `4*-5` = `-20`.
- The addition, giving `1+6` = `7`.
- The subtraction, giving `7 - -20` =
  `27`.

So, in this example the result is 27.

If there is a need to alter the
precedence, you can place expressions
within parenthesis (e.g., "`(2+5)*10`",
which results in `70`).

Note that `MOD` and `EXOR` can be
abbreviated `M.` and `E.` respectively.

When using floating point expressions,
the operators are:

- `+` `-` : addition, subtraction, from
            left to right.
- `*` `/` : multiplication, division,
            from left to right.
- `^`     : exponentiation, from left
            to right.
- `+` `-` : positive / negative.

Note that integer expressions are
automatically converted to floating
point if needed, as this allows mixing
integers and floating point in some
calculations, but you must take care to
force floating point calculations to
avoid integer overflows.

Example: the expression -

    a% = 1000 * 1000 + 1.2

gives correct result as 1000 is
converted to floating point before
calculation, but:

    x=1000: a% = x * x + 1.2

gives incorrect results as the
multiplication result is bigger than
32767.

Note that after any floating point
errors (division by 0 and overflow),
`ERR()` returns 3.


Boolean Operators
-----------------

Boolean operators return a "true" or
"false" value instead of a numeric
value, useful as conditions in loops
and `IF` statements.

Note that any boolean value can also be
used as a numeric value, in this case,
"true" is converted to 1 and "false"
converted to 0.

The supported boolean operators, in
order of precedence, are:

- `OR`   : Logical OR, true if one or
           both operands are true.
- `AND`  : Logical AND, true only if
           both operands are true.
- `NOT`  : Logical NOT, true only if
           operand is false.
- `<=` `>=` `<>` `<` `>` `=`
  For integer or floating point
  comparisons, compare the two numbers
  and return true or false.  Note that
  `<>` is _not equal_.
  You can only compare two values of
  the same type, so an expression like
  `x = 1.2` is invalid, but `1.2 = x`
  is valid as the second operand is
  converted to floating point before
  comparison.

The words `OR`, `AND` and `NOT` can be
abbreviated `O.`, `A.` and `N.`


Arrays
------

Arrays hold many ordered values (called
elements). The array elements can be
accessed by an index.

In FastBasic, arrays must be
dimensioned before use (see `DIM`
statement below). The index of the
element is written between parentheses
and goes from 0 to the number of
elements. Note that FastBasic does not
check for out of boundary accesses, so
you must be careful with your code to
not overrun the size of the arrays.

You can use an array position (the
variable name followed by the index) in
any location where a standard numeric
variable or value is expected.

Arrays can be of four types:

- `WORD` arrays (the default if no type
  is given) use two bytes of memory for
  each element, and works like normal
  numeric integer variables:
  -32768 to 32767 (signed).
- `BYTE` arrays use only one byte for
  each element, so the numeric range
  is reduced from 0 to 255 (unsigned).
- Floating point arrays, works like any
  floating point variable, and use six
  bytes of memory for each element.
- String arrays store a string in each
  element. String arrays use two bytes
  of memory for each element that is
  not yet assigned (containing empty
  strings), and 258 bytes for each
  element with a string assigned.


String Values
-------------

String values are written as a text
surrounded by double quotes (`"`). If
you need to include a double quote
character in a string, you must write
two double quotes together.

Example:

    PRINT "Hello ""world"""

Will print:

    Hello "world"

You can also include any character with
it's hexadecimal code using `$` just
after the closing quote, with no spaces
around. This is the only way to include
an ENTER character inside a string
constant, see this example:

    PRINT "Hello"$9B"world"$2E$2E

Will print:

    Hello
    world..


The bracket operator `[` `]` allows
creating a string from a portion of
another, and accepts two forms:

 - [ _start_ ]
   This form selects all characters
   from _start_ up to the end of the
   string, counting from 1.
   So, `A$[1]` selects the entire
   string, while `A$[3]` selects from
   the third character to the end,
   effectively removing the two leftmost
   characters.

 - [ _start_ , _len_ ]
   This form selects at most _len_
   characters from _start_, or up to the
   end of the string if there is not
   enough characters.

Example:

    PRINT "Hello World"[7]
    A$ = STR$(3.1415)[3,3]
    ? A$
    ? A$[2,1]

Will print:

    World
    141
    4

Note that the bracket operator creates
a new string and copies the characters
from the original string to the new
one. As the same buffer is always used
for the new string, you can't compare
two values without first assigning one
of them to a new string variable.

This will print "ERROR":

    A$="Don't Work"
    IF A$[2,2] = A$[3,3] THEN ? "ERROR"

while this will print "GOOD"

    A$="Long string"
    B$=A$[2,2]
    IF B$ <> A$[3,3] THEN ? "GOOD"



String Variables
----------------

The naming convention for string
variables is the same as for numeric
variables, but must end with a `$`
symbol.  Examples of valid string
variable names are `Text$`, `NAME1$`.

String variables always use 256 bytes,
the first byte storing the string length
and the following bytes storing up to
255 ATASCII characters.

There are two types of string
assignments:

 - The standard `=` sign copies the
   string expression in the right to
   the variable in the left.

 - The `=+` sign copies the string
   expression at the right to the end
   of the current string, concatenating
   the text.

Example:

    A$ = "Hello "
    A$ =+ "World"
    ? A$

Will print:

    Hello World


Functions
---------

Functions take parameters (normally
between parentheses) and return a
result. Functions can be abbreviated by
using a shorter name ended in a dot,
for example you can write `R.(10)`
instead of `RAND(10)`.

You can also omit parentheses on
functions that take only one argument,
for example, `RAND 10`.

Note: This is not possible when the
function accepts a variable number of
arguments (as with `USR`), or with the
`ADR` function.

Some functions don't take parameters,
and you must provide a set of
parentheses, like `KEY()`.
However, when abbreviated, you can omit
the parenthesis, like `K.` for `KEY()`.


Standard Functions
------------------

Following is a list of all the general
purpose functions supported by
FastBasic. Shown are the full syntax
and the abbreviated syntax.

- TIME / T. :
  Returns the current time in
  "jiffies." This is about 60 times per
  second in NTSC systems or 50 times
  per second in PAL systems. Use
  `TIMER` statement to reset to 0.
  Remember that this function returns
  an integer, so the maximum value is
  32767, or about 9 minutes in NTSC, and
  a little less than 11 minutes in PAL,
  after this the value will become
  negative. If you need to measure more
  than this amount, consider using the
  floating-point version `%TIME`
  Note: TIME is special, and does not
  need parentheses.

- ABS(_num_) / A.(_num_) :
  Returns the absolute value of _num_
  (e.g., `ABS(5)` and `ABS(-5)` both
  result in `5`).  Can be used with
  integers and floating point.

- SGN(_num_) / SG.(_num_) ;
  Returns the sign of _num_, this is 1
  if positive, -1 if negative or 0 if
  _num_ is 0. Can be used with integers
  and floating point.

- RAND(_num_) / R.(_num_) :
  Returns a random, non negative
  number, a maximum of 1 less than
  _num_. (e.g., `RAND(3)` will result
  in 0, 1, or 2.)
  (See also `RND()`.)

- FRE() / F. :
  Returns the free memory available in
  bytes.

- ERR() / E. :
  Returns the last Input/Output error
  value, or 1 if no error was
  registered.

- LEN(*string*) / L.(*string*) :
  Returns the length of the *string*.

- VAL(*string*) / V.(*string*) :
  Converts *string* to a number. If no
  conversion is possible, `ERR()` is
  set to 18. Can be used with integers
  and floating point.

- ASC(*string*) / AS.(*string*) :
  Returns the ATASCII code of the first
  character of the *string*.


Atari Specific Functions
------------------------

The following functions allow
interacting with the Atari hardware to
read controller and keyboard input and
to program with Player/Missile
graphics.


- PADDLE(_n_) / PA.(_n_) :
  Returns the value of the PADDLE
  controller _n_.

- PMADR(_n_) / PM.(_n_) :
  Returns the address of the data for
  Player _n_ or the address of the
  Missiles with _n_ = -1.

- PTRIG(_n_) / PT.(_n_) :
  Returns 0 if the PADDLE controller
  _n_ button is pressed, 1 otherwise.

- STICK(_n_) / S.(_n_) :
  Returns the JOYSTICK controller _n_
  position. `STICK(_n_)` values are:

      `10`  `14`  ` 6`

      `11`  `15`  ` 7`

      ` 9`  `13`  ` 5`

- STRIG(_n_) / STR.(_n_) :
  Returns 0 if JOYSTICK controller _n_
  button is pressed, 1 otherwise.

- KEY() / K. :
  Returns 0 if no key was pressed, or a
  keycode. The returned value only goes
  to 0 after reading the key in the OS
  (via a `GET` or `POKE 764, 255`
  statement).

  _Hint: The value returned is actually
  the same as_ `(PEEK(764) EXOR 255)`.
  The following program will show the
  `KEY()` codes for pressed keys:

      PRINT "Press keys, exit with ESC"
      REPEAT
        REPEAT : UNTIL KEY()
        PRINT "Key code: "; KEY()
        GET K
        PRINT "ATASCI code: "; K
      UNTIL K=27


Floating Point Functions
------------------------

These functions use floating point
values, and are only available in the
floating point version.

In case of errors (such as logarithm or
square root of negative numbers and
overflow in the results), the functions
will return an invalid value, and the
`ERR()` function returns 3.


- ATN(_n_) / AT.(_n_) :
  Arc-Tangent of _n_.

- COS(_n_) / CO.(_n_) : Cosine of _n_.

- EXP(_n_) : Natural exponentiation.

- EXP10(_n_) / EX.(_n_) :
  Returns ten raised to _n_.

- INT(_num_) / I.(_num_) :
  Converts the floating point number
  _num_ to the nearest integer from
  -32768 to 32767.

- LOG(_n_) : Natural logarithm of _n_.

- LOG10(_n_) / LO.(_n_) :
  Decimal logarithm of _n_.

- RND() / RN. :
  Returns a random positive number
  strictly less than 1.
  (See also `RAND()`.)

- SIN(_n_) / SI.(_n_) : Sine of _n_.

- SQR(_n_) / SQ.(_n_) :
  Square root of _n_.

- %TIME / %T. :
  This is the same as the `TIME` integer
  function, but returning a 24 bit
  number that does not wrap until more
  than 3 days.
  Note: Don't use the  `TIMER` statement
  if you are using this function, as the
  returned value will be invalid.


String Functions
----------------

- STR$(_num_) :
  Returns a string with a printable
  value for _num_. Can be used with
  integers and floating point. Note
  that this function can't be used at
  both sides of a comparison, as the
  resulting string is overwritten each
  time it is called.

- CHR$(_num_) :
  Converts _num_ to a one character
  string with the ATASCII value.


Low level Functions
-------------------

The following functions are called "low
level" because they interact directly
with the hardware. Use with care!


- ADR(_arr_) / &_arr_ :
  Returns the address of the first
  element of _arr_ in memory.
  Following elements of the array
  occupy adjacent memory locations.
  Instead of `ADR(X)` you can simply
  type `&X`.

- ADR(_str_) / &_str_ :
  Returns the address of the _string_
  in memory.  The first memory location
  contains the length of the string,
  and following locations contain the
  string characters.  (This differs from
  Atari BASIC and TurboBASIC XL, where
  the address returned points to the
  first character of the string.)

- ADR(_var_) / &_var_ :
  Returns the address of the _variable_
  in memory.

- DPEEK(_addr_) / D.(_addr_) :
  Returns the value of memory location
  _addr_ and _addr_+1 as a 16 bit
  integer.
  This is the same as doing
  PEEK(_addr_)+PEEK(_addr_+1)*256

- PEEK(_address_) / P.(_address_) :
  Returns the value of memory location
  at _address_.

- USR(_address_[,_num1_ ...]):
  Low level function that calls the
  user supplied machine code subroutine
  at _address_.

  Parameters are pushed to the CPU
  stack, with the LOW part pushed
  first, so the first PLA returns the
  HIGH part of the last parameter, and
  so on.

  The value of the A and X registers is
  used as a return value of the
  function, with A the low part and X
  the high part.

  This is a sample usage code snippet:

      ' PLA / EOR $FF / TAX / PLA / EOR $FF / RTS
      DATA ml() byte = $68,$49,$FF,$AA,$68,$49,$FF,$60
      FOR i=0 TO 1000 STEP 100
        ? i, USR(ADR(ml),i)
      NEXT i

- $(_addr_) :
  Returns the string at memory address
  _addr_.

  This is the inverse of `ADR()`, and
  can be used to create arbitrary
  strings in memory. For example, the
  following code prints "AB":

      DATA x() byte = 2, $41, $42
      ? $( ADR(x) )

  Also, you can store string addresses
  to reuse later, using less memory
  than copying the full string:

      x = ADR("Hello")
      ? $( x )

- %(_n_) :
  This returns the floating-point
  value stored at memory address _n_.


List Of Statements
==================

In the following descriptions,
statement usage is presented and the
abbreviation is given after a /.


Console Print and Input Statements
----------------------------------

**Reads Key From Keyboard**  
**GET _var_ / GE.**

  Waits for a keypress and writes the
  key value to _var_, which can be a
  variable name or an array position
  (like "array(123)").

  Note: Some keys on the Atari -- the
  console keys `START`, `SELECT`, and
  `OPTION`; modifiers `SHIFT` and
  `CONTROL`; and the `HELP`, `BREAK`,
  and `RESET` keys -- are not handled
  in the same way as the main keyboard,
  and cannot be read by `GET`.

  Hints: The status of all three console
  keys may be read via the GTIA `CONSOL`
  register, `PEEK(53279)`.

  Whether the `HELP` key is pressed
  can be detected via the POKEY `KBCODE`
  register, `PEEK(53769)`.

  Whether either `SHIFT` key is pressed
  can be detected via the POKEY `SKCTL`
  register, `PEEK(53775)`.


**Input Variable Or String**  
**INPUT _var_ / I.**  
**INPUT "prompt"; _var_**  
**INPUT "prompt", _var_**
**INPUT ; _var_**

  Reads from keyboard/screen and stores
  the value in _var_.

  A "?" sign is printed to the screen
  before input, or the "prompt" if
  given.  Also, if there is a comma
  after the prompt, spaces are printed
  to align to a column multiple of 10
  (similar to how a comma works in
  `PRINT`).  In the case you don't want
  any prompt, you can use a semicolon
  alone.

  If the value can't be read because
  input errors, the error is stored in
  ERR variable. Valid errors are 128 if
  BREAK key is pressed and 136 if
  CONTROL-3 is pressed.

  In case of a numeric variable, if the
  value can't be converted to a number,
  the value 18 is stored in ERR().

  See the _Device Input and Output
  Statements_ section for the `INPUT #`
  usage.


**Moves The Screen Cursor**  
**POSITION _column_, _row_ / POS.**

  Moves the screen cursor position to
  the given _column_ and _row_, so the
  next PRINT statement outputs at that
  position.

  Rows and columns are numerated from
  0.


**Print Strings And Numbers**  
**PRINT _expr_, ... / ?**  
**PRINT _expr_ TAB(_expr_) ...**  
**PRINT RTAB(_expr_) ...**  
**PRINT COLOR(_expr_) ...**  
**PRINT _expr_ ; ...**  

  Outputs strings and numbers to the
  screen or other output device.

  Each _expr_ can be a constant string,
  a string variable or any complex
  expression, with commas or semicolons
  between each expression.

  If the first expression is a device
  I/O channel (e.g., `PRINT #1,"HELLO"`)
  the output will be sent to that
  device.  In `GRAPHICS` modes other
  than 0 (e.g., large text `GRAPHICS 2`,
  multicolor text `GRAPHICS 12`, or even
  bitmapped graphics modes), use `#6` to
  write to that part of the screen.

  After writing the last expression,
  the cursor advanced to a new line,
  except if the statement ends in a
  comma, semicolon or `TAB`, where the
  cursor stays in the last position.

  If there is a comma before any
  expression, spaces are printed to
  advance the printing column to the
  next multiple of 10, allowing easy
  printing of tabulated data.

  The `COLOR` function alters the color
  the text that follows, until the end
  of the statement, depending on the
  graphics mode. This is abbreviated
  `C.`.  Use 0 or 128 in graphics 0, for
  normal or inverse video.  Use 0, 32,
  128 or 160 in graphics mode 1 and 2
  for the four available text colors,
  see the two examples below:

      ' In GRAPHICS 0:
      ? "NORMAL"; COLOR(128) "INVERSE"

      ' In GRAPHICS 2:
      S = 1234
      ? #6, "SCORE: "; COLOR(32) S

  The `TAB` function advances the
  position to a column multiple of the
  argument, so that `TAB(10)` is the
  same as using a comma to separate
  arguments. This is abbreviated `T.`.

  The `RTAB` function, abbreviated
  `RT.`, advances the position so that
  the next argument to print ends just
  before a column multiple of the
  argument, right aligning the printing
  of the data. This function must be
  immediately followed by a variable or
  a string to align.

  Note that `,`, `TAB` and `RTAB`
  always print at least one space, and
  that to separate `TAB` or `RTAB` and
  the previous and next arguments you
  can use a `;` or simply a space.

  See the _Device Input and Output
  Statements_ section for the `PRINT #`
  usage.

  This example shows the usage of `TAB`
  and `RTAB`, note that the columns
  will be left and right aligned
  respectively:

      FOR i=0 TO 10
        n = i*(9-2*i)*134
        ? TAB(8) "Val:" RTAB(20) n
      NEXT

   The output is:

      Val:0         0
      Val:1       938
      Val:2      1340
      Val:3      1206
      Val:4       536
      Val:5      -670
      Val:6     -2412
      Val:7     -4690
      Val:8     -7504
      Val:9    -10854
      Val:10   -14740

  *Advanced:* To implement the spacing
  on `,`, `TAB` and `RTAB`, FastBasic
  uses the current column in the OS, so
  that `POSITION` and printing to a
  graphics screen will work ok, unlike
  Atari BASIC; but when printing to a
  file or other devices the number of
  spaces will not be correct. Avoid
  using the functions to print to any
  device except the screen.

  *Advanced:* The `COLOR` function does
  an *exclusive or* of the given value
  with the value of each character in
  the original string before printing.

  *Advanced:* When writing abbreviated
  code, you can omit the semicolon in
  almost all places, and just join the
  values together. Avoid doing this in
  common code for better readability.


**Writes A Character To Screen**  
**PUT _num_ / PU.**

  Outputs one character to the screen,
  given by it's ATASCII code.


**Clears The Screen**  
**CLS**

  Clears the text screen. This is the
  same as `PUT 125`.
  For clearing the graphics screen, you
  can use `CLS #6`.


Control Statements
------------------

**Endless Loops**  
**DO**    
**LOOP / L.**

  Starts and ends an endless
  repetition. When reaching the LOOP
  statement the program begins again, 
  executing from the DO statement.

  The only way to terminate the loop is
  via an EXIT statement.


**Calls A Subroutine**  
**EXEC _name_ _num1_, ... / EXE. / @ **

  Calls the subroutine _name_, with the
  optional parameters _num1_ and so on,
  separated by commas.

  Note that the subroutine must be
  defined with PROC with the same number
  of parameters, but can be defined
  before or after the call.

  Instead of `EXEC` you can simply use
  a `@` in front of the procedure name.
  (i.e., these are equivalent:
  `EXEC GAMEOVER` and `@GAMEOVER`.)


**Exits From Loop Or PROC**  
**EXIT / EX.**

  Exits current loop or subroutine by
  jumping to the end.

  In case of loops, the program
  continues after the last statement of
  the loop. In case of PROC, the
  program returns to the calling EXEC.


**Loop Over Values Of A Variable**  
**FOR _var_=_value_ TO _end_ [STEP _step_] / F. T. S.**  
**NEXT _var_ / N.**

  FOR loop allows performing a loop a
  specified number of times while
  keeping a counting variable.

  First assigns the _value_ to _var_,
  and starts iterations. _var_ can be
  any variable name or a word array
  position (like "array(2)").

  In each iteration, the command first
  compares the value of _var_ with
  _end_, if the value is past the end
  it terminates the loop.

  At the end of the loop, _var_ is
  incremented by _step_ (or 1 if STEP
  is omitted) and the loops repeats.

  An EXIT statement also terminates the
  loop and skips to the end.

  Note that if _step_ is positive, the
  iteration ends when the value of
  _var_ is bigger than _end_, but if
  _step_ is negative, the iteration
  ends if value of _var_ is less than
  _end_.

  Also, _end_ and _step_ are evaluated
  only once at beginning of the loop;
  that value is stored and used for all
  loop iterations.

  If at the start of the loop _value_
  is already past _end_, the loop is
  completely skipped.

  A slightly modified usage of the
  FOR/NEXT loop allows for excluding
  the variable name from NEXT; this
  is required if _var_ is an array.

  This is an example of NEXT without
  variable:

      ' sample of FOR/NEXT loop without
      ' NEXT variable name
      FOR i=0 to 1000 step 100
        ? i
      NEXT


**Conditional Execution**  
**IF _condition_ THEN _statement_ / I. T.**  
**IF _condition_**  
**ELIF _condition_ / ELI.**  
**ELSE / EL.**  
**ENDIF / E.**

  The first form (with THEN) executes
  one _statement_ if the condition is
  true.

  This differs from Atari BASIC,
  TurboBASIC XL, and others, which will
  execute all statements after THEN until
  the end of the line.  For example:

      A=1
      IF A=0 THEN ? "ZERO":? "THE END"

  Results in "THE END" being printed in
  FastBasic, whereas nothing would be
  printed in Atari BASIC.

  The second form executes all
  statements following the IF (up until
  an ELIF, ELSE, or ENDIF) only if
  condition is true.

  If the condition is false, optional
  statements following the ELSE (until
  an ENDIF) are executed.

  In case of an ELIF, the new condition
  is tested and acts like a nested IF
  until an ELSE or ENDIF.

  This is an example of a multiple
  IF/ELIF/ELSE/ENDIF statement:

    IF _condition-1_
      ' Statements executed if
      ' _condition-1_ is true
    ELIF _condition-2_
      ' Statements executed if
      ' _condition-1_ is false but
      ' _condition-2_ is true
    ELIF _condition-3_
      ' Also, if _condition-1_ and
      ' _condition-2_ are false but
      ' _condition-3_ is true
    ELSE
      ' Executed if all of the above
      ' conditions are false
    ENDIF


**Define A Subroutine.**  
**PROC _name_ _var1_ .../ PR.**  
**ENDPROC / ENDP.**

  PROC statement starts the definition
  of a subroutine that can be called
  via EXEC or `@`.

  You can pass a list of integer
  variables separated by spaces after
  the PROC name to specify a number of
  parameters, the variables will be set
  to the values passed by the EXEC call.
  Those variable names are always
  global, so the values set are seen
  outside the PROC.

  The number of parameters in the PROC
  definition and in all the EXEC calls
  must be the same.

  Note that if the PROC statement is
  encountered while executing
  surrounding code, the full subroutine
  is skipped, so PROC / ENDPROC can
  appear any place in the program.


**Loop Until Condition Is True**  
**REPEAT / R.**  
**UNTIL _condition_ / U.**

  The REPEAT loop allows looping with a
  condition evaluated at the end of
  each iteration.

  Executes statements between REPEAT
  and UNTIL once, then evaluates the
  _condition_. If false, the loop is
  executed again, if true the loop
  ends.

  An EXIT statement also terminates the
  loop and skips to the end.

**Loop while condition is true**  
**WHILE _condition_ / W.**  
**WEND / WE.**

  The `WHILE` loop allows looping with
  a condition evaluated at the
  beginning of each iteration.

  Firstly it evaluates the condition.
  If false, it skips the whole loop to
  the end. If true, it executes the
  statements between `WHILE` and `WEND`
  and returns to the top to test the
  condition again.

  An EXIT statement also terminates the
  loop and skips to the end.


Graphic and Sound Statements
----------------------------

**Set Color Number**  
**COLOR _num_ / C.**

  Changes the color of `PLOT`, `DRAWTO`
  and the line color on `FILLTO` to
  _num_.

**Draws A Line**  
**DRAWTO _x_, _y_ / DR.**

  Draws a line from the last position
  to the given _x_ and _y_ positions.

**Sets Fill Color Number**  
**FCOLOR _num_ & FC.**

  Changes the filling color of `FILLTO`
  operation to _num_.

**Fill From Line To The Right**  
**FILLTO _x_, _y_ / FI.**

  Draws a line from the last position
  to the given _x_ and _y_ position
  using `COLOR` number. For each
  plotted point it also paints all
  points to the right with the `FCOLOR`
  number, until a point with different
  color than the first is reached.

**Sets Graphic Mode**  
**GRAPHICS _num_ / G.**

  Sets the graphics mode for graphics
  operations. Below is a basic chart of
  GRAPHICS modes, their full screen
  resolution and number of available
  colors.[^1]

Text modes[^2][^3][^4]:

|Mode   | Resolution | # Of Colors  |
|------ | ---------- | ------------ |
|GR. 0  | 40x24      |        2     |
|GR. 1  | 20x24      |        5     |
|GR. 2  | 20x12      |        5     |
|GR. 12 | 40x24      |        5     |
|GR. 13 | 40x12      |        5     |

Bitmapped graphics modes:[^5]

|Mode   | Resolution | # Of Colors   |
|------ | ---------- | ------------- |
|GR. 3  | 40x24      |        4      |
|GR. 4  | 80x48      |        2      |
|GR. 5  | 80x48      |        4      |
|GR. 6  | 160x96     |        2      |
|GR. 7  | 160x96     |        4      |
|GR. 8  | 320x192    |        2      |
|GR. 9  | 80x192     |   16 shades   |
|GR. 10 | 80x192     |        9      |
|GR. 11 | 80x192     |     16 hues   |
|GR. 14 | 160x192    |        2      |
|GR. 15 | 160x192    |        4      |

[^1]: `GRAPHICS 0` and `GRAPHICS 8`
offer two colors, where the "on"
pixels may be a different shade
(luminence) of the background color's
hue, but cannot have its own hue.
(Television color artifacting effects
can be utilized to simulate two
additional colors.) Use
`SETCOLOR 2,H,L1` and `SETCOLOR 1,0,L2`
(or `POKE 710,H*16+L1` & `POKE 709,L2`).

[^2]: Mode 0 (and the text window found
at the bottom of most other modes) can
render 128 different characters (from
a character set, aka font) in both
normal video, and inverse video, based
on whether the high bit of the character
is set. See `PRINT COLOR()`.

[^3]: Modes 1 and 2 are text modes that
offer multiple colors, but only a single
color (plus the background) may be used
by any given character cell.  The colors
are chosen by the two high bits of the
character.  This means only half of
a character set (font) -- 64 shapes --
may normally be used.  See
`PRINT COLOR()`.

[^4]: Modes 12 and 13 are mutlicolor
text modes, where every pair of
two bits in a character's bitmap data
are used to represent one of four
colors.  As with mode 0, 128 characters
may be used.  However, when the high bit
is set (which produces an inverse-video
effect in mode 0), the effect in these
modes is to change which color palette
register is used for the fourth color
(pixels comprised of `11` bits); instead
of `SETCOLOR 2` (aka `POKE 710`), the
color from `SETCOLOR 3` (aka `POKE 711`)
will be used.  See `PRINT COLOR()`.

[^5]: The so-called "GTIA modes" -- 9,
10, and 11 -- offer 16 shades of the
given background color (use
`SETCOLOR 4,H,0` or `POKE 712,H*16`),
all nine color registers
(`SECTOLOR N,H,L` or
`POKE 704+N,H*16+L`), or 15 hues of a
particular brightness (the background
remains darkest; use `SETCOLOR 4,0,L`),
respectively.

  For graphics modes which include a
  4-line `GRAPHICS 0` style text window
  at the bottom (all but 0, 9, 10, and
  11), add 16 to the mode number to
  disable the text window. (e.g.,
  `GRAPHICS 2+16`)

  Add 32 to the mode number to prevent
  the graphics data from being cleared.
  (Note: Some graphics data may be
  replaced when changing modes.)

  *Advanced:* The Atari OS `S:` screen
  device dictate which `GRAPHICS`
  modes are available.  However (as
  demonstrated by the text window), the
  Atari can mix graphics modes via use
  of Display Lists.  The ANTIC graphic
  chip uses a different set of values
  to reflect the different graphics
  modes (and modes 9, 10 and 11 utilize
  a feature managed by the GTIA chip),
  as well as other features (blank
  scanlines, fine scrolling, Display
  List Interrupts, etc.) Consult
  _De Re Atari_ chapter 2, "ANTIC and
  the Display List" for more details.

**Get color of pixel**  
**LOCATE _x_, _y_, _var_ / LOC.**

  Reads the color of pixel in the
  specified _x_ and _y_ coordinates and
  store into variable _var_.


**Plots A Single Point**  
**PLOT _x_, _y_ / PL.**

  Plots a point in the specified _x_
  and _y_ coordinates, with the current
  `COLOR` number.

**Player/Missile Graphics Mode**  
**PMGRAPHICS _num_ / PMG.**

  Set up Atari Player / Missile
  graphics.  A value of 0 disables all
  player and missiles; a value of 1
  sets up single line resolution; a
  value of 2 sets up double line
  resolution.

  Single line mode uses 256 bytes per
  player, while double line uses 128
  bytes per player.  (Note that all
  four missiles share the same data.)

  For retrieving the memory address of
  the player or missile data use the
  `PMADR()` function.

**Player/Missile Horizontal Move**  
**PMHPOS _num_,_pos_ / PM.**

  Set the horizontal position register
  for the player or missile _num_ to
  _pos_.

  Players 0 to 3 correspond to values 0
  to 3 of _num_; missiles 0 to 3
  correspond to the values 4 to 7,
  respectively.

  This is the same as writing:
  `POKE $D000 + num , pos`

  Note: Player/Missile graphics on the
  Atari are strips that are as tall
  as the screen, and therefore to move
  a shape vertically its data must be
  moved within their 128- or 256-byte
  buffer (using the `MOVE` statement,
  for example).

**Sets Displayed Color**  
**SETCOLOR _num_, _hue_, _lum_ / SE.**

  Alters the color registers so that
  color number _num_ has the given
  _hue_ and _luminance_.

  To set Player/Missile colors use
  negative values of _num_, -4 for
  player 0, -3 for player 1, -2 for
  player 2, and -1 for player 3.

  Missiles share the same color as
  their player, unless you combine
  them into a "5th Player" by setting
  bit number 4 of the `GPRIOR`
  register, e.g.: `POKE 623,16`. (You
  must also move them horizontally in
  unison if you wish to use them as a
  true 5th Player.)

  It is possible to cause pixels of
  certain overlapping players to
  produce a third color (or black)
  by setting bit number 5 of the
  `GPRIOR` register, e.g.
  `POKE 623,32`.

  Consult the `GPRIOR` section of
  _Mapping the Atari_ for more details.

**Adjust Voice Sound Parameters**  
**SOUND _voice_, _pitch_, _dist_, _vol_ / S.**  
**SOUND _voice_**  
**SOUND**

  Adjusts sound parameters for _voice_
  (from 0 to 3) of the given _pitch_,
  _distortion_ and _volume_.

  If only the _voice_ parameter is
  present, that voice is cleared so no
  sound is produced by that voice.

  If no parameters are given, it clears
  all voices so that no sounds are
  produced.

  Note: TurboBASIC XL offers a
  `DSOUND` statement to pair sound
  channels for increased (16-bit)
  frequency range.  This is not
  available in FastBasic.


Device Input and Output Statements
----------------------------------

**Binary read from file**  
**BGET #_iochn_,_address_,_len_ / BG.**

  Reads _length_ bytes from the channel
  _iochn_ and writes the bytes to
  _address_.

  For example, to read to a byte array,
  use `ADR(array)` to specify the
  address.

  On any error, `ERR()` will hold an
  error code, on success `ERR()` reads
  1.

**Binary Read From File**  
**BPUT #_iochn_,_address_,_len_ / BP.**

  Similar to `BPUT`, but writes
  _length_ bytes from memory at
  _address_ to the channel _iochn_.

  On any error, `ERR()` will hold an
  error code, on success `ERR()` reads
  1.

**Close Channel**  
**CLOSE #_iochn_  / CL.**

  Closes the input output channel
  _iochn_, finalizing all read/write
  operations.

  On any error, `ERR()` will hold an
  error code, on success `ERR()` reads
  1.

  Note that it is important to read the
  value of `ERR()` after close to
  ensure that written data is really on
  disk.

**Reads bytes from file**  
**GET #_iochn_, _var_, ...**

  Reads one byte from channel _iochn_
  and writes the value to _var_.

  _var_ can be a variable name or an
  array position (like `array(123)`)

  In case of any error, `ERR()` returns
  the error value.

**Input Variable Or String From File**  
**INPUT #_iochn_, _var_ / IN.**

  Reads a line from channel _iochn_ and
  stores to _var_.

  If _var_ is a string variable, the
  full line is stored.

  If _var_ is a numeric variable, the
  line is converted to a number first.

  On any error, `ERR()` will hold an
  error code, on success `ERR()` reads
  1.

**Opens I/O Channel**  
**OPEN #_ioc_,_mode_,_ax_,*dev* / O.**

  Opens I/O channel _ioc_ with _mode_,
  _aux_, over device *dev*.

  To open a disk file for writing,
  _mode_ should be 8, _aux_ 0 and *dev*
  the file name as "D:name.ext".

  To open a disk file for reading,
  _mode_ should be 4, _aux_ 0 and *dev*
  the file name as "D:name.ext".

  See Atari BASIC manual for more
  documentation in the open modes, aux
  values, and device names.

  On any error, `ERR()` will hold an
  error code, on success `ERR()` reads
  1.

**Print Strings And Numbers To A File**  
**PRINT #_iochn_, ... / ?**

  Uses the same rules as the normal
  print, but all the output is to the
  channel _iochn_.  Note that you must
  put a comma after the channel number,
  not a semicolon.

  On any error, ERR() will hold an
  error code, on success ERR() reads 1.

  Note that you can only read the error
  for the last element printed.

**Outputs One Byte To The File**  
**PUT #_iochn_, _num_ / PU.**

  Outputs one byte _num_ to the channel
  _iochn_.

  On any error, ERR() will hold an
  error code, on success ERR() reads 1.


**Generic I/O Operation**  
**XIO #_iochn_, _cmd_, _aux1_, _aux2_, *dev* / X.**

  Performs a general input/output
  operation on device *dev*, over
  channel _ioc_, with the command _cmd_
  ,and auxiliary bytes _aux1_ and
  _aux2_.

  Note that the arguments of XIO
  statements are in different order
  than Atari BASIC, for consistency
  with other statements the _iochn_ is
  the first argument.

  Example: to delete the file
  "FILE.TXT" from disk, you can do:

      XIO #1, 33, 0, 0, "D:FILE.TXT"


General Statements
------------------

**Line comments**  
**' / .**

  Any line starting with a dot or an
  apostrophe will be ignored. This is
  analogous to REM in Atari BASIC.


**Clears variables and free memory**  
**CLR**

  Clears all integer and floating-point
  variables to 0, all strings to empty
  strings and frees all memory
  associated with arrays.

  After `CLR` you can't access arrays
  without allocating again with `DIM`.


**Defines array with initial values**  
**DATA _arr()_ [type] = n1,n2, / DA.**

  This statement defines an array of
  fixed length with the values given.

  The array name should not be used
  before, and type can be `BYTE`
  (abbreviated `B.`) or `WORD`
  (abbreviated `W.`). If no type is
  given, a word data is assumed.

  If you end the `DATA` statement with
  a comma, the following line must be
  another `DATA` statement without the
  array name, and so on until the last
  line.

  Example:

      DATA big() byte = $12,$23,$45,
      DATA       byte = $08,$09,$15

  Note that the array can be modified
  afterwards like a normal array.


  *Advanced Usage*

  Byte DATA arrays can be used to
  include assembler routines (to call
  via `USR`, see the example above),
  display lists and any other type of
  binary data.

  To facilitate this, you can include
  constant strings and the address of
  other byte DATA array by name.

  All the bytes of the string, including
  the initial length byte are included
  into the DATA array.

  Example:

      DATA str() B. = "Hello", "World"
      X = ADR(str)
      ? $(X), $(X+6)
      DATA ad() B. = $AD,str,$A2,0,$60
      ? USR(ADR(ad)), str(0)


  *Loading data from a file*

  The cross-compiler also supports
  loading data from a file directly into
  the program, using the `BYTEFILE`
  (abbreviated `BYTEF.`) and `WORDFILE`
  (abbreviated `WORDF.` or simply `F.`)
  types and a file name enclosed in
  double quotes.

  Example:

      DATA img() bytefile "img.raw"
      DATA pos() wordfile "pos.bin"

  The compiler will search the file in
  the same folder than the current
  basic source.

  *Storing data into ROM*

  In addition to the above, the cross
  compiler allows to specify that the
  data should be stored in ROM, instead
  of the default in RAM. This means
  that the data can't be modified in
  targets that use ROM (cartridges),
  but will lower RAM usage.

  To specify this, simply add the `ROM`
  word after the type:

      DATA img() ROM 1234,5678
      DATA pos() BYTE ROM 1,2,3,4


**Decrements variable by 1**  
**DEC _var_ / DE.**

  Decrements the variable by 1; this is
  equivalent to "_var_ = _var_ - 1",
  but faster.

  _var_ can be any integer variable or
  integer array element.


**Allocate an Array / Define Var**  
**DIM _arr_(_size_) [type], .../ DI.**  
**DIM _var_, _var$_, _var%_ ...**

  The `DIM` statement allows defining
  arrays of specified length, and
  declaring variables explicitly,
  without assigning a value.

  The type must be `BYTE` (abbreviated
  `B.`) to define a byte array, with
  numbers from 0 to 255, or `WORD` (can
  be left out) to define an array with
  integers from -32768 to 32767.

  If the name _arr_ ends with a `$` or
  a '%' symbol, this defines a string
  array or floating point array
  respectively, in this case you can't
  specify a type.

  The size of the array is the number
  of elements plus one, the elements
  are numerated from 0, so that an
  array dimensioned to 10 holds 11
  values, from 0 to 10.

  The array is cleared after the `DIM`,
  so all elements are 0 or an empty
  string.

  In the second form, the variables
  given in the list are defined with
  the correct type, without giving a
  default value. The variables can
  be defined multiple times without
  an error if the types are always
  the same.

  You can `DIM` more than one array or
  variable by separating the names
  with commas.

  Example:

      DIM A(10), X, T$
      ? A(5), X


**Ends Program**  
**END : Ends program.**

  Terminates current program. END is
  only valid at end of input.


**Increments Variable By 1**  
**INC _var_**

  Increments the variable by 1, this is
  equivalent to "_var_ = _var_ + 1",
  but faster.

  _var_ can be any integer variable or
  integer array element.


**Pauses Execution**  
**PAUSE _num_ / PA.**
**PAUSE**

  Stops the current execution for the
  specified amount of time.

  _num_ is the time to pause in
  "jiffies", this is the number of TV
  scans in the system; 60 per second in
  NTSC or 50 per second in PAL.

  Omitting _num_ is the same as giving
  a value of 0, and pauses until the
  vertical retrace. This is useful for
  synchronization to the TV refresh and
  for fluid animation.

**Resets internal timer**  
**TIMER/ T.**

  Resets value returned by `TIME`
  function to 0.


Floating Point Statements
-------------------------

Those statements are only available in
the floating point version.


**Sets "degrees" mode**  
**DEG**

  Makes all trigonometric functions
  operate in degrees, so that 360 is
  the full circle.


**Sets "radians" mode**  
**RAD**

  Makes all trigonometric functions
  operate in radians, so that 2pi is
  the full circle.

  This mode is the default on startup.


Low Level Statements
--------------------

These are statements that directly
modify memory. Use with care!


**Writes a 16bit number to memory**  
**DPOKE _address_, _value_ / D.**

  Writes the _value_ to the memory
  location at _address_ and
  _address+1_, using standard CPU order
  (low byte first).


**Copies Bytes In Memory**  
**MOVE _from_, _to_, _length_ / M.**  
**-MOVE _from_, _to_, _length_ / -.**  

  Copies _length_ bytes in memory at
  address _from_ to address _to_.

  The `MOVE` version copies from the
  lower address to the upper address;
  the `-MOVE` version copies from upper
  address to lower address.

  The difference between the two MOVE
  statements is in case the memory
  ranges overlap; if _from_ is lower in
  memory than _to_, you need to use
  `-MOVE`, else you need to use `MOVE`,
  otherwise the result will not be a
  copy.

  `MOVE a, b, c` is equivalent to:

      FOR I=0 to c-1
        POKE b+I, PEEK(a+I)
      NEXT I

  but `-MOVE a, b, c` is instead:

      FOR I=c-1 to 0 STEP -1
        POKE b+I, PEEK(a+I)
      NEXT I


**Sets Memory To A Value**  
**MSET _address_, _length_, _value_ / MS.**  

  Writes _length_ bytes in memory at
  given _address_ with _value_.

  This is useful to clear graphics
  or P/M data, or simply to set an
  string to a repeated value.

  `MSET a, b, c` is equivalent to:

      FOR I=0 to b-1
        POKE a+I, c
      NEXT I


**Writes A Byte To Memory**  
**POKE _address_, _value_ / P.**

  Writes the _value_ (modulo 256) to
  the memory location at _address_.


Display List Interrupts
-----------------------

*Note: This is an advanced topic.*

Display list interrupts (normally called
`DLI`) are a way to modify display
registers at certain vertical positions
on the screen.

You can use them to:

- Display more colors in the image, by
  changing color registers - registers
  from $D012 to $D01A.

- Split one Player/Missile graphics to
  different horizontal positions -
  registers from $D000 to D007.

- Change scrolling position, screen
  width, P/M width, etc.

FastBasic allows you to specify one or
more DLI routines, activate one or
deactivate all DLI by using the `DLI`
statement:


**Define a new DLI**  
**DLI SET _name_ = _op1_, _op2_, ... / DLIS.**

  Setups a new DLI with the given name
  and performing the _op_ operations.

  Each operation is of the form:
  _data_ `INTO` _address_ or
  _data_ `WSYNC` `INTO` _address_.

  _data_ is one constant byte or the
  name of a `DATA BYTE` array, and
  _address_ is a memory location to
  modify.

  If _data_ is a DATA array, the first
  element (at index 0) will be used at
  the first line with DLI active in the
  screen, the second element at the
  second active line, etc.

  The `WSYNC` word advances one line in
  the display area (this is done by
  writing to the `WSYNC` ANTIC
  register), so the value is set in the
  next screen line. You can put the
  `WSYNC` word multiple times to
  advance more than one line. This
  allows one DLI to modify multiple
  lines at the screen.

  Multiple `INTO` words can be used to
  write more than one register with the
  same value.

  `INTO` can be abbreviated to `I.` and
  `WSYNC` to `W.`.

  You can specify any number of
  operations, but as each one takes some
  time you could see display artifacts
  if you use too many.

  Note that by defining a DLI you are
  simply giving it a name, you need to
  activate the DLI afterwards.

  You can split a DLI definition over
  multiple lines, just like DATA by
  ending a line with a comma and
  starting the next line with `DLI =`


**Enable a DLI**  
**DLI _name_ / DL.**

  This statement enables the DLI with
  the given name, the DLI must be
  defined before in the program.

  This setups the OS DLI pointer to the
  named DLI and activates the interrupt
  bit in the display processor (the
  ANTIC chip), but does not activates on
  which lines the DLI must be called.

  To define on which lines the DLI is
  active you must modify the _Display
  List_, see the example at the end of
  the section.

  You can also pass the name of a DATA
  BYTE array with a custom machine
  language routine to the `DLI`
  statement, the routine must begin with
  a _PHA_ and end with _PLA_ and _RTI_.


**Disable a DLI**  
**DLI / DL.**

  This statement simply disables the
  DLI, returning the display to the
  original


**DLI Examples**

  This is the most basic example of a
  DLI that simply changes the background
  color at the middle of the screen:

      ' Define the DLI: set background
      ' color to $24 = dark red.
      DLI SET d1 = $24 INTO $D01A
      ' Setups screen
      GRAPHICS 0
      ' Alter the Display List, adds
      ' a DLI at line 11 on the screen
      POKE DPEEK(560) + 16, 130
      ' Activate DLI
      DLI d1
      ' Wait for any keyu
      ? "Press a Key" : GET K
      ' Disable the DLI
      DLI

  The next example shows how you can use
  a DLI to change multiple values in the
  screen:

      ' An array with color values
      DATA Colors() BYTE = $24,$46,$68
      ' Define the DLI: set background
      ' color from the Color() array
      ' and text back color with value
      ' $8A in the same line and then
      ' the black in to the next line.
      DLI SET d2 = Colors INTO $D01A,
      DLI        = $8A INTO $D018,
      DLI        = $00 WSYNC INTO $D018
      ' Setups screen
      GRAPHICS 0
      ' Adds DLI at three lines:
      POKE DPEEK(560) + 13, 130
      POKE DPEEK(560) + 16, 130
      POKE DPEEK(560) + 19, 130
      ' Activate DLI
      DLI d2
      ' Wait for any keyu
      ? "Press a Key" : GET K
      ' Disable the DLI
      DLI

  The final example shows how you can
  move multiple P/M using one DLI

      ' Player shapes, positions and colors
      DATA p1() BYTE = $E7,$81,$81,$E7
      DATA p2() BYTE = $18,$3C,$3C,$18
      DATA pos() BYTE = $40,$60,$80,$A0
      DATA c1() BYTE = $28,$88,$C8,$08
      DATA c2() BYTE = $2E,$80,$CE,$06
      ' Our DLI writes the position and
      ' colors to Player 1 and Player 2
      DLI SET d3 = pos INTO $D000 INTO $D001,
      DLI        = c1 INTO $D012, c2 INTO $D013
      GRAPHICS 0 : PMGRAPHICS 2
      ' Setup our 4 DLI and Players
      FOR I = 8 TO 20 STEP 4
        POKE DPEEK(560) + I, 130
        MOVE ADR(p1), PMADR(0)+I*4+5,4
        MOVE ADR(p2), PMADR(1)+I*4+5,4
      NEXT
      ' Activate DLI
      DLI d3
      ? "Press a Key"
      REPEAT
        PAUSE
        pos(0) = pos(0) + 2
        pos(1) = pos(1) + 1
        pos(2) = pos(2) - 1
        pos(3) = pos(3) - 2
      UNTIL KEY()
      DLI


**Some useful registers**

  This is a table of some useful
  registers to change during a DLI:

|Address| Register                  |
| ----- | ------------------------- |
| $D000 | Player 0 horizontal pos.  |
| $D001 | Player 1 horizontal pos.  |
| $D002 | Player 2 horizontal pos.  |
| $D003 | Player 3 horizontal pos.  |
| $D004 | Missile 0 horizontal pos. |
| $D005 | Missile 1 horizontal pos. |
| $D006 | Missile 2 horizontal pos. |
| $D007 | Missile 3 horizontal pos. |
| $D012 | Color of player/missile 0 |
| $D013 | Color of player/missile 1 |
| $D014 | Color of player/missile 2 |
| $D015 | Color of player/missile 3 |
| $D016 | Color register 0          |
| $D017 | Color register 1          |
| $D018 | Color register 2          |
| $D019 | Color register 3          |
| $D01A | Color of background       |

Atari SIO Statements
--------------------

The Atari Serial Input Output interface
is the low-level interface between the
Atari 8-bit computers and the serial
peripherals, like disk-drives and
modems.

**Send any command over SIO**  
**SIO _ddevic_, _dunit_, _dcomnd_, _dstats_, _dbuf_, _dtimlo_, _dbyt_, _daux1_, _daux2_**

This function can be used to send any
SIO command to any SIO device.  For
example, this command is used to read
or write one sector in a floppy disk,
or send special commands to a FujiNet
network device.

| Parameter | Description            |
| --------- | ---------------------- |
| DDEVIC    | Device # (e.g. $71)    |
| DUNIT     | Unit #                 |
| DCOMND    | Command # ($00-$FF)    |
| DSTATS    | Read($40) / Write($80) |
| DBUF      | Target buffer address  |
| DTIMLO    | Timeout value          |
| DBYT      | # of bytes in payload  |
| DAUX1     | First Aux parameter    |
| DAUX2     | Second Aux parameter   |

The meanings of each of these is
highly dependent on the target device.

**Get last SIO error function**  
**SERR() / SE.**

This function returns the value in
`DSTATS`, which contains the error of
the last SIO operation from the device.

In the context of the FujiNet device,
can be used, along with `DVSTAT+4` to
determine any error from a network
operation.


FujiNet Statements
------------------

*NOTE:* The FujiNet Statements are not
available in the integer-only version.

These are statements that talk to the
FujiNet network adapter, and can be
used to open network connections, using
any protocol supported.

Each of these statements require a
_unit_ number, of which 8 are
available, numbered 1-8.

The general flow of use is:

* `NOPEN` a connection
* In a loop
  * Check for any traffic with `NSTATUS`
  * `NGET` if needed
  * Send any traffic with `NPUT`
* When done, `NCLOSE`.

**Open a Network Connection**  
**NOPEN _unit_, _mode_, _trans_, _url_ / NO.**

  Uses `N:` _unit_ to open a connection
  to _url_ using the desired _mode_ and
  _trans_ settings.

  Example URLs might be:
  `N:HTTPS://www.gnu.org/licenses/gpl-3.0.txt`

  Common _modes_:

  - 4: READ, mapped e.g. to GET in HTTP
  - 6: DIRECTORY, e.g. PROPFIND in HTTP
  - 8: WRITE, mapped e.g. to PUT in HTTP
  - 12: READ/WRITE, e.g. for TCP
  - 13: Mapped to POST in HTTP

  Common _trans_:

  - 0: No translation of characters.
  - 1: Change CR to ATASCII EOL.
  - 2: Change LF to ATASCII EOL.
  - 3: Change CR and LF to EOL.

**Close a Network Connection**  
**NCLOSE _unit_ / NC.**

  Closes a network connection _unit_
  previously opened by `NOPEN`.

**Get Network Connection Status**  
**NSTATUS _unit_ / NS.**

  Queries the status of specified
  network _unit_. The result is stored
  in `DVSTAT` starting at `$02EA`, and
  has the format:

  | Address | Description             |
  | ------- | ----------------------- |
  |  $02EA  | # of bytes waiting (LO) |
  |  $02EB  | # of bytes waiting (HI) |
  |  $02EC  | Connected? (0 or 1)     |
  |  $02ED  | Most recent error #     |

  You can easily get the # of bytes
  waiting by doing the following:

    NSTATUS 1
    BW = DPEEK($02EA)

**Read Bytes from Network to _addr_**  
**NGET _unit_, _addr_, _len_ / NG.**

**Write bytes to Network from _addr_**  
**NPUT _unit_, _addr_, _len_ / NG.**

  These two functions are complements
  of each other, reading and writing
  _len_ bytes to and from _addr_ as
  needed.

  When reading, _len_ must be less
  than, or equal to the number of bytes
  waiting to be received, or an SIO
  error will result. Therefore, it is a
  good idea to figure out how many
  bytes are waiting using the `NSTATUS`
  command.

  Conversely, when writing, _len_ must
  be less than, or equal to the number
  of bytes in the source buffer.

  For example all of the available SIO
  commands for FujiNet Network at this
  link:
  [SIO Commands for FujiNet Devices](https://github.com/FujiNetWIFI/fujinet-platformio/wiki/SIO-Commands-for-Device-IDs-%2471-to-%2478)

