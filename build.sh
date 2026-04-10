#!/bin/bash

set -e

cmake --version

# assume mkl-devel is installed in the virtual environment
pythonPrefix=$(python -c "import sys; print(sys.prefix)")

# Create symlinks for MKL libraries, otherwise CMake may not find them
echo "Creating symlinks for MKL libraries..."
pushd "$pythonPrefix/lib"
for lib in libmkl_*.so.2; do
    base="${lib%.2}"
    if [ ! -e "$base" ]; then
        ln -s "$lib" "$base"
        echo "  Created: $base -> $lib"
    fi
done

popd
pushd faiss

rm -rf ./build
    # -DCMAKE_CUDA_ARCHITECTURES="86" \

cmake -B build . \
    -DCMAKE_PREFIX_PATH="$pythonPrefix" \
    -DPython_EXECUTABLE="$(which python)" \
    -DFAISS_ENABLE_GPU=ON \
    -DFAISS_ENABLE_PYTHON=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CUDA_ARCHITECTURES="75;80;86;89;90;103;120" \
    -DBUILD_TESTING=OFF \
    -DCMAKE_INSTALL_PREFIX=install \
    -DCMAKE_INSTALL_RPATH='$ORIGIN/../../../' \
    -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON \
    -DFAISS_OPT_LEVEL=avx2 \
    -DBLA_VENDOR=Intel10_64lp \
    -DCMAKE_CXX_STANDARD=17 \
    -DCMAKE_CUDA_STANDARD=17

# Build
cmake --build build --parallel 8

# Install C++ library
cmake --install build

popd

pushd faiss/build/faiss/python

# Create wheel
python -m build --wheel

# Retag wheel with correct Python/ABI/platform tags
pythonTag="cp$(python -c 'import sys; print(str(sys.version_info.major) + str(sys.version_info.minor))')"
platformTag="$(python -c 'import platform; print("linux_" + platform.machine())')"
python -m wheel tags --python-tag "$pythonTag" --abi-tag "$pythonTag" --platform-tag "$platformTag" dist/faiss-*.whl

popd