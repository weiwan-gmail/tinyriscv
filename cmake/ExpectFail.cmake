# Run EXE; this script succeeds only when the process fails AND prints FAIL.
# Used by the `sim-fail` target (inject-and-catch).
#
#   cmake -DEXE=/path/to/sim_fail_csd -P cmake/ExpectFail.cmake

if(NOT EXE)
  message(FATAL_ERROR "ExpectFail.cmake requires -DEXE=<path>")
endif()

execute_process(
  COMMAND "${EXE}"
  RESULT_VARIABLE rc
  OUTPUT_VARIABLE out
  ERROR_VARIABLE err
  OUTPUT_STRIP_TRAILING_WHITESPACE
  ERROR_STRIP_TRAILING_WHITESPACE
)
set(_all "${out}\n${err}")
message(STATUS "sim-fail stdout:\n${out}")
if(err)
  message(STATUS "sim-fail stderr:\n${err}")
endif()

if(rc EQUAL 0)
  message(FATAL_ERROR
    "sim-fail: expected the checker to fail, but EXE exited 0 (failure was NOT caught)")
endif()
if(NOT _all MATCHES "FAIL")
  message(FATAL_ERROR
    "sim-fail: EXE exited ${rc} but output has no FAIL marker")
endif()
message(STATUS "sim-fail: caught expected FAIL (exit ${rc})")
