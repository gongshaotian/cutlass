// Standard Libray includes
# include <iostream>
# include <sstream>
# include <vector>

// Helpers methods to check for errors
# include "helper.h"
// Define the generic GEMM computation tamplate class
# include "cutlass/gemm/device/gemm.h"


/* all matrices have column-major layout. */


// 1. use cutlass template and launch a GEMM kenel.
cudaError_t CutlassSgemmNN(
  int M,
  int N,
  int K,
  float alpha, float const *A, int lda,
  float const *B, int ldb,
  float beta, float const *C, int ldc
){
  // Define type definition for single-precision CUTLASS GEMM with column-major
  using ColumnMajor = cutlass::layout::ColumnMajor;
  using CutlassGemm = cutlass::gemm::device::Gemm<float,        // Data-type of A matrix
                                                  ColumnMajor,  // Layout of A Matirx
                                                  float ,       // Data-type of B matrix
                                                  ColumnMajor,  // Layout of B matrix
                                                  float,        // Data-type of C matrix
                                                  ColumnMajor>;
  CutlassGemm gemm_operator;

  // Construct the CUTLASS GEMM arguments object.
  CutlassGemm::Arguments args({M, N, K},       // Gemm Problem dimensions
                              {A, lda},        // Tensor-ref for source Matrix A
                              {B, ldb},        // Tensor-ref for source Matirx B
                              {C, ldc},        // Tensor-ref for source Matrix C
                              {C, ldc},        // Tensor-ref for destination matirx D
                              {alpha, beta});

  // Launch the CUTLASS GEMM kernel.
  cutlass::Status status = gemm_operator(args);

  if (status != cutlass::Status::kSuccess){
    return cudaErrorUnknown;
  }

  return cudaSuccess;
}



// 2. use generic CUDA and CUDA Runtime API implamented Naive reference GEMM kernel
__global__ void ReferenceGemm_kernel(int M, int N, int K,
  float alpha, float const *A, int lda,
  float const *B, int ldb,
  float beta, float const *C, int ldc
){
    // column_major layout
    int x = threadIdx.x + blockIdx.x * blockDim.x;
    int y = threadIdx.y + blockIdx.y * blockDimy;

    if (x < M && y < N){
       float accumulator = 0;

       for(int k = 0; k < K; ++k){
        accumulator += A[i + k * lda] * B[k + j * lda];  // A[i, k] * B[k, j]
       }

       C[i + j * ldc] = alpha * accumulator + beta * C[i + j * ldc];
    }
}


cudaError_t ReferenceGemm(
  int M, int N, int K,
  float alpha, float const *A, int lda, float const *B,
  int ldb, float beta, float *C, int ldc){
    dim3 block(16, 16);
    dim3 grid((M + block.x -1)/ block.x, (N + block.y - 1)/block.y);

    ReferenceGemm_kernel<<<grid, block>>>(M, N, K, alpha, A, lda, B, ldb, beta, C, ldc);

    return cudaGetLastError();
}


// 3. Run Gemm
// 3.0 Generate arbitrary elements.
__global__ void InitializeMatrix_kernel(
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

    // Compute Leading Dimensions for each matrix
    int lda = M;     // A[M, K], Layout:column_major
    int ldb = K;     // B[K, N], Layout:column_major
    int ldc = M;     // C[M, N], Layout:column_major

    // Compute pointers to matrices in GPU device Memory.
    float *A;
    float *B;
    float *C_cutlass;
    float *C_reference;

if (!CheckResult(AllocateMatrix(A, M, K, seed=0))){
    return cudaUnKnown
}



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
