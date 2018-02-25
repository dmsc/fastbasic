# FastBasic - Fast BASIC interpreter for the Atari 8-bit computers

Introduction
============

`FastBasic` is a fast interpreter for
the BASIC language on the Atari 8-bit
computers.

One big difference from other BASIC
interpreters in the old 8-bit computers
is the lack of line numbers and the
integrated full-screen editor. This is
similar to newer programming
environments, giving the programmer a
lot of flexibility.

Another big difference is that default
variables and operations are done using
integer numbers, this is one of the
reasons that the programs run so fast.
The other reason is that the program is
parsed on run, generating optimized
code for very fast execution.

Currently, FastBasic support:
- Integer and floating point variables,
  including all standard arithmetic
  operators.
- All graphic, sound and color commands
  from Atari Basic, plus some
  extensions from Turbo Basic.
- All control flow structures from
  Atari Basic and Turbo Basic.
- Minimal string support.
- Arrays with "word" and "byte" types.
- User defined procedures.
- Compilation to binary loadable files.
- Available as a full version `FB.COM`
  and also as a smaller integer-only
  `FBI.COM`.


First Steps
===========

To run FastBasic from the included disk
image, simply type `FB` at the DOS
prompt. This will load the IDE and
present you with a little help text:

    --D:HELP.TXT-------------------0--
    '  FastBasic v3.2 -  (c) 2018 dmsc
    '
    ' Editor Help
    ' -----------
    '  Ctrl-A : Move to beg of line
    '  Ctrl-E : Move to end of line
    '  Ctrl-U : Page up
    '  Ctrl-V : Page down
    '  Ctrl-Z : Undo (only curr line)
    '  Ctrl-Q : Exit to DOS
    '  Ctrl-S : Save file
    '  Ctrl-L : Load file
    '  Ctrl-N : New file
    '  Ctrl-R : Parse and run program
    '  Ctrl-W : Compile to binary file
    '
    '- Press CONTROL-N to begin -

You are now in the integrated editor.
In the first line of the screen the
name of the currently edited file is
shown, and at the right the line of the
cursor.  Note that lines that show an
arrow pointing to the top-left are
empty lines beyond the last line of the
current file.

In this example, the cursor is in the
first column of the first line of the
file being edited.

As the help text says, just press the
`CONTROL` key and the letter `N` (at
the same time) to begin editing a new
file.  If the text was changed, the
editor asks if you want to save the
current file to disk, to skip saving
simply type `CONTROL-C`, to cancel the
New File command type `ESC`.

Now, you can start writing your BASIC
program. Try the following example,
pressing `RETURN` after each line to
advance to the next:

    INPUT "WHAT IS YOUR NAME?";NAME$
    ?
    ? "HELLO", NAME$

If you made any mistake, simply move
back using the cursor keys, this is
`CONTROL` and `-`, `=`, `+` or `*`,
then press `BACKSPACE` key and type
again.

After typing the last line, you can run
the program by pressing `CONTROL` and
`R`.

If you correctly typed your program,
the computer will ask you for your
name, type anything you want and press
`RETURN`

After this, the IDE waits for any key
press to return to the editor, so you
have a chance to see all your program
output.

If you made a mistake in the program,
instead of running the cursor will be
moved to the line and column of the
error so you can correct it and retry.

Remember to save often, pressing the
`CONTROL` and `S` keys, you need to
supply a filename. Type the name, and
press `ENTER` to save.  As with any
prompt, you can press `ESC` to cancel
the save operation.  Use the
`BACKSPACE` over the proposed file name
if you want to change it.


Compiling the program to disk
=============================

Once you are satisfied with your
program, you can compile to a disk
file, producing a program that can be
run directly from DOS.

Press the `CONTROL` and `W` key, and
type a name for your compiled program.
It is common practice to name your
compiled programs with an extension of
".COM" or ".XEX", also with ".COM"
files you don't need to type the
extension in some DOS.

Compiled programs include the full
runtime, so you can distribute them
alone without the IDE.


About the syntax
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
     name followed by `=` and a new
     value.
   - an empty line.

2. All statements and variable names
   can be lower or uppercase, the
   language is case insensitive.

3. Statements can be abbreviated to
   reduce typing, each statement have a
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

