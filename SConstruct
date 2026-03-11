#!/usr/bin/env python
import os
from SCons.Script import Glob, Default, SConscript

# --- 1. Load godot-cpp environment ---
env = SConscript("godot-cpp/SConstruct")

# --- 2. Enable compilation database ---
env.Tool("compilation_db")

# --- 3. Add include paths ---
env.Append(CPPPATH=[
    "include",                  # your extension headers
    "godot-cpp/include",
    "godot-cpp/gen/include",
    "godot-cpp/gdextension",
    "wfc-cpp/include"           # wfc-cpp headers
])

# --- 4. Build wfc-cpp directly via its SConstruct ---
# This will modify 'env' in place, like godot-cpp
SConscript("wfc-cpp/SConstruct", exports={"env": env})

# --- 5. Build your extension sources ---
VariantDir("build", "src", duplicate=0)
sources = Glob("src/*.cpp")

# --- 6. Platform-specific library build ---
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
            "demo/bin/libgdexample.{}.{}.simulator.a".format(env["platform"], env["target"]),
            source=sources,
        )
    else:
        library = env.StaticLibrary(
            "demo/bin/libgdexample.{}.{}.a".format(env["platform"], env["target"]),
            source=sources,
        )
else:
    library = env.SharedLibrary(
        "demo/bin/libgdexample{}{}".format(env["suffix"], env["SHLIBSUFFIX"]),
        source=sources,
    )

# --- 7. Default target and compile_commands.json ---
Default(library)
env.CompilationDatabase("compile_commands.json")
