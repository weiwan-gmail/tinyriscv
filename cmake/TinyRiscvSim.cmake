# Shared Verilator CMake helpers for tinyriscv (both cmake-system/ and
# cmake-conan/). Pattern: weiwan-gmail/rtl-learning-plan `cmake/RtlLabSim.cmake`.
#
# - Locate the Verilator kit; on Windows always drive verilator_bin.exe PE
#   (withlimon: https://github.com/withlimon/verilator-windows). Never the
#   extensionless Perl `verilator` (Explorer/CMD Open-with trap).
# - include(CheckCXXCompilerFlag) before verilate().
# - On MSVC, strip GCC-only -fcoroutines* flags Verilator may inject.
# - Drive the same C++ TB as sim/verilator (relative paths into rtl/ and
#   sim/verilator/; no CPU RTL rewrite).
# - sc_time_stamp: sim/verilator/tb_verilator.cpp already defines it. The
#   fail-harness uses cmake/sc_time_stamp.cpp (MSVC has no weak ELF symbols).

include_guard(GLOBAL)

set(TINYRISCV_CMAKE_DIR "${CMAKE_CURRENT_LIST_DIR}")
get_filename_component(TINYRISCV_REPO_ROOT "${TINYRISCV_CMAKE_DIR}/.." ABSOLUTE)

# MSYS2 names a Perl script share/verilator/bin/verilator_bin.exe. withlimon
# and mingw64/bin ship a real PE (MZ). Only the PE may be executed on Windows.
function(tinyriscv_windows_file_is_pe filepath outvar)
  set(_ok FALSE)
  if(EXISTS "${filepath}")
    file(READ "${filepath}" _magic HEX LIMIT 2)
    string(TOUPPER "${_magic}" _magic)
    if(_magic STREQUAL "4D5A")
      set(_ok TRUE)
    endif()
  endif()
  set(${outvar} ${_ok} PARENT_SCOPE)
endfunction()

function(tinyriscv_find_windows_pe outvar)
  unset(TINYRISCV_VERILATOR_BIN CACHE)
  set(_cands "")
  # Known PE bindirs first. $VERILATOR_ROOT/bin on MSYS2 is the Perl wrapper.
  list(APPEND _cands
    "D:/verilator/bin/verilator_bin.exe"
    "C:/msys64/mingw64/bin/verilator_bin.exe")
  if(DEFINED ENV{VERILATOR_ROOT} AND NOT "$ENV{VERILATOR_ROOT}" STREQUAL "")
    list(APPEND _cands
      "$ENV{VERILATOR_ROOT}/bin/verilator_bin.exe"
      "$ENV{VERILATOR_ROOT}/../bin/verilator_bin.exe"
      "$ENV{VERILATOR_ROOT}/../../bin/verilator_bin.exe")
  endif()
  foreach(_c IN LISTS _cands)
    get_filename_component(_abs "${_c}" ABSOLUTE)
    tinyriscv_windows_file_is_pe("${_abs}" _ispe)
    if(_ispe)
      set(${outvar} "${_abs}" PARENT_SCOPE)
      return()
    endif()
  endforeach()
  find_program(_tinyriscv_path_pe NAMES verilator_bin.exe)
  if(_tinyriscv_path_pe)
    tinyriscv_windows_file_is_pe("${_tinyriscv_path_pe}" _ispe)
    if(_ispe)
      set(${outvar} "${_tinyriscv_path_pe}" PARENT_SCOPE)
      return()
    endif()
  endif()
  set(${outvar} "" PARENT_SCOPE)
endfunction()

