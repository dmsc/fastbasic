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

MINI65=mini65
CC=gcc
CFLAGS=-g -O2 -Wall -I$(MINI65)/src/ -I$(MINI65)/ccan/
LDLIBS=-lm

RUNTEST=fbtest

MINI65_SRC=\
  atari.c\
  dosfname.c\
  hw.c\
  mathpack.c\
  sim65.c\

# All the tests
TESTS := $(sort $(wildcard tests/*.chk))

# The tests need to be rerun if any of this files change:
TESTS_DEPS=\
	../build/bin/fbc.xex\
	../build/bin/fastbasic-fp\
	../build/bin/fastbasic-int\
	../build/bin/ca65\
	../build/bin/ld65\
	../build/compiler/fastbasic-fp.lib\
	../build/compiler/fastbasic-int.lib\
	../build/compiler/fastbasic.cfg\


TESTS_XEX=$(TESTS:.chk=.xex)
TESTS_ASM=$(TESTS:.chk=.asm)
TESTS_OBJ=$(TESTS:.chk=.o)
TESTS_ATB=$(TESTS:.chk=.atb)
TESTS_LBL=$(TESTS:.chk=.lbl)
TESTS_STAMP=$(TESTS:.chk=.stamp)

OBJS=obj/fbtest.o $(MINI65_SRC:%.c=obj/%.o)

all: runtests

.PHONY: runtests clean distclean
runtests: $(TESTS_STAMP) fbtest

%.stamp: %.chk %.bas fbtest $(TESTS_DEPS)
	@./fbtest $<
	@touch $@

clean:
	rm -f $(TESTS_XEX) $(TESTS_ASM) $(TESTS_OBJ) $(TESTS_ATB) $(TESTS_LBL) $(OBJS) $(RUNTEST) $(TESTS_STAMP)

distclean: clean
	-rmdir obj

$(RUNTEST): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^ $(LDLIBS)

obj/%.o: $(MINI65)/src/%.c | obj mini65/src
	$(CC) $(CFLAGS) -c -o $@ $<

obj/%.o: src/%.c | obj mini65/src
	$(CC) $(CFLAGS) -c -o $@ $<

obj:
	mkdir -p $@

# Update mini65 submodule if not found
mini65/src:
	git submodule update --init $(MINI65)

# Automatic generation of dependency information for C files
obj/%.d: src/%.c | obj mini65/src
	$(CC) -MM -MP -MF $@ -MT "$(@:.d=.o) $@" $(CFLAGS) $<

ifneq "$(MAKECMDGOALS)" "clean"
    ifneq "$(MAKECMDGOALS)" "distclean"
        -include $(OBJS:%.o=%.d)
    endif
endif
