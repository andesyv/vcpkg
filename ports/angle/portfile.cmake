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
  if (NOT VCPKG_TARGET_IS_MINGW)
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

function(checkout_in_path PATH URL REF)
    if(EXISTS "${PATH}")
        file(GLOB FILES "${PATH}/*")
        if(NOT "${FILES}" STREQUAL "")
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

# function(checkout_gh_in_path PATH REPO REF FILEHASH)
#     if(EXISTS "${PATH}")
#         file(GLOB FILES "${PATH}/")
#         list(LENGTH FILES COUNT)
#         if(COUNT GREATER 0)
#             return()
#         endif()
#         file(REMOVE_RECURSE "${PATH}")
#     endif()

#     vcpkg_from_github(
#         OUT_SOURCE_PATH DEP_SOURCE_PATH
#         REPO "${REPO}"
#         REF "${REF}"
#         SHA512 "${FILEHASH}"
#     )

#     file(RENAME "${DEP_SOURCE_PATH}" "${PATH}")
#     file(REMOVE_RECURSE "${DEP_SOURCE_PATH}")
# endfunction()


vcpkg_find_acquire_program(GIT)
get_filename_component(GIT_PATH ${GIT} DIRECTORY)
vcpkg_add_to_path(PREPEND "${GIT_PATH}")

# vcpkg_find_acquire_program(PYTHON3)
x_vcpkg_get_python_packages(PYTHON_VERSION "3" OUT_PYTHON_VAR "PYTHON3" PACKAGES httplib2)
get_filename_component(PYTHON3_PATH ${PYTHON3} DIRECTORY)
vcpkg_add_to_path(PREPEND "${PYTHON3_PATH}")
# GN on Windows expects python to be reachable as "python3"
if (WIN32)
    get_filename_component(PYTHON3_EXT ${PYTHON3} EXT)
    file (CREATE_LINK ${PYTHON3} "${PYTHON3_PATH}/python3${PYTHON3_EXT}" COPY_ON_ERROR)
endif ()

if(WIN32)
    # Windows 10 SDK >= (10.0.19041.0) is required
    # https://developer.microsoft.com/en-us/windows/downloads/windows-10-sdk
    SET(VCPKG_POLICY_SKIP_ARCHITECTURE_CHECK enabled)
    set(ENV{DEPOT_TOOLS_WIN_TOOLCHAIN} 0)
    # set(OPTIONS "${OPTIONS} use_lld=false")
endif()

# chromium/6070
# set(ANGLE_COMMIT 3dbf8ebc9348dd3362bafb73d0c13fc3b805e398)
set(ANGLE_COMMIT cd6b265c262346dca0c236b9bcc99f403a43197c)
# set(ANGLE_VERSION 6070)
set(ANGLE_SHA512 cc58e374877627d35d20ac9e8745725eb0b1545abc83c35078e907e9ca91b8583c33446801ca598690abde5a13934af41145ac7c5b99add822f52851fcd2b822)
# set(ANGLE_BUILD_SUBMODULE_COMMIT 306e127bcaedbdffb2a84754d64ebcdfbfebedbe)

# set(ANGLE_THIRDPARTY_ZLIB_COMMIT fef58692c1d7bec94c4ed3d030a45a1832a9615d)
# set(ANGLE_THIRDPARTY_JSONCPP_COMMIT f62d44704b4da6014aa231cfc116e7fd29617d2a)
# set(ANGLE_THIRDPARTY_VULKAN_DEPS_COMMIT 69081d0e32f7b9c29e215265fb9cd74e474e1253)
# set(ANGLE_THIRDPARTY_VULKAN_MEMORY_ALLOCATOR_COMMIT 56300b29fbfcc693ee6609ddad3fdd5b7a449a21)

vcpkg_check_features(OUT_FEATURE_OPTIONS feature_options
    FEATURES
        opengl      USE_OPENGL_BACKEND
        opengles    USE_OPENGLES_BACKEND
        vulkan      USE_VULKAN_BACKEND
        direct3d9   USE_D3D9_BACKEND
        direct3d11  USE_D3D11_BACKEND
        metal       USE_METAL_BACKEND
        null        USE_NULL_BACKEND
)

