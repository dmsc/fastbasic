/*
 * FastBasic - Fast basic interpreter for the Atari 8-bit computers
 * Copyright (C) 2017-2025 Daniel Serpell
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
 */

// Small compiled token-pattern matcher used by the peephole optimizer.

#pragma once

#include "codew.h"
#include <cstdlib>
#include <functional>
#include <iostream>
#include <map>
#include <sstream>
#include <stdexcept>
#include <string>
#include <vector>

inline bool peep_debug_enabled()
{
    static int enabled = -1;
    if(enabled < 0)
    {
        auto e = std::getenv("FASTBASIC_PEEPHOLE_DEBUG");
        enabled = e && *e && std::string(e) != "0";
    }
    return enabled;
}

struct peep_state
{
    int print_color = 0;
    bool color_pending = false;
    int ioch = 0;
    bool ioch_pending = false;
    std::map<std::string, std::string> tgt;

    void on_label()
    {
        print_color = 0;
        color_pending = false;
        ioch = 0;
        ioch_pending = false;
    }
};

class peep_match
{
  public:
    enum capture_kind
    {
        cap_word,
        cap_byte,
        cap_varn,
        cap_label,
        cap_label_marker,
        cap_string,
        cap_any,
        cap_span
    };
    struct capture
    {
        capture_kind type;
        size_t index;
        size_t end;
        int value;
        bool numeric;
        std::string text;
    };
    size_t start = 0;
    size_t end = 0;
    peep_state &state;
    std::map<std::string, capture> caps;

    explicit peep_match(peep_state &s) : state(s) {}

    int word(std::string name) const { return caps.at(name).value; }
    int varn(std::string name) const { return caps.at(name).value; }
    bool numeric(std::string name) const { return caps.at(name).numeric; }
    std::string text(std::string name) const { return caps.at(name).text; }
    bool is_label(std::string name) const
    {
        return caps.at(name).type == cap_label_marker;
    }
    void debug_caps() const
    {
        for(auto &c : caps)
            std::cerr << "        " << c.first << "=" << c.second.value << "\n";
    }
};

class peep_pattern
{
  private:
    struct item
    {
        enum type
        {
            token,
            word,
            word_any,
            byte_range,
            byte,
            byte_any,
            varn,
            label,
            label_marker,
            string,
            any,
            span
        } type;
        std::string value;
        std::string name;
    };
    std::string source;
    std::vector<item> items;

  public:
    explicit peep_pattern(std::string p) : source(std::move(p))
    {
        std::istringstream in(source);
        std::string part;
        while(in >> part)
        {
            item i;
            if(part.size() > 1 && part[0] == '%')
            {
                auto colon = part.find(':');
                if(colon == std::string::npos)
                    throw std::runtime_error("invalid peephole capture '" + part + "'");
                std::string type = part.substr(1, colon - 1);
                std::string rest = part.substr(colon + 1);
                auto second = rest.find(':');
                i.name = rest.substr(0, second);
                if(type == "w")
                    i.type = item::word;
                else if(type == "W")
                    i.type = item::word_any;
                else if(type == "c")
                    i.type = item::byte_range;
                else if(type == "b")
                    i.type = item::byte;
                else if(type == "B")
                    i.type = item::byte_any;
                else if(type == "v")
                    i.type = item::varn;
                else if(type == "l")
                    i.type = item::label;
                else if(type == "L")
                    i.type = item::label_marker;
                else if(type == "s")
                    i.type = item::string;
                else if(type == "a")
                    i.type = item::any;
                else if(type == "e")
                {
                    i.type = item::span;
                    if(second == std::string::npos)
                        throw std::runtime_error("missing span terminator in '" + source + "'");
                    i.value = rest.substr(second + 1);
                }
                else
                    throw std::runtime_error("invalid peephole capture type in '" + part + "'");
            }
            else
            {
                i.type = item::token;
                i.value = part;
            }
            items.push_back(i);
        }
    }

    std::string first() const
    {
        if(items.empty() || items[0].type != item::token)
            return std::string();
        return items[0].value;
    }

    const std::string &source_text() const { return source; }

