#ifndef LUA_H
#define LUA_H

#include <stddef.h>

typedef struct lua_State lua_State;
typedef int (*lua_CFunction)(lua_State *L);

enum {
    LUA_OK = 0,
    LUA_MULTRET = -1
};

lua_State *luaL_newstate(void);
void luaL_openlibs(lua_State *L);
void lua_close(lua_State *L);
int luaL_loadstring(lua_State *L, const char *s);
int lua_pcall(lua_State *L, int nargs, int nresults, int errfunc);
void lua_getglobal(lua_State *L, const char *name);
int lua_isfunction(lua_State *L, int idx);
void lua_pop(lua_State *L, int n);
const char *lua_tostring(lua_State *L, int idx);
void lua_pushcfunction(lua_State *L, lua_CFunction f);
void lua_setfield(lua_State *L, int idx, const char *k);
void lua_newtable(lua_State *L);
void lua_setglobal(lua_State *L, const char *name);
double lua_tonumber(lua_State *L, int idx);
void lua_pushnumber(lua_State *L, double n);
void lua_pushstring(lua_State *L, const char *s);
int lua_gettop(lua_State *L);

#endif
