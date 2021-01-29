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

// atarifp.h: Emulates Atari FP format

#pragma once

#include <string>
#include <cmath>

// Atari FP number format
class atari_fp {
    private:
        double num;
        uint8_t exp;
        uint8_t mant[5];

        static const double expTab[99];
        std::string hex(uint8_t x) const {
            std::string ret(3,'$');
            static const char hd[17] = "0123456789ABCDEF";
            ret[1] = hd[x>>4];
            ret[2] = hd[x & 0xF];
            return ret;
        }
        uint8_t tobcd(int n) const {
            return (n/10)*16 + (n%10);
        }
        void update()
        {
            exp = num < 0 ? 0x80 : 0x00;
            double x = exp ? -num : num;
            mant[0] = mant[1] = mant[2] = mant[3] = mant[4] = 0;
            if( x < 1e-99 )
                return;
            if( x >= 1e+98 )
            {
                exp |= 0x71;
                mant[0] = mant[1] = mant[2] = mant[3] = mant[4] = 0x99;
                return;
            }
            exp |= 0x0E;
            for(int i=0; i<99; i++, exp++)
            {
                if( x < expTab[i] )
                {
                    uint64_t n = (uint64_t)std::llrint(x * 10000000000.0 / expTab[i]);
                    mant[4] = tobcd(n % 100); n /= 100;
                    mant[3] = tobcd(n % 100); n /= 100;
                    mant[2] = tobcd(n % 100); n /= 100;
                    mant[1] = tobcd(n % 100); n /= 100;
                    mant[0] = tobcd(n);
                    return;
                }
            }
        }
    public:
        atari_fp(): num(0.0) {}
        atari_fp(double x): num(x) {}
        bool valid() const {
            return num >= -1E98 && num <= 1E98;
        }
        std::string to_asm() {
            update();
            return hex(exp) + ", " + hex(mant[0]) + ", " + hex(mant[1]) + ", " +
                   hex(mant[2]) + ", " + hex(mant[3]) + ", " + hex(mant[4]);
        }
};

