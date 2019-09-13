/*
 * FastBasic - Fast basic interpreter for the Atari 8-bit computers
 * Copyright (C) 2017-2019 Daniel Serpell
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
        std::map<enum tokens, int> c1;
        std::map<std::pair<enum tokens, enum tokens>, int> c2;
        std::map<std::pair<enum tokens, int>, int> c3;
    public:
        opstat(std::vector<codew> &code):
            code(code)
        {
            enum tokens old = TOK_LAST_TOKEN;
            for(auto &c: code)
            {
                if( c.is_tok() )
                {
                    auto t = c.get_tok();
                    c1[t] ++;
                    if( old != TOK_LAST_TOKEN )
                        c2[{t, old}]++;
                    old = c.get_tok();
                }
                else
                {
                    if( c.is_byte() && old == TOK_BYTE )
                        c3[{old,c.get_val()}] ++;
                    else if( c.is_sbyte() && old == TOK_BYTE )
                        continue;
                    else if( c.is_sbyte() && old == TOK_BYTE_POKE )
                        continue;
                    else if( c.is_word() && old == TOK_NUM )
                        c3[{old,c.get_val()}] ++;
                    else if( c.is_sword() && old == TOK_NUM )
                        continue;
                    else if( c.is_sword() && old == TOK_NUM_POKE )
                        continue;
                    else if( c.is_byte() && old == TOK_VAR_LOAD )
                        continue;
                    else if( c.is_byte() && old == TOK_VAR_ADDR )
                        continue;
                    else
                        old = TOK_LAST_TOKEN;
                }
            }
            // Show results
            for(auto &c: c1)
                std::cerr << "\t" << c.second << "\t" << token_name(c.first) << "\n";
            for(auto &c: c2)
                std::cerr << "\t" << c.second << "\t"
                          << token_name(c.first.second) << "\t"
                          << token_name(c.first.first) << "\n";
            for(auto &c: c3)
                std::cerr << "\t" << c.second << "\t" << token_name(c.first.first)
                          << " " << c.first.second << "\n";
        }
};

