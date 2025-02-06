include("${CMAKE_CURRENT_LIST_DIR}/angle-functions.cmake")

if(VCPKG_TARGET_IS_LINUX)
    message(WARNING "Building with a gcc version less than 6.1 is not supported.")
    # Full list of dependencies is available through <angle source>/build/install-build-deps.py
    # TODO: Update list
    message(WARNING "${PORT} currently requires the following libraries from the system package manager:\n    libx11-dev\n    mesa-common-dev\n    libxi-dev\n    libxext-dev\n\nThese can be installed on Ubuntu systems via apt-get install libx11-dev mesa-common-dev libxi-dev libxext-dev.")
endif()


if(VCPKG_TARGET_IS_ANDROID)
    string(APPEND GN_CONFIGURE_OPTIONS " target_os=\"android\"")
elseif(VCPKG_TARGET_IS_IOS)
    string(APPEND GN_CONFIGURE_OPTIONS " target_os=\"ios\"")
elseif(VCPKG_TARGET_IS_EMSCRIPTEN)
    string(APPEND GN_CONFIGURE_OPTIONS " target_os=\"wasm\"")
elseif(VCPKG_TARGET_IS_UWP)
    string(APPEND GN_CONFIGURE_OPTIONS " target_os=\"winuwp\"")
elseif(VCPKG_TARGET_IS_WINDOWS)
    string(APPEND GN_CONFIGURE_OPTIONS " target_os=\"win\"")
    set(ENV{DEPOT_TOOLS_WIN_TOOLCHAIN} 0)
endif()



vcpkg_find_acquire_program(GIT)
get_filename_component(GIT_PATH ${GIT} DIRECTORY)
vcpkg_add_to_path(PREPEND "${GIT_PATH}")

x_vcpkg_get_python_packages(PYTHON_VERSION "3" OUT_PYTHON_VAR "PYTHON3" PACKAGES httplib2)
get_filename_component(PYTHON3_PATH ${PYTHON3} DIRECTORY)
vcpkg_add_to_path(PREPEND "${PYTHON3_PATH}")
# GN on Windows expects python to be reachable as "python3"
if(WIN32)
    get_filename_component(PYTHON3_EXT ${PYTHON3} EXT)
    file(CREATE_LINK ${PYTHON3} "${PYTHON3_PATH}/python3${PYTHON3_EXT}" COPY_ON_ERROR)
endif()




# chromium/6070
set(ANGLE_COMMIT cd6b265c262346dca0c236b9bcc99f403a43197c)
set(ANGLE_SHA512 cc58e374877627d35d20ac9e8745725eb0b1545abc83c35078e907e9ca91b8583c33446801ca598690abde5a13934af41145ac7c5b99add822f52851fcd2b822)

# The value of ANGLE_COMMIT_DATE is the output of
# git show -s --format="%ci" HEAD
# in a checked out ANGLE repo:
set(ANGLE_COMMIT_DATE "2023-10-14 07:05:36 +0000")
# The value of ANGLE_COMMIT_POSITION is the output of
# git rev-list HEAD --count
# in a checked out ANGLE repo:
set(ANGLE_COMMIT_POSITION 22059)

vcpkg_check_features(OUT_FEATURE_OPTIONS feature_options
    FEATURES
        opengl      USE_OPENGL_BACKEND
        vulkan      USE_VULKAN_BACKEND
        direct3d9   USE_D3D9_BACKEND
        direct3d11  USE_D3D11_BACKEND
        metal       USE_METAL_BACKEND
        null        USE_NULL_BACKEND
)

if(NOT USE_OPENGL_BACKEND AND NOT USE_VULKAN_BACKEND AND NOT USE_D3D9_BACKEND AND NOT USE_D3D11_BACKEND AND NOT USE_METAL_BACKEND AND NOT USE_NULL_BACKEND)
    message(FATAL_ERROR "At least one backend must be enabled")
