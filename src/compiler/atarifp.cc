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

// atarifp.cc: Emulates Atari FP format

#include "atarifp.h"

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

// Prints a double in a format suitable for BASIC input
std::string atari_fp::to_string()
{
    // Update internal representation
    update();

    // Check for '0'
    if( (exp & 0x7F) == 0 )
        return "0";

    // Transform mantisa to decimal digits
    char buf[12];
    char *dig = buf;
    for(int i=0; i<5; i++)
    {
        dig[2*i]   = '0' + (mant[i] >> 4);
        dig[2*i+1] = '0' + (mant[i] & 0x0F);
    }
    dig[10] = 0;

    // Extract exp and sign
    int iexp = (exp & 0x7F) * 2 - 136;
    int sgn = exp & 0x80;

    // Remove zeroes at end
    int i;
    for(i=9; i>0 && dig[i] == '0'; i--)
    {
        dig[i] = 0;
        iexp ++;
    }
    // Remove possible zero at start
    if( *dig == '0' )
    {
        dig++;
        i--;
    }

    // Result string - start with sign
    std::string ret = sgn ? "-" : "";

    if( iexp < 0 && iexp >= -i-1 )
    {
        while( iexp > -i-1 )
        {
            ret += *dig;
            dig++;
            iexp--;
        }
        ret += '.';
        ret += dig;
    }
    else if( iexp+2 == -i )
    {
        ret += ".0";
        ret += dig;
    }
    else if( iexp == 0 )
        ret += dig;
    else if( iexp == 1 )
    {
        ret += dig;
        ret += '0';
    }
    else if( iexp == 2 )
    {
        ret += dig;
        ret += "00";
    }
    else if( iexp < -99 )
    {
        ret += dig[0];
        ret += '.';
        if( i > 0 )
            ret += dig + 1;
        ret += "E-";
        iexp = - iexp - i;
        if( iexp > 9 )
            ret += '0' + (iexp/10);
        ret += '0' + (iexp % 10);
    }
    else
    {
        ret += dig;
        ret += 'E';
        if( iexp < 0 )
        {
            ret += '-';
            iexp = -iexp;
        }
        if( iexp > 9 )
            ret += '0' + (iexp/10);
        ret += '0' + (iexp % 10);
    }
    return ret;
}

