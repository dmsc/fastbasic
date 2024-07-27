/*
 * FastBasic - Fast basic interpreter for the Atari 8-bit computers
 * Copyright (C) 2017-2024 Daniel Serpell
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

// parser-actions.cc: parser functions called from the parsing tables
#include "parser.h"
#include "synt-sm-list.h"
#include <stdexcept>

using namespace syntax;
using dcode = statemachine::dcode;

static const syntax::statemachine &get(const sm_list &sl, std::string name)
{
    auto smi = sl.sms.find(name);
    if(smi == sl.sms.end())
        throw std::runtime_error("missing syntax table for '" + name + "'");
    return *(smi->second);
}

static bool parse_table(parse &s, const sm_list &sl, std::string name);

static void emit_bytes(parse &s, const std::vector<dcode> &data)
{
    for(auto &c : data)
    {
        switch(c.type)
        {
        case dcode::d_word_sym:
            s.emit_word(c.str);
            break;
        case dcode::d_word_val:
            s.emit_word(c.num);
            break;
        case dcode::d_byte_sym:
            s.emit_byte(c.str);
            break;
        case dcode::d_byte_val:
            s.emit_byte(c.num);
            break;
        case dcode::d_token:
            s.emit_tok(c.str);
            break;
        }
    }
}

static std::string ucase(std::string s)
{
    for(auto &c : s)
    {
        if(c >= 'a' && c <= 'z')
            c = c - 'a' + 'A';
    }
    return s;
}

static bool parse_literal(parse &s, std::string lit)
{
    s.error("'" + ucase(lit) + "'");
    for(auto ch : lit)
    {
        if(ch >= 'a' && ch <= 'z')
        {
            ch = ch - 'a' + 'A';
            if(!s.expect(ch))
            {
                if(!s.expect('.'))
                    return false;
                else
                    break;
            }
        }
        else if(!s.expect(ch))
            return false;
    }
    s.debug("GOT '" + lit + "'");
    s.add_text(ucase(lit));
    // Convert some simple alternatives
    if(lit == "EXEc")
        lit = "@";
    else if(lit == "PRInt")
        lit = "?";
    else if(lit == "ADR(")
    {
        lit = "&";
        s.expand.remove_parens++;
    }

    for(auto c: lit)
    {
        if(c >= 'a' && c <= 'z')
        {
            s.add_s_lit('.');
            break;
        }
        s.add_s_lit(c);
    }
    return true;
}

static bool parse_line(parse &s, const sm_list &sl,
                       const syntax::statemachine::line &line)
{
    for(const auto &c : line.pc)
    {
        switch(c.type)
        {
        case statemachine::pcode::c_literal:
            if(!parse_literal(s, c.str))
                return false;
            break;
        case statemachine::pcode::c_emit:
            emit_bytes(s, c.data);
            break;
        case statemachine::pcode::c_emit_return:
            emit_bytes(s, c.data);
            return true;
        case statemachine::pcode::c_call_ext:
            if(!call_parsing_action(c.str, s))
                return false;
            break;
        case statemachine::pcode::c_call_table:
            if(!parse_table(s, sl, c.str))
                return false;
            break;
        case statemachine::pcode::c_return:
            return true;
        }
    }
    return true;
}

static bool parse_table(parse &s, const sm_list &sl, std::string name)
{
    // Parse using the parsing tables in sl:
    auto current = get(sl, name);
    s.debug(current.name() + " (" + std::to_string(current.line_num()) + ")");
    s.check_level();
    s.skipws();
    s.error(current.error_text());
    auto spos = s.save();

    for(const auto &line : current.get_code())
    {
        if(parse_line(s, sl, line))
        {
            s.debug("<-- OK (" + std::to_string(line.lnum) + ")");
            s.lvl--;
            return true;
        }
        s.debug("-! " + std::to_string(line.lnum));
        s.restore(spos);
    }

    s.lvl--;
    return false;
}

bool syntax::parse_start(parse &s, const sm_list &sl)
{
    // Parse using the parsing tables in sl:
    return parse_table(s, sl, "PARSE_START");
}
