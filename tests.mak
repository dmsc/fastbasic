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

# Rules for running the tests
MINI65=testsuite/mini65
TEST_CFLAGS=-g -O2 -Wall -I$(MINI65)/src/ -I$(MINI65)/ccan/
TEST_LDLIBS=-lm
RUNTEST=build/bin/fbtest

MINI65_SRC=\
  atari.c\
  dosfname.c\
  hw.c\
  mathpack.c\
  sim65.c\

# All the tests
TESTS := $(sort $(wildcard testsuite/tests/*.chk))

# The tests need to be rerun if any of this files change:
TESTS_DEPS=\
	build/bin/fbc.xex\
	build/bin/fastbasic\
	build/bin/ca65\
	build/bin/ld65\
        $(COMPILER_COMMON)\

TESTS_XEX=$(TESTS:testsuite/%.chk=build/%.xex)
TESTS_ROM=$(TESTS:testsuite/%.chk=build/%.rom)
TESTS_ASM=$(TESTS:testsuite/%.chk=build/%.asm)
TESTS_OBJ=$(TESTS:testsuite/%.chk=build/%.o)
TESTS_ATB=$(TESTS:testsuite/%.chk=build/%.atb)
TESTS_LBL=$(TESTS:testsuite/%.chk=build/%.lbl)
TESTS_STAMP=$(TESTS:testsuite/%.chk=build/%.stamp)

RUNTEST_OBJS=build/obj/tests/fbtest.o $(MINI65_SRC:%.c=build/obj/tests/%.o)

# Runs the test suite
.PHONY: test
test: $(TESTS_STAMP) $(RUNTEST)

build/%.stamp: testsuite/%.chk testsuite/%.bas $(RUNTEST) $(TESTS_DEPS) | build/tests
	$(Q)$(RUNTEST) $<
	@touch $@

$(RUNTEST): $(RUNTEST_OBJS) | build/bin
	$(ECHO) "Linking $@"
	$(Q)$(CC) $(TEST_CFLAGS) -o $@ $^ $(TEST_LDLIBS)

build/obj/tests/%.o: $(MINI65)/src/%.c | build/obj/tests $(MINI65)/src
	$(ECHO) "Compiling $<"
	$(Q)$(CC) $(TEST_CFLAGS) -c -o $@ $<

build/obj/tests/%.o: testsuite/src/%.c | build/obj/tests $(MINI65)/src
	$(ECHO) "Compiling $<"
	$(Q)$(CC) $(TEST_CFLAGS) -c -o $@ $<

# Update mini65 submodule if not found
testsuite/mini65/src:
	$(Q)git submodule update --init $(MINI65)

# Automatic generation of dependency information for C files
build/obj/tests/%.d: testsuite/src/%.c | build/obj/tests $(MINI65)/src
	@$(CC) -MM -MP -MF $@ -MT "$(@:.d=.o) $@" $(TEST_CFLAGS) $<

build/obj/tests/%.d: $(MINI65)/src/%.c | build/obj/tests $(MINI65)/src
	@$(CC) -MM -MP -MF $@ -MT "$(@:.d=.o) $@" $(TEST_CFLAGS) $<

ifneq "$(MAKECMDGOALS)" "clean"
    ifneq "$(MAKECMDGOALS)" "distclean"
        -include $(RUNTEST_OBJS:%.o=%.d)
    endif
endif
