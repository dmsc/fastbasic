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

// parser.cc: C++ parser

#include "parser.h"
#include "ifile.h"
#include "vartype.h"

#include <algorithm>

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
        // Skip initial "-"
        s.expect('-');

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
        if( sn.length() && sn[0] == '-' )
            return 65536 - std::stoul(sn.substr(1));
        else
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
        if( s.expect('"') && !s.peek('"') )
        {
            return true;
        }
        char c = s.str[s.pos];
        str += c;
        s.pos++;
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
        s.pos++;
    return true;
}

bool SMB_E_EOL(parse &s)
{
    s.debug("E_EOL");
    s.skipws();
    if( s.expect('\'') )
        return SMB_E_REM(s);
    return( s.eos() || s.peek(':') || s.eol() );
}

bool SMB_E_PUSH_VAR(parse &s)
{
    // nothing to do!
    s.debug("E_PUSH_VAR");
    s.sto_var = s.remove_last().get_val();
    return true;
}

bool SMB_E_POP_VAR(parse &s)
{
    s.debug("E_POP_VAR");
    if (s.sto_var < 0)
    {
        s.debug("---------->ERROR: no variable stored!\n");
        return false;
    }
    s.emit_byte( s.sto_var );
    s.sto_var = -1;
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
    s.emit_byte(v_num);
    last_var_name = name;
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
    s.emit_byte( v[name] >> 8 );
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
static atari_fp get_fp_number(parse &s)
{
    auto start = s.pos;
    bool ok = false;

    // Optional sign
    s.expect('-');

    // Integer part
    while( s.range('0', '9') )
        ok = true;

    // Optional dot
    if( s.expect('.') )
    {
        // Fractional part
        while( s.range('0', '9') )
            ok = true;
    }

    if( !ok )
        return atari_fp(HUGE_VAL); // return invalid number

    // Optional exponent, only if any number before
    auto spos = s.save();
    if( s.expect('E') && // "E"
        (s.expect('-') || s.expect('+') || ok) && // '+' or '-' or nothing
        s.range('0', '9') ) // One figit
    {
        // Optional second digit
        s.range('0', '9');
    }
    else
        s.restore(spos);

    auto sn = s.str.substr(start, s.pos - start);
    s.debug("(got '" + sn + "')");
    return atari_fp( std::stod(sn) );
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

static std::string last_label_name;
bool SMB_E_LABEL_DEF(parse &s)
{
    s.debug("E_LABEL_DEF");
    auto &v = s.labels;
    std::string name;
    if( !s.get_ident(name) )
        return false;
    v[name] = VT_UNDEF;
    last_label_name = name;
    s.emit_label("fb_lbl_" + name);
    return true;
}

bool SMB_E_LABEL(parse &s)
{
    s.debug("E_LABEL");
    // Get type
    enum VarType type = get_vartype(s.remove_last().get_str());
    auto &v = s.labels;
    std::string name;
    if( !s.get_ident(name) )
        return false;
    if ( v.find(name) == v.end() )
    {
        if ( type != VT_UNDEF )
            return false;
        v[name] = VT_UNDEF;
    }
    // Check type
    if( v[name] != type )
        return false;
    s.emit_word("fb_lbl_" + name);
    return true;
}

bool SMB_E_LABEL_SET_TYPE(parse &s)
{
    s.debug("E_LABEL_SET_TYPE");

    s.skipws();
    // Get type
    enum VarType type = get_vartype(s.remove_last().get_str());
    auto &v = s.labels;
    if( do_debug )
        std::cout << "\tset label '" << last_label_name << "' to " << int(type) << "\n";
    v[last_label_name] = (v[last_label_name] & ~0xFF) + type;
    return true;
}

// Reads a DATA array from a file
bool SMB_E_DATA_FILE(parse &s)
{
    s.debug("E_DATA_FILE");
    s.skipws();
    // Get file name until the '"'
    std::string fname;
    if( !get_const_string(s, fname) )
        return false;

    auto f = open_include_file(s.in_fname, fname);
    if( !f )
    {
        std::cerr << s.in_fname << ":" << s.linenum << ":" << s.pos
                  << ": can't open data file '" << fname << "'";
        return false;
    }

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