function(tinyriscv_locate_verilator_kit)
  set(_root "")

  if(WIN32)
    tinyriscv_find_windows_pe(_pe)
    if(NOT _pe)
      message(FATAL_ERROR
        "Windows Verilator PE not found (verilator_bin.exe with MZ header).\n"
        "Install the withlimon build: https://github.com/withlimon/verilator-windows\n"
        "Extract to a short path (e.g. D:\\verilator), then:\n"
        "  VERILATOR_ROOT = D:\\verilator\n"
        "  PATH          += D:\\verilator\\bin\n"
        "Do NOT invoke the extensionless Perl `verilator` (Open-with trap).\n"
        "Do NOT invoke share/verilator/bin/verilator_bin.exe (Perl wrapper with a .exe suffix).\n"
        "PC2023 worker workspace: D:\\CursorWorker")
    endif()
    set(TINYRISCV_VERILATOR_BIN "${_pe}")
  else()
    # Do not pre-set the result variable — find_program skips the search if it
    # is already defined (even as "").
    unset(TINYRISCV_VERILATOR_BIN CACHE)
    find_program(TINYRISCV_VERILATOR_BIN NAMES verilator_bin HINTS
      "$ENV{VERILATOR_ROOT}/bin"
      /usr/bin
      /usr/local/bin)
    if(NOT TINYRISCV_VERILATOR_BIN)
      message(FATAL_ERROR
        "verilator_bin not found. Install Verilator 5.x (e.g. apt install verilator).")
    endif()
  endif()
  set(_pe "${TINYRISCV_VERILATOR_BIN}")

  get_filename_component(_bin "${_pe}" DIRECTORY)
  get_filename_component(_parent "${_bin}" DIRECTORY)
  foreach(_c
      "$ENV{VERILATOR_ROOT}"
      "${_parent}"
      "${_parent}/share/verilator"
      "/usr/share/verilator"
      "/usr/local/share/verilator"
      "D:/verilator"
      "C:/msys64/mingw64/share/verilator")
    if(_c AND EXISTS "${_c}/include/verilated.h")
      set(_root "${_c}")
      break()
    endif()
  endforeach()

  if(NOT _root)
    message(FATAL_ERROR
      "VERILATOR_ROOT kit not found (need include/verilated.h). PE was ${_pe}")
  endif()

  message(STATUS "TinyRiscvSim: VERILATOR_BIN=${_pe}")
  message(STATUS "TinyRiscvSim: VERILATOR_ROOT=${_root}")
  set(TINYRISCV_VERILATOR_BIN "${_pe}" PARENT_SCOPE)
  set(TINYRISCV_VERILATOR_ROOT "${_root}" PARENT_SCOPE)
endfunction()

function(tinyriscv_find_verilator)
  # Pre-seed VERILATOR_BIN so a Debian/Ubuntu verilator-config.cmake does not
  # FATAL (it searches only VERILATOR_ROOT/bin with NO_CMAKE_SYSTEM_PATH), and
  # so an MSYS2 kit config does not pick share/verilator/bin's Perl wrapper.
  if(WIN32)
    tinyriscv_find_windows_pe(_pe_seed)
    if(_pe_seed)
      set(TINYRISCV_VERILATOR_BIN "${_pe_seed}" CACHE FILEPATH "TINYRISCV_VERILATOR_BIN" FORCE)
      set(VERILATOR_BIN "${_pe_seed}" CACHE FILEPATH "VERILATOR_BIN" FORCE)
    endif()
  else()
    find_program(TINYRISCV_VERILATOR_BIN NAMES verilator_bin HINTS
      "$ENV{VERILATOR_ROOT}/bin" /usr/bin /usr/local/bin)
    if(TINYRISCV_VERILATOR_BIN)
      set(VERILATOR_BIN "${TINYRISCV_VERILATOR_BIN}" CACHE FILEPATH "VERILATOR_BIN" FORCE)
    endif()
  endif()

  # First find_package() triggers cmake-conan if the provider is registered.
  find_package(verilator QUIET)

  foreach(_pkg_var
      verilator_PACKAGE_FOLDER_RELEASE
      verilator_PACKAGE_FOLDER_RELWITHDEBINFO
      verilator_PACKAGE_FOLDER_DEBUG
      verilator_PACKAGE_FOLDER)
    if(DEFINED ${_pkg_var} AND EXISTS "${${_pkg_var}}/include/verilated.h")
      set(ENV{VERILATOR_ROOT} "${${_pkg_var}}")
      # Prefer the packaged PE (withlimon on Windows) over a stale PATH hit.
      unset(TINYRISCV_VERILATOR_BIN CACHE)
      message(STATUS "TinyRiscvSim: Conan package folder ${${_pkg_var}}")
      break()
    endif()
  endforeach()

  tinyriscv_locate_verilator_kit()
  set(VERILATOR_ROOT "${TINYRISCV_VERILATOR_ROOT}" CACHE PATH "VERILATOR_ROOT" FORCE)
  set(verilator_ROOT "${TINYRISCV_VERILATOR_ROOT}" CACHE PATH "verilator_ROOT" FORCE)
  set(VERILATOR_BIN "${TINYRISCV_VERILATOR_BIN}" CACHE FILEPATH "VERILATOR_BIN" FORCE)
  set(ENV{VERILATOR_ROOT} "${TINYRISCV_VERILATOR_ROOT}")

  if(NOT COMMAND verilate)
    if(EXISTS "${TINYRISCV_VERILATOR_ROOT}/verilator-config.cmake")
      include("${TINYRISCV_VERILATOR_ROOT}/verilator-config.cmake")
    else()
      message(STATUS
        "TinyRiscvSim: kit has no verilator-config.cmake (typical of withlimon); "
        "using bundled cmake/verilator-config.fallback.cmake")
      include("${TINYRISCV_CMAKE_DIR}/verilator-config.fallback.cmake")
    endif()
  endif()

  # Kit configs may find_program() VERILATOR_ROOT/bin (Perl wrapper on MSYS2).
  # Re-assert the PE after that include so verilate() drives verilator_bin.exe.
  if(WIN32)
    set(VERILATOR_BIN "${TINYRISCV_VERILATOR_BIN}" CACHE FILEPATH "VERILATOR_BIN" FORCE)
    tinyriscv_windows_file_is_pe("${VERILATOR_BIN}" _bin_is_pe)
    if(NOT _bin_is_pe)
      tinyriscv_find_windows_pe(_pe_fix)
      if(NOT _pe_fix)
        message(FATAL_ERROR
          "VERILATOR_BIN is not a PE engine: ${VERILATOR_BIN}\n"
          "Do not use share/verilator/bin/verilator_bin.exe (Perl wrapper).")
      endif()
      set(TINYRISCV_VERILATOR_BIN "${_pe_fix}" CACHE FILEPATH "TINYRISCV_VERILATOR_BIN" FORCE)
      set(VERILATOR_BIN "${_pe_fix}" CACHE FILEPATH "VERILATOR_BIN" FORCE)
      message(STATUS "TinyRiscvSim: replaced non-PE VERILATOR_BIN with ${_pe_fix}")
    endif()
  endif()

  if(NOT COMMAND verilate)
    message(FATAL_ERROR "verilate() missing after Verilator package load")
  endif()
