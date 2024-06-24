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
set(ANGLE_COMMIT e53b3ad723227356913a0cd7635cd6575c5cb6a3)
set(ANGLE_SHA512 1aad8e7d694f9f9e68f8b5174963c2b41d12c16e4e548c13a60b4612e89abfb4fe170cc4d9ad1a51086dc067d9e9fcb3ac20f5d2b21f3c15cbc28028a6a10aac)

# The value of ANGLE_COMMIT_DATE is the output of
# git show -s --format="%ci" HEAD
# in a checked out ANGLE repo:
set(ANGLE_COMMIT_DATE "2024-06-20 21:23:26 +0000")
# The value of ANGLE_COMMIT_POSITION is the output of
# git rev-list HEAD --count
# in a checked out ANGLE repo:
set(ANGLE_COMMIT_POSITION 23367)

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
    "build https://chromium.googlesource.com/chromium/src/build.git 00b3ce0aadb3827aa59227a7a4c89e33e787886f"
    "buildtools https://chromium.googlesource.com/chromium/src/buildtools.git 7817c353d060281937d1c8b59004af11dcc95884"
    "testing https://chromium.googlesource.com/chromium/src/testing 7521f3b99ca11c493ff1654394e589b5ce24b2a8"
    "third_party/EGL-Registry/src https://chromium.googlesource.com/external/github.com/KhronosGroup/EGL-Registry 7dea2ed79187cd13f76183c4b9100159b9e3e071"
    "third_party/OpenCL-CTS/src https://chromium.googlesource.com/external/github.com/KhronosGroup/OpenCL-CTS e0a31a03fc8f816d59fd8b3051ac6a61d3fa50c6"
    "third_party/OpenCL-Docs/src https://chromium.googlesource.com/external/github.com/KhronosGroup/OpenCL-Docs 774114e8761920b976d538d47fad8178d05984ec"
    "third_party/OpenCL-ICD-Loader/src https://chromium.googlesource.com/external/github.com/KhronosGroup/OpenCL-ICD-Loader 9b5e3849b49a1448996c8b96ba086cd774d987db"
    "third_party/OpenGL-Registry/src https://chromium.googlesource.com/external/github.com/KhronosGroup/OpenGL-Registry 5bae8738b23d06968e7c3a41308568120943ae77"
    "third_party/Python-Markdown https://chromium.googlesource.com/chromium/src/third_party/Python-Markdown 0f4473546172a64636f5d841410c564c0edad625"
    "third_party/SwiftShader https://swiftshader.googlesource.com/SwiftShader cea33ab2d5ad50cd7f1881fb9c36ffcaecdd69fc"
    "third_party/VK-GL-CTS/src https://chromium.googlesource.com/external/github.com/KhronosGroup/VK-GL-CTS c201252e6fbeff96a52bebe1713cddf3021da7e0"
    "third_party/abseil-cpp https://chromium.googlesource.com/chromium/src/third_party/abseil-cpp 06aa1dc684a547bad9481599dc84cf50f6a1aa3b"
    "third_party/astc-encoder/src https://chromium.googlesource.com/external/github.com/ARM-software/astc-encoder 573c475389bf51d16a5c3fc8348092e094e50e8f"
    "third_party/catapult https://chromium.googlesource.com/catapult.git 1a0040059f507232fecfba0fc6982c73f81edbb8"
    "third_party/cherry https://android.googlesource.com/platform/external/cherry 4f8fb08d33ca5ff05a1c638f04c85bbb8d8b52cc"
    "third_party/clang-format/script https://chromium.googlesource.com/external/github.com/llvm/llvm-project/clang/tools/clang-format.git 3c0acd2d4e73dd911309d9e970ba09d58bf23a62"
    "third_party/clspv/src https://chromium.googlesource.com/external/github.com/google/clspv a173c052455434a422bcfe5c12ffe44d574fd6e1"
    "third_party/dawn https://dawn.googlesource.com/dawn.git 6cdf3a1a195fa8ce4aec963dee146a7da6f435b8"
    "third_party/depot_tools https://chromium.googlesource.com/chromium/tools/depot_tools.git 66df2a3ec70d0628d47df1fdba69838a870a1303"
    "third_party/glmark2/src https://chromium.googlesource.com/external/github.com/glmark2/glmark2 ca8de51fedb70bace5351c6b002eb952c747e889"
    "third_party/glslang/src https://chromium.googlesource.com/external/github.com/KhronosGroup/glslang 68a17eb72182d3dcfac834eed3512ea205eac9d1"
    "third_party/googletest https://chromium.googlesource.com/chromium/src/third_party/googletest 17bbed2084d3127bd7bcd27283f18d7a5861bea8"
    "third_party/jinja2 https://chromium.googlesource.com/chromium/src/third_party/jinja2 2f6f2ff5e4c1d727377f5e1b9e1903d871f41e74"
    "third_party/jsoncpp https://chromium.googlesource.com/chromium/src/third_party/jsoncpp f62d44704b4da6014aa231cfc116e7fd29617d2a"
    "third_party/libc++/src https://chromium.googlesource.com/external/github.com/llvm/llvm-project/libcxx.git 3be02c8f029027e954c805c01ba9f9906fd3d55d"
    "third_party/libc++abi/src https://chromium.googlesource.com/external/github.com/llvm/llvm-project/libcxxabi.git 472d9aad97ad38d294aa0634100a4a1c0b6b34b9"
    "third_party/libdrm https://chromium.googlesource.com/chromiumos/third_party/libdrm 474894ed17a037a464e5bd845a0765a50f647898"
    "third_party/libjpeg_turbo https://chromium.googlesource.com/chromium/deps/libjpeg_turbo.git ccfbe1c82a3b6dbe8647ceb36a3f9ee711fba3cf"
    "third_party/libpng/src https://android.googlesource.com/platform/external/libpng d2ece84bd73af1cd5fae5e7574f79b40e5de4fba"
    "third_party/libunwind/src https://chromium.googlesource.com/external/github.com/llvm/llvm-project/libunwind.git c8f1d81998280ae2ea0e76ddb60aae6e1b4b860e"
    "third_party/llvm/src https://chromium.googlesource.com/external/github.com/llvm/llvm-project d222fa4521531cc4ac14b8e157d231c108c003be"
    "third_party/lunarg-vulkantools/src https://chromium.googlesource.com/external/github.com/LunarG/VulkanTools 413b7630fa6005667c83133ee7475e14309d1d93"
    "third_party/markupsafe https://chromium.googlesource.com/chromium/src/third_party/markupsafe e582d7f0edb9d67499b0f5abd6ae5550e91da7f2"
    "third_party/nasm https://chromium.googlesource.com/chromium/deps/nasm.git f477acb1049f5e043904b87b825c5915084a9a29"
    "third_party/protobuf https://chromium.googlesource.com/chromium/src/third_party/protobuf ed9284c473211491ae6de41d60ac0329a79270d8"
    "third_party/rapidjson/src https://chromium.googlesource.com/external/github.com/Tencent/rapidjson 781a4e667d84aeedbeb8184b7b62425ea66ec59f"
    "third_party/spirv-cross/src https://chromium.googlesource.com/external/github.com/KhronosGroup/SPIRV-Cross b8fcf307f1f347089e3c46eb4451d27f32ebc8d3"
    "third_party/spirv-headers/src https://chromium.googlesource.com/external/github.com/KhronosGroup/SPIRV-Headers 2acb319af38d43be3ea76bfabf3998e5281d8d12"
    "third_party/spirv-tools/src https://chromium.googlesource.com/external/github.com/KhronosGroup/SPIRV-Tools 581279dedd59d8353322fc2d61be07ccdcad0f13"
    "third_party/vulkan-deps https://chromium.googlesource.com/vulkan-deps 83e9eca04a1ba6f6e13263bb649d9d52d7e0fc52"
    "third_party/vulkan-headers/src https://chromium.googlesource.com/external/github.com/KhronosGroup/Vulkan-Headers e3c37e6e184a232e10b01dff5a065ce48c047f88"
    "third_party/vulkan-loader/src https://chromium.googlesource.com/external/github.com/KhronosGroup/Vulkan-Loader db0d129d43bda308328f91b15a5409161fbd50b7"
    "third_party/vulkan-tools/src https://chromium.googlesource.com/external/github.com/KhronosGroup/Vulkan-Tools 345af476e583366352e014ee8e43fc5ddf421ab9"
    "third_party/vulkan-utility-libraries/src https://chromium.googlesource.com/external/github.com/KhronosGroup/Vulkan-Utility-Libraries 1b07de9a3a174b853833f7f87a824f20604266b9"
    "third_party/vulkan-validation-layers/src https://chromium.googlesource.com/external/github.com/KhronosGroup/Vulkan-ValidationLayers 3fb31803aa89b9f2df2f9dee9f36a7d0f7ab54bc"
    "third_party/vulkan_memory_allocator https://chromium.googlesource.com/external/github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator 56300b29fbfcc693ee6609ddad3fdd5b7a449a21"
    "third_party/zlib https://chromium.googlesource.com/chromium/src/third_party/zlib 887bb57a1b1d38e348bd39ac7c2e6b4b6d18b9f7"
    "tools/clang https://chromium.googlesource.com/chromium/src/tools/clang.git 4336d0b16d1bd1bfa26fac1a679c3872fa109d7e"
    "tools/mb https://chromium.googlesource.com/chromium/src/tools/mb 553093afa42f8cf16c0a038fbe2bc8614c124887"
    "tools/md_browser https://chromium.googlesource.com/chromium/src/tools/md_browser 6cc8e58a83412dc31de6fb7614fadb0b51748d4b"
    "tools/memory https://chromium.googlesource.com/chromium/src/tools/memory 4ac80c5c63dc6072c0fee9439b43121c64e1301b"
    "tools/perf https://chromium.googlesource.com/chromium/src/tools/perf b835a09cd99ffa21d4bef57c8db36b4407ff1c9a"
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
set(BUILD_TARGETS :libEGL :libGLESv2 third_party/zlib:zlib)
if(VCPKG_TARGET_IS_WINDOWS AND USE_VULKAN_BACKEND)
    # ANGLE on Windows dynamically loads vulkan-1.dll from the build folder (no clue about other platforms yet)
    list(APPEND BUILD_TARGETS third_party/vulkan-loader/src:libvulkan)
endif()


append_gn_option(is_clang OFF)
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
set(TARGET_LIBRARY_PREFIX_PATH "${CURRENT_PACKAGES_DIR}")
if(VCPKG_LIBRARY_LINKAGE STREQUAL dynamic)
    set(TARGET_IMPORTED_LIBRARY_TYPE SHARED)
else()
    set(TARGET_IMPORTED_LIBRARY_TYPE STATIC)
endif()

if(VCPKG_TARGET_IS_WINDOWS AND USE_VULKAN_BACKEND)
    # ANGLE on Windows dynamically loads vulkan-1.dll from the build folder (no clue about other platforms yet)
    set(ADDITIONAL_LIBRARY_TARGETS "vulkan-1")
else()
    set(ADDITIONAL_LIBRARY_TARGETS "")
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