endif()

# Windows 10 SDK is required for the D3D debug runtime
# Currently supported SDK versions can be found in (<angle source>/build/vs_toolchain.py)
if(VCPKG_TARGET_IS_WINDOWS AND NOT $ENV{WindowsSdkDir} STREQUAL "" AND (USE_D3D9_BACKEND OR USE_D3D11_BACKEND))
    vcpkg_get_windows_sdk(WINDOWS_SDK)
    if(WINDOWS_SDK VERSION_LESS "10.0.22621")
        message(WARNING "The D3D backend debug runtime requires a Windows SDK of 10.0.22621 or higher")
    endif()
endif()

append_gn_option(angle_enable_gl ${USE_OPENGL_BACKEND})
append_gn_option(angle_enable_vulkan ${USE_VULKAN_BACKEND})
append_gn_option(angle_enable_d3d9 ${USE_D3D9_BACKEND})
append_gn_option(angle_enable_d3d11 ${USE_D3D11_BACKEND})
append_gn_option(angle_enable_metal ${USE_METAL_BACKEND})
append_gn_option(angle_enable_null ${USE_NULL_BACKEND})

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
        004-disable-gclient-hooks.patch
)

# This list was generated by:
# 1. Getting the last depot_tools (git clone https://chromium.googlesource.com/chromium/tools/depot_tools)
# 2. Checking out the ANGLE repo with all it's dependencies (path/to/depot_tools/fetch angle)
# 3. Running the parse-dep-info-for-current-directory.ps1 script on all dependencies using gclient
#    (py path/to/depot_tools/gclient.py recurse --no-progress -j1 powershell -Command parse-dep-info-for-current-directory.ps1)

