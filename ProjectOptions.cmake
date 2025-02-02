include(cmake/SystemLink.cmake)
include(cmake/LibFuzzer.cmake)
include(CMakeDependentOption)
include(CheckCXXCompilerFlag)


macro(SDL3RT_supports_sanitizers)
  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND NOT WIN32)
    set(SUPPORTS_UBSAN ON)
  else()
    set(SUPPORTS_UBSAN OFF)
  endif()

  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND WIN32)
    set(SUPPORTS_ASAN OFF)
  else()
    set(SUPPORTS_ASAN ON)
  endif()
endmacro()

macro(SDL3RT_setup_options)
  option(SDL3RT_ENABLE_HARDENING "Enable hardening" ON)
  option(SDL3RT_ENABLE_COVERAGE "Enable coverage reporting" OFF)
  cmake_dependent_option(
    SDL3RT_ENABLE_GLOBAL_HARDENING
    "Attempt to push hardening options to built dependencies"
    ON
    SDL3RT_ENABLE_HARDENING
    OFF)

  SDL3RT_supports_sanitizers()

  if(NOT PROJECT_IS_TOP_LEVEL OR SDL3RT_PACKAGING_MAINTAINER_MODE)
    option(SDL3RT_ENABLE_IPO "Enable IPO/LTO" OFF)
    option(SDL3RT_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(SDL3RT_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(SDL3RT_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" OFF)
    option(SDL3RT_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(SDL3RT_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" OFF)
    option(SDL3RT_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(SDL3RT_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(SDL3RT_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(SDL3RT_ENABLE_CLANG_TIDY "Enable clang-tidy" OFF)
    option(SDL3RT_ENABLE_CPPCHECK "Enable cpp-check analysis" OFF)
    option(SDL3RT_ENABLE_PCH "Enable precompiled headers" OFF)
    option(SDL3RT_ENABLE_CACHE "Enable ccache" OFF)
  else()
    option(SDL3RT_ENABLE_IPO "Enable IPO/LTO" ON)
    option(SDL3RT_WARNINGS_AS_ERRORS "Treat Warnings As Errors" ON)
    option(SDL3RT_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(SDL3RT_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" ${SUPPORTS_ASAN})
    option(SDL3RT_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(SDL3RT_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" ${SUPPORTS_UBSAN})
    option(SDL3RT_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(SDL3RT_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(SDL3RT_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(SDL3RT_ENABLE_CLANG_TIDY "Enable clang-tidy" ON)
    option(SDL3RT_ENABLE_CPPCHECK "Enable cpp-check analysis" ON)
    option(SDL3RT_ENABLE_PCH "Enable precompiled headers" OFF)
    option(SDL3RT_ENABLE_CACHE "Enable ccache" ON)
  endif()

  if(NOT PROJECT_IS_TOP_LEVEL)
    mark_as_advanced(
      SDL3RT_ENABLE_IPO
      SDL3RT_WARNINGS_AS_ERRORS
      SDL3RT_ENABLE_USER_LINKER
      SDL3RT_ENABLE_SANITIZER_ADDRESS
      SDL3RT_ENABLE_SANITIZER_LEAK
      SDL3RT_ENABLE_SANITIZER_UNDEFINED
      SDL3RT_ENABLE_SANITIZER_THREAD
      SDL3RT_ENABLE_SANITIZER_MEMORY
      SDL3RT_ENABLE_UNITY_BUILD
      SDL3RT_ENABLE_CLANG_TIDY
      SDL3RT_ENABLE_CPPCHECK
      SDL3RT_ENABLE_COVERAGE
      SDL3RT_ENABLE_PCH
      SDL3RT_ENABLE_CACHE)
  endif()

  SDL3RT_check_libfuzzer_support(LIBFUZZER_SUPPORTED)
  if(LIBFUZZER_SUPPORTED AND (SDL3RT_ENABLE_SANITIZER_ADDRESS OR SDL3RT_ENABLE_SANITIZER_THREAD OR SDL3RT_ENABLE_SANITIZER_UNDEFINED))
    set(DEFAULT_FUZZER ON)
  else()
    set(DEFAULT_FUZZER OFF)
  endif()

  option(SDL3RT_BUILD_FUZZ_TESTS "Enable fuzz testing executable" ${DEFAULT_FUZZER})

endmacro()

macro(SDL3RT_global_options)
  if(SDL3RT_ENABLE_IPO)
    include(cmake/InterproceduralOptimization.cmake)
    SDL3RT_enable_ipo()
  endif()

  SDL3RT_supports_sanitizers()

  if(SDL3RT_ENABLE_HARDENING AND SDL3RT_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR SDL3RT_ENABLE_SANITIZER_UNDEFINED
       OR SDL3RT_ENABLE_SANITIZER_ADDRESS
       OR SDL3RT_ENABLE_SANITIZER_THREAD
       OR SDL3RT_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    message("${SDL3RT_ENABLE_HARDENING} ${ENABLE_UBSAN_MINIMAL_RUNTIME} ${SDL3RT_ENABLE_SANITIZER_UNDEFINED}")
    SDL3RT_enable_hardening(SDL3RT_options ON ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()
endmacro()

macro(SDL3RT_local_options)
  if(PROJECT_IS_TOP_LEVEL)
    include(cmake/StandardProjectSettings.cmake)
  endif()

  add_library(SDL3RT_warnings INTERFACE)
  add_library(SDL3RT_options INTERFACE)

  include(cmake/CompilerWarnings.cmake)
  SDL3RT_set_project_warnings(
    SDL3RT_warnings
    ${SDL3RT_WARNINGS_AS_ERRORS}
    ""
    ""
    ""
    "")

  if(SDL3RT_ENABLE_USER_LINKER)
    include(cmake/Linker.cmake)
    SDL3RT_configure_linker(SDL3RT_options)
  endif()

  include(cmake/Sanitizers.cmake)
  SDL3RT_enable_sanitizers(
    SDL3RT_options
    ${SDL3RT_ENABLE_SANITIZER_ADDRESS}
    ${SDL3RT_ENABLE_SANITIZER_LEAK}
    ${SDL3RT_ENABLE_SANITIZER_UNDEFINED}
    ${SDL3RT_ENABLE_SANITIZER_THREAD}
    ${SDL3RT_ENABLE_SANITIZER_MEMORY})

  set_target_properties(SDL3RT_options PROPERTIES UNITY_BUILD ${SDL3RT_ENABLE_UNITY_BUILD})

  if(SDL3RT_ENABLE_PCH)
    target_precompile_headers(
      SDL3RT_options
      INTERFACE
      <vector>
      <string>
      <utility>)
  endif()

  if(SDL3RT_ENABLE_CACHE)
    include(cmake/Cache.cmake)
    SDL3RT_enable_cache()
  endif()

  include(cmake/StaticAnalyzers.cmake)
  if(SDL3RT_ENABLE_CLANG_TIDY)
    SDL3RT_enable_clang_tidy(SDL3RT_options ${SDL3RT_WARNINGS_AS_ERRORS})
  endif()

  if(SDL3RT_ENABLE_CPPCHECK)
    SDL3RT_enable_cppcheck(${SDL3RT_WARNINGS_AS_ERRORS} "" # override cppcheck options
    )
  endif()

  if(SDL3RT_ENABLE_COVERAGE)
    include(cmake/Tests.cmake)
    SDL3RT_enable_coverage(SDL3RT_options)
  endif()

  if(SDL3RT_WARNINGS_AS_ERRORS)
    check_cxx_compiler_flag("-Wl,--fatal-warnings" LINKER_FATAL_WARNINGS)
    if(LINKER_FATAL_WARNINGS)
      # This is not working consistently, so disabling for now
      # target_link_options(SDL3RT_options INTERFACE -Wl,--fatal-warnings)
    endif()
  endif()

  if(SDL3RT_ENABLE_HARDENING AND NOT SDL3RT_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR SDL3RT_ENABLE_SANITIZER_UNDEFINED
       OR SDL3RT_ENABLE_SANITIZER_ADDRESS
       OR SDL3RT_ENABLE_SANITIZER_THREAD
       OR SDL3RT_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    SDL3RT_enable_hardening(SDL3RT_options OFF ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()

endmacro()
