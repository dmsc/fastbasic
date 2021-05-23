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

# Make dependencies

$(COMMON_OBJS_FP): src/deftok.inc
$(COMMON_OBJS_INT): src/deftok.inc
build/obj/fp/parse.o: src/parse.asm build/gen/fp/basic.asm
build/obj/int/parse.o: src/parse.asm build/gen/int/basic.asm
$(CSYNT): \
 src/generator/csynt.cc \
 src/generator/synt-parse.h \
 src/generator/synt-wlist.h \
 src/generator/synt-sm.h \
 src/generator/synt-emit-cc.h \
 src/generator/synt-read.h
$(ASYNT): \
 src/generator/asynt.cc \
 src/generator/synt-parse.h \
 src/generator/synt-wlist.h \
 src/generator/synt-sm.h \
 src/generator/synt-emit-asm.h \
 src/generator/synt-read.h

$(HOST_OBJ) $(TARGET_OBJ): version.mk

# The compiler dependencies - auto-generated from c++ files
COMPILER_HOST_DEPS=$(COMPILER_HOST_INT_OBJ:.o=.d) $(COMPILER_HOST_FP_OBJ:.o=.d)
COMPILER_TARGET_DEPS=$(COMPILER_TARGET_INT_OBJ:.o=.d) $(COMPILER_TARGET_FP_OBJ:.o=.d)

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