if (NOT USE_OPENGL_BACKEND AND NOT USE_VULKAN_BACKEND AND NOT USE_D3D9_BACKEND AND NOT USE_D3D11_BACKEND AND NOT USE_METAL_BACKEND AND NOT USE_NULL_BACKEND)
    message (FATAL_ERROR "At least one backend must be enabled")
endif ()

function(append_gn_option NAME VALUE)
    if ("${VALUE}" STREQUAL "ON")
        set (GN_CONFIGURE_OPTIONS "${GN_CONFIGURE_OPTIONS} ${NAME}=true" PARENT_SCOPE)
    else ()
        set (GN_CONFIGURE_OPTIONS "${GN_CONFIGURE_OPTIONS} ${NAME}=false" PARENT_SCOPE)
    endif ()
endfunction()

append_gn_option(angle_enable_gl ${USE_OPENGL_BACKEND})
append_gn_option(angle_enable_vulkan ${USE_VULKAN_BACKEND})
append_gn_option(angle_enable_d3d9 ${USE_D3D9_BACKEND})
append_gn_option(angle_enable_d3d11 ${USE_D3D11_BACKEND})
append_gn_option(angle_enable_metal ${USE_METAL_BACKEND})
append_gn_option(angle_enable_null ${USE_NULL_BACKEND})
# append_gn_option(angle_enable_glsl )
# append_gn_option(angle_enable_essl )

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
# set (DEPENDENCIES
#     "build https://chromium.googlesource.com/chromium/src/build.git b43af392a3e3acdd0a718a88011bbfe66104a93e"
#     "buildtools https://chromium.googlesource.com/chromium/src/buildtools.git 11e982b6f9b6fc82ee7e944bce094504f00b31bd"
#     "testing https://chromium.googlesource.com/chromium/src/testing e71c84911df3f4d2a1e2992845cb526e6ad3ed93"
#     "third_party/EGL-Registry/src https://chromium.googlesource.com/external/github.com/KhronosGroup/EGL-Registry 7dea2ed79187cd13f76183c4b9100159b9e3e071"
#     "third_party/OpenCL-Docs/src https://chromium.googlesource.com/external/github.com/KhronosGroup/OpenCL-Docs 774114e8761920b976d538d47fad8178d05984ec"
#     "third_party/OpenCL-ICD-Loader/src https://chromium.googlesource.com/external/github.com/KhronosGroup/OpenCL-ICD-Loader 9b5e3849b49a1448996c8b96ba086cd774d987db"
#     "third_party/OpenGL-Registry/src https://chromium.googlesource.com/external/github.com/KhronosGroup/OpenGL-Registry 5bae8738b23d06968e7c3a41308568120943ae77"
#     "third_party/Python-Markdown https://chromium.googlesource.com/chromium/src/third_party/Python-Markdown 0f4473546172a64636f5d841410c564c0edad625"
#     "third_party/SwiftShader https://swiftshader.googlesource.com/SwiftShader d9ec9befba05a8dfca09c1e88f3f7be0e4b153c6"
#     "third_party/VK-GL-CTS/src https://chromium.googlesource.com/external/github.com/KhronosGroup/VK-GL-CTS 7d738783bf286e82937e431c295d4682f3767267"
#     "third_party/abseil-cpp https://chromium.googlesource.com/chromium/src/third_party/abseil-cpp 16ed8d7d56105c49a0bbc04a428bf00dc7fadaf6"
#     "third_party/astc-encoder/src https://chromium.googlesource.com/external/github.com/ARM-software/astc-encoder 573c475389bf51d16a5c3fc8348092e094e50e8f"
#     "third_party/catapult https://chromium.googlesource.com/catapult.git e0c9c85d41d6229ecb4d3180347c60c146df4ce1"
#     "third_party/cherry https://android.googlesource.com/platform/external/cherry 4f8fb08d33ca5ff05a1c638f04c85bbb8d8b52cc"
#     "third_party/clang-format/script https://chromium.googlesource.com/external/github.com/llvm/llvm-project/clang/tools/clang-format.git e5337933f2951cacd3aeacd238ce4578163ca0b9"
#     "third_party/depot_tools https://chromium.googlesource.com/chromium/tools/depot_tools.git 27ea34f94ea114fec4fc4a10720492dbe8f3d738"
#     "third_party/glmark2/src https://chromium.googlesource.com/external/github.com/glmark2/glmark2 ca8de51fedb70bace5351c6b002eb952c747e889"
#     "third_party/googletest https://chromium.googlesource.com/chromium/src/third_party/googletest 17bbed2084d3127bd7bcd27283f18d7a5861bea8"
#     "third_party/jsoncpp https://chromium.googlesource.com/chromium/src/third_party/jsoncpp f62d44704b4da6014aa231cfc116e7fd29617d2a"
#     "third_party/libc++/src https://chromium.googlesource.com/external/github.com/llvm/llvm-project/libcxx.git d8fb829b953bebe10885d3fc389c46a7c3f82e59"
#     "third_party/libc++abi/src https://chromium.googlesource.com/external/github.com/llvm/llvm-project/libcxxabi.git 5acf60c8b985bffe197e2ffc2169850dec89348e"
#     "third_party/libjpeg_turbo https://chromium.googlesource.com/chromium/deps/libjpeg_turbo.git 9b894306ec3b28cea46e84c32b56773a98c483da"
#     "third_party/libpng/src https://android.googlesource.com/platform/external/libpng d2ece84bd73af1cd5fae5e7574f79b40e5de4fba"
#     "third_party/libunwind/src https://chromium.googlesource.com/external/github.com/llvm/llvm-project/libunwind.git 7686b5d38c69d14932abfb1c1a66ba56c78791ad"
#     "third_party/nasm https://chromium.googlesource.com/chromium/deps/nasm.git 7fc833e889d1afda72c06220e5bed8fb43b2e5ce"
#     "third_party/protobuf https://chromium.googlesource.com/chromium/src/third_party/protobuf b2f4cca357754462dd8b47f33a02b1b41d152441"
#     "third_party/rapidjson/src https://chromium.googlesource.com/external/github.com/Tencent/rapidjson 781a4e667d84aeedbeb8184b7b62425ea66ec59f"
#     "third_party/vulkan-deps https://chromium.googlesource.com/vulkan-deps 69081d0e32f7b9c29e215265fb9cd74e474e1253"
#     "third_party/vulkan_memory_allocator https://chromium.googlesource.com/external/github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator 56300b29fbfcc693ee6609ddad3fdd5b7a449a21"
#     "third_party/zlib https://chromium.googlesource.com/chromium/src/third_party/zlib dfc48fc4de8e80416606e2aab42f430ced2a524e"
#     "tools/clang https://chromium.googlesource.com/chromium/src/tools/clang.git 86aed39db276fb876a2b98c93cc6ff8940377903"
#     "tools/mb https://chromium.googlesource.com/chromium/src/tools/mb 573b2a1530a8aa0eae188fe154940f0e69693551"
#     "tools/md_browser https://chromium.googlesource.com/chromium/src/tools/md_browser 6cc8e58a83412dc31de6fb7614fadb0b51748d4b"
#     "tools/memory https://chromium.googlesource.com/chromium/src/tools/memory bb03b820532d620e753e91a1ef9de538753d6899"
#     "tools/perf https://chromium.googlesource.com/chromium/src/tools/perf f130da7870383426a5d0817ba6cbe0d1aa717be8"
#     "tools/protoc_wrapper https://chromium.googlesource.com/chromium/src/tools/protoc_wrapper b5ea227bd88235ab3ccda964d5f3819c4e2d8032"
#     "tools/valgrind https://chromium.googlesource.com/chromium/src/tools/valgrind e10259da244f75e52a681371f679d9ec095ff62a"
#     "third_party/googletest/src https://chromium.googlesource.com/external/github.com/google/googletest.git 2d924d7a971e9667d76ad09727fb2402b4f8a1e3"
#     "third_party/jsoncpp/source https://chromium.googlesource.com/external/github.com/open-source-parsers/jsoncpp.git 42e892d96e47b1f6e29844cc705e148ec4856448"
#     "third_party/vulkan-deps/glslang/src https://chromium.googlesource.com/external/github.com/KhronosGroup/glslang 7fa0731a803e8c02347756df41e0b606a4a34e2d"
#     "third_party/vulkan-deps/spirv-cross/src https://chromium.googlesource.com/external/github.com/KhronosGroup/SPIRV-Cross 2de1265fca722929785d9acdec4ab728c47a0254"
#     "third_party/vulkan-deps/spirv-headers/src https://chromium.googlesource.com/external/github.com/KhronosGroup/SPIRV-Headers 88bc5e321c2839707df8b1ab534e243e00744177"
#     "third_party/vulkan-deps/spirv-tools/src https://chromium.googlesource.com/external/github.com/KhronosGroup/SPIRV-Tools 73876defc8d9bd7ff42d5f71b15eb3db0cf86c65"
#     "third_party/vulkan-deps/vulkan-headers/src https://chromium.googlesource.com/external/github.com/KhronosGroup/Vulkan-Headers f4bfcd885214675a6a0d7d4df07f52b511e6ea16"
#     "third_party/vulkan-deps/vulkan-loader/src https://chromium.googlesource.com/external/github.com/KhronosGroup/Vulkan-Loader 131a081e083d20ed27114afc5a9f1420d556b362"
#     "third_party/vulkan-deps/vulkan-tools/src https://chromium.googlesource.com/external/github.com/KhronosGroup/Vulkan-Tools f7017f23337b90a2b2ceb65a4e1050e8ad89e065"
#     "third_party/vulkan-deps/vulkan-utility-libraries/src https://chromium.googlesource.com/external/github.com/KhronosGroup/Vulkan-Utility-Libraries dcfce25b439a2785f2c90b184e1964898070b4f1"
#     "third_party/vulkan-deps/vulkan-validation-layers/src https://chromium.googlesource.com/external/github.com/KhronosGroup/Vulkan-ValidationLayers cc1e12c6fc9bdb96ea3f259286ac036db6b68116"
# )

