FastBasic test suite
====================

To run the testsuite, you need `git` to download the 6502 simulator and type
`make test` from the parent directory.  To run a single test:

    build/bin/fbtest testsuite/tests/<name>.chk


File format
-----------

Normal tests are a pair of files: `tests/<name>.chk` (the test definition)
and `tests/<name>.bas` (the source program).  A cross-only test may also have
a companion `tests/<name>.asm`; `fbtest` appends it to the generated assembly
before calling `ca65`.  This lets a test define a `USR` routine or page-aligned
bytecode using the runtime `TOK_*` symbols.  See `interp-page-cross` for an
example.

Editor tests (`Test: editor`) are different: the `.chk` file is
self-contained and **no `.bas` file is needed**.  The initial editor buffer is
declared explicitly with the `Document:` key, so the same `.bas` file is never
silently used as both program source and editor buffer.

The `.chk` file is a sequence of `Key: value` lines, followed by multi-line
sections terminated by a line containing only `.`.  Lines starting with `#` in
the header are comments.  Recognised keys:

| Key             | Value                                                          |
|:----------------|:---------------------------------------------------------------|
| `Name:`         | Human-readable test name (shown in pass/fail output).          |
| `Test:`         | comma/space/hyphen separated list of test modifiers (below).   |
| `Max-cycles:`   | Cycle limit for the simulator (default 20 000 000).            |
| `Error:`        | Expected compiler error message (for `error` tests).           |
| `Error-pos:`    | Expected error location as `line : column`.                    |
| `Document:`     | Editor tests only: initial document (see below).                |
| `Input:`        | Keystrokes fed to the running program (section, terminated by `.`). |
| `Output:`       | Expected captured output stream (rest of file, exact match).   |
| `Screen:`       | Expected screen state, up to 24 lines of up to 40 chars (section). |
| `Cursor:`       | Expected cursor position as `row,col` (editor tests, from ROWCRS/COLCRS). |
| `Expect-out:`   | Substring that must appear in the captured output.             |
| `Exists:`       | Filename that must exist after the run (in the test's DOS root).|
| `Check <file>:` | Section with expected content of a file written during the run.|
| `Files:`        | Filenames to copy into the DOS root before the run (section).  |

### Test modifiers (`Test:`)

| Modifier  | Meaning                                                       |
|:----------|:--------------------------------------------------------------|
| `run`     | Compile as XEX and run under mini65 (default for most tests). |
| `fp`      | Use the floating-point compiler (default).                    |
| `int`     | Use the integer compiler.                                     |
| `cross`   | Cross-compile (build/bin/fastbasic).                          |
| `native`  | Native compile (build/bin/fbc / fbci).                        |
| `compile` | Compile only, do not run.                                     |
| `error`   | Expect a compile error; `Error:` gives the message.           |
| `editor`  | Run the IDE (fb.xex) with a keystroke script. Implies `fp`.   |

Multiple modifiers can be combined: `Test: run, int` runs the integer
compiler, `Test: cross, compile` cross-compiles without running.

When neither `cross` nor `native` is given, both are used.  When neither `fp`
nor `int` is given, both are used.  A single test may be compiled and run up to
six ways: native FP/INT and cross FP/INT, each as XEX and cart ROM.


Input notation
--------------

The `Input:` section supports readable notation for control and special
characters.  All other bytes pass through literally (newlines in the file are
converted to ATASCII EOL `$9B`).

| Notation     | Maps to                                               |
|:-------------|:------------------------------------------------------|
| `^A` .. `^Z` | Ctrl-A (`$01`) .. Ctrl-Z (`$1A`). Case-insensitive.   |
| `<ESC>`      | Escape (`$1B`).                                       |
| `<UP>`       | Cursor up (`$1C`).                                    |
| `<DOWN>`     | Cursor down (`$1D`).                                  |
| `<LEFT>`     | Cursor left (`$1E`).                                  |
| `<RIGHT>`    | Cursor right (`$1F`).                                 |
| `<RETURN>`   | Return / ATASCII EOL (`$9B`).                         |
| `<CLS>`      | Clear screen (`$7D`).                                 |
| `<BACKSP>`   | Backspace (`$7E`).                                    |
| `<TAB>`      | Tab (`$7F`).                                          |
| `<DELLN>`    | Delete line (`$9C`).                                  |
| `<INSLN>`    | Insert line (`$9D`).                                  |
| `<DELTAB>`   | Clear tab stop (`$9E`).                               |
| `<SETTAB>`   | Set tab stop (`$9F`).                                 |
| `<BELL>`     | Bell (`$FD`).                                         |
| `<DEL>`      | Delete character at cursor (`$FE`).                   |
| `<INS>`      | Insert character at cursor (`$FF`).                   |
| `\xHH`       | Explicit hex byte (e.g. `\x9B` for ATASCII EOL).      |
| UTF-8 chars  | Multi-byte UTF-8 sequences from the ATASCII character set (e.g. `⇱` for CLS, `▄` for block graphic, `𝗔` for inverse A). |

Example — the following types "HELLO", runs the program, saves as
`T2.XEX` and quits:

    Input:
    HELLO
    ^R ^WT2.XEX
    ^Q^C
    .

For normal (non-editor) tests, every line break in `Input:` is passed to the
program.  In editor tests, the line break immediately before the terminating
`.` is treated as a section separator, not as a RETURN key press.  Use an
`<RETURN>` or an empty line before `.` when the script needs a final
RETURN.


Editor tests
------------

Editor tests (`Test: editor`) run the FastBasic IDE (`fb.xex`) under the
mini65 simulator with a scripted keystroke sequence.

### Initial document

The IDE opens `D:HELP.TXT` on startup, and that file is the initial editor
buffer.  The `Document:` key describes how to create it:

    Document: none

creates an empty `HELP.TXT`.  This is the default when `Document:` is omitted.

    Document:
    ' split test
    .

uses the lines between `Document:` and `.` as the initial document.  Lines
are converted from LF to ATASCII EOL.  The newline before the final `.` is not
part of the document; add an empty line before `.` if the document must end
with an EOL.

    Document: fixtures/lines33.txt

copies an ASCII fixture from the test directory, converting LF to ATASCII.
Fixtures are read-only and are never modified by a test.

`Document:` is only valid for editor tests.

### Per-test DOS root

Every editor test runs with its own emulated `D:` root:

    build/tests/<test-name>/

`HELP.TXT`, files from `Files:`, files written by the IDE, and the targets of
`Check:` and `Exists:` all live in that directory.  The harness creates the
directory and removes known output files before each run, so `Exists:` cannot
pass because of a file left by an earlier run.

All generated files stay under `build/`.  Tests never write into
`testsuite/tests/`.

### EOF termination

When the `Input:` feeder is exhausted, `str_get_char()` returns EOF and the
simulator's cycle limit is set to 1, causing it to stop on the next cycle
check.  This avoids wasting cycles waiting for more input when the editor is
idle.  This only applies to editor tests (the `str_stop_on_eof` flag); regular
tests are not affected.


Screen assertions
-----------------

The `Screen:` section allows editor tests to check the final state of the
emulated 24×40 text screen.  It contains up to 24 lines, each up to 40
characters, terminated by a line with only `.`.

Trailing spaces on each line are trimmed before comparison.  The screen is
read after the simulation ends and compared byte-exactly against the expected
content — the ATASCII inverse bit (`$80`) and all control characters are
preserved.  Notation is expanded in expected lines, so you can use `\x92` for
inverse space, `<CLS>` for `$7D`, UTF-8 characters like `𝗔` for inverse A, etc.

When a comparison fails, the actual screen row is also printed using UTF-8
characters with ANSI inverse-video escapes, so you can visually see what the
Atari screen looks like.

A `Cursor: row,col` line asserts the cursor position after the run; coordinates
are zero-based and are read from the emulated `ROWCRS` and `COLCRS` OS
variables.  This complements the cursor glyph in `Screen:` and is useful for
navigation tests.

The simulation is terminated when the input feeder reaches EOF, so the screen
snapshot captures the state at that point.

### Cursor rendering

The real Atari OS renders the cursor by XOR'ing `$80` at the cursor position
(`CRSINH`/`OLDCHR` mechanism).  The mini65 screen accessor includes the visible
cursor glyph, so the test harness reads the screen buffer directly and does
**not** invert the cursor cell again.  Goldens must account for the cursor
glyph — e.g., a normal space (`$20`) at the cursor position becomes inverse
space (`$A0`).

### Last-column and wrap markers

The editor writes continuation markers in the last column of a wrapped
logical line.  Tests must not write to (23, 39) unless they intend to trigger
a scroll, and screen goldens must include these marker cells when a line
overflows.

### Screen state after quit

If the editor quits (Ctrl-Q Ctrl-C), the screen is typically cleared.
`Screen:` assertions are meaningful only while the editor is still running
(e.g. after typing text or running a program).  Do not assert the post-quit
screen.


Debugging
---------

Set environment variables before running `make test` or `build/bin/fbtest`:

| Variable         | Effect                                                       |
|:-----------------|:-------------------------------------------------------------|
| `FBTEST_DEBUG`   | Enable sim65 debug messages (CIO activity, device I/O).      |
| `FB_DUMP_SCREEN` | Write the final 24×40 screen as raw ATASCII bytes to `build/tests/<test>.screen`. |
| `FB_DUMP_OUTPUT` | Write the captured output stream to `build/tests/<test>.output`. |

Example:

    FBTEST_DEBUG=1 FB_DUMP_SCREEN=1 \
        build/bin/fbtest testsuite/tests/ed-assert.chk

Both dump variables are switches; the files are always written under
`build/tests/`.


Peephole optimizer coverage
---------------------------

The cross-compiler can report every peephole rule and every successful match
when `FASTBASIC_PEEPHOLE_DEBUG` is set.  The coverage check compiles all test
sources for both targets, then fails if any rule was not reached:

    make peephole-coverage

The report lists matched and rewritten rule counts.  It treats a rule as
covered when its pattern plus guard matched, not only when it produced a
rewrite, because some rules deliberately only update optimizer state.  The
full compiler output is kept in `build/peephole-coverage/debug.log`.

When adding or changing an optimizer rule, add a test that exercises its
transformation and checks the program's output.  A rule that cannot be reached
from the grammar should be removed rather than left uncovered.


Cleanup
-------

Each test writes a cleanup manifest derived from its `.chk` declarations:

    build/tests/.fbtest-manifest-<test-name>

For editor tests the manifest contains `HELP.TXT` (from `Document:`), every
`Files:` copy, every `Check:` and `Exists:` file, and the test directory.  For
normal tests it contains the `Check:` and `Exists:` files.  The opt-in
`.screen` / `.output` debug dumps are also listed.

`make clean` reads those manifests and removes only the listed files.
Editor test directories are removed with `rmdir`, so a directory that still
contains user files is left in place.  Manifests are written in binary mode so
the same cleanup works on Windows with the MSYS shell tools used by the rest of
the Makefile.

Every file written by a test must therefore be declared with `Document:`,
`Files:`, `Check:`, or `Exists:`.


Architecture
------------

- `testsuite/src/fbtest.c` — the test harness (compilation, execution,
  output comparison, screen assertions, notation expansion).
- `testsuite/mini65/` — the mini65 6502 simulator with Atari BIOS
  emulation (submodule).
- `testsuite/tests/*.chk` — test definitions.
- `testsuite/tests/*.bas` — source programs for non-editor tests.
- `testsuite/tests/fixtures/` — shared read-only editor documents.
