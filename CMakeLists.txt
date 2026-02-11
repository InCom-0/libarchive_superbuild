cmake_minimum_required(VERSION 3.30...4.2)

# TODO: There is a wierd problem with the 'NAME' parameter ... so far it seems that for some reason it has to be 'LibArchive' when including libarchive_superbuild
project(libarchive_superbuild
    HOMEPAGE_URL "https://github.com/InCom-0/libarchive_superbuild"
    DESCRIPTION
    "Pure CMake wrap/superbuild around libarchive that can include and build the libarchive dependencies that are not available on the user's system (eg. useful for native windows builds and various niche cases)"
    LANGUAGES C CXX
)

set(CMAKE_CXX_SCAN_FOR_MODULES OFF)
option(BUILD_SHARED_LIBS "Build shared libraries" OFF)
option(libarchive_sb_STAGE_OUTPUTS "Stage build output artifacts into proper directory structure" ${PROJECT_IS_TOP_LEVEL})

option(libarchive_sb_USE_LOCAL_PACKAGES "Use local (usually system installed) packages for dependencies." ON)
option(libarchive_sb_USE_LOCAL_PACKAGES_ONLY "Forbid the build system from downloading missing dependencies." OFF)


# Baseline dependencies
option(ENABLE_MBEDTLS "" ON)
set(ENABLE_NETTLE OFF) # UNSUPPORTED and therefore OFF (reason: does not support CMake)
option(ENABLE_OPENSSL "" OFF) # Wierd errors on MSVC as well as MSYS2 ... both seem fixable though

# Hash related dependencies
option(ENABLE_LIBB2 "" OFF) # UNSUPPORTED and therefore OFF (reason: does not support CMake)
option(ENABLE_LZ4 "" ON)
option(ENABLE_LZO "" OFF) # Need to turn off before release
option(ENABLE_LZMA "" ON)
option(ENABLE_ZSTD "" ON)

option(ENABLE_ZLIB "" ON)
option(ENABLE_BZip2 "" OFF) # UNIMPLEMENTED

# Sequencial usage by libarchive: Uses LIBXML2 if available, if not tries EXPAT, if not tries WIN32_XMLITE
# Settings here should reflect that, as only one will ever get linked in libarchive
option(ENABLE_LIBXML2 "" OFF) # UNSUPPORTED for now and therefore OFF (reason: requires inconv which is not really available everywhere)
option(ENABLE_ICONV "" ${ENABLE_LIBXML2}) # This is used for LIBXML2, if libiconv is disabled then LIBXML2 won't be linked (or otherwise obtained)
option(ENABLE_EXPAT "" OFF) # UNIMPLEMENTED
option(ENABLE_PCREPOSIX "" OFF) # UNIMPLEMENTED. This should not be used in this day and age
option(ENABLE_PCRE2POSIX "" OFF) # UNIMPLEMENTED
option(ENABLE_LIBGCC "" ON)
option(ENABLE_WIN32_XMLLITE "" ON) # Nothing to implement ... we think (reason: only available on native Windows)
option(ENABLE_CNG "" ON) # Nothing to implement ... we think (reason: only available on native Windows)

option(libarchive_sb_XATTR "Enable extended attribute support" OFF) # UNSUPPORTED and therefore forced OFF (reason: only available on Linux)
option(libarchive_sb_ACL "Enable ACL support" OFF) # UNSUPPORTED and therefore forced OFF (reason: only available on Linux)

# Executables that are otherwise built by the libarchive project
option(ENABLE_TAR "" OFF)
option(ENABLE_CPIO "" OFF)
option(ENABLE_CAT "" OFF)
option(ENABLE_UNZIP "" OFF)

# Other settings - we don't want to inherit the settings from projects that include libarchive_superbuild
option(libarchive_sb_ENABLE_TEST "Passed to libarchive" OFF)
option(libarchive_sb_ENABLE_COVERAGE "Passed to libarchive" OFF)
option(libarchive_sb_ENABLE_INSTALL "Passed to libarchive" OFF) # UNSUPPORTED and therefore forced OFF (reason: not the goal of this project to allow that)

# Forces using CPM to obtain the package (regardless of other settings)
option(libarchive_sb_LIBARCHIVE_FORCE_CPM "" OFF)

option(libarchive_sb_MBEDTLS_FORCE_CPM "" OFF)
option(libarchive_sb_OPENSSL_FORCE_CPM "" OFF)

