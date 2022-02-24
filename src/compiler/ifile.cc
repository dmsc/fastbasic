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

// ifile.cc: Opens included file

#include "ifile.h"
#include <fstream>

static std::string get_path(std::string fname)
{
    // Get's path to file. This understands either '/' or '\' as path
    // separators, to be compatible between Unix and Windows.
    auto p = fname.find_last_of("/\\");
    if(p != fname.npos)
        return fname.substr(0, p);
    else
        return std::string();
}

std::unique_ptr<std::istream> open_include_file(std::string current_file,
                                                std::string fname)
{
    auto f = std::make_unique<std::ifstream>();

    // Get path of current file
    std::string path = get_path(current_file);

    if(!path.empty())
        path = path + "/" + fname;
    else
        path = fname;

    // Tries to open
    f->open(path, std::ios::binary);
    if(f->is_open())
        return f;

    // Try again without path
    f->open(fname, std::ios::binary);
    if(f->is_open())
        return f;

    f.reset();
    return f;
}
