cmake_minimum_required(VERSION 3.30...4.2)

project(libarchive_superbuild
    HOMEPAGE_URL "https://github.com/InCom-0/libarchive_superbuild"
    DESCRIPTION
    "Pure CMake wrap around libarchive that can include and build the libarchive dependencies that are not available on your system (eg. useful for native windows builds and other niche cases)"
    LANGUAGES C CXX
)

set(CMAKE_CXX_SCAN_FOR_MODULES OFF)
option(BUILD_SHARED_LIBS "Build shared libraries" OFF)
option(libarchive_superbuild_STAGE_OUTPUTS "Stage build output artifacts into proper directory structure" ON)

option(libarchive_superbuild_USE_LOCAL_PACKAGES "Use local (usually system installed) packages for dependencies." OFF)
option(libarchive_superbuild_USE_LOCAL_PACKAGES_ONLY "Forbid the build system from downloading missing dependencies." OFF)

if(NOT DEFINED CPM_USE_LOCAL_PACKAGES)
    set(CPM_USE_LOCAL_PACKAGES ${libarchive_superbuild_USE_LOCAL_PACKAGES} CACHE BOOL "CPM will try to find packages locally first" FORCE)
endif()
if(NOT DEFINED CPM_LOCAL_PACKAGES_ONLY)
    set(CPM_LOCAL_PACKAGES_ONLY ${libarchive_superbuild_USE_LOCAL_PACKAGES_ONLY} CACHE BOOL
        "CPM will not be forbidden from downloading packages. Will have to use local packages." FORCE)
endif()

# Baseline dependencies
option(ENABLE_MBEDTLS "" OFF)
set(ENABLE_NETTLE OFF) # UNSUPPORTED and therefore forced OFF (reason: does not support CMake)
option(ENABLE_OPENSSL "" OFF) # Wierd errors on MSVC as well as MSYS2 ... both seem fixable though

# Hash related dependencies
option(ENABLE_LIBB2 "" OFF) # UNSUPPORTED and therefore forced OFF (reason: does not support CMake)
option(ENABLE_LZ4 "" ON)
option(ENABLE_LZO "" ON) # Need to turn off before release
option(ENABLE_LZMA "" ON)
option(ENABLE_ZSTD "" ON)

option(ENABLE_ZLIB "" ON)
option(ENABLE_BZip2 "" ON)
option(ENABLE_LIBXML2 "" OFF) # UNSUPPORTED for now (reason: requires inconv which is not really available everywhere)


option(ENABLE_LZ4 "" ON)


option(ENABLE_ICONV "" OFF)
option(ENABLE_TAR "" OFF)
option(ENABLE_CPIO "" OFF)
option(ENABLE_CAT "" OFF)


include(cmake/CPM.cmake)

### This attempts to compile sample program to find out if we are using libc++(USING_LIBCXX) or libstdc++(USING_LIBSTDCXX) or MSVC_STL(USING_MSVC_STL)
include(cmake/stdlibQuery.cmake)


#-----------------------------------------------------------------------------
# Staging
#-----------------------------------------------------------------------------
include(cmake/StageOutputs.cmake)
if(libarchive_superbuild_STAGE_OUTPUTS)
    stageOutputDirsFor(libarchive_superbuild)
endif()


#-----------------------------------------------------------------------------
# Target specification
#-----------------------------------------------------------------------------

# Try to just find libarchive, if found its all good
if(libarchive_superbuild_USE_LOCAL_PACKAGES_ONLY)
    find_package(LibArchive OPTIONAL GLOBAL)
endif()

