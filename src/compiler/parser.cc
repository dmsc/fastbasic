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

// parser.cc: C++ parser

#include "parser.h"
#include "ifile.h"
#include "vartype.h"

#include <algorithm>
#include <cmath>

static unsigned long get_hex(parse &s)
{
    unsigned num = 0;
    auto start = s.pos;
    while( s.pos < s.str.length() )
    {
        char c = s.str[s.pos];
        if( c >= '0' && c <= '9' )
            num = num * 16 + (c - '0');
        else if( c >= 'a' && c <= 'f' )
            num = num * 16 + 10 + (c - 'a');
        else if( c >= 'A' && c <= 'F' )
            num = num * 16 + 10 + (c - 'A');
        else
            break;
        s.pos ++;
        if( num > 0xFFFF )
            return num;
    }
    if( s.pos == start )
        return 65536;   // No digits: error
    return num;
}

static unsigned long get_dec(parse &s)
{
    unsigned num = 0;
    auto start = s.pos;
    while( s.pos < s.str.length() )
    {
        char c = s.str[s.pos];
        if( c >= '0' && c <= '9' )
            num = num * 10 + (c - '0');
        else
            break;
        s.pos ++;
        if( num > 0xFFFF )
            return num;
    }
    if( s.pos == start )
        return 65536;   // No digits: error
    return num;
}

static unsigned long get_number(parse &s)
{
    auto start = s.pos;
    if( s.expect('$') )
    {
        s.debug("(hex)");
        auto h = get_hex(s);
        if( h > 65535 )
            return 65536;

        s.debug("(got '" + std::to_string(h) + "')");
        std::string sn = "$";
        if( h > 255 )
        {
            sn += s.hexd(h>>12);
            sn += s.hexd(h>>8);
        }
        sn += s.hexd(h>>4);
        sn += s.hexd(h);
        s.add_text( sn );
        return h;
    }
    else
    {
        bool sign = s.expect('-');
        int num = get_dec(s);

        if( num > 65535 || num < 0 )
            return 65536;

        if( s.expect('.') ) // If ends in a DOT, it's a fp number
        {
            s.pos = start;
            return 65536;
        }

        auto sn = std::to_string( sign ? -num : num );
        s.debug("(got '" + sn + "')");
        s.add_text( sn );
        if( sign )
            return 65536 - num;
        else
            return num;
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
            s.add_text( "@" + name );
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
            s.add_text( "@@" + name );
            s.emit_byte( name );
            s.skipws();
            return true;
        }
    }
    s.pos = start;
    return false;
}

bool SMB_E_NUMBER_WORD(parse &s)
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

bool SMB_E_NUMBER_BYTE(parse &s)
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

static bool get_const_string(parse &s, std::string &str)
{
    while( !s.eos() )
    {
        if( s.expect('"') )
        {
            if( s.expect('"') )
                str += '"';
            else if( s.expect('$') )
            {
                do
                {
                    auto c = get_hex(s);
                    if( c > 255 )
                        return false;
                    str += char(c);
                } while(s.expect('$'));
                if( !s.expect('"') )
                {
                    s.add_text_str(str);
                    return true;
                }
            }
            else
            {
                s.add_text_str(str);
                return true;
            }
        }
        else
        {
            str += char(s.str[s.pos]);
            s.pos++;
        }
    }
    return false;
}

bool SMB_E_CONST_STRING(parse &s)
{
    s.debug("E_CONST_STRING");
    std::string str;
    if( get_const_string(s, str) )
        return s.emit_str(str);
    return false;
}

bool SMB_E_REM(parse &s)
{
    s.debug("E_REM");
    while( !s.eos() && !s.expect('\n') && !s.expect('\x9b') )
    {
        s.expand.text.push_back(s.str[s.pos]);
        s.pos++;
    }
    return true;
}

bool SMB_E_EOL(parse &s)
{
    s.debug("E_EOL");
    s.skipws();
    if( s.expect('\'') )
    {
        s.add_text("\'");
        return SMB_E_REM(s);
    }
    return( s.eos() || s.peek(':') || s.eol() );
}

bool SMB_E_PUSH_VAR(parse &s)
{
    // nothing to do!
    s.debug("E_PUSH_VAR");
    s.var_stk.push_back(s.remove_last());
    return true;
}

