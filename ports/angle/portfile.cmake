if (VCPKG_TARGET_IS_LINUX)
    message(WARNING "Building with a gcc version less than 6.1 is not supported.")
    message(WARNING "${PORT} currently requires the following libraries from the system package manager:\n    libx11-dev\n    mesa-common-dev\n    libxi-dev\n    libxext-dev\n\nThese can be installed on Ubuntu systems via apt-get install libx11-dev mesa-common-dev libxi-dev libxext-dev.")
endif()

if (VCPKG_TARGET_ARCHITECTURE STREQUAL "x86")
    set(ANGLE_CPU_BITNESS ANGLE_IS_32_BIT_CPU)
elseif (VCPKG_TARGET_ARCHITECTURE STREQUAL "x64")
    set(ANGLE_CPU_BITNESS ANGLE_IS_64_BIT_CPU)
elseif (VCPKG_TARGET_ARCHITECTURE STREQUAL "arm")
    set(ANGLE_CPU_BITNESS ANGLE_IS_32_BIT_CPU)
elseif (VCPKG_TARGET_ARCHITECTURE STREQUAL "arm64")
    set(ANGLE_CPU_BITNESS ANGLE_IS_64_BIT_CPU)
else()
    message(FATAL_ERROR "Unsupported architecture: ${VCPKG_TARGET_ARCHITECTURE}")
endif()

set(ANGLE_USE_D3D11_COMPOSITOR_NATIVE_WINDOW "OFF")
if (VCPKG_TARGET_IS_WINDOWS OR VCPKG_TARGET_IS_UWP)
  set(ANGLE_BUILDSYSTEM_PORT "Win")
  if (NOT MINGW)
    set(ANGLE_USE_D3D11_COMPOSITOR_NATIVE_WINDOW "ON")
  endif()
elseif (VCPKG_TARGET_IS_OSX)
  set(ANGLE_BUILDSYSTEM_PORT "Mac")
elseif (VCPKG_TARGET_IS_LINUX)
  set(ANGLE_BUILDSYSTEM_PORT "Linux")
else()
  # default other platforms to "Linux" config
  set(ANGLE_BUILDSYSTEM_PORT "Linux")
endif()

# chromium/6070
set(ANGLE_COMMIT cd6b265c262346dca0c236b9bcc99f403a43197c)
set(ANGLE_VERSION 6070)
set(ANGLE_SHA512 cc58e374877627d35d20ac9e8745725eb0b1545abc83c35078e907e9ca91b8583c33446801ca598690abde5a13934af41145ac7c5b99add822f52851fcd2b822)
set(ANGLE_THIRDPARTY_ZLIB_COMMIT fef58692c1d7bec94c4ed3d030a45a1832a9615d)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO google/angle
    REF ${ANGLE_COMMIT}
    SHA512 ${ANGLE_SHA512}
    # On update check headers against opengl-registry
    PATCHES
        001-fix-uwp.patch
        002-fix-builder-error.patch
        003-fix-mingw.patch
        004-fix-gni-to-cmake.patch
)

# Generate angle_commit.h
set(ANGLE_COMMIT_HASH_SIZE 12)
string(SUBSTRING "${ANGLE_COMMIT}" 0 ${ANGLE_COMMIT_HASH_SIZE} ANGLE_COMMIT_HASH)
set(ANGLE_COMMIT_DATE "invalid-date")
set(ANGLE_REVISION "${ANGLE_VERSION}")
configure_file("${CMAKE_CURRENT_LIST_DIR}/angle_commit.h.in" "${SOURCE_PATH}/angle_commit.h" @ONLY)
configure_file("${CMAKE_CURRENT_LIST_DIR}/angle_commit.h.in" "${SOURCE_PATH}/src/common/angle_commit.h" @ONLY)
file(COPY "${CMAKE_CURRENT_LIST_DIR}/unofficial-angle-config.cmake" DESTINATION "${SOURCE_PATH}")

set(ANGLE_WEBKIT_BUILDSYSTEM_COMMIT "3b928ce58d577d94a25fe6fba82be98a7638f3fb")

