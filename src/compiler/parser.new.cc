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

// parser.cc: C++ Parser

#include <iostream>
#include <fstream>
#include <map>
#include <set>
#include <cmath>
#include <vector>

class parse {
    public:
        class codew {
            private:
                union {
                    int num;
                    std::string str;
                    atari_fp fp;
                    enum TOKENS tk;
                };
                enum {
                    tok,
                    byte,
                    byte_str,
                    word,
                    word_str,
                    label,
                    fp
                } type;
            public:
                int lnum;
                static codew ctok(enum TOKENS t, int lnum)
                {
                    codew c;
                    c.type = tok;
                    c.lnum = lnum;
                    c.tk = t;
                    return c;
                }
                static codew cbyte(std::string s, int lnum)
                {
                    codew c;
                    c.type = byte_str;
                    c.lnum = lnum;
                    c.str = s;
                    return c;
                }
                static codew cbyte(int n, int lnum)
                {
                    codew c;
                    c.type = byte;
                    c.lnum = lnum;
                    c.num = n;
                    return c;
                }
                static codew cword(std::string s, int lnum)
                {
                    codew c;
                    c.type = word_str;
                    c.lnum = lnum;
                    c.str = s;
                    return c;
                }
                static codew cword(int n, int lnum)
                {
                    codew c;
                    c.type = word;
                    c.lnum = lnum;
                    c.num = n;
                    return c;
                }
                static codew clabel(std::string s, int lnum)
                {
                    codew c;
                    c.type = label;
                    c.lnum = lnum;
                    c.str = s;
                    return c;
                }
                static codew cfp(atari_fp x, int lnum)
                {
                    codew c;
                    c.type = fp;
                    c.lnum = lnum;
                    c.fp = x;
                    return c;
                }
                bool operator<(const codew &c) const {
                    return (type == c.type) ? (value < c.value) : (type < c.type);
                }
        };
        class saved_pos {
            public:
                size_t pos;
                size_t opos;
        };
        class jump {
            public:
                LoopType type;
                std::string label;
        };
        int lvl, maxlvl;
        std::string str;
        size_t pos;
        size_t max_pos;
        bool low_error;
        std::string current_error;
        std::string saved_error;
        int linenum;
        std::map<std::string, std::vector<codew>> procs;
        std::map<std::string, int> vars;
        std::map<std::string, int> labels;
        std::vector<jump> jumps;
        int label_num;
        bool finalized;
        std::vector<codew> *code;

        parse():
            lvl(0), maxlvl(0), pos(0),
            max_pos(0), low_error(false), label_num(0),
            finalized(false),
            code(&procs[std::string()]) { }

        std::string new_label()
        {
            label_num++;
            return "jump_lbl_" + std::to_string(label_num);
        }
        std::string push_loop(LoopType type)
        {
            auto lbl = new_label();
            jumps.push_back({type, lbl});
            return lbl;
        }
        bool peek_loop(LoopType type)
        {
            if( !jumps.size() )
                return false;
            auto last = jumps.back();
            return !( last.type != type && ( type != LT_ELSE || last.type != LT_IF ) );
        }
        std::string pop_loop(LoopType type)
        {
            if( !jumps.size() )
            {
                std::cerr << "missing loop start\n";
                return std::string();
            }
            auto last = jumps.back();
            if( last.type != type )
            {
                if( type !=  LT_ELSE || last.type != LT_IF )
                {
                    std::cerr << "invalid loop type\n";
                    return std::string();
                }
            }
            auto lbl = last.label;
            jumps.pop_back();
            return lbl;
        }

        void new_line(std::string l, int ln)
        {
            pos = max_pos = 0;
            str = l;
            linenum = ln;
        }

        saved_pos save()
        {
            return saved_pos{pos, code->size()};
        }

        void error(std::string str)
        {
            if( str == "&LOW_ERROR" )
                low_error = true;
            else if( !str.empty() )
            {
                current_error = str;
                debug( "Set error='" + str + "'" );
            }
        }

        void restore(saved_pos s)
        {
            if( pos >= max_pos )
            {
                if( !current_error.empty() &&
                    ( !low_error || pos > max_pos || saved_error.empty() ) )
                {
                    debug("save error='" + current_error + "'");
                    saved_error = current_error;
                }
                max_pos = pos;
            }
            pos = s.pos;
            code->resize(s.opos);
        }

