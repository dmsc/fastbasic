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

# Main compilation rules
all: $(ATR) $(COMPILER_COMMON) $(COMPILER_TARGET)

dist: $(ATR) $(ZIPFILE)

.PHONY: clean
clean:
	$(Q)rm -f $(OBJS) $(LSTS) $(FILES) $(ATR) $(ZIPFILE) $(XEXS) $(MAPS) \
	      $(LBLS) $(SYNTP) $(COMPILER_HOST) $(FASTBASIC_TARGET_OBJ) \
	      $(FASTBASIC_HOST_DEPS) $(FASTBASIC_TARGET_DEPS) $(SYNTAX_PARSER_DEPS)\
	      $(SAMPLE_BAS:%.bas=build/gen/%.asm) \
	      $(FASTBASIC_HOST_OBJ) $(SYNTAX_PARSER_OBJ)
	$(Q)rm -f $(TESTS_XEX) $(TESTS_ROM) $(TESTS_ASM) $(TESTS_OBJ) $(TESTS_ATB) $(TESTS_LBL) $(RUNTEST_OBJS) $(RUNTEST) $(TESTS_STAMP) $(RUNTEST_OBJS:.o=.d)

.PHONY: distclean
distclean: clean
	$(Q)-rm -f build/gen/int/basic.asm build/gen/fp/basic.asm \
	    build/gen/int/basic.inc  build/gen/fp/basic.inc  \
	    build/gen/int/editor.asm build/gen/fp/editor.asm \
	    $(CMD_BAS_SRC) \
	    $(CMD_BAS_SRC:build/gen/%.bas=build/gen/fp/%.asm) \
	    $(COMPILER_HOST) $(COMPILER_TARGET) $(COMPILER_COMMON)
	$(Q)printf "%s\n" $(BUILD_FOLDERS) | sort -r | while read folder; do \
		test -d $$folder && rmdir $$folder || true ; done

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
$(SYNTP): $(SYNTAX_PARSER_OBJ) | build/gen
	$(ECHO) "Compile parser generator tool $@"
	$(Q)$(CXX) $(HOST_CXXFLAGS) -o $@ $^

# Host compiler build
build/obj/cxx/%.o: src/compiler/%.cc | build/obj/cxx
	$(ECHO) "Compile $<"
	$(Q)$(CXX) $(HOST_CXXFLAGS) $(FB_CXX) -c -o $@ $<

$(FASTBASIC_HOST): $(FASTBASIC_HOST_OBJ) | build/bin
	$(ECHO) "Linking host compiler"
	$(Q)$(CXX) $(HOST_CXXFLAGS) $(FB_CXX) -o $@ $^

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
build/obj/cxx-tgt/%.o: src/compiler/%.cc | build/obj/cxx-tgt
	$(ECHO) "Compile target $<"
	$(Q)$(CROSS)$(CXX) $(TARGET_CXXFLAGS) $(FB_CXX) -c -o $@ $<

$(FASTBASIC_TARGET): $(FASTBASIC_TARGET_OBJ) | build/compiler
	$(ECHO) "Linking target compiler"
	$(Q)$(CROSS)$(CXX) $(TARGET_CXXFLAGS) $(FB_CXX) -o $@ $^

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
build/gen/fp/basic.asm: $(SYNTAX_FP) $(SYNTP) | build/gen/fp
	$(ECHO) "Creating FP parsing bytecode"
	$(Q)$(SYNTP) $(SYNTAX_FP) -o $@

# Generator for syntax file - 6502 version - INTEGER
build/gen/int/basic.asm: $(SYNTAX_INT) $(SYNTP) | build/gen/int
	$(ECHO) "Creating INT parsing bytecode"
	$(Q)$(SYNTP) $(SYNTAX_INT) -o $@

# Sets the version inside command line compiler source
build/gen/cmdline-vers.bas: src/cmdline.bas version.mk
	$(Q)LC_ALL=C sed 's/%VERSION%/$(VERSION)/' < $< > $@

# Main program file
build/bin/fb.xex: $(IDE_OBJS_FP) $(A800_FP_OBJS) $(IDE_BAS_OBJS_FP) | build/bin $(LD65_HOST)
	$(ECHO) "Linking floating point IDE"
	$(Q)$(LD65_HOST) $(LD65_FLAGS) -Ln $(@:.xex=.lbl) -vm -m $(@:.xex=.map) -o $@ $^

build/bin/fbc.xex: $(CMD_OBJS_FP) $(A800_FP_OBJS) $(CMD_BAS_OBJS_FP) | build/bin $(LD65_HOST)
	$(ECHO) "Linking command line compiler"
	$(Q)$(LD65_HOST) $(LD65_FLAGS) -Ln $(@:.xex=.lbl) -vm -m $(@:.xex=.map) -o $@ $^

build/bin/fbi.xex: $(IDE_OBJS_INT) $(A800_OBJS) $(IDE_BAS_OBJS_INT) | build/bin $(LD65_HOST)
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
build/gen/fp/%.asm: build/gen/%.bas $(FASTBASIC_HOST) | build/gen/fp
	$(ECHO) "Compiling FP BASIC $<"
	$(Q)$(FASTBASIC_HOST) $(FB_FP_FLAGS) -o $@ -c $<

