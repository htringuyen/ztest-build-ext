#include <zephyr/ztest.h>
#include <zephyr/logging/log.h>
#include <zephyr/kernel.h>
#include <stdlib.h>

// #define k_malloc(x) malloc(x)
// #define k_free(x) free(x)

LOG_MODULE_REGISTER(dummy_malloc, LOG_LEVEL_INF);

ZTEST(dummy_malloc, test_dummy_malloc)
{
    LOG_INF("Starting test: k_malloc + k_free with int my_array");

    int *my_arr = k_malloc(4 * sizeof(int));
    zassert_not_null(my_arr, "k_malloc failed");
    LOG_INF("Allocated my_array at %p", my_arr);

    // Write values
    for (int i = 0; i < 4; i++) {
        my_arr[i] = i * 10;
        LOG_INF("my_arr[%d] = %d", i, my_arr[i]);
    }

    // Read back one value to check
    zassert_equal(my_arr[2], 20, "Unexpected value at my_arr[2]");

    k_free(my_arr);
    LOG_INF("Freed memory");
}

ZTEST_SUITE(dummy_malloc, NULL, NULL, NULL, NULL, NULL);