checkout_dependencies(
    "build https://chromium.googlesource.com/chromium/src/build.git 306e127bcaedbdffb2a84754d64ebcdfbfebedbe"
    "buildtools https://chromium.googlesource.com/chromium/src/buildtools.git d43434c2b23bdf4aba863237a3ef5ef2b178efe8"
    "testing https://chromium.googlesource.com/chromium/src/testing 537cca4a564ace75e0d72cefc8366401e96b1333"
    "third_party/EGL-Registry/src https://chromium.googlesource.com/external/github.com/KhronosGroup/EGL-Registry 7dea2ed79187cd13f76183c4b9100159b9e3e071"
    "third_party/OpenCL-Docs/src https://chromium.googlesource.com/external/github.com/KhronosGroup/OpenCL-Docs 774114e8761920b976d538d47fad8178d05984ec"
    "third_party/OpenCL-ICD-Loader/src https://chromium.googlesource.com/external/github.com/KhronosGroup/OpenCL-ICD-Loader 9b5e3849b49a1448996c8b96ba086cd774d987db"
    "third_party/OpenGL-Registry/src https://chromium.googlesource.com/external/github.com/KhronosGroup/OpenGL-Registry 5bae8738b23d06968e7c3a41308568120943ae77"
    "third_party/Python-Markdown https://chromium.googlesource.com/chromium/src/third_party/Python-Markdown 0f4473546172a64636f5d841410c564c0edad625"
    "third_party/SwiftShader https://swiftshader.googlesource.com/SwiftShader 400ac3a175a658d8157f8a363271ae7ab013c2ee"
    "third_party/VK-GL-CTS/src https://chromium.googlesource.com/external/github.com/KhronosGroup/VK-GL-CTS 7d738783bf286e82937e431c295d4682f3767267"
    "third_party/abseil-cpp https://chromium.googlesource.com/chromium/src/third_party/abseil-cpp ae615e13098061c8b1866dda7182b74f158d9dd2"
    "third_party/astc-encoder/src https://chromium.googlesource.com/external/github.com/ARM-software/astc-encoder 573c475389bf51d16a5c3fc8348092e094e50e8f"
    "third_party/catapult https://chromium.googlesource.com/catapult.git a4060bfb8bcb76ee41b9cfb18bafae669eeefbdb"
    "third_party/cherry https://android.googlesource.com/platform/external/cherry 4f8fb08d33ca5ff05a1c638f04c85bbb8d8b52cc"
    "third_party/clang-format/script https://chromium.googlesource.com/external/github.com/llvm/llvm-project/clang/tools/clang-format.git e5337933f2951cacd3aeacd238ce4578163ca0b9"
    "third_party/depot_tools https://chromium.googlesource.com/chromium/tools/depot_tools.git c51829968b91a150c73150b56fdf89e4bb34b695"
    "third_party/glmark2/src https://chromium.googlesource.com/external/github.com/glmark2/glmark2 ca8de51fedb70bace5351c6b002eb952c747e889"
    "third_party/googletest https://chromium.googlesource.com/chromium/src/third_party/googletest 17bbed2084d3127bd7bcd27283f18d7a5861bea8"
    "third_party/jsoncpp https://chromium.googlesource.com/chromium/src/third_party/jsoncpp f62d44704b4da6014aa231cfc116e7fd29617d2a"
    "third_party/libc++/src https://chromium.googlesource.com/external/github.com/llvm/llvm-project/libcxx.git bbce3ebce8ae057e2c5751184d0d5471ba75249d"
    "third_party/libc++abi/src https://chromium.googlesource.com/external/github.com/llvm/llvm-project/libcxxabi.git db9800c042df3ee2691031a58b5e37e89a7356a3"
    "third_party/libjpeg_turbo https://chromium.googlesource.com/chromium/deps/libjpeg_turbo.git 30bdb85e302ecfc52593636b2f44af438e05e784"
    "third_party/libpng/src https://android.googlesource.com/platform/external/libpng d2ece84bd73af1cd5fae5e7574f79b40e5de4fba"
    "third_party/libunwind/src https://chromium.googlesource.com/external/github.com/llvm/llvm-project/libunwind.git 7b1593d5caacf5d07faa5ef8535733ab51ad9bc8"
    "third_party/nasm https://chromium.googlesource.com/chromium/deps/nasm.git 7fc833e889d1afda72c06220e5bed8fb43b2e5ce"
    "third_party/protobuf https://chromium.googlesource.com/chromium/src/third_party/protobuf b2f4cca357754462dd8b47f33a02b1b41d152441"
    "third_party/rapidjson/src https://chromium.googlesource.com/external/github.com/Tencent/rapidjson 781a4e667d84aeedbeb8184b7b62425ea66ec59f"
    "third_party/vulkan-deps https://chromium.googlesource.com/vulkan-deps f719b699697baf566af0266c21b097259b7411c7"
    "third_party/vulkan_memory_allocator https://chromium.googlesource.com/external/github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator 56300b29fbfcc693ee6609ddad3fdd5b7a449a21"
    "third_party/zlib https://chromium.googlesource.com/chromium/src/third_party/zlib fef58692c1d7bec94c4ed3d030a45a1832a9615d"
    "tools/clang https://chromium.googlesource.com/chromium/src/tools/clang.git 22e15941889dad6fcffeca7134684b888299ad55"
    "tools/mb https://chromium.googlesource.com/chromium/src/tools/mb 7adb2360db9da9e8d3cca72cef12e45eb5995b9c"
    "tools/md_browser https://chromium.googlesource.com/chromium/src/tools/md_browser 6cc8e58a83412dc31de6fb7614fadb0b51748d4b"
    "tools/memory https://chromium.googlesource.com/chromium/src/tools/memory 8b06a53701884108e156dfad4a5498d1f96e3ca2"
    "tools/perf https://chromium.googlesource.com/chromium/src/tools/perf 88edb4121fd4f85956436084458dc692dfbb5239"
    "tools/protoc_wrapper https://chromium.googlesource.com/chromium/src/tools/protoc_wrapper b5ea227bd88235ab3ccda964d5f3819c4e2d8032"
    "tools/valgrind https://chromium.googlesource.com/chromium/src/tools/valgrind e10259da244f75e52a681371f679d9ec095ff62a"
    "third_party/googletest/src https://chromium.googlesource.com/external/github.com/google/googletest.git 2d924d7a971e9667d76ad09727fb2402b4f8a1e3"
    "third_party/jsoncpp/source https://chromium.googlesource.com/external/github.com/open-source-parsers/jsoncpp.git 42e892d96e47b1f6e29844cc705e148ec4856448"
    "third_party/vulkan-deps/glslang/src https://chromium.googlesource.com/external/github.com/KhronosGroup/glslang 48f9ed8b08be974f4e463ef38136c8f23513b2cf"
    "third_party/vulkan-deps/spirv-cross/src https://chromium.googlesource.com/external/github.com/KhronosGroup/SPIRV-Cross 724433d72925f54682ae637c8bc4f4b7e83c4409"
    "third_party/vulkan-deps/spirv-headers/src https://chromium.googlesource.com/external/github.com/KhronosGroup/SPIRV-Headers 4183b260f4cccae52a89efdfcdd43c4897989f42"
    "third_party/vulkan-deps/spirv-tools/src https://chromium.googlesource.com/external/github.com/KhronosGroup/SPIRV-Tools 661f429b11e4392139a6c0630ceb3e3182cdb0f4"
    "third_party/vulkan-deps/vulkan-headers/src https://chromium.googlesource.com/external/github.com/KhronosGroup/Vulkan-Headers 07ff4233bc69e573ae0a6b4b48ad16451ac4e37f"
    "third_party/vulkan-deps/vulkan-loader/src https://chromium.googlesource.com/external/github.com/KhronosGroup/Vulkan-Loader 5402dd26632797d3cdaedb97cef04849d5ec980d"
    "third_party/vulkan-deps/vulkan-tools/src https://chromium.googlesource.com/external/github.com/KhronosGroup/Vulkan-Tools 730552e6702cd73764b28f48271a967fba95162e"
    "third_party/vulkan-deps/vulkan-utility-libraries/src https://chromium.googlesource.com/external/github.com/KhronosGroup/Vulkan-Utility-Libraries ca0ad5798733d94a80a322c98dab9ca9a0cd0fb2"
    "third_party/vulkan-deps/vulkan-validation-layers/src https://chromium.googlesource.com/external/github.com/KhronosGroup/Vulkan-ValidationLayers 38891e233bf914cd82bc0a8b4c91b7b94e3cd86b"
)