        codew remove_last()
        {
            codew ret = code->back();
            code->pop_back();
            return ret;
        }
        void debug(const std::string &c)
        {
            if(do_debug)
            {
                if( lvl > maxlvl ) maxlvl = lvl;
                for(int i=0; i<lvl; i++)
                    std::cout << " ";
                std::cout << c << "\n";
                std::cout.flush();
            }
        }

        bool eos()
        {
            return pos >= str.length();
        }

        bool range(char c1, char c2)
        {
            if( pos < str.length() )
            {
                if( str[pos] >= c1 && str[pos] <= c2 )
                {
                    pos ++;
                    return true;
                }
            }
            return false;
        }
        bool ident_start()
        {
            return pos < str.length() &&
                ( (str[pos] >= 'a' && str[pos] <= 'z') ||
                  (str[pos] >= 'A' && str[pos] <= 'Z') || str[pos] == '_' );
        }
        bool get_ident(std::string &ret)
        {
            skipws();
            if( ident_start() )
            {
                while( pos < str.length() )
                {
                    char c = str[pos];
                    if( c >= 'a' && c <= 'z' )
                        c = c - ('a' - 'A');
                    if( (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '_' )
                    {
                        ret += c;
                        pos ++;
                    }
                    else
                        break;
                }
                skipws();
                return true;
            }
            else
                return false;
        }
        bool peek(char c)
        {
            if( pos < str.length() )
            {
                char p = str[pos];
                if( p >= 'a' && p >= 'z' )
                    p = p - ('a' - 'A');
                if( c >= 'a' && c <= 'z' )
                    c = c - ('a' - 'A');
                if( p == c )
                {
                    return true;
                }
            }
            return false;
        }
        bool skipws()
        {
            while( pos < str.length() && (str[pos] == ' ' || str[pos] == '\t') )
                pos++;
            return true;
        }
        bool expect(char c)
        {
            if( pos < str.length() )
            {
                char p = str[pos];
                if( p >= 'a' && p <= 'z' )
                    p = p - ('a' - 'A');
                if( c >= 'a' && c <= 'z' )
                    c = c - ('a' - 'A');
                if( p == c )
                {
                    pos ++;
                    return true;
                }
            }
            if( c == ',' )
            {
                current_error = "comma";
                debug( "Set error='" + current_error + "'" );
            }
            return false;
        }
        bool eol()
        {
            if( pos < str.length() )
            {
                // Three types of EOL:
                if( (str[pos] == 0x9B) || // AT-ASCII EOL
                    (str[pos] == '\n') )  // Unix EOL
                {
                    pos ++;
                    return true;
                }
                // Windows EOL, two bytes (last is :
                if( (str[pos] == '\r')  && (pos < str.length()-1) && (str[pos+1] == '\n') )
                {
                    pos += 2;
                    return true;
                }
            }
            return false;
        }
        bool emit_word(uint16_t w)
        {
            codew c{ codew::word, w, linenum};
            code->push_back(c);
            return true;
        }
        bool emit_word(std::string s)
        {
            if( s.find_first_not_of("0123456789") == s.npos )
                return emit_word( (int16_t)(std::stoul(s)) );
            codew c{ codew::word_str, s, linenum};
            code->push_back(c);
            return true;
        }
        bool emit_fp(atari_fp x)
        {
            codew c{ codew::fp, x.to_asm(), linenum};
            code->push_back(c);
            return true;
        }
        bool emit_label(std::string s)
        {
            codew c{ codew::label, s, linenum};
            code->push_back(c);
            return true;
        }
        bool emit(std::string s)
        {
            codew c{ codew::byte, s, linenum};
            if( s.substr(0,4) == "TOK_" )
                c.type = codew::tok;
            code->push_back(c);
            return true;
        }
        void push_proc(std::string l)
        {
            code = &procs[l];
        }
        void pop_proc(std::string l)
        {
            code = &procs[std::string()];
        }
        std::vector<codew> &full_code()
        {
            std::vector<codew> &p = procs[std::string()];
            if( !finalized )
            {
                finalized = true;
                // Correctly terminate main code
                if( !p.size() || p.back().type != codew::tok || p.back().value != "TOK_END" )
                    p.push_back({codew::tok, "TOK_END"});
                for(auto &c: procs)
                    if( !c.first.empty() )
                        p.insert(std::end(p), std::begin(c.second), std::end(c.second));
            }
            return p;
        }
};

