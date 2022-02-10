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

$(A800_FP_OBJS): src/deftok.inc
$(A800_OBJS): src/deftok.inc
build/obj/fp/parse.o: src/parse.asm build/gen/fp/basic.asm
build/obj/int/parse.o: src/parse.asm build/gen/int/basic.asm

$(FASTBASIC_HOST_OBJ) $(FASTBASIC_TARGET_OBJ): version.mk

# The compiler dependencies - auto-generated from c++ files
FASTBASIC_HOST_DEPS=$(FASTBASIC_HOST_OBJ:.o=.d)
FASTBASIC_TARGET_DEPS=$(FASTBASIC_TARGET_OBJ:.o=.d)
SYNTAX_PARSER_DEPS=$(SYNTAX_PARSER_OBJ:.o=.d)

# Automatic generation of dependency information for C++ files
build/obj/cxx/%.d: src/compiler/%.cc | build/obj/cxx
	@$(CXX) -MM -MP -MF $@ -MT "$(@:.d=.o) $@" $(FB_CXX) $(HOST_CXXFLAGS) $<
ifneq ($(CROSS),)
build/obj/cxx-tgt/%.d: src/compiler/%.cc | build/obj/cxx-tgt
	@$(CROSS)$(CXX) -MM -MP -MF $@ -MT "$(@:.d=.o) $@" $(FB_CXX) $(TARGET_CXXFLAGS) $<
endif

ifneq "$(MAKECMDGOALS)" "clean"
    ifneq "$(MAKECMDGOALS)" "distclean"
        -include $(FASTBASIC_HOST_DEPS)
        -include $(SYNTAX_PARSER_DEPS)
        ifneq ($(CROSS),)
            -include $(FASTBASIC_TARGET_DEPS)
        endif
    endif
endif
