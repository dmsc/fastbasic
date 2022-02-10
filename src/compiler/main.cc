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
#include <tuple>
#include "compile.h"
#include "os.h"
#include "target.h"

static int show_version()
{
    std::cerr << "FastBasic " VERSION " - (c) 2021 dmsc\n";
    return 0;
}

static int show_help()
{
    show_version();
    std::cerr << "Usage: fastbasic [options] <input.bas> [<file.asm>...]\n"
                 "\n"
                 "Options:\n"
                 " -d\t\tenable parser debug options (only useful to debug parser)\n"
                 " -n\t\tdon't run the optimizer, produces same code as 6502 version\n"
                 " -prof\t\tshow token usage statistics\n"
                 " -s:<name>\tplace code into given segment\n"
                 " -t:<target>\tselect compiler target ('atari-fp', 'atari-int', etc.)\n"
                 " -l\t\tproduce a listing of the unabbreviated parsed source\n"
                 " -c\t\tonly compile to assembler, don't produce binary\n"
                 " -C:<name>\tselect linker config file name\n"
                 " -S:<addr>\tselect binary starting address\n"
                 " -X:<opt>\tpass option to the assembler\n"
                 " -o <name>\tselect output file name\n"
                 " -v\t\tshow version and exit\n"
                 " -h\t\tshow this help\n"
                 "\n"
                 "You can pass multiple basic, assembly and object files to be linked together\n";
    return 0;
}

static int show_error(std::string msg)
{
    std::cerr << "fastbasic: " << msg << "\n";
    return 1;
}

// Tries to guess install folder given the program name
static std::string guess_install_folder(std::string arg)
{
    auto p = arg.find_last_of("/\\");
    if( p == arg.npos )
        return ".";
    else if( p == 0 )
        return "/";
    else
        return arg.substr(0,p);
}

// Selects a default target based on compiler name
static std::string default_target(const std::string &prog)
{
    // Get program filename
    auto base = os::file_name(prog);

    // Check if contains the word "-int":
    if( base.rfind("-int") != base.npos )
        return "atari-int";
    else
        return "default";
}

