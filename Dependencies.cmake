include(cmake/CPM.cmake)

function(AddSpdlogPackage WcharSupport WcharFilenames)
  CPMAddPackage(
          NAME spdlog
          VERSION 1.15.1
          GITHUB_REPOSITORY "gabime/spdlog"
          OPTIONS
          "SPDLOG_FMT_EXTERNAL ON"
          "SPDLOG_ENABLE_PCH ON"
          "SPDLOG_BUILD_PIC ON"
          "SPDLOG_WCHAR_SUPPORT ${WcharSupport}"
          "SPDLOG_WCHAR_FILENAMES ${WcharFilenames}"
          "SPDLOG_SANITIZE_ADDRESS OFF"
  )
endfunction()


# Done as a function so that updates to variables like
# CMAKE_CXX_FLAGS don't propagate out to other
# targets
function(SDL3RT_setup_dependencies)

  # For each dependency, see if it's
  # already been provided to us by a parent project

  if (NOT TARGET fmtlib::fmtlib)
    CPMAddPackage("gh:fmtlib/fmt#11.1.3")
  endif ()

  if (NOT TARGET spdlog::spdlog)
    if (WIN32)
      AddSpdlogPackage(ON ON)
    else ()
      AddSpdlogPackage(OFF OFF)
    endif ()
  endif ()

  if (NOT TARGET Catch2::Catch2WithMain)
    CPMAddPackage("gh:catchorg/Catch2@3.8.0")
  endif ()

  if (NOT TARGET CLI11::CLI11)
    CPMAddPackage("gh:CLIUtils/CLI11@2.4.2")
  endif ()

  if(NOT TARGET SDL3::SDL3)
    CPMAddPackage(
            NAME SDL3
            GITHUB_REPOSITORY libsdl-org/SDL
            GIT_TAG release-3.2.2
            OPTIONS
            "SDL_SHARED OFF"
            "SDL_STATIC ON"
            "SDL_TEST_LIBRARY OFF"
            #"SDL_INSTALL_TESTS OFF"
            #"SDL_DISABLE_INSTALL_DOCS OFF"
            #"SDL_DISABLE_INSTALL OFF"
    )
  endif()
endfunction()
