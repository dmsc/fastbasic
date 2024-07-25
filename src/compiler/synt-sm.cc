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

// synt-sm.cc: Parse and write the syntax state machine
#include "synt-sm.h"
#include "synt-pstate.h"
#include "synt-symlist.h"
#include "synt-wlist.h"
#include <algorithm>
#include <iostream>
#include <string>
#include <vector>

using namespace syntax;

bool statemachine::parse_description()
{
    // Description is from ':' to the end of line, skipping spaces
    p.space();
    sentry s(p);
    p.all();
    _desc = s.str();
    return s(true);
}

static int dhex(char c)
{
    if(c >= '0' && c <= '9')
        return c - '0';
    else if(c >= 'a' && c <= 'f')
        return c - 'a';
    else
        return c - 'A';
}

static bool match_backslash(parse_state &p, std::string &str)
{
    sentry s(p);
    if(p.ch('\\'))
    {
        if(p.ch('n'))
            str += '\n';
        else if(p.ch('r'))
            str += '\r';
        else if(p.ch('t'))
            str += '\t';
        else if(p.ch('"'))
            str += '"';
        else if(p.ch('\\'))
            str += '\\';
        else if(p.ch('x') && (p.ch('0', '9') || p.ch('a', 'f') || p.ch('A', 'F')) &&
                (p.ch('0', '9') || p.ch('a', 'f') || p.ch('A', 'F')))
            str += char(16 * dhex(s.str()[1]) + dhex(s.str()[2]));
        else
            return s(false);
        return s(true);
    }
    return s(false);
}

static bool match_char(parse_state &p, std::string &str)
{
    sentry s(p);
    if(match_backslash(p, str))
        return true;
    else if(p.ch('"') || p.eol())
        return s(false);
    else if(p.ch(0, 127))
    {
        str += s.str();
        return true;
    }
    else
        return s(false);
}

bool statemachine::parse_str(line &current)
{
    std::string s;
    while(match_char(p, s))
        ;
    if(p.eol())
        return p.error("un-terminated string");
    else if(!p.ch('"'))
        return p.error("invalid character in string");
    current.pc.emplace_back(pcode{pcode::c_literal, s});
    return true;
}

// Parses one emit token
bool statemachine::read_emit_token(std::vector<dcode> &emit)
{
    p.space();
    bool is_word = p.ch('&');
    int n = p.read_number();
    if(n < 0)
    {
        auto tk = p.read_ident();
        if(tk.empty())
            return p.error("Expected token to EMIT");
        if(is_word)
        {
            auto s = syms.map().find(tk);
            if(s == syms.map().end())
                return p.error("Unknown symbol to emit: " + tk);
            if(s->second > 65535)
                emit.push_back({dcode::d_word_sym, s->first, 0});
            else
                emit.push_back({dcode::d_word_val, std::string(), s->second});
        }
        else if(tk.substr(0, 4) == "TOK_")
        {
            // Search in token list
            if(tok.map().find(tk) == tok.map().end())
                return p.error("Unknown token to emit: " + tk);
            emit.push_back({dcode::d_token, tk, 0});
        }
        else
        {
            auto s = syms.map().find(tk);
            if(s == syms.map().end())
                return p.error("Unknown symbol to emit: " + tk);
            if((s->second & 0xFFFFFF) > 255 || s->second == symlist::sym_import)
                return p.error("Invalid symbol value for a byte: " + tk);
            if(s->second > 255)
                emit.push_back({dcode::d_byte_sym, s->first, 0});
            else
                emit.push_back({dcode::d_byte_val, std::string(), s->second});
        }
    }
    else
    {
        if(is_word)
            emit.push_back({dcode::d_word_val, std::string(), n});
        else
            emit.push_back({dcode::d_byte_val, std::string(), n});
    }
    return true;
}

// Parses a emit line "{" byte/token, &word, ... "}"
bool statemachine::read_emit_line(std::vector<dcode> &emit)
{
    while(true)
    {
        p.space();
        if(!read_emit_token(emit))
            return false;
        if(p.ch('}'))
            break;
        if(!p.ch(','))
            return p.error("Expected ',' or '}'");
    }
    return true;
}

