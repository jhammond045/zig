--
-- ZIG version 2.0 - the ZZT-Inspired Game Creation System
-- Copyright (C) 1998-2001, Jacob Hammond
-- Released under Interactive Fantasies
-- Website: http://surf.to/zig
-- E-mail:  zig16@hotmail.com
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; either version 2 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-307, USA.
--
-- Contact information:
--  * via e-mail: zig16@hotmail.com
--  * via paper mail:
--                  Jacob Hammond
--                  1680 Prairie Hawke Ct.
--                  McKinleyville, CA  95519
--                  USA
--
-- Telephone number available on request.
--
-----------------------------------------------------------------------------
-- palette.e
-- Fast palette routine using DOS interrupts. From Greg Harris.
--
-- get_palette() and set_palette()

-- I found a way to read and set the individual DAC palette with
-- interrupts. I know there is a routine for setting individual palette
-- entries in Euphoria, however, the set_palette routine included below
-- appears to be about 30% faster than the built in routine. Get_palette is
-- also included. Please feel free to use this if it helps.

-- Greg Harris
-- Hollow Horse Software
include machine.e

global function get_palette(integer index)
--get palette entry index and return {r,g,b} for index
    sequence regs
    integer val1, val2, val3

    if config[NO_EGA] = TRUE then
        return({0,0,0})
    end if

    if index < 0 then index = 0 end if
    if index > 255 then index = 255 end if
    regs = repeat(0,10)
    regs[REG_AX] = #1015
    regs[REG_BX] = index
    regs = dos_interrupt(#10,regs)
    --green
    val1 = and_bits(regs[REG_CX], #FF00) / 256
    --blue
    val2 = and_bits(regs[REG_CX], #FF)
    --red
    val3 = and_bits(regs[REG_DX], #FF00) / 256
    return {val3,val1,val2} --{r,g,b}
end function
-----------------------------------------------------------------

global procedure set_palette(integer index, sequence color)
    --similar to Euphoria's palette() command
    --Set palette entry index with color {r,g,b}

    sequence regs

    if config[NO_EGA] = FALSE then

        regs = repeat(0, 10)
        regs[REG_AX] = #1010
        regs[REG_BX] = index
        regs[REG_CX] = color[2] * 256 + color[3]
        regs[REG_DX] = color[1] * 256
        regs = dos_interrupt(#10, regs)

    end if

end procedure

