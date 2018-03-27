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
-- zig.ex
-- This is the main module, containing nearly everything.
--


without type_check
without warning
without profile_time

    
-- Includes
-- (There are some more includes throughout the code.)
include graphics.e      -- graphics functions
include image.e         -- text- and graphic-image manipulation
include wildcard.e      -- DOS wildcard functions
include misc.e          -- random functions, etc.
include machine.e       -- low-level functions
include file.e          -- file manipulation
include get.e           -- extended file routines

include zig_modw.e       -- the ModWave library
include zig_keyb.e       -- get_keys() and related functions


-- Global constant definitions

global constant
        VERSION = "2.1",          -- current version number
        COPYRIGHT = "1997-2001",    -- copyright year range
        SAFETY = 0,                 -- safety stuff off/on (slower when on)

        -- basic definitions
        NULL = 0,       -- null constant
        TRUE = 1,
        FALSE = 0,
        ON = TRUE,
        OFF = FALSE,

        -- graphics mode constants for video_mode()
        EGA = 1,
        VGA = 2,

        -- charset 1 - used for standard ASCII-set box - unused
        --UL = 218,
        --UR = 191,
        --LL = 192,
        --LR = 217,
        --V = 179,
        --H = 196,

        -- charset 2 - ZIG's standard set box characters
        UL = 192,   -- upper-left corner
        UR = 193,   -- upper-right
        LL = 194,   -- lower-left
        LR = 195,   -- lower-right
        H = 196,    -- horizontal line
        V = 197,    -- vertical line

        -- palette modification machine code allocation
        PAL_CODE = allocate(21),

        -- keyboard scan codes (for normal get_key(), does not work for
        --                      get_keys() )
        KEY_UP = 328,       -- all of these are pretty obvious
        KEY_DN = 336,
        KEY_LF = 331,
        KEY_RT = 333,
        KEY_HOME = 327,
        KEY_END = 335,
        KEY_F1 = 315,
        KEY_F2 = 316,
        KEY_F3 = 317,
        KEY_F4 = 318,
        KEY_F5 = 319,
        KEY_F6 = 320,
        KEY_F7 = 321,
        KEY_F8 = 322,
        KEY_F9 = 323,
        KEY_F10 = 324,
        KEY_PGUP = 329,
        KEY_PGDN = 337,
        KEY_TAB = 9,
        KEY_ESC = 27,
        KEY_CR = 13,
        KEY_CT_UP = 397,
        KEY_CT_DN = 401,
        KEY_CT_LF = 371,
        KEY_CT_RT = 372,
        KEY_INS = 338,
        KEY_DEL = 339,
        KEY_ALT_UP = 408,
        KEY_ALT_DN = 416,
        KEY_ALT_LF = 411,
        KEY_ALT_RT = 413,
        KEY_ALT_L = 277,
        KEY_ALT_P = 281,
        KEY_ALT_S = 284,
        KEY_ALT_C = 302,
        KEY_CTRLCR = 10,

        -- get_keys() special keyboard scan codes
        S_KEY_ESC = 1,
        S_KEY_L_CTRL = 29,
        S_KEY_R_CTRL = 285,
        S_KEY_L_ALT = 56,
        S_KEY_R_ALT = 312,
        S_KEY_F1 = 59,
        S_KEY_F2 = 60,
        S_KEY_F3 = 61,
        S_KEY_F4 = 62,
        S_KEY_F5 = 63,
        S_KEY_F6 = 64,
        S_KEY_F7 = 65,
        S_KEY_F8 = 66,
        S_KEY_F9 = 67,
        S_KEY_F10 = 68,
        
        -- lookup table for alpha-keys get_keys()
        S_ALPHA_TABLE = {30,48,46,32,18,33,34,35,23,36,37,38,50,49,24,25,16,19,31,20,22,47,17,45,21,44},
        S_NUM_TABLE = {11,2,3,4,5,6,7,8,9,10},
        S_NUMPAD_TABLE = {82,79,80,81,75,76,77,71,72,73},

        -- file format headers for version recognition
        -- our default header
        DEF_HEADER = "***ZIG World File v2.0 format 4***",
        -- header for old file format 3
        DEF_HEADER_FF3 = "***ZIG World File v2.0 format 3***",
        -- header for old file format 1
        DEF_HEADER_FF1 = "***ZIG World File v2.0 format 1***",
        -- header for old file format 2
        DEF_HEADER_FF2 = "***ZIG World File v2.0 format 2***",
        -- header for version 1.0.x worlds
        V10_HEADER = "ZIG10A",      -- 10B, C, D added automatically

        -- flash data for on-screen messages
        CS = {15, 14, 10, 12, 13, 9, 1, 5, 4, 6, 13, 14},

        -- lookup constants for the sidebar stats data
        STAT_NAME = 1,  -- the stat's name
        STAT_CHAR = 2,  -- stat's char
        STAT_VAR = 3,   -- variable that the stat is bound to

        -- lookup constants for the flag data
        FLAG_NAME = 1,  -- flag's name
        FLAG_VALUE = 2, -- flag's value (1/0)

        -- lookup for variable data
        VAR_NAME = 1,   -- variable's name
        VAR_VALUE = 2,  -- variable's value

        -- prototypes for various in-game data types
        NEW_STAT = {{}, 0, {}}, -- a new sidebar stat
        NEW_FLAG = {{}, 0},     -- a new flag
        NEW_VAR = {{}, 0},      -- a new variable

        -- general constants

        -- the default configuration settings
        DEFAULT_CONFIG = {0,ON,22050,16,STEREO,ON,OFF,FALSE,FALSE},
        -- lookup values for the configuration sequence
        RUN_TIMES = 1,      -- how many times this copy has been run
        SOUND_ON = 2,       -- sound on/off (1/0) [1]
        SOUND_FREQ = 3,     -- sound playback frequency [22050]
        SOUND_CHANNELS = 4, -- number of max. active channels [16]
        SOUND_STEREO = 5,   -- stereo sound? (1/0) [STEREO]
        VERBOSE_L = 6,      -- verbose loaders (1/0) [1]
        FAST_FADES = 7,     -- 'fast' fades (1/0) [0]
        NO_FADES = 8,       -- no fades at all (1/0) [0]
        NO_EGA = 9,         -- don't use EGA, just default mode (1/0) [0]

        CONFIG_OPTIONS = {"Sound engine",
                          "Sound frequency",
                          "Sound channels",
                          "Stereo sound",
                          "Verbose loaders",
                          "Fast fades",
                          "No fades at all",
                          "No EGA usage (not recommended)"},


        -- system-default font settings - don't modify unless you know what
        -- you are doing =)
        FONT_WIDTH = 8,     -- the font's width
        FONT_HEIGHT = 16,   -- hmm...

        -- constants for the sb_input() routine
        SBI_FILENAME = 1,   -- getting a filename
        SBI_NUMBER = 2,     -- a number
        SBI_ANYSTR = 3,     -- any string (probably not used at all)

        -- type constants for world/board property data types
        PROP_VALUE = 1,             -- a value
        PROP_VALUE_CONFIRMED = 2,   -- a value - confirmed (used for brd size)
        PROP_STRING = 3,    -- a string (e.g. board/world name)
        PROP_BOARD = 4,     -- a board (e.g. starting/title board)
        PROP_PALETTE = 5,   -- a palette data object (e.g. board palette)
        PROP_CHARSET = 6,   -- a charset data object
        PROP_OBJECT = 7,    -- an object (board controller object)
        PROP_BOOLEAN = 8,   -- a boolean value

        -- lookups for world/board properties
        PROP_DATA_NAME = 1,
        PROP_DATA_PARAM = 2,
        PROP_DATA_TYPE = 3,
        PROP_DATA_INDEX = 4,

        -- lookups for board data
        BRD_SIZEX = 1,  -- the board's size X
        BRD_SIZEY = 2,  -- the board's size Y
        BRD_LAYERS = 3, -- number of layers
        BRD_NAME = 4,   -- the board's name
        BRD_EXITN = 5,  -- exit to north
        BRD_EXITS = 6,  -- exit to south
        BRD_EXITE = 7,  -- east
        BRD_EXITW = 8,  -- west
        BRD_PAL = 9,    -- the board's palette
        BRD_CHARSET = 10,   -- the board's character set
        BRD_MUSICFILE = 11, -- the board's default music file
        BRD_CTROBJ = 12,    -- board's controller object
        BRD_OFFSETX = 13,
        BRD_OFFSETY = 14,
        BRD_VPX1 = 15,
        BRD_VPY1 = 16,
        BRD_VPX2 = 17,
        BRD_VPY2 = 18,
        BRD_DATA = 19,      -- the actual board data
        BRD_OBJECTS = 20,   -- the objects on the board
        BRD_FOCUSOBJ = 21,  -- focus object (added dynamically)

        -- data strings for the Board Properties window
        BRD_PROPS_DATA = {{"Board Size X", BRD_SIZEX, PROP_VALUE_CONFIRMED},
                          {"Board Size Y", BRD_SIZEY, PROP_VALUE_CONFIRMED},
                          {"Number of Layers", BRD_LAYERS, PROP_VALUE_CONFIRMED},
                          {"Board Name", BRD_NAME, PROP_STRING},
                          {"Exit to North", BRD_EXITN, PROP_BOARD},
                          {"Exit to South", BRD_EXITS, PROP_BOARD},
                          {"Exit to East", BRD_EXITE, PROP_BOARD},
                          {"Exit to West", BRD_EXITW, PROP_BOARD},
                          {"Palette", BRD_PAL, PROP_PALETTE},
                          {"Character Set", BRD_CHARSET, PROP_CHARSET},
                          {"Music File", BRD_MUSICFILE, PROP_STRING},
                          {"Edit Controller Object", BRD_CTROBJ, PROP_OBJECT},
                          {"Default offset X", BRD_OFFSETX, PROP_VALUE},
                          {"Default offset Y", BRD_OFFSETY, PROP_VALUE},
                          {"Default viewport X1", BRD_VPX1, PROP_VALUE},
                          {"Default viewport Y1", BRD_VPY1, PROP_VALUE},
                          {"Default viewport X2", BRD_VPX2, PROP_VALUE},
                          {"Default viewport Y2", BRD_VPY2, PROP_VALUE}},

        BRD_NO_EXIT = 0,    -- used for when a board has no exit n/s/e/w set

        BRD_TILEELEMS = 3,  -- how many elements per tile
        -- for an individual tile on a board
        BRD_TILECHAR = 1,   -- tile's ASCII character
        BRD_TILECOLOR = 2,  -- tile's color
        BRD_TILEFLAGS = 3,  -- tile flags (reserved for future use)

        -- lookups for world properties
        WRLD_NAME = 1,      -- world's name
        WRLD_TITLEBRD = 2,  -- world's title board
        WRLD_STARTBRD = 3,  -- world's start board
        WRLD_SBAUTO = 4,    -- autoset flag
        WRLD_HEALTHEND = 5, -- endgame on health = 0 flag
        WRLD_FILENAME = 6,  -- the world's file name (filled in at load time)
        WRLD_BOARDS = 7,    -- the board data

        -- data strings for World Properties
        WRLD_PROPS_DATA = {{"World Name", WRLD_NAME, PROP_STRING},
                           {"Title Board", WRLD_TITLEBRD, PROP_BOARD},
                           {"Starting Board", WRLD_STARTBRD, PROP_BOARD},
                           {"Start Board Autoset", WRLD_SBAUTO, PROP_BOOLEAN},
                           {"Endgame on health = 0", WRLD_HEALTHEND, PROP_BOOLEAN}},

        -- defaults for board sizes
        DEFAULT_BRD_SIZEX = 25, -- default size X
        DEFAULT_BRD_SIZEY = 60, -- default size Y
        DEFAULT_BRD_LAYERS = 3, -- default number of layers

        -- game engine error codes
        CE_UNCLOSED_STRING = 1,     -- an unclosed string (like "Hey there )
        CE_MALFORMED_STATEMENT = 2, -- statement with too few/many params

        -- error result codes
        CE_RESUME = 1,
        CE_HALT = 2,
        CE_ENDGAME = 3,

        -- one-line message data for game engine
        MAX_MESSAGES = 100, -- number of possible one-line messages
        -- lookups for 1line message data
        MSG_MSG = 1,    -- the message itself
        MSG_COLOR = 2,  -- its color (0=flashing)
        MSG_TIME = 3,   -- the time (absolute) when the message will be killed
        MSG_X = 4,      -- message location X
        MSG_Y = 5,      -- message location Y (0=centered, as below)
        CENTERED = 0,   -- centered is MSG_Y = 0
        FLASHING = 0,
        MSG_UPDATEINT = .05, -- time between message color changes/updates

        -- more general data
        TPS = 0.105,  -- time of a single cycle-1 wait [0.105]

        -- editor constants
        -- the default pattern data for the editor
        DEFAULT_PATTERN_DATA = {{'Û'}, {'²'}, {'±'}, {'°'}, {' '}},
        PAT_CHAR = 1,   -- lookup for pattern data - char
        PAT_OBJECT = 2, -- lookup for pattern data - if object, then is here
        CSR_FLASH_DELAY = 0.1,  -- the cursor's flash delay [0.1]
        DRAWING_OFF = 0,    -- drawing off
        DRAWING_ON = 1,     -- drawing is on
        DRAWING_TEXT = 2,   -- text entry mode
        RUNNING = 0,        -- loop constant (e.g. while status = RUNNING)
        STOP = 1,           -- loop constant
        CSR_NORMAL = 202,   -- 'Å', char for normal cursor mode (drawing off)
        CSR_DRAWING = 202,  -- 'Î', drawing on character
        CSR_TEXT = '_',     -- text entry cursor
        MSG_ETIME = 2,      -- time for an editor message to be displayed
        OBJ_HALTED = -1,    -- OBJ_POS of object is equal to this if it is halted
        SB_REDRAW_TICK = .5,    -- sidebar redraw tick frequency

        -- block action constants
        BS_CANCEL = 1,  -- cancel the operation
        BS_COPY = 3,    -- copy block
        BS_FILL = 4,    -- fill block
        BS_ERASE = 5,   -- erase block

        -- draw routine full-layer constants
        VISIBLE_ALL_ON = {1},   -- pass this for all layers on
        VISIBLE_ALL_OFF = {0},  -- ... and this for all off

        -- lookups for object data sequences
        OBJ_X = 1,      -- object's position X
        OBJ_Y = 2,      -- position Y
        OBJ_LAYER = 3,  -- current layer of object
        OBJ_CHAR = 4,   -- object's ASCII character
        OBJ_COLOR = 5,  -- 16x16 object color
        OBJ_CYCLE = 6,  -- object cycle speed
        OBJ_NAME = 7,   -- object's name (sequence)
        OBJ_COLLIDE = 8,    -- can collide? (1/0)
        -- runstate (0=run, -1=halt, else run state is set to the absolute
        --           time when the object will resume execution after a /i)
        OBJ_RUNSTATE = 9,
        OBJ_POS = 10,   -- code position
        OBJ_LOCKED = 11,    -- is locked? (1/0)
        OBJ_LIBFROM = 12,   -- library where it came from
        OBJ_PROPS = 13,     -- property string
        OBJ_LIBINDEX = 14,
        OBJ_FLOW = 14,
        OBJ_PUSHABLE = 15,
        OBJ_WALKDIR = 16,
        NUM_OBJ_PARAMS = 14,    -- the count of object parameters

        -- a new object prototype
        NEW_OBJECT = {{0,   -- X
                       0,   -- Y
                       0,   -- Layer
                       0,   -- Char
                       0,   -- Color
                       3,   -- Cycle
                       {},  -- Name
                       ON,  -- Collide on/off
                       1,   -- Runstate (1=active, else t-cycle till active)
                       1,   -- Code counter
                       OFF, -- Lock on/off
                       {},  -- Library from
                       {}}},    -- Props

        -- new board prototype
        NEW_BOARD = {DEFAULT_BRD_SIZEX,             -- Size X
                     DEFAULT_BRD_SIZEY,             -- Size Y
                     DEFAULT_BRD_LAYERS,            -- Layers
                     {},                            -- Name
                     BRD_NO_EXIT,                   -- Exit North
                     BRD_NO_EXIT,                   -- Exit South
                     BRD_NO_EXIT,                   -- Exit East
                     BRD_NO_EXIT,                   -- Exit West
                     {},                            -- Palette
                     {},                            -- Charset
                     {},                            -- Music File
                     NEW_OBJECT,                    -- Controller Object
                     0,                             -- Offset X
                     0,                             -- Offset Y
                     1,                             -- VPX1
                     1,                             -- VPY1
                     25,                            -- VPX2
                     60,                            -- VPY2
                     repeat(0,                      -- Data
                      (((DEFAULT_BRD_SIZEX * DEFAULT_BRD_SIZEY)
                      * BRD_TILEELEMS) * DEFAULT_BRD_LAYERS) + 1),
                     {}},                           -- Objects

        -- new world prototype
        NEW_WORLD = {{}, 1, BRD_NO_EXIT, 1, 1, {}, repeat(NEW_BOARD, 1)},

        -- game engine data types
        DT_VAR = 1,     -- a variable (starting with %)
        DT_LABEL = 2,   -- a jump label
        DT_OBJECT = 3,  -- another object (w/o @)
        DT_CHAR = 4,    -- an ASCII character code
        DT_LIT = 5,     -- literal expression - then, else, integer, etc.
        DT_SCD = 6,     -- single coordiate (x or y)
        DT_FLAG = 7,    -- a flag
        DT_COLOR = 8,   -- a color (cXX or number)
        DT_CYCLE = 9,   -- a cycle speed (0-255)
        DT_BOOL = 10,   -- a boolean value
        DT_FILE = 11,   -- a filename
        DT_LAYER = 12,  -- a layer value
        DT_VAL = 13,    -- any value (0-32762)
        DT_PEL = 14,    -- a palette element (red green or blue) 0-63
        DT_VTYPE = 15,  -- variable type (string, integer, array, etc.)
        DT_DIR = 16,    -- a direction
        DT_KEY = 17,    -- a key on the keyboard
        DT_STRING = 18, -- a text string up to 80 chars
        DT_BOARD = 19,  -- a board, either number or name
        DT_IGNORE = 20, -- ignore this value
        DT_IFBLOCK = 21,-- an #if block

        DT_A_OPT = 255, -- added to indicate an optional value

        -- command types
        CMD_STATEMENT = 1,  -- a # statement
        CMD_VARASSIGN = 2,  -- a variable assignment (%)
        CMD_DIR = 3,        -- a directional move (/ or ?)
        CMD_INSTDIR = 4,    -- instant directional move (\)
        CMD_NAMEASSIGN = 5, -- name assignment (@)
        CMD_LABEL = 6,      -- label (:)
        CMD_MSG = 7,        -- a message
        CMD_ZAPLABEL = 8,
        CMD_TYPES = {{'#'}, {'%'}, {'/', '?'}, {'\\'}, {'@'}, {':'}, {'!', '$'}, {'|'}},

        -- command constants for identification from table
        C_ADDSTAT = 1,
        C_ARRAYSET = 2,
        C_BIND = 3,
        C_BINDAPPEND = 4,
        C_CHANGE = 5,
        C_CHANGEAREA = 6,
        C_CHAR = 7,
        C_CLEAR = 8,
        C_CLONE = 9,
        C_COLOR = 10,
        C_CYCLE = 11,
        C_DELSTAT = 12,
        C_DIE = 13,
        C_END = 14,
        C_ENDGAME = 15,
        C_FADE = 16,
        C_FADEVOL = 17,
        C_FOCUS = 18,
        C_GHOST = 19,
        C_IDLE = 20,
        C_IF = 21,
        C_LOADFONT = 22,
        C_LOADMOD = 23,
        C_PLAYMOD = 24,
        C_PAUSEMOD = 25,
        C_MOVE = 26,
        C_MOVETOBOARD = 27,
        C_PLAYWAV = 28,
        C_LOCK = 29,
        C_RESTART = 30,
        C_RESTORE = 31,
        C_SHAKE = 32,
        C_SCROLL = 33,
        C_SCROLLAREA = 34,
        C_SEND = 35,
        C_SET = 36,
        C_SETPAL = 37,
        C_SIDEBAR = 38,
        C_SOLID = 39,
        C_TRANSPARENCY = 40,
        C_TRANSPORT = 41,
        C_TRANSPORTFOCUS = 42,
        C_UNLOCK = 43,
        C_VARIABLE = 44,
        C_VISLAYER = 45,
        C_VOLUME = 46,
        C_GO = 47,
        C_ZAP = 48,
        C_OFFSET = 49,
        C_VIEWPORT = 50,
        C_GIVE = 51,
        C_TAKE = 52,
        C_TRY = 53,
        C_PUSHABLE = 54,
        C_BECOME = 55,
        C_WALK = 56,
        C_PUT = 57,
        C_ITEMDIE = 58,
        C_LINES = 59,
        C_SHOOT = 60,
        C_SENDAT = 61,
        C_SHIFTCHAR = 62,
        C_TEXT = 63,

        -- command data
        OS_COMMANDS =
        {
         {"#addstat", {DT_VAR, DT_STRING, DT_CHAR + DT_A_OPT}}, -- 1
         {"#arrayset", {DT_VAR, DT_VAL, DT_VAL + DT_A_OPT}},    -- 2
         {"#bind", {DT_OBJECT}},                                -- 3
         {"#bindappend", {DT_OBJECT}},                          -- 4
         {"#change", {DT_CHAR, DT_COLOR}},   -- 5
         {"#changearea", {DT_SCD, DT_SCD, DT_SCD, DT_SCD, DT_COLOR + DT_A_OPT, DT_CHAR, DT_LIT + DT_A_OPT, DT_COLOR + DT_A_OPT, DT_CHAR, DT_LIT + DT_A_OPT}},   -- 6
         {"#char", {DT_CHAR}},  -- 7
         {"#clear", {DT_FLAG}}, -- 8
         {"#clone", {DT_OBJECT, DT_SCD, DT_SCD}}, -- 9
         {"#color", {DT_COLOR}},    -- 10
         {"#cycle", {DT_CYCLE}},    -- 11
         {"#delstat", {DT_VAR}},    -- 12
         {"#die", {}},  -- 13
         {"#end", {}},  -- 14
         {"#endgame", {}},   -- 15
         {"#fade", {DT_LIT, DT_VAL}},   -- 16
         {"#fadevol", {DT_LIT}},    -- 17
         {"#focus", {}},  -- 18
         {"#ghost", {}}, -- 19
         {"#idle", {}}, -- 20
         {"#if", {DT_BOOL, DT_IFBLOCK}},    -- 21
         {"#loadfont", {DT_FILE}},  -- 22
         {"#loadmod", {DT_FILE}},   -- 23
         {"#playmod", {}},  -- 24
         {"#pausemod", {}}, -- 25
         {"#move", {DT_SCD, DT_SCD}},  -- 26
         {"#movetoboard", {DT_BOARD}},   -- 27
         {"#playwav", {DT_FILE}},   -- 28
         {"#lock", {}}, -- 29
         {"#restart", {}},  -- 30
         {"#restore", {DT_STRING}},  -- 31
         {"#shake", {DT_VAL}},  -- 32
         {"#scroll", {DT_LAYER, DT_VAL, DT_VAL}},   -- 33
         {"#scrollarea", {DT_SCD, DT_SCD, DT_SCD, DT_SCD, DT_LAYER, DT_VAL, DT_VAL}},   -- 34
         {"#send", {DT_LABEL}}, -- 35
         {"#set", {DT_FLAG}},   -- 36
         {"#setpal", {DT_COLOR, DT_PEL, DT_PEL, DT_PEL}},   -- 37
         {"#sidebar", {DT_BOOL}},   -- 38
         {"#solid", {}}, -- 39
         {"#transparency", {DT_LAYER, DT_BOOL}},    -- 40
         {"#transport", {DT_BOARD}},    -- 41
         {"#transportfocus", {DT_BOARD}}, -- 42
         {"#unlock", {}},   -- 43
         {"#variable", {DT_VAR, DT_VTYPE + DT_A_OPT}},  -- 44
         {"#vislayers", {DT_LAYER, DT_BOOL}},    -- 45
         {"#volume", {DT_VAL}}, -- 46
         {"#go", {DT_DIR}}, -- 47
         {"#zap", {DT_LABEL}},  -- 48
         {"#offset", {DT_VAL}},     -- 49
         {"#viewport", {DT_VAL, DT_VAL, DT_VAL, DT_VAL}},   -- 50
         {"#give", {DT_VAR, DT_VAL}},   -- 51
         {"#take", {DT_VAR, DT_VAL}},   -- 52
         {"#try", {DT_DIR}},  -- 53
         {"#pushable", {}},             -- 54
         {"#become", {DT_LIT}},         -- 55
         {"#walk", {DT_DIR}},           -- 56
         {"#put", {DT_DIR}},            -- 57
         {"#itemdie", {}},              -- 58
         {"#lines", {DT_VAL}},          -- 59
         {"#shoot", {DT_DIR}},          -- 60
         {"#sendat", {DT_DIR}},         -- 61
         {"#shiftchar", {DT_CHAR, DT_VAL, DT_VAL}}, -- 62
         {"#text", {DT_SCD, DT_SCD, DT_STRING}}},   -- 63

        -- unsupported ZZT-OOP or other commands
        OS_COMMANDS_UNSUP = {"_focus"},

        -- LB socketed plugin installed in code (not implemented)
        LB_SOCKET = FALSE


-- Global variables

global atom
    -- scroll dimensions data
    Scroll_SizeX,
    Scroll_SizeY,
    Scroll_PosX,
    Scroll_PosY,
    Scroll_TextC,
    Scroll_BackC,
    Scroll_HLTitleC,
    Scroll_BorderC,

    screen_sizex,   -- the size of the screen X
    screen_sizey,   -- size Y
    sidebar_width,  -- width of the sidebar
    sidebar,        -- is the sidebar visible? (1/0)

    next_available_message, -- the next available message value - not totally
                            -- neccesary but used to speed things up

    message_x,      -- current new one-line message location x
    message_y,      -- "" location y
    message_color,  -- color (0=flashing)
    message_time,   -- seconds to last
    cs_counter,     -- cycle count
    oldstatlen,     -- length stats was on last sidebar_ge_draw_stats pass
    r1_store,       -- used by dlg_library_menu

    first_load,     -- is this the first load of the main screen?

    font_height,    -- variable system font height
    font_squish     -- sqush the font for 43/50 line mode (t/f)


global sequence
    world,              -- the whole game world
    current_mod,        -- current MOD that's playing
    backup_world,       -- the backup world - used to restore orig. world
                        -- state after playing
    system_palette,     -- the default system palette loaded from default.zpl
    system_charset,     -- default sys charset loaded from default.zch
    default_charset,    -- this PC's BIOS charset
    flags,              -- flag data
    variables,          -- the variables
    stats,              -- sidebar stats
    messages,           -- in-game message buffers
    fadata,             -- fade data (current step of fade)
    config,             -- global configuration
    this_dir,           -- the directory ZIG was started from
    name_pass,          -- compiler thing
    color_table,        -- table of color names
    lit_color_table,    -- pretty table of color names
    help_text,          -- the ZIG manual
    charset             -- the charset


-- display the first text while the code is processing

sequence line
text_color(15)
bk_color(0)
line = "  ZIG v" & VERSION & "  "
position(11, 40 - floor(length(line) / 2))
puts(1, line)
text_color(7)
line = "  Initializing code...  "
position(13, 40 - floor(length(line) / 2))
puts(1, line)


-- load the palette functions - it's down here for compatibility
include zig_egap.e



-- allow_all_paledit()
-- called from init() to make the BIOS let us modify all 16 color elements
-- of the palette in EGA text mode. otherwise it won't work right.
global procedure allow_all_paledit()

    -- put the assembly code in its place
    poke(PAL_CODE, {#50,#52,#BA,#DA,#03,#00,#00,#EC,#B2,#C0,#FA,#B0,#00,#EE,
                    #B0,#00,#EE,#FB,#5A,#58,#C3})

    -- add the values
    for i = 0 to 15 do

        poke(PAL_CODE + 12, i)
        poke(PAL_CODE + 15, i)

        call(PAL_CODE)  -- call it for each color

    end for

    poke(PAL_CODE + 12, #20)    -- the end

    call(PAL_CODE)

end procedure


-- video_mode()
-- sets the video mode. call with video_mode(EGA) or video_mode(VGA).
global procedure video_mode(atom wot)

    atom a
    sequence regs

    if wot = EGA then
        -- set EGA 640x350 text mode
        regs = repeat(0, 10)    -- define registers
        regs[REG_AX] = #1201    -- set our register data
        regs[REG_BX] = #0030
        regs = dos_interrupt(#10, regs) -- 1st call
        regs[REG_AX] = #0003
        regs = dos_interrupt(#10, regs) -- 2nd call
        font_height = 14        -- set the variable font height
    elsif wot = VGA then
        out_byte(#3C4, 1) out_byte(#3C5, 1)     -- char width of 8
        out_byte(#3C2, #63)     -- use 25.175MHz dotclock
        a = in_byte(#3DA)       -- reset attrib control
        out_byte(#3C0, #33) out_byte(#3C0, 0)    -- reset
        font_height = 16        -- set the variable font height
    end if

end procedure


-- blink()
-- toggles blinking colors. if 0, then bright backgrounds are enabled. other-
-- wise, the background colors 8-15 cause the foreground to blink.
global procedure blink(integer f)

        sequence inr, outr

        inr = repeat(0, 10)
        inr[REG_AX] = #1003     -- blink/bright
        inr[REG_BX] = f         -- the value

        outr = dos_interrupt(#10, inr)  -- int10h call

end procedure


-- load_palette()
-- loads a ZIG palette file from an open file. pass open file's number.
function load_palette(atom fileno)

    sequence pal

    -- define a palette prototype
    pal = repeat({0, 0, 0}, 16)

    for z = 1 to 16 do  -- 16 colors...
        for a = 1 to 3 do   -- ...and 3 elms/color
            pal[z][a] = get_bytes(fileno, 1)    -- read the byte
            pal[z][a] = pal[z][a][1]            -- get rid of result code
        end for
    end for

    return(pal)     -- give it

end function


-- save a ZIG palette sequence to a file.
procedure save_palette(atom fileno, sequence pal)

    for z = 1 to 16 do      -- 16 colors and 3 elements/color
        for a = 1 to 3 do
            puts(fileno, pal[z][a])     -- write the char
        end for
    end for

end procedure


-- load a ZIG character set from an open file.
function load_charset(atom fileno)

    sequence loll
    sequence charset

    -- define a character set prototype
    charset = repeat(repeat(0, 16), 256)

    if not font_squish then
        for z = 1 to 256 do     -- 256 characters
            for a = 1 to 16 do  -- 16 lines per character
                charset[z][a] = get_bytes(fileno, 1)
                charset[z][a] = charset[z][a][1]
            end for
        end for
    else
        for z = 1 to 256 do     -- 256 characters
            for a = 1 to 8 do  -- 8 lines per character
                charset[z][a] = get_bytes(fileno, 1)
                charset[z][a] = charset[z][a][1]
                loll = get_bytes(fileno, 1)
            end for
        end for
    end if

    return(charset)

end function


-- save a ZIG character set to a file.
procedure save_charset(atom fileno, sequence charset)

    for z = 1 to 256 do -- 256 characters
        for a = 1 to 16 do  -- 16 lines/char
            puts(fileno, charset[z][a])
        end for
    end for

end procedure


-- get an lpstring.
-- an lpstring begins with a byte that is the string's length. read this
-- byte, and then get the appropriate number of characters.
function get_lpstr(atom f)

    return(get_bytes(f, getc(f)))

end function


-- get a 4-byte integer from a file.
-- safety checks ensure we don't get bad read.
function get_int4(atom f)

    sequence s

    s = get_bytes(f, 4)
    if length(s) = 0 then
        return(0)
    else return(bytes_to_int(s))
    end if

end function


-- get a 2-byte integer from a file.
-- safety checks ensure we don't get bad read.
function get_int2(atom f)

    sequence s

    s = get_bytes(f, 2)
    if length(s) = 0 then
        return(0)
    else return(bytes_to_int(s & {0, 0}))
    end if

end function


-- return a stripped-filename.
-- no / or dirs, or .zig.
function fproc(sequence file)
    atom a

    file = upper(file)

    while 1 do  -- infinite
        a = find('\\', file)    -- look for a backslash
        if not a then   -- no more backslashes,
            exit        -- so exit the loop
        else file = file[a + 1..length(file)]   -- advance it
        end if
    end while

    if find('.', file) then -- there is an extension
        file = file[1..find('.', file) - 1] -- be done with it
    end if

    return(file)

end function


-- clear the world, making a new one. sets all default values. called at
-- load time.
procedure clear_world()

    world = NEW_WORLD       -- set world from prototype
    world[WRLD_NAME] = "Untitled World"     -- world's name
    world[WRLD_BOARDS][1][BRD_NAME] = "Title Board"     -- set the name
    backup_world = {}       -- clear it too

end procedure


-- calculate the space needed for a board's data.
function return_board_geometry(atom sx, atom sy, atom layers, atom elems)

    return((((sx * sy) * elems) * layers) + 1)

end function


function calc_geometry(atom sizex, atom sizey, atom layers, atom x, atom y, atom layer, atom elem)

    atom elems

    sizex = sizex - 1
    sizey = sizey - 1
    layers = layers - 1
    elems = 2

    return( 1 +
            (
            (x * (sizey *
            layers * elems))    -- again, owww!
            + (y * (layers * elems))
            + (layer * (elems))
            + elem
            )
          )
    
end function


-- return a value for use with referencing a board's data to get a tile.
function calc_board_geometry(atom boardnum, atom sizex, atom sizey, atom layers, atom elems)

    -- owww!

    atom bsizex, bsizey, blayers

    -- size defs
    if SAFETY then
        bsizex = world[WRLD_BOARDS][boardnum][BRD_SIZEX]
        bsizey = world[WRLD_BOARDS][boardnum][BRD_SIZEY]
        blayers = world[WRLD_BOARDS][boardnum][BRD_LAYERS]

        -- corrections if too big
        if sizex > bsizex then sizex = bsizex end if
        if sizey > bsizey then sizey = bsizey end if
        if layers > blayers then layers = blayers end if
        if elems > BRD_TILEELEMS then elems = BRD_TILEELEMS end if
    end if

    -- decrement 'em all
    sizex = sizex - 1
    sizey = sizey - 1
    layers = layers - 1
    elems = elems - 1

    return( 1 +
            (
            (sizex * (world[WRLD_BOARDS][boardnum][BRD_SIZEY] *
            world[WRLD_BOARDS][boardnum][BRD_LAYERS] * BRD_TILEELEMS))    -- again, owww!
            + (sizey * (world[WRLD_BOARDS][boardnum][BRD_LAYERS] * BRD_TILEELEMS))
            + (layers * (BRD_TILEELEMS))
            + elems
            )
          )

end function


-- sets the entire palette to the sequence specified.
procedure set_all_pal(sequence pal)

    if config[NO_EGA] = TRUE then
        return      -- not using EGA, so no special effects
    end if

    for z = 1 to 16 do
        set_palette(z - 1, pal[z])  -- set the individual colors
    end for

end procedure


-- wait for a screen retrace. may be buggy.
procedure wait_retrace()

    if config[NO_EGA] = TRUE then
        return      -- no EGA stuff, so no retrace wait
    end if

    while in_byte(#3DA) != 9 do end while       -- wait for it, then exit

end procedure


-- fades out the screen. call fade_out_end() after calling this.
global procedure fade_out(atom speed)

    sequence xpal

    if config[NO_EGA] = TRUE or config[NO_FADES] = TRUE then
        return  -- effects are off one way or another
    end if

    -- prototype def
    xpal = repeat({0,0,0}, 16)

    -- get the current palette
    for z = 0 to 15 do
        xpal[z + 1] = get_palette(z)
    end for

    fadata = xpal   -- write to the shared fade variable

    for z = 63 to 1 by -speed do
        for a = 0 to 15 do
            for b = 1 to 3 do
                xpal[a + 1][b] = xpal[a + 1][b] - speed
                if xpal[a + 1][b] < 1 then xpal[a + 1][b] = 1 end if
            end for
            set_palette(a, xpal[a + 1])
        end for
    end for

end procedure


-- finish fading out
global procedure fade_out_end()

    if config[NO_EGA] = TRUE or config[NO_FADES] = TRUE then
        return      -- no graphics used - don't fade
    end if

    for z = 0 to 15 do
        set_palette(z, fadata[z + 1])   -- restore original palette
    end for

end procedure


-- start a fade in
global procedure fade_in_start()

    sequence xpal

    if config[NO_EGA] = TRUE or config[NO_FADES] = TRUE then
        return      -- nofx
    end if

    xpal = repeat({0,0,0}, 16)
    fadata = repeat({0,0,0}, 16)

    for z = 0 to 15 do
        fadata[z + 1] = get_palette(z)  -- store the original data
    end for

    for a = 0 to 15 do
        set_palette(a, {1, 1, 1})   -- clear the palette colors
    end for

end procedure


-- do the fade in
global procedure fade_in(atom speed)

    sequence xpal, lpal

    if config[NO_EGA] = TRUE or config[NO_FADES] = TRUE then
        return      -- no efx
    end if

    xpal = repeat({1,1,1}, 16)
    lpal = fadata

    for z = 1 to 63 by speed do
        for a = 0 to 15 do      -- for each color
            for b = 1 to 3 do   -- and each element
                xpal[a + 1][b] = xpal[a + 1][b] + speed -- add it
                if xpal[a + 1][b] > lpal[a + 1][b] then xpal[a + 1][b] = lpal[a + 1][b] end if
            end for
            set_palette(a, xpal[a + 1])     -- do it
        end for
    end for

end procedure


-- font code base by David Cuny and Jiri Babor
global function rtrim(sequence s)
    integer i

    i = length(s)

    if not length(s) then return({}) end if

    while i do
        if s[i] and s[i] != 32 then exit end if
        i = i - 1
    end while

    return(s[1..i])

end function


-- trims a string from the left.
global function ltrim(sequence s)
    integer i

    i = 1   -- counter
    
    if not length(s) then return({}) end if

    while i do
        if s[i] and s[i] != 32 then exit end if   -- encountered a thing
        i = i + 1
    end while

    return(s[i..length(s)])     -- give it

end function


-- loads the default character set from the ega rom. used for making the
-- system charset, and for 'revert to ascii' in the char editor.
global procedure load_rom_font()
    integer a, val, total, cnt
    sequence b, cb, cbm, regs, char

    if config[NO_EGA] = TRUE then
        return
    end if

    regs = repeat(0,10)
    regs[REG_AX] = #1130
    regs[REG_BX] = #600
    regs = dos_interrupt(#10, regs)
    a = #10 * regs[REG_ES] + regs[REG_BP] + 16  -- bypass zero char
    char = {}
    default_charset = repeat({}, 255)
    for i = 1 to 255 do                   -- again bypass zero
        cbm = {}
        cb = rtrim(peek({a, 16}))          -- char bytes, right trimmed
        for j = 1 to length(cb) do
            b = and_bits(cb[j], {128, 64, 32, 16, 8, 4, 2, 1}) and 1
            cbm = append(cbm, rtrim(b))
        end for
        a = a + 16
        char = append(char, cbm)
        cnt = 16 - length(char[i])
        for q = 1 to length(char[i]) do
            val = 256
            total = 0
            for z = 1 to length (char[i][q]) do
                val = val / 2
                if char[i][q][z] = 1 then
                    total = total + val
                end if
            end for
            default_charset[i] = default_charset[i] & total
        end for
        for p = 1 to cnt do
            default_charset[i] = default_charset[i] & 0
        end for
    end for
    default_charset = prepend(default_charset, {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0})

end procedure


global procedure add_font(integer char, sequence pattern)
    object    lowMem
    sequence  inReg, outReg

    if config[NO_EGA] = TRUE then
        return
    end if

    lowMem = allocate_low( length( pattern ) )   -- get memory
    poke( lowMem, pattern )               -- move description to memory
    inReg = repeat( 0, 10 )               -- initialize register list
    inReg[REG_AX] = #1100                 -- new char function
    inReg[REG_BX] = 16 * 256              -- 16 bytes/char - for 256 characters
    inReg[REG_CX] = 1                     -- number of characters to change
    inReg[REG_DX] = char                  -- first character to change
    inReg[REG_ES] = floor(lowMem / 16)    -- segment of low_mem (low memory)
    inReg[REG_BP] = remainder(lowMem, 16) -- offset of low_mem
    wait_retrace()
    outReg = dos_interrupt( #10, inReg )  -- bios call
    free_low( lowMem )                    -- free the memory
end procedure


global procedure add_all_fonts(integer offset, sequence pat2)
    object    lowMem
    sequence  inReg, outReg, pattern

    if config[NO_EGA] = TRUE then
        return
    end if

    pattern = {}
    -- there's probably a more efficient way to do this \/
    for z = 1 to length(pat2) do
        for a = 1 to 16 do
            pattern = append(pattern, pat2[z][a])
        end for
    end for
    lowMem = allocate_low( length( pattern ) )   -- get memory
    poke( lowMem, pattern )         -- move all fonts descriptions to memory
    inReg = repeat( 0, 10 )         -- initialize register list
    inReg[REG_AX] = #1100           -- new char function
    inReg[REG_BX] = 16 * 256        -- 16 bytes/char - for 256 characters
    inReg[REG_CX] = length(pat2)        -- number of characters to change
    inReg[REG_DX] = offset               -- first character to change
    inReg[REG_ES] = floor(lowMem / 16)    -- segment of low_mem (low memory)
    inReg[REG_BP] = remainder(lowMem, 16) -- offset of low_mem
    outReg = dos_interrupt( #10, inReg )  -- bios call
    free_low( lowMem )  -- free the memory

end procedure


global function pattern_to_binary(sequence pattern)
    integer accum
    -- replace pattern with bits
    for i = 1 to length(pattern) do
        -- convert to binary
        accum = 0
        if pattern[i][1] != 0 then accum = accum + 128       end if
        if pattern[i][2] != 0 then accum = accum + 64        end if
        if pattern[i][3] != 0 then accum = accum + 32        end if
        if pattern[i][4] != 0 then accum = accum + 16        end if
        if pattern[i][5] != 0 then accum = accum + 8         end if
        if pattern[i][6] != 0 then accum = accum + 4         end if
        if pattern[i][7] != 0 then accum = accum + 2         end if
        if pattern[i][8] != 0 then accum = accum + 1         end if
        -- replace with number
        pattern[i] = accum
    end for
    return pattern
end function


global procedure font( integer char, sequence pattern )

    if config[NO_EGA] = TRUE then
        return
    end if

    add_font(char, pattern_to_binary(pattern))

end procedure

-- font code ends


-- trim()
-- trim a text string of spaces or nulls on both ends.
global function trim(sequence tt)

    return(ltrim(rtrim(tt)))      -- give the result

end function


procedure load_config()

    atom ff
    object cfg

    ff = open("zig.cfg", "r")
    if ff != -1 then
        cfg = get(ff)
        close(ff)
    else
        config = DEFAULT_CONFIG
        return
    end if

    if sequence(cfg) then
        config = cfg[2]
    end if

end procedure


procedure save_config()

    atom ff

    ff = open("zig.cfg", "w")
    if ff != -1 then
        print(ff, config)
        close(ff)
    end if

end procedure


procedure outro()

    sequence plobe

    text_color(7)
    bk_color(0)
    clear_screen()

    plobe = "Thank you for using ZIG v" & VERSION & "."
    puts(1, "\n" & repeat(' ', 40 - (length(plobe) / 2)) & repeat('-', length(plobe)) & "\n")
    text_color(15)
    puts(1, repeat(' ', 40 - (length(plobe) / 2)) & plobe)
    text_color(7)
    puts(1, "\n" & repeat(' ', 40 - (length(plobe) / 2)) & repeat('-', length(plobe)) & "\n")

    puts(1, "\n\n\t(C) " & COPYRIGHT & ", Jacob Hammond / The ZIG Project.")
    puts(1, "\n\tReleased under Interactive Fantasies.")
    puts(1, "\n\tOfficial webpage:\thttp://surf.to/zig")
    puts(1, "\n\tOr:              \thttp://lightning.prohosting.com/~zig/")
    puts(1, "\n\tIF webpage:      \thttp://hydra78.tripod.com/")
    puts(1, "\n\n\tE-mail:          \tzig16@hotmail.com")
    if config[RUN_TIMES] = 1 then
        puts(1, "\n\n\tZIG has been run 1 time.")
    else printf(1, "\n\n\tZIG has been run a total of %d times.", config[RUN_TIMES])
    end if

end procedure



procedure cleanup_and_exit(atom ec)

    cursor(UNDERLINE_CURSOR)

    if config[SOUND_ON] = TRUE then
        close_modwave()
    end if

    -- unload data - probably unneccesary
    world = {}
    backup_world = {}

    load_rom_font()

    save_config()

    if graphics_mode(-1) then
        puts(1, "\nCouldn't restore original display mode\n\n")
    end if

    if chdir(this_dir) then
        puts(1, "\nCouldn't change to original directory\n\n")
    end if

    outro()

    abort(ec)

end procedure


procedure reset_world()
    -- zig is 1337
    if length(backup_world) then
        world = backup_world
        backup_world = {}
    end if
    
    sidebar = ON

end procedure


procedure store_world()

    backup_world = world

end procedure


function board_in_range(atom boardnum)

    if length(world[WRLD_BOARDS]) >= boardnum
    and boardnum > 0 then
        return(1)
    else return(0)
    end if

end function


function object_in_range(atom boardnum, atom obj)

    if not SAFETY then
        return(1)
    end if

    if obj > 0 and obj <= length(world[WRLD_BOARDS][boardnum][BRD_OBJECTS]) then
        return(1)
    else return(0)
    end if
end function


procedure new_board(atom where_at)

    --if not board_in_range(where_at) then
    --    return
    --end if

    if where_at < 1 then
        world[WRLD_BOARDS] = append(world[WRLD_BOARDS], NEW_BOARD)
    else
        if where_at = 1 then
            world[WRLD_BOARDS] = prepend(world[WRLD_BOARDS], NEW_BOARD)
        elsif where_at >= length(world[WRLD_BOARDS]) then
            world[WRLD_BOARDS] = append(world[WRLD_BOARDS], NEW_BOARD)
        else
            world[WRLD_BOARDS] =
                world[WRLD_BOARDS][1..where_at - 1]
                & {NEW_BOARD}
                & world[WRLD_BOARDS][where_at..length(world[WRLD_BOARDS])]
        end if
    end if

end procedure


procedure clear_board(atom boardnum)

    world[WRLD_BOARDS][boardnum] = NEW_BOARD

end procedure


procedure delete_board(atom boardnum)

    if board_in_range(boardnum) then
        if boardnum = 1 then
            if length(world[WRLD_BOARDS]) > 1 then
                world[WRLD_BOARDS] = world[WRLD_BOARDS][2..length(world[WRLD_BOARDS])]
            end if
        elsif boardnum = length(world[WRLD_BOARDS]) then
            world[WRLD_BOARDS] = world[WRLD_BOARDS][1..length(world[WRLD_BOARDS]) - 1]
        else
            world[WRLD_BOARDS] = world[WRLD_BOARDS][1..boardnum - 1] & world[WRLD_BOARDS][boardnum + 1..length(world[WRLD_BOARDS])]
        end if
    end if

end procedure


function eget(atom boardnum, atom x, atom y, atom layer, atom item)

    return(world[WRLD_BOARDS][boardnum][BRD_DATA][calc_board_geometry(boardnum, x, y, layer, item)])

end function


procedure eset(atom boardnum, atom x, atom y, atom layer, atom item, atom val)

    world[WRLD_BOARDS][boardnum][BRD_DATA][calc_board_geometry(boardnum, x, y, layer, item)] = val

end procedure


function new_object(atom boardnum)

    world[WRLD_BOARDS][boardnum][BRD_OBJECTS] = append(world[WRLD_BOARDS][boardnum][BRD_OBJECTS], NEW_OBJECT)

    return(length(world[WRLD_BOARDS][boardnum][BRD_OBJECTS]))

end function


procedure clear_object(atom boardnum, atom obj)

    world[WRLD_BOARDS][boardnum][BRD_OBJECTS][obj] = NEW_OBJECT

end procedure


procedure delete_object(atom boardnum, atom obj)

    if object_in_range(boardnum, obj) and obj > 0 then
        if obj = 1 then
            if length(world[WRLD_BOARDS][boardnum][BRD_OBJECTS]) = 1 then
                world[WRLD_BOARDS][boardnum][BRD_OBJECTS] = {}
            else
                world[WRLD_BOARDS][boardnum][BRD_OBJECTS] =
                        world[WRLD_BOARDS][boardnum][BRD_OBJECTS][2..
                        length(world[WRLD_BOARDS][boardnum][BRD_OBJECTS])]
            end if
        elsif obj = length(world[WRLD_BOARDS][boardnum][BRD_OBJECTS]) then
            world[WRLD_BOARDS][boardnum][BRD_OBJECTS] =
                    world[WRLD_BOARDS][boardnum][BRD_OBJECTS][1..
                    length(world[WRLD_BOARDS][boardnum][BRD_OBJECTS]) - 1]
        else
            world[WRLD_BOARDS][boardnum][BRD_OBJECTS] =
                    world[WRLD_BOARDS][boardnum][BRD_OBJECTS][1..obj - 1] &
                    world[WRLD_BOARDS][boardnum][BRD_OBJECTS][obj + 1..
                    length(world[WRLD_BOARDS][boardnum][BRD_OBJECTS])]
        end if
    end if
end procedure


function ge_delete_object(sequence o, atom obj)

    if obj = 1 then
        if length(o) = 1 then
            o = {}
        else
            o = o[2..length(o)]
        end if

    elsif obj = length(o) then
        o = o[1..length(o) - 1]

    else
        o = o[1..obj - 1] & o[obj + 1..length(o)]

    end if

    return(o)

end function


function oget(atom boardnum, atom obj, atom element)

    if SAFETY then
        if board_in_range(boardnum) then
            if object_in_range(boardnum, obj) then
                if element > 0 and element <= NUM_OBJ_PARAMS then
                    return(world[WRLD_BOARDS][boardnum][BRD_OBJECTS][obj][1][element])
                end if
            end if
        end if
    else
        return(world[WRLD_BOARDS][boardnum][BRD_OBJECTS][obj][1][element])
    end if

end function


procedure oset(atom boardnum, atom obj, atom element, object val)

    if SAFETY then
        if board_in_range(boardnum) then
            if object_in_range(boardnum, obj) then
                if element > 0 and element <= NUM_OBJ_PARAMS then
                    world[WRLD_BOARDS][boardnum][BRD_OBJECTS][obj][1][element] = val
                end if
            end if
        end if
    else
        world[WRLD_BOARDS][boardnum][BRD_OBJECTS][obj][1][element] = val
    end if

end procedure


function coords_in_range(atom board, atom x, atom y)

    if x < 1
    or y < 1
    or x > world[WRLD_BOARDS][board][BRD_SIZEX]
    or y > world[WRLD_BOARDS][board][BRD_SIZEY] then
        return(FALSE)
    else return(TRUE)
    end if

end function


function find_object(atom board, atom x, atom y, atom layer)

    if board_in_range(board) then
        for z = 1 to length(world[WRLD_BOARDS][board][BRD_OBJECTS]) do
            if oget(board, z, OBJ_X) = x then
                if oget(board, z, OBJ_Y) = y then
                    if oget(board, z, OBJ_LAYER) = layer then
                        return(z)
                    end if
                end if
            end if
        end for
    end if

    return(0)

end function


function find_object_by_name(sequence obj, sequence name)

    name = lower(name)

    for z = 1 to length(obj) do
        if compare(name, lower(obj[z][1][OBJ_NAME])) = 0 then
            return(z)
        end if
    end for

    return(0)

end function


global procedure box(atom X1, atom Y1, atom X2, atom Y2, atom BoxColor, sequence Cap)

    atom ISizeX, ISizeY
    sequence PutLine1, PutLine2, Spaces

    ISizeX = (X2 - X1) - 2
    ISizeY = (Y2 - Y1) - 1
    PutLine1 = repeat(H, ISizeY)
    PutLine1 = prepend(PutLine1, UL)
    PutLine1 = append(PutLine1, UR)
    PutLine2 = repeat(H, ISizeY)
    PutLine2 = prepend(PutLine2, LL)
    PutLine2 = append(PutLine2, LR)
    Spaces = repeat(32, ISizeY)
    Spaces = prepend(Spaces, V)  Spaces = append(Spaces, V)

    text_color(14)
    bk_color(BoxColor)
    position(X1, Y1)
    puts(1, PutLine1)
    position(X2, Y1)
    puts(1, PutLine2)

    for X = X1 + 1 to X2 - 1 do
        position(X, Y1)
        puts(1, Spaces)
    end for

    if length(Cap) then
        text_color(15)
        bk_color(BoxColor)
        --position(X1, Y1 + ((Y2 - Y1) / 2) - (length(Cap) / 2))
        position(X1, Y1 + 2)
        puts(1, " " & Cap & " ")
    end if

end procedure


procedure loader_window(sequence c)
    if sidebar then
        box(6, 10, 18, 50, 7, c)
    else
        box(6, 20, 18, 60, 7, c)   
    end if
end procedure


procedure loader_print(sequence t)
    
    sequence ss
    
    ss = save_text_image({8, 11}, {17, 49})
    display_text_image({7, 11}, ss)
    
    if length(t) > 38 then
        t = t[1..38]
    end if
    
    text_color(0)
    bk_color(7)
    if sidebar then
        position(17, 11)
    else position(17, 21)
    end if
    puts(1, t & repeat(32, 38 - length(t)))
    
end procedure


procedure save_object(atom file, sequence obj)

    puts(file, int_to_bytes(length(obj)))

    if length(obj) != 0 then

        print(file, obj[1])
        puts(file, 0)

        for z = 2 to length(obj) do
            puts(file, length(obj[z]))
            for a = 1 to length(obj[z]) do
                puts(file, obj[z][a])
            end for
        end for
    end if

    puts(file, 0)

end procedure


function load_object(atom file)

    atom objlen, linelen
    sequence obj, buf

    objlen = get_int4(file)
    obj = {}

    for z = 1 to objlen do
        if z = 1 then
            buf = get(file)
            buf = buf[2]
        else
            linelen = getc(file)
            buf = {}
            for a = 1 to linelen do
                buf = buf & getc(file)
            end for
        end if
        obj = append(obj, buf)
    end for

    linelen = getc(file)        -- junk

    return(obj)

end function


procedure save_board(atom file, sequence board)

        puts(file, int_to_bytes(board[BRD_SIZEX]))
        puts(file, int_to_bytes(board[BRD_SIZEY]))
        puts(file, int_to_bytes(board[BRD_LAYERS]))
        puts(file, length(board[BRD_NAME]))
        puts(file, board[BRD_NAME])
        puts(file, int_to_bytes(board[BRD_EXITN]))
        puts(file, int_to_bytes(board[BRD_EXITS]))
        puts(file, int_to_bytes(board[BRD_EXITE]))
        puts(file, int_to_bytes(board[BRD_EXITW]))

        puts(file, length(board[BRD_PAL]))
        if length(board[BRD_PAL]) then
            for d = 1 to length(board[BRD_PAL]) do
                for c = 1 to 3 do
                    puts(file, board[BRD_PAL][d][c])
                end for
            end for
        end if

        puts(file, int_to_bytes(length(board[BRD_CHARSET])))
        if length(board[BRD_CHARSET]) then
            puts(file, length(board[BRD_CHARSET][1]))
            for d = 1 to length(board[BRD_CHARSET]) do
                for c = 1 to length(board[BRD_CHARSET][d]) do
                    puts(file, board[BRD_CHARSET][d][c])
                end for
            end for
        end if

        puts(file, length(board[BRD_MUSICFILE]))
        puts(file, board[BRD_MUSICFILE])

        puts(file, int_to_bytes(length(board[BRD_DATA])))
        puts(file, board[BRD_DATA])

        puts(file, 0)
        save_object(file, board[BRD_CTROBJ])
        puts(file, 0)

        puts(file, int_to_bytes(length(board[BRD_OBJECTS])))

        for z = 1 to length(board[BRD_OBJECTS]) do
            save_object(file, board[BRD_OBJECTS][z])
        end for

        puts(file, 0)

end procedure


procedure save_world(atom file)

    atom a

    puts(file, DEF_HEADER)

    puts(file, length(world[WRLD_NAME]))
    puts(file, world[WRLD_NAME])
    puts(file, int_to_bytes(world[WRLD_TITLEBRD]))
    puts(file, int_to_bytes(world[WRLD_STARTBRD]))
    puts(file, length(world[WRLD_FILENAME]))
    puts(file, world[WRLD_FILENAME])

    puts(file, world[WRLD_SBAUTO])
    puts(file, world[WRLD_HEALTHEND])
    
    puts(file, int_to_bytes(length(world[WRLD_BOARDS])))

    a = seek(file, 512)

    for z = 1 to length(world[WRLD_BOARDS]) do
        puts(file, int_to_bytes(z))
        save_board(file, world[WRLD_BOARDS][z])
    end for

    puts(1, 0 & "ZWF2-EOF" & 27)

end procedure


procedure old_save_world(atom file)

    print(file, world)

end procedure


function old_load_world(atom file)

    sequence a

    a = get(file)
    return(a[2])

end function


function get_uns(atom f)

    atom a

    a = getc(f)
    return(a)

end function


function load_board(atom f, sequence board)

        object a
        
        loader_print("Reading board headers.")
        board[BRD_SIZEX] = get_int4(f)
        board[BRD_SIZEY] = get_int4(f)
        board[BRD_LAYERS] = get_int4(f)
        board[BRD_NAME] = get_lpstr(f)
        board[BRD_EXITN] = get_int4(f)
        board[BRD_EXITS] = get_int4(f)
        board[BRD_EXITE] = get_int4(f)
        board[BRD_EXITW] = get_int4(f)

        a = getc(f)
        if a != 0 then
            board[BRD_PAL] = repeat({0, 0, 0}, a)
            for d = 1 to a do
                for c = 1 to 3 do
                    board[BRD_PAL][d][c] = getc(f)
                end for
            end for
        else
            board[BRD_PAL] = {}
        end if

        a = get_int4(f)
        if a != 0 then
            a = {a, getc(f)}
            board[BRD_CHARSET] = repeat(repeat(0, a[2]), a[1])
            for d = 1 to length(board[BRD_CHARSET]) do
                for c = 1 to length(board[BRD_CHARSET][d]) do
                    board[BRD_CHARSET][d][c] = getc(f)
                end for
            end for
        else
            board[BRD_CHARSET] = {}
        end if

        board[BRD_MUSICFILE] = get_lpstr(f)

        loader_print("Reading data.")
        a = get_int4(f)
        board[BRD_DATA] = get_bytes(f, a)

        loader_print("Reading objects.")
        a = getc(f)
        board[BRD_CTROBJ] = load_object(f)
        a = getc(f)

        a = get_int4(f)
        board[BRD_OBJECTS] = repeat({}, a)

        for z = 1 to a do
            board[BRD_OBJECTS][z] = load_object(f)
        end for

        a = getc(f)

        return(board)

end function


function load_f1_board(atom f, sequence board)

        object a

        board[BRD_MUSICFILE] = {}

        board[BRD_SIZEX] = get_int4(f)
        board[BRD_SIZEY] = get_int4(f)
        board[BRD_LAYERS] = get_int4(f)
        board[BRD_NAME] = get_lpstr(f)
        board[BRD_EXITN] = get_int4(f)
        board[BRD_EXITS] = get_int4(f)
        board[BRD_EXITE] = get_int4(f)
        board[BRD_EXITW] = get_int4(f)

        a = getc(f)
        if a != 0 then
            board[BRD_PAL] = repeat({0, 0, 0}, a)
            for d = 1 to a do
                for c = 1 to 3 do
                    board[BRD_PAL][d][c] = getc(f)
                end for
            end for
        else
            board[BRD_PAL] = {}
        end if

        a = get_int4(f)
        if a != 0 then
            a = {a, getc(f)}
            board[BRD_CHARSET] = repeat(repeat(0, a[2]), a[1])
            for d = 1 to length(board[BRD_CHARSET]) do
                for c = 1 to length(board[BRD_CHARSET][d]) do
                    board[BRD_CHARSET][d][c] = getc(f)
                end for
            end for
        else
            board[BRD_CHARSET] = {}
        end if

        a = get_int4(f)
        board[BRD_DATA] = get_bytes(f, a)

        a = getc(f)
        board[BRD_CTROBJ] = get_uns(f)
        board[BRD_OBJECTS] = get_uns(f)

        return(board)

end function


function load_f2_board(atom f, sequence board)

        object a

        board[BRD_SIZEX] = get_int4(f)
        board[BRD_SIZEY] = get_int4(f)
        board[BRD_LAYERS] = get_int4(f)
        board[BRD_NAME] = get_lpstr(f)
        board[BRD_EXITN] = get_int4(f)
        board[BRD_EXITS] = get_int4(f)
        board[BRD_EXITE] = get_int4(f)
        board[BRD_EXITW] = get_int4(f)

        a = getc(f)
        if a != 0 then
            board[BRD_PAL] = repeat({0, 0, 0}, a)
            for d = 1 to a do
                for c = 1 to 3 do
                    board[BRD_PAL][d][c] = getc(f)
                end for
            end for
        else
            board[BRD_PAL] = {}
        end if

        a = get_int4(f)
        if a != 0 then
            a = {a, getc(f)}
            board[BRD_CHARSET] = repeat(repeat(0, a[2]), a[1])
            for d = 1 to length(board[BRD_CHARSET]) do
                for c = 1 to length(board[BRD_CHARSET][d]) do
                    board[BRD_CHARSET][d][c] = getc(f)
                end for
            end for
        else
            board[BRD_CHARSET] = {}
        end if

        board[BRD_MUSICFILE] = get_lpstr(f)

        a = get_int4(f)
        board[BRD_DATA] = get_bytes(f, a)

        a = getc(f)
        board[BRD_CTROBJ] = get_uns(f)
        board[BRD_OBJECTS] = get_uns(f)

        return(board)

end function


include zig_libs.e        -- library functions


global function old_index(atom x, atom y, atom l, atom i)
    atom ret

    ret = ((x - 1) * 540) + ((y - 1) * 9) + ((l - 1) * 3) + (i - 1)
    if ret = 0 then
        ret = 1
    end if

    return(ret)
end function

-- return a {char,color} from {code,color} - translate from ZZT codes
function zzt_translate_code(sequence cc)

    if cc[1] = #01 then cc[1] = #00
    elsif cc[1] = #04 then cc[1] = #02
    elsif cc[1] = #05 then cc[1] = #84
    elsif cc[1] = #06 then cc[1] = #9D
    elsif cc[1] = #07 then cc[1] = #04
    elsif cc[1] = #08 then cc[1] = #0C
    elsif cc[1] = #09 then cc[1] = #0A
    elsif cc[1] = #0A then cc[1] = #E8
    elsif cc[1] = #0B then cc[1] = #F0
    elsif cc[1] = #0C then cc[1] = 'O'
    elsif cc[1] = #0D then cc[1] = #0B
    elsif cc[1] = #0E then cc[1] = #7F
    elsif cc[1] = #0F then cc[1] = '/'
    elsif cc[1] = #10 then cc[1] = '\\'
    elsif cc[1] = #11 then cc[1] = '\\'
    elsif cc[1] = #12 then cc[1] = #F8
    elsif cc[1] = #13 then cc[1] = #B0
    elsif cc[1] = #14 then cc[1] = #B0
    elsif cc[1] = #15 then cc[1] = #DB
    elsif cc[1] = #16 then cc[1] = #B2
    elsif cc[1] = #17 then cc[1] = #B1
    elsif cc[1] = #18 then cc[1] = #FE
    elsif cc[1] = #19 then cc[1] = #12
    elsif cc[1] = #1A then cc[1] = #1D
    elsif cc[1] = #1B then cc[1] = #B2 cc = append(cc, 1)
    elsif cc[1] = #1C then cc[1] = #00
    elsif cc[1] = #1D then cc[1] = '|'
    elsif cc[1] = #1E then cc[1] = ')'
    elsif cc[1] = #1F then cc[1] = '+'
    elsif cc[1] = #20 then cc[1] = #2A
    elsif cc[1] = #21 then cc[1] = #CD
    elsif cc[1] = #22 then cc[1] = #99
    elsif cc[1] = #23 then cc[1] = #05
    elsif cc[1] = #24 then cc[1] = #01
    elsif cc[1] = #25 then cc[1] = #2A
    elsif cc[1] = #26 then cc[1] = #5E
    elsif cc[1] = #27 then cc[1] = ''
    elsif cc[1] = #28 then cc[1] = '>'
    elsif cc[1] = #29 then cc[1] = #EA
    elsif cc[1] = #2A then cc[1] = #E3
    elsif cc[1] = #2B then cc[1] = #BA
    elsif cc[1] = #2C then cc[1] = #E9
    elsif cc[1] = #2D then cc[1] = #4F

    elsif cc[1] = #2F then cc[1] = cc[2] cc[2] = #1F
    elsif cc[1] = #30 then cc[1] = cc[2] cc[2] = #2F
    elsif cc[1] = #31 then cc[1] = cc[2] cc[2] = #3F
    elsif cc[1] = #32 then cc[1] = cc[2] cc[2] = #4F
    elsif cc[1] = #33 then cc[1] = cc[2] cc[2] = #5F
    elsif cc[1] = #34 then cc[1] = cc[2] cc[2] = #6F
    elsif cc[1] = #35 then cc[1] = cc[2] cc[2] = #0F

    end if

    return(cc)

end function


procedure zl_add_line(atom b, atom o, sequence a)
    world[WRLD_BOARDS][b][BRD_OBJECTS][o] = append(world[WRLD_BOARDS][b][BRD_OBJECTS][o], a)
end procedure


function find_in_lib(sequence a)
    
    a = lower(a)
    
    for z = 1 to length(object_library) do
        if compare(lower(object_library[z][LIB_NAME]), a) = 0 then
            return(z)
        end if
    end for
    
    return(0)
    
end function


function load_zzt_world(sequence file)

    atom f, size, count, code, color, cx, cy, nboards, zx, zy, oc, ut, uc
    sequence ccc, ascii_set
    object d
    
    loader_window("Importing ZZT world")
    
    loader_print("ZZT loader started.")

    loader_print("Reading ascii.zch:")
    f = open("ascii.zch", "rb")
    if f != -1 then
        ascii_set = load_charset(f)
        loader_print("ascii.zch successfully loaded.")
    else
        ascii_set = system_charset
        loader_print("ascii.zch could not be loaded, using")
        loader_print("default character set instead.")
    end if
    close(f)
    
    -- open the file
    f = open(file, "rb")
    loader_print("Opening file: " & file)
    
    -- clear the world
    clear_world()
    loader_print("Clearing existing data.")

    -- if the file exists...    
    if f > 0 then       -- then begin loading

        loader_print("File exists.")
        
        -- get the header
        d = get_bytes(f, 2)
        -- and check it
        if compare(d, {#FF, #FF}) != 0 then      -- not a ZZT world
            loader_print("Invalid header!")
            close(f)    -- end
            return(2)
        end if
        loader_print("Valid header.")

        nboards = get_int2(f)     -- # of boards (zero-based)
        nboards = nboards + 1     -- make it the actual number
        -- define the boards
        world[WRLD_BOARDS] = repeat(NEW_BOARD, nboards)
        loader_print("Board count: " & sprintf("%d", nboards))
        
        -- skip other headers
        loader_print("Skipping other headers.")
        d = seek(f, #1D)

        d = getc(f)     -- title length
        world[WRLD_NAME] = get_bytes(f, d)
        loader_print("World title: " & world[WRLD_NAME])
        d = seek(f, #32)
        
        -- skip more headers - skip to start of boards
        d = seek(f, #200)
        loader_print("Seeking to board start.")
        
        for b = 1 to nboards do -- for all boards
        
            loader_print("Loading board " & sprintf("%d", b))

            world[WRLD_BOARDS][b][BRD_CHARSET] = ascii_set

            size = get_int2(f)  -- board size
            loader_print("Data size: " & sprintf("%d", size))
            count = getc(f)     -- length of title
            d = get_bytes(f, #20)   -- get the title
            if count > #20 then count = #20 end if
            world[WRLD_BOARDS][b][BRD_NAME] = d[1..count]
            loader_print("Title: " & d[1..count])
            d = get_bytes(f, 15)    -- padding

            -- start reading blocks
            cx = 1  -- current x 
            cy = 1  -- current y
            for z = 1 to 15000 do
                count = getc(f)
                code = getc(f)
                color = getc(f)
                ccc = zzt_translate_code({code, color})
                code = ccc[1]
                color = ccc[2]
                if length(ccc) = 3 then oc = 1
                else oc = 2
                end if
                for a = 1 to count do
                    eset(b, cx, cy, oc, BRD_TILECHAR, code)
                    eset(b, cx, cy, oc, BRD_TILECOLOR, color)
                    cy = cy + 1
                    if cy > 60 then
                        cy = 1
                        cx = cx + 1
                        if cx > 25 then
                            exit
                        end if
                    end if
                end for
                if cx > 25 then
                    exit
                end if
            end for
            
            d = seek(f, where(f) + 2)
            code = getc(f)
            if code != 0 then code = code + 1 end if
            world[WRLD_BOARDS][b][BRD_EXITN] = code

            code = getc(f)
            if code != 0 then code = code + 1 end if
            world[WRLD_BOARDS][b][BRD_EXITS] = code
            
            code = getc(f)
            if code != 0 then code = code + 1 end if
            world[WRLD_BOARDS][b][BRD_EXITW] = code
            
            code = getc(f)
            if code != 0 then code = code + 1 end if
            world[WRLD_BOARDS][b][BRD_EXITE] = code
            
            
            
            d = seek(f, where(f) + #50)

            count = get_int2(f)     -- # objects
            loader_print("")
            
            for z = 1 to count + 1 do
                position(17, 11)
                printf(1, "Object %d of %d  ", {z, count + 1})
                zy = getc(f)
                zx = getc(f)
                d = seek(f, where(f) + 6)
                code = getc(f)
                d = seek(f, where(f) + 6)
                ut = getc(f)
                uc = getc(f)
                d = seek(f, where(f) - 8)
                ccc = zzt_translate_code({ut, uc})
                if zx != 0 and zy != 0 then
                    --
                    -- Object or scroll
                    --
                    eset(b, zx, zy, 1, BRD_TILECHAR, ccc[1])
                    eset(b, zx, zy, 1, BRD_TILECOLOR, ccc[2])
                    if eget(b, zx, zy, 2, BRD_TILECHAR) = 1
                    or eget(b, zx, zy, 2, BRD_TILECHAR) = 232 then
                        oc = new_object(b)
                        oset(b, oc, OBJ_X, zx)
                        oset(b, oc, OBJ_Y, zy)
                        oset(b, oc, OBJ_LAYER, 2)
                        if eget(b, zx, zy, 2, BRD_TILECHAR) = 232 then
                            oset(b, oc, OBJ_CHAR, 232)
                        else oset(b, oc, OBJ_CHAR, code)
                        end if
                        oset(b, oc, OBJ_COLOR, eget(b, zx, zy, 2, BRD_TILECOLOR))
                        
                        d = seek(f, where(f) + #E)
                        code = get_int2(f)
                        d = seek(f, where(f) + 8)
                        ccc = get_bytes(f, code)
                        d = {}
                        cx = 1
                        if length(ccc) = 0 then
                            eset(b, zx, zy, 2, BRD_TILECHAR, oget(b, oc, OBJ_CHAR))
                            eset(b, zx, zy, 2, BRD_TILECOLOR, oget(b, oc, OBJ_COLOR))
                            delete_object(b, oc)
                        else
                            if eget(b, zx, zy, 2, BRD_TILECHAR) = 232 then
                                zl_add_line(b, oc, "#end")
                                zl_add_line(b, oc, ":touch")
                            end if
                            for a = 1 to length(ccc) do
                                if a = length(ccc) then
                                    zl_add_line(b, oc, d)
                                    d = {}
                                    exit
                                end if
                                if ccc[a] = 10
                                or ccc[a] = 13 then
                                    zl_add_line(b, oc, d)
                                    d = {}
                                else
                                    d = d & ccc[a]
                                end if
                            end for
                            if eget(b, zx, zy, 2, BRD_TILECHAR) = 232 then
                                zl_add_line(b, oc, "#die")
                            end if
                            eset(b, zx, zy, 2, BRD_TILECHAR, 0)
                        end if
                    else
                        --
                        -- Passage
                        --
                        if eget(b, zx, zy, 2, BRD_TILECHAR) = 240 then
                            oc = new_object(b)
                            oset(b, oc, OBJ_X, zx)
                            oset(b, oc, OBJ_Y, zy)
                            oset(b, oc, OBJ_LAYER, 2)
                            oset(b, oc, OBJ_CHAR, 240)
                            eset(b, zx, zy, 2, BRD_TILECHAR, 0)
                            oset(b, oc, OBJ_COLOR, eget(b, zx, zy, 2, BRD_TILECOLOR))
                            code = getc(f)
                            code = getc(f) + 1
                            zl_add_line(b, oc, "#end")
                            zl_add_line(b, oc, ":touch")
                            zl_add_line(b, oc, "#transport " & sprintf("%d", code))
                            zl_add_line(b, oc, "#end")
                            d = seek(f, where(f) + #C)
                        elsif eget(b, zx, zy, 2, BRD_TILECHAR) = 2 then
                        --
                        -- Player
                        --
                            oc = new_object(b)
                            oset(b, oc, OBJ_X, zx)
                            oset(b, oc, OBJ_Y, zy)
                            oset(b, oc, OBJ_LAYER, 2)
                            oset(b, oc, OBJ_CHAR, 2)
                            eset(b, zx, zy, 2, BRD_TILECHAR, 0)
                            oset(b, oc, OBJ_COLOR, 31)
                            count = find_in_lib("player")
                            if count then
                                for zee = 1 to length(object_library[count][LIB_PROG]) do
                                    zl_add_line(b, oc, object_library[count][LIB_PROG][zee])
                                end for
                            else
                                zl_add_line(b, oc, "@player")
                                zl_add_line(b, oc, "#cycle 1")
                                zl_add_line(b, oc, "#focus")
                                zl_add_line(b, oc, ":loop")
                                zl_add_line(b, oc, "#if keyb up then /n")
                                zl_add_line(b, oc, "#if keyb down then /s")
                                zl_add_line(b, oc, "#if keyb left then /w")
                                zl_add_line(b, oc, "#if keyb right then /e")
                                zl_add_line(b, oc, "#loop")
                            end if
                            d = seek(f, where(f) + #E)
                        elsif eget(b, zx, zy, 2, BRD_TILECHAR) = 12 then
                        --
                        -- Key
                        --
                            if find_in_lib("key") then
                                ut = find_in_lib("key")
                                oc = new_object(b)
                                oset(b, oc, OBJ_X, zx)
                                oset(b, oc, OBJ_Y, zy)
                                oset(b, oc, OBJ_LAYER, 2)
                                oset(b, oc, OBJ_CHAR, object_library[ut][LIB_CHAR])
                                oset(b, oc, OBJ_COLOR, eget(b, zx, zy, 2, BRD_TILECOLOR))
                                oset(b, oc, OBJ_LIBFROM, object_library[ut][LIB_FROM])
                                eset(b, zx, zy, 2, BRD_TILECHAR, 0)
                                for zz = 1 to length(object_library[ut][LIB_PROG]) do
                                    zl_add_line(b, oc, object_library[ut][LIB_PROG][zz])
                                end for
                            end if
                        elsif eget(b, zx, zy, 2, BRD_TILECHAR) = '„' then
                        --
                        -- Ammo
                        --
                            if find_in_lib("ammo") then
                                ut = find_in_lib("ammo")
                                oc = new_object(b)
                                oset(b, oc, OBJ_X, zx)
                                oset(b, oc, OBJ_Y, zy)
                                oset(b, oc, OBJ_LAYER, 2)
                                oset(b, oc, OBJ_CHAR, object_library[ut][LIB_CHAR])
                                oset(b, oc, OBJ_COLOR, eget(b, zx, zy, 2, BRD_TILECOLOR))
                                oset(b, oc, OBJ_LIBFROM, object_library[ut][LIB_FROM])
                                oset(b, oc, OBJ_PROPS, {5})
                                eset(b, zx, zy, 2, BRD_TILECHAR, 0)
                                for zz = 1 to length(object_library[ut][LIB_PROG]) do
                                    zl_add_line(b, oc, object_library[ut][LIB_PROG][zz])
                                end for
                            end if
                        
                        else d = seek(f, where(f) + #E)
                        end if
                        
                        code = get_int2(f)  -- data len
                        d = seek(f, where(f) + (code + 8))
                    end if
                else
                    d = seek(f, where(f) + #E)
                    code = get_int2(f)  -- data len
                    d = seek(f, where(f) + (code + 8))
                end if
            end for

        end for

    else

        loader_print("File does not exist.")
        close(f)
        return(1)

    end if

    loader_print("Import complete!")

    close(f)
    return(0)

end function


function load_v10_world(atom f)

    object aa
    sequence wp
    atom boards

    aa = seek(f, 7)
    aa = get(f)
    boards = aa[2][1]
    world[WRLD_BOARDS] = repeat(NEW_BOARD, boards)

    aa = seek(f, 13)

    for z = 1 to boards do

        world[WRLD_BOARDS][z][BRD_PAL] = system_palette
        world[WRLD_BOARDS][z][BRD_CHARSET] = system_charset

        for a = 1 to 16 do
            for b = 1 to 3 do
                world[WRLD_BOARDS][z][BRD_PAL][a][b] = getc(f)
            end for
        end for

        for a = 1 to 256 do
            for b = 1 to 16 do
                world[WRLD_BOARDS][z][BRD_CHARSET][a][b] = getc(f)
            end for
        end for

    end for

    for z = 1 to boards do
        wp = get_bytes(f, 13500)
        for x = 1 to 25 do
            for y = 1 to 60 do
                for a = 1 to 3 do
                    eset(z, x, y, a, 1, wp[old_index(x, y, a, 2)])
                    eset(z, x, y, a, 2, wp[old_index(x, y, a, 3)])
                end for
            end for
        end for
    end for

    aa = seek(f, where(f) + 10)

    return(0)

end function


function load_world(atom f, sequence fname)

    atom format_type
    object a
    sequence header, v1head
    
    fname = trim(fname)

    if compare(lower(fname[length(fname) - 3..length(fname)]), ".zzt") = 0 then
        close(f)
        return(load_zzt_world(fname))
    end if

    loader_window("Loading World")
    loader_print(fname)
    
    a = fname
    if find('\\', fname) then
        while TRUE do
            if find('\\', fname) = 0 then exit
            else
                fname = fname[find('\\', fname) + 1..length(fname)]
            end if
        end while
        a = chdir(a[1..length(a) - (length(fname) + 1)])
    end if

    header = get_bytes(f, length(DEF_HEADER))
    v1head = header[1..6]

    if compare(header, DEF_HEADER_FF1) = 0 then
        format_type = 2
        loader_print("Old format 1.")
    elsif compare(header, DEF_HEADER_FF2) = 0 then
        format_type = 3
        loader_print("Old format 2.")
    elsif compare(header, DEF_HEADER_FF3) = 0 then
        format_type = 4
        loader_print("Old format 3.")
    elsif compare(header, DEF_HEADER) = 0 then
        format_type = 1
        loader_print("Current format (standard).")
    else
        if compare(v1head, V10_HEADER) = 0 then
            loader_print("v1.0.x world.")
            format_type = 5
        else return(1)
        end if
    end if

    clear_world()

    if format_type = 5 then
        loader_print("Loading v1.0.x world.")
        return(load_v10_world(f))
    end if

    loader_print("Reading headers.")
    world[WRLD_NAME] = get_lpstr(f)
    world[WRLD_TITLEBRD] = get_int4(f)
    world[WRLD_STARTBRD] = get_int4(f)
    world[WRLD_FILENAME] = get_lpstr(f)
      
    if format_type = 1 then
        world[WRLD_SBAUTO] = get_uns(f)
        world[WRLD_HEALTHEND] = get_uns(f)
    end if
    
    world[WRLD_BOARDS] = repeat(NEW_BOARD, get_int4(f))
    loader_print(sprintf("%d boards.", length(world[WRLD_BOARDS])))

    a = seek(f, 512)
    for z = 1 to length(world[WRLD_BOARDS]) do
        loader_print("Loading board " & sprintf("%d", z))
        a = get_int4(f)
        if format_type = 2 then
            world[WRLD_BOARDS][z] = load_f1_board(f, NEW_BOARD)
        elsif format_type = 3 then
            world[WRLD_BOARDS][z] = load_f2_board(f, NEW_BOARD)
        else
            world[WRLD_BOARDS][z] = load_board(f, NEW_BOARD)
        end if
    end for

    return(0)

end function


function load_manual(atom f)

    sequence s
    object b
    
    s = {}
    while 1 do
        b = gets(f)
        if atom(b) then
            exit
        end if
        s = append(s, b[1..length(b) - 1])
    end while
    
    return(s)
    
end function


function init()

    atom f
    sequence c

    allow_break(0)
    tick_rate(100)

    load_config()
    config[RUN_TIMES] = config[RUN_TIMES] + 1
    
--    crash_file("zig.err")
--    crash_message("Sorry, an internal error has occured!\n" &
--                "Please send the file \"zig.err\" to zig16@hotmail.com.\n" &
--                "If you can, provide details about what you were doing when the crash\n" &
--               "occured, and send the world that caused the crash.")
    

    this_dir = current_dir()
    
    color_table = {"black",
                   "dkblue",
                   "dkgreen",
                   "dkcyan",
                   "dkred",
                   "dkmagenta",
                   "brown",
                   "grey",
                   "dkgrey",
                   "blue",
                   "green",
                   "cyan",
                   "red",
                   "magenta",
                   "yellow",
                   "white"}
                   
    lit_color_table = {"black",
                       "blue",
                       "green",
                       "cyan",
                       "red",
                       "magenta",
                       "brown",
                       "grey",
                       "grey",
                       "blue",
                       "green",
                       "cyan",
                       "red",
                       "magenta",
                       "yellow",
                       "white"}
                       

    Scroll_SizeX = 16
    Scroll_SizeY = 52
    Scroll_PosX = 5
    Scroll_PosY = 9
    Scroll_TextC = 14
    Scroll_BackC = 1
    Scroll_HLTitleC = 15
    Scroll_BorderC = 9

    flags = {}
    variables = {}
    stats = {}
    messages = {}

    message_x = 25
    message_y = CENTERED
    message_color = FLASHING
    message_time = 2
    next_available_message = 1
    cs_counter = 0
    r1_store = 1

    sidebar = OFF

    current_mod = {}

    first_load = TRUE

    if graphics_mode(3) then
        puts(1, "\nCouldn't initialize textmode 80x25x16!")
        return(3)
    end if

    screen_sizex = 25
    screen_sizey = 80
    sidebar_width = 20
    font_squish = FALSE

    if config[NO_EGA] = FALSE then
        video_mode(EGA)
        if not text_rows(screen_sizex) then
            puts(1, "\nBad row value")
            return(6)
        end if
        allow_all_paledit()
        blink(0)
    end if

    sound(0)
    cursor(NO_CURSOR)

    f = open("default.zpl", "rb")
    if f = -1 then return(1)
    else system_palette = load_palette(f)
        close(f)
    end if
    
    f = open("manual.txt", "r")
    if f != -1 then
        help_text = load_manual(f)
        close(f)
    end if

    load_rom_font()

    f = open("default.zch", "rb")

    if f = -1 then return(2)
    else system_charset = load_charset(f)
        close(f)
    end if

    if config[NO_EGA] = FALSE then
        set_all_pal(system_palette)
        add_all_fonts(0, system_charset)
    end if

    lib_listing = load_lib_listing()
    object_library = load_libraries(lib_listing)

    if config[SOUND_ON] = ON then
        if init_modwave(
            config[SOUND_STEREO],
            config[SOUND_FREQ],
            config[SOUND_CHANNELS]) then
            return(4)
        end if
        set_volume(MASTER, #F)
        set_volume(VOICE, #F)
    end if
    
    c = command_line()
    if length(c) > 2 then
        if find('.', c[3]) = 0 then
            c[3] = c[3] & ".zig"
        end if
        f = open(c[3], "rb")
        if f = -1 then
            return(5)
        else
            if load_world(f, c[3]) then
                return(5)
            end if
        end if
    end if

    return(0)

end function


function ty(atom h)

    return(h + (screen_sizey - 80))

end function


global function screen_save()

    return(save_text_image({1, 1}, {screen_sizex, screen_sizey}))

end function


global procedure screen_restore(sequence s)

    display_text_image({1, 1}, s)

end procedure


procedure text_at(atom x, atom y, sequence t, atom c)

    position(x, y)

    text_color(c)
    puts(1, t)

end procedure


procedure sidebar_clear()

    sequence d

    if sidebar then

        d = {}

        for z = 1 to 20 do
            d = d & {32, 31}
        end for

        display_text_image({1, ty(61)}, repeat(d, screen_sizex))

    end if

end procedure


procedure sb_print(atom x, sequence text, atom color)

    if sidebar then

        text_at(x, ty(62), text, color)

    end if

end procedure


procedure sb_print_bk(atom x, sequence text, atom fcolor, atom bcolor)

    if sidebar then

        text_color(fcolor)
        bk_color(bcolor)

        position(x, ty(62))
        puts(1, text)

    end if

end procedure


procedure sb_cenprint(atom x, sequence text, atom fcolor, atom bcolor)

    if sidebar then

        text_color(fcolor)
        bk_color(bcolor)

        position(x, ty(61) + (10 - (length(text) / 2)))
        puts(1, text)

    end if

end procedure


procedure sb_btnprint(atom x, sequence btn, sequence text, atom btncolor)

    if sidebar then

        text_color(0)
        bk_color(btncolor)

        position(x, ty(62))
        puts(1, ' ' & btn & ' ')

        text_color(14)
        bk_color(1)

        puts(1, ' ' & text)

    end if

end procedure


procedure sidebar_ge_draw_base()

    if sidebar then

        sb_cenprint(2, "úù - " & H & H & H &" - ùú", 15, 1)
        sb_cenprint(4, "úù - " & H & H & H & " - ùú", 15, 1)

        --sb_cenprint(2, " - - - - ", 15, 1)
        sb_cenprint(3, "     ZIG     ", 0, 7)
        --sb_cenprint(4, " - - - - ", 15, 1)
        sb_cenprint(24, "v" & VERSION, 7, 1)
        
        sb_btnprint(6, "F2", "Save Game", 3)
        sb_btnprint(7, "F4", "Load Game", 7)

    end if

end procedure


function get_board_chunk(atom board, atom layer, sequence coords)

    atom x1, y1, x2, y2, cnt
    sequence hunk

    x1 = coords[1][1]
    y1 = coords[1][2]
    x2 = coords[2][1]
    y2 = coords[2][2]

    if coords_in_range(board, x1, y1)
    and coords_in_range(board, x2, y2) then

        hunk = repeat(repeat(0, ((y2 - y1) + 1) * 2), (x2 - x1) + 1)

        for x = x1 to x2 do
            cnt = 1
            for y = y1 to y2 do
                hunk[x - (x1 - 1)][cnt] = eget(board, x, y, layer, BRD_TILECHAR)
                hunk[x - (x1 - 1)][cnt + 1] = eget(board, x, y, layer, BRD_TILECOLOR)
                cnt = cnt + 2
            end for
        end for
    end if

    return(hunk)

end function


procedure set_board_chunk(atom board, atom layer, sequence coords, atom char, atom color)

    atom x1, y1, x2, y2

    x1 = coords[1][1]
    y1 = coords[1][2]
    x2 = coords[2][1]
    y2 = coords[2][2]

    if coords_in_range(board, x1, y1)
    and coords_in_range(board, x2, y2) then

        for x = x1 to x2 do
            for y = y1 to y2 do
                if find_object(board, x, y, layer) then
                    delete_object(board, find_object(board, x, y, layer))
                end if
                if char != -1 then eset(board, x, y, layer, BRD_TILECHAR, char) end if
                if color != -1 then eset(board, x, y, layer, BRD_TILECOLOR, color) end if
            end for
        end for
    end if
end procedure


procedure set_multi_chunk(atom board, atom layer, sequence coords, sequence chunk, atom transp)

    atom x1, y1, x2, y2, cnt

    x1 = coords[1]
    y1 = coords[2]
    x2 = coords[1] + (length(chunk) - 1)
    y2 = coords[2] + ((length(chunk[1]) - 1) / 2)

        for x = x1 to x2 do
            cnt = 1
            for y = y1 to y2 do

                if coords_in_range(board, x, y) then

                    if transp then
                        if chunk[x - (x1 - 1)][cnt] > 0 then
                            eset(board, x, y, layer, BRD_TILECHAR, chunk[x - (x1 - 1)][cnt])
                            eset(board, x, y, layer, BRD_TILECOLOR, chunk[x - (x1 - 1)][cnt + 1])
                        end if
                    else
                        eset(board, x, y, layer, BRD_TILECHAR, chunk[x - (x1 - 1)][cnt])
                        eset(board, x, y, layer, BRD_TILECOLOR, chunk[x - (x1 - 1)][cnt + 1])
                    end if
                
                end if

                cnt = cnt + 2
            end for
        end for
        
end procedure


procedure resize_board(atom board, sequence new_size)

    sequence c
    atom use_x, use_y, use_l

    use_x = world[WRLD_BOARDS][board][BRD_SIZEX]
    use_y = world[WRLD_BOARDS][board][BRD_SIZEY]
    use_l = world[WRLD_BOARDS][board][BRD_LAYERS]

    c = repeat({}, use_l)
    for z = 1 to use_l do
        c[z] = get_board_chunk(board, z, {{1, 1}, {use_x, use_y}})
    end for
    
    world[WRLD_BOARDS][board][BRD_DATA] = repeat(0, return_board_geometry(new_size[1], new_size[2], new_size[3], BRD_TILEELEMS))

    world[WRLD_BOARDS][board][BRD_SIZEX] = new_size[1]
    world[WRLD_BOARDS][board][BRD_SIZEY] = new_size[2]
    world[WRLD_BOARDS][board][BRD_LAYERS] = new_size[3]
    
    if use_l > new_size[3] then
        use_l = new_size[3]
    end if
    
    for z = 1 to use_l do
        set_multi_chunk(board, z, {1, 1}, c[z], 0)
    end for
    
    for z = 1 to length(world[WRLD_BOARDS][board][BRD_OBJECTS]) do
        if oget(board, z, OBJ_X) > new_size[1]
        or oget(board, z, OBJ_Y) > new_size[2] then
            delete_object(board, z)
        end if
    end for

end procedure


function color_element_fore(atom color)

    while color > 15 do
        color = color - 16
    end while

    return(color)

end function


function color_element_back(atom color)

    atom ret

    ret = 0

    while color > 15 do
        ret = ret + 1
        color = color - 16
    end while

    return(ret)

end function


function color_attribute(atom fore, atom back)

    return((back * 16) + fore)

end function


procedure draw_shown_objects(atom b, sequence offsets, sequence visible_layers)

    atom x, y, ry

    if length(visible_layers) = 1 then

        if visible_layers[1] = 1 then ry = 1 else ry = 0
        end if

        visible_layers = repeat(ry, world[WRLD_BOARDS][b][BRD_LAYERS])

    end if

    for z = 1 to length(world[WRLD_BOARDS][b][BRD_OBJECTS]) do

        x = oget(b, z, OBJ_X) - offsets[1]
        y = oget(b, z, OBJ_Y) - offsets[2]

        if x > 0 and x <= screen_sizex then
            if y > 0 and y <= screen_sizey - sidebar_width then
                if visible_layers[oget(b, z, OBJ_LAYER)] then
                    display_text_image({x, y},
                        {{'!', 15}})
                end if
            end if
        end if

    end for

end procedure


procedure draw_object(atom b, atom z, sequence offsets, sequence visible_layers, sequence viewport)

    atom x, y, ry, no_draw
    sequence draw, obj

    if length(offsets) then end if  -- get rid of warning

    if length(visible_layers) = 1 then
        if visible_layers[1] = 1 then ry = 1 else ry = 0
        end if
        visible_layers = repeat(ry, world[WRLD_BOARDS][b][BRD_LAYERS])
    end if
    
    -- viewport: the drawing area on the screen. x1,y1,x2,y2
    -- offset: the scrolled position of the board.
    
    if viewport[1] < 1 then viewport[1] = 1 end if
    if viewport[2] < 1 then viewport[2] = 1 end if
    if viewport[3] > screen_sizex then viewport[1] = screen_sizex end if
    if sidebar then
        if viewport[4] > (screen_sizey - sidebar_width) then viewport[4] = (screen_sizey - sidebar_width) end if
    else if viewport[4] > screen_sizey then viewport[4] = screen_sizey end if
    end if
    
    obj = world[WRLD_BOARDS][b][BRD_OBJECTS]
    draw = {0, 0}

        no_draw = FALSE
        x = obj[z][1][OBJ_X] - offsets[1]
        y = obj[z][1][OBJ_Y] - offsets[2]
        if x >= viewport[1] and x <= viewport[3] then
            if y >= viewport[2] and y <= viewport[4] then
                if visible_layers[obj[z][1][OBJ_LAYER]] then
                    for zz = obj[z][1][OBJ_LAYER] to world[WRLD_BOARDS][b][BRD_LAYERS] do
                        if eget(b, x + offsets[1], y + offsets[2], zz, BRD_TILECHAR) != 0 then
                            no_draw = TRUE
                        end if
                    end for
                end if
                
                if not no_draw then
                    display_text_image({x, y},
                        {{obj[z][1][OBJ_CHAR], obj[z][1][OBJ_COLOR]}})
                end if
            end if
        end if

end procedure


procedure draw_objects(atom b, sequence offsets, sequence visible_layers, sequence viewport)

    atom x, y, ry, no_draw
    sequence draw, obj

    if length(offsets) then end if  -- get rid of warning

    if length(visible_layers) = 1 then
        if visible_layers[1] = 1 then ry = 1 else ry = 0
        end if
        visible_layers = repeat(ry, world[WRLD_BOARDS][b][BRD_LAYERS])
    end if
    
    -- viewport: the drawing area on the screen. x1,y1,x2,y2
    -- offset: the scrolled position of the board.
    
    if viewport[1] < 1 then viewport[1] = 1 end if
    if viewport[2] < 1 then viewport[2] = 1 end if
    if viewport[3] > screen_sizex then viewport[1] = screen_sizex end if
    if sidebar then
        if viewport[4] > (screen_sizey - sidebar_width) then viewport[4] = (screen_sizey - sidebar_width) end if
    else if viewport[4] > screen_sizey then viewport[4] = screen_sizey end if
    end if
    
    if atom(world[WRLD_BOARDS][b][BRD_OBJECTS]) then
        return
    end if

    obj = world[WRLD_BOARDS][b][BRD_OBJECTS]
    draw = {0, 0}

    for z = 1 to length(obj) do
        no_draw = FALSE
        x = obj[z][1][OBJ_X] - offsets[1]
        y = obj[z][1][OBJ_Y] - offsets[2]
        if x >= viewport[1] and x <= viewport[3] then
            if y >= viewport[2] and y <= viewport[4] then
                if visible_layers[obj[z][1][OBJ_LAYER]] then
                    for zz = obj[z][1][OBJ_LAYER] to world[WRLD_BOARDS][b][BRD_LAYERS] do
                        if eget(b, x + offsets[1], y + offsets[2], zz, BRD_TILECHAR) != 0 then
                            no_draw = TRUE
                        end if
                    end for
                end if
                
                if not no_draw then
                    display_text_image({x, y},
                        {{obj[z][1][OBJ_CHAR], obj[z][1][OBJ_COLOR]}})
                end if
            end if
        end if
    end for

end procedure


procedure draw_ge_object(atom z, sequence obj, atom b, sequence offsets, sequence visible_layers, sequence viewport)

    atom x, y, ry, no_draw
    sequence draw, ss
    
    if length(offsets) then end if  -- get rid of warning

    if length(visible_layers) = 1 then
        if visible_layers[1] = 1 then ry = 1 else ry = 0
        end if
        visible_layers = repeat(ry, world[WRLD_BOARDS][b][BRD_LAYERS])
    end if
    
    -- viewport: the drawing area on the screen. x1,y1,x2,y2
    -- offset: the scrolled position of the board.
    
    if viewport[1] < 1 then viewport[1] = 1 end if
    if viewport[2] < 1 then viewport[2] = 1 end if
    if viewport[3] > screen_sizex then viewport[1] = screen_sizex end if
    if sidebar then
        if viewport[4] > (screen_sizey - sidebar_width) then viewport[4] = (screen_sizey - sidebar_width) end if
    else if viewport[4] > screen_sizey then viewport[4] = screen_sizey end if
    end if

    draw = {0, 0}
    
--    ss = screen_save()

        no_draw = FALSE
        x = obj[z][1][OBJ_X] - offsets[1]
        y = obj[z][1][OBJ_Y] - offsets[2]
        if x >= viewport[1] and x <= viewport[3] then
            if y >= viewport[2] and y <= viewport[4] then
                if visible_layers[obj[z][1][OBJ_LAYER]] = 1 then
                    for zz = obj[z][1][OBJ_LAYER] to world[WRLD_BOARDS][b][BRD_LAYERS] do
                        if eget(b, x + offsets[1], y + offsets[2], zz, BRD_TILECHAR) != 0 then
                            no_draw = TRUE
                        end if
                    end for
                else no_draw = TRUE
                end if
                
                if not no_draw then
--                    ss[x][(y * 2) - 1] = obj[z][1][OBJ_CHAR]
--                    ss[x][y * 2] = obj[z][1][OBJ_COLOR]
                    put_screen_char(x, y, {obj[z][1][OBJ_CHAR], obj[z][1][OBJ_COLOR]})
                end if
            end if
        end if
    
--    screen_restore(ss)

end procedure


procedure draw_board_tile(atom boardnum, atom x, atom y, sequence offsets, sequence visible_layers, sequence viewport)

    integer rx, ry, a
    sequence draw

    if length(offsets) then end if  -- get rid of warning

    if length(visible_layers) = 1 then
        if visible_layers[1] = 1 then ry = 1 else ry = 0
        end if
        visible_layers = repeat(ry, world[WRLD_BOARDS][boardnum][BRD_LAYERS])
    end if
    
    -- viewport: the drawing area on the screen. x1,y1,x2,y2
    -- offset: the scrolled position of the board.
    
    if viewport[1] < 1 then viewport[1] = 1 end if
    if viewport[2] < 1 then viewport[2] = 1 end if
    if viewport[3] > screen_sizex then viewport[1] = screen_sizex end if
    if sidebar then
        if viewport[4] > (screen_sizey - sidebar_width) then viewport[4] = (screen_sizey - sidebar_width) end if
    else if viewport[4] > screen_sizey then viewport[4] = screen_sizey end if
    end if

    draw = {0, 0}
    x = x - offsets[1]
    y = y - offsets[2]
    
            rx = x + offsets[1]
            ry = y + offsets[2]
            if rx >= 1 and ry >= 1 then
                if rx <= world[WRLD_BOARDS][boardnum][BRD_SIZEX]
                and ry <= world[WRLD_BOARDS][boardnum][BRD_SIZEY] then
                    for z = 1 to world[WRLD_BOARDS][boardnum][BRD_LAYERS] do
                        if visible_layers[z] then
                            a = eget(boardnum, rx, ry, z, BRD_TILECHAR)
                            if a then
                                -- set char...
                                draw[1] = a
                                -- and color
                                draw[2] = eget(boardnum, rx, ry, z, BRD_TILECOLOR)
                            end if
                        end if
                    end for
                end if
            end if

    display_text_image({x, y}, {draw})

    for z = 1 to world[WRLD_BOARDS][boardnum][BRD_LAYERS] do
        if find_object(boardnum, rx, ry, z) then
            draw_object(boardnum, find_object(boardnum, rx, ry, z), offsets, visible_layers, viewport)
        end if                                           
    end for

end procedure

function ge_find_object_at_xy_layer(sequence o, sequence l, atom x, atom y)

    for z = 1 to length(l) do
        if o[l[z]][1][OBJ_X] = x
        and o[l[z]][1][OBJ_Y] = y then
            return(l[z])
        end if
    end for
    
    return(0)
    
end function


procedure draw_ge_board_tile(atom boardnum, sequence o, atom x, atom y, sequence offsets, sequence visible_layers, sequence viewport, sequence layer_table)

    atom rx, ry, a, dflag
    sequence draw
    
    if length(visible_layers) = 1 then
        if visible_layers[1] = 1 then ry = 1 else ry = 0
        end if
        visible_layers = repeat(ry, world[WRLD_BOARDS][boardnum][BRD_LAYERS])
    end if

    if (x > world[WRLD_BOARDS][boardnum][BRD_SIZEX]
    or y > world[WRLD_BOARDS][boardnum][BRD_SIZEY])
    or (x < 1 or y < 1) then
        return
    end if

    rx = x - offsets[1]
    ry = y - offsets[2]
    
    if rx > viewport[3] or rx < viewport[1] then
        return
    end if
    if ry > viewport[4] or ry < viewport[2] then
        return
    end if

    draw = {0, 0}
    dflag = -1

    for z = 1 to world[WRLD_BOARDS][boardnum][BRD_LAYERS] do
        if visible_layers[z] then
            if eget(boardnum, x, y, z, BRD_TILECHAR) != 0 then 
                draw = {eget(boardnum, x, y, z, BRD_TILECHAR),
                        eget(boardnum, x, y, z, BRD_TILECOLOR)}
            end if
            if dflag != -1 then
                draw[2] = color_attribute(color_element_fore(draw[2]), color_element_back(dflag))
            end if
            dflag = -1
            a = ge_find_object_at_xy_layer(o, layer_table[z], x, y)
            if a != 0 and o[a][1][OBJ_CHAR] != 0 then
                draw = {o[a][1][OBJ_CHAR], o[a][1][OBJ_COLOR]}
                if color_element_back(draw[2]) = 0 and z != 1 then
                    a = eget(boardnum, x, y, z - 1, BRD_TILECHAR)
                    if a != 0 and a != 32 and a != 255 then
                        draw[2] = color_attribute(color_element_fore(draw[2]), color_element_fore(eget(boardnum, x, y, z - 1, BRD_TILECOLOR)))
                    end if
                end if
                if z < world[WRLD_BOARDS][boardnum][BRD_LAYERS] then
                    if visible_layers[z + 1] then
                        a = eget(boardnum, x, y, z + 1, BRD_TILECHAR)
                        if a != 0 and a != 32 and a != 255 then
                            dflag = draw[2] --eget(boardnum, x, y, z + 1, BRD_TILECOLOR)
                        end if
                    end if
                end if
            end if
        end if
    end for

    if rx >= viewport[1] and rx <= viewport[3] then
        if ry >= viewport[2] and ry <= viewport[4] then
            put_screen_char(rx, ry, draw)
        end if
    end if

end procedure


procedure draw_ge_objects(sequence obj, atom b, sequence offsets, sequence visible_layers, sequence viewport, sequence layer_table)

    atom x, y, ry, no_draw
    sequence draw, ss
    
    for z = 1 to length(obj) do
        draw_ge_board_tile(b, obj, obj[z][1][OBJ_X], obj[z][1][OBJ_Y], offsets, visible_layers, viewport, layer_table)
    end for
    
    return
    
    
    if length(offsets) then end if  -- get rid of warning

    if length(visible_layers) = 1 then
        if visible_layers[1] = 1 then ry = 1 else ry = 0
        end if
        visible_layers = repeat(ry, world[WRLD_BOARDS][b][BRD_LAYERS])
    end if
    
    -- viewport: the drawing area on the screen. x1,y1,x2,y2
    -- offset: the scrolled position of the board.
    
    if viewport[1] < 1 then viewport[1] = 1 end if
    if viewport[2] < 1 then viewport[2] = 1 end if
    if viewport[3] > screen_sizex then viewport[1] = screen_sizex end if
    if sidebar then
        if viewport[4] > (screen_sizey - sidebar_width) then viewport[4] = (screen_sizey - sidebar_width) end if
    else if viewport[4] > screen_sizey then viewport[4] = screen_sizey end if
    end if

    draw = {0, 0}
    
--    ss = screen_save()

    for z = 1 to length(obj) do
        no_draw = FALSE
        x = obj[z][1][OBJ_X] - offsets[1]
        y = obj[z][1][OBJ_Y] - offsets[2]
        if x >= viewport[1] and x <= viewport[3] then
            if y >= viewport[2] and y <= viewport[4] then
                if visible_layers[obj[z][1][OBJ_LAYER]] = 1 then
                    for zz = obj[z][1][OBJ_LAYER] to world[WRLD_BOARDS][b][BRD_LAYERS] do
                        if eget(b, x + offsets[1], y + offsets[2], zz, BRD_TILECHAR) != 0 then
                            no_draw = TRUE
                        end if
                    end for
                else no_draw = TRUE
                end if
                
                if not no_draw then
--                    ss[x][(y * 2) - 1] = obj[z][1][OBJ_CHAR]
--                    ss[x][y * 2] = obj[z][1][OBJ_COLOR]
                    put_screen_char(x, y, {obj[z][1][OBJ_CHAR], obj[z][1][OBJ_COLOR]})
                end if
            end if
        end if
    end for
    
--    screen_restore(ss)

end procedure


procedure draw_board__(atom boardnum, sequence offsets, sequence visible_layers, sequence viewport)

    integer rx, ry, a
    sequence draw

    if length(offsets) then end if  -- get rid of warning

    if length(visible_layers) = 1 then
        if visible_layers[1] = 1 then ry = 1 else ry = 0
        end if
        visible_layers = repeat(ry, world[WRLD_BOARDS][boardnum][BRD_LAYERS])
    end if
    
    -- viewport: the drawing area on the screen. x1,y1,x2,y2
    -- offset: the scrolled position of the board.
    
    if viewport[1] < 1 then viewport[1] = 1 end if
    if viewport[2] < 1 then viewport[2] = 1 end if
    if viewport[3] > screen_sizex then viewport[1] = screen_sizex end if
    if sidebar then
        if viewport[4] > (screen_sizey - sidebar_width) then viewport[4] = (screen_sizey - sidebar_width) end if
    else if viewport[4] > screen_sizey then viewport[4] = screen_sizey end if
    end if

    if sidebar then
        draw = repeat(repeat(0, (screen_sizey - sidebar_width) * 2), screen_sizex)
    else draw = repeat(repeat(0, screen_sizey * 2), screen_sizex)
    end if
    
    for x = viewport[1] to viewport[3] do
        for y = viewport[2] to viewport[4] do
            rx = x + offsets[1]
            ry = y + offsets[2]
            if rx >= 1 and ry >= 1 then
                if rx <= world[WRLD_BOARDS][boardnum][BRD_SIZEX]
                and ry <= world[WRLD_BOARDS][boardnum][BRD_SIZEY] then
                    for z = 1 to world[WRLD_BOARDS][boardnum][BRD_LAYERS] do
                        if visible_layers[z] = 1 then
                            a = eget(boardnum, rx, ry, z, BRD_TILECHAR)
                            if a then
                                -- set char...
                                draw[x][(y * 2) - 1] = a
                                -- and color
                                draw[x][(y * 2)] = eget(boardnum, rx, ry, z, BRD_TILECOLOR)
                            end if
                        end if
                    end for
                end if
            end if
        end for
    end for

    display_text_image({1, 1}, draw)

end procedure


procedure draw_ge_board(atom boardnum, sequence offsets, sequence visible_layers, sequence viewport)

    draw_board__(boardnum, offsets, visible_layers, viewport)

end procedure


procedure draw_board(atom boardnum, sequence offsets, sequence visible_layers, sequence viewport)

    draw_board__(boardnum, offsets, visible_layers, viewport)
    draw_objects(boardnum, offsets, visible_layers, viewport)

end procedure


procedure draw_board_one_row(atom boardnum, sequence o, atom zx, sequence offsets, sequence visible_layers, sequence viewport, sequence layer_table)

    integer rx, ry, a
    sequence draw

    if length(offsets) then end if  -- get rid of warning

    if length(visible_layers) = 1 then
        if visible_layers[1] = 1 then ry = 1 else ry = 0
        end if
        visible_layers = repeat(ry, world[WRLD_BOARDS][boardnum][BRD_LAYERS])
    end if
    
    -- viewport: the drawing area on the screen. x1,y1,x2,y2
    -- offset: the scrolled position of the board.
    -- zx is a position absolute to the screen
    
    if viewport[1] < 1 then viewport[1] = 1 end if
    if viewport[2] < 1 then viewport[2] = 1 end if
    if viewport[3] > screen_sizex then viewport[1] = screen_sizex end if
    if sidebar then
        if viewport[4] > (screen_sizey - sidebar_width) then viewport[4] = (screen_sizey - sidebar_width) end if
    else if viewport[4] > screen_sizey then viewport[4] = screen_sizey end if
    end if

    if sidebar then
        draw = repeat(repeat(0, (screen_sizey - sidebar_width) * 2), screen_sizex)
    else draw = repeat(repeat(0, screen_sizey * 2), screen_sizex)
    end if
    
    for x = viewport[1] to viewport[3] do
        for y = viewport[2] to viewport[4] do
            if x = zx then
            rx = x + offsets[1]
            ry = y + offsets[2]
            if rx >= 1 and ry >= 1 then
                if rx <= world[WRLD_BOARDS][boardnum][BRD_SIZEX]
                and ry <= world[WRLD_BOARDS][boardnum][BRD_SIZEY] then
                    for z = 1 to world[WRLD_BOARDS][boardnum][BRD_LAYERS] do
                        if visible_layers[z] then
                            a = eget(boardnum, rx, ry, z, BRD_TILECHAR)
                            if a then
                                -- set char...
                                draw[x][(y * 2) - 1] = a
                                -- and color
                                draw[x][(y * 2)] = eget(boardnum, rx, ry, z, BRD_TILECOLOR)
                            end if
                        end if
                    end for
                end if
            end if
            end if
        end for
    end for
    
    display_text_image({zx, 1}, {draw[zx]})
    draw_ge_objects(o, boardnum, offsets, visible_layers, viewport, layer_table)

end procedure


global function sb_input(atom TypeOf, atom Line, sequence Prompt, object Max)
    atom Pos, Key
    sequence Ext, Inp, SS

    SS = screen_save()

    Line = 21

    bk_color(1)

    for z = Line - 1 to Line + 2 do
        sb_print(z, repeat(32, 18), 15)
    end for

    if sequence(Max) then
        Inp = Max
        Pos = length(Max)
        Max = 8
    else
        Inp = {}
        Pos = 1
    end if

    if TypeOf = SBI_FILENAME then
        Ext = "." & Prompt[length(Prompt) - 2..length(Prompt)]
        Prompt = Prompt[1..length(Prompt) - 3]
        Max = 8
    else Ext = {}
    end if

    if TypeOf = SBI_ANYSTR and Max > 18 then Max = 18 end if

    position(Line, 62)
    text_color(14)
    bk_color(1)
    puts(1, Prompt)
    position(Line + 1, 62)
    text_color(15)
    bk_color(0)
    puts(1, repeat(32, Max))
    position(Line + 1, 62)
    puts(1, Inp)

    if TypeOf = SBI_FILENAME then
        position(Line + 1, 70)
        puts(1, Ext)
    end if

    cursor(UNDERLINE_CURSOR)
    position(Line + 1, 62 + length(Inp))
    Key = -1

    while Key != KEY_ESC and Key != KEY_CR do
        Key = get_key()
        if TypeOf = SBI_FILENAME then
            if (upper(Key) != Key or lower(Key) != Key) or (Key >= '0' and Key <= '9') then
                if length(Inp) < Max then
                    Key = upper(Key)
                    Inp = append(Inp, Key)
                    position(Line + 1, 62)
                    puts(1, Inp)
                end if
            end if
        else
            if Key > 31 and Key < 127 and length(Inp) < Max then
                Inp = append(Inp, Key)
                position(Line + 1, 62)
                puts(1, Inp)
            end if
        end if
        if Key = 8 then
            if length(Inp) != 0 then
                Inp = Inp[1..length(Inp) - 1]
                position(Line + 1, 62)
                puts(1, Inp & " ")
                position(Line + 1, 62)
                puts(1, Inp)
            end if
        end if
    end while

    cursor(NO_CURSOR)
    screen_restore(SS)
    
    if Key = KEY_ESC then
        return({})
    end if

    return Inp
end function


procedure invert_area(sequence c1, sequence c2)

    sequence buf

    buf = save_text_image(c1, c2)

    for z = 1 to length(buf) do
        for a = 1 to length(buf[z]) by 2 do
            buf[z][a + 1] = 255 - buf[z][a + 1]
        end for
    end for

    display_text_image(c1, buf)

end procedure


procedure delay(atom t)
    
    atom tt
    
    tt = time() + t
    while tt > time() do
    end while
    
end procedure



include zig.inc



global function do_scroll(sequence Caption, sequence Scroll, atom Sel)

    atom X, PutX, OldX, Key
    sequence TxtScr, ps

    TxtScr = save_text_image({1, 1}, {25, 80})
    cursor(NO_CURSOR)

    text_color(14)
    bk_color(1)

    X = Scroll_PosX + (Scroll_SizeX / 2)
    for z = 1 to (Scroll_SizeX / 2) - 1 do
        box(X - z,
            Scroll_PosY - 1,
            X + z,
            (Scroll_PosY) + Scroll_SizeY,
            Scroll_BackC,
            Caption)
        delay(.01)
    end for    

    box(Scroll_PosX,
        Scroll_PosY - 1,
        (Scroll_PosX - 1) + Scroll_SizeX,
        (Scroll_PosY) + Scroll_SizeY,
        Scroll_BackC,
        Caption)

    if Sel then X = Sel else X = 1 end if
    bk_color(Scroll_BackC)

    text_color(Scroll_HLTitleC)
    position(Scroll_PosX + (Scroll_SizeX / 2), Scroll_PosY)
    puts(1, "ò")
    position(Scroll_PosX + (Scroll_SizeX / 2), Scroll_PosY + Scroll_SizeY - 1)
    puts(1, "ó")

    Key = -2
    while Key != 27 and Key != 13 do

        if Key = -2 then OldX = 0 else OldX = X end if

        Key = get_key()
        if Key != -1 then
            if Key = KEY_UP then
                X = X - 1
            elsif Key = KEY_DN then
                X = X + 1
            elsif Key = KEY_PGUP then
                X = X - (Scroll_SizeX - 3)
            elsif Key = KEY_PGDN then
                X = X + (Scroll_SizeX - 3)
            end if
        end if

        if X != OldX then
            if X < 1 then
                X = 1
            elsif X > length(Scroll) then
                X = length(Scroll)
            end if
            if X != OldX then
                X = X + 1
                text_color(Scroll_TextC)
                for z = 1 to Scroll_SizeX - 2 do
                    ps = {}
                    PutX = (z - (Scroll_SizeX / 2)) + (X - 1)
                    if PutX > 0 and PutX < (length(Scroll) + 1) then
                        position(Scroll_PosX + z, Scroll_PosY + 1)
                        if length(Scroll[PutX]) >= (Scroll_SizeY - 2) then
                            Scroll[PutX] = Scroll[PutX][1..(Scroll_SizeY - 3)]
                        end if
                        if length(Scroll[PutX]) != 0 then
                            if Scroll[PutX][1] = '$' then
                                ps = expand_str(Scroll[PutX][2..length(Scroll[PutX])])
--                                ps = set_str_color(repeat(32, (Scroll_SizeY / 2) - (length(Scroll[PutX]) / 2)), 31) &
                                    
                                    --t_ge_translatecodes(apply_str_color(Scroll[PutX][2..length(Scroll[PutX])],
                                    --Scroll_HLTitleC+16))
                                --puts(1, repeat(32, Scroll_SizeY - 2))
                                puts(1, repeat(32, Scroll_SizeX))
                                display_text_image({Scroll_PosX + z, Scroll_PosY + 1}, {ps})
                                --position(Scroll_PosX + z, (Scroll_PosY + ((Scroll_SizeY / 2) - (length(Scroll[PutX]) / 2))) + 1)
                                --text_color(Scroll_HLTitleC)
                                --puts(1, Scroll[PutX][2..length(Scroll[PutX])])
                                --text_color(Scroll_TextC)
                            elsif Scroll[PutX][1] = '!' then
                                puts(1, repeat(32, Scroll_SizeY - 2))
                                if z = (Scroll_SizeX / 2) then
                                    text_color(Scroll_TextC)
                                else text_color(Scroll_BorderC)
                                end if
                                position(Scroll_PosX + z, Scroll_PosY + 1)
                                puts(1, "  ")
                                text_color(Scroll_HLTitleC)
                                puts(1, Scroll[PutX][find(';', Scroll[PutX]) + 1..length(Scroll[PutX])])
                            else
                                text_color(Scroll_TextC)
                                puts(1, Scroll[PutX])
                                puts(1, repeat(32, (Scroll_SizeY - 2) - length(Scroll[PutX])))
                            end if
                        else
                            puts(1, repeat(32, Scroll_SizeY - 2))
                        end if
                    elsif PutX = 0 or PutX = (length(Scroll) + 1) then
                        position(Scroll_PosX + z, Scroll_PosY + 1)
                        text_color(Scroll_BorderC)
                        puts(1, repeat('*', Scroll_SizeY - 2))
                        text_color(Scroll_TextC)
                    else
                        position(Scroll_PosX + z, Scroll_PosY + 1)
                        puts(1, repeat(32, Scroll_SizeY - 2))
                    end if
                end for
                X = X - 1
                --position(Scroll_PosX, Scroll_PosY + (Scroll_SizeY - 6))
                --printf(1, "%3d", X)
            end if
        end if
    end while

    clear_keys()
    
    Key = Scroll_PosX + (Scroll_SizeX / 2)
    for z = (Scroll_SizeX / 2) - 1 to 1 by -1 do
        display_text_image({1, 1}, TxtScr)
        box(Key - z,
            Scroll_PosY - 1,
            Key + z,
            (Scroll_PosY) + Scroll_SizeY,
            Scroll_BackC,
            Caption)
        delay(.01)
    end for    
    
    display_text_image({1, 1}, TxtScr)

    if Key = 27 then return {} end if

    OldX = (Scroll_SizeX / 2)
    PutX = (OldX - (Scroll_SizeX / 2)) + X
    if length(Scroll[PutX]) != 0 then
        if Scroll[PutX][1] = '!' then
            return(Scroll[PutX][2..(find(';', Scroll[PutX]) - 1)])
        else return {}
        end if
    else return {}
    end if

end function


function edit_object(sequence obj)

    if length(obj) = 1 then
        obj = append(obj, {})
    end if

    obj = {obj[1]} & do_ed(obj[2..length(obj)])

    return(obj)

end function


function edit_controller_object(sequence obj)

    if length(obj) = 0 then
        obj = NEW_OBJECT & {{}}
    elsif length(obj) = 1 then
        obj = append(obj, {})
    end if

    return({obj[1]} & do_ed(obj[2..length(obj)]))

end function


function select_board(atom selected_one, atom add_none)

    atom a
    sequence scroll_return, scrolld, title

    scrolld = {}

    if add_none then
        scrolld = append(scrolld, "!0;None")
    end if

    title = "Select a board to edit (ESC to cancel)"

    for z = 1 to length(world[WRLD_BOARDS]) do

        scrolld = append(scrolld, "!" & sprint(z) & ";")

        a = length(scrolld)

        if not length(world[WRLD_BOARDS][z][BRD_NAME]) then

            scrolld[a] = scrolld[a] & "(Untitled board, #" & sprint(z) & ")"

        else

            scrolld[a] = scrolld[a] & world[WRLD_BOARDS][z][BRD_NAME]

        end if

    end for

    if not add_none then
        scrolld = append(scrolld, "!0;Add new board")
    end if

    scroll_return = do_scroll(title, scrolld, selected_one)

    if not length(scroll_return) then
        return(selected_one)
    else
        scroll_return = value(scroll_return)
        return(scroll_return[2])
    end if

end function


function get_world_name(sequence fname)

    atom f
    sequence header, rname

    f = open(fname, "rb")

    header = get_bytes(f, length(DEF_HEADER))

    rname = get_lpstr(f)

    if length(rname) > 28 then
        rname = rname[1..26] & ".."
    end if

    close(f)

    return(rname)

end function


function find_manual_label(sequence s)
    
    for z = 1 to length(help_text) do
        if length(help_text[z]) > 0 then
            if help_text[z][1] = ':' then
                if compare(trim(help_text[z][2..length(help_text[z])]), s) = 0 then
                    return(z)
                end if
            end if
        end if
    end for
    
    return(1)
    
end function


procedure do_help(sequence start_label)
    
    atom l, e, s
    sequence r

    if length(start_label) = 0 then
        l = 2
    else l = find_manual_label(start_label) + 1
    end if
    
    s = 1
        
    while 1 do

        if s = 1 then
            e = length(help_text)
            for z = l to length(help_text) do
                if compare("#end", help_text[z]) = 0 then
                    e = z - 1
                    exit
                end if
            end for
        end if
    
        start_label = do_scroll("ZIG Help", help_text[l..e], s)
        if length(start_label) = 0 then
            exit
        end if
        
        for z = l to e do
            if compare(":" & start_label, help_text[z]) = 0 then
                s = z - (l - 1)
                exit
            else s = 1
            end if
        end for
        
        if s = 1 then
            if length(start_label) = 0 then
                l = 1
            else l = find_manual_label(start_label) + 1
            end if
        end if
    
    end while
    
end procedure


global function select_file(sequence Mask, sequence title)
    -- example value for Mask: "*.zig"

    atom Exit, aas
    sequence DirectoryIndex, FileIndex, Scroll, n, OldDir
    object Dir

    OldDir = current_dir()

    Exit = FALSE
    while Exit != TRUE do

        DirectoryIndex = {}
        FileIndex = {}
        Scroll = {}
        Dir = dir("*.*")
        n = {}

        if sequence(Dir) then   -- there are files in here
            Dir = sort(Dir)
            for z = 1 to length(Dir) do -- get directories out
                if length(Dir[z][2]) then
                    if Dir[z][2][1] = 'd' then  -- found a directory
                        Scroll = append(Scroll, "!d" & length(Scroll) + 1 & ";" & Dir[z][1] & "/")    -- add to chooser scroll
                        DirectoryIndex = append(DirectoryIndex, {Dir[z][1], length(Scroll)})    -- add to finder index
                    end if
                end if
            end for
        end if

        Dir = dir(Mask)
        if sequence(Dir) then   -- there are files matching the filemask
            Dir = sort(Dir)
            for z = 1 to length(Dir) do
                if compare(Mask, "*.zig") = 0  then
                    Scroll = append(Scroll, "!f" & length(Scroll) + 1 & ";" & Dir[z][1] & repeat(32, 16 - length(Dir[z][1])) & get_world_name(Dir[z][1]))    -- add to chooser scroll
                else Scroll = append(Scroll, "!f" & length(Scroll) + 1 & ";" & Dir[z][1])
                end if
                FileIndex = append(FileIndex, {Dir[z][1], length(Scroll)})    -- add to finder index
            end for
        end if
        
        if compare(Mask, "*.zig") = 0 then
            Dir = dir("*.zzt")
            if sequence(Dir) then   -- there are files matching the filemask
                Dir = sort(Dir)
                for z = 1 to length(Dir) do
                    Scroll = append(Scroll, "!f" & length(Scroll) + 1 & ";" & Dir[z][1] & repeat(32, 20))
                    FileIndex = append(FileIndex, {Dir[z][1], length(Scroll)})    -- add to finder index
                end for
            end if
        end if

        if length(Scroll) = 0 then
            n = do_scroll(title & " (ESC to cancel)", {"(no files)"}, 1)
            return {1}
        end if

        n = do_scroll(title & " (ESC to cancel)", Scroll, 1)

        aas = 0
        if length(n) != 0 then
            if n[1] = 'd' then
                system("cd " & Scroll[n[2]][5..length(Scroll[n[2]]) - 1], 2)
                Exit = FALSE
                aas = 0
            else aas = 1
            end if
        else aas = 1
        end if

        if aas = 1 then
                Dir = current_dir()
                if Dir[length(Dir)] != '\\' then
                    Dir = Dir & '\\'
                end if
                system("cd " & OldDir, 2)
                if length(n) != 0 then
                    if compare(Mask, "*.zig") = 0 then
                        if length(n) > 1 then
                            return(trim(Dir & Scroll[n[2]][5..17]))
                        else return({})
                        end if
                    end if
                    return(Dir & Scroll[n[2]][5..length(Scroll[n[2]])])
                else return({})
                end if
        end if

    end while

    system("cd " & OldDir, 2)
    return {1}

end function


procedure dlg_get_color_drawex(atom x, atom y)

    atom p
    
    x = x - 1
    y = y - 1

    display_text_image({20, ty(63)}, {{254, y}})
    display_text_image({20, ty(65)}, {{254, x}})
    display_text_image({20, ty(65)}, {{254, x}})
    
    p = color_attribute(y,x)
    
    display_text_image({20, ty(67)}, {{219, p, 178, p, 177, p, 176, p, 32, p}})
    display_text_image({20, ty(73)}, {{174, p}})

end procedure


function dlg_get_color(atom prev)

    atom x, y, run_mode, old_x, old_y, key
    sequence color_array, saved_screen

    saved_screen = screen_save()

    sidebar_clear()

    color_array = repeat(repeat(254, 32), 16)

    for bgnd = 1 to 16 do
        for fgnd = 1 to 16 do
            color_array[bgnd][(fgnd * 2)] = color_attribute(fgnd - 1, bgnd - 1)
        end for
    end for

    box(3, ty(62), 20, ty(79), 1, "Select Color")
    display_text_image({4, ty(63)}, color_array)

    sb_btnprint(22, "Enter", "Select", 3)
    sb_btnprint(23, "ESC", "Cancel", 7)

    x = color_element_back(prev) + 1
    y = color_element_fore(prev) + 1
    run_mode = RUNNING
    
    dlg_get_color_drawex(x, y)
    
    text_color(15) bk_color(0)
    position(3 + x, ty(62 + y))
    puts(1, CSR_NORMAL)

    while run_mode = RUNNING do

        old_x = x
        old_y = y

        key = get_key()

        if key != -1 then
            if key = KEY_UP then x = x - 1
            elsif key = KEY_DN then x = x + 1
            elsif key = KEY_LF then y = y - 1
            elsif key = KEY_RT then y = y + 1
            elsif key = KEY_HOME then
                y = y - 8
            elsif key = KEY_END then
                y = y + 8
            elsif key = KEY_PGUP then
                x = x - 8
            elsif key = KEY_PGDN then
                x = x + 8
            elsif key = KEY_CR then

                prev = color_attribute(y - 1, x - 1)
                run_mode = STOP

            elsif key = KEY_ESC then

                run_mode = STOP

            end if
        end if

        if x != old_x or y != old_y then
            if x > 16 then x = 16 end if
            if y > 16 then y = 16 end if
            if x < 1 then x = 1 end if
            if y < 1 then y = 1 end if

            display_text_image({4, ty(63)}, color_array)

            position(3 + x, ty(62 + y))
            text_color(15) bk_color(0)
            puts(1, CSR_NORMAL)
            
            dlg_get_color_drawex(x, y)

        end if

    end while

    screen_restore(saved_screen)
    return(prev)

end function


function dlg_get_char(atom prev)

    atom x, y, run_mode, old_x, old_y, key, oprev
    sequence char_array, saved_screen

    saved_screen = screen_save()

    sidebar_clear()

    char_array = repeat(repeat(7, 32), 16)

    for zx = 1 to 16 do
        for zy = 1 to 16 do
            char_array[zx][(zy * 2) - 1] = color_attribute(zy - 1, zx - 1)
        end for
    end for

    box(3, ty(62), 20, ty(79), 1, "Select Char")
    display_text_image({4, ty(63)}, char_array)

    sb_btnprint(22, "Enter", "Select", 3)
    sb_btnprint(23, "ESC", "Cancel", 7)
    
    oprev = prev
    if prev < 0 then
        prev = 0
    end if
    
    x = color_element_back(prev) + 1    -- works! :)
    y = color_element_fore(prev) + 1       --
    run_mode = RUNNING

    display_text_image({3 + x, ty(62 + y)}, {{color_attribute(y - 1, x - 1), 31}})

    position(20, ty(63))
    printf(1, "%3d", color_attribute(y - 1, x - 1))


    while run_mode = RUNNING do

        old_x = x
        old_y = y

        key = get_key()

        if key != -1 then
            if key = KEY_UP then x = x - 1
            elsif key = KEY_DN then x = x + 1
            elsif key = KEY_LF then y = y - 1
            elsif key = KEY_RT then y = y + 1
            elsif key = KEY_PGUP then
                x = 1
            elsif key = KEY_PGDN then
                x = 32
            elsif key = KEY_HOME then
                y = 1
            elsif key = KEY_END then
                y = 16
            elsif key = KEY_CR then

                prev = color_attribute(y - 1, x - 1)    -- also works!
                run_mode = STOP

            elsif key = KEY_ESC then
                
                prev = oprev
                run_mode = STOP

            end if
        end if

        if x != old_x or y != old_y then
            if x > 16 then x = 16 end if
            if y > 16 then y = 16 end if
            if x < 1 then x = 1 end if
            if y < 1 then y = 1 end if

            display_text_image({4, ty(63)}, char_array)

            display_text_image({3 + x, ty(62 + y)}, {{color_attribute(y - 1, x - 1), 31}})

            position(20, ty(63))
            printf(1, "%3d", color_attribute(y - 1, x - 1))

        end if

    end while

    screen_restore(saved_screen)
    return(prev)

end function


global procedure edit_charset_drawchar(sequence pat)
    sequence d, e

    d = {}
    for z = 1 to font_height do
        e = {}
        for a = 1 to FONT_WIDTH do
            if pat[z][a] = 'x' then
                e = e & "Û‡Û‡"
            else e = e & "ú‡ú‡"
            end if
        end for
        d = append(d, e)
    end for

    display_text_image({5, 6}, d)
end procedure


function edit_charset_makepattern(sequence CharSet, atom curchar)
    sequence bits, ret

    ret = repeat(repeat(0, FONT_WIDTH), FONT_HEIGHT)
    for z = 1 to FONT_HEIGHT do
        bits = int_to_bits(CharSet[curchar + 1][z], 8)
        for a = 1 to 8 do
            if bits[a] = 1 then
                ret[z][9 - a] = 'x'
            end if
        end for
    end for

    return ret
end function


function shift_char_x(sequence cc, atom d)

    sequence bcc
    
    bcc = cc
    
    if d = 1 then
        -- down
        for z = 1 to FONT_HEIGHT - 1 do
            bcc[z + 1] = cc[z]
        end for
        bcc[1] = cc[FONT_HEIGHT]
    else
        -- up
        for z = 2 to FONT_HEIGHT do
            bcc[z - 1] = cc[z]
        end for
        bcc[FONT_HEIGHT] = cc[1]
    end if

    return(bcc)
    
end function


function shift_char_y(sequence cc, atom d)

    sequence bcc
    
    bcc = cc
    
    if d = 1 then
        -- right
        for z = 1 to FONT_WIDTH - 1 do
            for a = 1 to FONT_HEIGHT do
                bcc[a][z + 1] = cc[a][z]
            end for
        end for
        for a = 1 to FONT_HEIGHT do
            bcc[a][1] = cc[a][FONT_WIDTH]
        end for
    else
        -- left
        for z = 2 to FONT_WIDTH do
            for a = 1 to FONT_HEIGHT do
                bcc[a][z - 1] = cc[a][z]
            end for
        end for
        for a = 1 to FONT_HEIGHT do
            bcc[a][FONT_WIDTH] = cc[a][1]
        end for
    end if

    return(bcc)
    
end function



procedure shift_char(atom c, atom x, atom y)

    sequence cc, bufcc

    if length(charset) and c > -1 then
        cc = edit_charset_makepattern(charset, c)
        if x > 0 then
            for lx = 1 to x do
                cc = shift_char_x(cc, 1)
            end for
        else
            for lx = 1 to -x do
                cc = shift_char_x(cc, -1)
            end for
        end if
        
        if y > 0 then
            for lx = 1 to y do
                cc = shift_char_y(cc, 1)
            end for
        else
            for lx = 1 to -y do
                cc = shift_char_y(cc, -1)
            end for
        end if
        
        charset[c + 1] = pattern_to_binary(cc)
        add_all_fonts(0, charset)
--        add_font(c, charset[c + 1])
        
    end if
    
    
end procedure


function char_el_x(atom c)
    atom a
    
    a = 0
    while c >= 32 do
        c = c - 32
        a = a + 1
    end while
    
    return(a)
    
end function


function char_el_y(atom c)
    
    while c >= 32 do
        c = c - 32
    end while
    
    return(c)
    
end function


global function edit_charset(sequence CharSet)
    atom
        curchar,
        x,
        y,
        draw,
        k,
        ox,
        oy,
        ct,
        t,
        mod_flag,
        od,
        f,
        fino,
        old_char
    sequence
        cc,
        fn,
        bufcc,
        copy_buf,
        SS,
        whole_set

    curchar = 0
    x = 1
    y = 1
    draw = 0
    t = 0
    copy_buf = {}
    whole_set = repeat(repeat(7, 64), 8)

    for z = 1 to 8 do
        for a = 1 to 32 do
            whole_set[z][(a * 2) - 1] = t
            t = t + 1
        end for
    end for

    t = 0

    SS = screen_save()
    box(3, 4, 25, 56, 1, "Character Set Editor")
    
    -- CharSet is a standard binary char sequence
    -- cc is an x-pattern single char

    cc = edit_charset_makepattern(CharSet, curchar)
    edit_charset_drawchar(cc)

    text_at(5, 25, "Current character: " & sprintf("%3d", curchar), 15)
    display_text_image({6, 50}, {{curchar, 15}})
    text_at(4, 25, "+/- - select character to edit", 7)
    text_at(6, 25, "Alt+arrows - select character", 7)
    text_at(7, 25, "F1/F2 - copy/paste character", 7)
    text_at(8, 25, "Space - set/clear current pixel", 7)
    text_at(9, 25, "Tab - toggle draw mode", 7)
    text_at(10, 25, "Ctrl+arrows - shift character", 7)
    text_at(11, 25, "H/V - flip horiz./vert.", 7)
    text_at(12, 25, "C - clear current character", 7)
    text_at(13, 25, "S - save current set", 7)
    text_at(14, 25, "L - load set", 7)
    text_at(15, 25, "R - revert char to ASCII", 7)
    text_at(16, 25, "Z - revert char to ZIG", 7)
    text_at(20, 6, "Ctrl+H - help", 7)

    display_text_image({17, 23}, whole_set)

    ct = 0
    add_all_fonts(0, CharSet)
    display_text_image({4 + x, 5 + y}, {"Û" & 14 & "Û" & 14})

    while 1 do
        k = get_key()
        ox = x
        oy = y
        od = draw
        mod_flag = 0
        old_char = -1

        if k = KEY_ESC then
            CharSet[curchar + 1] = pattern_to_binary(cc)
            screen_restore(SS)
            return(CharSet)
        elsif k = KEY_UP then
            x = x - 1
        elsif k = KEY_DN then
            x = x + 1
        elsif k = KEY_LF then
            y = y - 1
        elsif k = KEY_RT then
            y = y + 1
        elsif k = KEY_F1 then
            copy_buf = cc
        elsif k = 'R' or k = 'r' then       -- revert to ASCII
            CharSet[curchar + 1] = default_charset[curchar + 1]
            cc = edit_charset_makepattern(CharSet, curchar)
            mod_flag = 1
        elsif k = 'Z' or k = 'z' then       -- revert to ZIG
            CharSet[curchar + 1] = system_charset[curchar + 1]
            cc = edit_charset_makepattern(CharSet, curchar)
            mod_flag = 1
        elsif k = 8 then
            do_help("edbp")
        elsif k = KEY_F2 then
            if length(copy_buf) != 0 then
                cc = copy_buf
                mod_flag = 1
            end if
        elsif k = 'C' or k = 'c' then
            cc = edit_charset_makepattern(CharSet, 0)
            mod_flag = 1
        elsif k = ' ' then
            if cc[x][y] = 0 then
                cc[x][y] = 'x'
            else cc[x][y] = 0
            end if
            mod_flag = 1
        elsif k = 'S' or k = 's' then
            fn = sb_input(SBI_FILENAME, 20, "Filename?.ZCH", 8)
            if length(fn) > 0 then
                fn = fn & ".zch"
                f = open(fn, "wb")
                save_charset(f, CharSet)
                close(f)
            end if
        elsif k = 'L' or k = 'l' then
            fn = select_file("*.zch", "Select a charset")
            if length(fn) > 1 then
                fino = open(fn, "rb")
                CharSet = load_charset(fino)
                cc = edit_charset_makepattern(CharSet, curchar)
                mod_flag = 1
                close(fino)
            end if
        elsif k = KEY_TAB then
            if draw = 0 then draw = 1 else draw = 0 end if
        elsif k = '+' or k = '=' or k = KEY_PGUP or k = KEY_ALT_RT then
            if curchar != 255 then
                old_char = curchar
                CharSet[curchar + 1] = pattern_to_binary(cc)
                curchar = curchar + 1
            end if
        elsif k = '-' or k = '_' or k = KEY_PGDN or k = KEY_ALT_LF then
            if curchar != 0 then
                old_char = curchar
                CharSet[curchar + 1] = pattern_to_binary(cc)
                curchar = curchar - 1
            end if
        elsif k = KEY_ALT_UP then
            if curchar > 31 then
                old_char = curchar
                CharSet[curchar + 1] = pattern_to_binary(cc)
                curchar = curchar - 32
            end if
        elsif k = KEY_ALT_DN then
            if curchar < 223 then
                old_char = curchar
                CharSet[curchar + 1] = pattern_to_binary(cc)
                curchar = curchar + 32
                cc = edit_charset_makepattern(CharSet, curchar)
            end if
        elsif k = 'V' or k = 'v' then
            bufcc = cc
            for lx = 1 to 14 do
                bufcc[lx] = cc[(14 + 1) - lx]
            end for
            cc = bufcc
            mod_flag = 1
        elsif k = 'H' or k = 'h' then
            bufcc = cc
            for lx = 1 to FONT_HEIGHT do
                for ly = 1 to FONT_WIDTH do
                    bufcc[lx][ly] = cc[lx][(FONT_WIDTH + 1) - ly]
                end for
            end for
            cc = bufcc
            mod_flag = 1
        elsif k = KEY_CT_UP then
            bufcc = cc
            for lx = 1 to FONT_HEIGHT - 1 do
                bufcc[lx] = cc[lx + 1]
            end for
            bufcc[FONT_HEIGHT] = cc[1]
            cc = bufcc
            mod_flag = 1
        elsif k = KEY_CT_DN then
            bufcc = cc
            for lx = 2 to FONT_HEIGHT do
                bufcc[lx] = cc[lx - 1]
            end for
            bufcc[1] = cc[FONT_HEIGHT]
            cc = bufcc
            mod_flag = 1
        elsif k = KEY_CT_LF then
            bufcc = cc
            for lx = 1 to FONT_HEIGHT do
                for ly = 1 to FONT_WIDTH - 1 do
                    bufcc[lx][ly] = cc[lx][ly + 1]
                end for
            end for
            for lx = 1 to FONT_HEIGHT do
                bufcc[lx][FONT_WIDTH] = cc[lx][1]
            end for
            cc = bufcc
            mod_flag = 1
        elsif k = KEY_CT_RT then
            bufcc = cc
            for lx = 1 to FONT_HEIGHT do
                for ly = 2 to FONT_WIDTH do
                    bufcc[lx][ly] = cc[lx][ly - 1]
                end for
            end for
            for lx = 1 to FONT_HEIGHT do
                bufcc[lx][1] = cc[lx][FONT_WIDTH]
            end for
            cc = bufcc
            mod_flag = 1
        end if

        if x != ox or y != oy or od != draw then
            if x < 1 then
                x = 1
            end if
            if y < 1 then
                y = 1
            end if
            if x > font_height then
                x = font_height
            end if
            if y > FONT_WIDTH then
                y = FONT_WIDTH
            end if

            t = 50001
            if draw = 1 then
                cc[x][y] = 'x'
                mod_flag = 1
            end if
            if cc[ox][oy] = 'x' then
                display_text_image({4 + ox, 4 + oy*2}, {"Û‡Û‡"})
            else display_text_image({4 + ox, 4 + oy*2}, {"ú‡ú‡"})
            end if

        end if

        if mod_flag = 1 then
            put_screen_char(17 + char_el_x(curchar), 23 + char_el_y(curchar), {curchar, 15})

            CharSet[curchar + 1] = pattern_to_binary(cc)
            edit_charset_drawchar(cc)
            add_all_fonts(0, CharSet)
            --font(curchar, cc)
        end if
        
        if old_char != -1 then
            put_screen_char(17 + char_el_x(old_char), 23 + char_el_y(old_char), {old_char, 7})
            put_screen_char(17 + char_el_x(curchar), 23 + char_el_y(curchar), {curchar, 142})

            cc = edit_charset_makepattern(CharSet, curchar)
            edit_charset_drawchar(cc)
            bk_color(1)
            text_at(5, 25, "Current character: " & sprintf("%3d", curchar), 15)
            display_text_image({5, 50}, {{curchar, 15}})
        end if

        t = t + 1
        if t > 10000 then
            t = 0
            if ct = 0 then
                display_text_image({4 + x, 4 + y*2}, {"Û" & 14 & "Û" & 14})
                ct = 1
            else
                if cc[x][y] = 'x' then
                    display_text_image({4 + x, 4 + y*2}, {"Û‡Û‡"})
                else display_text_image({4 + x, 4 + y*2}, {"ú‡ú‡"})
                end if
                ct = 0
            end if
        end if

    end while
    return(CharSet)
end function


function sidebar_button_color_rotate(atom s)

    if s = 3 then return(7) else return(3) end if

end function


function confirm(sequence title, sequence caption)

    atom tw, r, ll
    sequence ss

    ss = screen_save()

    ll = length(caption)
    if length(title) > ll then
        ll = length(title)
    end if

    tw = (screen_sizey / 2) - ((ll + 6) / 2)
    box(10, tw, 14, tw + ll + 6, 1, title)

    text_at(12, tw + 3, caption, 14)

    while 1 do
        r = upper(get_key())
        if r = 'Y' then screen_restore(ss) return(1)
        elsif r = 'N' or r = KEY_ESC then screen_restore(ss) return(0)
        end if
    end while


end function


procedure msg(sequence title, sequence caption)

    atom tw, r, ll
    sequence ss

    ss = screen_save()

    ll = length(caption)
    if length(title) > ll then
        ll = length(title)
    end if

    tw = (screen_sizey / 2) - ((ll + 6) / 2)
    box(10, tw, 14, tw + ll + 6, 1, title)

    text_at(12, tw + 3, caption, 14)

    r = wait_key()
    
    screen_restore(ss)
    clear_keys()

end procedure


global function modify_object_props(sequence obj, sequence lib)
    atom n
    sequence nn, old, ss
    
    ss = screen_save()

    n = 0
    old = obj[1][OBJ_PROPS]
    obj[1][OBJ_PROPS] = {}

    sidebar_clear()
    box(4, 61, 21, 80, 1, lib[LIB_NAME])

    text_color(14)
    for z = 1 to length(lib[LIB_PROPS]) do
        position(3 + (z * 3), 63)
        puts(1, lib[LIB_PROPS][z][PROP_NAME])
    end for
    
    for z = 1 to length(lib[LIB_PROPS]) do
        position(3 + (z * 3), 63)
        text_color(15)
        bk_color(1)
        puts(1, lib[LIB_PROPS][z][PROP_NAME] & "? ")
        if length(old) >= z then
            if old[z] != 0 then
                text_color(7)
                printf(1, "(%d)", old[z])
            end if
        end if
        text_color(14)
        position((3 + (z * 3)) + 1, 63)
        if lib[LIB_PROPS][z][PROP_TYPE] = CHOOSE_NUM then
            bk_color(0)
            puts(1, "   ")
            bk_color(1)
            printf(1, " (max: %d)  ", lib[LIB_PROPS][z][PROP_MAX])
            while TRUE do
                cursor(UNDERLINE_CURSOR)
                position((3 + (z * 3)) + 1, 63)
                nn = gets(0)
                nn = value(nn[1..length(nn) - 1])
                n = nn[2]
                if lib[LIB_PROPS][z][PROP_MAX] >= n then
                    position((3 + (z * 3)) + 1, 63)
                    bk_color(1)
                    if n = 0 then
                        if length(old) >= z then
                            n = old[z]
                        end if
                    end if
                    printf(1, "%3d", n)
                    obj[1][OBJ_PROPS] = obj[1][OBJ_PROPS] & {n}
                    exit
                else
                    position((3 + (z * 3)) + 1, 63)
                    bk_color(0)
                    puts(1, "   ")
                    bk_color(1)
                    printf(1, " (max: %d)  ", lib[LIB_PROPS][z][PROP_MAX])
                end if
                cursor(NO_CURSOR)
            end while
        elsif lib[LIB_PROPS][z][PROP_TYPE] = CHOOSE_BOARD then
            n = select_board(1, TRUE)
            position((3 + (z * 3)) + 1, 63)
            bk_color(1)
            if n = 0 then
                if length(old) >= z then
                    n = old[z]
                end if
            end if
            printf(1, "%3d", n)
            obj[1][OBJ_PROPS] = obj[1][OBJ_PROPS] & {n}
        elsif lib[LIB_PROPS][z][PROP_TYPE] = CHOOSE_CHAR then
            n = dlg_get_char(0)
            position((3 + (z * 3)) + 1, 63)
            bk_color(1)
            if n = 0 then
                if length(old) >= z then
                    n = old[z]
                end if
            end if
            printf(1, "%3d", n)
            obj[1][OBJ_PROPS] = obj[1][OBJ_PROPS] & {n}
        elsif lib[LIB_PROPS][z][PROP_TYPE] = CHOOSE_COLOR then
            n = dlg_get_color(15)
            position((3 + (z * 3)) + 1, 63)
            text_color(color_element_fore(n))
            bk_color(color_element_back(n))
            puts(1, 254)
            obj[1][OBJ_PROPS] = obj[1][OBJ_PROPS] & {n}
        end if
        position(3 + (z * 3), 63)
        text_color(14)
        bk_color(1)
        puts(1, lib[LIB_PROPS][z][PROP_NAME] & " ")
    end for
    
    screen_restore(ss)

    return(obj)

end function


procedure dlg_library_menu(atom board, atom x, atom y, atom layer, atom color)

    atom r1, r2, k, m
    sequence ss, object_libout
    object uv1, uv2, uv3, uv4


    ss = screen_save()
    
    sidebar_clear()
    box(3, 61, 20, 80, 1, "Categories")
    uv1 = repeat(0, length(class_table))
    for z = 1 to length(class_table) do
        if find(class_table[z][1], uv1) != 0 then
            uv2 = 2
            while TRUE do
                if find(class_table[z][uv2], uv1) = 0 then
                    uv1[z] = class_table[z][uv2]
                    exit
                else uv2 = uv2 + 1
                    if uv2 > length(class_table[z]) then
                        uv1[z] = '0'
                        exit
                    end if
                end if
            end while
        else uv1[z] = class_table[z][1]
        end if
    end for

    uv2 = 3    
    for z = 1 to length(class_table) do
        uv2 = sidebar_button_color_rotate(uv2)
        text_color(0)
        bk_color(uv2)
        position(3 + z, 63)
        puts(1, " " & upper(uv1[z]) & " ")
        text_color(14)
        bk_color(1)
        puts(1, " " & upper(class_table[z][1]) & class_table[z][2..length(class_table[z])])
    end for
    
    uv2 = 0
    while TRUE do
        uv3 = wait_key()
        if uv3 = KEY_CR
        or uv3 = KEY_ESC then
            screen_restore(ss)
            return
        end if
        uv3 = lower(uv3)
        ?uv3
        for z = 1 to length(uv1) do
            ?uv1[z]
            if uv3 = uv1[z] then
                uv2 = z
                exit
            end if
        end for
        if uv2 != 0 then
            exit
        end if
    end while

    object_libout = {}    
    for z = 1 to length(object_library) do
        if object_library[z][LIB_CLASS] = uv2 then
            object_libout = append(object_libout, object_library[z])
        end if
    end for

    r1 = r1_store
    r2 = r1 + 15
    --r2 = length(object_libout)
    if r2 > length(object_libout) then r2 = length(object_libout) end if

    while TRUE do
        sidebar_clear()

        box(3, 61, 20, 80, 1, "Choose an Object")
        uv1 = repeat(0, length(object_libout) + 1)
        uv3 = 3
        sb_print(1, "Building key", 15)
        sb_print(2, "table...", 15)
        
        for z = r1 to r2 do
            uv2 = 1
            while TRUE do
                uv1[z] = upper(object_libout[z][LIB_NAME][uv2])
                uv1[length(object_libout) + 1] = FALSE
                if uv1[z] = ' ' then
                    uv1[z] = uv1[r1]
                end if
                for a = r1 to z - 1 do
                    if uv1[a] = uv1[z] then
                        uv2 = uv2 + 1
                        if uv2 > length(object_libout[z][LIB_NAME]) then
                            uv1[length(uv1)] = TRUE
                            for b = 'A' to 'Z' do
                                for c = r1 to z - 1 do
                                    if uv1[c] = b then
                                        uv1[length(uv1)] = FALSE
                                        exit
                                    else uv1[length(uv1)] = TRUE
                                    end if
                                end for
                                if uv1[length(uv1)] = TRUE then
                                    uv1[length(uv1)] = 2
                                    uv1[z] = b
                                    exit
                                end if
                            end for
                            if uv1[length(uv1)] = FALSE then
                                uv1[length(uv1)] = TRUE
                                for b = '0' to '9' do
                                end for
                            end if
                        end if
                        if uv1[length(uv1)] = 2 then
                            uv1[length(uv1)] = FALSE
                            exit
                        else
                            uv1[length(uv1)] = TRUE
                            exit
                        end if
                    end if
                end for
                if uv1[length(uv1)] = FALSE then
                    exit
                end if
            end while
            sb_btnprint(3 + (z - (r1 - 1)), {uv1[z]}, object_libout[z][LIB_NAME], uv3)
            uv3 = sidebar_button_color_rotate(uv3)
        end for
        sb_print(1, "            ", 15)
        sb_print(2, "        ", 15)

        sb_btnprint(21, "PU", "Move list up", uv3)  uv3 = sidebar_button_color_rotate(uv3)
        sb_btnprint(22, "PD", "Move list down", uv3)

        uv2 = FALSE
        uv4 = FALSE
        while TRUE do

            k = get_key()

            if k != -1 then
                if k = KEY_PGUP then
                    uv4 = r1
                    r1 = r1 - 1

                    if r1 < 1 then
                        r1 = 1
                    end if

                    if uv4 != r1 then
                        r2 = r1 + 15
                        uv4 = TRUE
                        exit
                    else
                        uv4 = FALSE
                    end if
                elsif k = KEY_PGDN then
                    uv4 = r1
                    r1 = r1 + 1

                    if r1 + 15 > length(object_libout) then
                        r1 = uv4
                    end if

                    if uv4 != r1 then
                        r2 = r1 + 15
                        uv4 = TRUE
                        exit
                    else
                        uv4 = FALSE
                    end if
                elsif k = KEY_CR or k = KEY_ESC then
                    r1_store = r1
                    exit
                else
                    k = upper(k)
                    for z = r1 to r2 do
                        uv1[length(uv1)] = FALSE
                        if k = uv1[z] then
                            eset(board, x, y, layer, BRD_TILECHAR, 0)
                            eset(board, x, y, layer, BRD_TILECOLOR, 0)
                            if find_object(board, x, y, layer) then
                                delete_object(board, find_object(board, x, y, layer))
                            end if
                            m = new_object(board)
                            oset(board, m, OBJ_X, x)
                            oset(board, m, OBJ_Y, y)
                            oset(board, m, OBJ_LAYER, layer)
                            oset(board, m, OBJ_NAME, object_libout[z][LIB_NAME])
                            oset(board, m, OBJ_LIBFROM, object_libout[z][LIB_FROM])
                            world[WRLD_BOARDS][board][BRD_OBJECTS][m] = modify_object_props(world[WRLD_BOARDS][board][BRD_OBJECTS][m], object_libout[z])
                            world[WRLD_BOARDS][board][BRD_OBJECTS][m] = {world[WRLD_BOARDS][board][BRD_OBJECTS][m][1]} & object_libout[z][LIB_PROG]
                            if object_libout[z][LIB_CHAR] = -1 then
                                oset(board, m, OBJ_CHAR, dlg_get_char(0))
                            else
                                oset(board, m, OBJ_CHAR, object_libout[z][LIB_CHAR])
                            end if
                            if object_libout[z][LIB_COLOR] = -1 then
                                oset(board, m, OBJ_COLOR, color)
                            else
                                oset(board, m, OBJ_COLOR, object_libout[z][LIB_COLOR])
                            end if
                            oset(board, m, OBJ_LIBFROM, object_libout[z][LIB_FROM])
                            uv1[length(uv1)] = TRUE
                            r1_store = r1
                            exit
                        end if
                    end for
                    if uv1[length(uv1)] then
                        r1_store = r1
                        exit
                    end if
                end if
            end if
        end while
        if uv4 = FALSE then exit end if
    end while
    
    r1_store = r1 
    screen_restore(ss)
    
end procedure


procedure dlg_do_transfer(atom board)

    atom t_type, t_item, f
    sequence result, a, ftype, fname

    while 1 do

        result = do_scroll("Transfer Operations: Step 1",
                    {"Which transfer type?","",
                     "!" & 1 & ";Import",
                     "!" & 2 & ";Export","",
                     "ESC to cancel"}, 3)

        if length(result) then t_type = result[1] else exit end if

        if t_type = 1 then a = "import" else a = "export" end if

        result = do_scroll("Transfer Operations: Step 2",
                {"Item to " & a & "?","",
                 "!" & 1 & ";Board",
                 "!" & 2 & ";Palette",
                 "!" & 3 & ";Charset",
                 "ESC to cancel"}, 3)

        if length(result) then t_item = result[1] else exit end if

        if t_item = 1 then ftype = ".ZBR"
        elsif t_item = 2 then ftype = ".ZPL"
        elsif t_item = 3 then ftype = ".ZCH"
        end if

        if t_type = 1 then
            fname = select_file("*" & ftype, "Select a file")
        else
            fname = sb_input(SBI_FILENAME, 20, "Export file?" & ftype[2..4], 8)
            fname = fname & ftype
        end if

        if length(fname) < 5 then
            exit
        end if

        if t_type = 1 then      -- import

            f = open(fname, "rb")

            if t_item = 1 then
                world[WRLD_BOARDS][board] = load_board(f, NEW_BOARD)
            elsif t_item = 2 then
                world[WRLD_BOARDS][board][BRD_PAL] = load_palette(f)
            elsif t_item = 3 then
                world[WRLD_BOARDS][board][BRD_CHARSET] = load_charset(f)
            end if

            close(f)

        else

            f = open(fname, "wb")

            if t_item = 1 then
                save_board(f, world[WRLD_BOARDS][board])
            elsif t_item = 2 then
                save_palette(f, world[WRLD_BOARDS][board][BRD_PAL])
            elsif t_item = 3 then
                save_charset(f, world[WRLD_BOARDS][board][BRD_CHARSET])
            end if

            close(f)

        end if

        exit
    end while

end procedure


procedure editpal_bars(sequence C, atom s)

    for z = 1 to 3 do

        if s = z then
            text_color(15)
        else text_color(7)
        end if

        position(8 + z, 25)
        bk_color(0)
        puts(1, repeat(32, 31))

        position(8 + z, 25)
        bk_color(0)
        if C[z] / 2 > 1 then
            puts(1, repeat(219, (C[z] / 2) - 1))  --196
            if floor(C[z] / 2) != C[z] / 2 then
                puts(1, 'Ý')
            end if
        end if

        position(8 + z, 55)
        printf(1, "%3d", C[z])
    end for

end procedure


procedure editpal_rbars()
    text_color(15)
    for z = 1 to 3 do
        position(8 + z, 25)
        bk_color(1)
        puts(1, repeat(32, 32))
        position(8 + z, 52)
        printf(1, "   ", {})
    end for
end procedure


procedure editpal_draw_arrow(atom a)

    position(14, 4)
    bk_color(1)
    puts(1, repeat(32, 16))
    position(14, 4 + a)
    text_color(15)
    puts(1, 25)
    
end procedure


-- spaghetti koad... yes, sad
global function edit_pal(object Pal)
    atom
        C,
        oC,
        k,
        f,
        sele
    sequence
        CurC,
        fn,
        ss
    object ju

    set_all_pal(Pal)
    ss = screen_save()

    C = 1
    sele = 1
    CurC = get_palette(C)

    box(7, 2, 16, 59, 1, "Palette Editor")
    text_at(9, 4, "Color: " & sprint(C), 15)
    box(10, 4, 13, 8, 0, "")
    display_text_image({11, 5}, repeat({219,C,219,C,219,C}, 2))
    display_text_image({15, 4}, {{32,0,219,1,219,2,219,3,219,4,219,5,219,6,219,7,219,8,219,9,219,10,219,11,219,12,219,13,219,14,219,15}})
    bk_color(1)
    text_at(12, 15, ",,, - change/edit element", 15)
    text_at(13, 15, "+/- - change current color", 15)
    text_at(15, 25, "ESC - exit  S/L - save/load", 15)

    editpal_bars(CurC, sele)
    editpal_draw_arrow(sele)

    while 1 do
        oC = C
        k = get_key()

        if k = 'R' then
            if CurC[1] <= 62 then CurC[1] = CurC[1] + 1 oC = -1 end if
        elsif k = KEY_LF then
            if CurC[sele] > 0 then CurC[sele] = CurC[sele] - 1 oC = -1 end if
        elsif k = KEY_RT then
            if CurC[sele] <= 62 then CurC[sele] = CurC[sele] + 1 oC = -1 end if
        elsif k = KEY_UP then
            if sele != 1 then
                sele = sele - 1
                oC = -1
            end if
        elsif k = KEY_DN then
            if sele != 3 then
                sele = sele + 1
                oC = -1
            end if
        elsif k = 'H' or k = 'h' then
            do_help("edbp")
        elsif k = 'r' then
            if CurC[1] > 0 then CurC[1] = CurC[1] - 1 oC = -1 end if
        elsif k = 'G' then
            if CurC[2] <= 62 then CurC[2] = CurC[2] + 1 oC = -1 end if
        elsif k = 'g' then
            if CurC[2] > 0 then CurC[2] = CurC[2] - 1 oC = -1 end if
        elsif k = 'B' then
            if CurC[3] <= 62 then CurC[3] = CurC[3] + 1 oC = -1 end if
        elsif k = 'b' then
            if CurC[3] > 0 then CurC[3] = CurC[3] - 1 oC = -1 end if
        elsif k = KEY_ESC then

            fn = {}

            for z = 0 to 15 do
                fn = append(fn, get_palette(z))
            end for

            screen_restore(ss)

            return(fn)

        elsif k = '+' or k = '=' then
            if C < 15 then
                C = C + 1
                CurC = get_palette(C)
                editpal_rbars()
            end if
        elsif k = '-' or k = '_' then
            if C > 0 then
                C = C - 1
                CurC = get_palette(C)
                editpal_rbars()
            end if
        elsif k = 'S' or k = 's' then
            fn = sb_input(SBI_FILENAME, 20, "Filename?.ZPL", 8)
            fn = fn & ".zpl"
            f = open(fn, "wb")
            ju = {}
            for z = 1 to 16 do
                ju = ju & {get_palette(z - 1)}
            end for
            save_palette(f, ju)
            close(f)
        elsif k = 'L' or k = 'l' then
            fn = select_file("*.zpl", "Select a palette")
            if not atom(dir(fn)) then
                f = open(fn, "rb")
                CurC = load_palette(f)
                set_all_pal(CurC)
                CurC = CurC[C]
                close(f)
            end if
        end if

        if C != oC then
            if oC != -1 then
                text_at(9, 4, "Color: " & sprint(C) & " ", 15)
                box(10, 4, 13, 8, 0, "")
                display_text_image({11, 5}, repeat({219,C,219,C,219,C}, 2))
            end if
            editpal_draw_arrow(C)
            editpal_bars(CurC, sele)
            set_palette(C, CurC)
        end if
    end while

end function


function dlg_get_block_coords(sequence curs, sequence limits, sequence prev_coords, sequence offsets)

    atom x, y, select, k, old_x, old_y, flag
    sequence saved_screen, corners, inv_buffer, g

    saved_screen = screen_save()

    if length(prev_coords) then
        corners = prev_coords
    else corners = {{1, 1}, {1, 1}}
    end if

    for z = 1 to 2 do

        sidebar_clear()

        flag = TRUE

        bk_color(1)

        sb_print(3, "Move cursor to", 14)
        sb_print(5, "of block and press", 14)
        sb_print(6, "Space.", 14)

        sb_btnprint(8, "L", "Use Last Block", 3)
        sb_btnprint(9, "P", "Paste", 7)
        sb_btnprint(11, "ESC", "Cancel", 3)

        if z = 1 then
            sb_print(4, "upper-left corner", 14)
            x = curs[1]
            y = curs[2]
        else
            sb_print(4, "lower-right corner", 14)
        end if

        select = FALSE

        while not select do

            k = get_key()

            old_x = x
            old_y = y

            if k = KEY_ESC then
                corners = {}
                select = -2
                exit
            elsif k = KEY_UP then
                x = x - 1
            elsif k = KEY_DN then
                x = x + 1
            elsif k = KEY_LF then
                y = y - 1
            elsif k = KEY_RT then
                y = y + 1
            elsif k = 'L' or k = 'l' then
                corners = prev_coords
                select = -2
                exit
            elsif k = KEY_CR or k = 32 then
                if z = 1 then
                    corners[1][1] = x
                    corners[1][2] = y
                else
                    corners[2][1] = x
                    corners[2][2] = y
                end if
                exit
            elsif k = 'P' or k = 'p' then
                corners = {-1}
                select = -2
                exit
            end if

            if x != old_x or y != old_y or flag then
            
                if z = 2 then
                    if x < corners[1][1] then
                        x = old_x
                    end if
                    if y < corners[1][2] then
                        y = old_y
                    end if
                end if

                if not flag then
                    screen_restore(inv_buffer)
                end if

                flag = FALSE

                if x > limits[1] then x = limits[1] end if
                if y > limits[2] then y = limits[2] end if
                if x < 1 then x = 1 end if
                if y < 1 then y = 1 end if

                g = save_text_image({old_x - offsets[1], old_y - offsets[2]}, {old_x - offsets[1], old_y - offsets[2]})

                inv_buffer = screen_save()

                if z = 2 then
                    invert_area(corners[1], {x - offsets[1], y - offsets[2]})
                end if

                display_text_image({x - offsets[1], y - offsets[2]}, {{CSR_NORMAL, 15}})
            end if

        end while

        if select = -2 then
            exit
        end if

    end for

    screen_restore(saved_screen)

    return(corners)

end function


function dlg_get_block_action()

    atom k, sel
    sequence saved_screen

    saved_screen = screen_save()

    sidebar_clear()

    sb_print(3, "Block Action?", 15)
    sb_btnprint(6, "C", "Copy", 7)
    sb_btnprint(7, "F", "Fill w/ Pattern", 3)
    sb_btnprint(8, "E", "Erase", 7)
    --sb_btnprint(9, "S", "Save", 3)
    --sb_btnprint(10, "L", "Load", 7)
    sb_btnprint(10, "ESC", "Cancel", 3)

    sel = FALSE

    while not sel do

        k = upper(get_key())

        if k = KEY_ESC then sel = BS_CANCEL
        elsif k = 'C' then sel = BS_COPY
        elsif k = 'F' then sel = BS_FILL
        elsif k = 'E' then sel = BS_ERASE
        end if

    end while

    screen_restore(saved_screen)

    return(sel)

end function


function dlg_get_block_fill_sort()

    atom k
    sequence saved_screen

    saved_screen = screen_save()

    sidebar_clear()

    sb_print(3, "Fill Type?", 15)

    sb_print(6, "Press any key to", 14)
    sb_print(7, "fill with the", 14)
    sb_print(8, "current pattern and", 14)
    sb_print(9, "color.", 14)

    sb_print(11, "Or, fill with:", 15)
    sb_btnprint(12, "C", "Color only", 3)
    sb_btnprint(13, "P", "Pattern only", 7)

    sb_btnprint(15, "ESC", "Cancel", 3)

    k = upper(wait_key())

    if k = 'C' then return(1)
    elsif k = 'P' then return(2)
    elsif k = KEY_ESC then return(-1)
    else return(0)
    end if

end function


procedure configure()

    atom cur, k, ocur
    sequence ss
    
    return

    cur = 1

    ss = screen_save()

    box(3, 5, 22, 55, 1, "ZIG Configuration")

    text_color(14)

    for z = 1 to length(CONFIG_OPTIONS) do

        position(4 + z, 8)
        puts(1, CONFIG_OPTIONS[z])
        position(4 + z, 48)
        printf(1, "%5d", config[z + 1])

    end for

    position(6 + length(CONFIG_OPTIONS), 8)
    puts(1, "Select an option and press Enter to change")
    position(7 + length(CONFIG_OPTIONS), 8)
    puts(1, "its value. Press ESC to exit.")

    while TRUE do

        ocur = cur
        k = get_key()

        if k = KEY_UP then
            cur = cur - 1
        elsif k = KEY_DN then
            cur = cur + 1
        elsif k = KEY_ESC then
            exit
        end if

        if cur != ocur then

            if cur < 1 then
                cur = 1
            end if

            if cur > length(CONFIG_OPTIONS) then
                cur = length(CONFIG_OPTIONS)
            end if

            text_color(14)
            bk_color(1)
            position(4 + ocur, 8)
            puts(1, CONFIG_OPTIONS[ocur])
            position(4 + ocur, 48)
            printf(1, "%5d", config[ocur + 1])

            text_color(15)
            bk_color(0)
            position(4 + cur, 8)
            puts(1, CONFIG_OPTIONS[cur])
            position(4 + cur, 48)
            printf(1, "%5d", config[cur + 1])


        end if

    end while

    screen_restore(ss)

end procedure


procedure draw_single_prop(sequence prop, object data, atom num, atom is_sel)

    if not is_sel then
        text_color(14)
        bk_color(1)
    else
        text_color(15)
        bk_color(0)
    end if

    position(3 + num, 8)
    puts(1, prop[PROP_DATA_NAME])

    position(3 + num, 33)

    if prop[PROP_DATA_TYPE] = PROP_VALUE
    or prop[PROP_DATA_TYPE] = PROP_VALUE_CONFIRMED then
        print(1, data)
    elsif prop[PROP_DATA_TYPE] = PROP_STRING then
        puts(1, data)
    elsif prop[PROP_DATA_TYPE] = PROP_PALETTE then
        puts(1, "(palette)")
    elsif prop[PROP_DATA_TYPE] = PROP_CHARSET then
        puts(1, "(character set)")
    elsif prop[PROP_DATA_TYPE] = PROP_OBJECT then
        puts(1, "(object)")
    elsif prop[PROP_DATA_TYPE] = PROP_BOOLEAN then
        if data then
            puts(1, "On ")
        else puts(1, "Off")
        end if
    elsif prop[PROP_DATA_TYPE] = PROP_BOARD then
        if data != BRD_NO_EXIT then
            puts(1, world[WRLD_BOARDS][data][BRD_NAME])
        else puts(1, "(no board selected)")
        end if
    end if

    --{"Board Size X", BRD_SIZEX, PROP_VALUE_CONFIRMED}
end procedure


function edit_property(sequence prop, object data, atom select)

    object o

    position(3 + select, 33)
    text_color(15)
    bk_color(0)

    if prop[PROP_DATA_TYPE] = PROP_VALUE
    or prop[PROP_DATA_TYPE] = PROP_VALUE_CONFIRMED then

        puts(1, "   ")
        o = data
        position(3 + select, 33)
        cursor(THICK_UNDERLINE_CURSOR)
        data = value(prompt_string({}))
        cursor(NO_CURSOR)
        if data[2] = 0 then
            data[2] = o
        end if
        data = data[2]

    elsif prop[PROP_DATA_TYPE] = PROP_STRING then

        puts(1, repeat(32, 20))
        position(3 + select, 33)
        cursor(THICK_UNDERLINE_CURSOR)
        data = prompt_string({})
        cursor(NO_CURSOR)

    elsif prop[PROP_DATA_TYPE] = PROP_PALETTE then

        if length(data) = 0 then
            data = system_palette
        end if
        data = edit_pal(data)

    elsif prop[PROP_DATA_TYPE] = PROP_CHARSET then

        if length(data) = 0 then
            data = system_charset
        end if
        data = edit_charset(data)

    elsif prop[PROP_DATA_TYPE] = PROP_OBJECT then
        
        data = edit_controller_object(data)

    elsif prop[PROP_DATA_TYPE] = PROP_BOARD then

        data = select_board(data, TRUE)
        
    elsif prop[PROP_DATA_TYPE] = PROP_BOOLEAN then
        
        if data then
            data = FALSE
        else data = TRUE
        end if

    end if

    draw_single_prop(prop, data, select, TRUE)

    return(data)

end function


procedure draw_props(sequence props, sequence data, atom select)

    for z = 1 to length(props) do

        if select = z then
            draw_single_prop(props[z], data[z], z, TRUE)
        else
            draw_single_prop(props[z], data[z], z, FALSE)
        end if
    end for

end procedure


function dlg_edit_props(sequence props, sequence data, sequence caption, atom board)

    atom
        select,
        runmode,
        k,
        old
    sequence
        saved_screen,
        old_vals

    saved_screen = screen_save()

    box(2, 5, 7 + length(props), 58, 1, caption)

    position(5 + length(props), 8)
    puts(1, "Press Enter to modify a property.")
    position(6 + length(props), 8)
    puts(1, "Press ESC to exit.")

    if board != 0 then
        old_vals = data[1..3]
    end if

    select = 1
    runmode = RUNNING

    draw_props(props, data, select)

    while runmode = RUNNING do

        old = select
        k = get_key()

        if k = KEY_UP then
            select = select - 1
        elsif k = KEY_DN then
            select = select + 1
        elsif k = 'H' or k = 'h' then
            if length(props) > 7 then
                do_help("edbp")
            else do_help("edwp")
            end if
        elsif k = KEY_CR then
            data[select] = edit_property(props[select], data[select], select)

            box(2, 5, 7 + length(props), 58, 1, caption)

            position(5 + length(props), 8)
            puts(1, "Press Enter to modify a property.")
            position(6 + length(props), 8)
            puts(1, "Press ESC to exit.")
            draw_props(props, data, select)

        elsif k = KEY_ESC then
            runmode = STOP
        end if

        if select != old then

            if select < 1 then
                select = 1 end if

            if select > length(props) then
                select = length(props) end if

            draw_single_prop(props[old], data[old], old, FALSE)
            draw_single_prop(props[select], data[select], select, TRUE)

        end if

    end while

    if board != 0 then
        if compare(data[1..3], old_vals) then
                resize_board(board, data[1..3])
        end if
    end if

    screen_restore(saved_screen)
    return(data)

end function


function temp_get_main_selection()

    atom
        key,
        return_val

    key = -1
    return_val = 0

    while return_val = 0 do

        key = get_key()

        if key != -1 then

            key = upper(key)

            if key = 'W' then return(1)
            elsif key = 'P' then return(2)
            elsif key = 'R' then return(3)
            elsif key = 'E' then return(4)
            elsif key = 'A' then return(5)
            elsif key = 'H' then return(6)
--            elsif key = 'C' then return(8)
            elsif key = 'Q'
            or key = 27 then return(7)
            end if

        end if

    end while

end function


procedure apply_board_settings(atom board)

    if length(world[WRLD_BOARDS][board][BRD_PAL]) then
        set_all_pal(world[WRLD_BOARDS][board][BRD_PAL])
    else set_all_pal(system_palette)
    end if

    if length(world[WRLD_BOARDS][board][BRD_CHARSET]) then
        charset = world[WRLD_BOARDS][board][BRD_CHARSET]
    else charset = system_charset
    end if
    
    add_all_fonts(0, charset)

    if config[SOUND_ON] = ON then
        if length(world[WRLD_BOARDS][board][BRD_MUSICFILE]) != 0 then
            if compare(world[WRLD_BOARDS][board][BRD_MUSICFILE], current_mod) != 0 then
                if load_mod(world[WRLD_BOARDS][board][BRD_MUSICFILE]) then end if
                current_mod = world[WRLD_BOARDS][board][BRD_MUSICFILE]
                unpause_sound()
            end if
        end if
    end if

end procedure


procedure intro()

    atom ff, tt

    ff = open("zig.lg", "rb")
    if ff != -1 then
        world[WRLD_BOARDS][1] = load_board(ff, NEW_BOARD)
        close(ff)
    else
        return
    end if

    apply_board_settings(1)

    fade_in_start()
    draw_board(1, {0, 0}, VISIBLE_ALL_ON, {1, 1, 25, 80})
    fade_in(5 * (config[FAST_FADES] + 1))

    set_palette(0, {63,63,63})
    for z = 1 to 500 do end for
    set_palette(0, {0,0,0})
    tt = time() + 1.5
    while tt > time() and get_key() = -1 do end while

    fade_out(5 * (config[FAST_FADES] + 1))
    clear_screen()
    clear_world()
    apply_board_settings(1)

end procedure


procedure draw_board_title()

    if world[WRLD_TITLEBRD] > 0 then
        draw_board(world[WRLD_TITLEBRD], {0, 0}, VISIBLE_ALL_ON, {1, 1, screen_sizex, screen_sizey - sidebar_width})
        apply_board_settings(world[WRLD_TITLEBRD])
    end if

end procedure


function handle_main_screen()

    draw_board_title()

    if first_load then
        fade_in_start()
    end if

    sidebar_clear()
    sb_cenprint(2, "úù - " & H & H & H & " - ùú", 15, 1)
    sb_cenprint(3, "     ZIG     ", 0, 7)
    sb_cenprint(4, "úù - " & H & H & H & " - ùú", 15, 1)

    sb_btnprint(7, "W", "World:", 7)

    if length(world[WRLD_FILENAME]) then
        sb_cenprint(8, ' ' & world[WRLD_FILENAME] & ' ', 15, 0)
    else
        sb_cenprint(8, " (none) ", 15, 0)
    end if

    sb_btnprint(10, "P", "Play World", 3)
    sb_btnprint(11, "R", "Restore Game", 7)
    sb_btnprint(12, "E", "World Editor", 3)

    sb_btnprint(14, "A", "About ZIG", 3)
    sb_btnprint(15, "H", "Help!", 7)
    sb_btnprint(16, "Q", "Quit ZIG", 3)

    sb_print(20, "ZIG version " & VERSION & '.', 7)
    sb_print(21, "(C) " & COPYRIGHT & ",", 7)
    sb_print(22, "Jacob Hammond.", 7)
    sb_print(23, "ZIG is freeware", 7)
    sb_print(24, "under the GNU GPL.", 7)

    if first_load then
        first_load = FALSE
        fade_in(5 * (config[FAST_FADES] + 1))
    end if

    return(temp_get_main_selection())

end function


function integer_divide(atom a, atom b)
    if remainder(a, b) then
        return((a / b) - .5)
    else return((a / b))
    end if

end function


function pattern_has_object(sequence p)

    if length(p) = 2 then
        if length(p[2]) != 0 then
            return(TRUE)
        end if
    end if

    return(FALSE)

end function


procedure editor_draw_patterns(sequence pattern_data, atom pattern)
    atom
        s1,
        s2
    sequence put

    put = {}

    pattern_data = pattern_data & {{'N', {}}}

    if pattern > length(pattern_data) then
        pattern = length(pattern_data)
    end if

    s1 = pattern - 8
    s2 = pattern + 9
    for z = s1 to s2 do
        if z > 0 and z <= length(pattern_data) then
            if z = pattern then
                if length(pattern_data[z]) = 2 then
                    put = put & {pattern_data[z][PAT_CHAR], color_attribute(0, 14)}
                else
                    put = put & {pattern_data[z][PAT_CHAR], 14}
                end if
            else
                if pattern_data[z][PAT_CHAR] = 'N'
                and length(pattern_data[z]) = 2 then
                    if length(pattern_data[z][PAT_OBJECT]) = 0 then
                        put = put & {'N', color_attribute(14, 8)}
                    end if
                elsif length(pattern_data[z]) = 2 then
                    put = put & {pattern_data[z][PAT_CHAR], color_attribute(0, 7)}
                else
                    put = put & {pattern_data[z][PAT_CHAR], 7}
                end if
            end if
        else put = put & {32, 31}
        end if
    end for

    display_text_image({5, 62}, {put})

end procedure


procedure editor_draw_color(object color)

    if sequence(color) then
        if length(color) = 1 then
            color = color[1]
        else
            color = color_attribute(color[1], color[2])
        end if
    end if

    display_text_image({8, 73}, {{254, color}})

end procedure


procedure editor_draw_boardnum(atom board)

    position(18, 73)

    text_color(15)
    bk_color(1)

    printf(1, "%d  ", board)

end procedure


procedure editor_draw_layer(atom layer)

    position(19, 74)

    text_color(15)
    bk_color(1)

    printf(1, "%d  ", layer)

end procedure


procedure editor_draw_drawstatus(atom d)

    position(11, 77)

    text_color(14)
    bk_color(1)

    if d = DRAWING_ON then
        text_color(15)
        puts(1, "On  ")
    elsif d = DRAWING_TEXT then
        text_color(13)
        puts(1, "Text")
    else
        puts(1, "Off ")
    end if

end procedure


procedure editor_draw__sidebar_elems()

    sb_cenprint(1, "úù - " & H & H & " - ùú", 15, 1)
    sb_cenprint(2, " ZIG Editor ", 0, 7)
    sb_cenprint(3, "úù - " & H & H & " - ùú", 15, 1)

    box(4, 61, 9, 80, 1, "Patterns")

    sb_btnprint(6, "P", "Select Pattern", 3)
    sb_btnprint(7, "D", "Select Char.", 7)
    sb_btnprint(8, "C", "Color: ", 3)

    sb_btnprint(10, "Arrows", "Move", 7)
    sb_btnprint(11, "Tab", "Drawing:", 3)
    sb_btnprint(12, "F2", "Text entry", 7)
    sb_btnprint(13, "A", "Blocks", 3)

    sb_btnprint(15, "N", "New World", 7)
    sb_btnprint(16, "L/S", "Load/Save", 3)
    sb_btnprint(18, "B", "Board:", 7)
    sb_btnprint(19, "`~", "Layer:", 3)
    sb_btnprint(20, "I", "Board Info", 7)
    sb_btnprint(21, "W", "World Info", 3)

    sb_btnprint(23, "O", "Place Object", 7)
    sb_btnprint(24, "F1", "Libraries", 3)

end procedure


procedure editor_edraw_cursor(atom x, atom y, sequence offsets, atom curs)

    position(x - offsets[1], y - offsets[2])

    if curs = DRAWING_OFF then

        text_color(15)
        bk_color(0)

        puts(1, CSR_NORMAL)

    elsif curs = DRAWING_ON then

        text_color(14)
        bk_color(1)

        puts(1, CSR_DRAWING)

    elsif curs = DRAWING_TEXT then

        text_color(15)
        bk_color(0)

        puts(1, CSR_TEXT)

    end if

end procedure


procedure mod_test()

    sequence fname, ss

    if length(current_mod) > 0 then

        current_mod = {}
        pause_sound()
        return

    end if

    fname = select_file("*.mod", "MOD test")

    if load_mod(fname) then

        ss = screen_save()
        msg("Error loading MOD", "There was an error loading the MOD!")
        screen_restore(ss)
        return

    else

        current_mod = fname
        unpause_sound()

    end if

end procedure


function colored_text(sequence t, atom c)

    sequence ret

    ret = {}

    for z = 1 to length(t) do
        ret = ret & t[z]
        ret = ret & c
    end for

    return(ret)

end function


function board_message(atom board)

    if length(world[WRLD_BOARDS][board][BRD_NAME]) then
        return({colored_text(" " & world[WRLD_BOARDS][board][BRD_NAME] & " (board #" & sprintf("%d", {board}) & ") ", color_attribute(14, 8))})
    else return({colored_text(" Untitled board, #" & sprintf("%d", {board}) & " ", color_attribute(14, 8))})
    end if

end function


procedure draw_x_y(atom x, atom y, atom px, atom py)

    sequence a
    
    a = "(" & sprint(x) & "," & sprint(y) & ") [" & sprint(px) & "," & sprint(py) & "]"
    if length(a) < 18 then
        a = a & repeat(32, 18 - length(a))
    end if

    bk_color(1)

    sb_print(25, a, 15)

end procedure


procedure do_editor()

    atom x,
        y,
        layer,
        board,
        csr_flash_timer,
        csr_visible,
        pattern,
        color,
        drawing_mode,
        run_mode,
        k,
        old_x,
        old_y,
        update_cursor,
        msg_timer,
        msg_active,
        place_flag,
        old_board

    sequence
        pattern_data,
        offsets,
        message,
        last_block,
        block,
        old_offsets,
        viewport

    object
        u1,
        u2,
        u3

    if world[WRLD_STARTBRD] > 0 then
        board = world[WRLD_STARTBRD]
    else board = 1
    end if
    
    color = 15
    drawing_mode = DRAWING_OFF
    run_mode = RUNNING
    offsets = {0, 0}
    last_block = {}
    block = {}
    message = board_message(board)
    viewport = {1, 1, 25, 60}

    msg_active = 1
    msg_timer = time() + MSG_ETIME

    x = 1
    y = 1

    layer = 2

    pattern_data = DEFAULT_PATTERN_DATA
    pattern = 1

    place_flag = FALSE

    csr_flash_timer = time() + CSR_FLASH_DELAY
    csr_visible = TRUE

    draw_board(board, offsets, VISIBLE_ALL_ON, viewport)
    apply_board_settings(board)

    sidebar_clear()

    editor_draw__sidebar_elems()

    editor_draw_patterns(pattern_data, pattern)
    editor_draw_color(color)
    editor_draw_drawstatus(drawing_mode)
    editor_draw_boardnum(board)
    editor_draw_layer(layer)

    clear_keys()


    while run_mode = RUNNING
    do

        old_x = x
        old_y = y
        old_board = board
        old_offsets = offsets
        update_cursor = 0

        place_flag = FALSE

        k = get_key()

        if k != -1 then

            if k = KEY_UP then

                x = x - 1

            elsif k = KEY_DN then

                x = x + 1

            elsif k = KEY_LF then

                y = y - 1

            elsif k = KEY_RT then

                y = y + 1

            elsif k = KEY_HOME then

                if x = 1 then
                    y = 1
                    offsets[2] = 0
                else x = 1 offsets[1] = 0
                end if

            elsif k = KEY_TAB then

                if drawing_mode = DRAWING_OFF then
                    drawing_mode = DRAWING_ON
                else drawing_mode = DRAWING_OFF
                end if

                editor_draw_drawstatus(drawing_mode)

            elsif k = KEY_F2 then

                if drawing_mode != DRAWING_TEXT then
                    drawing_mode = DRAWING_TEXT
                else drawing_mode = DRAWING_OFF
                end if

                editor_draw_drawstatus(drawing_mode)

            elsif k = KEY_F1 then

                dlg_library_menu(board, x, y, layer, color)

            elsif k = 27 or k = 1 then

                if drawing_mode = DRAWING_OFF then
                    run_mode = STOP
                else
                    drawing_mode = DRAWING_OFF
                    editor_draw_drawstatus(drawing_mode)
                end if

            elsif k = KEY_F10 then

                k = -1
                while k = -1 do
                    k = get_key()
                    draw_shown_objects(board, offsets, VISIBLE_ALL_ON)
                    draw_objects(board, offsets, VISIBLE_ALL_ON, viewport)
                end while

                old_board = -1

            elsif k = '~'
            or k = '`' then

                layer = layer + 1

                if layer > world[WRLD_BOARDS][board][BRD_LAYERS] then
                    layer = 1
                end if

                editor_draw_layer(layer)

            elsif k = KEY_ALT_C then

                if length(world[WRLD_BOARDS][board][BRD_CHARSET]) = 0 then
                    world[WRLD_BOARDS][board][BRD_CHARSET] = system_charset
                end if
                world[WRLD_BOARDS][board][BRD_CHARSET] =
                        edit_charset(world[WRLD_BOARDS][board][BRD_CHARSET])

            --elsif k = KEY_ALT_P then

                --if length(world[WRLD_BOARDS][board][BRD_PAL]) = 0 then
                    --world[WRLD_BOARDS][board][BRD_PAL] = system_palette
                --end if
                --world[WRLD_BOARDS][board][BRD_PAL] =
                        --edit_pal(world[WRLD_BOARDS][board][BRD_PAL])

            end if
        end if

        if k != -1 and drawing_mode != DRAWING_TEXT then

            k = upper(k)

            if k = 'P' or k = KEY_ALT_P then

                if k = 'P' then pattern = pattern + 1
                elsif k = KEY_ALT_P then pattern = pattern - 1
                end if

                if pattern > length(pattern_data) + 1 then
                    pattern = 1
                elsif pattern < 1 then
                    pattern = length(pattern_data)
                end if

                editor_draw_patterns(pattern_data, pattern)
                
            elsif k >= '0' and k <= '9' then
                
                message = "Visible layers: "
                for z = 1 to world[WRLD_BOARDS][board][BRD_LAYERS] do
                    message = message & "1 "
                end for
                message = {colored_text(message[1..length(message) - 1], color_attribute(14, 8))}
                msg_active = 1
                msg_timer = time() + MSG_ETIME / 2

            elsif k = 'C' then

                color = dlg_get_color(color)
                editor_draw_color(color)

            elsif k = 'T' then

                dlg_do_transfer(board)
                draw_board(board, offsets, VISIBLE_ALL_ON, viewport)
                apply_board_settings(board)

            elsif k = 'D' then

                if pattern = length(pattern_data) + 1 then
                    pattern_data = append(pattern_data, {0})
                end if

                pattern_data[pattern][PAT_CHAR] = dlg_get_char(pattern_data[pattern][PAT_CHAR])
                editor_draw_patterns(pattern_data, pattern)

            elsif k = 'M' then

                mod_test()
                
            elsif k = 'Z' then
                
                if confirm("Sure?", "Really clear the board [y/N]?") then
                
                    offsets = {0, 0}
                    x = 1
                    y = 1
                    layer = 2
                    world[WRLD_BOARDS][board] = NEW_BOARD
                    draw_board(board, offsets, VISIBLE_ALL_ON, viewport)
                    apply_board_settings(board)
                
                end if

            elsif k = 'N' then

                if confirm("Sure?", "Really clear the world [y/N]?") then

                    offsets = {0, 0}
                    x = 1
                    y = 1
                    layer = 2
                    board = 1
                    clear_world()
                    draw_board(board, offsets, VISIBLE_ALL_ON, viewport)
                    apply_board_settings(board)

                end if

            elsif k = 'O' then

                u2 = dlg_get_char(-1)
                
                if u2 != -1 then
                    delete_object(board, find_object(board, x, y, layer))
                    u1 = new_object(board)
                    eset(board, x, y, layer, BRD_TILECHAR, 0)
                    eset(board, x, y, layer, BRD_TILECOLOR, 0)
                    oset(board, u1, OBJ_X, x)
                    oset(board, u1, OBJ_Y, y)
                    oset(board, u1, OBJ_LAYER, layer)
                    oset(board, u1, OBJ_CHAR, u2)
                    oset(board, u1, OBJ_COLOR, color)
                    
                    world[WRLD_BOARDS][board][BRD_OBJECTS][u1] =
                            edit_object(world[WRLD_BOARDS][board][BRD_OBJECTS][u1])

                    --draw_board(board, offsets, VISIBLE_ALL_ON)
                    draw_object(board, u1, offsets, VISIBLE_ALL_ON, viewport)
                end if

            elsif k = ' ' then

                place_flag = TRUE

            elsif k = KEY_CR
            or k = KEY_CTRLCR then
            
                u1 = find_object(board, x, y, layer)
                
                if u1 then
                    
                    u2 = lower(oget(board, u1, OBJ_LIBFROM))
                        
                    if length(u2) != 0 then
                        if find(u2, lib_listing) != 0 then
                            u3 = oget(board, u1, OBJ_NAME)
                            for aa = 1 to length(object_library) do
                                if compare(object_library[aa][LIB_NAME], u3) = 0 then
                                    world[WRLD_BOARDS][board][BRD_OBJECTS][u1] = 
                                            modify_object_props(world[WRLD_BOARDS][board][BRD_OBJECTS][u1], object_library[aa])
                                    if object_library[aa][LIB_CODELOCK] != 0 then
                                        u2 = 1
                                        if k = KEY_CTRLCR then
                                            u2 = 0
                                        end if
                                    end if
                                    exit
                                end if
                            end for
                        end if
                    end if
                    
                    if sequence(u2) then
                        u2 = 0
                    end if

                    if u2 = 0 then
                        world[WRLD_BOARDS][board][BRD_OBJECTS][u1] =
                                        edit_object(world[WRLD_BOARDS][board][BRD_OBJECTS][find_object(board, x, y, layer)])
                    end if

                    if pattern = length(pattern_data) + 1 then
                    
                        pattern_data =
                            append(pattern_data,
                            {oget(board, u1, OBJ_CHAR),
                             world[WRLD_BOARDS][board][BRD_OBJECTS][u1]})
                    
                    else
                    
                        pattern_data[pattern] =
                            {oget(board, find_object(board, x, y, layer), OBJ_CHAR),
                             world[WRLD_BOARDS][board][BRD_OBJECTS][find_object(board, x, y, layer)]}
                             
                    end if

                        color = oget(board, u1, OBJ_COLOR)
                        
                else

                    if pattern = length(pattern_data) + 1 then
                        pattern_data =
                            append(pattern_data,
                            {eget(board, x, y, layer, BRD_TILECHAR)})
                    
                        color = eget(board, x, y, layer, BRD_TILECOLOR)

                    else
        
                        u1 = 0
                        u2 = eget(board, x, y, layer, BRD_TILECHAR)
                    
                        for z = 1 to length(pattern_data) do
        
                            if pattern_data[z][PAT_CHAR] = u2
                            and not pattern_has_object(pattern_data[z]) then
                    
                                u1 = z
                                exit
        
                            end if
                        end for
                    
                        if u1 != 0 then
        
                            pattern = u1
                
                        else

                            pattern_data =
                                append(pattern_data,
                                {eget(board, x, y, layer, BRD_TILECHAR)})
                
                            pattern = length(pattern_data)
                        
                        end if
        
                        color = eget(board, x, y, layer, BRD_TILECOLOR)

                    end if
                    
                end if

                editor_draw_patterns(pattern_data, pattern)
                editor_draw_color(color)

            elsif k = 'S' then

                if length(world[WRLD_FILENAME]) then
                    u1 = sb_input(SBI_FILENAME, 23, "Filename?.ZIG", world[WRLD_FILENAME])
                else
                    u1 = sb_input(SBI_FILENAME, 23, "Filename?.ZIG", 8)
                end if

                if length(u1) then
                    world[WRLD_FILENAME] = u1
                    u1 = open(u1 & ".zig", "wb")
                    save_world(u1)
                    close(u1)
                end if

            elsif k = 'L' then

                u1 = select_file("*.zig", "World load")
                if length(u1) > 1 then
                    u2 = u1
                    u1 = open(u1, "rb")

                    if u1 != -1 then

                        clear_world()
                        u3 = load_world(u1, u2)
                        if length(world[WRLD_NAME]) = 0 then
                            world[WRLD_NAME] = fproc(u2)
                        end if
                        if u3 then
                            u2 = screen_save()
                            clear_screen()
                            printf(1, "Load error %d!", u3)
                            u3 = wait_key()
                            screen_restore(u2)
                        end if

                        close(u1)

                        board = 1
                        x = 1
                        y = 1
                        layer = 2
                        old_board = 0
                        offsets = {0, 0}

                        draw_board(board, offsets, VISIBLE_ALL_ON, viewport)

                    end if
                end if

            elsif k = 'B' then

                u1 = select_board(board, FALSE)

                if u1 != 0 then
                    board = u1
                else
                    new_board(length(world[WRLD_BOARDS]) + 1)
                    board = length(world[WRLD_BOARDS])
                end if

            elsif k = KEY_PGUP then

                if board > 1 then
                    board = board - 1
                end if

            elsif k = KEY_PGDN then

                if length(world[WRLD_BOARDS]) > board then
                    board = board + 1
                end if

            elsif k = 'A' then

                u1 = dlg_get_block_coords({x, y},
                    {world[WRLD_BOARDS][board][BRD_SIZEX],
                     world[WRLD_BOARDS][board][BRD_SIZEY]},
                     last_block,
                     offsets)

                if length(u1) then

                    if atom(u1[1]) then

                        if u1[1] = -1 then

                            if length(block) then
                                set_multi_chunk(board, layer, {x, y}, block, TRUE)
                            end if
                            u2 = screen_save()

                        end if

                    else

                        last_block = u1
                        u2 = screen_save()
                        invert_area(u1[1] - offsets[1], u1[2] - offsets[2])
                        u3 = dlg_get_block_action()
                        if u3 = BS_COPY then
                            block = get_board_chunk(board, layer, u1)
                        elsif u3 = BS_FILL then
                            if not pattern_has_object(pattern_data[pattern]) then
                                u3 = dlg_get_block_fill_sort()
                                if u3 = 1 then
                                    set_board_chunk(board, layer, u1, -1, color)
                                elsif u3 = 2 then
                                    set_board_chunk(board, layer, u1, pattern_data[pattern][PAT_CHAR], -1)
                                else
                                    if u3 != -1 then
                                        set_board_chunk(board, layer, u1, pattern_data[pattern][PAT_CHAR], color)
                                    end if
                                end if
                            else
                                msg("Can't fill", "The current pattern has an object in it - can't fill with that.")
                            end if

                        elsif u3 = BS_ERASE then

                            set_board_chunk(board, layer, u1, 0, 0)

                        end if

                    end if

                    screen_restore(u2)
                    old_board = -1

                end if

            elsif k = 'W' then

                world[1..WRLD_BOARDS - 1] = dlg_edit_props(WRLD_PROPS_DATA, world[1..WRLD_BOARDS - 1], "Editing World Properties", 0)

            elsif k = 'I' then

                world[WRLD_BOARDS][board][1..BRD_DATA - 1] = dlg_edit_props(BRD_PROPS_DATA, world[WRLD_BOARDS][board][1..BRD_DATA - 1], "Editing properties for board #" & sprint(board), board)
                apply_board_settings(board)
                
            elsif k = 'H' then
                
                do_help("edi0")

            end if
        else
            if k = 8 then

                y = y - 1

                if y < 1 then y = 1
                end if

            end if

            if k >= 32 and k <= 127 then

                eset(board, x, y, layer, BRD_TILECHAR, k)
                eset(board, x, y, layer, BRD_TILECOLOR, color)

                y = y + 1

                if y > world[WRLD_BOARDS][board][BRD_SIZEY] then

                    y = world[WRLD_BOARDS][board][BRD_SIZEY]
                    x = x + 1

                    if x > world[WRLD_BOARDS][board][BRD_SIZEX] then
                        x = world[WRLD_BOARDS][board][BRD_SIZEX]
                    end if

                end if

            end if
        end if


        if drawing_mode = DRAWING_ON then place_flag = TRUE end if


        if board != old_board then

            message = board_message(board)
            msg_active = 1
            msg_timer = time() + MSG_ETIME
            editor_draw_boardnum(board)

            draw_board(board, offsets, VISIBLE_ALL_ON, viewport)
            apply_board_settings(board)
                
            if world[WRLD_SBAUTO] then
                world[WRLD_STARTBRD] = board
            end if

        end if

        if msg_timer != 0 then
            if msg_timer < time() then
                msg_timer = 0
                draw_board(board, offsets, VISIBLE_ALL_ON, viewport)
            else
                display_text_image({2, 3}, message)
            end if
        end if

        if x != old_x or y != old_y then

            if x > world[WRLD_BOARDS][board][BRD_SIZEX] then
                x = world[WRLD_BOARDS][board][BRD_SIZEX]
            end if

            if y > world[WRLD_BOARDS][board][BRD_SIZEY] then
                y = world[WRLD_BOARDS][board][BRD_SIZEY]
            end if

            if x < 1 then
                x = 1
            end if

            if y < 1 then
                y = 1
            end if

            if x - offsets[1] > screen_sizex and x > old_x then
                offsets[1] = offsets[1] + 8
            end if

            if sidebar then
                if y - offsets[2] > (screen_sizey - 20) and y > old_y then
                    offsets[2] = offsets[2] + 8
                end if
            else
                if y - offsets[2] > screen_sizey and y > old_y then
                    offsets[2] = offsets[2] + 8
                end if
            end if

            if layer > world[WRLD_BOARDS][board][BRD_LAYERS] then
                layer = world[WRLD_BOARDS][board][BRD_LAYERS]
                editor_draw_layer(layer)
            end if

            if x - offsets[1] < 1 then
                offsets[1] = offsets[1] - 8
            end if

            if y - offsets[2] < 1 then
                offsets[2] = offsets[2] - 8
            end if

            if compare(offsets, old_offsets) != 0 then
                draw_board(board, offsets, VISIBLE_ALL_ON, viewport)
            end if

            draw_x_y(x, y, world[WRLD_BOARDS][board][BRD_SIZEX], world[WRLD_BOARDS][board][BRD_SIZEY])

            draw_board_tile(board, old_x, old_y, offsets, VISIBLE_ALL_ON, viewport)
            update_cursor = 2
            csr_visible = TRUE

        end if


        if place_flag then

            if pattern = length(pattern_data) + 1 then
                pattern = pattern - 1
            end if

            if pattern_has_object(pattern_data[pattern]) then

                if drawing_mode = DRAWING_OFF then
                    if eget(board, x, y, layer, BRD_TILECHAR) != 0
                    or find_object(board, x, y, layer) != 0 then

                        delete_object(board, find_object(board, x, y, layer))
                        eset(board, x, y, layer, BRD_TILECHAR, 0)
                        eset(board, x, y, layer, BRD_TILECOLOR, color)

                    else

                        eset(board, x, y, layer, BRD_TILECHAR, 0)
                        eset(board, x, y, layer, BRD_TILECOLOR, color)
                        u1 = new_object(board)
                        world[WRLD_BOARDS][board][BRD_OBJECTS][u1] = pattern_data[pattern][PAT_OBJECT]
                        oset(board, u1, OBJ_X, x)
                        oset(board, u1, OBJ_Y, y)
                        oset(board, u1, OBJ_LAYER, layer)
                        oset(board, u1, OBJ_CHAR, pattern_data[pattern][PAT_CHAR])
                        oset(board, u1, OBJ_COLOR, color)
                        --draw_board(board, offsets, VISIBLE_ALL_ON)
                        draw_object(board, u1, offsets, VISIBLE_ALL_ON, viewport)

                    end if

                end if

            else

                if drawing_mode = DRAWING_OFF then
                    if eget(board, x, y, layer, BRD_TILECHAR) != 0
                    or find_object(board, x, y, layer) != 0 then

                        delete_object(board, find_object(board, x, y, layer))
                        eset(board, x, y, layer, BRD_TILECHAR, 0)
                        eset(board, x, y, layer, BRD_TILECOLOR, color)

                    else

                        eset(board, x, y, layer, BRD_TILECHAR, pattern_data[pattern][PAT_CHAR])
                        eset(board, x, y, layer, BRD_TILECOLOR, color)

                    end if

                else

                    delete_object(board, find_object(board, x, y, layer))
                    eset(board, x, y, layer, BRD_TILECHAR, pattern_data[pattern][PAT_CHAR])
                    eset(board, x, y, layer, BRD_TILECOLOR, color)

                end if
            end if

        end if

        if csr_flash_timer < time() then

            update_cursor = 1

        end if

        if update_cursor != 0 then

            csr_flash_timer = time() + CSR_FLASH_DELAY

            if update_cursor != 2 then
                csr_visible = not(csr_visible)
            end if

            if csr_visible then
                editor_edraw_cursor(x, y, offsets, drawing_mode)
            else
                draw_board_tile(board, x, y, offsets, VISIBLE_ALL_ON, viewport)
            end if

        end if

    end while

end procedure


function identify_command_type(atom cmd_type)
    atom a

    a = 0

    for b = 1 to length(CMD_TYPES) do
        if find(cmd_type, CMD_TYPES[b]) != 0 then a = 1 exit end if
    end for

    if a = 0 then return(CMD_MSG)
    else
        for b = 1 to length(CMD_TYPES) do
            if find(cmd_type, CMD_TYPES[b]) then
                return(b)
            end if
        end for
    end if

end function


procedure compile_error(atom board, sequence info, sequence desc)

    atom tw, r, ll
    sequence ss, caption, title
    
    title = "Compiler error"
    caption = sprintf("Error: Object %d (%s) on board %d", {info[1], info[2], board})

    ss = screen_save()

    ll = length(desc)
    if length(title) > ll then
        ll = length(title)
    end if

    tw = (screen_sizey / 2) - ((ll + 6) / 2)
    box(9, tw, 14, tw + ll + 6, 4, title)

    text_at(11, tw + 3, caption, 14)
    text_at(12, tw + 3, desc, 14)

    r = wait_key()
    
    screen_restore(ss)

end procedure


function dir_opp(atom d)
    
    if d = 'n' then d = 's'
    elsif d = 's' then d = 'n'
    elsif d = 'e' then d = 'w'
    elsif d = 'w' then d = 'e'
    end if
    
    return(d)
    
end function


function dir_spin(atom d, atom spindir)

    d = lower(d)

    if spindir = 2
    or spindir = -2 then
        return(dir_opp(d))
    elsif spindir = 1 then
        if d = 'n' then d = 'e'
        elsif d = 'e' then d = 's'
        elsif d = 's' then d = 'w'
        elsif d = 'w' then d = 'n'
        end if
    elsif spindir = -1 then
        if d = 'n' then d = 'w'
        elsif d = 'e' then d = 'n'
        elsif d = 's' then d = 'e'
        elsif d = 'w' then d = 's'
        end if
    elsif spindir = -3 then
        return(dir_spin(d, 1))
    elsif spindir = 3 then
        return(dir_spin(d, -1))
    end if
    
    return(d)
    
end function


function dir_rnd()
    
    atom a
    
    a = rand(4)
    if a = 1 then return('n')
    elsif a = 2 then return('s')
    elsif a = 3 then return('w')
    elsif a = 4 then return('e')
    end if
    
end function


function dir_rndns()
    
    atom a
    
    a = rand(2)
    if a = 1 then return('n')
    elsif a = 2 then return('s')
    end if
    
end function


function dir_rndne()
    
    atom a
    
    a = rand(2)
    if a = 1 then return('n')
    elsif a = 2 then return('e')
    end if
    
end function


function dir_rndp(atom d)

    atom a
    a = rand(2)
    if d = 'n' or d = 's' then
        if a = 1 then return('e')
        else return('w')
        end if
    else
        if a = 1 then return('n')
        else return('s')
        end if
    end if
        
end function


function dir_seek(sequence d1, sequence d2)
    
    atom diffx, diffy, a, rdiffx, rdiffy
    
    diffx = d2[1] - d1[1]
    diffy = d2[2] - d1[2]
    rdiffx = diffx
    if diffx < 0 then
        rdiffx = -diffx
    end if
    rdiffy = diffy
    if diffy < 0 then
        rdiffy = -diffy
    end if
    
    if rdiffx - rdiffy > -10
    and rdiffx - rdiffy < 10 then
        a = rand(2)
        if a = 1 then
            if diffx > 0 then
                return('n')
            else return('s')
            end if
        else
            if diffy > 0 then
                return('w')
            else return('e')
            end if
        end if
    else
        if rdiffx > rdiffy then
            if diffx > 0 then
                return('n')
            else return('s')
            end if
        else
            if diffy > 0 then
                return('w')
            else return('e')
            end if
        end if
    end if
    
end function


function ge_pgm_error(sequence objname, sequence caption)

    atom tw, r, ll
    sequence ss, title

    title = "Program error (object name: '" & objname & "')"

    ss = screen_save()

    ll = length(caption)
    if length(title) > ll then
        ll = length(title)
    end if

    tw = (screen_sizey / 2) - ((ll + 6) / 2)
    box(10, tw, 18, tw + ll + 6, 4, title)

    bk_color(4)

    text_at(12, tw + 3, caption, 14)

    text_at(14, tw + 3, "[R]esume - keep running object", 15)
    text_at(15, tw + 3, "[H]alt the object", 15)
    text_at(16, tw + 3, "[E]nd this game       [R/H/E]?", 15)

    while TRUE do
        r = upper(wait_key())
        if r = 'R' then
            screen_restore(ss)
            return(CE_RESUME)
        elsif r = 'H' then
            screen_restore(ss)
            return(CE_HALT)
        elsif r = 'E' then
            screen_restore(ss)
            return(CE_ENDGAME)
        end if
    end while

end function


procedure add_control_object(atom board)

    sequence ctr

    if length(world[WRLD_BOARDS][board][BRD_CTROBJ]) then

        ctr = NEW_OBJECT
        ctr[1][OBJ_COLLIDE] = 0
        ctr[1][OBJ_X] = 1
        ctr[1][OBJ_Y] = 1
        ctr[1][OBJ_CHAR] = 0

        ctr = ctr & {world[WRLD_BOARDS][board][BRD_CTROBJ]}

        world[WRLD_BOARDS][board][BRD_CTROBJ] =
            append(world[WRLD_BOARDS][board][BRD_OBJECTS], ctr)

    end if

end procedure


function break_up_words(sequence a)

    atom in_quote, ps, fl
    sequence b, c

    b = {}  c = {}
    in_quote = FALSE
    ps = 0
    fl = 0
    
    for z = 1 to length(a) do
        if z = length(a) then
            if a[z] != '"' then c = c & a[z] end if
            b = append(b, c)
            return(b)
        end if
        
        if a[z] = '"' then
            if in_quote = TRUE then
                b = append(b, c)
                c = {}
                in_quote = FALSE
                ps = 1
                fl = 1
            else
                in_quote = TRUE
                ps = 1
            end if
        end if
        
        if a[z] = ' ' and in_quote = FALSE then
            if fl != 1 then
                b = append(b, c)
                c = {}
                if z = length(a) then
                    return(b)
                end if
            else fl = 0
            end if
        else 
            if ps = 0 then c = c & a[z]
            else ps = 0 end if
        end if
    end for

    return(b)

end function


function translate_dir(atom d)

    d = upper(d)

    if d = 'N' then return({-1, 0})
    elsif d = 'S' then return({1, 0})
    elsif d = 'W' then return({0, -1})
    elsif d = 'E' then return({0, 1})
    elsif d = 'I' then return({0, 0})
    end if

    return({0, 0})

end function


-- translate a command to an atom
function translate_command(sequence c)

    if c[1] != '#' then  -- is there no # there?
        c = "#" & c     -- add one
    end if

    c = lower(c)

    for z = 1 to length(OS_COMMANDS_UNSUP) do   -- check for unsupported cmd
        if compare(c, OS_COMMANDS_UNSUP[z]) = 0 then
            msg("Error", "Unsupported ZZT-OOP command: " & c)
            return(-1)
        end if
    end for

    for z = 1 to length(OS_COMMANDS) do
        if compare(c, OS_COMMANDS[z][1]) = 0 then
            return(z)
        end if
    end for

    --msg("Error", "Unrecognized command: " & c)
    return(-1)  -- it's a #send

end function


function break_up_cmd(sequence l)

    atom lz
    sequence n

    n = {}
    lz = 1

    for z = 2 to length(l) do

        if l[z] = '/'
        or l[z] = '\\'
        or l[z] = '?' then
            n = append(n, l[lz..z - 1])
            lz = z
        elsif l[z] = '#' then
            n = append(n, l[lz..z - 1])
            lz = z
            exit
        end if

    end for

    n = append(n, l[lz..length(l)])

    return(n)

end function


function compile_line(sequence l, sequence info)

    atom t
    sequence rr, tmp

    rr = l

    -- remember to nest returns!

    name_pass = {}

    -- catch 0-length statements
    if length(l) = 0 then
        return({{CMD_MSG, " "}})
    end if
    
    t = l[1]
    if t = '\'' then    -- comment
        return({{}})
    elsif t = '@' then
        name_pass = l[2..length(l)]
        return({{CMD_NAMEASSIGN, l[2..length(l)]}})
    elsif t = '%' then
        l = break_up_words(l)
        l[1] = l[1][2..length(l[1])]
        return({{CMD_VARASSIGN, l}})
    elsif t = ':' then
        return({{CMD_LABEL, l[2..length(l)]}})
    elsif t = '|' then
        return({{CMD_ZAPLABEL, l[2..length(l)]}})
    elsif t = '/' or t = '?' then
        l = break_up_cmd(l)
        l[1] = break_up_words(l[1])
        l[1][1] = l[1][1][2..length(l[1][1])]
        l[1] = {CMD_STATEMENT, {C_GO} & l[1]}
        return(l)
    elsif t = '#' then  -- command
        l = trim(l)
        l = break_up_words(l)
        tmp = l[1]
        l[1] = translate_command(l[1])
        if l[1] = -1 then   -- a #send label
            return({{CMD_STATEMENT, {C_SEND, tmp[2..length(tmp)]}}})
        else
            if (length(l) - 1) < length(OS_COMMANDS[l[1]][2]) then
                if length(info[3]) = 0 then
                    info[3] = "no name"
                end if
                compile_error(info[1], info[2..3], "Parameter count mismatch: " & rr)
                return({{}})
            end if
            return({{CMD_STATEMENT, l}})
        end if
    else                -- message
        return({{CMD_MSG, l}})
    end if

end function


procedure compile_objects(atom board)

    atom l
    sequence obj
    
    name_pass = {}

    obj = world[WRLD_BOARDS][board][BRD_OBJECTS]

    if length(world[WRLD_BOARDS][board][BRD_CTROBJ]) > 1 then
        world[WRLD_BOARDS][board][BRD_CTROBJ][1][OBJ_COLLIDE] = FALSE
        obj = append(obj, world[WRLD_BOARDS][board][BRD_CTROBJ])
    end if

    if length(obj) < 1 then
        return
    end if

    bk_color(1)
    sb_print(21, "Compiling...   ", 15)
    sb_print(22, "1 of " & sprintf("%d", length(obj)) & "        ", 15)
    sb_print(23, "Board " & sprintf("%d", board) & "         ", 15)

    for o = 1 to length(obj) do
        obj[o][1][OBJ_POS] = 1  -- code position 1
        obj[o][1][OBJ_RUNSTATE] = 0 -- running
        obj[o][1] = append(obj[o][1], 'n')  -- add OBJ_FLOW
        obj[o][1] = append(obj[o][1], 0)    -- add OBJ_PUSHABLE
        obj[o][1] = append(obj[o][1], 0)    -- add OBJ_WALKDIR
        sb_print(22, sprintf("%d", o) & " of " & sprintf("%d", length(obj)) & "        ", 15)
        if length(obj[o]) > 1 then
            l = 1
            while l <= length(obj[o]) do
                l = l + 1
                if l > length(obj[o]) then
                    exit
                end if
                obj[o] = obj[o][1..l - 1] & compile_line(obj[o][l], {board, o, obj[o][1][OBJ_NAME]}) & obj[o][l + 1..length(obj[o])]
                if length(name_pass) then   -- for #bind of others
                    obj[o][1][OBJ_NAME] = name_pass
                    name_pass = {}
                end if
            end while
        end if
    end for

    world[WRLD_BOARDS][board][BRD_OBJECTS] = obj

end procedure


function ge_compile_object(sequence obj)

        atom l

--        obj[1][OBJ_POS] = 1  -- code position 1
--        obj[1][OBJ_RUNSTATE] = 0 -- running
--        obj[1] = append(obj[1], 'n')  -- add OBJ_FLOW
--        obj[1] = append(obj[1], 0)    -- add OBJ_PUSHABLE
--        obj[1] = append(obj[1], 0)    -- add OBJ_WALKDIR
        if length(obj) > 1 then
            l = 0
            while l <= length(obj) do
                l = l + 1
                if l > length(obj) then
                    exit
                end if
                obj = obj[1..l - 1] & compile_line(obj[l], {0, obj, "LIB_OBJ"}) & obj[l + 1..length(obj)]
            end while
        end if
        
        return(obj)
    
end function


procedure setup_world()

    flags = {}
    variables = {}
    stats = {}
    messages = {}

    message_x = 25
    message_y = CENTERED
    message_color = FLASHING
    message_time = 2
    next_available_message = 1
    cs_counter = 0
    oldstatlen = length(stats)

    for z = 1 to length(world[WRLD_BOARDS]) do
        compile_objects(z)
        world[WRLD_BOARDS][z] = append(world[WRLD_BOARDS][z], -1)
    end for

end procedure


function get_flag_value(sequence flagname)

    for z = 1 to length(flags) do
        if compare(flagname, flags[z][FLAG_NAME]) = 0 then
            return(flags[z][FLAG_VALUE])
        end if
    end for

    return(0)

end function


procedure new_flag()

    flags = append(flags, NEW_FLAG)

end procedure


procedure set_flag(sequence flagname, atom val)

    flagname = lower(flagname)
    
    for z = 1 to length(flags) do
        if compare(flagname, flags[z][FLAG_NAME]) = 0 then
            flags[z][FLAG_VALUE] = val
            return
        end if
    end for

    new_flag()
    flags[length(flags)][FLAG_NAME] = flagname
    flags[length(flags)][FLAG_VALUE] = val

end procedure


function get_var_value(object varname)

    if atom(varname) then
        return(variables[varname][VAR_VALUE])
    end if

    varname = lower(varname)

    for z = 1 to length(variables) do
        if compare(varname, variables[z][VAR_NAME]) = 0 then
            return(variables[z][VAR_VALUE])
        end if
    end for

    return(0)

end function


procedure new_variable()

    variables = append(variables, NEW_VAR)

end procedure


procedure set_var(sequence varname, atom val)

    varname = lower(varname)
    
    if compare(varname, "mess.x") = 0 then message_x = val
    elsif compare(varname, "mess.y") = 0 then message_y = val
    elsif compare(varname, "mess.color") = 0 then message_color = val
    elsif compare(varname, "mess.time") = 0 then message_time = val
    else
        for z = 1 to length(variables) do
            if compare(varname, variables[z][VAR_NAME]) = 0 then
                variables[z][VAR_VALUE] = val
                return
            end if
        end for

        new_variable()
        variables[length(variables)][VAR_NAME] = varname
        variables[length(variables)][VAR_VALUE] = val
    end if

end procedure


procedure new_stat(sequence name, sequence var, atom char)

    var = lower(var)

    stats = append(stats, NEW_STAT)
    stats[length(stats)][STAT_NAME] = name
    if var[1] = '%' then var = var[2..length(var)]
    end if
    stats[length(stats)][STAT_VAR] = var
    stats[length(stats)][STAT_CHAR] = char

    set_var(var, get_var_value(var))

end procedure


function kill_stat(sequence name)

    for z = 1 to length(stats) do
        if compare(name, stats[z][STAT_NAME]) = 0 then
            stats = stats[1..z - 1] & stats[z + 1..length(stats)]
            return(0)
        end if
    end for

    return(-1)

end function


procedure sidebar_ge_draw_stats()

    bk_color(1)

    if sidebar = ON and length(stats) != oldstatlen then
        for z = 9 to 24 do
            position(z, 62)
            puts(1, repeat(32, 18))
        end for
    end if

    oldstatlen = length(stats)

    if sidebar = ON and length(stats) != 0 then

        for z = 1 to length(stats) do
            if 8 + z > 24  then
                exit
            end if
            display_text_image({8 + z, 62}, {{stats[z][STAT_CHAR], 31}})
            position(8 + z, 64)
            text_color(14)
            puts(1, stats[z][STAT_NAME] & ':')
            position(8 + z, 74)
            printf(1, "%4d", get_var_value(stats[z][STAT_VAR]))
        end for

    end if

end procedure


function valu(object a)

    sequence b
    b = value(a)
    return(b[2])

end function


function cutout(sequence s, atom c)
    
    return(s[1..c - 1] & s[c + 1..length(s)])
    
end function


function cat(sequence s)

    sequence r
    
    if length(s) = 0 then
        return({})
    end if

    if atom(s[1]) then
        return(s)
    end if

    r = {}

    for z = 1 to length(s) do
        r = r & (s[z] & " ")
    end for

    r = r[1..length(r) - 1]
    return(r)

end function


procedure new_message(sequence mess, atom board, sequence o, sequence offs, sequence vl, sequence viewport, sequence layer_table)

    for z = length(messages) to 1 by -1 do
        if length(messages) >= z then
            if mess[MSG_X] = messages[z][MSG_X] then
                draw_board_one_row(board, o, messages[z][MSG_X], offs, vl, viewport, layer_table)
                messages = cutout(messages, z)
                exit
            end if
        else exit
        end if
    end for

    messages = append(messages, mess)

    -- msg,color,time,x,y

end procedure


procedure update_messages(atom board, sequence o, sequence offs, sequence vl, sequence viewport, sequence layer_table)
    atom why, rest

    rest = FALSE

    cs_counter = cs_counter + 1
    if cs_counter > length(CS) then
        cs_counter = 1
    end if

    while 1 do

    for z = 1 to length(messages) do
        if length(messages[z][MSG_MSG]) != 0 then
            if messages[z][MSG_TIME] < time() then
                draw_board_one_row(board, o, messages[z][MSG_X], offs, vl, viewport, layer_table)
                if length(messages) = 1 then
                    messages = {}
                else
                    if z = length(messages) then
                        messages = messages[1..length(messages) - 1]
                    elsif z = 1 then
                        messages = messages[2..length(messages)]
                    else
                        messages = messages[1..z - 1] & messages[z + 1..length(messages)]
                    end if
                end if
                rest = TRUE
                exit
            else
                if messages[z][MSG_Y] = CENTERED then
                    why = screen_sizey
                    if sidebar then
                        why = why - sidebar_width
                    end if
                    why = why / 2
                    why = (why - (length(messages[z][MSG_MSG]) / 2)) - 2
                    if why < 1 then why = 1 end if
                else why = messages[z][MSG_Y]
                end if
                position(messages[z][MSG_X], why)
                bk_color(0)
                if messages[z][MSG_COLOR] = 0 then
                    text_color(CS[cs_counter])
                else text_color(messages[z][MSG_COLOR])
                end if
                puts(1, 32 & messages[z][MSG_MSG] & 32)
            end if
        end if
    end for

    if rest != TRUE then
        return
    end if

    return

    end while

end procedure


function ge_find_object(sequence o, sequence n)

    n = lower(n)

    for z = 1 to length(o) do

        if compare(lower(o[z][1][OBJ_NAME]), n) = 0 then
            return(z)
        end if

    end for

    return(0)

end function


function ge_find_label(sequence ob, atom typeof, sequence name, atom first)

    atom result

    result = 0
    name = lower(name)

    for a = 2 to length(ob) do
        if length(ob[a]) then
            if ob[a][1] = typeof then
                if compare(name, lower(ob[a][2])) = 0 then
                    result = a
                    if first = TRUE then
                        exit
                    end if
                end if
            end if
        end if
    end for

    return(result)

end function


-- return new obj#dest from obj#source
function ge_pgmcopy(sequence o, atom dest, atom source)

    sequence set, new

    set = o[dest][1]

    new = o[source]
    new[1] = set

    return(new)

end function


function ge_find_object_at_xy(sequence o, atom x, atom y, atom layer)

    for z = 1 to length(o) do
        if o[z][1][OBJ_X] = x then
            if o[z][1][OBJ_Y] = y then
                if o[z][1][OBJ_LAYER] = layer then
                    return(z)
                end if
            end if
        end if
    end for

    return(0)

end function


function ge_trans_color(sequence c)

    if length(c) then

        c = lower(c)
        for z = 0 to 15 do
            if compare(c, color_table[z + 1]) = 0 then
                return(z)
            end if
        end for
        
        c = upper(c)
        if c[1] = 'C' then
            if length(c) = 3 then
                return(color_attribute(hex_to_int(c[2]), hex_to_int(c[3])))
            else return(color_attribute(hex_to_int(c[2]), 0))
            end if
        else
            return(valu(c))
        end if

    end if

end function


function make_layer_table(sequence o, atom l)
    
    sequence la
    
    la = repeat({}, l)
    
    for z = 1 to length(o) do
        if o[z][1][OBJ_LAYER] > 0 then
            la[o[z][1][OBJ_LAYER]] = append(la[o[z][1][OBJ_LAYER]], z)
        end if
    end for
    
    return(la)
    
end function


procedure ge_debugline(sequence s)

    s = s
    return

end procedure


function findkey(sequence k, atom a)
    
    if find(a, k) then
        return(1)
    end if
    return(0)
    
end function


function check_object(sequence o, sequence old_locs, atom z, atom fo)

    atom dx, dy
    
    if o[z][1][OBJ_COLLIDE] then
        for a = 1 to length(o) do
            if a != z then
                if compare(o[z][1][OBJ_X..OBJ_LAYER], o[a][1][OBJ_X..OBJ_LAYER]) = 0 then
                    if o[a][1][OBJ_COLLIDE] then
                        
                            if compare(o[z][1][OBJ_X..OBJ_LAYER], old_locs[z]) != 0 then
                                dx = ge_find_label(o[z], CMD_LABEL, "thud", TRUE)
                                if dx != 0 then
                                    o[z][1][OBJ_POS] = dx - 1
                                    o[z][1][OBJ_RUNSTATE] = 0
                                    o[z][1][OBJ_WALKDIR] = 0
                                end if
                                if z = fo then
                                    dx = ge_find_label(o[a], CMD_LABEL, "touch", TRUE)
                                    if dx != 0 then
                                        o[a][1][OBJ_POS] = dx - 1
                                        o[a][1][OBJ_RUNSTATE] = 0
                                        o[a][1][OBJ_WALKDIR] = 0
                                    end if
                                end if
                            end if
                            
                            if compare(o[a][1][OBJ_X..OBJ_LAYER], old_locs[a]) != 0 then
                                dx = ge_find_label(o[a], CMD_LABEL, "thud", TRUE)
                                if dx != 0 then
                                    o[a][1][OBJ_POS] = dx - 1
                                    o[a][1][OBJ_RUNSTATE] = 0
                                    o[a][1][OBJ_WALKDIR] = 0
                                end if
                                if a = fo then
                                    dx = ge_find_label(o[z], CMD_LABEL, "touch", TRUE)
                                    if dx != 0 then
                                        o[z][1][OBJ_POS] = dx - 1
                                        o[z][1][OBJ_RUNSTATE] = 0
                                        o[z][1][OBJ_WALKDIR] = 0
                                    end if
                                end if
                            end if
                        
                        if o[a][1][OBJ_PUSHABLE] or a = fo then
                            dx = old_locs[a][1] - old_locs[z][1]
                            dy = old_locs[a][2] - old_locs[z][2]
                            o[a][1][OBJ_X] += dx            
                            o[a][1][OBJ_Y] += dy
                            o = check_object(o, old_locs, z, fo)
                        else
                            o[z][1][OBJ_X] = old_locs[z][1]
                            o[z][1][OBJ_Y] = old_locs[z][2]
                                                    
                            o[a][1][OBJ_X] = old_locs[a][1]
                            o[a][1][OBJ_Y] = old_locs[a][2]
                        end if
                    end if
                end if
            end if
        end for
    end if
    
    return(o)
    
end function


-- the game engine
procedure play_world()

    atom board,
        z,
        exit_flag,
        cycle_time,
        key,
        board_redraw,
        msg_time,
        old_board, 
        save_point, 
        focus_object, 
        l, 
        increment, 
        aa, 
        ct, 
        offset_auto, 
        set_to_die, 
        game_over, 
        set_focus, 
        walk_flag, 
        debugger, 
        redraw_pre,
        bk_redraw,
        sb_redraw,
        pre_aa,
        high_mode
        
    sequence o, 
        offsets, 
        next_statement, 
        scroll_accums, 
        appender, 
        old_locs, 
        save_line, 
        viewport, 
        visible_layers, 
        keys, 
        die_coords,
        bullet_code,
        layer_table
        
    object v1, v2, v3, v4, v5
        
    exit_flag = 0       -- loop ends if set
    game_over = FALSE
    board = world[WRLD_STARTBRD] 
    board_redraw = FALSE
    bk_redraw = FALSE
    debugger = OFF
    sb_redraw = FALSE
    high_mode = FALSE
    
    if find_in_lib("bullet") then
        bullet_code = object_library[find_in_lib("bullet")][LIB_PROG]
        bullet_code = ge_compile_object(bullet_code)
    else
        bullet_code = {}
    end if

    if board < 1 then   -- is the start board set?
        -- no
        msg("Start Board not set", "This world has no Start Board selected, can't use.")
        return
    end if

    o = world[WRLD_BOARDS][board][BRD_OBJECTS]
    -- clear the board's objects for now
    world[WRLD_BOARDS][board][BRD_OBJECTS] = {}

    -- does the board have any objects?
    if length(o) < 1 then
        -- no, can't continue
        msg("No objects - nonexecutable", "Can't execute, no objects.")
        return
    end if

    sidebar_clear()         -- clear the sidebar,
    sidebar_ge_draw_base()  -- draw the game engine base,
    sidebar_ge_draw_stats() -- and draw any stats

    offsets = {0, 0}        -- set scroll position to top
    -- set standard viewport
    viewport = {1, 1, screen_sizex, screen_sizey - sidebar_width}
    -- all layers on
    visible_layers = repeat(ON, world[WRLD_BOARDS][board][BRD_LAYERS])
    
    apply_board_settings(board) -- set charset and palette
    
    layer_table = make_layer_table(o, world[WRLD_BOARDS][board][BRD_LAYERS])
    
    draw_ge_board(board, offsets, visible_layers, viewport)   -- draw the board,
    draw_ge_objects(o, board, offsets, visible_layers, viewport, layer_table)  -- and the objects

    focus_object = -1   -- not set yet
    offset_auto = -1

    -- next_statement is used for executing a statement on an object
    -- dynamically; e.g. after an #if.
    next_statement = repeat({}, length(o))
    -- scroll accumulators - for scrolling messages
    scroll_accums = repeat({{}}, length(o))
    
    msg_time = time()
    
    clear_keys()
    
    -- try to find the :enter label
    for zz = 1 to length(o) do
        v1 = ge_find_label(o[zz], CMD_LABEL, "enter", TRUE)
        if v1 != 0 then
            o[zz][1][OBJ_POS] = v1 - 1
            o[zz][1][OBJ_RUNSTATE] = 0
        end if
    end for
    
    -- the main loop
    while not exit_flag do
    
        -- don't redraw everything, by default
        redraw_pre = FALSE
        board_redraw = redraw_pre
        bk_redraw = FALSE
    
        -- read from the keyboard
        keys = get_keys()

        if length(keys) then
            --key = keys[length(keys)]
            if find(42, keys) or find(54, keys) then
                if find(KEY_UP, keys) then
                    keys = {KEY_UP + 1024}
                elsif find(KEY_DN, keys) then
                    keys = {KEY_DN + 1024}
                elsif find(KEY_LF, keys) then
                    keys = {KEY_LF + 1024}
                elsif find(KEY_RT, keys) then
                    keys = {KEY_RT + 1024}
                end if
            end if
        else keys = {-1}
        end if
        
        v1 = debugger
        
        if findkey(keys, 1) then -- esc was pressed
            -- confirm exiting
            if game_over then
                exit
            end if
            if confirm("Are you sure?", "End this game? [y/n]") then
                -- get out
                exit
            end if
        elsif findkey(keys, S_KEY_F2) then
            msg("Sorry...", "Not supported yet.")
        elsif findkey(keys, S_KEY_F10) then
            if debugger then debugger = OFF
            else debugger = ON
            end if
        end if

        -- this cycle's time - used for delay stuff
        cycle_time = time()

        redraw_pre = FALSE
        sb_redraw = FALSE
        
        if debugger != v1 then
            if debugger then
                v1 = text_rows(50)
            else
                v1 = text_rows(25)
                apply_board_settings(board)
                video_mode(EGA)
            end if
            board_redraw = TRUE
        end if
        
        if debugger then
            position(27, 1)
            printf(1, "cycle_time: %3.3f  board: %d, obj. count: %d", {cycle_time, board, length(o)})
        end if
        
        if focus_object > 0 then
            if o[focus_object][1][OBJ_CYCLE] < .1 then
                o[focus_object][1][OBJ_CYCLE] = 1
            end if
        end if  
        
        -- time to update messages yet?
        if cycle_time > msg_time then

            if game_over then
            
                messages = {{"Game Over!", FLASHING, cycle_time + 10, 25, CENTERED}}
                
            end if

            msg_time = cycle_time + MSG_UPDATEINT
    
            update_messages(board, o, offsets, visible_layers, viewport, layer_table)
            sidebar_ge_draw_stats()
            
        end if

        old_board = board
        old_locs = repeat({}, length(o))
        
        die_coords = {}
        
        set_focus = FALSE

        -- starting a cycle
        z = 1
        while z do
        
            if z > length(o) then
                exit
            end if

            appender = {}
            set_to_die = 0
            
            -- reset the object's old coordinate registers
            if find(0, old_locs[z]) = 0 then
                old_locs[z] = {o[z][1][OBJ_X], o[z][1][OBJ_Y], o[z][1][OBJ_LAYER]}
            end if

            -- is there something that needs to go?
            if length(next_statement[z]) then   -- yes
                -- enable the object to go if it is stopped
                if o[z][1][OBJ_POS] = OBJ_HALTED then
                    o[z][1][OBJ_POS] = 1
                end if
                -- set it to go
                o[z][1][OBJ_RUNSTATE] = 0
            end if
            
            if o[z][1][OBJ_POS] != OBJ_HALTED
            or o[z][1][OBJ_WALKDIR] != 0 then  -- is the object running?
            
                walk_flag = FALSE

                -- account for halted/walking
                if o[z][1][OBJ_POS] = OBJ_HALTED
                and o[z][1][OBJ_WALKDIR] != 0 then
                    walk_flag = TRUE
                    o[z][1][OBJ_POS] = 1
                end if

                -- is the object idling?
                if o[z][1][OBJ_RUNSTATE] != 0 then
                    
                    -- it is, check to see if it can go yet
                    if cycle_time > (o[z][1][OBJ_RUNSTATE] +
                        (TPS * o[z][1][OBJ_CYCLE])) then
                        o[z][1][OBJ_RUNSTATE] = 0
                    end if
                    
                else

                    if length(o[z]) > 1 then
                        save_point = o[z][1][OBJ_POS] + 1
                        save_line = o[z][save_point]
                    else
                        save_point = 1
                        save_line = o[z][save_point]    -- ???
                    end if
                    
                    -- it's ready to rock, set the code pointer from OBJ_POS
                    l = o[z][1][OBJ_POS] + 1
                    -- we should increment at the end by default.
                    -- statements like #if set increment to false.
                    increment = TRUE

                    -- is there a statement from #if that needs to be executed?
                    if length(next_statement[z]) then   -- yes
                        if atom(next_statement[z][1]) then
                            if next_statement[z][1] = 16384 then
                                -- jumping to a line from a scroll
                                o[z][1][OBJ_POS] = next_statement[z][2]
                                l = o[z][1][OBJ_POS] + 1
                                o[z][1][OBJ_RUNSTATE] = 0
                                increment = TRUE
                            else
                                o[z][l] = next_statement[z]
                                increment = FALSE
                            end if
                        else
                            o[z][l] = next_statement[z]
                            increment = FALSE
                        end if
                        next_statement[z] = {}
                    end if

                    if length(o[z][l]) != 0
                    and not walk_flag then    -- this line has something

                        if o[z][l][1] = CMD_STATEMENT
                        or o[z][l][1] = CMD_VARASSIGN then

                            aa = length(o[z][l][2])
                            if atom(o[z][l][2][1]) then
                                if o[z][l][2][1] = C_IF then
                                    v1 = find("then", o[z][l][2])
                                    if v1 then
                                        aa = v1
                                    end if
                                end if
                            end if
                        
                            -- look for flags
                            v1 = 1
                            if o[z][l][1] = CMD_STATEMENT then
                                if o[z][l][2][1] = C_SET
                                or o[z][l][2][1] = C_CLEAR then
                                    v1 = 0
                                end if
                            end if

                            if v1 then
                                for a = 2 to aa do
                                    for b = 1 to length(flags) do
                                        if compare(flags[b][FLAG_NAME], lower(o[z][l][2][a])) = 0 then
                                            o[z][l][2][a] = sprintf("%d", get_flag_value(lower(o[z][l][2][a])))
                                        end if
                                    end for
                                end for
                            end if
                            
                            -- look for variable usages
                            aa = length(o[z][l][2])
                            if atom(o[z][l][2][1]) then
                                if o[z][l][2][1] = C_IF then
                                    v1 = find("then", o[z][l][2])
                                    if v1 then
                                        aa = v1
                                    end if
                                end if
                            end if
                            
                            for a = 2 to aa do
                                if o[z][l][2][a][1] = '%'
                                and find('.', o[z][l][2][a]) > 1 then
                                    v1 = o[z][l][2][a][2..find('.', o[z][l][2][a]) - 1]
                                    v2 = 0
                                    v3 = o[z][l][2][a][find('.', o[z][l][2][a]) + 1..length(o[z][l][2][a])]
                                    if compare(v1, "me") = 0 then
                                        v2 = z
                                    else v2 = find_object_by_name(o, v1)
                                    end if
                                    if v2 != 0 then
                                        v4 = 0
                                        if compare(v3, "x") = 0 then
                                            v4 = o[v2][1][OBJ_X]
                                        elsif compare(v3, "y") = 0 then
                                            v4 = o[v2][1][OBJ_Y]
                                        elsif compare(v3, "layer") = 0 then
                                            v4 = o[v2][1][OBJ_LAYER]
                                        elsif compare(v3, "char") = 0 then
                                            v4 = o[v2][1][OBJ_CHAR]
                                        elsif compare(v3, "color") = 0 then
                                            v4 = o[v2][1][OBJ_COLOR]
                                        end if
                                        o[z][l][2][a] = sprintf("%d", v4)
                                    end if
                                elsif compare(o[z][l][2][a], "%prop1") = 0 then
                                    if length(o[z][1][OBJ_PROPS]) >= 1 then
                                        o[z][l][2][a] = sprintf("%d", o[z][1][OBJ_PROPS][1])
                                    end if
                                elsif compare(o[z][l][2][a], "%prop2") = 0 then
                                    if length(o[z][1][OBJ_PROPS]) >= 1 then
                                        o[z][l][2][a] = sprintf("%d", o[z][1][OBJ_PROPS][2])
                                    end if
                                elsif compare(o[z][l][2][a], "%prop3") = 0 then
                                    if length(o[z][1][OBJ_PROPS]) >= 1 then
                                        o[z][l][2][a] = sprintf("%d", o[z][1][OBJ_PROPS][3])
                                    end if
                                elsif compare(o[z][l][2][a], "%prop4") = 0 then
                                    if length(o[z][1][OBJ_PROPS]) >= 1 then
                                        o[z][l][2][a] = sprintf("%d", o[z][1][OBJ_PROPS][4])
                                    end if
                                    
                                end if
                            end for
                            

                            -- look for variable usages
                            aa = length(o[z][l][2])
                            if atom(o[z][l][2][1]) then
                                if o[z][l][2][1] = C_IF then
                                    v1 = find("then", o[z][l][2])
                                    if v1 then
                                        aa = v1
                                    end if
                                end if
                            end if
                            
                            -- if it is a variable assignment, do not convert 1st
                            if o[z][l][1] = CMD_VARASSIGN then
                                v2 = 2
                            else v2 = 1
                            end if

                            while aa > v2 do
                                if length(o[z][l][2][aa]) = 0 then
                                    o[z][l][2][aa] = {0}
                                end if
                                if o[z][l][2][aa][1] = '%' then
                                    o[z][l][2][aa] = sprintf("%d", get_var_value(lower(o[z][l][2][aa][2..length(o[z][l][2][aa])])))
                                end if
                                aa = aa - 1
                            end while
                            
                            -- look for directional stuff
                            aa = length(o[z][l][2])
                            
                            while aa > 1 do
                                v1 = lower(o[z][l][2][aa])
                                
                                if aa != length(o[z][l][2]) then
                                    if compare(v1, "cw") = 0 then
                                        o[z][l][2][aa] = {dir_spin(o[z][l][2][aa + 1][1], 1)}
                                        o[z][l][2] = o[z][l][2][1..aa] & o[z][l][2][aa + 2..length(o[z][l][2])]
                                    elsif compare(v1, "ccw") = 0 then
                                        o[z][l][2][aa] = {dir_spin(o[z][l][2][aa + 1][1], -1)}
                                        o[z][l][2] = o[z][l][2][1..aa] & o[z][l][2][aa + 2..length(o[z][l][2])]
                                    elsif compare(v1, "opp") = 0 then
                                        o[z][l][2][aa] = {dir_opp(o[z][l][2][aa + 1][1])}
                                        o[z][l][2] = o[z][l][2][1..aa] & o[z][l][2][aa + 2..length(o[z][l][2])]
                                    elsif compare(v1, "rndp") = 0 then
                                        o[z][l][2][aa] = {dir_rndp(o[z][l][2][aa + 1][1])}
                                        o[z][l][2] = o[z][l][2][1..aa] & o[z][l][2][aa + 2..length(o[z][l][2])]
                                    end if
                                end if
                                
                                if compare(v1, "rndns") = 0 then
                                    o[z][l][2][aa] = {dir_rndns()}
                                    --o[z][l][2] = o[z][l][2][1..aa] & o[z][l][2][aa + 1..length(o[z][l][2])]
                                elsif compare(v1, "rndne") = 0 then
                                    o[z][l][2][aa] = {dir_rndne()}
                                    --o[z][l][2] = o[z][l][2][1..aa] & o[z][l][2][aa + 1..length(o[z][l][2])]
                                elsif compare(v1, "rnd") = 0 then
                                    o[z][l][2][aa] = {dir_rnd()}
                                    --o[z][l][2] = o[z][l][2][1..aa] & o[z][l][2][aa + 1..length(o[z][l][2])]
                                elsif compare(v1, "flow") = 0 then
                                    if o[z][1][OBJ_FLOW] != 0 then
                                        o[z][l][2][aa] = {o[z][1][OBJ_FLOW]}
                                    end if
                                elsif compare(v1, "seek") = 0 then
                                    v1 = 0
                                    if aa != length(o[z][l][2]) then
                                        v1 = ge_find_object(o, o[z][l][2][aa + 1])
                                    end if
                                    if v1 != 0 then
                                        v2 = 1
                                    else
                                        v2 = 0
                                        if focus_object = -1 then
                                            v1 = ge_pgm_error(o[z][1][OBJ_NAME], "No focus object / couldn't find seek object.")
                                            if v1 = CE_HALT then
                                                o[z][1][OBJ_POS] = OBJ_HALTED
                                            elsif v1 = CE_ENDGAME then
                                                return
                                            end if
                                        else v1 = focus_object
                                        end if
                                    end if
                                    o[z][l][2][aa] = {dir_seek({o[v1][1][OBJ_X], o[v1][1][OBJ_Y]}, {o[z][1][OBJ_X], o[z][1][OBJ_Y]})}
                                    if v2 = 1 then
                                        o[z][l][2] = o[z][l][2][1..aa] & o[z][l][2][aa + 1..length(o[z][l][2])]
                                    end if
                                end if

                                aa = aa - 1
                                        
                            end while

                            -- look for operators
                            aa = length(o[z][l][2])
                            if atom(o[z][l][2][1]) then
                                if o[z][l][2][1] = C_IF then
                                    v1 = find("then", o[z][l][2])
                                    if v1 then
                                        aa = v1
                                    end if
                                end if
                            end if
                            
                            if o[z][l][1] = CMD_VARASSIGN then
                                v4 = 3
                            else v4 = 1
                            end if

                            while aa > v4 do
                            
                                if compare(o[z][l][2][aa], "+") = 0 then
                                    if aa < length(o[z][l][2])
                                    and aa > 2 then
                                        o[z][l][2][aa - 1] = sprintf("%d", (valu(o[z][l][2][aa - 1]) + valu(o[z][l][2][aa + 1])))
                                        o[z][l][2] = o[z][l][2][1..aa - 1] & o[z][l][2][aa + 2..length(o[z][l][2])]
                                        aa = aa - 1
                                    end if

                                elsif compare(o[z][l][2][aa], ">") = 0 then
                                    if aa < length(o[z][l][2])
                                    and aa > 2 then
                                        o[z][l][2][aa - 1] = sprintf("%d", (valu(o[z][l][2][aa - 1]) > valu(o[z][l][2][aa + 1])))
                                        o[z][l][2] = o[z][l][2][1..aa - 1] & o[z][l][2][aa + 2..length(o[z][l][2])]
                                        aa = aa - 1
                                    end if

                                elsif compare(o[z][l][2][aa], "<") = 0 then
                                    if aa < length(o[z][l][2])
                                    and aa > 2 then
                                        o[z][l][2][aa - 1] = sprintf("%d", (valu(o[z][l][2][aa - 1]) < valu(o[z][l][2][aa + 1])))
                                        o[z][l][2] = o[z][l][2][1..aa - 1] & o[z][l][2][aa + 2..length(o[z][l][2])]
                                        aa = aa - 1
                                    end if

                                elsif compare(o[z][l][2][aa], "-") = 0 then
                                    if aa < length(o[z][l][2])
                                    and aa > 2 then
                                        o[z][l][2][aa - 1] = sprintf("%d", (valu(o[z][l][2][aa - 1]) - valu(o[z][l][2][aa + 1])))
                                        o[z][l][2] = o[z][l][2][1..aa - 1] & o[z][l][2][aa + 2..length(o[z][l][2])]
                                        aa = aa - 1
                                    end if

                                elsif compare(o[z][l][2][aa], "*") = 0 then
                                    if aa < length(o[z][l][2])
                                    and aa > 2 then
                                        o[z][l][2][aa - 1] = sprintf("%d", (valu(o[z][l][2][aa - 1]) * valu(o[z][l][2][aa + 1])))
                                        o[z][l][2] = o[z][l][2][1..aa - 1] & o[z][l][2][aa + 2..length(o[z][l][2])]
                                        aa = aa - 1
                                    end if
                                    
                                elsif compare(o[z][l][2][aa], "/") = 0 then
                                    if aa < length(o[z][l][2])
                                    and aa > 2 then
                                        o[z][l][2][aa - 1] = sprintf("%d", (valu(o[z][l][2][aa - 1]) / valu(o[z][l][2][aa + 1])))
                                        o[z][l][2] = o[z][l][2][1..aa - 1] & o[z][l][2][aa + 2..length(o[z][l][2])]
                                        aa = aa - 1
                                    end if
                                    
                                elsif compare(lower(o[z][l][2][aa]), "not") = 0 then
                                    if aa < length(o[z][l][2]) then
                                        o[z][l][2][aa] = sprintf("%d", valu(o[z][l][2][aa + 1]) != 1)
                                        o[z][l][2] = o[z][l][2][1..aa] & o[z][l][2][aa + 2..length(o[z][l][2])]
                                        aa = aa - 1
                                    end if
                                    
                                elsif compare(lower(o[z][l][2][aa]), "keyb") = 0 then
                                    if aa < length(o[z][l][2]) and game_over = FALSE then
                                        v1 = o[z][l][2][aa + 1]
                                        v2 = 0
                                        if compare("up", v1) = 0 then
                                            if findkey(keys, KEY_UP) then v2 = 1 end if

                                        elsif compare("down", v1) = 0 then
                                            if findkey(keys, KEY_DN) then v2 = 1 end if

                                        elsif compare("left", v1) = 0 then
                                            if findkey(keys, KEY_LF) then v2 = 1 end if

                                        elsif compare("right", v1) = 0 then
                                            if findkey(keys, KEY_RT) then v2 = 1 end if
                                        
                                        elsif compare("shiftup", v1) = 0 then
                                            if findkey(keys, KEY_UP + 1024) then v2 = 1 end if
                                        
                                        elsif compare("shiftdown", v1) = 0 then
                                            if findkey(keys, KEY_DN + 1024) then v2 = 1 end if
                                        
                                        elsif compare("shiftleft", v1) = 0 then
                                            if findkey(keys, KEY_LF + 1024) then v2 = 1 end if
                                        
                                        elsif compare("shiftright", v1) = 0 then
                                            if findkey(keys, KEY_RT + 1024) then v2 = 1 end if
                                            
                                        elsif compare("enter", v1) = 0 then
                                            if findkey(keys, 28) then
                                                v2 = 1
                                            end if
                                        
                                        elsif compare("space", v1) = 0 then
                                            if findkey(keys, 57) then v2 = 1 end if
                                            
                                        elsif length(v1) = 1 then
                                        
                                            v1 = upper(v1[1])
                                            if v1 >= 'A' and v1 <= 'Z' then
                                                if findkey(keys, S_ALPHA_TABLE[(v1 - 'A') + 1]) then
                                                    v2 = 1
                                                end if
                                            end if
                                            
                                            if v1 >= '0' and v1 <= '9' then
                                                if findkey(keys, S_NUM_TABLE[(v1 - '0') + 1]) then
                                                    v2 = 1
                                                end if
                                                
                                                if findkey(keys, S_NUMPAD_TABLE[(v1 - '0') + 1]) then
                                                    v2 = 1
                                                end if
                                            end if
                                        end if
                                        o[z][l][2][aa] = sprintf("%d", v2)
                                        o[z][l][2] = o[z][l][2][1..aa] & o[z][l][2][aa + 2..length(o[z][l][2])]
                                    end if

                                elsif compare(lower(o[z][l][2][aa]), "blocked") = 0 then
                                    if aa < length(o[z][l][2]) then
                                            v1 = o[z][1][OBJ_X]
                                            v2 = o[z][1][OBJ_Y]
                                            v3 = o[z][l][2][aa + 1][1]
                                            if v3 = 'n' then v1 -= 1
                                            elsif v3 = 's' then v1 += 1
                                            elsif v3 = 'w' then v2 -= 1
                                            elsif v3 = 'e' then v2 += 1
                                            end if
                                            if coords_in_range(board, v1, v2) then
                                                v3 = eget(board, v1, v2, o[z][1][OBJ_LAYER], BRD_TILECHAR)
                                                if v3 = 0 then
                                                    v3 = ge_find_object_at_xy(o, v1, v2, o[z][1][OBJ_LAYER])
                                                    if v3 = 0 then
                                                        o[z][l][2][aa + 1] = "0"
                                                    else
                                                        if o[v3][1][OBJ_COLLIDE] = TRUE then
                                                            o[z][l][2][aa + 1] = "1"
                                                        else o[z][l][2][aa + 1] = "0"
                                                        end if
                                                    end if
                                                else
                                                    o[z][l][2][aa + 1] = "1"
                                                end if
                                            else
                                                o[z][l][2][aa + 1] = "1"
                                            end if
                                            o[z][l][2] = o[z][l][2][1..aa - 1] & o[z][l][2][aa + 1..length(o[z][l][2])]
                                    end if
                                
                                elsif compare(lower(o[z][l][2][aa]), "contact") = 0 then
                                    if focus_object != -1 then
                                        v1 = focus_object
                                        v2 = 0
                                        if o[z][1][OBJ_X] = o[v1][1][OBJ_X] then
                                            if o[z][1][OBJ_Y] = o[v1][1][OBJ_Y] - 1
                                            or o[z][1][OBJ_Y] = o[v1][1][OBJ_Y] + 1 then
                                                v2 = 1
                                            end if
                                        else
                                            if o[z][1][OBJ_Y] = o[v1][1][OBJ_Y] then
                                                if o[z][1][OBJ_X] = o[v1][1][OBJ_X] - 1
                                                or o[z][1][OBJ_X] = o[v1][1][OBJ_X] + 1 then
                                                    v2 = 1
                                                end if
                                            end if
                                        end if
                                    else
                                        v2 = 0
                                    end if
                                    o[z][l][2][aa] = sprintf("%d", v2)
                                    
                                elsif compare(lower(o[z][l][2][aa]), "getobjname") = 0 then
                                    if aa + 1 < length(o[z][l][2]) then
                                        v2 = translate_dir(o[z][l][2][aa + 1][1])
                                        v1 = ge_find_object_at_xy(o, o[z][1][OBJ_X] + v2[1], o[z][1][OBJ_Y] + v2[2], o[z][1][OBJ_LAYER])
                                        if v1 then
                                            o[z][l][2][aa] = o[v1][1][OBJ_NAME]
                                        else o[z][l][2][aa] = "null"
                                        end if
                                        o[z][l][2] = o[z][l][2][1..aa] & o[z][l][2][aa + 2..length(o[z][l][2])]
                                    end if
                                    
                                elsif compare(lower(o[z][l][2][aa]), "alligned") = 0 then
                                    v1 = focus_object
                                    v2 = 0
                                    if v1 != -1 then
                                        if o[z][1][OBJ_X] = o[v1][1][OBJ_X]
                                        or o[z][1][OBJ_Y] = o[v1][1][OBJ_Y] then
                                            v2 = 1
                                        end if
                                    end if
                                    o[z][l][2][aa] = sprintf("%d", v2)
                                    
                                elsif compare(lower(o[z][l][2][aa]), "flag") = 0 then
                                    if aa < length(o[z][l][2]) then
                                        o[z][l][2] = o[z][l][2][1..aa - 1] & {sprintf("%d", get_flag_value(lower(o[z][l][2][aa + 1])))} & o[z][l][2][aa + 2..length(o[z][l][2])]
                                    end if
                                    
                                elsif compare(lower(o[z][l][2][aa]), "colorname") = 0 then
                                    if aa < length(o[z][l][2]) then
                                        v1 = valu(o[z][l][2][aa + 1])
                                        if v1 > -1 and v1 < 16 then
                                            v1 = v1 + 1
                                            o[z][l][2] = o[z][l][2][1..aa - 1] & {lit_color_table[v1]} & o[z][l][2][aa + 2..length(o[z][l][2])]
                                        end if
                                    end if
                                    
                                elsif compare(lower(o[z][l][2][aa]), "dirval") = 0 then
                                    v1 = 0
                                    if aa < length(o[z][l][2]) then
                                        if o[z][l][2][aa + 1][1] = 'n' then
                                            v1 = '1'
                                        elsif o[z][l][2][aa + 1][1] = 's' then
                                            v1 = '2'
                                        elsif o[z][l][2][aa + 1][1] = 'w' then
                                            v1 = '3'
                                        elsif o[z][l][2][aa + 1][1] = 'e' then
                                            v1 = '4'
                                        end if
                                        o[z][l][2] = o[z][l][2][1..aa - 1] & {{v1}} & o[z][l][2][aa + 2..length(o[z][l][2])]
                                    end if
                                    
                                elsif compare(lower(o[z][l][2][aa]), "rand") = 0 then
                                    if aa < length(o[z][l][2]) then
                                        v1 = valu(o[z][l][2][aa + 1])
                                        o[z][l][2] = o[z][l][2][1..aa - 1] & {sprintf("%d", rand(v1))} & o[z][l][2][aa + 2..length(o[z][l][2])]
                                    end if
                                    
                                end if
                                
                                aa = aa - 1

                            end while


                            -- look for =
                            aa = length(o[z][l][2])
                            if atom(o[z][l][2][1]) then
                                if o[z][l][2][1] = C_IF then
                                    v1 = find("then", o[z][l][2])
                                    if v1 then
                                        aa = v1 
                                    end if
                                end if
                            end if

                            if o[z][l][1] = CMD_VARASSIGN then
                                v4 = 3
                            else v4 = 1
                            end if

                            while aa > v4 do
                                if compare(o[z][l][2][aa], "=") = 0 then
                                    if aa = 2 and o[z][l][1] = CMD_VARASSIGN then else
                                        if aa < length(o[z][l][2])
                                        and aa > 2 then
                                            o[z][l][2][aa - 1] = sprintf("%d", (valu(o[z][l][2][aa - 1]) = valu(o[z][l][2][aa + 1])))
                                            o[z][l][2] = o[z][l][2][1..aa - 1] & o[z][l][2][aa + 2..length(o[z][l][2])]
                                            aa = aa - 1
                                        end if
                                    end if
                                end if
                                aa = aa - 1
                            end while
                            
                            if o[z][l][1] = CMD_VARASSIGN then
                                if length(o[z][l][2]) > 2 then
                                    if length(o[z][l][2][1]) > 0 then
                                        set_var(o[z][l][2][1], valu(o[z][l][2][3]))
                                    end if
                                end if
                            end if
                            
                        end if
                                       
                        ge_debugline(o[z][l])

                        if o[z][l][1] = CMD_STATEMENT then

                            ct = o[z][l][2][1]

                            if ct = C_ADDSTAT       then
                                new_stat(o[z][l][2][2], o[z][l][2][3], valu(o[z][l][2][4]))
                                
                            elsif ct = C_BECOME then
                                
                                if length(o[z][l][2]) > 2 then
                                    v1 = lower(o[z][l][2][3])
                                    v2 = ge_trans_color(o[z][l][2][2])
                                else
                                    v1 = lower(o[z][l][2][2])
                                    v2 = o[z][1][OBJ_COLOR]
                                end if
                                
                                if find_in_lib(v1) and FALSE = TRUE then    --disabled
                                    v3 = find_in_lib(v1)
                                    o[z][1][OBJ_POS] = 1
                                    o[z][1][OBJ_RUNSTATE] = 0
                                    save_line = {}
                                    
                                    o[z][1][OBJ_CHAR] = object_library[v3][LIB_CHAR]
                                    o[z][1][OBJ_COLOR] = object_library[v3][LIB_COLOR]
                                    o[z][1][OBJ_LIBFROM] = object_library[v3][LIB_FROM]
                                    o[z][1][OBJ_NAME] = object_library[v3][LIB_NAME]
                                    o[z] = o[z][1]
                                    for zz = 1 to length(object_library[v3][LIB_PROG]) do
                                        o[z] = append(o[z], object_library[v3][LIB_PROG][zz])
                                    end for
                                    o[z] = ge_compile_object(o[z])
                                    
                                else
                                    if compare(v1, "fake") = 0 or compare(v1, "empty") = 0 then
                                        set_to_die = z
                                    end if
                                end if
                                
                            elsif ct = C_BIND       then
                                v1 = ge_find_object(o, cat(o[z][l][2][2..length(o[z][l][2])]))
                                if v1 then
                                    o[z] = ge_pgmcopy(o, z, v1)
                                    o[z][1][OBJ_NAME] = o[v1][1][OBJ_NAME]
                                    o[z][1][OBJ_POS] = 1
                                    o[z][1][OBJ_RUNSTATE] = 0
                                    save_line = {}
                                else
                                    v1 = ge_pgm_error(o[z][1][OBJ_NAME], "Object to #bind to does not exist: " & o[z][l][2][2])
                                    if v1 = CE_HALT then
                                        o[z][1][OBJ_POS] = OBJ_HALTED
                                    elsif v1 = CE_ENDGAME then
                                        return
                                    end if
                                end if

                            elsif ct = C_BINDAPPEND then
                                if ge_find_object(o, o[z][l][2][2]) then
                                    o[z] = ge_pgmcopy(o, z, ge_find_object(o, o[z][l][2][2]))
                                    o[z][1][OBJ_NAME] = {}
                                    o[z][1][OBJ_POS] = 1
                                    o[z][1][OBJ_RUNSTATE] = 0
                                    save_line = {}
                                else
                                    v1 = ge_pgm_error(o[z][1][OBJ_NAME], "Object to #bindappend to does not exist: " & o[z][l][2][2])
                                    if v1 = CE_HALT then
                                        o[z][1][OBJ_POS] = OBJ_HALTED
                                    elsif v1 = CE_ENDGAME then
                                        return
                                    end if
                                end if

                            elsif ct = C_CHANGE     then
                            elsif ct = C_CHANGEAREA then
                            elsif ct = C_CHAR       then
                                o[z][1][OBJ_CHAR] = valu(o[z][l][2][2])
                                old_locs[z] = {0,0,0}

                            elsif ct = C_CLEAR      then
                                set_flag(o[z][l][2][2], FALSE)

                            elsif ct = C_CLONE      then
                                --{DT_OBJECT, DT_STRING, DT_SCD, DT_SCD}
                                v1 = ge_find_object(o, lower(o[z][l][2][2]))
                                if v1 then
                                    o = append(o, o[v1])
                                    v1 = length(o)
                                    o[v1][1][OBJ_X] = valu(o[z][l][2][3])
                                    o[v1][1][OBJ_Y] = valu(o[z][l][2][4])
                                    o[v1][1][OBJ_POS] = 1
                                    o[v1][1][OBJ_RUNSTATE] = 0
                                    o[v1][1][OBJ_LOCKED] = 0
                                    
                                    next_statement = append(next_statement, {})
                                    scroll_accums = append(scroll_accums, {})
                                    old_locs = append(old_locs, {0, 0, 0})
                                    layer_table = make_layer_table(o, world[WRLD_BOARDS][board][BRD_LAYERS])
                                end if
                            
                            elsif ct = C_COLOR      then
                                o[z][1][OBJ_COLOR] = ge_trans_color(o[z][l][2][2])
                                old_locs[z] = {0,0,0}
                                      
                            elsif ct = C_CYCLE      then
                                if length(o[z][l][2]) > 1 then
                                    o[z][1][OBJ_CYCLE] = valu(o[z][l][2][2])
                                end if

                            elsif ct = C_DELSTAT    then
                                if kill_stat(o[z][l][2][2]) then
                                    v1 = ge_pgm_error(o[z][1][OBJ_NAME], "Stat not found to kill: " & o[z][l][2][2])
                                    if v1 = CE_HALT then
                                        o[z][1][OBJ_POS] = OBJ_HALTED
                                    elsif v1 = CE_ENDGAME then
                                        return
                                    end if
                                end if

                            elsif ct = C_DIE        then
                                if length(o) = 1 then
                                    v1 = ge_pgm_error(o[z][1][OBJ_NAME], "Last object on board should not die.")
                                    if v1 = CE_HALT then
                                        o[z][1][OBJ_POS] = OBJ_HALTED
                                    elsif v1 = CE_ENDGAME then
                                        return
                                    end if
                                else
                                    set_to_die = z
                                end if

                            elsif ct = C_END        then
                                o[z][1][OBJ_POS] = OBJ_HALTED
                                increment = FALSE

                            elsif ct = C_ENDGAME    then
                            
                                game_over = TRUE
                            
                            elsif ct = C_FADE       then

                                if compare(lower(o[z][l][2][2]), "out") = 0 then
                                    fade_out(valu(o[z][l][2][3]) / 2)
                                    fade_out_end()
                                elsif compare(lower(o[z][l][2][2]), "restore") = 0 then
                                    fade_out_end()
                                else
                                    v1 = ge_pgm_error(o[z][1][OBJ_NAME], "Unrecognized #fade method: " & o[z][l][2][2])
                                    if v1 = CE_HALT then
                                        o[z][1][OBJ_POS] = OBJ_HALTED
                                    elsif v1 = CE_ENDGAME then
                                        return
                                    end if
                                end if

                            elsif ct = C_FOCUS      then
                                focus_object = z

                            elsif ct = C_GHOST      then
                                o[z][1][OBJ_COLLIDE] = FALSE
                                
                            elsif ct = C_GIVE then
                                set_var(o[z][l][2][2], get_var_value(o[z][l][2][2]) + valu(o[z][l][2][3]))
                            
                            elsif ct = C_IDLE       then
                                o[z][1][OBJ_RUNSTATE] = cycle_time
                                
                            elsif ct = C_ITEMDIE then
                                if focus_object != -1 then
                                    v1 = o[focus_object][1][OBJ_X]
                                    v2 = o[focus_object][1][OBJ_Y]
                                    v3 = 0
                                    for a1 = -1 to 1 do
                                        for a2 = -1 to 1 do
                                            if o[z][1][OBJ_X] = v1 + a1
                                            and o[z][1][OBJ_Y] = v2 + a2 then
                                                v3 = 1
                                                exit
                                            end if
                                        end for
                                    end for
                                    
                                    if v3 then
                                        die_coords = append(die_coords, {o[focus_object][1][OBJ_X], o[focus_object][1][OBJ_Y]})
                                        o[focus_object][1][OBJ_X] = o[z][1][OBJ_X]
                                        o[focus_object][1][OBJ_Y] = o[z][1][OBJ_Y]
                                        old_locs[focus_object] = {0,0,0}
                                    end if
                                end if
                                set_to_die = z

                            elsif ct = C_IF then
                                v1 = valu(o[z][l][2][2])
                                if v1 then
                                    if compare(lower(o[z][l][2][3]), "then") = 0 then
                                        v2 = 4
                                    else v2 = 3
                                    end if
                                    -- add else and error checking, later
                                    if length(o[z][l][2][v2]) > 0 then
                                        if o[z][l][2][v2][1] != '#'
                                        and o[z][l][2][v2][1] != '/'
                                        and o[z][l][2][v2][1] != '?'
                                        and o[z][l][2][v2][1] != '!'
                                        and o[z][l][2][v2][1] != '%' then
                                            o[z][l][2][v2] = "#" & o[z][l][2][v2]
                                        end if
                                    end if
                                    next_statement[z] = compile_line(cat(o[z][l][2][v2..length(o[z][l][2])]), {board, z, o[z][1][OBJ_NAME]})
                                    next_statement[z] = next_statement[z][1]
                                    increment = TRUE
                                else
                                    next_statement[z] = {}
                                    
                                end if
                                
                            elsif ct = C_LINES then
                                
                                if valu(o[z][l][2][2]) = 43 then
                                    v1 = text_rows(43)
                                    screen_sizex = 43
                                    font_squish = TRUE
                                    allow_all_paledit()
                                    blink(0)
                                    apply_board_settings(board)
                                    board_redraw = TRUE
                                    high_mode = TRUE
                                elsif valu(o[z][l][2][2]) = 25 then
                                    v1 = text_rows(25)
                                    screen_sizex = 25
                                    font_squish = FALSE
                                    allow_all_paledit()
                                    blink(0)
                                    apply_board_settings(board)
                                    if viewport[3] > screen_sizex then
                                        viewport = {1,1,25,80}
                                    end if
                                    board_redraw = TRUE
                                    high_mode = FALSE
                                end if

                            elsif ct = C_LOADFONT   then
                                v1 = open(o[z][l][2][2], "rb")
                                if v1 then
                                    v2 = load_charset(v1)
                                    add_all_fonts(0, v2)
                                    close(v1)
                                end if
                            
                            elsif ct = C_LOADMOD    then
                                if load_mod(o[z][l][2][2]) then
                                    v1 = ge_pgm_error(o[z][1][OBJ_NAME], "Could not load MOD: " & o[z][l][2][2])
                                    if v1 = CE_HALT then
                                        o[z][1][OBJ_POS] = OBJ_HALTED
                                    elsif v1 = CE_ENDGAME then
                                        return
                                    end if
                                else
                                    unpause_sound()
                                end if

                            elsif ct = C_OFFSET then
                            
                                if compare(lower(o[z][l][2][2]), "auto") = 0 then
                                    offset_auto = z
                                    v1 = viewport[1] + floor((viewport[3] - viewport[1]) / 2)
                                    v2 = viewport[2] + floor((viewport[4] - viewport[2]) / 2)
                                    offsets = {o[z][1][OBJ_X] - v1, o[z][1][OBJ_Y] - v2}
                                else
                                    offset_auto = -1
                                    if length(o[z][l][2]) > 2 then
                                        offsets = {valu(o[z][l][2][2]), valu(o[z][l][2][3])}
                                    end if
                                end if
                                board_redraw = TRUE

                            elsif ct = C_PLAYMOD    then
                                
                                if config[SOUND_ON] then
                                    unpause_sound()
                                end if
                            
                            elsif ct = C_PAUSEMOD   then
                            
                                if config[SOUND_ON] then
                                    pause_sound()
                                end if
                            
                            elsif ct = C_PUSHABLE then
                            
                                o[z][1][OBJ_PUSHABLE] = 1
                            
                            elsif ct = C_PUT then
                            
                                if length(o[z][l][2]) > 2 then
                                    v1 = o[z][1][OBJ_X]
                                    v2 = o[z][1][OBJ_Y]
                                    o[z][l][2][2][1] = lower(o[z][l][2][2][1])
                                    if o[z][l][2][2][1] = 'n' then
                                        v1 -= 1
                                    elsif o[z][l][2][2][1] = 's' then
                                        v1 += 1
                                    elsif o[z][l][2][2][1] = 'w' then
                                        v2 -= 1
                                    elsif o[z][l][2][2][1] = 'e' then
                                        v2 += 1
                                    end if
                                    
                                    o[z][l][2][3] = lower(o[z][l][2][3])
                                    
                                    v3 = 0
                                    v4 = 0
                                    
                                    if find(o[z][l][2][3], color_table)  then
                                        
                                    end if
                                
                                    if compare(o[z][l][2][3], "empty") = 0 then
                                    elsif compare(o[z][l][2][3], "fake") = 0 then
                                        v4 = 0
                                    end if
                
                                    if v3 then
                                        v3 = ge_find_object_at_xy(o, v1, v2, o[z][1][OBJ_LAYER])
                                        if v3 then
                                            if v3 = focus_object
                                            and v3 != -1 then
                                                v3 = ge_pgm_error(o[z][1][OBJ_NAME], "Don't kill the focus object with #put.")
                                                if v3 = CE_HALT then
                                                    o[z][1][OBJ_POS] = OBJ_HALTED
                                                elsif v3 = CE_ENDGAME then
                                                    return
                                                end if
                                                v3 = 0
                                            else
                                                set_to_die = v3
                                            end if
                                        end if
                                    end if
                                
                                    die_coords = append(die_coords, {v1, v2})
                                end if
                                    
                            elsif ct = C_MOVE       then

                                o[z][1][OBJ_X] = valu(o[z][l][2][2])
                                o[z][1][OBJ_Y] = valu(o[z][l][2][3])
                                if length(o[z][l][2]) > 3 then
                                    o[z][1][OBJ_LAYER] = valu(o[z][l][2][4])
                                    layer_table = make_layer_table(o, world[WRLD_BOARDS][board][BRD_LAYERS])
                                end if
                            
                            elsif ct = C_MOVETOBOARD then

                                v1 = valu(o[z][l][2][2])
                                if v1 = 0 then
                                    v1 = o[z][l][2][2..length(o[z][l][2])]
                                    v2 = {}
                                    for a = 1 to length(v1) do
                                        v2 = v2 & (v1[a] & " ")
                                    end for
                                    v1 = 0
                                    v2 = lower(v2[1..length(v2) - 1])
                                    
                                    for a = 1 to length(world[WRLD_BOARDS]) do
                                        if compare(trim(lower(world[WRLD_BOARDS][a][BRD_NAME])), v2) = 0 then
                                            v1 = a
                                            exit
                                        end if
                                    end for
                                end if
                                
                                if v1 != 0 and v1 != board then
                                    o[z][1][OBJ_POS] = o[z][1][OBJ_POS] + 1
                                    if o[z][1][OBJ_POS] >= length(o[z]) then
                                        o[z][1][OBJ_POS] = OBJ_HALTED
                                    end if
                                    v3 = new_object(v1)
                                    world[WRLD_BOARDS][v1][BRD_OBJECTS][v3] = o[z]
                                    set_to_die = z
                                end if

                            elsif ct = C_PLAYWAV    then
                            
                                v1 = load_wave(o[z][l][2][2])
                                if sequence(v1) then
                                    unpause_sound()
                                    v1 = play_wave(v1, 0, 100)
                                end if
                            
                            elsif ct = C_LOCK       then
                            
                                o[z][1][OBJ_LOCKED] = TRUE
                            
                            elsif ct = C_RESTART    then
                            
                                o[z][1][OBJ_POS] = 1
                                next_statement[z] = {}
                                l = 2
                                increment = FALSE
                            
                            elsif ct = C_RESTORE    then

                                v1 = ge_find_label(o[z], CMD_ZAPLABEL, o[z][l][2][2], 0)
                                if v1 != 0 then
                                    o[z][v1][1] = CMD_LABEL
                                end if

                            elsif ct = C_SHOOT then
                                
                                v1 = translate_dir(o[z][l][2][2][1])
                                v2 = ge_find_object_at_xy(o, o[z][1][OBJ_X] + v1[1], o[z][1][OBJ_Y] + v1[2], o[z][1][OBJ_LAYER])
                                v3 = eget(board, o[z][1][OBJ_X] + v1[1], o[z][1][OBJ_Y] + v1[2], o[z][1][OBJ_LAYER], BRD_TILECHAR)
                                
                                if v2 != 0 then
                                    v1 = ge_find_label(o[v2], CMD_LABEL, "shot", TRUE)
                                    if v1 != 0 then
                                        o[v2][1][OBJ_POS] = v1 - 1
                                        o[v2][1][OBJ_RUNSTATE] = 0
                                    end if
                                elsif v3 = 0 then
                                    o = append(o, {NEW_OBJECT[1]})
                                    v4 = length(o)
                                    o[v4] = o[v4] & bullet_code
                                    o[v4][1][OBJ_X] = o[z][1][OBJ_X] + v1[1]
                                    o[v4][1][OBJ_Y] = o[z][1][OBJ_Y] + v1[2]
                                    o[v4][1][OBJ_LAYER] = o[z][1][OBJ_LAYER]
                                    o[v4][1][OBJ_CHAR] = 7
                                    o[v4][1][OBJ_COLOR] = 15
                                    o[v4][1][OBJ_CYCLE] = 1

                                    o[v4][1] = append(o[v4][1], 'n')  -- add OBJ_FLOW
                                    o[v4][1] = append(o[v4][1], 0)    -- add OBJ_PUSHABLE
                                    o[v4][1] = append(o[v4][1], 0)    -- add OBJ_WALKDIR
                                    
                                    next_statement = append(next_statement, {})
                                    scroll_accums = append(scroll_accums, {})
                                    old_locs = append(old_locs, {0, 0})
                                
                                    v2 = {}
                                    if v1[1] = -1 then
                                        v2 = "firen"
                                    elsif v1[1] = 1 then
                                        v2 = "fires"
                                    elsif v1[2] = -1 then
                                        v2 = "firew"
                                    elsif v1[2] = 1 then
                                        v2 = "firee"
                                    end if
                                    
                                    v3 = ge_find_label(o[v4], CMD_LABEL, v2, TRUE)
                                    if v3 != 0 then
                                        o[v4][1][OBJ_POS] = v3 - 1
                                        o[v4][1][OBJ_RUNSTATE] = 0
                                    end if
                                    
                                    layer_table = make_layer_table(o, world[WRLD_BOARDS][board][BRD_LAYERS])
                                    
                                end if
                                
                            elsif ct = C_SCROLL     then
                            elsif ct = C_SCROLLAREA then
                            elsif ct = C_SEND       then

                                -- check for #send all:label
                                v4 = 0
                                if length(o[z][l][2][2]) >= 3 then
                                    if compare(lower(o[z][l][2][2][1..3]), "all") = 0
                                    or compare(lower(o[z][l][2][2][1..3]), "oth") = 0 then
                                        if length(o[z][l][2][2]) >= 6 then
                                            if compare(lower(o[z][l][2][2][1..6]), "others") then
                                                v1 = z
                                            end if
                                        end if
                                        v4 = 1
                                        v1 = 0
                                        v3 = 2
                                        if length(o[z][l][2]) > 3 then
                                            if compare(lower(o[z][l][2][3]), "but") = 0 then
                                                -- #send all but name:label
                                                v2 = find(':', o[z][l][2][4])
                                                if v2 > 0 then
                                                    v1 = ge_find_object(o, o[z][l][2][4][1..v2 - 1])
                                                end if
                                                v3 = 4
                                            end if
                                        end if
                                        v2 = find(':', o[z][l][2][v3])
                                        if v2 > 0 then
                                            -- the label
                                            v3 = o[z][l][2][v3][v2 + 1..length(o[z][l][2][v3])]
                                            for a = 1 to length(o) do
                                                if a != v1  -- if not excluded object...
                                                and a != z  -- and not this object...
                                                and o[a][1][OBJ_LOCKED] = FALSE then  -- and object is not locked
                                                    -- find it and send if ok
                                                    v2 = ge_find_label(o[a], CMD_LABEL, v3, TRUE)
                                                    if v2 != 0 then
                                                        o[a][1][OBJ_POS] = v2 - 1
                                                        --o[a][1][OBJ_RUNSTATE] = 0
                                                    end if
                                                end if
                                            end for
                                        end if
                                    end if
                                end if
    
                                if v4 = 0 then
                                    for a = 2 to length(o[z][l][2]) do
                                        if find(':', o[z][l][2][a]) then
                                            v4 = 1
                                            v1 = {}
                                            for az = 2 to a do
                                                v1 = v1 & o[z][l][2][az] & " "
                                            end for
                                            v1 = trim(v1)
                                            -- the object
                                            v2 = trim(lower(v1[1..find(':', v1) - 1]))
                                            -- the label to send
                                            v3 = lower(v1[find(':', v1) + 1..length(v1)])
                                            for az = 1 to length(o) do
                                                if compare(lower(o[az][1][OBJ_NAME]), v2) = 0
                                                and o[az][1][OBJ_LOCKED] = FALSE then
                                                    v1 = ge_find_label(o[az], CMD_LABEL, v3, TRUE)
                                                    if v1 != 0 then
                                                        o[az][1][OBJ_POS] = v1 - 1
                                                        --o[az][1][OBJ_RUNSTATE] = 0
                                                        if z = az then
                                                            l = v1
                                                        end if
                                                    end if
                                                end if
                                            end for
                                        end if
                                    end for
                                end if
                                    
                                if v4 = 0 then
                                    v1 = ge_find_label(o[z], CMD_LABEL, lower(o[z][l][2][2]), TRUE)
                                    if v1 != 0 then
                                        o[z][1][OBJ_POS] = v1 - 1
                                        l = v1
                                    end if
                                end if

                            elsif ct = C_SET        then

                                set_flag(o[z][l][2][2], TRUE)
                                
                            elsif ct = C_SENDAT then
                                
                                v1 = translate_dir(o[z][l][2][2][1])
                                v2 = ge_find_object_at_xy(o, o[z][1][OBJ_X] + v1[1], o[z][1][OBJ_Y] + v1[2], o[z][1][OBJ_LAYER])
                                if v2 != 0 then
                                    v1 = ge_find_label(o[v2], CMD_LABEL, lower(o[z][l][2][3][2..length(o[z][l][2][3])]), TRUE)
                                    if v1 != 0 then
                                        o[v2][1][OBJ_POS] = v1 - 1
                                        o[v2][1][OBJ_RUNSTATE] = 0
                                    end if
                                    
                                end if

                            elsif ct = C_SETPAL     then
                            
                                if valu(o[z][l][2][2]) < 0
                                or valu(o[z][l][2][2]) > 15 then
                                    v1 = ge_pgm_error(o[z][1][OBJ_NAME], "Bad #setpal color: " & sprintf("%d", o[z][l][2][2]))
                                    if v1 = CE_HALT then
                                        o[z][1][OBJ_POS] = OBJ_HALTED
                                    elsif v1 = CE_ENDGAME then
                                        return
                                    end if
                                else
                                    set_palette(valu(o[z][l][2][2]),
                                        {valu(o[z][l][2][3]),
                                         valu(o[z][l][2][4]),
                                         valu(o[z][l][2][5])})
                                end if
                                
                            elsif ct = C_SHIFTCHAR then
                                
                                shift_char(valu(o[z][l][2][2]), valu(o[z][l][2][3]), valu(o[z][l][2][4]))

                            elsif ct = C_SIDEBAR    then

                                sidebar = valu(o[z][l][2][2])
                                sb_redraw = TRUE

                            elsif ct = C_SOLID      then
                            
                                o[z][1][OBJ_COLLIDE] = TRUE
                                o[z][1][OBJ_PUSHABLE] = FALSE
                            
                            elsif ct = C_TAKE then
                                
                                if get_var_value(o[z][l][2][2]) - valu(o[z][l][2][3]) < 0 then
                                    if length(o[z][l][2]) > 3 then
                                        v1 = ge_find_label(o[z], CMD_LABEL, lower(o[z][l][2][4]), TRUE)
                                        if v1 != 0 then
                                            o[z][1][OBJ_POS] = v1 - 1
                                            o[z][1][OBJ_RUNSTATE] = 0
                                        end if
                                    end if
                                else
                                    set_var(o[z][l][2][2], get_var_value(o[z][l][2][2]) - valu(o[z][l][2][3]))
                                end if
    
                            elsif ct = C_TEXT then
                                
                                v1 = {valu(o[z][l][2][2]), valu(o[z][l][2][3])}
                                if coords_in_range(board, v1[1], v1[2]) then
                                    set_multi_chunk(board, o[z][1][OBJ_LAYER], v1, {t_ge_translatecodes(expand_str(o[z][l][2][4]))}, 0)
                                    draw_board_one_row(board, o, v1[1], offsets, visible_layers, viewport, layer_table)
                                end if
                            
                            elsif ct = C_TRANSPARENCY then
                            elsif ct = C_TRANSPORT  then
                            
                                v1 = valu(o[z][l][2][2])
                                if v1 = 0 then
                                    v1 = o[z][l][2][2..length(o[z][l][2])]
                                    v2 = {}
                                    for a = 1 to length(v1) do
                                        v2 = v2 & (v1[a] & " ")
                                    end for
                                    v1 = 0
                                    v2 = lower(v2[1..length(v2) - 1])
                                    
                                    for a = 1 to length(world[WRLD_BOARDS]) do
                                        if compare(trim(lower(world[WRLD_BOARDS][a][BRD_NAME])), v2) = 0 then
                                            v1 = a
                                            exit
                                        end if
                                    end for
                                end if
                                
                                if v1 != 0 and board_in_range(v1) then
                                    board = v1
                                end if
                                
                            elsif ct = C_TRANSPORTFOCUS then

                                v1 = valu(o[z][l][2][2])
                                if v1 = 0 then
                                    v1 = o[z][l][2][2..length(o[z][l][2])]
                                    v2 = {}
                                    for a = 1 to length(v1) do
                                        v2 = v2 & (v1[a] & " ")
                                    end for
                                    v1 = 0
                                    v2 = lower(v2[1..length(v2) - 1])
                                    
                                    for a = 1 to length(world[WRLD_BOARDS]) do
                                        if compare(trim(lower(world[WRLD_BOARDS][a][BRD_NAME])), v2) = 0 then
                                            v1 = a
                                            exit
                                        end if
                                    end for
                                end if
                                
                                if v1 != 0 and board_in_range(v1) then
                                    if focus_object > 0 then
                                        v3 = new_object(v1)
                                        world[WRLD_BOARDS][v1][BRD_OBJECTS][v3] = o[focus_object]
                                        oset(v1, v3, OBJ_X, world[WRLD_BOARDS][v1][BRD_SIZEX])
                                        o = ge_delete_object(o, focus_object)
                                        next_statement = cutout(next_statement, z)
                                        scroll_accums = cutout(scroll_accums, z)
                                        old_locs = cutout(old_locs, z)
                                        set_focus = TRUE
                                        focus_object = v3
                                    end if
                                    board = v1
                                    exit
                                end if

                            elsif ct = C_UNLOCK     then
                            
                                o[z][1][OBJ_LOCKED] = FALSE
                            
                            elsif ct = C_VARIABLE   then
                            elsif ct = C_VIEWPORT then

                                viewport = {valu(o[z][l][2][2]),
                                            valu(o[z][l][2][3]),
                                            valu(o[z][l][2][4]),
                                            valu(o[z][l][2][5])}
                                            
                                board_redraw = TRUE
                                bk_redraw = TRUE

                            elsif ct = C_VISLAYER   then
                                if length(o[z][l][2]) > world[WRLD_BOARDS][board][BRD_LAYERS] then
                                    visible_layers = repeat(1, world[WRLD_BOARDS][board][BRD_LAYERS])
                                    for zee = 2 to world[WRLD_BOARDS][board][BRD_LAYERS] + 1 do
                                        visible_layers[zee - 1] = (valu(o[z][l][2][zee]) = 1)
                                    end for
                                end if
                                board_redraw = TRUE
                            
                            elsif ct = C_WALK then
                            
                                o[z][l][2][2][1] = lower(o[z][l][2][2][1])
                                
                                if o[z][l][2][2][1] = 'n'
                                or o[z][l][2][2][1] = 's'
                                or o[z][l][2][2][1] = 'w'
                                or o[z][l][2][2][1] = 'e' then
                                    o[z][1][OBJ_WALKDIR] = o[z][l][2][2][1]
                                elsif o[z][l][2][2][1] = 'i'
                                or compare(o[z][l][2][2], "idle") = 0 then
                                    o[z][1][OBJ_WALKDIR] = 0
                                end if
                                    
                            elsif ct = C_GO         then
                            
                                if o[z][l][2][2][1] = 'n' then
                                    o[z][1][OBJ_X] -= 1
                                elsif o[z][l][2][2][1] = 's' then
                                    o[z][1][OBJ_X] += 1
                                elsif o[z][l][2][2][1] = 'w' then
                                    o[z][1][OBJ_Y] -= 1
                                elsif o[z][l][2][2][1] = 'e' then
                                    o[z][1][OBJ_Y] += 1
                                end if
                                if o[z][l][2][2][1] >= 'e'
                                and o[z][l][2][2][1] != 'i' then
                                    o[z][1][OBJ_FLOW] = lower(o[z][l][2][2][1])
                                end if
                                o[z][1][OBJ_RUNSTATE] = cycle_time
                                
                            elsif ct = C_ZAP        then
                                    
                                if length(o[z][l][2]) > 1 then
                                    v1 = ge_find_label(o[z], CMD_LABEL, o[z][l][2][2], TRUE)
                                    if v1 != 0 then
                                        o[z][v1][1] = CMD_ZAPLABEL
                                    end if
                                end if

                            end if

                        elsif o[z][l][1] = CMD_VARASSIGN then

                        elsif o[z][l][1] = CMD_MSG then
                                                
                            for b = 1 to length(variables) do
                                v1 = match('%' & variables[b][VAR_NAME], lower(o[z][l][2]))
                                if v1 != 0 then
                                    v2 = v1 + length(variables[b][VAR_NAME]) + 1
                                    o[z][l][2] = o[z][l][2][1..v1 - 1] &
                                            sprintf("%d", get_var_value(b)) &
                                            o[z][l][2][v2..length(o[z][l][2])]
                                end if
                            end for

                            v1 = find('%', o[z][l][2])                            
                            if v1 then
                                v2 = 0
                                if v1 != 1 then
                                    if o[z][l][2][v1 - 1] = ' ' then
                                        v2 = 1
                                    end if
                                else v2 = 1
                                end if
                                
                                if v2 = 1 then
                                    v2 = find('.', o[z][l][2])
                                    if v2 - 1 > v1 then
                                        v3 = o[z][l][2][v1 + 1..v2 - 1]
                                        v4 = o[z][l][2][v2 + 1..length(o[z][l][2])] & "    "
                                        
                                        if compare(v3, "me") = 0 then
                                            v1 = z
                                        else v1 = find_object_by_name(o, v3)
                                        end if
                                        
                                        if v1 != 0 then
                                            v2 = 0
                                            v3 = 0
                                            if v4[1] = 'x' then
                                                v2 = o[v1][1][OBJ_X]
                                                v3 = 1
                                            elsif v4[1] = 'y' then
                                                v2 = o[v1][1][OBJ_Y]
                                                v3 = 1
                                            elsif compare(v4[1..5], "layer") = 0 then
                                                v2 = o[v1][1][OBJ_LAYER]
                                                v3 = 5
                                            elsif compare(v4[1..4], "char") = 0 then
                                                v2 = o[v1][1][OBJ_CHAR]
                                                v3 = 4
                                            elsif compare(v4[1..5], "color") = 0 then
                                                v2 = o[v1][1][OBJ_COLOR]
                                                v3 = 5
                                            end if
                                            
                                            if find('%', o[z][l][2]) = 1 then
                                                o[z][l][2] = sprintf("%d", v2) & o[z][l][2][find('.', o[z][l][2]) + v3 + 1..length(o[z][l][2])]
                                            else
                                                o[z][l][2] = o[z][l][2][1..find('%', o[z][l][2]) - 1] & sprintf("%d", v2) & o[z][l][2][find('.', o[z][l][2]) + v3 + 1..length(o[z][l][2])]
                                            end if
                                        end if
                                    end if
                                end if
                            end if
                                                        
                            v1 = match("|colorname", lower(o[z][l][2]))
                            if v1 != 0 then
                                if length(o[z][l][2]) >= v1 + 10 then
                                    v2 = trim(o[z][l][2][v1 + 10..length(o[z][l][2])])
                                    if find(' ', v2) then
                                        v2 = v2[1..find(' ', v2) - 1]
                                    end if
                                    v3 = v2
                                    v2 = color_element_fore(valu(v2))
                                    if v2 > -1 and v2 < 16 then
                                        v2 = v2 + 1
                                        o[z][l][2] = o[z][l][2][1..v1 - 1] & color_table[v2] & " " & o[z][l][2][v1 + 12 + length(v3)..length(o[z][l][2])]
                                    end if
                                end if
                            end if
                        
                            scroll_accums[z] = append(scroll_accums[z], o[z][l][2])

                        elsif o[z][l][1] = CMD_NAMEASSIGN then

                            o[z][1][OBJ_NAME] = o[z][l][2]

                        end if
                        
                    end if


                        if o[z][1][OBJ_WALKDIR] != 0 then
                            if o[z][1][OBJ_WALKDIR] = 'n' then
                                o[z][1][OBJ_X] -= 1
                            elsif o[z][1][OBJ_WALKDIR] = 's' then
                                o[z][1][OBJ_X] += 1
                            elsif o[z][1][OBJ_WALKDIR] = 'w' then
                                o[z][1][OBJ_Y] -= 1
                            elsif o[z][1][OBJ_WALKDIR] = 'e' then
                                o[z][1][OBJ_Y] += 1
                            end if
                            o[z][1][OBJ_RUNSTATE] = cycle_time
                        end if
                        
                        
                        -- is the object out of bounds to the north?
                        if o[z][1][OBJ_X] < 1 and o[z][1][OBJ_COLLIDE] then
                            set_focus = -2
                            -- the exit board
                            v1 = world[WRLD_BOARDS][board][BRD_EXITN]
                            -- if the board has an exit, and the current object has focus
                            if v1 != BRD_NO_EXIT
                            and focus_object = z then
                                -- check to see if the coordinate is out of bounds on the
                                -- next board. if so then we can't move.
                                if o[z][1][OBJ_Y] <= world[WRLD_BOARDS][v1][BRD_SIZEY] then
                                    -- okay, now check to see if we're blocked.
                                    v2 = eget(v1, world[WRLD_BOARDS][v1][BRD_SIZEX], o[z][1][OBJ_Y], o[z][1][OBJ_LAYER], BRD_TILECHAR)
                                    if v2 = 0 then  -- we are go
                                        board = v1
                                        o[z][1][OBJ_X] = world[WRLD_BOARDS][board][BRD_SIZEX]
                                        set_focus = TRUE
                                    end if
                                end if
                            end if
                            if set_focus != TRUE then
                                o[z][1][OBJ_X] = 1
                            end if
                        end if

                        -- is the object out of bounds to the south?
                        if o[z][1][OBJ_X] > world[WRLD_BOARDS][board][BRD_SIZEX] and o[z][1][OBJ_COLLIDE] then
                            set_focus = -2
                            -- the exit board
                            v1 = world[WRLD_BOARDS][board][BRD_EXITS]
                            -- if the board has an exit, and the current object has focus
                            if v1 != BRD_NO_EXIT
                            and focus_object = z then
                                -- check to see if the coordinate is out of bounds on the
                                -- next board. if so then we can't move.
                                if o[z][1][OBJ_Y] <= world[WRLD_BOARDS][v1][BRD_SIZEY] then
                                    -- okay, now check to see if we're blocked.
                                    v2 = eget(v1, 1, o[z][1][OBJ_Y], o[z][1][OBJ_LAYER], BRD_TILECHAR)
                                    if v2 = 0 then  -- we are go
                                        board = v1
                                        o[z][1][OBJ_X] = 1
                                        set_focus = TRUE
                                    end if
                                end if
                            end if
                            if set_focus != TRUE then
                                o[z][1][OBJ_X] = world[WRLD_BOARDS][board][BRD_SIZEX]
                            end if
                        end if

                        -- is the object out of bounds to the east?
                        if o[z][1][OBJ_Y] > world[WRLD_BOARDS][board][BRD_SIZEY] and o[z][1][OBJ_COLLIDE] then
                            set_focus = -2
                            -- the exit board
                            v1 = world[WRLD_BOARDS][board][BRD_EXITE]
                            -- if the board has an exit, and the current object has focus
                            if v1 != BRD_NO_EXIT
                            and focus_object = z then
                                -- check to see if the coordinate is out of bounds on the
                                -- next board. if so then we can't move.
                                if o[z][1][OBJ_X] <= world[WRLD_BOARDS][v1][BRD_SIZEX] then
                                    -- okay, now check to see if we're blocked.
                                    v2 = eget(v1, o[z][1][OBJ_X], 1, o[z][1][OBJ_LAYER], BRD_TILECHAR)
                                    if v2 = 0 then  -- we are go
                                        board = v1
                                        o[z][1][OBJ_Y] = 1
                                        set_focus = TRUE
                                    end if
                                end if
                            end if
                            if set_focus != TRUE then
                                o[z][1][OBJ_Y] = world[WRLD_BOARDS][board][BRD_SIZEY]
                            end if
                        end if

                        -- is the object out of bounds to the west?
                        if o[z][1][OBJ_Y] < 1 and o[z][1][OBJ_COLLIDE] then
                            set_focus = -2
                            -- the exit board
                            v1 = world[WRLD_BOARDS][board][BRD_EXITW]
                            -- if the board has an exit, and the current object has focus
                            if v1 != BRD_NO_EXIT
                            and focus_object = z then
                                -- check to see if the coordinate is out of bounds on the
                                -- next board. if so then we can't move.
                                if o[z][1][OBJ_Y] <= world[WRLD_BOARDS][v1][BRD_SIZEY] then
                                    -- okay, now check to see if we're blocked.
                                    v2 = eget(v1, o[z][1][OBJ_X], world[WRLD_BOARDS][v1][BRD_SIZEY], o[z][1][OBJ_LAYER], BRD_TILECHAR)
                                    if v2 = 0 then  -- we are go
                                        board = v1
                                        o[z][1][OBJ_Y] = world[WRLD_BOARDS][board][BRD_SIZEY]
                                        set_focus = TRUE
                                    end if
                                end if
                            end if
                            if set_focus != TRUE then
                                o[z][1][OBJ_Y] = 1
                            end if
                            
                        end if
                        
                        
                        if set_focus = -2 then
                            -- try to find the thud label in the target
                            v1 = ge_find_label(o[z], CMD_LABEL, "thud", TRUE)
                            if v1 != 0 then
                                o[z][1][OBJ_POS] = v1 - 1
                                o[z][1][OBJ_RUNSTATE] = 0
                            end if
                            o[z][1][OBJ_WALKDIR] = 0
                            set_focus = FALSE 
                        end if
                        
                        if set_focus = TRUE then
                        
                            if length(save_line)
                            and save_point > 1 then
                                o[z][save_point] = save_line
                            end if

                            if increment then
                                o[z][1][OBJ_POS] = o[z][1][OBJ_POS] + 1
                                if o[z][1][OBJ_POS] >= (length(o[z])) then
                                    o[z][1][OBJ_POS] = OBJ_HALTED
                                end if
                            end if
                            
                            v3 = new_object(board)
                            world[WRLD_BOARDS][board][BRD_OBJECTS][v3] = o[z]
                            o = ge_delete_object(o, z)
                            focus_object = v3
                            
                            exit
                            
                        end if
                        
                        
                        -- is the object hitting a wall?
                        if o[z][1][OBJ_COLLIDE] and board = old_board then
                            if o[z][1][OBJ_X] != -1 then
                                if eget(board, o[z][1][OBJ_X], o[z][1][OBJ_Y], o[z][1][OBJ_LAYER], BRD_TILECHAR) != 0 then
                                    -- reset it
                                    o[z][1][OBJ_X] = old_locs[z][1]
                                    o[z][1][OBJ_Y] = old_locs[z][2]
                                    -- try to find the thud label in the target
                                    v1 = ge_find_label(o[z], CMD_LABEL, "thud", TRUE)
                                    if v1 != 0 then
                                        o[z][1][OBJ_POS] = v1 - 1
                                        o[z][1][OBJ_RUNSTATE] = 0
                                    end if
                                    o[z][1][OBJ_WALKDIR] = 0
                                end if
                            end if
                        end if


                    if length(save_line) then
                        o[z][save_point] = save_line
                    end if

                    if increment then
                        o[z][1][OBJ_POS] = o[z][1][OBJ_POS] + 1
                        if o[z][1][OBJ_POS] >= (length(o[z])) then
                            o[z][1][OBJ_POS] = OBJ_HALTED
                        end if
                    end if

                    if o[z][1][OBJ_RUNSTATE] != 0
                    or o[z][1][OBJ_POS] = OBJ_HALTED
                    or set_to_die != 0 then
                        if length(scroll_accums[z]) != 0 then
                            v1 = 0
                            for a = 1 to length(scroll_accums[z]) do
                                if length(scroll_accums[z][a]) > 1 then
                                    v1 = 1
                                end if
                            end for
                            if v1 = 1 then
                                if length(scroll_accums[z][1]) = 0 then
                                    scroll_accums[z] = scroll_accums[z][2..length(scroll_accums[z])]
                                end if
                                if length(scroll_accums[z]) = 1 then
                                    new_message({scroll_accums[z][1],
                                        message_color,
                                        message_time + time(),
                                        message_x,
                                        message_y}, board, o, offsets, visible_layers, viewport, layer_table)
                                else
                                    v1 = o[z][1][OBJ_NAME]
                                    if length(v1) = 0 then
                                        v1 = "Interaction"
                                    end if
                                    v1 = do_scroll(v1, scroll_accums[z], 1)
                                    clear_keys()
                                    v2 = ge_find_label(o[z], CMD_LABEL, v1, TRUE)
                                    if v2 != 0 then
                                        next_statement[z] = {16384, v2}
                                    end if
                                end if
                            end if
                            scroll_accums[z] = {}
                        end if
                    end if
                    
                    if set_to_die != 0 then
                    
                        if focus_object = set_to_die then
                            focus_object = -1
                        end if
                        if focus_object > set_to_die then
                            focus_object -= 1
                        end if
                        
                        die_coords = append(die_coords, {o[set_to_die][1][OBJ_X], o[set_to_die][1][OBJ_Y]})
                        o = ge_delete_object(o, set_to_die)
                        next_statement = cutout(next_statement, set_to_die)
                        scroll_accums = cutout(scroll_accums, set_to_die)
                        old_locs = cutout(old_locs, set_to_die)
                        set_to_die = 0
                        layer_table = make_layer_table(o, world[WRLD_BOARDS][board][BRD_LAYERS])
                        z = z - 1

                    end if
                    
                end if
                
                if walk_flag then
                    o[z][1][OBJ_POS] = OBJ_HALTED
                    walk_flag = FALSE
                end if

            end if
            
            z = z + 1

        end while
        
        -- the board is being switched if so:
        if board != old_board then  -- yes
        
            clear_keys()

            if set_focus = FALSE then
                world[WRLD_BOARDS][old_board][BRD_FOCUSOBJ] = focus_object
            else
                world[WRLD_BOARDS][old_board][BRD_FOCUSOBJ] = -1
            end if
            
            world[WRLD_BOARDS][old_board][BRD_OBJECTS] = o
            
            -- copy the objects to a work variable
            o = world[WRLD_BOARDS][board][BRD_OBJECTS]
            world[WRLD_BOARDS][board][BRD_OBJECTS] = {}
            
            -- does the board have any objects?
            if length(o) < 1 then
                -- no, can't continue
                msg("No objects - nonexecutable", "Can't execute, destination board has no objects.")
                return
            end if

            offsets = {0, 0}        -- set scroll position to top
            offset_auto = 0
            -- all layers on
            visible_layers = repeat(ON, world[WRLD_BOARDS][board][BRD_LAYERS])
            -- default viewport
            viewport = {1, 1, screen_sizex, screen_sizey}

            -- clear messages            
            messages = {}

            fade_out(5 * (config[FAST_FADES] + 1))
            bk_color(0)
            clear_screen()
            fade_out_end()

            sidebar_clear()         -- clear the sidebar,
            sidebar_ge_draw_base()  -- draw the game engine base,
            sidebar_ge_draw_stats() -- and draw any stats
            
            layer_table = make_layer_table(o, world[WRLD_BOARDS][board][BRD_LAYERS])

            apply_board_settings(board) -- set charset and palette
            draw_ge_board(board, offsets, visible_layers, viewport)   -- draw the board,
            draw_ge_objects(o, board, offsets, visible_layers, viewport, layer_table)  -- and the objects
            
            unpause_sound()

            next_statement = repeat({}, length(o))
            scroll_accums = repeat({{}}, length(o))
            
            if set_focus = FALSE then
                if world[WRLD_BOARDS][board][BRD_FOCUSOBJ] > 0 then
                    focus_object = world[WRLD_BOARDS][board][BRD_FOCUSOBJ]
                else
                    focus_object = -1
                end if
            end if
            
            -- try to find the :enter label
            for zz = 1 to length(o) do
                v1 = ge_find_label(o[zz], CMD_LABEL, "enter", TRUE)
                if v1 != 0 then
                    o[zz][1][OBJ_POS] = v1 - 1
                    o[zz][1][OBJ_RUNSTATE] = 0
                end if
            end for
                        
        else

            --ss = screen_save()
            --set_active_page(1)
            --screen_restore(ss)

            -- crosscheck for collisions.
            -- "why do it this way? it seems like it would slow it down."
            -- actually, checking all of the objects at the end of a cycle,
            -- rather than checking them individually after each cycle,
            -- is the same speed if not quicker. and this way, we can have
            -- seamless object movement (which = cool).
            -- of course, doing this slows down things like the 1090 object
            -- demo. oh well.
            
            -- the while-cycle and buffer stuff has been removed and is
            -- in oldcode.dat

            -- go through all the objects
            for zz = 1 to length(o) do
                if o[zz][1][OBJ_X] != old_locs[zz][1]
                or o[zz][1][OBJ_Y] != old_locs[zz][2]
                or o[zz][1][OBJ_LAYER] != old_locs[zz][3] then
                    o = check_object(o, old_locs, zz, focus_object)
                end if
            end for
            
            
            -- automatically set the offset if on
            if offset_auto > 0 then
                for zz = 1 to length(o) do
                    if offset_auto = zz then
                        if o[zz][1][OBJ_X] != old_locs[zz][1]
                            or o[zz][1][OBJ_Y] != old_locs[zz][2] then
                            v3 = offsets
                            v1 = viewport[1] + floor((viewport[3] - viewport[1]) / 2)
                            v2 = viewport[2] + floor((viewport[4] - viewport[2]) / 2)
                            offsets = {o[zz][1][OBJ_X] - v1, o[zz][1][OBJ_Y] - v2}
                            if offsets[1] != v3[1]
                            or offsets[2] != v3[2] then
                                board_redraw = TRUE
                            end if
                        end if
                    end if
                end for
            end if
            
            if sb_redraw then
                sidebar_clear()         -- clear the sidebar,
                sidebar_ge_draw_base()  -- draw the game engine base,
                sidebar_ge_draw_stats() -- and draw any stats
            end if
            
            if board_redraw = FALSE then
                for zz = 1 to length(die_coords) do
                    if die_coords[zz][1] > 0
                    and die_coords[zz][2] > 0 then
                        draw_ge_board_tile(board, o, die_coords[zz][1], die_coords[zz][2], offsets, visible_layers, viewport, layer_table)
                    end if
                end for
                
                for zz = 1 to length(old_locs) do
                    if length(old_locs[zz]) > 0 then
                        if compare(old_locs[zz], {o[zz][1][OBJ_X], o[zz][1][OBJ_Y], o[zz][1][OBJ_LAYER]}) != 0 then
                            if old_locs[zz][1] > 0 and old_locs[zz][2] > 0 then
                                draw_ge_board_tile(board, o, old_locs[zz][1], old_locs[zz][2], offsets, visible_layers, viewport, layer_table)
                                --draw_ge_object(zz, o, board, offsets, visible_layers, viewport)
                            end if
                            draw_ge_board_tile(board, o, o[zz][1][OBJ_X], o[zz][1][OBJ_Y], offsets, visible_layers, viewport, layer_table)
                        end if
                    end if
                end for
            else
                draw_ge_board(board, offsets, visible_layers, viewport)
                draw_ge_objects(o, board, offsets, visible_layers, viewport, layer_table)
            end if

            --ss = screen_save()
            --set_active_page(0)
            --screen_restore(ss)

        end if

    end while
    
    if high_mode then
        v1 = text_rows(25)
        screen_sizex = 25
        font_squish = FALSE
        allow_all_paledit()
        blink(0)
        high_mode = FALSE
    end if

end procedure


function quit_msg()

    atom a
    
    a = rand(13)

    if a = 1 then
        return("Not leaving now, are you?")
    elsif a = 2 then
        return("Going so soon?")
    elsif a = 3 then
        return("Really?")
    elsif a = 4 then
        return("Are you totally sure?")
    elsif a = 5 then
        return("Don't leave yet!")
    elsif a = 6 then
        return("Hey, it's not cool to quit!")
    elsif a = 7 then
        return("Winners never quit and quitters never win! :P")
    elsif a = 8 then
        return("Exit to that boring OS?")
    elsif a = 9 then
        return("Bye!")
    elsif a = 10 then
        return("Totally sure?")
    elsif a = 11 then
        return("Leave?")
    elsif a = 12 then
        return("Do you have a good reason to leave?")
    elsif a = 13 then
        return("Why leave now?")
    elsif a = 14 then
        return("Exit?")
    elsif a = 15 then
        return("Quit?")
    end if

end function


procedure do_main()

    atom act, run_mode
    object u1, u2, u3

    run_mode = RUNNING
    sidebar = ON

    while run_mode = RUNNING do
        act = handle_main_screen()

        if act = 1 then
            u1 = select_file("*.zig", "World Load")
            if length(u1) > 1 then
                u2 = u1
                u1 = open(u1, "rb")

                if u1 != -1 then

                    clear_world()
                    u3 = load_world(u1, u2)
                    world[WRLD_FILENAME] = fproc(u2)
                    if u3 then
                        u2 = screen_save()
                        bk_color(4)
                        clear_screen()
                        printf(1, "Load error %d!", u3)
                        u3 = wait_key()
                        screen_restore(u2)
                    end if

                    close(u1)

                    draw_board_title()

                end if
            end if
        elsif act = 2 then
            store_world()
            setup_world()
            play_world()
            reset_world()
        elsif act = 3 then
            msg("Sorry...", "Not yet implemented.")
        elsif act = 4 then
            do_editor()
        elsif act = 5 then
            u1 = do_scroll("About ZIG",
                            {"$- - - -",
                             "$`EZIG",
                             "$- - - -",{},
                             "$Version " & VERSION,
                             "$Copyright " & COPYRIGHT & ", Jacob Hammond.",
                             "$Freeware under the GNU General Public License",
                             "$Released under Interactive Fantasies",{},{},
                             "ZIG has been and is a work in progress; it",
                             "was begun in March of 1998. It was inspired",
                             "by Epic [Mega]Games' classic game ZZT, thus",
                             "the name ZZT-Inspired Game Creation System.",
                             "ZIG is not a clone of ZZT, more of a",
                             "remake of sorts.",{},
                             "$Webpage",
                             "$http://surf.to/zig",
                             "$or",
                             "$http://lightning.prohosting.com/~zig/",{},
                             "$E-mail",
                             "$zig16@hotmail.com",{},
                             "$For license information, read gnugpl.txt",
                             "$which is included with ZIG.",{}
                             }, 5)

        elsif act = 6 then
            do_help({})
        elsif act = 7 then
            if confirm("Quit? [y/n]", quit_msg()) then
                run_mode = STOP
            end if
        elsif act = 8 then
            configure()
        end if
    end while

    fade_out(5 * (config[FAST_FADES] + 1))
    clear_screen()
    fade_out_end()

    cleanup_and_exit(0)

end procedure


procedure interpret_errorcode(atom errorcode)

    atom mmm
    sequence c

    if errorcode then

        text_color(15)
        puts(1, "\ninit(): An error occurred while starting up.")
        printf(1, "\n\nError code %d: ", errorcode)
        text_color(7)

        if errorcode = 1 then
            puts(1, "Couldn't load default palette file (DEFAULT.ZPL).\nChances are ZIG wasn't started out of its directory. Fix that and try again.\nIf all else fails, try redownloading.\n")
        elsif errorcode = 2 then
            puts(1, "Couldn't load default character set file (DEFAULT.ZCH).\nChances are ZIG wasn't started out of its directory. Fix that and try again.\nIf all else fails, try redownloading.\n")
        elsif errorcode = 3 then
            puts(1, "Couldn't get into 80x25x16 textmode.\nThis is probably a configuration error, or else you have a really weird PC.\n")
        elsif errorcode = 4 then
            puts(1, "init_modwave had an error.\nStart ZIG with sound off, or adjust your settings.\n")
        elsif errorcode = 5 then
            c = command_line()
            printf(1, "Couldn't load world specified on commandline (%s).", {c[3]})
        elsif errorcode = 6 then
            printf(1, "Internal error of some kind - Jacob screwed up init(), contact him.", {})
        else
            puts(1, "Unspecifiable/unmapped error, please report.\n")
        end if

        puts(1, "\nExiting with errors.\n\nPress a key...")

        mmm = wait_key()

        cleanup_and_exit(errorcode)

    end if

end procedure


clear_world()
interpret_errorcode(init())
do_main()

