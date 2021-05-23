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

// parse.h: Parse a syntax file
#include <memory>

template<class SM>
class syntax_parser
{
    private:

    public:
        wordlist tok;
        wordlist ext;
        std::map<std::string, std::unique_ptr<SM>> sm_list;

        syntax_parser(parseState &p):
            tok(p, "TOKENS", 0),
            ext(p, "EXTERN", 128)
        {
        }

        bool parse_file(parseState &p)
        {
            // Parse TOKENS
            if( !tok.parse() )
            {
                p.error("missing TOKENS table");
                return false;
            }

            // Parse EXTERN routines
            if( !ext.parse() )
            {
                p.error("missing EXTERN table");
                return false;
            }

            // Parse state machines

            while( !p.eof() )
            {
                auto sm = std::make_unique<SM>(p);
                if( sm->parse() )
                {
                    sm_list[sm->name()] = std::move(sm);
                }
                else
                {
                    sentry s(p);
                    p.all();
                    p.error("invalid input '" + s.str() + "'");
                    return false;
                }
            }

            std::cerr << "syntax: " << tok.next() << " possible tokens.\n";
            std::cerr << "syntax: " << (ext.next() + sm_list.size() - 128)
                      << " tables in the parser-table.\n";

            return true;
        }

};
