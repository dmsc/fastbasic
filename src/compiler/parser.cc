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

// parser.cc: C++ parser

#include <string>

#include "codew.h"

class parse {
    public:
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
                if( type == LT_ELSE || type == LT_ELIF )
                    type = LT_IF;
                loop_error("missing " + get_loop_name(type));
                return std::string();
            }
            auto last = jumps.back();
            if( last.type != type )
            {
                if( type !=  LT_ELSE || last.type != LT_IF )
                {
                    if( type == LT_ELSE || type == LT_ELIF )
                        type = LT_IF;
                    loop_error("missing " + get_loop_name(type));
                    return std::string();
                }
            }
            auto lbl = last.label;
            jumps.pop_back();
            return lbl;
        }
        std::string check_loops()
        {
            // Checks that there are no unclosed loops at the end
            // of compilation.
            if( !jumps.size() )
                return std::string();
            for( ; jumps.size(); jumps.pop_back() )
            {
                auto type = jumps.back().type;
                if( type != LT_EXIT )
                    return "unclosed " + get_loop_name(type);
            }
            return "EXIT without loop";
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
                current_error = "expected " + str;
                debug( "Set error='" + current_error + "'" );
            }
        }

        bool loop_error(std::string str)
        {
            current_error = str;
            saved_error = current_error;
            debug( "Set loop error='" + current_error + "'" );
            return false;
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
                if( (str[pos] == '\x9B') || // AT-ASCII EOL
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
            code->push_back(codew::cword(s, linenum));
            return true;
        }
        bool emit_word(int x)
        {
            code->push_back(codew::cword(x, linenum));
            return true;
        }
        bool emit_fp(atari_fp x)
        {
            code->push_back(codew::cfp(x, linenum));
            return true;
        }
        bool emit_label(std::string s)
        {
            code->push_back(codew::clabel(s, linenum));
            return true;
        }
        bool emit_tok(enum tokens tk)
        {
            code->push_back(codew::ctok(tk, linenum));
            return true;
        }
        bool emit_str(std::string s)
        {
            code->push_back(codew::cstring(s, linenum));
            return true;
        }
        bool emit_byte(std::string s)
        {
            code->push_back(codew::cbyte(s, linenum));
            return true;
        }
        bool emit_byte(int x)
        {
            code->push_back(codew::cbyte(x, linenum));
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
                if( !p.size() || !p.back().is_tok(TOK_END) )
                    p.push_back(codew::ctok(TOK_END,0));
                for(auto &c: procs)
                    if( !c.first.empty() )
                        p.insert(std::end(p), std::begin(c.second), std::end(c.second));
            }
            return p;
        }
        std::vector<enum tokens> used_tokens()
        {
            auto code = full_code();
            std::set<enum tokens> set;
            for(auto &c: code)
            {
                if( c.is_tok() )
                    set.insert(c.get_tok());
            }
            std::vector<enum tokens> ret;
            for(auto &t: set)
                ret.push_back(t);
            return ret;
        }
};

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
            s.emit_byte( name );
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
    s.emit_word( num );
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
    s.emit_byte( num );
    s.skipws();
    return true;
}

static bool SMB_E_EOL(parse &s)
{
    s.debug("E_EOL");
    s.skipws();
    return( s.eos() || s.peek('\'') || s.peek(':') || s.eol() );
}

static bool SMB_E_CONST_STRING(parse &s)
{
    s.debug("E_CONST_STRING");
    std::string str;
    while( !s.eos() )
    {
        if( s.expect('"') && !s.peek('"') )
        {
            s.emit_str(str);
            return true;
        }
        char c = s.str[s.pos];
        str += c;
        s.pos++;
    }
    return false;
}

static bool SMB_E_REM(parse &s)
{
    s.debug("E_REM");
    while( !s.eos() && !s.expect('\n') && !s.expect('\x9b') )
        s.pos++;
    return true;
}

static bool SMB_E_PUSH_LT(parse &s)
{
    // nothing to do!
    s.debug("E_PUSH_LT");
    auto t = get_looptype(s.remove_last().get_str());
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
            return s.loop_error("EXIT without loop");
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
    s.emit_byte(v_num);
    last_var_name = name;
    return true;
}

static bool SMB_E_VAR_SET_TYPE(parse &s)
{
    s.debug("E_VAR_SET_TYPE");

    // Get type
    enum VarType type = get_vartype(s.remove_last().get_str());
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
    s.emit_byte( v[name] >> 8 );
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

static bool SMB_E_VAR_ARRAY_STRING(parse &s)
{
    s.debug("E_VAR_ARRAY_STRING");
    return var_check(s, VT_ARRAY_STRING);
}

static bool SMB_E_VAR_STRING(parse &s)
{
    s.debug("E_VAR_STRING");
    return var_check(s, VT_STRING);
}

#ifdef FASTBASIC_FP
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

static bool SMB_E_VAR_FP(parse &s)
{
    s.debug("E_VAR_FP");
    return var_check(s, VT_FLOAT);
}
#endif

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

