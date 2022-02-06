/*
 * FastBasic - Fast basic interpreter for the Atari 8-bit computers
 * Copyright (C) 2017-2022 Daniel Serpell
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

bool syntax::syntax_optimize(sm_list_type &sm_list)
{
    // Optimize parsing tables:
    //
    //   If a table ends with a call to another table, and that table
    //   is only referenced once, just join the two tables.
    //
    // This is needed to allow floating-point syntax to alter integer
    // syntax without making the integer parser bigger.
    std::vector<std::string> to_delete;
    for(const auto &sm : sm_list)
    {
        auto n = sm.second->name();
        int used = n == "PARSE_START" ? 1 : 0;

        for(const auto &sm2 : sm_list)
            used += sm2.second->has_call(n);
        if(!used)
        {
            std::cerr << "syntax: table '" << n << "' unused.\n";
            return false;
        }
        if(used == 1)
        {
            // This table was used only once, see if we can do a tail call
            for(const auto &sm2 : sm_list)
            {
                if(sm2.second->end_call(n))
                {
                    // Perform optimization:
                    std::cerr << "syntax: optimizing table '" << n << "' into '"
                              << sm2.second->name() << "'.\n";
                    if(!sm2.second->tail_call(*sm.second))
                        return false;
                    // Add name to tables to delete
                    to_delete.push_back(n);
                }
            }
        }
    }

    // Delete unused tables
    for(auto &n : to_delete)
        sm_list.erase(n);
    to_delete.clear();

    //
    //   If a table is empty, remove all references to it.
    //
    for(const auto &sm : sm_list)
    {
        if(sm.second->is_empty())
        {
            auto n = sm.second->name();

            std::cerr << "syntax: optimizing table '" << n << "' empty, will delete.\n";
            // Ok, delete this table
            to_delete.push_back(n);

            // And all references
            for(const auto &sm2 : sm_list)
                sm2.second->delete_call(n);
        }
    }

    // Delete unused tables
    for(auto &n : to_delete)
        sm_list.erase(n);

    // Do local optimization on each table
    for(auto &sm : sm_list)
        sm.second->optimize();

    return true;
}
