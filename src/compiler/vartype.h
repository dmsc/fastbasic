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

// vartype.h: Defines types of variables

#pragma once
#include <string>

enum VarType {
        VT_UNDEF = 0,
        VT_WORD,
        VT_ARRAY_WORD,
        VT_ARRAY_BYTE,
        VT_ARRAY_STRING,
        VT_ARRAY_FLOAT,
        VT_STRING,
        VT_FLOAT
};

VarType get_vartype(std::string t);
std::string get_vt_name(enum VarType t);
bool var_type_is_array(enum VarType t);

