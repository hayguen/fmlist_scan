cmake_minimum_required(VERSION 3.5)
project(prj_ana)

if (NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release)
  message(STATUS "Build type not specified: defaulting to Release.")
endif()

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

find_library(LIQUIDLIB NAMES liquid)
if(NOT LIQUIDLIB)
  message(FATAL_ERROR "Didn't find liquid library. install from https://github.com/jgaeddert/liquid-dsp/")
endif()

add_executable( checkSpectrumForCarrier ${CMAKE_CURRENT_LIST_DIR}/checkSpectrumForCarrier.cpp )

target_link_libraries( checkSpectrumForCarrier LINK_PUBLIC ${LIQUIDLIB} )