# Source modifications due to lack of Git metadata from vcpkg_from_github:

# The LASTCHANGE.committime file is required by GN and generated by doing "build/util/lastchange.py -o build/util/LASTCHANGE" in a checked out ANGLE repo
file(COPY_FILE "${CMAKE_CURRENT_LIST_DIR}/res/LASTCHANGE.committime" "${SOURCE_PATH}/build/util/LASTCHANGE.committime")

# The <angle source>/src/commit_id.py script generates a angle_commit.h file containing Git information. Unfortunately for us, since our source
# code checkout doesn't contain any git metadata, this script will always fail and fallback to it's default values for the
# generated angle_commit.h file. But we can hack around this by overriding the fallback values to the actual Git information.
fetch_angle_commit_id()
if(ANGLE_COMMIT_ID)
    vcpkg_replace_string("${SOURCE_PATH}/src/commit_id.py" "commit_id = 'unknown hash'" "commit_id = '${ANGLE_COMMIT_ID}'")
else()
    message(WARNING "Failed to fetch commit id for autogenerated commit file. ${PORT} package might not contain the correct version information.")
endif()
vcpkg_replace_string("${SOURCE_PATH}/src/commit_id.py" "commit_date = 'unknown date'" "commit_date = '${ANGLE_COMMIT_DATE}'")
vcpkg_replace_string("${SOURCE_PATH}/src/commit_id.py" "commit_position = '0'" "commit_position = '${ANGLE_COMMIT_POSITION}'")


