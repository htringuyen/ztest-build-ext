
#include <stddef.h>
#include <stdlib.h>

// #ifndef k_malloc
// #define k_malloc(x) malloc(x)
// #endif

// #ifndef k_free
// #define k_free(x) free(x)
// #endif

void *k_malloc(size_t size) {
    return malloc(size);
}

void k_free(void *ptr) {
    free(ptr);
}

void *k_realloc(void *ptr, size_t size) {
    return realloc(ptr, size);
}