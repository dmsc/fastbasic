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

// codegen.cc: 6502 native code generator

// Very simple code generator, emits 6502 assembly code implementing
// the tokens

#include "basic.h" // enum tokens

class codegen
{
    private:
        std::string last_usr_lbl;
        std::vector<codew> &code;
        std::set<std::string> &globals;
        std::set<std::string> &globals_zp;
        std::vector<std::string> const_data;
        std::vector<std::string> asm_code;
        std::map<int, std::string> vars;
        unsigned pos;
        bool stack_y;
        int stack_y_off;
        int lbl_num;

        std::string new_label()
        {
            return std::string("c_lbl_") + std::to_string(lbl_num++);
        }

        std::string call_str(std::string name, bool use_y = true)
        {
            if( name.substr(0,4) == "TOK_" )
                name.replace(0,3,"EXE");
            globals.insert(name);
            if( use_y )
                stack_y = false;
            return std::string(" JSR ") + name;
        }

        std::vector<std::string> call(std::string name)
        {
            return { call_str(name) };
        }

        std::vector<std::string> use_stack(std::vector<std::string> c, int pop)
        {
            if ( !stack_y || stack_y_off > 1 || stack_y_off < -1 )
                c.insert(c.begin(), " LDY sptr" );
            else if ( stack_y_off == 1 )
                c.insert(c.begin(), " DEY" );
            else if ( stack_y_off == -1 )
                c.insert(c.begin(), " INY" );

            stack_y = true;
            stack_y_off = 0;
            if ( pop )
            {
                stack_y_off = -1;
                c.push_back( " INC sptr" );
            }
            return c;
        }

        std::vector<std::string> add_push(std::vector<std::string> c)
        {
            globals.insert("pushAX");
            c.insert(c.begin(), " JSR pushAX" );
            stack_y = true;
            stack_y_off = 1;
            return c;
        }

        std::string add_cdata(const std::vector<std::string> &data)
        {
            auto lbl = std::string("fb_cdata_" + std::to_string(const_data.size()));
            const_data.push_back(lbl + ":");
            for(auto s: data)
                const_data.push_back(s);
            return lbl;
        }

        std::string add_cdata(std::string data)
        {
            return add_cdata(std::vector<std::string>{ data });
        }

        std::string get_var(const codew &cw, unsigned off = 0) const
        {
            auto v = cw.get_val();
            auto s = vars.find(v);
            if( s != vars.end() )
            {
                if( off )
                    return ".LOWORD(" + s->second + " + " + std::to_string(off) + ")";
                else
                    return s->second;
            }
            return ".LOWORD(heap_start + " + std::to_string(2*v+off) + ")";
        }

