/*
 * FastBasic - Fast basic interpreter for the Atari 8-bit computers
 * Copyright (C) 2017,2018 Daniel Serpell
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

#include <iostream>
#include <string>
#include <map>

class wordlist {
    private:
        parseState &p;
        int n;
        const char *name;
        std::map<std::string, int> list;
        std::string read_ident()
        {
            sentry s(p);
            while(p.ident_ch());
            std::string ret = s.str();
            p.space();
            return ret;
        }
        bool end_line()
        {
            return p.space() && (p.eof() || p.eol() || p.comment());
        }
        bool skip_comments()
        {
            while(!p.eof() && (p.blank() || p.comment())); // Skip comments and blank lines
            return true;
        }
    public:
        wordlist(parseState &p, const char *name, int start): p(p), n(start), name(name) {}
        int next() const { return n; }
        const std::map<std::string, int> &map() const { return list; }
        bool parse()
        {
            skip_comments();
            sentry s(p);
            std::string tok = read_ident();
            if( !s(tok == name && skip_comments() && p.ch('{')) )
                return false;
            // Read all tokens
            while(1)
            {
                skip_comments();
                sentry s1(p);
                tok = read_ident();
                if( tok.empty() )
                {
                    p.error("not a word in '" + s1.str() + "'");
                    p.all();
                }
                else
                {
                    if( list.end() != list.find(tok) )
                        p.error("word already exists '" + tok + "'");
                    else
                        list[tok] = n++;
                }
                sentry s2(p);
                if( s2( skip_comments() && p.ch('}') ) )
                    break;
                if( s2( skip_comments() && p.ch(',') ) )
                    continue;
                if( s2( end_line() && skip_comments() ) )
                    continue;

                p.error("expected a ',' or newline");
            }
            return true;
        }
};
