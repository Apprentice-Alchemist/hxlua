import Lua;
class Main {
static function main() {
	Sys.println("Hello World!");
	var vm:State = Lua.newstate();
	Sys.println("VM Created");
	Lua.openlibs(vm);
	Sys.println("libs opened");
	Lua.dofile(vm, "script.lua");
	Sys.println("file loaded");
	Lua.getglobal(vm, "foo");
	Lua.pushinteger(vm, 1);
	Lua.pushnumber(vm, 2.0);
	Lua.pushstring(vm, "three");
	Lua.pcall(vm, 3, 0, 1);
	trace("closing vm");
	Lua.close(vm);
	Sys.println("vm closed");
}
}