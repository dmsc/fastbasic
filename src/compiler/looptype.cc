/*
 * FastBasic - Fast basic interpreter for the Atari 8-bit computers
 * Copyright (C) 2017-2025 Daniel Serpell
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

// looptype.cc: Defines types of loops and variables

#include "looptype.h"
#include <stdexcept>

std::string get_loop_name(enum LoopType l)
{
    switch(l)
    {
    case LT_PROC_2:
        return "PROC";
    case LT_PROC_DATA:
        return "PROC/DATA";
    case LT_EXIT:
        return "EXIT";
    case LT_DO_LOOP:
        return "DO loop";
    case LT_REPEAT:
        return "REPEAT loop";
    case LT_WHILE_1:
    case LT_WHILE_2:
        return "WHILE loop";
    case LT_FOR_1:
    case LT_FOR_2:
        return "FOR loop";
    case LT_IF:
        return "IF";
    case LT_ELSE:
        return "ELSE";
    case LT_ELIF:
        return "ELIF";
    default:
        return "unknown loop";
    }
}

LoopType get_looptype(std::string t)
{
    if(t == "LT_PROC_DATA")
        return LT_PROC_DATA;
    if(t == "LT_PROC_2")
        return LT_PROC_2;
    if(t == "LT_DO_LOOP")
        return LT_DO_LOOP;
    if(t == "LT_REPEAT")
        return LT_REPEAT;
    if(t == "LT_WHILE_1")
        return LT_WHILE_1;
    if(t == "LT_WHILE_2")
        return LT_WHILE_2;
    if(t == "LT_FOR_1")
        return LT_FOR_1;
    if(t == "LT_FOR_2")
        return LT_FOR_2;
    if(t == "LT_EXIT")
        return LT_EXIT;
    if(t == "LT_IF")
        return LT_IF;
    if(t == "LT_ELSE")
        return LT_ELSE;
    if(t == "LT_ELIF")
        return LT_ELIF;
    throw std::runtime_error("invalid loop type");
}

bool loop_add_indent(enum LoopType l)
{
    switch(l)
    {
    case LT_PROC_2:
    case LT_DO_LOOP:
    case LT_REPEAT:
    case LT_WHILE_1:
    case LT_FOR_1:
    case LT_IF:
    case LT_ELSE:
        return true;
    case LT_ELIF:
    case LT_PROC_DATA:
    case LT_EXIT:
    case LT_WHILE_2:
    case LT_FOR_2:
        return false;
    default:
        return false;
    }
}
