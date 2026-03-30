vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO myint/perceptualdiff
    HEAD_REF master
    REF 5850a7a2c0425ab6a2b740aec5466f842c3f5657
    SHA512 cef2aa55e079f86512d936ddc3d54e6f67368c011e06d27b84ded8d37c739b311da378e20dbb5f79be9758d2df76bdc4443d497b2d7cad9628f275ac0ff1617d
    PATCHES
      symbol-exporting.patch
)

# Override CMakeLists.txt and package config file
configure_file(${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt ${SOURCE_PATH}/CMakeLists.txt @ONLY)
configure_file(${CMAKE_CURRENT_LIST_DIR}/config.cmake.in ${SOURCE_PATH}/config.cmake.in COPYONLY)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
)

vcpkg_cmake_install()
vcpkg_cmake_config_fixup()
vcpkg_copy_pdbs()

# Clean up debug config files
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include)
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/share)

# Rename license
file(RENAME "${CURRENT_PACKAGES_DIR}/share/${PORT}/LICENSE" "${CURRENT_PACKAGES_DIR}/share/${PORT}/copyright")