There are numeric expressions, boolean
expressions and string expressions.

In FastBasic, standard  numeric
expressions are evaluated as integers
from -32768 to 32767, this is called 16
bit signed integer values.

Floating point expressions are used
*only* if numbers have a decimal point.
Floating point numbers are stored with
standard Atari BCD representation, with
a range from 1E-98 to 1E+98.

Boolean expressions are "true" or
"false", represented as the numbers 1
and 0.

String expressions contain arbitrary
text, in FastBasic strings can have up
to 255 characters of length.


Numeric Values
--------------

Basic values can be written as decimal
numbers (like 123, 1000, etc.), as
hexadecimal numbers with a $ sign
before (like $1C0, $A00, etc.) or by
using the name of a variable.

Floating point values are written with
a decimal dot and an optional exponent
(like 1.0E+10, or -3.2)


Numeric Variables
-----------------

Variable names must begin with a letter
or the symbol _, and can contain any
letter, number or the symbol _.
Examples of valid variable names are
"COUNTER", "My_Var", "num1".

Floating point variables have an "%" as
last character in the name. Examples of
valid names are "MyNum%", "x1%".


Numeric Operators
-----------------

There are various "operators" the
perform calculation in expressions, the
operators with higher precedence always
execute first. These are the *integer*
operators in order of precedence:

- `+` `-`      : addition, subtraction,
                 from left to right.
- `*` `/` MOD  : multiplication,
                 division, modulus,
                 from left to right.
- `&` `!` EXOR : binary AND, OR and
                 EXOR, from left to
                 right.
- `+` `-`      : positive / negative.

For example, an expression like
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

If there is need to alter the
precedence, you can put the expression
between parenthesis.

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
point if needed, this allows mixing
integers and floating point in some
calculations, but you must have care
to force floating point calculations to
avoid integer overflows.

Example: the expression

    a% = 1000 * 1000 + 1.2

gives correct result as "1000" is
converted to floating point before
calculation, but:

    x=1000: a% = x * x + 1.2

gives incorrect results as the
multiplication result is bigger tan
32767.

Note that after any floating point
errors (division by 0 and overflow),
ERR() returns 3.


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

- OR     : Logical OR, true if one or
           both operands are true.
- AND    : Logical AND, true only if
           both operands are true.
- NOT    : Logical NOT, true only if
           operand is false.
- <=  >=  <>  <  >  =
  Integer or floating point comparison,
  compare the two numbers and return
  true or false.  Note that "<>" is
  "not equal".
  You can only compare two values of
  the same type, so an expression like
  "x = 1.2" is invalid, but "1.2 = x"
  is valid as the second operand is
  converted to floating point before
  comparison.


Arrays
------

Arrays hold many numeric values (called
elements), the elements can be accessed
by an index.

In FastBasic, arrays must be
dimensioned before use (see `DIM`
statement bellow), the index of the
element is written between parenthesis
and goes from 0 to the number of
elements less 1.

You can use an array position (the
variable name followed by the index) in
any location where a standard numeric
variable or value is expected.

Arrays can be of two types: WORD arrays
or BYTE arrays. Word arrays (the
default if no type is given) use two
bytes of memory for each element, and
works like normal numeric variables.
Byte arrays use only one byte for each
element, but the numeric range is
reduced from 0 to 255.


String Values
-------------

String values are written as a text
surrounded by double quotes (""). If
you need to include a double quote
character in a string, you must write
two double quotes together.

Example:

    PRINT "Hello ""world"""

Will print:

    Hello "world"


String Variables
---------------

String variables are named the same as
numeric variables but must end with a $
symbol.  Valid variable names are
"Text$", "NAME1$".


Standard Functions
------------------

Functions take parameters between
parenthesis and produce a result.
Following is a list of all the
functions supported by FastBasic.

- TIME : Returns the curren time in
         "jiffies". This is about 60
         times per second in NTSC
         systems, 50 times per second
         in PAL systems.

- ABS(_num_) : Returns the absolute
               value of _num_. Can be
               used with integers and
               floating point.

- SGN(_num_) ; Returns the sign of
               _num_, this is 1 if
               positive, -1 if negative
               or 0 if _num_ is 0. Can
               be used with integers
               and floating point.

