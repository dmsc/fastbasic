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

// synt-sm.cc: Parse and write the syntax state machine

#include <iostream>
#include <string>
#include <vector>

template<class EM>
class statemachine {
    private:
        parseState &p;
        bool complete;
        int lnum;          // Line number in input file
        std::string _name; // Table name
        std::string _code; // Parsing code
        std::string _desc; // Table description
        std::vector<std::string> ebytes;
        bool parse_name()
        {
            sentry s(p);
            while(p.ident_ch());
            _name = s.str();
            return s( p.ch(':') );
        }
        bool parse_description()
        {
            // Description is from ':' to the end of line, skipping spaces
            p.space();
            sentry s(p);
            p.all();
            _desc = s.str();
            return s(true);
        }
        std::string read_ident()
        {
            sentry s(p);
            while(p.ident_ch());
            std::string ret = s.str();
            p.space();
            return ret;
        }
        void skip_comments()
        {
            while(!p.eof() && p.comment()); // Skip comments and blank lines
        }
        bool add_char(std::string &str, char c)
        {
            if( c < 8 || c > 126 )
            {
                p.error(std::string("invalid char '") + c + "'");
                return false;
            }
            else if( c != '\'' && c != '\"' && c >= ' ' && c <= 'z' )
            {
                str = "'";
                str += c;
                str += "'";
                return true;
            }
            static char hex[17] = "0123456789ABCDEF";
            str = EM::hex_prefix;
            str += hex[(c>>4)&15];
            str += hex[c&15];
            return true;
        }
        int dhex(char c)
        {
            if( c >= '0' && c <= '9' )
                return c - '0';
            else if( c >= 'a' && c <= 'f' )
                return c - 'a';
            else
                return c - 'A';
        }
        bool add_hex(std::string &str)
        {
            sentry s(p);
            if( s( (p.ch('0','9') || p.ch('a','f') || p.ch('A','F')) &&
                   (p.ch('0','9') || p.ch('a','f') || p.ch('A','F')) )
              )
                return add_char(str, char(16 * dhex(s.str()[0]) + dhex(s.str()[1])));
            else
                return false;
        }
        bool str_char(std::string &str)
        {
            sentry s(p);
            if( s(p.ch('\\') && (
                        ( p.ch('n') && add_char(str,'\n')  ) ||
                        ( p.ch('r') && add_char(str,'\r')  ) ||
                        ( p.ch('t') && add_char(str,'\t')  ) ||
                        ( p.ch('"') && add_char(str,'"')   ) ||
                        ( p.ch('\\') && add_char(str,'\\') ) ||
                        ( p.ch('x') && add_hex(str)        )   ) ) )
                return true;
            else if( p.ch('"') )
                return s(false);
            else if( s(p.ch(' ', 'z')) )
                return add_char(str, s.str()[0]);
            else
                return false;
        }
        bool parse_str(std::string &line)
        {
            std::vector<std::string> list;
            std::string str;
            while(str_char(str))
                list.push_back(str);
            if( !p.ch('"') )
                return p.error("invalid character in string");
            line += EM::emit_literal(list);
            return true;
        }
        bool end_line()
        {
            return p.space() && (p.eof() || p.eol() || p.comment());
        }
        // Parses a emit line "{" byte/token, &word, ... "}"
        bool read_emit_line()
        {
            while(true) {
                p.space();
                bool is_word = p.ch('&');
                auto tok = read_ident();
                if( tok.empty() )
                    return p.error("Expected token to EMIT");
                if( is_word )
                {
                    ebytes.push_back("<" + tok);
                    ebytes.push_back(">" + tok);
                }
                else
                    ebytes.push_back(tok);
                if( p.ch('}') )
                    break;
                if( !p.ch(',') )
                    return p.error("Expected ',' or '}'");
            }
            return true;
        }
        bool emit_bytes(bool last, std::string &line, int lnum)
        {
            if( 0 == ebytes.size() )
                return false;
            line += EM::emit_bytes(last, ebytes, lnum);
            ebytes.clear();
            return true;
        }
        bool parse_line(std::string &line, int &lnum)
        {
            skip_comments();
            if( complete || p.eof() || p.eol() || !p.blank() )
                return false;

            bool canFail = false; // True if the parsing rule can fail (== has actions)
            lnum = p.line;

            // Reads commands until EOL or comment
            while(1)
            {
                std::string cmd;
                if( end_line() )
                {
                    if( !emit_bytes(true, line, lnum) )
                        line += EM::emit_ret(lnum);
                    // If line can't fail, rule is complete.
                    complete = !canFail;
                    return true;
                }
                sentry s(p);
                // String?
                if( p.ch('"') )
                {
                    emit_bytes(false, line, lnum);
                    if(!parse_str(line))
                        return p.error("parse: string \"" + s.str() + "\" invalid");
                    canFail = true;
                    continue;
                }
                // Command ?
                cmd = read_ident();
                p.space();
                if( cmd == "emit" )
                {
                    if( p.ch('{') )
                    {
                        if( !read_emit_line() )
                            return false;
                    }
                    else
                    {
                        std::string tok = read_ident();
                        if( tok.empty() )
                            return p.error("EMIT expects a token");
                        ebytes.push_back(tok);
                    }
                    continue;
                }
                else if( cmd == "word" )
                {
                    std::string tok = read_ident();
                    if( tok.empty() )
                        return p.error("WORD expects a number");
                    ebytes.push_back("<" + tok);
                    ebytes.push_back(">" + tok);
                    continue;
                }

                emit_bytes(false, line, lnum);

                if( cmd == "pass" )
                {
                    complete = true;
                    if( !end_line() )
                        return p.error("parse: 'pass' should be the only command in a line");
                    line += EM::emit_ret(lnum);
                    // End of command, and end of SM
                    return true;
                }
                else if( !cmd.empty() )
                {
                    canFail = true;
                    line += EM::emit_call(cmd);
                }
                else
                    p.error("invalid label \"" + cmd + "\"");
            }
            return false;
        }
    public:
        statemachine(parseState &p): p(p), complete(false), lnum(-1) {}
        std::string name() const {
            return _name;
        }
        bool parse()
        {
            skip_comments();
            if( p.eof() || p.eol() || p.blank() ) return false;
            if( !parse_name() ) return false;
            lnum = p.line;
            if( !parse_description() ) return false;
            std::string line;
            int lnum = 0;
            while(parse_line(line, lnum))
            {
                _code += EM::emit_line(line, lnum);
                line.clear();
            }
            return true;
        }
        void print(std::ostream &out) const {
            EM::print(out, _name, _desc, _code, complete, lnum);
        }
};
