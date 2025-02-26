// Standard Libray includes
# include <iostream>
# include <sstream>
# include <vector>

// Helpers methods to check for errors
# include "helper.h"
// Define the generic GEMM computation tamplate class
# include "cutlass/gemm/device/gemm.h"


// 1. use cutlass template and launch a GEMM kenel.



// 2. use generic CUDA and CUDA Runtime API implamented Naive reference GEMM kernel


// 3. Run Gemm
// 3.0 Generate arbitrary elements.
__global__ void IntializeMatrix_kernel(
    float *matrix,
    int rows,
    int columns,
    int seed = 0
){
    int i = threadIdx.x + blockIdx.x * blockDim.x;
    int y = threadIdx.y + blockIdx.y * blockDim.y;

    if ( i < row && j < columns){
        int offset = i + j * rows;

        // use Linear Congruential Generator generate arbitrary elements.
        int const k = 16807;
        int const m = 16;
        float value = float( ((k + seed) * k % m ) - m / 2);

        matrix[offset] = value;
    }
}

cudaError_t InitializeMatrix(float *matrix, int rows, int columns, int seed=0){
    dim3 block(16, 16);
    dim3 grid((rows + block.x -1 ) /block.x, (columns + block.y) / block.y);

    InitializeMatrix_kernel<<<grid, block>>>(matrix, rows, columns, seed);
}


// 3.1 allocate Matrix
cudaError_t AllocateMatrix(float **matrix, int rows, int columns, int seed = 0){
    cudaError_t result;

    size_t matrix_size = rows * columns * sizeof(float);
    result = cudaMalloc(reinterpret_cast<void **>matrix, matrix_size);
    if (result != cudaSuccess){
        std::cerr << "Failed to allocate matrix: " 
        << cudaGetErrorString(result) << std::endl;
        return result;
    }

    // clear matrix
    result = cudaMemset(*matrix, 0, matrix_size);
    if (result != cudaSuccess){
        std::cerr << "Failed to clear matrix device memory: "
        << cudaGetErrorString(result) << std::endl;
        return result;
    }

    result = InitializeMatrix(matrix, rows, columns, seed);
    if (result != cudaSuccess){
        std::cerr << "Failed to initialize matrix: "
        << cudaGetErrorString(result) << std::endl;
        return result;
    }

    return result;
}


// 3.2 launch GEMM kernel
cudaError_t TestCutlassAndReferenceGemm(){
    cudaError_t result;

    bool CheckResult = [&](cudaError_t result){
        return result == cudaSuccess;
    };




    return result;
}


// 3.3 main 
int main(){int argc, const char *arg[]}{
    // GEMM problem dimensions
    int problem[3] = {128, 128, 128};
    for (int i = 1; i < argc; ++i){
        std::stringstream ss(arg[i]);
        ss >> problem[i-1];
    }

    // Scalars used for linear scaling the result of the matrix product
    float scalars[2] = {1, 0};  // {alpha, beta}
    for (int i = 4; i < argc && i < 6; ++i){
        std::stringstream ss(arg[i]);
        ss >> scalars[i-4];
    }

    // run cutlass GEMM & reference GEMM
    cudaError_t result = TestCutlassAndReferenceGemm(
        problem[0],
        problem[1],
        problem[2],
        scalars[0],
        scalars[1]
    );
    
    if (result == cudaSuccess){
        std::cout << "Passed." << std::endl;
    }

    return result == cudaSuccess ? 0 : -1;
}