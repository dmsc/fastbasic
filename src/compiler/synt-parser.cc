/*
 * FastBasic - Fast basic interpreter for the Atari 8-bit computers
 * Copyright (C) 2017-2024 Daniel Serpell
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

syntax_parser::syntax_parser(parse_state &p, sm_list &sl) : p(p), sl(sl) {}

bool syntax_parser::parse_sm_name(const std::string &name)
{
    if(name.empty())
        return p.error("Table name must start in first column of file");
    else if(p.ch(':'))
        return true;
    else
        return p.error("Table name must end with colon");
}

bool syntax_parser::parse_file()
{
    // Parse syntax file
    while(1)
    {
        // Get section machine name:
        p.skip_comments();
        if(p.eof())
            break;

        std::string name = p.read_ident();
        // Check if it is a syntax table or a word list
        if(name == "TOKENS")
        {
            if(!sl.tok.parse(p))
                return p.error("error parsing TOKENS table", false);
        }
        else if(name == "EXTERN")
        {
            if(!sl.ext.parse(p))
                return p.error("error parsing EXTERN table", false);
        }
        else if(name == "SYMBOLS")
        {
            if(!sl.syms.parse(p))
                return p.error("error parsing SYMBOLS table", false);
        }
        else if(!parse_sm_name(name))
        {
            return p.error("invalid table '" + name + "'", false);
        }
        else
        {
            // Check if we already have this state-machine
            auto smi = sl.sms.find(name);
            if(smi != sl.sms.end())
            {
                if(!smi->second->parse_extra())
                    return false;
            }
            else
            {
                auto sm =
                    std::make_unique<statemachine>(p, name, sl.tok, sl.ext, sl.syms);
                if(sm->parse())
                {
                    sl.sms[name] = std::move(sm);
                }
                else
                {
                    return p.error("invalid input");
                }
            }
        }
    }

    return true;
}

void syntax_parser::show_summary() const
{
    std::cerr << "syntax: " << sl.tok.next() << " possible tokens.\n";
    std::cerr << "syntax: " << (sl.ext.next() + sl.sms.size() - 128)
              << " tables in the parser-table.\n";
}
