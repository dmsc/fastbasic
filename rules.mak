#
#  FastBasic - Fast basic interpreter for the Atari 8-bit computers
#  Copyright (C) 2017-2021 Daniel Serpell
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

# Main compilation rules
all: $(ATR) $(COMPILER_COMMON) $(COMPILER_TARGET)

dist: $(ATR) $(ZIPFILE)

.PHONY: clean
clean:
	$(Q)rm -f $(OBJS) $(LSTS) $(FILES) $(ATR) $(ZIPFILE) $(XEXS) $(MAPS) \
	      $(LBLS) $(ASYNT) $(CSYNT) $(COMPILER_HOST) $(TARGET_OBJ) \
	      $(COMPILER_HOST_DEPS) $(COMPILER_TARGET_DEPS) \
	      $(SAMPLE_BAS:%.bas=build/gen/%.asm) \
	      $(SAMP_OBJS) $(HOST_OBJ)
	$(Q)rm -f $(TESTS_XEX) $(TESTS_ROM) $(TESTS_ASM) $(TESTS_OBJ) $(TESTS_ATB) $(TESTS_LBL) $(RUNTEST_OBJS) $(RUNTEST) $(TESTS_STAMP) $(RUNTEST_OBJS:.o=.d)

.PHONY: distclean
distclean: clean
	$(Q)-rm -f build/gen/int/basic.asm build/gen/fp/basic.asm \
	    build/gen/int/basic.cc build/gen/fp/basic.cc \
	    build/gen/int/basic.h  build/gen/fp/basic.h  \
	    build/gen/int/basic.inc  build/gen/fp/basic.inc  \
	    build/gen/int/editor.asm build/gen/fp/editor.asm \
	    $(CMD_BAS_SRC) \
	    $(CMD_BAS_SRC:build/gen/%.bas=build/gen/fp/%.asm) \
	    $(COMPILER_HOST) $(COMPILER_TARGET) $(COMPILER_COMMON)
	$(Q)test -d build/obj/tests       && rmdir build/obj/tests       || true
	$(Q)test -d build/tests           && rmdir build/tests           || true
	$(Q)test -d build/gen/fp          && rmdir build/gen/fp          || true
	$(Q)test -d build/gen/int         && rmdir build/gen/int         || true
	$(Q)test -d build/obj/fp/interp   && rmdir build/obj/fp/interp   || true
	$(Q)test -d build/obj/int/interp  && rmdir build/obj/int/interp  || true
	$(Q)test -d build/obj/int/interp  && rmdir build/obj/int/interp  || true
	$(Q)test -d build/obj/rom-fp/interp && rmdir build/obj/rom-fp/interp || true
	$(Q)test -d build/obj/rom-int/interp && rmdir build/obj/rom-int/interp || true
	$(Q)test -d build/obj/fp          && rmdir build/obj/fp          || true
	$(Q)test -d build/obj/int         && rmdir build/obj/int         || true
	$(Q)test -d build/obj/rom-fp      && rmdir build/obj/rom-fp      || true
	$(Q)test -d build/obj/rom-int     && rmdir build/obj/rom-int     || true
	$(Q)test -d build/obj/cxx-fp      && rmdir build/obj/cxx-fp      || true
	$(Q)test -d build/obj/cxx-int     && rmdir build/obj/cxx-int     || true
	$(Q)test -d build/obj/cxx-tgt-fp  && rmdir build/obj/cxx-tgt-fp  || true
	$(Q)test -d build/obj/cxx-tgt-int && rmdir build/obj/cxx-tgt-int || true
	$(Q)test -d build/compiler/asminc && rmdir build/compiler/asminc || true
	$(Q)test -d build/bin             && rmdir build/bin             || true
	$(Q)test -d build/gen             && rmdir build/gen             || true
	$(Q)test -d build/obj             && rmdir build/obj             || true
	$(Q)test -d build/disk            && rmdir build/disk            || true
	$(Q)test -d build/compiler        && rmdir build/compiler        || true

