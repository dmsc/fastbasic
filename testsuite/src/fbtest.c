/*
 * FastBasic - Fast basic interpreter for the Atari 8-bit computers
 * Copyright (C) 2017-2025 Daniel Serpell
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>
 */

// fbtest.c: Runs tests of the compiler and interpreter.

#define _GNU_SOURCE // for asprintf
#include "atari.h"
#include "sim65.h"
#include "atcio.h"
#include <errno.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

#ifdef _WIN32
# include <direct.h>
# define MKDIR(path) _mkdir(path)
# define PATH_SEP "\\"
// Implement missing "strndup"
static char *strndup(const char *s, size_t n)
{
    char *ret = malloc(n + 1);
    strncpy(ret, s, n);
    ret[n] = 0;
    return ret;
};
#else
# define MKDIR(path) mkdir(path, 0777)
# define PATH_SEP "/"
#endif

// Flags
static int verbose;
static const char *fb_atari_comp_int = "build/bin/fbci.xex";
static const char *fb_atari_comp_fp  = "build/bin/fbc.xex";
static const char *fb_atari_ide_int  = "build/bin/fbi.xex";
static const char *fb_atari_ide_fp   = "build/bin/fb.xex";
static const char *fb_compiler       = "build" PATH_SEP "bin" PATH_SEP "fastbasic";
static const char *ca65_path         = "build" PATH_SEP "bin" PATH_SEP "ca65";
static const char *ld65_path         = "build" PATH_SEP "bin" PATH_SEP "ld65";
static const char *fb_lib_path       = "build/compiler";
static const char *output_dir        = "build/tests";

#define CA65_OPTS   "-t atari -g"
#define FB_LIB_FP   "fastbasic-fp.lib"
#define FB_LIB_INT  "fastbasic-int.lib"
#define FB_CFG_FILE "fastbasic.cfg"
#define FB_PATHS    "-target-path:compiler -syntax-path:src/syntax"
#define FB_INT_TARGET   "-t:atari-int"
#define FB_FP_TARGET    "-t:atari-fp"
#define FB_LIB_ROM_FP   "fastbasic-cart-fp.lib"
#define FB_LIB_ROM_INT  "fastbasic-cart-int.lib"
#define FB_CFG_FILE_ROM "fastbasic-cart.cfg"

// Maximum number of cycles for the native compiler
#define MAX_FPC_CYCLES 28000000

// Functions to get/put characters to running XEX
static size_t str_out_pos, str_out_len, str_in_pos, str_in_len;
static char *str_out;
static const char *str_in;
static sim65 str_s;
static int str_stop_on_eof;
static int input_eof;
static void str_put_char(int c)
{
    if (c == 0x9b)
        c = '\n';
    else if (c == 0)
        c = '\n';

    if (str_out_pos < str_out_len)
        str_out[str_out_pos++] = c;
}
static int str_get_char(void)
{
    if (str_in_pos < str_in_len)
        return 0xFF & str_in[str_in_pos++];
    // Input exhausted
    input_eof = 1;
    if (str_stop_on_eof)
        sim65_set_cycle_limit(str_s, 1);
    return EOF;
}

// ATASCII→UTF-8 table for visual screen diagnostics.
// Adapted from conv-atascii-utf8.c — indexed by ATASCII byte value.
static const char *const atascii_utf8[256] = {
                    "♥", "├", "🮇", "┘", "┤", "┐", "╱", "╲",
                    "◢", "▗", "◣", "▝", "▘", "🮂", "▂", "▖",
                    "♣", "┌", "─", "┼", "●", "▄", "▎", "┬",
                    "┴", "▌", "└", "␛", "↑", "↓", "←", "→",
                    " ", "!", "\"", "#", "$", "%", "&", "'",
                    "(", ")", "*", "+", ",", "-", ".", "/",
                    "0", "1", "2", "3", "4", "5", "6", "7",
                    "8", "9", ":", ";", "<", "=", ">", "?",
                    "@", "A", "B", "C", "D", "E", "F", "G",
                    "H", "I", "J", "K", "L", "M", "N", "O",
                    "P", "Q", "R", "S", "T", "U", "V", "W",
                    "X", "Y", "Z", "[", "\\", "]", "^", "_",
                    "♦", "a", "b", "c", "d", "e", "f", "g",
                    "h", "i", "j", "k", "l", "m", "n", "o",
                    "p", "q", "r", "s", "t", "u", "v", "w",
                    "x", "y", "z", "♠", "|", "⇱", "◀", "▶",
                    "♥", "┣", "▊", "┛", "┫", "┓", "╱", "╲",
                    "◤", "▛", "◥", "▙", "▟", "▆", "🮅", "▜",
                    "♣", "┏", "━", "╋", "●", "▀", "🮊", "┳",
                    "┻", "▐", "┗", "\n", "⇑", "⇓", "⇐", "⇒",
                    "█", "!", "\"", "#", "$", "%", "&", "'",
                    "(", ")", "*", "+", ",", "-", ".", "/",
                    "𝟬", "𝟭", "𝟮", "𝟯", "𝟰", "𝟱", "𝟲", "𝟳",
                    "𝟴", "𝟵", ":", ";", "<", "=", ">", "?",
                    "@", "𝗔", "𝗕", "𝗖", "𝗗", "𝗘", "𝗙", "𝗚",
                    "𝗛", "𝗜", "𝗝", "𝗞", "𝗟", "𝗠", "𝗡", "𝗢",
                    "𝗣", "𝗤", "𝗥", "𝗦", "𝗧", "𝗨", "𝗩", "𝗪",
                    "𝗫", "𝗬", "𝗭", "[", "\\", "]", "^", "_",
                    "♦", "𝗮", "𝗯", "𝗰", "𝗱", "𝗲", "𝗳", "𝗴",
                    "𝗵", "𝗶", "𝗷", "𝗸", "𝗹", "𝗺", "𝗻", "𝗼",
                    "𝗽", "𝗾", "𝗿", "𝘀", "𝘁", "𝘂", "𝘃", "𝘄",
                    "𝘅", "𝘆", "𝘇", "♠", "|", "⇱", "◀", "▶"
};

// Print one screen row as UTF-8 with ANSI inverse-video escapes.
// atari_screen_get() already contains the visible cursor glyph, so the
// character must not be inverted again here.
static void print_screen_row_utf8(FILE *fp, int row)
{
    int inv = 0;
    for (int c = 0; c < 40; c++)
    {
        int ch = atari_screen_get(row, c);
        int is_inv = ch & 0x80;
        if (is_inv != inv)
        {
            fputs(inv ? "\033[27m" : "\033[7m", fp);
            inv = is_inv;
        }
        fputs(atascii_utf8[ch & 0x7F], fp);
    }
    if (inv)
        fputs("\033[27m", fp);
}

