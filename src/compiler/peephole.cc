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
 *
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>
 */

// peephole.cc: Peephole optimizer

#include "peephole.h"
#include "peephole-patterns.h"
#include <map>
#include <set>

static std::vector<peep_rule> make_peephole_rules()
{
    return {
        {"TOK_NUM %w:x TOK_NEG",
            [](const peep_match &m, peep_builder &b) {
                b.write("TOK_NUM %w", -m.word("x"));
            }},
        {"TOK_NUM %w:x TOK_USHL",
            [](const peep_match &m, peep_builder &b) {
                b.write("TOK_NUM %w", 2 * m.word("x"));
            }},
        {"TOK_NUM %w:x TOK_SHL8",
            [](const peep_match &m, peep_builder &b) {
                b.write("TOK_NUM %w", 256 * m.word("x"));
            }},
        {"TOK_PUSH TOK_NUM %w:x TOK_MUL", "TOK_SHL8",
            [](const peep_match &m) { return m.word("x") == 256; }},
        {"TOK_PUSH TOK_NUM %w:x TOK_MUL", "TOK_USHL TOK_USHL",
            [](const peep_match &m) { return m.word("x") == 4; }},
        {"TOK_PUSH TOK_NUM %w:x TOK_MUL", "TOK_USHL",
            [](const peep_match &m) { return m.word("x") == 2; }},
        {"TOK_PUSH TOK_NUM %w:x TOK_MUL", "",
            [](const peep_match &m) { return m.word("x") == 1; }},
        {"TOK_PUSH TOK_NUM %w:x TOK_DIV", "",
            [](const peep_match &m) { return m.word("x") == 1; }},
        {"TOK_PUSH TOK_NUM %w:x TOK_ADD", "",
            [](const peep_match &m) { return m.word("x") == 0; }},
        {"TOK_PUSH TOK_NUM %w:x TOK_SUB", "",
            [](const peep_match &m) { return m.word("x") == 0; }},
        {"TOK_PUSH TOK_NUM %w:x TOK_NEQ", "TOK_COMP_0",
            [](const peep_match &m) { return m.word("x") == 0; }},
        {"TOK_PUSH TOK_NUM %w:x TOK_EQ", "TOK_COMP_0 TOK_L_NOT",
            [](const peep_match &m) { return m.word("x") == 0; }},
        {"TOK_NUM %w:x TOK_ADD_VAR %v:v",
                       "TOK_VAR_LOAD $v",
                       [](const peep_match &m) { return m.word("x") == 0; }},
        {"TOK_NUM %w:x TOK_PUSH TOK_NUM %w:y TOK_ADD",
            [](const peep_match &m, peep_builder &b) {
                b.write("TOK_NUM %w", m.word("x") + m.word("y"));
            }},
        {"TOK_NUM %w:x TOK_PUSH TOK_NUM %w:y TOK_SUB",
            [](const peep_match &m, peep_builder &b) {
                b.write("TOK_NUM %w", m.word("x") - m.word("y"));
            }},
        // Memory and I/O.
        {"TOK_NUM %w:x TOK_VAR_STORE %v:v",
                       "TOK_VAR_STORE_0 $v",
                       [](const peep_match &m) { return m.word("x") == 0; }},
        {"TOK_VAR_ADDR %v:v TOK_SADDR TOK_GET TOK_DPOKE",
                       "TOK_GET TOK_VAR_STORE $v"},
        {"TOK_VAR_ADDR %v:v TOK_SADDR TOK_GETKEY TOK_DPOKE",
                       "TOK_GETKEY TOK_VAR_STORE $v"},
        {"TOK_NUM %w:x TOK_PUT",
            [](const peep_match &m, peep_builder &b) {
                b.write("TOK_BYTE_PUT %b", m.word("x"));
            }},
        {"TOK_BYTE %B:x TOK_PUT", "TOK_BYTE_PUT $x"},
        // Track PRINT_COLOR and remove redundant color changes.
        {"TOK_NUM %w:x TOK_BYTE_POKE %B:color",
            [](const peep_match &m, peep_builder &b) {
                int x = m.word("x");
                if(x == m.state.print_color)
                    return;
                m.state.print_color = x;
                m.state.color_pending = true;
                b.keep();
            },
            [](const peep_match &m) {
                return m.text("color") == "PRINT_COLOR";
            }},
        // A color change from a non-constant expression is unknown.
        {"TOK_BYTE_POKE %B:color",
            [](const peep_match &m, peep_builder &b) {
                if(m.state.color_pending)
                    m.state.color_pending = false;
                else
                    m.state.print_color = -1;
                b.keep();
            },
            [](const peep_match &m) {
                return m.text("color") == "PRINT_COLOR";
            }},
        {"TOK_NUM %c:x TOK_PEEK",
            [](const peep_match &m, peep_builder &b) {
                b.write("TOK_BYTE_PEEK %b", m.word("x"));
            }},
        {"TOK_BYTE %B:x TOK_PEEK", "TOK_BYTE_PEEK $x"},
        // Constant-address POKE variants.
        {"TOK_NUM %c:a TOK_SADDR TOK_NUM %w:v TOK_POKE",
            [](const peep_match &m, peep_builder &b) {
                b.write("TOK_NUM %w", m.word("v") & 255);
                b.write("TOK_BYTE_POKE %b", m.word("a"));
            }},
        {"TOK_NUM %c:a TOK_SADDR TOK_VAR_LOAD %v:v TOK_POKE",
            [](const peep_match &m, peep_builder &b) {
                b.write("TOK_VAR_LOAD $v", m);
                b.write("TOK_BYTE_POKE %b", m.word("a"));
            }},
        {"TOK_BYTE %B:a TOK_SADDR TOK_NUM %w:v TOK_POKE",
            [](const peep_match &m, peep_builder &b) {
                b.write("TOK_NUM %w", m.word("v") & 255);
                b.write("TOK_BYTE_POKE $a", m);
            }},
        {"TOK_BYTE %B:a TOK_SADDR TOK_VAR_LOAD %v:v TOK_POKE",
            [](const peep_match &m, peep_builder &b) {
                b.write("TOK_VAR_LOAD $v TOK_BYTE_POKE $a", m);
            }},
        {"TOK_NUM %W:a TOK_SADDR TOK_NUM %w:v TOK_POKE",
            [](const peep_match &m, peep_builder &b) {
                b.write("TOK_NUM %w", m.word("v") & 255);
                b.write("TOK_NUM_POKE $a", m);
            }},
        {"TOK_NUM %w:a TOK_SADDR TOK_VAR_LOAD %v:v TOK_POKE",
            [](const peep_match &m, peep_builder &b) {
                b.write("TOK_VAR_LOAD $v", m);
                b.write("TOK_NUM_POKE %w", m.word("a"));
            }},
        // Constant arithmetic operations.
        {"TOK_NUM %w:x TOK_PUSH TOK_NUM %w:y TOK_MUL",
            [](const peep_match &m, peep_builder &b) {
                b.write("TOK_NUM %w", m.word("x") * m.word("y"));
            }},
        {"TOK_NUM %w:x TOK_PUSH TOK_NUM %w:y TOK_DIV",
            [](const peep_match &m, peep_builder &b) {
                int y = m.word("y");
                int v = y ? m.word("x") / y : (m.word("x") < 0 ? 1 : -1);
                b.write("TOK_NUM %w", v);
            }},
        {"TOK_NUM %w:x TOK_PUSH TOK_NUM %w:y TOK_MOD",
            [](const peep_match &m, peep_builder &b) {
                int y = m.word("y");
                int v = y ? m.word("x") % y : m.word("x");
                b.write("TOK_NUM %w", v);
            }},
        {"TOK_NUM %w:x TOK_PUSH TOK_NUM %w:y TOK_BIT_AND",
            [](const peep_match &m, peep_builder &b) {
                b.write("TOK_NUM %w", m.word("x") & m.word("y"));
            }},
        {"TOK_NUM %w:x TOK_PUSH TOK_NUM %w:y TOK_BIT_OR",
            [](const peep_match &m, peep_builder &b) {
                b.write("TOK_NUM %w", m.word("x") | m.word("y"));
            }},
        {"TOK_NUM %w:x TOK_PUSH TOK_NUM %w:y TOK_BIT_EXOR",
            [](const peep_match &m, peep_builder &b) {
                b.write("TOK_NUM %w", m.word("x") ^ m.word("y"));
            }},
        // Variable updates.
        {"TOK_PUSH TOK_VAR_LOAD %v:x TOK_ADD",
                       "TOK_ADD_VAR $x"},
        {"TOK_VAR_LOAD %v:x TOK_PUSH TOK_NUM %w:y TOK_ADD",
                       "TOK_NUM $y:w TOK_ADD_VAR $x"},
        {"TOK_VAR_LOAD %v:x TOK_PUSH TOK_VAR_LOAD %v:y TOK_ADD",
                       "TOK_VAR_LOAD $x TOK_USHL",
                       [](const peep_match &m) { return m.varn("x") == m.varn("y"); }},
        {"TOK_NUM %w:one TOK_ADD_VAR %v:x TOK_VAR_STORE %v:y",
                       "TOK_INCVAR $x",
                       [](const peep_match &m) {
                           return m.word("one") == 1 && m.varn("x") == m.varn("y");
                       }},
        {"TOK_VAR_LOAD %v:x TOK_PUSH TOK_NUM %w:one TOK_ADD "
                       "TOK_VAR_STORE %v:y",
                       "TOK_INCVAR $x",
                       [](const peep_match &m) {
                           return m.word("one") == 1 && m.varn("x") == m.varn("y");
                       }},
        {"TOK_VAR_LOAD %v:x TOK_PUSH TOK_NUM %w:one TOK_SUB "
                       "TOK_VAR_STORE %v:y",
                       "TOK_DECVAR $x",
                       [](const peep_match &m) {
                           return m.word("one") == 1 && m.varn("x") == m.varn("y");
                       }},
        {"TOK_VAR_ADDR %v:x TOK_INC", "TOK_INCVAR $x"},
        {"TOK_SADDR TOK_INC", "TOK_INC"},
        {"TOK_VAR_ADDR %v:x TOK_DEC", "TOK_DECVAR $x"},
        {"TOK_SADDR TOK_DEC", "TOK_DEC"},
        // Boolean and branch simplifications.
        {"TOK_L_NOT TOK_L_NOT", "TOK_COMP_0"},
        {"TOK_EQ TOK_L_NOT", "TOK_NEQ"},
        {"TOK_NEQ TOK_L_NOT", "TOK_EQ"},
        {"TOK_CALL %l:target TOK_RET", "TOK_JUMP $target"},
        {"TOK_L_NOT TOK_CJUMP", "TOK_CNJUMP"},
        {"TOK_L_NOT TOK_CNJUMP", "TOK_CJUMP"},
        {"TOK_CJUMP %l:from TOK_JUMP %l:to %L:end",
                       "TOK_CNJUMP $to $end",
                       [](const peep_match &m) {
                           return m.text("from") == m.text("end");
                       }},
        {"TOK_CJUMP %l:from TOK_RET %L:end",
                       "TOK_CNRET $end",
                       [](const peep_match &m) {
                           return m.text("from") == m.text("end");
                       }},
        {"TOK_CJUMP %l:from TOK_NUM %w:v TOK_RET %L:end",
                       "TOK_CNRET $end",
                       [](const peep_match &m) {
                           return m.word("v") == 0 && m.text("from") == m.text("end");
                       }},
        {"TOK_CNJUMP %l:from TOK_JUMP %l:to %L:end",
                       "TOK_CJUMP $to $end",
                       [](const peep_match &m) {
                           return m.text("from") == m.text("end");
                       }},
        {"TOK_CNJUMP %l:from TOK_RET %L:end",
                       "TOK_CRET $end",
                       [](const peep_match &m) {
                           return m.text("from") == m.text("end");
                       }},
        {"TOK_CNJUMP %l:from TOK_NUM %w:v TOK_RET %L:end",
                       "TOK_CRET $end",
                       [](const peep_match &m) {
                           return m.word("v") == 0 && m.text("from") == m.text("end");
                       }},
        {"TOK_L_NOT TOK_CRET", "TOK_CNRET"},
        {"TOK_L_NOT TOK_CNRET", "TOK_CRET"},
        {"TOK_NUM %w:x TOK_COMP_0",
            [](const peep_match &m, peep_builder &b) {
                b.write("TOK_NUM %w", m.word("x") ? 1 : 0);
            }},
        {"TOK_NUM %w:x TOK_CNJUMP %l:target",
            [](const peep_match &m, peep_builder &b) {
                if(m.word("x"))
                {
                    b.write("TOK_JUMP $target", m);
                }
            }},
        {"TOK_NUM %w:x TOK_CJUMP %l:target",
            [](const peep_match &m, peep_builder &b) {
                if(!m.word("x"))
                {
                    b.write("TOK_JUMP $target", m);
                }
            }},
        // Transform multiple subtractions to addition:
        //   PUSH a SUB PUSH b SUB  ->  PUSH a PUSH b ADD SUB
        {"TOK_PUSH TOK_VAR_LOAD %v:a TOK_SUB TOK_PUSH TOK_VAR_LOAD %v:b TOK_SUB",
            "TOK_PUSH TOK_VAR_LOAD $a TOK_PUSH TOK_VAR_LOAD $b TOK_ADD TOK_SUB"},
        {"TOK_PUSH TOK_VAR_LOAD %v:a TOK_SUB TOK_PUSH TOK_NUM %w:b TOK_SUB",
            "TOK_PUSH TOK_VAR_LOAD $a TOK_PUSH TOK_NUM $b TOK_ADD TOK_SUB"},
        {"TOK_PUSH TOK_NUM %w:a TOK_SUB TOK_PUSH TOK_VAR_LOAD %v:b TOK_SUB",
            "TOK_PUSH TOK_NUM $a TOK_PUSH TOK_VAR_LOAD $b TOK_ADD TOK_SUB"},
        {"TOK_PUSH TOK_NUM %w:a TOK_SUB TOK_PUSH TOK_NUM %w:b TOK_SUB",
            "TOK_PUSH TOK_NUM $a TOK_PUSH TOK_NUM $b TOK_ADD TOK_SUB"},
        // VAR + VAR * 2  ->  VAR * 2 + VAR
        {"TOK_VAR_LOAD %v:x TOK_PUSH TOK_VAR_LOAD %v:y TOK_USHL TOK_ADD",
            "TOK_VAR_LOAD $y TOK_USHL TOK_ADD_VAR $x"},
        // Array indexing: ARR(VAR + X) with a word index.
        {"TOK_VAR_LOAD %v:x TOK_PUSH TOK_NUM %w:n TOK_ADD_VAR %v:y TOK_USHL TOK_ADD",
            "TOK_NUM $n TOK_ADD_VAR $y TOK_USHL TOK_ADD_VAR $x"},
        // VAR = VAR +/- 1 through the address/DPOKE sequence.
        {"TOK_VAR_ADDR %v:x TOK_SADDR TOK_VAR_LOAD %v:y TOK_PUSH TOK_NUM %w:one "
         "TOK_ADD TOK_DPOKE",
            "TOK_INCVAR $x",
            [](const peep_match &m) {
                return m.word("one") == 1 && m.varn("x") == m.varn("y");
            }},
        {"TOK_VAR_ADDR %v:x TOK_SADDR TOK_VAR_LOAD %v:y TOK_PUSH TOK_NUM %w:one "
         "TOK_SUB TOK_DPOKE",
            "TOK_DECVAR $x",
            [](const peep_match &m) {
                return m.word("one") == 1 && m.varn("x") == m.varn("y");
            }},
        // Boolean results already normalized by COMP_0 need no second test.
        {"TOK_NEQ TOK_COMP_0", "TOK_NEQ"},
        {"TOK_L_AND TOK_COMP_0", "TOK_L_AND"},
        {"TOK_L_OR TOK_COMP_0", "TOK_L_OR"},
        {"TOK_L_NOT TOK_COMP_0", "TOK_L_NOT"},
        {"TOK_COMP_0 TOK_COMP_0", "TOK_COMP_0"},
        {"TOK_EQ TOK_COMP_0", "TOK_EQ"},
        {"TOK_LT TOK_COMP_0", "TOK_LT"},
        {"TOK_GT TOK_COMP_0", "TOK_GT"},
        // NOT (A > x)  ==  A <= x  ->  A < x+1
        {"TOK_NUM %w:x TOK_GT TOK_L_NOT",
            [](const peep_match &m, peep_builder &b) {
                int x = m.word("x");
                if(x == 32637)
                    b.write("TOK_NUM %w TOK_BIT_OR TOK_COMP_0", 1);
                else
                    b.write("TOK_NUM %w TOK_LT", (x + 1) & 0xFFFF);
            }},
        // STRING[i, n>255] -> STRING[i, 255]
        {"TOK_NUM %w:x TOK_STR_IDX",
            [](const peep_match &m, peep_builder &b) {
                b.write("TOK_NUM %w TOK_STR_IDX", 255);
            },
            [](const peep_match &m) { return m.word("x") > 255; }},
        // NOT (A < x)  ==  A >= x  ->  A > x-1
        {"TOK_NUM %w:x TOK_LT TOK_L_NOT",
            [](const peep_match &m, peep_builder &b) {
                int x = m.word("x");
                if(x == -32768)
                    b.write("TOK_NUM %w TOK_BIT_OR TOK_COMP_0", 1);
                else
                    b.write("TOK_NUM %w TOK_GT", (x - 1) & 0xFFFF);
            }},
        // JUMP to the immediately following label.
        {"TOK_JUMP %l:target %L:label",
            "$label",
            [](const peep_match &m) {
                return m.text("target") == m.text("label");
            }},
        // Drop one dead item after an unconditional JUMP.
        {"TOK_JUMP %l:target %a:dead",
            "TOK_JUMP $target",
            [](const peep_match &m) { return !m.is_label("dead"); }},
        // Drop dead code after RET or END.
        {"TOK_RET %a:dead", "TOK_RET",
            [](const peep_match &m) { return !m.is_label("dead"); }},
        {"TOK_END %a:dead", "TOK_END",
            [](const peep_match &m) { return !m.is_label("dead"); }},
        // PRINT CHR$(X) is the same as PUT X.
        {"TOK_CHR TOK_PRINT_STR", "TOK_PUT"},
        // Join a constant string with a known-color PUT.
        {"TOK_CSTRING %s:s TOK_PRINT_STR TOK_NUM %w:x TOK_PUT",
            [](const peep_match &m, peep_builder &b) {
                b.write("TOK_CSTRING %s TOK_PRINT_STR",
                        m.text("s") + char(m.word("x") ^ m.state.print_color));
            },
            [](const peep_match &m) {
                return m.text("s").size() < 255 && m.state.print_color >= 0;
            }},
        {"TOK_CSTRING %s:s TOK_PRINT_STR TOK_BYTE_PUT %a:x",
            [](const peep_match &m, peep_builder &b) {
                b.write("TOK_CSTRING %s TOK_PRINT_STR",
                        m.text("s") + char(m.word("x") ^ m.state.print_color));
            },
            [](const peep_match &m) {
                return m.numeric("x") && m.text("s").size() < 255 &&
                       m.state.print_color >= 0;
            }},
        // Join two adjacent constant strings.
        {"TOK_CSTRING %s:s1 TOK_PRINT_STR TOK_CSTRING %s:s2 TOK_PRINT_STR",
            [](const peep_match &m, peep_builder &b) {
                b.write("TOK_CSTRING %s TOK_PRINT_STR",
                        m.text("s1") + m.text("s2"));
            },
            [](const peep_match &m) {
                return m.text("s1").size() + m.text("s2").size() < 256;
            }},
    };
}

