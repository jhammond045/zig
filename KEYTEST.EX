include zig_keyb.e

atom k
sequence l
k = 0
l = {}
while k != 1 do
    l = get_keys()
    if length(l) then k = l[1] else k = 0 end if
    ?l
end while

