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

// looptype.cc: Defines types of loops and variables

#include <string>
#include <stdexcept>

enum LoopType {
    // First entries can't use "EXIT"
    LT_PROC_1 = 0,
    LT_DATA,
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

std::string get_loop_name(enum LoopType l)
{
    switch( l )
    {
        case LT_PROC_1:
        case LT_PROC_2:
            return "PROC";
        case LT_DATA:
            return "DATA";
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

static LoopType get_looptype(std::string t)
{
    if( t == "LT_PROC_1" )
        return LT_PROC_1;
    if( t == "LT_PROC_2" )
        return LT_PROC_2;
    if( t == "LT_DATA" )
        return LT_DATA;
    if( t == "LT_DO_LOOP" )
        return LT_DO_LOOP;
    if( t == "LT_REPEAT" )
        return LT_REPEAT;
    if( t == "LT_WHILE_1" )
        return LT_WHILE_1;
    if( t == "LT_WHILE_2" )
        return LT_WHILE_2;
    if( t == "LT_FOR_1" )
        return LT_FOR_1;
    if( t == "LT_FOR_2" )
        return LT_FOR_2;
    if( t == "LT_EXIT" )
        return LT_EXIT;
    if( t == "LT_IF" )
        return LT_IF;
    if( t == "LT_ELSE" )
        return LT_ELSE;
    if( t == "LT_ELIF" )
        return LT_ELIF;
    throw std::runtime_error("invalid loop type");
}