# Build an ATR disk image using "mkatr".
$(ATR): $(DOS:%=$(DOSDIR)/%) $(FILES) | build
	$(ECHO) "Creating ATR disk image"
	$(Q)mkatr $@ $(DOSDIR) -b $^

# Build compiler ZIP file.
$(ZIPFILE): $(COMPILER_COMMON) $(COMPILER_TARGET) | build
	$(CROSS)strip $(COMPILER_TARGET)
	# This rule is complicated because we want to store only the paths
	# relative to the compiler directory, not the full path of the build
	# directory.
	(cd build/compiler ; zip -9v ../../$@ $(COMPILER_COMMON:build/compiler/%=%) $(COMPILER_TARGET:build/compiler/%=%) )

# BAS sources also transformed to ATASCII (replace $0A with $9B)
build/disk/%.bas: samples/fp/%.bas | build/disk
	$(Q)LC_ALL=C tr '\n' '\233' < $< > $@

build/disk/%.bas: samples/int/%.bas | build/disk
	$(Q)LC_ALL=C tr '\n' '\233' < $< > $@

build/disk/%.bas: tests/%.bas | build/disk
	$(Q)LC_ALL=C tr '\n' '\233' < $< > $@

# Transform a text file to ATASCII (replace $0A with $9B)
build/disk/%: % version.mk | build/disk
	$(Q)LC_ALL=C sed 's/%VERSION%/$(VERSION)/' < $< | LC_ALL=C tr '\n' '\233' > $@

build/disk/%.txt: %.md version.mk | build/disk
	$(Q)LC_ALL=C sed 's/%VERSION%/$(VERSION)/' < $< | LC_ALL=C awk 'BEGIN{for(n=0;n<127;n++)chg[sprintf("%c",n)]=128+n} {l=length($$0);for(i=1;i<=l;i++){c=substr($$0,i,1);if(c=="`"){x=1-x;if(x)c="\002";else c="\026";}else if(x)c=chg[c];printf "%c",c;}printf "\233";}' > $@

# Copy ".XEX" as ".COM"
build/disk/%.com: build/bin/%.xex | build/disk
	$(Q)cp $< $@

# Parser generator for 6502
$(ASYNT): src/generator/asynt.cc | build/gen
	$(ECHO) "Compile 6502 parser generator tool $<"
	$(Q)$(CXX) $(HOST_CXXFLAGS) -o $@ $<

# Parser generator for C++
$(CSYNT): src/generator/csynt.cc | build/gen
	$(ECHO) "Compile C parser generator tool $<"
	$(Q)$(CXX) $(HOST_CXXFLAGS) -o $@ $<

# Host compiler build
build/obj/cxx-int/%.o: src/compiler/%.cc | build/obj/cxx-int
	$(ECHO) "Compile INT $<"
	$(Q)$(CXX) $(HOST_CXXFLAGS) $(INTCXX) -c -o $@ $<

build/obj/cxx-int/%.o: build/gen/int/%.cc | build/obj/cxx-int
	$(ECHO) "Compile INT $<"
	$(Q)$(CXX) $(HOST_CXXFLAGS) $(INTCXX) -c -o $@ $<

$(COMPILER_HOST_INT): $(COMPILER_HOST_INT_OBJ) | build/bin
	$(ECHO) "Linking INT compiler"
	$(Q)$(CXX) $(HOST_CXXFLAGS) $(INTCXX) -o $@ $^

build/obj/cxx-fp/%.o: src/compiler/%.cc | build/obj/cxx-fp
	$(ECHO) "Compile FP $<"
	$(Q)$(CXX) $(HOST_CXXFLAGS) $(FPCXX) -c -o $@ $<

build/obj/cxx-fp/%.o: build/gen/fp/%.cc | build/obj/cxx-fp
	$(ECHO) "Compile FP $<"
	$(Q)$(CXX) $(HOST_CXXFLAGS) $(FPCXX) -c -o $@ $<