endfunction()

function(tinyriscv_strip_msvc_gcc_flags target)
  if(NOT MSVC)
    return()
  endif()
  foreach(_prop COMPILE_OPTIONS INTERFACE_COMPILE_OPTIONS)
    get_target_property(_opts ${target} ${_prop})
    if(_opts)
      list(FILTER _opts EXCLUDE REGEX "fcoroutines")
      set_property(TARGET ${target} PROPERTY ${_prop} "${_opts}")
    endif()
  endforeach()
endfunction()

# Read sim/verilator/rtl.f so CMake tracks the same file list as Make.
# Paths in rtl.f are relative to sim/verilator/. +incdir+ lines become
# Verilator +incdir+ (needed for `include "defines.v"`). defines.v itself
# is a header, not a module — skip it as a SOURCES entry.
function(tinyriscv_load_rtl_f out_sources out_incdirs)
  set(_f "${TINYRISCV_REPO_ROOT}/sim/verilator/rtl.f")
  set(_base "${TINYRISCV_REPO_ROOT}/sim/verilator")
  if(NOT EXISTS "${_f}")
    message(FATAL_ERROR "TinyRiscvSim: missing ${_f}")
  endif()
  set(_srcs "")
  set(_incs "")
  file(STRINGS "${_f}" _lines)
  foreach(_line IN LISTS _lines)
    string(STRIP "${_line}" _line)
    if(_line STREQUAL "" OR _line MATCHES "^#")
      continue()
    endif()
    if(_line MATCHES "^\\+incdir\\+(.*)$")
      set(_p "${CMAKE_MATCH_1}")
      if(NOT IS_ABSOLUTE "${_p}")
        get_filename_component(_p "${_base}/${_p}" ABSOLUTE)
      endif()
      list(APPEND _incs "${_p}")
      continue()
    endif()
    if(NOT IS_ABSOLUTE "${_line}")
      get_filename_component(_p "${_base}/${_line}" ABSOLUTE)
    else()
      set(_p "${_line}")
    endif()
    get_filename_component(_name "${_p}" NAME)
    if(_name STREQUAL "defines.v")
      continue()
    endif()
    if(NOT EXISTS "${_p}")
      message(FATAL_ERROR "TinyRiscvSim: rtl.f source missing: ${_p}")
    endif()
    list(APPEND _srcs "${_p}")
  endforeach()
  if(NOT _srcs)
    message(FATAL_ERROR "TinyRiscvSim: rtl.f produced no Verilog sources")
  endif()
  set(${out_sources} "${_srcs}" PARENT_SCOPE)
  set(${out_incdirs} "${_incs}" PARENT_SCOPE)
endfunction()