// Runs atari XEX file capturing the output
static int run_atari_prog(const char *progname, char *output, size_t *output_len,
                          const char *input, size_t input_len, uint64_t max_cycles,
                          int is_rom, const char *cmdline, int fix_margins,
                          const char *dos_root)
{
    // Init input/output
    str_in = input;
    str_in_pos = 0;
    str_in_len = input_len;
    str_out = output;
    str_out_pos = 0;
    str_out_len = *output_len - 1;
    memset(str_out, 0, *output_len);
    input_eof = 0;
    // Init emulator
    sim65 s = sim65_new();
    if (!s)
        return -1;
    // NOTE: never enable full instruction tracing here, a single run can
    //       log billions of lines and fill the disk.
    // sim65_set_debug(s, sim65_debug_trace);
    if (getenv("FBTEST_DEBUG"))
        // Log CIO and device activity, useful to debug editor scripts
        sim65_set_debug(s, sim65_debug_messages);
    emu_options opts = {
        .get_char = str_get_char, .put_char = str_put_char, .flags = atari_opt_cycletime
    };
    atari_init(s, &opts);
    // Add command line
    atari_dos_add_cmdline(s, progname);
    if (cmdline)
        atari_dos_add_cmdline(s, cmdline);
    // Set DOS path
    atari_dos_set_root(s, dos_root ? dos_root : output_dir);
    // Use 0 as left-margin value, to normalize results. This is not
    // done when running the IDE, that expects the default margins.
    if (fix_margins)
    {
        unsigned char val = 0;
        sim65_add_data_ram(s, 0x52, &val, 1); // LMARGN
        sim65_add_data_ram(s, 0x55, &val, 1); // COLCRS
    }

    sim65_set_cycle_limit(s, max_cycles);
    str_s = s;
    enum sim65_error e;
    if( is_rom )
        e = atari_rom_load(s, 0xA000, progname);
    else
        e = atari_xex_load(s, progname, 1);
    str_s = NULL;
    // Cycle limit hit after input exhausted is the normal editor exit path
    if (e == sim65_err_cycle_limit && str_stop_on_eof && input_eof)
        e = sim65_err_none;
    if (e == sim65_err_user)
    {
        fprintf(stderr, "%s: error reading XEX/ROM file\n", progname);
        free(s);
        return -1;
    }
    else if (e)
    {
        // Prints error message
        fprintf(stderr, "%s: simulator returned %s at address %04x.\n",
                progname, sim65_error_str(s, e), sim65_error_addr(s));
        free(s);
        return -1;
    }
    // Return the current value of FastBasic stack, used to check for stack errors
    // TODO: this should depend on actual compiled value, we currently expect the
    //       value to be constant.
    int x = 0x28 != (sim65_get_byte(s, 0x8E) & 0xFF);
    // Update output length
    *output_len = str_out_pos;
    free(s);
    if (x)
        fprintf(stderr, "%s: simulator stack invalid at exit: %d.\n",
                progname, x);
    return x;
}

// Checks that the captured output matches the expected output
static int check_output(const char *fname, const char *expected_out, const char *out)
{
    if (!strcmp(expected_out, out))
        return 0;
    size_t l = 0;
    for (l = 0; out[l] == expected_out[l] && out[l]; l++);

    size_t l1 = l > 20 ? l - 20 : 0;
    size_t l2 = l + 20;
    fprintf(stderr, "%s: output does not match:\n", fname);
    fprintf(stderr, "expected: ");
    for(const char *x = expected_out + l1; x<(expected_out+l2) && *x; x++)
        putc(*x > 31 && *x < 127 ? *x : '.', stderr);
    fprintf(stderr, "\ngot:      ");
    for(const char *x = out + l1; x<(out+l2) && *x; x++)
        putc(*x > 31 && *x < 127 ? *x : '.', stderr);
    fprintf(stderr, "\n          ");
    for(size_t x = l1; x<l; x++)
        putc(' ', stderr);
    fprintf(stderr, "^\n");
    return -1;
}

// Run's an XEX file testing if the output matches the expected output
int run_test_xex(const char *fname, const char *input, const char *expected_out,
                 uint64_t max_cycles, int rom)
{
    size_t len = strlen(expected_out) + 128;
    char *out = calloc(len + 1, 1);

    int e = run_atari_prog(fname, out, &len, input, strlen(input), max_cycles, rom, 0, 1, NULL);
    if (!e)
    {
        // Check
        e = check_output(fname, expected_out, out);
    }
    else if (e > 0)
        fprintf(stderr,"%s: unexpected stack value.\n", fname);
    else
        fprintf(stderr, "%s: error on execution.\n", fname);
    free(out);
    return e;
}

// Copies a file from the test directory into a DOS root, converting to
// ATASCII.  The destination is always under build/.
static int atascii_convert(const char *infile, const char *outfile);
static int copy_fixture_to(const char *srcdir, const char *name, const char *dst)
{
    char *src;
    if (asprintf(&src, "%s/%s", srcdir, name) < 0)
        return -1;
    int e = atascii_convert(src, dst);
    free(src);
    return e;
}

static int dos_copy_file(const char *srcdir, const char *name, const char *dstdir)
{
    char *dst;
    if (asprintf(&dst, "%s/%s", dstdir, name) < 0)
        return -1;
    int e = copy_fixture_to(srcdir, name, dst);
    free(dst);
    return e;
}

// Removes a file from a directory, ignoring errors.
static void unlink_in(const char *dir, const char *name)
{
    char *path;
    if (asprintf(&path, "%s/%s", dir, name) >= 0)
    {
        unlink(path);
        free(path);
    }
}

// Converts ASCII file to ATASCII
static int atascii_convert(const char *infile, const char *outfile)
{
    FILE *fi = fopen(infile, "rb");
    if (!fi)
    {
        fprintf(stderr, "%s: can't open input file.\n", infile);
        return -1;
    }
    FILE *fo = fopen(outfile, "wb");
    if (!fo)
    {
        fclose(fi);
        fprintf(stderr, "%s: can't open output file.\n", outfile);
        return -1;
    }
    int c;
    while (EOF != (c = fgetc(fi)))
    {
        if (c == '\n')
            c = 0x9b;
        fputc(c, fo);
    }
    fclose(fo);
    fclose(fi);
    return 0;
}

