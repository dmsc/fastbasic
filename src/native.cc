/*
 * FastBasic - Fast basic interpreter for the Atari 8-bit computers
 * Copyright (C) 2017 Daniel Serpell
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

// native.cc: Main native compiler file
// ------------------------------------

#include <iostream>
#include <fstream>
#include <map>
#include <vector>

enum VarType {
        VT_UNDEF = 0,
        VT_WORD,
        VT_ARRAY_WORD,
        VT_ARRAY_BYTE,
        VT_STRING
};

enum LoopType {
    // First entries can't use "EXIT"
    LT_PROC_1 = 0,
    LT_DATA,
    LT_EXIT,
    // From here, loops don't push jump destinations
    LT_LAST_JUMP = 32,
    LT_PROC_2,
    LT_DO_LOOP,
    LT_REPEAT,
    LT_WHILE_1,
    LT_FOR_1,
    // And from here, loops push destinations and are ignored by EXIT
    LT_WHILE_2 = 128,
    LT_FOR_2,
    LT_IF,
    LT_ELSE,
    LT_ELIF
};

static bool do_debug = false;

class parse {
    public:
        class codew {
            public:
                enum { tok, byte, word, label, comment } type;
                std::string value;
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
        std::vector<codew> code;
        std::map<std::string, int> vars;
        std::map<std::string, int> labels;
        std::vector<jump> jumps;
        int label_num;

        parse(): lvl(0), maxlvl(0), pos(0), max_pos(0), label_num(0) {}

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
            return !( last.type != type && ( type != 'E' || last.type != 'I' ) );
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

        void new_line(std::string l)
        {
            pos = max_pos = 0;
            str = l;
        }

        saved_pos save()
        {
            return saved_pos{pos, code.size()};
        }

        void restore(saved_pos s)
        {
            if( pos > max_pos ) max_pos = pos;
            pos = s.pos;
            code.resize(s.opos);
        }

        codew remove_last()
        {
            codew ret = code.back();
            code.pop_back();
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
            return false;
        }
        bool emit_word(std::string s)
        {
            codew c{ codew::word, s};
            code.push_back(c);
            return true;
        }
        bool emit_label(std::string s)
        {
            codew c{ codew::label, s};
            code.push_back(c);
            return true;
        }
        bool comment(std::string s)
        {
            codew c{ codew::comment, s};
            code.push_back(c);
            return true;
        }
        bool emit(std::string s)
        {
            codew c{ codew::byte, s};
            if( s.substr(0,4) == "TOK_" )
                c.type = codew::tok;
            code.push_back(c);
            return true;
        }
};

static VarType get_vartype(parse::codew cw)
{
    auto t = cw.value;
    if( t == "VT_UNDEF" )
        return VT_UNDEF;
    if( t == "VT_WORD" )
        return VT_WORD;
    if( t == "VT_ARRAY_WORD" )
        return VT_ARRAY_WORD;
    if( t == "VT_ARRAY_BYTE" )
        return VT_ARRAY_BYTE;
    if( t == "VT_STRING" )
        return VT_STRING;
    return VT_UNDEF;
}

static LoopType get_looptype(parse::codew cw)
{
    auto t = cw.value;
    if( t == "LT_PROC_1" )
        return LT_PROC_1;
    if( t == "LT_PROC_2" )
        return LT_PROC_2;
    if( t == "LT_DATA" )
        return LT_DATA;
    if( t == "LT_DO_LOOP" )
        return LT_DO_LOOP;
    if( t == "LT_REPEAT" )
        return LT_REPEAT;
    if( t == "LT_WHILE_1" )
        return LT_WHILE_1;
    if( t == "LT_WHILE_2" )
        return LT_WHILE_2;
    if( t == "LT_FOR_1" )
        return LT_FOR_1;
    if( t == "LT_FOR_2" )
        return LT_FOR_2;
    if( t == "LT_EXIT" )
        return LT_EXIT;
    if( t == "LT_IF" )
        return LT_IF;
    if( t == "LT_ELSE" )
        return LT_ELSE;
    if( t == "LT_ELIF" )
        return LT_ELIF;
    throw std::runtime_error("invalid loop type");
}

static unsigned long get_number(parse &s)
{
    auto start = s.pos;
    if( s.expect('$') )
    {
        s.debug("(hex)");
        start ++;
        if( !s.range('0', '9') && !s.range('A', 'F') && !s.range('a', 'f') )
            return 65536;

        while( s.range('0', '9') || s.range('A', 'F') || s.range('a', 'f') );
        auto sn = s.str.substr(start, s.pos - start);
        s.debug("(got '" + sn + "')");
        return std::stoul(sn, 0, 16);
    }
    else
    {
        if( !s.range('0', '9') )
            return 65536;

        while( s.range('0', '9') );
        auto sn = s.str.substr(start, s.pos - start);
        s.debug("(got '" + sn + "')");
        return std::stoul(sn);
    }
}

static bool get_asm_constant(parse &s)
{
    if( s.expect('@') )
    {
        std::string name;
        // Reads ASM constant
        if( !s.get_ident(name) )
            return false;
        s.emit_word( name );
        s.skipws();
        return true;
    }
    return false;
}

static bool SMB_E_NUMBER_WORD(parse &s)
{
    s.debug("E_NUMBER_WORD");
    s.skipws();
    if( get_asm_constant(s) )
        return true;
    auto num = get_number(s);
    if( num > 65535 )
        return false;
    s.emit_word( std::to_string(num) );
    s.skipws();
    return true;
}

static bool SMB_E_NUMBER_BYTE(parse &s)
{
    s.debug("E_NUMBER_BYTE");
    s.skipws();
    auto num = get_number(s);
    if( num > 255 )
        return false;
    s.emit( std::to_string(num) );
    s.skipws();
    return true;
}

static bool SMB_E_EOL(parse &s)
{
    s.debug("E_EOL");
    return( s.eos() || s.expect('\n') || s.expect(0x9b) );
}

static bool SMB_E_CONST_STRING(parse &s)
{
    s.debug("E_CONST_STRING");
    std::string str;
    int len = 0;
    bool in_str = false;
    while( !s.eos() )
    {
        if( s.expect('"') && !s.peek('"') )
        {
            if( in_str )
                str += "\"";
            s.emit( std::string("TOK_CSTRING, ") + std::to_string(len) + str + ", 0" );
            return true;
        }
        char c = s.str[s.pos];
        if( c < 32 || c == '"' || c > 127 )
        {
            if( in_str )
                str += "\"";
            str += ", " + std::to_string(0xFF & c);
            in_str = false;
        }
        else
        {
            if( !in_str )
                str += ", \"";
            str += c;
            in_str = true;
        }
        s.pos++;
        len ++;
    }
    return false;
}

static bool SMB_E_REM(parse &s)
{
    s.debug("E_REM");
    while( !s.eos() && !s.peek('\n') && !s.peek(0x9b) )
        s.pos++;
    return true;
}

static bool SMB_E_PUSH_LT(parse &s)
{
    // nothing to do!
    s.debug("E_PUSH_LT");
    auto t = get_looptype(s.remove_last());
    auto l = s.push_loop(t);
    switch(t)
    {
        case LT_DO_LOOP:
        case LT_REPEAT:
        case LT_WHILE_1:
        case LT_FOR_1:
            s.emit_label(l);
            break;
        case LT_WHILE_2:
        case LT_FOR_2:
        case LT_IF:
        case LT_PROC_1:
        case LT_DATA:
            s.emit_word(l);
            break;
        case LT_EXIT:
        case LT_ELSE:
        case LT_ELIF:
        case LT_PROC_2:
        case LT_LAST_JUMP:
            break;
    }
    return true;
}

static bool SMB_E_POP_LOOP(parse &s)
{
    // nothing to do!
    s.debug("E_POP_LOOP");
    auto l = s.pop_loop(LT_DO_LOOP);
    if( l.empty() )
        return false;
    s.emit_word(l);
    s.emit_label(l + "_x");
    return true;
}

static bool SMB_E_POP_WHILE(parse &s)
{
    // nothing to do!
    s.debug("E_POP_WHILE");
    auto l1 = s.pop_loop(LT_WHILE_2);
    auto l2 = s.pop_loop(LT_WHILE_1);
    if( l1.empty() || l2.empty() )
        return false;
    s.emit_word(l2);
    s.emit_label(l1);
    s.emit_label(l2 + "_x");
    return true;
}

static bool SMB_E_POP_IF(parse &s)
{
    // nothing to do!
    s.debug("E_POP_IF");
    auto l = s.pop_loop(LT_ELSE);
    if( l.empty() )
        return false;
    s.emit_label(l);
    while( s.peek_loop(LT_ELIF) )
        s.emit_label(s.pop_loop(LT_ELIF));
    return true;
}

static bool SMB_E_ELSE(parse &s)
{
    // nothing to do!
    s.debug("E_ELSE");
    auto l1 = s.pop_loop(LT_IF);
    if( l1.empty() )
        return false;
    auto l2 = s.push_loop(LT_ELSE);
    s.emit_word(l2);
    s.emit_label(l1);
    return true;
}

static bool SMB_E_ELIF(parse &s)
{
    // nothing to do!
    s.debug("E_ELIF");
    auto l1 = s.pop_loop(LT_IF);
    if( l1.empty() )
        return false;
    auto l2 = s.push_loop(LT_ELIF);
    s.emit_word(l2);
    s.emit_label(l1);
    return true;
}

static bool SMB_E_EXIT_LOOP(parse &s)
{
    // nothing to do!
    s.debug("E_EXIT_LOOP");
    auto last = s.jumps.size();
    while(1)
    {
        if( last == 0 )
            return false;
        last--;
        auto type = s.jumps[last].type;
        if( type == LT_ELIF || type == LT_IF || type == LT_ELSE || type == LT_FOR_2 || type == LT_WHILE_2 )
            continue;
        break;
    }
    s.emit_word( s.jumps[last].label + "_x" );
    return true;
}

static bool SMB_E_POP_PROC_1(parse &s)
{
    // nothing to do!
    s.debug("E_POP_PROC_1");
    auto l = s.pop_loop(LT_PROC_1);
    if( l.empty() )
        return false;
    s.emit_label(l);
    return true;
}

static bool SMB_E_POP_PROC_2(parse &s)
{
    // nothing to do!
    s.debug("E_POP_PROC_2");
    auto l = s.pop_loop(LT_PROC_2);
    if( l.empty() )
        return false;
    s.emit_label(l + "_x");
    return true;
}

static bool SMB_E_POP_DATA(parse &s)
{
    // nothing to do!
    s.debug("E_POP_DATA");
    auto l = s.pop_loop(LT_DATA);
    if( l.empty() )
        return false;
    s.emit_label(l);
    return true;
}

static bool SMB_E_POP_FOR(parse &s)
{
    // nothing to do!
    s.debug("E_POP_FOR");
    auto l1 = s.pop_loop(LT_FOR_2);
    auto l2 = s.pop_loop(LT_FOR_1);
    if( l1.empty() || l2.empty() )
        return false;
    s.remove_last();
    s.emit_word(l2);
    s.emit_label(l1);
    s.emit_label(l2 + "_x");
    return true;
}

static bool SMB_E_POP_REPEAT(parse &s)
{
    // nothing to do!
    s.debug("E_POP_REPEAT");
    auto l = s.pop_loop(LT_REPEAT);
    if( l.empty() )
        return false;
    s.emit_word(l);
    s.emit_label(l + "_x");
    return true;
}

static std::string last_var_name;
static bool SMB_E_VAR_CREATE(parse &s)
{
    s.debug("E_VAR_CREATE");
    auto &v = s.vars;
    std::string name;
    if( !s.get_ident(name) )
        return false;
    if( v.find(name) != v.end() )
        return false;
    auto v_num = v.size();
    v[name] = 0 + 256 * v_num;
    s.emit(std::to_string(v_num));
    last_var_name = name;
    return true;
}

static bool SMB_E_VAR_SET_TYPE(parse &s)
{
    s.debug("E_VAR_SET_TYPE");

    // Get type
    char type = get_vartype(s.remove_last());
    if( do_debug )
        std::cout << "\tset var '" << last_var_name << "' to " << int(type) << "\n";
    s.vars[last_var_name] = (s.vars[last_var_name] & ~0xFF) + type;
    return true;
}

static bool var_check(parse &s, int type)
{
    auto &v = s.vars;
    std::string name;
    if( !s.get_ident(name) )
        return false;
    if( v.find(name) == v.end() )
        return false;
    if( (v[name] & 0xFF) != type )
        return false;
    s.emit( std::to_string(v[name] >> 8) );
    return true;
}

static bool SMB_E_VAR_WORD(parse &s)
{
    s.debug("E_VAR_WORD");
    return var_check(s, VT_WORD);
}

static bool SMB_E_VAR_ARRAY_WORD(parse &s)
{
    s.debug("E_VAR_ARRAY_WORD");
    return var_check(s, VT_ARRAY_WORD);
}

static bool SMB_E_VAR_ARRAY_BYTE(parse &s)
{
    s.debug("E_VAR_ARRAY_BYTE");
    return var_check(s, VT_ARRAY_BYTE);
}

static bool SMB_E_VAR_STRING(parse &s)
{
    s.debug("E_VAR_STRING");
    return var_check(s, VT_STRING);
}

static bool SMB_E_LABEL_DEF(parse &s)
{
    s.debug("E_LABEL_DEF");
    auto &v = s.labels;
    std::string name;
    if( !s.get_ident(name) )
        return false;
    v[name] = 1;
    s.emit_label("proc_lbl_" + name);
    return true;
}

static bool SMB_E_LABEL(parse &s)
{
    s.debug("E_LABEL");
    auto &v = s.labels;
    std::string name;
    if( !s.get_ident(name) )
        return false;
    if( v.find(name) == v.end() )
        v[name] = 0;
    s.emit_word("proc_lbl_" + name);
    return true;
}

static bool SMB_E_END_PARSE(parse &s)
{
    s.debug("E_END_PARSE");
    return true;
}

#define COLOR   0x009F
#define IOCHN   0x00A0
#define COLOR0  0x02C4
#define ROWCRS  0x54
#define COLCRS  0x55
#define OPEN    0x03
#define AUDF1   0xD200
#define AUDCTL  0xD208
#define SKCTL   0xD20F

#include "basic.cc"


static bool readLine(std::string &r, std::istream &is)
{
 int c;
 while( -1 != (c = is.get()) )
 {
     if( c == '\n' || c == '\x9b' )
         return true;
     r += char(c);
 }
 return false;
}

// Implements a simple peephole optimizer
class peephole
{
    private:
        std::vector<parse::codew> &code;
        size_t current;
        // Matching functions for the peephole opt
        bool mtok(size_t idx, std::string name)
        {
            idx += current;
            return ( idx < code.size() &&
                     code[idx].type == parse::codew::tok &&
                     code[idx].value == name );
        }
        bool mword(size_t idx)
        {
            idx += current;
            if ( idx < code.size() && code[idx].type == parse::codew::word )
            {
                auto s = code[idx].value;
                return ( s.find_first_not_of("0123456789") == s.npos );
            }
            else
                return false;
        }
        bool mbyte(size_t idx)
        {
            idx += current;
            if ( idx < code.size() && code[idx].type == parse::codew::byte )
            {
                auto s = code[idx].value;
                return ( s.find_first_not_of("0123456789") == s.npos );
            }
            else
                return false;
        }
        int16_t val(size_t idx)
        {
            idx += current;
            if ( idx < code.size() &&
                 ( code[idx].type == parse::codew::word || code[idx].type == parse::codew::byte ) )
                return (int16_t)(std::stoul(code[idx].value));
            else
                return 0x8000;
        }
        void del(size_t idx)
        {
            code.erase( code.begin() + idx + current);
        }
        void set_w(size_t idx, int16_t x)
        {
            code[idx+current].type = parse::codew::word;
            code[idx+current].value = std::to_string(x);
        }
        void set_b(size_t idx, int16_t x)
        {
            code[idx+current].type = parse::codew::byte;
            code[idx+current].value = std::to_string(x & 0xFF);
        }
        void set_tok(size_t idx, std::string tok)
        {
            code[idx+current].type = parse::codew::tok;
            code[idx+current].value = tok;
        }
    public:
        peephole(std::vector<parse::codew> &code):
            code(code), current(0)
        {
            bool changed;
            do
            {
                changed = false;

                for(size_t i=0; i<code.size(); i++)
                {
                    current = i;
                    // Sequences:
                    //   TOK_NUM / x / TOK_USHL  -> TOK_NUM / 2*x
                    if( mtok(0,"TOK_NUM") && mword(1) && mtok(2,"TOK_USHL") )
                    {
                        del(2); set_w(1, 2 * val(1)); i--; changed = true;
                        continue;
                    }
                    //   TOK_NUM / x / TOK_SHL8  -> TOK_NUM / 256*x
                    if( mtok(0,"TOK_NUM") && mword(1) && mtok(2,"TOK_SHL8") )
                    {
                        del(2); set_w(1, 256 * val(1)); i--; changed = true;
                        continue;
                    }
                    //   TOK_NUM / x<256         -> TOK_BYTE / x
                    if( mtok(0,"TOK_NUM") && mword(1) && ( (val(1) & ~0xFF) ==  0) )
                    {
                        set_tok(0, "TOK_BYTE"); set_b(1, val(1)); i--; changed = true;
                        continue;
                    }
                    //   TOK_BYTE / x / TOK_SHL8  -> TOK_NUM / 256*x
                    if( mtok(0,"TOK_BYTE") && mbyte(1) && mtok(2,"TOK_SHL8") )
                    {
                        del(2); set_tok(0, "TOK_NUM"); set_w(1, 256 * val(1)); i--; changed = true;
                        continue;
                    }
                    //   TOK_BYTE / x / TOK_USHL  -> TOK_NUM / 2*x
                    if( mtok(0,"TOK_BYTE") && mbyte(1) && mtok(2,"TOK_USHL") )
                    {
                        del(2); set_tok(0, "TOK_NUM"); set_w(1, 2 * val(1)); i--; changed = true;
                        continue;
                    }
                    //   TOK_BYTE / 4 / TOK_MUL   -> TOK_USHL TOK_USHL
                    if( mtok(0,"TOK_BYTE") && mbyte(1) && val(1) == 4 && mtok(2,"TOK_MUL") )
                    {
                        del(2); set_tok(1, "TOK_USHL"); set_tok(0, "TOK_USHL"); i--; changed = true;
                        continue;
                    }
                    //   TOK_BYTE / 2 / TOK_MUL   -> TOK_USHL
                    if( mtok(0,"TOK_BYTE") && mbyte(1) && val(1) == 2 && mtok(2,"TOK_MUL") )
                    {
                        del(2); del(1); set_tok(0, "TOK_USHL"); i--; changed = true;
                        continue;
                    }
                    //   TOK_BYTE / 1 / TOK_MUL   -> -
                    if( mtok(0,"TOK_BYTE") && mbyte(1) && val(1) == 1 && mtok(2,"TOK_MUL") )
                    {
                        del(2); del(1); del(0); i--; changed = true;
                        continue;
                    }
                    //   TOK_BYTE / 1 / TOK_DIV   -> -
                    if( mtok(0,"TOK_BYTE") && mbyte(1) && val(1) == 1 && mtok(2,"TOK_DIV") )
                    {
                        del(2); del(1); del(0); i--; changed = true;
                        continue;
                    }
                    //   TOK_BYTE / 0 / TOK_ADD   -> -
                    if( mtok(0,"TOK_BYTE") && mbyte(1) && val(1) == 0 && mtok(2,"TOK_ADD") )
                    {
                        del(2); del(1); del(0); i--; changed = true;
                        continue;
                    }
                    //   TOK_BYTE / 0 / TOK_SUB   -> -
                    if( mtok(0,"TOK_BYTE") && mbyte(1) && val(1) == 0 && mtok(2,"TOK_SUB") )
                    {
                        del(2); del(1); del(0); i--; changed = true;
                        continue;
                    }
                    //   TOK_BYTE / 0 / TOK_NEQ   -> TOK_COMP_0
                    if( mtok(0,"TOK_BYTE") && mbyte(1) && val(1) == 0 && mtok(2,"TOK_NEQ") )
                    {
                        del(2); del(1); set_tok(0,"TOK_COMP_0"); i--; changed = true;
                        continue;
                    }
                    //   TOK_BYTE / 0 / TOK_EQ   -> TOK_COMP_0 TOK_L_NOT
                    if( mtok(0,"TOK_BYTE") && mbyte(1) && val(1) == 0 && mtok(2,"TOK_EQ") )
                    {
                        del(2); set_tok(0,"TOK_COMP_0"); set_tok(1, "TOK_L_NOT"); i--; changed = true;
                        continue;
                    }
                    //   TOK_BYTE / x / TOK_BYTE / y / TOK_ADD   -> TOK_NUM (x+y)
                    if( mtok(0,"TOK_BYTE") && mbyte(1) && mtok(2,"TOK_BYTE") && mbyte(3) && mtok(4,"TOK_ADD") )
                    {
                        set_tok(0, "TOK_NUM"); set_w(1, val(1)+val(3)); del(4); del(3); del(2); i--; changed = true;
                        continue;
                    }
                    //   TOK_NUM / x / TOK_NUM / y / TOK_ADD   -> TOK_NUM (x+y)
                    if( mtok(0,"TOK_NUM") && mword(1) && mtok(2,"TOK_NUM") && mword(3) && mtok(4,"TOK_ADD") )
                    {
                        set_tok(0, "TOK_NUM"); set_w(1, val(1)+val(3)); del(4); del(3); del(2); i--; changed = true;
                        continue;
                    }
                    //   TOK_BYTE / x / TOK_BYTE / y / TOK_SUB   -> TOK_NUM (x-y)
                    if( mtok(0,"TOK_BYTE") && mbyte(1) && mtok(2,"TOK_BYTE") && mbyte(3) && mtok(4,"TOK_SUB") )
                    {
                        set_tok(0, "TOK_NUM"); set_w(1, val(1)-val(3)); del(4); del(3); del(2); i--; changed = true;
                        continue;
                    }
                    //   TOK_NUM / x / TOK_NUM / y / TOK_SUB   -> TOK_NUM (x-y)
                    if( mtok(0,"TOK_NUM") && mword(1) && mtok(2,"TOK_NUM") && mword(3) && mtok(4,"TOK_SUB") )
                    {
                        set_tok(0, "TOK_NUM"); set_w(1, val(1)-val(3)); del(4); del(3); del(2); i--;
                        continue; changed = true;
                    }
                }
            } while(changed);
        }
};

static int show_version()
{
    std::cerr << "FastBasic - (c) 2017 dmsc\n";
    return 0;
}

static int show_help()
{
    show_version();
    std::cerr << "Usage: fastbasic [options] <input.bas> <output.asm>\n"
                 "\n"
                 "Options:\n"
                 " -d\tenable parser debug options (only useful to debug parser)\n"
                 " -v\tshow version and exit\n"
                 " -h\tshow this help\n";
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
    std::string iname;
    std::ifstream ifile;
    std::ofstream ofile;

    for(auto &arg: args)
    {
        if( arg == "-d" )
            do_debug = true;
        else if( arg == "-v" )
            return show_version();
        else if( arg == "-h" )
            return show_help();
        else if( arg.empty() )
            return show_error("invalid argument, try -h for help");
        else if( arg[0] == '-' )
            return show_error("invalid option '" + arg + "', try -h for help");
        else if( !ifile.is_open() )
        {
            ifile.open(arg);
            if( !ifile.is_open() )
                return show_error("can't open input file '" + arg + "'");
            iname = arg;
        }
        else if( !ofile.is_open() )
        {
            ofile.open(arg);
            if( !ofile.is_open() )
                return show_error("can't open output file '" + arg + "'");
        }
        else
            return show_error("too many arguments, try -h for help");
    }
    if( !ifile.is_open() )
        return show_error("missing input file name");

    if( !ofile.is_open() )
        return show_error("missing output file name");

    parse s;
    int ln = 0;
    while(1)
    {
        std::string line;
        if( !readLine(line, ifile) && line.empty() )
            break;
        ln++;
        if( do_debug )
            std::cerr << iname << ": parsing line " << ln << "\n";
        s.comment("LINE " + std::to_string(ln));
        s.new_line(line);
        if( !SMB_PARSE_START(s) )
        {
            std::cerr << iname << ":" << ln << ":" << s.max_pos << ": parse error\n";
            size_t min = 0, max = s.str.length();
            if( s.max_pos > 40 ) min = s.max_pos - 40;
            if( s.max_pos + 40 < max ) max = s.max_pos + 40;
            for(auto i = min; i<s.max_pos; i++)
                std::cerr << s.str[i];
            std::cerr << "<--- HERE -->";
            for(auto i = s.max_pos; i<max; i++)
                std::cerr << s.str[i];
            std::cerr << "\n";
            return 1;
        }
    }
    if( do_debug )
    {
        std::cerr << "parse end:\n";
        std::cerr << "MAX LEVEL: " << s.maxlvl << "\n";
    }

    s.emit("TOK_END");
    // Optimize
    peephole pp(s.code);

    // Write tokens
    ofile << "; TOKENS:\n";
    for(size_t i=0; i<sizeof(TOKENS)/sizeof(TOKENS[0]); i++)
        if( TOKENS[i] && *TOKENS[i] )
            ofile << TOKENS[i] << " = 2 * " << i << "\n";
    ofile << "TOK_END = 0\n\n"
             ";-----------------------------\n"
             "; Variables\n"
             "NUM_VARS = " << s.vars.size() << "\n"
             ";-----------------------------\n"
             "; Bytecode\n";
    for(auto c: s.code)
    {
        switch(c.type)
        {
            case parse::codew::tok:
                ofile << "\t.byte\t" << c.value << "\n";
                break;
            case parse::codew::byte:
                ofile << "\t.byte\t" << c.value << "\n";
                break;
            case parse::codew::word:
                ofile << "\t.word\t" << c.value << "\n";
                break;
            case parse::codew::label:
                ofile << c.value << ":\n";
                break;
            case parse::codew::comment:
                ofile << "; " << c.value << "\n";
                break;
        }
    }

    return 0;
}