- INT(_num_) : Converts the floating
               point number _num_ to
               the nearest integer from
               -32768 to 32767. In case
               of error, ERR() returns
               3.

- PADDLE(_n_): Returns the value of the
               PADDLE controller _n_.

- PTRIG(_n_) : Returns 0 if the PADDLE
               controller _n_ button is
               pressed, 1 otherwise.

- STICK(_n_) : Returns the JOYSTICK
               controller _n_ position,
               this is 15 if centered.
               See Atari Basic manual
               for all possible values.

- STRIG(_n_) : Returns 0 if JOYSTICK
               controller _n_ button is
               pressed, 1 otherwise.

- RAND(_num_) : Returns a random, non
                negative number, less
                than _num_.

- KEY() : Returns 0 if no key was
          pressed, or a keycode. The
          returned value only goes to 0
          after reading the key in the
          OS (via a `GET` or `POKE
          764,0` statement).  _Hint:
          The value returned is
          actually the same as_
          `(PEEK(764) EXOR 255)`.

- FRE() : Returns the free memory
          available in bytes.

- ERR() : Returns the last Input/Output
          error value, or 1 if no error
          was registered.

- LEN(*string*) : Returns the length of
                  the *string*.

- VAL(*string*) : Convert *string* to a
                  number. If no
                  conversion is
                  possible, ERR() is
                  set to 18. Can be
                  used with integers
                  and floatign point.

- ASC(*string*) : Returns the ATASCI
                  code of the first
                  character of the
                  *string*.


Floating Point functions
------------------------

This functions return a floating point
value.

- COS(_n_): Cosine of _n_.

- EXP(_n_) : Natural exponentiation.

- EXP10(_n_) : Returns ten raised to _n_.

- LOG(_n_) : Natural logarithm of _n_.

- LOG10(_n_): Decimal logarithm of _n_.

- RND(): Returns a random positive
         number strictly less than 1.

- SQR(_n_): Square root of _n_.

- SIN(_n_): Sine of _n_.

- ATN(_n_): Arc-Tangent of _n_.

Note that, as any floating point
calculation, in case of error ERR()
returns 3.


String functions
----------------

- STR$(_num_): Returns a string with a
               printable value for
               _num_. Can be used with
               integers and floating
               point. Note that this
               function can't be used
               at both sides of a
               comparison, as the
               resulting string is
               overwritten each time it
               is called.


Low level Functions
-------------------

The following functions are called "low
level" because they interact directly
with the hardware. Use with care!.


- ADR(_arr_): Returns the address of
              the first element of
              _arr_ in memory.
              Following elements of the
              array occupy adjacent
              memory locations.

- ADR(_str_): Returns the address of
              the _string_ in memory.
              The first memory location
              contains the length of
              the string, and following
              locations contain the
              string characters.

- DPEEK(_addr_): Returns the value of
                 memory location _addr_
                 and _addr_+1 as a 16
                 bit integer.

- PEEK(_address_): Returns the value of
                   memory location at
                   _address_.

- USR(_address_[,_num1_ ...]):
    Low level function, calls the user
    supplied machine code subroutine at
    _address_.

  Parameters are pushed to the CPU
  stack, with the LOW part pushed
  first, so the first PLA returns the
  HIGH part of the last parameter, and
  so on.

  The value of the A and X registers is
  used as a return value of the
  function, with A the low part and X
  the high part.

  This is a sample usage:

      ' PLA / EOR $FF / TAX / PLA / EOR $FF / RTS
      DATA ml() byte = $68,$49,$FF,$AA,$68,$49,$FF,$60
      FOR i=0 TO 1000 STEP 100
        ? i, USR(ADR(ml),i)
      NEXT i


List of statements
==================

In the following descriptions, the
statement usage is presented and the
abbreviation is given after a /.


Console Print and Input Statements
----------------------------------

**Reads key from Keyboard**  
**GET _var_ / GE.**

  Waits for a key-press and writes the
  key value to _var_.

  _var_ can be a variable name or an
  array position (like "array(123)")