// Compile file using native (emulated) compiler
static int compile_native(const char *atbname, const char *xexname, const char *error_data,
                          int do_fp)
{
    const char *compiler = do_fp ? fb_atari_comp_fp : fb_atari_comp_int;
    char *cmd = calloc(strlen(atbname) + strlen(xexname) + 16, 1);
    char *out = calloc(2048, 1);
    char *err = 0;
    size_t len = 2047;
    unlink(xexname);
    // Remove output dir from paths
    const size_t l = strlen(output_dir);
    if (strncmp(atbname, output_dir, l) || strncmp(xexname, output_dir, l))
        sprintf(cmd, "%s %s", atbname, xexname);
    else
        sprintf(cmd, "%s %s", atbname + l, xexname + l);
    int e = run_atari_prog(compiler, out, &len, 0, 0, MAX_FPC_CYCLES, 0, cmd, 1, NULL);

    if (e)
        fprintf(stderr, "%s: can't execute compiler.\n", compiler);
    else if (0 != (err = strstr(out, "FILE ERROR")))
    {
        for (char *eol = err; *eol && !(*eol == '\n' && (*eol = 0)); eol ++);
        fprintf(stderr, "%s: compiler '%s'\n", atbname, err);
        e = -1;
    }
    else if (0 != (err = strstr(out, "at line")))
    {
        // Compilation error (expected succeed)!
        if (!error_data || !strstr(out, error_data))
        {
            // Extract full error line
            for (char *eol = err; *eol && !(*eol == '\n' && (*eol = 0)); eol ++);
            for (; err > out && err[-1] != '\n'; err --);
            fprintf(stderr, "%s: unexpected compile error: '%s'\n", atbname, err);
            e = -1;
        }
    }
    else if (error_data)
    {
        // Compilation succeeded (expected fail!)
        fprintf(stderr, "%s: compiled without error, unexpected\n", atbname);
        e = -1;
    }
    free(cmd);
    free(out);
    return e;
}

static int run_prog(const char *prog, char *out, size_t *len)
{
    // Redirect standard error
    char *cmd = 0;
    if (asprintf(&cmd, "%s 2>&1", prog) < 0)
    {
        fprintf(stderr, "%s: memory error\n", prog);
        return -1;
    }

    FILE *f = popen(cmd, "r");
    if (!f)
    {
        fprintf(stderr, "%s: can't execute compiler.\n", prog);
        return -1;
    }
    free(cmd);

    int clen = 0;
    int c;
    while (clen < *len && (EOF != (c = fgetc(f))))
        out[clen++] = c;
    *len = clen;
    return pclose(f) ? 1 : 0;
}

static int compile_cross(const char *basname, const char *asmname,
                         const char *objname, const char *outname, int fp,
                         int comp_ok, int error_pos_line, int error_pos_column,
                         int compile_rom)
{
    const char *fb_target = fp ? FB_FP_TARGET : FB_INT_TARGET;
    const char *libs = compile_rom ? (fp ? FB_LIB_ROM_FP : FB_LIB_ROM_INT)
                                   : (fp ? FB_LIB_FP : FB_LIB_INT);
    const char *cfg = compile_rom ? FB_CFG_FILE_ROM : FB_CFG_FILE;
    char *cmd = 0;
    char *out = calloc(8192, 1);
    int e = -1;

    // Erase all files
    unlink(asmname);
    unlink(objname);
    unlink(outname);

    if (asprintf(&cmd, "%s " FB_PATHS " %s -c -o %s %s", fb_compiler, fb_target, asmname, basname) < 0)
    {
        fprintf(stderr, "%s: memory error.\n", basname);
        goto xit;
    }

    // Calls compiler
    size_t len = 8191;
    e = run_prog(cmd, out, &len);
    if (e < 0)
        goto xit;
    else if (e && comp_ok)
    {
        fprintf(stderr, "%s: compile error: '%s'\n", basname, out);
        goto xit;
    }
    else if (e && !comp_ok)
    {
        // Extract error line and column, format is:
        //   FILE_NAME:LINE:COLUMN: MESSAGE
        int line = 0, column = 0;
        // Ignore errors, assume 0 as line and column
        sscanf(out, "%*[^:]:%d:%d:", &line, &column);
        if (error_pos_line != line || error_pos_column != column)
        {
            fprintf(stderr, "%s: bad error line or column, actual %d:%d, expected %d:%d\n",
                    basname, line, column, error_pos_line, error_pos_column);
            goto xit;
        }
        e = 0;
    }
    else if (!e)
    {
        e = -1;
        // Assemble to object file
        free(cmd);
        if (asprintf(&cmd, "%s %s -o %s -I %s/asminc %s", ca65_path,
                     CA65_OPTS, objname, fb_lib_path, asmname) < 0)
        {
            fprintf(stderr, "%s: memory error.\n", asmname);
            goto xit;
        }
        len = 8191;
        e = run_prog(cmd, out, &len);
        if (e && comp_ok)
        {
            fprintf(stderr, "%s: assembly error: '%s'\n", asmname, out);
            goto xit;
        }

        // Now, link to XEX / ROM
        free(cmd);
        if (asprintf(&cmd, "%s -C %s/%s -o %s %s %s/%s", ld65_path, fb_lib_path,
                     cfg, outname, objname, fb_lib_path, libs) < 0)
        {
            fprintf(stderr, "%s: memory error.\n", asmname);
            goto xit;
        }

        len = 8191;
        e = run_prog(cmd, out, &len);
        if (e && comp_ok)
        {
            fprintf(stderr, "%s: link error: '%s'\n", objname, out);
            goto xit;
        }
        else if (!e && !comp_ok)
        {
            // Compilation succeeded (expected fail!)
            fprintf(stderr, "%s: compiled without error, unexpected\n", basname);
            e = -1;
            goto xit;
        }
        else if (e)
            e = 0;
    }

xit:
    free(cmd);
    free(out);
    return e;
}

static char *build_fname(const char *base_name, const char *ext)
{
    char *ret;
    asprintf(&ret, "%s/%s.%s", output_dir, base_name, ext);
    if( !ret )
    {
        fprintf(stderr,"memory error");
        exit(1);
    }
    return ret;
}


static char *source_fname(const char *base_name, const char *ext)
{
    char *ret;
    asprintf(&ret, "%s.%s", base_name, ext);
    if( !ret )
    {
        fprintf(stderr,"memory error");
        exit(1);
    }
    return ret;
}


enum tests {
    test_run = 1,
    test_fp = 2,
    test_int = 4,
    test_cross = 8,
    test_native = 16,
    test_compile_error = 32,
    test_editor = 64
};

