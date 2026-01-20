& "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\Common7\Tools\Launch-VsDevShell.ps1" -Arch amd64 -HostArch amd64

Push-Location .\faiss

if (-not $env:CUDA_PATH) {
    $env:CUDA_PATH = "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.9"
}
$env:PATH = "$env:CUDA_PATH\bin;$env:PATH"  # $env:CUDA_PATH set by cuda action

$nvccPath = "$env:CUDA_PATH\bin\nvcc.exe"

Write-Host "Detected CUDA_PATH: $env:CUDA_PATH"
if (-not (Test-Path $nvccPath)) {
    Write-Error "NVCC executable not found at $nvccPath"
    Write-Host "Listing bin directory content:"
    Get-ChildItem "$env:CUDA_PATH\bin"
    exit 1
}

# Add CUDA bin to path for runtime DLLs
$env:PATH = "$env:CUDA_PATH\bin;$env:PATH"


# Use MKL from virtual environment
$pythonLibrary = "$env:pythonLocation\Library"

$env:MKLROOT = $pythonLibrary

# Get PyTorch's lib directory for OpenMP
$torchLib = python -c "import torch; import os; print(os.path.join(os.path.dirname(torch.__file__), 'lib'))"

cmake -G "Ninja" -B build . `
    -DCUDAToolkit_ROOT="$env:CUDA_PATH" `
    -DCMAKE_CUDA_COMPILER="$nvccPath" `
    -DCMAKE_PREFIX_PATH="$torchLib;$pythonLibrary;$env:CUDA_PATH\lib\cmake" `
    -DFAISS_ENABLE_GPU=ON `
    -DFAISS_ENABLE_PYTHON=ON `
    -DCMAKE_BUILD_TYPE=Release `
    -DCMAKE_CUDA_ARCHITECTURES="75;86;89;120" `
    -DBUILD_TESTING=OFF `
    -DCMAKE_INSTALL_PREFIX=install `
    -DFAISS_OPT_LEVEL=avx2 `
    -DBLA_VENDOR=Intel10_64lp `
    -DCMAKE_CXX_STANDARD=17 `
    -DCMAKE_CUDA_STANDARD=17 `
    
# Build
cmake --build build --parallel

# Install C++ library
cmake --install build

Pop-Location
