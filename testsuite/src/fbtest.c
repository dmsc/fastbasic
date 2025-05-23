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
#include <errno.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#ifdef _WIN32
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
# define PATH_SEP "/"
#endif

// Flags
static int verbose;
static const char *fb_atari_comp_int = "build/bin/fbci.xex";
static const char *fb_atari_comp_fp  = "build/bin/fbc.xex";
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
    else
        return EOF;
}

// Runs atari XEX file capturing the output
static int run_atari_prog(const char *progname, char *output, size_t *output_len,
                          const char *input, size_t input_len, uint64_t max_cycles,
                          int is_rom, const char *cmdline)
{
    // Init input/output
    str_in = input;
    str_in_pos = 0;
    str_in_len = input_len;
    str_out = output;
    str_out_pos = 0;
    str_out_len = *output_len - 1;
    memset(str_out, 0, *output_len);
    // Init emulator
    sim65 s = sim65_new();
    if (!s)
        return -1;
    // sim65_set_debug(s, sim65_debug_trace);
    emu_options opts = {
        .get_char = str_get_char, .put_char = str_put_char, .flags = atari_opt_cycletime
    };
    atari_init(s, &opts);
    // Add command line
    atari_dos_add_cmdline(s, progname);
    if (cmdline)
        atari_dos_add_cmdline(s, cmdline);
    // Set DOS path
    atari_dos_set_root(s, output_dir);
    // Use 0 as left-margin value, to normalize results
    unsigned char val = 0;
    sim65_add_data_ram(s, 0x52, &val, 1); // LMARGN
    sim65_add_data_ram(s, 0x55, &val, 1); // COLCRS

    sim65_set_cycle_limit(s, max_cycles);
    enum sim65_error e;
    if( is_rom )
        e = atari_rom_load(s, 0xA000, progname);
    else
        e = atari_xex_load(s, progname, 1);
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

// Run's an XEX file testing if the output matches the expected output
int run_test_xex(const char *fname, const char *input, const char *expected_out,
                 uint64_t max_cycles, int rom)
{
    size_t len = strlen(expected_out) + 128;
    char *out = calloc(len + 1, 1);

    int e = run_atari_prog(fname, out, &len, input, strlen(input), max_cycles, rom, 0);
    if (!e)
    {
        // Check
        if (strcmp(expected_out, out))
        {
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
            e = -1;
        }
    }
    else if (e > 0)
        fprintf(stderr,"%s: unexpected stack value.\n", fname);
    else
        fprintf(stderr, "%s: error on execution.\n", fname);
    free(out);
    return e;
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
    int e = run_atari_prog(compiler, out, &len, 0, 0, MAX_FPC_CYCLES, 0, cmd);

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
    test_compile_error = 32
};

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
    int error_pos_line = 0, error_pos_column = 0;
    int test = 0, n = 0, line = 0;
    uint64_t max_cycles = 20000000;
    char lbuf[256];
    while ( 0 != fgets(lbuf, sizeof(lbuf)-1, f) )
    {
        line ++;
        if ( !*lbuf || *lbuf == '\n' )
            continue;

        char key[16], buf[256];
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
            else if(len < 1)
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
    if (!expected_out)
        expected_out = strdup("");
    if (!input_buf)
        input_buf = strdup("");
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

    // Generate ATASCII file
    atascii_convert(basname, atbname);

    // Ok, do tests
    int test_ok = 0;
    char *cmd_out = calloc(65536, 1);

    do
    {
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
    free(basname);
    free(atbname);
    free(romname);
    free(xexname);
    free(asmname);
    free(objname);
    free(base_name);
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

