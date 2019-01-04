#
#  FastBasic - Fast basic interpreter for the Atari 8-bit computers
#  Copyright (C) 2017,2018 Daniel Serpell
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

# Set "CROSS" to the compiler prefix, forces compilation of two compilers, one
# native and one for the cross-target.
CROSS=
EXT=
SHEXT=
CXX=g++
CXXFLAGS=-O2 -Wall
SYNTFLAGS=
SYNTFP=-DFASTBASIC_FP
FPASM=--asm-define FASTBASIC_FP --asm-include-dir gen/fp
INTASM=--asm-include-dir gen/int
FPCXX=-DFASTBASIC_FP -Igen/fp
INTCXX=-Igen/int

# Cross
CL65OPTS=-g -tatari -Ccompiler/fastbasic.cfg

ATR=build/fastbasic.atr
ZIPFILE=build/fastbasic.zip
PROGS=bin/fb.xex bin/fbi.xex
NATIVE_INT=bin/fastbasic-int
NATIVE_FP=bin/fastbasic-fp
CROSS_INT=compiler/fastbasic-int$(EXT)
CROSS_FP=compiler/fastbasic-fp$(EXT)
LIB_INT=compiler/fastbasic-int.lib
LIB_FP=compiler/fastbasic-fp.lib

NATIVES=$(NATIVE_INT) $(NATIVE_FP)

# Sample programs
SAMPLE_FP_BAS=\
    fp/ahlbench.bas \
    fp/draw.bas \

SAMPLE_INT_BAS=\
    int/pi.bas \
    int/carrera3d.bas \
    int/pmtest.bas \
    int/sieve.bas \

SAMPLE_BAS=$(SAMPLE_INT_BAS) $(SAMPLE_FP_BAS)
SAMPLE_X_BAS=$(SAMPLE_FP_BAS:fp/%=%) $(SAMPLE_INT_BAS:int/%=%)

# Test programs
TEST_BAS=\
    testio.bas \
    testproc.bas \
    testusr.bas \

# Output files inside the ATR
FILES=\
    disk/fb.com \
    disk/fbc.com \
    disk/fbi.com \
    disk/readme \
    disk/manual.txt \
    disk/startup.bat \
    disk/help.txt \
    $(TEST_BAS:%=disk/%) \
    $(SAMPLE_X_BAS:%=disk/%) \
    $(SAMPLE_X_BAS:%.bas=disk/%.com) \

# BW-DOS files to copy inside the ATR
DOSDIR=disk/dos/
DOS=\
    xbw130.dos\
    copy.com\
    pause.com\

# ASM files used in the RUNTIME
RT_AS_SRC=\
    src/standalone.asm\

# ASM files used in the IDE and Command Line compiler
COMPILER_AS_SRC=\
    src/actions.asm\
    src/errors.asm\
    src/parse.asm\
    src/vars.asm\

# ASM files used in the IDE
IDE_AS_SRC=$(COMPILER_AS_SRC)\
    src/menu.asm\

# ASM files used in the Command Line compiler
CMD_AS_SRC=$(COMPILER_AS_SRC)\
    src/cmdmenu.asm\

# Common ASM files
COMMON_AS_SRC=\
    src/alloc.asm\
    src/clearmem.asm\
    src/exehdr.asm\
    src/interpreter.asm\
    src/memptr.asm\
    src/interp/absneg.asm\
    src/interp/addsub.asm\
    src/interp/bgetput.asm\
    src/interp/bitand.asm\
    src/interp/bitexor.asm\
    src/interp/bitor.asm\
    src/interp/cdata.asm\
    src/interp/close.asm\
    src/interp/chr.asm\
    src/interp/cmpstr.asm\
    src/interp/comp0.asm\
    src/interp/const.asm\
    src/interp/copystr.asm\
    src/interp/dec.asm\
    src/interp/dim.asm\
    src/interp/div.asm\
    src/interp/dpeek.asm\
    src/interp/dpoke.asm\
    src/interp/drawto.asm\
    src/interp/for.asm\
    src/interp/for_exit.asm\
    src/interp/free.asm\
    src/interp/getkey.asm\
    src/interp/graphics.asm\
    src/interp/inc.asm\
    src/interp/input.asm\
    src/interp/iochn.asm\
    src/interp/ioget.asm\
    src/interp/jump.asm\
    src/interp/land.asm\
    src/interp/lnot.asm\
    src/interp/lor.asm\
    src/interp/move.asm\
    src/interp/mset.asm\
    src/interp/mul.asm\
    src/interp/negax.asm\
    src/interp/nmove.asm\
    src/interp/pause.asm\
    src/interp/peek.asm\
    src/interp/poke.asm\
    src/interp/print_eol.asm\
    src/interp/print_str.asm\
    src/interp/print_tab.asm\
    src/interp/push.asm\
    src/interp/putchar.asm\
    src/interp/rand.asm\
    src/interp/return.asm\
    src/interp/sgn.asm\
    src/interp/shl8.asm\
    src/interp/soundoff.asm\
    src/interp/str.asm\
    src/interp/streol.asm\
    src/interp/strindex.asm\
    src/interp/time.asm\
    src/interp/ushl.asm\
    src/interp/usr.asm\
    src/interp/val.asm\
    src/interp/varaddr.asm\
    src/interp/xio.asm\