option(libarchive_sb_LIBB2_FORCE_CPM "" OFF)
option(libarchive_sb_LZ4_FORCE_CPM "" OFF)
option(libarchive_sb_LZO_FORCE_CPM "" OFF)
option(libarchive_sb_LZMA_FORCE_CPM "" OFF)
option(libarchive_sb_ZSTD_FORCE_CPM "" OFF)

option(libarchive_sb_ZLIB_FORCE_CPM "" OFF)
option(libarchive_sb_BZip2_FORCE_CPM "" OFF)

option(libarchive_sb_LIBXML2_FORCE_CPM "" OFF)


option(libarchive_sb_ENABLE_INTERNAL_TESTS "Enable building some libraries and executables used for testing whether they ca link to LibArchive::LibArchive target." OFF)


include(cmake/CPM.cmake)

### This attempts to compile sample program to find out if we are using libc++(USING_LIBCXX) or libstdc++(USING_LIBSTDCXX) or MSVC_STL(USING_MSVC_STL)
include(cmake/stdlibQuery.cmake)


#-----------------------------------------------------------------------------
# Staging
#-----------------------------------------------------------------------------
include(cmake/StageOutputs.cmake)
if(libarchive_sb_STAGE_OUTPUTS)
    stageOutputDirsFor(libarchive_sb)
endif()


#-----------------------------------------------------------------------------
# Target specification
#-----------------------------------------------------------------------------
set(CPM_USE_LOCAL_PACKAGES OFF) # Forbid CPM performing find_package (we do this manually because the underlying libraries are not really 'modern CMake friendly')

# This is prepared so that we can pass it to depedent libraries easier
if(BUILD_SHARED_LIBS)
    set(libarchive_sb_BUILD_SHARED_LIBS ON)
    set(libarchive_sb_BUILD_STATIC_LIBS OFF)
else()
    set(libarchive_sb_BUILD_SHARED_LIBS OFF)
    set(libarchive_sb_BUILD_STATIC_LIBS ON)
endif()


# Try to just find libarchive, if found its all good
if(libarchive_sb_USE_LOCAL_PACKAGES AND (NOT libarchive_sb_LIBARCHIVE_FORCE_CPM))
    find_package(LibArchive GLOBAL)
endif()

