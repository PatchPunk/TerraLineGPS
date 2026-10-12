#!/usr/bin/env python3
"""Use installed Lua shared library for local compile-only syntax check."""
from pathlib import Path
import ctypes
from ctypes.util import find_library
lib=ctypes.CDLL(find_library('lua5.4') or 'liblua5.4.so.0')
lib.luaL_newstate.restype=ctypes.c_void_p
lib.luaL_loadbufferx.argtypes=[ctypes.c_void_p,ctypes.c_char_p,ctypes.c_size_t,ctypes.c_char_p,ctypes.c_char_p]
lib.luaL_loadbufferx.restype=ctypes.c_int
lib.lua_tolstring.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_void_p]
lib.lua_tolstring.restype=ctypes.c_char_p
lib.lua_close.argtypes=[ctypes.c_void_p]
root=Path(__file__).resolve().parents[1]
L=lib.luaL_newstate()
try:
    lua=list((root/'scripts').glob('*.lua'))
    failed=[]
    for f in lua:
        s=f.read_bytes()
        status=lib.luaL_loadbufferx(L,s,len(s),str(f.name).encode(),None)
        if status!=0:
            failed.append((f.name,(lib.lua_tolstring(L,-1,None) or b'error').decode()))
            lib.lua_close(L); L=lib.luaL_newstate()
        else:
            lib.lua_close(L); L=lib.luaL_newstate()
    if failed:
        for f,e in failed: print(f,e)
        raise SystemExit(1)
    print(f'{len(lua)} Lua files compile successfully (Lua 5.4 syntax-only check)')
finally: lib.lua_close(L)
