LUA_VERSION ?= 5.3
LUA_DIR = /usr/local
LUA_LIBDIR = $(LUA_DIR)/lib/lua/$(LUA_VERSION)
LUA_SHAREDIR = $(LUA_DIR)/share/lua/$(LUA_VERSION)
LUA_INCDIR = $(LUA_DIR)/include

CC = gcc
CFLAGS = -fPIC -Wall -Wextra -Wno-implicit-fallthrough -O3 -fwrapv
LUA_LIB = lua$(LUA_VERSION)
LIBS = $(LUA_LIB) m
LIBFLAGS = $(foreach lib,$(LIBS),-l$(lib))

CB0R_DIR = $(HOME)/Libraries/cb0r
CB0R_INCDIR = $(CB0R_DIR)/src
CB0R_SRCDIR = $(CB0R_DIR)/src

lib/cb0r.so: src/lua-cb0r.c
	mkdir -p lib
	cd src && $(CC) -shared $(CFLAGS) -I $(CB0R_INCDIR) -I src $(LIBFLAGS) $(CB0R_SRCDIR)/cb0r.c lua-cb0r.c -o ../lib/cb0r.so

install: cb0r.so
	cp lib/cb0r.so $(LUA_LIBDIR)
	cp share/cbor_iter.lua $(LUA_SHAREDIR)

clean:
	rm lib/cb0r.so