set (DEPENDENCIES
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

foreach (dep IN LISTS DEPENDENCIES)
    separate_arguments(dep_parts UNIX_COMMAND "${dep}")
    list(GET dep_parts 0 rel_path)
    list(GET dep_parts 1 repo)
    list(GET dep_parts 2 commit)

    checkout_in_path(
        "${SOURCE_PATH}/${rel_path}"
        "${repo}"
        "${commit}"
    )
endforeach ()

# Append depot_tools to path (needed for gclient down below)
vcpkg_add_to_path(PREPEND "${SOURCE_PATH}/third_party/depot_tools")

# checkout_in_path(
#     "${SOURCE_PATH}/build"
#     "https://chromium.googlesource.com/chromium/src/build"
#     "${ANGLE_BUILD_SUBMODULE_COMMIT}"
# )

# Generate gclient config file
file(WRITE "${SOURCE_PATH}/build/config/gclient_args.gni" "checkout_angle_internal = false\ncheckout_angle_mesa = false\ncheckout_angle_restricted_traces = false\ngenerate_location_tags = false\n")
file(COPY "${CMAKE_CURRENT_LIST_DIR}/res/testing" DESTINATION "${SOURCE_PATH}")
# The LASTCHANGE.committime file is generated by doing "build/util/lastchange.py -o build/util/LASTCHANGE" in a checked out ANGLE repo
file(COPY_FILE "${CMAKE_CURRENT_LIST_DIR}/res/LASTCHANGE.committime" "${SOURCE_PATH}/build/util/LASTCHANGE.committime")

# Fetch addition gclient distfiles by running hooks:
message(STATUS "Fetching additional distfiles via gclient hooks")
file(COPY_FILE "${CMAKE_CURRENT_LIST_DIR}/res/.gclient" "${SOURCE_PATH}/.gclient")
vcpkg_execute_required_process(
    COMMAND "${PYTHON3}" "third_party/depot_tools/gclient.py" "runhooks"
    WORKING_DIRECTORY "${SOURCE_PATH}"
    LOGNAME "gclient-hooks-${TARGET_TRIPLET}"
)

# if(WIN32 AND NOT $ENV{WindowsSdkDir} STREQUAL "")
# 	string(REGEX REPLACE "\\\\+$" "" WindowsSdkDir $ENV{WindowsSdkDir})
# 	file(APPEND "${SOURCE_PATH}/build/config/gclient_args.gni" "windows_sdk_path = \"${WindowsSdkDir}\"\n")
# endif()

# checkout_in_path(
#     "${SOURCE_PATH}/third_party/zlib"
#     "https://chromium.googlesource.com/chromium/src/third_party/zlib"
#     "${ANGLE_THIRDPARTY_ZLIB_COMMIT}"
# )

# checkout_in_path(
#     "${SOURCE_PATH}/third_party/jsoncpp"
#     "https://chromium.googlesource.com/chromium/src/third_party/jsoncpp"
#     "${ANGLE_THIRDPARTY_JSONCPP_COMMIT}"
# )

# Generate angle_commit.h
# set(ANGLE_COMMIT_HASH_SIZE 12)
# string(SUBSTRING "${ANGLE_COMMIT}" 0 ${ANGLE_COMMIT_HASH_SIZE} ANGLE_COMMIT_HASH)
# set(ANGLE_COMMIT_DATE "invalid-date")
# set(ANGLE_REVISION "${ANGLE_VERSION}")
# configure_file("${CMAKE_CURRENT_LIST_DIR}/angle_commit.h.in" "${SOURCE_PATH}/angle_commit.h" @ONLY)
# configure_file("${CMAKE_CURRENT_LIST_DIR}/angle_commit.h.in" "${SOURCE_PATH}/src/common/angle_commit.h" @ONLY)
# file(COPY "${CMAKE_CURRENT_LIST_DIR}/unofficial-angle-config.cmake" DESTINATION "${SOURCE_PATH}")

# set(ANGLE_WEBKIT_BUILDSYSTEM_COMMIT "3b928ce58d577d94a25fe6fba82be98a7638f3fb")

# # Download WebKit gni-to-cmake.py conversion script
# vcpkg_download_distfile(GNI_TO_CMAKE_PY
#     URLS "https://github.com/WebKit/WebKit/raw/${ANGLE_WEBKIT_BUILDSYSTEM_COMMIT}/Source/ThirdParty/ANGLE/gni-to-cmake.py"
#     FILENAME "gni-to-cmake.py"
#     SHA512 fb56e23f6295dd5eacd4205285898a88b60b391b666745d67899578e56abda5ab00f1da92fe70bf5aa511842231cae567c15718cf7bf4ce923db29119225d109
# )

# if (USE_VULKAN_BACKEND)
    
# endif ()

# Vulkan sources are required even when not building the Vulkan backend (could possibly optimize in the future with empty build files)
# checkout_in_path(
#     "${SOURCE_PATH}/third_party/vulkan_memory_allocator"
#     "https://chromium.googlesource.com/external/github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator"
#     "${ANGLE_THIRDPARTY_VULKAN_MEMORY_ALLOCATOR_COMMIT}"
# )

# checkout_in_path(
#     "${SOURCE_PATH}/third_party/vulkan-deps"
#     "https://chromium.googlesource.com/vulkan-deps"
#     "${ANGLE_THIRDPARTY_VULKAN_DEPS_COMMIT}"
# )

# # Fetched from ${SOURCE_PATH}/third_party/vulkan-deps/DEPS :
# set (VULKAN_SOURCES_TO_FETCH
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

# foreach(source IN LISTS VULKAN_SOURCES_TO_FETCH)
#     separate_arguments(checkout_values UNIX_COMMAND "${source}")
#     list(GET checkout_values 0 rel_path)
#     list(GET checkout_values 1 repo)
#     list(GET checkout_values 2 commit)

#     checkout_in_path(
#         "${SOURCE_PATH}/third_party/vulkan-deps/${rel_path}"
#         "https://github.com/KhronosGroup/${repo}.git"
#         "${commit}"
#     )
# endforeach()

# Generate CMake files from GN / GNI files
# x_vcpkg_get_python_packages(PYTHON_VERSION "3" OUT_PYTHON_VAR "PYTHON3" PACKAGES ply)

# set(_root_gni_files_to_convert
#   "compiler.gni Compiler.cmake"
#   "libGLESv2.gni GLESv2.cmake"
# )

# if (use_opengl_renderer OR use_opengles_renderer)
# list(APPEND _renderer_gn_files_to_convert "libANGLE/renderer/gl/BUILD.gn GL.cmake")
# endif ()

# if (use_direct3d9_renderer OR use_direct3d11_renderer)
# list(APPEND _renderer_gn_files_to_convert "libANGLE/renderer/d3d/BUILD.gn D3D.cmake")
# endif ()

# if (use_metal_renderer)
# list(APPEND _renderer_gn_files_to_convert "libANGLE/renderer/metal/BUILD.gn Metal.cmake")
# endif ()

# if (use_vulkan_renderer)
# list(APPEND _renderer_gn_files_to_convert "libANGLE/renderer/vulkan/BUILD.gn Vulkan.cmake")
# endif ()

# if (use_null_renderer)
# list(APPEND _renderer_gn_files_to_convert "libANGLE/renderer/null/BUILD.gn Null.cmake")
# endif ()

# foreach(_root_gni_file IN LISTS _root_gni_files_to_convert)
#   separate_arguments(_file_values UNIX_COMMAND "${_root_gni_file}")
#   list(GET _file_values 0 _src_gn_file)
#   list(GET _file_values 1 _dst_file)
#   vcpkg_execute_required_process(
#       COMMAND "${PYTHON3}" "${GNI_TO_CMAKE_PY}" "src/${_src_gn_file}" "${_dst_file}"
#       WORKING_DIRECTORY "${SOURCE_PATH}"
#       LOGNAME "gni-to-cmake-${_dst_file}-${TARGET_TRIPLET}"
#   )
# endforeach()

# foreach(_renderer_gn_file IN LISTS _renderer_gn_files_to_convert)
#   separate_arguments(_file_values UNIX_COMMAND "${_renderer_gn_file}")
#   list(GET _file_values 0 _src_gn_file)
#   list(GET _file_values 1 _dst_file)
#   get_filename_component(_src_dir "${_src_gn_file}" DIRECTORY)
#   vcpkg_execute_required_process(
#       COMMAND "${PYTHON3}" "${GNI_TO_CMAKE_PY}" "src/${_src_gn_file}" "${_dst_file}" --prepend "src/${_src_dir}/"
#       WORKING_DIRECTORY "${SOURCE_PATH}"
#       LOGNAME "gni-to-cmake-${_dst_file}-${TARGET_TRIPLET}"
#   )
# endforeach()

# Fetch additional CMake files from WebKit ANGLE buildsystem
# vcpkg_download_distfile(WK_ANGLE_INCLUDE_CMAKELISTS
#     URLS "https://github.com/WebKit/WebKit/raw/${ANGLE_WEBKIT_BUILDSYSTEM_COMMIT}/Source/ThirdParty/ANGLE/include/CMakeLists.txt"
#     FILENAME "include_CMakeLists.txt"
#     SHA512 a7ddf3c6df7565e232f87ec651cc4fd84240b8866609e23e3e6e41d22532fd34c70e0f3b06120fd3d6d930ca29c1d0d470d4c8cb7003a66f8c1a840a42f32949
# )
# configure_file("${WK_ANGLE_INCLUDE_CMAKELISTS}" "${SOURCE_PATH}/include/CMakeLists.txt" COPYONLY)

# vcpkg_download_distfile(WK_ANGLE_CMAKE_WEBKITCOMPILERFLAGS
#     URLS "https://github.com/WebKit/WebKit/raw/${ANGLE_WEBKIT_BUILDSYSTEM_COMMIT}/Source/cmake/WebKitCompilerFlags.cmake"
#     FILENAME "WebKitCompilerFlags.cmake"
#     SHA512 dd1b826c12051e872bfbcafde6a5c7ad1c805cc3d0d86b13c9ea2705ec732ca8151d765f304965b949fc5d0dee66676e32cef5498881edb5d84fa18715faa0bb
# )
# configure_file("${WK_ANGLE_CMAKE_WEBKITCOMPILERFLAGS}" "${SOURCE_PATH}/cmake/WebKitCompilerFlags.cmake" COPYONLY)

# vcpkg_download_distfile(WK_ANGLE_CMAKE_WEBKITMACROS
#     URLS "https://github.com/WebKit/WebKit/raw/${ANGLE_WEBKIT_BUILDSYSTEM_COMMIT}/Source/cmake/WebKitMacros.cmake"
#     FILENAME "WebKitMacros.cmake"
#     SHA512 2d6c38ca51f31e86c2bf68c74f8565e7248b7828ffaa94e91b665fe6e168dd202696e63b879372d1ccd7e9b9f143a2424dcbd37e6bd93a3ed6a8051834feddf0
# )
# configure_file("${WK_ANGLE_CMAKE_WEBKITMACROS}" "${SOURCE_PATH}/cmake/WebKitMacros.cmake" COPYONLY)

# vcpkg_download_distfile(WK_ANGLE_SHADER_PROGRAM_VERSION
#     URLS "https://github.com/WebKit/WebKit/raw/${ANGLE_WEBKIT_BUILDSYSTEM_COMMIT}/Source/ThirdParty/ANGLE/WebKit/ANGLEShaderProgramVersion.h"
#     FILENAME "ANGLEShaderProgramVersion.h"
#     SHA512 54987c82049fb5ca1d1cb7a3cac694f6077bc7e25af863ce4a4f64c37644e037b9ae4b5ed344b838e81a0ca60850a77b5438e931b820301931abb75008e7d6dd
# )
# configure_file("${WK_ANGLE_SHADER_PROGRAM_VERSION}" "${SOURCE_PATH}/src/ANGLEShaderProgramVersion.h" COPYONLY)

# Copy additional custom CMake buildsystem into appropriate folders
# file(GLOB MAIN_BUILDSYSTEM "${CMAKE_CURRENT_LIST_DIR}/cmake-buildsystem/CMakeLists.txt" "${CMAKE_CURRENT_LIST_DIR}/cmake-buildsystem/*.cmake")
# file(COPY ${MAIN_BUILDSYSTEM} DESTINATION "${SOURCE_PATH}")
# file(GLOB MODULES "${CMAKE_CURRENT_LIST_DIR}/cmake-buildsystem/cmake/*.cmake")
# file(COPY ${MODULES} DESTINATION "${SOURCE_PATH}/cmake")

# vcpkg_cmake_configure(
#     SOURCE_PATH "${SOURCE_PATH}"
#     OPTIONS_DEBUG -DDISABLE_INSTALL_HEADERS=1
#     OPTIONS
#         "-D${ANGLE_CPU_BITNESS}=1"
#         "-DPORT=${ANGLE_BUILDSYSTEM_PORT}"
#         "-DANGLE_USE_D3D11_COMPOSITOR_NATIVE_WINDOW=${ANGLE_USE_D3D11_COMPOSITOR_NATIVE_WINDOW}"
#         "-DVCPKG_TARGET_IS_WINDOWS=${VCPKG_TARGET_IS_WINDOWS}"
#         ${feature_options}
# )

# vcpkg_cmake_install()

# vcpkg_cmake_config_fixup(CONFIG_PATH share/unofficial-angle PACKAGE_NAME unofficial-angle)

# vcpkg_copy_pdbs()

# if(VCPKG_CMAKE_SYSTEM_NAME STREQUAL Linux)
#     set(OPTIONS "${OPTIONS} use_allocator=\"none\" use_sysroot=false use_glib=false")
# endif()

# set (GN_CONFIGURE_OPTIONS "${GN_CONFIGURE_OPTIONS} target_cpu=\"${VCPKG_TARGET_ARCHITECTURE}\" is_clang=false build_with_chromium=false libEGL_egl_loader_config=false")
set (GN_CONFIGURE_OPTIONS "${GN_CONFIGURE_OPTIONS} target_cpu=\"${VCPKG_TARGET_ARCHITECTURE}\" is_clang=false build_with_chromium=false")

if(VCPKG_LIBRARY_LINKAGE STREQUAL dynamic)
    set (GN_CONFIGURE_OPTIONS "${GN_CONFIGURE_OPTIONS} is_component_build=true")
    list(APPEND DEFINITIONS COMPONENT_BUILD)
    # set(targets :v8_libbase :v8_libplatform :v8)
else()
    set (GN_CONFIGURE_OPTIONS "${GN_CONFIGURE_OPTIONS} is_component_build=false")
    # set(targets :v8_monolith)
endif()

set (GN_CONFIGURE_OPTIONS_DEBUG "${GN_CONFIGURE_OPTIONS} is_debug=true")
set (GN_CONFIGURE_OPTIONS_RELEASE "${GN_CONFIGURE_OPTIONS} is_debug=false")

message("Configure options: ${GN_CONFIGURE_OPTIONS}")

vcpkg_gn_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS_DEBUG "${GN_CONFIGURE_OPTIONS_DEBUG}"
    OPTIONS_RELEASE "${GN_CONFIGURE_OPTIONS_RELEASE}"
)