$(COMPILER_HOST_FP): $(COMPILER_HOST_FP_OBJ) | build/bin
	$(ECHO) "Linking FP compiler"
	$(Q)$(CXX) $(HOST_CXXFLAGS) $(FPCXX) -o $@ $^

$(CA65_HOST): $(CA65_SRC) | build/bin
	$(ECHO) "Compile CA65"
	$(Q)$(CC) $(HOST_CFLAGS) $(CC65_CFLAGS) -o $@ $^

$(LD65_HOST): $(LD65_SRC) | build/bin
	$(ECHO) "Compile LD65"
	$(Q)$(CC) $(HOST_CFLAGS) $(CC65_CFLAGS) -o $@ $^

$(AR65_HOST): $(AR65_SRC) | build/bin
	$(ECHO) "Compile AR65"
	$(Q)$(CC) $(HOST_CFLAGS) $(CC65_CFLAGS) -o $@ $^

# Target compiler build
ifeq ($(CROSS),)
# No cross-compilation, just copy host tools to target tools:
$(COMPILER_TARGET): build/compiler/%$(EXT): build/bin/% | build/compiler
	$(Q)cp -f $< $@
else
# Cross-compilation: compile for target
build/obj/cxx-tgt-int/%.o: src/compiler/%.cc | build/obj/cxx-tgt-int
	$(ECHO) "Compile INT $<"
	$(Q)$(CROSS)$(CXX) $(TARGET_CXXFLAGS) $(INTCXX) -c -o $@ $<

build/obj/cxx-tgt-int/%.o: build/gen/int/%.cc | build/obj/cxx-tgt-int
	$(ECHO) "Compile INT $<"
	$(Q)$(CROSS)$(CXX) $(TARGET_CXXFLAGS) $(INTCXX) -c -o $@ $<

$(COMPILER_TARGET_INT): $(COMPILER_TARGET_INT_OBJ) | build/compiler
	$(ECHO) "Linking target INT compiler"
	$(Q)$(CROSS)$(CXX) $(TARGET_CXXFLAGS) $(INTCXX) -o $@ $^

build/obj/cxx-tgt-fp/%.o: src/compiler/%.cc | build/obj/cxx-tgt-fp
	$(ECHO) "Compile FP $<"
	$(Q)$(CROSS)$(CXX) $(TARGET_CXXFLAGS) $(FPCXX) -c -o $@ $<

build/obj/cxx-tgt-fp/%.o: build/gen/fp/%.cc | build/obj/cxx-tgt-fp
	$(ECHO) "Compile FP $<"
	$(Q)$(CROSS)$(CXX) $(TARGET_CXXFLAGS) $(FPCXX) -c -o $@ $<

$(COMPILER_TARGET_FP): $(COMPILER_TARGET_FP_OBJ) | build/compiler
	$(ECHO) "Linking target FP compiler"
	$(Q)$(CROSS)$(CXX) $(TARGET_CXXFLAGS) $(FPCXX) -o $@ $^

$(CA65_TARGET): $(CA65_SRC) | build/compiler
	$(ECHO) "Compile target CA65"
	$(Q)$(CROSS)$(CC) $(TARGET_CFLAGS) $(CC65_CFLAGS) -o $@ $^

$(LD65_TARGET): $(LD65_SRC) | build/compiler
	$(ECHO) "Compile target LD65"
	$(Q)$(CROSS)$(CC) $(TARGET_CFLAGS) $(CC65_CFLAGS) -o $@ $^

$(AR65_TARGET): $(AR65_SRC) | build/compiler
	$(ECHO) "Compile target AR65"
	$(Q)$(CROSS)$(CC) $(TARGET_CFLAGS) $(CC65_CFLAGS) -o $@ $^
endif

