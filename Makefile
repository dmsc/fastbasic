#
#  FastBasic - Fast basic interpreter for the Atari 8-bit computers
#  Copyright (C) 2017-2019 Daniel Serpell
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
OPTFLAGS=-O2
CXXFLAGS=-Wall -DVERSION=\"$(VERSION)\" $(OPTFLAGS)
SYNTFLAGS=
SYNTFP=-DFASTBASIC_FP
FPASM=--asm-define FASTBASIC_FP --asm-include-dir gen/fp
INTASM=--asm-include-dir gen/int
FPCXX=-DFASTBASIC_FP -Igen/fp -Isrc/compiler
INTCXX=-Igen/int -Isrc/compiler

# Get version string
include version.mk

# Do not delete intermediate files
.SECONDARY:

# Cross
CL65OPTS=-g -tatari -Ccompiler/fastbasic.cfg

ATR=build/fastbasic.atr
ZIPFILE=build/fastbasic.zip
PROGS=bin/fb.xex bin/fbi.xex bin/fbc.xex

# To allow cross-compilation (ie, from Linux to Windows), we build two versions
# of the compiler, one for the host (build machine) and one for the target.
COMPILER_HOST_INT=bin/fastbasic-int
COMPILER_HOST_FP=bin/fastbasic-fp
COMPILER_TARGET_INT=compiler/fastbasic-int$(EXT)
COMPILER_TARGET_FP=compiler/fastbasic-fp$(EXT)
LIB_INT=compiler/fastbasic-int.lib
LIB_FP=compiler/fastbasic-fp.lib

# Sample programs
SAMPLE_FP_BAS=\
    fp/ahlbench.bas \
    fp/draw.bas \
    fp/fedora.bas \

SAMPLE_INT_BAS=\
    int/carrera3d.bas \
    int/iospeed.bas \
    int/joyas.bas \
    int/pi.bas \
    int/pmtest.bas \
    int/sieve.bas \

SAMPLE_BAS=$(SAMPLE_INT_BAS) $(SAMPLE_FP_BAS)
SAMPLE_X_BAS=$(SAMPLE_FP_BAS:fp/%=%) $(SAMPLE_INT_BAS:int/%=%)

# Output files inside the ATR
FILES=\
    disk/fb.com \
    disk/fbc.com \
    disk/fbi.com \
    disk/readme \
    disk/manual.txt \
    disk/startup.bat \
    disk/help.txt \
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
    src/memptr.asm\
    src/parse.asm\
    src/vars.asm\

# ASM files used in the IDE
IDE_AS_SRC=$(COMPILER_AS_SRC)\
    src/menu.asm\

# ASM files used in the Command Line compiler
CMD_AS_SRC=$(COMPILER_AS_SRC)\
    src/cmdmenu.asm\

# Common ASM files
# NOTE: clearmem should be above other files because it defines
#       TOK_END that should be the first token.
COMMON_AS_SRC=\
    src/alloc.asm\
    src/exehdr.asm\
    src/interpreter.asm\
    src/interp/clearmem.asm\
    src/interp/absneg.asm\
    src/interp/addsub.asm\
    src/interp/bgetput.asm\
    src/interp/bitand.asm\
    src/interp/bitexor.asm\
    src/interp/bitor.asm\
    src/interp/cdata.asm\
    src/interp/chr.asm\
    src/interp/cmpstr.asm\
    src/interp/color.asm\
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
    src/interp/getkey.asm\
    src/interp/graphics.asm\
    src/interp/inc.asm\
    src/interp/input.asm\
    src/interp/iochn.asm\
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
    src/interp/plot.asm\
    src/interp/pmgraphics.asm\
    src/interp/poke.asm\
    src/interp/position.asm\
    src/interp/print_str.asm\
    src/interp/print_tab.asm\
    src/interp/push.asm\
    src/interp/put.asm\
    src/interp/putchar.asm\
    src/interp/rand.asm\
    src/interp/return.asm\
    src/interp/saddr.asm\
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
    src/interp/varstore.asm\
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
    src/interp/mul6.asm\

# BAS editor source
IDE_BAS_SRC=\
    src/editor.bas\

# BAS command line source
CMD_BAS_SRC=\
    gen/cmdline-vers.bas\