# Execute the following only if either A) we don't want to use local packages (at all) or B) we want to use them but 'LibArchive' package wasn't found
if(NOT LibArchive_FOUND)

    #-----------------------------------------------------------------------------
    # Obtain baseline dependencies 
    #-----------------------------------------------------------------------------
    if(ENABLE_MBEDTLS)
        if(libarchive_superbuild_USE_LOCAL_PACKAGES)
            find_package(MbedTLS OPTIONAL CONFIG)
        endif()

        if(NOT MbedTLS_FOUND)
            CPMAddPackage(
                URI "gh:Mbed-TLS/mbedtls@4.0.0"
                OPTIONS
                "ENABLE_TESTING OFF"
                "ENABLE_PROGRAMS OFF"
            )
        endif()
    endif()

    if(ENABLE_OPENSSL)
        if(CMAKE_SYSTEM_NAME MATCHES "Darwin")
            message(STATUS "OpenSSL is deprecated on MacOS - Disabling finding and/or building it")
        else()
            if(libarchive_superbuild_USE_LOCAL_PACKAGES)
                find_package(OpenSSL OPTIONAL)
            endif()

            if(NOT OpenSSL_FOUND)
                # We need to test for some programs here:
                # jom  
                # strawberryperl
                # nasm

                set(OPENSSL_CONFIGURE_TOOL "C:/msys64/usr/bin/perl.exe")
                CPMAddPackage(
                    URI "gh:jimmy-park/openssl-cmake#3.6.0"
                    OPTIONS
                    "OPENSSL_TARGET_VERSION 3.6.1"
                    "BUILD_SHARED_LIBS OFF"
                    "OPENSSL_TEST OFF"

                )
            endif()
        endif()
    endif()

    #-----------------------------------------------------------------------------
    # Obtain compression library dependencies
    #-----------------------------------------------------------------------------
    if(ENABLE_LZ4)
        if(libarchive_superbuild_USE_LOCAL_PACKAGES)
            if(USING_MSVC_STL)
                find_package(lz4 OPTIONAL CONFIG)
            else()
                find_path(LZ4_INCLUDE_DIR lz4.h)
                find_library(LZ4_LIBRARY NAMES lz4 liblz4)
                include(FindPackageHandleStandardArgs)
                find_package_handle_standard_args(lz4 DEFAULT_MSG LZ4_LIBRARY LZ4_INCLUDE_DIR)
            endif()
        endif()

        if((NOT lz4_FOUND))
            CPMAddPackage(
                URI "gh:lz4/lz4@1.10.0"
                SOURCE_SUBDIR build/cmake
                OPTIONS
                "BUILD_SHARED_LIBS OFF"
                "BUILD_STATIC_LIBS ON"
                "LZ4_BUILD_CLI OFF"
                NAME lz4
            )
            # This is a hack to trick the ancient-style CMakeLists script in libarchive
            set(LZ4_LIBRARY lz4)
            set(LZ4_INCLUDE_DIR ${lz4_SOURCE_DIR}/lib)
            find_package_handle_standard_args(LZ4 DEFAULT_MSG LZ4_LIBRARY LZ4_INCLUDE_DIR)

            if(NOT LZ4_FOUND)
                message(FATAL_ERROR "lz4: CMake was not successful is obtaining and setting up lz4 using CPM (attempt to build from source).
                 This should never happen unless the underlying repo is broken or otherwise made incompatible.")
            endif()

        endif()
    endif()

    if(ENABLE_LZO)
        if(libarchive_superbuild_USE_LOCAL_PACKAGES)
            if(USING_MSVC_STL)
                find_package(lzo2 OPTIONAL CONFIG)
            else()
                find_path(LZO2_INCLUDE_DIR lzo/lzoconf.h)
                find_library(LZO2_LIBRARY NAMES lzo2 liblzo2)
                include(FindPackageHandleStandardArgs)
                find_package_handle_standard_args(lzo2 DEFAULT_MSG LZO2_LIBRARY LZO2_INCLUDE_DIR)
            endif()
        endif()

        if(NOT lzo2_FOUND)
            CPMAddPackage(
                URL http://www.oberhumer.com/opensource/lzo/download/lzo-2.10.tar.gz
                URL_HASH SHA256=c0f892943208266f9b6543b3ae308fab6284c5c90e627931446fb49b4221a072
                OPTIONS
                "ENABLE_STATIC ON"
                "ENABLE_SHARED OFF"
                NAME lzo2
            )
            # This is a hack to trick the ancient-style CMakeLists script in libarchive
            set(LZO2_LIBRARY lzo_static_lib)
            set(LZO2_INCLUDE_DIR ${lzo2_SOURCE_DIR}/include)
            find_package_handle_standard_args(LZO2 DEFAULT_MSG LZO2_LIBRARY LZO2_INCLUDE_DIR)
            if(NOT LZO2_FOUND)
                message(FATAL_ERROR "lzo2: CMake was not successful is obtaining and setting up lzo2 using CPM (attempt to build from source).
                 This should never happen unless the underlying repo is broken or otherwise made incompatible.")
            endif()
        endif()
    endif()

    if(ENABLE_LZMA)
        if(libarchive_superbuild_USE_LOCAL_PACKAGES)
            find_package(LibLZMA OPTIONAL)
        endif()

        # set(LZMA_API_STATIC ON)
        if(NOT LibLZMA_FOUND)
            CPMAddPackage(
                URI "gh:tukaani-project/xz@5.8.2"
                OPTIONS
                "BUILD_SHARED_LIBS OFF"
                "LZMA_API_STATIC ON"
                "ENABLE_NLS OFF"
                "XZ_TOOL_XZDEC OFF"
                "XZ_TOOL_LZMADEC OFF"
                "XZ_TOOL_LZMAINFO OFF"
                "XZ_TOOL_XZ OFF"
                "XZ_TOOL_XZDEC OFF"
                "XZ_TOOL_SCRIPTS OFF"
                "XZ_DOXYGEN OFF"
                "XZ_DOC OFF"
                NAME LibLZMA
            )

            # This is a hack to trick the ancient-style CMakeLists script in libarchive
            set(LIBLZMA_LIBRARY liblzma)
            set(LIBLZMA_LIBRARIES liblzma)
            set(LIBLZMA_INCLUDE_DIR ${xz_SOURCE_DIR}/src/liblzma/api)
            set(LIBLZMA_INCLUDE_DIRS ${xz_SOURCE_DIR}/src/liblzma/api)
            find_package_handle_standard_args(LIBLZMA DEFAULT_MSG LIBLZMA_LIBRARY LIBLZMA_INCLUDE_DIR)

            if(NOT LIBLZMA_FOUND)
                message(FATAL_ERROR "LibLZMA: CMake was not successful is obtaining and setting up LibLZMA using CPM (attempt to build from source).
                 This should never happen unless the underlying repo is broken or otherwise made incompatible.")
            endif()
        endif()
    endif()

    if(ENABLE_ZSTD)
        if(libarchive_superbuild_USE_LOCAL_PACKAGES)
            if(USING_MSVC_STL)
                find_package(zstd OPTIONAL CONFIG)
            else()
                find_path(ZSTD_INCLUDE_DIR zstd.h)
                find_library(ZSTD_LIBRARY NAMES zstd libzstd)
                include(FindPackageHandleStandardArgs)
                find_package_handle_standard_args(zstd DEFAULT_MSG ZSTD_LIBRARY ZSTD_INCLUDE_DIR)
            endif()
        endif()

        if(NOT zstd_FOUND)
            CPMAddPackage(
                URI "gh:facebook/zstd@1.5.7"
                SOURCE_SUBDIR build/cmake
                OPTIONS
                "ZSTD_BUILD_STATIC ON"
                "ZSTD_BUILD_SHARED OFF"
                "ZSTD_BUILD_PROGRAMS OFF"
                "ZSTD_BUILD_CONTRIB OFF"
                "ZSTD_BUILD_TESTS OFF"
                NAME zstd
            )
            # This is a hack to trick the ancient-style CMakeLists script in libarchive
            set(ZSTD_LIBRARY libzstd)
            set(ZSTD_INCLUDE_DIR ${lzo2_SOURCE_DIR}/include)
            find_package_handle_standard_args(ZSTD DEFAULT_MSG ZSTD_LIBRARY ZSTD_INCLUDE_DIR)
            if(NOT ZSTD_FOUND)
                message(FATAL_ERROR "zstd: CMake was not successful is obtaining and setting up zstd using CPM (attempt to build from source).
                 This should never happen unless the underlying repo is broken or otherwise made incompatible.")
            endif()
        endif()
    endif()



    if(ENABLE_ZLIB)
        if(libarchive_superbuild_USE_LOCAL_PACKAGES)
            find_package(ZLIB OPTIONAL)
        endif()

        if(NOT ZLIB_FOUND)
            CPMAddPackage(
                URI "gh:madler/zlib@1.3.1.2"
                OPTIONS
                "ZLIB_BUILD_SHARED OFF"
                "ZLIB_BUILD_STATIC ON"
                "ZLIB_INSTALL OFF"
                "ZLIB_INSTALL_COMPAT_DLL OFF"
                "ZLIB_BUILD_TESTING OFF"
                "ZLIB_BUILD_MINIZIP OFF"
                NAME ZLIB
            )
            # This is a hack to trick the ancient-style CMakeLists script in libarchive
            set(ZLIB_LIBRARY zlibstatic)
            set(ZLIB_LIBRARIES ${ZLIB_LIBRARY})
            set(ZLIB_INCLUDE_DIR ${zlib_SOURCE_DIR})
            find_package_handle_standard_args(ZLIB DEFAULT_MSG ZLIB_LIBRARY ZLIB_INCLUDE_DIR)

            if(NOT ZLIB_FOUND)
                message(FATAL_ERROR "ZLIB: CMake was not successful is obtaining and setting up ZLIB using CPM (attempt to build from source).
                 This should never happen unless the underlying repo is broken or otherwise made incompatible.")
            endif()
        endif()
    endif()






    #-----------------------------------------------------------------------------
    # Obtain libarchive
    #-----------------------------------------------------------------------------
    CPMAddPackage(
        URI "gh:libarchive/libarchive@3.8.5"
        OPTIONS
        "ENABLE_LIBB2 OFF"
        "ENABLE_EXPAT OFF"
        "ENABLE_ICONV OFF"
        # "ENABLE_LIBGCC OFF"
        # "ENABLE_PCREPOSIX OFF"
        # "ENABLE_PCRE2POSIX OFF"
        # "LIBLZMA_INCLUDE_DIRS ${LibLZMA_SOURCE_DIR}/src/liblzma/api"
        # "LIBLZMA_LIBRARIES liblzma"
        "ENABLE_TAR OFF"
        "ENABLE_CPIO OFF"
        "ENABLE_CAT OFF"
        "ENABLE_UNZIP OFF"
        "ENABLE_TEST OFF"
        "ENABLE_INSTALL OFF"
        NAME LibArchive_LOCAL
    )

    if(BUILD_SHARED_LIBS)
        add_library(LibArchive::LibArchive ALIAS archive)
        if(openssl-cmake_ADDED)
            add_dependencies(archive OpenSSL::Crypto)
        endif()
    else()
        add_library(LibArchive::LibArchive ALIAS archive_static)
        if(openssl-cmake_ADDED)
            add_dependencies(archive_static OpenSSL::Crypto)
        endif()

    endif()
endif()

add_library(testLib src/main.cpp)
target_link_libraries(testLib PUBLIC LibArchive::LibArchive)