# FP Interpreter ASM files
FP_AS_SRC=\
    src/interp/fp_abs.asm\
    src/interp/fp_atn.asm\
    src/interp/fp_cmp.asm\
    src/interp/fp_coef.asm\
    src/interp/fp_const.asm\
    src/interp/fp_div.asm\
    src/interp/fp_evalpoly.asm\
    src/interp/fp_exp.asm\
    src/interp/fp_exp10.asm\
    src/interp/fp_int.asm\
    src/interp/fp_intfp.asm\
    src/interp/fp_ipow.asm\
    src/interp/fp_load.asm\
    src/interp/fp_log.asm\
    src/interp/fp_log10.asm\
    src/interp/fp_mul.asm\
    src/interp/fp_pop.asm\
    src/interp/fp_push.asm\
    src/interp/fp_rnd.asm\
    src/interp/fp_set1.asm\
    src/interp/fp_sgn.asm\
    src/interp/fp_sincos.asm\
    src/interp/fp_sqrt.asm\
    src/interp/fp_store.asm\
    src/interp/fp_str.asm\
    src/interp/fp_sub.asm\
    src/interp/fp_val.asm\
    src/interp/fpmain.asm\

# BAS editor source
IDE_BAS_SRC=\
    src/editor.bas\

# BAS command line source
CMD_BAS_SRC=\
    src/cmdline.bas\

# Object files
RT_OBJS_FP=$(RT_AS_SRC:src/%.asm=obj/fp/%.o)
IDE_OBJS_FP=$(IDE_AS_SRC:src/%.asm=obj/fp/%.o)
CMD_OBJS_FP=$(CMD_AS_SRC:src/%.asm=obj/fp/%.o)
COMMON_OBJS_FP=$(COMMON_AS_SRC:src/%.asm=obj/fp/%.o) $(FP_AS_SRC:src/%.asm=obj/fp/%.o)
IDE_BAS_OBJS_FP=$(IDE_BAS_SRC:src/%.bas=obj/fp/%.o)
CMD_BAS_OBJS_FP=$(CMD_BAS_SRC:src/%.bas=obj/fp/%.o)

RT_OBJS_INT=$(RT_AS_SRC:src/%.asm=obj/int/%.o)
IDE_OBJS_INT=$(IDE_AS_SRC:src/%.asm=obj/int/%.o)
COMMON_OBJS_INT=$(COMMON_AS_SRC:src/%.asm=obj/int/%.o)
IDE_BAS_OBJS_INT=$(IDE_BAS_SRC:src/%.bas=obj/int/%.o)
SAMP_OBJS=$(SAMPLE_BAS:%.bas=obj/%.o)

# Compiler library files
COMPILER=\
	 $(CROSS_INT)\
	 $(LIB_INT)\
	 $(CROSS_FP)\
	 $(LIB_FP)\
	 compiler/fastbasic.cfg\
	 compiler/fb$(SHEXT)\
	 compiler/fb-int$(SHEXT)\
	 compiler/USAGE.md\
	 compiler/LICENSE\
	 compiler/MANUAL.md\

# All Output files
OBJS=$(RT_OBJS_FP) $(IDE_OBJS_FP) $(COMMON_OBJS_FP) $(IDE_BAS_OBJS_FP) $(CMD_BAS_OBSJ_FP) \
     $(RT_OBJS_INT) $(IDE_OBJS_INT) $(COMMON_OBJS_INT) $(IDE_BAS_OBJS_INT) \
     $(SAMP_OBJS)
LSTS=$(OBJS:%.o=%.lst)

MAPS=$(PROGS:.xex=.map) $(SAMPLE_X_BAS:%.bas=bin/%.map)
LBLS=$(PROGS:.xex=.lbl) $(SAMPLE_X_BAS:%.bas=bin/%.lbl)
SYNT=gen/synt
CSYNT=gen/csynt

