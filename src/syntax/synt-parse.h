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

// synt-parse.cc: Parser for basic syntax file

#include <iostream>
#include <string>

struct parseState;
class sentry
{
    private:
        parseState &p;
        unsigned pos, line, col;
    public:
        sentry(parseState &orig);
        bool operator()(bool consume);
        std::string str();
};

struct parseState
{
    const char *str;
    unsigned pos, line, col;
    parseState(const char *str): str(str), pos(0), line(1), col(1)  { }
    bool advance()
    {
        if( str[pos] )
        {
            if( str[pos] == '\n' )
            {
                col = 1;
                line++;
            }
            else
                col++;
            pos ++;
        }
        return true;
    }
    bool eof()
    {
        return !str[pos];
    }
    bool ch(char c)
    {
        return (str[pos] == c) && advance();
    }
    bool ch(char a, char b)
    {
        return str[pos] >= a && str[pos] <= b && advance();
    }
    bool ident_ch()
    {
        return ch('_') || ch('a','z') || ch('A','Z') || ch('0','9');
    }
    bool line_cont()
    {
        sentry s(*this);
        if( ch('\\') && ch('\n') )
            return true;
        return s(false);
    }
    bool blank()
    {
        return ch(' ') || ch('\t') || line_cont();
    }
    bool space()
    {
        while(blank());
        return true;
    }
    bool eol()
    {
        sentry s(*this);
        return s( space() && (eof() || ch('\n') || (ch('\r') && ch('\n'))) );
    }
    bool noteol()
    {
        sentry s(*this);
        return s(!eol());
    }
    bool all()
    {
        while( noteol() )
            advance();
        return true;
    }
    bool comment()
    {
        sentry s(*this);
        return s(space() && ( (ch('#') && all()) || eol()));
    }
    bool error(std::string err)
    {
        std::cerr << "parse: error at " << line << ":" << col << ": " << err << "\n";
        return !all();
    }
};

sentry::sentry(parseState &orig): p(orig), pos(orig.pos), line(orig.line), col(orig.col) { }
bool sentry::operator()(bool consume) {
    if( !consume ) { p.pos = pos; p.line = line; p.col = col; }
    return consume;
}
std::string sentry::str()
{
    return std::string(p.str+pos, p.pos-pos);
}
