/*
 * FastBasic - Fast basic interpreter for the Atari 8-bit computers
 * Copyright (C) 2017-2025 Daniel Serpell
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

// compile.cc: Main compiler

#include "compile.h"
#include <fstream>
#include <iostream>

#include "codestat.h"
#include "parser.h"
#include "peephole.h"
#include "vartype.h"

// Reads a complete source line, respecting ATASCII and ASCII EOL inly
// outside strings.
static int readLine(std::string &r, std::istream &is)
{
    // Special handling of EOL: We allow Unix / DOS line endings - except inside
    // strings, because that would be incompatible with the Atari IDE.
    // To properly split lines then, we must pre-parse the content, skipping
    // comments and keeping track of the strings.
    bool in_string = false;
    bool in_comment = false;
    bool in_start = true;
    int num_lines = 0;
    while(-1 != is.peek())
    {
        char c = is.get();
        r += c;
        if(in_string)
        {
            // Inside strings, consume any char except for the '"'
            // but increase line-number for easier debugging.
            if(c == '\x0A')
                num_lines++;
            else if(c == '\"')
                in_string = false;
            continue;
        }
        // Check for DOS end of line
        if(c == '\x0D' && '\x0A' == is.peek())
        {
            // Check if next char is 0x0A and replace
            c = is.get();
            r[r.size() - 1] = c;
        }
        // Check for any end of line
        if(c == '\x0A' || c == '\x9B')
            return num_lines + 1;
        // Check we are not entering a string or a comment
        if(in_start)
        {
            if(c == '.' || c == '\'')
                in_comment = true;
            if(c != ' ')
                in_start = false;
        }
        if(!in_comment)
        {
            if(c == '\'')
                in_comment = true;
            else if(c == ':')
                in_start = true;
            else if(c == '\"')
                in_string = true;
        }
    }
    return 0;
}

// Parses one source line
static bool parse_line(std::string line, int ln, parse &s, bool show_text,
                       unsigned short_text, const syntax::sm_list &sl,
                       std::string &short_line, std::ostream &list_file)
{
    s.new_line(line, ln);
    while(s.pos != line.length())
    {
        if(!syntax::parse_start(s, sl) || (s.pos != line.length() && !s.peek(':')))
        {
            std::string msg = "parse error";
            if(!s.saved_errors.empty())
            {
                // Get min level
                auto ml =
                    std::min_element(s.saved_errors.begin(), s.saved_errors.end(),
                                     [](auto &a, auto &b) { return a.lvl < b.lvl; });
                msg += ", expected: ";
                bool first = true;
                for(const auto &i : s.saved_errors)
                {
                    if(i.lvl == ml->lvl)
                    {
                        if(!first)
                            msg += ", ";
                        msg += i.msg;
                        first = false;
                    }
                }
            }
            throw parse_error(msg, s.max_pos);
        }
        else
        {
            if(short_text > 0)
            {
                auto txt = s.expand.get_short();
                if(txt.size())
                {
                    if(!short_line.size())
                        short_line = txt;
                    else if(short_line.size() + 1 + txt.size() < short_text)
                    {
                        short_line += ':';
                        short_line += txt;
                    }
                    else
                    {
                        list_file << short_line << '\x9B';
                        short_line = txt;
                    }
                }
            }
            else if(show_text)
                list_file << s.expand.get() << "\n";
        }

        s.expect(':');
    }
    return true;
}

static int show_error(std::string msg)
{
    std::cerr << "fastbasic: " << msg << "\n";
    return 1;
}

static char printable(char c)
{
    if(c < 32)
        return '.';
    else if(c < 127)
        return c;
    else
        return '.';
}

compiler::compiler()
{
    optimize = true;
    segname = "BYTECODE";
    show_stats = false;
    show_text = false;
    short_text = 0;
    do_debug = false;
}

int compiler::compile_file(std::string iname, std::string output_filename,
                           const syntax::sm_list &sl, std::string listing_filename)
{
    std::ifstream ifile;
    std::ofstream ofile, lstfile;

    ifile.open(iname, std::ios::binary);
    if(!ifile.is_open())
        return show_error("can't open input file '" + iname + "'");

    ofile.open(output_filename);
    if(!ofile.is_open())
        return show_error("can't open output file '" + output_filename + "'");

    if(show_text)
    {
        lstfile.open(listing_filename);
        if(!lstfile.is_open())
            return show_error("can't open listing file '" + listing_filename + "'");
    }

    parse s(do_debug);
    s.set_input_file(iname);

    int ln = 1;
    std::string list_prog;
    while(1)
    {
        try
        {
            std::string line;
            int lines = readLine(line, ifile);
            if(!lines && line.empty())
                break;
            if(do_debug)
                std::cout << iname << ": parsing line " << ln << "\n";
            parse_line(line, ln, s, show_text, short_text, sl, list_prog, lstfile);
            ln += lines;
        }
        catch(parse_error &e)
        {
            // Get start/end of current line, removing last EOL
            size_t min = 0, max = s.str.length();
            if(max && s.str[max - 1] == '\n')
                max--;
            // Adjust error position to be inside the line
            if(e.pos > max)
                e.pos = max;
            // Only show up to 76 characters total
            if(max > 76)
            {
                if(e.pos > 50)
                    min = e.pos - 50;
                if(max - min > 76)
                    max = min + 76;
            }
            // Show error position, line and marker
            std::cerr << iname << ":" << ln << ":" << e.pos << ": " << e.what() << "\n  ";
            for(auto i = min; i < e.pos; i++)
                std::cerr << printable(s.str[i]);
            std::cerr << " ";
            for(auto i = e.pos; i < max; i++)
                std::cerr << printable(s.str[i]);
            std::cerr << "\n  ";
            for(auto i = min; i < e.pos; i++)
                std::cerr << "-";
            std::cerr << "^\n";

            return 1;
        }
    }
    if(do_debug)
    {
        std::cout << "parse end:\n";
        std::cout << "MAX LEVEL: " << s.maxlvl << "\n";
    }

    // Show short line
    if(short_text && list_prog.size())
        lstfile << list_prog << '\x9B';

    // Check unclosed loops
    auto loop_error = s.check_loops();
    if(loop_error.size())
    {
        std::cerr << iname << ":" << ln << ": " << loop_error << "\n";
        return 1;
    }

    s.emit_tok("TOK_END");
    // Optimize
    if(optimize)
        do_peephole(s.full_code());
    // Statistics
    if(show_stats)
        do_opstat(s.full_code());

    // Get global symbols
    std::set<std::string> globals, globals_zp;
    for(auto &c : s.full_code())
    {
        if(c.is_symbol())
        {
            // Lower-case symbols are internal
            auto s = c.get_str();
            if(!s.empty() && s[0] >= 'A' && s[0] <= '_')
            {
                if(c.is_sword())
                    globals.insert(c.get_str());
                else if(c.is_sbyte())
                    globals_zp.insert(c.get_str());
            }
        }
    }

    // Output all global symbols
    ofile << "; Imported symbols\n";
    for(auto &c : globals)
        ofile << "\t.global " << c << "\n";
    for(auto &c : globals_zp)
        ofile << "\t.globalzp " << c << "\n";

    // Export common symbols and include atari defs
    ofile << "\n"
             "; Exported symbols\n"
             "\t.export bytecode_start\n"
             "\n\t.include \"target.inc\"\n\n";

    // Write tokens
    ofile << "; TOKENS:\n";
    for(auto &i : s.used_tokens())
        ofile << "\t.importzp\t" << i << "\n";
    ofile << ";-----------------------------\n"
             "; Macro to get variable ID from name\n"
             "\t.import __HEAP_RUN__\n"
             ".macro makevar name\n"
             "\t.byte <((.ident (.concat (\"fb_var_\", name)) - __HEAP_RUN__)/2)\n"
             ".endmacro\n"
             "; Variables\n";
    // Create a map to reorder variables by number:
    auto vlist = std::map<int, std::string>();
    for(auto &v : s.vars)
        if(!v.first.empty() && v.first[0] != '-')
            vlist.emplace(v.second, v.first);
    ofile << "\t.segment \"HEAP\"\n";
    // And now, output all variables:
    for(auto &v : vlist)
    {
        auto vtype = VarType(v.first & 0xFF);
        ofile << "\t.export fb_var_" << v.second << "\n";
        ofile << "fb_var_" << v.second << ":\t.res " << get_vt_size(vtype) << "\t; "
              << get_vt_name(vtype) << " variable\n";
    }
    ofile << ";-----------------------------\n"
             "; Bytecode\n"
             "\t.segment \""
          << segname
          << "\"\n"
             "bytecode_start:\n";
    ln = -1;
    ;
    // Map with all line labels already emitted, this is needed
    // to avoid duplicate labels on reordered lines.
    std::map<int, int> line_labels;
    for(auto c : s.full_code())
    {
        if(c.linenum() != ln)
        {
            ln = c.linenum();
            std::string lbl = "@FastBasic_LINE_" + std::to_string(ln);
            // If we already emitted this label, adds a numbered sufix
            if(line_labels.find(ln) != line_labels.end())
            {
                line_labels[ln]++;
                lbl = lbl + "_" + std::to_string(line_labels[ln]);
            }
            else
                line_labels[ln] = 0;
            // Adds a label to facilitate debugging of resulting program
            ofile << lbl << ":\t; LINE " << ln << "\n";
        }
        // Handle labels
        if(c.is_label())
        {
            // Check if the name starts with the label prefix
            auto full_name = c.get_str();
            auto ln = std::string(s.label_prefix).length();
            if(full_name.substr(0, ln) == s.label_prefix)
            {
                // Yes, this is a valid label
                auto name = full_name.substr(ln);
                auto it = s.labels.find(name);
                if(it == s.labels.end())
                    std::cerr << "internal error: unknown label type '" << name << "'\n";
                else
                {
                    auto lbl = it->second;
                    auto seg = lbl.get_segment();
                    if(seg.size())
                        ofile << "\t.segment \"" << seg << "\"\n";
                    else if(lbl.is_proc())
                        ofile << "\t.segment \"" << segname << "\"\n";
                    else
                        ofile << "\t.segment \"DATA\"\n";
                }
                ofile << "\t.export\t" << full_name << "\n";
            }
        }
        ofile << c.to_asm() << "\n";
    }

    return 0;
}
