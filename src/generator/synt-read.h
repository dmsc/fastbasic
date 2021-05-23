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

// synt-read.h: Reads syntax file to a string, with parsing of optional
//              parts.

#include <set>
#include <fstream>
#include <vector>

class options
{
    private:
        void usage()
        {
            std::cerr << "Usage: " << prog_name << " [-options] [input_files...]\n"
                         "\n"
                         "Options:\n"
                         "  -h       Show this help.\n"
                         "  -D name  Define symbol 'name' to use in syntax.\n"
                         "  -o file  specify output file name 'file'.\n";
        }
        void error(std::string msg)
        {
            std::cerr << prog_name << ": error, " << msg << ". Use '-h' for help.\n";
            std::exit(1);
        }
        std::string readInput(std::istream &in) const
        {
            std::string r;
            int c;
            // Simple state machine to detect "#@if <word>" and "#@endif"
            int st = 0, skip = 0;
            std::string word;
            while( -1 != (c = in.get()) )
            {
                switch( st )
                {
                    case 0:
                        st = ( c == '#' ) ? 1 : 0;
                        break;
                    case 1:
                        st = ( c == '@' ) ? 2 : 0;
                        break;
                    case 2:
                        st = ( c == 'i' || c == 'I' ) ? 3 : (c == 'e' || c == 'E') ? 6 : 0;
                        break;
                    case 3:
                        st = ( c == 'f' || c == 'F' ) ? 4 : 0;
                        break;
                    case 4:
                        st = ( c == ' ' ) ? 5 : 0;
                        break;
                    case 5:
                        // WORD
                        if ( c >= 'a' && c <= 'z' )
                            word += (c - ('a'-'A'));
                        else if ( (c >= 'A' && c <= 'Z') || c == '_' || (word.empty() && c == '!') )
                            word += c;
                        else
                        {
                            // Search WORD in defines, start skip if not found, or if found
                            // and started with '!':
                            if( word.size() > 1 && word[0] == '!' )
                                skip = skip + (defs.find(word.substr(1)) != defs.end());
                            else if( !word.empty() )
                                skip = skip + (defs.find(word) == defs.end());

                            st = 0;
                            word.clear();
                        }
                        break;
                    case 6:
                        st = ( c == 'n' || c == 'N' ) ? 7 : 0;
                        break;
                    case 7:
                        st = ( c == 'd' || c == 'D' ) ? 8 : 0;
                        break;
                    case 8:
                        st = ( c == 'i' || c == 'I' ) ? 9 : 0;
                        break;
                    case 9:
                        st = ( c == 'f' || c == 'F' ) ? 10 : 0;
                        break;
                    case 10:
                        st = 0;
                        if( skip )
                            skip --;
                        break;
                }
                if( !skip || c == '\n' || c == '#' )
                    r += char(c);
            }
            return r;
        }

    public:
        size_t current = 0;
        std::set<std::string> defs;
        std::vector<std::string> input_names;
        std::string output_name;
        std::string prog_name;
        std::ofstream output_file;
        std::ofstream output_hfile;

        std::ostream &output()
        {
            if( output_name.empty() || output_name == "-" )
                return std::cout;
            if( !output_file.is_open() )
            {
                output_file.open(output_name);
                if( !output_file.is_open() )
                    error("can't open output file: '" + output_name + "'");
            }
            return output_file;
        }

        std::ostream &output_header(std::string ext)
        {
            if( output_name.empty() || output_name == "-" )
                return std::cout;
            if( !output_hfile.is_open() )
            {
                auto n = output_name.find_last_of("./");
                if( n != output_name.npos && output_name[n] == '/' )
                    n = output_name.npos;
                auto hname = output_name.substr(0, n) + ext;
                output_hfile.open(hname);
                if( !output_hfile.is_open() )
                    error("can't open output file: '" + hname + "'");
            }
            return output_hfile;
        }

        bool next_input()
        {
            return current < input_names.size();
        }

        std::pair<std::string, std::string> input()
        {
            if( current >= input_names.size() )
                return make_pair(std::string(), std::string());

            std::string input_name = input_names[current];
            current ++;

            if( input_name.empty() || input_name == "-" )
                return make_pair(readInput(std::cin), "stdin");
            std::ifstream input_file;
            input_file.open(input_name);
            if( !input_file.is_open() )
                error("can't open input file: '" + input_name + "'");
            return make_pair(readInput(input_file), input_name);
        }

        options(int argc, const char **argv):
            prog_name(argv[0])
        {
            for(int i=1; i<argc; i++)
            {
                std::string x(argv[i]);
                if( x.size() > 1 && x[0] == '-')
                {
                    if( x[1] == 'D' )
                    {
                        if( x.size() > 2 )
                            defs.insert(x.substr(2));
                        else if( i+1 < argc )
                            defs.insert(argv[++i]);
                        else
                            error("option '-D' needs an argument");
                    }
                    else if( x[1] == 'o' )
                    {
                        if( !output_name.empty() )
                            error("option '-o' multiple times");
                        else if( x.size() > 2 )
                            output_name = x.substr(2);
                        else if( i+1 < argc )
                            output_name = argv[++i];
                        else
                            error("option '-o' needs argument");
                    }
                    else
                        error("invalid option '" + x + "'\n");
                }
                else
                    input_names.push_back(x);
            }
            // If np input files, add an empty name for standard input
            if( !input_names.size() )
                input_names.push_back(std::string());
        }
};

