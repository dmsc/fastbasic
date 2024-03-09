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

// synt-preproc.cc: Pre-processor for the syntax files
#include "synt-preproc.h"

using namespace syntax;

void preproc::add_def(std::string def)
{
    defs.insert(def);
}

std::string preproc::read_input(std::istream &in) const
{
    std::string r;
    int c;
    // Simple state machine to detect "#@if <word>" and "#@endif"
    int st = 0, skip = 0;
    std::string word;
    while(-1 != (c = in.get()))
    {
        switch(st)
        {
        case 0:
            st = (c == '#') ? 1 : 0;
            break;
        case 1:
            st = (c == '@') ? 2 : 0;
            break;
        case 2:
            st = (c == 'i' || c == 'I') ? 3 : (c == 'e' || c == 'E') ? 6 : 0;
            break;
        case 3:
            st = (c == 'f' || c == 'F') ? 4 : 0;
            break;
        case 4:
            st = (c == ' ') ? 5 : 0;
            break;
        case 5:
            // WORD
            if(c >= 'a' && c <= 'z')
                word += (c - ('a' - 'A'));
            else if((c >= 'A' && c <= 'Z') || c == '_' || (word.empty() && c == '!'))
                word += c;
            else
            {
                // Search WORD in defines, start skip if not found, or if found
                // and started with '!':
                if(word.size() > 1 && word[0] == '!')
                    skip = skip + (defs.find(word.substr(1)) != defs.end());
                else if(!word.empty())
                    skip = skip + (defs.find(word) == defs.end());

                st = 0;
                word.clear();
            }
            break;
        case 6:
            st = (c == 'n' || c == 'N') ? 7 : 0;
            break;
        case 7:
            st = (c == 'd' || c == 'D') ? 8 : 0;
            break;
        case 8:
            st = (c == 'i' || c == 'I') ? 9 : 0;
            break;
        case 9:
            st = (c == 'f' || c == 'F') ? 10 : 0;
            break;
        case 10:
            st = 0;
            if(skip)
                skip--;
            break;
        }
        if(!skip || c == '\n' || c == '#')
            r += char(c);
    }
    return r;
}
