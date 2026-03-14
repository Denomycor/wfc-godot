#!/usr/bin/env python
import os
from SCons.Script import Glob, Default, SConscript

# --- Load godot-cpp environment ---
env = SConscript("godot-cpp/SConstruct")

env.Tool("compilation_db")

# --- Include paths ---
env.Append(CPPPATH=[
    "include",
    "src",
    "thirdparty/wfc/include",
    "godot-cpp/include",
    "godot-cpp/gen/include",
    "godot-cpp/gdextension"
])

# --- Variant dir for extension ---
VariantDir("build", "src", duplicate=0)

# --- Extension sources ---
extension_sources = Glob("build/*.cpp")

# --- WFC sources ---
wfc_sources = Glob("thirdparty/wfc/src/*.cpp")

sources = extension_sources + wfc_sources

# --- Platform build ---
if env["platform"] == "macos":
    library = env.SharedLibrary(
        "demo/bin/libgdexample.{}.{}.framework/libgdexample.{}.{}".format(
            env["platform"], env["target"], env["platform"], env["target"]
        ),
        source=sources,
    )

elif env["platform"] == "ios":
    if env["ios_simulator"]:
        library = env.StaticLibrary(
            "demo/bin/libgdexample.{}.{}.simulator.a".format(
                env["platform"], env["target"]
            ),
            source=sources,
        )
    else:
        library = env.StaticLibrary(
            "demo/bin/libgdexample.{}.{}.a".format(
                env["platform"], env["target"]
            ),
            source=sources,
        )

else:
    library = env.SharedLibrary(
        "demo/bin/libgdexample{}{}".format(
            env["suffix"], env["SHLIBSUFFIX"]
        ),
        source=sources,
    )

Default(library)

env.CompilationDatabase("compile_commands.json")
