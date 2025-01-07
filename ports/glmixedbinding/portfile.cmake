vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO andesyv/glmixedbinding
    REF 184fed2dfcd02522f47d21c70fd3206b2a7b2536
    SHA512 97178d9299ffe770980c5d8ee97e55c1c31f3ad7fabb88fcf1f9e8790de07348c8cc24ce74fe70ae9837e43c0eeb5f3fdfcb7286e878d8c3c86e651e52172aae
    PATCHES
        0001_force-system-install.patch
        0003_fix-cmake-configs-paths.patch
        0004_fix-config-expected-paths.patch
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DOPTION_BUILD_TESTS=OFF
        -DOPTION_BUILD_TOOLS=OFF
        -DOPTION_BUILD_EXAMPLES=OFF
        -DGIT_REV=0
        -DCMAKE_DISABLE_FIND_PACKAGE_cpplocate=ON
        -DOPTION_BUILD_EXAMPLES=OFF
    MAYBE_UNUSED_VARIABLES
        CMAKE_DISABLE_FIND_PACKAGE_cpplocate
)

vcpkg_cmake_install()
vcpkg_cmake_config_fixup()
vcpkg_copy_pdbs()

## _IMPORT_PREFIX needs to go up one extra level in the directory tree.
file(GLOB_RECURSE TARGET_CMAKES "${CURRENT_PACKAGES_DIR}/*-export.cmake")
foreach(TARGET_CMAKE IN LISTS TARGET_CMAKES)
    file(READ ${TARGET_CMAKE} _contents)
    string(REPLACE
[[
get_filename_component(_IMPORT_PREFIX "${CMAKE_CURRENT_LIST_FILE}" PATH)
get_filename_component(_IMPORT_PREFIX "${_IMPORT_PREFIX}" PATH)
get_filename_component(_IMPORT_PREFIX "${_IMPORT_PREFIX}" PATH)
]]
[[
get_filename_component(_IMPORT_PREFIX "${CMAKE_CURRENT_LIST_FILE}" PATH)
get_filename_component(_IMPORT_PREFIX "${_IMPORT_PREFIX}" PATH)
get_filename_component(_IMPORT_PREFIX "${_IMPORT_PREFIX}" PATH)
get_filename_component(_IMPORT_PREFIX "${_IMPORT_PREFIX}" PATH)
]]
        _contents "${_contents}")
    file(WRITE ${TARGET_CMAKE} "${_contents}")
endforeach()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

# Remove files already published by egl-registry
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/include/KHR")

# Handle copyright
file(RENAME "${CURRENT_PACKAGES_DIR}/share/${PORT}/LICENSE" "${CURRENT_PACKAGES_DIR}/share/${PORT}/copyright")
configure_file("${CMAKE_CURRENT_LIST_DIR}/usage" "${CURRENT_PACKAGES_DIR}/share/${PORT}/usage" @ONLY)
