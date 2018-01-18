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
#include <cmath>
#include <vector>

enum VarType {
        VT_UNDEF = 0,
        VT_WORD,
        VT_ARRAY_WORD,
        VT_ARRAY_BYTE,
        VT_STRING,
        VT_FLOAT
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

// Atari FP number format
class atari_fp {
    private:
        double num;
        uint8_t exp;
        uint8_t mant[5];

        static const double expTab[99];
        std::string hex(uint8_t x) const {
            std::string ret(3,'$');
            static const char hd[17] = "0123456789ABCDEF";
            ret[1] = hd[x>>4];
            ret[2] = hd[x & 0xF];
            return ret;
        }
        uint8_t tobcd(int n) const {
            return (n/10)*16 + (n%10);
        }
        void update()
        {
            exp = num < 0 ? 0x80 : 0x00;
            double x = exp ? -num : num;
            mant[0] = mant[1] = mant[2] = mant[3] = mant[4] = 0;
            if( x < 1e-99 )
                return;
            if( x >= 1e+98 )
            {
                exp |= 0x71;
                mant[0] = mant[1] = mant[2] = mant[3] = mant[4] = 0x99;
                return;
            }
            exp |= 0x0E;
            for(int i=0; i<99; i++, exp++)
            {
                if( x < expTab[i] )
                {
                    uint64_t n = (uint64_t)std::llrint(x * 10000000000.0 / expTab[i]);
                    mant[4] = tobcd(n % 100); n /= 100;
                    mant[3] = tobcd(n % 100); n /= 100;
                    mant[2] = tobcd(n % 100); n /= 100;
                    mant[1] = tobcd(n % 100); n /= 100;
                    mant[0] = tobcd(n);
                    return;
                }
            }
        }
    public:
        atari_fp(double x): num(x) {}
        bool valid() const {
            return num >= -1E98 && num <= 1E98;
        }
        std::string to_asm() {
            update();
            return hex(exp) + ", " + hex(mant[0]) + ", " + hex(mant[1]) + ", " +
                   hex(mant[2]) + ", " + hex(mant[3]) + ", " + hex(mant[4]);
        }
};

const double atari_fp::expTab[99] = {
    1e-98, 1e-96, 1e-94, 1e-92, 1e-90, 1e-88, 1e-86, 1e-84, 1e-82, 1e-80,
    1e-78, 1e-76, 1e-74, 1e-72, 1e-70, 1e-68, 1e-66, 1e-64, 1e-62, 1e-60,
    1e-58, 1e-56, 1e-54, 1e-52, 1e-50, 1e-48, 1e-46, 1e-44, 1e-42, 1e-40,
    1e-38, 1e-36, 1e-34, 1e-32, 1e-30, 1e-28, 1e-26, 1e-24, 1e-22, 1e-20,
    1e-18, 1e-16, 1e-14, 1e-12, 1e-10, 1e-08, 1e-06, 1e-04, 1e-02, 1e+00,
    1e+02, 1e+04, 1e+06, 1e+08, 1e+10, 1e+12, 1e+14, 1e+16, 1e+18, 1e+20,
    1e+22, 1e+24, 1e+26, 1e+28, 1e+30, 1e+32, 1e+34, 1e+36, 1e+38, 1e+40,
    1e+42, 1e+44, 1e+46, 1e+48, 1e+50, 1e+52, 1e+54, 1e+56, 1e+58, 1e+60,
    1e+62, 1e+64, 1e+66, 1e+68, 1e+70, 1e+72, 1e+74, 1e+76, 1e+78, 1e+80,
    1e+82, 1e+84, 1e+86, 1e+88, 1e+90, 1e+92, 1e+94, 1e+96, 1e+98
};

static bool do_debug = false;

class parse {
    public:
        class codew {
            public:
                enum { tok, byte, word, label, fp } type;
                std::string value;
                int lnum;
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
            max_pos(0), label_num(0),
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

