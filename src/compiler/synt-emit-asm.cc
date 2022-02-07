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

// synt-emit-asm.cc: emit parser as an ASM file
#include "synt-emit-asm.h"

#include <ostream>
#include <string>
#include <vector>

using namespace syntax;

namespace
{
class asm_emit
{
  private:
    std::ostream &os;
    const statemachine &sm;

    std::vector<std::string> transform_bytes(const std::vector<std::string> &data)
    {
        // Transform word constants to low/high:
        std::vector<std::string> ret;
        for(auto &c : data)
        {
            if(c.size() && c[0] == '&')
            {
                ret.push_back('<' + c.substr(1, c.npos));
                ret.push_back('>' + c.substr(1, c.npos));
            }
            else
                ret.push_back(c);
        }
        return ret;
    }
    void print_bytes_n(const std::vector<std::string> &data, size_t n)
    {
        if(!n)
            return;
        os << "\t.byte SM_EMIT_" << n;
        for(size_t i = 0; i < n; i++)
            os << ", " << data[i];
        os << "\n";
    }
    void print_bytes_ret(const std::vector<std::string> &data)
    {
        auto x = transform_bytes(data);
        if(!x.size())
            print_return();
        else
        {
            print_bytes_n(x, x.size() - 1);
            os << "\t.byte SM_ERET, " << x.back() << "\n";
        }
    }
    void print_bytes(const std::vector<std::string> &data)
    {
        auto x = transform_bytes(data);
        print_bytes_n(x, x.size());
    }
    void print_literal(std::string str)
    {
        for(auto &ch : str)
        {
            if(ch >= ' ' && ch < 127 && ch != '\'')
                os << "\t.byte \'" << ch << "\'\n";
            else
                os << "\t.byte " << (ch & 0xFF) << "\n";
        }
    }
    void print_return() { os << "\t.byte SM_RET\n"; }
    void print_call(std::string sub) { os << "\t.byte SMB_" << sub << "\n"; }
    void print_line(const std::vector<statemachine::pcode> &pc, int lnum)
    {
        // os << "\t; " << lnum << "\n";
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
                print_bytes_ret(c.data);
                break;
            case statemachine::pcode::c_call_ext:
            case statemachine::pcode::c_call_table:
                print_call(c.str);
                break;
            case statemachine::pcode::c_return:
                print_return();
                break;
            }
        }
    }

  public:
    asm_emit(std::ostream &os, const statemachine &sm) : os(os), sm(sm) {}
    void print()
    {
        os << sm.name() << ":\t; " << sm.line_num() << "\n";
        for(const auto &line : sm.get_code())
            print_line(line.pc, line.lnum);
        if(!sm.is_complete())
            os << "\t.byte SM_EXIT\n";
        os << "\n";
    }
};
} // namespace

bool syntax::syntax_emit_asm(std::ostream &hdr, std::ostream &out, sm_list &sl)
{
    // Output header
    hdr << "; Syntax state machine - header\n"
           "; -----------------------------\n"
           "; This is a generated file - do not modify\n"
           "\n"
           "; Token Values\n";

    for(auto i : sl.tok.map())
        hdr << "\t.importzp " << i.first << "\n";
    hdr << "\n";
    hdr << "\t.assert\tTOK_END = 0, error, \"TOK_END must be 0\"";

    // Output parser state machine
    out << "; Syntax state machine\n"
           "; --------------------\n"
           "; This is a generated file - do not modify\n"
           "\n";

    // External symbols
    out << "; External symbols\n";
    for(auto i : sl.ext.map())
        out << " .global " << i.first << "\n";

    // State machine symbol IDs
    out << "\n"
           "; State Machine IDs\n";
    int n = 128;
    for(auto i : sl.ext.map())
    {
        i.second = n++;
        out << "SMB_" << i.first << "\t= " << i.second << "\n";
    }
    out << "\nSMB_STATE_START\t= " << sl.ext.next() << "\n\n";

    int ns = sl.ext.next();
    for(auto &sm : sl.sms)
        out << "SMB_" << sm.second->name() << "\t= " << ns++ << "\n";

    // Emit array with addresses
    out << "\n"
           "; Address of State Machine tables\n"
           "\n"
           "SM_TABLE_ADDR:\n";
    for(auto i : sl.ext.map())
        out << "\t.word " << i.first << " - 1\n";
    for(auto &sm : sl.sms)
        out << "\t.word " << sm.second->name() << " - 1\n";
    // Emit state machine tables
    out << "\n"
           "; State machine tables\n";

    for(auto &sm : sl.sms)
    {
        asm_emit a(out, *sm.second);
        a.print();
    }

    return true;
}