**Input variable or string**  
**INPUT _var_ / I.**  
**INPUT "prompt"; _var_**  
**INPUT "prompt", _var_**

  Reads form keyboard/screen and stores
  the value in _var_.

  A "?" sign is printed to the screen
  before input, or the "prompt" if
  given.  Also, if there is a comma
  after the prompt, spaces are printed
  to align to a column multiple of 10
  (similar to how a comma works in
  PRINT).

  If the value can't be read because
  input errors, the error is stored in
  ERR variable. Valid errors are 128 if
  BREAK key is pressed and 136 if
  CONTROL-3 is pressed.

  In case of a numeric variable, if the
  value can't be converted to a number,
  the value 18 is stored in ERR().

**Moves the screen cursor**  
**POSITION _row_, _column_ / POS.**

  Moves the screen cursor position to
  the given _row_ and _column_, so the
  next PRINT statement outputs at that
  position.

  Rows and columns are numerated from
  0.

**Print strings and numbers**  
**PRINT _expr_, ... / ?**

  Outputs strings and numbers to the
  screen.

  Each _expr_ can be a constant string,
  a string variable or any complex
  expression, with commas or semicolons
  between each expression.

  After writing the last expression,
  the cursor advanced to a new line,
  except if the statement ends in a
  comma or a semicolon, where the
  cursor stays in the last position.

  If there is a comma before any
  expression, the column is advanced to
  the next multiple of 10, so that
  tabulated data can be printed.


**Writes a character to the screen**  
**PUT _num_ / PU.**

  Outputs one character to the screen,
  given by it's ATASCI code.


Control Statements
------------------

**Endless loops**  
**DO**  
**LOOP / L.**

  Starts and ends an endless
  repetition, when reaching the LOOP
  statement the program begins again
  executing form the DO statement.

  The only way to terminate the loop is
  via de EXIT statement.


**Calls a subroutine**  
**EXEC _name_ / EXE.**

  Calls the subroutine _name_. Note
  that the subroutine must be defined
  with PROC, but can be defined before
  or after the call.


**Exits from loop or PROC**  
**EXIT / EX.**

  Exits current loop or subroutine, by
  jumping to the end.

  In case of loops, the program
  continues after the last statement of
  the loop, in case of PROC, the
  program returns to the calling EXEC.


**Loop over values of a variable**  
**FOR _var_=_value_ TO _end_ [STEP _step_] / F. TO S.**  
**NEXT _var_ / N.**

  FOR loop allows performing a loop a
  specified number of times while
  keeping a counting variable.

  First, assigns the _value_ to _var_,
  and starts iterations. _var_ can be
  any variable name or a word array
  position (like "array(2)").

  In each iteration, first compares the
  value of _var_ with _end_, if the
  value is past the end, terminates the
  loop.

  At the end of the loop, _var_ is
  incremented by _step_ (or 1 if STEP
  is omitted) and the loops repeats.

  An EXIT statement also terminates the
  loop and skips to the end.

  Note that if _step_ is positive,
  iteration ends if value of _var_ is
  bigger than _end_, but if _step_ is
  negative, iteration ends if value of
  _var_ is less than _end_.

  Also, _end_ and _step_ are evaluated
  only once at beginning of the loop,
  that value is stored and used for all
  loop iterations.

  If at the start of the loop _value_
  is already past _end_, the loop is
  completely skipped.

  As an extension, you can left out the
  variable name in NEXT, and currently
  the variable name is actually
  ignored.


**Conditional execution**  
**IF _condition_ THEN _statement_ / I. T.**  
**IF _condition_**  
**ELIF _condition_ / ELI.**  
**ELSE / E.**  
**ENDIF / END.**

  The first form (with THEN) executes
  one _statement_ if the condition is
  true.

  The second form executes all
  statements following the IF (up until
  any of ELIF, ELSE, ENDIF) only if
  condition is true.

  If condition is false, optional
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
      ' are false
    ENDIF


**Define a subroutine.**  
**PROC _name_ / PRO.**  
**ENDPROC / ENDP.**

  PROC statement starts definition of a
  subroutine, that can be called via
  EXEC.

  Note that if the PROC statement is
  encountered while executing
  surrounding code, the full subroutine
  is skipped, so PROC / ENDPROC can
  appear any place in the program.