# Execute the following only if either A) we don't want to use local packages (at all) or B) we want to use them but 'LibArchive' package wasn't found
if(NOT LibArchive_FOUND)

    #-----------------------------------------------------------------------------
    # Obtain baseline dependencies 
    #-----------------------------------------------------------------------------
    if(ENABLE_MBEDTLS)
        if(libarchive_sb_USE_LOCAL_PACKAGES AND (NOT libarchive_sb_MBEDTLS_FORCE_CPM))
            find_package(MbedTLS CONFIG)
            if(NOT MbedTLS_FOUND)
                message(STATUS "MbedTLS: Not found using find_package(). Trying to download and build from source using CPM.")
            endif()
        endif()

        if(NOT MbedTLS_FOUND)
            if(libarchive_sb_USE_LOCAL_PACKAGES_ONLY AND (NOT libarchive_sb_MBEDTLS_FORCE_CPM))
                message(FATAL_ERROR "MbedTLS: Trying to download when 'libarchive_sb_USE_LOCAL_PACKAGES_ONLY' is set to a truthy value; The package is missing (or otherwise CMake cannot find it)")
            endif()
            CPMAddPackage(
                URL https://github.com/Mbed-TLS/mbedtls/releases/download/mbedtls-4.0.0/mbedtls-4.0.0.tar.bz2
                URL_HASH SHA256=2f3a47f7b3a541ddef450e4867eeecb7ce2ef7776093f3a11d6d43ead6bf2827
                OPTIONS
                "USE_SHARED_MBEDTLS_LIBRARY ${libarchive_sb_BUILD_SHARED_LIBS}"
                "USE_STATIC_MBEDTLS_LIBRARY ${libarchive_sb_BUILD_STATIC_LIBS}"
                "USE_SHARED_TF_PSA_CRYPTO_LIBRARY OFF"
                "USE_STATIC_TF_PSA_CRYPTO_LIBRARY ON"
                "ENABLE_TESTING OFF"
                "ENABLE_PROGRAMS OFF"
                EXCLUDE_FROM_ALL TRUE
                NAME MbedTLS
            )
            # This is a hack to trick the ancient-style CMakeLists script in libarchive
            # LibArchive later runs tests against existence of includes which fail ...
            # ... this is ok since we trick it to link first class CMake target 'tfpsacrypto' which has the includes attached as part of 'BUILD_INTERFACE'

            set(MBEDTLS_INCLUDE_DIRS ${MbedTLS_SOURCE_DIR}/include)
            set(MBEDTLS_LIBRARY MbedTLS::mbedtls)
            set(MBEDX509_LIBRARY MbedTLS::mbedx509)
            set(MBEDCRYPTO_LIBRARY tfpsacrypto)
            find_package_handle_standard_args(TFPSACRYPTO DEFAULT_MSG MBEDCRYPTO_LIBRARY)
            if(NOT TFPSACRYPTO_FOUND)
                message(FATAL_ERROR "MbedTLS: CMake was not successful is obtaining and setting up MbedTLS using CPM (attempt to build from source).
                 This should never happen unless the upstream repo is broken or otherwise made incompatible.")
            else()
                set(MBEDTLS_FOUND TRUE)
            endif()

        endif()
    endif()

    if(ENABLE_OPENSSL)
        if(CMAKE_SYSTEM_NAME MATCHES "Darwin")
            message(STATUS "OpenSSL is deprecated on MacOS - Disabling finding and/or building it")
        else()
            if(libarchive_sb_USE_LOCAL_PACKAGES AND (NOT libarchive_sb_OPENSSL_FORCE_CPM))
                find_package(OpenSSL)
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
        if(libarchive_sb_USE_LOCAL_PACKAGES AND (NOT libarchive_sb_LZ4_FORCE_CPM))
            if(USING_MSVC_STL)
                find_package(lz4 CONFIG)
            else()
                find_path(LZ4_INCLUDE_DIR lz4.h)
                find_library(LZ4_LIBRARY NAMES lz4 liblz4)
                include(FindPackageHandleStandardArgs)
                find_package_handle_standard_args(lz4 DEFAULT_MSG LZ4_LIBRARY LZ4_INCLUDE_DIR)
            endif()
        endif()

        if((NOT lz4_FOUND))
            if(libarchive_sb_USE_LOCAL_PACKAGES_ONLY AND (NOT libarchive_sb_LZ4_FORCE_CPM))
                message(FATAL_ERROR "lz4: Trying to download when 'libarchive_sb_USE_LOCAL_PACKAGES_ONLY' is set to a truthy value; The package is missing (or otherwise CMake cannot find it)")
            endif()
            CPMAddPackage(
                URI "gh:lz4/lz4@1.10.0"
                SOURCE_SUBDIR build/cmake
                OPTIONS
                "BUILD_SHARED_LIBS ${libarchive_sb_BUILD_SHARED_LIBS}"
                "BUILD_STATIC_LIBS ${libarchive_sb_BUILD_STATIC_LIBS}"
                "LZ4_BUILD_CLI OFF"
                NAME lz4
            )
            # This is a hack to trick the ancient-style CMakeLists script in libarchive
            set(LZ4_LIBRARY lz4)
            set(LZ4_INCLUDE_DIR ${lz4_SOURCE_DIR}/lib)
            find_package_handle_standard_args(LZ4 DEFAULT_MSG LZ4_LIBRARY LZ4_INCLUDE_DIR)

            if(NOT LZ4_FOUND)
                message(FATAL_ERROR "lz4: CMake was not successful is obtaining and setting up lz4 using CPM (attempt to build from source).
                 This should never happen unless the upstream repo is broken or otherwise made incompatible.")
            endif()

        endif()
    endif()

    if(ENABLE_LZO)
        if(libarchive_sb_USE_LOCAL_PACKAGES AND (NOT libarchive_sb_LZO_FORCE_CPM))
            if(USING_MSVC_STL)
                find_package(lzo2 CONFIG)
            else()
                find_path(LZO2_INCLUDE_DIR lzo/lzoconf.h)
                find_library(LZO2_LIBRARY NAMES lzo2 liblzo2)
                include(FindPackageHandleStandardArgs)
                find_package_handle_standard_args(lzo2 DEFAULT_MSG LZO2_LIBRARY LZO2_INCLUDE_DIR)
            endif()
        endif()

        if(NOT lzo2_FOUND)
            if(libarchive_sb_USE_LOCAL_PACKAGES_ONLY AND (NOT libarchive_sb_LZO_FORCE_CPM))
                message(FATAL_ERROR "lzo2: Trying to download when 'libarchive_sb_USE_LOCAL_PACKAGES_ONLY' is set to a truthy value; The package is missing (or otherwise CMake cannot find it)")
            endif()
            CPMAddPackage(
                URL http://www.oberhumer.com/opensource/lzo/download/lzo-2.10.tar.gz
                URL_HASH SHA256=c0f892943208266f9b6543b3ae308fab6284c5c90e627931446fb49b4221a072
                OPTIONS
                "ENABLE_STATIC ${libarchive_sb_BUILD_STATIC_LIBS}"
                "ENABLE_SHARED ${libarchive_sb_BUILD_SHARED_LIBS}"
                NAME lzo2
            )
            # This is a hack to trick the ancient-style CMakeLists script in libarchive
            set(LZO2_LIBRARY lzo_static_lib)
            set(LZO2_INCLUDE_DIR ${lzo2_SOURCE_DIR}/include)
            find_package_handle_standard_args(LZO2 DEFAULT_MSG LZO2_LIBRARY LZO2_INCLUDE_DIR)
            if(NOT LZO2_FOUND)
                message(FATAL_ERROR "lzo2: CMake was not successful is obtaining and setting up lzo2 using CPM (attempt to build from source).
                 This should never happen unless the upstream repo is broken or otherwise made incompatible.")
            endif()
        endif()
    endif()

    if(ENABLE_LZMA)
        if(libarchive_sb_USE_LOCAL_PACKAGES AND (NOT libarchive_sb_LZMA_FORCE_CPM))
            find_package(LibLZMA)
        endif()

        # set(LZMA_API_STATIC ON)
        if(NOT LibLZMA_FOUND)
            if(libarchive_sb_USE_LOCAL_PACKAGES_ONLY AND (NOT libarchive_sb_LZMA_FORCE_CPM))
                message(FATAL_ERROR "LibLZMA: Trying to download when 'libarchive_sb_USE_LOCAL_PACKAGES_ONLY' is set to a truthy value; The package is missing (or otherwise CMake cannot find it)")
            endif()
            set(CPM_USE_LOCAL_PACKAGES OFF) # Temporary hack that I should probably fix later
            CPMAddPackage(
                URI "gh:tukaani-project/xz@5.8.2"
                OPTIONS
                "BUILD_SHARED_LIBS ${libarchive_sb_BUILD_SHARED_LIBS}"
                "LZMA_API_STATIC ${libarchive_sb_BUILD_STATIC_LIBS}"
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
            unset(CPM_USE_LOCAL_PACKAGES) # Temporary hack that I should probably fix later

            # This is a hack to trick the ancient-style CMakeLists script in libarchive
            set(LIBLZMA_LIBRARY liblzma)
            set(LIBLZMA_LIBRARIES ${LIBLZMA_LIBRARY})
            set(LIBLZMA_INCLUDE_DIR ${LibLZMA_SOURCE_DIR}/src/liblzma/api)
            set(LIBLZMA_INCLUDE_DIRS ${LIBLZMA_INCLUDE_DIR})
            find_package_handle_standard_args(LIBLZMA DEFAULT_MSG LIBLZMA_LIBRARY LIBLZMA_INCLUDE_DIR)

            if(NOT LIBLZMA_FOUND)
                message(FATAL_ERROR "LibLZMA: CMake was not successful is obtaining and setting up LibLZMA using CPM (attempt to build from source).
                 This should never happen unless the upstream repo is broken or otherwise made incompatible.")
            endif()
        endif()
    endif()

    if(ENABLE_ZSTD)
        if(libarchive_sb_USE_LOCAL_PACKAGES AND (NOT libarchive_sb_ZSTD_FORCE_CPM))
            if(USING_MSVC_STL)
                find_package(zstd CONFIG)
            else()
                find_path(ZSTD_INCLUDE_DIR zstd.h)
                find_library(ZSTD_LIBRARY NAMES zstd libzstd)
                include(FindPackageHandleStandardArgs)
                find_package_handle_standard_args(zstd DEFAULT_MSG ZSTD_LIBRARY ZSTD_INCLUDE_DIR)
            endif()
        endif()

        if(NOT zstd_FOUND)
            if(libarchive_sb_USE_LOCAL_PACKAGES_ONLY AND (NOT libarchive_sb_ZSTD_FORCE_CPM))
                message(FATAL_ERROR "zstd: Trying to download when 'libarchive_sb_USE_LOCAL_PACKAGES_ONLY' is set to a truthy value; The package is missing (or otherwise CMake cannot find it)")
            endif()
            CPMAddPackage(
                URI "gh:facebook/zstd@1.5.7"
                SOURCE_SUBDIR build/cmake
                OPTIONS
                "ZSTD_BUILD_STATIC ${libarchive_sb_BUILD_STATIC_LIBS}"
                "ZSTD_BUILD_SHARED ${libarchive_sb_BUILD_SHARED_LIBS}"
                "ZSTD_BUILD_PROGRAMS OFF"
                "ZSTD_BUILD_CONTRIB OFF"
                "ZSTD_BUILD_TESTS OFF"
                NAME zstd
            )
            # This is a hack to trick the ancient-style CMakeLists script in libarchive
            set(ZSTD_LIBRARY libzstd)
            set(ZSTD_INCLUDE_DIR ${zstd_SOURCE_DIR}/include)
            find_package_handle_standard_args(ZSTD DEFAULT_MSG ZSTD_LIBRARY ZSTD_INCLUDE_DIR)
            if(NOT ZSTD_FOUND)
                message(FATAL_ERROR "zstd: CMake was not successful is obtaining and setting up zstd using CPM (attempt to build from source).
                 This should never happen unless the upstream repo is broken or otherwise made incompatible.")
            endif()
        endif()
    endif()


    if(ENABLE_ZLIB)
        if(libarchive_sb_USE_LOCAL_PACKAGES AND (NOT libarchive_sb_ZLIB_FORCE_CPM))
            find_package(ZLIB)
        endif()

        if(NOT ZLIB_FOUND)
            if(libarchive_sb_USE_LOCAL_PACKAGES_ONLY AND (NOT libarchive_sb_ZLIB_FORCE_CPM))
                message(FATAL_ERROR "ZLIB: Trying to download when 'libarchive_sb_USE_LOCAL_PACKAGES_ONLY' is set to a truthy value; The package is missing (or otherwise CMake cannot find it)")
            endif()
            CPMAddPackage(
                URI "gh:madler/zlib@1.3.1.2"
                OPTIONS
                "ZLIB_BUILD_SHARED ${libarchive_sb_BUILD_SHARED_LIBS}"
                "ZLIB_BUILD_STATIC ${libarchive_sb_BUILD_STATIC_LIBS}"
                "ZLIB_INSTALL OFF"
                "ZLIB_INSTALL_COMPAT_DLL OFF"
                "ZLIB_BUILD_TESTING OFF"
                "ZLIB_BUILD_MINIZIP OFF"
                NAME ZLIB
            )
            # This is a hack to trick the ancient-style CMakeLists script in libarchive
            set(ZLIB_LIBRARY zlibstatic)
            set(ZLIB_LIBRARIES ${ZLIB_LIBRARY})
            set(ZLIB_INCLUDE_DIR ${ZLIB_SOURCE_DIR})
            find_package_handle_standard_args(ZLIB DEFAULT_MSG ZLIB_LIBRARY ZLIB_INCLUDE_DIR)

            if(NOT ZLIB_FOUND)
                message(FATAL_ERROR "ZLIB: CMake was not successful is obtaining and setting up ZLIB using CPM (attempt to build from source).
                 This should never happen unless the upstream repo is broken or otherwise made incompatible.")
            endif()
        endif()
    endif()



    #-----------------------------------------------------------------------------
    # Obtain libarchive
    #-----------------------------------------------------------------------------
    if(libarchive_sb_USE_LOCAL_PACKAGES_ONLY AND (NOT libarchive_sb_LIBARCHIVE_FORCE_CPM))
        message(FATAL_ERROR "LibArchive: Trying to download when 'libarchive_sb_USE_LOCAL_PACKAGES_ONLY' is set to a truthy value; The package is missing (or otherwise CMake cannot find it)")
    endif()

    CPMAddPackage(
        URI "gh:libarchive/libarchive@3.8.5"
        OPTIONS
        "BUILD_SHARED_LIBS ${libarchive_sb_BUILD_SHARED_LIBS}"
        "ENABLE_LIBB2 OFF"
        "ENABLE_EXPAT OFF"
        # "ENABLE_LIBGCC OFF"
        # "ENABLE_PCREPOSIX OFF"
        # "ENABLE_PCRE2POSIX OFF"
        # "LIBLZMA_INCLUDE_DIRS ${LibLZMA_SOURCE_DIR}/src/liblzma/api"
        # "LIBLZMA_LIBRARIES liblzma"
        "ENABLE_XATTR ${libarchive_sb_XATTR}"
        "ENABLE_ACL ${libarchive_sb_ACL}"
        "ENABLE_TEST ${libarchive_sb_ENABLE_TEST}"
        "ENABLE_COVERAGE ${libarchive_sb_ENABLE_COVERAGE}"
        "ENABLE_INSTALL ${libarchive_sb_ENABLE_INSTALL}"
        NAME LibArchive
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

unset(CPM_USE_LOCAL_PACKAGES) # Unset local variable set at the top

if(libarchive_sb_ENABLE_INTERNAL_TESTS)
    add_executable(libarchive_sb_testExecutable src/main.cpp)
    target_link_libraries(libarchive_sb_testExecutable PUBLIC LibArchive::LibArchive)
endif()
