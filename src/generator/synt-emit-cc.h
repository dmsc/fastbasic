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

// Emit parser as a C++ file
// -------------------------

#pragma once

#include <ostream>
#include <sstream>
#include <string>
#include <vector>

class cc_emit
{
    public:
        static constexpr const char *hex_prefix = "0x";
        static std::string emit_literal(std::vector<std::string> &list)
        {
            static int lbl_num = 0;
            std::string ret, dbg;
            bool used_lbl = false;
            for(auto &ch: list)
            {
                if( ch.length() == 3 && ch[0] == '\'' && ch[1] >= 'a' && ch[1] <= 'z' )
                {
                    ch[1] = ch[1] - 'a' + 'A';
                    dbg += ch[1];
                    ret += "\t\tif( !s.expect(" + ch + ") )"
                           " { if( !s.expect('.') ) break; "
                           "goto accept_char_" + std::to_string(lbl_num) + "; }\n";
                    used_lbl = true;
                }
                else
                {
                    ret += "\t\tif( !s.expect(" + ch + ") ) break;\n";
                    if( ch.length() == 3 && ch[0] == '\'' )
                        dbg += ch[1];
                    else if( ch == "0x22" )
                        dbg += "\\\"";
                    else if( ch == "0x27" )
                        dbg += "\\\'";
                    else
                        dbg += ch;
                }
            }
            if( used_lbl )
            {
                ret += "accept_char_" + std::to_string(lbl_num) + ":\n";
                lbl_num ++;
            }
            ret += "\t\ts.debug(\"GOT '" + dbg + "'\");\n";
            ret += "\t\ts.add_text(\"" + dbg + "\");\n";
            return ret;
        }
        static std::string emit_bytes(bool last, std::vector<std::string> &ebytes, int lnum)
        {
            if( 0 == ebytes.size() )
                return std::string();

            std::stringstream os;
            for(auto &s: ebytes)
            {
                if( s.empty() )
                    continue;
                if( s[0] == '<' )
                    continue;
                if( s[0] == '>' )
                    os << "\t\ts.emit_word(\"" << s.substr(1) << "\");\n";
                else if( s.substr(0,4) == "TOK_" )
                    os << "\t\ts.emit_tok(" << s << ");\n";
                else
                    os << "\t\ts.emit_byte(\"" << s << "\");\n";
            }
            os << "\n";

            if( last )
                os << "\t\ts.debug(\"<-- OK (" + std::to_string(lnum) + ")\");\n"
                      "\t\ts.lvl--;\n"
                      "\t\treturn true;\n";
            return os.str();
        }
        static std::string emit_ret(int lnum)
        {
            return "\t\ts.debug(\"<-- OK (" + std::to_string(lnum) + ")\");\n"
                   "\t\ts.lvl--;\n"
                   "\t\treturn true;\n";
        }
        static std::string emit_call(std::string sub)
        {
            return "\t\tif( !SMB_" + sub + "(s) ) break;\n";
        }
        static std::string emit_line(std::string line, int lnum)
        {
            return "\tdo {\n" + line +
                   "\t} while(0);\n"
                   "\ts.debug(\"-! " + std::to_string(lnum) + "\");\n"
                   "\ts.restore(spos);\n";
        }
        static void print(std::ostream &os, std::string name, std::string desc,
                          const std::vector<std::string> &code, bool ok, int lnum)
        {
            os << "static bool SMB_" << name << "(parse &s) {\n"
                  "\ts.debug(\"" << name << " (" << lnum << ")\");\n"
                  "\ts.check_level();\n"
                  "\ts.skipws();\n"
                  "\ts.error(\"" << desc << "\");\n"
                  "\tauto spos = s.save();\n";
            for(const auto &line: code)
                os << line;
            os << "\ts.lvl--;\n"
                  "\treturn false;\n}\n"
                  "\n";
        }
};