# Object files
RT_OBJS_FP=$(RT_AS_SRC:src/%.asm=obj/fp/%.o)
IDE_OBJS_FP=$(IDE_AS_SRC:src/%.asm=obj/fp/%.o)
CMD_OBJS_FP=$(CMD_AS_SRC:src/%.asm=obj/fp/%.o)
COMMON_OBJS_FP=$(COMMON_AS_SRC:src/%.asm=obj/fp/%.o) $(FP_AS_SRC:src/%.asm=obj/fp/%.o)
IDE_BAS_OBJS_FP=$(IDE_BAS_SRC:src/%.bas=obj/fp/%.o)
CMD_BAS_OBJS_FP=$(CMD_BAS_SRC:gen/%.bas=obj/fp/%.o)

RT_OBJS_INT=$(RT_AS_SRC:src/%.asm=obj/int/%.o)
IDE_OBJS_INT=$(IDE_AS_SRC:src/%.asm=obj/int/%.o)
COMMON_OBJS_INT=$(COMMON_AS_SRC:src/%.asm=obj/int/%.o)
IDE_BAS_OBJS_INT=$(IDE_BAS_SRC:src/%.bas=obj/int/%.o)
SAMP_OBJS=$(SAMPLE_BAS:%.bas=obj/%.o)

# Compiler library files
COMPILER_COMMON=\
	 $(LIB_INT)\
	 $(LIB_FP)\
	 compiler/fastbasic.cfg\
	 compiler/fb$(SHEXT)\
	 compiler/fb-int$(SHEXT)\
	 compiler/USAGE.md\
	 compiler/LICENSE\
	 compiler/MANUAL.md\

# Compiler source files (C++)
COMPILER_SRC=\
	atarifp.cc\
	basic.cc\
	codestat.cc\
	looptype.cc\
	main.cc\
	parser.cc\
	peephole.cc\
	vartype.cc\

# Host compiler
COMPILER_HOST=\
	 $(COMPILER_HOST_INT)\
	 $(COMPILER_HOST_FP)

# Target compiler
COMPILER_TARGET=\
	 $(COMPILER_TARGET_INT)\
	 $(COMPILER_TARGET_FP)

# All ASM Output files
OBJS=$(RT_OBJS_FP) \
     $(IDE_OBJS_FP) $(IDE_BAS_OBJS_FP) \
     $(COMMON_OBJS_FP) \
     $(CMD_OBJS_FP) $(CMD_BAS_OBJS_FP) \
     $(RT_OBJS_INT) \
     $(IDE_OBJS_INT) $(IDE_BAS_OBJS_INT) \
     $(COMMON_OBJS_INT) \
     $(SAMP_OBJS)

# Listing files
LSTS=$(OBJS:%.o=%.lst)

# Map and Label files for the XEX
MAPS=$(PROGS:.xex=.map) $(SAMPLE_X_BAS:%.bas=bin/%.map)
LBLS=$(PROGS:.xex=.lbl) $(SAMPLE_X_BAS:%.bas=bin/%.lbl)

# The syntax parsers, to ASM (for the IDE) and C++ (for the compiler)
ASYNT=gen/asynt
CSYNT=gen/csynt

# The compiler object files, for FP and INT versions, HOST and TARGET
COMPILER_HST_FP_OBJ=$(COMPILER_SRC:%.cc=obj/cxx-fp/%.o)
COMPILER_HST_INT_OBJ=$(COMPILER_SRC:%.cc=obj/cxx-int/%.o)
COMPILER_TGT_FP_OBJ=$(COMPILER_SRC:%.cc=obj/cxx-tgt-fp/%.o)
COMPILER_TGT_INT_OBJ=$(COMPILER_SRC:%.cc=obj/cxx-tgt-int/%.o)

# The compiler dependencies - auto-generated
COMPILER_HST_DEPS=$(COMPILER_HST_INT_OBJ:.o=.d) $(COMPILER_HST_FP_OBJ:.o=.d)
COMPILER_TGT_DEPS=$(COMPILER_TGT_INT_OBJ:.o=.d) $(COMPILER_TGT_FP_OBJ:.o=.d)

# All the HOST and TARGET obj
HOST_OBJ=$(COMPILER_HST_FP_OBJ) $(COMPILER_HST_INT_OBJ)
TARGET_OBJ=$(COMPILER_TGT_FP_OBJ) $(COMPILER_TGT_INT_OBJ)