    bool match(std::vector<codew> &code, size_t current, peep_match &out) const
    {
        out.caps.clear();
        out.start = current;
        size_t pos = current;
        for(auto &i : items)
        {
            switch(i.type)
            {
            case item::token:
                if(pos >= code.size() || !code[pos].is_tok(i.value))
                    return false;
                pos++;
                break;
            case item::word:
                if(pos >= code.size() || !code[pos].is_word())
                    return false;
                out.caps[i.name] = {peep_match::cap_word, pos, pos + 1,
                                    (int16_t)code[pos].get_val(), true, {}};
                pos++;
                break;
            case item::word_any:
                if(pos >= code.size() ||
                   !(code[pos].is_word() || code[pos].is_sword()))
                    return false;
                out.caps[i.name] = {
                    peep_match::cap_word, pos, pos + 1,
                    code[pos].is_word() ? (int16_t)code[pos].get_val() : 0,
                    code[pos].is_word(),
                    code[pos].is_word() ? std::string() : code[pos].get_str()};
                pos++;
                break;
            case item::byte_range:
                if(pos >= code.size() || !code[pos].is_word() ||
                   code[pos].get_val() < 0 || code[pos].get_val() > 255)
                    return false;
                out.caps[i.name] = {peep_match::cap_word, pos, pos + 1,
                                  code[pos].get_val(), true, {}};
                pos++;
                break;
            case item::byte:
                if(pos >= code.size() || !code[pos].is_byte())
                    return false;
                out.caps[i.name] = {peep_match::cap_byte, pos, pos + 1,
                                  code[pos].get_val(), true, {}};
                pos++;
                break;
            case item::byte_any:
                if(pos >= code.size() ||
                   !(code[pos].is_byte() || code[pos].is_sbyte()))
                    return false;
                out.caps[i.name] = {
                    peep_match::cap_byte, pos, pos + 1,
                    code[pos].is_byte() ? code[pos].get_val() : 0,
                    code[pos].is_byte(),
                    code[pos].is_byte() ? std::string() : code[pos].get_str()};
                pos++;
                break;
            case item::varn:
                if(pos >= code.size() || !code[pos].is_varn())
                    return false;
                out.caps[i.name] = {peep_match::cap_varn, pos, pos + 1,
                                  code[pos].get_varn(), true, {}};
                pos++;
                break;
            case item::label:
                if(pos >= code.size() || !code[pos].is_sword())
                    return false;
                out.caps[i.name] = {peep_match::cap_label, pos, pos + 1, 0, false,
                                  code[pos].get_str()};
                pos++;
                break;
            case item::label_marker:
                if(pos >= code.size() || !code[pos].is_label())
                    return false;
                out.caps[i.name] = {peep_match::cap_label_marker, pos, pos + 1, 0,
                                  false, code[pos].get_str()};
                pos++;
                break;
            case item::string:
                if(pos >= code.size() || !code[pos].is_string())
                    return false;
                out.caps[i.name] = {peep_match::cap_string, pos, pos + 1, 0, false,
                                  code[pos].get_str()};
                pos++;
                break;
            case item::any:
            {
                if(pos >= code.size())
                    return false;
                bool numeric = code[pos].is_byte() || code[pos].is_word();
                int value = numeric && code[pos].is_word()
                              ? (int16_t)code[pos].get_val()
                              : (numeric ? code[pos].get_val() : 0);
                out.caps[i.name] = {code[pos].is_label()
                                      ? peep_match::cap_label_marker
                                      : peep_match::cap_any,
                                  pos, pos + 1, value, numeric, {}};
                pos++;
                break;
            }
            case item::span:
            {
                size_t begin = pos;
                while(pos < code.size() && !code[pos].is_tok(i.value))
                    pos++;
                if(pos == begin || pos >= code.size())
                    return false;
                out.caps[i.name] = {peep_match::cap_span, begin, pos, 0, false, {}};
                break;
            }
            }
        }
        out.end = pos;
        return true;
    }
};

class peep_builder
{
  private:
    const std::vector<codew> *code;
    int line;
  public:
    std::vector<codew> out;
    bool modified = true;
    peep_builder(const std::vector<codew> &c, int l) : code(&c), line(l) {}
    void keep() { modified = false; }
    void tok(std::string t) { out.push_back(codew::ctok(t, line)); }
    void word(int v) { out.push_back(codew::cword(v, line)); }
    void symbol(std::string s) { out.push_back(codew::cword(s, line)); }
    void byte(int v) { out.push_back(codew::cbyte(v, line)); }
    void string(std::string s) { out.push_back(codew::cstring(s, line)); }
    void emit_value(const std::string &part, int value)
    {
        if(part == "%w")
            word(value & 0xFFFF);
        else if(part == "%b")
            byte(value & 0xFF);
        else
            throw std::runtime_error("invalid peephole format: " + part);
    }
    void emit_value(const std::string &part, const std::string &value)
    {
        if(part == "%s")
            string(value);
        else
            throw std::runtime_error("invalid peephole format: " + part);
    }
    template<typename T>
    void write(const char *format, T value)
    {
        std::istringstream in(format);
        std::string part;
        bool used = false;
        while(in >> part)
        {
            if(part.size() > 1 && part[0] == '%')
            {
                if(used)
                    throw std::runtime_error("multiple values in peephole format");
                emit_value(part, value);
                used = true;
            }
            else
                tok(part);
        }
        if(!used)
            throw std::runtime_error("missing value in peephole format");
    }
    void write(const char *format, const peep_match &m)
    {
        std::istringstream in(format);
        std::string part;
        while(in >> part)
        {
            if(part.size() > 1 && part[0] == '$')
                raw(m, part.substr(1));
            else if(part.size() > 1 && part[0] == '%')
                throw std::runtime_error("value required in peephole format");
            else
                tok(part);
        }
    }
    void raw(const peep_match &m, std::string name)
    {
        auto &c = m.caps.at(name);
        if(c.type == peep_match::cap_span)
            for(size_t i = c.index; i < c.end; ++i)
                out.push_back((*code)[i]);
        else
            out.push_back((*code)[c.index]);
    }
    bool valid_span(const peep_match &m, const std::string &name) const
    {
        auto it = m.caps.find(name);
        if(it == m.caps.end() || it->second.type != peep_match::cap_span ||
           it->second.index >= it->second.end)
            return false;
        int line = (*code)[it->second.index].linenum();
        for(size_t i = it->second.index; i < it->second.end; ++i)
        {
            auto &c = (*code)[i];
            if(c.linenum() != line || c.is_label())
                return false;
            if(c.is_tok())
            {
                auto t = c.get_tok();
                if(t == "TOK_POKE" || t == "TOK_DPOKE" ||
                   t == "TOK_BYTE_POKE" || t == "TOK_NUM_POKE" ||
                   t == "TOK_PUT" || t == "TOK_END")
                    return false;
            }
        }
        return true;
    }
};

