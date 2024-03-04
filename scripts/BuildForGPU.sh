#!/bin/bash

# Usage:
# For no RAFT (NVIDIA's library), do
# bash BuildForGPU.sh --disable-raft
# Otherwise, do bash BuildForGPU.sh if you know RAFT had been installed.

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

# Default value is 75;72. `-DCMAKE_CUDA_ARCHITECTURES="75;72"` for specifying
# which GPU architectures to build against.
CUDA_ARCHITECTURES="75;72"

function print_help
{
  echo "Usage: $0 [-h|--help] [-b <build_directory>]"
  echo ""
  echo "Options:"
  echo "-h, --help               Print this help message."
  echo "-b, --build-dir <path>   Specify the path for the build directory. If not provided,"
  echo "                          'BuildGPU' will be used as the default value."
  echo "-r, --disable-raft       Disable RAFT implementation"
  exit 1
}

create_cmake_options()
{
  local cmake_options="-DFAISS_ENABLE_GPU=${ENABLE_GPU} \
    -DFAISS_ENABLE_PYTHON=${ENABLE_PYTHON} \
    -DFAISS_ENABLE_RAFT=${ENABLE_RAFT} \
    -DBUILD_TESTING=${ENABLE_TESTING} \
    -DBUILD_SHARED_LIBS=${SHARED_LIBS} \
    -DFAISS_ENABLE_C_API=${C_API} \
    -DFAISS_OPT_LEVEL=${CPU_OPTIMIZATION_LEVEL} \
    -DBLA_VENDOR=Intel10_64_dyn -DMKL_LIBRARIES=/opt/intel/oneapi/mkl/latest/lib/libmkl_rt.so.2 \
    -DCMAKE_CUDA_ARCHITECTURES=${CUDA_ARCHITECTURES}"

  echo $cmake_options
}

run_cmake()
{
  local cmake_options=$1
  echo "Build directory: $BUILD_DIR"
  echo "Parent directory: $parent_directory"
  cmake $cmake_options -B "$BUILD_DIR" "$parent_directory" 
}

run_make()
{
  make -C $BUILD_DIR
  make -C $BUILD_DIR -j faiss
  make -C $BUILD_DIR -j swigfaiss
  (cd $BUILD_DIR/faiss/python && python3 setup.py install)
}

run_with_sudo_optionally()
{
  local command=$1

  # Check if current user is root (user ID=0) or if sudo is not available
  if [ "$(id -u)" -eq 0 ] || ! command -v sudo &> /dev/null; then
    $command
  else
    sudo $command
  fi
}

main()
{
  # Parse command-line arguments
  while [[ $# -gt 0 ]]; do
      case "$1" in
          --build-dir)
              BUILD_DIR="$2"
              shift # past argument
              shift # past value
              ;;
          --disable-raft)
            ENABLE_RAFT="OFF"
            shift # past argument
            ;;
          --help)
              print_help
              exit 0
              ;;
          *)
              # Unknown option
              print_help
              exit 1
              ;;
      esac
  done

  # Install Intel oneAPI Math Kernel Library (oneMKL) if we hadn't already.
  # https://www.intel.com/content/www/us/en/developer/tools/oneapi/onemkl-download.html?operatingsystem=linux&distributions=aptpackagemanager

  if ! dpkg -l | grep -qw intel-oneapi-mkl-devel; then

    # Download the key to the system keyring, to set up the repository.
    wget -O- https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB \
    | gpg --dearmor \
    | run_with_sudo_optionally "tee /usr/share/keyrings/oneapi-archive-keyring.gpg" \
    > /dev/null

    # Add the signed entry to APT sources and configure the APT client to use the
    # Intel repository.
    echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" \
    | run_with_sudo_optionally "tee /etc/apt/sources.list.d/oneAPI.list"

    # Update the packages list and repository index.
    run_with_sudo_optionally "apt update"

    run_with_sudo_optionally "apt install -y intel-oneapi-mkl-devel"
    # Find the main MKL library file
    mkl_library=$(find /opt -type f -name "*libmkl_rt.so*")
  else
    echo "intel-oneapi-mkl-devel package already installed."
  fi

  script_directory=$(dirname "$0")
  parent_directory=$(dirname "$script_directory")
  echo "parent directory: $parent_directory"
  echo "$script_directory"
  cd "$script_directory"
  echo "current Dir"
  pwd

  # Get CUDA Architecture.
  source GetComputeCapability.sh
  CUDA_ARCHITECTURES=$(get_compute_capability_as_cuda_architecture)

  cd - || exit

  if [ -z "${BUILD_DIR:-}" ]; then
    BUILD_DIR="$parent_directory/BuildGPU"
  fi

  mkdir -p "${BUILD_DIR}" || exit

  # Capture the cmake options
  local cmake_options=$(create_cmake_options)

  run_cmake "$cmake_options"

  run_make
}

main "$@"