all: $(ATR) $(COMPILER_COMMON) $(COMPILER_TARGET)

dist: $(ATR) $(ZIPFILE)

clean: test-clean
	rm -f $(OBJS) $(LSTS) $(FILES) $(ATR) $(ZIPFILE) $(PROGS) $(MAPS) \
	      $(LBLS) $(ASYNT) $(CSYNT) $(COMPILER_TARGET) $(TARGET_OBJ) \
	      $(LIB_INT) $(LIB_FP) $(COMPILER_HST_DEPS) $(COMPILER_TGT_EPS) \
	      $(SAMPLE_BAS:%.bas=gen/%.asm) \
	      $(SAMP_OBJS) \
	      compiler/MANUAL.md

distclean: clean test-distclean
	rm -f gen/int/basic.asm gen/fp/basic.asm \
	    gen/int/basic.cc gen/fp/basic.cc \
	    gen/int/basic.h  gen/fp/basic.h  \
	    gen/int/basic.inc  gen/fp/basic.inc  \
	    gen/int/editor.asm gen/fp/editor.asm \
	    $(CMD_BAS_SRC) \
	    $(CMD_BAS_SRC:gen/%.bas=gen/fp/%.asm) \
	    $(COMPILER_HOST) $(HOST_OBJ)
	-rmdir gen/fp gen/int obj/fp/interp obj/int/interp obj/fp obj/int
	-rmdir obj/cxx-fp obj/cxx-int bj/cxx-tgt-fp obj/cxx-tgt-int
	-rmdir bin gen obj
	make -C testsuite distclean

# Build an ATR disk image using "mkatr".
$(ATR): $(DOS:%=$(DOSDIR)/%) $(FILES) | build
	mkatr $@ $(DOSDIR) -b $^

# Build compiler ZIP file.
$(ZIPFILE): $(COMPILER_COMMON) $(COMPILER_TARGET) | build
	$(CROSS)strip $(COMPILER_TARGET)
	zip -9vj $@ $(COMPILER_COMMON) $(COMPILER_TARGET)

# BAS sources also transformed to ATASCII (replace $0A with $9B)
disk/%.bas: samples/fp/%.bas
	LC_ALL=C tr '\n' '\233' < $< > $@

disk/%.bas: samples/int/%.bas
	LC_ALL=C tr '\n' '\233' < $< > $@

disk/%.bas: tests/%.bas
	LC_ALL=C tr '\n' '\233' < $< > $@

# Transform a text file to ATASCII (replace $0A with $9B)
disk/%: % version.mk
	LC_ALL=C sed 's/%VERSION%/$(VERSION)/' < $< | LC_ALL=C tr '\n' '\233' > $@

disk/%.txt: %.md version.mk
	LC_ALL=C sed 's/%VERSION%/$(VERSION)/' < $< | LC_ALL=C awk 'BEGIN{for(n=0;n<127;n++)chg[sprintf("%c",n)]=128+n} {l=length($$0);for(i=1;i<=l;i++){c=substr($$0,i,1);if(c=="`"){x=1-x;if(x)c="\002";else c="\026";}else if(x)c=chg[c];printf "%c",c;}printf "\233";}' > $@

# Copy ".XEX" as ".COM"
disk/%.com: bin/%.xex
	cp $< $@

# Parser generator for 6502
$(ASYNT): src/syntax/asynt.cc | gen
	$(CXX) $(CXXFLAGS) -o $@ $<

# Parser generator for C++
$(CSYNT): src/syntax/csynt.cc | gen
	$(CXX) $(CXXFLAGS) -o $@ $<

# Host compiler build
obj/cxx-int/%.o: src/compiler/%.cc | obj/cxx-int
	$(CXX) $(CXXFLAGS) $(INTCXX) -c -o $@ $<

obj/cxx-int/%.o: gen/int/%.cc | obj/cxx-int
	$(CXX) $(CXXFLAGS) $(INTCXX) -c -o $@ $<

$(COMPILER_HOST_INT): $(COMPILER_HST_INT_OBJ) | bin
	$(CXX) $(CXXFLAGS) $(INTCXX) -o $@ $^

