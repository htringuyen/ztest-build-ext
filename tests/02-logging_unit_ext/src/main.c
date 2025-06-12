/*
 * Copyright (c) 2016 Intel Corporation
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include <zephyr/ztest.h>
#include <zephyr/logging/log.h>

LOG_MODULE_REGISTER(ztest_build_ext, LOG_LEVEL_DBG);

/**
 * @brief Test Asserts
 *
 * This test verifies various assert macros provided by ztest.
 *
 */
ZTEST(logging_sample, test_some_logs)
{
	zassert_true(1, "1 was false");
	LOG_INF("================================== This log is from inside test function ==================================");
	
	zassert_false(0, "0 was true");
	LOG_INF("================================== This log is from inside test function ==================================");
}

ZTEST_SUITE(logging_sample, NULL, NULL, NULL, NULL, NULL);