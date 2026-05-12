#ifndef LUAZ_METAL_H
#define LUAZ_METAL_H

#include <Metal/Metal.h>
#include "luaz_core.h"

typedef struct luaz_metal_context {
    id<MTLDevice> device;
    id<MTLCommandQueue> commandQueue;
    id<MTLLibrary> library;
    CAMetalLayer* metalLayer;
    id<MTLRenderPipelineState> pipelineState;
    id<MTLBuffer> uniformBuffer;
    dispatch_semaphore_t frameSemaphore;
    uint32_t frameCounter;
} luaz_metal_context_t;

typedef struct luaz_metal_buffer {
    id<MTLBuffer> buffer;
    size_t size;
    uint32_t flags;
} luaz_metal_buffer_t;

typedef struct luaz_metal_texture {
    id<MTLTexture> texture;
    MTLTextureDescriptor* descriptor;
    uint32_t width;
    uint32_t height;
} luaz_metal_texture_t;

luaz_metal_context_t* luaz_metal_create(void* nativeView);
void luaz_metal_destroy(luaz_metal_context_t* ctx);
int luaz_metal_render(luaz_metal_context_t* ctx, luaz_vm_t* vm);
int luaz_metal_create_buffer(luaz_metal_context_t* ctx, size_t size, uint32_t flags, luaz_metal_buffer_t** out_buffer);
void luaz_metal_destroy_buffer(luaz_metal_buffer_t* buffer);
int luaz_metal_create_texture(luaz_metal_context_t* ctx, uint32_t width, uint32_t height, luaz_metal_texture_t** out_texture);
void luaz_metal_destroy_texture(luaz_metal_texture_t* texture);
void luaz_metal_present(luaz_metal_context_t* ctx);

#endif