obj/cxx-fp/%.o: src/compiler/%.cc | obj/cxx-fp
	$(CXX) $(CXXFLAGS) $(FPCXX) -c -o $@ $<

obj/cxx-fp/%.o: gen/fp/%.cc | obj/cxx-fp
	$(CXX) $(CXXFLAGS) $(FPCXX) -c -o $@ $<

$(COMPILER_HOST_FP): $(COMPILER_HST_FP_OBJ) | bin
	$(CXX) $(CXXFLAGS) $(FPCXX) -o $@ $^

# Target compiler build
ifeq ($(CROSS),)
$(COMPILER_TARGET_INT): $(COMPILER_HOST_INT)
	cp -f $< $@

$(COMPILER_TARGET_FP): $(COMPILER_HOST_FP)
	cp -f $< $@
else
obj/cxx-tgt-int/%.o: src/compiler/%.cc | obj/cxx-tgt-int
	$(CXX) $(CXXFLAGS) $(INTCXX) -c -o $@ $<

obj/cxx-tgt-int/%.o: gen/int/%.cc | obj/cxx-tgt-int
	$(CXX) $(CXXFLAGS) $(INTCXX) -c -o $@ $<

$(COMPILER_TARGET_INT): $(COMPILER_TGT_INT_OBJ)
	$(CROSS)$(CXX) $(CXXFLAGS) $(INTCXX) -o $@ $^

obj/cxx-tgt-fp/%.o: src/compiler/%.cc | obj/cxx-tgt-fp
	$(CXX) $(CXXFLAGS) $(FPCXX) -c -o $@ $<

obj/cxx-tgt-fp/%.o: gen/int/%.cc | obj/cxx-tgt-fp
	$(CXX) $(CXXFLAGS) $(FPCXX) -c -o $@ $<

$(COMPILER_TARGET_FP): $(COMPILER_TGT_FP_OBJ)
	$(CROSS)$(CXX) $(CXXFLAGS) $(FPCXX) -o $@ $^
endif

# Generator for syntax file - 6502 version - FLOAT
gen/fp/%.asm: src/%.syn $(ASYNT) | gen/fp
	$(ASYNT) $(SYNTFLAGS) $(SYNTFP) $< -o $@

# Generator for syntax file - 6502 version - INTEGER
gen/int/%.asm: src/%.syn $(ASYNT) | gen/int
	$(ASYNT) $(SYNTFLAGS) $< -o $@

# Generator for syntax file - C++ version - FLOAT
gen/fp/%.cc gen/fp/%.h: src/%.syn $(CSYNT) | gen/fp
	$(CSYNT) $(SYNTFLAGS) $(SYNTFP) $< -o gen/fp/$*.cc

# Generator for syntax file - C++ version - INTEGER
gen/int/%.cc gen/int/%.h: src/%.syn $(CSYNT) | gen/int
	$(CSYNT) $(SYNTFLAGS) $< -o gen/int/$*.cc

# Sets the version inside command line compiler source
gen/cmdline-vers.bas: src/cmdline.bas version.mk
	LC_ALL=C sed 's/%VERSION%/$(VERSION)/' < $< > $@

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
gen/fp/%.asm: gen/%.bas $(COMPILER_HOST_FP) | gen/fp
	$(COMPILER_HOST_FP) $< $@

gen/fp/%.asm: src/%.bas $(COMPILER_HOST_FP) | gen/fp
	$(COMPILER_HOST_FP) $< $@

gen/int/%.asm: src/%.bas $(COMPILER_HOST_INT) | gen/int
	$(COMPILER_HOST_INT) $< $@

gen/fp/%.asm: samples/fp/%.bas $(COMPILER_HOST_FP) | gen/fp
	$(COMPILER_HOST_FP) $< $@

gen/int/%.asm: samples/int/%.bas $(COMPILER_HOST_INT) | gen/int
	$(COMPILER_HOST_INT) $< $@

# Object file rules
obj/fp/%.o: src/%.asm | obj/fp obj/fp/interp
	cl65 $(CL65OPTS) $(FPASM) -c -l $(@:.o=.lst) -o $@ $<

obj/fp/%.o: gen/fp/%.asm | obj/fp
	cl65 $(CL65OPTS) $(FPASM) -c -l $(@:.o=.lst) -o $@ $<

