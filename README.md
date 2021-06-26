# hxlua

[![Build](https://github.com/Apprentice-Alchemist/hxlua/actions/workflows/main.yml/badge.svg)](https://github.com/Apprentice-Alchemist/hxlua/actions/workflows/main.yml)

Haxe bindings for luaJIT

## Setup
```bash
$ cd path/to/hxlua
$ cd LuaJIT && make && sudo make install # Posix systems
$ cd LuaJIT/src && msvcbuild.bat # Windows, run in an MSVC Command Prompt
$ cd ..
# Regenerate the C side of the hashlink bindings
$ haxe -lib hxlua Lua -D hl_gen -hl out.hl --no-output
# Build the hashlink binary.
$ cd native
# On windows, assumes you have installed hashlink in %HASHLINK%.
# On posix, assumes you have installed hashlink in the default path
# If not, pass -DHASHLINK_BIN=... and -DHASHLINK_INCLUDE=...
# If you intend to use this binary with lime on windows, you'll need to pass
# -DHXCPP_M32 -DHASHLINK_BIN=path/to/lime/templates/bin/hl/windows -DHASHLINK_INCLUDE=path/to/lime/project/include
# And then manually copy lua.hdll to export/hl/bin in your project.
# This may or may not work, I haven't tested it.
$ haxelib run hxcpp Build.xml
$ cp lua.hdll /usr/local/lib # Posix systems
$ copy lua.hdll /path/to/somewhere/in/your/PATH # Windows
```

## Contributing
If you find a bug or want to add a feature, pull requests are always welcome.