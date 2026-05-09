#include "lauxlib.h"

int luaL_error(lua_State *L, const char *fmt, ...) {
    (void)L;
    (void)fmt;
    return 1;
}
