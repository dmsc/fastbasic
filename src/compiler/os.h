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

// os.h: Host OS functions
#pragma once

#include <string>
#include <vector>

namespace os
{
// Returns the current compiler search path for the given base
std::vector<std::string> get_search_path(const std::string &filename);
// Locates a file or folder in the compiler data and
// returns the path
std::string compiler_path(const std::string &filename);
// Appends a file name to a path
std::string full_path(const std::string &path, const std::string &filename);
// Search a file in a list of paths
std::string search_path(const std::vector<std::string> &paths,
                        const std::string &filename);
// Returns the file name from a full path
std::string file_name(const std::string &path);
// Returns the directory name from a full path
std::string dir_name(const std::string &path);
// Returns true if the path is an absolute path
bool path_absolute(const std::string &path);
// Changes the filename "extension" to given one.
std::string add_extension(std::string name, std::string ext);
// Gets filename extension, normalized to lower-case.
// NOTE: this only works on ASCII characters - it is expected that standard
//        file extensions are ASCII only (like "asm" and "bas").
std::string get_extension_lower(std::string name);
// Execute external program, waiting for the result
int prog_exec(std::string exe, std::vector<std::string> &args);
// OS specific initializations
void init(const std::string &prog);
// Remove a file
void remove_file(const std::string &path);

} // namespace os