bool statemachine::parse_line(line &current)
{
    current.pc.clear();
    p.skip_comments();
    if(!p.blank() || (p.space() && p.eol()))
        return false;
    if(complete)
        return p.error("table '" + _name + "' is already completed");

    bool canFail = false; // True if the parsing rule can fail (== has actions)
    current.lnum = p.get_line();

    // Reads commands until EOL or comment
    while(1)
    {
        std::string cmd;
        if(p.end_line())
        {
            current.pc.emplace_back(pcode{pcode::c_return});
            // If line can't fail, rule is complete.
            complete = !canFail;
            return true;
        }
        sentry s(p);
        // String?
        if(p.ch('"'))
        {
            if(!parse_str(current))
                return p.error("parse: string \"" + s.str() + "\" invalid");
            canFail = true;
            continue;
        }
        // Command ?
        cmd = p.read_ident();
        p.space();
        if(cmd == "emit")
        {
            std::vector<dcode> emit;
            if(p.ch('{'))
            {
                if(!read_emit_line(emit))
                    return false;
            }
            else
            {
                if(!read_emit_token(emit))
                    return p.error("EMIT expects a token");
            }
            current.pc.emplace_back(pcode{emit});
            continue;
        }

        if(cmd == "pass")
        {
            complete = true;
            if(!p.end_line())
                return p.error("parse: 'pass' should be the only command in a line");
            current.pc.emplace_back(pcode{pcode::c_return});
            // End of command, and end of SM
            return true;
        }
        else if(!cmd.empty())
        {
            canFail = true;
            if(ext.map().count(cmd))
                current.pc.emplace_back(pcode{pcode::c_call_ext, cmd});
            else
                current.pc.emplace_back(pcode{pcode::c_call_table, cmd});
        }
        else
            p.error("invalid label \"" + cmd + "\"");
    }
    return false;
}

int statemachine::has_call(std::string tab) const
{
    int n = 0;
    for(auto &l : code)
        for(auto &c : l.pc)
            if(c.type == pcode::c_call_table && c.str == tab)
                n++;
    return n;
}

int statemachine::is_empty() const
{
    return (code.size() == 0) || (code.size() == 1 && code[0].pc.size() == 1 &&
                                  code[0].pc[0].type == pcode::c_return);
}

void statemachine::delete_call(std::string tab)
{
    for(auto &l : code)
    {
        auto &v = l.pc;
        v.erase(std::remove_if(v.begin(), v.end(),
                               [&](pcode &x) {
                                   return (x.type == pcode::c_call_table && x.str == tab);
                               }),
                v.end());
    }
}

bool statemachine::end_call(std::string tab) const
{
    if(code.size())
    {
        auto &l = code.back().pc;
        if(l.size() == 2 && l[0].type == pcode::c_call_table && l[0].str == tab &&
           l[1].type == pcode::c_return)
            return true;
    }
    return false;
}

bool statemachine::just_call(std::string tab) const
{
    for(const auto &lc: code)
    {
        auto &l = lc.pc;
        if(l.size() == 2 && l[0].type == pcode::c_call_table && l[0].str == tab &&
           l[1].type == pcode::c_return)
            return true;
    }
    return false;
}

bool statemachine::parse()
{
    lnum = p.get_line();
    if(!parse_description())
        return false;
    line current;
    while(parse_line(current))
        code.push_back(current);
    return true;
}

bool statemachine::parse_extra()
{
    bool prepend = p.ch('<');
    bool do_complete = complete;
    line last;
    if(do_complete)
    {
        // Remove last line to re-add later
        complete = false;
        if(code.size())
        {
            last = code.back();
            code.pop_back();
        }
    }
    line current;
    while(parse_line(current))
    {
        if(prepend)
            code.insert(code.begin(), current);
        else
            code.push_back(current);
    }
    // Restore if needed
    if(do_complete)
    {
        if(complete)
            return p.error("table '" + _name + "' was already completed");
        complete = true;
        code.push_back(last);
    }
    return true;
}

bool statemachine::tail_call(const statemachine &from)
{
    if(complete)
        return p.error("table '" + _name + "' was already completed");
    if(!code.size())
        return p.error("invalid optimization in table '" + _name + "'");

    code.pop_back();
    for(auto &l : from.code)
        code.push_back(l);
    complete = from.complete;
    return true;
}

bool statemachine::inline_call(std::string tab, const statemachine &from)
{
    if(from.complete)
        return p.error("table '" + from._name + "' was already completed");

    auto new_code = std::vector<line>();

    for(const auto &l : code)
    {
        if(l.pc.size() == 2 && l.pc[0].type == pcode::c_call_table &&
           l.pc[0].str == tab && l.pc[1].type == pcode::c_return)
        {
            for(auto &t : from.code)
                new_code.push_back(t);
        }
        else
            new_code.push_back(l);
    }
    code = new_code;
    return true;
}

void statemachine::optimize()
{
    // Replace multiple "emits" with only one
    for(auto &line : code)
    {
        auto &pc = line.pc;
        for(size_t i = 1; i < pc.size(); i++)
        {
            auto &c0 = pc[i - 1];
            auto &c1 = pc[i];
            if(c0.type == pcode::c_emit && c1.type == pcode::c_emit)
            {
                c0.data.insert(c0.data.end(), c1.data.begin(), c1.data.end());
                pc.erase(pc.begin() + i);
                i--;
            }
        }
    }
    // Replace "emit" followed by "return" with an emit & return
    for(auto &line : code)
    {
        auto &pc = line.pc;
        for(size_t i = 1; i < pc.size(); i++)
        {
            if(pc[i - 1].type == pcode::c_emit && pc[i].type == pcode::c_return)
            {
                pc[i - 1].type = pcode::c_emit_return;
                pc.erase(pc.begin() + i);
                i--;
            }
        }
    }
}