class peep_rule
{
  public:
    using cond_fn = std::function<bool(const peep_match &)>;
    using action_fn = std::function<void(const peep_match &, peep_builder &)>;
    struct rep_item
    {
        bool capture;
        char mode;
        std::string value;
    };
    peep_pattern pattern;
    std::vector<rep_item> replacement;
    action_fn action;
    cond_fn condition;

    peep_rule(std::string pat, std::string repl, cond_fn cond = {})
        : pattern(std::move(pat)), action(), condition(std::move(cond))
    {
        std::istringstream in(repl);
        std::string part;
        while(in >> part)
        {
            if(part.size() > 1 && part[0] == '$')
            {
                auto colon = part.find(':');
                char mode = 0;
                std::string name = part.substr(1, colon == std::string::npos
                                                     ? std::string::npos
                                                     : colon - 1);
                if(colon != std::string::npos)
                    mode = part[colon + 1];
                replacement.push_back({true, mode, name});
            }
            else
                replacement.push_back({false, 0, part});
        }
    }
    peep_rule(std::string pat, action_fn act, cond_fn cond = {})
        : pattern(std::move(pat)), action(std::move(act)), condition(std::move(cond))
    {
    }

    bool match(std::vector<codew> &code, size_t current, peep_match &m) const
    {
        return pattern.match(code, current, m) &&
               (!condition || condition(m));
    }
    void build(const peep_match &m, peep_builder &b) const
    {
        if(action)
        {
            action(m, b);
            return;
        }
        for(auto &r : replacement)
        {
            if(!r.capture)
                b.tok(r.value);
            else if(r.mode == 'b')
                b.byte(m.word(r.value));
            else if(r.mode == 'w')
                b.word(m.word(r.value));
            else
                b.raw(m, r.value);
        }
    }
};

class peep_rules
{
  private:
    std::string name;
    std::vector<peep_rule> rules;
    std::map<std::string, std::vector<size_t>> by_first;

  public:
    peep_rules(std::string n, std::vector<peep_rule> r)
        : name(std::move(n)), rules(std::move(r))
    {
        for(size_t i = 0; i < rules.size(); i++)
            by_first[rules[i].pattern.first()].push_back(i);
        if(peep_debug_enabled())
            for(size_t i = 0; i < rules.size(); i++)
                std::cerr << "peephole pattern [" << name << "] #" << i
                          << ": " << rules[i].pattern.source_text() << "\n";
    }
    bool apply(std::vector<codew> &code, size_t current, peep_state &state,
               std::vector<codew> &repl, size_t &begin, size_t &end,
               bool &modified) const
    {
        if(current >= code.size() || !code[current].is_tok())
            return false;
        auto it = by_first.find(code[current].get_tok());
        if(it == by_first.end())
            return false;
        peep_match m(state);
        for(size_t index : it->second)
        {
            auto &rule = rules[index];
            if(!rule.match(code, current, m))
                continue;
            if(peep_debug_enabled())
            {
                std::cerr << "peephole match [" << name << "] #" << index
                          << ": " << rule.pattern.source_text() << "\n";
                m.debug_caps();
            }
            peep_builder b(code, code[current].linenum());
            rule.build(m, b);
            if(peep_debug_enabled() && b.modified)
                std::cerr << "peephole apply [" << name << "] #" << index
                          << ": " << rule.pattern.source_text() << "\n";
            repl = std::move(b.out);
            begin = m.start;
            end = m.end;
            modified = b.modified;
            return true;
        }
        return false;
    }
};