# Download WebKit gni-to-cmake.py conversion script
vcpkg_download_distfile(GNI_TO_CMAKE_PY
    URLS "https://github.com/WebKit/WebKit/raw/${ANGLE_WEBKIT_BUILDSYSTEM_COMMIT}/Source/ThirdParty/ANGLE/gni-to-cmake.py"
    FILENAME "gni-to-cmake.py"
    SHA512 fb56e23f6295dd5eacd4205285898a88b60b391b666745d67899578e56abda5ab00f1da92fe70bf5aa511842231cae567c15718cf7bf4ce923db29119225d109
)

# Generate CMake files from GN / GNI files
x_vcpkg_get_python_packages(PYTHON_VERSION "3" OUT_PYTHON_VAR "PYTHON3" PACKAGES ply)

set(_root_gni_files_to_convert
  "compiler.gni Compiler.cmake"
  "libGLESv2.gni GLESv2.cmake"
)
set(_renderer_gn_files_to_convert
  "libANGLE/renderer/d3d/BUILD.gn D3D.cmake"
  "libANGLE/renderer/gl/BUILD.gn GL.cmake"
  "libANGLE/renderer/metal/BUILD.gn Metal.cmake"
)

foreach(_root_gni_file IN LISTS _root_gni_files_to_convert)
  separate_arguments(_file_values UNIX_COMMAND "${_root_gni_file}")
  list(GET _file_values 0 _src_gn_file)
  list(GET _file_values 1 _dst_file)
  vcpkg_execute_required_process(
      COMMAND "${PYTHON3}" "${GNI_TO_CMAKE_PY}" "src/${_src_gn_file}" "${_dst_file}"
      WORKING_DIRECTORY "${SOURCE_PATH}"
      LOGNAME "gni-to-cmake-${_dst_file}-${TARGET_TRIPLET}"
  )
endforeach()

foreach(_renderer_gn_file IN LISTS _renderer_gn_files_to_convert)
  separate_arguments(_file_values UNIX_COMMAND "${_renderer_gn_file}")
  list(GET _file_values 0 _src_gn_file)
  list(GET _file_values 1 _dst_file)
  get_filename_component(_src_dir "${_src_gn_file}" DIRECTORY)
  vcpkg_execute_required_process(
      COMMAND "${PYTHON3}" "${GNI_TO_CMAKE_PY}" "src/${_src_gn_file}" "${_dst_file}" --prepend "src/${_src_dir}/"
      WORKING_DIRECTORY "${SOURCE_PATH}"
      LOGNAME "gni-to-cmake-${_dst_file}-${TARGET_TRIPLET}"
  )
endforeach()

# Fetch additional CMake files from WebKit ANGLE buildsystem
vcpkg_download_distfile(WK_ANGLE_INCLUDE_CMAKELISTS
    URLS "https://github.com/WebKit/WebKit/raw/${ANGLE_WEBKIT_BUILDSYSTEM_COMMIT}/Source/ThirdParty/ANGLE/include/CMakeLists.txt"
    FILENAME "include_CMakeLists.txt"
    SHA512 a7ddf3c6df7565e232f87ec651cc4fd84240b8866609e23e3e6e41d22532fd34c70e0f3b06120fd3d6d930ca29c1d0d470d4c8cb7003a66f8c1a840a42f32949
)
configure_file("${WK_ANGLE_INCLUDE_CMAKELISTS}" "${SOURCE_PATH}/include/CMakeLists.txt" COPYONLY)

vcpkg_download_distfile(WK_ANGLE_CMAKE_WEBKITCOMPILERFLAGS
    URLS "https://github.com/WebKit/WebKit/raw/${ANGLE_WEBKIT_BUILDSYSTEM_COMMIT}/Source/cmake/WebKitCompilerFlags.cmake"
    FILENAME "WebKitCompilerFlags.cmake"
    SHA512 dd1b826c12051e872bfbcafde6a5c7ad1c805cc3d0d86b13c9ea2705ec732ca8151d765f304965b949fc5d0dee66676e32cef5498881edb5d84fa18715faa0bb
)
file(COPY "${WK_ANGLE_CMAKE_WEBKITCOMPILERFLAGS}" DESTINATION "${SOURCE_PATH}/cmake")