**Loop until condition is true**  
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

  The WHILE loop allows looping with a
  condition evaluated at the beginning
  of each iteration.

  First, evaluates the condition. If
  false, skips the whole loop to the
  end. If true, executes the statements
  between WHILE and WEND and returns to
  the top to test the condition again.

  An EXIT statement also terminates the
  loop and skips to the end.


Graphic and Sound Statements
----------------------------

**Set color number**  
**COLOR _num_ / C.**

  Changes the color of PLOT, DRAWTO and
  the line color on FILLTO to _num_.


**Draws a line**  
**DRAWTO _x_, _y_ / DR.**

  Draws a line from last position to
  the given _x_ and _y_ positions.

**Sets fill color number**  
**FCOLOR _num_ & FC.**

  Changes the filling color of FILLTO
  operation to _num_.

**Fill from line to the right**  
**FILLTO _x_, _y_ / FI.**

  Draws a line from last position to
  the given _x_ and _y_ position, using
  COLOR number, and for each plotted
  point also paint all points to the
  right with the FCOLOR number until a
  point with different color than the
  first.


**Sets graphic mode**  
**GRAPHICS _num_ / G.**

  Sets the graphics mode for graphics
  operations. See Atari Basic manual
  for a list of graphics modes, sizes
  and number of colors.

**Plots a single point**  
**PLOT _x_, _y_ / PL.**

  Plots a point in the specified _x_
  and _y_ coordinates, with the current
  COLOR number.

**Sets displayed color**
**SETCOLOR _num_, _hue_, _lum_ / SE.**  

  Alters the color registers so that
  color number _num_ has the given
  _hue_ and _luminance_.

**Adjust voice sound parameters**  
**SOUND _voice_, _pitch_, _dist_, _vol_ / S.**  
**SOUND _voice_**  
**SOUND**

  Adjust sound parameters for _voice_
  (from 0 to 3) ot the given _pitch_,
  _distortion_ and _volume_.

  If only the _voice_ parameter is
  present, that voice is cleared so no
  sound is produced by that voice.

  If no parameters are given, clears
  all voices so that no sounds are
  produced.


Device Input and Output Statements
----------------------------------

**Binary read from file**  
**BGET #_iochn_,_address_,_len_ / BG.**

  Reads _length_ bytes from the channel
  _iochn_ and writes the bytes to
  _address_.

  For example, to read to a byte array,
  use "ADR(array)" to specify the
  address.

  On any error, ERR() will hold an
  error code, on success ERR() reads 1.

**Binary read from file**  
**BPUT #_iochn_,_address_,_len_ / BP.**

  Similar to BPUT, but writes _length_
  bytes from memory at _address_ to the
  channel _iochn_.

  On any error, ERR() will hold an
  error code, on success ERR() reads 1.

**Close channel**  
**CLOSE #_iochn_  / CL.**

  Closes the input output channel
  _iochn_, finalizing all read/write
  operations.

  On any error, ERR() will hold an
  error code, on success ERR() reads 1.

  Note that it is important to read the
  value of ERR() after close to ensure
  that written data is really on disk.

**Reads bytes from file**  
**GET #_iochn_, _var_, ...**

  Reads one byte from channel _iochn_
  and writes the value to _var_.

  _var_ can be a variable name or an
  array position (like "array(123)")

  In case of any error, ERR() returns
  the error value.

**Input variable or string from file**  
**INPUT #_iochn_, _var_ / IN.**

  Reads a line from channel _iochn_ and
  stores to _var_.

  If _var_ is a string variable, the
  full line is stored.

  If _var_ is a numeric variable, the
  line is converted to a number first.

  On any error, ERR() will hold an
  error code, on success ERR() reads 1.

**Opens I/O channel**  
**OPEN #_ioc_,_mode_,_ax_,*dev* / O.**

  Opens I/O channel _ioc_ with _mode_,
  _aux_, over device *dev*.

  To open a disk file for writing,
  _mode_ should be 8, _aux_ 0 and *dev*
  the file name as "D:name.ext".

  To open a disk file for reading,
  _mode_ should be 4, _aux_ 0 and *dev*
  the file name as "D:name.ext".

  See Atari Basic manual for more
  documentation in the open modes, aux
  values and device names.

  On any error, ERR() will hold an
  error code, on success ERR() reads 1.