build/gen/fp/%.asm: src/%.bas $(FASTBASIC_HOST) | build/gen/fp
	$(ECHO) "Compiling FP BASIC $<"
	$(Q)$(FASTBASIC_HOST) $(FB_FP_FLAGS) -o $@ -c $<

build/gen/int/%.asm: src/%.bas $(FASTBASIC_HOST) | build/gen/int
	$(ECHO) "Compiling INT BASIC $<"
	$(Q)$(FASTBASIC_HOST) $(FB_INT_FLAGS) -o $@ -c $<

build/gen/fp/%.asm: samples/fp/%.bas $(FASTBASIC_HOST) | build/gen/fp
	$(ECHO) "Compiling FP BASIC sample $<"
	$(Q)$(FASTBASIC_HOST) $(FB_FP_FLAGS) -o $@ -c $<

build/gen/int/%.asm: samples/int/%.bas $(FASTBASIC_HOST) | build/gen/int
	$(ECHO) "Compiling INT BASIC sample $<"
	$(Q)$(FASTBASIC_HOST) $(FB_INT_FLAGS) -o $@ -c $<

# Object file rules
build/obj/fp/%.o: src/%.asm | $(AS_FOLDERS:src%=build/obj/fp%) $(CA65_HOST)
	$(ECHO) "Assembly FP $<"
	$(Q)$(CA65_HOST) $(CA65_FP_FLAGS) -l $(@:.o=.lst) -o $@ $<

build/obj/fp/%.o: build/gen/fp/%.asm | build/obj/fp $(CA65_HOST)
	$(ECHO) "Assembly FP $<"
	$(Q)$(CA65_HOST) $(CA65_FP_FLAGS) -l $(@:.o=.lst) -o $@ $<

build/obj/rom-fp/%.o: src/%.asm | $(AS_FOLDERS:src%=build/obj/rom-fp%) $(CA65_HOST)
	$(ECHO) "Assembly Cart FP $<"
	$(Q)$(CA65_HOST) $(CA65_FP_FLAGS) $(CA65_ROM) -l $(@:.o=.lst) -o $@ $<

build/obj/int/%.o: src/%.asm | $(AS_FOLDERS:src%=build/obj/int%) $(CA65_HOST)
	$(ECHO) "Assembly INT $<"
	$(Q)$(CA65_HOST) $(CA65_INT_FLAGS) -l $(@:.o=.lst) -o $@ $<

build/obj/int/%.o: build/gen/int/%.asm | build/obj/int $(CA65_HOST)
	$(ECHO) "Assembly INT $<"
	$(Q)$(CA65_HOST) $(CA65_INT_FLAGS) -l $(@:.o=.lst) -o $@ $<

build/obj/rom-int/%.o: src/%.asm | $(AS_FOLDERS:src%=build/obj/rom-int%) $(CA65_HOST)
	$(ECHO) "Assembly Cart INT $<"
	$(Q)$(CA65_HOST) $(CA65_INT_FLAGS) $(CA65_ROM) -l $(@:.o=.lst) -o $@ $<

# Rule to build all folders
$(BUILD_FOLDERS):
	$(Q)mkdir -p $@

# Library files
$(LIB_FP): $(RT_OBJS_FP) $(A800_FP_OBJS) | build/compiler $(AR65_HOST)
	$(ECHO) "Creating FP library $@"
	$(Q)rm -f $@
	$(Q)$(AR65_HOST) a $@ $^

$(LIB_ROM_FP): $(RT_OBJS_ROM_FP) $(A800_FP_ROM_OBJS) | build/compiler $(AR65_HOST)
	$(ECHO) "Creating Cart FP library $@"
	$(Q)rm -f $@
	$(Q)$(AR65_HOST) a $@ $^

$(LIB_INT): $(RT_OBJS_INT) $(A800_OBJS) | build/compiler $(AR65_HOST)
	$(ECHO) "Creating INT library $@"
	$(Q)rm -f $@
	$(Q)$(AR65_HOST) a $@ $^

$(LIB_ROM_INT): $(RT_OBJS_ROM_INT) $(A800_ROM_OBJS) | build/compiler $(AR65_HOST)
	$(ECHO) "Creating Cart INT library $@"
	$(Q)rm -f $@
	$(Q)$(AR65_HOST) a $@ $^

# Copy manual to compiler changing the version string.
build/compiler/MANUAL.md: manual.md version.mk | build/compiler
	$(Q)LC_ALL=C sed 's/%VERSION%/$(VERSION)/' < $< > $@

# Copy other files to compiler folder
build/compiler/%: compiler/% | build/compiler
	$(Q)cp -f $< $@

# Copy compatibility binaries
build/compiler/fb$(EXT): build/compiler/fastbasic$(EXT)
	$(Q)cp -f $< $@

# Copy compatibility binaries
build/compiler/fb-int$(EXT): build/compiler/fastbasic$(EXT)
	$(Q)cp -f $< $@

# Copy syntax files to compiler folder
build/compiler/syntax/%: src/syntax/% | build/compiler/syntax
	$(Q)cp -f $< $@

# Copy other files to compiler folder
build/compiler/%: compiler/% | build/compiler
	$(Q)cp -f $< $@

# Copy assembly include files from CC65
build/compiler/asminc/%: cc65/asminc/% | build/compiler/asminc
	$(Q)cp -f $< $@


