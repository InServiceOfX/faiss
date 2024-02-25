################################################################################
## CCACHE package
################################################################################

FIND_PROGRAM(CCACHE_FOUND ccache)

IF(CCACHE_FOUND)
  MESSAGE(STATUS "CCache Found, setting CXX_COMPILER_LAUNCHER")
  SET(CMAKE_CXX_COMPILER_LAUNCHER ccache)
ELSE()
  MESSAGE(STATUS "CCache not Found")
ENDIF()