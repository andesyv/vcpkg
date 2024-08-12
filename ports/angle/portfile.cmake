include("${CMAKE_CURRENT_LIST_DIR}/angle-functions.cmake")

if(VCPKG_TARGET_IS_LINUX)
    message(WARNING "${PORT} currently only supports CLang on Linux")
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
set(ANGLE_COMMIT a674dc1dae8fc6e7b4839429f27ff00629a04d8a)
set(ANGLE_SHA512 0ae026a07ca95013f4380a2aa26cd7c056b52bb1e80a37f7136e3185b3cb7a7c428f1283f11274d141309cf4babf59ec39de756f785ac53ef466f41d0a2cd834)

# The value of ANGLE_COMMIT_DATE is the output of
# git show -s --format="%ci" HEAD
# in a checked out ANGLE repo:
set(ANGLE_COMMIT_DATE "2024-06-27 20:02:46 +0000")
# The value of ANGLE_COMMIT_POSITION is the output of
# git rev-list HEAD --count
# in a checked out ANGLE repo:
set(ANGLE_COMMIT_POSITION 23407)

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
    "build https://chromium.googlesource.com/chromium/src/build.git d6f058677a1198f6e24a5fb371beb6f052771dcf 005-disable-thin-archive-generation.patch"
    "buildtools https://chromium.googlesource.com/chromium/src/buildtools.git 94d7b86a83537f8a7db7dccb0bf885739f7a81aa"
    "testing https://chromium.googlesource.com/chromium/src/testing ab63c08c0e37d8af5bc3b59742424c26a1466589"
    "third_party/EGL-Registry/src https://chromium.googlesource.com/external/github.com/KhronosGroup/EGL-Registry 7dea2ed79187cd13f76183c4b9100159b9e3e071"
    "third_party/OpenCL-CTS/src https://chromium.googlesource.com/external/github.com/KhronosGroup/OpenCL-CTS e0a31a03fc8f816d59fd8b3051ac6a61d3fa50c6"
    "third_party/OpenCL-Docs/src https://chromium.googlesource.com/external/github.com/KhronosGroup/OpenCL-Docs 774114e8761920b976d538d47fad8178d05984ec"
    "third_party/OpenCL-ICD-Loader/src https://chromium.googlesource.com/external/github.com/KhronosGroup/OpenCL-ICD-Loader 9b5e3849b49a1448996c8b96ba086cd774d987db"
    "third_party/OpenGL-Registry/src https://chromium.googlesource.com/external/github.com/KhronosGroup/OpenGL-Registry 5bae8738b23d06968e7c3a41308568120943ae77"
    "third_party/Python-Markdown https://chromium.googlesource.com/chromium/src/third_party/Python-Markdown 0f4473546172a64636f5d841410c564c0edad625"
    "third_party/SwiftShader https://swiftshader.googlesource.com/SwiftShader a0ec371d8331d787c61eccc89fb411019330314e"
    "third_party/VK-GL-CTS/src https://chromium.googlesource.com/external/github.com/KhronosGroup/VK-GL-CTS 25d8c0099575a44f456b127034f43eed4538f599"
    "third_party/abseil-cpp https://chromium.googlesource.com/chromium/src/third_party/abseil-cpp 3736ae744b8bd621ca949b91c1756257eccee919"
    "third_party/astc-encoder/src https://chromium.googlesource.com/external/github.com/ARM-software/astc-encoder 573c475389bf51d16a5c3fc8348092e094e50e8f"
    "third_party/catapult https://chromium.googlesource.com/catapult.git 022cd349fe146c3dd0ba31f2789c630fc40e76a0"
    "third_party/cherry https://android.googlesource.com/platform/external/cherry 4f8fb08d33ca5ff05a1c638f04c85bbb8d8b52cc"
    "third_party/clang-format/script https://chromium.googlesource.com/external/github.com/llvm/llvm-project/clang/tools/clang-format.git 3c0acd2d4e73dd911309d9e970ba09d58bf23a62"
    "third_party/clspv/src https://chromium.googlesource.com/external/github.com/google/clspv a173c052455434a422bcfe5c12ffe44d574fd6e1"
    "third_party/dawn https://dawn.googlesource.com/dawn.git 6cdf3a1a195fa8ce4aec963dee146a7da6f435b8"
    "third_party/depot_tools https://chromium.googlesource.com/chromium/tools/depot_tools.git f4e8e13e8bc5673347f86e1be3ec4ccbf1a440c2"
    "third_party/glmark2/src https://chromium.googlesource.com/external/github.com/glmark2/glmark2 ca8de51fedb70bace5351c6b002eb952c747e889"
    "third_party/glslang/src https://chromium.googlesource.com/external/github.com/KhronosGroup/glslang ea087ff90d03947307cfe52500b74551aa35d34d"
    "third_party/googletest https://chromium.googlesource.com/chromium/src/third_party/googletest 17bbed2084d3127bd7bcd27283f18d7a5861bea8"
    "third_party/jinja2 https://chromium.googlesource.com/chromium/src/third_party/jinja2 2f6f2ff5e4c1d727377f5e1b9e1903d871f41e74"
    "third_party/jsoncpp https://chromium.googlesource.com/chromium/src/third_party/jsoncpp f62d44704b4da6014aa231cfc116e7fd29617d2a"
    "third_party/libc++/src https://chromium.googlesource.com/external/github.com/llvm/llvm-project/libcxx.git 09b99fd8ab300c93ff7b8df6688cafb27bd3db28"
    "third_party/libc++abi/src https://chromium.googlesource.com/external/github.com/llvm/llvm-project/libcxxabi.git 6171cc7fb1b842b112cfe5afa05c0e42a6342fe1"
    "third_party/libdrm https://chromium.googlesource.com/chromiumos/third_party/libdrm 474894ed17a037a464e5bd845a0765a50f647898"
    "third_party/libjpeg_turbo https://chromium.googlesource.com/chromium/deps/libjpeg_turbo.git ccfbe1c82a3b6dbe8647ceb36a3f9ee711fba3cf"
    "third_party/libpng/src https://android.googlesource.com/platform/external/libpng d2ece84bd73af1cd5fae5e7574f79b40e5de4fba"
    "third_party/libunwind/src https://chromium.googlesource.com/external/github.com/llvm/llvm-project/libunwind.git 48659aac13221a8cb4b552a9646e392bd49163ab"
    "third_party/llvm/src https://chromium.googlesource.com/external/github.com/llvm/llvm-project d222fa4521531cc4ac14b8e157d231c108c003be"
    "third_party/lunarg-vulkantools/src https://chromium.googlesource.com/external/github.com/LunarG/VulkanTools 00c49e3b56cc9748228d2e5b0d1e8e9c4409a02f"
    "third_party/markupsafe https://chromium.googlesource.com/chromium/src/third_party/markupsafe e582d7f0edb9d67499b0f5abd6ae5550e91da7f2"
    "third_party/nasm https://chromium.googlesource.com/chromium/deps/nasm.git f477acb1049f5e043904b87b825c5915084a9a29"
    "third_party/protobuf https://chromium.googlesource.com/chromium/src/third_party/protobuf ed9284c473211491ae6de41d60ac0329a79270d8"
    "third_party/rapidjson/src https://chromium.googlesource.com/external/github.com/Tencent/rapidjson 781a4e667d84aeedbeb8184b7b62425ea66ec59f"
    "third_party/spirv-cross/src https://chromium.googlesource.com/external/github.com/KhronosGroup/SPIRV-Cross b8fcf307f1f347089e3c46eb4451d27f32ebc8d3"
    "third_party/spirv-headers/src https://chromium.googlesource.com/external/github.com/KhronosGroup/SPIRV-Headers 2acb319af38d43be3ea76bfabf3998e5281d8d12"
    "third_party/spirv-tools/src https://chromium.googlesource.com/external/github.com/KhronosGroup/SPIRV-Tools ca004da9f9c7fa7ed536709823bd604fab3cd7da"
    "third_party/vulkan-deps https://chromium.googlesource.com/vulkan-deps 7ff358e64e2ba8121386cbcaaa95835c6abe63af"
    "third_party/vulkan-headers/src https://chromium.googlesource.com/external/github.com/KhronosGroup/Vulkan-Headers e3c37e6e184a232e10b01dff5a065ce48c047f88"
    "third_party/vulkan-loader/src https://chromium.googlesource.com/external/github.com/KhronosGroup/Vulkan-Loader 05f36c032ef20676eff121a8c8d5e6e33796ec8b"
    "third_party/vulkan-tools/src https://chromium.googlesource.com/external/github.com/KhronosGroup/Vulkan-Tools 345af476e583366352e014ee8e43fc5ddf421ab9"
    "third_party/vulkan-utility-libraries/src https://chromium.googlesource.com/external/github.com/KhronosGroup/Vulkan-Utility-Libraries 60fe7d0c153dc07325a8fb45310723a1767db811"
    "third_party/vulkan-validation-layers/src https://chromium.googlesource.com/external/github.com/KhronosGroup/Vulkan-ValidationLayers df3e018436e38c2536d5b79e1e662e6323b6fbe2"
    "third_party/vulkan_memory_allocator https://chromium.googlesource.com/external/github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator 56300b29fbfcc693ee6609ddad3fdd5b7a449a21"
    "third_party/zlib https://chromium.googlesource.com/chromium/src/third_party/zlib 8b7eff801b46f9d52d756a21b31239ae4e403611"
    "tools/clang https://chromium.googlesource.com/chromium/src/tools/clang.git e5f2479d0d4290113cf482a999276266f2ff2170"
    "tools/mb https://chromium.googlesource.com/chromium/src/tools/mb 7c0882a310b8ca11c9399a521bc95d1cf2086c13"
    "tools/md_browser https://chromium.googlesource.com/chromium/src/tools/md_browser 6cc8e58a83412dc31de6fb7614fadb0b51748d4b"
    "tools/memory https://chromium.googlesource.com/chromium/src/tools/memory a0eeba1c75aba820a482a8847946dae6f9078281"
    "tools/perf https://chromium.googlesource.com/chromium/src/tools/perf cd747a5520a1a4d1fe04e1fc092cd7bf0d2d36d9"
    "tools/protoc_wrapper https://chromium.googlesource.com/chromium/src/tools/protoc_wrapper dbcbea90c20ae1ece442d8ef64e61c7b10e2b013"
    "tools/valgrind https://chromium.googlesource.com/chromium/src/tools/valgrind e10259da244f75e52a681371f679d9ec095ff62a"
    "third_party/dawn/third_party/dxc https://chromium.googlesource.com/external/github.com/microsoft/DirectXShaderCompiler 4353db3983e2e38eb9e136bd02d2330582375c05"
    "third_party/dawn/third_party/glfw https://chromium.googlesource.com/external/github.com/glfw/glfw b35641f4a3c62aa86a0b3c983d163bc0fe36026d"
    "third_party/dawn/third_party/khronos/EGL-Registry https://chromium.googlesource.com/external/github.com/KhronosGroup/EGL-Registry 7dea2ed79187cd13f76183c4b9100159b9e3e071"
    "third_party/dawn/third_party/khronos/OpenGL-Registry https://chromium.googlesource.com/external/github.com/KhronosGroup/OpenGL-Registry 5bae8738b23d06968e7c3a41308568120943ae77"
    "third_party/dawn/third_party/webgpu-headers https://chromium.googlesource.com/external/github.com/webgpu-native/webgpu-headers 8049c324dc7b3c09dc96ea04cb02860f272c8686"
    "third_party/googletest/src https://chromium.googlesource.com/external/github.com/google/googletest.git 2d924d7a971e9667d76ad09727fb2402b4f8a1e3"
    "third_party/jsoncpp/source https://chromium.googlesource.com/external/github.com/open-source-parsers/jsoncpp.git 42e892d96e47b1f6e29844cc705e148ec4856448"
)

