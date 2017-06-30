/*
 * FastBasic - Fast basic interpreter for the Atari 8-bit computers
 * Copyright (C) 2017 Daniel Serpell
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

// Translates the syntax file to an assembly file for CA65
// -------------------------------------------------------

#include <string>
#include <iostream>
#include <sstream>
#include <map>
#include <memory>
#include <vector>

extern void addConf(const std::string &k, const std::string &v);

class parseState;
class sentry
{
    private:
        parseState &p;
        unsigned pos, line, col;
    public:
        sentry(parseState &orig);
        bool operator()(bool consume);
        std::string str();
};

struct parseState
{
    const char *str;
    unsigned pos, line, col;
    parseState(const char *str): str(str), pos(0), line(1), col(1)  { }
    bool advance()
    {
        if( str[pos] )
        {
            if( str[pos] == '\n' )
            {
                col = 1;
                line++;
            }
            else
                col++;
            pos ++;
        }
        return true;
    }
    bool eof()
    {
        return !str[pos];
    }
    bool ch(char c)
    {
        return (str[pos] == c) && advance();
    }
    bool ch(char a, char b)
    {
        return str[pos] >= a && str[pos] <= b && advance();
    }
    bool ident_ch()
    {
        return ch('_') || ch('a','z') || ch('A','Z') || ch('0','9');
    }
    bool blank()
    {
        return ch(' ') || ch('\t');
    }
    bool space()
    {
        while(blank());
        return true;
    }
    bool eol()
    {
        sentry s(*this);
        return s( space() && (eof() || ch('\n') || (ch('\r') && ch('\n'))) );
    }
    bool noteol()
    {
        sentry s(*this);
        return s(!eol());
    }
    bool all()
    {
        while( noteol() )
            advance();
        return true;
    }
    bool comment()
    {
        sentry s(*this);
        return s(space() && ( (ch('#') && all()) || eol()));
    }
    bool error(std::string err)
    {
        std::cerr << "parse: error at " << line << ":" << col << ": " << err << "\n";
        return !all();
    }
};

sentry::sentry(parseState &orig): p(orig), pos(orig.pos), line(orig.line), col(orig.col) { }
bool sentry::operator()(bool consume) {
    if( !consume ) { p.pos = pos; p.line = line; p.col = col; }
    return consume;
}
std::string sentry::str()
{
    return std::string(p.str+pos, p.pos-pos);
}

class statemachine {
    private:
        parseState &p;
        bool complete;
        std::string _name;
        std::string _code;
        std::vector<std::string> ebytes;
        bool parse_name()
        {
            sentry s(p);
            while(p.ident_ch());
            _name = s.str();
            return s( p.ch(':') );
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
            else if( c != '\'' && c >= ' ' && c <= 'z' )
            {
                str = "'";
                str += c;
                str += "'";
                return true;
            }
            static char hex[17] = "0123456789ABCDEF";
            str = "$";
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
                        p.ch('n') && add_char(str,'\n') ||
                        p.ch('r') && add_char(str,'\r') ||
                        p.ch('t') && add_char(str,'\t') ||
                        p.ch('"') && add_char(str,'"') ||
                        p.ch('\\') && add_char(str,'\\') ||
                        p.ch('x') && add_hex(str) ) ) )
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
            std::string str;
            while(str_char(str))
                line += "\t.byte " + str + "\n";
            if( !p.ch('"') )
                return p.error("invalid character in string");
            return true;
        }
        bool end_line()
        {
            return p.space() && (p.eof() || p.eol() || p.comment());
        }
        bool emit_bytes(bool last, std::string &line)
        {
            auto n = ebytes.size();
            std::string lst;
            if( !n )
                return false;
            if( last )
            {
                n--;
                lst = ebytes[n];
                ebytes.pop_back();
            }
            std::stringstream os;
            if( n )
            {
                os << "\t.byte SM_EMIT_" << n;
                for(auto &s: ebytes)
                    os << ", " << s;
                os << "\n";
            }
            if( last )
                os << "\t.byte SM_ERET, " << lst << "\n";
            line += os.str();
            ebytes.clear();
            return true;
        }
        bool parse_line(std::string &line)
        {
            skip_comments();
            if( complete || p.eof() || p.eol() || !p.blank() )
                return false;
            // Reads commands until EOL or comment
            while(1)
            {
                std::string cmd;
                if( end_line() )
                {
                    if( !emit_bytes(true, line) )
                        line += "\t.byte SM_RET\n";
                    return true;
                }
                sentry s(p);
                // String?
                if( p.ch('"') )
                {
                    emit_bytes(false, line);
                    if(!parse_str(line))
                        return p.error("parse: string \"" + s.str() + "\" invalid");
                    continue;
                }
                // Command ?
                cmd = read_ident();
                p.space();
                if( cmd == "emit" )
                {
                    std::string tok = read_ident();
                    if( tok.empty() )
                        return p.error("EMIT expects a token");
                    ebytes.push_back(tok);
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

                emit_bytes(false, line);

                if( cmd == "pass" )
                {
                    complete = true;
                    if( !end_line() )
                        return p.error("parse: 'pass' should be the only command in a line");
                    line += "\t.byte SM_RET\n";
                    // End of command, and end of SM
                    return true;
                }
                else if( cmd == "JMP" )
                {
                    std::string lbl = read_ident();
                    if( lbl.empty() )
                        return p.error("JMP expects a label");
                    if( !end_line() )
                        return p.error("parse: 'jmp' should be the last command in a line");
                    line += "\t.byte SM_JMP\n\t.byte SMB_";
                    line += lbl;
                    line += "\n";
                    return true;
                }
                else if( cmd == "ejmp" )
                {
                    std::string tok = read_ident();
                    std::string lbl = read_ident();
                    if( tok.empty() || lbl.empty() )
                        return p.error("EJMP expects a token and a label");
                    if( !end_line() )
                        return p.error("parse: 'ejmp' should be the last command in a line");
                    line += "\t.byte SM_EJMP\n\t.byte ";
                    line += tok;
                    line += "\n\t.byte SMB_";
                    line += lbl;
                    line += "\n";
                    // End of command
                    return true;
                }
                else if( !cmd.empty() )
                {
                    line += "\t.byte SMB_";
                    line += cmd;
                    line += "\n";
                }
                else
                    p.error("invalid label \"" + cmd + "\"");
            }
            return false;
        }
    public:
        statemachine(parseState &p): p(p), complete(false) {}
        std::string name() const {
            return _name;
        }
        bool parse()
        {
            skip_comments();
            if( p.eof() || p.eol() || p.blank() ) return false;
            if( !parse_name() ) return false;
            while(parse_line(_code));
            return true;
        }
        void print() const {
            std::cout << _name << ":\n"
                << _code;
            if( !complete )
                std::cout << "\t.byte SM_EXIT\n";
            std::cout << "\n";
        }
};

class wordlist {
    private:
        parseState &p;
        int n;
        const char *name;
        std::map<std::string, int> list;
        std::string read_ident()
        {
            sentry s(p);
            while(p.ident_ch());
            std::string ret = s.str();
            p.space();
            return ret;
        }
        bool end_line()
        {
            return p.space() && (p.eof() || p.eol() || p.comment());
        }
        bool skip_comments()
        {
            while(!p.eof() && (p.blank() || p.comment())); // Skip comments and blank lines
            return true;
        }
    public:
        wordlist(parseState &p, const char *name, int start): p(p), n(start), name(name) {}
        int next() const { return n; }
        const std::map<std::string, int> &map() const { return list; }
        bool parse()
        {
            skip_comments();
            sentry s(p);
            std::string tok = read_ident();
            if( !s(tok == name && skip_comments() && p.ch('{')) )
                return false;
            // Read all tokens
            while(1)
            {
                skip_comments();
                sentry s1(p);
                tok = read_ident();
                if( tok.empty() )
                {
                    p.error("not a word in '" + s1.str() + "'");
                    p.all();
                }
                else
                {
                    if( list.end() != list.find(tok) )
                        p.error("word already exists '" + tok + "'");
                    else
                        list[tok] = n++;
                }
                sentry s2(p);
                if( s2( skip_comments() && p.ch('}') ) )
                    break;
                if( s2( skip_comments() && p.ch(',') ) )
                    continue;
                if( s2( end_line() && skip_comments() ) )
                    continue;

                p.error("expected a ',' or newline");
            }
            return true;
        }
};

bool p_file(parseState &p)
{
    // Output header
    std::cout << "; Syntax state machine\n\n";

    while(1)
    {
        wordlist tok(p, "TOKENS", 1);
        if( !tok.parse() )
            break;
        for(auto i: tok.map())
            std::cout << i.first << "\t= " << i.second << " * 2\n";
        std::cout << "\n";
        std::cerr << "syntax: " << tok.next() << " possible tokens.\n";
    }

    wordlist ext(p, "EXTERN", 128);
    if( ext.parse() )
    {
        int n = 128;
        for(auto i: ext.map())
            std::cout << " .global " << i.first << "\n";
        for(auto i: ext.map())
        {
            i.second = n++;
            std::cout << "SMB_" << i.first << "\t= " << i.second << "\n";
        }
        std::cout << "\nSMB_STATE_START\t= " << ext.next() << "\n\n";
    }

    std::map<std::string, std::unique_ptr<statemachine>> sm_list;

    while( !p.eof() )
    {
        auto sm = std::make_unique<statemachine>(p);
        if( sm->parse() )
        {
            sm_list[sm->name()] = std::move(sm);
        }
        else
        {
            sentry s(p);
            p.all();
            p.error("invalid input '" + s.str() + "'");
        }
    }
    // Emit labels table
    int ns = ext.next();
    for(auto &sm: sm_list)
        std::cout << "SMB_" << sm.second->name() << "\t= " << ns++ << "\n";
    // Emit array with addresses
    std::cout << "\nSM_TABLE_ADDR:\n";
    for(auto i: ext.map())
        std::cout << "\t.word " << i.first << " - 1\n";
    for(auto &sm: sm_list)
        std::cout << "\t.word " << sm.second->name() << " - 1\n";
    // Emit state machine tabless
    std::cout << "\n";
    for(auto &sm: sm_list)
        sm.second->print();

    std::cerr << "syntax: " << (ns-128) << " tables in the parser-table.\n";
    return true;
}


#if 1
static std::string readInput()
{
 std::string r;
 int c;
 while( -1 != (c = std::cin.get()) )
  r += char(c);
 return r;
}

int main()
{
 std::string inp = readInput();

 parseState ps(inp.c_str());
 p_file(ps);

 return 0;
}
#endif
