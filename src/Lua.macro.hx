package;

import sys.io.File;
import haxe.macro.Expr;
using Lambda;
private enum CType {
	CVoid;
	CInt;
	CString;
	CState;
	IntBool;
	LuaNumber;
	LuaInteger;
	LuaCFunction;
	Ref(t:CType);
	CDynamic;
	HaxeFunction(ret:CType,args:Array<CType>);
	CBytes;
}

class Lua {
	public static var header = "#define HL_NAME(n) lua_##n
#include <hl.h>
#if defined(__APPLE__) || defined(__ANDROID__) || defined(__linux__) || defined(HL_CLANG)
#undef EXPORT
#define EXPORT __attribute__((visibility(\"default\")))
#endif

#define _STATE _ABSTRACT(lua_State)

#include \"lua.h\"
#include \"lauxlib.h\"
#include \"lualib.h\"
#include \"luajit.h\"

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
";

	static function convType(c:ComplexType):CType {
		return switch c {
			case TPath({pack: _, name: name, params: params}):
				switch name {
                    case "Void": CVoid;
					case "Int" | "ThreadStatus" | "LuaType": CInt;
					case "LuaNumber": LuaNumber;
					case "LuaInteger": LuaInteger;
					case "LuaCFunction": LuaCFunction;
					case "State": CState;
					case "CString": CString;
					case "IntBool": IntBool;
					case "Ref": Ref(switch params[0] {
							case TPType(t): convType(t);
							case TPExpr(e): throw "assert";
						});
                    case "Bytes": CBytes;
                    case "T" | "Dynamic": CDynamic;
                    // case "Reader" | "Writer": HaxeFunction(CVoid,[]);
					case var n: throw "unhandled type : " + n;
				}
			case _: throw "unhandled type : " + c;
		}
	}
    static function toC(c:CType) {
        return switch c {
            case CVoid: "void";
            case CInt: "int";
            case CString: "const char *";
            case CState: "lua_State *";
            case IntBool: "bool";
            case LuaNumber: "lua_Number";
            case LuaInteger: "lua_Integer";
            case LuaCFunction: "vclosure *";
            case Ref(t): toC(t) + "*";
            case CDynamic: "vdynamic *";
            case HaxeFunction(_,_): "vclosure *";
            case CBytes: "vbyte *";
        }
    }
    static function toHL(c:CType) {
        return switch c {
            case CVoid: "_VOID";
            case CInt: "_I32";
            case CString: "_BYTES";
            case CState: "_STATE";
            case IntBool: "_BOOL";
            case LuaNumber: "_F64";
            case LuaInteger: "_I32";
            case LuaCFunction: "_FUN(_I32,_STATE)";
            case Ref(t): "_REF(" + toHL(t) + ")";
            case CDynamic: "_DYN";
            case HaxeFunction(ret,args): "_DYN(" + toHL(ret) + "," + [for(a in args) toHL(a)].join(" ") + ")";
            case CBytes: "_BYTES";
        }
    }
	public static function gen() {
		var fields = haxe.macro.Context.getBuildFields();
        #if (hl_gen&&!display)
		var str = new StringBuf();
        str.add(header);
        #end
		for (f in fields) {
            if(f.name == "init") continue;
			switch f.kind {
				case FFun({args: args, ret: convType(_) => ret, expr: null, params: params}):
					var nativename:String;
                    {
						var m = f.meta.find(item -> item.name == ":native");
                        if(m != null) {
							nativename = switch m.params[0].expr {
								case EConst(CString(s)): s;
								case _: throw "assert";
							}
                            f.meta.remove(m);
                        } else {
                            continue;
                        }
                    }
					if (f.meta.exists(item -> item.name == ":skipHL"))
						continue;
					var args:Array<{
						name:String,
						type:CType
					}> = args.map(a -> {
						name: a.name,
						type: convType(a.type)
					});

                    #if (hl_gen&&!display)
                    str.add("HL_PRIM ");
                    str.add(toC(ret));
                    str.add(" ");
                    str.add("HL_NAME(hl_");
                    str.add(f.name);
                    str.add(")(");
                    str.add([for(a in args) '${toC(a.type)} ${a.name}'].join(","));
                    str.add(") {\n");
                    str.add("    ");
                    if(ret != CVoid) str.add("return ");
                    if(ret == LuaCFunction) str.add("hl_alloc_closure_void(" + "luacfunctype" + ",");
                    str.add(nativename + "(");
                    str.add([for(a in args) {
                        switch a.type {
                            case IntBool:"(int)" + a.name;
                            case LuaCFunction: a.name + "->fun";
                            case CDynamic: "(void*)" + a.name;
                            case HaxeFunction(_,_): a.name + "->fun";
                            case _: a.name;
                        }
                    }].join(","));
                    if(ret == IntBool) str.add(") == 1;\n") else if(ret == LuaCFunction) str.add("));\n") else str.add(");\n");
                    str.add("}\n\n");
                    str.add('DEFINE_PRIM(${toHL(ret)},hl_${f.name},${[for(a in args) toHL(a.type)].join(" ")})\n\n');
                    #end
				case _:
					continue;
			}
		}
        #if (hl_gen&&!display)
        File.saveContent("native/lua.c",str.toString());
        #end
		return fields;
	}
}
