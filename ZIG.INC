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
-- zig.inc
-- The code editor.
--


constant ED_HEIGHT = 22, ED_STX = 1, ED_STY = 5, ED_WIDTH = 51

global atom color_coding
sequence est, blank

est = {}
for z = 1 to ED_WIDTH / 5 do
    est = est & ("*" & repeat(0, 4))
end for

blank = {}
for z = 1 to ED_WIDTH do
    blank = blank & {32, 31}
end for

color_coding = 1


global function col_attr(atom fore, atom back)

    return((back * 16) + fore)

end function


global function apply_str_color(sequence l, atom c)

    atom cx
    sequence r
    
    if ED_WIDTH - length(l) > 0 then
        l = l & repeat(0, ED_WIDTH - length(l))
    end if

    r = repeat(0, length(l) * 2)

    cx = 1
    for z = 1 to length(l) do
        r[(z * 2) - 1] = l[z]
        r[(z * 2)] = c
    end for

    return(r)

end function


global function set_str_color(sequence l, atom c)

    for z = 2 to length(l) by 2 do
        l[z] = c
    end for

    return(l)

end function


global function ed_colorcode(sequence l)

    if l[1] = '@' then
        return(set_str_color(l, 30))
    elsif l[1] = '#' then
        return(set_str_color(l, 23))
    elsif l[1] = '/' or l[1] = '\\' or l[1] = '?' then
        return(set_str_color(l, 19))
    elsif l[1] = ':' then
        return(set_str_color(l, 48))
    elsif l[1] = '\'' then
        return(set_str_color(l, 16))
    else return(l)
    end if

    return(l)

end function


global function hex_to_int(atom a)

    a = upper(a)

    if (a >= '0') and (a <= '9') then
        return(a - '0')
    elsif a = 'A' then return(10)
    elsif a = 'B' then return(11)
    elsif a = 'C' then return(12)
    elsif a = 'D' then return(13)
    elsif a = 'E' then return(14)
    elsif a = 'F' then return(15)
    else return(-1)
    end if

end function


global function expand_str(sequence l)

    atom cx
    sequence r

    r = repeat(0, length(l) * 2)

    cx = 1
    for z = 1 to length(l) do
        r[(z * 2) - 1] = l[z]
        r[(z * 2)] = 15
    end for
    
    return(r)

end function


global function t_ge_translatecodes(sequence l)

    atom curf, curb, z

    curf = -1
    curb = 1
    
    z = 1
    while 1 do
        if z > length(l) - 1 then exit end if
        if curf != -1 then l[z + 1] = col_attr(curf, curb) end if
        if l[z] = '`' and z < length(l) - 2 then
            curf = hex_to_int(l[z + 2])
            if curf != -1 then
                l = l[1..z - 1] & l[z + 4..length(l)]
                --l = l & {0,15,0,15}
                l[z + 1] = col_attr(curf, curb)
                if z > length(l) - 1 then return(l) end if
            end if
        end if
        if l[z] = '~' and z < length(l) - 2 then
            curb = hex_to_int(l[z + 2])
            if curb != -1 then
                l = l[1..z - 1] & l[z + 4..length(l)]
                --l = l & {0,15,0,15}
                l[z + 1] = col_attr(curf, curb)
                if z > length(l) - 1 then return(l) end if
            end if
        end if
        z = z + 2
    end while
    
    return(l)

end function


global function t_translatecodes(sequence l)

    atom curf, curb

    curf = -1
    curb = 1
    
    for z = 1 to length(l) - 1 by 2 do
        if curf != -1 then l[z + 1] = col_attr(curf, curb) end if
        if l[z] = '`' and z < length(l) - 2 then
            curf = hex_to_int(l[z + 2])
            if curf != -1 then
                l = l[1..z - 1] & l[z + 4..length(l)]
                l = l & {0,31,0,31}
                l[z + 1] = col_attr(curf, curb)
                if z > length(l) - 1 then return(l) end if
            end if
        end if
        if l[z] = '~' and z < length(l) - 2 then
            curb = hex_to_int(l[z + 2])
            if curb != -1 then
                l = l[1..z - 1] & l[z + 4..length(l)]
                l = l & {0,31,0,31}
                l[z + 1] = col_attr(curf, curb)
                if z > length(l) - 1 then return(l) end if
            end if
        end if
    end for
    
    return(l)

end function


global function ed_cst(sequence l, atom c)

    atom cx
    sequence r

    l = l & repeat(0, ED_WIDTH - length(l))
    r = repeat(0, length(l) * 2)

    cx = 1
    for z = 1 to length(l) do
        r[(z * 2) - 1] = l[z]
        r[(z * 2)] = c
    end for

    if color_coding then
        return(t_translatecodes(ed_colorcode(r)))
    else return(r)
    end if

end function


global procedure ed_redraw(sequence e, atom x)

    integer topx, botx, c

    topx = (x - (ED_HEIGHT / 2)) + 2
    botx = x + (ED_HEIGHT / 2) - 1
    c = 2

    for z = topx to botx do

        if z = x then
            display_text_image({ED_STX + c, ED_STY}, {apply_str_color(e[z], 31)})
        else
            if z > 0 and z < length(e) + 1 then
                display_text_image({ED_STX + c, ED_STY}, {ed_cst(e[z], 31)})
            elsif z = 0 or z = length(e) + 1 then
                display_text_image({ED_STX + c, ED_STY},
                {ed_cst(est, 30)})
            else
                display_text_image({ED_STX + c, ED_STY}, {blank})
            end if
        end if

        c = c + 1
    end for

