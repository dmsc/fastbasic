/*
 * FastBasic - Fast basic interpreter for the Atari 8-bit computers
 * Copyright (C) 2017,2018 Daniel Serpell
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

// codestat.cc: Generate code statistics

class opstat
{
    private:
        std::vector<codew> &code;
        std::map<codew, int> c1;
        std::map<std::pair<codew, codew>, int> c2;
    public:
        opstat(std::vector<codew> &code):
            code(code)
        {
            codew old{ codew::byte, std::string() };
            for(auto &c: code)
            {
                if( c.type == codew::tok )
                {
                    std::pair<codew, codew> p{c, old};
                    c1[c] ++;
                    if( old.type == codew::tok )
                        c2[{c, old}]++;
                    old = c;
                }
                else if( c.type == codew::byte && old.type == codew::tok
                         && old.value == "TOK_BYTE" )
                    c1[old = { codew::tok, "TOK_BYTE " + c.value }]++;
                else if( c.type == codew::word && old.type == codew::tok
                        && old.value == "TOK_NUM" )
                    c1[old = { codew::tok, "TOK_NUM " + c.value }]++;
            }
            // Show results
            for(auto &c: c1)
                std::cerr << "\t" << c.second << "\t" << c.first.value << "\n";
            for(auto &c: c2)
                std::cerr << "\t" << c.second << "\t" << c.first.second.value << "\t" << c.first.first.value << "\n";
        }
};

