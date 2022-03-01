#
#  FastBasic - Fast basic interpreter for the Atari 8-bit computers
#  Copyright (C) 2017-2022 Daniel Serpell
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License along
#  with this program.  If not, see <http://www.gnu.org/licenses/>
#

# Main rule:
target: all

# Set "CROSS" to the compiler prefix, forces compilation of two compilers, one
# native and one for the cross-target.
CROSS=
CXX=g++
CC=gcc

# Optimization flags, added to C and C++ compiler flags
OPTFLAGS=-O2

# General flags for 6502 assembly files
CA65_FLAGS=-g -tatari -I cc65/asminc -I src

# Flags added to the ROM-able library
CA65_ROM=-DNO_SMCODE

# Flags added to assembly sources for Floating Point / Integer compilers:
CA65_FP_FLAGS=-D FASTBASIC_FP -I build/gen/fp $(CA65_FLAGS)
CA65_INT_FLAGS=-I build/gen/int $(CA65_FLAGS)
CA65_A5200_FLAGS=-g -t atari5200 -I cc65/asminc -I src -DNO_SMCODE

# Flags for the LD65 linker
LD65_FLAGS=-Ccompiler/fastbasic.cfg

# Flags added to C++ sources for Floating Point / Integer compilers:
FB_CXX=-Isrc/compiler

# Flags for the cross compiler, integer and floating-point
FB_INT_FLAGS=-target-path:compiler -syntax-path:src/syntax -t:atari-int
FB_FP_FLAGS=-target-path:compiler -syntax-path:src/syntax -t:atari-fp

# Flags added to the compilation of CC65 tools (CA65, LD65 and AR65):
CC65_CFLAGS=-Icc65/common -DBUILD_ID="fastbasic-$(VERSION)"

# Flags for local tools needed to generate target files
HOST_OPTFLAGS=$(OPTFLAGS)
HOST_CXXFLAGS=-Wall -DVERSION=\"$(VERSION)\" $(HOST_OPTFLAGS)
HOST_CFLAGS=-Wall $(HOST_OPTFLAGS)

# Flags for cross-compilation, could differ from host tools:
TARGET_OPTFLAGS=$(OPTFLAGS)
TARGET_CXXFLAGS=-Wall -DVERSION=\"$(VERSION)\" $(TARGET_OPTFLAGS)
TARGET_CFLAGS=-Wall $(TARGET_OPTFLAGS)

# By default use quiet build
Q=@
ECHO=@printf "\e[0;32m%s\e[0m\n"

# Detect Windows OS and set file extensions:
ifeq ($(strip $(shell echo '_WIN32' | $(CROSS)$(CXX) -E - | grep  "_WIN32")),_WIN32)
    # Linux / OS-X
    EXT=
else
    # Windows:
    EXT=.exe
endif

# Get version string
include version.mk

# Do not delete intermediate files
.SECONDARY:

ATR=build/fastbasic.atr
ZIPFILE=build/fastbasic.zip
PROGS=build/bin/fb.xex build/bin/fbi.xex build/bin/fbc.xex

# To allow cross-compilation (ie, from Linux to Windows), we build two versions
# of the compiler, one for the host (build machine) and one for the target.
FASTBASIC_HOST=build/bin/fastbasic
CA65_HOST=build/bin/ca65
LD65_HOST=build/bin/ld65
AR65_HOST=build/bin/ar65

FASTBASIC_TARGET=build/compiler/fastbasic$(EXT)
CA65_TARGET=build/compiler/ca65$(EXT)
LD65_TARGET=build/compiler/ld65$(EXT)
AR65_TARGET=build/compiler/ar65$(EXT)

LIB_INT=build/compiler/fastbasic-int.lib
LIB_FP=build/compiler/fastbasic-fp.lib
LIB_ROM_INT=build/compiler/fastbasic-cart-int.lib
LIB_ROM_FP=build/compiler/fastbasic-cart-fp.lib
LIB_A5200=build/compiler/fastbasic-5200.lib

# Sample programs
SAMPLE_FP_BAS=\
    fp/ahlbench.bas \
    fp/draw.bas \
    fp/fedora.bas \

