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

MINI65=mini65/src
CC=gcc
CFLAGS=-g -O2 -Wall -I$(MINI65) -I$(MINI65)/../ccan/
LDLIBS=-lm


MINI65_SRC=\
  atari.c\
  hw.c\
  mathpack.c\
  sim65.c\

TESTS := $(wildcard tests/*.chk)

all: runtests

.PHONY: runtests
runtests: $(TESTS) fbtest
	./fbtest $(TESTS)

MINI65_OBJ=$(MINI65_SRC:%.c=obj/%.o)

fbtest: obj/fbtest.o $(MINI65_OBJ)
	$(CC) $(CFLAGS) -o $@ $^ $(LDLIBS)

obj/%.o: $(MINI65)/%.c | obj
	$(CC) $(CFLAGS) -c -o $@ $<

obj/%.o: src/%.c | obj
	$(CC) $(CFLAGS) -c -o $@ $<

obj:
	mkdir -p $@
