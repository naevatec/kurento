cmake_minimum_required(VERSION 3.5)

project("kurento-module-opencv-example")
message(STATUS "CMake project: ${PROJECT_NAME}")

include(GNUInstallDirs) # CMAKE_INSTALL_*

# Add CMake modules provided by the project, if any.
#list(INSERT CMAKE_MODULE_PATH 0 "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

find_package(KurentoUtils)
if(NOT KurentoUtils_FOUND)
  message(FATAL_ERROR "KurentoUtils not found; please install package 'kurento-cmake-utils'")
endif()

message("If CodeGenerator is not found, you need to install 'kurento-module-core' from the Kurento repository")
include(CodeGenerator)
get_values_from_model(PREFIX VALUE MODELS ${CMAKE_CURRENT_SOURCE_DIR}/src/server/interface KEYS version)

include(KurentoGitHelpers)
get_git_version(PROJECT_VERSION ${VALUE_VERSION})
message(STATUS "Project version: ${PROJECT_NAME}-${PROJECT_VERSION}")

# Compiler flags
include(CommonBuildFlags)
common_buildflags_set()
#common_buildflags_print()

# Development: Add here exceptions to the "Warnings are Errors" rule.
# Also, DOCUMENT WHY and always remove them as soon as the problem is fixed.
# For example:
#set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-error=unused-function")
#set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-error=unused-variable")

# Disable error when macros __TIME__, __DATE__ or __TIMESTAMP__ are encountered
include(CheckCXXCompilerFlag)
CHECK_CXX_COMPILER_FLAG("-Wno-error=date-time" HAS_WARNING_DATE_TIME)
if(HAS_WARNING_DATE_TIME)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-error=date-time")
endif()

string(REPLACE "." ";" VERSION_LIST ${PROJECT_VERSION})
list(GET VERSION_LIST 0 PROJECT_VERSION_MAJOR)
list(LENGTH VERSION_LIST _len)
if(${_len} GREATER 1)
  list(GET VERSION_LIST 1 PROJECT_VERSION_MINOR)
endif()
if(${_len} GREATER 2)
  list(GET VERSION_LIST 2 PROJECT_VERSION_PATCH)
endif()

set(GST_REQUIRED ^1.0.0)
set(OPENCV_REQUIRED <5.0.0)

find_package(PkgConfig)
pkg_check_modules(GSTREAMER REQUIRED gstreamer-1.0>=${GST_REQUIRED})

include(GenericFind)
generic_find(LIBNAME KMSCORE VERSION ^7.0.0 REQUIRED)
generic_find(LIBNAME OpenCV VERSION ${OPENCV_REQUIRED} REQUIRED)

# Generate file "config.h"
set(VERSION "${PROJECT_VERSION}")
set(PACKAGE "${PROJECT_NAME}")
set(GETTEXT_PACKAGE "${PROJECT_NAME}")
set(KURENTO_MODULES_SO_DIR "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}/${KURENTO_MODULES_DIR_INSTALL_PREFIX}")
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/config.h.cmake ${CMAKE_CURRENT_BINARY_DIR}/config.h)
set(CMAKE_C_FLAGS   "${CMAKE_C_FLAGS}   -DHAVE_CONFIG_H")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DHAVE_CONFIG_H")

include_directories(${CMAKE_CURRENT_BINARY_DIR})
include_directories(${CMAKE_CURRENT_SOURCE_DIR})

add_subdirectory(src)