# Generator for syntax file - 6502 version - FLOAT
build/gen/fp/%.asm: src/%.syn $(ASYNT) | build/gen/fp
	$(ECHO) "Creating FP parsing bytecode"
	$(Q)$(ASYNT) $(SYNTFLAGS_ASM) $(SYNTFP) $< -o $@

# Generator for syntax file - 6502 version - INTEGER
build/gen/int/%.asm: src/%.syn $(ASYNT) | build/gen/int
	$(ECHO) "Creating INT parsing bytecode"
	$(Q)$(ASYNT) $(SYNTFLAGS_ASM) $< -o $@

# Generator for syntax file - C++ version - FLOAT
build/gen/fp/%.cc build/gen/fp/%.h: src/%.syn $(CSYNT) | build/gen/fp
	$(ECHO) "Creating FP cross parser"
	$(Q)$(CSYNT) $(SYNTFLAGS_CPP) $(SYNTFP) $< -o build/gen/fp/$*.cc

# Generator for syntax file - C++ version - INTEGER
build/gen/int/%.cc build/gen/int/%.h: src/%.syn $(CSYNT) | build/gen/int
	$(ECHO) "Creating INT cross parser"
	$(Q)$(CSYNT) $(SYNTFLAGS_CPP) $< -o build/gen/int/$*.cc

# Sets the version inside command line compiler source
build/gen/cmdline-vers.bas: src/cmdline.bas version.mk
	$(Q)LC_ALL=C sed 's/%VERSION%/$(VERSION)/' < $< > $@

# Main program file
build/bin/fb.xex: $(IDE_OBJS_FP) $(COMMON_OBJS_FP) $(IDE_BAS_OBJS_FP) | build/bin $(LD65_HOST)
	$(ECHO) "Linking floating point IDE"
	$(Q)$(LD65_HOST) $(LD65_FLAGS) -Ln $(@:.xex=.lbl) -vm -m $(@:.xex=.map) -o $@ $^

build/bin/fbc.xex: $(CMD_OBJS_FP) $(COMMON_OBJS_FP) $(CMD_BAS_OBJS_FP) | build/bin $(LD65_HOST)
	$(ECHO) "Linking command line compiler"
	$(Q)$(LD65_HOST) $(LD65_FLAGS) -Ln $(@:.xex=.lbl) -vm -m $(@:.xex=.map) -o $@ $^

build/bin/fbi.xex: $(IDE_OBJS_INT) $(COMMON_OBJS_INT) $(IDE_BAS_OBJS_INT) | build/bin $(LD65_HOST)
	$(ECHO) "Linking integer IDE"
	$(Q)$(LD65_HOST) $(LD65_FLAGS) -Ln $(@:.xex=.lbl) -vm -m $(@:.xex=.map) -o $@ $^

# Compiled program files
build/bin/%.xex: build/obj/fp/%.o $(LIB_FP) | build/bin $(LD65_HOST)
	$(ECHO) "Linking floating point $@"
	$(Q)$(LD65_HOST) $(LD65_FLAGS) -Ln $(@:.xex=.lbl) -vm -m $(@:.xex=.map) -o $@ $^

build/bin/%.xex: build/obj/int/%.o $(LIB_INT) | build/bin $(LD65_HOST)
	$(ECHO) "Linking integer $@"
	$(Q)$(LD65_HOST) $(LD65_FLAGS) -Ln $(@:.xex=.lbl) -vm -m $(@:.xex=.map) -o $@ $^

# Generates basic bytecode from source file
build/gen/fp/%.asm: build/gen/%.bas $(COMPILER_HOST_FP) | build/gen/fp
	$(ECHO) "Compiling FP BASIC $<"
	$(Q)$(COMPILER_HOST_FP) $< $@

build/gen/fp/%.asm: src/%.bas $(COMPILER_HOST_FP) | build/gen/fp
	$(ECHO) "Compiling FP BASIC $<"
	$(Q)$(COMPILER_HOST_FP) $< $@

