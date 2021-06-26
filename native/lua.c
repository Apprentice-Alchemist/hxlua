#define HL_NAME(n) lua_##n
#include <hl.h>
#if defined(__APPLE__) || defined(__ANDROID__) || defined(__linux__) || defined(HL_CLANG)
#undef EXPORT
#define EXPORT __attribute__((visibility("default")))
#endif

#define _STATE _ABSTRACT(lua_State)

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
#include "luajit.h"

static hl_type *luacfunctype = NULL;
static hl_type *bytes_type = NULL;
HL_PRIM void HL_NAME(hl_init)(hl_type *ct,hl_type *bt) {
    luacfunctype = ct;
    bytes_type = bt;
}

DEFINE_PRIM(_VOID,hl_init,_TYPE _TYPE)

typedef struct
{
    hl_type *t;
    int length;
    vbyte *b;
} hl_bytes;

#define _HL_BYTES _OBJ(_I32 _BYTES)

static const char *read(lua_State *L, void *ud, size_t *sz)
{
    hl_bytes *b = hl_call1(hl_bytes *, ((vclosure *)ud), lua_State *, L);
    *sz = b->length;
    return b->b;
}

static int write(lua_State *L, const void *p, size_t sz, void *ud)
{
    hl_bytes *b = hl_alloc_dynamic(bytes_type);
    b->length = (int)sz;
    b->b = (vbyte*)p;
    return hl_call2(int, ((vclosure *)ud), lua_State *, L, hl_bytes*,b);
}

HL_PRIM int HL_NAME(hl_load)(lua_State *L, vclosure *reader, const char *chunkname)
{
    return lua_load(L, read, reader, chunkname);
}

DEFINE_PRIM(_I32, hl_load, _STATE _FUN(_HL_BYTES, _STATE) _BYTES)

HL_PRIM int HL_NAME(hl_dump)(lua_State *L, vclosure *writer)
{
    return lua_dump(L, write, writer);
}

DEFINE_PRIM(_I32, hl_dump, _STATE _FUN(_I32, _STATE _HL_BYTES))
HL_PRIM lua_State * HL_NAME(hl_newstate)() {
    return luaL_newstate();
}

DEFINE_PRIM(_STATE,hl_newstate,)

HL_PRIM void HL_NAME(hl_close)(lua_State * L) {
    lua_close(L);
}

DEFINE_PRIM(_VOID,hl_close,_STATE)

HL_PRIM lua_State * HL_NAME(hl_newthread)(lua_State * L) {
    return lua_newthread(L);
}

DEFINE_PRIM(_STATE,hl_newthread,_STATE)

HL_PRIM vclosure * HL_NAME(hl_atpanic)(lua_State * L,vclosure * panicf) {
    return hl_alloc_closure_void(luacfunctype,lua_atpanic(L,panicf->fun));
}

DEFINE_PRIM(_FUN(_I32,_STATE),hl_atpanic,_STATE _FUN(_I32,_STATE))

HL_PRIM int HL_NAME(hl_gettop)(lua_State * L) {
    return lua_gettop(L);
}

DEFINE_PRIM(_I32,hl_gettop,_STATE)

HL_PRIM void HL_NAME(hl_settop)(lua_State * L,int idx) {
    lua_settop(L,idx);
}

DEFINE_PRIM(_VOID,hl_settop,_STATE _I32)

HL_PRIM void HL_NAME(hl_pushvalue)(lua_State * L,int idx) {
    lua_pushvalue(L,idx);
}

DEFINE_PRIM(_VOID,hl_pushvalue,_STATE _I32)

HL_PRIM void HL_NAME(hl_remove)(lua_State * L,int idx) {
    lua_remove(L,idx);
}

DEFINE_PRIM(_VOID,hl_remove,_STATE _I32)

HL_PRIM void HL_NAME(hl_insert)(lua_State * l,int idx) {
    lua_insert(l,idx);
}

DEFINE_PRIM(_VOID,hl_insert,_STATE _I32)

HL_PRIM void HL_NAME(hl_replace)(lua_State * L,int idx) {
    lua_replace(L,idx);
}

DEFINE_PRIM(_VOID,hl_replace,_STATE _I32)

