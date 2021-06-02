/*
 * FastBasic - Fast basic interpreter for the Atari 8-bit computers
 * Copyright (C) 2017-2021 Daniel Serpell
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

// main.cc: Main compiler file

#include <iostream>
#include <vector>
#include "compile.h"

static int show_version()
{
    std::cerr << "FastBasic " VERSION " - (c) 2021 dmsc\n";
    return 0;
}

static int show_help()
{
    show_version();
    std::cerr << "Usage: fastbasic [options] <input.bas> <output.asm>\n"
                 "\n"
                 "Options:\n"
                 " -d\t\tenable parser debug options (only useful to debug parser)\n"
                 " -n\t\tdon't run the optimizer, produces same code as 6502 version\n"
                 " -prof\t\tshow token usage statistics\n"
                 " -s=<name>\tplace code into given segment\n"
                 " -l\t\tproduce a listing of the unabbreviated parsed source\n"
                 " -v\t\tshow version and exit\n"
                 " -h\t\tshow this help\n";
    return 0;
}

static int show_error(std::string msg)
{
    std::cerr << "fastbasic: " << msg << "\n";
    return 1;
}

int main(int argc, char **argv)
{
    std::vector<std::string> args(argv+1, argv+argc);
    std::string iname, oname;
    compiler comp;

    // Process command line options
    for(auto &arg: args)
    {
        if( arg == "-d" )
            comp.do_debug = true;
        else if( arg == "-n" )
            comp.optimize = false;
        else if( arg == "-prof" )
            comp.show_stats = true;
        else if( arg == "-v" )
            return show_version();
        else if( arg == "-l" )
            comp.show_text = true;
        else if( arg == "-h" )
            return show_help();
        else if( arg.empty() )
            return show_error("invalid argument, try -h for help");
        else if( arg.rfind("-s=", 0) == 0 )
        {
            auto seg = arg.substr(3);
            if( !seg.size() || (seg.find('"') != std::string::npos) )
                return show_error("invalid segment name");
            comp.segname = seg;
        }
        else if( arg[0] == '-' )
            return show_error("invalid option '" + arg + "', try -h for help");
        else if( iname.empty() )
        {
            iname = arg;
        }
        else if( oname.empty() )
        {
            oname = arg;
        }
        else
            return show_error("too many arguments, try -h for help");
    }
    if( iname.empty() )
        return show_error("missing input file name");

    if( oname.empty() )
        return show_error("missing output file name");

    return comp.compile_file(iname, oname);
}
