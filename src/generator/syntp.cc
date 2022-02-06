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

// syntax-processor: translates the syntax file to C++ or ASM files
#include "synt-emit-asm.h"
#include "synt-emit-cc.h"
#include "synt-optimize.h"
#include "synt-parser.h"
#include "synt-preproc.h"
#include "synt-pstate.h"
#include <fstream>
#include <iostream>
#include <vector>

using namespace syntax;

static std::string prog_name;

static void usage()
{
    std::cerr << "Usage: " << prog_name
              << " [-options] [input_files...]\n"
                 "\n"
                 "Options:\n"
                 "  -a       Generate assembly file with parsing bytecode.\n"
                 "  -c       Generate C++ file with parsing source.\n"
                 "  -h       Show this help.\n"
                 "  -H       specify output header file extension.\n"
                 "  -D name  Define symbol 'name' to use in syntax.\n"
                 "  -o file  specify output file name 'file'.\n";
    std::exit(0);
}

static void error(std::string msg)
{
    std::cerr << prog_name << ": error, " << msg << ", use '-h' for help.\n";
    std::exit(1);
}

static std::ostream &open_output(std::string name, std::ofstream &file)
{
    if(name.empty() || name == "-")
        return std::cout;

    file.open(name);
    if(!file.is_open())
        error("can't open output file: '" + name + "'");

    return file;
}

static std::ostream &open_output_header(std::string name, std::string ext,
                                        std::ofstream &file)
{
    if(name.empty() || name == "-")
        return std::cout;

    // Replace extension
    auto n = name.find_last_of("./");
    if(n != name.npos && name[n] == '/')
        n = name.npos; // no extension
    name = name.substr(0, n) + ext;

    file.open(name);
    if(!file.is_open())
        error("can't open output header file: '" + name + "'");

    return file;
}

static std::istream &open_input(std::string name, std::ifstream &file)
{
    if(name.empty() || name == "-")
        return std::cin;

    file.open(name);
    if(!file.is_open())
        error("can't open input file: '" + name + "'");

    return file;
}

int main(int argc, const char **argv)
{
    std::string header_ext;
    std::string output_name;
    std::vector<std::string> input_names;
    enum
    {
        gen_none,
        gen_cpp,
        gen_asm
    } opt_generate = gen_none;

    prog_name = argv[0];

    preproc pre;

    // Process options:
    for(int i = 1; i < argc; i++)
    {
        std::string x(argv[i]);
        if(x.size() > 1 && x[0] == '-')
        {
            if(x[1] == 'D')
            {
                if(x.size() > 2)
                    pre.add_def(x.substr(2));
                else if(i + 1 < argc)
                    pre.add_def(argv[++i]);
                else
                    error("option '-D' needs an argument");
            }
            else if(x[1] == 'o')
            {
                if(!output_name.empty())
                    error("option '-o' multiple times");
                else if(x.size() > 2)
                    output_name = x.substr(2);
                else if(i + 1 < argc)
                    output_name = argv[++i];
                else
                    error("option '-o' needs argument");
            }
            else if(x[1] == 'a')
            {
                if(x.size() > 2 || opt_generate != gen_none)
                    error("use option '-a' alone");
                else
                {
                    opt_generate = gen_asm;
                    if(header_ext.empty())
                        header_ext = ".inc";
                }
            }
            else if(x[1] == 'c')
            {
                if(x.size() > 2 || opt_generate != gen_none)
                    error("use option '-c' alone");
                else
                {
                    opt_generate = gen_cpp;
                    if(header_ext.empty())
                        header_ext = ".h";
                }
            }
            else if(x[1] == 'H')
            {
                if(x.size() > 2)
                    header_ext = x.substr(2);
                else if(i + 1 < argc)
                    header_ext = argv[++i];
                else
                    error("option '-H' needs argument");
            }
            else if(x[1] == 'h')
                usage();
            else
                error("invalid option '" + x + "'");
        }
        else
            input_names.push_back(x);
    }
    if(opt_generate == gen_none)
        error("use ar least one generator option");

    // If no input files, add an empty name for standard input
    if(!input_names.size())
        input_names.push_back(std::string());

    // Open output file:
    std::ofstream ofile, hfile;
    auto &ostrm = open_output(output_name, ofile);
    auto &hstrm = open_output_header(output_name, header_ext, hfile);

    // Process all input files:
    parse_state p;
    syntax_parser pf(p);
    for(auto &name : input_names)
    {
        std::ifstream ifile;
        auto &inp = open_input(name, ifile);
        auto data = pre.read_input(inp);

        p.reset(data.c_str(), name);
        if(!pf.parse_file())
            return 1;
    }
    // Show parsing summary
    pf.show_summary();

    // Optimize
    syntax_optimize(pf.sm_list);

    // And generate code
    if(opt_generate == gen_cpp)
    {
        syntax_emit_cc(hstrm, ostrm, pf.sm_list, pf.tok, pf.ext);
    }
    else if(opt_generate == gen_asm)
    {
        syntax_emit_asm(hstrm, ostrm, pf.sm_list, pf.tok, pf.ext);
    }

    return 0;
}