SAMPLE_INT_BAS=\
    int/carrera3d.bas \
    int/dli.bas \
    int/iospeed.bas \
    int/joyas.bas \
    int/pi.bas \
    int/pmtest.bas \
    int/sieve.bas \

SAMPLE_BAS=$(SAMPLE_INT_BAS) $(SAMPLE_FP_BAS)
SAMPLE_X_BAS=$(SAMPLE_FP_BAS:fp/%=%) $(SAMPLE_INT_BAS:int/%=%)

# Output files inside the ATR
FILES=\
    build/disk/fb.com \
    build/disk/fbc.com \
    build/disk/fbi.com \
    build/disk/readme \
    build/disk/manual.txt \
    build/disk/startup.bat \
    build/disk/help.txt \
    $(SAMPLE_X_BAS:%=build/disk/%) \
    $(SAMPLE_X_BAS:%.bas=build/disk/%.com) \

# BW-DOS files to copy inside the ATR
DOSDIR=disk/dos/
DOS=\
    xbw130.dos\
    copy.com\
    efast.com\
    pause.com\

# folders with assembly files
AS_FOLDERS=\
    src\
    src/interp\
    src/interp/a800\
    src/interp/atari\
    src/interp/atarifp\
    src/interp/a5200\

# ASM files used in the RUNTIME
RT_AS_SRC=\
    src/standalone.asm\
    src/cartridge.asm\

# ASM files used in the IDE and Command Line compiler
COMPILER_AS_SRC=\
    src/actions.asm\
    src/errors.asm\
    src/memptr.asm\
    src/parse.asm\
    src/vars.asm\

# ASM files used in the IDE
IDE_AS_SRC=$(COMPILER_AS_SRC)\
    src/menu.asm\
    src/countlines.asm\
    src/comp_header.asm\

# ASM files used in the Command Line compiler
CMD_AS_SRC=$(COMPILER_AS_SRC)\
    src/cmdmenu.asm\
    src/comp_header.asm\

# Base ASM files
# NOTE: clearmem should be above other files because it defines
#       TOK_END that should be the first token.
BASE_AS_SRC=\
    src/alloc.asm\
    src/interpreter.asm\
    src/interp/clearmem.asm\
    src/interp/absneg.asm\
    src/interp/addsub.asm\
    src/interp/bitand.asm\
    src/interp/bitexor.asm\
    src/interp/bitor.asm\
    src/interp/chr.asm\
    src/interp/cmpstr.asm\
    src/interp/comp0.asm\
    src/interp/const.asm\
    src/interp/const_poke.asm\
    src/interp/copystr.asm\
    src/interp/dec.asm\
    src/interp/div.asm\
    src/interp/dpeek.asm\
    src/interp/dpoke.asm\
    src/interp/for.asm\
    src/interp/for_exit.asm\
    src/interp/inc.asm\
    src/interp/jump.asm\
    src/interp/land.asm\
    src/interp/lnot.asm\
    src/interp/lor.asm\
    src/interp/move.asm\
    src/interp/mset.asm\
    src/interp/mul.asm\
    src/interp/negax.asm\
    src/interp/nmove.asm\
    src/interp/peek.asm\
    src/interp/peekb.asm\
    src/interp/poke.asm\
    src/interp/pop.asm\
    src/interp/print_str.asm\
    src/interp/push.asm\
    src/interp/put.asm\
    src/interp/putbyte.asm\
    src/interp/return.asm\
    src/interp/saddr.asm\
    src/interp/sgn.asm\
    src/interp/shl8.asm\
    src/interp/strindex.asm\
    src/interp/ushl.asm\
    src/interp/usr.asm\
    src/interp/varadd.asm\
    src/interp/varaddr.asm\
    src/interp/varstore.asm\

# Common Atari specific code
ATARI_AS_SRC=\
    src/interp/atari/color.asm\
    src/interp/atari/pause.asm\
    src/interp/atari/pmgraphics.asm\
    src/interp/atari/position.asm\
    src/interp/atari/print_tab.asm\
    src/interp/atari/rand.asm\
    src/interp/atari/soundoff.asm\
    src/interp/atari/time.asm\

