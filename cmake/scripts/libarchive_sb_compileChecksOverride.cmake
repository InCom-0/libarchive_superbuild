### Turning off check_function_exists when the dependencies in question are added by CPM
### This is a very hacky solution ... but a better one does not exist as far as I know

if(MbedTLS_ADDED)
    set(ARCHIVE_CRYPTO_MD5_MBEDTLS TRUE)
    set(ARCHIVE_CRYPTO_RMD160_MBEDTLS TRUE)
    set(ARCHIVE_CRYPTO_SHA1_MBEDTLS TRUE)
    set(ARCHIVE_CRYPTO_SHA256_MBEDTLS TRUE)
    set(ARCHIVE_CRYPTO_SHA384_MBEDTLS TRUE)
    set(ARCHIVE_CRYPTO_SHA512_MBEDTLS TRUE)
endif()

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