end procedure


global function prep(sequence s)

    for z = 1 to length(s) do
        if sequence(s[z]) then
            if length(s[z]) > (ED_WIDTH - 2) then
                s = s[1..z - 1]
                        & {s[z][1..(ED_WIDTH - 2)]}
                        & {s[z][(ED_WIDTH - 2) + 1..length(s[z])]}
                        & s[z + 1..length(s)]
            end if
        end if
    end for

    return(s)

end function


global function do_ed(object e)

    atom exitflag, x, y, k, ox, oy, p
    sequence ss

    e = prep(e)

    cursor(UNDERLINE_CURSOR)

    ss = screen_save()

    box(ED_STX + 1, ED_STY - 2, ED_STX + ED_HEIGHT, ED_STY + ED_WIDTH, 1, "Editing Object")
    ed_redraw(e, 1)

    clear_keys()

    exitflag = 0
    x = -999
    y = 1

    while not exitflag do

        k = get_key()
        if x = -999 then
            x = 1
            ox = 0
        else ox = x
        end if
        oy = y

        if k = 27 then
            exitflag = 1
        elsif k = KEY_PGUP then
            x = x - (ED_HEIGHT - 3)
        elsif k = KEY_PGDN then
            x = x + (ED_HEIGHT - 3)
        elsif k = KEY_UP then
            x = x - 1
        elsif k = KEY_DN then
            x = x + 1
        elsif k = KEY_LF then
            y = y - 1
        elsif k = KEY_RT then
            y = y + 1
        elsif k = KEY_HOME then
            y = 1
        elsif k = KEY_END then
            y = length(e[x]) + 1
        elsif k = 25 then
            e = e[1..x - 1] & e[x + 1..length(e)]
            x = x - 1
        elsif k = KEY_CR then
            if y = length(e[x]) + 1 then
                e = e[1..x] & {{}} & e[x + 1..length(e)]
                x = x + 1
            elsif y = 1 then
                e = e[1..x - 1] & {{}} & e[x..length(e)]
                x = x + 1
                ox = -1
            else
                e = e[1..x - 1] & {e[x][1..y - 1]} & {e[x][y..length(e[x])]} & e[x + 1..length(e)]
                x = x + 1
                y = 1
            end if
        elsif k = 8 then
            if y = 1 then
                if x != 1 then
                    y = length(e[x - 1]) + 1
                    e = e[1..x - 2] & ({e[x - 1] & e[x]}) & e[x + 1..length(e)]
                    x = x - 1
                end if
            elsif y = length(e[x]) + 1 then
                e[x] = e[x][1..length(e[x]) - 1]
                y = y - 1
            else
                e[x] = e[x][1..y - 2] & e[x][y..length(e[x])]
                y = y - 1
            end if
        elsif k = KEY_DEL then
            if length(e[x]) = 1 then
                e[x] = {}
            elsif length(e[x]) = 0 then
                if length(e) != 1 then
                    e = e[1..x - 1] & e[x + 1..length(e)]
                else e = {}
                end if
            else
                if y = 1 then
                    e[x] = e[x][2..length(e[x])]
                elsif y >= length(e[x]) then
                    e[x] = e[x][1..length(e[x]) - 1]
                    y = length(e[x])
                else
                    e[x] = e[x][1..y - 1] & e[x][y + 1..length(e[x])]
                end if
            end if
            ox = -1
        elsif k != -1 then
            if y = 1 then
                e[x] = {k} & e[x]
            elsif y = length(e[x]) + 1 then
                e[x] = e[x] & {k}
            else
                e[x] = e[x][1..y - 1] & {k} & e[x][y..length(e[x])]
            end if
            y = y + 1
        end if

        if x != ox or y != oy then

            if length(e) = 0 then
                e = {{}}
            end if

            if x < 1 then
                x = 1
            end if

            if y < 1 then
                y = 1
            end if

            if x > length(e) then
                x = length(e)
            end if

            if y > length(e[x]) + 1 then
                y = length(e[x]) + 1
            end if

            if length(e[x]) > (ED_WIDTH - 2) then
                if x + 1 > length(e) then
                    e = append(e, {})
                end if
                p = ED_WIDTH - 2
                for z = p to 1 by -1 do
                    if e[x][z] = ' ' or
                    e[x][z] = 0 then
                        p = z
                        exit
                    end if
                end for
                e = e[1..x - 1] & {e[x][1..p]} & {e[x + 1] & e[x][p + 1..length(e[x])]} & e[x + 2..length(e)]
                x = x + 1
                y = length(e[x]) + 1
            end if

            position(ED_STX + ED_HEIGHT, ED_STY)
            printf(1, " %3d,%2d ", {x, y})

            position(12, ED_STY + (y - 1))
            ed_redraw(e, x)

        end if

    end while

    screen_restore(ss)
    cursor(NO_CURSOR)
    return(e)

end function

