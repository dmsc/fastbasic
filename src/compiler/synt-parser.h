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

// synt-parser.h: Parse a syntax file
#pragma once
#include "synt-sm-list.h"

namespace syntax
{
class parse_state;

class syntax_parser
{
  private:
    parse_state &p;
    sm_list &sl;
    bool parse_sm_name(const std::string &name);

  public:
    // Constructor, from a parser state
    syntax_parser(parse_state &p, sm_list &sl);
    // Parse one file
    bool parse_file();
    // Show final summary of parser files
    void show_summary() const;
};
} // namespace syntax
