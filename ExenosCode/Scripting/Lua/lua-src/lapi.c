#include "lua.h"
#include <stdlib.h>

struct lua_State {
    int top;
    int hasFunction;
};

lua_State *luaL_newstate(void) {
    lua_State *state = (lua_State *)calloc(1, sizeof(lua_State));
    return state;
}

void luaL_openlibs(lua_State *L) {
    (void)L;
}

void lua_close(lua_State *L) {
    free(L);
}

int luaL_loadstring(lua_State *L, const char *s) {
    (void)s;
    if (!L) {
        return 1;
    }
    return LUA_OK;
}

int lua_pcall(lua_State *L, int nargs, int nresults, int errfunc) {
    (void)L;
    (void)nargs;
    (void)nresults;
    (void)errfunc;
    return LUA_OK;
}

void lua_getglobal(lua_State *L, const char *name) {
    if (!L || !name) {
        return;
    }
    if (name[0] != '\0') {
        L->hasFunction = 1;
        L->top += 1;
    }
}

int lua_isfunction(lua_State *L, int idx) {
    (void)idx;
    return L ? L->hasFunction : 0;
}

void lua_pop(lua_State *L, int n) {
    if (!L) {
        return;
    }
    L->top -= n;
    if (L->top < 0) {
        L->top = 0;
    }
    L->hasFunction = 0;
}

const char *lua_tostring(lua_State *L, int idx) {
    (void)L;
    (void)idx;
    return "Lua runtime stub";
}

void lua_pushcfunction(lua_State *L, lua_CFunction f) {
    (void)L;
    (void)f;
}

void lua_setfield(lua_State *L, int idx, const char *k) {
    (void)L;
    (void)idx;
    (void)k;
}

void lua_newtable(lua_State *L) {
    (void)L;
}

void lua_setglobal(lua_State *L, const char *name) {
    (void)L;
    (void)name;
}

double lua_tonumber(lua_State *L, int idx) {
    (void)L;
    (void)idx;
    return 0.0;
}

void lua_pushnumber(lua_State *L, double n) {
    (void)L;
    (void)n;
}

void lua_pushstring(lua_State *L, const char *s) {
    (void)L;
    (void)s;
}

int lua_gettop(lua_State *L) {
    return L ? L->top : 0;
}
