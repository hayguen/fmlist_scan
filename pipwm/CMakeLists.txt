project (pipwm)

if (NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release)
  message(STATUS "Build type not specified: defaulting to Release.")
endif()

add_executable (pipwm pwm.c)

target_link_libraries (pipwm LINK_PUBLIC wiringPi)
