# Warn that only static linking is supported
vcpkg_check_linkage(ONLY_STATIC_LIBRARY )

# CDTAPI version used by this port file.
set(DTAPI_VERSION 6.6.0)

# Init variabale for name of library source file to safe initial values.
set(LIB_NAME_BASE "CDTAPI")
set(LIB_NAME_ARCH "")
set(LIB_NAME_CRT "")
set(LIB_NAME_EXT "")
set(LIB_NAME_DBG_SUFFIX "")

# Determine which platform is targetted
if(VCPKG_TARGET_IS_WINDOWS)
  message(STATUS "Installing CDTAPI for Windows.")
  
  # Mutual exclusivity check for Windows-only features
  if ("vc17" IN_LIST FEATURES AND "vc16" IN_LIST FEATURES AND "vc15" IN_LIST FEATURES)
    message(FATAL_ERROR "Features 'vc17', 'vc16' and 'vc15' are mutually exclusive. Please specify only one.")
  endif()

  # Step 1: set Windows specific names and locations for DTAPI
  
  #x86 or x64
  if (VCPKG_TARGET_ARCHITECTURE STREQUAL "x86")
    set(LIB_NAME_ARCH "")
  elseif (VCPKG_TARGET_ARCHITECTURE STREQUAL "x64")
    set(LIB_NAME_ARCH "64")
  else()
    message(FATAL_ERROR "Unsupported architecture: ${VCPKG_TARGET_ARCHITECTURE}")
  endif()
  
  # Which visual studio verions?
  if ("vc17" IN_LIST FEATURES)
    set(LIB_SRCDIR "vc17")
  elseif ("vc16" IN_LIST FEATURES)
    set(LIB_SRCDIR "vc16")
  elseif ("vc15" IN_LIST FEATURES)
    set(LIB_SRCDIR "vc15")
  else()
    # No feature specified => auto detect based on platform toolset.
    if (VCPKG_PLATFORM_TOOLSET STREQUAL "v143")
      set(LIB_SRCDIR "vc17")
    elseif (VCPKG_PLATFORM_TOOLSET STREQUAL "v142")
      set(LIB_SRCDIR "vc16")
    elseif (VCPKG_PLATFORM_TOOLSET STREQUAL "v141")
      set(LIB_SRCDIR "vc15")
    else()
      # Default to VC16 version.
      set(LIB_SRCDIR "vc16")
    endif()
  endif()
  
  # Using dynamic or static runtimes?
  if (VCPKG_CRT_LINKAGE STREQUAL "dynamic")
    set(LIB_NAME_CRT "MD")
  else()
    set(LIB_NAME_CRT "MT")
  endif()

  set(LIB_NAME_EXT "lib")
  set(LIB_NAME_DBG_SUFFIX "d")
  
  #Step 2: download zip with Windows binaries.
  vcpkg_download_distfile(
    ARCHIVE
    URLS "https://dektec.com/products/SDK/DTAPI/Downloads/dtapi-v${DTAPI_VERSION}-windows.zip"
    FILENAME "dtapi-v${DTAPI_VERSION}-windows.tar.gz"
    SHA512 3EAB7649AB82C6814B3A6654B32975E13353B2A424273A508A9CEB4CDA40DD35FE9D9A0FCAB0DE4E879A5C67380D1BABD62E355B3EC6EAE9836D4FB5C2BF6C58
  )

elseif(VCPKG_TARGET_IS_LINUX)
  message(STATUS "Installing CDTAPI for Linux.")
  
  # Step 1: set Linux specific names and locations for DTAPI.
  
  set(LIB_SRCDIR ".")
  
  #x86 or x64
  if (VCPKG_TARGET_ARCHITECTURE STREQUAL "x86")
    set(LIB_NAME_ARCH "")
  elseif (VCPKG_TARGET_ARCHITECTURE STREQUAL "x64")
    set(LIB_NAME_ARCH "64")
  else()
    message(FATAL_ERROR "Unsupported architecture: ${VCPKG_TARGET_ARCHITECTURE}")
  endif()
  
  set(LIB_NAME_CRT "")
  set(LIB_NAME_EXT "o")
  set(LIB_NAME_DBG_SUFFIX "")
  
  #Step 2: download zip with Linux binaries.
  vcpkg_download_distfile(
    ARCHIVE
    URLS "https://dektec.com/products/SDK/DTAPI/Downloads/dtapi-v${DTAPI_VERSION}-linux.tar.gz"
    FILENAME "dtapi-v${DTAPI_VERSION}-linux.tar.gz"
    SHA512 4CC807B8295FD92C094B78DB3F0D234CE76825097A920CF1FA6E07151BC9108E28DBD1EF1EAB3F836EBBFF1BCCBBC18611E84A2892D87EA5AEB662C0E0383BAF
  )
  
else()
  message(FATAL_ERROR "Only the Windows and Linux platforms are supported.")
endif()

# Step 3: extract archive with CDTAPI
vcpkg_extract_source_archive_ex(
    OUT_SOURCE_PATH SOURCE_PATH ARCHIVE ${ARCHIVE}
  )

# Construct full library name
set(LIB_NAME "${LIB_NAME_BASE}${LIB_NAME_ARCH}${LIB_NAME_CRT}")
message(STATUS "Using '${LIB_SRCDIR}/${LIB_NAME}.${LIB_NAME_EXT}' as source")

##############################################################################################################
#                                                                                                            #
# Install files                                                                                              #
#                                                                                                            #
##############################################################################################################

# Install - CDTAPI includes
file(GLOB INCLUDE_FILES ${SOURCE_PATH}/include/CDTAPI*.h)
foreach(INCLUDE_FILE ${INCLUDE_FILES})
  file(INSTALL
   "${INCLUDE_FILE}"
   DESTINATION ${CURRENT_PACKAGES_DIR}/include/${PORT}
  )
endforeach()

# Install - CDTAPI debug library
file(INSTALL
     "${SOURCE_PATH}/lib/${LIB_SRCDIR}/${LIB_NAME}${LIB_NAME_DBG_SUFFIX}.${LIB_NAME_EXT}"
     DESTINATION ${CURRENT_PACKAGES_DIR}/debug/lib
     RENAME "${LIB_NAME_BASE}.${LIB_NAME_EXT}"
    )

# Install - CDTAPI release library
file(INSTALL
     "${SOURCE_PATH}/lib/${LIB_SRCDIR}/${LIB_NAME}.${LIB_NAME_EXT}"
       DESTINATION ${CURRENT_PACKAGES_DIR}/lib
     RENAME "${LIB_NAME_BASE}.${LIB_NAME_EXT}"
    )
# Install - CDTAPI copyright file
file(INSTALL
   "${SOURCE_PATH}/share/cdtapi/copyright"
   DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT}
  )

# Install - CDTAPI cmake files library
file(GLOB SHARE_FILES ${SOURCE_PATH}/share/cdtapi/*.cmake)
foreach(SHARE_FILE ${SHARE_FILES})
  file(INSTALL
  "${SHARE_FILE}"
  DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT}
  )
endforeach()

# Check if one or more features are a part of a package installation.
# See /docs/maintainers/vcpkg_check_features.md for more details
vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
  FEATURES # <- Keyword FEATURES is required because INVERTED_FEATURES are being used
    tbb   WITH_TBB
  INVERTED_FEATURES
    tbb   ROCKSDB_IGNORE_PACKAGE_TBB
)