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



// 3. host function

// 3.1 initialize Matrix
cudaError_t AllocateMatrix(float **matrix, int m, int n, int seed = 0){

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