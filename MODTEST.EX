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
-- modwave.e
-- Module and Wave file player for Euphoria  (version 3f)
-- Pete Eberlein <xseal@harborside.com>
-- Revision history highlights:
-- Oct. 28, 1997 (just the loader)
-- Jan. 23, 98 (working on the rest)
-- Feb. 11  fixed the speed, bpm was a major headache
-- Feb. 12  added Jacques Deschenes' doswrap.e for fast DOS file input
-- Feb. 22  did wave files w/ effects
-- Mar. 16  fixed the last mod memory leak (I hope)
-- Mar. 24  fixed sb pro high-speed playback bug
-- Apr. 17  inlined fastfile.e and sound.e
-- Apr. 21  fixed bug that causeways:  mod-chan = max-chan
-- Apr. 22  fixed lost keypresses when using Michael Bolin's keyread.e
-- Apr. 25  fixed memory corruption bug (DS,ES not saved on interrupt!)

-- stuff todo:
---- xm, s3m, it loaders  (not anytime soon)
---- more effects for wav files
---- kill the inventor of mod files


-- fastfile.e
-- fast binary file operations (converted from doswrap.e by Jacques Deschenes)
-- Pete Eberlein <xseal@harborside.com>

-- fopen     } returns -1 if error, file handle otherwise

-- fclose    } fresult = -1 if error, 0 otherwise

-- freads     \
-- fread_mem   } fresult = bytes_read or -1 if error

-- fwrites    \ 
-- fwrite_mem  } fresult = bytes_written or -1 if error

-- fseek      \
-- fseek_end   } fresult = new_file_pos or -1 if error
-- fseek_rel  /

include machine.e

constant buffer_size = 32768
constant file_buffer = allocate_low(buffer_size)
if file_buffer = 0 then
    puts(1, "out of low memory\n")
    abort(1)
end if

sequence regs
regs = repeat(0, 10)

global constant READ = 0, WRITE = 1, READ_WRITE=2
global integer fresult

type filemode(object i)
    if atom(i) then
        return i >= 0 and i <= 2
    end if
    return 1
end type