all: $(ATR) $(NATIVES) $(COMPILER)

dist: $(ATR) $(ZIPFILE)

clean:
	rm -f $(OBJS) $(LSTS) $(FILES) $(ATR) $(ZIPFILE) $(PROGS) $(MAPS) $(LBLS) $(SYNT) $(CSYNT) $(CROSS_INT) $(CROSS_FP) $(LIB_INT) $(LIB_FP)

distclean: clean
	rm -f gen/int/basic.asm gen/fp/basic.asm \
	    gen/int/basic.cc gen/fp/basic.cc \
	    gen/int/basic.h  gen/fp/basic.h  \
	    gen/int/basic.inc  gen/fp/basic.inc  \
	    $(IDE_BAS_SRC:src/%.bas=gen/fp/%.asm) \
	    $(CMD_BAS_SRC:src/%.bas=gen/fp/%.asm) \
	    $(IDE_BAS_SRC:src/%.bas=gen/int/%.asm) \
	    $(SAMPLE_BAS:%.bas=gen/%.asm) \
	    $(NATIVES)
	-rmdir gen/fp gen/int obj/fp/interp obj/int/interp obj/fp obj/int
	-rmdir bin gen obj

# Build an ATR disk image using "mkatr".
$(ATR): $(DOS:%=$(DOSDIR)/%) $(FILES) | build
	mkatr $@ $(DOSDIR) -b $^

# Build compiler ZIP file.
$(ZIPFILE): $(COMPILER) | build
	$(CROSS)strip $(CROSS_INT)
	$(CROSS)strip $(CROSS_FP)
	zip -9vj $@ $(COMPILER)

# BAS sources also transformed to ATASCII (replace $0A with $9B)
disk/%.bas: samples/fp/%.bas
	tr '\n' '\233' < $< > $@

disk/%.bas: samples/int/%.bas
	tr '\n' '\233' < $< > $@

disk/%.bas: tests/%.bas
	tr '\n' '\233' < $< > $@

# Transform a text file to ATASCII (replace $0A with $9B)
disk/%: %
	tr '\n' '\233' < $< > $@

disk/%.txt: %.md
	LC_ALL=C awk 'BEGIN{for(n=0;n<127;n++)chg[sprintf("%c",n)]=128+n} {l=length($$0);for(i=1;i<=l;i++){c=substr($$0,i,1);if(c=="`"){x=1-x;if(x)c="\002";else c="\026";}else if(x)c=chg[c];printf "%c",c;}printf "\233";}' < $< > $@

# Copy ".XEX" as ".COM"
disk/%.com: bin/%.xex
	cp $< $@

# Parser generator for 6502
$(SYNT): src/synt.cc | gen
	$(CXX) $(CXXFLAGS) -o $@ $<

# Parser generator for C++
$(CSYNT): src/csynt.cc | gen
	$(CXX) $(CXXFLAGS) -o $@ $<

# Native compiler
$(NATIVE_INT): src/compiler/main.cc gen/int/basic.cc | bin
	$(CXX) $(CXXFLAGS) $(INTCXX) -o $@ $<

$(NATIVE_FP): src/compiler/main.cc gen/fp/basic.cc | bin
	$(CXX) $(CXXFLAGS) $(FPCXX) -o $@ $<

# Cross compiler
ifeq ($(CROSS),)
$(CROSS_INT): $(NATIVE_INT)
	cp -f $< $@
else
$(CROSS_INT): src/compiler/main.cc gen/int/basic.cc
	$(CROSS)$(CXX) $(CXXFLAGS) $(INTCXX) -o $@ $<
endif

ifeq ($(CROSS),)
$(CROSS_FP): $(NATIVE_FP)
	cp -f $< $@
else
$(CROSS_FP): src/compiler/main.cc gen/fp/basic.cc
	$(CROSS)$(CXX) $(CXXFLAGS) $(FPCXX) -o $@ $<
endif

# Generator for syntax file - 6502 version - FLOAT
gen/fp/%.asm: src/%.syn $(SYNT) | gen/fp
	$(SYNT) $(SYNTFLAGS) $(SYNTFP) $< -o $@

# Generator for syntax file - 6502 version - INTEGER
gen/int/%.asm: src/%.syn $(SYNT) | gen/int
	$(SYNT) $(SYNTFLAGS) $< -o $@

# Generator for syntax file - C++ version - FLOAT
gen/fp/%.cc: src/%.syn $(CSYNT) | gen/fp
	$(CSYNT) $(SYNTFLAGS) $(SYNTFP) $< -o $@