HL_PRIM int HL_NAME(hl_checkstack)(lua_State * L,int sz) {
    return lua_checkstack(L,sz);
}

DEFINE_PRIM(_I32,hl_checkstack,_STATE _I32)

HL_PRIM void HL_NAME(hl_xmove)(lua_State * from,lua_State * to,int n) {
    lua_xmove(from,to,n);
}

DEFINE_PRIM(_VOID,hl_xmove,_STATE _STATE _I32)

HL_PRIM bool HL_NAME(hl_isnumber)(lua_State * L,int idx) {
    return lua_isnumber(L,idx) == 1;
}

DEFINE_PRIM(_BOOL,hl_isnumber,_STATE _I32)

HL_PRIM bool HL_NAME(hl_isstring)(lua_State * L,int idx) {
    return lua_isstring(L,idx) == 1;
}

DEFINE_PRIM(_BOOL,hl_isstring,_STATE _I32)

HL_PRIM bool HL_NAME(hl_iscfunction)(lua_State * L,int idx) {
    return lua_iscfunction(L,idx) == 1;
}

DEFINE_PRIM(_BOOL,hl_iscfunction,_STATE _I32)

HL_PRIM bool HL_NAME(hl_isuserdata)(lua_State * L,int idx) {
    return lua_isuserdata(L,idx) == 1;
}

DEFINE_PRIM(_BOOL,hl_isuserdata,_STATE _I32)

HL_PRIM int HL_NAME(hl_type)(lua_State * L,int idx) {
    return lua_type(L,idx);
}

DEFINE_PRIM(_I32,hl_type,_STATE _I32)

HL_PRIM const char * HL_NAME(hl_typename)(lua_State * L,int tp) {
    return lua_typename(L,tp);
}

DEFINE_PRIM(_BYTES,hl_typename,_STATE _I32)

HL_PRIM bool HL_NAME(hl_equal)(lua_State * L,int idx1,int idx2) {
    return lua_equal(L,idx1,idx2) == 1;
}

DEFINE_PRIM(_BOOL,hl_equal,_STATE _I32 _I32)

HL_PRIM bool HL_NAME(hl_rawequal)(lua_State * L,int idx1,int idx2) {
    return lua_rawequal(L,idx1,idx2) == 1;
}

DEFINE_PRIM(_BOOL,hl_rawequal,_STATE _I32 _I32)

HL_PRIM bool HL_NAME(hl_lessthan)(lua_State * L,int idx1,int idx2) {
    return lua_lessthan(L,idx1,idx2) == 1;
}

DEFINE_PRIM(_BOOL,hl_lessthan,_STATE _I32 _I32)

HL_PRIM lua_Number HL_NAME(hl_tonumber)(lua_State * L,int idx) {
    return lua_tonumber(L,idx);
}

DEFINE_PRIM(_F64,hl_tonumber,_STATE _I32)

HL_PRIM lua_Integer HL_NAME(hl_tointeger)(lua_State * L,int idx) {
    return lua_tointeger(L,idx);
}

DEFINE_PRIM(_I32,hl_tointeger,_STATE _I32)

HL_PRIM bool HL_NAME(hl_toboolean)(lua_State * L,int idx) {
    return lua_toboolean(L,idx) == 1;
}

DEFINE_PRIM(_BOOL,hl_toboolean,_STATE _I32)

HL_PRIM const char * HL_NAME(hl_tolstring)(lua_State * L,int idx,int* len) {
    return lua_tolstring(L,idx,len);
}

DEFINE_PRIM(_BYTES,hl_tolstring,_STATE _I32 _REF(_I32))

HL_PRIM int HL_NAME(hl_objlen)(lua_State * L,int idx) {
    return lua_objlen(L,idx);
}

DEFINE_PRIM(_I32,hl_objlen,_STATE _I32)

HL_PRIM vclosure * HL_NAME(hl_tocfunction)(lua_State * L,int idx) {
    return hl_alloc_closure_void(luacfunctype,lua_tocfunction(L,idx));
}

DEFINE_PRIM(_FUN(_I32,_STATE),hl_tocfunction,_STATE _I32)

