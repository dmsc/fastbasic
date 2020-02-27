/*
 * FastBasic - Fast basic interpreter for the Atari 8-bit computers
 * Copyright (C) 2017-2019 Daniel Serpell
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>
 */

// looptype.h: Defines types of loops and variables

#pragma once

#include <string>

enum LoopType {
    // First entries can't use "EXIT"
    LT_PROC_DATA = 0,
    LT_EXIT,
    // From here, loops don't push jump destinations
    LT_LAST_JUMP = 32,
    LT_PROC_2,
    LT_DO_LOOP,
    LT_REPEAT,
    LT_WHILE_1,
    LT_FOR_1,
    // And from here, loops push destinations and are ignored by EXIT
    LT_WHILE_2 = 128,
    LT_FOR_2,
    LT_IF,
    LT_ELSE,
    LT_ELIF
};

std::string get_loop_name(enum LoopType l);
LoopType get_looptype(std::string t);