bool SMB_E_POP_VAR(parse &s)
{
    s.debug("E_POP_VAR");
    if (s.var_stk.empty())
        throw parse_error("variable stack empty", s.pos);
    s.code->push_back(s.var_stk.back());
    s.var_stk.pop_back();
    return true;
}

bool SMB_E_PUSH_LT(parse &s)
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
            s.emit_word(l);
            break;
        case LT_EXIT:
        case LT_ELSE:
        case LT_ELIF:
        case LT_PROC_2:
        case LT_LAST_JUMP:
            break;
        case LT_PROC_DATA:
            // Optimize by switching codep
            s.remove_last();
            s.push_proc(l);
            break;
    }
    return true;
}

bool SMB_E_POP_LOOP(parse &s)
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

bool SMB_E_POP_WHILE(parse &s)
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

bool SMB_E_POP_IF(parse &s)
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

bool SMB_E_ELSEIF(parse &s)
{
    // nothing to do!
    s.debug("E_ELSEIF");
    auto l1 = s.pop_loop(LT_IF);
    if( l1.empty() )
        return false;
    auto t = get_looptype(s.remove_last().get_str());
    auto l2 = s.push_loop(t);
    s.emit_word(l2);
    s.emit_label(l1);
    return true;
}

bool SMB_E_EXIT_LOOP(parse &s)
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

bool SMB_E_POP_PROC_DATA(parse &s)
{
    // nothing to do!
    s.debug("E_POP_PROC_DATA");
    auto l = s.pop_loop(LT_PROC_DATA);
    if( l.empty() )
        return false;
    s.pop_proc(l);
    return true;
}

bool SMB_E_POP_PROC_2(parse &s)
{
    // nothing to do!
    s.debug("E_POP_PROC_2");
    auto l = s.pop_loop(LT_PROC_2);
    if( l.empty() )
        return false;
    s.emit_label(l + "_x");
    return true;
}

bool SMB_E_POP_FOR(parse &s)
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

bool SMB_E_POP_REPEAT(parse &s)
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
bool SMB_E_VAR_CREATE(parse &s)
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
    s.emit_varn(name);
    last_var_name = name;
    s.add_text( name );
    return true;
}

