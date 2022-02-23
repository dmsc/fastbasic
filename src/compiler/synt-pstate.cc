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

// synt-pstate.cc: Parser state for parsing syntax files
#include "synt-pstate.h"
#include <iostream>

using namespace syntax;

sentry::sentry(parse_state &orig) : p(orig), pos(orig.pos), line(orig.line), col(orig.col)
{
}

bool sentry::operator()(bool consume)
{
    if(!consume)
    {
        p.pos = pos;
        p.line = line;
        p.col = col;
    }
    return consume;
}

std::string sentry::str()
{
    return std::string(p.str + pos, p.pos - pos);
}

void parse_state::reset(const char *new_str, std::string new_fname)
{
    str = new_str;
    pos = 0;
    line = 1;
    col = 1;
    file_name = new_fname;
}

bool parse_state::advance()
{
    if(str[pos])
    {
        if(str[pos] == '\n')
        {
            col = 1;
            line++;
        }
        else
            col++;
        pos++;
    }
    return true;
}

bool parse_state::eof()
{
    return !str[pos];
}

bool parse_state::ch(char c)
{
    return (str[pos] == c) && advance();
}

bool parse_state::ch(char a, char b)
{
    return str[pos] >= a && str[pos] <= b && advance();
}

bool parse_state::ident_ch()
{
    return ch('_') || ch('a', 'z') || ch('A', 'Z') || ch('0', '9');
}

bool parse_state::line_cont()
{
    sentry s(*this);
    if(ch('\\') && ch('\n'))
        return true;
    return s(false);
}

bool parse_state::blank()
{
    return ch(' ') || ch('\t') || line_cont();
}

bool parse_state::space()
{
    while(blank())
        ;
    return true;
}

bool parse_state::eol()
{
    sentry s(*this);
    return s(eof() || ch('\n') || (ch('\r') && ch('\n')));
}

bool parse_state::noteol()
{
    sentry s(*this);
    return s(!eol());
}

bool parse_state::all()
{
    while(noteol())
        advance();
    return true;
}

bool parse_state::comment()
{
    sentry s(*this);
    return s(space() && ((ch('#') && all()) || eol()));
}

bool parse_state::skip_comments()
{
    while(!eof() && comment())
        ; // Skip comments and blank lines
    return true;
}

std::string parse_state::read_ident()
{
    space();
    sentry s(*this);
    while(ident_ch())
        ;
    std::string ret = s.str();
    space();
    return ret;
}

int parse_state::read_number()
{
    space();
    sentry s(*this);

    // Hex numbers start with '$' or '0x'
    if( ch('$') || ( ch('0') && (ch('x') || ch('X')) ) )
    {
        sentry r(*this);
        // Read hex digits
        while( ch('a', 'f') || ch('A', 'F') || ch('0', '9') );
            ;
        auto str = r.str();
        space();
        try {
            return std::stoi(str, nullptr, 16);
        }
        catch(...)
        {
        }
        return -1;
    }
    // Decimal numbers
    while( ch('0', '9') )
        ;
    auto str = s.str();
    space();
    try {
        return std::stoi(str, nullptr, 10);
    }
    catch(...)
    {
    }
    return -1;
}

bool parse_state::end_line()
{
    return space() && (eof() || eol() || comment());
}

bool parse_state::error(std::string err, bool show)
{
    std::cerr << file_name << ": error at " << line << ":" << col << ": " << err << "\n";
    if( show )
    {
        int ocol = col;
        pos -= (col - 1);
        col = 1;
        sentry s(*this);
        all();
        std::cerr << s.str() << "\n";
        std::cerr << std::string(ocol - 1, '-') << "^\n";
    }
    return false;
}
