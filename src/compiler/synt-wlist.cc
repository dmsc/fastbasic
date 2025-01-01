/*
 * FastBasic - Fast basic interpreter for the Atari 8-bit computers
 * Copyright (C) 2017-2025 Daniel Serpell
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

// synt-wlist.cc: Parse the syntax word lists
#include "synt-wlist.h"
#include "synt-pstate.h"

using namespace syntax;

bool wordlist::parse(parse_state &p)
{
    p.skip_comments();
    sentry s(p);

    while(p.end_line())
        ;
    if(!p.ch('{'))
        return false;
    // Read all tokens
    while(1)
    {
        p.skip_comments();
        p.space();

        if(p.ch('}'))
            break;

        auto tok = p.read_ident();
        if(tok.empty())
        {
            p.error("missing identifier");
            return false;
        }
        else
        {
            if(list.end() != list.find(tok))
                p.error("word already exists '" + tok + "'");
            else
                list[tok] = n++;
        }

        if(!p.end_line() && !(p.skip_comments() && p.ch(',')))
        {
            p.error("expected a ',' or newline");
            return false;
        }
    }
    return true;
}
