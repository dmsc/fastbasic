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

// Translates the syntax file to an assembly file for CA65
// -------------------------------------------------------

#include "synt-emit-asm.h"
#include "synt-parse.h"
#include "synt-wlist.h"
#include "synt-sm.h"
#include "synt-read.h"

#include <iostream>
#include <memory>
#include <string>
#include <vector>

bool p_file(parseState &p, std::ostream &out, std::ostream &hdr)
{
    // Parse TOKENS
    wordlist tok(p, "TOKENS", 0);
    if( !tok.parse() )
    {
        p.error("missing TOKENS table");
        return false;
    }

    // Parse EXTERN routines
    wordlist ext(p, "EXTERN", 128);
    if( !ext.parse() )
        p.error("missing EXTERN table");

    // Parse state machines
    std::map<std::string, std::unique_ptr<statemachine<asm_emit>>> sm_list;

    while( !p.eof() )
    {
        auto sm = std::make_unique<statemachine<asm_emit>>(p);
        if( sm->parse() )
        {
            sm_list[sm->name()] = std::move(sm);
        }
        else
        {
            sentry s(p);
            p.all();
            p.error("invalid input '" + s.str() + "'");
        }
    }

    std::cerr << "syntax: " << tok.next() << " possible tokens.\n";
    std::cerr << "syntax: " << (ext.next() + sm_list.size() - 128)
              << " tables in the parser-table.\n";

    // Output header
    hdr << "; Syntax state machine - header\n"
           "; -----------------------------\n"
           "; This is a generated file - do not modify\n"
           "\n"
           "; Token Values\n";

    for(auto i: tok.map())
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
    for(auto i: ext.map())
        out << " .global " << i.first << "\n";

    // State machine symbol IDs
    out << "\n"
           "; State Machine IDs\n";
    int n = 128;
    for(auto i: ext.map())
    {
        i.second = n++;
        out << "SMB_" << i.first << "\t= " << i.second << "\n";
    }
    out << "\nSMB_STATE_START\t= " << ext.next() << "\n\n";

    int ns = ext.next();
    for(auto &sm: sm_list)
        out << "SMB_" << sm.second->name() << "\t= " << ns++ << "\n";

    // Emit array with addresses
    out << "\n"
           "; Address of State Machine tables\n"
           "\n"
           "SM_TABLE_ADDR:\n";
    for(auto i: ext.map())
        out << "\t.word " << i.first << " - 1\n";
    for(auto &sm: sm_list)
        out << "\t.word " << sm.second->name() << " - 1\n";
    // Emit state machine tables
    out << "\n"
           "; State machine tables\n";
    for(auto &sm: sm_list)
        sm.second->print(out);

    return true;
}

int main(int argc, const char **argv)
{
 options opt(argc, argv);
 std::string inp = readInput(opt.defs, opt.input());

 parseState ps(inp.c_str());
 p_file(ps, opt.output(), opt.output_header(".inc"));

 return 0;
}