// Initial document specification for editor tests.
enum document_kind {
    doc_default = 0, // no Document: key, start with an empty file
    doc_none,
    doc_inline,
    doc_file
};

// Expands control-key, named-key, and UTF-8 notation in an input buffer.
// ^X (0x41-0x5A) -> Ctrl-A..Z ($01-$1A)
// <NAME> -> single byte from the Atari special-character table
// \xHH -> hex byte
// UTF-8 multi-byte sequences -> ATASCII byte from atascii_utf8 table
// All other bytes pass through literally.
// Returns a malloc'ed buffer; caller must free the original.
static char *expand_notation(char *input, size_t *len_out)
{
    static const struct { const char *name; int code; } keys[] = {
        { "ESC", 0x1B }, { "UP", 0x1C }, { "DOWN", 0x1D },
        { "LEFT", 0x1E }, { "RIGHT", 0x1F }, { "RETURN", 0x9B },
        { "CLS", 0x7D },
        { "BACKSP", 0x7E }, { "TAB", 0x7F }, { "DELLN", 0x9C },
        { "INSLN", 0x9D }, { "DELTAB", 0x9E }, { "SETTAB", 0x9F },
        { "BELL", 0xFD }, { "DEL", 0xFE }, { "INS", 0xFF },
        { NULL, 0 }
    };
    size_t in_len = strlen(input);
    char *out = malloc(in_len + 1);
    size_t oi = 0;
    for (size_t i = 0; i < in_len; )
    {
        unsigned char c = (unsigned char)input[i];
        if (c == '^' && i + 1 < in_len)
        {
            unsigned char next = (unsigned char)input[i + 1];
            if (next >= 'A' && next <= 'Z')
            {
                out[oi++] = next - 'A' + 1;
                i += 2;
                continue;
            }
            if (next >= 'a' && next <= 'z')
            {
                out[oi++] = next - 'a' + 1;
                i += 2;
                continue;
            }
        }
        if (c == '<')
        {
            size_t j = i + 1;
            while (j < in_len && input[j] != '>')
                j++;
            if (j < in_len)
            {
                size_t nlen = j - i - 1;
                for (int k = 0; keys[k].name; k++)
                {
                    if (strlen(keys[k].name) == nlen &&
                        !strncasecmp(input + i + 1, keys[k].name, nlen))
                    {
                        out[oi++] = (unsigned char)keys[k].code;
                        i = j + 1;
                        goto next;
                    }
                }
            }
        }
        if (c == '\\' && i + 3 < in_len && input[i + 1] == 'x')
        {
            int hi = -1, lo = -1;
            unsigned char h = (unsigned char)input[i + 2];
            unsigned char l = (unsigned char)input[i + 3];
            if      (h >= '0' && h <= '9') hi = h - '0';
            else if (h >= 'A' && h <= 'F') hi = h - 'A' + 10;
            else if (h >= 'a' && h <= 'f') hi = h - 'a' + 10;
            if      (l >= '0' && l <= '9') lo = l - '0';
            else if (l >= 'A' && l <= 'F') lo = l - 'A' + 10;
            else if (l >= 'a' && l <= 'f') lo = l - 'a' + 10;
            if (hi >= 0 && lo >= 0)
            {
                out[oi++] = (unsigned char)(hi * 16 + lo);
                i += 4;
                continue;
            }
        }
        // UTF-8: scan atascii_utf8 table for a match at current position.
        if (c >= 0xC0)
        {
            for (int k = 0; k < 256; k++)
            {
                size_t ulen = strlen(atascii_utf8[k]);
                if (i + ulen <= in_len &&
                    !memcmp(input + i, atascii_utf8[k], ulen))
                {
                    out[oi++] = (unsigned char)k;
                    i += ulen;
                    goto next;
                }
            }
        }
        out[oi++] = c;
        i++;
    next:;
    }
    out[oi] = 0;
    *len_out = oi;
    free(input);
    return out;
}

// Reads a section of lines, terminated by a lone ".", converting newlines
// to ATASCII EOL. Returns a malloc'ed buffer and its size, or NULL if the
// section is unterminated.
static char *read_section(FILE *f, int *line, size_t *len_out)
{
    size_t cap = 4096, size = 0;
    char *buf = calloc(cap, 1), lbuf[256];
    while (fgets(lbuf, sizeof(lbuf)-1, f))
    {
        (*line)++;
        if (!strcmp(lbuf, ".") || !strcmp(lbuf, ".\n"))
        {
            buf[size] = 0;
            *len_out = size;
            return buf;
        }
        size_t l = strlen(lbuf);
        if (l && lbuf[l-1] == '\n')
            lbuf[l-1] = 0x9B;
        while (size + l + 1 > cap)
        {
            cap *= 2;
            char *nb = realloc(buf, cap);
            if (!nb)
            {
                free(buf);
                return NULL;
            }
            buf = nb;
        }
        memcpy(buf + size, lbuf, l);
        size += l;
    }
    free(buf);
    return NULL;
}