# Prevent a ninja re-config loop
set(NINJA_REBUILD "build build.ninja: gn\n  generator = 1\n  depfile = build.ninja.d")
vcpkg_replace_string("${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg/build.ninja" "${NINJA_REBUILD}" "")
vcpkg_replace_string("${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/build.ninja" "${NINJA_REBUILD}" "")

set (BUILD_TARGETS :libEGL :libGLESv2)
set (LINK_TARGETS libEGL libGLESv2)
# if (USE_OPENGL_BACKEND)
#     list(APPEND BUILD_TARGETS src/libANGLE/renderer/gl:angle_gl_backend)
# endif ()

# if (USE_D3D11_BACKEND)
#     list(APPEND BUILD_TARGETS src/libANGLE/renderer/d3d:angle_d3d11_backend)
# endif ()

# if (USE_D3D9_BACKEND)
#     list(APPEND BUILD_TARGETS src/libANGLE/renderer/d3d:angle_d3d9_backend)
# endif ()

# if (USE_VULKAN_BACKEND)
#     list(APPEND BUILD_TARGETS src/libANGLE/renderer/vulkan:angle_vulkan_backend)
# endif ()

# # if (USE_METAL_BACKEND)
# #     list(APPEND BUILD_TARGETS src/libANGLE/renderer/metal:angle_metal_backend)
# # endif ()