build/gen/int/%.asm: src/%.bas $(COMPILER_HOST_INT) | build/gen/int
	$(ECHO) "Compiling INT BASIC $<"
	$(Q)$(COMPILER_HOST_INT) $< $@

build/gen/fp/%.asm: samples/fp/%.bas $(COMPILER_HOST_FP) | build/gen/fp
	$(ECHO) "Compiling FP BASIC sample $<"
	$(Q)$(COMPILER_HOST_FP) $< $@

build/gen/int/%.asm: samples/int/%.bas $(COMPILER_HOST_INT) | build/gen/int
	$(ECHO) "Compiling INT BASIC sample $<"
	$(Q)$(COMPILER_HOST_INT) $< $@

# Object file rules
build/obj/fp/%.o: src/%.asm | build/obj/fp build/obj/fp/interp $(CA65_HOST)
	$(ECHO) "Assembly FP $<"
	$(Q)$(CA65_HOST) $(CA65_FP_FLAGS) -l $(@:.o=.lst) -o $@ $<

build/obj/fp/%.o: build/gen/fp/%.asm | build/obj/fp $(CA65_HOST)
	$(ECHO) "Assembly FP $<"
	$(Q)$(CA65_HOST) $(CA65_FP_FLAGS) -l $(@:.o=.lst) -o $@ $<

build/obj/rom-fp/%.o: src/%.asm | build/obj/rom-fp build/obj/rom-fp/interp $(CA65_HOST)
	$(ECHO) "Assembly Cart FP $<"
	$(Q)$(CA65_HOST) $(CA65_FP_FLAGS) $(CA65_ROM) -l $(@:.o=.lst) -o $@ $<

build/obj/int/%.o: src/%.asm | build/obj/int build/obj/int/interp $(CA65_HOST)
	$(ECHO) "Assembly INT $<"
	$(Q)$(CA65_HOST) $(CA65_INT_FLAGS) -l $(@:.o=.lst) -o $@ $<

build/obj/int/%.o: build/gen/int/%.asm | build/obj/int $(CA65_HOST)
	$(ECHO) "Assembly INT $<"
	$(Q)$(CA65_HOST) $(CA65_INT_FLAGS) -l $(@:.o=.lst) -o $@ $<

build/obj/rom-int/%.o: src/%.asm | build/obj/rom-int build/obj/rom-int/interp $(CA65_HOST)
	$(ECHO) "Assembly Cart INT $<"
	$(Q)$(CA65_HOST) $(CA65_INT_FLAGS) $(CA65_ROM) -l $(@:.o=.lst) -o $@ $<

build/tests build/obj/tests \
build/gen build/obj build/obj/fp build/obj/int build/obj/fp/interp build/obj/int/interp \
build/obj/rom-fp build/obj/rom-int build/obj/rom-fp/interp build/obj/rom-int/interp \
build/gen/fp build/gen/int build/obj/cxx-fp build/obj/cxx-int build/obj/cxx-tgt-fp \
build/obj/cxx-tgt-int build/bin build/disk build/compiler/asminc build/compiler build:
	$(Q)mkdir -p $@

# Library files
$(LIB_FP): $(RT_OBJS_FP) $(COMMON_OBJS_FP) | build/compiler $(AR65_HOST)
	$(ECHO) "Creating FP library $@"
	$(Q)rm -f $@
	$(Q)$(AR65_HOST) a $@ $^

$(LIB_ROM_FP): $(RT_OBJS_ROM_FP) $(COMMON_OBJS_ROM_FP) | build/compiler $(AR65_HOST)
	$(ECHO) "Creating Cart FP library $@"
	$(Q)rm -f $@
	$(Q)$(AR65_HOST) a $@ $^

$(LIB_INT): $(RT_OBJS_INT) $(COMMON_OBJS_INT) | build/compiler $(AR65_HOST)
	$(ECHO) "Creating INT library $@"
	$(Q)rm -f $@
	$(Q)$(AR65_HOST) a $@ $^

