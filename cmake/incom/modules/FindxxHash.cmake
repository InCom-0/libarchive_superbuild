#[=======================================================================[.rst:
FindxxHash
--------------

Find xxHash headers and libraries.

Imported Targets
^^^^^^^^^^^^^^^^

``xxHash::xxhash``
  The libxxhash library, if found.


Result Variables
^^^^^^^^^^^^^^^^

This will define the following variables in your project.
Note that one typically does not need to use these variables because lz4::lz4 is first class CMake target that encapsulates all of them.

``xxHash_FOUND``
  true if (the requested version of) XXHASH is available.
``xxHash_VERSION``
  the version of XXHASH.
``xxHash_LIBRARY``
  the libraries to link against to use XXHASH.
``xxHash_INCLUDE_DIR``
  where to find the LZ headers.
``xxHash_COMPILE_OPTIONS``
  this should be passed to target_compile_options(), if the
  target is not used for linking

#]=======================================================================]

# Try config package first (from xxHashConfig.cmake / xxHash-config.cmake)
set(_pkg "${CMAKE_FIND_PACKAGE_NAME}") # e.g. xxHash
set(_args CONFIG NO_MODULE)

if(${_pkg}_FIND_QUIETLY)
    list(APPEND _args QUIET)
endif()
if(${_pkg}_FIND_REQUIRED)
    list(APPEND _args REQUIRED)
endif()
if(DEFINED ${_pkg}_FIND_VERSION)
    list(APPEND _args ${${_pkg}_FIND_VERSION})
    if(${_pkg}_FIND_VERSION_EXACT)
        list(APPEND _args EXACT)
    endif()
endif()
if(DEFINED ${_pkg}_FIND_COMPONENTS)
    list(APPEND _args COMPONENTS ${${_pkg}_FIND_COMPONENTS})
endif()
if(DEFINED ${_pkg}_FIND_OPTIONAL_COMPONENTS)
    list(APPEND _args OPTIONAL_COMPONENTS ${${_pkg}_FIND_OPTIONAL_COMPONENTS})
endif()

find_package(${_pkg} ${_args})
if(${_pkg}_FOUND)
    # Config package found; stop here.
    set(xxHash_FOUND TRUE)
    return()
endif()

# Config package NOT found; proceed with finding using PkgConfig.
find_package(PkgConfig QUIET)
if(PkgConfig_FOUND)
    pkg_check_modules(xxHash_PC QUIET IMPORTED_TARGET libxxhash)
endif()

if(xxHash_PC_FOUND)
    if(NOT TARGET xxHash::xxhash)
        add_library(xxHash::xxhash ALIAS PkgConfig::xxHash_PC)
    endif()

    set(xxHash_COMPILE_OPTIONS ${xxHash_PC_CFLAGS_OTHER} CACHE STRING "libxxhash target compile options")
    set(xxHash_VERSION ${xxHash_PC_VERSION} CACHE STRING "libxxhash target version")

    find_path(xxHash_INCLUDE_DIR
        NAMES xxhash.h
        HINTS ${xxHash_PC_INCLUDEDIR} ${xxHash_PC_INCLUDE_DIRS}
    )
    find_library(xxHash_LIBRARY
        NAMES ${xxHash_NAMES} xxhash
        HINTS ${xxHash_PC_LIBDIR} ${xxHash_PC_LIBRARY_DIRS}
    )

    include(FindPackageHandleStandardArgs)
    find_package_handle_standard_args(
        ${CMAKE_FIND_PACKAGE_NAME}
        REQUIRED_VARS xxHash_LIBRARY xxHash_INCLUDE_DIR
        VERSION_VAR xxHash_VERSION
    )
    set(xxHash_LIBRARIES ${xxHash_LIBRARY})
    set(xxHash_INCLUDE_DIRS ${xxHash_INCLUDE_DIR})

else()
    message(STATUS "xxHash: libxxhash was not found via find_package() via FindxxHash.cmake module via PkgConfig.")
endif()

mark_as_advanced(
    xxHash_LIBRARY
    xxHash_INCLUDE_DIR
)