// Runs one test from the test-file
int fbtest(const char *fname)
{
    FILE *f = fopen(fname, "rb");
    if (!f)
    {
        fprintf(stderr, "%s: error, can't open file.\n", fname);
        return -1;
    }

    /* File format:
     *   NAME: The name of the test
     *   TEST: The test to do
     *   ERROR: The expected error from compiler (optional)
     *   MAX-CYCLES: The maximum number of cycles to wait for program termination.
     *               (if not given, use 20_000_000.
     *   INPUT:
     *   Optional input, up to a line with only a '.'.
     *   OUTPUT:
     *   The expected output, up to the end of the file.
     */
    char *name = 0, *expected_out = 0, *input_buf = 0, *error_data = 0;
    char *files[16];
    int nfiles = 0;
    // Initial editor document
    int doc_kind = doc_default, doc_set = 0;
    char *doc_filename = 0, *doc_data = 0;
    size_t doc_len = 0;
    size_t input_len = 0;
    // Expected content of files written during an editor session
    struct
    {
        char *name;
        char *data;
        size_t len;
    } checks[16];
    int nchecks = 0;
    // Names of files that must exist after the run
    char *exists[16];
    int nexists = 0;
    // Substrings that must appear in the captured output stream
    char *expects[8];
    int nexpects = 0;
    // Expected screen content (24 rows of up to 40 cols)
    char *expected_screen[24];
    int screen_lines = 0;
    int error_pos_line = 0, error_pos_column = 0;
    int test = 0, n = 0, line = 0;
    uint64_t max_cycles = 20000000;
    char lbuf[256];
    while ( 0 != fgets(lbuf, sizeof(lbuf)-1, f) )
    {
        line ++;
        if ( !*lbuf || *lbuf == '\n' )
            continue;

        char key[48], buf[256];
        n = sscanf(lbuf, "%15[^:]: %255[^\n\r]", key, buf);
        if (n < 1)
        {
            fprintf(stderr, "%s:%d: error, can't parse 'key: value'\n", fname, line);
            return -1;
        }
        else if (!strcasecmp(key, "name"))
            name = strdup(buf);
        else if (!strcasecmp(key, "test"))
        {
            // Split into words by ',' '-' or spaces
            for( char *p = buf, *tok; (tok = strtok(p, " \t-,")) ; p = NULL)
            {
                if (!strcasecmp(tok, "run"))
                    test = test_cross | test_native | test_fp | test_int | test_run;
                else if (!strcasecmp(tok, "fp"))
                    test = (test | test_fp) & ~test_int;
                else if (!strcasecmp(tok, "int"))
                    test = (test | test_int) & ~test_fp;
                else if (!strcasecmp(tok, "cross"))
                    test = test & ~test_native;
                else if (!strcasecmp(tok, "native"))
                    test = test & ~test_cross;
                else if (!strcasecmp(tok, "compile"))
                    test = test_cross | test_native | test_fp | test_int;
                else if (!strcasecmp(tok, "editor"))
                    // Runs the IDE; the initial buffer comes from Document:
                    test = test_editor | test_fp;
                else if (!strcasecmp(tok, "error"))
                    test |= test_compile_error;
                else
                {
                    fprintf(stderr, "%s:%d: error, unknown test '%s'\n", fname, line, buf);
                    return -1;
                }
            }
        }
        else if (!strcasecmp(key, "error"))
            error_data = strdup(buf);
        else if (!strcasecmp(key, "error-pos"))
        {
            if( 2 != sscanf(buf, "%i : %i", &error_pos_line, &error_pos_column) )
            {
                fprintf(stderr, "%s:%d: error, invalid value for error-pos '%s'\n",
                        fname, line, buf);
                return -1;
            }
        }
        else if (!strcasecmp(key, "max-cycles"))
        {
            char *ep = 0;
            errno = 0;
            max_cycles = strtoul(buf, &ep, 0);
            if( errno == ERANGE || (*ep != 0 && *ep != ' ' && *ep != '\t') )
            {
                fprintf(stderr, "%s:%d: error, invalid value for max-cycles '%s'\n",
                        fname, line, buf);
                return -1;
            }
        }
        else if (!strcasecmp(key, "document"))
        {
            // Initial editor document, only valid for editor tests.
            //   Document: none        start with an empty HELP.TXT
            //   Document: <file>      install an ASCII fixture
            //   Document:              read the inline section below
            if (doc_set)
            {
                fprintf(stderr, "%s:%d: more than one DOCUMENT entry.\n", fname, line);
                return -1;
            }
            doc_set = 1;
            if (n < 2 || !*buf)
            {
                doc_kind = doc_inline;
                doc_data = read_section(f, &line, &doc_len);
                if (!doc_data)
                {
                    fprintf(stderr, "%s:%d: unfinished DOCUMENT section.\n", fname, line);
                    return -1;
                }
            }
            else if (!strcasecmp(buf, "none"))
                doc_kind = doc_none;
            else
            {
                doc_kind = doc_file;
                doc_filename = strdup(buf);
            }
        }
        else if (!strcasecmp(key, "files"))
        {
            // Files to copy into the DOS root before the run
            while ( 0 != fgets(lbuf, sizeof(lbuf)-1, f) )
            {
                line ++;
                size_t l = strlen(lbuf);
                while (l && (lbuf[l-1] == '\n' || lbuf[l-1] == ' ' || lbuf[l-1] == '\t'))
                    lbuf[--l] = 0;
                if (!strcmp(lbuf, "."))
                    break;
                if (!l || nfiles >= 16)
                {
                    fprintf(stderr, "%s:%d: error, invalid FILES entry\n", fname, line);
                    return -1;
                }
                files[nfiles++] = strdup(lbuf);
            }
            if (feof(f))
            {
                fprintf(stderr, "%s:%d: unfinished FILES section.\n", fname, line);
                return -1;
            }
        }
        else if (!strcasecmp(key, "check"))
        {
            // Compare a file written during the session against this content
            if (n < 2 || !*buf)
            {
                fprintf(stderr, "%s:%d: error, missing file name in CHECK\n", fname, line);
                return -1;
            }
            if (nchecks >= 16)
            {
                fprintf(stderr, "%s:%d: error, too many CHECK sections.\n", fname, line);
                return -1;
            }
            checks[nchecks].name = strdup(buf);
            checks[nchecks].data = read_section(f, &line, &checks[nchecks].len);
            if (!checks[nchecks].data)
            {
                fprintf(stderr, "%s:%d: unfinished CHECK section.\n", fname, line);
                return -1;
            }
            nchecks++;
        }
        else if (!strcasecmp(key, "exists"))
        {
            if (n < 2 || !*buf)
            {
                fprintf(stderr, "%s:%d: error, missing file name in EXISTS\n", fname, line);
                return -1;
            }
            if (nexists >= 16)
            {
                fprintf(stderr, "%s:%d: error, too many EXISTS entries.\n", fname, line);
                return -1;
            }
            exists[nexists++] = strdup(buf);
        }
        else if (!strcasecmp(key, "expect-out"))
        {
            if (n < 2 || !*buf)
            {
                fprintf(stderr, "%s:%d: error, missing text in EXPECT-OUT\n", fname, line);
                return -1;
            }
            if (nexpects >= 8)
            {
                fprintf(stderr, "%s:%d: error, too many EXPECT-OUT entries.\n", fname, line);
                return -1;
            }
            expects[nexpects++] = strdup(buf);
        }
        else if (!strcasecmp(key, "screen"))
        {
            if (screen_lines)
            {
                fprintf(stderr, "%s:%d: more than one SCREEN section.\n", fname, line);
                return -1;
            }
            if (n > 1 && *buf)
            {
                fprintf(stderr, "%s:%d: error, extra characters in SCREEN '%s'\n", fname, line, buf);
                return -1;
            }
            while ( 0 != fgets(lbuf, sizeof(lbuf)-1, f) )
            {
                line++;
                if ( !strcmp(lbuf, ".") || !strcmp(lbuf, ".\n") )
                    break;
                if (screen_lines >= 24)
                {
                    fprintf(stderr, "%s:%d: error, too many SCREEN lines (max 24).\n", fname, line);
                    return -1;
                }
                size_t l = strlen(lbuf);
                // Trim trailing newline
                if (l && lbuf[l-1] == '\n')
                    lbuf[--l] = 0;
                // Trim trailing spaces
                while (l && lbuf[l-1] == ' ')
                    lbuf[--l] = 0;
                // Expand notation
                size_t elen;
                char *line_buf = expand_notation(strdup(lbuf), &elen);
                expected_screen[screen_lines++] = line_buf;
            }
            if (feof(f))
            {
                fprintf(stderr, "%s:%d: unfinished SCREEN section.\n", fname, line);
                return -1;
            }
        }
        else if (!strcasecmp(key, "input"))
        {
            size_t input_size = 0;
            if (n > 1 && *buf)
            {
                fprintf(stderr, "%s:%d: error, extra characters in INPUT '%s'\n", fname, line, buf);
                return -1;
            }
            if (input_buf)
            {
                fprintf(stderr, "%s:%d: more than one INPUT section.\n", fname, line);
                free(input_buf);
                return -1;
            }
            // Get the rest of the file until the end
            input_buf = calloc(8192, 1);
            // Read lines
            while ( 0 != fgets(lbuf, sizeof(lbuf)-1, f) )
            {
                line++;
                if ( !strcmp(lbuf, ".") || !strcmp(lbuf, ".\n") )
                    break;
                size_t l = strlen(lbuf);
                if (l + input_size > 8191)
                {
                    fprintf(stderr, "%s:%d: error, extra characters in output '%s'\n", fname, line, buf);
                    free(input_buf);
                    return -1;
                }
                if (l && (lbuf[l-1] == '\n'))
                        lbuf[l-1] = 0x9B;
                memcpy(input_buf + input_size, lbuf, l);
                input_size += l;
            }
            input_buf[input_size] = 0;
            input_len = input_size;
            if (feof(f))
            {
                fprintf(stderr, "%s:%d: unfinished INPUT section.\n", fname, line);
                free(input_buf);
                return -1;
            }
        }
        else if (!strcasecmp(key, "output"))
        {
            if (n > 1 && *buf)
            {
                fprintf(stderr, "%s:%d: error, extra characters in OUTPUT '%s'\n", fname, line, buf);
                free(input_buf);
                return -1;
            }
            // Get the rest of the file until the end
            expected_out = calloc(65536, 1);
            size_t len = fread(expected_out, 1, 65535, f);
            if (len >= 65535)
            {
                fprintf(stderr, "%s: error, output text too long.\n", fname);
                free(input_buf);
                return -1;
            }
            // Editor tests compare the screen and files, not the output
            else if (len < 1 && !(test & test_editor))
            {
                fprintf(stderr, "%s: error, no output.\n", fname);
                free(input_buf);
                return -1;
            }
            expected_out[len] = 0;
            break;
        }
        else
        {
            fprintf(stderr, "%s:%d: error, unknown key '%s'\n", fname, line, key);
            return -1;
        }
    }
    fclose(f);

    // Check test specs
    if (!test)
    {
        fprintf(stderr, "%s: error, no test to run\n", fname);
        return -1;
    }
    if (!name)
        name = "unnamed";
    if (doc_set && !(test & test_editor))
    {
        fprintf(stderr, "%s: error, DOCUMENT is only valid for editor tests\n", fname);
        return -1;
    }
    if (!expected_out)
        expected_out = strdup("");
    if (!input_buf)
    {
        input_buf = strdup("");
        input_len = 0;
    }
    // Expand ^X, <NAME>, \xHH notation after the whole file is parsed, so
    // header keys may appear in any order.  In editor tests, the final EOL
    // of the Input section is a section separator, not a RETURN keystroke.
    {
        size_t expanded_len;
        input_buf = expand_notation(input_buf, &expanded_len);
        input_len = expanded_len;
    }
    if ((test & test_editor) && input_len &&
        (unsigned char)input_buf[input_len - 1] == 0x9B)
        input_len--;
    if (error_data && !(test & test_compile_error))
    {
        fprintf(stderr, "%s: error data but no compile error expected\n", fname);
        return -1;
    }
    if ((test & test_compile_error) && !error_data)
        error_data = strdup("");

    // Get file names from test file
    const char *ext = strrchr(fname, '.');
    if (!ext)
        ext = fname + strlen(fname);

    // base_name: file name without extension
    char *base_name = strndup(fname, ext - fname);

    // tag_name: file name without directory and extension
    char *tag_name = strrchr(base_name, '/');
    if( !tag_name )
        tag_name = base_name;
    else
        tag_name = tag_name + 1;

    // srcdir: directory containing the test files
    char *srcdir = (tag_name != base_name) ?
        strndup(fname, tag_name - base_name - 1) : strdup(".");

    // basname: input basic file name
    char *basname = source_fname(base_name, "bas");
    // atbname: BASIC file converted to ATASCII
    char *atbname = build_fname(tag_name, "atb");
    // xexname: XEX file name (compiled from the cross-compiler)
    char *xexname = build_fname(tag_name, "xex");
    // comname: COM file name (compiled from the native compiler)
    char *comname = build_fname(tag_name, "com");
    // romname: ROM file name
    char *romname = build_fname(tag_name, "rom");
    // asmname: Assembler file name
    char *asmname = build_fname(tag_name, "asm");
    // objname: Object file name
    char *objname = build_fname(tag_name, "o");

    // Generate ATASCII file for normal (non-editor) tests.  Editor tests
    // use the Document: section instead of the paired .bas file.
    if (!(test & test_editor))
        atascii_convert(basname, atbname);

    // Ok, do tests
    int test_ok = 0;
    char *cmd_out = calloc(65536, 1);

    do
    {
        if (0 != (test & test_editor))
        {
            const char *ide = (test & test_int) ? fb_atari_ide_int : fb_atari_ide_fp;
            if (verbose)
                fprintf(stderr, "%s: run editor '%s'\n", fname, ide);

            // Each editor test gets its own DOS root, always under build/.
            MKDIR(output_dir);
            char *test_root;
            if (asprintf(&test_root, "%s/%s", output_dir, tag_name) < 0)
                exit(1);
            MKDIR(test_root);
            char *help_txt;
            if (asprintf(&help_txt, "%s/HELP.TXT", test_root) < 0)
                exit(1);

            // Setup the initial document and extra files in the DOS root.
            int e = 0;
            unlink(help_txt);
            for (int i = 0; i < nfiles; i++)
                unlink_in(test_root, files[i]);
            for (int i = 0; i < nchecks; i++)
                unlink_in(test_root, checks[i].name);
            for (int i = 0; i < nexists; i++)
                unlink_in(test_root, exists[i]);

            if (doc_kind == doc_file)
            {
                if (copy_fixture_to(srcdir, doc_filename, help_txt))
                {
                    fprintf(stderr, "%s: can't install document '%s'.\n",
                            fname, doc_filename);
                    e = -1;
                }
            }
            else
            {
                FILE *fh = fopen(help_txt, "wb");
                if (!fh)
                {
                    fprintf(stderr, "%s: can't create '%s'.\n", fname, help_txt);
                    e = -1;
                }
                else
                {
                    if (doc_kind == doc_inline && doc_len)
                    {
                        // The newline before the section terminator is not
                        // part of the document.  Add an empty line before the
                        // terminator to keep a trailing EOL.
                        size_t len = doc_len;
                        if ((unsigned char)doc_data[len - 1] == 0x9B)
                            len--;
                        if (fwrite(doc_data, 1, len, fh) != len)
                            e = -1;
                    }
                    fclose(fh);
                }
            }
            for (int i = 0; !e && i < nfiles; i++)
            {
                unlink_in(test_root, files[i]);
                if (dos_copy_file(srcdir, files[i], test_root))
                {
                    fprintf(stderr, "%s: can't install file '%s'.\n",
                            fname, files[i]);
                    e = -1;
                }
            }

            // Run the IDE with the keystroke script
            size_t len = 65536;
            char *out = calloc(len + 1, 1);
            if (!e)
            {
                str_stop_on_eof = 1;
                e = run_atari_prog(ide, out, &len, input_buf, input_len,
                                   max_cycles, 0, 0, 0, test_root);
                str_stop_on_eof = 0;
            }
            // Cursor state is exposed for diagnostics only: the screen
            // accessor already includes the visible cursor glyph.
            int cur_row, cur_col;
            atario_cursor_get(&cur_row, &cur_col);

            // Dump final E: screen state as raw ATASCII bytes for hex analysis.
            if (getenv("FB_DUMP_SCREEN"))
            {
                char *dump;
                if (asprintf(&dump, "%s/%s.screen", output_dir, tag_name) >= 0)
                {
                    FILE *fd = fopen(dump, "wb");
                    if (fd)
                    {
                        for (int r = 0; r < 24; r++)
                        {
                            for (int c = 0; c < 40; c++)
                                putc(atari_screen_get(r, c), fd);
                            putc('\n', fd);
                        }
                        fclose(fd);
                    }
                    free(dump);
                }
            }
            if (!e && screen_lines)
            {
                // Compare expected screen against the actual screen buffer.
                // atari_screen_get() includes the cursor glyph, so it must
                // not be XORed again here.
                for (int r = 0; !e && r < screen_lines; r++)
                {
                    char actual[41];
                    for (int c = 0; c < 40; c++)
                        actual[c] = atari_screen_get(r, c);
                    actual[40] = 0;
                    int alen = 40;
                    while (alen > 0 && actual[alen - 1] == ' ')
                        alen--;
                    actual[alen] = 0;
                    if (strcmp(expected_screen[r], actual))
                    {
                        fprintf(stderr, "%s: SCREEN row %d mismatch:\n", fname, r);
                        fprintf(stderr, "  expected: '%s'\n", expected_screen[r]);
                        fprintf(stderr, "  actual:   '%s'\n", actual);
                        fprintf(stderr, "  cursor:   %d,%d\n", cur_row, cur_col);
                        fprintf(stderr, "  screen:   ");
                        print_screen_row_utf8(stderr, r);
                        fprintf(stderr, "\n");
                        e = -1;
                    }
                }
            }
            if (!e && *expected_out)
                e = check_output(fname, expected_out, out);

            // Dump captured output stream, to debug editor test scripts.
            if (getenv("FB_DUMP_OUTPUT"))
            {
                char *dumpo;
                if (asprintf(&dumpo, "%s/%s.output", output_dir, tag_name) >= 0)
                {
                    FILE *fd = fopen(dumpo, "wb");
                    if (fd)
                    {
                        fwrite(out, 1, strlen(out), fd);
                        fclose(fd);
                    }
                    free(dumpo);
                }
            }
            // Check expected substrings of the captured output stream
            for (int i = 0; !e && i < nexpects; i++)
            {
                if (!strstr(out, expects[i]))
                {
                    fprintf(stderr, "%s: '%s' not found on output.\n",
                            fname, expects[i]);
                    e = -1;
                }
            }

            // Check the contents of files written during the session
            for (int i = 0; !e && i < nchecks; i++)
            {
                char *path;
                if (asprintf(&path, "%s/%s", test_root, checks[i].name) < 0)
                    exit(1);
                FILE *fc = fopen(path, "rb");
                free(path);
                char *got = 0;
                size_t rlen = 0;
                if (fc)
                {
                    fseek(fc, 0, SEEK_END);
                    long sz = ftell(fc);
                    fseek(fc, 0, SEEK_SET);
                    got = calloc(sz + 1, 1);
                    rlen = fread(got, 1, sz, fc);
                    fclose(fc);
                }
                if (!got)
                {
                    fprintf(stderr, "%s: can't open checked file '%s'.\n",
                            fname, checks[i].name);
                    e = -1;
                }
                else if (rlen != checks[i].len ||
                         memcmp(got, checks[i].data, rlen))
                {
                    size_t d = 0;
                    while (d < rlen && d < checks[i].len &&
                           got[d] == checks[i].data[d])
                        d++;
                    fprintf(stderr,
                            "%s: file '%s' does not match: %lu bytes vs %lu "
                            "expected, first difference at byte %lu.\n",
                            fname, checks[i].name, (unsigned long)rlen,
                            (unsigned long)checks[i].len, (unsigned long)d);
                    e = -1;
                }
                free(got);
            }

            // Check that files were created during the session
            for (int i = 0; !e && i < nexists; i++)
            {
                char *path;
                if (asprintf(&path, "%s/%s", test_root, exists[i]) < 0)
                    exit(1);
                FILE *fx = fopen(path, "rb");
                free(path);
                if (!fx)
                {
                    fprintf(stderr, "%s: file '%s' not created.\n",
                            fname, exists[i]);
                    e = -1;
                }
                else
                    fclose(fx);
            }

            if (e > 0)
                fprintf(stderr, "%s: unexpected stack value.\n", fname);
            else if (e < 0)
                fprintf(stderr, "%s: error on editor execution.\n", fname);
            free(out);
            free(help_txt);
            free(test_root);
            if (e)
                break;
        }
        if (0 != (test & test_native) && 0 != (test & test_fp))
        {
            if (verbose)
                fprintf(stderr, "%s: compile fp native\n", fname);
            // Floating Point: native
            if (compile_native(atbname, comname, error_data, 1))
                break;

            if (test & test_run)
            {
                if (verbose)
                    fprintf(stderr, "%s: run fp native\n", fname);
                // Now, runs and checks XEX
                if (run_test_xex(comname, input_buf, expected_out, max_cycles, 0))
                    break;
            }
        }
        if (0 != (test & test_native) && 0 != (test & test_int))
        {
            if (verbose)
                fprintf(stderr, "%s: compile int native\n", fname);
            // Integer: native
            if (compile_native(atbname, comname, error_data, 0))
                break;

            if (test & test_run)
            {
                if (verbose)
                    fprintf(stderr, "%s: run int native\n", fname);
                // Now, runs and checks XEX
                if (run_test_xex(comname, input_buf, expected_out, max_cycles, 0))
                    break;
            }
        }
        if (0 != (test & test_fp) && 0 != (test & test_cross))
        {
            // XEX version:
            if (verbose)
                fprintf(stderr, "%s: compile fp cross\n", fname);
            // Floating Point: cross
            if (compile_cross(basname, asmname, objname, xexname, 1,
                              !(test & test_compile_error),
                              error_pos_line, error_pos_column, 0))
                break;

            if (test & test_run)
            {
                if (verbose)
                    fprintf(stderr, "%s: run fp cross\n", fname);
                // Now, runs and checks XEX
                if (run_test_xex(xexname, input_buf, expected_out, max_cycles, 0))
                    break;
            }

            // CARTRIDGE version:
            if (verbose)
                fprintf(stderr, "%s: compile cartridge fp cross\n", fname);
            // Floating Point: cross
            if (compile_cross(basname, asmname, objname, romname, 1,
                              !(test & test_compile_error),
                              error_pos_line, error_pos_column, 1))
                break;

            if (test & test_run)
            {
                if (verbose)
                    fprintf(stderr, "%s: run cartridge fp cross\n", fname);
                // Now, runs and checks ROM
                if (run_test_xex(romname, input_buf, expected_out, max_cycles, 1))
                    break;
            }
        }
        if (0 != (test & test_int) && 0 != (test & test_cross))
        {
            // XEX version:
            if (verbose)
                fprintf(stderr, "%s: compile int cross\n", fname);
            // Integer: cross
            if (compile_cross(basname, asmname, objname, xexname, 0,
                              !(test & test_compile_error),
                              error_pos_line, error_pos_column, 0))
                break;

            if (test & test_run)
            {
                if (verbose)
                    fprintf(stderr, "%s: run int cross\n", fname);
                // Now, runs and checks XEX
                if (run_test_xex(xexname, input_buf, expected_out, max_cycles, 0))
                    break;
            }

            // CARTRIDGE version:
            if (verbose)
                fprintf(stderr, "%s: compile cartridge int cross\n", fname);
            // Integer: cross
            if (compile_cross(basname, asmname, objname, romname, 0,
                              !(test & test_compile_error),
                              error_pos_line, error_pos_column, 1))
                break;

            if (test & test_run)
            {
                if (verbose)
                    fprintf(stderr, "%s: run cartridge int cross\n", fname);
                // Now, runs and checks ROM
                if (run_test_xex(romname, input_buf, expected_out, max_cycles, 1))
                    break;
            }
        }

        test_ok = 1;
    }
    while(0);

    printf("TEST '%s': %s\n", name,
           test_ok ? "\e[42m passed \e[0m" : "\e[41m not passed \e[0m");
    free(cmd_out);
    free(error_data);
    free(input_buf);
    free(expected_out);
    free(name);
    free(doc_filename);
    free(doc_data);
    free(basname);
    free(atbname);
    free(romname);
    free(xexname);
    free(asmname);
    free(objname);
    free(base_name);
    free(srcdir);
    for (int i = 0; i < nfiles; i++)
        free(files[i]);
    for (int i = 0; i < nchecks; i++)
    {
        free(checks[i].name);
        free(checks[i].data);
    }
    for (int i = 0; i < nexists; i++)
        free(exists[i]);
    for (int i = 0; i < nexpects; i++)
        free(expects[i]);
    for (int i = 0; i < screen_lines; i++)
        free(expected_screen[i]);
    return !test_ok;
}


