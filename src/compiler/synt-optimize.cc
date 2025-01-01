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

// synt-optimize.cc: Optimizer for the parsing tables
#include "synt-optimize.h"

using namespace syntax;

static bool syntax_merge(sm_list &sl, bool verbose)
{
    // Merge parsing tables:
    //
    //   If a table ends with a call to another table, and that table
    //   is only referenced once, just join the two tables.
    //
    //   If a table line is just a call to another table, and is only
    //   referenced once, inline the table to the calling one.
    //
    // This is needed to allow floating-point syntax to alter integer
    // syntax without making the integer parser bigger.
    std::vector<std::string> to_delete;
    for(const auto &sm : sl.sms)
    {
        auto n = sm.second->name();
        int used = n == "PARSE_START" ? 1 : 0;

        for(const auto &sm2 : sl.sms)
            used += sm2.second->has_call(n);
        if(!used)
        {
            std::cerr << "syntax: table '" << n << "' unused.\n";
            return false;
        }
        if(used == 1)
        {
            // This table was used only once, see if we can inline it
            for(const auto &sm2 : sl.sms)
            {
                if(sm2.second->end_call(n))
                {
                    // Perform optimization:
                    if(verbose)
                        std::cerr << "syntax: optimizing table '" << n << "' into '"
                                  << sm2.second->name() << "'.\n";
                    if(!sm2.second->tail_call(*sm.second))
                        return false;
                    // Add name to tables to delete
                    to_delete.push_back(n);
                }
                else if(sm2.second->just_call(n))
                {
                    // Perform optimization:
                    if(verbose)
                        std::cerr << "syntax: inline table '" << n << "' into '"
                                  << sm2.second->name() << "'.\n";
                    if(!sm2.second->inline_call(n, *sm.second))
                        return false;
                    // Add name to tables to delete
                    to_delete.push_back(n);
                }
            }
        }
    }
    // Delete unused tables
    for(auto &n : to_delete)
        sl.sms.erase(n);

    return true;
}

bool syntax::syntax_optimize(sm_list &sl, bool verbose, bool merge)
{
    // Optimize parsing tables:
    // - Merge tables:
    if(merge)
    {
        if(!syntax_merge(sl, verbose))
            return false;
    }

    // - If a table is empty, remove all references to it.
    std::vector<std::string> to_delete;
    for(const auto &sm : sl.sms)
    {
        if(sm.second->is_empty())
        {
            auto n = sm.second->name();

            if(verbose)
                std::cerr << "syntax: optimizing table '" << n
                          << "' empty, will delete.\n";
            // Ok, delete this table
            to_delete.push_back(n);

            // And all references
            for(const auto &sm2 : sl.sms)
                sm2.second->delete_call(n);
        }
    }

    // Delete unused tables
    for(auto &n : to_delete)
        sl.sms.erase(n);

    // Do local optimization on each table
    for(auto &sm : sl.sms)
        sm.second->optimize();

    return true;
}
