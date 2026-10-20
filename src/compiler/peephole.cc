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
        // Constant byte address with an arbitrary value expression.
        {"TOK_NUM %c:a TOK_SADDR %e:value:TOK_POKE TOK_POKE",
            [](const peep_match &m, peep_builder &b) {
                if(!b.valid_span(m, "value"))
                {
                    b.keep();
                    return;
                }
                b.raw(m, "value");
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

static std::vector<peep_rule> make_expand_number_rules()
{
    return {
        {"TOK_BYTE %b:x",
            [](const peep_match &m, peep_builder &b) {
                b.write("TOK_NUM %w", m.word("x"));
            }},
        {"TOK_1",
            [](const peep_match &, peep_builder &b) {
                b.write("TOK_NUM %w", 1);
            }},
        {"TOK_0",
            [](const peep_match &, peep_builder &b) {
                b.write("TOK_NUM %w", 0);
            }},
    };
}

static std::vector<peep_rule> make_shorten_number_rules()
{
    return {
        {"TOK_NUM %w:x", "TOK_0",
            [](const peep_match &m) { return m.word("x") == 0; }},
        {"TOK_NUM %w:x", "TOK_1",
            [](const peep_match &m) { return m.word("x") == 1; }},
        {"TOK_NUM %w:x", "TOK_1 TOK_NEG",
            [](const peep_match &m) { return m.word("x") == -1; }},
        {"TOK_NUM %w:x",
            [](const peep_match &m, peep_builder &b) {
                b.write("TOK_BYTE %b", m.word("x"));
            },
            [](const peep_match &m) {
                return 0 == (m.word("x") & ~0xFF);
            }},
    };
}

static std::vector<peep_rule> make_expand_push_rules()
{
    return {
        {"TOK_PUSH_BYTE", "TOK_PUSH TOK_BYTE"},
        {"TOK_PUSH_NUM", "TOK_PUSH TOK_NUM"},
        {"TOK_PUSH_0", "TOK_PUSH TOK_0"},
        {"TOK_PUSH_1", "TOK_PUSH TOK_1"},
        {"TOK_PUSH_VAR_LOAD", "TOK_PUSH TOK_VAR_LOAD"},
        {"TOK_VAR_SADDR %v:x", "TOK_VAR_ADDR $x TOK_SADDR"},
    };
}

static std::vector<peep_rule> make_fold_push_rules()
{
    return {
        {"TOK_PUSH TOK_BYTE", "TOK_PUSH_BYTE"},
        {"TOK_PUSH TOK_NUM", "TOK_PUSH_NUM"},
        {"TOK_PUSH TOK_1", "TOK_PUSH_1"},
        {"TOK_PUSH TOK_0", "TOK_PUSH_0"},
        {"TOK_PUSH TOK_VAR_LOAD", "TOK_PUSH_VAR_LOAD"},
    };
}

static std::vector<peep_rule> make_fold_saddr_rules()
{
    return {
        {"TOK_VAR_ADDR %v:x TOK_SADDR", "TOK_VAR_SADDR $x"},
    };
}

static bool can_retarget(const peep_match &m)
{
    auto it = m.state.tgt.find(m.text("target"));
    return it != m.state.tgt.end() && it->second != m.text("target");
}

static void retarget(const peep_match &m, peep_builder &b,
                     const char *jump, const char *ret)
{
    auto it = m.state.tgt.find(m.text("target"));
    if(it == m.state.tgt.end())
        return;
    if(it->second == "__TOK_RET__")
        b.tok(ret);
    else
    {
        b.tok(jump);
        b.symbol(it->second);
    }
}

static std::vector<peep_rule> make_label_target_rules()
{
    return {
        {"TOK_JUMP %l:target",
            [](const peep_match &m, peep_builder &b) {
                retarget(m, b, "TOK_JUMP", "TOK_RET");
            },
            can_retarget},
        {"TOK_CJUMP %l:target",
            [](const peep_match &m, peep_builder &b) {
                retarget(m, b, "TOK_CJUMP", "TOK_CRET");
            },
            can_retarget},
        {"TOK_CNJUMP %l:target",
            [](const peep_match &m, peep_builder &b) {
                retarget(m, b, "TOK_CNJUMP", "TOK_CNRET");
            },
            can_retarget},
    };
}

static std::vector<peep_rule> make_print_char_rules()
{
    return {
        {"TOK_NUM %w:x TOK_BYTE_POKE %B:color",
            [](const peep_match &m, peep_builder &b) {
                m.state.print_color = m.word("x");
                m.state.color_pending = true;
                b.keep();
            },
            [](const peep_match &m) {
                return m.text("color") == "PRINT_COLOR";
            }},
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
        {"TOK_CSTRING %s:s TOK_PRINT_STR",
            [](const peep_match &m, peep_builder &b) {
                for(char c : m.text("s"))
                    b.write("TOK_BYTE_PUT %b", c ^ m.state.print_color);
            },
            [](const peep_match &m) {
                return m.text("s").size() < 3 && m.state.print_color >= 0;
            }},
    };
}

static std::vector<peep_rule> make_iochn_rules()
{
    return {
        {"TOK_CALL",
            [](const peep_match &m, peep_builder &b) {
                m.state.ioch = 0;
                m.state.ioch_pending = false;
                b.keep();
            }},
        {"TOK_NUM %w:x TOK_IOCHN",
            [](const peep_match &m, peep_builder &b) {
                int x = m.word("x");
                if(x == m.state.ioch)
                    return;
                m.state.ioch = x;
                m.state.ioch_pending = true;
                b.keep();
            }},
        {"TOK_IOCHN",
            [](const peep_match &m, peep_builder &b) {
                if(m.state.ioch_pending)
                    m.state.ioch_pending = false;
                else
                    m.state.ioch = -1;
                b.keep();
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
    peep_rules expand_push_rules;
    peep_rules expand_rules;
    peep_rules shorten_rules;
    peep_rules fold_push_rules;
    peep_rules fold_saddr_rules;
    peep_rules label_target_rules;
    peep_rules print_char_rules;
    peep_rules iochn_rules;
    void replace_range(size_t begin, size_t end, std::vector<codew> &&replacement)
    {
        changed = true;
        code.erase(code.begin() + begin, code.begin() + end);
        code.insert(code.begin() + begin, replacement.begin(), replacement.end());
    }
    void apply_rules_at(size_t &i, peep_rules &table, peep_state &state)
    {
        std::vector<codew> replacement;
        size_t begin, end;
        bool modified;
        if(!table.apply(code, i, state, replacement, begin, end, modified))
            return;
        if(modified)
        {
            replace_range(begin, end, std::move(replacement));
            i--;
        }
    }
    void run_rules(peep_rules &table, peep_state &state)
    {
        for(size_t i = 0; i < code.size(); i++)
        {
            if(code[i].is_label())
                state.on_label();
            if(!code[i].is_tok())
                continue;
            apply_rules_at(i, table, state);
        }
    }
    void run_rules(peep_rules &table)
    {
        peep_state state;
        run_rules(table, state);
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
            if(code[i].is_label() && !labels.count(code[i].get_str()))
            {
                changed = true;
                code.erase(code.begin() + i);
                i--;
            }
        }
    }
    // Jump threading optimization.
    // Replace JUMP to RET or another JUMP with a direct jump to target.
    void build_label_targets(peep_state &state)
    {
        state.tgt.clear();
        // Map each label to the instruction it falls through to.
        for(size_t current = 0; current < code.size(); current++)
        {
            if(code[current].is_label())
            {
                std::string l = code[current].get_str();
                size_t i = current + 1;
                // Search target - next "normal" instruction
                for(; i < code.size(); i++)
                    if(!code[i].is_label())
                        break;
                    else
                        state.tgt[l] = code[i].get_str();
                if(i < code.size())
                {
                    auto &next = code[i];
                    if(next.is_tok("TOK_RET"))
                        state.tgt[l] = "__TOK_RET__";
                    else if(next.is_tok("TOK_JUMP") && i + 1 < code.size() &&
                            code[i + 1].is_sword() &&
                            code[i + 1].get_str().find("lbl") !=
                                std::string::npos)
                        state.tgt[l] = code[i + 1].get_str();
                }
            }
        }
    }

  public:
    peephole(std::vector<codew> &code)
        : code(code), rules("main", make_peephole_rules()),
          expand_push_rules("expand-push", make_expand_push_rules()),
          expand_rules("expand-number", make_expand_number_rules()),
          shorten_rules("shorten-number", make_shorten_number_rules()),
          fold_push_rules("fold-push", make_fold_push_rules()),
          fold_saddr_rules("fold-saddr", make_fold_saddr_rules()),
          label_target_rules("label-target", make_label_target_rules()),
          print_char_rules("print-char", make_print_char_rules()),
          iochn_rules("iochn", make_iochn_rules())
    {
        run_rules(expand_push_rules);
        run_rules(expand_rules);
        do
        {
            changed = false;
            remove_unused_labels();
            peep_state state;
            build_label_targets(state);
            run_rules(label_target_rules, state);
            run_rules(iochn_rules);
            run_rules(rules, state);
        } while(changed);
        run_rules(print_char_rules);
        run_rules(shorten_rules);
        run_rules(fold_push_rules);
        run_rules(fold_saddr_rules);
        remove_saddr_saves();
    }
};

void do_peephole(std::vector<codew> &code)
{
    peephole pp(code);
}
