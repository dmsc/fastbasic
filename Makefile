CXX=g++
CXXFLAGS=-O2 -Wall

# Cross
CL65OPTS=-g -tatari -Csrc/fastbasic.cfg --asm-include-dir gen

ATR=fastbasic.atr
PROG=bin/fastbasic.xex
NATIVE=bin/fastbasic

# Output files inside the ATR
FILES=\
    disk/fb.com \
    disk/readme \
    disk/manual.txt \
    disk/startup.bat \
    disk/carrera3d.bas \
    disk/draw.bas \
    disk/help.txt \
    disk/pmtest.bas \
    disk/sieve.bas \
    disk/testif.bas \
    disk/testio.bas \
    disk/testloop.bas \
    disk/testproc.bas \
    disk/testusr.bas \

# BW-DOS files to copy inside the ATR
DOSDIR=disk/dos/
DOS=\
    xbw130.dos\
    copy.com\

AS_SRC=\
    src/actions.asm\
    src/alloc.asm\
    src/errors.asm\
    src/exehdr.asm\
    src/interpreter.asm\
    src/io.asm\
    src/menu.asm\
    src/parse.asm\
    src/runtime.asm\
    src/vars.asm\

# Output files:
OBJS=$(AS_SRC:src/%.asm=obj/%.o)
LSTS=$(AS_SRC:src/%.asm=obj/%.lst)
MAP=$(PROG:.xex=.map)
LBL=$(PROG:.xex=.lbl)
SYNT=gen/synt
CSYNT=gen/csynt

all: $(ATR) $(NATIVE)

clean:
	rm -f $(OBJS) $(LSTS) $(FILES) $(ATR) $(PROG) $(MAP) $(LBL) $(SYNT) $(CSYNT) $(NATIVE)

distclean: clean
	rm -f gen/basic.asm
	-rmdir bin gen obj

# Build an ATR disk image using "mkatr".
$(ATR): $(DOS:%=$(DOSDIR)/%) $(FILES)
	mkatr $@ $(DOSDIR) -b $^

# BAS sources also transformed to ATASCII (replace $0A with $9B)
disk/%.bas: tests/%.bas
	tr '\n' '\233' < $< > $@

# Transform a text file to ATASCII (replace $0A with $9B)
disk/%: %
	tr '\n' '\233' < $< > $@

# Copy ".XEX" as ".COM"
disk/fb.com: $(PROG)
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
$(PROG): $(OBJS) | bin
	cl65 $(CL65OPTS) -Ln $(@:.xex=.lbl) -vm -m $(@:.xex=.map) -o $@ $(OBJS)

# Generates basic bytecode from source file
gen/%.asm: src/%.bas $(NATIVE)
	$(NATIVE) $< $@

# Object file rules
obj/%.o: src/%.asm | obj
	cl65 $(CL65OPTS) -c -l $(@:.o=.lst) -o $@ $<

gen obj bin:
	mkdir -p $@

# Dependencies
obj/parse.o: src/parse.asm gen/basic.asm
obj/menu.o: src/menu.asm gen/editor.asm

$(CSYNT): src/csynt.cc src/synt-parse.h src/synt-wlist.h src/synt-sm.h src/synt-emit-cc.h
$(SYNT): src/synt.cc src/synt-parse.h src/synt-wlist.h src/synt-sm.h src/synt-emit-asm.h

