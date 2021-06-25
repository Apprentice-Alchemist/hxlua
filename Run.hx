import sys.io.File;
import sys.io.Process;

using StringTools;
using Lambda;

class Run {
	public static function main() {
		final args = Sys.args();
        final c = Sys.getCwd();
		if (args[0] == "rebuild") {
			rebuild(args.pop());
		}
        Sys.setCwd(c);
	}

	static function rebuild(thispath:String) {
		var hxcpp_path:String;
		{
			final proc = new sys.io.Process("haxelib", ["libpath", "hxcpp"]);
			proc.exitCode();
			hxcpp_path = proc.stdout.readAll().toString();
			proc.close();
		}
		Sys.setCwd(thispath + "LuaJIT/src");
		if (Sys.systemName() == "Windows") {
			setupVS();
			// Sys.command(hxcpp_path.replace("/", "\\") + "msvc64-setup.bat");
			Sys.command("msvcbuild.bat");
			File.copy("lua51.dll", "../../lib/Windows64/lua51.dll");
			File.copy("lua51.dll", "../../lib/Windows64/lua51.dll");
		} else {
			Sys.command("make");
			if (Sys.systemName() == "Linux")
				File.copy("libluajit-5.1.so", "../../lib/Linux64/libluajit-5.1.so");
			else
				File.copy("libluajit-5.1.dylib", "../../lib/Mac64/libluajit-5.1.dylib");
		}
        Sys.setCwd(thispath);
	}

	static function setupVS() {
		// var proc = new sys.io.Process("C:\\Program Files (x86)\\Microsoft Visual Studio\\Installer\\vswhere.exe", [
		// 	"-latest",
		// 	"-products",
		// 	"*",
		// 	"-requires",
		// 	"Microsoft.VisualStudio.Component.VC.Tools.x86.x64",
		// 	"-property",
		// 	"installationPath"
		// ]);
		// proc.exitCode();
		// var p = proc.stdout.readAll().toString().split("\n");
		// p.pop();
		// var path = p.pop();
		// trace(path);
		// Sys.command(path + "\\VC\\Auxiliary\\Build\\vcvars64.bat",[]);
		// proc.close();
	}
}
