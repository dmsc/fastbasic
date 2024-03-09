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

// target.h: read target definitions
#pragma once
#include "synt-sm-list.h"
#include <memory>
#include <string>
#include <vector>

namespace syntax
{
class sm_list;
}

class target
{
  private:
    syntax::sm_list s;
    std::string lib_name;
    std::string cfg_name;
    std::string bin_extension;
    std::vector<std::string> ca65_args_;

  public:
    target();
    void load(std::string target_folder, std::string syntax_folder, std::string fname);
    const syntax::sm_list &sl() const { return s; }
    std::string lib() const { return lib_name; }
    std::string cfg() const { return cfg_name; }
    std::string bin_ext() const { return bin_extension; }
    const std::vector<std::string> &ca65_args() const { return ca65_args_; }
};
