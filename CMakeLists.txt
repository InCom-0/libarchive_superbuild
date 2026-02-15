cmake_minimum_required(VERSION 3.30...4.2)

project(libarchive_superbuild
    HOMEPAGE_URL "https://github.com/InCom-0/libarchive_superbuild"
    DESCRIPTION
    "Pure CMake wrap/superbuild around libarchive that can include and build the libarchive dependencies that are not available on the user's system (eg. useful for native windows builds and various niche cases)"
    LANGUAGES C CXX
)

set(CMAKE_CXX_SCAN_FOR_MODULES OFF)
option(BUILD_SHARED_LIBS "Build shared libraries" OFF)
option(libarchive_sb_STAGE_OUTPUTS "Stage build output artifacts into proper directory structure" ${PROJECT_IS_TOP_LEVEL})

option(CPM_USE_LOCAL_PACKAGES "Use local (usually system installed) packages for dependencies." ON)
option(CPM_LOCAL_PACKAGES_ONLY "Forbid the build system from downloading missing dependencies." OFF)


# Baseline dependencies
option(ENABLE_MBEDTLS "" OFF)
set(ENABLE_NETTLE OFF) # UNSUPPORTED and therefore OFF (reason: does not support CMake)
option(ENABLE_OPENSSL "" OFF) # Wierd errors on MSVC as well as MSYS2 ... both seem fixable though

# Hash related dependencies
option(ENABLE_LIBB2 "" OFF) # UNSUPPORTED and therefore OFF (reason: does not support CMake)
option(ENABLE_LZ4 "" ON)
option(ENABLE_LZO "" ON) # Need to turn off before release
option(ENABLE_LZMA "" OFF)
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
option(libarchive_sb_LIBARCHIVE_FORCE_CPM "" ON)

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

### 
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules")


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
# set(CPM_USE_LOCAL_PACKAGES OFF) # Forbid CPM performing find_package (we do this manually because the underlying libraries are not really 'modern CMake friendly')

# This is prepared so that we can pass it to dependent libraries CPMAddPackage easier
if(BUILD_SHARED_LIBS)
    set(libarchive_sb_BUILD_SHARED_LIBS ON)
    set(libarchive_sb_BUILD_STATIC_LIBS OFF)
else()
    set(libarchive_sb_BUILD_SHARED_LIBS OFF)
    set(libarchive_sb_BUILD_STATIC_LIBS ON)
endif()


# Try to just find libarchive, if found its all good
if((CPM_LOCAL_PACKAGES_ONLY OR CPM_USE_LOCAL_PACKAGES) AND (NOT libarchive_sb_LIBARCHIVE_FORCE_CPM))
    find_package(LibArchive GLOBAL)
    if(NOT LibArchive_FOUND)
        if(CPM_LOCAL_PACKAGES_ONLY)
            message(FATAL_ERROR "libarchive_superbuild: LibArchive not (fully) found on the system. Eventhrough 'CPM_LOCAL_PACKAGES_ONLY' is set to TRUE.")
        endif()
        message(STATUS "libarchive_superbuild: LibArchive not (fully) found on the system. Proceeding to build from source.")
    endif()
else()
    message(STATUS "libarchive_superbuild: User requested LibArchive to be build from source, proceeding to check for dependencies.")
endif()