global function fopen(sequence name, filemode mode)
    atom name_buffer
    name_buffer = allocate_low(length(name)+1)
    if not name_buffer then
        return -1
    end if
    poke(name_buffer, name & 0)
    if sequence(mode) then
        if find('w',mode) or find('W',mode) then -- write
            if find('r',mode) or find('R',mode) then -- read+write
                mode = READ_WRITE
            else
                mode = WRITE
            end if
        else -- read
            mode = READ
        end if
    end if
    regs[REG_AX] = #3D00 + mode
    regs[REG_DS] = floor(name_buffer/16)
    regs[REG_DX] = remainder(name_buffer,16)
    regs = dos_interrupt(#21,regs)
    if and_bits(regs[REG_FLAGS],1) then
        if mode != READ then
            regs[REG_AX] = #3C00
            regs[REG_CX] = 0 -- attributes
            regs[REG_DS] = floor(name_buffer/16)
            regs[REG_DX] = remainder(name_buffer,16)
            regs = dos_interrupt(#21,regs)
            if and_bits(regs[REG_FLAGS],1) then
                regs[REG_AX] = -1 -- fail to create
            end if
        else
            regs[REG_AX] = -1 -- fail to open
        end if
    end if
    free_low(name_buffer)
    return regs[REG_AX]  -- return file handle
end function            
        
global procedure fclose(integer handle)
    regs[REG_AX] = #3E00
    regs[REG_BX] = handle
    regs = dos_interrupt(#21,regs)
    fresult = -and_bits(regs[REG_FLAGS], 1)
end procedure

global function freads(integer handle, integer bytes)
    sequence data, outregs
    regs[REG_AX] = #3F00
    regs[REG_BX] = handle
    regs[REG_DS] = floor(file_buffer/16)
    regs[REG_DX] = remainder(file_buffer,16)
    data = {}
    fresult = 0
    while bytes do
        if bytes > buffer_size then
            regs[REG_CX] = buffer_size
        else
            regs[REG_CX] = bytes
        end if
        bytes = bytes - regs[REG_CX]
        outregs = dos_interrupt(#21,regs)
        if and_bits(outregs[REG_FLAGS],1) then
            fresult = -1
            return {} -- failed to read
        end if
        data = data & peek({file_buffer, outregs[REG_AX]})
        fresult = fresult + outregs[REG_AX]
    end while
    return data
end function

global procedure fread_mem(integer handle, atom mem, integer bytes)
    sequence outregs
    regs[REG_AX] = #3F00
    regs[REG_BX] = handle
    regs[REG_DS] = floor(file_buffer/16)
    regs[REG_DX] = remainder(file_buffer,16)
    fresult = 0
    while bytes do
        if bytes > buffer_size then
            regs[REG_CX] = buffer_size
        else
            regs[REG_CX] = bytes
        end if
        bytes = bytes - regs[REG_CX]
        outregs = dos_interrupt(#21,regs)
        if and_bits(outregs[REG_FLAGS],1) then
            fresult = -1
            return -- failed to read
        end if
        mem_copy(mem, file_buffer, outregs[REG_AX])
        mem = mem + outregs[REG_AX]
        fresult = fresult + outregs[REG_AX]
    end while
end procedure

global procedure fwrites(integer handle, sequence data)
    sequence outregs
    regs[REG_AX] = #4000
    regs[REG_BX] = handle
    regs[REG_DS] = floor(file_buffer/16)
    regs[REG_DX] = remainder(file_buffer,16)
    fresult = 0
    while length(data) do
        if length(data) > buffer_size then
            regs[REG_CX] = buffer_size
            poke(file_buffer, data[1..buffer_size])
            data = data[buffer_size+1..length(data)]
        else
            regs[REG_CX] = length(data)
            poke(file_buffer, data)
            data = {}
        end if
        outregs = dos_interrupt(#21,regs)
        if and_bits(outregs[REG_FLAGS],1) then
            fresult = -1
            return  -- failed to write
        end if
        fresult = fresult + outregs[REG_AX]
    end while
end procedure

global procedure fwrite_mem(integer handle, atom mem, integer bytes)
    sequence outregs
    regs[REG_AX] = #4000
    regs[REG_BX] = handle
    regs[REG_DS] = floor(file_buffer/16)
    regs[REG_DX] = remainder(file_buffer,16)
    fresult = 0
    while bytes do
        if bytes > buffer_size then
            regs[REG_CX] = buffer_size
        else
            regs[REG_CX] = bytes
        end if
        mem_copy(file_buffer, mem, regs[REG_CX])
        mem = mem + regs[REG_CX]
        bytes = bytes - regs[REG_CX]
        outregs = dos_interrupt(#21,regs)
        if and_bits(outregs[REG_FLAGS],1) then
            fresult = -1
            return -- failed to read
        end if
        fresult = fresult + outregs[REG_AX]
    end while
end procedure

procedure f_seek()
    regs = dos_interrupt(#21,regs)
    if and_bits(regs[REG_FLAGS], 1) then
        fresult = -1
    else
        fresult = regs[REG_AX] + #10000 * regs[REG_DX]
    end if
end procedure

global procedure fseek(integer handle, integer distance)
    regs[REG_AX] = #4200
    regs[REG_BX] = handle
    regs[REG_CX] = floor(distance/#10000)
    regs[REG_DX] = remainder(distance,#10000)
    f_seek()
end procedure
    
global procedure fseek_rel(integer handle, integer distance)
    regs[REG_AX] = #4201
    regs[REG_BX] = handle
    regs[REG_CX] = floor(distance/#10000)
    regs[REG_DX] = remainder(distance,#10000)
    f_seek()
end procedure

global procedure fseek_end(integer handle, integer distance)
    regs[REG_AX] = #4202
    regs[REG_BX] = handle
    regs[REG_CX] = floor(distance/#10000)
    regs[REG_DX] = remainder(distance,#10000)
    f_seek()
end procedure

------------------------- end fastfile.e -----------------------------------


-- sound.e
-- SoundBlaster interface
-- Pete Eberlein
-- 25 Apr 1998

include machine.e

function allocate_proc(sequence code)
    atom proc
    proc = allocate(length(code))
    if proc then
        lock_memory(proc, length(code))
        poke(proc, code)
        return proc
    end if
    printf(1, "Unable to allocate memory for length-%d sequence...\nProgram aborted.\n", {length(code)})
    abort(1)
end function

----------------------------------------------------------------------------
--PORT I/O------------------------------------------------------------------
----------------------------------------------------------------------------

constant in_byte_result = allocate_proc({0})
constant in_byte_proc = allocate_proc(
   {#50,                    --push eax
    #52,                    --push edx
    #BA,#00,#00,#00,#00,    --mov edx, port (3)
    #EC,                    --in al, dx
    #A2}                    --mov result, al
    & int_to_bytes(in_byte_result) & {
    #5A,                    --pop edx
    #58,                    --pop eax
    #C3})                   --ret
constant out_byte_proc = allocate_proc(
   {#50,                    --push eax
    #52,                    --push edx
    #BA,#00,#00,#00,#00,    --mov edx, port (3)
    #B0,#00,                --mov al, data (8)
    #EE,                    --out dx, al
    #5A,                    --pop edx
    #58,                    --pop eax
    #C3})                   --ret
constant out_word_proc = allocate_proc(
   {#50,                    --push eax
    #52,                    --push edx
    #BA,#00,#00,#00,#00,    --mov edx, port (3)
    #B8,#00,#00,#00,#00,    --mov eax, data (8)
    #66,#EF,                --out dx, ax
    #5A,                    --pop edx
    #58,                    --pop eax
    #C3})                   --ret

global function in_byte(integer port)
    poke4(in_byte_proc + 3, port)
    call(in_byte_proc)
    return peek(in_byte_result)
end function

global procedure out_byte(integer port, object data)
    poke4(out_byte_proc + 3, port)
    if atom(data) then
        data = {data}
    end if
    for i = 1 to length(data) do
        poke(out_byte_proc + 8, data[i])
        call(out_byte_proc)
    end for
end procedure

global procedure out_word(integer port, object data)
    poke4(out_word_proc + 3, port)
    if atom(data) then
        data = {data}
    end if
    for i = 1 to length(data) do
        poke4(out_word_proc + 8, data[i])
        call(out_word_proc)
    end for
end procedure


----------------------------------------------------------------------------
--SOUND BLASTER INITIALIZATION----------------------------------------------
----------------------------------------------------------------------------

global constant 
    MONO = 1,
    STEREO = 2
    
global integer playback_mode, playback_bits, playback_rate, volume, 
    sound_debug_file, pcspeaker
global sequence sound_error
sound_debug_file = 0
playback_mode = 0
pcspeaker = 0
integer base, irq, dma, irq_int_vector, sound_init
sound_init = 0
integer DSP_RESET,        -- dsp reset i/o port
        DSP_READ_data,    -- dsp read data i/o port
        DSP_WRITE_data ,  -- dsp write data i/o port
        DSP_WRITE_STATUS, -- dsp write status i/o port
        DSP_data_AVAIL,   -- dsp read status i/o port

-- some DSP commands
        AUTO_INIT_8,        -- auto initialize 8-bit
        PAUSE_DMA,          -- halt dma operation
        CONTINUE_DMA,       -- continue dma operation
        CONTINUE_AUTO_INIT, -- continue auto-initialize dma
        EXIT_AUTO_INIT      -- exit auto-initialize dma operation
constant 
        SET_TIME_CONSTANT = #40, -- set dsp sample rate (sb/pro)
        SET_SAMPLE_RATE = #41,   -- set dsp sample rate (sb16)
        SET_BLOCK_SIZE = #48,    -- set data block size
        SPEAKER_ON = #D1,        -- turn on dsp speaker
        SPEAKER_OFF = #D3,       -- turn off dsp speaker
        GET_DSP_VERSION = #E1

integer DMA_ADDRESS,
        DMA_COUNT,
        DMA_CLEAR,
        DMA_MODE,
        DMA_PAGE,
        DMA_MASK


atom DSPVer, dsp_isr, low_buffer, speakertable
atom dma_buffer, data_buffer
AUTO_INIT_8 = 0
sequence old_dsp_isr
constant dsp_subproc = allocate_proc({0,0,0,0})
constant ret_subproc = allocate_proc({#C3}) -- ret
poke4(dsp_subproc, ret_subproc)
constant cli = allocate_proc(           
   {#FA,                    --    0: cli  ; disable interrupts
    #C3})                   --    1: ret
constant sti = allocate_proc(
   {#FB,                    --    0: sti  ; enable interrupts
    #C3})                   --    1: ret


global integer block_size, num_blocks
block_size = 0  -- will choose later on based on playback_mode and playback_rate
num_blocks = 2


integer code_segment, data_segment

procedure get_segments()
    atom segment, save_segment
    -- read code and data segments (hardint.ex)
    segment = allocate_proc({0,0,0,0})

    save_segment = allocate_proc(
       {#50,                    -- push eax
        #0E,                    -- push cs or #1E push ds
        #58,                    -- pop eax
        #A3}&int_to_bytes(segment)&{-- mov [segment],eax (4)
        #58,                    -- pop eax
        #C3})                   -- ret

    call(save_segment) -- save code segment
    code_segment = peek(segment) + 256 * peek(segment+1)

    poke(save_segment+1, #1E)
    call(save_segment) -- save data segment
    data_segment = peek(segment) + 256 * peek(segment+1)

    free(segment)
    free(save_segment)
end procedure


procedure write_dsp(integer value)
    for i = 0 to 100 do
        if and_bits(in_byte(DSP_WRITE_STATUS), #80) = 0 then
            out_byte(DSP_WRITE_data, value)
            exit
        end if
    end for
end procedure

function read_dsp()
    for i = 0 to 100 do
        if and_bits(in_byte(DSP_data_AVAIL), #80) then
            return in_byte(DSP_READ_data)
        end if
    end for
    return -1
end function

global constant  -- values for set_volume()
    MASTER = #22,
    VOICE = #04,
    FM = #26,
    CD = #28,
    LINE = #2E,
    MIC = #0A

procedure write_mixer(integer index, integer value)
    if not pcspeaker then
        out_byte(base + 4, index)
        out_byte(base + 5, value)
    elsif index = MASTER then
        for i = 0 to 255 do
            poke(speakertable+i, floor(xor_bits(i,128)*value/#1100))
        end for
    end if
end procedure

procedure reset_dsp()
    integer junk

    -- resetting the DSP
    out_byte(DSP_RESET, 1)
    junk = in_byte(DSP_RESET)
    junk = in_byte(DSP_RESET)
    junk = in_byte(DSP_RESET)
    out_byte(DSP_RESET, 0)

    for i = 1 to 100 do
        if read_dsp() = #AA then
            return
        end if
    end for

    sound_error = "DSP failed to reset"
end procedure


global procedure close_sound()
    if sound_init = 0 then
        return
    end if
    if pcspeaker then
        call(cli)
        out_byte(#43, #36)
        out_byte(#40, #FC) --lo(65532)
        out_byte(#40, #FF) --hi(65532)
        set_vector(irq_int_vector, old_dsp_isr)
        out_byte(#61, and_bits(in_byte(#61), #FC))
        call(sti)
        free(speakertable)
    else
        write_dsp(SPEAKER_OFF)
        write_dsp(PAUSE_DMA)
        write_dsp(EXIT_AUTO_INIT)
        reset_dsp()
        set_vector(irq_int_vector, old_dsp_isr)
    end if
    free(dsp_isr)
    if pcspeaker then
        free(dma_buffer)
    else
        free_low(low_buffer)
    end if
    playback_mode = 0
end procedure

global procedure clear_dma_buffer()
    mem_set(dma_buffer, 128, block_size * num_blocks)
end procedure

--            dma channel:  0    1    2    3    4    5    6    7
constant dma_addresses = {#00, #02, #04, #06, #C0, #C4, #C8, #CC}
constant dma_counts =    {#01, #03, #05, #07, #C2, #C6, #CA, #CE}
constant dma_pages =     {#87, #83, #81, #82, #8F, #8B, #89, #8A}

global function init_sound(integer c, integer b, integer r)
    object blaster
    integer A, I, D, buffsize
    integer PIC_MASK, IRQ_STOP_MASK, IRQ_START_MASK

    if sound_init then
        close_sound()
    end if

    pcspeaker = 0
    
    printf(1, "Mode: %d  Bits: %d  Stereo/mono: %d\n", {r, b, c})
    
    playback_mode = c
    playback_bits = b
    playback_rate = r

    blaster = getenv("BLASTER") & ' '
    if atom(blaster) then
        puts(1, "BLASTER environment variable not found, using PC speaker.\n")
        sound_error = "BLASTER environment variable not found"
        if sound_debug_file then
            puts(sound_debug_file, sound_error & '\n')
        end if
        pcspeaker = 1
    else
        A = find('A', blaster)
        I = find('I', blaster)
        if playback_bits = 8 then
            D = find('D', blaster)
        elsif playback_bits = 16 then
            D = find('H', blaster)
        else
            D = 0
        end if
        if not (A and I) then
            sound_error = "Invalid BLASTER environment variable"
            if sound_debug_file then
                puts(sound_debug_file, sound_error & '\n')
            end if
            pcspeaker = 1
        end if
        if D = 0 then
            sound_error = sprintf("%d-bit playback rate not supported", {playback_bits})
            if sound_debug_file then
                puts(sound_debug_file, sound_error & '\n')
            end if
            pcspeaker = 1
        end if
    end if
    if pcspeaker = 0 then
        base = blaster[A+1]*#100 + blaster[A+2]*#10 + blaster[A+3] - #3330
        irq = blaster[I+1] - '0'
        if blaster[I+2] >= '0' and blaster[I+2] <= '9' then
            irq = 10*irq + blaster[I+2] - '0'
        end if
        dma = blaster[D+1] - '0'
    
        -- setup the dsp ports
        DSP_RESET = base + 6         -- dsp reset i/o port
        DSP_READ_data = base + #A    -- dsp read data i/o port
        DSP_WRITE_data = base + #C   -- dsp write data i/o port
        DSP_WRITE_STATUS = base + #C -- dsp write status i/o port
        DSP_data_AVAIL = base + #E   -- dsp read status i/o port
      
        -- setup some dsp commands
        PAUSE_DMA = #D0 + 5 * (playback_bits=16)      -- halt dma operation
        CONTINUE_DMA = #D4 + 2 * (playback_bits=16)   -- continue dma operation
        CONTINUE_AUTO_INIT = #45 + 2 * (playback_bits=16)  -- continue auto-initialize dma
        EXIT_AUTO_INIT = #DA - (playback_bits=16)          -- exit auto-initialize dma operation

        -- setup the dma ports
        DMA_ADDRESS = dma_addresses[dma+1]
        DMA_COUNT = dma_counts[dma+1]
        DMA_PAGE = dma_pages[dma+1]
        if dma < 4 then
            DMA_MASK = #A
            DMA_MODE = #B
            DMA_CLEAR = #C
        else
            DMA_MASK = #D4
            DMA_MODE = #D6
            DMA_CLEAR = #D8
        end if
    
        if irq < 8 then
            PIC_MASK = #21
            irq_int_vector = irq + 8
        else
            PIC_MASK = #A1
            irq_int_vector = #70 + irq - 8
        end if
        IRQ_STOP_MASK = power(2, and_bits(irq, 7))
        IRQ_START_MASK = not_bits(IRQ_STOP_MASK)
    
        reset_dsp()

        -- get dsp version number
        write_dsp(GET_DSP_VERSION)
        DSPVer = read_dsp()
        DSPVer = DSPVer + read_dsp() / 100
    
        printf(1, "Sound Blaster detected: A%x I%x D%x  (DSP version %1.2f).\n\n", {base, irq, dma, DSPVer})
        if DSPVer < 2 then
            sound_error = "Old SB card not supported (DSP version < 2.00)"
            if sound_debug_file then
                puts(sound_debug_file, sound_error & '\n')
            end if
            pcspeaker = 1
        elsif DSPVer < 4 then
            if playback_rate * playback_mode > 45454 then
                playback_rate = 45454 / playback_mode    -- sb pro limited to 44khz mono or 22khz stereo
            end if
            if sound_debug_file then
                printf(1, "Playback rate too high - lowered to %d\n", {playback_rate})
            end if
        end if
    end if

    if pcspeaker then
        playback_mode = MONO
        playback_rate = 10920
        block_size = 1024
        puts(1, "Using PC speaker. Mono, rate 10920, blocksize 1024.\n")
    end if

    -- allocate dma buffer and stuff
    if block_size = 0 then
         block_size = floor(playback_mode * playback_rate / 11025) * 512 + 512
    end if
    buffsize = block_size * num_blocks
    
    if pcspeaker then
        if sound_debug_file then
            puts(sound_debug_file, "Using PC speaker\n")
        end if
        dma_buffer = allocate(buffsize)
        if dma_buffer = 0 then
            sound_error = "could not allocate memory for dma buffer"
                puts(1, sound_error & '\n')
            return 1
        end if
    else
        low_buffer = allocate_low(2 * buffsize)
        if low_buffer = 0 then
            sound_error = "could not allocate low memory for dma buffer"
            puts(1, sound_error & '\n')
            return 1
        end if
        if and_bits(low_buffer,#FFFF0000) = and_bits(low_buffer+buffsize-1,#FFFF0000) then
            dma_buffer = low_buffer
        else
            dma_buffer = and_bits(low_buffer, #FFFF0000) + #10000
        end if
    end if
    
    clear_dma_buffer()
--    poke(dma_buffer, rand(repeat(256, buffsize)))
    get_segments()

    -- create interupt service routine
    if pcspeaker then
        speakertable = allocate_proc(repeat(0,256))
        data_buffer = allocate_proc(repeat(0,12))
        dsp_isr = allocate_proc(
   {#9C,                    --    0: pushf
    #1E,                    --    1: push ds
    #50,                    --    2: push eax
    #B8,#00,#00,#00,#00,    --    3: mov eax, data_segment (4)
    #50,                    --    8: push eax
    #1F,                    --    9: pop ds
    #A1,#00,#00,#00,#00,    --    A: mov eax, [bufaddress] (11)
    #21,#C0,                --    F: and eax, eax
    #74,#54,                --   11: jz notplaying
    #50,                    --   13: push eax
    #8A,#00,                --   14: mov al, [eax]
    #25,#FF,#00,#00,#00,    --   16: and eax, #FF
    #8A,#80,#00,#00,#00,#00,--   1B: mov al, [eax + speakertable] (29)
    #E6,#42,                --   21: out #42, al
    #58,                    --   23: pop eax
    #F7,#05,#00,#00,#00,#00,#01,#00,#00,#00,--   24: test dword ptr [countdown], 1 (38)
    #74,#37,                --   2E: jz notplaying
    #FF,#05,#00,#00,#00,#00,--   30: inc dword ptr [bufaddress] (50)
    #FF,#0D,#00,#00,#00,#00,--   36: dec dword ptr [bufcount] (56)
    #75,#29,                --   3C: jnz notplaying
    #C7,#05,#00,#00,#00,#00,#00,#00,#00,#00,--   3E: mov dword ptr [bufcount], dword block_size (64) (68)
    #40,                    --   48: inc eax
    #2D,#00,#00,#00,#00,    --   49: sub eax, dword block_size (74)
    #60,                    --   4E: pusha
    #FF,#15,#00,#00,#00,#00,--   4F: call near dword ptr [dsp_subproc] (81)
    #61,                    --   55: popa
    #3D,#00,#00,#00,#00,    --   56: cmp eax, dword lastbuffer (87)
    #75,#0A,                --   5B: jne notplaying
    #C7,#05,#00,#00,#00,#00,#00,#00,#00,#00,--   5D: mov dword ptr [bufaddress], dword buffer (95) (99)
    #58,                    --   67: notplaying: pop eax
    #FF,#0D,#00,#00,#00,#00,--   68: dec dword ptr [countdown] (106)
    #75,#13,                --   6E: jnz exit_int_8
    #C7,#05,#00,#00,#00,#00,#00,#00,#00,#00,--   70: mov dword ptr [countdown], dword newrate (114) (118)
    #1F,                    --   7A: pop ds
    #9D,                    --   7B: popf
    #EA,#00,#00,#00,#00,#00,#00,--   7C: old_int_8: db #EA 0 0 0 0 0 0 (124)
    #50,                    --   83: exit_int_8: push eax
    #B0,#20,                --   84: mov al, #20
    #E6,#20,                --   86: out #20, al
    #58,                    --   88: pop eax
    #1F,                    --   89: pop ds
    #9D,                    --   8A: popf
    #CF}                    --   8B: iret
    )
poke4(dsp_isr + 4, data_segment)
poke4(dsp_isr + 11, data_buffer) --bufaddress)
poke4(dsp_isr + 29, speakertable)
poke4(dsp_isr + 38, data_buffer+8) --countdown)
poke4(dsp_isr + 50, data_buffer) --bufaddress)
poke4(dsp_isr + 56, data_buffer+4) --bufcount)
poke4(dsp_isr + 64, data_buffer+4) --bufcount)
poke4(dsp_isr + 68, block_size)
poke4(dsp_isr + 74, block_size)
poke4(dsp_isr + 81, dsp_subproc)
poke4(dsp_isr + 87, dma_buffer + buffsize - block_size)
poke4(dsp_isr + 95, data_buffer) --bufaddress)
poke4(dsp_isr + 99, dma_buffer)
poke4(dsp_isr + 106, data_buffer+8) --countdown)
poke4(dsp_isr + 114, data_buffer+8) --countdown)
poke4(dsp_isr + 118, 1) --newrate)
--poke(dsp_isr + 124, old_int_8)

        irq_int_vector = 8
        old_dsp_isr = get_vector(irq_int_vector)
        poke4(dsp_isr+125, old_dsp_isr[2])
        poke(dsp_isr+129, and_bits(old_dsp_isr[1],#FF) & floor(old_dsp_isr[1] / 256))
        poke4(data_buffer, {
            0, -- dma_buffer
            0, -- bufcount
            1}) -- tickrate
            
        set_vector(irq_int_vector, {code_segment, dsp_isr})

        mem_set(speakertable, 0, 256)

    else
        data_buffer = allocate_proc({0})
        dsp_isr = allocate_proc(
           {#60,                    -- pusha
            #06,                    -- push es
            #1E,                    -- push ds
            #9C,                    -- pushf
            #68}&int_to_bytes(data_segment)&{ -- push dword data_seg
            #1F,                    -- pop ds
            #A0}&int_to_bytes(data_buffer)&{-- mov al, [data_buffer]
            #31,#DB,                -- xor ebx, ebx
            #88,#C3,                -- mov bl, al
            #FE,#C0,                -- inc al
            #3C,num_blocks,         -- cmp al, num_blocks
            #75,#02,                -- jne l2
            #30,#C0,                -- xor al, al
            #A2}&int_to_bytes(data_buffer)&{-- l2: mov [data_buffer], al

            #B8}&int_to_bytes(block_size)&{-- mov eax, block_size
            #F7,#E3,                -- mul ebx
            #05}&int_to_bytes(dma_buffer)&{-- add eax, dword dma_buffer
            #FB,                    -- sti
            #FF,#15}&int_to_bytes(dsp_subproc)&{-- call near dword ptr [dsp_subproc]
    
            #BA}&int_to_bytes(base+#E+(playback_bits=16))&{-- mov edx, port
            #EC,                    -- in al, dx
            #B0,#20,                -- mov al, #20
            #E6,#A0,                -- out #A0, al
            #E6,#20,                -- out #20, al
            #9D,                    -- popf
            #1F,                    -- push ds
            #07,                    -- push es
            #61,                    -- popa
            #CF})                   -- iret
    
        call(cli)
        -- install interrupt service routine
        out_byte(PIC_MASK, or_bits(in_byte(PIC_MASK), IRQ_STOP_MASK))
        old_dsp_isr = get_vector(irq_int_vector)
        set_vector(irq_int_vector, {code_segment, dsp_isr})
        out_byte(PIC_MASK, and_bits(in_byte(PIC_MASK), IRQ_START_MASK))
        call(sti)

    end if
    volume = #FF
    write_mixer(MASTER, volume)
    sound_init = 1
    puts(1, "Sound initialized OK.\n")
    return 0
end function

global procedure hook_dsp(atom handler)
    call(cli)
    if handler then
        poke4(dsp_subproc, handler)
    else
        poke4(dsp_subproc, ret_subproc)
    end if
    call(sti)
end procedure


global procedure set_playback_rate(integer rate)
    -- set playback rate
    if sound_init = 0 then
        return
    end if
    playback_rate = rate
    if pcspeaker then
        rate = floor(rate*2 / 18.2)
        call(cli)
        poke4(dsp_isr + 118, rate) --newrate)
        poke4(data_buffer+8, rate)
        out_byte(#43, #36)
        rate = floor(65532 / rate)
        out_byte(#40, and_bits(rate,#FF))
        rate = floor(rate / 256)
        out_byte(#40, and_bits(rate,#FF))

        out_byte(#43, #90)
        out_byte(#61, or_bits(in_byte(#61), 3))
--        out_byte(#42, #00)
        call(sti)
    elsif DSPVer < 4 then
        write_dsp(SET_TIME_CONSTANT)
        rate = playback_mode * rate
        if rate <= 22727 then
            write_dsp(256 - floor(1000000 / rate))
            AUTO_INIT_8 = #1C  -- normal 8-bit auto-initialize
        else
            if rate > 45454 then
                rate = 45454  -- sb pro limited to 44khz mono or 22khz stereo
                playback_rate = rate / playback_mode
                puts(1, "rate too high\n")
            end if
--            write_dsp(floor((65536 - floor(256000000 / rate)) / 256))
            write_dsp(floor((65536 - floor(256000000 / rate)) / 256))
            AUTO_INIT_8 = #90  -- high speed 8-bit auto-initialize
        end if
    else
        AUTO_INIT_8 = 0
        write_dsp(SET_SAMPLE_RATE)
        write_dsp(floor(playback_rate / #100))
        write_dsp(and_bits(playback_rate, #FF))
    end if
end procedure

integer paused

global procedure start_sound()
    integer buf_ofs, buf_len

    if sound_init = 0 then
        return
    end if

    paused = 0
    
    if pcspeaker then
        set_playback_rate(playback_rate)
        poke4(data_buffer, {
            dma_buffer, -- dma_buffer
            block_size}) -- bufcount
        return
    end if    

    poke(data_buffer, 0)  -- start on block 0

    reset_dsp()

    -- set up dma
    if playback_bits = 8 then
        buf_ofs = and_bits(dma_buffer, #FFFF)
        buf_len = and_bits(block_size * num_blocks, #FFFF) - 1
    else  -- playback_bits = 16
        buf_ofs = and_bits(floor(dma_buffer / 2), #FFFF)
        buf_len = and_bits(floor(block_size * num_blocks / 2), #FFFF) - 1
    end if
    out_byte(DMA_MASK, or_bits(dma, 4))
    out_byte(DMA_CLEAR, 0)
    out_byte(DMA_MODE, #58 + and_bits(dma, 3))
    out_byte(DMA_ADDRESS, and_bits(buf_ofs, #FF))
    out_byte(DMA_ADDRESS, floor(buf_ofs / #100))
    out_byte(DMA_COUNT, and_bits(buf_len, #FF))
    out_byte(DMA_COUNT, floor(buf_len / #100))
    out_byte(DMA_PAGE, floor(dma_buffer / #10000))
    out_byte(DMA_MASK, and_bits(dma, 3))

    set_playback_rate(playback_rate)
    
    write_dsp(SPEAKER_ON)

    if DSPVer < 4 then  -- sb/pro

        write_mixer(#E, #11 + 2*(playback_mode=STEREO))  -- set mono or stero playback
    
        write_dsp(SET_BLOCK_SIZE)  -- set block size
        write_dsp(and_bits(block_size, #FF))
        write_dsp(floor(block_size / #100))

        write_dsp(AUTO_INIT_8) -- 8-bit auto-initialize (normal/highspeed)

    else  -- sb16+
        
        write_dsp(#D6 - 2 * playback_bits)  -- #C6 (8-bit) or #B6 (16-bit)
        write_dsp((playback_mode=STEREO) * #20)
        if playback_bits = 8 then
            buf_len = block_size - 1
        else
            buf_len = floor(block_size / 2) - 1
        end if        
        write_dsp(and_bits(buf_len, #FF))
        write_dsp(floor(buf_len / #100))

    end if    
end procedure

global procedure pause_sound()
    paused = 1    
    if pcspeaker then
        poke4(data_buffer, {
            0, -- dma_buffer
            0}) -- bufcount
    elsif AUTO_INIT_8 = #90 then
        reset_dsp()
    else
        write_dsp(PAUSE_DMA)
    end if
end procedure

global procedure unpause_sound()
    paused = 0
    if pcspeaker then
        poke4(data_buffer, {
            dma_buffer, -- dma_buffer
            block_size}) -- bufcount
    elsif AUTO_INIT_8 = #90 then
        start_sound()
    else
        write_dsp(CONTINUE_DMA)
    end if
--    write_dsp(CONTINUE_AUTO_INIT)
end procedure



global procedure toggle_pause()
    if paused then
        unpause_sound()
    else
        pause_sound()
    end if
end procedure



global procedure set_volume(integer which, integer level)
    write_mixer(which, level)
end procedure

global procedure volume_up()
    if volume < #FF then
        volume = volume + #11
        set_volume(MASTER, volume)
    end if
end procedure

global procedure volume_down()
    if volume > 0 then
        volume = volume - #11
        set_volume(MASTER, volume)
    end if
end procedure

------------------------- end sound.e --------------------------------------

include wildcard.e -- for upper()

global constant LOAD_MOD_FAIL = -1, LOAD_MOD_SUCCESS = 0, LOAD_WAVE_FAIL = -1

sequence module_name, sample_names

atom mod_info, samples, patterns, channels, update_proc, max_channels
constant channel_size = 92, sample_size = 24
constant max_volume = 255

atom volume_table, sine_table, hz_table, jump_table
integer mod_loaded, modwave_init
mod_loaded = 0  modwave_init = 0

global function option(integer i, object o1, object o2)
    if i then return o1 else return o2 end if
end function

global procedure unload_mod()
    atom buf
    integer num_samples
    if not mod_loaded then
        return
    end if
    pause_sound()
    for i = 0 to peek(mod_info) - 1 do
        poke4(channels + i*channel_size + 12, 0)
    end for
    num_samples = peek(mod_info + 2)
    mem_set(mod_info, 0, 13)
    for i = 1 to num_samples do
        buf = peek4u(samples + i * sample_size)
        if buf then
            free(buf)
        end if
    end for
    free(patterns)
    free(samples)
    clear_dma_buffer()
    mod_loaded = 0
end procedure

constant max_amiga_note = 1700
global function load_mod(sequence file_name)
    integer fn, len, loopstart, looplen, int
    integer num_orders, num_samples, num_patterns, num_channels
    sequence signature, temp, orders
    atom buffer
    object result

    if not modwave_init then
        return LOAD_MOD_FAIL
    elsif mod_loaded then
        unload_mod()
    end if
    
    fn = fopen(file_name, "rb")
    
    if fn = -1 then
        return LOAD_MOD_FAIL
    end if

    int = match(".MOD", upper(file_name))
    if int then

        if sound_debug_file then puts(sound_debug_file, "loading mod ") end if
        num_samples = 31

        fseek(fn, 1080)
        -- get signature
        signature = freads(fn, 4)
        if compare(signature, "M.K.") = 0  
        or compare(signature, "FLT4") = 0 then
            num_channels = 4
        elsif compare(signature, "6CHN") = 0 then
            num_channels = 6
        elsif compare(signature, "8CHN") = 0 then
            num_channels = 8
        elsif compare(signature[3..4], "CH") = 0 then
            num_channels = (signature[1]-'0')*10 + (signature[2]-'0')
        else
            num_channels = 4
            num_samples = 15
            signature = "N.T."
        end if
        fseek(fn, 0)
        
        if num_channels > max_channels then
            close(fn)
            return LOAD_MOD_FAIL
        end if        

        -- get module name
        module_name = freads(fn, 20)
        while compare(module_name < ' ', repeat(0, 20)) do   -- get rid of 
            module_name = module_name + (module_name < ' ')  -- control chars
        end while

        if sound_debug_file then puts(sound_debug_file, "(" & signature & "),  sampleinfo, ") end if

        -- get sample info
        sample_names = repeat(repeat(0,22),num_samples)
        samples = allocate((num_samples+1) * sample_size)
        if samples = 0 then
            close(fn)
            return LOAD_MOD_FAIL
        end if
        lock_memory(samples, (num_samples+1) * sample_size)
        mem_set(samples, 0, (num_samples+1) * sample_size)
        for i = 1 to num_samples do
            -- sample name
            sample_names[i] = freads(fn, 22)
            while compare(sample_names[i] < ' ', repeat(0, 22)) do   -- get rid of 
                sample_names[i] = sample_names[i] + (sample_names[i] < ' ')  -- control chars
            end while
            
            temp = freads(fn, 8)
            -- sample length
            len = (temp[1] * #100 + temp[2]) * 2
            if len <= 2 then
                len = 0
            end if
            poke4(samples+i*sample_size, {0, len})
            -- fine tune
            poke4(samples+i*sample_size+16, hz_table + max_amiga_note*4*temp[3])
            -- volume
            int = temp[4]
            if int > 64 then int = 64 end if
            poke(samples+i*sample_size+20, int)
            
            -- loop start
            loopstart = (temp[5] * #100 + temp[6]) * 2
            -- loop length
            looplen = (temp[7] * #100 + temp[8]) * 2
            if looplen <= 2 then
                poke4(samples+i*sample_size+8, {0,0})
            else
                if loopstart + looplen > len then
                    looplen = len - loopstart
                end if
                poke4(samples+i*sample_size+8, {loopstart, looplen})
            end if
        end for

        if sound_debug_file then puts(sound_debug_file, "orders, ") end if
        -- get song length
        temp = freads(fn, 2)
        num_orders = temp[1]

        -- get pattern order and number of patterns
        orders = freads(fn, 128)
        num_patterns = 0
        for i = 1 to 128 do
            if orders[i] > num_patterns then
                num_patterns = orders[i]
            end if
        end for
        num_patterns = num_patterns + 1

        if num_samples != 15 then
            temp = freads(fn, 4)
        end if

        if sound_debug_file then puts(sound_debug_file, "patterns, ") end if
        len = num_channels * 8 * 64 * num_patterns
        patterns = allocate(len)
        if patterns = 0 then
            free(samples)
            close(fn)
            return LOAD_MOD_FAIL
        end if
        lock_memory(patterns, len)
        
        buffer = patterns
        temp = freads(fn, 4*num_patterns*64*num_channels)
        int = 0
        for i = 1 to num_patterns do
            for j = 1 to 64 do
                for c = 1 to num_channels do
                poke(buffer,
                    {and_bits(temp[int+1], #F0) + floor(temp[int+3] / 16), -- sample number
                    temp[int+2],  -- sample period (low byte)
                    and_bits(temp[int+1], #F),  -- sample period (high byte)
                    0,0,
                    and_bits(temp[int+3], #F),  -- effect number
                    temp[int+4],  -- effect parameters
                    0})       
                buffer = buffer + 8
                int = int + 4
                end for
            end for        
        end for
        if sound_debug_file then puts(sound_debug_file, "samples, ") end if
        for i = 1 to num_samples do
            len = peek4u(samples + i*sample_size + 4)
            if len then
                buffer = allocate(len)
                if buffer then
                    fread_mem(fn, buffer, len)
                    poke4(samples+i*sample_size, buffer)
                    if peek4u(samples+i*sample_size+12) then -- looplen
                        loopstart = peek4u(samples+i*sample_size+8)
                        poke4(samples+i*sample_size+8, buffer + loopstart)
                    end if
                else
                    temp = freads(fn, len)
                end if
            end if
        end for
        if sound_debug_file then puts(sound_debug_file, "done.\n") end if


--        poke(channels, repeat(0, (num_channels+1) * channel_size))
        mem_set(channels, 0, num_channels * channel_size)
        for i = 0 to num_channels-1 do
            if and_bits(i,3) = 0 or and_bits(i,3) = 3 or playback_mode = MONO then
                poke4(channels + i*channel_size + 52, {volume_table,0})
            else
                poke4(channels + i*channel_size + 52, {0,volume_table})
            end if
        end for

        call(cli)
        poke(mod_info, {num_channels, num_orders, num_samples, num_patterns,
        6,  -- speed
        -1, -- order
        -1, -- pattern
        1, -- tick
        250,0,0,0, -- tickcount
        63, -- row
        125, -- bpm
        0, -- loop order (always loops)
        250,0,0,0} -- ticks per second * 5
        &int_to_bytes(patterns)  -- pattern offset
        &int_to_bytes(patterns)  -- constant pattern offset
        &int_to_bytes(samples)   -- samples
        &orders) -- orders
        call(sti)

        mod_loaded = 1
        result = LOAD_MOD_SUCCESS

    end if

    fclose(fn)

    return result
end function


global procedure close_modwave()
    if modwave_init = 0 then
        return
    end if
    pause_sound()
    if mod_loaded then
        unload_mod()
    end if
    hook_dsp(0)
    close_sound()
    free(mod_info)
    free(volume_table)
    free(sine_table)
    free(update_proc)
    free(hz_table)
    free(channels)
    free(jump_table)
    modwave_init = 0
end procedure


global function init_modwave(integer mode, integer rate, integer max_chans)
    sequence amps, notes, sine
    
    puts(1, "Trying to initialize sound library.\n")
    
    if modwave_init then
        close_modwave()
    end if

    if init_sound(mode, 8, rate) then      -- only 8-bit playback
        puts(1, "init_sound() error\n")
        return 1
    end if

    amps = repeat(0, 256)
    for a = -128 to 127 do
        amps[and_bits(a+256,#FF)+1] = a
    end for
    volume_table = allocate(1024 * (max_volume+1))
    if volume_table = 0 then
        close_modwave()
        return 1
    end if
    lock_memory(volume_table, 1024 * (max_volume+1))
    for v = 0 to max_volume do
        poke4(volume_table + v*1024, floor(amps * v))
    end for

    notes = repeat(0, max_amiga_note)
    for note = 1 to max_amiga_note-1 do
        notes[note+1] = 
        7159090.5  -- NTSC
--        7093789.2  -- PAL
         / (note * 2)
    end for
    hz_table = allocate(16 * max_amiga_note * 4)
    if hz_table = 0 then
        free(volume_table)
        close_modwave()
        return 1
    end if
    lock_memory(hz_table, 16 * max_amiga_note * 4)
    for finetune = -8 to 7 do
        poke4(hz_table + max_amiga_note * 4 * and_bits(finetune+16,#F),
--          floor(0.5 + notes / power(1.0072382087, -finetune)))
          floor(0.5 + notes / power(1.00724641222, -finetune)))
    end for
    
    sine_table = allocate(64*16)
    if sine_table = 0 then
        free(hz_table)
        free(volume_table)
        close_modwave()
        return 1
    end if
    lock_memory(sine_table, 64*16)
    sine = repeat(0, 64)
    for j = 0 to 63 do
         sine[64-j] = 2 * sin(j*3.1415927/32)
    end for
    for i = 0 to 15 do
        poke(sine_table + i*64, floor(sine * i))
    end for


    jump_table = allocate(16 * 4)
    if jump_table = 0 then
        free(sine_table)
        free(hz_table)
        free(volume_table)
        close_modwave()
        return 1
    end if
    lock_memory(jump_table, 16 * 4)
    mod_info = allocate(272)
    if mod_info = 0 then
        free(jump_table)
        free(sine_table)
        free(hz_table)
        free(volume_table)
        close_modwave()
        return 1
    end if
    lock_memory(mod_info, 272)
    mem_set(mod_info, 0, 272)
    poke(mod_info + 7, 50)

    max_channels = max_chans
    channels = allocate(max_channels * channel_size)
    if channels = 0 then
        free(mod_info)
        free(jump_table)
        free(sine_table)
        free(hz_table)
        free(volume_table)
        close_modwave()
        return 1
    end if
    lock_memory(channels, max_channels * channel_size)
    mem_set(channels, 0, max_channels * channel_size)

    if sound_debug_file then puts(sound_debug_file, "compiling... ") end if
    update_proc = allocate_proc(

   {#FC,                    --    0: cld
    #1E,                    --    1: push ds
    #07,                    --    2: pop es
    #89,#C7,                --    3: mov edi, eax
    #B9,#00,#00,#00,#00,    --    5: mov ecx, block_size (6)
    #EB,#50,                --    A: jmp l1
    #8B,#46,#28,            --    C: reset_sample: mov eax, [(chan esi).loopstart]
    #89,#46,#0C,            --    F: mov [(chan esi).pos], eax
    #21,#C0,                --   12: and eax, eax
    #74,#19,                --   14: jz cancel_sample
    #8B,#46,#2C,            --   16: mov eax, [(chan esi).looplength]
    #89,#46,#10,            --   19: mov [(chan esi).length], eax
    #EB,#08,                --   1C: jmp inc_sample_count
    #FF,#46,#0C,            --   1E: inc_sample: inc dword ptr [(chan esi).pos]
    #FF,#4E,#10,            --   21: dec dword ptr [(chan esi).length]
    #74,#E6,                --   24: jz reset_sample
    #81,#46,#14,#00,#00,#00,#00,--   26: inc_sample_count: add dword ptr [(chan esi).count], dword playback_rate (41)
    #7E,#EF,                --   2D: jle inc_sample
    #EB,#6B,                --   2F: cancel_sample: jmp l3
    #81,#46,#08,#00,#00,#00,#00,--   31: tickcount_reset: add dword ptr [(mod esi).tickcount], dword playback_rate5 (52)
    #FE,#4E,#07,            --   38: dec byte ptr [(mod esi).tick]
    #74,#71,                --   3B: jz increment_row
    #51,                    --   3D: do_tick_effect: push ecx
    #57,                    --   3E: push edi
    #B9,#00,#00,#00,#00,    --   3F: mov ecx, max_channels (64)
    #BF,#00,#00,#00,#00,    --   44: mov edi, channels (69)
    #8B,#5F,#3C,            --   49: tick_effect: mov ebx, [(chan edi).effectproc]
    #21,#DB,                --   4C: and ebx, ebx
    #74,#02,                --   4E: jz end_tick_effect
    #FF,#E3,                --   50: jmp near ebx
    #83,#C7,#5C,            --   52: end_tick_effect: add edi, 92
    #49,                    --   55: dec ecx
    #75,#F1,                --   56: jnz tick_effect
    #5F,                    --   58: pop edi
    #59,                    --   59: pop ecx
    #EB,#0D,                --   5A: jmp end_tickcount
    #BE,#00,#00,#00,#00,    --   5C: l1: mov esi, mod_info (93)
    #8B,#46,#0F,            --   61: mov eax, [(mod esi).tickspersec]
    #29,#46,#08,            --   64: sub dword ptr [(mod esi).tickcount], eax
    #7E,#C8,                --   67: jle tickcount_reset
    #51,                    --   69: end_tickcount: push ecx
    #B9,#00,#00,#00,#00,    --   6A: mov ecx, max_channels (107)
    #BE,#00,#00,#00,#00,    --   6F: mov esi, channels (112)
    #BB,#00,#80,#00,#00,    --   74: mov ebx, #8000
    #89,#DA,                --   79: mov edx, ebx
    #8B,#46,#0C,            --   7B: l2: mov eax, [(chan esi).pos]
    #21,#C0,                --   7E: and eax, eax
    #74,#1A,                --   80: jz l3
    #0F,#B6,#00,            --   82: movzx eax, [eax]
    #C1,#E0,#02}&           --   85: shl eax, 2
    option(playback_mode = STEREO,{
    #50,                    --   88: push eax
    #03,#46,#1C,            --   89: add eax, dword ptr [(chan esi).volumeR]
    #03,#10,                --   8C: add edx, dword ptr [eax]
    #58},                   --   8E: pop eax
    {#90,#90,#90,#90,#90,#90,#90})&{
    #03,#46,#18,            --   8F: add eax, dword ptr [(chan esi).volumeL]
    #03,#18,                --   92: add ebx, dword ptr [eax]
    #8B,#46,#08,            --   94: mov eax, [(chan esi).hertz]
    #29,#46,#14,            --   97: sub dword ptr [(chan esi).count], eax
    #7E,#82,                --   9A: jle inc_sample
    #83,#C6,#5C,            --   9C: l3: add esi, 92
    #49,                    --   9F: dec ecx
    #75,#D9,                --   A0: jnz l2
    #88,#3F,                --   A2: mov [edi], bh
    #47,                    --   A4: inc edi
    #59}&                   --   A5: pop ecx
    option(playback_mode = STEREO,{
    #88,#37,                --   A6: mov [edi], dh
    #47,                    --   A8: inc edi
    #49},                   --   A9: dec ecx
    {#90,#90,#90,#90})&{
    #49,                    --   AA: dec ecx
    #75,#AF,                --   AB: jnz l1
    #C3,                    --   AD: ret
    #8A,#46,#04,            --   AE: increment_row: mov al, [(mod esi).speed]
    #88,#46,#07,            --   B1: mov [(mod esi).tick], al
    #FE,#46,#0C,            --   B4: inc byte ptr [(mod esi).row]
    #80,#7E,#0C,#40,        --   B7: cmp byte ptr [(mod esi).row], 64
    #7D,#0E,                --   BB: jge reset_pattern
    #0F,#B6,#06,            --   BD: movzx eax, [(mod esi).channels]
    #C1,#E0,#03,            --   C0: shl eax, 3
    #01,#46,#13,            --   C3: add dword ptr [(mod esi).patternofs], eax
    #8B,#46,#13,            --   C6: mov eax, [(mod esi).patternofs]
    #EB,#36,                --   C9: jmp do_pattern
    #80,#6E,#0C,#40,        --   CB: reset_pattern: sub byte ptr [(mod esi).row], 64
    #0F,#B6,#56,#0C,        --   CF: movzx edx, [(mod esi).row]
    #FE,#46,#05,            --   D3: inc byte ptr [(mod esi).order]
    #0F,#B6,#46,#05,        --   D6: movzx eax, [(mod esi).order]
    #3A,#46,#01,            --   DA: cmp al, [(mod esi).orders]
    #72,#08,                --   DD: jb orderloop
    #8A,#46,#0E,            --   DF: mov al, [(mod esi).orderloop]
    #88,#46,#05,            --   E2: mov [(mod esi).order], al
    #20,#C0,                --   E5: and al, al
    #8A,#44,#30,#1F,        --   E7: orderloop: mov al, [(mod esi).orderinfo + eax]
    #88,#46,#06,            --   EB: mov [(mod esi).pattern], al
    #0F,#B6,#1E,            --   EE: movzx ebx, [(mod esi).channels]
    #C1,#E3,#03,            --   F1: shl ebx, 3
    #F7,#E3,                --   F4: mul ebx
    #01,#D0,                --   F6: add eax, edx
    #C1,#E0,#06,            --   F8: shl eax, 6
    #03,#46,#17,            --   FB: add eax, [(mod esi).patternptr]
    #89,#46,#13,            --   FE: mov [(mod esi).patternofs], eax
    #51,                    --  101: do_pattern: push ecx
    #57,                    --  102: push edi
    #0F,#B6,#0E,            --  103: movzx ecx, [(mod esi).channels]
    #BF,#00,#00,#00,#00,    --  106: mov edi, channels (263)
    #0F,#B6,#18,            --  10B: l4: movzx ebx, [eax]
    #20,#DB,                --  10E: and bl,bl
    #75,#3C,                --  110: jnz set_sample
    #0F,#B6,#58,#05,        --  112: end_set_sample: movzx ebx, [eax+5]
    #88,#5F,#02,            --  116: mov [edi+2], bl
    #C7,#47,#3C,#00,#00,#00,#00,--  119: mov dword ptr [edi+60], 0
    #C1,#E3,#02,            --  120: shl ebx, 2
    #81,#C3,#00,#00,#00,#00,--  123: add ebx, dword jump_table (293)
    #FF,#23,                --  129: jmp near dword ptr [ebx]
    #8B,#58,#01,            --  12B: end_effect: mov ebx, [eax+1]
    #21,#DB,                --  12E: and ebx, ebx
    #75,#51,                --  130: jnz set_period
    #83,#C0,#08,            --  132: end_set_period: add eax, 8
    #83,#C7,#5C,            --  135: add edi, 92
    #E2,#D1,                --  138: loop l4
    #B9,#00,#00,#00,#00,    --  13A: mov ecx, max_channels (315)
    #2A,#0E,                --  13F: sub cl, [(mod esi).channels]
    #0F,#8F,#02,#FF,#FF,#FF,--  141: jg near tick_effect
    #5F,                    --  147: pop edi
    #59,                    --  148: pop ecx
    #E9,#1B,#FF,#FF,#FF,    --  149: jmp near end_tickcount
    #88,#1F,                --  14E: set_sample: mov [edi], bl
    #56,                    --  150: push esi
    #C1,#E3,#03,            --  151: shl ebx, 3
    #8B,#56,#1B,            --  154: mov edx, [(mod esi).sampleptr]
    #8D,#34,#5B,            --  157: lea esi, [ebx + ebx*2]
    #01,#D6,                --  15A: add esi, edx
    #83,#C7,#0C,            --  15C: add edi, 12
    #A5,                    --  15F: movsd
    #A5,                    --  160: movsd
    #83,#EE,#08,            --  161: sub esi, 8
    #83,#C7,#0C,            --  164: add edi, 12
    #A5,                    --  167: movsd
    #A5,                    --  168: movsd
    #A5,                    --  169: movsd
    #A5,                    --  16A: movsd
    #A5,                    --  16B: movsd
    #83,#EF,#34,            --  16C: sub edi, 52
    #C7,#47,#14,#00,#00,#00,#00,--  16F: mov dword ptr [(chan edi).count], playback_rate (370)
    #0F,#B6,#16,            --  176: movzx edx, [esi]
    #BB,#00,#00,#00,#00,    --  179: mov ebx, volume_proc (378)
    #FF,#D3,                --  17E: call near ebx
    #5E,                    --  180: pop esi
    #EB,#8F,                --  181: jmp end_set_sample
    #89,#5F,#04,            --  183: set_period: mov [(chan edi).period], ebx
    #C1,#E3,#02,            --  186: shl ebx, 2
    #03,#5F,#30,            --  189: add ebx, dword ptr [(chan edi).hertztable]
    #8B,#1B,                --  18C: mov ebx, [ebx]
    #89,#5F,#08,            --  18E: mov [(chan edi).hertz], ebx
    #EB,#9F,                --  191: jmp end_set_period
    #80,#38,#00,            --  193: cmp byte ptr [eax], 0
    #75,#9A,                --  196: jnz end_set_period
    #80,#78,#05,#00,        --  198: cmp byte ptr [eax+5], 0
    #75,#94,                --  19C: jnz end_set_period
    #8A,#1F,                --  19E: mov bl, [(chan edi).sample]
    #EB,#AC,                --  1A0: jmp set_sample
    #31,#DB,                --  1A2: set_offset: xor ebx, ebx
    #8A,#78,#06,            --  1A4: mov bh, [eax+6]
    #8B,#57,#24,            --  1A7: mov edx, [(chan edi).samplength]
    #29,#DA,                --  1AA: sub edx, ebx
    #03,#5F,#20,            --  1AC: add ebx, [(chan edi).sampstart]
    #89,#5F,#0C,            --  1AF: mov [(chan edi).pos], ebx
    #89,#57,#10,            --  1B2: mov [(chan edi).length], edx
    #E9,#71,#FF,#FF,#FF,    --  1B5: jmp near end_effect
    #83,#FA,#00,            --  1BA: do_volume: cmp edx, 0
    #7D,#02,                --  1BD: jge vol_too_lo
    #31,#D2,                --  1BF: xor edx, edx
    #83,#FA,#40,            --  1C1: vol_too_lo: cmp edx, 64
    #7E,#05,                --  1C4: jle vol_too_hi
    #BA,#40,#00,#00,#00,    --  1C6: mov edx, 64
    #88,#57,#01,            --  1CB: vol_too_hi: mov [(chan edi).volume], dl
    #C1,#E2,#0A,            --  1CE: shl edx, 10
    #8B,#5F,#34,            --  1D1: mov ebx, dword ptr [(chan edi).volumeTL]
    #21,#DB,                --  1D4: and ebx, ebx
    #74,#12,                --  1D6: jz silence_left
    #01,#D3,                --  1D8: add ebx, edx
    #89,#5F,#18,            --  1DA: end_silence_left: mov [(chan edi).volumeL], ebx
    #8B,#5F,#38,            --  1DD: mov ebx, dword ptr [(chan edi).volumeTR]
    #21,#DB,                --  1E0: and ebx, ebx
    #74,#0D,                --  1E2: jz silence_right
    #01,#D3,                --  1E4: add ebx, edx
    #89,#5F,#1C,            --  1E6: end_silence_right: mov [(chan edi).volumeR], ebx
    #C3,                    --  1E9: ret
    #BB,#00,#00,#00,#00,    --  1EA: silence_left: mov ebx, volume_table (491)
    #EB,#E9,                --  1EF: jmp end_silence_left
    #BB,#00,#00,#00,#00,    --  1F1: silence_right: mov ebx, volume_table (498)
    #EB,#EE,                --  1F6: jmp end_silence_right
    #0F,#B6,#50,#06,        --  1F8: set_volume: movzx edx, [eax+6]
    #BB,#00,#00,#00,#00,    --  1FC: mov ebx, volume_proc (509)
    #FF,#D3,                --  201: call near ebx
    #E9,#23,#FF,#FF,#FF,    --  203: jmp near end_effect
    #8A,#78,#06,            --  208: jump_to_pattern: mov bh, [eax+6]
    #88,#7E,#05,            --  20B: mov [(mod esi).order], bh
    #C6,#46,#0C,#3F,        --  20E: mov byte ptr [(mod esi).row], 63
    #E9,#14,#FF,#FF,#FF,    --  212: jmp near end_effect
    #8A,#78,#06,            --  217: pattern_break: mov bh, [eax+6]
    #80,#C7,#40,            --  21A: add bh, 64
    #88,#7E,#0C,            --  21D: mov byte ptr [(mod esi).row], bh
    #E9,#06,#FF,#FF,#FF,    --  220: jmp near end_effect
    #0F,#B6,#58,#06,        --  225: song_speed: movzx ebx, [eax+6]
    #83,#FB,#00,            --  229: cmp ebx, 0
    #0F,#84,#F9,#FE,#FF,#FF,--  22C: je near end_effect
    #80,#FB,#20,            --  232: cmp bl, #20
    #76,#0D,                --  235: jbe setspeed
    #88,#5E,#0D,            --  237: mov [(mod esi).bpm], bl
    #D1,#E3,                --  23A: shl ebx, 1
    #89,#5E,#0F,            --  23C: mov [(mod esi).tickspersec], ebx
    #E9,#E7,#FE,#FF,#FF,    --  23F: jmp near end_effect
    #88,#5E,#04,            --  244: setspeed: mov [(mod esi).speed], bl
    #88,#5E,#07,            --  247: mov [(mod esi).tick], bl
    #E9,#DC,#FE,#FF,#FF,    --  24A: jmp near end_effect
    #C7,#47,#3C,#00,#00,#00,#00,--  24F: setup_porta_up: mov dword ptr [(chan edi).effectproc], dword porta_up_proc (594)
    #8A,#58,#06,            --  256: mov bl, [eax+6]
    #20,#DB,                --  259: and bl, bl
    #0F,#84,#CA,#FE,#FF,#FF,--  25B: jz near end_effect
    #88,#5F,#40,            --  261: mov [(chan edi).portaup], bl
    #E9,#C2,#FE,#FF,#FF,    --  264: jmp near end_effect
    #C7,#47,#3C,#00,#00,#00,#00,--  269: setup_porta_down: mov dword ptr [(chan edi).effectproc], dword porta_down_proc (620)
    #8A,#58,#06,            --  270: mov bl, [eax+6]
    #20,#DB,                --  273: and bl, bl
    #0F,#84,#B0,#FE,#FF,#FF,--  275: jz near end_effect
    #88,#5F,#41,            --  27B: mov [(chan edi).portadown], bl
    #E9,#A8,#FE,#FF,#FF,    --  27E: jmp near end_effect
    #C7,#47,#3C,#00,#00,#00,#00,--  283: setup_porta_note: mov dword ptr [(chan edi).effectproc], dword porta_note_proc (646)
    #8A,#58,#06,            --  28A: mov bl, [eax+6]
    #20,#DB,                --  28D: and bl, bl
    #74,#03,                --  28F: jz skip_porta_note
    #88,#5F,#42,            --  291: mov [(chan edi).portanote], bl
    #8B,#58,#01,            --  294: skip_porta_note: mov ebx, [eax+1]
    #21,#DB,                --  297: and ebx, ebx
    #74,#03,                --  299: jz skip_porta_period
    #89,#5F,#4E,            --  29B: mov [(chan edi).targetnote], ebx
    #E9,#8F,#FE,#FF,#FF,    --  29E: skip_porta_period: jmp near end_set_period
    #C7,#47,#3C,#00,#00,#00,#00,--  2A3: setup_vibrato: mov dword ptr [(chan edi).effectproc], dword vibrato_proc (678)
    #0F,#B6,#50,#06,        --  2AA: movzx edx, [eax+6]
    #20,#D2,                --  2AE: and dl, dl
    #0F,#84,#75,#FE,#FF,#FF,--  2B0: jz near end_effect
    #89,#D3,                --  2B6: mov ebx, edx
    #80,#E2,#0F,            --  2B8: and dl, #F
    #C1,#E2,#06,            --  2BB: shl edx, 6
    #81,#C2,#00,#00,#00,#00,--  2BE: add edx, sine_table (704)
    #C0,#EB,#04,            --  2C4: shr bl, 4
    #C6,#47,#48,#3F,        --  2C7: mov byte ptr [(chan edi).sinepos], 63
    #88,#5F,#49,            --  2CB: mov byte ptr [(chan edi).sinespeed], bl
    #89,#57,#4A,            --  2CE: mov dword ptr [(chan edi).sinetable], edx
    #E9,#55,#FE,#FF,#FF,    --  2D1: jmp near end_effect
    #C7,#47,#3C,#00,#00,#00,#00,--  2D6: setup_volume_slide_porta: mov dword ptr [(chan edi).effectproc], dword volume_slide_porta_proc (729)
    #EB,#10,                --  2DD: jmp in_volume_slide
    #C7,#47,#3C,#00,#00,#00,#00,--  2DF: setup_volume_slide_vibrato: mov dword ptr [(chan edi).effectproc], dword volume_slide_vibrato_proc (738)
    #EB,#07,                --  2E6: jmp in_volume_slide
    #C7,#47,#3C,#00,#00,#00,#00,--  2E8: setup_volume_slide: mov dword ptr [(chan edi).effectproc], dword volume_slide_proc (747)
    #8A,#58,#06,            --  2EF: in_volume_slide: mov bl, [eax+6]
    #F6,#C3,#0F,            --  2F2: test bl, #F
    #75,#05,                --  2F5: jnz other_volume
    #C0,#EB,#04,            --  2F7: shr bl, 4
    #F6,#DB,                --  2FA: neg bl
    #F6,#DB,                --  2FC: other_volume: neg bl
    #88,#5F,#43,            --  2FE: mov [(chan edi).volslide] , bl
    #E9,#25,#FE,#FF,#FF,    --  301: jmp near end_effect
    #0F,#B6,#57,#01,        --  306: volume_slide_porta: movzx edx, [(chan edi).volume]
    #0F,#BE,#5F,#43,        --  30A: movsx ebx, [(chan edi).volslide]
    #01,#DA,                --  30E: add edx, ebx
    #BB,#00,#00,#00,#00,    --  310: mov ebx, volume_proc (785)
    #FF,#D3,                --  315: call near ebx
    #8B,#57,#04,            --  317: porta_to_note: mov edx, [(chan edi).period]
    #0F,#B6,#5F,#42,        --  31A: movzx ebx, [(chan edi).portanote]
    #8B,#6F,#4E,            --  31E: mov ebp, dword ptr [(chan edi).targetnote]
    #39,#EA,                --  321: cmp edx, ebp
    #7C,#11,                --  323: jl add_to_note
    #29,#DA,                --  325: sub edx, ebx
    #39,#EA,                --  327: cmp edx, ebp
    #7F,#25,                --  329: jg porta_set_note
    #89,#EA,                --  32B: mov edx, ebp
    #C7,#47,#3C,#00,#00,#00,#00,--  32D: mov dword ptr [(chan edi).effectproc], 0
    #EB,#1A,                --  334: jmp porta_set_note
    #01,#DA,                --  336: add_to_note: add edx, ebx
    #39,#EA,                --  338: cmp edx, ebp
    #7C,#14,                --  33A: jl porta_set_note
    #89,#EA,                --  33C: mov edx, ebp
    #C7,#47,#3C,#00,#00,#00,#00,--  33E: mov dword ptr [(chan edi).effectproc], 0
    #EB,#09,                --  345: jmp porta_set_note
    #0F,#BE,#5F,#40,        --  347: porta_up: movsx ebx, [(chan edi).portaup]
    #8B,#57,#04,            --  34B: mov edx, [(chan edi).period]
    #29,#DA,                --  34E: sub edx, ebx
    #83,#FA,#71,            --  350: porta_set_note: cmp edx, 113
    #7F,#05,                --  353: jg not_too_low
    #BA,#71,#00,#00,#00,    --  355: mov edx, 113
    #81,#FA,#58,#03,#00,#00,--  35A: not_too_low: cmp edx, 856
    #7C,#05,                --  360: jl not_too_high
    #BA,#58,#03,#00,#00,    --  362: mov edx, 856
    #89,#57,#04,            --  367: not_too_high: mov [(chan edi).period], edx
    #C1,#E2,#02,            --  36A: porta_set_hertz: shl edx, 2
    #03,#57,#30,            --  36D: add edx, dword ptr [(chan edi).hertztable]
    #8B,#1A,                --  370: mov ebx, dword ptr [edx]
    #89,#5F,#08,            --  372: mov dword ptr [(chan edi).hertz], ebx
    #E9,#D8,#FC,#FF,#FF,    --  375: jmp near end_tick_effect
    #0F,#B6,#5F,#41,        --  37A: porta_down: movzx ebx, [(chan edi).portadown]
    #8B,#57,#04,            --  37E: mov edx, [(chan edi).period]
    #01,#DA,                --  381: add edx, ebx
    #EB,#CB,                --  383: jmp porta_set_note
    #0F,#B6,#57,#01,        --  385: volume_slide_vibrato: movzx edx, [(chan edi).volume]
    #0F,#BE,#5F,#43,        --  389: movsx ebx, [(chan edi).volslide]
    #01,#DA,                --  38D: add edx, ebx
    #BB,#00,#00,#00,#00,    --  38F: mov ebx, volume_proc (912)
    #FF,#D3,                --  394: call near ebx
    #0F,#B6,#5F,#48,        --  396: vibrato: movzx ebx, [(chan edi).sinepos]
    #03,#5F,#4A,            --  39A: add ebx, [(chan edi).sinetable]
    #8A,#57,#49,            --  39D: mov dl, [(chan edi).sinespeed]
    #0F,#BE,#1B,            --  3A0: movsx ebx, [ebx]
    #28,#57,#48,            --  3A3: sub byte ptr [(chan edi).sinepos], dl
    #7C,#07,                --  3A6: jl reset_sine
    #8B,#57,#04,            --  3A8: back_into_vibrato: mov edx, [(chan edi).period]
    #01,#DA,                --  3AB: add edx, ebx
    #EB,#BB,                --  3AD: jmp porta_set_hertz
    #80,#47,#48,#40,        --  3AF: reset_sine: add byte ptr [(chan edi).sinepos], 64
    #EB,#F3,                --  3B3: jmp back_into_vibrato
    #0F,#B6,#57,#01,        --  3B5: volume_slide: movzx edx, [(chan edi).volume]
    #0F,#BE,#5F,#43,        --  3B9: movsx ebx, [(chan edi).volslide]
    #01,#DA,                --  3BD: add edx, ebx
    #BB,#00,#00,#00,#00,    --  3BF: mov ebx, volume_proc (960)
    #FF,#D3,                --  3C4: call near ebx
    #E9,#87,#FC,#FF,#FF,    --  3C6: jmp near end_tick_effect
    #0F,#B6,#58,#06,        --  3CB: misc_effect: movzx ebx, [eax+6]
    #88,#DA,                --  3CF: mov dl, bl
    #80,#E3,#0F,            --  3D1: and bl, #F
    #80,#E2,#F0,            --  3D4: and dl, #F0
    #80,#FA,#10,            --  3D7: cmp dl, #10
    #74,#14,                --  3DA: je fineslide_up
    #80,#FA,#20,            --  3DC: cmp dl, #20
    #74,#48,                --  3DF: je fineslide_down
    #80,#FA,#A0,            --  3E1: cmp dl, #A0
    #74,#54,                --  3E4: je finevolslide_up
    #80,#FA,#B0,            --  3E6: cmp dl, #B0
    #74,#6B,                --  3E9: je finevolslide_down
    #E9,#3B,#FD,#FF,#FF,    --  3EB: jmp near end_effect
    #8B,#57,#04,            --  3F0: fineslide_up: mov edx, [(chan edi).period]
    #21,#DB,                --  3F3: and ebx, ebx
    #75,#03,                --  3F5: jnz fineslide_up_ok
    #8A,#5F,#44,            --  3F7: mov bl, [(chan edi).fineslideup]
    #88,#5F,#44,            --  3FA: fineslide_up_ok: mov [(chan edi).fineslideup], bl
    #29,#DA,                --  3FD: sub edx, ebx
    #83,#FA,#71,            --  3FF: fineslide_set_note: cmp edx, 113
    #7F,#05,                --  402: jg fs_not_too_low
    #BA,#71,#00,#00,#00,    --  404: mov edx, 113
    #81,#FA,#58,#03,#00,#00,--  409: fs_not_too_low: cmp edx, 856
    #7C,#05,                --  40F: jl fs_not_too_high
    #BA,#58,#03,#00,#00,    --  411: mov edx, 856
    #89,#57,#04,            --  416: fs_not_too_high: mov [(chan edi).period], edx
    #C1,#E2,#02,            --  419: fineslide_set_hertz: shl edx, 2
    #03,#57,#30,            --  41C: add edx, dword ptr [(chan edi).hertztable]
    #8B,#1A,                --  41F: mov ebx, dword ptr [edx]
    #89,#5F,#08,            --  421: mov dword ptr [(chan edi).hertz], ebx
    #E9,#02,#FD,#FF,#FF,    --  424: jmp near end_effect
    #21,#DB,                --  429: fineslide_down: and ebx, ebx
    #75,#03,                --  42B: jnz fineslide_dn_ok
    #8A,#5F,#45,            --  42D: mov bl, [(chan edi).fineslidedn]
    #88,#5F,#45,            --  430: fineslide_dn_ok: mov [(chan edi).fineslidedn], bl
    #8B,#57,#04,            --  433: mov edx, [(chan edi).period]
    #29,#DA,                --  436: sub edx, ebx
    #EB,#C5,                --  438: jmp fineslide_set_note
    #21,#DB,                --  43A: finevolslide_up: and ebx, ebx
    #75,#03,                --  43C: jnz finevolslide_up_ok
    #8A,#5F,#46,            --  43E: mov bl, [(chan edi).volslideup]
    #88,#5F,#46,            --  441: finevolslide_up_ok: mov [(chan edi).volslideup], bl
    #0F,#B6,#57,#01,        --  444: movzx edx, [(chan edi).volume]
    #29,#DA,                --  448: sub edx, ebx
    #BB,#00,#00,#00,#00,    --  44A: mov ebx, volume_proc (1099)
    #FF,#D3,                --  44F: call near ebx
    #E9,#D5,#FC,#FF,#FF,    --  451: jmp near end_effect
    #21,#DB,                --  456: finevolslide_down: and ebx, ebx
    #75,#03,                --  458: jnz finevolslide_dn_ok
    #8A,#5F,#47,            --  45A: mov bl, [(chan edi).volslidedn]
    #88,#5F,#47,            --  45D: finevolslide_dn_ok: mov [(chan edi).volslidedn], bl
    #0F,#B6,#57,#01,        --  460: movzx edx, [(chan edi).volume]
    #29,#DA,                --  464: sub edx, ebx
    #BB,#00,#00,#00,#00,    --  466: mov ebx, volume_proc (1127)
    #FF,#D3,                --  46B: call near ebx
    #E9,#B9,#FC,#FF,#FF})   --  46D: jmp near end_effect

    poke4(update_proc + 6, block_size)
    poke4(update_proc + 41, playback_rate)
    poke4(update_proc + 52, playback_rate * 5)
    poke4(update_proc + 64, max_channels)
    poke4(update_proc + 69, channels)
    poke4(update_proc + 93, mod_info)
    poke4(update_proc + 107, max_channels)
    poke4(update_proc + 112, channels)
    poke4(update_proc + 263, channels)
    poke4(update_proc + 293, jump_table)
    poke4(update_proc + 315, max_channels)
    poke4(update_proc + 370, playback_rate)
    poke4(update_proc + 378, update_proc + 442) -- do_volume
    poke4(update_proc + 491, volume_table)
    poke4(update_proc + 498, volume_table)
    poke4(update_proc + 509, update_proc + 442) -- do_volume
    poke4(update_proc + 594, update_proc + 839) -- porta_up
    poke4(update_proc + 620, update_proc + 890) -- porta_down
    poke4(update_proc + 646, update_proc + 791) -- porta_to_note
    poke4(update_proc + 678, update_proc + 918) -- vibrato
    poke4(update_proc + 704, sine_table)
    poke4(update_proc + 729, update_proc + 774) -- volume_slide_porta
    poke4(update_proc + 738, update_proc + 901) -- volume_side_vibrato
    poke4(update_proc + 747, update_proc + 949) -- volume_slide
    poke4(update_proc + 785, update_proc + 442) -- do_volume
    poke4(update_proc + 912, update_proc + 442) -- do_volume
    poke4(update_proc + 960, update_proc + 442) -- do_volume
    poke4(update_proc + 1099, update_proc + 442) -- do_volume
    poke4(update_proc + 1127, update_proc + 442) -- do_volume

    poke4(jump_table, update_proc + {299,591,617,643,675,726,735,299,299,418,744,520,504,535,971,549})
    
    if sound_debug_file then printf(sound_debug_file, " (#%x) done.\n", {update_proc}) end if
    
    hook_dsp(update_proc)
    start_sound()

    modwave_init = 1
    return 0
end function


constant 
    effect_names = {"Porta up     ", "Porta down   ", "Porta to note", 
    "Vibrato      ", "Porta+VolSlid", "Vibrato+VSlid", "Tremolo      ", 
    "Pan          ", "Sample Offset", "Volume Slide ", "Pattern Jump ", 
    "Set Volume   ", "Pattern Break", "Misc. Effect ", "Set Speed    ",
    "             "}

global procedure track(integer row)
    integer sample, volume, l, effect
    sequence slider
    position(row,1)
    if mod_loaded then
    puts(1, module_name)
    end if
    printf(1, "  track(%3d/%3d) pattern(%2d/%2d) row(%2d) speed(%2d@%3dbpm) \n", 
    {peek(mod_info+5)+1, peek(mod_info+1), peek(mod_info+6)+1, peek(mod_info+3), peek(mod_info+12),
    peek(mod_info+4),peek(mod_info+13)})
    for i = 0 to peek(mod_info)-1 do
        sample = peek(channels+i*channel_size)
        printf(1, "%d ", {i})
        if sample then
            puts(1, sample_names[sample] & ' ')
        else
            puts(1, repeat(32, 23))
        end if
        slider = repeat('-', 40) & ' '
        l = floor(peek4u(channels+i*channel_size+8) / 750)
        if l > 40 then
            l = 40
        elsif l < 1 then
            l = 1
        end if
        volume = peek(channels+i*channel_size+1)
        if volume < 2 then
            slider[l] = '|'
        elsif volume < 17 then
            slider[l] = 176
        elsif volume < 33 then
            slider[l] = 177
        elsif volume < 49 then
            slider[l] = 178
        else
            slider[l] = 219
        end if
        effect = peek(channels+i*channel_size+2)
        if effect > 0 and effect < 16 then
            puts(1, slider&effect_names[effect] & "\n")
        else
            puts(1, slider&"             \n")
        end if
    end for
--    for i = 0 to 7 do
--        printf(1, "%d %7x %7x %7x %7x %7x %7x %7x %7x\n",
--            i&peek4u({channels + i*channel_size, 8}))
--    end for

end procedure

global function get_mod_info()
-- returns the following sequence
-- {current track, total tracks,
--  current pattern, total patterns,
--  current row,
--  current speed, current bpm (beats per minute),
--  {
--   {sample name, frequency, volume, effect name}
--     ...  for each track
--  }
-- }
    sequence result, tracks
    integer sample, effect
    result = {peek(mod_info+5)+1, peek(mod_info+1), peek(mod_info+6)+1, peek(mod_info+3), peek(mod_info+12),
        peek(mod_info+4),peek(mod_info+13)}
    tracks = repeat(0, peek(mod_info))
    for i = 0 to length(tracks) - 1 do
        sample = peek(channels+i*channel_size)
        if sample then
            effect = peek(channels+i*channel_size+2)
            if effect <= 0 or effect > 16 then
                effect = 16
            end if
            tracks[i+1] = {
                sample_names[sample],
                peek4u(channels+i*channel_size+8),
                peek(channels+i*channel_size+1),
                effect_names[effect]}
        else
            tracks[i+1] = {repeat(' ',23),0,0,0}
        end if
    end for
    return append(result, tracks)
end function

global procedure next_track()
    if mod_loaded then
        poke(mod_info + 7, {1, 50,0,0,0, 63})
    end if
end procedure

global procedure select_track(integer track_number) -- 1 based indexing
    if mod_loaded
    and track_number > 0
    and track_number <= peek(mod_info + 1) then
        poke(mod_info + 7, {1, 50,0,0,0, 63})
        poke(mod_info + 5, track_number - 2)
    end if
end procedure

global procedure list_samples(integer row)
    if mod_loaded then
    for i = 0 to 10 do
        position(row+i, 1)
        puts(1, sample_names[i+1])
        if i+12 <= length(sample_names) then
            position(row+i, 26)
            puts(1, sample_names[i+12])
        end if
        if i+23 <= length(sample_names) then
            position(row+i, 51)
            puts(1, sample_names[i+23])
        end if
    end for
    end if
end procedure


global function load_wave(sequence file_name)
    integer fn, len, int
    sequence temp, tag
    atom buffer, convert_proc
    object result

    fn = fopen(file_name, "rb")
    
    result = LOAD_WAVE_FAIL
    if fn != -1 then
    
-- structure of wave file header record  (courtesy Jacques Deschenes)
-- tagged record type file. tags are 4 characters long.
--     data              offset       data nature
--     ------------------------------------------
--     tag               [1..4]       "RIFF" file Id tag
--     integer           [5..8]       file length excluding this record
--     tag               [9..12]      "WAVE"  confirm it's a wave file
--     tag               [13..16]     "fmt " announce format record
--     integer           [17..20]     length of format record
--     word              [21..22]     format tag
--     word              [23..24]     number of channels  (mono=1,stereo=2)
--     integer           [25..28]     samples per seconds
--     integer           [29..32]     average bytes per second  
--     word              [33..34]     block align
--     word              [35..36]     bits per sample
--     tag               [37..40]     "data" or "fact"  record
--     integer           [41..44]     length of that record, if data it means
--                                    length of sound sample, if fact jump
--                                     over it and go to data record.   
--
        temp = freads(fn, 36)
        if sound_debug_file then puts(sound_debug_file, "loading wav: "&temp[1..4]) end if
        if compare(temp[1..4], "RIFF") = 0 then
            if compare(temp[9..12], "WAVE") = 0 then
                int = bytes_to_int(temp[17..20])
                if int > #10 then
                    tag = freads(fn, int - #10)
                end if
                tag = freads(fn, 8)
                while compare(tag[1..4], "data") do
                    fseek_rel(fn, bytes_to_int(tag[5..8]))
                    tag = freads(fn, 8)
                end while
                result = repeat(0, 3)
                result[2] = bytes_to_int(tag[5..8])  -- length
                if sound_debug_file then 
                printf(sound_debug_file, " %d ", {result[2]})
                if temp[23] = 1 then
                    puts(sound_debug_file, "MONO")
                else
                    puts(sound_debug_file, "STEREO")
                end if
                printf(sound_debug_file, " %d-bit... ", {temp[35]})
                end if
                result[1] = allocate(result[2])
                if result[1] = 0 then
                    close(fn)
                    return LOAD_WAVE_FAIL
                end if
                fread_mem(fn, result[1], result[2])
                result[3] = bytes_to_int(temp[25..28])  -- hertz
            elsif sound_debug_file then 
                puts(sound_debug_file, "  missing WAVE tag! ")
            end if
        elsif sound_debug_file then 
            puts(sound_debug_file, "  missing RIFF tag! ")
        end if

        if sequence(result) then
        if temp[35] = 8 and temp[23] = 1 then  -- MONO 8-bit
            lock_memory(result[1], result[2])
            convert_proc = allocate_proc(
   {#60,                    -- pusha
    #BE}&int_to_bytes(result[1])&{    -- mov esi, 1
    #B9}&int_to_bytes(result[2])&{    -- mov ecx, 2
    #80,#36,#80,            -- label1: xor byte ptr [esi], #80
    #46,                    -- inc esi
    #49,                    -- dec ecx
    #75,#F9,                -- jnz label1
    #61,                    -- popa
    #C3})                   -- ret
            call(convert_proc)
            free(convert_proc)
        elsif temp[35] = 16 and temp[23] = 1 then   -- MONO 16-bit
            buffer = result[1]
            result[2] = floor(result[2] / 2)
            result[1] = allocate(result[2])
            if result[1] = 0 then
                free(buffer)
                close(fn)
                return LOAD_WAVE_FAIL
            end if
            lock_memory(result[1], result[2])
            convert_proc = allocate_proc(
   {#60,                    -- pusha
    #BE}&int_to_bytes(buffer)&{    -- mov esi, 5
    #BF}&int_to_bytes(result[1])&{    -- mov edi, 1
    #B9}&int_to_bytes(result[2])&{ -- mov ecx, 2
    #46,                    -- label1: inc esi
    #8A,#06,                -- mov al, [esi]
    #46,                    -- inc esi
    #88,#07,                -- mov [edi], al
    #47,                    -- inc edi
    #49,                    -- dec ecx
    #75,#F6,                -- jnz label1
    #61,                    -- popa
    #C3})                   -- ret
            call(convert_proc)
            free(convert_proc)
            free(buffer)
        elsif temp[35] = 8 and temp[23] = 2 then  -- STEREO 8-bit
            buffer = result[1]
            len = floor(result[2] / 2)
            result = {allocate(len), len, result[3], allocate(len)}
            if result[1] = 0 or result[4] = 0 then
                if result[1] then free(result[1]) end if
                if result[4] then free(result[4]) end if
                free(buffer)
                close(fn)
                return LOAD_WAVE_FAIL
            end if
            lock_memory(result[1], len)
            lock_memory(result[4], len)
            convert_proc = allocate_proc(
   {#60,                    -- pusha
    #BE}&int_to_bytes(buffer)&{    -- mov esi, 5
    #BB}&int_to_bytes(result[1])&{    -- mov ebx, 1
    #BA}&int_to_bytes(result[4])&{    -- mov edx, 4
    #B9}&int_to_bytes(len)&{    -- mov ecx, 6
    #66,#AD,                -- label1: lodsw
    #66,#35,#80,#80,        -- xor ax, #8080
    #88,#03,                -- mov [ebx], al
    #88,#22,                -- mov [edx], ah
    #43,                    -- inc ebx
    #42,                    -- inc edx
    #49,                    -- dec ecx
    #75,#F1,                -- jnz label1
    #61,                    -- popa
    #C3})                   -- ret
            call(convert_proc)
            free(convert_proc)
            free(buffer)
        elsif temp[35] = 16 and temp[23] = 2 then  -- STEREO 16-bit
            buffer = result[1]
            len = floor(result[2] / 4)
            result = {allocate(len), len, result[3], allocate(len)}
            if result[1] = 0 or result[4] = 0 then
                if result[1] then free(result[1]) end if
                if result[4] then free(result[4]) end if
                free(buffer)
                close(fn)
                return LOAD_WAVE_FAIL
            end if
            lock_memory(result[1], len)
            lock_memory(result[4], len)
            convert_proc = allocate_proc(
   {#60,                    -- pusha
    #BE}&int_to_bytes(buffer)&{    -- mov esi, 5
    #BB}&int_to_bytes(result[1])&{    -- mov ebx, 1
    #BA}&int_to_bytes(result[4])&{    -- mov edx, 4
    #B9}&int_to_bytes(len)&{    -- mov ecx, 6
    #8A,#46,#01,            -- label1: mov al, [esi+1]
    #8A,#66,#03,            -- mov ah, [esi+3]
    #83,#C6,#04,            -- add esi, 4
    #88,#03,                -- mov [ebx], al
    #88,#22,                -- mov [edx], ah
    #43,                    -- inc ebx
    #42,                    -- inc edx
    #49,                    -- dec ecx
    #75,#EE,                -- jnz label1
    #61,                    -- popa
    #C3})                   -- ret
            call(convert_proc)
            free(convert_proc)
            free(buffer)
        end if
        if sound_debug_file then puts(sound_debug_file, "converted, ") end if
        end if
        if sound_debug_file then puts(sound_debug_file, "done.\n") end if
        fclose(fn)
    end if

    return result
end function


global function play_wave(object wave_info, integer loop, integer volume)
    sequence result
    result = {}
    if modwave_init and sequence(wave_info) then
    for i = max_channels - 1 to 0 by -1 do
        if peek4u(channels + i*channel_size + 12) = 0 then
            poke(channels + i*channel_size + 1, volume)
            poke4(channels + i*channel_size + 8, 
                wave_info[3] &
                wave_info[1..2] & 
                0 & 
                (volume_table + volume * 1024 * (length(wave_info)=4 or length(result)=0)) & 
                (volume_table + volume * 1024 * (length(wave_info)=3)) &
                 wave_info[1..2] &
                (wave_info[1..2] * (loop != 0)) &
                hz_table &
                volume_table &
                volume_table)
            if length(result) then
                return result & i
            else
                result = {i}
                if length(wave_info) > 3 then
                    wave_info = wave_info[4] & wave_info[2..3]
                else
                    exit
                end if
            end if
        end if    
    end for
    end if
    return result
end function

global procedure stop_wave(object chan_id)
-- chan_id = sequence returned by play_wave
    atom chan
    if atom(chan_id) then
        chan_id = {chan_id}
    end if
    for i = 1 to length(chan_id) do
        chan = channels + channel_size * chan_id[i]
        poke4(chan + 12, {0,0,0})
    end for
end procedure

global procedure set_wave_hertz(object chan_id, integer hz)
-- chan_id = sequence returned by play_wave
    atom chan
    if atom(chan_id) then
        chan_id = {chan_id}
    end if
    for i = 1 to length(chan_id) do
        chan = channels + channel_size * chan_id[i]
        poke4(chan + 8, hz)
    end for
end procedure

global procedure set_wave_offset(object chan_id, integer offset)
-- chan_id = sequence returned by play_wave
    atom chan, pos, len
    if atom(chan_id) then
        chan_id = {chan_id}
    end if
    for i = 1 to length(chan_id) do
        chan = channels + channel_size * chan_id[i]
        pos = peek4u(chan+32) + offset
        len = peek4u(chan+36) - offset
        if len < 0 then
             pos = 0
             len = 0
        end if
        poke4(chan + 12, pos)
        poke4(chan + 16, len)
    end for
end procedure

global procedure set_wave_volume(object chan_id, object volume)
-- chan_id = sequence returned by play_wave
    atom chan
    if atom(chan_id) then
        chan_id = {chan_id}
    end if
    for i = 1 to length(chan_id) do
        chan = channels + channel_size * chan_id[i]
        if length(chan_id) = 1 then -- MONO
            if sequence(volume) then
                poke4(chan + 24, volume_table + volume * 1024)
            else
                poke4(chan + 24, repeat(volume_table + volume * 1024, 2))
            end if
        else   -- STEREO
            if sequence(volume) then
                poke4(chan + 24, volume_table + volume * 1024 * {i=1,i=2})
            else
                poke4(chan + 24, repeat(volume_table + volume * 1024, 2) * {i=1,i=2})
            end if
        end if
    end for
end procedure

global function is_wave_playing(object chan_id)
-- chan_id = sequence returned by play_wave
    atom chan, result
    if atom(chan_id) then
        chan_id = {chan_id}
    end if
    result = 0
    for i = 1 to length(chan_id) do
        chan = channels + channel_size * chan_id[i]
        result = result or peek4u(chan+12)
    end for
    return result
end function

global function switch_wave(object chan_id, object wave_info, integer loop, integer volume)
    stop_wave(chan_id)
    chan_id = play_wave(wave_info, loop, volume)
    return chan_id
end function

global procedure unload_wave(object wave_info)
    if sequence(wave_info) then
        free(wave_info[1])
        if length(wave_info) >= 4 then
            free(wave_info[4])
        end if
    end if
end procedure

global function load_waves(sequence waves)
    for i = 1 to length(waves) do
        puts(1, "loading "&waves[i]&"...\n")
        waves[i] = load_wave(waves[i])
    end for
    return waves
end function

global procedure unload_waves(sequence waves)
    for i = 1 to length(waves) do
        unload_wave(waves[i])
    end for
end procedure


include get.e

atom a,b,c
sequence s
puts(1, "MOD playback rate (11025,22050,33075,44100)? ")
s = get(0)  a = s[2]
puts(1, "Number of channels (4-32)? ")
s = get(0)  b = s[2]
puts(1, "Stereo playback (2) or mono playback (1)? [1/2] ")
s = get(0)  c = s[2]
if c != 1 and c != 2 then
    c = 1
end if

if init_modwave(c, a, b) then
    puts(1, "Init error!")
    abort(0)
end if

puts(1, "Playing test MOD.\n")

if load_mod("intro.mod") then
    puts(1, "couldn't load intro.mod")
    close_modwave()
    abort(0)
end if

while get_key() = -1 do
    
end while

