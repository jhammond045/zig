-- ZIG Library Loader v2.0 - library format convention 3 (text-literals)

include file.e
include get.e
include wildcard.e

global sequence object_library, -- library data
                lib_listing,    -- listing of object libraries loaded
                class_table     -- class table

global constant
        -- Library operation constants
                CHOOSE_NUM = 0, CHOOSE_BOARD = 1, CHOOSE_CHAR = 2,
                CHOOSE_COLOR = 3
                
global constant
        -- lookup values for objects stored in libraries
        LIB_FROM = 1,   -- where the object is from (which library)
        LIB_CODELOCK = 2,  -- is the code locked?
        LIB_NAME = 3,   -- its name
        LIB_CHAR = 4,   -- char
        LIB_COLOR = 5,    -- color
        LIB_CLASS = 6,  -- object's class NUMBER (ref to class_table)
                        -- 0 is no class (not displayed in menu)
        LIB_PROPS = 7,  -- the properties - subsequence
            -- lookup values for properties
            PROP_NAME = 1,  -- property name
            PROP_MAX = 2,   -- max amount for this property
            PROP_TYPE = 3,  -- the type (see CHOOSE_nnnn constants)
        LIB_PROG = 8,    -- the object's program
        
        NEW_LIB_ITEM = {{},0,{},2,15,0,{},{{}}}


global function load_lib_listing()

    atom        f
    sequence    libs, dx

    if sequence(dir("zig_libs.inf")) then
        f = open("zig_libs.inf", "r")
    else
        f = open("zig_libs.inf", "w")
        if length(dir("stdlib.olf")) then
            puts(f, "stdlib.olf")
        else puts(f, "NULL")
        end if
        close(f)
        f = open("zig_libs.inf", "r")
    end if

    libs = {}
    dx = {}
    while TRUE do
        dx = gets(f)
        dx = dx[1..length(dx) - 1]
        if not compare(dx, "NULL") then
            exit
        end if
        if length(dir(dx)) then
            libs = append(libs, lower(dx))
        end if
    end while
    close(f)

    return(libs)

end function


function valu(object a)

    sequence b
    b = value(a)
    return(b[2])

end function


function get_word(sequence a, atom b)

    sequence c
    c = {}
    
    if b < 1 then b = 1 end if
    
    for z = b to length(a) - 1 do
        if z = length(a) - 1 then
            c = c & {a[z]}
            return(c)
        else
            if a[z] != 32 and a[z] != 0 and a[z] != 10 and a[z] != 13 then
                c = c & {a[z]}
            else
                return(c)
            end if
        end if
    end for
    return(c)

end function


function get_param(sequence a)

    return(get_word(a, find(' ', a) + 1))
    
end function


global function load_libraries(sequence files)
    atom f, exitf, cl, flen, n
    sequence b, olf, buf, x
    
    class_table = {}

    olf = {}
    for z = 1 to length(files) do
        if length(dir(files[z])) then
            f = open(files[z], "r")
            flen = seek(f, -1)
            flen = where(f)
            cl = seek(f, 0)
            b = gets(f)
            if compare(b[1..3], "***") = 0 then
                exitf = 0
                buf = {}
                cl = 0
                while exitf = 0 do
                    if where(f) >= flen then exit end if
                    b = gets(f)
                    if length(b) then
                        if b[1] != '.' then
                            if b[1] != ';' then
                                buf = append(buf, b[1..length(b) - 1])
                            end if
                        else
                            x = upper(get_word(b, 2))
                            if compare(x, "OBJECT") = 0 then
                                x = upper(get_param(b))
                                if compare(x, "BEGIN") = 0 then
                                    olf = append(olf, NEW_LIB_ITEM)
                                    cl = cl + 1
                                    olf[cl][LIB_FROM] = files[z]
                                end if
                            elsif compare(x, "NAME") = 0 and cl != 0 then
                                olf[cl][LIB_NAME] = get_param(b)
                            elsif compare(x, "CHAR") = 0 and cl != 0 then
                                olf[cl][LIB_CHAR] = valu(get_param(b))
                            elsif compare(x, "COLOR") = 0 and cl != 0 then
                                olf[cl][LIB_COLOR] = valu(get_param(b))
                            elsif compare(x, "CODELOCK") = 0 and cl != 0 then
                                olf[cl][LIB_CODELOCK] = (valu(get_param(b)) = 1)
                            elsif compare(x, "CLASS") = 0 and cl != 0 then
                                x = lower(get_param(b))
                                if find(x, class_table) != 0 then
                                    olf[cl][LIB_CLASS] = find(x, class_table)
                                else
                                    class_table = class_table & {x}
                                    olf[cl][LIB_CLASS] = length(class_table)
                                end if
                            elsif compare(x, "CODE") = 0 and cl != 0 then
                                x = upper(get_param(b))
                                if compare(x, "BEGIN") = 0 then
                                    buf = {}
                                elsif compare(x, "END") = 0 then
                                    olf[cl][LIB_PROG] = buf
                                    buf = {}
                                end if
                            elsif compare(x, "PROP") = 0 and cl != 0 then
                                x = upper(get_param(b))
                                if compare(x, "COUNT") = 0 then
                                    olf[cl][LIB_PROPS] = repeat({{},0,0}, valu(b[13..length(b)]))
                                end if
                            elsif compare(x, "PNAME") = 0 and cl != 0 then
                                n = b[8] - 48
                                olf[cl][LIB_PROPS][n][PROP_NAME] = b[9..length(b) - 1]
                            elsif compare(x, "PMAX") = 0 and cl != 0 then
                                n = b[7] - 48
                                olf[cl][LIB_PROPS][n][PROP_MAX] = valu(b[8..length(b) - 1])
                            elsif compare(x, "PTYPE") = 0 and cl != 0 then
                                n = b[8] - 48
                                x = trim(upper(b[9..length(b) - 1]))
                                if compare(x, "VALUE") = 0 then
                                    olf[cl][LIB_PROPS][n][PROP_TYPE] = CHOOSE_NUM
                                elsif compare(x, "BOARD") = 0 then
                                    olf[cl][LIB_PROPS][n][PROP_TYPE] = CHOOSE_BOARD
                                elsif compare(x, "CHAR") = 0 then
                                    olf[cl][LIB_PROPS][n][PROP_TYPE] = CHOOSE_CHAR
                                elsif compare(x, "COLOR") = 0 then
                                    olf[cl][LIB_PROPS][n][PROP_TYPE] = CHOOSE_COLOR
                                end if
                            end if
                        end if
                    end if
                end while
            end if
            close(f)
        end if
    end for
    
    return olf
end function


global procedure libload()
    
object_library = load_libraries(load_lib_listing())

printf(1, "Number of objects: %d\n", length(object_library))

for z = 1 to length(object_library) do
    printf(1, "Object %d\nLibrary from: %s\n", {z, object_library[z][LIB_FROM]})
    printf(1, "Name: %s, ", {object_library[z][LIB_NAME]})
    printf(1, "Char: %d, Color: %d, Codelock: %d\n ", {object_library[z][LIB_CHAR], object_library[z][LIB_COLOR], object_library[z][LIB_CODELOCK]})
end for

end procedure


