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

// Emit parser as an ASM file
// --------------------------

#pragma once

#include <ostream>
#include <sstream>
#include <string>
#include <vector>

class asm_emit
{
    public:
        static constexpr const char *hex_prefix = "$";
        static std::string emit_literal(std::vector<std::string> &list)
        {
            std::string ret;
            for(auto &ch: list)
                ret += "\t.byte " + ch + "\n";
            return ret;
        }
        static std::string emit_bytes(bool last, std::vector<std::string> &ebytes, int)
        {
            auto n = ebytes.size();
            std::string lst;
            if( !n )
                return std::string();
            if( last )
            {
                n--;
                lst = ebytes[n];
                ebytes.pop_back();
            }
            std::stringstream os;
            if( n )
            {
                os << "\t.byte SM_EMIT_" << n;
                for(auto &s: ebytes)
                    os << ", " << s;
                os << "\n";
            }
            if( last )
                os << "\t.byte SM_ERET, " << lst << "\n";
            return os.str();
        }
        static std::string emit_ret(int)
        {
            return "\t.byte SM_RET\n";
        }
        static std::string emit_call(std::string sub)
        {
            return "\t.byte SMB_" + sub + "\n";
        }
        static std::string emit_line(std::string line, int)
        {
            return line;
        }
        static void print(std::ostream &os, std::string name, std::string desc,
                          const std::vector<std::string> &code, bool ok, int lnum)
        {
            os << name << ":\t; " << lnum << "\n";
            for(const auto &line: code)
                os << line;
            if( !ok )
                os << "\t.byte SM_EXIT\n";
            os << "\n";
        }
};
