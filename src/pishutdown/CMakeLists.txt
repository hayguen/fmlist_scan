project (pishutdown)

if (NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release)
  message(STATUS "Build type not specified: defaulting to Release.")
endif()

add_executable (pishutdown pishutdown.c)

target_link_libraries (pishutdown LINK_PUBLIC wiringPi)

message(STATUS "CMAKE_INSTALL_PREFIX is ${CMAKE_INSTALL_PREFIX}. change by calling cmake -DCMAKE_INSTALL_PREFIX=/usr/local." )
install(TARGETS pishutdown DESTINATION bin)