# Atari 8-bit specific code
A800_AS_SRC=\
    $(BASE_AS_SRC)\
    $(ATARI_AS_SRC)\
    src/interp/a800/bgetput.asm\
    src/interp/a800/getkey.asm\
    src/interp/a800/graphics.asm\
    src/interp/a800/input.asm\
    src/interp/a800/iochn.asm\
    src/interp/a800/putchar.asm\
    src/interp/a800/str.asm\
    src/interp/a800/streol.asm\
    src/interp/a800/val.asm\
    src/interp/a800/xio.asm\

# FP Interpreter ASM files
A800_FP_AS_SRC=\
    $(A800_AS_SRC)\
    src/interp/atarifp/fp_coef.asm\
    src/interp/atarifp/fp_abs.asm\
    src/interp/atarifp/fp_atn.asm\
    src/interp/atarifp/fp_cmp.asm\
    src/interp/atarifp/fp_const.asm\
    src/interp/atarifp/fp_div.asm\
    src/interp/atarifp/fp_evalpoly.asm\
    src/interp/atarifp/fp_exp.asm\
    src/interp/atarifp/fp_exp10.asm\
    src/interp/atarifp/fp_int.asm\
    src/interp/atarifp/fp_intfp.asm\
    src/interp/atarifp/fp_ipow.asm\
    src/interp/atarifp/fp_load.asm\
    src/interp/atarifp/fp_log.asm\
    src/interp/atarifp/fp_log10.asm\
    src/interp/atarifp/fp_mul.asm\
    src/interp/atarifp/fp_pop.asm\
    src/interp/atarifp/fp_push.asm\
    src/interp/atarifp/fp_rnd.asm\
    src/interp/atarifp/fp_set1.asm\
    src/interp/atarifp/fp_sgn.asm\
    src/interp/atarifp/fp_sincos.asm\
    src/interp/atarifp/fp_sqrt.asm\
    src/interp/atarifp/fp_store.asm\
    src/interp/atarifp/fp_str.asm\
    src/interp/atarifp/fp_sub.asm\
    src/interp/atarifp/fp_val.asm\
    src/interp/atarifp/fpmain.asm\
    src/interp/atarifp/mul6.asm\

# Atari 5200 specific code
A5200_AS_SRC=\
    $(BASE_AS_SRC)\
    $(ATARI_AS_SRC)\
    src/a5200cart.asm\
    src/interp/a5200/drawto.asm\
    src/interp/a5200/getkey.asm\
    src/interp/a5200/graphics.asm\
    src/interp/a5200/input.asm\
    src/interp/a5200/putchar.asm\
    src/interp/a5200/str.asm\
    src/interp/a5200/val.asm\

# BAS editor source
IDE_BAS_SRC=\
    src/editor.bas\

# BAS command line source
CMD_BAS_SRC=\
    build/gen/cmdline-vers.bas\

# Object files
RT_OBJS_FP=$(RT_AS_SRC:src/%.asm=build/obj/fp/%.o)
IDE_OBJS_FP=$(IDE_AS_SRC:src/%.asm=build/obj/fp/%.o)
CMD_OBJS_FP=$(CMD_AS_SRC:src/%.asm=build/obj/fp/%.o)
A800_FP_OBJS=$(A800_FP_AS_SRC:src/%.asm=build/obj/fp/%.o)
IDE_BAS_OBJS_FP=$(IDE_BAS_SRC:src/%.bas=build/obj/fp/%.o)
CMD_BAS_OBJS_FP=$(CMD_BAS_SRC:build/gen/%.bas=build/obj/fp/%.o)
RT_OBJS_ROM_FP=$(RT_AS_SRC:src/%.asm=build/obj/rom-fp/%.o)
A800_FP_ROM_OBJS=$(A800_FP_AS_SRC:src/%.asm=build/obj/rom-fp/%.o)

