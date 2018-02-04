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

// atarifp.cc: Emulates Atari FP format

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

const double atari_fp::expTab[99] = {
    1e-98, 1e-96, 1e-94, 1e-92, 1e-90, 1e-88, 1e-86, 1e-84, 1e-82, 1e-80,
    1e-78, 1e-76, 1e-74, 1e-72, 1e-70, 1e-68, 1e-66, 1e-64, 1e-62, 1e-60,
    1e-58, 1e-56, 1e-54, 1e-52, 1e-50, 1e-48, 1e-46, 1e-44, 1e-42, 1e-40,
    1e-38, 1e-36, 1e-34, 1e-32, 1e-30, 1e-28, 1e-26, 1e-24, 1e-22, 1e-20,
    1e-18, 1e-16, 1e-14, 1e-12, 1e-10, 1e-08, 1e-06, 1e-04, 1e-02, 1e+00,
    1e+02, 1e+04, 1e+06, 1e+08, 1e+10, 1e+12, 1e+14, 1e+16, 1e+18, 1e+20,
    1e+22, 1e+24, 1e+26, 1e+28, 1e+30, 1e+32, 1e+34, 1e+36, 1e+38, 1e+40,
    1e+42, 1e+44, 1e+46, 1e+48, 1e+50, 1e+52, 1e+54, 1e+56, 1e+58, 1e+60,
    1e+62, 1e+64, 1e+66, 1e+68, 1e+70, 1e+72, 1e+74, 1e+76, 1e+78, 1e+80,
    1e+82, 1e+84, 1e+86, 1e+88, 1e+90, 1e+92, 1e+94, 1e+96, 1e+98
};

