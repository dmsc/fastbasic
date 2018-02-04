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

// codew.h: Representation of bytecode
#pragma once

#include "basic.h" // enum tokens

class codew {
    private:
        enum {
            tok,
            byte,
            byte_str,
            word,
            word_str,
            label,
            fp,
            string
        } type;
        int num;
        std::string str;
        atari_fp x;
        enum tokens tk;
        int lnum;
    public:
        static codew ctok(enum tokens t, int lnum)
        {
            codew c;
            c.type = tok;
            c.lnum = lnum;
            c.tk = t;
            return c;
        }
        static codew cbyte(std::string s, int lnum)
        {
            if( s.find_first_not_of("0123456789") == s.npos )
                return cbyte((int16_t)(std::stoul(s)), lnum);
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
            if( s.find_first_not_of("0123456789") == s.npos )
                return cword((int16_t)(std::stoul(s)), lnum);
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
            c.x = x;
            return c;
        }
        static codew cstring(std::string s, int lnum)
        {
            codew c;
            c.type = string;
            c.lnum = lnum;
            c.str = s;
            return c;
        }
        // Test type
        bool is_tok(enum tokens t) const {
            return type == tok && tk == t;
        }
        bool is_sbyte(std::string s) const {
            return type == byte_str && str == s;
        }
        bool is_sword(std::string s) const {
            return type == word_str && str == s;
        }
        bool is_tok() const {
            return type == tok;
        }
        bool is_byte() const {
            return type == byte;
        }
        bool is_word() const {
            return type == word;
        }
        bool is_sbyte() const {
            return type == byte_str;
        }
        bool is_sword() const {
            return type == word_str;
        }
        bool is_label() const {
            return type == label;
        }
        // Get data
        std::string get_str() {
            if( type == byte_str || type == word_str || type == label )
                return str;
            else
                return std::string();
        }
        int get_val() const {
            if( type == byte || type == word )
                return num;
            else
                return -1;
        }
        enum tokens get_tok() const {
            if( type == tok )
                return tk;
            else
                return TOK_LAST_TOKEN;
        }
        int linenum() const
        {
            return lnum;
        }
        std::string to_asm()
        {
            switch(type)
            {
                case tok:
                    return "\t.byte\t" + token_name(tk);
                case byte:
                    return "\t.byte\t" + std::to_string(num & 0xFF);
                case word:
                    return "\t.word\t" + std::to_string(num & 0xFFFF);
                case byte_str:
                    return "\t.byte\t" + str;
                case word_str:
                    return "\t.word\t" + str;
                case fp:
                    return "\t.byte\t" + x.to_asm();
                case label:
                    return str + ":";
                case string:
                    return "\t.byte\t" + str;
            }
            return std::string();
        }
#if 0
        bool operator<(const codew &c) const {
            return (type == c.type) ? (value < c.value) : (type < c.type);
        }
#endif
};