RT_OBJS_INT=$(RT_AS_SRC:src/%.asm=build/obj/int/%.o)
IDE_OBJS_INT=$(IDE_AS_SRC:src/%.asm=build/obj/int/%.o)
A800_OBJS=$(A800_AS_SRC:src/%.asm=build/obj/int/%.o)
A5200_OBJS=$(A5200_AS_SRC:src/%.asm=build/obj/a5200/%.o)
IDE_BAS_OBJS_INT=$(IDE_BAS_SRC:src/%.bas=build/obj/int/%.o)
SAMP_OBJS=$(SAMPLE_BAS:%.bas=build/obj/%.o)
RT_OBJS_ROM_INT=$(RT_AS_SRC:src/%.asm=build/obj/rom-int/%.o)
A800_ROM_OBJS=$(A800_AS_SRC:src/%.asm=build/obj/rom-int/%.o)

# Compiler library files
COMPILER_COMMON=\
	 $(LIB_INT)\
	 $(LIB_FP)\
	 $(LIB_ROM_INT)\
	 $(LIB_ROM_FP)\
	 $(LIB_A5200)\
	 build/compiler/fastbasic.cfg\
	 build/compiler/fastbasic-a5200.cfg\
	 build/compiler/fastbasic-cart.cfg\
	 build/compiler/USAGE.md\
	 build/compiler/LICENSE\
	 build/compiler/MANUAL.md\
	 build/compiler/asminc/atari_antic.inc\
	 build/compiler/asminc/atari_gtia.inc\
	 build/compiler/asminc/atari.inc\
	 build/compiler/asminc/atari5200.inc\
	 build/compiler/asminc/atari_pokey.inc\
	 build/compiler/asminc/target.inc\
	 build/compiler/syntax/a5200.syn\
	 build/compiler/syntax/a800.syn\
	 build/compiler/syntax/basic.syn\
	 build/compiler/syntax/dli.syn\
	 build/compiler/syntax/extended.syn\
	 build/compiler/syntax/fileio.syn\
	 build/compiler/syntax/float.syn\
	 build/compiler/syntax/graphics.syn\
	 build/compiler/syntax/gr-a5200.syn\
	 build/compiler/syntax/pm.syn\
	 build/compiler/syntax/sound.syn\
	 build/compiler/a5200.tgt\
	 build/compiler/a800.tgt\
	 build/compiler/atari-5200.tgt\
	 build/compiler/atari-cart-fp.tgt\
	 build/compiler/atari-cart-int.tgt\
	 build/compiler/atari-fp.tgt\
	 build/compiler/atari-int.tgt\
	 build/compiler/default.tgt\

# Compiler source files (C++)
COMPILER_SRC=\
	atarifp.cc\
	codestat.cc\
	compile.cc\
	ifile.cc\
	looptype.cc\
	main.cc\
	os.cc\
	parser.cc\
	parser-actions.cc\
	peephole.cc\
	target.cc\
	vartype.cc\
	synt-optimize.cc\
	synt-parser.cc\
	synt-preproc.cc\
	synt-pstate.cc\
	synt-sm.cc\
	synt-symlist.cc\
	synt-wlist.cc\

