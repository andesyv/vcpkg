cmake_minimum_required(VERSION 3.10)

project(perceptualdiff)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

if(NOT MSVC)
    add_compile_options(
        -Wall -Wextra -pedantic -Wcast-qual -Wpointer-arith -Winit-self
        -Wswitch-default -Wmissing-include-dirs -Wold-style-cast
        -Wnon-virtual-dtor -Wshadow -Wno-unknown-pragmas)
endif()

# The library supports OpenMP, but support for this has not been enabled in this port for now
# option(USE_OPENMP "Use OpenMP" FALSE)
# if(USE_OPENMP)
#     find_package(OpenMP CONFIG REQUIED)
#     add_compile_options(${OpenMP_CXX_FLAGS})
#     if(NOT MSVC)
#         set(CMAKE_EXE_LINKER_FLAGS
#             "${CMAKE_EXE_LINKER_FLAGS} ${OpenMP_CXX_FLAGS}")
#     endif()
# endif()

# option(SANITIZERS "Enable sanitizers" FALSE)
# if(SANITIZERS)
#     add_compile_options(-fsanitize=address,undefined -fno-omit-frame-pointer)
#     set(CMAKE_EXE_LINKER_FLAGS
#         "${CMAKE_EXE_LINKER_FLAGS} -fsanitize=address,undefined")
# endif()

find_package(FreeImage CONFIG REQUIRED)
include(GNUInstallDirs)


# Executable with 
add_library(pdiff lpyramid.cpp rgba_image.cpp metric.cpp)
target_link_libraries(pdiff PUBLIC freeimage::FreeImage)
include(GenerateExportHeader)
generate_export_header(pdiff)
target_include_directories(pdiff PUBLIC
    "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>"
    "$<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}>"
    "$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>"
)
list(APPEND PUBLIC_HEADERS
    lpyramid.h
    rgba_image.h
    metric.h
    exceptions.h
    ${CMAKE_CURRENT_BINARY_DIR}/pdiff_export.h
)
install(TARGETS pdiff
    EXPORT "${PROJECT_NAME}Targets"
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)
install(FILES ${PUBLIC_HEADERS} DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/${PROJECT_NAME}")


# Install cmake exportable targets, package configuration and dist files
set(PACKAGE_CONFIG_DIR "${CMAKE_INSTALL_DATAROOTDIR}/${PROJECT_NAME}")
install(EXPORT "${PROJECT_NAME}Targets"
    FILE "${PROJECT_NAME}Targets.cmake"
    DESTINATION "${PACKAGE_CONFIG_DIR}"
    NAMESPACE ${PROJECT_NAME}::
)
install(FILES LICENSE DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/${PROJECT_NAME}")
include(CMakePackageConfigHelpers)
write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
    VERSION "@VERSION@"
    COMPATIBILITY AnyNewerVersion
)
configure_package_config_file(${CMAKE_CURRENT_SOURCE_DIR}/config.cmake.in
    "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
    INSTALL_DESTINATION "${PACKAGE_CONFIG_DIR}"
)
install(FILES
    "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
    DESTINATION "${PACKAGE_CONFIG_DIR}"
)
