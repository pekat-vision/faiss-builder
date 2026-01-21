import shutil
import platform
import os

if platform.system() == "Windows":
    import sys
    import site

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
    if os.path.isdir(py_lib_bin):
        mkl_dirs.append(py_lib_bin)

    # Fallback to Intel oneAPI MKL default path
    mkl_dirs.append(r"C:\Program Files (x86)\Intel\oneAPI\mkl\latest\bin")

    for dll in mkl_dlls:
        found = False
        for mkl_base in mkl_dirs:
            src = os.path.join(mkl_base, dll)
            if os.path.exists(src):
                print(f"Found {dll} in {src}")
                found = True
                break
        if not found:
            print(f"Warning: {dll} not found in any known MKL location")