// Implements a simple peephole optimizer
class peephole
{
  private:
    bool changed;
    std::vector<codew> &code;
    peep_rules rules;
    size_t current;
    // Matching functions for the peephole opt
    bool mtok(size_t idx, std::string tok)
    {
        idx += current;
        return idx < code.size() && code[idx].is_tok(tok);
    }
    bool mcbyte(size_t idx, std::string name)
    {
        idx += current;
        return idx < code.size() && code[idx].is_sbyte(name);
    }
    bool mcword(size_t idx, std::string name)
    {
        idx += current;
        return idx < code.size() && code[idx].is_sword(name);
    }
    bool mlabel(size_t idx)
    {
        idx += current;
        return idx < code.size() && code[idx].is_label();
    }
    bool mlblw(size_t idx)
    {
        idx += current;
        return idx < code.size() && code[idx].is_sword() &&
               code[idx].get_str().find("lbl") != std::string::npos;
    }
    bool mword(size_t idx)
    {
        idx += current;
        return idx < code.size() && code[idx].is_word();
    }
    bool mbyte(size_t idx)
    {
        idx += current;
        return idx < code.size() && code[idx].is_byte();
    }
    // Returns 256 if not a string
    unsigned mstring(size_t idx)
    {
        idx += current;
        if(idx < code.size() && code[idx].is_string())
            return code[idx].get_str().size();
        else
            return 256;
    }
    std::string lbl(size_t idx)
    {
        idx += current;
        if(idx < code.size() && code[idx].is_label())
            return code[idx].get_str();
        else
            return std::string();
    }
    std::string wlbl(size_t idx)
    {
        if(mlblw(idx))
            return code[idx + current].get_str();
        else
            return std::string();
    }
    int16_t val(size_t idx)
    {
        idx += current;
        if(idx < code.size())
            return code[idx].get_val();
        else
            return 0x8000;
    }
    int varn(size_t idx)
    {
        idx += current;
        if(idx < code.size())
            return code[idx].get_varn();
        else
            return 0x8000;
    }
    std::string str(size_t idx)
    {
        idx += current;
        if(idx < code.size())
            return code[idx].get_str();
        else
            return std::string();
    }
    void del(size_t idx)
    {
        if(idx + current < code.size())
        {
            changed = true;
            code.erase(code.begin() + idx + current);
        }
    }
    void ins_w(size_t idx, int16_t x)
    {
        int lnum = 0;
        changed = true;
        if(code.size() > idx + current)
            lnum = code[idx + current].linenum();
        code.insert(code.begin() + idx + current, codew::cword(x, lnum));
    }
    void ins_b(size_t idx, int16_t x)
    {
        int lnum = 0;
        changed = true;
        if(code.size() > idx + current)
            lnum = code[idx + current].linenum();
        code.insert(code.begin() + idx + current, codew::cbyte(x & 0xFF, lnum));
    }
    void ins_tok(size_t idx, std::string tok)
    {
        int lnum = 0;
        changed = true;
        if(code.size() > idx + current)
            lnum = code[idx + current].linenum();
        code.insert(code.begin() + idx + current, codew::ctok(tok, lnum));
    }
    void set_ws(size_t idx, std::string str)
    {
        changed = true;
        code[idx + current] = codew::cword(str, code[idx + current].linenum());
    }
    void set_w(size_t idx, int16_t x)
    {
        changed = true;
        code[idx + current] = codew::cword(x & 0xFFFF, code[idx + current].linenum());
    }
    void set_b(size_t idx, int16_t x)
    {
        changed = true;
        code[idx + current] = codew::cbyte(x & 0xFF, code[idx + current].linenum());
    }
    void set_tok(size_t idx, std::string tok)
    {
        changed = true;
        code[idx + current] = codew::ctok(tok, code[idx + current].linenum());
    }
    void set_string(size_t idx, std::string str)
    {
        changed = true;
        code[idx + current] = codew::cstring(str, code[idx + current].linenum());
    }
    void replace_range(size_t begin, size_t end, std::vector<codew> &&replacement)
    {
        changed = true;
        code.erase(code.begin() + begin, code.begin() + end);
        code.insert(code.begin() + begin, replacement.begin(), replacement.end());
    }
    // Transforms all "numeric" tokens to TOK_NUM, so that the next phases can
    // optimize
    void expand_numbers()
    {
        for(size_t i = 0; i < code.size(); i++)
        {
            // Skip non-tokens
            if(!code[i].is_tok())
                continue;

            current = i;
            // Sequences:
            //   TOK_BYTE / x
            if(mtok(0, "TOK_BYTE") && mbyte(1))
            {
                set_tok(0, "TOK_NUM");
                set_w(1, val(1));
                i++;
            }
            //   TOK_1
            else if(mtok(0, "TOK_1"))
            {
                set_tok(0, "TOK_NUM");
                ins_w(1, 1);
                i++;
            }
            //   TOK_0
            else if(mtok(0, "TOK_0"))
            {
                set_tok(0, "TOK_NUM");
                ins_w(1, 0);
                i++;
            }
        }
    }
    // Transforms small "numeric" tokens to TOK_BYTE, TOK_1 and TOK_0
    void shorten_numbers()
    {
        for(size_t i = 0; i < code.size(); i++)
        {
            // Skip non-tokens
            if(!code[i].is_tok())
                continue;

            current = i;
            // Sequences:
            //   TOK_NUM / x == 0
            if(mtok(0, "TOK_NUM") && mword(1) && val(1) == 0)
            {
                del(1);
                set_tok(0, "TOK_0");
            }
            //   TOK_NUM / x == 1
            else if(mtok(0, "TOK_NUM") && mword(1) && val(1) == 1)
            {
                del(1);
                set_tok(0, "TOK_1");
            }
            //   TOK_NUM / x == -1
            else if(mtok(0, "TOK_NUM") && mword(1) && val(1) == -1)
            {
                set_tok(0, "TOK_1");
                set_tok(1, "TOK_NEG");
            }
            //   TOK_NUM / x < 256
            else if(mtok(0, "TOK_NUM") && mword(1) && 0 == (val(1) & ~0xFF))
            {
                set_tok(0, "TOK_BYTE");
                set_b(1, val(1));
            }
        }
    }
    // Expands PUSH and SADDR tokens
    void expand_push()
    {
        for(size_t i = 0; i < code.size(); i++)
        {
            // Skip non-tokens
            if(!code[i].is_tok())
                continue;

            current = i;
            if(mtok(0, "TOK_PUSH_BYTE"))
            {
                set_tok(0, "TOK_BYTE");
                ins_tok(0, "TOK_PUSH");
            }
            else if(mtok(0, "TOK_PUSH_NUM"))
            {
                set_tok(0, "TOK_NUM");
                ins_tok(0, "TOK_PUSH");
            }
            else if(mtok(0, "TOK_PUSH_0"))
            {
                set_tok(0, "TOK_0");
                ins_tok(0, "TOK_PUSH");
            }
            else if(mtok(0, "TOK_PUSH_1"))
            {
                set_tok(0, "TOK_1");
                ins_tok(0, "TOK_PUSH");
            }
            else if(mtok(0, "TOK_PUSH_VAR_LOAD"))
            {
                set_tok(0, "TOK_VAR_LOAD");
                ins_tok(0, "TOK_PUSH");
            }
            else if(mtok(0, "TOK_VAR_SADDR"))
            {
                set_tok(0, "TOK_VAR_ADDR");
                ins_tok(2, "TOK_SADDR");
            }
        }
    }
    // Transforms print of small constant strings to sequence of BYTE_PUT
    void print_chars()
    {
        int print_color = 0;
        for(size_t i = 0; i < code.size(); i++)
        {
            current = i;
            // Track current print color
            if(mtok(2, "TOK_BYTE_POKE") && mcbyte(3, "PRINT_COLOR"))
            {
                if(mtok(0, "TOK_NUM") && mword(1))
                    print_color = val(1);
                else
                    print_color = -1;
            }
            if(print_color >= 0 && mtok(0, "TOK_CSTRING") && mstring(1) < 3 &&
               mtok(2, "TOK_PRINT_STR"))
            {
                auto s = str(1);
                del(2);
                del(1);
                del(0);
                for(char c : s)
                {
                    ins_tok(0, "TOK_BYTE_PUT");
                    ins_b(1, (c ^ print_color) & 0xFF);
                    current += 2;
                }
            }
        }
    }
    // Folds PUSH followed by known sequences
    void fold_push()
    {
        for(size_t i = 0; i < code.size(); i++)
        {
            current = i;
            if(mtok(0, "TOK_PUSH"))
            {
                //   TOK_BYTE
                if(mtok(1, "TOK_BYTE"))
                {
                    set_tok(1, "TOK_PUSH_BYTE");
                    del(0);
                }
                //   TOK_NUM
                else if(mtok(1, "TOK_NUM"))
                {
                    set_tok(1, "TOK_PUSH_NUM");
                    del(0);
                }
                //   TOK_1
                else if(mtok(1, "TOK_1"))
                {
                    set_tok(1, "TOK_PUSH_1");
                    del(0);
                }
                //   TOK_0
                else if(mtok(1, "TOK_0"))
                {
                    set_tok(1, "TOK_PUSH_0");
                    del(0);
                }
                //   TOK_VAR_LOAD / x
                if(mtok(1, "TOK_VAR_LOAD"))
                {
                    set_tok(1, "TOK_PUSH_VAR_LOAD");
                    del(0);
                }
            }
        }
    }
    // Folds SADDR after known sequences
    void fold_saddr()
    {
        for(size_t i = 0; i < code.size(); i++)
        {
            current = i;
            if(mtok(0, "TOK_VAR_ADDR") && mtok(2, "TOK_SADDR"))
            {
                set_tok(0, "TOK_VAR_SADDR");
                del(2);
            }
        }
    }
    // Remove SADDR save/restore pairs around calls when no lvalue address is
    // pending.  A push starts a region where SADDR is already saved, so nested
    // calls inside its arguments do not need their own save/restore.
    void remove_saddr_saves()
    {
        struct saved
        {
            size_t pos;
            bool live;
        };
        std::vector<saved> stack;
        std::vector<bool> remove(code.size(), false);
        bool live = false;
        for(size_t i = 0; i < code.size(); i++)
        {
            if(code[i].is_label())
            {
                live = false;
                continue;
            }
            if(!code[i].is_tok())
                continue;
            auto tok = code[i].get_tok();
            if(tok == "TOK_SADDR" || tok == "TOK_VAR_SADDR")
                live = true;
            else if(tok == "TOK_POKE" || tok == "TOK_DPOKE" ||
                    tok == "TOK_NUM_POKE" || tok == "TOK_BYTE_POKE" ||
                    tok == "TOK_FP_STORE" || tok == "TOK_COPY_STR" ||
                    tok == "TOK_INC" || tok == "TOK_DEC" || tok == "TOK_END")
                live = false;
            else if(tok == "TOK_PUSH_SADDR")
            {
                stack.push_back({i, live});
                if(!live)
                    remove[i] = true;
                // Inside the saved region, nested calls do not need to save it.
                live = false;
            }
            else if(tok == "TOK_POP_SADDR")
            {
                if(stack.empty())
                    continue;
                auto saved = stack.back();
                stack.pop_back();
                if(!saved.live)
                    remove[i] = true;
                live = saved.live;
            }
        }
        for(size_t i = code.size(); i-- > 0;)
            if(remove[i])
                code.erase(code.begin() + i);
    }

