/*
 * FastBasic - Fast basic interpreter for the Atari 8-bit computers
 * Copyright (C) 2017-2021 Daniel Serpell
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

// vartype.cc: Defines types of variables

#include "vartype.h"

VarType get_vartype(std::string t)
{
    if( t == "VT_UNDEF" )
        return VT_UNDEF;
    if( t == "VT_WORD" )
        return VT_WORD;
    if( t == "VT_ARRAY_WORD" )
        return VT_ARRAY_WORD;
    if( t == "VT_ARRAY_BYTE" )
        return VT_ARRAY_BYTE;
    if( t == "VT_ARRAY_STRING" )
        return VT_ARRAY_STRING;
    if( t == "VT_ARRAY_FLOAT" )
        return VT_ARRAY_FLOAT;
    if( t == "VT_STRING" )
        return VT_STRING;
    if( t == "VT_FLOAT" )
        return VT_FLOAT;
    return VT_UNDEF;
}

std::string get_vt_name(enum VarType t)
{
    switch(t) {
        case VT_ARRAY_WORD:
            return "Word Array";
        case VT_ARRAY_BYTE:
            return "Byte Array";
        case VT_ARRAY_STRING:
            return "String Array";
        case VT_ARRAY_FLOAT:
            return "Float Array";
        case VT_WORD:
            return "Word";
        case VT_STRING:
            return "String";
        case VT_FLOAT:
            return "Float";
        case VT_UNDEF:
            break;
    }
    return "UNDEFINED";
}

// Properties of variable types:
bool var_type_is_array(enum VarType t)
{
    switch(t) {
        case VT_ARRAY_WORD:
        case VT_ARRAY_BYTE:
        case VT_ARRAY_STRING:
        case VT_ARRAY_FLOAT:
            return true;
        case VT_UNDEF:
        case VT_WORD:
        case VT_STRING:
        case VT_FLOAT:
            return false;
    }
    return false;
}

