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

// os.h: Host OS functions
#pragma once

#include <string>
#include <vector>

namespace os
{
    // Appends a file name to a path
    std::string full_path(const std::string &path, const std::string &filename);
    // Returns the file name from a full path
    std::string file_name(const std::string &path);
    // Returns the directory name from a full path
    std::string dir_name(const std::string &path);
    // Returns true if the path is an absolute path
    bool path_absolute(const std::string &path);
    // Changes the filename "extension" to given one.
    std::string add_extension(std::string name, std::string ext);
    // Execute external program, waiting for the result
    int prog_exec(std::string exe, std::vector<std::string> &args);

}
