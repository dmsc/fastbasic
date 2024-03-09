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

// synt-sm-list.h: List of parsing tables, tokens and externals
#pragma once
#include "synt-sm.h"
#include "synt-symlist.h"
#include "synt-wlist.h"
#include <map>
#include <memory>

namespace syntax
{
class wordlist;
// List of syntax tables
class sm_list
{
  public:
    std::map<std::string, std::unique_ptr<statemachine>> sms;
    wordlist tok;
    wordlist ext;
    symlist syms;
    sm_list() : tok(0), ext(128) {}
};
} // namespace syntax
