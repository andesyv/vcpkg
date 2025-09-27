function(checkout_in_path_from_github)
  cmake_parse_arguments(PARSE_ARGV 0 arg "" PATH "")
  if(EXISTS "${arg_PATH}")
    file(GLOB FILES "${arg_PATH}/*")
    if(NOT "${FILES}" STREQUAL "")
      return()
    endif()
    file(REMOVE_RECURSE "${arg_PATH}")
  endif()

  vcpkg_from_github(
    OUT_SOURCE_PATH DEP_SOURCE_PATH
    ${arg_UNPARSED_ARGUMENTS}
  )
  file(RENAME "${DEP_SOURCE_PATH}" "${arg_PATH}")
  file(REMOVE_RECURSE "${DEP_SOURCE_PATH}")
endfunction()

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
  INVERTED_FEATURES
  d3d11       DILIGENT_NO_DIRECT3D11
  d3d12       DILIGENT_NO_DIRECT3D12
  gl          DILIGENT_NO_OPENGL
  metal       DILIGENT_NO_METAL
  vulkan      DILIGENT_NO_VULKAN
  webgpu      DILIGENT_NO_WEBGPU
)

vcpkg_from_github(
  OUT_SOURCE_PATH SOURCE_PATH
  REPO DiligentGraphics/DiligentCore
  REF v2.5.6
  SHA512 377242db5e3e92f3cffb592d2fd549c2505cc24bc1953e4ce343a129502906eb3f1414bcae716aa3c7e990e58a847f569f420ad49349c6d1d1d8aff3e83a0839
  HEAD_REF master
  PATCHES
    001-libc++-compile-fix.patch
)

# Required dependencies if building OpenGL, Metal, Vulkan or WebGPU backends
if(NOT DILIGENT_NO_OPENGL OR NOT DILIGENT_NO_METAL OR NOT DILIGENT_NO_VULKAN OR NOT DILIGENT_NO_WEBGPU)
  checkout_in_path_from_github(
    PATH "${SOURCE_PATH}/ThirdParty/SPIRV-Tools"
    REPO DiligentGraphics/SPIRV-Tools
    REF 421f81205ccea8baafa775915fcf588683c14119
    SHA512 6b8ebedd510ff46f7f495714a8c63cd27a83adb5c1028aa56d8784c397260cc018bb85bec764d1d981396c0b1a5ebb78c2c2187e637ce80e8dc3acd6c1bc7c05
  )

  checkout_in_path_from_github(
    PATH "${SOURCE_PATH}/ThirdParty/SPIRV-Cross"
    REPO DiligentGraphics/SPIRV-Cross
    REF 5d127b917f080c6f052553c47170ec0ba702e54f
    SHA512 37ffb8d5120768d43acebed7790e51441af3afaee1aabeb54486b4178dfc56e518d75b21cc4cdd3eee52e311d912adbd57a282ff6a440fb56cb18a4a3c6fc7cc
  )

  checkout_in_path_from_github(
    PATH "${SOURCE_PATH}/ThirdParty/SPIRV-Headers"
    REPO DiligentGraphics/SPIRV-Headers
    REF 2acb319af38d43be3ea76bfabf3998e5281d8d12
    SHA512 364ab8ea4a81b3589bd9e58d50c89d21859cb4a324b224f74ec7c371631f127c0e7f36d074436b6cba8a1919e83d3a3790baa94268b47862c28a2d3ca55fccfa
  )

  checkout_in_path_from_github(
    PATH "${SOURCE_PATH}/ThirdParty/glslang"
    REPO DiligentGraphics/glslang
    REF 3ecc2d9751b2a64621ad21b1bf89788d03a3d04e
    SHA512 38cf67d695a25e5b768c946adbe4f4927fdf827e48d0e02f2255d81e63dc20040fb82b6dfbac373567779d34196da2ab1a0cf7aed6fffb27eace856533696cc0
  )
endif()

if(NOT DILIGENT_NO_VULKAN)
  checkout_in_path_from_github(
    PATH "${SOURCE_PATH}/ThirdParty/volk"
    REPO DiligentGraphics/volk
    REF 466085407d5d2f50583fd663c1d65f93a7709d3e
    SHA512 08b9979f789f3041a943f95e363f65cbfea38048ffa82e100f948bc12abd0186a1fc45e58e65b61262b2786e44ac053eb86abc5d08ff4d11252fc3df5cfe2e67
  )

  checkout_in_path_from_github(
    PATH "${SOURCE_PATH}/ThirdParty/Vulkan-Headers"
    REPO DiligentGraphics/Vulkan-Headers
    REF b379292b2ab6df5771ba9870d53cf8b2c9295daf
    SHA512 ef317636fe959e0e9acabb8bb173810fccaecc797b8fb3c0a6d7ea7e739937117fe80e1878d1dc2e22e4bdf1faf4dc5e046203d868de8551fb2352ba88fcef80
  )
endif()

checkout_in_path_from_github(
  PATH "${SOURCE_PATH}/ThirdParty/xxHash"
  REPO DiligentGraphics/xxHash
  REF a57f6cce2698049863af8c25787084ae0489d849
  SHA512 151fd6365b9a54363c440db2d4d3ec6bde62f340cd8af8799fe69164a77c115cfcd1a25531a11d12c61eae90e77adc5b9a30491649e724c05131bcd8937f20d2
)

vcpkg_cmake_configure(
  SOURCE_PATH "${SOURCE_PATH}"
  OPTIONS
    ${FEATURE_OPTIONS}
#  MAYBE_UNUSED_VARIABLES
)

vcpkg_cmake_install()
#vcpkg_cmake_config_fixup() # Might not be needed
vcpkg_copy_pdbs()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

# Licenses are automatically installed to CURRENT_PACKAGES_DIR/Licenses. So let's join em to a single copyright file
# to be consistent with other VCPKG packages.
file(GLOB_RECURSE LICENSE_FILES "${CURRENT_PACKAGES_DIR}/Licenses/*")
vcpkg_install_copyright(FILE_LIST ${LICENSE_FILES})
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/Licenses")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/Licenses")