obj/int/%.o: src/%.asm | obj/int obj/int/interp
	cl65 $(CL65OPTS) $(INTASM) -c -l $(@:.o=.lst) -o $@ $<

obj/int/%.o: gen/int/%.asm | obj/int
	cl65 $(CL65OPTS) $(INTASM) -c -l $(@:.o=.lst) -o $@ $<

gen obj obj/fp obj/int obj/fp/interp obj/int/interp gen/fp gen/int \
obj/cxx-fp obj/cxx-int obj/cxx-tgt-fp obj/cxx-tgt-int bin build:
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
.PHONY: test-clean
.PHONY: test-distclean
test: $(COMPILER_COMMON) $(COMPILER_HOST) bin/fbc.xex
	make -C testsuite

test-clean:
	make -C testsuite clean

test-distclean:
	make -C testsuite distclean

# Copy manual to compiler
compiler/MANUAL.md: manual.md
	cp -f $< $@

# Dependencies
$(COMMON_OBJS_FP): src/deftok.inc
$(COMMON_OBJS_INT): src/deftok.inc
obj/fp/parse.o: src/parse.asm gen/fp/basic.asm
obj/int/parse.o: src/parse.asm gen/int/basic.asm
$(CSYNT): \
 src/syntax/csynt.cc \
 src/syntax/synt-parse.h \
 src/syntax/synt-wlist.h \
 src/syntax/synt-sm.h \
 src/syntax/synt-emit-cc.h \
 src/syntax/synt-read.h
$(ASYNT): \
 src/syntax/asynt.cc \
 src/syntax/synt-parse.h \
 src/syntax/synt-wlist.h \
 src/syntax/synt-sm.h \
 src/syntax/synt-emit-asm.h \
 src/syntax/synt-read.h

$(HOST_OBJ) $(TARGET_OBJ): version.mk

# Automatic generation of dependency information for C++ files
obj/cxx-tgt-int/%.d: src/compiler/%.cc | obj/cxx-tgt-int
	@$(CROSS)$(CXX) -MM -MP -MF $@ -MT "$(@:.d=.o) $@" $(INTCXX) $(CXXFLAGS) $<
obj/cxx-tgt-int/%.d: gen/fp/%.cc | obj/cxx-tgt-int
	@$(CROSS)$(CXX) -MM -MP -MF $@ -MT "$(@:.d=.o) $@" $(INTCXX) $(CXXFLAGS) $<
obj/cxx-tgt-fp/%.d: src/compiler/%.cc | obj/cxx-tgt-fp
	@$(CROSS)$(CXX) -MM -MP -MF $@ -MT "$(@:.d=.o) $@" $(FPCXX) $(CXXFLAGS) $<
obj/cxx-tgt-fp/%.d: gen/fp/%.cc | obj/cxx-tgt-fp
	@$(CROSS)$(CXX) -MM -MP -MF $@ -MT "$(@:.d=.o) $@" $(FPCXX) $(CXXFLAGS) $<
obj/cxx-int/%.d: src/compiler/%.cc | gen/int/basic.h obj/cxx-int
	@$(CXX) -MM -MP -MF $@ -MT "$(@:.d=.o) $@" $(INTCXX) $(CXXFLAGS) $<
obj/cxx-int/%.d: gen/int/%.cc | obj/cxx-int
	@$(CXX) -MM -MP -MF $@ -MT "$(@:.d=.o) $@" $(INTCXX) $(CXXFLAGS) $<
obj/cxx-fp/%.d: src/compiler/%.cc | gen/fp/basic.h obj/cxx-fp
	@$(CXX) -MM -MP -MF $@ -MT "$(@:.d=.o) $@" $(FPCXX) $(CXXFLAGS) $<
obj/cxx-fp/%.d: gen/fp/%.cc | obj/cxx-fp
	@$(CXX) -MM -MP -MF $@ -MT "$(@:.d=.o) $@" $(FPCXX) $(CXXFLAGS) $<

ifneq "$(MAKECMDGOALS)" "clean"
    ifneq "$(MAKECMDGOALS)" "distclean"
        -include $(COMPILER_HST_DEPS)
        ifneq ($(CROSS),)
            -include $(COMPILER_TGT_DEPS)
        endif
    endif
endif