# CC65 sources
CA65_SRC=\
	cc65/ca65/anonname.c\
	cc65/ca65/asserts.c\
	cc65/ca65/condasm.c\
	cc65/ca65/dbginfo.c\
	cc65/ca65/ea65.c\
	cc65/ca65/easw16.c\
	cc65/ca65/enum.c\
	cc65/ca65/error.c\
	cc65/ca65/expr.c\
	cc65/ca65/feature.c\
	cc65/ca65/filetab.c\
	cc65/ca65/fragment.c\
	cc65/ca65/global.c\
	cc65/ca65/incpath.c\
	cc65/ca65/instr.c\
	cc65/ca65/istack.c\
	cc65/ca65/lineinfo.c\
	cc65/ca65/listing.c\
	cc65/ca65/macro.c\
	cc65/ca65/main.c\
	cc65/ca65/nexttok.c\
	cc65/ca65/objcode.c\
	cc65/ca65/objfile.c\
	cc65/ca65/options.c\
	cc65/ca65/pseudo.c\
	cc65/ca65/repeat.c\
	cc65/ca65/scanner.c\
	cc65/ca65/segdef.c\
	cc65/ca65/segment.c\
	cc65/ca65/sizeof.c\
	cc65/ca65/span.c\
	cc65/ca65/spool.c\
	cc65/ca65/struct.c\
	cc65/ca65/studyexpr.c\
	cc65/ca65/symbol.c\
	cc65/ca65/symentry.c\
	cc65/ca65/symtab.c\
	cc65/ca65/token.c\
	cc65/ca65/toklist.c\
	cc65/ca65/ulabel.c\
	cc65/common/abend.c\
	cc65/common/addrsize.c\
	cc65/common/alignment.c\
	cc65/common/assertion.c\
	cc65/common/bitops.c\
	cc65/common/chartype.c\
	cc65/common/check.c\
	cc65/common/cmdline.c\
	cc65/common/coll.c\
	cc65/common/cpu.c\
	cc65/common/debugflag.c\
	cc65/common/exprdefs.c\
	cc65/common/filestat.c\
	cc65/common/fname.c\
	cc65/common/gentype.c\
	cc65/common/hashfunc.c\
	cc65/common/hashtab.c\
	cc65/common/intstack.c\
	cc65/common/mmodel.c\
	cc65/common/print.c\
	cc65/common/searchpath.c\
	cc65/common/segnames.c\
	cc65/common/shift.c\
	cc65/common/strbuf.c\
	cc65/common/strpool.c\
	cc65/common/strutil.c\
	cc65/common/target.c\
	cc65/common/tgttrans.c\
	cc65/common/version.c\
	cc65/common/xmalloc.c\
	cc65/common/xsprintf.c\

LD65_SRC=\
	cc65/common/abend.c\
	cc65/common/addrsize.c\
	cc65/common/alignment.c\
	cc65/common/assertion.c\
	cc65/common/chartype.c\
	cc65/common/check.c\
	cc65/common/cmdline.c\
	cc65/common/coll.c\
	cc65/common/exprdefs.c\
	cc65/common/fileid.c\
	cc65/common/filetype.c\
	cc65/common/fname.c\
	cc65/common/gentype.c\
	cc65/common/hashfunc.c\
	cc65/common/hashtab.c\
	cc65/common/print.c\
	cc65/common/searchpath.c\
	cc65/common/strbuf.c\
	cc65/common/strpool.c\
	cc65/common/strutil.c\
	cc65/common/target.c\
	cc65/common/version.c\
	cc65/common/xmalloc.c\
	cc65/common/xsprintf.c\
	cc65/ld65/asserts.c\
	cc65/ld65/bin.c\
	cc65/ld65/binfmt.c\
	cc65/ld65/cfgexpr.c\
	cc65/ld65/condes.c\
	cc65/ld65/config.c\
	cc65/ld65/dbgfile.c\
	cc65/ld65/dbgsyms.c\
	cc65/ld65/error.c\
	cc65/ld65/exports.c\
	cc65/ld65/expr.c\
	cc65/ld65/extsyms.c\
	cc65/ld65/fileinfo.c\
	cc65/ld65/fileio.c\
	cc65/ld65/filepath.c\
	cc65/ld65/fragment.c\
	cc65/ld65/global.c\
	cc65/ld65/library.c\
	cc65/ld65/lineinfo.c\
	cc65/ld65/main.c\
	cc65/ld65/mapfile.c\
	cc65/ld65/memarea.c\
	cc65/ld65/o65.c\
	cc65/ld65/objdata.c\
	cc65/ld65/objfile.c\
	cc65/ld65/scanner.c\
	cc65/ld65/scopes.c\
	cc65/ld65/segments.c\
	cc65/ld65/span.c\
	cc65/ld65/spool.c\
	cc65/ld65/tpool.c\
	cc65/ld65/xex.c\

AR65_SRC=\
	cc65/common/abend.c\
	cc65/common/chartype.c\
	cc65/common/check.c\
	cc65/common/cmdline.c\
	cc65/common/coll.c\
	cc65/common/filestat.c\
	cc65/common/filetime.c\
	cc65/common/fname.c\
	cc65/common/hashfunc.c\
	cc65/common/print.c\
	cc65/common/version.c\
	cc65/common/xmalloc.c\
	cc65/common/xsprintf.c\
	cc65/ar65/add.c\
	cc65/ar65/del.c\
	cc65/ar65/error.c\
	cc65/ar65/exports.c\
	cc65/ar65/extract.c\
	cc65/ar65/fileio.c\
	cc65/ar65/global.c\
	cc65/ar65/library.c\
	cc65/ar65/list.c\
	cc65/ar65/main.c\
	cc65/ar65/objdata.c\
	cc65/ar65/objfile.c\

