#include <assert.h>

#include "endianness.h"
#include "half_precision_float.h"

#include "lua5.3/lua.h"
#include "lua5.3/lauxlib.h"

#include "cb0r.h"

#define BYTESWAP(val) _Generic((val), uint32_t: ntoh32(val), uint64_t: ntoh64(val))

#define PUSH_INT_AS_FLOAT(L, cbor_val, int_type, float_type)      \
	{                                                             \
		assert(sizeof(float_type) == sizeof(int_type));           \
		union                                                     \
		{                                                         \
			uint8_t u8[sizeof(float_type)];                       \
			int_type int_val;                                     \
		} data;                                                   \
		assert(cbor_val.length == sizeof data.u8);                \
		memcpy(&data.u8, cb0r_value(&cbor_val), cbor_val.length); \
		/* Reverse byte order if necessary. */                    \
		int_type int_val = BYTESWAP(data.int_val);                \
		float_type f;                                             \
		memcpy(&f, &int_val, sizeof f);                           \
		lua_pushnumber(L, (lua_Number)f);                         \
	}

static const uint8_t * lua_push_cb0r(
	lua_State * L,
	const uint8_t * start,
	const uint8_t * end
) {
	cb0r_s val;
	cb0r((uint8_t *) start, (uint8_t *) end, 0, &val);
	if (start + val.header > end) {
		return luaL_error(L, "not enough bytes for header"), NULL;
	}
	if (val.end > end) {
		return luaL_error(L, "not enough bytes after header"), NULL;
	}
	const uint8_t * const val_end = val.end;
	switch (val.type) {
		case CB0R_INT:
			// TODO: Check for overflow in case of lua_Integer smaller than uint64_t.
			lua_pushinteger(L, (lua_Integer) val.value);
			break;
		case CB0R_NEG: {
			// Assume wrapping on overflow: -fwrapv flag in GCC
			int64_t neg_val = (int64_t) -1 - (int64_t) val.value;
			if (neg_val > 0)
				return luaL_error(L, "overflow in negative number"), NULL;
			lua_pushinteger(L, neg_val);
			break;
		}
		case CB0R_BYTE: case CB0R_UTF8:
			if (cb0r_value(&val) + cb0r_vlen(&val) > end)
				return luaL_error(L, "string length greater than length of CBOR"), NULL;
			lua_pushlstring(L, (const char *) cb0r_value(&val), cb0r_vlen(&val));
			break;
		case CB0R_ARRAY: {
			lua_createtable(L, val.length, 0);
			const uint8_t * item_start = cb0r_value(&val);
			for (uint64_t i = 0; i < val.length; ++i) {
				item_start = lua_push_cb0r(L, item_start, val_end);
				lua_rawseti(L, -2, (lua_Integer) i + 1);
			}
			break;
		}
		case CB0R_MAP: {
			lua_createtable(L, 0, val.length);
			const uint8_t * key_value_start = cb0r_value(&val);
			for (uint64_t i = 0; i < val.length; i += 2) {
				key_value_start = lua_push_cb0r(L, key_value_start, val_end);
				key_value_start = lua_push_cb0r(L, key_value_start, val_end);
				lua_settable(L, -3);
			}
			break;
		}
		case CB0R_TAG: case CB0R_SIMPLE: case CB0R_TAGS: case CB0R_DATETIME:
		case CB0R_EPOCH: case CB0R_BIGNUM: case CB0R_BIGNEG:
		case CB0R_FRACTION: case CB0R_BIGFLOAT: case CB0R_BASE64URL:
		case CB0R_BASE64: case CB0R_HEX: case CB0R_DATA:
		case CB0R_SIMPLES: return luaL_error(L, "unhandleable type"), NULL;
		case CB0R_FALSE: case CB0R_TRUE:
			lua_pushboolean(L, val.type == CB0R_TRUE); break;
		case CB0R_NULL:
			lua_pushnil(L); break;
		case CB0R_UNDEF: return luaL_error(L, "unhandleable type"), NULL;
		case CB0R_FLOAT: {
			switch (val.length) {
				case 2: {
					double half_float_val = decode_half(cb0r_value(&val));
					lua_pushnumber(L, (lua_Number)half_float_val);
					break;
				}
				case 4:
					PUSH_INT_AS_FLOAT(L, val, uint32_t, float);
					break;
				case 8:
					PUSH_INT_AS_FLOAT(L, val, uint64_t, double);
					break;
			}
			break;
		}
		case CB0R_ERR: return luaL_error(L, "unknown CBOR error"), NULL;
		case CB0R_EPARSE: return luaL_error(L, "invalid CBOR structure"), NULL;
		case CB0R_EBAD: return luaL_error(L, "invalid type byte"), NULL;
		case CB0R_EBIG: return luaL_error(L, "unsupported size"), NULL;
		case CB0R_EMAX: default: return luaL_error(L, "unknown error"), NULL;
	}
	return val_end;
}

static int lua_cb0r_decode(lua_State * L) {
	size_t len;
	const char * const cbor = luaL_checklstring(L, 1, &len);
	// Convert one-based indexing to zero-based indexing.
	lua_Integer offset = luaL_optinteger(L, 2, 1) - 1;
	if (!(0 <= offset && offset < (lua_Integer) len)) {
		return luaL_error(L, "empty string or offset out of range");
	}
	const char * const cbor_val_end = (const char *) lua_push_cb0r(
		L,
		(const uint8_t *) cbor + offset,
		(const uint8_t *) cbor + len
	);
	// Convert zero-based indexing to one-based indexing.
	lua_pushinteger(L, cbor_val_end - cbor + 1);
	return 2;
}

int luaopen_cb0r(lua_State * L) {
	lua_pushcfunction(L, &lua_cb0r_decode);
	return 1;
}
