package;

private abstract IntBool(Int) from Int to Int {
	@:to function toBool():Bool {
		return this != 0;
	}

	@:from static function fromBool(b:Bool):IntBool {
		return b ? 1 : 0;
	}
}

#if hl
abstract State(hl.Abstract<"lua_State">) {}

private abstract CString(hl.Bytes) from hl.Bytes to hl.Bytes {
	@:from static inline function fromString(s:String) {
		return @:privateAccess s.toUTF8();
	}

	@:to inline function toString():String {
		return @:privateAccess String.fromUTF8(this);
	}
}

private typedef Ref<T> = hl.Ref<T>;
private typedef Bytes = hl.Bytes;
private typedef LuaNumber = Float;
private typedef LuaInteger = Int;
#elseif cpp
@:include("lua.hpp")
@:native("lua_State *")
extern class State {}

private abstract CString(cpp.ConstCharStar) from cpp.ConstCharStar to cpp.ConstCharStar {
	@:from static inline function fromString(s:String):CString {
		return (s : cpp.ConstCharStar);
	}

	@:to inline function toString():String {
		return (this : String);
	}
}

private typedef Ref<T> = cpp.Star<T>;

private abstract Bytes(cpp.Star<Void>) {
	@:from static function fromBytes(b:haxe.io.Bytes) {
		return cast @:privateAccess b.b;
	}
}

private typedef LuaNumber = Float;
private typedef LuaInteger = cpp.Int64;
#end
private typedef Reader = cpp.Callable<(state:State, size:Ref<Int>) -> Bytes>;
private typedef Writer = cpp.Callable<(state:State, data:Bytes, size:Int) -> Int>;
typedef LuaCFunction = cpp.Callable<State->Int>;

enum abstract LuaType(Int) {
	var LUA_TNONE = -1;
	var LUA_TNIL = 0;
	var LUA_TBOOLEAN = 1;
	var LUA_TLIGHTUSERDATA = 2;
	var LUA_TNUMBER = 3;
	var LUA_TSTRING = 4;
	var LUA_TTABLE = 5;
	var LUA_TFUNCTION = 6;
	var LUA_TUSERDATA = 7;
	var LUA_TTHREAD = 8;
}

enum abstract ThreadStatus(Int) {
	var LUA_SOMETHING = -1;
	var LUA_OK;
	var LUA_YIELD;
	var LUA_ERRRUN;
	var LUA_ERRSYNTAX;
	var LUA_ERRMEM;
	var LUA_ERRERR;
}

enum abstract GcOptions(Int) {
	var LUA_GCSTOP = 0;
	var LUA_GCRESTART = 1;
	var LUA_GCCOLLECT = 2;
	var LUA_GCCOUNT = 3;
	var LUA_GCCOUNTB = 4;
	var LUA_GCSTEP = 5;
	var LUA_GCSETPAUSE = 6;
	var LUA_GCSETSTEPMUL = 7;
	var LUA_GCISRUNNING = 9;
}