**Print strings and numbers to a file**  
**PRINT #_iochn_, ... / ?**

  Same rules as the normal print, but
  all the output is to the channel
  _iochn_.  Note that you must put a
  comma after the channel number, not a
  semicolon.

  On any error, ERR() will hold an
  error code, on success ERR() reads 1.

  Note that you can only read the error
  for the last element printed.

**Outputs one byte to the file**  
**PUT #_iochn_, _num_ / PU.**

  Outputs one byte _num_ to the channel
  _iochn_.

  On any error, ERR() will hold an
  error code, on success ERR() reads 1.


**Generic I/O operation**  
**XIO #_iochn_, _cmd_, _aux1_, _aux2_, *dev* / X.**

  Performs a general input/output
  operation on device *dev*, over
  channel _ioc_, with the command _cmd_
  and auxiliary bytes _aux1_ and
  _aux2_.

  Note that the arguments of XIO
  statements are in different order
  than Atari Basic, for consistency
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
  apostrophe will be ignored.

**Defines array with initial values**  
**DATA _arr()_ [type] = n1,n2, / DA.**

  This statement defines an array of
  fixes length with the values given.

  The array name should not be used
  before, and type can be "BYTE"
  (abbreviated "B.") or "WORD"
  (abbreviated "W.").

  If you end the DATA statement with a
  comma, the following line must be
  another DATA statement without the
  array name, and so on until the last
  line.

  Example:

      DATA big() byte = $12,$23,$45,
      DATA       byte = $08,$09,$15

  Note that the array can be modified
  afterwards like a normal array.


**Decrements variable by 1**  
**DEC _var_ / DE.**

  Decrements the variable by 1, this is
  equivalent to "_var_ = _var_ - 1",
  but faster.


**Allocate an array**  
**DIM _arr_(_size_) [type], .../ DI.**

  The DIM statement allows defining
  arrays of specified length.

  The type must be "BYTE" (abbreviated
  "B.") to define a byte array, with
  numbers from 0 to 255, or "WORD" (can
  be left out) to define an array with
  integers from -32768 to 32767.

  The size of the array is the number
  of elements, the elements are
  numerated from 0, so that an array of
  size 10 holds values from 0 to 9.

  You can DIM more than one array by
  separating the names with commas.

  The array is cleared after the "DIM",
  so all elements are 0.


**Ends program**  
**END : Ends program.**

  Terminates current program, only valid at end of input.


**Increments variable by 1**  
**INC _var_**

  Increments the variable by 1, this is
  equivalent to "_var_ = _var_ + 1",
  but faster.


**Pauses execution**  
**PAUSE _num_ / PA.**

  Stops the current execution until the
  specified time.

  _num_ is the time to pause in
  "jiffies", this is the number of TV
  scans in the system, 60 per second in
  NTSC or 50 per second in PAL.

  A value of 0 pauses until the
  vertical retrace, this is useful to
  synchronize to the TV and get fluid
  animations.


Floating point statements
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


Low level statements
--------------------

Those are statements that directly
modify memory. Use with care.


**Writes a 16bit number to memory**  
**DPOKE _address_, _value_ / D.**

  Writes the _value_ to the memory
  location at _address_ and
  _address+1_, using standard CPU order
  (low byte first).


**Copies bytes in memory**  
**MOVE _from_, _to_, _length_ / M.**  
**-MOVE _from_, _to_, _length_ / -.**  

  Copies _length_ bytes in memory at
  address _from_ to address _to_.

  The MOVE version copies from the
  lower address to the upper address,
  the -MOVE version copies from upper
  address to lower address.

  The difference of the two statements
  is in case the memory ranges overlap,
  if _from_ is lower in memory than
  _to_, you need to use -MOVE, else you
  need to use MOVE, otherwise the
  result will no be a copy.

  MOVE a, b, c is equivalent to:

      FOR I=0 to c-1
        POKE b+I, a+I
      NEXT I

  but -MOVE a, b, c is instead:

      FOR I=c-1 to 0 STEP -1
        POKE b+I, a+I
      NEXT I


**Writes a byte to memory**  
**POKE _address_, _value_ / P.**

  Writes the _value_ (modulo 256) to
  the memory location at _address_.