        void restore(saved_pos s)
        {
            if( pos > max_pos ) max_pos = pos;
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
        bool emit_word(std::string s)
        {
            codew c{ codew::word, s, linenum};
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

// Properties of variable types:
static bool var_type_is_array(enum VarType t)
{
    switch(t) {
        case VT_ARRAY_WORD:
        case VT_ARRAY_BYTE:
            return true;
        case VT_UNDEF:
        case VT_WORD:
        case VT_STRING:
        case VT_FLOAT:
            return false;
    }
    return false;
}

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
    if( t == "VT_FLOAT" )
        return VT_FLOAT;
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
        if( s.expect('.') ) // If ends in a DOT, it's a fp number
        {
            s.pos = start;
            return 65536;
        }
        auto sn = s.str.substr(start, s.pos - start);
        s.debug("(got '" + sn + "')");
        return std::stoul(sn);
    }
}

static atari_fp get_fp_number(parse &s)
{
    auto start = s.pos;

    // Optional sign
    s.expect('-');

    // Integer part
    while( s.range('0', '9') );

    // Optional dot
    if( s.expect('.') )
    {
        // Fractional part
        while( s.range('0', '9') );
    }

    // Optional exponent, only if any number before
    if( s.pos != start && s.expect('E') )
    {
        // Optional exponent sign
        if( !s.expect('-') )
            s.expect('+');
        // And up to two numbers
        s.range('0', '9');
        s.range('0', '9');
    }

    if( s.pos == start )
        return atari_fp(HUGE_VAL); // return invalid number

    auto sn = s.str.substr(start, s.pos - start);
    s.debug("(got '" + sn + "')");
    return atari_fp( std::stod(sn) );
}

static bool get_asm_word_constant(parse &s)
{
    auto start = s.pos;
    if( s.expect('@') )
    {
        std::string name;
        // Reads ASM constant
        if( s.get_ident(name) )
        {
            s.emit_word( name );
            s.skipws();
            return true;
        }
    }
    s.pos = start;
    return false;
}

static bool get_asm_byte_constant(parse &s)
{
    auto start = s.pos;
    if( s.expect('@') && s.expect('@') )
    {
        std::string name;
        // Reads ASM constant
        if( s.get_ident(name) )
        {
            s.emit( name );
            s.skipws();
            return true;
        }
    }
    s.pos = start;
    return false;
}

static bool SMB_E_NUMBER_WORD(parse &s)
{
    s.debug("E_NUMBER_WORD");
    s.skipws();
    if( get_asm_word_constant(s) )
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
    if( get_asm_byte_constant(s) )
        return true;
    auto num = get_number(s);
    if( num > 255 )
        return false;
    s.emit( std::to_string(num) );
    s.skipws();
    return true;
}

static bool SMB_E_NUMBER_FP(parse &s)
{
    s.debug("E_NUMBER_FP");
    s.skipws();
    auto num = get_fp_number(s);
    if( !num.valid() )
        return false;
    s.emit_fp( num );
    s.skipws();
    return true;
}

static bool SMB_E_EOL(parse &s)
{
    s.debug("E_EOL");
    return( s.eos() || s.peek('\'') || s.peek(':') || s.eol() );
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
        case LT_DATA:
            s.emit_word(l);
            break;
        case LT_EXIT:
        case LT_ELSE:
        case LT_ELIF:
        case LT_PROC_2:
        case LT_LAST_JUMP:
            break;
        case LT_PROC_1:
            // Optimize by switching codep
            s.remove_last();
            s.push_proc(l);
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
    s.pop_proc(l);
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
    auto l2 = s.pop_loop(LT_FOR_1);
    auto l1 = s.pop_loop(LT_FOR_2);
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
    enum VarType type = get_vartype(s.remove_last());
    auto &v = s.vars;
    if( do_debug )
        std::cout << "\tset var '" << last_var_name << "' to " << int(type) << "\n";
    v[last_var_name] = (v[last_var_name] & ~0xFF) + type;
    // If type is FLOAT, allocate two more invisible variables
    if( type == VT_FLOAT )
    {
        v[ "-fake-" + std::to_string(v.size()) ] = 0;
        v[ "-fake-" + std::to_string(v.size()) ] = 0;
    }
    // This rule only succeeds on array types (defined with "DIM"), other
    // variable types create the variable and then fail so the parser can retry
    // with the new created variable.
    return var_type_is_array(type);
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

static bool SMB_E_VAR_FP(parse &s)
{
    s.debug("E_VAR_FP");
    return var_check(s, VT_FLOAT);
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

#include "basic.cc"


static bool readLine(std::string &r, std::istream &is)
{
 int c;
 while( -1 != (c = is.get()) )
 {
     r += char(c);
     if( c == '\n' || c == '\x9b' )
         return true;
 }
 return false;
}

// Opcode statistics!
class opstat
{
    private:
        std::vector<parse::codew> &code;
        std::map<parse::codew, int> c1;
        std::map<std::pair<parse::codew, parse::codew>, int> c2;
    public:
        opstat(std::vector<parse::codew> &code):
            code(code)
        {
            parse::codew old{ parse::codew::byte, std::string() };
            for(auto &c: code)
            {
                if( c.type == parse::codew::tok )
                {
                    std::pair<parse::codew, parse::codew> p{c, old};
                    c1[c] ++;
                    if( old.type == parse::codew::tok )
                        c2[{c, old}]++;
                    old = c;
                }
                else if( c.type == parse::codew::byte && old.type == parse::codew::tok
                         && old.value == "TOK_BYTE" )
                    c1[old = { parse::codew::tok, "TOK_BYTE " + c.value }]++;
                else if( c.type == parse::codew::word && old.type == parse::codew::tok
                        && old.value == "TOK_NUM" )
                    c1[old = { parse::codew::tok, "TOK_NUM " + c.value }]++;
            }
            // Show results
            for(auto &c: c1)
                std::cerr << "\t" << c.second << "\t" << c.first.value << "\n";
            for(auto &c: c2)
                std::cerr << "\t" << c.second << "\t" << c.first.second.value << "\t" << c.first.first.value << "\n";
        }
};

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
        bool mcbyte(size_t idx, std::string name)
        {
            idx += current;
            return ( idx < code.size() &&
                     code[idx].type == parse::codew::byte &&
                     code[idx].value == name );
        }
        bool mcword(size_t idx, std::string name)
        {
            idx += current;
            return ( idx < code.size() &&
                     code[idx].type == parse::codew::word &&
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
        void ins(size_t idx)
        {
            int lnum = 0;
            if( code.size() > idx + current )
                lnum = code[idx+current].lnum;
            code.insert(code.begin() + idx + current, {parse::codew::tok, "invalid", lnum});
        }
        void set_w(size_t idx, int16_t x)
        {
            code[idx+current].type = parse::codew::word;
            code[idx+current].value = std::to_string(x & 0xFFFF);
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
        // Transforms all "numeric" tokens to TOK_NUM, so that the next phases can
        // optimize
        void expand_numbers()
        {
            for(size_t i=0; i<code.size(); i++)
            {
                current = i;
                // Sequences:
                //   TOK_BYTE / x
                if( mtok(0,"TOK_BYTE") && mbyte(1) )
                {
                    set_tok(0, "TOK_NUM"); set_w(1, val(1)); i++;
                }
                //   TOK_1
                else if( mtok(0,"TOK_1") )
                {
                    set_tok(0, "TOK_NUM"); ins(1); set_w(1, 1); i++;
                }
                //   TOK_0
                else if( mtok(0,"TOK_0") )
                {
                    set_tok(0, "TOK_NUM"); ins(1); set_w(1, 0); i++;
                }
                //   TOK_NUM / non numeric constant
                else if( mtok(0,"TOK_NUM") )
                {
                    if( mcword(1, "AUDF1") )       set_w(1, 0xD200);
                    else if( mcword(1, "AUDCTL") ) set_w(1, 0xD208);
                    else if( mcword(1, "SKCTL") )  set_w(1, 0xD20F);
                    else if( mcword(1, "COLOR0") ) set_w(1, 0x02C4);
                    else if( mcword(1, "PADDL0") ) set_w(1, 0x0270);
                    else if( mcword(1, "STICK0") ) set_w(1, 0x0278);
                    else if( mcword(1, "PTRIG0") ) set_w(1, 0x027C);
                    else if( mcword(1, "STRIG0") ) set_w(1, 0x0284);
                    else if( mcword(1, "CH") )     set_w(1, 0x02FC);
                    else if( mcword(1, "FILDAT") ) set_w(1, 0x02FD);
                }
            }
        }
        // Transforms small "numeric" tokens to TOK_BYTE, TOK_1 and TOK_0
        void shorten_numbers()
        {
            for(size_t i=0; i<code.size(); i++)
            {
                current = i;
                // Sequences:
                //   TOK_NUM / x == 0
                if( mtok(0,"TOK_NUM") && mword(1) && val(1) == 0 )
                {
                    del(1); set_tok(0, "TOK_0");
                }
                //   TOK_NUM / x == 1
                else if( mtok(0,"TOK_NUM") && mword(1) && val(1) == 1 )
                {
                    del(1); set_tok(0, "TOK_1");
                }
                //   TOK_NUM / x == -1
                else if( mtok(0,"TOK_NUM") && mword(1) && val(1) == -1 )
                {
                    set_tok(0, "TOK_1"); set_tok(1, "TOK_NEG");
                }
                //   TOK_NUM / x < 256
                else if( mtok(0,"TOK_NUM") && mword(1) && 0 == (val(1) & ~0xFF) )
                {
                    set_tok(0, "TOK_BYTE"); set_b(1, val(1));
                }
            }
        }
    public:
        peephole(std::vector<parse::codew> &code):
            code(code), current(0)
        {
            bool changed;
            expand_numbers();
            do
            {
                changed = false;

                for(size_t i=0; i<code.size(); i++)
                {
                    current = i;
                    // Sequences:
                    //   TOK_NUM / x / TOK_NEG  -> TOK_NUM / -x
                    if( mtok(0,"TOK_NUM") && mword(1) && mtok(2,"TOK_NEG") )
                    {
                        del(2); set_w(1, - val(1)); i--; changed = true;
                        continue;
                    }
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
                    //   TOK_NUM / 4 / TOK_MUL   -> TOK_USHL TOK_USHL
                    if( mtok(0,"TOK_NUM") && mword(1) && val(1) == 4 && mtok(2,"TOK_MUL") )
                    {
                        del(2); set_tok(1, "TOK_USHL"); set_tok(0, "TOK_USHL"); i--; changed = true;
                        continue;
                    }
                    //   TOK_NUM / 2 / TOK_MUL   -> TOK_USHL
                    if( mtok(0,"TOK_NUM") && mword(1) && val(1) == 2 && mtok(2,"TOK_MUL") )
                    {
                        del(2); del(1); set_tok(0, "TOK_USHL"); i--; changed = true;
                        continue;
                    }
                    //   TOK_NUM / 1 / TOK_MUL   -> -
                    if( mtok(0,"TOK_NUM") && mword(1) && val(1) == 1 && mtok(2,"TOK_MUL") )
                    {
                        del(2); del(1); del(0); i--; changed = true;
                        continue;
                    }
                    //   TOK_NUM / 1 / TOK_DIV   -> -
                    if( mtok(0,"TOK_NUM") && mword(1) && val(1) == 1 && mtok(2,"TOK_DIV") )
                    {
                        del(2); del(1); del(0); i--; changed = true;
                        continue;
                    }
                    //   TOK_NUM / 0 / TOK_ADD   -> -
                    if( mtok(0,"TOK_NUM") && mword(1) && val(1) == 0 && mtok(2,"TOK_ADD") )
                    {
                        del(2); del(1); del(0); i--; changed = true;
                        continue;
                    }
                    //   TOK_NUM / 0 / TOK_SUB   -> -
                    if( mtok(0,"TOK_NUM") && mword(1) && val(1) == 0 && mtok(2,"TOK_SUB") )
                    {
                        del(2); del(1); del(0); i--; changed = true;
                        continue;
                    }
                    //   TOK_NUM / 0 / TOK_NEQ   -> TOK_COMP_0
                    if( mtok(0,"TOK_NUM") && mword(1) && val(1) == 0 && mtok(2,"TOK_NEQ") )
                    {
                        del(2); del(1); set_tok(0,"TOK_COMP_0"); i--; changed = true;
                        continue;
                    }
                    //   TOK_BYTE / 0 / TOK_EQ   -> TOK_COMP_0 TOK_L_NOT
                    if( mtok(0,"TOK_NUM") && mword(1) && val(1) == 0 && mtok(2,"TOK_EQ") )
                    {
                        del(2); set_tok(0,"TOK_COMP_0"); set_tok(1, "TOK_L_NOT"); i--; changed = true;
                        continue;
                    }
                    //   TOK_NUM / x / TOK_NUM / y / TOK_ADD   -> TOK_NUM (x+y)
                    if( mtok(0,"TOK_NUM") && mword(1) && mtok(2,"TOK_NUM") && mword(3) && mtok(4,"TOK_ADD") )
                    {
                        set_tok(0, "TOK_NUM"); set_w(1, val(1)+val(3)); del(4); del(3); del(2); i--; changed = true;
                        continue;
                    }
                    //   TOK_NUM / x / TOK_NUM / y / TOK_SUB   -> TOK_NUM (x-y)
                    if( mtok(0,"TOK_NUM") && mword(1) && mtok(2,"TOK_NUM") && mword(3) && mtok(4,"TOK_SUB") )
                    {
                        set_tok(0, "TOK_NUM"); set_w(1, val(1)-val(3)); del(4); del(3); del(2); i--;
                        continue; changed = true;
                    }
                    //   TOK_NUM / x / TOK_NUM / y / TOK_MUL   -> TOK_NUM (x*y)
                    if( mtok(0,"TOK_NUM") && mword(1) && mtok(2,"TOK_NUM") && mword(3) && mtok(4,"TOK_MUL") )
                    {
                        set_tok(0, "TOK_NUM"); set_w(1, val(1) * val(3)); del(4); del(3); del(2); i--; changed = true;
                        continue;
                    }
                    //   TOK_NUM / x / TOK_NUM / y / TOK_DIV   -> TOK_NUM (x/y)
                    if( mtok(0,"TOK_NUM") && mword(1) && mtok(2,"TOK_NUM") && mword(3) && mtok(4,"TOK_DIV") )
                    {
                        int16_t div = val(3);
                        if( div )
                            div = val(1) / div;
                        else if( val(1) < 0 )
                            div = 1;  // Probably a bug in the division routine, but we emulate the result
                        else
                            div = -1;
                        set_tok(0, "TOK_NUM"); set_w(1, div); del(4); del(3); del(2); i--;
                        continue; changed = true;
                    }
                    //   TOK_NUM / x / TOK_NUM / y / TOK_MOD   -> TOK_NUM (x%y)
                    if( mtok(0,"TOK_NUM") && mword(1) && mtok(2,"TOK_NUM") && mword(3) && mtok(4,"TOK_MOD") )
                    {
                        int16_t div = val(3);
                        if( div )
                            div = val(1) % div;
                        else
                            div = val(1);  // Probably a bug in the division routine, but we emulate the result
                        set_tok(0, "TOK_NUM"); set_w(1, div); del(4); del(3); del(2); i--;
                        continue; changed = true;
                    }
                    //   TOK_NUM / x / TOK_NUM / y / TOK_BIT_AND   -> TOK_NUM (x&y)
                    if( mtok(0,"TOK_NUM") && mword(1) && mtok(2,"TOK_NUM") && mword(3) && mtok(4,"TOK_BIT_AND") )
                    {
                        set_tok(0, "TOK_NUM"); set_w(1, val(1) & val(3)); del(4); del(3); del(2); i--; changed = true;
                        continue;
                    }
                    //   TOK_NUM / x / TOK_NUM / y / TOK_BIT_OR   -> TOK_NUM (x|y)
                    if( mtok(0,"TOK_NUM") && mword(1) && mtok(2,"TOK_NUM") && mword(3) && mtok(4,"TOK_BIT_OR") )
                    {
                        set_tok(0, "TOK_NUM"); set_w(1, val(1) | val(3)); del(4); del(3); del(2); i--; changed = true;
                        continue;
                    }
                    //   TOK_NUM / x / TOK_NUM / y / TOK_BIT_EXOR   -> TOK_NUM (x^y)
                    if( mtok(0,"TOK_NUM") && mword(1) && mtok(2,"TOK_NUM") && mword(3) && mtok(4,"TOK_BIT_EXOR") )
                    {
                        set_tok(0, "TOK_NUM"); set_w(1, val(1) ^ val(3)); del(4); del(3); del(2); i--; changed = true;
                        continue;
                    }
                    //  VAR + VAR    ==>   2 * VAR
                    //   TOK_VAR / x / TOK_VAR / x / TOK_ADD   -> TOK_VAR / x / TOK_USHL
                    if( mtok(0,"TOK_VAR_LOAD") && mbyte(1) && mtok(2,"TOK_VAR_LOAD") && mbyte(3) && mtok(4,"TOK_ADD") && val(1) == val(3) )
                    {
                        set_tok(2, "TOK_USHL"); del(4); del(3); i--; changed = true;
                        continue;
                    }
                    //  VAR = VAR + 1   ==>  INC VAR
                    //   TOK_VAR_A / x / TOK_VAR / x / TOK_NUM / 1 / TOK_ADD / TOK_DPOKE
                    //        -> TOK_VAR_A / x / TOK_INC
                    if( mtok(0,"TOK_VAR_ADDR") && mbyte(1) &&
                        mtok(2,"TOK_VAR_LOAD") && mbyte(3) &&
                        mtok(4,"TOK_NUM") && mword(5) && val(5) == 1 &&
                        mtok(6,"TOK_ADD") && mtok(7,"TOK_DPOKE") &&
                        val(1) == val(3) )
                    {
                        set_tok(2, "TOK_INC"); del(7); del(6); del(5); del(4); del(3); i--; changed = true;
                        continue;
                    }
                    //  VAR = VAR - 1   ==>  DEC VAR
                    //   TOK_VAR_A / x / TOK_VAR / x / TOK_NUM / 1 / TOK_SUB / TOK_DPOKE
                    //        -> TOK_VAR_A / x / TOK_DEC
                    if( mtok(0,"TOK_VAR_ADDR") && mbyte(1) &&
                        mtok(2,"TOK_VAR_LOAD") && mbyte(3) &&
                        mtok(4,"TOK_NUM") && mword(5) && val(5) == 1 &&
                        mtok(6,"TOK_SUB") && mtok(7,"TOK_DPOKE") &&
                        val(1) == val(3) )
                    {
                        set_tok(2, "TOK_DEC"); del(7); del(6); del(5); del(4); del(3); i--; changed = true;
                        continue;
                    }
                    //   TOK_BYTE / IOCHN / TOK_NUM / 0 / TOK_POKE  -> TOK_IOCHN0
                    if( mtok(0,"TOK_BYTE") && mcbyte(1, "IOCHN") &&
                        mtok(2,"TOK_NUM") && mword(3) && val(3) == 0 && mtok(4,"TOK_POKE") )
                    {
                        set_tok(0, "TOK_IOCHN0"); del(4); del(3); del(2); del(1); i--; changed = true;
                        continue;
                    }
                }
            } while(changed);
            shorten_numbers();
        }
};

static int show_version()
{
    std::cerr << "FastBasic r2 - (c) 2017 dmsc\n";
    return 0;
}

static int show_help()
{
    show_version();
    std::cerr << "Usage: fastbasic [options] <input.bas> <output.asm>\n"
                 "\n"
                 "Options:\n"
                 " -d\tenable parser debug options (only useful to debug parser)\n"
                 " -prof\tshow token usage statistics\n"
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
    bool show_stats = false;

    for(auto &arg: args)
    {
        if( arg == "-d" )
            do_debug = true;
        else if( arg == "-prof" )
            show_stats = true;
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
        s.new_line(line, ln);
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
    peephole pp(s.full_code());
    // Statistics
    if( show_stats )
        opstat op(s.full_code());

    // Write global symbols
    for(auto &c: s.full_code())
    {
        if( c.type == parse::codew::word && c.value[0] >= 'A' && c.value[0] <= '_' )
            ofile << "\t.global " << c.value << "\n";
        else if( c.type == parse::codew::byte && c.value[0] >= 'A' && c.value[0] <= '_' )
            ofile << "\t.globalzp " << c.value << "\n";
    }
    // Export common symbols and include atari defs
    ofile << "\t.export bytecode_start\n"
             "\t.exportzp NUM_VARS\n"
             "\n\t.include \"atari.inc\"\n\n";

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
             "; Bytecode\n"
             "bytecode_start:\n";
    ln = -1;;
    for(auto c: s.full_code())
    {
        if( c.lnum != ln )
        {
            ln = c.lnum;
            ofile << "; LINE " << ln << "\n";
        }
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
            case parse::codew::fp:
                ofile << "\t.byte\t" << c.value << "\n";
                break;
            case parse::codew::label:
                ofile << c.value << ":\n";
                break;
        }
    }

    return 0;
}
