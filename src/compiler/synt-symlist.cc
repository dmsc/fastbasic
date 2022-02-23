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

// synt-symlist.cc: Parse a list of symbols
#include "synt-symlist.h"
#include "synt-pstate.h"

using namespace syntax;

bool symlist::parse(parse_state &p)
{
    p.skip_comments();
    sentry s(p);

    while(p.end_line())
        ;
    if(!p.ch('{'))
        return false;
    // Read pairs " name = value ":
    while(1)
    {
        p.skip_comments();
        p.space();

        if(p.ch('}'))
            break;

        auto sym = p.read_ident();
        if(sym.empty())
        {
            return p.error("missing identifier");
        }
        else
        {
            if(list.end() != list.find(sym))
                return p.error("symbol already exists '" + sym + "'");
        }
        p.space();
        if( !p.ch('=') )
            return p.error("expected '=' after symbol name");
        p.space();
        auto val = p.read_number();
        if( val == -1 )
        {
            auto s = p.read_ident();
            if( s == "import" )
                val = sym_import;
            else if( s == "importzp" )
                val = sym_importzp;
            else
                return p.error("invalid symbol value");
        }
        list[sym] = val;

        if(!p.end_line() && !(p.skip_comments() && p.ch(',')))
        {
            return p.error("expected a ',' or newline");
        }
    }
    return true;
}
