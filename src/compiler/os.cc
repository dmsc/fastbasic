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

// os.cc: Host OS functions
#include "os.h"
#include <memory>

#ifdef _WIN32
#include <windows.h>
#define HAVE_DRIVE 1
static const char *path_sep = "\\/";
#else
#include <signal.h>
#include <sys/wait.h>
#include <unistd.h>
#include <cerrno>
#define HAVE_DRIVE 0
static const char *path_sep = "/";
#endif

bool os::path_absolute(const std::string &path)
{
    if(path.find_first_of(path_sep) == 0)
        return true;
    // On windows, detect if we have a drive letter
    else if(HAVE_DRIVE && path.size() > 2 && path[1] == ':')
        return true;
    else
        return false;
}

std::string os::full_path(const std::string &path, const std::string &filename)
{
    // Join a path with a filename
    if(path.empty())
        return std::string(".") + path_sep[0] + filename;
    auto pos = path.find_last_of(path_sep);
    if(pos == path.npos || (pos + 1) < path.size())
        return path + path_sep[0] + filename;
    else
        return path + filename;
}

std::string os::file_name(const std::string &path)
{
    auto p = path.find_last_of(path_sep);
    if(p != path.npos)
        return path.substr(p);
    else if(HAVE_DRIVE && path.size() > 2 && path[1] == ':')
        return path.substr(2);
    else
        return path;
}

std::string os::dir_name(const std::string &path)
{
    auto p = path.find_last_of(path_sep);
    if(p && p != path.npos)
        return path.substr(0, p);
    else if(!p && path.size())
        return path.substr(0, 1);
    else if(HAVE_DRIVE && path.size() > 2 && path[1] == ':')
        return path.substr(0, 2);
    else
        return ".";
}

std::string os::add_extension(std::string name, std::string ext)
{
    auto pos = name.find_last_of(".");
    if(pos == name.npos || pos == 0)
        return name + ext;
    else
        return name.substr(0, pos) + ext;
}

std::string os::get_extension_lower(std::string name)
{
    auto pos = name.find_last_of(".");
    if(pos == name.npos || pos == 0)
        return std::string();
    auto ret = name.substr(pos + 1);
    for(auto &c: ret)
        c = std::tolower(c);
    return ret;
}

void os::init()
{
#ifdef _WIN32
    // On windows, we need to set console output to UTF-8:
    SetConsoleOutputCP(CP_UTF8);
#else
    // No init needed.
#endif
}

int os::prog_exec(std::string exe, std::vector<std::string> &args)
{
    std::vector<const char *> pargs;
#ifdef _WIN32
    // Escape any string with spaces in it:
    std::vector<std::string> esc_args;
    for(const auto &s : args)
    {
        if(s.find(' ') != s.npos)
            esc_args.push_back("\"" + s + "\"");
        else
            esc_args.push_back(s);
    }
    // Create a vector with C pointers
    for(const auto &s : esc_args)
        pargs.push_back(s.c_str());
    pargs.push_back(nullptr);
    // win32 has the "spawn" function that calls the program and waits
    // for termination:
    return _spawnv(_P_WAIT, exe.c_str(), (char **)pargs.data());
#else
    // Create a vector with C pointers
    for(const auto &s : args)
        pargs.push_back(s.c_str());
    pargs.push_back(nullptr);

    // We reimplement "system" to allow passing arguments without escaping:

    // Ignore INT and QUIT signals in the parent process:
    sigset_t oldmask, newmask;
    struct sigaction sa = {SIG_IGN, 0}, oldint, oldquit;
    sigaction(SIGINT, &sa, &oldint);
    sigaction(SIGQUIT, &sa, &oldquit);

    // Block SIGCHLD
    sigemptyset(&newmask);
    sigaddset(&newmask, SIGCHLD);
    sigprocmask(SIG_BLOCK, &newmask, &oldmask);

    int status = -1;
    auto pid = fork();
    if(pid == 0)
    {
        // Child, reset INT, QUIT and CHLD signals to default
        struct sigaction sa = {SIG_DFL, 0};
        sigaction(SIGINT, &sa, nullptr);
        sigaction(SIGQUIT, &sa, nullptr);
        sigprocmask(SIG_SETMASK, &oldmask, nullptr);
        // Exec process
        execv(exe.c_str(), (char **)pargs.data());
        // If we got here, it is an error
        _exit(127);
    }
    else if(pid != -1)
    {
        // Wait until child returns
        while((waitpid(pid, &status, 0) == -1) && (errno == EINTR))
            ;
    }

    // Restore signals
    sigprocmask(SIG_SETMASK, &oldmask, NULL);
    sigaction(SIGINT, &oldint, NULL);
    sigaction(SIGQUIT, &oldquit, NULL);

    return status;
#endif
}