# Generator for syntax file - C++ version - INTEGER
gen/int/%.cc: src/%.syn $(CSYNT) | gen/int
	$(CSYNT) $(SYNTFLAGS) $< -o $@

# Main program file
bin/fb.xex: $(IDE_OBJS_FP) $(COMMON_OBJS_FP) $(IDE_BAS_OBJS_FP) | bin
	cl65 $(CL65OPTS) -Ln $(@:.xex=.lbl) -vm -m $(@:.xex=.map) -o $@ $^

bin/fbc.xex: $(CMD_OBJS_FP) $(COMMON_OBJS_FP) $(CMD_BAS_OBJS_FP) | bin
	cl65 $(CL65OPTS) -Ln $(@:.xex=.lbl) -vm -m $(@:.xex=.map) -o $@ $^

bin/fbi.xex: $(IDE_OBJS_INT) $(COMMON_OBJS_INT) $(IDE_BAS_OBJS_INT) | bin
	cl65 $(CL65OPTS) -Ln $(@:.xex=.lbl) -vm -m $(@:.xex=.map) -o $@ $^

# Compiled program files
bin/%.xex: obj/fp/%.o $(LIB_FP) | bin
	cl65 $(CL65OPTS) -Ln $(@:.xex=.lbl) -vm -m $(@:.xex=.map) -o $@ $^

bin/%.xex: obj/int/%.o $(LIB_INT) | bin
	cl65 $(CL65OPTS) -Ln $(@:.xex=.lbl) -vm -m $(@:.xex=.map) -o $@ $^

# Generates basic bytecode from source file
gen/fp/%.asm: src/%.bas $(NATIVE_FP) | gen/fp
	$(NATIVE_FP) $< $@

gen/int/%.asm: src/%.bas $(NATIVE_INT) | gen/int
	$(NATIVE_INT) $< $@

gen/fp/%.asm: samples/fp/%.bas $(NATIVE_FP) | gen/fp
	$(NATIVE_FP) $< $@

gen/int/%.asm: samples/int/%.bas $(NATIVE_INT) | gen/int
	$(NATIVE_INT) $< $@

# Object file rules
obj/fp/%.o: src/%.asm | obj/fp obj/fp/interp
	cl65 $(CL65OPTS) $(FPASM) -c -l $(@:.o=.lst) -o $@ $<

obj/fp/%.o: gen/fp/%.asm | obj/fp
	cl65 $(CL65OPTS) $(FPASM) -c -l $(@:.o=.lst) -o $@ $<

obj/int/%.o: src/%.asm | obj/int obj/int/interp
	cl65 $(CL65OPTS) $(INTASM) -c -l $(@:.o=.lst) -o $@ $<

obj/int/%.o: gen/int/%.asm | obj/int
	cl65 $(CL65OPTS) $(INTASM) -c -l $(@:.o=.lst) -o $@ $<

gen obj obj/fp obj/int obj/fp/interp obj/int/interp gen/fp gen/int bin build:
	mkdir -p $@

# Library files
$(LIB_FP): $(RT_OBJS_FP) $(COMMON_OBJS_FP)
	rm -f $@
	ar65 a $@ $^

$(LIB_INT): $(RT_OBJS_INT) $(COMMON_OBJS_INT)
	rm -f $@
	ar65 a $@ $^

# Runs the test suite
.PHONY: test
test: $(COMPILER) bin/fbc.xex
	make -C testsuite

# Copy manual to compiler
compiler/MANUAL.md: manual.md
	cp -f $< $@

# Dependencies
$(COMMON_OBJS_FP): src/deftok.inc
$(COMMON_OBJS_INT): src/deftok.inc
obj/fp/parse.o: src/parse.asm gen/fp/basic.asm
obj/int/parse.o: src/parse.asm gen/int/basic.asm
$(CSYNT): src/csynt.cc src/synt-parse.h src/synt-wlist.h src/synt-sm.h src/synt-emit-cc.h src/synt-read.h
$(SYNT): src/synt.cc src/synt-parse.h src/synt-wlist.h src/synt-sm.h src/synt-emit-asm.h src/synt-read.h
$(NATIVES) $(CROSS_INT) $(CROSS_FP): \
 src/compiler/main.cc src/compiler/atarifp.cc \
 src/compiler/looptype.cc src/compiler/vartype.cc gen/int/basic.cc \
 src/compiler/parser.cc src/compiler/peephole.cc \
 src/compiler/codestat.cc src/compiler/codew.h

