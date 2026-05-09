import Foundation

enum LuaBindings {
    private static weak var sink: NodeCommandSink?

    static func install(in state: OpaquePointer?, sink: NodeCommandSink) {
        self.sink = sink
        lua_newtable(state)
        lua_pushcfunction(state, lua_sprite_add)
        lua_setfield(state, -2, "add")
        lua_setglobal(state, "sprite")
    }

    static func addSprite(x: Double, y: Double) {
        sink?.addSprite(x: x, y: y)
    }
}

@_cdecl("lua_sprite_add")
func lua_sprite_add(_ state: OpaquePointer?) -> Int32 {
    guard let state else { return 0 }
    let top = lua_gettop(state)
    let x = top >= 1 ? lua_tonumber(state, 1) : 0
    let y = top >= 2 ? lua_tonumber(state, 2) : 0
    LuaBindings.addSprite(x: x, y: y)
    return 0
}