# Firmware → inst.data in the CMake binary dir (TB $readmemh("inst.data")).
# Prefer tests/example/simple (needs RISC-V GCC + GNU make). If the toolchain
# is missing, keep building the Verilator model and smoke with the committed
# ISA image tests/isa/generated/rv32ui-p-add.bin.
function(tinyriscv_prepare_firmware)
  find_package(Python3 COMPONENTS Interpreter REQUIRED)
  find_program(TINYRISCV_GNU_MAKE NAMES gmake make mingw32-make)
  find_program(TINYRISCV_RISCV_GCC NAMES
    riscv64-unknown-elf-gcc
    riscv-none-elf-gcc
    riscv32-unknown-elf-gcc
    riscv-none-embed-gcc)

  set(_simple_dir "${TINYRISCV_REPO_ROOT}/tests/example/simple")
  set(_simple_bin "${_simple_dir}/simple.bin")
  set(_isa_bin "${TINYRISCV_REPO_ROOT}/tests/isa/generated/rv32ui-p-add.bin")
  set(_py "${TINYRISCV_REPO_ROOT}/tools/BinToMem_CLI.py")
  set(_inst "${CMAKE_CURRENT_BINARY_DIR}/inst.data")
  set(_fw "")
  set(_fw_kind "")

  if(TINYRISCV_RISCV_GCC AND TINYRISCV_GNU_MAKE)
    add_custom_command(
      OUTPUT "${_simple_bin}"
      COMMAND "${TINYRISCV_GNU_MAKE}" -C "${_simple_dir}"
      DEPENDS
        "${_simple_dir}/main.c"
        "${_simple_dir}/Makefile"
        "${TINYRISCV_REPO_ROOT}/tests/example/common.mk"
        "${TINYRISCV_REPO_ROOT}/tests/example/start.S"
        "${TINYRISCV_REPO_ROOT}/tests/example/init.c"
        "${TINYRISCV_REPO_ROOT}/tests/example/trap_entry.S"
        "${TINYRISCV_REPO_ROOT}/tests/example/trap_handler.c"
        "${TINYRISCV_REPO_ROOT}/tests/example/link.lds"
        "${TINYRISCV_REPO_ROOT}/tests/example/lib/utils.c"
      COMMENT "RISC-V firmware: make -C tests/example/simple"
      VERBATIM)
    set(_fw "${_simple_bin}")
    set(_fw_kind "tests/example/simple/simple.bin (${TINYRISCV_RISCV_GCC})")
  elseif(EXISTS "${_simple_bin}")
    set(_fw "${_simple_bin}")
    set(_fw_kind "prebuilt tests/example/simple/simple.bin (no RISC-V gcc/make on PATH)")
    message(STATUS
      "TinyRiscvSim: RISC-V toolchain not found; using existing ${_simple_bin}")
  elseif(EXISTS "${_isa_bin}")
    set(_fw "${_isa_bin}")
    set(_fw_kind "fallback tests/isa/generated/rv32ui-p-add.bin (no RISC-V toolchain)")
    message(WARNING
      "TinyRiscvSim: no RISC-V toolchain and no simple.bin.\n"
      "  Install gcc-riscv64-unknown-elf (or xpack riscv-none-elf-gcc) and reconfigure\n"
      "  to smoke tests/example/simple, matching `make -C sim/verilator sim`.\n"
      "  Until then, inst.data is built from ${_isa_bin} (still TEST_PASS).\n"
      "  The Verilator C++ model is built either way.")
  else()
    message(WARNING
      "TinyRiscvSim: no firmware image found. The Verilator model still builds;\n"
      "  `sim` / ctest need inst.data. See CMAKE.md.")
    set(TINYRISCV_INST_DATA "" PARENT_SCOPE)
    set(TINYRISCV_FIRMWARE_KIND "none" PARENT_SCOPE)
    return()
  endif()

  add_custom_command(
    OUTPUT "${_inst}"
    COMMAND "${Python3_EXECUTABLE}" "${_py}" "${_fw}" "${_inst}"
    DEPENDS "${_fw}" "${_py}"
    COMMENT "BinToMem ${_fw} -> inst.data"
    VERBATIM)
  add_custom_target(tinyriscv_fw ALL DEPENDS "${_inst}")
  set(TINYRISCV_INST_DATA "${_inst}" PARENT_SCOPE)
  set(TINYRISCV_FIRMWARE_KIND "${_fw_kind}" PARENT_SCOPE)
  message(STATUS "TinyRiscvSim: firmware ${_fw_kind}")
endfunction()