#if hl
@:hlNative("lua")
#elseif cpp
@:include("lua.hpp")
@:buildXml("
<copyFile name='lua51.dll' from='${haxelib:hxlua}/lib/${BINDIR}' overwrite='true' toolId='exe' if='windows'>
<copyFile name='libluajit-5.1.so' from='${haxelib:hxlua}/lib/${BINDIR}' overwrite='true' toolId='exe' if='linux'>
<copyFile name='libluajit-5.1.dylib' from='${haxelib:hxlua}/lib/${BINDIR}' overwrite='true' toolId='exe' if='mac'>
<files id='haxe'>
            <compilerflag value='-I${haxelib:hxlua}/LuaJIT/src'/>
        </files>
		<target id='haxe'>
			<libpath name='${haxelib:hxlua}/lib/${BINDIR}'/>
            <lib base='lua51' if='windows'/>
			<lib base='luajit-5.1' unless='windows'/>
			<vflag name='-Wl,-rpath=$ORIGIN' value='' unless='windows'/>
		</target>
")
#end
extern class Lua {
	static inline var MINSTACK = 20;
	static inline var MULTRET = -1;
	static inline var REGISTRYINDEX = -10000;
	static inline var ENVIRONINDEX = -10001;
	static inline var GLOBALSINDEX = -10002;
	static inline function upvalueindex(i:Int):Int {
		return GLOBALSINDEX - i;
	}
	@:native("luaL_newstate")
	static function newstate():State;
	@:native("lua_close")
	static function close(L:State):Void;
	@:native("lua_newthread")
	static function newthread(L:State):State;
	@:native("lua_atpanic")
	static function atpanic(L:State, panicf:LuaCFunction):LuaCFunction;
	@:native("lua_gettop")
	static function gettop(L:State):Int;
	@:native("lua_settop")
	static function settop(L:State, idx:Int):Void;
	@:native("lua_pushvalue")
	static function pushvalue(L:State, idx:Int):Void;
	@:native("lua_remove")
	static function remove(L:State, idx:Int):Void;
	@:native("lua_insert")
	static function insert(l:State, idx:Int):Void;
	@:native("lua_replace")
	static function replace(L:State, idx:Int):Void;
	@:native("lua_checkstack")
	static function checkstack(L:State, sz:Int):Int;
	@:native("lua_xmove")
	static function xmove(from:State, to:State, n:Int):Void;
	@:native("lua_isnumber")
	static function isnumber(L:State, idx:Int):IntBool;
	@:native("lua_isstring")
	static function isstring(L:State, idx:Int):IntBool;
	@:native("lua_iscfunction")
	static function iscfunction(L:State, idx:Int):IntBool;
	@:native("lua_isuserdata")
	static function isuserdata(L:State, idx:Int):IntBool;
	@:native("lua_type")
	static function type(L:State, idx:Int):LuaType;
	@:native("lua_typename")
	static function typename(L:State, tp:Int):CString;
	@:native("lua_equal")
	static function equal(L:State, idx1:Int, idx2:Int):IntBool;
	@:native("lua_rawequal")
	static function rawequal(L:State, idx1:Int, idx2:Int):IntBool;
	@:native("lua_lessthan")
	static function lessthan(L:State, idx1:Int, idx2:Int):IntBool;
	@:native("lua_tonumber")
	static function tonumber(L:State, idx:Int):LuaNumber;
	@:native("lua_tointeger")
	static function tointeger(L:State, idx:Int):LuaInteger;
	@:native("lua_toboolean")
	static function toboolean(L:State, idx:Int):IntBool;
	@:native("lua_tolstring")
	static function tolstring(L:State, idx:Int, len:Ref<#if cpp cpp.SizeT #elseif hl Int #end>):CString;
	@:native("lua_objlen")
	static function objlen(L:State, idx:Int):#if cpp cpp.SizeT #else Int #end;
	@:native("lua_tocfunction")
	static function tocfunction(L:State, idx:Int):LuaCFunction;
	@:native("lua_touserdata")
	static function touserdata<T:Dynamic>(L:State, idx:Int):T;
	@:native("lua_tothread")
	static function tothread(L:State, idx:Int):State;
	@:native("lua_topointer")
	static function topointer<T:Dynamic>(L:State, idx:Int):T;
	@:native("lua_pushnil")
	static function pushnil(L:State):Void;
	@:native("lua_pushnumber")
	static function pushnumber(L:State, n:LuaNumber):Void;
	@:native("lua_pushinteger")
	static function pushinteger(L:State, n:LuaInteger):Void;
	@:native("lua_pushlstring")
	static function pushlstring(L:State, s:Bytes, len:#if cpp cpp.SizeT #else Int #end):Void;
	@:native("lua_pushstring")
	static function pushstring(L:State, s:CString):Void;
	@:native("lua_pushcclosure")
	static function pushcclosure(L:State, fn:LuaCFunction, n:Int):Void;
	@:native("lua_pushlightuserdata")
	static function pushlightuserdata<T:Dynamic>(L:State, p:T):Void;
	@:native("lua_pushthread")
	static function pushthread(L:State):Int;
	@:native("lua_gettable")
	static function gettable(L:State, idx:Int):Void;
	@:native("lua_getfield")
	static function getfield(L:State, idx:Int, name:CString):Void;
	@:native("lua_rawget")
	static function rawget(L:State, idx:Int):Void;
	@:native("lua_rawgeti")
	static function rawgeti(L:State, idx:Int, n:Int):Void;
	@:native("lua_createtable")
	static function createtable(L:State, narr:Int, nrec:Int):Void;
	@:native("lua_newuserdata")
	static function newuserdata<T:Dynamic>(L:State, sz:#if cpp cpp.SizeT #else Int #end):T;
	@:native("lua_getmetatable")
	static function getmetatable(L:State, objindex:Int):Int;
	@:native("lua_getfenv")
	static function getfenv(L:State, idx:Int):Void;
	@:native("lua_settable")
	static function settable(L:State, idx:Int):Void;
	@:native("lua_setfield")
	static function setfield(L:State, idx:Int, k:CString):Void;
	@:native("lua_rawset")
	static function rawset(L:State, idx:Int):Void;
	@:native("lua_rawseti")
	static function rawseti(L:State, idx:Int, n:Int):Void;
	@:native("lua_setmetatable")
	static function setmetatable(L:State, objindex:Int):Void;
	@:native("lua_setfenv")
	static function setfenv(L:State, idx:Int):Int;

	@:native("lua_call")
	static function call(L:State, nargs:Int, nresults:Int):Void;
	@:native("lua_pcall")
	static function pcall(L:State, nargs:Int, nresults:Int, errfunc:Int):Int;
	@:native("lua_cpcall")
	static function cpcall<T:Dynamic>(L:State, func:LuaCFunction, ud:T):Int;
	@:native("lua_load")
	static function load(L:State, reader:Reader, dt:Bytes, chunkname:CString):Int;
	@:native("lua_dump")
	static function dump(L:State, writer:Writer, data:Bytes):Int;
	@:native("lua_yield")
	static function yield(L:State, nresults:Int):ThreadStatus;
	@:native("lua_resume")
	static function resume(L:State, narg:Int):ThreadStatus;
	@:native("lua_status")
	static function status(L:State):ThreadStatus;
	@:native("lua_gc")
	static function gc(L:State, what:Int, data:Int):Int;
	@:native("lua_error")
	static function error(L:State):Int;
	@:native("lua_next")
	static function next(L:State, idx:Int):Int;
	@:native("lua_concat")
	static function concat(L:State, n:Int):Void;

	static inline function pop(L:State, n:Int):Void {
		settop(L, -n - 1);
	}

	static inline function newtable(L:State):Void {
		createtable(L, 0, 0);
	}

	static inline function register(L:State, n:CString, f:LuaCFunction):Void {
		pushcfunction(L, (f));
		setglobal(L, (n));
	}

	static inline function strlen(L:State, i:Int):Int {
		return objlen(L, i);
	}
	static inline function isfunction(L:State, n:Int):Bool {
		return type(L, (n)) == LUA_TFUNCTION;
	}
	static inline function istable(L:State, n:Int):Bool {
		return type(L, (n)) == LUA_TTABLE;
	}
	static inline function islightuserdata(L:State, n:Int):Bool {
		return type(L, (n)) == LUA_TLIGHTUSERDATA;
	}
	static inline function isnil(L:State, n:Int):Bool {
		return type(L, (n)) == LUA_TNIL;
	}
	static inline function isboolean(L:State, n:Int):Bool {
		return type(L, (n)) == LUA_TBOOLEAN;
	}
	static inline function isthread(L:State, n:Int):Bool {
		return type(L, (n)) == LUA_TTHREAD;
	}
	static inline function isnone(L:State, n:Int):Bool {
		return type(L, (n)) == LUA_TNONE;
	}
	static inline function isnoneornil(L:State, n:Int):Bool {
		return (cast type(L, (n)) : Int) <= 0;
	}

	static inline function pushliteral(L:State, s:String):Void {
		pushlstring(L, haxe.io.Bytes.ofString(s), s.length);
	}

	static inline function pushcfunction(L:State, f:LuaCFunction):Void {
		pushcclosure(L, f, 0);
	}

	static inline function setglobal(L:State, s:CString):Void {
		setfield(L, GLOBALSINDEX, s);
	}

	static inline function getglobal(L:State, s:CString):Void {
		getfield(L, GLOBALSINDEX, s);
	}

	static inline function tostring(L:State, i:Int):Void {
		tolstring(L, i, null);
	}

	@:native("lua_setlevel")
	static function setlevel(from:State, to:State):Void;
	@:native("luaL_openlibs")
	static function openlibs(L:State):Void;
	@:native("luaL_loadfile")
	static function loadfile(L:State, filename:CString):Int;

	static inline function dofile(L:State,f:String):Bool {
		return loadfile(L,f) == 1 && pcall(L,0,MULTRET,0) == 1;
	}

}

@:hlNative("lua","hl_open_")
@:include("lua.hpp")
extern class LuaOpen {
	static inline var LUA_COLIBNAME = "coroutine";
	static inline var LUA_MATHLIBNAME = "math";
	static inline var LUA_STRLIBNAME = "string";
	static inline var LUA_TABLIBNAME = "table";
	static inline var LUA_IOLIBNAME = "io";
	static inline var LUA_OSLIBNAME = "os";
	static inline var LUA_LOADLIBNAME = "package";
	static inline var LUA_DBLIBNAME = "debug";
	static inline var LUA_BITLIBNAME = "bit";
	static inline var LUA_JITLIBNAME = "jit";
	static inline var LUA_FFILIBNAME = "ffi";

    @:native("luaopen_base")
    static function base(L:State):Void;

	@:native("luaopen_math")
	static function math(L:State):Void;
	@:native("luaopen_string")
	static function string(L:State):Void;
	@:native("luaopen_table")
	static function table(L:State):Void;
	@:native("luaopen_io")
	static function io(L:State):Void;
	@:native("luaopen_os")
	static function os(L:State):Void;
	@:native("luaopen_package")
	static function _package(L:State):Void;
	@:native("luaopen_debug")
	static function debug(L:State):Void;
	@:native("luaopen_bit")
	static function bit(L:State):Void;
	@:native("luaopen_jit")
	static function jit(L:State):Void;
	@:native("luaopen_ffi")
	static function ffi(L:State):Void;
	@:native("luaopen_string_buffer")
	static function string_buffer(L:State):Void;
}