    // Unused labels removal
    void remove_unused_labels()
    {
        // Go through code accumulating all label expressions
        std::set<std::string> labels;
        for(auto &c : code)
        {
            if(c.is_sword())
                labels.insert(c.get_str());
        }
        // And go through code removing labels not in the list
        for(size_t i = 0; i < code.size(); i++)
        {
            current = i;
            if(mlabel(0) && !labels.count(lbl(0)))
            {
                del(0);
                i--;
            }
        }
    }
    // Remove extra IOCHN0 tokens
    void trace_iochn()
    {
        // This is the calculated current I/O channel
        int ioch = 0;
        for(current = 0; current < code.size(); current++)
        {
            if(!code[current].is_tok())
            {
                if(mlabel(0))
                    ioch = 0; // Assume 0 after any label or CALL
                continue;
            }
            if(mtok(0, "TOK_CALL"))
                ioch = 0; // Assume 0 after any label or CALL
            else if(mtok(0, "TOK_NUM") && mword(1) && mtok(2, "TOK_IOCHN"))
            {
                if(ioch == val(1))
                {
                    // Remove redundant set IOCHN
                    del(2);
                    del(1);
                    del(0);
                    current--;
                }
                else
                {
                    ioch = val(1);
                    current += 2;
                }
            }
            else if(mtok(0, "TOK_IOCHN"))
            {
                ioch = -1;
            }
            else if(mtok(0, "TOK_NUM") && mword(1) && mtok(2, "TOK_IOCHN") &&
                    mtok(3, "TOK_NUM") && mword(4) && mtok(5, "TOK_IOCHN"))
            {
                // Setting I/O channel just after IOCHN, delete redundant one
                del(2);
                del(1);
                del(0);
                current--;
            }
        }
    }