function(tinyriscv_add_soc_sim)
  tinyriscv_load_rtl_f(_srcs _incs)
  set(_tb "${TINYRISCV_REPO_ROOT}/sim/verilator/tb_verilator.cpp")
  if(NOT EXISTS "${_tb}")
    message(FATAL_ERROR "TinyRiscvSim: missing ${_tb}")
  endif()

  add_executable(sim_tinyriscv "${_tb}")
  target_compile_features(sim_tinyriscv PRIVATE cxx_std_17)

  set(_inc_args "")
  foreach(_inc IN LISTS _incs)
    list(APPEND _inc_args "+incdir+${_inc}")
  endforeach()

  # Same warning set as sim/verilator/Makefile. CheckCXXCompilerFlag must run
  # before verilate() (Verilator's TIMING/coroutines probe uses it).
  include(CheckCXXCompilerFlag)

  verilate(sim_tinyriscv
    PREFIX Vtb_verilator
    TOP_MODULE tb_verilator
    SOURCES ${_srcs}
    INCLUDE_DIRS ${_incs}
    VERILATOR_ARGS
      --clk clk
      --Wno-fatal
      -Wno-UNOPTFLAT
      -Wno-WIDTH
      -Wno-CASEINCOMPLETE
      -Wno-UNSIGNED
      -Wno-PINMISSING
      -Wno-TIMESCALEMOD
      -Wno-IMPLICIT
      --timescale 1ns/1ps
      ${_inc_args}
  )
  tinyriscv_strip_msvc_gcc_flags(sim_tinyriscv)
endfunction()

function(tinyriscv_add_fail_sim)
  add_executable(sim_fail_probe
    "${TINYRISCV_CMAKE_DIR}/fail-harness/tb_intentional_fail.cpp"
    "${TINYRISCV_CMAKE_DIR}/sc_time_stamp.cpp")
  target_compile_features(sim_fail_probe PRIVATE cxx_std_17)
  include(CheckCXXCompilerFlag)
  verilate(sim_fail_probe
    PREFIX Vfail_probe
    TOP_MODULE fail_probe
    SOURCES "${TINYRISCV_CMAKE_DIR}/fail-harness/fail_probe.v"
    VERILATOR_ARGS --Wno-fatal --timescale 1ns/1ps
  )
  tinyriscv_strip_msvc_gcc_flags(sim_fail_probe)
endfunction()

function(tinyriscv_sim_setup)
  if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
  endif()
  set(CMAKE_CXX_STANDARD 17)
  set(CMAKE_CXX_STANDARD_REQUIRED ON)

  tinyriscv_find_verilator()
  include(CheckCXXCompilerFlag)

  tinyriscv_add_soc_sim()
  tinyriscv_add_fail_sim()
  tinyriscv_prepare_firmware()

  set(_sim_cwd "${CMAKE_CURRENT_BINARY_DIR}")
  set(_sim_deps sim_tinyriscv)
  if(TARGET tinyriscv_fw)
    list(APPEND _sim_deps tinyriscv_fw)
  endif()

  add_custom_target(sim
    DEPENDS ${_sim_deps}
    COMMAND "$<TARGET_FILE:sim_tinyriscv>" +max-cycles=2000000
    WORKING_DIRECTORY "${_sim_cwd}"
    COMMENT "Run tinyriscv Verilator TB (same as make -C sim/verilator sim)"
    VERBATIM)

  add_custom_target(sim-fail
    DEPENDS sim_fail_probe
    COMMAND ${CMAKE_COMMAND}
            -DEXE=$<TARGET_FILE:sim_fail_probe>
            -P ${TINYRISCV_CMAKE_DIR}/ExpectFail.cmake
    COMMENT "Inject-and-catch: fail_probe checker must FAIL; runner succeeds only then"
    VERBATIM)

  add_test(NAME sim_tinyriscv
    COMMAND sim_tinyriscv +max-cycles=2000000
    WORKING_DIRECTORY "${_sim_cwd}")
  if(TARGET tinyriscv_fw)
    # ctest does not build ALL; require inst.data via a setup fixture.
    add_test(NAME tinyriscv_fw_setup
      COMMAND ${CMAKE_COMMAND} --build "${CMAKE_BINARY_DIR}" --target tinyriscv_fw)
    set_tests_properties(tinyriscv_fw_setup PROPERTIES FIXTURES_SETUP tinyriscv_fw)
    set_tests_properties(sim_tinyriscv PROPERTIES FIXTURES_REQUIRED tinyriscv_fw)
  endif()

  add_test(NAME sim-fail
    COMMAND ${CMAKE_COMMAND}
            -DEXE=$<TARGET_FILE:sim_fail_probe>
            -P ${TINYRISCV_CMAKE_DIR}/ExpectFail.cmake)
endfunction()
