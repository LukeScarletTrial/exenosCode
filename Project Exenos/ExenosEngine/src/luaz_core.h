#ifndef LUAZ_CORE_H
#define LUAZ_CORE_H

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>

typedef enum {
    LUAZ_TYPE_NIL,
    LUAZ_TYPE_BOOL,
    LUAZ_TYPE_INT,
    LUAZ_TYPE_FLOAT,
    LUAZ_TYPE_STRING,
    LUAZ_TYPE_TABLE,
    LUAZ_TYPE_FUNCTION,
    LUAZ_TYPE_USERDATA,
    LUAZ_TYPE_METAL_BUFFER,
    LUAZ_TYPE_METAL_TEXTURE
} luaz_type_t;

typedef struct luaz_value {
    luaz_type_t type;
    uint32_t type_tag;
    union {
        int64_t i;
        double f;
        bool b;
        void* p;
        struct {
            const char* data;
            size_t len;
        } str;
    } data;
} luaz_value_t;

typedef struct luaz_register_pool {
    luaz_value_t x[16];
    uint16_t allocated;
    uint16_t pinned;
} luaz_register_pool_t;

typedef struct luaz_vm {
    luaz_register_pool_t registers;
    void* global_table;
    void* metal_device;
    void* metal_queue;
    void* bytecode_cache;
    size_t cache_size;
    uint32_t version;
} luaz_vm_t;

typedef struct luaz_bytecode_header {
    uint32_t magic;
    uint32_t version;
    uint32_t flags;
    uint32_t code_size;
    uint32_t data_size;
    uint32_t register_count;
    uint32_t type_annotation_count;
} luaz_bytecode_header_t;

luaz_vm_t* luaz_vm_create(void);
void luaz_vm_destroy(luaz_vm_t* vm);
int luaz_load_bytecode(luaz_vm_t* vm, const uint8_t* data, size_t len);
int luaz_hot_reload(luaz_vm_t* vm, const uint8_t* data, size_t len);
void luaz_execute(luaz_vm_t* vm);

#endif