if(VCPKG_TARGET_IS_LINUX)
    checkout_dependencies(
        "third_party/wayland https://chromium.googlesource.com/external/anongit.freedesktop.org/git/wayland/wayland 75c1a93e2067220fa06208f20f8f096bb463ec08"
        "third_party/dawn/third_party/dxheaders https://chromium.googlesource.com/external/github.com/microsoft/DirectX-Headers 980971e835876dc0cde415e8f9bc646e64667bf7"
    )
endif()


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
vcpkg_execute_required_process(
    COMMAND "${PYTHON3}" "third_party/depot_tools/gclient.py" "config" "--unmanaged" "."
    WORKING_DIRECTORY "${SOURCE_PATH}"
    LOGNAME "gclient-config-${TARGET_TRIPLET}"
)

# Remove DEPS instructions to synchronize using Git (VCPKG doesn't store Git metadata, so synchronization will crash)
file(GLOB_RECURSE GCLIENT_DEPS_FILES LIST_DIRECTORIES false RELATIVE "${SOURCE_PATH}" "${SOURCE_PATH}/DEPS")
foreach(_file ${GCLIENT_DEPS_FILES})
    vcpkg_replace_string("${SOURCE_PATH}/${_file}" "git_dependencies = 'SYNC'" "")
    vcpkg_replace_string("${SOURCE_PATH}/${_file}" "git_dependencies = \"SYNC\"" "")

    # TODO https://github.com/microsoft/vcpkg/pull/34719:
    # vcpkg_replace_string("${SOURCE_PATH}/${_file}" "git_dependencies = .+\n" "" REGEX IGNORE_UNCHANGED)
