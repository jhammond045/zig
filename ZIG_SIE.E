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
-- zig_sie.e
-- The sie editor (C) Jacob Hammond.
--

include graphics.e

-- sie editor code segment START --------------------------------------------

global procedure sie_Redraw(sequence Ed, atom X, atom Y)
    atom RealX

    bk_color(1)

    clear_screen()

    text_color(14)
    bk_color(4)
    puts(1, " [sie 2.0] Editing Object ")

    text_color(0)
    bk_color(3)

    position(25, 1)
    printf(1, " %2d, %2d  Esc - end object editing ", {X, Y})

    text_color(15)
    bk_color(1)

    for z = 2 to 24 do
        RealX = (X - 12) + z

        if RealX = 0 or RealX = length(Ed) + 1 then
            position(z, 1)
            text_color(9)
            for a = 1 to 8 do
                puts(1, "    -    ")
            end for
            text_color(15)
        end if

        if RealX > 0 and RealX < length(Ed) + 1 then
            position(z, 1)
            for a = 1 to length(Ed[RealX]) do
                puts(1, Ed[RealX][a])
            end for
        end if
    end for

    position(12, Y + 1)
end procedure

global procedure sie_InitDisplay()

    bk_color(1)
    cursor(UNDERLINE_CURSOR)

    clear_screen()

    text_color(14)
    bk_color(4)
    puts(1, "sie 0.9a - beta 4 ")

    text_color(15)
    bk_color(1)
end procedure

global function do_ed(sequence Ed)
    atom Key, X, Y, OldX, OldY
    sequence Buf, SS

    SS = screen_save()
    sie_InitDisplay()

    X = 1
    Y = 1

    sie_Redraw(Ed, X, 1)

    while 1 do
        OldX = X
        OldY = Y

        Key = get_key()
        if Key = KEY_UP then
            X = X - 1
        elsif Key = KEY_DN then
            X = X + 1
        elsif Key = KEY_LF then
            Y = Y - 1
        elsif Key = KEY_RT then
            Y = Y + 1
        elsif Key = KEY_HOME then
            Y = 1
            sie_Redraw(Ed, X, Y)
        elsif Key = KEY_END then
            Y = length(Ed[X] + 1)
            sie_Redraw(Ed, X, Y)
        elsif Key = 8 then          -- Backspace
            if Y != 1 then
                Buf = Ed[X][1..Y - 1]
                for z = Y + 1 to length(Ed[X]) do
                    Buf = append(Buf, Ed[X][z])
                end for

                Ed[X] = Buf

                Y = Y - 1

                sie_Redraw(Ed, X, Y)
            else                    -- deleting a line w/ bksp
                if length(Ed) != 1 then
                    if length(Ed[X]) = 1 then
                        Ed[X] = {}
                    elsif length(Ed[X]) = 0 then
                        if X = length(Ed) then
                            Ed = Ed[1..length(Ed) - 1]
                        else
                            Buf = Ed[1..X - 1]

                            for z = X + 1 to length(Ed) do
                                Buf = append(Buf, Ed[z])
                            end for

                            Ed = Buf
                        end if
                    end if

                    X = X - 1

                    sie_Redraw(Ed, X, Y)
                end if
            end if
        elsif Key = KEY_CR then

            if X > length(Ed) then
                Ed = append(Ed, {})
            else
                Buf = Ed[1..X]
                Buf = append(Buf, {})

                for z = X + 1 to length(Ed) do
                    Buf = append(Buf, Ed[z])
                end for

                Ed = Buf
            end if

            X = X + 1
            Y = 1

            sie_Redraw(Ed, X, Y)

        elsif Key = KEY_ESC then
            cursor(NO_CURSOR)
            screen_restore(SS)
            return Ed
        elsif Key != -1 then
            if Y != length(Ed[X] + 1) then
                if length(Ed[X]) = 0 then
                    Ed[X] = append(Ed[X], Key)
                else
                    Ed[X] = Ed[X][1..Y - 1] & Key & Ed[X][Y..length(Ed[X])]
                end if
            else
                Ed[X] = append(Ed[X], Key)
            end if
            Y = Y + 1

            sie_Redraw(Ed, X, Y)
        end if

        if X != OldX then
            if X < 1 then
                X = 1
            elsif X > length(Ed + 1) then
                X = length(Ed + 1)
            end if
        end if

        if Y != OldY then
            if Y < 1 then
                Y = 1
            elsif Y > length(Ed[X]) then
                Y = length(Ed[X])
            end if
            position(12, Y)
        end if

        if X != OldX then
            Y = 1

            sie_Redraw(Ed, X, Y)
            position(12, Y)
        end if
    end while

end function

-- end of sie editor code segment -------------------------------------------


