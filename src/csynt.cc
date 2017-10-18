/*
 * FastBasic - Fast basic interpreter for the Atari 8-bit computers
 * Copyright (C) 2017 Daniel Serpell
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

bool p_file(parseState &p, std::ostream &out)
{
    // Output header
    out << "// Syntax state machine\n\n";

    while(1)
    {
        wordlist tok(p, "TOKENS", 1);
        if( !tok.parse() )
            break;
        out << "static const char * TOKENS[" << 1 + tok.next() << "] {\n";
        std::vector<std::string> sorted_toks(tok.next());
        for(auto i: tok.map())
            sorted_toks[i.second] = i.first;
        for(auto i: sorted_toks)
            out << "    \"" << i << "\",\n";
        out << "\t\"LAST_TOKEN\"\n};\n";
        std::cerr << "syntax: " << tok.next() << " possible tokens.\n";
    }

    wordlist ext(p, "EXTERN", 128);
    if( ext.parse() )
    {
        int n = 128;
        for(auto i: ext.map())
            out << "extern bool SMB_" << i.first << "(parse &s);\n";
        for(auto i: ext.map())
        {
            i.second = n++;
        }
    }

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
    // Emit labels table
    int ns = ext.next();
    for(auto &sm: sm_list)
        out << "static bool SMB_" << sm.second->name() << "(parse &s);\t// " << ns++ << "\n";
    // Emit state machine tables
    out << "\n";
    for(auto &sm: sm_list)
        sm.second->print(out);

    std::cerr << "syntax: " << (ns-128) << " tables in the parser-table.\n";
    return true;
}

int main(int argc, const char **argv)
{
 options opt(argc, argv);
 std::string inp = readInput(opt.defs, opt.input());

 parseState ps(inp.c_str());
 p_file(ps, opt.output());

 return 0;
}
