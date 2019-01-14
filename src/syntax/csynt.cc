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

// Translates the syntax file to a C++ file
// ----------------------------------------

#include "synt-emit-cc.h"
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
    // Sort tokens by index (order in token table)
    std::vector<std::string> sorted_toks(tok.next());
    for(auto i: tok.map())
        sorted_toks[i.second] = i.first;

    // Parse EXTERN routines
    wordlist ext(p, "EXTERN", 128);
    if( !ext.parse() )
        p.error("missing EXTERN table");

    // Parse state machines
    std::map<std::string, std::unique_ptr<statemachine<cc_emit>>> sm_list;

    while( !p.eof() )
    {
        auto sm = std::make_unique<statemachine<cc_emit>>(p);
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
    hdr << "// Syntax state machine - header\n"
           "// -----------------------------\n"
           "// This is a generated file - do not modify\n"
           "#pragma once\n"
           "#include <string>\n"
           "\n"
           "enum tokens {\n";
    for(auto i: sorted_toks)
        hdr << "    " << i << ",\n";
    hdr << "    TOK_LAST_TOKEN\n"
           "};\n"
           "\n"
           "std::string token_name(enum tokens t);\n";

    // Output parser C++ file
    out << "// Syntax state machine\n"
           "// --------------------\n"
           "// This is a generated file - do not modify\n"
           "\n"
           "static const char * token_names[" << 1 + tok.next() << "] {\n";
    // Token names
    for(auto i: sorted_toks)
        out << "    \"" << i << "\",\n";
    out << "    \"LAST_TOKEN\"\n"
           "};\n"
           "\n"
           "std::string token_name(enum tokens t)\n"
           "{\n"
           "    return token_names[t];\n"
           "}\n"
           "\n";

    // External functions
    int n = 128;
    for(auto i: ext.map())
    {
        out << "static bool SMB_" << i.first << "(parse &s);\t// " << n << "\n";
        i.second = n++;
    }

    // Emit state machine tables
    for(auto &sm: sm_list)
        out << "static bool SMB_" << sm.second->name() << "(parse &s);\t// " << n++ << "\n";
    // Emit state machine tables
    out << "\n";
    for(auto &sm: sm_list)
        sm.second->print(out);

    return true;
}

int main(int argc, const char **argv)
{
 options opt(argc, argv);
 std::string inp = readInput(opt.defs, opt.input());

 parseState ps(inp.c_str());
 p_file(ps, opt.output(), opt.output_header(".h"));

 return 0;
}
