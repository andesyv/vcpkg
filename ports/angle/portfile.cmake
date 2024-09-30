vcpkg_check_linkage(ONLY_DYNAMIC_LIBRARY) # Only dynamic linkage is supported as of now

include("${CMAKE_CURRENT_LIST_DIR}/angle-functions.cmake")

if(VCPKG_TARGET_IS_LINUX)
    message(WARNING "${PORT} currently only supports CLang on Linux")
    # Full list of dependencies is available through <angle source>/build/install-build-deps.py
    # TODO: Update list
    message(WARNING "${PORT} currently requires the following libraries from the system package manager:\n    libx11-dev\n    mesa-common-dev\n    libxi-dev\n    libxext-dev\n\nThese can be installed on Ubuntu systems via apt-get install libx11-dev mesa-common-dev libxi-dev libxext-dev.")
elseif(VCPKG_TARGET_IS_WINDOWS)
    # Windows 10 SDK 10.0.22621 (with debugging tools) is required on Windows
    # Currently supported SDK versions can be found in (<angle source>/build/vs_toolchain.py)
    verify_windows_sdk(
        SDK_VERSION "10.0.22621"
        CHECK_FOR_DEBUGGING_TOOLS # ANGLE additionally requires "debugging tools" enabled for the SDK
    )

    string(REGEX REPLACE "\\\\+$" "" WindowsSdkDir $ENV{WindowsSdkDir})
    string(APPEND GN_CONFIGURE_OPTIONS " windows_sdk_path=\"${WindowsSdkDir}\"")
endif()

# With the addition of the rust-toolchain pipeline, the python script extracting the rust-toolchain will fail if the Windows path limit is reached...
# Specifically, this sub-path is too long at 180 characters: /third_party/rust-toolchain/lib/rustlib/src/rust/vendor/libdbus-sys-0.2.5/vendor/dbus/test/data/valid-service-files/org.freedesktop.DBus.TestSuiteShellEchoServiceSuccess.service.in
# Limit is 42 as "/${PORT}/src/<git-hash>.clean" adds an additional 38 characters bringing the total up to 38 + 180 = 218 characters, which gives us 260 - 218 = 42 characters to work with
vcpkg_buildpath_length_warning(42)

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
if(VCPKG_HOST_IS_WINDOWS)
    get_filename_component(PYTHON3_EXT ${PYTHON3} EXT)
    file(CREATE_LINK ${PYTHON3} "${PYTHON3_PATH}/python3${PYTHON3_EXT}" COPY_ON_ERROR)
endif()




# chromium/6652
set(ANGLE_COMMIT fc65058c1593956a69d06cb556ec97b2cf67f5ee)
set(ANGLE_SHA512 1c273b1f4e00db9c39275222b4ed407e4bada2f7544f61e69ab130f00d91932ad07deff911f1185f7935417c498b516cda97f5a5b8f9e0e1d69f36716f4e0a28)