endforeach()

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
# TODO: Check if this logic applies to Windows
if(VCPKG_TARGET_IS_WINDOWS OR VCPKG_LIBRARY_LINKAGE STREQUAL dynamic)
    set(BUILD_TARGETS :libEGL :libGLESv2 third_party/zlib:zlib)
    set(CONFIG_TARGET_LIBRARIES libEGL libGLESv2 third_party_zlib)
else()
    set(BUILD_TARGETS :libEGL_static :libGLESv2_static)
    set(CONFIG_TARGET_LIBRARIES libEGL libGLESv2)
endif()
if(VCPKG_TARGET_IS_WINDOWS AND USE_VULKAN_BACKEND)
    # ANGLE on Windows dynamically loads vulkan-1.dll from the build folder (no clue about other platforms yet)
    list(APPEND BUILD_TARGETS third_party/vulkan-loader/src:libvulkan)
endif()

if(VCPKG_TARGET_IS_WINDOWS)
    append_gn_option(is_clang OFF)
else()
    # Force ninja to build using CLang on all unix platforms. Building with GCC seems to fail as only libc++ is
    # being properly linked (and not libstdc++).
    append_gn_option(is_clang ON)
endif()

append_gn_option(build_with_chromium OFF)
append_gn_option(use_dummy_lastchange ON)

