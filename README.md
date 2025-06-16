# Ztest build extension

Used by [zephyr-without-west](https://github.com/htringuyen/zephyr-without-west) for building compact unit tests and a modular way to manage dependecies used in those tests.

For simple usages, please view example testing applications in `tests`.
The naming conventions of the test application is as follows: [app_id]-[app_name]\_[testing_type]\_[testing_way]. Where:
- `app_id`: e.g. 01, 02, etc. Apps with the same id share the same logic (usually the same source)
- `app_name`: descriptive name of the app, apps with the same id have the same `app_name`
- `testing_type`: `ut` for unit test or `it` for integration test
- `testing_way`: `ext` if using `ztest-build-ext`, `def` if using default twiter build and run way.

For understanding this project, you can start with the zephyr's custom cmake module [ztest_build_ext](https://github.com/htringuyen/zephyr/blob/main/cmake/modules/ztest_build_ext.cmake)
