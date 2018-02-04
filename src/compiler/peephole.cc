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

// peephole.cc: Peephole optimizer


// Implements a simple peephole optimizer
class peephole
{
    private:
        bool changed;
        std::vector<codew> &code;
        size_t current;
        // Matching functions for the peephole opt
        bool mtok(size_t idx, enum tokens tok)
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
        std::string lbl(size_t idx)
        {
            idx += current;
            if ( idx < code.size() && code[idx].is_label() )
                return code[idx].get_str();
            else
                return std::string();
        }
        std::string wlbl(size_t idx)
        {
            if ( mlblw(idx) )
                return code[idx+current].get_str();
            else
                return std::string();
        }
        int16_t val(size_t idx)
        {
            idx += current;
            if ( idx < code.size() )
                return code[idx].get_val();
            else
                return 0x8000;
        }
        void del(size_t idx)
        {
            changed = true;
            code.erase( code.begin() + idx + current);
        }
        void ins_w(size_t idx, int16_t x)
        {
            int lnum = 0;
            changed = true;
            if( code.size() > idx + current )
                lnum = code[idx+current].linenum();
            code.insert(code.begin() + idx + current, codew::cword(x, lnum));
        }
        void set_w(size_t idx, int16_t x)
        {
            changed = true;
            code[idx+current] = codew::cword(x&0xFFFF, code[idx+current].linenum());
        }
        void set_b(size_t idx, int16_t x)
        {
            changed = true;
            code[idx+current] = codew::cbyte(x&0xFF, code[idx+current].linenum());
        }
        void set_tok(size_t idx, enum tokens tok)
        {
            changed = true;
            code[idx+current] = codew::ctok(tok, code[idx+current].linenum());
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
                if( mtok(0,TOK_BYTE) && mbyte(1) )
                {
                    set_tok(0, TOK_NUM); set_w(1, val(1)); i++;
                }
                //   TOK_1
                else if( mtok(0,TOK_1) )
                {
                    set_tok(0, TOK_NUM); ins_w(1, 1); i++;
                }
                //   TOK_0
                else if( mtok(0,TOK_0) )
                {
                    set_tok(0, TOK_NUM); ins_w(1, 0); i++;
                }
                //   TOK_NUM / non numeric constant
                else if( mtok(0,TOK_NUM) )
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
                if( mtok(0,TOK_NUM) && mword(1) && val(1) == 0 )
                {
                    del(1); set_tok(0, TOK_0);
                }
                //   TOK_NUM / x == 1
                else if( mtok(0,TOK_NUM) && mword(1) && val(1) == 1 )
                {
                    del(1); set_tok(0, TOK_1);
                }
                //   TOK_NUM / x == -1
                else if( mtok(0,TOK_NUM) && mword(1) && val(1) == -1 )
                {
                    set_tok(0, TOK_1); set_tok(1, TOK_NEG);
                }
                //   TOK_NUM / x < 256
                else if( mtok(0,TOK_NUM) && mword(1) && 0 == (val(1) & ~0xFF) )
                {
                    set_tok(0, TOK_BYTE); set_b(1, val(1));
                }
            }
        }
        // Unused labels removal
        void remove_unused_labels()
        {
            // Go through code accumulating all label expressions
            std::set<std::string> labels;
            for(auto &c: code)
            {
                if( c.is_sword() )
                    labels.insert(c.get_str());
            }
            // And go through code removing labels not in the list
            for(size_t i=0; i<code.size(); i++)
            {
                current = i;
                if( mlabel(0) && !labels.count(lbl(0)) )
                {
                    del(0);
                    i--;
                }
            }
        }
    public:
        peephole(std::vector<codew> &code):
            code(code), current(0)
        {
            expand_numbers();
            do
            {
                changed = false;
                remove_unused_labels();

                for(size_t i=0; i<code.size(); i++)
                {
                    current = i;
                    // Sequences:
                    //   TOK_NUM / x / TOK_NEG  -> TOK_NUM / -x
                    if( mtok(0,TOK_NUM) && mword(1) && mtok(2,TOK_NEG) )
                    {
                        del(2); set_w(1, - val(1)); i--;
                        continue;
                    }
                    //   TOK_NUM / x / TOK_USHL  -> TOK_NUM / 2*x
                    if( mtok(0,TOK_NUM) && mword(1) && mtok(2,TOK_USHL) )
                    {
                        del(2); set_w(1, 2 * val(1)); i--;
                        continue;
                    }
                    //   TOK_NUM / x / TOK_SHL8  -> TOK_NUM / 256*x
                    if( mtok(0,TOK_NUM) && mword(1) && mtok(2,TOK_SHL8) )
                    {

                        del(2); set_w(1, 256 * val(1)); i--;
                        continue;
                    }
                    //   TOK_NUM / 4 / TOK_MUL   -> TOK_USHL TOK_USHL
                    if( mtok(0,TOK_NUM) && mword(1) && val(1) == 4 && mtok(2,TOK_MUL) )
                    {
                        del(2); set_tok(1, TOK_USHL); set_tok(0, TOK_USHL); i--;
                        continue;
                    }
                    //   TOK_NUM / 2 / TOK_MUL   -> TOK_USHL
                    if( mtok(0,TOK_NUM) && mword(1) && val(1) == 2 && mtok(2,TOK_MUL) )
                    {
                        del(2); del(1); set_tok(0, TOK_USHL); i--;
                        continue;
                    }
                    //   TOK_NUM / 1 / TOK_MUL   -> -
                    if( mtok(0,TOK_NUM) && mword(1) && val(1) == 1 && mtok(2,TOK_MUL) )
                    {
                        del(2); del(1); del(0); i--;
                        continue;
                    }
                    //   TOK_NUM / 1 / TOK_DIV   -> -
                    if( mtok(0,TOK_NUM) && mword(1) && val(1) == 1 && mtok(2,TOK_DIV) )
                    {
                        del(2); del(1); del(0); i--;
                        continue;
                    }
                    //   TOK_NUM / 0 / TOK_ADD   -> -
                    if( mtok(0,TOK_NUM) && mword(1) && val(1) == 0 && mtok(2,TOK_ADD) )
                    {
                        del(2); del(1); del(0); i--;
                        continue;
                    }
                    //   TOK_NUM / 0 / TOK_SUB   -> -
                    if( mtok(0,TOK_NUM) && mword(1) && val(1) == 0 && mtok(2,TOK_SUB) )
                    {
                        del(2); del(1); del(0); i--;
                        continue;
                    }
                    //   TOK_NUM / 0 / TOK_NEQ   -> TOK_COMP_0
                    if( mtok(0,TOK_NUM) && mword(1) && val(1) == 0 && mtok(2,TOK_NEQ) )
                    {
                        del(2); del(1); set_tok(0,TOK_COMP_0); i--;
                        continue;
                    }
                    //   TOK_BYTE / 0 / TOK_EQ   -> TOK_COMP_0 TOK_L_NOT
                    if( mtok(0,TOK_NUM) && mword(1) && val(1) == 0 && mtok(2,TOK_EQ) )
                    {
                        del(2); set_tok(0,TOK_COMP_0); set_tok(1, TOK_L_NOT); i--;
                        continue;
                    }
                    //   TOK_NUM / x / TOK_NUM / y / TOK_ADD   -> TOK_NUM (x+y)
                    if( mtok(0,TOK_NUM) && mword(1) && mtok(2,TOK_NUM) && mword(3) && mtok(4,TOK_ADD) )
                    {
                        set_tok(0, TOK_NUM); set_w(1, val(1)+val(3)); del(4); del(3); del(2); i--;
                        continue;
                    }
                    //   TOK_NUM / x / TOK_NUM / y / TOK_SUB   -> TOK_NUM (x-y)
                    if( mtok(0,TOK_NUM) && mword(1) && mtok(2,TOK_NUM) && mword(3) && mtok(4,TOK_SUB) )
                    {
                        set_tok(0, TOK_NUM); set_w(1, val(1)-val(3)); del(4); del(3); del(2); i--;
                        continue;
                    }
                    //   TOK_NUM / x / TOK_NUM / y / TOK_MUL   -> TOK_NUM (x*y)
                    if( mtok(0,TOK_NUM) && mword(1) && mtok(2,TOK_NUM) && mword(3) && mtok(4,TOK_MUL) )
                    {
                        set_tok(0, TOK_NUM); set_w(1, val(1) * val(3)); del(4); del(3); del(2); i--;
                        continue;
                    }
                    //   TOK_NUM / x / TOK_NUM / y / TOK_DIV   -> TOK_NUM (x/y)
                    if( mtok(0,TOK_NUM) && mword(1) && mtok(2,TOK_NUM) && mword(3) && mtok(4,TOK_DIV) )
                    {
                        int16_t div = val(3);
                        if( div )
                            div = val(1) / div;
                        else if( val(1) < 0 )
                            div = 1;  // Probably a bug in the division routine, but we emulate the result
                        else
                            div = -1;
                        set_tok(0, TOK_NUM); set_w(1, div); del(4); del(3); del(2); i--;
 continue;
                    }
                    //   TOK_NUM / x / TOK_NUM / y / TOK_MOD   -> TOK_NUM (x%y)
                    if( mtok(0,TOK_NUM) && mword(1) && mtok(2,TOK_NUM) && mword(3) && mtok(4,TOK_MOD) )
                    {
                        int16_t div = val(3);
                        if( div )
                            div = val(1) % div;
                        else
                            div = val(1);  // Probably a bug in the division routine, but we emulate the result
                        set_tok(0, TOK_NUM); set_w(1, div); del(4); del(3); del(2); i--;
 continue;
                    }
                    //   TOK_NUM / x / TOK_NUM / y / TOK_BIT_AND   -> TOK_NUM (x&y)
                    if( mtok(0,TOK_NUM) && mword(1) && mtok(2,TOK_NUM) && mword(3) && mtok(4,TOK_BIT_AND) )
                    {
                        set_tok(0, TOK_NUM); set_w(1, val(1) & val(3)); del(4); del(3); del(2); i--;
                        continue;
                    }
                    //   TOK_NUM / x / TOK_NUM / y / TOK_BIT_OR   -> TOK_NUM (x|y)
                    if( mtok(0,TOK_NUM) && mword(1) && mtok(2,TOK_NUM) && mword(3) && mtok(4,TOK_BIT_OR) )
                    {
                        set_tok(0, TOK_NUM); set_w(1, val(1) | val(3)); del(4); del(3); del(2); i--;
                        continue;
                    }
                    //   TOK_NUM / x / TOK_NUM / y / TOK_BIT_EXOR   -> TOK_NUM (x^y)
                    if( mtok(0,TOK_NUM) && mword(1) && mtok(2,TOK_NUM) && mword(3) && mtok(4,TOK_BIT_EXOR) )
                    {
                        set_tok(0, TOK_NUM); set_w(1, val(1) ^ val(3)); del(4); del(3); del(2); i--;
                        continue;
                    }
                    //  VAR + VAR    ==>   2 * VAR
                    //   TOK_VAR / x / TOK_VAR / x / TOK_ADD   -> TOK_VAR / x / TOK_USHL
                    if( mtok(0,TOK_VAR_LOAD) && mbyte(1) && mtok(2,TOK_VAR_LOAD) && mbyte(3) && mtok(4,TOK_ADD) && val(1) == val(3) )
                    {
                        set_tok(2, TOK_USHL); del(4); del(3); i--;
                        continue;
                    }
                    //  VAR = VAR + 1   ==>  INC VAR
                    //   TOK_VAR_A / x / TOK_VAR / x / TOK_NUM / 1 / TOK_ADD / TOK_DPOKE
                    //        -> TOK_VAR_A / x / TOK_INC
                    if( mtok(0,TOK_VAR_ADDR) && mbyte(1) &&
                        mtok(2,TOK_VAR_LOAD) && mbyte(3) &&
                        mtok(4,TOK_NUM) && mword(5) && val(5) == 1 &&
                        mtok(6,TOK_ADD) && mtok(7,TOK_DPOKE) &&
                        val(1) == val(3) )
                    {
                        set_tok(2, TOK_INC); del(7); del(6); del(5); del(4); del(3); i--;
                        continue;
                    }
                    //  VAR = VAR - 1   ==>  DEC VAR
                    //   TOK_VAR_A / x / TOK_VAR / x / TOK_NUM / 1 / TOK_SUB / TOK_DPOKE
                    //        -> TOK_VAR_A / x / TOK_DEC
                    if( mtok(0,TOK_VAR_ADDR) && mbyte(1) &&
                        mtok(2,TOK_VAR_LOAD) && mbyte(3) &&
                        mtok(4,TOK_NUM) && mword(5) && val(5) == 1 &&
                        mtok(6,TOK_SUB) && mtok(7,TOK_DPOKE) &&
                        val(1) == val(3) )
                    {
                        set_tok(2, TOK_DEC); del(7); del(6); del(5); del(4); del(3); i--;
                        continue;
                    }
                    //   TOK_BYTE / IOCHN / TOK_NUM / 0 / TOK_POKE  -> TOK_IOCHN0
                    if( mtok(0,TOK_BYTE) && mcbyte(1, "IOCHN") &&
                        mtok(2,TOK_NUM) && mword(3) && val(3) == 0 && mtok(4,TOK_POKE) )
                    {
                        set_tok(0, TOK_IOCHN0); del(4); del(3); del(2); del(1); i--;
                        continue;
                    }
                    // NOT NOT A -> A
                    //   TOK_L_NOT / TOK_L_NOT -> TOK_COMP_0
                    if( mtok(0, TOK_L_NOT) && mtok(1, TOK_L_NOT) )
                    {
                        set_tok(0, TOK_COMP_0); del(1);
                        continue;
                    }
                    // NOT A=B -> A<>B
                    //   TOK_EQ / TOK_L_NOT -> TOK_NEQ
                    if( mtok(0, TOK_EQ) && mtok(1, TOK_L_NOT) )
                    {
                        set_tok(0, TOK_NEQ); del(1);
                        continue;
                    }
                    // NOT A<>B -> A=B
                    //   TOK_NEQ / TOK_L_NOT -> TOK_EQ
                    if( mtok(0, TOK_NEQ) && mtok(1, TOK_L_NOT) )
                    {
                        set_tok(0, TOK_EQ); del(1);
                        continue;
                    }
                    // (bool) != 0  -> (bool)
                    //   TOK_L_AND | TOK_L_OR | TOK_L_NOT |
                    //   TOK_NEQ | TOK_COMP_0 | TOK_EQ |
                    //   TOK_LT | TOK_GT
                    //       / TOK_COMP_0   ->  remove TOK_COMP_0
                    if( (mtok(0, TOK_NEQ) ||
                         mtok(0, TOK_L_AND) ||
                         mtok(0, TOK_L_OR) ||
                         mtok(0, TOK_L_NOT) ||
                         mtok(0, TOK_COMP_0) ||
                         mtok(0, TOK_EQ) ||
                         mtok(0, TOK_LT) ||
                         mtok(0, TOK_GT)) && mtok(1, TOK_COMP_0) )
                    {
                        del(1);
                        continue;
                    }
                    // CALL xxxxx / RETURN  ->  JUMP xxxxx
                    //   TOK_CALL / x / TOK_RET -> TOK_JUMP / x
                    if( mtok(0,TOK_CALL) && mtok(2,TOK_RET) )
                    {
                        set_tok(0, TOK_JUMP); del(2);
                        continue;
                    }
                    // Bypass CJUMP over another JUMP
                    //   TOK_CJUMP / x / TOK_JUMP / y / LABEL x
                    //     -> TOK_L_NOT / TOK_CJUMP / y / LABEL x
                    if( mtok(0,TOK_CJUMP) && mtok(2,TOK_JUMP) && mlabel(4) &&
                        lbl(4) == wlbl(1) )
                    {
                        set_tok(0, TOK_L_NOT); set_tok(2, TOK_CJUMP); del(1);
                        continue;
                    }
                    // Remove dead code after a JUMP
                    if( mtok(0,TOK_JUMP) && !mlabel(2) )
                    {
                        del(2);
                        continue;
                    }
                }
            } while(changed);
            shorten_numbers();
        }
};