HL_PRIM vdynamic * HL_NAME(hl_touserdata)(lua_State * L,int idx) {
    return lua_touserdata(L,idx);
}

DEFINE_PRIM(_DYN,hl_touserdata,_STATE _I32)

HL_PRIM lua_State * HL_NAME(hl_tothread)(lua_State * L,int idx) {
    return lua_tothread(L,idx);
}

DEFINE_PRIM(_STATE,hl_tothread,_STATE _I32)

HL_PRIM vdynamic * HL_NAME(hl_topointer)(lua_State * L,int idx) {
    return lua_topointer(L,idx);
}

DEFINE_PRIM(_DYN,hl_topointer,_STATE _I32)

HL_PRIM void HL_NAME(hl_pushnil)(lua_State * L) {
    lua_pushnil(L);
}

DEFINE_PRIM(_VOID,hl_pushnil,_STATE)

HL_PRIM void HL_NAME(hl_pushnumber)(lua_State * L,lua_Number n) {
    lua_pushnumber(L,n);
}

DEFINE_PRIM(_VOID,hl_pushnumber,_STATE _F64)

HL_PRIM void HL_NAME(hl_pushinteger)(lua_State * L,lua_Integer n) {
    lua_pushinteger(L,n);
}

DEFINE_PRIM(_VOID,hl_pushinteger,_STATE _I32)

HL_PRIM void HL_NAME(hl_pushlstring)(lua_State * L,vbyte * s,int len) {
    lua_pushlstring(L,s,len);
}

DEFINE_PRIM(_VOID,hl_pushlstring,_STATE _BYTES _I32)

HL_PRIM void HL_NAME(hl_pushstring)(lua_State * L,const char * s) {
    lua_pushstring(L,s);
}

DEFINE_PRIM(_VOID,hl_pushstring,_STATE _BYTES)

HL_PRIM void HL_NAME(hl_pushcclosure)(lua_State * L,vclosure * fn,int n) {
    lua_pushcclosure(L,fn->fun,n);
}

DEFINE_PRIM(_VOID,hl_pushcclosure,_STATE _FUN(_I32,_STATE) _I32)

HL_PRIM void HL_NAME(hl_pushlightuserdata)(lua_State * L,vdynamic * p) {
    lua_pushlightuserdata(L,(void*)p);
}

DEFINE_PRIM(_VOID,hl_pushlightuserdata,_STATE _DYN)

HL_PRIM int HL_NAME(hl_pushthread)(lua_State * L) {
    return lua_pushthread(L);
}

DEFINE_PRIM(_I32,hl_pushthread,_STATE)

HL_PRIM void HL_NAME(hl_gettable)(lua_State * L,int idx) {
    lua_gettable(L,idx);
}

DEFINE_PRIM(_VOID,hl_gettable,_STATE _I32)

HL_PRIM void HL_NAME(hl_getfield)(lua_State * L,int idx,const char * name) {
    lua_getfield(L,idx,name);
}

DEFINE_PRIM(_VOID,hl_getfield,_STATE _I32 _BYTES)

HL_PRIM void HL_NAME(hl_rawget)(lua_State * L,int idx) {
    lua_rawget(L,idx);
}

DEFINE_PRIM(_VOID,hl_rawget,_STATE _I32)

HL_PRIM void HL_NAME(hl_rawgeti)(lua_State * L,int idx,int n) {
    lua_rawgeti(L,idx,n);
}

DEFINE_PRIM(_VOID,hl_rawgeti,_STATE _I32 _I32)

HL_PRIM void HL_NAME(hl_createtable)(lua_State * L,int narr,int nrec) {
    lua_createtable(L,narr,nrec);
}

DEFINE_PRIM(_VOID,hl_createtable,_STATE _I32 _I32)

HL_PRIM vdynamic * HL_NAME(hl_newuserdata)(lua_State * L,int sz) {
    return lua_newuserdata(L,sz);
}

DEFINE_PRIM(_DYN,hl_newuserdata,_STATE _I32)

HL_PRIM int HL_NAME(hl_getmetatable)(lua_State * L,int objindex) {
    return lua_getmetatable(L,objindex);
}

DEFINE_PRIM(_I32,hl_getmetatable,_STATE _I32)

