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

option(ENABLE_MBEDTLS "" OFF)
set(ENABLE_NETTLE OFF) # UNSUPPORTED and therefore forced OFF (reason: does not support CMake)
option(ENABLE_OPENSSL "" ON)


option(ENABLE_BZip2 "" ON)
option(ENABLE_ZLIB "" ON)
option(ENABLE_LZMA "" ON)
option(ENABLE_ZSTD "" ON)

option(ENABLE_LZ4 "" ON)


option(ENABLE_ICONV "" OFF)
option(ENABLE_TAR "" OFF)
option(ENABLE_CPIO "" OFF)
option(ENABLE_CAT "" OFF)


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

# Try to just find libarchive, if found its all good
if(libarchive_superbuild_USE_LOCAL_PACKAGES)
    find_package(LibArchive OPTIONAL GLOBAL)
endif()

# Execute the following only if either A) we don't want to use local packages (at all) or B) we want to use them but 'LibArchive' package wasn't found
if(NOT LibArchive_FOUND)

    #####################################################################
    ### Obtain baseline dependencies ###
    #####################################################################
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
        if(libarchive_superbuild_USE_LOCAL_PACKAGES)
            find_package(OpenSSL OPTIONAL)
        endif()

        if(NOT OpenSSL_FOUND)
            # We need to test for some programs here:
            # jom  
            # strawberryperl
            # nasm

            CPMAddPackage(
                URI "gh:jimmy-park/openssl-cmake@3.6"
                OPTIONS
                "BUILD_SHARED_LIBS OFF"
                "OPENSSL_TEST OFF"
            )
        endif()
    endif()

    #####################################################################
    ### Obtain compression library dependencies ###
    #####################################################################
    if(ENABLE_ZLIB)
        if(libarchive_superbuild_USE_LOCAL_PACKAGES)
            find_package(ZLIB OPTIONAL)
        endif()

        if(NOT ZLIB_FOUND)
            CPMAddPackage(
                URI "gh:tukaani-project/xz@5.8.2"
                OPTIONS
                "BUILD_SHARED_LIBS OFF"
                "ENABLE_NLS OFF"
                "XZ_TOOL_XZDEC OFF"
                "XZ_TOOL_LZMADEC OFF"
                "XZ_TOOL_LZMAINFO OFF"
                "XZ_TOOL_XZ OFF"
                "XZ_TOOL_XZDEC OFF"
                "XZ_TOOL_SCRIPTS OFF"
                "XZ_DOXYGEN OFF"
                "XZ_DOC OFF"
                NAME xz
            )
        endif()
    endif()

    if(ENABLE_LZMA)
        if(libarchive_superbuild_USE_LOCAL_PACKAGES)
            find_package(LibLZMA OPTIONAL)
        endif()

        if(NOT LibLZMA_FOUND)
            CPMAddPackage(
                URI "gh:tukaani-project/xz@5.8.2"
                OPTIONS
                "BUILD_SHARED_LIBS OFF"
                "ENABLE_NLS OFF"
                "XZ_TOOL_XZDEC OFF"
                "XZ_TOOL_LZMADEC OFF"
                "XZ_TOOL_LZMAINFO OFF"
                "XZ_TOOL_XZ OFF"
                "XZ_TOOL_XZDEC OFF"
                "XZ_TOOL_SCRIPTS OFF"
                "XZ_DOXYGEN OFF"
                "XZ_DOC OFF"
                NAME xz
            )

            # This is a hack to trick the ancient-style CMakeLists script in libarchive
            set(LIBLZMA_LIBRARY liblzma)
            set(LIBLZMA_INCLUDE_DIR ${xz_SOURCE_DIR}/src/liblzma/api)
            set(LIBLZMA_FOUND TRUE)
        endif()
    endif()







    #####################################################################
    ### Obtain libarchive ###
    #####################################################################
    CPMAddPackage(
        URI "gh:libarchive/libarchive@3.8.5"
        OPTIONS
        "ENABLE_OPENSSL OFF"
        "ENABLE_LIBB2 OFF"
        "ENABLE_LZ4 OFF"
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
        NAME LibArchive
    )

    if(BUILD_SHARED_LIBS)
        add_library(LibArchive::LibArchive ALIAS archive)
    else()
        add_library(LibArchive::LibArchive ALIAS archive_static)
    endif()
endif()

add_library(testLib src/main.cpp)
target_link_libraries(testLib PUBLIC LibArchive::LibArchive)