# The value of ANGLE_COMMIT_DATE is the output of
# git show -s --format="%ci" HEAD
# in a checked out ANGLE repo:
set(ANGLE_COMMIT_DATE "2024-09-06 23:33:02 +0000")
# The value of ANGLE_COMMIT_POSITION is the output of
# git rev-list HEAD --count
# in a checked out ANGLE repo:
set(ANGLE_COMMIT_POSITION 23816)

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
    "build https://chromium.googlesource.com/chromium/src/build.git 0f665af83d239a975953e7a4593927ece5148879 005-disable-thin-archive-generation.patch"
    "buildtools https://chromium.googlesource.com/chromium/src/buildtools.git 012c060b76f063701ba9749166dacc853dd9cc89"
    "testing https://chromium.googlesource.com/chromium/src/testing ad248e83d004cb24b0f5486d839ce708c4a604ca"
    "third_party/EGL-Registry/src https://chromium.googlesource.com/external/github.com/KhronosGroup/EGL-Registry 7dea2ed79187cd13f76183c4b9100159b9e3e071"
    "third_party/OpenCL-CTS/src https://chromium.googlesource.com/external/github.com/KhronosGroup/OpenCL-CTS e0a31a03fc8f816d59fd8b3051ac6a61d3fa50c6"
    "third_party/OpenCL-Docs/src https://chromium.googlesource.com/external/github.com/KhronosGroup/OpenCL-Docs 774114e8761920b976d538d47fad8178d05984ec"
    "third_party/OpenCL-ICD-Loader/src https://chromium.googlesource.com/external/github.com/KhronosGroup/OpenCL-ICD-Loader 9b5e3849b49a1448996c8b96ba086cd774d987db"
    "third_party/OpenGL-Registry/src https://chromium.googlesource.com/external/github.com/KhronosGroup/OpenGL-Registry 5bae8738b23d06968e7c3a41308568120943ae77"
    "third_party/Python-Markdown https://chromium.googlesource.com/chromium/src/third_party/Python-Markdown 0f4473546172a64636f5d841410c564c0edad625"
    "third_party/SwiftShader https://swiftshader.googlesource.com/SwiftShader 5561c71fa64e5f7f726f74f23a8aac5cc308d18a"
    "third_party/VK-GL-CTS/src https://chromium.googlesource.com/external/github.com/KhronosGroup/VK-GL-CTS 7d2299e67fe7c84f6ae883962ff080487f091e1d"
    "third_party/abseil-cpp https://chromium.googlesource.com/chromium/src/third_party/abseil-cpp ea8a06debe2dc70afb1a257dd75f89ba056a526f"
    "third_party/astc-encoder/src https://chromium.googlesource.com/external/github.com/ARM-software/astc-encoder 573c475389bf51d16a5c3fc8348092e094e50e8f"
    "third_party/catapult https://chromium.googlesource.com/catapult.git 1b83be0f9678815742dbd6114be0bdc4478bd047"
    "third_party/cherry https://android.googlesource.com/platform/external/cherry 4f8fb08d33ca5ff05a1c638f04c85bbb8d8b52cc"
    "third_party/clang-format/script https://chromium.googlesource.com/external/github.com/llvm/llvm-project/clang/tools/clang-format.git 3c0acd2d4e73dd911309d9e970ba09d58bf23a62"
    "third_party/clspv/src https://chromium.googlesource.com/external/github.com/google/clspv a173c052455434a422bcfe5c12ffe44d574fd6e1"
    "third_party/dawn https://dawn.googlesource.com/dawn.git 1eca38fa52364bf66c0d288a0537a2813d72b39b 006-disable-gclient-hooks-dawn.patch"
    "third_party/depot_tools https://chromium.googlesource.com/chromium/tools/depot_tools.git 43691064b48769d3b084d8feee29990f2bd70dff"
    "third_party/glmark2/src https://chromium.googlesource.com/external/github.com/glmark2/glmark2 ca8de51fedb70bace5351c6b002eb952c747e889"
    "third_party/glslang/src https://chromium.googlesource.com/external/github.com/KhronosGroup/glslang a496a34b439022750d41d2ba04fbbe416ef81c9a"
    "third_party/googletest https://chromium.googlesource.com/chromium/src/third_party/googletest 17bbed2084d3127bd7bcd27283f18d7a5861bea8"
    "third_party/jinja2 https://chromium.googlesource.com/chromium/src/third_party/jinja2 2f6f2ff5e4c1d727377f5e1b9e1903d871f41e74"
    "third_party/jsoncpp https://chromium.googlesource.com/chromium/src/third_party/jsoncpp f62d44704b4da6014aa231cfc116e7fd29617d2a"
    "third_party/libc++/src https://chromium.googlesource.com/external/github.com/llvm/llvm-project/libcxx.git a4812f9f726e74b536daccdc8756e9bca5736886"
    "third_party/libc++abi/src https://chromium.googlesource.com/external/github.com/llvm/llvm-project/libcxxabi.git 11b62edaf245bb83bc259c37f269446cb34ef01e"
    "third_party/libdrm https://chromium.googlesource.com/chromiumos/third_party/libdrm 474894ed17a037a464e5bd845a0765a50f647898"
    "third_party/libjpeg_turbo https://chromium.googlesource.com/chromium/deps/libjpeg_turbo.git 4426a8da65e8d1eb652210d0c5b3a339e05aec01"
    "third_party/libpng/src https://android.googlesource.com/platform/external/libpng d2ece84bd73af1cd5fae5e7574f79b40e5de4fba"
    "third_party/libunwind/src https://chromium.googlesource.com/external/github.com/llvm/llvm-project/libunwind.git dc70138c3e68e2f946585f134e20815851e26263"
    "third_party/llvm/src https://chromium.googlesource.com/external/github.com/llvm/llvm-project d222fa4521531cc4ac14b8e157d231c108c003be"
    "third_party/lunarg-vulkantools/src https://chromium.googlesource.com/external/github.com/LunarG/VulkanTools a24a94aa0d1fc4e5556bdf9c6b2afe8eacc55326"
    "third_party/markupsafe https://chromium.googlesource.com/chromium/src/third_party/markupsafe 6638e9b0a79afc2ff7edd9e84b518fe7d5d5fea9"
    "third_party/nasm https://chromium.googlesource.com/chromium/deps/nasm.git f477acb1049f5e043904b87b825c5915084a9a29"
    "third_party/protobuf https://chromium.googlesource.com/chromium/src/third_party/protobuf da2fe725b80ac0ba646fbf77d0ce5b4ac236f823"
    "third_party/rapidjson/src https://chromium.googlesource.com/external/github.com/Tencent/rapidjson 781a4e667d84aeedbeb8184b7b62425ea66ec59f"
    "third_party/spirv-cross/src https://chromium.googlesource.com/external/github.com/KhronosGroup/SPIRV-Cross b8fcf307f1f347089e3c46eb4451d27f32ebc8d3"
    "third_party/spirv-headers/src https://chromium.googlesource.com/external/github.com/KhronosGroup/SPIRV-Headers efb6b4099ddb8fa60f62956dee592c4b94ec6a49"
    "third_party/spirv-tools/src https://chromium.googlesource.com/external/github.com/KhronosGroup/SPIRV-Tools e1782d6675b88225225e331a6318554d473c54db"
    "third_party/vulkan-deps https://chromium.googlesource.com/vulkan-deps 725499142cb601efc3f66bdb16d75843c0760478 007-disable-gclient-hooks-vulkan-deps.patch"
    "third_party/vulkan-headers/src https://chromium.googlesource.com/external/github.com/KhronosGroup/Vulkan-Headers c6391a7b8cd57e79ce6b6c832c8e3043c4d9967b"
    "third_party/vulkan-loader/src https://chromium.googlesource.com/external/github.com/KhronosGroup/Vulkan-Loader c758bac8bf1580b5018adafd3a2ec709237b0134"
    "third_party/vulkan-tools/src https://chromium.googlesource.com/external/github.com/KhronosGroup/Vulkan-Tools 4c63e845962ff3b197855f3ae4907a47d0863f5a"
    "third_party/vulkan-utility-libraries/src https://chromium.googlesource.com/external/github.com/KhronosGroup/Vulkan-Utility-Libraries fbb4db92c6b2ac09003b2b8e5ceb978f4f2dda71"
    "third_party/vulkan-validation-layers/src https://chromium.googlesource.com/external/github.com/KhronosGroup/Vulkan-ValidationLayers af7b0a35d009b5ad6e0b280a5b81388608ebfe39"
    "third_party/vulkan_memory_allocator https://chromium.googlesource.com/external/github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator 56300b29fbfcc693ee6609ddad3fdd5b7a449a21"
    "third_party/zlib https://chromium.googlesource.com/chromium/src/third_party/zlib d3aea2341cdeaf7e717bc257a59aa7a9407d318a"
    "tools/clang https://chromium.googlesource.com/chromium/src/tools/clang.git 5208ebe9c2e5e20b332798f99501e3faaaa059b6"
    "tools/mb https://chromium.googlesource.com/chromium/src/tools/mb 6417f436c78b355ef2e02485789acbeae1ca4e10"
    "tools/md_browser https://chromium.googlesource.com/chromium/src/tools/md_browser 6cc8e58a83412dc31de6fb7614fadb0b51748d4b"
    "tools/memory https://chromium.googlesource.com/chromium/src/tools/memory a7bb45e874cd595c082fdbf9697afe3b49dcb9ae"
    "tools/perf https://chromium.googlesource.com/chromium/src/tools/perf 9da6470c4783a9c170230758e336b9de0b39c503"
    "tools/protoc_wrapper https://chromium.googlesource.com/chromium/src/tools/protoc_wrapper dbcbea90c20ae1ece442d8ef64e61c7b10e2b013"
    "tools/rust https://chromium.googlesource.com/chromium/src/tools/rust.git 24da716443785814f2425c0160f88220e7b8b486"
    "tools/valgrind https://chromium.googlesource.com/chromium/src/tools/valgrind f9f02d66abacbb6b1bf00573b7426ec6dc767b38"
)

