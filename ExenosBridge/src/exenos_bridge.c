#include "exenos_bridge.h"
#include "luaz_core.h"
#include "luaz_metal.h"
#include "luaz_reload.h"

exenos_vm_handle exenos_vm_create(void) {
    return luaz_vm_create();
}

void exenos_vm_destroy(exenos_vm_handle handle) {
    luaz_vm_destroy((luaz_vm_t*)handle);
}

int exenos_vm_load_bytecode(exenos_vm_handle handle, const uint8_t* data, size_t len) {
    return luaz_load_bytecode((luaz_vm_t*)handle, data, len);
}

int exenos_vm_hot_reload(exenos_vm_handle handle, const uint8_t* data, size_t len) {
    return luaz_hot_reload((luaz_vm_t*)handle, data, len);
}

void exenos_vm_execute(exenos_vm_handle handle) {
    luaz_execute((luaz_vm_t*)handle);
}

uint32_t exenos_vm_get_version(exenos_vm_handle handle) {
    luaz_vm_t* vm = (luaz_vm_t*)handle;
    return vm ? vm->version : 0;
}

exenos_metal_handle exenos_metal_create(void* native_view) {
    return luaz_metal_create(native_view);
}

void exenos_metal_destroy(exenos_metal_handle handle) {
    luaz_metal_destroy((luaz_metal_context_t*)handle);
}

int exenos_metal_render(exenos_metal_handle handle, exenos_vm_handle vm) {
    return luaz_metal_render((luaz_metal_context_t*)handle, (luaz_vm_t*)vm);
}

int exenos_metal_create_buffer(exenos_metal_handle handle, size_t size, uint32_t flags, void** out_buffer) {
    return luaz_metal_create_buffer((luaz_metal_context_t*)handle, size, flags, (luaz_metal_buffer_t**)out_buffer);
}

void exenos_metal_destroy_buffer(void* buffer) {
    luaz_metal_destroy_buffer((luaz_metal_buffer_t*)buffer);
}

int exenos_metal_create_texture(exenos_metal_handle handle, uint32_t width, uint32_t height, void** out_texture) {
    return luaz_metal_create_texture((luaz_metal_context_t*)handle, width, height, (luaz_metal_texture_t**)out_texture);
}

void exenos_metal_destroy_texture(void* texture) {
    luaz_metal_destroy_texture((luaz_metal_texture_t*)texture);
}

void exenos_metal_present(exenos_metal_handle handle) {
    luaz_metal_present((luaz_metal_context_t*)handle);
}

exenos_reload_handle exenos_reload_create(exenos_vm_handle vm) {
    return luaz_reload_create((luaz_vm_t*)vm);
}

void exenos_reload_destroy(exenos_reload_handle handle) {
    luaz_reload_destroy((luaz_reload_context_t*)handle);
}

int exenos_reload_push_bytecode(exenos_reload_handle handle, const uint8_t* data, size_t len) {
    return luaz_reload_push_bytecode((luaz_reload_context_t*)handle, data, len);
}

int exenos_reload_start_monitor(exenos_reload_handle handle) {
    return luaz_reload_start_monitor((luaz_reload_context_t*)handle);
}

void exenos_reload_stop_monitor(exenos_reload_handle handle) {
    luaz_reload_stop_monitor((luaz_reload_context_t*)handle);
}
