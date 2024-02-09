#!/bin/bash

# CMake options as variables, see
# https://github.com/ernestyalumni/faiss/blob/main/INSTALL.md

# -DFAISS_ENABLE_GPU=ON to enable build GPU indices
ENABLE_GPU="ON"
# -DFAISS_ENABLE_PYTHON=ON to enable building Python bindings (for use in,
# for example, in LangChain)
ENABLE_PYTHON="ON"
# -DFAISS_ENABLE_RAFT=ON - enables building RAFT implementations of IVF-Flat and
# IVF-PQ GPU-accelerated indices;
# RAFT (Rapid Analytics and Framework Toolkit) is a library for data science,
# graph learning.
# IVF-Flat, IVF-PQ are types of indexing methods used in FAISS;
# * IVF-Flat (Inverted File with Flat quantization) involves partitioning the
# 	feature space into smaller subsets or cells and then performing brute-force
# 	search within these partitions.
# * IVF-PQ (Inverted File with Product Quantization) uses a coarser quantizer
# 	combined with product quantization on residuals.
# See https://developer.nvidia.com/blog/accelerated-vector-search-approximating-with-rapids-raft-ivf-flat/
ENABLE_RAFT="ON"
# -DBUILD_TESTING=ON - to enable building C++ tests
ENABLE_TESTING="ON"
# -DBUILD_SHARED_LIBS=ON to build a shared library
SHARED_LIBS="ON"
# -DFAISS_ENABLE_C_API=ON in order to enable building C API
# Enable for future Rust bindings/API/interface.
C_API="ON"

## Optimization-Related Options
# Enable compiler to generate code using optimized SIMD instructions (possible
# values generic, avx2, avx512, increasing order of optimization
CPU_OPTIMIZATION_LEVEL="avx2"

run_cmake()
{
  local cmake_options="-DFAISS_ENABLE_GPU=${ENABLE_GPU} \
    -DFAISS_ENABLE_PYTHON=${ENABLE_PYTHON} \
    -DFAISS_ENABLE_RAFT=${ENABLE_RAFT} \
    -DBUILD_TESTING=${ENABLE_TESTING} \
    -DBUILD_SHARED_LIBS=${SHARED_LIBS} \
    -DFAISS_ENABLE_C_API=${C_API} \
    -DFAISS_OPT_LEVEL=${CPU_OPTIMIZATION_LEVEL}"

  cmake %{cmake_options}
}

main()
{
  run_cmake "$1"
}

main "$@"