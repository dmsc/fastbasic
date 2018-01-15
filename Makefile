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

ATR=fastbasic.atr
PROGS=bin/fb.xex bin/fbi.xex
NATIVE_INT=compiler/fastbasic-int
NATIVE_FP=compiler/fastbasic-fp

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
    testcmp.bas \
    testif.bas \
    testio.bas \
    testloop.bas \
    testproc.bas \
    testusr.bas \

# Output files inside the ATR
FILES=\
    disk/fb.com \
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

# ASM files used in the IDE
IDE_AS_SRC=\
    src/actions.asm\
    src/errors.asm\
    src/menu.asm\
    src/parse.asm\
    src/vars.asm\

# Common ASM files
COMMON_AS_SRC=\
    src/alloc.asm\
    src/exehdr.asm\
    src/interpreter.asm\
    src/runtime.asm\

# BAS editor source
BAS_SRC=\
    src/editor.bas\

# Object files
RT_OBJS_FP=$(RT_AS_SRC:src/%.asm=obj/fp/%.o)
IDE_OBJS_FP=$(IDE_AS_SRC:src/%.asm=obj/fp/%.o)
COMMON_OBJS_FP=$(COMMON_AS_SRC:src/%.asm=obj/fp/%.o)
BAS_OBJS_FP=$(BAS_SRC:src/%.bas=obj/fp/%.o)

RT_OBJS_INT=$(RT_AS_SRC:src/%.asm=obj/int/%.o)
IDE_OBJS_INT=$(IDE_AS_SRC:src/%.asm=obj/int/%.o)
COMMON_OBJS_INT=$(COMMON_AS_SRC:src/%.asm=obj/int/%.o)
BAS_OBJS_INT=$(BAS_SRC:src/%.bas=obj/int/%.o)
SAMP_OBJS=$(SAMPLE_BAS:%.bas=obj/%.o)

# Compiler library files
COMPILER=\
	 compiler/fastbasic-int\
	 compiler/fastbasic-int.lib\
	 compiler/fastbasic-fp\
	 compiler/fastbasic-fp.lib\

# All Output files
OBJS=$(RT_OBJS_FP) $(IDE_OBJS_FP) $(COMMON_OBJS_FP) $(BAS_OBJS_FP) \
     $(RT_OBJS_INT) $(IDE_OBJS_INT) $(COMMON_OBJS_INT) $(BAS_OBJS_INT) \
     $(SAMP_OBJS)
LSTS=$(OBJS:%.o=%.lst)

MAPS=$(PROGS:.xex=.map) $(SAMPLE_X_BAS:%.bas=bin/%.map)
LBLS=$(PROGS:.xex=.lbl) $(SAMPLE_X_BAS:%.bas=bin/%.lbl)
SYNT=gen/synt
CSYNT=gen/csynt

all: $(ATR) $(NATIVES) $(COMPILER)

clean:
	rm -f $(OBJS) $(LSTS) $(FILES) $(ATR) $(PROGS) $(MAPS) $(LBLS) $(SYNT) $(CSYNT) $(COMPILER)

distclean: clean
	rm -f gen/int/basic.asm gen/fp/basic.asm gen/int/basic.cc gen/fp/basic.cc \
	    $(BAS_SRC:src/%.bas=gen/fp/%.asm) \
	    $(BAS_SRC:src/%.bas=gen/int/%.asm) \
	    $(SAMPLE_BAS:%.bas=gen/%.asm)
	-rmdir gen/fp gen/int obj/fp obj/int
	-rmdir bin gen obj

# Build an ATR disk image using "mkatr".
$(ATR): $(DOS:%=$(DOSDIR)/%) $(FILES)
	mkatr $@ $(DOSDIR) -b $^

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
$(NATIVE_INT): src/native.cc gen/int/basic.cc | bin
	$(CXX) $(CXXFLAGS) $(INTCXX) -o $@ $<

$(NATIVE_FP): src/native.cc gen/fp/basic.cc | bin
	$(CXX) $(CXXFLAGS) $(FPCXX) -o $@ $<

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
bin/fb.xex: $(IDE_OBJS_FP) $(COMMON_OBJS_FP) $(BAS_OBJS_FP) | bin
	cl65 $(CL65OPTS) -Ln $(@:.xex=.lbl) -vm -m $(@:.xex=.map) -o $@ $^

bin/fbi.xex: $(IDE_OBJS_INT) $(COMMON_OBJS_INT) $(BAS_OBJS_INT) | bin
	cl65 $(CL65OPTS) -Ln $(@:.xex=.lbl) -vm -m $(@:.xex=.map) -o $@ $^

# Compiled program files
bin/%.xex: obj/fp/%.o $(RT_OBJS_FP) $(COMMON_OBJS_FP) | bin
	cl65 $(CL65OPTS) -Ln $(@:.xex=.lbl) -vm -m $(@:.xex=.map) -o $@ $^

bin/%.xex: obj/int/%.o $(RT_OBJS_INT) $(COMMON_OBJS_INT) | bin
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
obj/fp/%.o: src/%.asm | obj/fp
	cl65 $(CL65OPTS) $(FPASM) -c -l $(@:.o=.lst) -o $@ $<

obj/fp/%.o: gen/fp/%.asm | obj/fp
	cl65 $(CL65OPTS) $(FPASM) -c -l $(@:.o=.lst) -o $@ $<

obj/int/%.o: src/%.asm | obj/int
	cl65 $(CL65OPTS) $(INTASM) -c -l $(@:.o=.lst) -o $@ $<

obj/int/%.o: gen/int/%.asm | obj/int
	cl65 $(CL65OPTS) $(INTASM) -c -l $(@:.o=.lst) -o $@ $<

gen obj obj/fp obj/int gen/fp gen/int bin:
	mkdir -p $@

# Library files
compiler/fastbasic-fp.lib: $(RT_OBJS_FP) $(COMMON_OBJS_FP)
	rm -f $@
	ar65 a $@ $^

compiler/fastbasic-int.lib: $(RT_OBJS_INT) $(COMMON_OBJS_INT)
	rm -f $@
	ar65 a $@ $^

# Dependencies
obj/fp/parse.o: src/parse.asm gen/fp/basic.asm
obj/int/parse.o: src/parse.asm gen/int/basic.asm
$(CSYNT): src/csynt.cc src/synt-parse.h src/synt-wlist.h src/synt-sm.h src/synt-emit-cc.h src/synt-read.h
$(SYNT): src/synt.cc src/synt-parse.h src/synt-wlist.h src/synt-sm.h src/synt-emit-asm.h src/synt-read.h
