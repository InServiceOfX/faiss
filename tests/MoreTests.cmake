set(FAISS_MORE_TESTS_SRC
  test_more_ivfpq_indexing.cpp 
)

add_executable(faiss_more_tests ${FAISS_MORE_TESTS_SRC})

if(NOT FAISS_OPT_LEVEL STREQUAL "avx2" AND NOT FAISS_OPT_LEVEL STREQUAL "avx512")
  target_link_libraries(faiss_more_tests PRIVATE faiss)
endif()

if(FAISS_OPT_LEVEL STREQUAL "avx2")
  # Linux/Unix
  target_compile_options(faiss_more_tests PRIVATE $<$<COMPILE_LANGUAGE:CXX>:-mavx2 -mfma>)

  target_link_libraries(faiss_more_tests PRIVATE faiss_avx2)
endif()

if(FAISS_OPT_LEVEL STREQUAL "avx512")
  # Linux/Unix
  target_compile_options(faiss_more_tests PRIVATE $<$<COMPILE_LANGUAGE:CXX>:-mavx2 -mfma -mavx512f -mavx512f -mavx512cd -mavx512vl -mavx512dq -mavx512bw>)
  target_link_libraries(faiss_more_tests PRIVATE faiss_avx512)
endif()

include(FetchContent)
FetchContent_Declare(googletest
  URL "https://github.com/google/googletest/archive/release-1.12.1.tar.gz")
set(BUILD_GMOCK CACHE BOOL OFF)
set(INSTALL_GTEST CACHE BOOL OFF)
FetchContent_MakeAvailable(googletest)

find_package(OpenMP REQUIRED)

target_link_libraries(faiss_more_tests PRIVATE
  OpenMP::OpenMP_CXX
  gtest_main
  $<$<BOOL:${FAISS_ENABLE_RAFT}>:raft::raft>
)

# Defines `gtest_discover_tests()`.
include(GoogleTest)
gtest_discover_tests(faiss_more_tests)