$(LIB_ROM_INT): $(RT_OBJS_ROM_INT) $(COMMON_OBJS_ROM_INT) | build/compiler $(AR65_HOST)
	$(ECHO) "Creating Cart INT library $@"
	$(Q)rm -f $@
	$(Q)$(AR65_HOST) a $@ $^

# Copy manual to compiler changing the version string.
build/compiler/MANUAL.md: manual.md version.mk | build/compiler
	$(Q)LC_ALL=C sed 's/%VERSION%/$(VERSION)/' < $< > $@

# Copy other files to compiler folder
build/compiler/%: compiler/% | build/compiler
	$(Q)cp -f $< $@

# Copy assembly include files from CC65
build/compiler/asminc/%: cc65/asminc/% | build/compiler/asminc
	$(Q)cp -f $< $@

# Dependencies
$(COMMON_OBJS_FP): src/deftok.inc
$(COMMON_OBJS_INT): src/deftok.inc
build/obj/fp/parse.o: src/parse.asm build/gen/fp/basic.asm
build/obj/int/parse.o: src/parse.asm build/gen/int/basic.asm

$(HOST_OBJ) $(TARGET_OBJ): version.mk

# Automatic generation of dependency information for C++ files
build/obj/cxx-int/%.d: src/compiler/%.cc | build/gen/int/basic.h build/obj/cxx-int
	@$(CXX) -MM -MP -MF $@ -MT "$(@:.d=.o) $@" $(INTCXX) $(HOST_CXXFLAGS) $<
build/obj/cxx-int/%.d: build/gen/int/%.cc | build/obj/cxx-int
	@$(CXX) -MM -MP -MF $@ -MT "$(@:.d=.o) $@" $(INTCXX) $(HOST_CXXFLAGS) $<
build/obj/cxx-fp/%.d: src/compiler/%.cc | build/gen/fp/basic.h build/obj/cxx-fp
	@$(CXX) -MM -MP -MF $@ -MT "$(@:.d=.o) $@" $(FPCXX) $(HOST_CXXFLAGS) $<
build/obj/cxx-fp/%.d: build/gen/fp/%.cc | build/obj/cxx-fp
	@$(CXX) -MM -MP -MF $@ -MT "$(@:.d=.o) $@" $(FPCXX) $(HOST_CXXFLAGS) $<
ifneq ($(CROSS),)
build/obj/cxx-tgt-int/%.d: src/compiler/%.cc | build/gen/int/basic.h build/obj/cxx-tgt-int
	@$(CROSS)$(CXX) -MM -MP -MF $@ -MT "$(@:.d=.o) $@" $(INTCXX) $(TARGET_CXXFLAGS) $<
build/obj/cxx-tgt-int/%.d: build/gen/fp/%.cc | build/obj/cxx-tgt-int
	@$(CROSS)$(CXX) -MM -MP -MF $@ -MT "$(@:.d=.o) $@" $(INTCXX) $(TARGET_CXXFLAGS) $<
build/obj/cxx-tgt-fp/%.d: src/compiler/%.cc | build/gen/fp/basic.h build/obj/cxx-tgt-fp
	@$(CROSS)$(CXX) -MM -MP -MF $@ -MT "$(@:.d=.o) $@" $(FPCXX) $(TARGET_CXXFLAGS) $<
build/obj/cxx-tgt-fp/%.d: build/gen/fp/%.cc | build/obj/cxx-tgt-fp
	@$(CROSS)$(CXX) -MM -MP -MF $@ -MT "$(@:.d=.o) $@" $(FPCXX) $(TARGET_CXXFLAGS) $<
endif

ifneq "$(MAKECMDGOALS)" "clean"
    ifneq "$(MAKECMDGOALS)" "distclean"
        -include $(COMPILER_HOST_DEPS)
        ifneq ($(CROSS),)
            -include $(COMPILER_TARGET_DEPS)
        endif
    endif
endif
