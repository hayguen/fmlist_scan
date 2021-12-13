
cmake_minimum_required(VERSION 3.5)
project(prj_prescanDAB LANGUAGES C CXX)

if (NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release)
  message(STATUS "Build type not specified: defaulting to Release.")
endif()

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# packages and libraries
list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake/Modules)

find_package(PkgConfig)
find_package(LibUSB)

set(THREADS_USE_PTHREADS_WIN32 true)
find_package(Threads REQUIRED)

pkg_check_modules (LIBRTLSDR_PKG librtlsdr)

find_path(RTLSDR_INCLUDE_DIR NAMES rtl-sdr.h
    HINTS
        $ENV{HOME}/.local/include
    PATHS
        ${LIBRTLSDR_PKG_INCLUDE_DIRS}
        /usr/include
        /usr/local/include
)

FIND_LIBRARY( RTLSDR NAMES librtlsdr.a
    HINTS
        $ENV{HOME}/.local/lib
    PATHS
        ${LIBRTLSDR_PKG_LIBRARY_DIRS}
        /usr/lib
        /usr/local/lib
)

if(NOT LIBUSB_FOUND)
    message(FATAL_ERROR "LibUSB 1.0 required to compile rtl-sdr")
endif()
if(NOT THREADS_FOUND)
    message(FATAL_ERROR "pthreads(-win32) required to compile rtl-sdr")
endif()


include_directories(
  ${RTLSDR_INCLUDE_DIR}
  ${LIBUSB_INCLUDE_DIR}
  ${THREADS_PTHREADS_INCLUDE_DIR}
)


# internal libs

add_library(convenience_static STATIC convenience/convenience.cpp)

if(WIN32)
  add_library(libgetopt_static STATIC getopt/getopt.cpp)
  target_link_libraries(convenience_static ${RTLSDR})
endif()


# executable

add_executable(prescanDAB prescanDAB.cpp band-handler.cpp)

# link libs
target_link_libraries(prescanDAB convenience_static ${RTLSDR} ${LIBUSB_LIBRARIES} ${CMAKE_THREAD_LIBS_INIT})

if(UNIX)
  target_link_libraries(prescanDAB m)
endif()

if(WIN32)
  target_link_libraries(prescanDAB libgetopt_static)
endif()

