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

// target.cc: read target definitions
#include "target.h"
#include "os.h"
#include "synt-optimize.h"
#include "synt-parser.h"
#include "synt-preproc.h"
#include "synt-pstate.h"
#include "synt-sm-list.h"
#include <fstream>
#include <iostream>
#include <vector>

class target_file
{
  public:
    std::string install_folder;
    std::vector<std::string> slist;
    std::vector<std::string> ca65_args;
    std::string lib_name;
    std::string cfg_name;
    std::string bin_ext;
    target_file(std::string install_folder) : install_folder(install_folder) {}
    void read_file(std::string fname);
};

static std::string sub(std::string inp, size_t s, size_t e)
{
    if(s >= inp.size() || s >= e)
        return std::string();
    else if(e >= inp.size())
        return inp.substr(s);
    else
        return inp.substr(s, e - s);
}

void target_file::read_file(std::string fname)
{
    if(!fname.size())
        fname = "default";

    // Add extension if missing
    if(fname.find('.') == fname.npos)
        fname = os::add_extension(fname, ".tgt");

    if(!os::path_absolute(fname))
        fname = os::full_path(install_folder, fname);

    std::ifstream f;
    f.open(fname);
    if(!f.is_open())
        throw std::runtime_error("Can't open target definition file '" + fname + "'");

    // Read:
    std::string line;
    while(std::getline(f, line).good())
    {
        // Parse line:
        auto s = line.find_first_not_of(" \t\r\n");
        // Skip blank lines and comments
        if(s != line.npos && line[s] != '#')
        {
            // split line into "key" and "args":
            auto e = line.find_first_of(" \t\r\n", s);
            auto a = line.find_first_not_of(" \t\r\n", e);
            auto key = sub(line, s, e);
            auto args = sub(line, a, line.npos);
            if(key == "include")
            {
                read_file(args);
            }
            else if(key == "library")
            {
                lib_name = args;
            }
            else if(key == "config")
            {
                cfg_name = args;
            }
            else if(key == "extension")
            {
                bin_ext = args;
            }
            else if(key == "ca65")
            {
                size_t i = 0;
                while(i < args.size())
                {
                    auto e = args.find_first_of(" \t\r\n", i);
                    ca65_args.push_back(sub(args, i, e));
                    i = args.find_first_not_of(" \t\r\n", e);
                }
            }
            else if(key == "syntax")
            {
                size_t i = 0;
                while(i < args.size())
                {
                    auto e = args.find_first_of(" \t\r\n", i);
                    slist.push_back(sub(args, i, e));
                    i = args.find_first_not_of(" \t\r\n", e);
                }
            }
            else
                throw std::runtime_error("Bad key '" + key + "' in target file '" +
                                         fname + "'");
        }
    }
}

target::target() {}

void target::load(std::string target_folder, std::string syntax_folder, std::string fname)
{
    // Read target file
    target_file f(target_folder);
    f.read_file(fname);
    lib_name = f.lib_name;
    cfg_name = f.cfg_name;
    bin_extension = f.bin_ext;
    ca65_args_ = f.ca65_args;
    // Process all syntax files:
    syntax::preproc pre;
    syntax::parse_state p;
    syntax::syntax_parser pf(p, s);
    for(auto &name : f.slist)
    {
        std::ifstream ifile;
        ifile.open(os::full_path(syntax_folder, name));
        if(!ifile.is_open())
            throw std::runtime_error("can't open syntax file: '" + name + "'");
        auto data = pre.read_input(ifile);
        p.reset(data.c_str(), name);
        if(!pf.parse_file())
            throw std::runtime_error("error parsing syntax file: '" + name + "'");
    }
    // Optimize
    syntax_optimize(s, false);
}
