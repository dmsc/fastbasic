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
        parseState &p;
        bool parse_sm_name(std::string &name)
        {
            sentry s(p);
            while(p.ident_ch());
            name = s.str();
            return s( p.ch(':') );
        }
    public:
        wordlist tok;
        wordlist ext;
        std::map<std::string, std::unique_ptr<SM>> sm_list;

        syntax_parser(parseState &p):
            p(p),
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

            while(1)
            {
                // Get state machine name:
                while(!p.eof() && p.comment()); // Skip comments and blank lines
                if( p.eof() )
                    break;

                std::string name;
                if( !parse_sm_name(name) )
                {
                    p.error("invalid state-machine name '" + name + "'");
                    return false;
                }

                // Check if we already have this state-machine
                auto smi = sm_list.find(name);
                if(smi != sm_list.end())
                {
                    if( !smi->second->parse_extra() )
                        return false;
                }
                else
                {
                    auto sm = std::make_unique<SM>(p, name);
                    if( sm->parse() )
                    {
                        sm_list[name] = std::move(sm);
                    }
                    else
                    {
                        sentry s(p);
                        p.all();
                        p.error("invalid input '" + s.str() + "'");
                        return false;
                    }
                }
            }

            return true;
        }

        void show_summary()
        {
            std::cerr << "syntax: " << tok.next() << " possible tokens.\n";
            std::cerr << "syntax: " << (ext.next() + sm_list.size() - 128)
                      << " tables in the parser-table.\n";
        }
};