string(APPEND GN_CONFIGURE_OPTIONS " target_cpu=\"${VCPKG_TARGET_ARCHITECTURE}\" angle_build_tests=false")

if(VCPKG_LIBRARY_LINKAGE STREQUAL dynamic)
    append_gn_option(is_component_build ON)
else()
    append_gn_option(is_component_build OFF)
endif()


set(GN_CONFIGURE_OPTIONS_DEBUG "${GN_CONFIGURE_OPTIONS} is_debug=true")
set(GN_CONFIGURE_OPTIONS_RELEASE "${GN_CONFIGURE_OPTIONS} is_debug=false")
# We assume all users who wants to use the vulkan backend in debug mode also wants the vulkan validation layers.
if(USE_VULKAN_BACKEND)
    string(APPEND GN_CONFIGURE_OPTIONS_DEBUG " angle_enable_vulkan_validation_layers=true")
endif()


debug_message("Debug GN configure options: ${GN_CONFIGURE_OPTIONS_DEBUG}")
debug_message("Release GN configure options: ${GN_CONFIGURE_OPTIONS_RELEASE}")

vcpkg_gn_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS_DEBUG "${GN_CONFIGURE_OPTIONS_DEBUG}"
    OPTIONS_RELEASE "${GN_CONFIGURE_OPTIONS_RELEASE}"
)

if(VCPKG_LIBRARY_LINKAGE STREQUAL static)
    # After configuring targets, we can query for additional dependent targets from the GN buildsystem
    # (we don't have to reconfigure again because we know they will already be a part of the build files)
    append_gn_dependent_targets(
        TARGET ":libGLESv2_static"
        SOURCE_PATH "${SOURCE_PATH}"
        OUT_TARGET_LIST BUILD_TARGETS
        OUT_LIBNAME_LIST CONFIG_TARGET_LIBRARIES
    )
endif()


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
set(CONFIG_TARGET_LIBRARY_PREFIX_PATH "${CURRENT_PACKAGES_DIR}")
if(VCPKG_LIBRARY_LINKAGE STREQUAL dynamic)
    set(CONFIG_TARGET_IMPORTED_LIBRARY_TYPE SHARED)
else()
    set(CONFIG_TARGET_IMPORTED_LIBRARY_TYPE STATIC)
endif()

if(VCPKG_TARGET_IS_WINDOWS AND USE_VULKAN_BACKEND)
    # ANGLE on Windows dynamically loads vulkan-1.dll from the build folder (no clue about other platforms yet)
    list(APPEND CONFIG_TARGET_LIBRARIES vulkan-1)
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


# Hack for deploying dynamically loaded DLLs. See Qt5, Magnum and OpenNI2 ports for other examples of similar hacks.
# (VCPKG is currently missing a system for having ports specify "plugins", a.k.a. dynamically loaded DLLs on Windows)
if(VCPKG_TARGET_IS_WINDOWS)
    debug_message("VCPKG_BUILD_TYPE is ${VCPKG_BUILD_TYPE}")

    if(NOT DEFINED VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "debug")
        file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/angledeploy.ps1" DESTINATION "${CURRENT_PACKAGES_DIR}/debug/tools/unofficial-angle")
    endif()

    if(NOT DEFINED VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "release")
        file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/angledeploy.ps1" DESTINATION "${CURRENT_PACKAGES_DIR}/tools/unofficial-angle")
    endif()
endif()


# Copyright and usage
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
configure_file("${CMAKE_CURRENT_LIST_DIR}/usage.in" "${CURRENT_PACKAGES_DIR}/share/${PORT}/usage" @ONLY)
