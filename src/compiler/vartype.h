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

// vartype.h: Defines types of variables

#pragma once
#include <string>

// Variable types
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

// Returns VarType from the type name
VarType get_vartype(std::string t);
// Returns the variable type name from VarType.
std::string get_vt_name(enum VarType t);
// Returns the size in bytes for this variable type
int get_vt_size(enum VarType t);
// Returns true if VarType is an array type
bool var_type_is_array(enum VarType t);

// Label types
class labelType {
    public:
        // Create from string in parser file
        labelType(std::string t);
        labelType();
        bool is_defined();
        bool is_proc();
        bool add_proc_params(int params);
        int  num_params();
        void define();
        void set_type(std::string);
        bool operator !=(const labelType &l) const { return type != l.type; }
    private:
        int type;
};