bool SMB_E_VAR_SET_TYPE(parse &s)
{
    s.debug("E_VAR_SET_TYPE");

    s.skipws();
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

bool var_check(parse &s, int type)
{
    auto &v = s.vars;
    std::string name;
    if( !s.get_ident(name) )
        return false;
    if( v.find(name) == v.end() )
        return false;
    if( (v[name] & 0xFF) != type )
        return false;
    s.add_text(name);
    s.emit_varn(name);
    return true;
}

bool SMB_E_VAR_WORD(parse &s)
{
    s.debug("E_VAR_WORD");
    return var_check(s, VT_WORD);
}

bool SMB_E_VAR_SEARCH(parse &s)
{
    enum VarType type = get_vartype(s.remove_last().get_str());
    s.debug("E_VAR_SEARCH: " + get_vt_name(type));
    return var_check(s, type);
}

#ifdef FASTBASIC_FP
// Get optional exponent for FP number
static int parse_fp_exp(parse &s)
{
    auto spos = s.save();
    if( s.expect('E') )
    {
        // Expect either a '-' or a '+'
        int exp = 0;
        bool esign = s.expect('-') || (s.expect('+') , false);
        if ( s.range('0', '9') )
        {
            exp = s.str[s.pos-1] - '0';
            if ( s.range('0', '9') )
                exp = exp * 10 + s.str[s.pos-1] - '0';
            return esign ? -exp : exp;
        }
    }
    s.restore(spos);
    return 0;
}

static atari_fp get_fp_number(parse &s)
{
    // Optional sign
    bool sign = s.expect('-');

    // Get all digits:
    bool ok = false;
    double num = 0;
    int dot = -1, norm = 0;
    while( s.pos < s.str.length() )
    {
        char c = s.str[s.pos];
        if( c >= '0' && c <= '9' )
        {
            num = num * 10 + (c - '0');
            // Normalize numbers too big
            if( num > 1e30 )
            {
                num = num / 1000;
                norm += 3;
            }
            ok = true;
        }
        else if( c == '.' )
            dot = s.pos + 1;
        else
            break;
        s.pos ++;
    }
    if( !ok )
        return atari_fp(HUGE_VAL); // return invalid number

    // Calculate dot exponent
    dot = dot >= 0 ? s.pos - dot : 0;

    // Optional exponent and resulting number
    num = num * std::pow(10, parse_fp_exp(s) - dot + norm);
    num = sign ? -num : num;

    auto fp = atari_fp(num);
    auto sn = fp.to_string();
    s.debug("(got '" + sn + "')");
    s.add_text(sn);
    return fp;
}

bool SMB_E_NUMBER_FP(parse &s)
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

#endif

bool SMB_E_LABEL_DEF(parse &s)
{
    auto l = s.push_loop(LT_PROC_DATA);
    s.remove_last();
    s.push_proc(l);

    s.debug("E_LABEL_DEF");
    auto &v = s.labels;
    auto name = s.last_label;
    if( v[name].is_defined() )
        return false;
    s.current_params = 0;
    s.add_text(name);
    s.emit_label("fb_lbl_" + name);
    return true;
}

bool SMB_E_LABEL(parse &s)
{
    s.debug("E_LABEL");
    // Get type
    auto ltype = labelType(s.remove_last().get_str());
    // Get identifier
    std::string name;
    if( !s.get_ident(name) )
        return false;
    auto it = s.labels.find(name);
    if( it == s.labels.end() )
        return false;
    // Check type
    if( it->second != ltype )
        return false;
    s.add_text(name);
    s.emit_word("fb_lbl_" + name);
    return true;
}

bool SMB_E_COUNT_PARAM(parse &s)
{
    s.debug("E_COUNT_PARAM");
    s.current_params ++;
    return false;
}

// Called in EXEC, creates a label if not exists, if already exists checks
// that it is a PROC.
bool SMB_E_LABEL_CREATE(parse &s)
{
    s.debug("E_LABEL_CREATE");
    std::string name;
    if( !s.get_ident(name) )
        return false;
    // Get type, create if not exists
    auto &v = s.labels[name];
    // Check type
    if( !v.is_proc() )
        return false;
    // Store variable name
    s.add_text(name);
    s.last_label = name;
    s.current_params = 0;
    return true;
}

bool SMB_E_DO_EXEC(parse &s)
{
    int pnum = s.current_params;
    s.debug("E_DO_EXEC");
    auto &l = s.labels[s.last_label];
    if( !l.add_proc_params(pnum) )
        throw parse_error("invalid number of parameters in EXEC, expected " +
                std::to_string(l.num_params()) + ", got "
                + std::to_string(pnum) , s.pos);
    s.emit_word("fb_lbl_" + s.last_label);
    return true;
}

bool SMB_E_PROC_CHECK(parse &s)
{
    int pnum = s.current_params - 1;
    s.debug("E_PROC_CHECK");
    auto &l = s.labels[s.last_label];
    if( !l.add_proc_params(pnum) )
        throw parse_error("invalid number of parameters in PROC, expected " +
                std::to_string(l.num_params()) + ", got "
                + std::to_string(pnum) , s.pos);
    l.define();
    return true;
}

bool SMB_E_LABEL_SET_TYPE(parse &s)
{
    s.debug("E_LABEL_SET_TYPE");
    s.skipws();
    // Get type
    s.labels[s.last_label] = labelType(s.remove_last().get_str());
    return true;
}

// Reads a DATA array from a file
bool SMB_E_DATA_FILE(parse &s)
{
    s.debug("E_DATA_FILE");
    s.skipws();
    // Get file name until the '"'
    std::string fname;
    auto pos = s.pos;
    if( !get_const_string(s, fname) )
        return false;

    auto f = open_include_file(s.in_fname, fname);
    if( !f )
        throw parse_error("can't open data file '" + fname + "'", pos);

    // Read the file to a buffer of max 64k
    for(unsigned i=0; i<65536; i++)
    {
        int c = f->get();
        if( c < 0 || c > 255 )
            break;
        s.emit_byte( c );
    }
    return true;
}
