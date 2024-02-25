# Build Notes

## Cmake version

For Ubuntu 22.04 LTS, apt repository for cmake uses version 3.22.1. This is found by running `apt policy cmake`.

Note that while the rapids AI version is "23.12" in `fetch_rapids.cmake`, as of 20240217, `rapids-cmake` has branch-24.04 as its latest.

Thus, we need to update cmake to a version equal to or greater than 3.23 from kitware.

## apt package requirements

- Intel oneAPI Math Kernel Library (oneMKL), as opposed to OpenBLAS, for linear algebra routines on the CPU.
  * see https://www.intel.com/content/www/us/en/developer/tools/oneapi/onemkl-download.html?operatingsystem=linux
  * ```
	# Prerequisites for first-time users.
  wget -O- https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB \
  | gpg --dearmor | sudo tee /usr/share/keyrings/oneapi-archive-keyring.gpg > /dev/null

  # Add signed entry to APT sources and configure APT client to use Intel repository.
  echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" | sudo tee /etc/apt/sources.list.d/oneAPI.list

  sudo apt update

  sudo apt install intel-oneapi-mkl
  sudo apt install intel-oneapi-mkl-devel
  ```
  * The resulting library "should" be in `/opt/intel/oneapi/mkl/` and then the subdirectory named after the version or a symbolic link called `latest`, then `lib/`, e.g. `/opt/intel/oneapi/mkl/2024.0/lib/libmkl_rt.so.2`


- `SWIG` - Simplied Wrapper and Interface Generator allows calling of native functions (written in C or C++) by other languages (such as Python) for the Python bindings.
  * ```
	sudo apt-get install swig
	```

## Python package requirements

Setup up a virtual environment.

```
python3 -m venv ./venv/

# Activate the virtual environment.

source ./venvCPU/bin/activate
```
