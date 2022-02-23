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

// synt-sm.h: Parse and write the syntax state machine
#pragma once
#include <iostream>
#include <string>
#include <vector>

namespace syntax
{
class parse_state;
class wordlist;
class symlist;

class statemachine
{
  public:
    // Data to emit into code
    class dcode
    {
      public:
        enum dtype
        {
            // A token
            d_token,
            // A byte
            d_byte,
            // A word
            d_word
        } type;
        std::string val;
    };
    // A parsing code:
    class pcode
    {
      public:
        enum ctype
        {
            // A literal to match, this is simply a list of characters
            c_literal,
            // A sequence of bytes / words to emit on parsing
            c_emit,
            // An emit followed by a return
            c_emit_return,
            // A call to another table
            c_call_table,
            // A call to an external sub
            c_call_ext,
            // Return success
            c_return
        } type;
        // Store a vector of bytes to emit, stored as strings
        // to allow emitting constants
        std::vector<dcode> data;
        // Stores the name for the call or the literal characters
        std::string str;
        // Creates a literal or call:
        pcode(enum ctype t, std::string &s) : type(t), str(s) {}
        // Creates an emit:
        pcode(std::vector<dcode> &s) : type(c_emit), data(s) {}
        // Creates a return:
        pcode(enum ctype t) : type(t) {}
        // Test type
        bool is_emit() const { return type == c_emit; }
        bool is_return() const { return type == c_return; }
    };
    // A line in a syntax table is a sequence of parsing codes:
    class line
    {
      public:
        std::vector<pcode> pc;
        int lnum;
    };

  private:
    parse_state &p;
    bool complete;
    int lnum;               // Line number in input file
    std::string _name;      // Table name
    const wordlist &tok;    // Token list
    const wordlist &ext;    // Externals list
    const symlist &syms;    // Symbols
    std::vector<line> code; // Parsing code lines
    std::string _desc;      // Table description
    // Parse table description
    bool parse_description();
    // Parse a string
    bool parse_str(line &current);
    // Parses one emit byte, token or &word
    bool read_emit_token(std::vector<dcode> &emit);
    // Parses a emit line "{" byte/token, &word, ... "}"
    bool read_emit_line(std::vector<dcode> &emit);
    // Parse one line of the table
    bool parse_line(line &current);

  public:
    statemachine(parse_state &p, std::string name, const wordlist &tok, const wordlist &ext, const symlist &syms)
        : p(p), complete(false), lnum(-1), _name(name), tok(tok), ext(ext), syms(syms)
    {
    }
    std::string name() const { return _name; }
    int has_call(std::string tab) const;
    int is_empty() const;
    void delete_call(std::string tab);
    bool end_call(std::string tab) const;
    const std::vector<line> &get_code() const { return code; };
    int line_num() const { return lnum; }
    bool is_complete() const { return complete; }
    /* Parse a new table */
    bool parse();
    /* Parse extra definitions for a table */
    bool parse_extra();
    // Do a tail-call from one statemachine to another
    bool tail_call(const statemachine &from);
    // Optimize state machine code
    void optimize();
    std::string error_text() const { return _desc; }
};
} // namespace syntax
