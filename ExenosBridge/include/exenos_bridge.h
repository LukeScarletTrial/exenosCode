#ifndef EXENOS_BRIDGE_H
#define EXENOS_BRIDGE_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef void* exenos_vm_handle;
typedef void* exenos_metal_handle;
typedef void* exenos_reload_handle;

exenos_vm_handle exenos_vm_create(void);
void exenos_vm_destroy(exenos_vm_handle handle);
int exenos_vm_load_bytecode(exenos_vm_handle handle, const uint8_t* data, size_t len);
int exenos_vm_hot_reload(exenos_vm_handle handle, const uint8_t* data, size_t len);
void exenos_vm_execute(exenos_vm_handle handle);
uint32_t exenos_vm_get_version(exenos_vm_handle handle);

exenos_metal_handle exenos_metal_create(void* native_view);
void exenos_metal_destroy(exenos_metal_handle handle);
int exenos_metal_render(exenos_metal_handle handle, exenos_vm_handle vm);
int exenos_metal_create_buffer(exenos_metal_handle handle, size_t size, uint32_t flags, void** out_buffer);
void exenos_metal_destroy_buffer(void* buffer);
int exenos_metal_create_texture(exenos_metal_handle handle, uint32_t width, uint32_t height, void** out_texture);
void exenos_metal_destroy_texture(void* texture);
void exenos_metal_present(exenos_metal_handle handle);

exenos_reload_handle exenos_reload_create(exenos_vm_handle vm);
void exenos_reload_destroy(exenos_reload_handle handle);
int exenos_reload_push_bytecode(exenos_reload_handle handle, const uint8_t* data, size_t len);
int exenos_reload_start_monitor(exenos_reload_handle handle);
void exenos_reload_stop_monitor(exenos_reload_handle handle);

#ifdef __cplusplus
}
#endif

#endif