# if (USE_NULL_BACKEND)
#     list(APPEND BUILD_TARGETS src/libANGLE/renderer/null:angle_null_backend)
# endif ()

message(STATUS "Building ANGLE with targets: ${BUILD_TARGETS}")

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

set(DEFINITIONS_DEBUG ${DEFINITIONS})
set(DEFINITIONS_RELEASE ${DEFINITIONS})
configure_file("${CMAKE_CURRENT_LIST_DIR}/unofficial-angle-config.cmake.in" "${CURRENT_PACKAGES_DIR}/share/${PORT}/unofficial-angle-config.cmake.in" @ONLY)

vcpkg_copy_pdbs()

# file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
# # Remove empty directories inside include directory
# file(GLOB directory_children RELATIVE "${CURRENT_PACKAGES_DIR}/include" "${CURRENT_PACKAGES_DIR}/include/*")
# foreach(directory_child ${directory_children})
# if(IS_DIRECTORY "${CURRENT_PACKAGES_DIR}/include/${directory_child}")
# file(GLOB_RECURSE subdirectory_children "${CURRENT_PACKAGES_DIR}/include/${directory_child}/*")
# if("${subdirectory_children}" STREQUAL "")
# file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/include/${directory_child}")
# endif()
# endif()
# endforeach()
# unset(subdirectory_children)
# unset(directory_child)
# unset(directory_children)

file(INSTALL "${SOURCE_PATH}/LICENSE" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)
file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
