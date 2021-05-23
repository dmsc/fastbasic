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

// Translates the syntax file to a C++ file
// ----------------------------------------

#include "synt-emit-cc.h"
#include "synt-parse.h"
#include "synt-wlist.h"
#include "synt-sm.h"
#include "synt-read.h"
#include "parse.h"

#include <iostream>
#include <string>
#include <vector>

bool p_file(parseState &p, std::ostream &out, std::ostream &hdr)
{
    syntax_parser<statemachine<cc_emit>> pf(p);

    if( !pf.parse_file(p) )
        return false;

    // Sort tokens by index (order in token table)
    std::vector<std::string> sorted_toks(pf.tok.next());
    for(auto i: pf.tok.map())
        sorted_toks[i.second] = i.first;

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
           "class parse;\n"
           "bool parse_start(parse &s);\n"
           "std::string token_name(enum tokens t);\n";

    // Output parser C++ file
    out << "// Syntax state machine\n"
           "// --------------------\n"
           "// This is a generated file - do not modify\n"
           "\n"
           "#include \"basic.h\"\n"
           "#include \"parser.h\"\n"
           "\n"
           "static const char * token_names[" << 1 + pf.tok.next() << "] {\n";
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
    for(auto i: pf.ext.map())
    {
        out << "bool SMB_" << i.first << "(parse &s);\t// " << n << "\n";
        i.second = n++;
    }

    // Emit state machine tables
    for(auto &sm: pf.sm_list)
        out << "static bool SMB_" << sm.second->name() << "(parse &s);\t// " << n++ << "\n";
    // Emit state machine tables
    out << "\n";
    for(auto &sm: pf.sm_list)
        sm.second->print(out);

    out << "\n"
           "// Parsing start function\n"
           "bool parse_start(parse &s)\n"
           "{\n"
           "    return SMB_PARSE_START(s);\n"
           "}\n"
           "\n";
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
