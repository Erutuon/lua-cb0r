package = "lua-cb0r"
version = "0.1.0-1"
source = {
   url = "git+https://github.com/Erutuon/lua-cb0r.git",
   tag = "v0.1.0"
}
description = {
   summary = "Quickly deserializes basic CBOR types into Lua types using the cb0r library",
   homepage = "https://github.com/Erutuon/lua-cb0r",
   license = "MIT",
   maintainer = "Erutuon <5840197+Erutuon@users.noreply.github.com>"
}
supported_platforms = {
   "unix"
}
dependencies = {
   "lua >= 5.1, <= 5.4"
}
build = {
   type = "builtin",
   modules = {
      cb0r = {
         sources = { "src/lua-cb0r.c", "cb0r/src/cb0r.c" },
         incdirs = { "cb0r/src" }
      }
   },
   install = {
      lua = {
         ["cbor_iter"] = "cbor_iter.lua",
      }
   }
}
