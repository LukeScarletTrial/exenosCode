#ifndef LUAZ_RELOAD_H
#define LUAZ_RELOAD_H

#include "luaz_core.h"
#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

typedef struct luaz_reload_context {
    int shm_fd;
    void* shm_base;
    size_t shm_size;
    dispatch_source_t monitor_source;
    luaz_vm_t* vm;
    void (*reload_callback)(luaz_vm_t*, const uint8_t*, size_t);
} luaz_reload_context_t;

#define LUAZ_SHM_NAME "/luaz_hotreload"
#define LUAZ_SHM_SIZE (16 * 1024 * 1024)

luaz_reload_context_t* luaz_reload_create(luaz_vm_t* vm);
void luaz_reload_destroy(luaz_reload_context_t* ctx);
int luaz_reload_push_bytecode(luaz_reload_context_t* ctx, const uint8_t* data, size_t len);
int luaz_reload_start_monitor(luaz_reload_context_t* ctx);
void luaz_reload_stop_monitor(luaz_reload_context_t* ctx);

#endif
