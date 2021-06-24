local cb0r_decode = require "cb0r"

local function decode_hex(hex)
    local s = ""
    for byte in hex:gmatch("%x%x") do
        s = s .. string.char(tonumber(byte, 16))
    end
    return s
end

local tests, successes = 0, 0

local function print_successes()
    if successes == tests then
        if tests == 1 then
            io.write("1 test was successful\n")
        else
            io.write("All ", tests, " tests were successful\n")
        end
    else
        io.write(successes, " test", successes == 1 and "" or "s", " out of ", tests, " ", successes == 1 and "was" or "were", " successful\n")
    end
end

local function assert(bool, ...)
    if not bool then
        io.stderr:write(...)
    else
        successes = successes + 1
    end
    tests = tests + 1
end

local function test_number(hex, expected)
    local float_val = cb0r_decode(decode_hex(hex))
    assert(float_val == expected)
    if math.type then
        assert(math.type(float_val) == math.type(expected))
    end
end

local function test_string(cbor, expected)
    local string_val = cb0r_decode(cbor)
    assert(string_val == expected)
end

-- unsigned integers

test_number("01", 1)
test_number("18 01", 1)
test_number("19 0001", 1)
test_number("1A 00000001", 1)
test_number("1b 0000000000000001", 1)

-- utf-8

local hello = "Hello, world!"
test_string(string.char(0x60 + #hello) .. hello, hello)
test_string("\x78" .. string.char(#hello) .. hello, hello)
test_string("\x79\0" .. string.char(#hello) .. hello, hello)
test_string("\x7A" .. ("\0"):rep(3) .. string.char(#hello) .. hello, hello)

-- cb0r doesn't handle strings with 8-byte lengths.
-- test_string("\x7B" .. ("\0"):rep(7) .. string.char(#hello) .. hello, hello)

-- floats

test_number("F9 3C00", 1.0)
test_number("FA 3F800000", 1.0)
test_number("FB 3FF0000000000000", 1.0)

print_successes()
