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

// vartype.cc: Defines types of variables

#include "vartype.h"
#include <stdexcept>

VarType get_vartype(std::string t)
{
    if(t == "VT_UNDEF")
        return VT_UNDEF;
    if(t == "VT_WORD")
        return VT_WORD;
    if(t == "VT_ARRAY_WORD")
        return VT_ARRAY_WORD;
    if(t == "VT_ARRAY_BYTE")
        return VT_ARRAY_BYTE;
    if(t == "VT_ARRAY_STRING")
        return VT_ARRAY_STRING;
    if(t == "VT_ARRAY_FLOAT")
        return VT_ARRAY_FLOAT;
    if(t == "VT_STRING")
        return VT_STRING;
    if(t == "VT_FLOAT")
        return VT_FLOAT;
    return VT_UNDEF;
}

std::string get_vt_name(enum VarType t)
{
    switch(t)
    {
    case VT_ARRAY_WORD:
        return "word array";
    case VT_ARRAY_BYTE:
        return "byte array";
    case VT_ARRAY_STRING:
        return "string array";
    case VT_ARRAY_FLOAT:
        return "float array";
    case VT_WORD:
        return "word";
    case VT_STRING:
        return "string";
    case VT_FLOAT:
        return "float";
    case VT_UNDEF:
        break;
    }
    return "UNDEFINED";
}

int get_vt_size(enum VarType t)
{
    switch(t)
    {
    case VT_ARRAY_WORD:
    case VT_ARRAY_BYTE:
    case VT_ARRAY_STRING:
    case VT_ARRAY_FLOAT:
    case VT_WORD:
    case VT_STRING:
        return 2;
    case VT_FLOAT:
        return 6;
    case VT_UNDEF:
        return 0;
    }
    return 0;
}

// Properties of variable types:
bool var_type_is_array(enum VarType t)
{
    switch(t)
    {
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

labelType::labelType() : type(0) {}

labelType::labelType(std::string str)
{
    set_type(str);
}

void labelType::set_type(std::string str)
{
    if(str == "VT_ARRAY_WORD")
        type = 128;
    else if(str == "VT_ARRAY_BYTE")
        type = 129;
    else
        throw std::runtime_error("invalid label type " + str);
}

void labelType::set_segment(std::string str)
{
    segment = str;
}

std::string labelType::get_segment()
{
    return segment;
}

bool labelType::is_defined()
{
    return type >= 64;
}

bool labelType::is_proc()
{
    return type < 128;
}

bool labelType::add_proc_params(int params)
{
    if(!type)
        type = params + 1;

    return num_params() == params;
}

int labelType::num_params()
{
    return (type & 63) - 1;
}

void labelType::define()
{
    type |= 64;
}
