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

// os.cc: Host OS functions
#include "os.h"
#include <memory>

#ifdef _WIN32
# include <windows.h>
static const char *path_sep = "\\/";
#else
# include <unistd.h>
# include <signal.h>
# include <sys/wait.h>
static const char *path_sep = "/";
#endif


std::string os::full_path(const std::string &path, const std::string &filename)
{
    // Join a path with a filename
    if( path.empty() )
        return std::string(".") + path_sep[0] + filename;
    auto pos = path.find_last_of(path_sep);
    if( pos == path.npos || (pos + 1) < path.size() )
        return path + path_sep[0] + filename;
    else
        return path + filename;
}

std::string os::add_extension(std::string name, std::string ext)
{
    auto pos = name.find_last_of(".");
    if( pos == name.npos || pos == 0 )
        return name + ext;
    else
        return name.substr(0, pos) + ext;
}

int os::prog_exec(std::string exe, std::vector<std::string> &args)
{
    // Create a vector with C pointers
    std::vector<const char *> pargs;
    for(const auto &s: args)
        pargs.push_back(s.c_str());
    pargs.push_back(nullptr);

    // Execute the program
#ifdef _WIN32
    // win32 has the "spawn" function that calls the program and waits
    // for termination:
    return _spawnv( _P_WAIT, exe.c_str(), (char **)pargs.data());
#else
    // We reimplement "system" to allow passing arguments without escaping:

    // Ignore INT and QUIT signals in the parent process:
    sigset_t oldmask, newmask;
    struct sigaction sa = { SIG_IGN, 0 }, oldint, oldquit;
    sigaction(SIGINT, &sa, &oldint);
    sigaction(SIGQUIT, &sa, &oldquit);

    // Block SIGCHLD
    sigemptyset(&newmask);
    sigaddset(&newmask, SIGCHLD);
    sigprocmask(SIG_BLOCK, &newmask, &oldmask);

    int status = -1;
    auto pid = fork();
    if( pid == 0 )
    {
        // Child, reset INT, QUIT and CHLD signals to default
        struct sigaction sa = { SIG_DFL, 0 };
        sigaction(SIGINT, &sa, nullptr);
        sigaction(SIGQUIT, &sa, nullptr);
        sigprocmask(SIG_SETMASK, &oldmask, nullptr);
        // Exec process
        execv(exe.c_str(), (char **)pargs.data());
        // If we got here, it is an error
        _exit(127);
    }
    else if( pid != -1 )
    {
        // Wait until child returns
        while( (waitpid(pid, &status, 0) == -1) && (errno == EINTR) );
    }

    // Restore signals
    sigprocmask(SIG_SETMASK, &oldmask, NULL);
    sigaction(SIGINT, &oldint, NULL);
    sigaction(SIGQUIT, &oldquit, NULL);

    return status;
#endif
}