# Append depot_tools to path (needed for gclient down below)
vcpkg_add_to_path(PREPEND "${SOURCE_PATH}/third_party/depot_tools")

# Generate gclient config file
file(COPY_FILE "${CMAKE_CURRENT_LIST_DIR}/res/gclient_args.gni" "${SOURCE_PATH}/build/config/gclient_args.gni")
if(VCPKG_TARGET_IS_WINDOWS AND NOT $ENV{WindowsSdkDir} STREQUAL "")
	string(REGEX REPLACE "\\\\+$" "" WindowsSdkDir $ENV{WindowsSdkDir})
	file(APPEND "${SOURCE_PATH}/build/config/gclient_args.gni" "windows_sdk_path = \"${WindowsSdkDir}\"\n")
endif()

file(COPY "${CMAKE_CURRENT_LIST_DIR}/res/testing" DESTINATION "${SOURCE_PATH}")

# Fetch addition gclient distfiles by running hooks:
message(STATUS "Fetching additional distfiles via gclient hooks")
file(COPY_FILE "${CMAKE_CURRENT_LIST_DIR}/res/.gclient" "${SOURCE_PATH}/.gclient")
vcpkg_execute_required_process(
    COMMAND "${PYTHON3}" "third_party/depot_tools/gclient.py" "runhooks"
    WORKING_DIRECTORY "${SOURCE_PATH}"
    LOGNAME "gclient-hooks-${TARGET_TRIPLET}"
)


# # Fetched from ${SOURCE_PATH}/third_party/vulkan-deps/DEPS :
# set(VULKAN_SOURCES_TO_FETCH
#     "glslang/src glslang 7fa0731a803e8c02347756df41e0b606a4a34e2d"
#     "spirv-cross/src SPIRV-Cross 2de1265fca722929785d9acdec4ab728c47a0254"
#     "spirv-headers/src SPIRV-Headers 88bc5e321c2839707df8b1ab534e243e00744177"
#     "spirv-tools/src SPIRV-Tools 73876defc8d9bd7ff42d5f71b15eb3db0cf86c65"
#     "vulkan-headers/src Vulkan-Headers f4bfcd885214675a6a0d7d4df07f52b511e6ea16"
#     "vulkan-loader/src Vulkan-Loader 131a081e083d20ed27114afc5a9f1420d556b362"
#     "vulkan-tools/src Vulkan-Tools f7017f23337b90a2b2ceb65a4e1050e8ad89e065"
#     "vulkan-utility-libraries/src Vulkan-Utility-Libraries dcfce25b439a2785f2c90b184e1964898070b4f1"
#     "vulkan-validation-layers/src Vulkan-ValidationLayers cc1e12c6fc9bdb96ea3f259286ac036db6b68116"
# )


# if(VCPKG_CMAKE_SYSTEM_NAME STREQUAL Linux)
#     set(OPTIONS "${OPTIONS} use_allocator=\"none\" use_sysroot=false use_glib=false")
# endif()

# Targets can be found after following https://github.com/google/angle/blob/main/doc/DevSetup.md by doing
# gn ls <generated-build-folder>
set(BUILD_TARGETS :libEGL :libGLESv2 third_party/zlib:zlib)

append_gn_option(is_clang OFF)
append_gn_option(build_with_chromium OFF)
append_gn_option(use_dummy_lastchange ON)

string(APPEND GN_CONFIGURE_OPTIONS "target_cpu=\"${VCPKG_TARGET_ARCHITECTURE}\"")

if(VCPKG_LIBRARY_LINKAGE STREQUAL dynamic)
    append_gn_option(is_component_build ON)
else()
    append_gn_option(is_component_build OFF)