int main(int argc, char **argv)
{
    auto program_name = std::string(argv[0]);
    auto install_folder = guess_install_folder(program_name);
    auto syntax_folder = os::full_path(install_folder, "syntax");
    auto target_folder = install_folder;
    std::vector<std::string> args(argv+1, argv+argc);
    std::string out_name;
    std::string exe_name;
    bool got_outname = false, one_step = false, next_is_output = false;
    std::string target_name = default_target(program_name);
    std::string cfg_file_def;
    compiler comp;
    std::vector<std::string> asm_opts = {"-tatari","-g"};
    std::vector<std::string> link_opts;
    // BAS files, compile INPUT(BAS) to OUTPUT(ASM)
    std::vector<std::tuple<std::string,std::string>> bas_files;
    // ASM files, assemble INPUT(ASM) to OUTPUT(OBJ) producing a listing
    std::vector<std::tuple<std::string,std::string>> asm_files;
    // OBJ files, link INPUT(OBJ) to output executable
    std::vector<std::string> link_files;

    // Process command line options
    for(auto &arg: args)
    {
        // Process delayed options
        if( next_is_output )
        {
            out_name = arg;
            if( exe_name.empty() )
                exe_name = out_name;
            next_is_output = false;
            continue;
        }
        // Process options
        if( arg == "-d" )
            comp.do_debug = true;
        else if( arg == "-n" )
            comp.optimize = false;
        else if( arg == "-prof" )
            comp.show_stats = true;
        else if( arg == "-v" )
            return show_version();
        else if( arg == "-c" )
        {
            one_step = true;
        }
        else if( arg == "-l" )
            comp.show_text = true;
        else if( arg == "-h" )
            return show_help();
        else if( arg.empty() )
            return show_error("invalid argument, try -h for help");
        else if( arg.rfind("-o", 0) == 0)
        {
            if( got_outname )
                return show_error("multiple '-o' option for the same file");
            got_outname = true;
            if( arg.size() > 2 )
            {
                out_name = arg.substr(2);
                if( exe_name.empty() )
                    exe_name = out_name;
            }
            else
                next_is_output = true;
        }
        else if( arg.rfind("-s:", 0) == 0 || arg.rfind("-s=", 0) == 0 )
        {
            auto seg = arg.substr(3);
            if( !seg.size() || (seg.find('"') != std::string::npos) )
                return show_error("invalid segment name");
            comp.segname = seg;
        }
        else if( arg.rfind("-t:", 0) == 0 || arg.rfind("-t=", 0) == 0 )
        {
            auto tgt = arg.substr(3);
            if( !tgt.size() || (tgt.find('"') != std::string::npos) )
                return show_error("invalid compiler target name");
            target_name = tgt;
        }
        else if( arg.rfind("-C:", 0) == 0 || arg.rfind("-C=", 0) == 0 )
        {
            cfg_file_def = arg.substr(3);
        }
        else if( arg.rfind("-X:", 0) == 0 || arg.rfind("-X=", 0) == 0 )
        {
            asm_opts.push_back(arg.substr(3));
        }
        else if( arg.rfind("-S:", 0) == 0 || arg.rfind("-S=", 0) == 0 )
        {
            link_opts.push_back("--start-addr");
            link_opts.push_back(arg.substr(3));
        }
        else if( arg.rfind("-syntax-path:", 0) == 0 || arg.rfind("-syntax-path=", 0) == 0 )
        {
            syntax_folder = arg.substr(13);
        }
        else if( arg.rfind("-target-path:", 0) == 0 || arg.rfind("-target-path=", 0) == 0 )
        {
            target_folder = arg.substr(13);
        }
        else if( arg[0] == '-' )
            return show_error("invalid option '" + arg + "', try -h for help");
        else if( arg.rfind(".o") == arg.size() - 2 || arg.rfind(".obj") == arg.size() - 4 )
        {
            // An object file, pass to the linker
            link_files.push_back(arg);
        }
        else if( arg.rfind(".s") == arg.size() - 2 || arg.rfind(".asm") == arg.size() - 4 )
        {
            // An assembly file, pass to the assembler and linker
            std::string obj_name = os::add_extension(arg, ".o");
            if( got_outname )
            {
                obj_name = os::add_extension(out_name, ".o");
                got_outname = false;
            }

            asm_files.emplace_back(arg, obj_name);
            if( !one_step )
                link_files.push_back(obj_name);
        }
        else
        {
            // Other files are assumed to be BASIC sources
            std::string asm_name = os::add_extension(arg, ".asm");
            std::string obj_name = os::add_extension(arg, ".o");
            if( got_outname )
            {
                asm_name = os::add_extension(out_name, ".asm");
                obj_name = os::add_extension(out_name, ".o");
                got_outname = false;
            }

            bas_files.emplace_back(arg, asm_name);
            if( !one_step )
            {
                asm_files.emplace_back(asm_name, obj_name);
                link_files.push_back(obj_name);
            }
        }
    }
    if( !bas_files.size() && !asm_files.size() && !link_files.size() )
        return show_error("missing input file name");
    if( next_is_output )
        return show_error("option '-o' must supply a file name");

    // Read target definition
    target tgt;

    try {
        tgt.load(target_folder, syntax_folder, target_name);
    }
    catch(std::exception &e)
    {
        std::cerr << e.what() << "\n";
        return 1;
    }
    std::string lib_name = os::full_path(install_folder, tgt.lib());
    std::string cfg_file = cfg_file_def.size() ? cfg_file_def : os::full_path(install_folder, tgt.cfg());

    // Guess final exe file name
    if( link_files.size() && exe_name.empty() )
        exe_name = os::add_extension(link_files[0], tgt.bin_ext());

    for(auto &f: bas_files)
    {
        auto bas_name = std::get<0>(f), asm_name = std::get<1>(f);
        std::cerr << "BAS compile '" << bas_name << "' to '" << asm_name << "'\n";
        auto e = comp.compile_file(bas_name, asm_name, tgt.sl());
        if( e )
            return e;
    }
    for(auto &f: asm_files)
    {
        auto ca65 = os::full_path(install_folder, "ca65");
        auto asm_name = std::get<0>(f), obj_name = std::get<1>(f);
        auto lst_name = os::add_extension(obj_name, ".lst");

        std::cerr << "ASM assemble '" << asm_name << "' to '" << obj_name << "'\n";
        std::vector<std::string> args {
            "ca65", "-I", os::full_path(install_folder, "asminc"), "-o",
            obj_name, "-l", lst_name
        };
        for(auto &o: asm_opts)
            args.push_back(o);
        args.push_back(asm_name);
        auto e = os::prog_exec(ca65, args);
        if( e )
            return show_error("can't assemble file\n");
    }
    if( link_files.size() )
    {
        auto ld65 = os::full_path(install_folder, "ld65");
        //$LD65" -C "$CFGFILE" "$@" -o "$XEX" -Ln "$LBL" "$FB.lib"
        std::cerr << "LINK " << exe_name << "\n";
        std::vector<std::string> args {
            "ld65", "-C", cfg_file, "-o", exe_name,
            "-Ln", os::add_extension(exe_name, ".lbl")
        };
        for(auto &f: link_files)
            args.push_back(f);
        args.push_back(lib_name);
        auto e = os::prog_exec(ld65, args);
        if( e )
            return show_error("can't assemble file\n");
    }


    return 0;
}
