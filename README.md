# lua-cb0r
A library for Lua 5.3, written with the help of the [cb0r](https://github.com/quartzjer/cb0r) library, that just returns a function
to decode a basic CBOR value at an index in a string, and return the Lua value and one-based index after the CBOR object, all that
is necessary to implement a CBOR sequence decoder.

I created this because I was reading CBOR sequences more than 2 gigabytes long
([Wikimedia XML page dumps](https://meta.wikimedia.org/wiki/Data_dumps) converted to CBOR) and I wanted to decode it faster
than the [pure- or part-Lua libraries](https://luarocks.org/search?q=cbor) on LuaRocks can do.

It can be compiled with a GCC incantation similar to the following, once the cb0r library is downloaded and the path to its `src`
directory is put in, in place of `path/to/cb0r/src`:

    gcc -shared -fPIC -Wall -Wextra -Wno-implicit-fallthrough -O3 -fwrapv -I path/to/cb0r/src -llua5.3 -lm path/to/cb0r/src/cb0r.c lua-cb0r.c -o cb0r.so