HL_PRIM void HL_NAME(hl_getfenv)(lua_State * L,int idx) {
    lua_getfenv(L,idx);
}

DEFINE_PRIM(_VOID,hl_getfenv,_STATE _I32)

HL_PRIM void HL_NAME(hl_settable)(lua_State * L,int idx) {
    lua_settable(L,idx);
}

DEFINE_PRIM(_VOID,hl_settable,_STATE _I32)

HL_PRIM void HL_NAME(hl_setfield)(lua_State * L,int idx,const char * k) {
    lua_setfield(L,idx,k);
}

DEFINE_PRIM(_VOID,hl_setfield,_STATE _I32 _BYTES)

HL_PRIM void HL_NAME(hl_rawset)(lua_State * L,int idx) {
    lua_rawset(L,idx);
}

DEFINE_PRIM(_VOID,hl_rawset,_STATE _I32)

HL_PRIM void HL_NAME(hl_rawseti)(lua_State * L,int idx,int n) {
    lua_rawseti(L,idx,n);
}

DEFINE_PRIM(_VOID,hl_rawseti,_STATE _I32 _I32)

HL_PRIM void HL_NAME(hl_setmetatable)(lua_State * L,int objindex) {
    lua_setmetatable(L,objindex);
}

DEFINE_PRIM(_VOID,hl_setmetatable,_STATE _I32)

HL_PRIM int HL_NAME(hl_setfenv)(lua_State * L,int idx) {
    return lua_setfenv(L,idx);
}

DEFINE_PRIM(_I32,hl_setfenv,_STATE _I32)

HL_PRIM void HL_NAME(hl_call)(lua_State * L,int nargs,int nresults) {
    lua_call(L,nargs,nresults);
}

DEFINE_PRIM(_VOID,hl_call,_STATE _I32 _I32)

HL_PRIM int HL_NAME(hl_pcall)(lua_State * L,int nargs,int nresults,int errfunc) {
    return lua_pcall(L,nargs,nresults,errfunc);
}

DEFINE_PRIM(_I32,hl_pcall,_STATE _I32 _I32 _I32)

HL_PRIM int HL_NAME(hl_cpcall)(lua_State * L,vclosure * func,vdynamic * ud) {
    return lua_cpcall(L,func->fun,(void*)ud);
}

DEFINE_PRIM(_I32,hl_cpcall,_STATE _FUN(_I32,_STATE) _DYN)

HL_PRIM int HL_NAME(hl_yield)(lua_State * L,int nresults) {
    return lua_yield(L,nresults);
}

DEFINE_PRIM(_I32,hl_yield,_STATE _I32)

HL_PRIM int HL_NAME(hl_resume)(lua_State * L,int narg) {
    return lua_resume(L,narg);
}

DEFINE_PRIM(_I32,hl_resume,_STATE _I32)

HL_PRIM int HL_NAME(hl_status)(lua_State * L) {
    return lua_status(L);
}

DEFINE_PRIM(_I32,hl_status,_STATE)

HL_PRIM int HL_NAME(hl_gc)(lua_State * L,int what,int data) {
    return lua_gc(L,what,data);
}

DEFINE_PRIM(_I32,hl_gc,_STATE _I32 _I32)

HL_PRIM int HL_NAME(hl_error)(lua_State * L) {
    return lua_error(L);
}

DEFINE_PRIM(_I32,hl_error,_STATE)

HL_PRIM int HL_NAME(hl_next)(lua_State * L,int idx) {
    return lua_next(L,idx);
}

DEFINE_PRIM(_I32,hl_next,_STATE _I32)

HL_PRIM void HL_NAME(hl_concat)(lua_State * L,int n) {
    lua_concat(L,n);
}

DEFINE_PRIM(_VOID,hl_concat,_STATE _I32)

HL_PRIM void HL_NAME(hl_openlibs)(lua_State * L) {
    luaL_openlibs(L);
}

DEFINE_PRIM(_VOID,hl_openlibs,_STATE)

HL_PRIM int HL_NAME(hl_loadfile)(lua_State * L,const char * filename) {
    return luaL_loadfile(L,filename);
}

DEFINE_PRIM(_I32,hl_loadfile,_STATE _BYTES)

