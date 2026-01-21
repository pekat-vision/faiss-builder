# Copyright (c) Meta Platforms, Inc. and affiliates.
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

from __future__ import print_function

import os
import platform
import shutil
import glob

from setuptools import setup
from setuptools.dist import Distribution


# Tell setuptools this is a platform-specific binary wheel
class BinaryDistribution(Distribution):
    def has_ext_modules(self):
        return True


# make the faiss python package dir
shutil.rmtree("faiss", ignore_errors=True)
os.mkdir("faiss")

# Windows: Bundle MKL DLLs (but not libiomp5md.dll - use PyTorch's OpenMP)
if platform.system() == "Windows":
    import sys

    mkl_dlls = [
        "mkl_avx2.2.dll",
        "mkl_core.2.dll",
        "mkl_def.2.dll",
        "mkl_intel_thread.2.dll",
        "mkl_rt.2.dll",
        "mkl_vml_avx2.2.dll",
        "mkl_vml_cmpt.2.dll",
        "mkl_vml_def.2.dll",
    ]


    # Find MKL DLLs in current Python env Library/bin (pip, mkl-dev, conda)
    mkl_dirs = []
    py_lib_bin = os.path.join(sys.prefix, "Library", "bin")
    # if os.path.isdir(py_lib_bin):
    mkl_dirs.append(py_lib_bin)

    # Fallback to Intel oneAPI MKL default path
    mkl_dirs.append(r"C:\Program Files (x86)\Intel\oneAPI\mkl\latest\bin")

    for dll in mkl_dlls:
        found = False
        for mkl_base in mkl_dirs:
            src = os.path.join(mkl_base, dll)
            print(f"Looking for {src}")
            if os.path.exists(src):
                print(f"Bundling {dll} from {src}")
                shutil.copyfile(src, f"faiss/{dll}")
                found = True
                break
        if not found:
            print(f"Warning: {dll} not found in any known MKL location")

long_description = """
Faiss is a library for efficient similarity search and clustering of dense
vectors. It contains algorithms that search in sets of vectors of any size,
up to ones that possibly do not fit in RAM. It also contains supporting
code for evaluation and parameter tuning. Faiss is written in C++ with
complete wrappers for Python/numpy. Some of the most useful algorithms
are implemented on the GPU. It is developed by Facebook AI Research.
"""
setup(
    name="faiss",
    version="1.13.2+wingpu",
    description="A library for efficient similarity search and clustering of dense vectors",
    long_description=long_description,
    long_description_content_type="text/plain",
    url="https://github.com/facebookresearch/faiss",
    author="Matthijs Douze, Jeff Johnson, Herve Jegou, Lucas Hosseini",
    author_email="faiss@meta.com",
    license="MIT",
    keywords="search nearest neighbors",
    install_requires=["numpy>=1.21,<2.0", "packaging"],
    packages=["faiss", "faiss.contrib", "faiss.contrib.torch"],
    package_data={
        "faiss": ["*.so", "*.pyd", "*.a", "*.dll"],
    },
    zip_safe=False,
    distclass=BinaryDistribution,
)