int main(int argc, char **argv)
{
    int opt;
    while ((opt = getopt(argc, argv, "hvc:i:f:l:a:k:C:")) != -1)
    {
        switch (opt)
        {
            case 'h': // help
                fprintf(stderr, "Usage: %s [options] <test1.chk> ...\n"
                        "Options:\n"
                        " -h: Show this help\n"
                        " -v: Verbose execution\n"
                        " -c <compiler.xex>: Sets path of fp Atari compiler [%s]\n"
                        " -C <compiler.xex>: Sets path of int Atari compiler [%s]\n"
                        " -f <fp-compiler>: Sets path of cross-compiler [%s]\n"
                        " -l <lib-path>: Sets path for the libraries and includes [%s]\n"
                        " -a <ca65-path>: Sets path for the CA65 assembler [%s]\n"
                        " -k <ld65-path>: Sets path for the LD65 linker [%s]\n",
                        argv[0], fb_atari_comp_fp, fb_atari_comp_int, fb_compiler,
                        fb_lib_path, ca65_path, ld65_path);
                return 0;
            case 'v': // verbose
                verbose = 1;
                break;
            case 'a': // CA65 assembler path
                ca65_path = optarg;
                break;
            case 'k': // LD65 linker path
                ld65_path = optarg;
                break;
            case 'c': // atari compiler path
                fb_atari_comp_fp = optarg;
                break;
            case 'C': // atari compiler path
                fb_atari_comp_int = optarg;
                break;
            case 'f': // cross-compiler path
                fb_compiler = optarg;
                break;
            case 'l': // cross libraries path
                fb_lib_path = optarg;
                break;
            default:
                return EXIT_FAILURE;
        }
    }

    int pass = 0, fail = 0;
    for(int i=optind; i<argc; i++)
        if (!fbtest(argv[i]))
            pass ++;
        else
            fail ++;

    if( pass + fail > 1 )
    {
        printf("SUMMARY: ");
        if (fail)
            printf("%d tests passed, %d tests failed.\n", pass, fail);
        else
            printf("all %d tests passed.\n", pass);
    }
    return fail ? EXIT_FAILURE : 0;
}