        std::vector<std::string> emit_tok()
        {
            // assert( pos < code.size() );
            // assert( code[pos].is_tok() );
            auto tok = code[pos].get_tok();
            pos++;

            // This should include all tokens
            switch(tok)
            {
                case TOK_END:
                    return { " JMP ($0A)" };     // Return to DOS
                case TOK_NUM:
                {
                    auto s = code[pos++].to_str();
                    return { " LDA #<" + s,
                             " LDX #>" + s };
                }
                case TOK_BYTE:
                    return { " LDA #<" + code[pos++].to_str(),
                             " LDX #0" };
                case TOK_BYTE_SADDR:
                {
                    return { " LDA #<" + code[pos++].to_str(),
                             " LDX #0",
                             " STA saddr",
                             " STX saddr+1" };
                }
                case TOK_SADDR:
                {
                    return { " STA saddr",
                             " STX saddr+1" };
                }
                case TOK_CSTRING:
                {
                    auto lbl = add_cdata(code[pos++].to_asm());
                    return { " LDA #<" + lbl,
                             " LDX #>" + lbl };
                }
                case TOK_CDATA:
                {
                    auto dst = code[pos++].to_str(); // target label (not used)
                    auto data = std::vector<std::string>();
                    while( pos < code.size() && !code[pos].is_label() )
                        data.push_back( code[pos++].to_asm() );
                    auto lbl = add_cdata(data);
                    stack_y = 0;
                    return { " LDY #0",
                             " LDA #<" + lbl,
                             " STA (saddr), Y",
                             " LDA #>" + lbl,
                             " INY",
                             " STA (saddr), Y" };
                }
                case TOK_VAR_ADDR:
                {
                    auto n = get_var(code[pos++]);
                    return { " LDA #<" + n ,
                             " LDX #>" + n };
                }
                case TOK_VAR_SADDR:
                {
                    auto n = get_var(code[pos++]);
                    return { " LDA #<" + n ,
                             " LDX #>" + n,
                             " STA saddr",
                             " STX saddr+1" };
                }
                case TOK_VAR_LOAD:
                {
                    auto & cp = code[pos++];
                    return { " LDA " + get_var(cp) ,
                             " LDX " + get_var(cp,1) };
                }
                case TOK_SHL8:
                    return { " TAX", " LDX #0" };
                case TOK_0:
                    return { " LDA #0", " TAX" };
                case TOK_1:
                    return { " LDA #1", " LDX #0" };
                case TOK_PUSH:
                    return add_push( std::vector<std::string>() );
                case TOK_PUSH_NUM:
                {
                    auto s = code[pos++].to_str();
                    return add_push( { " LDA #<" + s,
                                       " LDX #>" + s } );
                }
                case TOK_PUSH_VAR_LOAD:
                {
                    auto & cp = code[pos++];
                    return add_push( { " LDA " + get_var(cp) ,
                                       " LDX " + get_var(cp,1) } );
                }
                case TOK_PUSH_BYTE:
                    return add_push( { " LDA #<" + code[pos++].to_str(),
                                       " LDX #0" } );
                case TOK_PUSH_0:
                    return add_push( { " LDA #0", " TAX" } );
                case TOK_PUSH_1:
                    return add_push( { " LDA #1", " LDX #0" } );
                case TOK_NEG:
                    return call( "neg_AX" );
                case TOK_ADD:
                    return use_stack( { " CLC", " ADC stack_l,Y", " PHA",
                                        " TXA", " ADC stack_h,Y", " TAX", " PLA" }, 1 );
                case TOK_SUB:
                    return use_stack( { " EOR #$FF", " SEC", " ADC stack_l,Y", " PHA",
                                        " TXA", " EOR #$FF", " ADC stack_h,Y", " TAX", " PLA" },
                                        1 );
                case TOK_BIT_AND:
                    return use_stack( { " AND stack_l,Y", " PHA", " TXA",
                                        " AND stack_h,Y", " TAX", " PLA" }, 1 );
                case TOK_BIT_OR:
                    return use_stack( { " ORA stack_l,Y", " PHA", " TXA",
                                        " ORA stack_h,Y", " TAX", " PLA" }, 1 );
                case TOK_BIT_EXOR:
                    return use_stack( { " EOR stack_l,Y", " PHA", " TXA",
                                        " EOR stack_h,Y", " TAX", " PLA" }, 1 );
                case TOK_PEEK:
                    return { " STX *+6", " TAX", " LDA $FF00,X", " LDX #0" }; // SMC
                case TOK_DPEEK:
                    stack_y = false;
                    return { " STX *+9", " STX *+9", " TAY",
                             " LDA $FF00,Y", " LDX $FF01,Y" }; // SMC
                case TOK_L_NOT:
                    return { " EOR #1" };
                case TOK_L_OR:
                    return use_stack( { " ORA stack_l,Y" }, 1 );
                case TOK_L_AND:
                    return use_stack( { " AND stack_l,Y" }, 1 );
                case TOK_LT:
                    // TODO: add CNJUMP
                    if (pos < code.size() && code[pos].is_tok() &&
                        code[pos].get_tok() == TOK_CJUMP )
                    {
                        pos++;
                        auto c = code[pos++].to_str();
                        auto l1 = new_label();
                        auto l2 = new_label();
                        auto l3 = new_label();
                        return use_stack(
                                {" INC sptr",
                                 " EOR #255",
                                 " SEC",
                                 " ADC stack_l,Y",
                                 " TXA",
                                 " EOR #255",
                                 " ADC stack_h,Y",
                                 " BVS " + l1,
                                 " BMI " + l2,
                                 l3 + ":",
                                 " JMP " + c,
                                 l1 + ":",
                                 " BMI " + l3,
                                 l2 + ":" },
                                 0);
                    }
                    else
                    {
                        return call( token_name(tok) );
                    }
                case TOK_GT:
                    // TODO: add CNJUMP
                    if (pos < code.size() && code[pos].is_tok() &&
                        code[pos].get_tok() == TOK_CJUMP )
                    {
                        pos++;
                        auto c = code[pos++].to_str();
                        auto l1 = new_label();
                        auto l2 = new_label();
                        auto l3 = new_label();
                        return use_stack(
                                {" INC sptr",
                                 " CMP stack_l,Y",
                                 " TXA",
                                 " SBC stack_h,Y",
                                 " BVS " + l1,
                                 " BMI " + l2,
                                 l3 + ":",
                                 " JMP " + c,
                                 l1 + ":",
                                 " BMI " + l3,
                                 l2 + ":" },
                                 0);
                    }
                    else
                    {
                        return call( token_name(tok) );
                    }
                case TOK_NEQ:
                    if (pos < code.size() && code[pos].is_tok() &&
                        code[pos].get_tok() == TOK_CJUMP )
                    {
                        pos++;
                        auto c = code[pos++].to_str();
                        auto l1 = new_label();
                        return use_stack(
                                {" INC sptr",
                                 " CMP stack_l,Y",
                                 " BNE " + l1,
                                 " TXA",
                                 " CMP stack_h,Y",
                                 " BNE " + l1,
                                 " JMP " + c,
                                 l1 + ":" }, 0);
                    }
                    else if (pos < code.size() && code[pos].is_tok() &&
                        code[pos].get_tok() == TOK_CNJUMP )
                    {
                        pos++;
                        auto c = code[pos++].to_str();
                        auto l1 = new_label();
                        auto l2 = new_label();
                        return use_stack(
                                {" INC sptr",
                                 " CMP stack_l,Y",
                                 " BNE " + l1,
                                 " TXA",
                                 " CMP stack_h,Y",
                                 " BEQ " + l2,
                                 l1 + ":",
                                 " JMP " + c,
                                 l2 + ":" }, 1);
                    }
                    else
                    {
                        return call( token_name(tok) );
                    }
                case TOK_EQ:
                    if (pos < code.size() && code[pos].is_tok() &&
                        code[pos].get_tok() == TOK_CJUMP )
                    {
                        pos++;
                        auto c = code[pos++].to_str();
                        auto l1 = new_label();
                        auto l2 = new_label();
                        return use_stack(
                                {" INC sptr",
                                 " CMP stack_l,Y",
                                 " BNE " + l1,
                                 " TXA",
                                 " CMP stack_h,Y",
                                 " BEQ " + l2,
                                 l1 + ":",
                                 " JMP " + c,
                                 l2 + ":" }, 0);
                    }
                    else if (pos < code.size() && code[pos].is_tok() &&
                        code[pos].get_tok() == TOK_CNJUMP )
                    {
                        pos++;
                        auto c = code[pos++].to_str();
                        auto l1 = new_label();
                        return use_stack(
                                {" INC sptr",
                                 " CMP stack_l,Y",
                                 " BNE " + l1,
                                 " TXA",
                                 " CMP stack_h,Y",
                                 " BNE " + l1,
                                 " JMP " + c,
                                 l1 + ":" }, 0);
                    }
                    else
                    {
                        return call( token_name(tok) );
                    }
                case TOK_COMP_0:
                    if (pos < code.size() && code[pos].is_tok() &&
                        code[pos].get_tok() == TOK_CJUMP )
                    {
                        pos++;
                        auto c = code[pos++].to_str();
                        auto l1 = new_label();
                        stack_y = false;
                        return { " TAY",
                                 " BNE " + l1,
                                 " TXA",
                                 " BNE " + l1,
                                 " JMP " + c,
                                 l1 + ":" };
                    }
                    else if (pos < code.size() && code[pos].is_tok() &&
                        code[pos].get_tok() == TOK_CNJUMP )
                    {
                        pos++;
                        auto c = code[pos++].to_str();
                        auto l1 = new_label();
                        auto l2 = new_label();
                        stack_y = false;
                        return { " TAY",
                                 " BNE " + l1,
                                 " TXA",
                                 " BEQ " + l2,
                                 l1 + ":",
                                 " JMP " + c,
                                 l2 + ":" };
                    }
                    else
                    {
                        auto l1 = new_label();
                        auto l2 = new_label();
                        stack_y = false;
                        return { " TAY", " BNE " + l1,
                                 " TXA", " BEQ " + l2,
                                 l1 + ":", " LDA #1", " LDX #0", l2 + ":" };
                    }
                case TOK_POKE:
                {
                    stack_y = false;
                    return { " LDY #0",
                             " STA (saddr), y" };
                }
                case TOK_DPOKE:
                {
                    stack_y = false;
                    return { " LDY #0",
                             " STA (saddr), y",
                             " INY",
                             " TXA",
                             " STA (saddr), Y" };
                }
                case TOK_INC:
                {
                    auto l1 = new_label();
                    auto l2 = new_label();
                    auto l3 = new_label();
                    return { " STX " + l2 + "+2", " STX " + l1 + "+2", " TAX", l1 + ":",
                             " INC $FF00, X", " BNE " + l3, l2 + ":", " INC $FF01, X",
                             l3 + ":" };
                }
                case TOK_INCVAR:
                {
                    auto & cp = code[pos++];
                    auto l = new_label();
                    return { " INC " + get_var(cp),
                             " BNE " + l,
                             " INC " + get_var(cp,1),
                             l + ":" };
                }
                case TOK_DEC:
                {
                    auto l1 = new_label();
                    auto l2 = new_label();
                    auto l3 = new_label();
                    return { " STX " + l2 + "+2", " STX " + l1 + "+2", " STX " + l3 + "+2",
                             " TAX", l1 + ":", " LDA $FF00,X", " BNE " + l3,
                             l2 + ":", " DEC $FF01, X", l3 + ":", " DEC $FF00, X" };
                }
                case TOK_DECVAR:
                {
                    auto & cp = code[pos++];
                    auto l = new_label();
                    return { " LDA " + get_var(cp),
                             " BNE " + l,
                             " DEC " + get_var(cp,1),
                             l + ":",
                             " DEC " + get_var(cp) };
                }
                case TOK_VAR_STORE:
                {
                    auto & cp = code[pos++];
                    return { " STA " + get_var(cp),
                             " STX " + get_var(cp,1) };
                }
                case TOK_DIM:
                {
                    auto & cp = code[pos++];
                    return { call_str("alloc_array"),
                             " LDA tmp2",
                             " LDX tmp2+1",
                             " STA " + get_var(cp),
                             " STX " + get_var(cp,1) };
                }
                case TOK_JUMP:
                {
                    auto c = code[pos++].to_str();
                    return { " JMP " + c };
                }
                case TOK_CJUMP:
                {
                    auto l = new_label();
                    auto c = code[pos++].to_str();
                    return { " LSR", " BCS " + l, " JMP " + c, l + ":" };
                }
                case TOK_CNJUMP:
                {
                    auto l = new_label();
                    auto c = code[pos++].to_str();
                    return { " LSR", " BCC " + l, " JMP " + c, l + ":" };
                }
                case TOK_CALL:
                {
                    auto c = code[pos++].to_str();
                    stack_y = false;
                    return { " JSR " + c };
                }
                case TOK_RET:
                    return { " RTS" };
                case TOK_CRET:
                {
                    auto l = new_label();
                    return { " LSR", " BCS " + l, " RTS", l + ":" };
                }
                case TOK_CNRET:
                {
                    auto l = new_label();
                    return { " LSR", " BCC " + l, " RTS", l + ":" };
                }
                case TOK_USHL:
                    stack_y = false;
                    return { " ASL", " TAY", " TXA", " ROL", " TAX", " TYA" };
                case TOK_USR_ADDR:
                    last_usr_lbl = new_label();
                    return { " STA " + last_usr_lbl + " - 2",
                             " STX " + last_usr_lbl + " - 1",
                             " LDA #>(" + last_usr_lbl + " - 1)",
                             " PHA",
                             " LDA #<(" + last_usr_lbl + " - 1)",
                             " PHA" };
                case TOK_USR_PARAM:
                    return { " PHA", " TXA", " PHA" };
                case TOK_USR_CALL:
                {
                    stack_y = false;
                    return { " JMP $FFFF",
                             last_usr_lbl + ":"};
                }
#ifdef FASTBASIC_FP
                case TOK_FLOAT:
                {
                    auto lbl = add_cdata(code[pos++].to_asm());
                    return { " LDA #<" + lbl,
                             " LDX #>" + lbl,
                             call_str( token_name(TOK_FP_LOAD) ) };
                }
#endif
                case TOK_ABS:
                case TOK_SGN:
                case TOK_MUL:
                case TOK_DIV:
                case TOK_MOD:
                case TOK_TIME:
                case TOK_FRE:
                case TOK_RAND:
                case TOK_MOVE:
                case TOK_NMOVE:
                case TOK_MSET:
                case TOK_GRAPHICS:
                case TOK_PLOT:
                case TOK_DRAWTO:
                case TOK_PMGRAPHICS:
                case TOK_PRINT_STR:
                case TOK_PRINT_TAB:
                case TOK_PRINT_EOL:
                case TOK_GETKEY:
                case TOK_INPUT_STR:
                case TOK_XIO:
                case TOK_CLOSE:
                case TOK_GET:
                case TOK_PUT:
                case TOK_BPUT:
                case TOK_BGET:
                case TOK_IOCHN:
                case TOK_FOR:
                case TOK_FOR_NEXT:
                case TOK_FOR_EXIT:
                case TOK_COPY_STR:
                case TOK_VAL:
                case TOK_CMP_STR:
                case TOK_INT_STR:
                case TOK_STR_IDX:
                case TOK_CAT_STR:
                case TOK_CHR:
                case TOK_SOUND_OFF:
                case TOK_PAUSE:
#ifdef FASTBASIC_FP
                case TOK_INT_FP:
                case TOK_FP_VAL:
                case TOK_FP_SGN:
                case TOK_FP_ABS:
                case TOK_FP_NEG:
                case TOK_FP_DIV:
                case TOK_FP_MUL:
                case TOK_FP_SUB:
                case TOK_FP_ADD:
                case TOK_FP_STORE:
                case TOK_FP_LOAD:
                case TOK_FP_EXP:
                case TOK_FP_EXP10:
                case TOK_FP_LOG:
                case TOK_FP_LOG10:
                case TOK_FP_INT:
                case TOK_FP_CMP:
                case TOK_FP_IPOW:
                case TOK_FP_RND:
                case TOK_FP_SQRT:
                case TOK_FP_SIN:
                case TOK_FP_COS:
                case TOK_FP_ATN:
                case TOK_FP_STR:
#endif
                    return call( token_name(tok) );
                case TOK_LAST_TOKEN:
                    return {};
            }
            return {};
        }