# Syntax file parser
SYNTAX_PARSER_SRC=\
	synt-emit-asm.cc\
	synt-optimize.cc\
	synt-parser.cc\
	synt-preproc.cc\
	synt-pstate.cc\
	synt-sm.cc\
	synt-symlist.cc\
	synt-wlist.cc\
	syntp.cc\

# Syntax files for integer version
SYNTAX_INT=\
	src/syntax/a800.syn\
	src/syntax/basic.syn\
	src/syntax/dli.syn\
	src/syntax/fileio.syn\
	src/syntax/pm.syn\
	src/syntax/graphics.syn\
	src/syntax/sound.syn\

# Syntax files for floating-point version
SYNTAX_FP=\
	$(SYNTAX_INT)\
	src/syntax/float.syn\

# Host compiler
COMPILER_HOST=\
	 $(CA65_HOST)\
	 $(LD65_HOST)\
	 $(AR65_HOST)\
	 $(FASTBASIC_HOST)\
	 build/bin/fb$(EXT)\

# Target compiler
COMPILER_TARGET=\
	 $(CA65_TARGET)\
	 $(LD65_TARGET)\
	 $(AR65_TARGET)\
	 $(FASTBASIC_TARGET)\
	 build/compiler/fb$(EXT)\

# All ASM Output files
OBJS=$(RT_OBJS_FP) \
     $(IDE_OBJS_FP) $(IDE_BAS_OBJS_FP) \
     $(A800_FP_OBJS) \
     $(A5200_OBJS) \
     $(RT_OBJS_ROM_FP) $(A800_FP_ROM_OBJS) \
     $(CMD_OBJS_FP) $(CMD_BAS_OBJS_FP) \
     $(RT_OBJS_INT) \
     $(IDE_OBJS_INT) $(IDE_BAS_OBJS_INT) \
     $(A800_OBJS) \
     $(RT_OBJS_ROM_INT) $(A800_ROM_OBJS) \
     $(SAMP_OBJS)

# Listing files
LSTS=$(OBJS:%.o=%.lst)

# XEX with Map and Label files
XEXS=$(PROGS) $(SAMPLE_X_BAS:%.bas=build/bin/%.xex)
MAPS=$(PROGS:.xex=.map) $(SAMPLE_X_BAS:%.bas=build/bin/%.map)
LBLS=$(PROGS:.xex=.lbl) $(SAMPLE_X_BAS:%.bas=build/bin/%.lbl)

# The syntax parser, to ASM (for the IDE) and C++ (for the compiler)
SYNTP=build/gen/syntp
SYNTAX_PARSER_OBJ=$(SYNTAX_PARSER_SRC:%.cc=build/obj/cxx/%.o)

# The compiler object files, for FP and INT versions, HOST and TARGET
FASTBASIC_HOST_OBJ=$(COMPILER_SRC:%.cc=build/obj/cxx/%.o)
FASTBASIC_TARGET_OBJ=$(COMPILER_SRC:%.cc=build/obj/cxx-tgt/%.o)

# All folders created during compilation:
BUILD_FOLDERS=\
 $(AS_FOLDERS:src%=build/obj/fp%)\
 $(AS_FOLDERS:src%=build/obj/int%)\
 $(AS_FOLDERS:src%=build/obj/rom-fp%)\
 $(AS_FOLDERS:src%=build/obj/rom-int%)\
 $(AS_FOLDERS:src%=build/obj/a5200%)\
 build/bin\
 build/compiler/asminc\
 build/compiler/syntax\
 build/compiler\
 build/disk\
 build/gen/fp\
 build/gen/int\
 build/gen\
 build/obj/cxx\
 build/obj/cxx-tgt\
 build/obj/tests\
 build/obj\
 build/tests\
 build\


include tests.mak
include rules.mak
include deps.mak
