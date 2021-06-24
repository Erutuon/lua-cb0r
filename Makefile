LUA_VERSION ?= 5.3
LUA_DIR = /usr/local
LUA_LIBDIR = $(LUA_DIR)/lib/lua/$(LUA_VERSION)
LUA_SHAREDIR = $(LUA_DIR)/share/lua/$(LUA_VERSION)
LUA_INCDIR = $(LUA_DIR)/include

CC = gcc

CFLAGS = -fPIC -Wall -Wextra -Wno-implicit-fallthrough -fwrapv
ifdef debug
	CFLAGS += -O1 -g
else
	CFLAGS += -O3
endif

LUA_LIB = lua$(LUA_VERSION)
LIBS = $(LUA_LIB) m
LIBFLAGS = $(foreach lib,$(LIBS),-l$(lib))

CB0R_DIR = cb0r
CB0R_INCDIR = $(CB0R_DIR)/src
CB0R_SRCDIR = $(CB0R_DIR)/src

LIB_OUTDIR = lib
CB0R_SO = $(LIB_OUTDIR)/cb0r.so

$(CB0R_SO): src/lua-cb0r.c
	mkdir -p $(LIB_OUTDIR)
	$(CC) -shared $(CFLAGS) -I $(CB0R_INCDIR) -I src $(LIBFLAGS) $(CB0R_SRCDIR)/cb0r.c src/lua-cb0r.c -o $(CB0R_SO)

install: $(CB0R_SO)
	cp $(CB0R_SO) $(LUA_LIBDIR)
	cp share/cbor_iter.lua $(LUA_SHAREDIR)

clean:
	rm -f $(CB0R_SO)

test: $(CB0R_SO)
	lua -e 'package.cpath = "$(LIB_OUTDIR)/?.so"' test/test.lua
