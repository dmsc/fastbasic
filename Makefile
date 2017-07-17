CXX=g++
CXXFLAGS=-O2 -Wall

# Cross
CL65OPTS=-g -tatari -Csrc/fastbasic.cfg --asm-include-dir gen

ATR=fastbasic.atr
PROG=bin/fastbasic.xex
NATIVE=bin/fastbasic

# Sample programs
SAMPLE_BAS=\
    carrera3d.bas \
    draw.bas \
    pmtest.bas \
    sieve.bas \

# Test programs
TEST_BAS=\
    testif.bas \
    testio.bas \
    testloop.bas \
    testproc.bas \
    testusr.bas \

# Output files inside the ATR
FILES=\
    disk/fb.com \
    disk/readme \
    disk/manual.txt \
    disk/startup.bat \
    disk/help.txt \
    $(TEST_BAS:%=disk/%) \
    $(SAMPLE_BAS:%=disk/%) \
    $(SAMPLE_BAS:%.bas=disk/%.com) \

# BW-DOS files to copy inside the ATR
DOSDIR=disk/dos/
DOS=\
    xbw130.dos\
    copy.com\

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
RT_OBJS=$(RT_AS_SRC:src/%.asm=obj/%.o)
IDE_OBJS=$(IDE_AS_SRC:src/%.asm=obj/%.o)
COMMON_OBJS=$(COMMON_AS_SRC:src/%.asm=obj/%.o)
BAS_OBJS=$(BAS_SRC:src/%.bas=obj/%.o)
SAMP_OBJS=$(SAMPLE_BAS:%.bas=obj/%.o)

# Listing files
RT_LSTS=$(RT_AS_SRC:src/%.asm=obj/%.lst)
IDE_LSTS=$(IDE_AS_SRC:src/%.asm=obj/%.lst)
COMMON_LSTS=$(COMMON_AS_SRC:src/%.asm=obj/%.lst)
BAS_LSTS=$(BAS_SRC:src/%.bas=obj/%.lst)
SAMP_LSTS=$(SAMPLE_BAS:%.bas=obj/%.lst)

# All Output files
OBJS=$(RT_OBJS) $(IDE_OBJS) $(COMMON_OBJS) $(BAS_OBJS) $(SAMP_OBJS)
LSTS=$(RT_LSTS) $(IDE_LSTS) $(COMMON_LSTS) $(BAS_LSTS) $(SAMP_LSTS)

MAPS=$(PROG:.xex=.map) $(SAMPLE_BAS:%.bas=bin/%.map)
LBLS=$(PROG:.xex=.lbl) $(SAMPLE_BAS:%.bas=bin/%.lbl)
SYNT=gen/synt
CSYNT=gen/csynt

all: $(ATR) $(NATIVE)

clean:
	rm -f $(OBJS) $(LSTS) $(FILES) $(ATR) $(PROG) $(MAPS) $(LBLS) $(SYNT) $(CSYNT) $(NATIVE)

distclean: clean
	rm -f gen/basic.asm gen/basic.cc $(BAS_SRC:src/%.bas=gen/%.asm) $(SAMPLE_BAS:%.bas=gen/%.asm)
	-rmdir bin gen obj

# Build an ATR disk image using "mkatr".
$(ATR): $(DOS:%=$(DOSDIR)/%) $(FILES)
	mkatr $@ $(DOSDIR) -b $^

# BAS sources also transformed to ATASCII (replace $0A with $9B)
disk/%.bas: samples/%.bas
	tr '\n' '\233' < $< > $@

disk/%.bas: tests/%.bas
	tr '\n' '\233' < $< > $@

# Transform a text file to ATASCII (replace $0A with $9B)
disk/%: %
	tr '\n' '\233' < $< > $@

disk/%.txt: %.md
	tr '\n' '\233' < $< > $@

# Copy ".XEX" as ".COM"
disk/fb.com: $(PROG)
	cp $< $@

disk/%.com: bin/%.xex
	cp $< $@

# Parser generator for 6502
$(SYNT): src/synt.cc | gen
	$(CXX) $(CXXFLAGS) -o $@ $<

# Parser generator for C++
$(CSYNT): src/csynt.cc | gen
	$(CXX) $(CXXFLAGS) -o $@ $<

# Native compiler
$(NATIVE): src/native.cc gen/basic.cc | bin
	$(CXX) $(CXXFLAGS) -Igen -o $@ $<

# Generator for syntax file - 6502 version
gen/%.asm: src/%.syn $(SYNT) | gen
	$(SYNT) < $< > $@

# Generator for syntax file - C++ version
gen/%.cc: src/%.syn $(CSYNT) | gen
	$(CSYNT) < $< > $@

# Main program file
$(PROG): $(IDE_OBJS) $(COMMON_OBJS) $(BAS_OBJS) | bin
	cl65 $(CL65OPTS) -Ln $(@:.xex=.lbl) -vm -m $(@:.xex=.map) -o $@ $^

# Compiled program files
bin/%.xex: obj/%.o $(RT_OBJS) $(COMMON_OBJS) | bin
	cl65 $(CL65OPTS) -Ln $(@:.xex=.lbl) -vm -m $(@:.xex=.map) -o $@ $^

# Generates basic bytecode from source file
gen/%.asm: src/%.bas $(NATIVE) | gen
	$(NATIVE) $< $@

gen/%.asm: samples/%.bas $(NATIVE) | gen
	$(NATIVE) $< $@

# Object file rules
obj/%.o: src/%.asm | obj
	cl65 $(CL65OPTS) -c -l $(@:.o=.lst) -o $@ $<

obj/%.o: gen/%.asm | obj
	cl65 $(CL65OPTS) -c -l $(@:.o=.lst) -o $@ $<

gen obj bin:
	mkdir -p $@

# Dependencies
obj/parse.o: src/parse.asm gen/basic.asm
$(CSYNT): src/csynt.cc src/synt-parse.h src/synt-wlist.h src/synt-sm.h src/synt-emit-cc.h
$(SYNT): src/synt.cc src/synt-parse.h src/synt-wlist.h src/synt-sm.h src/synt-emit-asm.h
