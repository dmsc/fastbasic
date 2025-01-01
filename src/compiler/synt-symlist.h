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

// synt-symlist.h: Parse a list of symbols
#pragma once
#include <map>
#include <string>

namespace syntax
{
class parse_state;

class symlist
{
  private:
    std::map<std::string, int> list;

  public:
    static const int sym_import = 1 << 24;
    static const int sym_importzp = 2 << 24;
    // Constructor, with a parsing state, the wordlist name and the starting ID
    symlist() {}
    // Access map from names to values.
    const std::map<std::string, int> &map() const { return list; }
    // Parse from parse_state
    bool parse(parse_state &p);
};
} // namespace syntax
