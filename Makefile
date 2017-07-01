CXX=g++
CXXFLAGS=-O2 -Wall

# Cross
CL65OPTS=-g -tatari -Csrc/fastbasic.cfg --asm-include-dir gen

ATR=fastbasic.atr
PROG=bin/fastbasic.xex

# Output files inside the ATR
FILES=\
    disk/fb.com \
    disk/readme \
    disk/manual.txt \
    disk/startup.bat \
    disk/carrera3d.bas \
    disk/draw.bas \
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

all: $(ATR)

clean:
	rm -f $(OBJS) $(LSTS) $(FILES) $(ATR) $(PROG) $(MAP) $(LBL) $(SYNT)

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

# Parser generator
$(SYNT): src/synt.cc gen
	$(CXX) $(CXXFLAGS) -o $@ $<

# Generator for syntax file
gen/%.asm: src/%.syn $(SYNT) gen
	$(SYNT) < $< > $@

# Main program file
$(PROG): $(OBJS) bin
	cl65 $(CL65OPTS) -Ln $(@:.xex=.lbl) -vm -m $(@:.xex=.map) -o $@ $(OBJS)

obj/%.o: src/%.asm obj
	cl65 $(CL65OPTS) -c -l $(@:.o=.lst) -o $@ $<

gen obj bin:
	mkdir -p $@

# Dependencies
obj/parse.o: src/parse.asm gen/basic.asm

