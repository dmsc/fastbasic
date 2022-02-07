/*
 * FastBasic - Fast basic interpreter for the Atari 8-bit computers
 * Copyright (C) 2017-2022 Daniel Serpell
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

// synt-emit-cc.cc: emit parser as a C++ file
#include "synt-emit-cc.h"
#include "synt-wlist.h"

#include <ostream>
#include <sstream>
#include <string>
#include <vector>

using namespace syntax;

namespace
{
class cpp_emit
{
  private:
    std::ostream &os;
    const statemachine &sm;
    int lbl_num = 0;

    void print_bytes_ret(const std::vector<std::string> &data, int lnum)
    {
        print_bytes(data);
        print_return(lnum);
    }
    void print_bytes(const std::vector<std::string> &data)
    {
        for(auto &c : data)
        {
            if(c.size() && c[0] == '&')
                os << "\t\ts.emit_word(\"" << c.substr(1) << "\");\n";
            else if(c.substr(0, 4) == "TOK_")
                os << "\t\ts.emit_tok(\"" << c << "\");\n";
            else
                os << "\t\ts.emit_byte(\"" << c << "\");\n";
        }
        os << "\n";
    }
    void print_literal(std::string str)
    {
        std::stringstream dbg;
        bool used_lbl = false;
        for(auto &ch : str)
        {
            if(ch >= 'a' && ch <= 'z')
            {
                ch = ch - 'a' + 'A';
                dbg << ch;
                os << "\t\tif( !s.expect(\'" << ch
                   << "\') )"
                      " { if( !s.expect('.') ) break; "
                      "goto accept_char_"
                   << lbl_num << "; }\n";
                used_lbl = true;
            }
            else
            {
                if(ch >= ' ' && ch < 127 && ch != '\'')
                    os << "\t\tif( !s.expect('" << ch << "') ) break;\n";
                else
                    os << "\t\tif( !s.expect(" << (ch & 255) << ") ) break;\n";

                if(ch >= ' ' && ch < 127 && ch != '"')
                    dbg << ch;
                else
                    dbg << "\\x" << std::hex << (ch >> 4) << (ch & 15);
            }
        }
        if(used_lbl)
        {
            os << "accept_char_" << lbl_num << ":\n";
            lbl_num++;
        }
        os << "\t\ts.debug(\"GOT '" << dbg.str() << "'\");\n";
        os << "\t\ts.add_text(\"" << dbg.str() << "\");\n";
    }
    void print_return(int lnum)
    {
        os << "\t\ts.debug(\"<-- OK (" << lnum
           << ")\");\n"
              "\t\ts.lvl--;\n"
              "\t\treturn true;\n";
    }
    void print_call_tab(std::string sub) { os << "\t\tif( !SMB_" << sub << "(s) ) break;\n"; }
    void print_call_ext(std::string sub)
    {
        os << "\t\tif( !call_parsing_action(\"" << sub << "\", s) ) break;\n";
    }
    void print_line(const std::vector<statemachine::pcode> &pc, int lnum)
    {
        os << "\tdo {\n";
        for(const auto &c : pc)
        {
            switch(c.type)
            {
            case statemachine::pcode::c_literal:
                print_literal(c.str);
                break;
            case statemachine::pcode::c_emit:
                print_bytes(c.data);
                break;
            case statemachine::pcode::c_emit_return:
                print_bytes_ret(c.data, lnum);
                break;
            case statemachine::pcode::c_call_ext:
                print_call_ext(c.str);
                break;
            case statemachine::pcode::c_call_table:
                print_call_tab(c.str);
                break;
            case statemachine::pcode::c_return:
                print_return(lnum);
                break;
            }
        }
        os << "\t} while(0);\n"
              "\ts.debug(\"-! "
           << lnum
           << "\");\n"
              "\ts.restore(spos);\n";
    }

  public:
    cpp_emit(std::ostream &os, const statemachine &sm) : os(os), sm(sm) {}
    void print()
    {
        os << "static bool SMB_" << sm.name()
           << "(parse &s) {\n"
              "\ts.debug(\""
           << sm.name() << " (" << sm.line_num()
           << ")\");\n"
              "\ts.check_level();\n"
              "\ts.skipws();\n"
              "\ts.error(\""
           << sm.error_text()
           << "\");\n"
              "\tauto spos = s.save();\n";

        for(const auto &line : sm.get_code())
            print_line(line.pc, line.lnum);

        os << "\ts.lvl--;\n"
              "\treturn false;\n}\n"
              "\n";
    }
};
} // namespace

bool syntax::syntax_emit_cc(std::ostream &hdr, std::ostream &out, sm_list_type &sm_list,
                            const wordlist &tok, const wordlist &ext)
{
    // Sort tokens by index (order in token table)
    std::vector<std::string> sorted_toks(tok.next());
    for(auto i : tok.map())
        sorted_toks[i.second] = i.first;

    // Output header
    hdr << "// Syntax state machine - header\n"
           "// -----------------------------\n"
           "// This is a generated file - do not modify\n"
           "#pragma once\n"
           "#include <string>\n"
           "\n"
           "class parse;\n"
           "bool parse_start(parse &s);\n";

    // Output parser C++ file
    out << "// Syntax state machine\n"
           "// --------------------\n"
           "// This is a generated file - do not modify\n"
           "\n"
           "#include \"basic.h\"\n"
           "#include \"parser.h\"\n"
           "\n";

    // Emit state machine tables
    for(auto &sm : sm_list)
        out << "static bool SMB_" << sm.second->name() << "(parse &s);\n";

    // Emit state machine tables
    out << "\n";
    for(auto &sm : sm_list)
    {
        cpp_emit c(out, *sm.second);
        c.print();
    }

    out << "\n"
           "// Parsing start function\n"
           "bool parse_start(parse &s)\n"
           "{\n"
           "    return SMB_PARSE_START(s);\n"
           "}\n"
           "\n";
    return true;
}