# Execute the following only if either A) we don't want to use local packages (at all) or B) we want to use them but 'LibArchive' package wasn't found
if(NOT LibArchive_FOUND)

    #-----------------------------------------------------------------------------
    # Obtain baseline dependencies 
    #-----------------------------------------------------------------------------
    if(ENABLE_MBEDTLS)
        if(lCPM_USE_LOCAL_PACKAGESS AND (NOT libarchive_sb_MBEDTLS_FORCE_CPM))
            find_package(MbedTLS CONFIG)
            if(NOT MbedTLS_FOUND)
                message(STATUS "MbedTLS: Not found using find_package(). Trying to download and build from source using CPM.")
            endif()
        endif()

        if(NOT MbedTLS_FOUND)
            if(CPM_LOCAL_PACKAGES_ONLY AND (NOT libarchive_sb_MBEDTLS_FORCE_CPM))
                message(FATAL_ERROR "MbedTLS: Trying to download when 'CPM_LOCAL_PACKAGES_ONLY' is set to a truthy value; The package is missing (or otherwise CMake cannot find it)")
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
            if(lCPM_USE_LOCAL_PACKAGESS AND (NOT libarchive_sb_OPENSSL_FORCE_CPM))
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
        CPMAddPackage(
            URI "gh:lz4/lz4@1.10.0"
            SOURCE_SUBDIR build/cmake
            OPTIONS
            "BUILD_SHARED_LIBS OFF"
            "BUILD_STATIC_LIBS ON"
            "LZ4_BUILD_CLI OFF"
            FORCE ${libarchive_sb_LZ4_FORCE_CPM}
            NAME LZ4
        )

        ### Note: LZ4 always builds as static lib when in 'bundled mode', which this is
        if(LZ4_ADDED)
            if(NOT TARGET lz4::lz4)
                add_library(lz4::lz4 ALIAS lz4_static)
                set(LZ4_INCLUDE_DIR ${LZ4_SOURCE_DIR}/lib)
                set(LZ4_LIBRARY lz4::lz4)
            endif()
        else()
        endif()
    endif()

    if(ENABLE_LZO)
        CPMAddPackage(
            URL http://www.oberhumer.com/opensource/lzo/download/lzo-2.10.tar.gz
            URL_HASH SHA256=c0f892943208266f9b6543b3ae308fab6284c5c90e627931446fb49b4221a072
            OPTIONS
            "ENABLE_STATIC ${libarchive_sb_BUILD_STATIC_LIBS}"
            "ENABLE_SHARED ${libarchive_sb_BUILD_SHARED_LIBS}"
            FORCE ${libarchive_sb_LZO_FORCE_CPM}
            NAME LZO2
        )
        if(LZO2_ADDED)
            if(NOT TARGET lzo2::lzo2)
                if(libarchive_sb_BUILD_STATIC_LIBS)
                    add_library(lzo2::lzo2 ALIAS lzo_static_lib)
                else()
                    add_library(lzo2::lzo2 ALIAS lzo_shared_lib)
                endif()
                set(LZO2_INCLUDE_DIR ${LZO2_SOURCE_DIR}/include)
                set(LZO2_LIBRARY lzo2::lzo2)
            endif()
        else()
        endif()
    endif()

    if(ENABLE_LZMA)
        if(lCPM_USE_LOCAL_PACKAGESS AND (NOT libarchive_sb_LZMA_FORCE_CPM))
            find_package(LibLZMA)
        endif()

        # set(LZMA_API_STATIC ON)
        if(NOT LibLZMA_FOUND)
            if(CPM_LOCAL_PACKAGES_ONLY AND (NOT libarchive_sb_LZMA_FORCE_CPM))
                message(FATAL_ERROR "LibLZMA: Trying to download when 'CPM_LOCAL_PACKAGES_ONLY' is set to a truthy value; The package is missing (or otherwise CMake cannot find it)")
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
        CPMAddPackage(
            URI "gh:facebook/zstd@1.5.7"
            SOURCE_SUBDIR build/cmake
            OPTIONS
            "ZSTD_BUILD_STATIC ${libarchive_sb_BUILD_STATIC_LIBS}"
            "ZSTD_BUILD_SHARED ${libarchive_sb_BUILD_SHARED_LIBS}"
            "ZSTD_BUILD_PROGRAMS OFF"
            "ZSTD_BUILD_CONTRIB OFF"
            "ZSTD_BUILD_TESTS OFF"
            FORCE ${libarchive_sb_ZSTD_FORCE_CPM}
            NAME zstd
        )
        if(zstd_ADDED)
            if(NOT TARGET zstd::libzstd)
                add_library(zstd::libzstd ALIAS libzstd)
                set(ZSTD_INCLUDE_DIR ${zstd_SOURCE_DIR}/lib)
                set(ZSTD_LIBRARY zstd::libzstd)
            endif()
        else()
        endif()
    endif()


    if(ENABLE_ZLIB)
        set(ZLIB_USE_STATIC_LIBS ${libarchive_sb_BUILD_STATIC_LIBS})
        CPMAddPackage(
            URI "gh:madler/zlib@1.3.1"
            OPTIONS
            "ZLIB_BUILD_SHARED ${libarchive_sb_BUILD_SHARED_LIBS}"
            "ZLIB_BUILD_STATIC ${libarchive_sb_BUILD_STATIC_LIBS}"
            "ZLIB_INSTALL OFF"
            "ZLIB_INSTALL_COMPAT_DLL OFF"
            "ZLIB_BUILD_TESTING OFF"
            "ZLIB_BUILD_MINIZIP OFF"
            FORCE ${libarchive_sb_ZLIB_FORCE_CPM}
            NAME ZLIB
        )

        if(ZLIB_ADDED)
            ### Hacks to make sure the build does not blow.
            ### Lbarchive tries to 'trial compile' linking to zlib which doesn't exist yet if we are building it
            ### These settings just plug in the results of that
            set(ZLIB_INCLUDE_DIR ${zstd_SOURCE_DIR})

            if(${libarchive_sb_BUILD_STATIC_LIBS})
                if(NOT TARGET ZLIB::ZLIB)
                    add_library(ZLIB::ZLIB ALIAS zlibstatic)
                endif()
                set(ZLIB_DLL FALSE)
                set(WITHOUT_ZLIB_DLL TRUE)

            else()
                if(NOT TARGET ZLIB::ZLIB)
                    add_library(ZLIB::ZLIB ALIAS zlib)
                endif()
                set(ZLIB_DLL TRUE)
                set(WITHOUT_ZLIB_DLL FALSE)

            endif()
            set(ZLIB_LIBRARIES ZLIB::ZLIB)

            if(USING_MSVC_STL)
                set(ZLIB_WINAPI TRUE)
            else()
                set(ZLIB_WINAPI FALSE)
            endif()

        else()
        endif()

        # This is a hack to trick the ancient-style CMakeLists script in libarchive
        # set(ZLIB_LIBRARY zlibstatic)
        # set(ZLIB_LIBRARIES ${ZLIB_LIBRARY})
        # set(ZLIB_INCLUDE_DIR ${ZLIB_SOURCE_DIR})
        # find_package_handle_standard_args(ZLIB DEFAULT_MSG ZLIB_LIBRARY ZLIB_INCLUDE_DIR)

    endif()



    #-----------------------------------------------------------------------------
    # Obtain libarchive
    #-----------------------------------------------------------------------------
    if(CPM_LOCAL_PACKAGES_ONLY AND (NOT libarchive_sb_LIBARCHIVE_FORCE_CPM))
        message(FATAL_ERROR "LibArchive: Trying to download when 'CPM_LOCAL_PACKAGES_ONLY' is set to a truthy value; The package is missing (or otherwise CMake cannot find it)")
    endif()


    ### Turning off check_function_exists when the dependencies in question are added by CPM
    ### This is a very hacky solution ... but a better one does not exist as far as I know
    if(libb2_ADDED)
        set(HAVE_LIBB2 TRUE)
    endif()
    if(zstd_ADDED)
        set(HAVE_LIBZSTD TRUE)
        set(HAVE_ZSTD_compressStream TRUE)
        set(HAVE_ZSTD_minCLevel TRUE)
    endif()
    if(zstd_ADDED)
        set(HAVE_PKCS5_PBKDF2_HMAC_SHA1 TRUE)
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
        FORCE TRUE
        NAME LibArchive
    )


    if(libarchive_sb_BUILD_SHARED_LIBS)
        add_library(LibArchive::LibArchive ALIAS archive)
        if(openssl-cmake_ADDED)
            add_dependencies(archive OpenSSL::Crypto)
        endif()
        if(ENABLE_ZLIB)
            if(NOT ZLIB_USE_STATIC_LIBS)
                target_compile_definitions(archive_static PRIVATE ZLIB_DLL)
            endif()
            if(USING_MSVC_STL)
                target_compile_definitions(archive_static PRIVATE ZLIB_WINAPI)
            endif()
        endif()
    else()
        add_library(LibArchive::LibArchive ALIAS archive_static)
        if(openssl-cmake_ADDED)
            add_dependencies(archive_static OpenSSL::Crypto)
        endif()
        if(ENABLE_ZLIB)
            if(NOT ZLIB_USE_STATIC_LIBS)
                target_compile_definitions(archive_static PRIVATE ZLIB_DLL)
            endif()
            if(USING_MSVC_STL)
                target_compile_definitions(archive_static PRIVATE ZLIB_WINAPI)
            endif()
        endif()
    endif()


    unset(ZLIB_USE_STATIC_LIBS)
endif()


if(libarchive_sb_ENABLE_INTERNAL_TESTS)
    add_executable(libarchive_sb_testExecutable src/main.cpp)
    target_link_libraries(libarchive_sb_testExecutable PUBLIC LibArchive::LibArchive)
endif()
