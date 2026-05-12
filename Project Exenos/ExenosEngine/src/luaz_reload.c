#include "luaz_reload.h"
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <dispatch/dispatch.h>

luaz_reload_context_t* luaz_reload_create(luaz_vm_t* vm) {
    luaz_reload_context_t* ctx = calloc(1, sizeof(luaz_reload_context_t));
    if (!ctx) return NULL;
    
    ctx->vm = vm;
    ctx->shm_fd = -1;
    ctx->shm_base = MAP_FAILED;
    ctx->shm_size = LUAZ_SHM_SIZE;
    
    shm_unlink(LUAZ_SHM_NAME);
    
    ctx->shm_fd = shm_open(LUAZ_SHM_NAME, O_CREAT | O_RDWR, 0666);
    if (ctx->shm_fd == -1) {
        free(ctx);
        return NULL;
    }
    
    if (ftruncate(ctx->shm_fd, ctx->shm_size) == -1) {
        close(ctx->shm_fd);
        shm_unlink(LUAZ_SHM_NAME);
        free(ctx);
        return NULL;
    }
    
    ctx->shm_base = mmap(NULL, ctx->shm_size, PROT_READ | PROT_WRITE, MAP_SHARED, ctx->shm_fd, 0);
    if (ctx->shm_base == MAP_FAILED) {
        close(ctx->shm_fd);
        shm_unlink(LUAZ_SHM_NAME);
        free(ctx);
        return NULL;
    }
    
    memset(ctx->shm_base, 0, ctx->shm_size);
    
    return ctx;
}

void luaz_reload_destroy(luaz_reload_context_t* ctx) {
    if (!ctx) return;
    
    luaz_reload_stop_monitor(ctx);
    
    if (ctx->shm_base != MAP_FAILED) {
        munmap(ctx->shm_base, ctx->shm_size);
    }
    
    if (ctx->shm_fd != -1) {
        close(ctx->shm_fd);
        shm_unlink(LUAZ_SHM_NAME);
    }
    
    free(ctx);
}

int luaz_reload_push_bytecode(luaz_reload_context_t* ctx, const uint8_t* data, size_t len) {
    if (!ctx || !data || len > ctx->shm_size - sizeof(uint32_t) * 2) return -1;
    
    uint32_t* header = (uint32_t*)ctx->shm_base;
    
    header[0] = 0x52444C5A;
    header[1] = (uint32_t)len;
    
    memcpy((uint8_t*)ctx->shm_base + sizeof(uint32_t) * 2, data, len);
    
    __sync_synchronize();
    header[0] = 0x52444C43;
    
    return 0;
}

static void luaz_reload_handler(void* context) {
    luaz_reload_context_t* ctx = (luaz_reload_context_t*)context;
    if (!ctx || !ctx->vm) return;
    
    uint32_t* header = (uint32_t*)ctx->shm_base;
    uint32_t magic = header[0];
    uint32_t len = header[1];
    
    if (magic == 0x52444C43 && len > 0 && len <= ctx->shm_size - sizeof(uint32_t) * 2) {
        const uint8_t* data = (const uint8_t*)ctx->shm_base + sizeof(uint32_t) * 2;
        
        if (ctx->reload_callback) {
            ctx->reload_callback(ctx->vm, data, len);
        } else {
            luaz_hot_reload(ctx->vm, data, len);
        }
        
        header[0] = 0x52444C5A;
    }
}

int luaz_reload_start_monitor(luaz_reload_context_t* ctx) {
    if (!ctx) return -1;
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    
    ctx->monitor_source = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    if (!ctx->monitor_source) return -2;
    
    dispatch_source_set_timer(ctx->monitor_source, DISPATCH_TIME_NOW, 16 * NSEC_PER_MSEC, 1 * NSEC_PER_MSEC);
    dispatch_source_set_event_handler_f(ctx->monitor_source, luaz_reload_handler);
    dispatch_set_context(ctx->monitor_source, ctx);
    
    dispatch_resume(ctx->monitor_source);
    
    return 0;
}

void luaz_reload_stop_monitor(luaz_reload_context_t* ctx) {
    if (!ctx || !ctx->monitor_source) return;
    
    dispatch_source_cancel(ctx->monitor_source);
    dispatch_release(ctx->monitor_source);
    ctx->monitor_source = NULL;
}
