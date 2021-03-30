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

// codew.h: Representation of bytecode
#pragma once

#include "basic.h" // enum tokens
#include "atarifp.h"
#include <stdexcept>

class codew {
    private:
        enum {
            tok,        // A bytecode TOKEN
            byte,       // One byte, as number (0 to 255)
            byte_str,   // One byte, as a label
            word,       // Two bytes, as number (-32768 to 32767)
            word_str,   // Two bytes, as a label
            label,      // A label (target of a jump)
            fp,         // A FP number, 6 bytes.
            string      // A constant string, length+bytes
        } type;
        int num;
        std::string str;
        atari_fp x;
        enum tokens tk;
        int lnum;
        // Escape string to include in assembly output
        std::string escape(std::string str)
        {
            std::string ret;
            bool quote = false;
            for(auto c: str)
            {
                if( c < 32 || c == '"' || c > 126 )
                {
                    if( quote )
                        ret += "\"";
                    ret += ", " + std::to_string(0xFF & c);
                    quote = false;
                }
                else
                {
                    if( !quote )
                        ret += ", \"";
                    ret += c;
                    quote = true;
                }
            }
            if( quote )
                ret += "\"";
            return ret;
        }
        codew() {};
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
        bool is_string() const {
            return type == string;
        }
        bool is_symbol() const {
            return type == byte_str || type == word_str || type == label;
        }
        // Get data
        std::string get_str() {
            if( type == byte_str || type == word_str || type == label ||
                type == string )
                return str;
            else
                throw std::runtime_error("internal error: not a string");
        }
        int get_val() const {
            if( type == byte || type == word )
                return num;
            else
                throw std::runtime_error("internal error: not a value");
        }
        enum tokens get_tok() const {
            if( type == tok )
                return tk;
            else
                throw std::runtime_error("internal error: not a token");
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
                    return "\t.byte\t" + std::to_string(str.length()) + escape(str);
            }
            return std::string();
        }
};

