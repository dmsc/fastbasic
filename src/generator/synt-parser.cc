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

// synt-parser.cc: Parse a syntax file
#include "synt-parser.h"
#include "synt-pstate.h"
#include <iostream>

using namespace syntax;

syntax_parser::syntax_parser(parse_state &p)
    : p(p), tok(p, "TOKENS", 0), ext(p, "EXTERN", 128)
{
}

bool syntax_parser::parse_sm_name(std::string &name)
{
    name = p.read_ident();
    if(name.empty())
        p.error("Table name must start in first column of file");
    else if(p.ch(':'))
        return true;
    else
        p.error("Table name must end with colon");
    return false;
}

bool syntax_parser::parse_file()
{
    // Parse TOKENS
    if(!tok.parse())
    {
        p.error("missing TOKENS table");
        return false;
    }

    // Parse EXTERN routines
    if(!ext.parse())
    {
        p.error("missing EXTERN table");
        return false;
    }

    // Parse state machines
    while(1)
    {
        // Get state machine name:
        p.skip_comments();
        if(p.eof())
            break;

        std::string name;
        if(!parse_sm_name(name))
        {
            p.error("invalid table name '" + name + "'");
            return false;
        }

        // Check if we already have this state-machine
        auto smi = sm_list.find(name);
        if(smi != sm_list.end())
        {
            if(!smi->second->parse_extra())
                return false;
        }
        else
        {
            auto sm = std::make_unique<statemachine>(p, name);
            if(sm->parse())
            {
                sm_list[name] = std::move(sm);
            }
            else
            {
                p.error("invalid input");
                return false;
            }
        }
    }

    return true;
}

void syntax_parser::show_summary() const
{
    std::cerr << "syntax: " << tok.next() << " possible tokens.\n";
    std::cerr << "syntax: " << (ext.next() + sm_list.size() - 128)
              << " tables in the parser-table.\n";
}
