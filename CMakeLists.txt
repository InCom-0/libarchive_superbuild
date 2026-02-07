cmake_minimum_required(VERSION 3.30...4.2)

project(libarchive_superbuild
    HOMEPAGE_URL "https://github.com/InCom-0/libarchive_superbuild"
    VERSION "0.0.0"
    DESCRIPTION
    "Pure CMake wrap around libarchive that can include and build the libarchive dependencies that are not available on your system (eg. useful for native windows builds and other niche cases)"
    LANGUAGES C CXX)

set(CMAKE_CXX_SCAN_FOR_MODULES OFF)
option(BUILD_SHARED_LIBS "Build shared libraries" ON)
option(libarchive_superbuild_STAGE_OUTPUTS "Stage build output artifacts into proper directory structure" ON)

option(libarchive_superbuild_USE_LOCAL_PACKAGES "Use local (usually system installed) packages for dependencies." OFF)
option(libarchive_superbuild_USE_LOCAL_PACKAGES_ONLY "Forbid the build system from downloading missing dependencies." OFF)


include(cmake/CPM.cmake)

### This attempts to compile sample program to find out if we are using libc++(USING_LIBCXX) or libstdc++(USING_LIBSTDCXX) or MSVC_STL(USING_MSVC_STL)
include(cmake/stdlibQuery.cmake)


#####################################################################
### Staging ###
#####################################################################
include(cmake/StageOutputs.cmake)
if(libarchive_superbuild_STAGE_OUTPUTS)
    stageOutputDirsFor(libarchive_superbuild)
endif()


######################################################################
### Target specification ###
######################################################################