    // Jump threading optimization.
    // Replace JUMP to RET or another JUMP with a direct jump to target.
    void replace_label_targets()
    {
        // Build a MAP of label that go to another target
        std::map<std::string, std::string> tgt;
        for(current = 0; current < code.size(); current++)
        {
            if(mlabel(0))
            {
                std::string l = lbl(0);
                size_t i;
                // Search target - next "normal" instruction
                for(i = 1; i < code.size() - current; i++)
                    if(!mlabel(i))
                        break;
                    else
                        tgt[l] = lbl(i);
                if(mtok(i, "TOK_RET"))
                    tgt[l] = "__TOK_RET__";
                else if(mtok(i, "TOK_JUMP") && mlblw(i + 1))
                    tgt[l] = wlbl(i + 1);
            }
        }
        // Now, replace JUMPS
        if(tgt.size())
        {
            for(current = 0; current < code.size(); current++)
            {
                if(!code[current].is_tok())
                    continue;

                if((mtok(0, "TOK_CJUMP") || mtok(0, "TOK_CNJUMP") ||
                    mtok(0, "TOK_JUMP")) &&
                   mlblw(1) && tgt.find(wlbl(1)) != tgt.end())
                {
                    std::string t = tgt[wlbl(1)];
                    if(t == "__TOK_RET__")
                    {
                        // We can only replace JUMP to RET with RET, not ConditionalJUMP
                        if(mtok(0, "TOK_JUMP"))
                        {
                            set_tok(0, "TOK_RET");
                            del(1);
                        }
                        else if(mtok(0, "TOK_CJUMP"))
                        {
                            set_tok(0, "TOK_CRET");
                            del(1);
                        }
                        else if(mtok(0, "TOK_CNJUMP"))
                        {
                            set_tok(0, "TOK_CNRET");
                            del(1);
                        }
                    }
                    else if(wlbl(1) != t)
                        set_ws(1, t);
                }
            }
        }
    }

  public:
    peephole(std::vector<codew> &code)
        : code(code), rules("main", make_peephole_rules()), current(0)
    {
        expand_push();
        expand_numbers();
        do
        {
            changed = false;
            remove_unused_labels();
            replace_label_targets();
            trace_iochn();
            peep_state state;

            for(size_t i = 0; i < code.size(); i++)
            {
                // Only go through tokens
                if(!code[i].is_tok())
                    continue;

                current = i;

                // Apply compiled token-rewrite rules.
                {
                    std::vector<codew> replacement;
                    size_t begin, end;
                    bool modified;
                    if(rules.apply(code, i, state, replacement, begin, end,
                                   modified))
                    {
                        if(modified)
                        {
                            replace_range(begin, end, std::move(replacement));
                            i--;
                        }
                        continue;
                    }
                }

            }
        } while(changed);
        print_chars();
        shorten_numbers();
        fold_push();
        fold_saddr();
        remove_saddr_saves();
    }
};

void do_peephole(std::vector<codew> &code)
{
    peephole pp(code);
}