endif()


set(GN_CONFIGURE_OPTIONS_DEBUG "${GN_CONFIGURE_OPTIONS} is_debug=true")
set(GN_CONFIGURE_OPTIONS_RELEASE "${GN_CONFIGURE_OPTIONS} is_debug=false")
# We assume all users who wants to use the vulkan backend in debug mode also wants the vulkan validation layers.
if(USE_VULKAN_BACKEND)
    set(GN_CONFIGURE_OPTIONS_DEBUG "${GN_CONFIGURE_OPTIONS_DEBUG} angle_enable_vulkan_validation_layers=true")
    string(APPEND GN_CONFIGURE_OPTIONS_DEBUG "angle_enable_vulkan_validation_layers=true")
endif()


debug_message("Debug GN configure options: ${GN_CONFIGURE_OPTIONS_DEBUG}")
debug_message("Release GN configure options: ${GN_CONFIGURE_OPTIONS_RELEASE}")

vcpkg_gn_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS_DEBUG "${GN_CONFIGURE_OPTIONS_DEBUG}"
    OPTIONS_RELEASE "${GN_CONFIGURE_OPTIONS_RELEASE}"
)


debug_message("Building ANGLE with targets: ${BUILD_TARGETS}")

vcpkg_gn_install(
    SOURCE_PATH "${SOURCE_PATH}"
    TARGETS ${BUILD_TARGETS}
)

set(PACKAGES_INCLUDE_DIR "${CURRENT_PACKAGES_DIR}/include/${PORT}")
set(SOURCE_INCLUDE_DIR "${SOURCE_PATH}/include")
file(GLOB_RECURSE INCLUDE_FILES LIST_DIRECTORIES false RELATIVE "${SOURCE_INCLUDE_DIR}" "${SOURCE_INCLUDE_DIR}/*.h")
foreach(_file ${INCLUDE_FILES})
    configure_file("${SOURCE_INCLUDE_DIR}/${_file}" "${PACKAGES_INCLUDE_DIR}/${_file}" COPYONLY)
endforeach()

# Create package config file
set(TARGET_INCLUDES_PREFIX_PATH "${PACKAGES_INCLUDE_DIR}")
set(TARGET_LIBRARY_PREFIX_PATH "${CURRENT_PACKAGES_DIR}")
if(VCPKG_LIBRARY_LINKAGE STREQUAL dynamic)
    set(TARGET_IMPORTED_LIBRARY_TYPE SHARED)
else()
    set(TARGET_IMPORTED_LIBRARY_TYPE STATIC)
endif()

message(STATUS "Installing: ${CURRENT_PACKAGES_DIR}/share/unofficial-angle/unofficial-angle-config.cmake")
configure_file("${CMAKE_CURRENT_LIST_DIR}/unofficial-angle-config.cmake.in" "${CURRENT_PACKAGES_DIR}/share/unofficial-angle/unofficial-angle-config.cmake" @ONLY)

# We use vcpkg_cmake_config_fixup to calculate the correct prefix path. Unfortunately,
# vcpkg_cmake_config_fixup currently also merges the debug and release version of our
# config script, which we don't need. Luckily it only messes with INTERFACE_LINK_LIBRARIES
# property so we can get around vcpkg_cmake_config_fixup's merging by using
# other properties instead and making a dummy copy of the config script for the debug
# config script.
configure_file("${CURRENT_PACKAGES_DIR}/share/unofficial-angle/unofficial-angle-config.cmake" "${CURRENT_PACKAGES_DIR}/debug/share/unofficial-angle/unofficial-angle-config.cmake" COPYONLY)

vcpkg_cmake_config_fixup(PACKAGE_NAME unofficial-angle)


# Copyright and usage
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
configure_file("${CMAKE_CURRENT_LIST_DIR}/usage.in" "${CURRENT_PACKAGES_DIR}/share/${PORT}/usage" @ONLY)
