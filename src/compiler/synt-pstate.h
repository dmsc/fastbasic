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

// synt-pstate.h: Parser state for parsing syntax files
#pragma once
#include <string>

namespace syntax
{
class parse_state;

class sentry
{
  private:
    parse_state &p;
    unsigned pos, line, col;

  public:
    sentry(parse_state &orig);
    bool operator()(bool consume);
    std::string str();
};

class parse_state
{
  private:
    const char *str;
    unsigned pos, line, col;
    std::string file_name;
    friend class sentry;

  public:
    // Constructor
    parse_state() { reset("", std::string()); }
    // Restart parsing with give data and name
    void reset(const char *new_str, std::string new_fname);
    // Advance parser (consume one character)
    bool advance();
    // Parser predicates
    bool eof();              // At EOF?
    bool peek(char c);       // Is character c, but don't consume.
    bool ch(char c);         // Is character c?
    bool ch(char a, char b); // Is character between a and b?
    bool ident_ch();         // Is valid identifier character?
    bool line_cont();        // Is line continuation?
    bool blank();            // Is space/blank ?
    bool eol();              // Is end-of-line?
    bool space();            // Consume 0 or more spaces
    bool noteol();           // Not at end of line
    bool all();              // Consume rest of line until EOL
    bool comment();          // Consume a comment (if found)
    bool end_line();         // Check for end of line or a comment
    bool skip_comments();    // Skip comments and blank lines
    // Reads an identifier, skips spaces before and after
    std::string read_ident();
    // Reads a positive number, returns -1 if not possible
    int read_number();
    // Reads one character
    std::string read_char();
    // Show parsing error at this position
    bool error(std::string err, bool show = true);
    int get_line() const { return line; }
};
} // namespace syntax
