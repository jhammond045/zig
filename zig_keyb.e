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
-- keyread.e
-- Michael Bolin's get_keys() routine, used by ZIG's game engine.
-- Michael's comments are below:
 
-- Here's an extremely useful library routine for reading the keyboard.
 
-- It is used just like get_key(), except that it's called get_keys(),
-- it returns a sequence instead of an atom, and the values returned are
-- scan codes, instead of ASCII codes.
 
-- The advantage is that the routine will recognize multiple keypresses
-- at the same time, and return them in one sequence.
-- Also, there is no repeat delay, instead the code is returned constantly
-- until the key is released.
 
-- Finally, the routine is also some 10-20 times faster than get_key()
 
-- Regards,
--                 Michael Bolin
--                 June 1997                   
-------------------------------------------------------------------- 
-- Hi all,
-- 
-- Everyone using my keyread.e include file should now replace it with this
-- updated version. A bug has been fixed that could cause it to crash
-- (in programs that use it along with the ordinary input routines).
-- It has a new procedure, clear_keys(), that should be called after any
-- calls to these normal routines, i.e. get_key(), gets(0), etc., but it
-- is not necessary if your program uses only get_keys().
-- 
-- Regards,
--             Michael Bolin
--             February 4, 1998

------------- keyread.e ---------------------
include machine.e

sequence usual_address
atom keyboard_address,keyb_point
atom code_segment,segment,key_buffer
atom de_interrupt

de_interrupt=allocate(4)
lock_memory(de_interrupt,4)
poke(de_interrupt,{#FB,#C3,#FA,#C3})

segment=allocate(4)
lock_memory(segment,4)

key_buffer=allocate(1024)
lock_memory(key_buffer,1024)

keyb_point=allocate(4)
lock_memory(keyb_point,4)
poke(keyb_point,{0,0,0,0})          -- offset into keyboard buffer

sequence save_segment_code
save_segment_code = {
    #53,   -- push ebx
    #0E,   -- push cs   or #1E push ds
    #5B,   -- pop ebx
    #89, #1D} & int_to_bytes(segment) & -- mov segment, ebx
    {#5B,   -- pop ebx
    #C3}    -- ret

atom save_segment
save_segment = allocate(length(save_segment_code))
poke(save_segment, save_segment_code)
call(save_segment) -- save code segment

code_segment = peek(segment)+peek(segment+1)*256

poke(save_segment+1, #1E)
call(save_segment) -- save data segment

usual_address = get_vector(9)

sequence keyboard_code
keyboard_code={#1E,                         -- push ds
               #60,                             -- pushad
               #BB}&peek({segment,2})&{0,0}&    -- mov ebx, data segment value
               {#53,                            -- push ebx
               #1F,                             -- pop ds
               #BA,#60,00,00,00,                -- mov edx,#60
               #EC,                             -- in al,edx
               #BE}&int_to_bytes(keyb_point) &  -- mov esi,keybuffer offset
               {#8B,#2E} &                      -- mov ebp,[esi]
               #BE & int_to_bytes(key_buffer) & -- mov esi,keybuffer
               {#88,#04,#2E} &                  -- mov [esi+ebp],al
               #BE & int_to_bytes(keyb_point) & -- move esi,keybuffer offset
               {#45,                            -- inc ebp
               #81,#E5,255,3,0,0,               -- and ebp,1023
               #89,#2E,                         -- mov [esi],ebp
               #E4,#61,                         -- in al,0x61
               #0C,#82,                         -- or al,0x82
               #E6,#61,                         -- out 0x61,al
               #24,#7F,                         -- and al,0x7f
               #E6,#61,                         -- out 0x61,al
               #B0,#20,                         -- mov al,0x20
               #E6,#20,                         -- out 0x20,al
               #61,                             -- popad
               #1F,                             -- popds
               #EA}
               & int_to_bytes(usual_address[2]) &
               and_bits(usual_address[1],255) & floor(usual_address[1]/256)

keyboard_address=allocate(length(keyboard_code))

poke(keyboard_address,keyboard_code)

lock_memory(keyboard_address,length(keyboard_code))

poke(key_buffer,repeat(0,1024))
set_vector(9,{code_segment,keyboard_address})

sequence pressed_keys
sequence two_longs,two_codes

pressed_keys={}
two_longs={53,181,83,211,79,207,81,209,28,156,56,184,29,157,77,205,
           75,203,80,208,72,200,73,201,71,199,82,210}
two_codes={53+256,53+384,83+256,83+384,79+256,79+384,81+256,81+384,
           28+256,28+384,56+256,56+384,29+256,29+384,333,333+128,
           331,331+128,336,336+128,328,328+128,329,329+128,327,
           327+128,338,338+128}

sequence old_codes
old_codes={}
global function get_keys()
    sequence codes
    integer offset,place,key,code,pos

    call(de_interrupt+2)
    offset=peek(keyb_point)
    poke(1052,peek(1050))           -- Clear keyboard buffer
    if offset=0 then
        call(de_interrupt)
        return pressed_keys
    end if
    poke(keyb_point,{0,0,0,0})
    codes=old_codes & peek({key_buffer,offset})
    call(de_interrupt)
    place=1
    while place<=length(codes) do
        code=codes[place]
        if code=224 then
            if length(codes)-place=0 then
                exit                         -- If not enough codes in buffer
            end if
            pos=find(codes[place+1],two_longs)
            if pos then
                key=two_codes[pos]
                place=place+1
            else
                key=0
            end if
        elsif code=225 then                         -- Ignore pause key
            key=0
            if length(codes)-place>=5 then
                place=place+4
            else
                exit
            end if
        else
            key=code
        end if
        if key then                 -- Insert or remove key from pressed list
            if and_bits(key,128)=128 then
                pos=find(key-128,pressed_keys)
                if pos then
                    pressed_keys=pressed_keys[1..pos-1] &
                        pressed_keys[pos+1..length(pressed_keys)]
                end if
            else
                pos=find(key,pressed_keys)
                if pos=0 then
                    pressed_keys=append(pressed_keys,key)
                end if
            end if
            place=place+1
        else
            place=place+2
        end if
    end while
    old_codes=codes[place..length(codes)]
    return pressed_keys
end function

global procedure clear_keys()
    poke(1052,peek(1050))           -- Clear keyboard buffer
    poke(keyb_point,{0,0,0,0})
    poke(key_buffer,repeat(0,1024))
    pressed_keys={}
end procedure

-- In Euphoria 2.1 this file (unless modified) is FREE - 0 statements.
with 56247325 -- delete this statement if it causes an error

