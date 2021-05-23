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

// Translates the syntax file to an assembly file for CA65
// -------------------------------------------------------

#include "synt-emit-asm.h"
#include "synt-parse.h"
#include "synt-wlist.h"
#include "synt-sm.h"
#include "synt-read.h"
#include "parse.h"

#include <iostream>
#include <string>
#include <vector>

bool p_file(options &opt, std::ostream &out, std::ostream &hdr)
{
    parseState p;
    syntax_parser<statemachine<asm_emit>> pf(p);

    while(opt.next_input())
    {
        auto inp = opt.input();
        p.reset(inp.first.c_str(), inp.second);
        if( !pf.parse_file(p) )
            return false;
    }
    pf.show_summary();

    // Output header
    hdr << "; Syntax state machine - header\n"
           "; -----------------------------\n"
           "; This is a generated file - do not modify\n"
           "\n"
           "; Token Values\n";

    for(auto i: pf.tok.map())
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
    for(auto i: pf.ext.map())
        out << " .global " << i.first << "\n";

    // State machine symbol IDs
    out << "\n"
           "; State Machine IDs\n";
    int n = 128;
    for(auto i: pf.ext.map())
    {
        i.second = n++;
        out << "SMB_" << i.first << "\t= " << i.second << "\n";
    }
    out << "\nSMB_STATE_START\t= " << pf.ext.next() << "\n\n";

    int ns = pf.ext.next();
    for(auto &sm: pf.sm_list)
        out << "SMB_" << sm.second->name() << "\t= " << ns++ << "\n";

    // Emit array with addresses
    out << "\n"
           "; Address of State Machine tables\n"
           "\n"
           "SM_TABLE_ADDR:\n";
    for(auto i: pf.ext.map())
        out << "\t.word " << i.first << " - 1\n";
    for(auto &sm: pf.sm_list)
        out << "\t.word " << sm.second->name() << " - 1\n";
    // Emit state machine tables
    out << "\n"
           "; State machine tables\n";
    for(auto &sm: pf.sm_list)
        sm.second->print(out);

    return true;
}

int main(int argc, const char **argv)
{
 options opt(argc, argv);
 return !p_file(opt, opt.output(), opt.output_header(".inc"));
}