vcpkg_download_distfile(WK_ANGLE_CMAKE_WEBKITMACROS
    URLS "https://github.com/WebKit/WebKit/raw/${ANGLE_WEBKIT_BUILDSYSTEM_COMMIT}/Source/cmake/WebKitMacros.cmake"
    FILENAME "WebKitMacros.cmake"
    SHA512 2d6c38ca51f31e86c2bf68c74f8565e7248b7828ffaa94e91b665fe6e168dd202696e63b879372d1ccd7e9b9f143a2424dcbd37e6bd93a3ed6a8051834feddf0
)
file(COPY "${WK_ANGLE_CMAKE_WEBKITMACROS}" DESTINATION "${SOURCE_PATH}/cmake")

vcpkg_download_distfile(WK_ANGLE_SHADER_PROGRAM_VERSION
    URLS "https://github.com/WebKit/WebKit/raw/${ANGLE_WEBKIT_BUILDSYSTEM_COMMIT}/Source/ThirdParty/ANGLE/WebKit/ANGLEShaderProgramVersion.h"
    FILENAME "ANGLEShaderProgramVersion.h"
    SHA512 54987c82049fb5ca1d1cb7a3cac694f6077bc7e25af863ce4a4f64c37644e037b9ae4b5ed344b838e81a0ca60850a77b5438e931b820301931abb75008e7d6dd
)
file(COPY "${WK_ANGLE_SHADER_PROGRAM_VERSION}" DESTINATION "${SOURCE_PATH}/src")

# Copy additional custom CMake buildsystem into appropriate folders
file(GLOB MAIN_BUILDSYSTEM "${CMAKE_CURRENT_LIST_DIR}/cmake-buildsystem/CMakeLists.txt" "${CMAKE_CURRENT_LIST_DIR}/cmake-buildsystem/*.cmake")
file(COPY ${MAIN_BUILDSYSTEM} DESTINATION "${SOURCE_PATH}")
file(GLOB MODULES "${CMAKE_CURRENT_LIST_DIR}/cmake-buildsystem/cmake/*.cmake")
file(COPY ${MODULES} DESTINATION "${SOURCE_PATH}/cmake")

function(checkout_in_path PATH URL REF)
    if(EXISTS "${PATH}")
        file(GLOB files "${PATH}/*")
        if(files)
            return()
        endif()
        file(REMOVE_RECURSE "${PATH}")
    endif()

    vcpkg_from_git(
        OUT_SOURCE_PATH DEP_SOURCE_PATH
        URL "${URL}"
        REF "${REF}"
    )
    file(RENAME "${DEP_SOURCE_PATH}" "${PATH}")
    file(REMOVE_RECURSE "${DEP_SOURCE_PATH}")
endfunction()

checkout_in_path(
    "${SOURCE_PATH}/third_party/zlib"
    "https://chromium.googlesource.com/chromium/src/third_party/zlib"
    "${ANGLE_THIRDPARTY_ZLIB_COMMIT}"
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS_DEBUG -DDISABLE_INSTALL_HEADERS=1
    OPTIONS
        "-D${ANGLE_CPU_BITNESS}=1"
        "-DPORT=${ANGLE_BUILDSYSTEM_PORT}"
        "-DANGLE_USE_D3D11_COMPOSITOR_NATIVE_WINDOW=${ANGLE_USE_D3D11_COMPOSITOR_NATIVE_WINDOW}"
        "-DVCPKG_TARGET_IS_WINDOWS=${VCPKG_TARGET_IS_WINDOWS}"
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(CONFIG_PATH share/unofficial-angle PACKAGE_NAME unofficial-angle)

vcpkg_copy_pdbs()

file(INSTALL "${SOURCE_PATH}/LICENSE" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
# Remove empty directories inside include directory
file(GLOB directory_children RELATIVE "${CURRENT_PACKAGES_DIR}/include" "${CURRENT_PACKAGES_DIR}/include/*")
foreach(directory_child ${directory_children})
    if(IS_DIRECTORY "${CURRENT_PACKAGES_DIR}/include/${directory_child}")
        file(GLOB_RECURSE subdirectory_children "${CURRENT_PACKAGES_DIR}/include/${directory_child}/*")
        if("${subdirectory_children}" STREQUAL "")
            file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/include/${directory_child}")
        endif()
    endif()
endforeach()
unset(subdirectory_children)
unset(directory_child)
unset(directory_children)

file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
