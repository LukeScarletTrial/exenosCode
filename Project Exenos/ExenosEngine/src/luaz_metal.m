#include "luaz_metal.h"
#include <QuartzCore/QuartzCore.h>

static const char* luaz_metal_shaders =
    "#include <metal_stdlib>\n"
    "using namespace metal;\n"
    "struct VertexIn {\n"
    "    float4 position [[attribute(0)]];\n"
    "    float4 color [[attribute(1)]];\n"
    "};\n"
    "struct VertexOut {\n"
    "    float4 position [[position]];\n"
    "    float4 color;\n"
    "};\n"
    "vertex VertexOut vertex_main(VertexIn in [[stage_in]]) {\n"
    "    VertexOut out;\n"
    "    out.position = in.position;\n"
    "    out.color = in.color;\n"
    "    return out;\n"
    "}\n"
    "fragment float4 fragment_main(VertexOut in [[stage_in]]) {\n"
    "    return in.color;\n"
    "}\n";

luaz_metal_context_t* luaz_metal_create(void* nativeView) {
    luaz_metal_context_t* ctx = calloc(1, sizeof(luaz_metal_context_t));
    if (!ctx) return NULL;
    
    ctx->device = MTLCreateSystemDefaultDevice();
    if (!ctx->device) {
        free(ctx);
        return NULL;
    }
    
    ctx->commandQueue = [ctx->device newCommandQueue];
    ctx->frameSemaphore = dispatch_semaphore_create(3);
    
    UIView* view = (__bridge UIView*)nativeView;
    ctx->metalLayer = [CAMetalLayer layer];
    ctx->metalLayer.device = ctx->device;
    ctx->metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    ctx->metalLayer.framebufferOnly = YES;
    ctx->metalLayer.frame = view.bounds;
    
    [view.layer addSublayer:ctx->metalLayer];
    
    NSError* error = nil;
    ctx->library = [ctx->device newLibraryWithSource:@(luaz_metal_shaders) options:nil error:&error];
    if (!ctx->library) {
        luaz_metal_destroy(ctx);
        return NULL;
    }
    
    id<MTLFunction> vertexFunc = [ctx->library newFunctionWithName:@"vertex_main"];
    id<MTLFunction> fragmentFunc = [ctx->library newFunctionWithName:@"fragment_main"];
    
    MTLRenderPipelineDescriptor* pipelineDesc = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineDesc.vertexFunction = vertexFunc;
    pipelineDesc.fragmentFunction = fragmentFunc;
    pipelineDesc.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    
    ctx->pipelineState = [ctx->device newRenderPipelineStateWithDescriptor:pipelineDesc error:&error];
    if (!ctx->pipelineState) {
        luaz_metal_destroy(ctx);
        return NULL;
    }
    
    ctx->uniformBuffer = [ctx->device newBufferWithLength:sizeof(float) * 16 options:MTLResourceStorageModeShared];
    
    return ctx;
}

void luaz_metal_destroy(luaz_metal_context_t* ctx) {
    if (!ctx) return;
    
    ctx->uniformBuffer = nil;
    ctx->pipelineState = nil;
    ctx->library = nil;
    ctx->commandQueue = nil;
    ctx->device = nil;
    
    free(ctx);
}

int luaz_metal_render(luaz_metal_context_t* ctx, luaz_vm_t* vm) {
    if (!ctx || !ctx->metalLayer) return -1;
    
    dispatch_semaphore_wait(ctx->frameSemaphore, DISPATCH_TIME_FOREVER);
    
    id<CAMetalDrawable> drawable = [ctx->metalLayer nextDrawable];
    if (!drawable) return -2;
    
    MTLRenderPassDescriptor* passDesc = [MTLRenderPassDescriptor renderPassDescriptor];
    passDesc.colorAttachments[0].texture = drawable.texture;
    passDesc.colorAttachments[0].loadAction = MTLLoadActionClear;
    passDesc.colorAttachments[0].storeAction = MTLStoreActionStore;
    passDesc.colorAttachments[0].clearColor = MTLClearColorMake(0.05, 0.05, 0.08, 1.0);
    
    id<MTLCommandBuffer> commandBuffer = [ctx->commandQueue commandBuffer];
    id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:passDesc];
    
    [encoder setRenderPipelineState:ctx->pipelineState];
    [encoder endEncoding];
    
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
    
    __block dispatch_semaphore_t semaphore = ctx->frameSemaphore;
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
        dispatch_semaphore_signal(semaphore);
    }];
    
    ctx->frameCounter++;
    
    return 0;
}

int luaz_metal_create_buffer(luaz_metal_context_t* ctx, size_t size, uint32_t flags, luaz_metal_buffer_t** out_buffer) {
    if (!ctx || !out_buffer) return -1;
    
    luaz_metal_buffer_t* buffer = calloc(1, sizeof(luaz_metal_buffer_t));
    if (!buffer) return -2;
    
    MTLResourceOptions options = MTLResourceStorageModeShared;
    if (flags & 0x01) options = MTLResourceStorageModePrivate;
    if (flags & 0x02) options = MTLResourceStorageModeManaged;
    
    buffer->buffer = [ctx->device newBufferWithLength:size options:options];
    buffer->size = size;
    buffer->flags = flags;
    
    if (!buffer->buffer) {
        free(buffer);
        return -3;
    }
    
    *out_buffer = buffer;
    return 0;
}

void luaz_metal_destroy_buffer(luaz_metal_buffer_t* buffer) {
    if (!buffer) return;
    buffer->buffer = nil;
    free(buffer);
}

int luaz_metal_create_texture(luaz_metal_context_t* ctx, uint32_t width, uint32_t height, luaz_metal_texture_t** out_texture) {
    if (!ctx || !out_texture) return -1;
    
    luaz_metal_texture_t* texture = calloc(1, sizeof(luaz_metal_texture_t));
    if (!texture) return -2;
    
    MTLTextureDescriptor* desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
                                                                                    width:width
                                                                                   height:height
                                                                                mipmapped:NO];
    desc.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
    desc.storageMode = MTLStorageModePrivate;
    
    texture->texture = [ctx->device newTextureWithDescriptor:desc];
    texture->descriptor = desc;
    texture->width = width;
    texture->height = height;
    
    if (!texture->texture) {
        free(texture);
        return -3;
    }
    
    *out_texture = texture;
    return 0;
}

void luaz_metal_destroy_texture(luaz_metal_texture_t* texture) {
    if (!texture) return;
    texture->texture = nil;
    texture->descriptor = nil;
    free(texture);
}

void luaz_metal_present(luaz_metal_context_t* ctx) {
}