    public:
        codegen(std::vector<codew> &code, std::set<std::string> &globals,
                std::set<std::string> &globals_zp,
                const std::map<std::string, int> &var_map ) :
            code(code), globals(globals), globals_zp(globals_zp),
            const_data(), asm_code(), pos(0), stack_y(false),
            stack_y_off(0), lbl_num(0)
        {
            // Get variable names
            for(auto &v: var_map)
                if (!v.first.empty() && v.first[0] != '-' )
                    vars[ v.second >> 8 ] = "fb_var_" + v.first;
        }

        void gen_code()
        {
            // Add some globals
            globals.insert("stack_l");
            globals.insert("stack_h");
            globals_zp.insert("sptr");
            globals_zp.insert("saddr");
            globals_zp.insert("tmp2");
            // Generate code
            while( pos < code.size() )
            {
                auto &cp = code[pos];
                if( cp.is_tok() )
                {
                    auto v = emit_tok();
                    asm_code.insert(asm_code.end(), v.begin(), v.end());
                }
                else if( cp.is_label() )
                {
                    asm_code.push_back( cp.to_str() + ":" );
                    pos++;
                }
                else
                {
                    std::cerr << "internal error at " << cp.linenum() << "\n";
                    pos++;
                }
            }
        }
        std::vector<std::string> &full_code()
        {
            return asm_code;
        }
        std::vector<std::string> &full_data()
        {
            return const_data;
        }
};
