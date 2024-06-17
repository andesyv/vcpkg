# TODO: https://cmake.org/cmake/help/latest/guide/importing-exporting/index.html
install(
  TARGETS libEGL libGLESv2
  EXPORT AngleTargets
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
  INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

install(EXPORT AngleTargets   )