if(VCPKG_TARGET_IS_LINUX)
    checkout_dependencies(
        "third_party/wayland https://chromium.googlesource.com/angle/angle.git fc65058c1593956a69d06cb556ec97b2cf67f5ee"
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
    vcpkg_replace_string("${SOURCE_PATH}/src/commit_id.py" "commit_id = [^\n]+\n" "commit_id = '${ANGLE_COMMIT_ID}'\n" REGEX)
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

vcpkg_execute_required_process(
    COMMAND "${PYTHON3}" "third_party/depot_tools/gclient.py" "runhooks"
    WORKING_DIRECTORY "${SOURCE_PATH}"
    LOGNAME "gclient-hooks-${TARGET_TRIPLET}"
)

if(NOT EXISTS "${SOURCE_PATH}/third_party/llvm-build")
    message(FATAL_ERROR "Hooks scripts failed to generate a required build utility")
endif()



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
    string(APPEND GN_CONFIGURE_OPTIONS " is_clang=false")
else()
    # Force ninja to build using CLang on all unix platforms. Building with GCC seems to fail as only libc++ is
    # being properly linked (and not libstdc++).
    string(APPEND GN_CONFIGURE_OPTIONS " is_clang=true")
endif()

string(APPEND GN_CONFIGURE_OPTIONS " build_with_chromium=false")
string(APPEND GN_CONFIGURE_OPTIONS " use_dummy_lastchange=true")

string(APPEND GN_CONFIGURE_OPTIONS " target_cpu=\"${VCPKG_TARGET_ARCHITECTURE}\"")
string(APPEND GN_CONFIGURE_OPTIONS " angle_build_tests=false")

if(VCPKG_LIBRARY_LINKAGE STREQUAL dynamic)
    string(APPEND GN_CONFIGURE_OPTIONS " is_component_build=true")
else()
    string(APPEND GN_CONFIGURE_OPTIONS " is_component_build=false")
endif()

string(STRIP "${GN_CONFIGURE_OPTIONS}" GN_CONFIGURE_OPTIONS)
set(GN_CONFIGURE_OPTIONS_DEBUG "${GN_CONFIGURE_OPTIONS} is_debug=true")
set(GN_CONFIGURE_OPTIONS_RELEASE "${GN_CONFIGURE_OPTIONS} is_debug=false")

# By default, frame capture is enabled for all ANGLE builds. This allows one to trace what OpenGL calls were
# translated to in the backend. While useful in debug builds, it adds some runtime overhead which is usually
# not desired in release builds.
string(APPEND GN_CONFIGURE_OPTIONS_RELEASE " angle_has_frame_capture=false")

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
