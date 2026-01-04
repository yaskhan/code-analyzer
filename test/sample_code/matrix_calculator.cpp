// Matrix Calculator Library
// Demonstrates C++ classes, templates, inheritance, and operators

#include <iostream>
#include <vector>
#include <stdexcept>
#include <cmath>
#include <memory>

/// Matrix dimension mismatch exception
class MatrixDimensionException : public std::runtime_error {
public:
    MatrixDimensionException(const std::string& message) 
        : std::runtime_error(message) {}
};

/// Base matrix class with template support
template<typename T>
class Matrix {
protected:
    std::vector<std::vector<T>> data;
    size_t rows;
    size_t cols;
    
public:
    /// Constructor with dimensions
    Matrix(size_t rows, size_t cols) : rows(rows), cols(cols) {
        data.resize(rows, std::vector<T>(cols, T()));
    }
    
    /// Constructor with initialization
    Matrix(std::initializer_list<std::initializer_list<T>> init) {
        rows = init.size();
        cols = init.begin()->size();
        data.resize(rows);
        
        size_t i = 0;
        for (auto& row : init) {
            data[i] = std::vector<T>(row);
            i++;
        }
    }
    
    /// Copy constructor
    Matrix(const Matrix& other) : rows(other.rows), cols(other.cols), data(other.data) {}
    
    /// Move constructor
    Matrix(Matrix&& other) noexcept : rows(other.rows), cols(other.cols), data(std::move(other.data)) {
        other.rows = 0;
        other.cols = 0;
    }
    
    /// Virtual destructor
    virtual ~Matrix() = default;
    
    /// Gets matrix dimensions
    std::pair<size_t, size_t> dimensions() const {
        return {rows, cols};
    }
    
    /// Element access with bounds checking
    T& at(size_t row, size_t col) {
        if (row >= rows || col >= cols) {
            throw MatrixDimensionException("Index out of bounds");
        }
        return data[row][col];
    }
    
    /// Const element access
    const T& at(size_t row, size_t col) const {
        if (row >= rows || col >= cols) {
            throw MatrixDimensionException("Index out of bounds");
        }
        return data[row][col];
    }
    
    /// Matrix addition
    Matrix operator+(const Matrix& other) const {
        if (rows != other.rows || cols != other.cols) {
            throw MatrixDimensionException("Matrix dimensions must match for addition");
        }
        
        Matrix result(*this);
        for (size_t i = 0; i < rows; i++) {
            for (size_t j = 0; j < cols; j++) {
                result.data[i][j] += other.data[i][j];
            }
        }
        return result;
    }
    
    /// Matrix subtraction
    Matrix operator-(const Matrix& other) const {
        if (rows != other.rows || cols != other.cols) {
            throw MatrixDimensionException("Matrix dimensions must match for subtraction");
        }
        
        Matrix result(*this);
        for (size_t i = 0; i < rows; i++) {
            for (size_t j = 0; j < cols; j++) {
                result.data[i][j] -= other.data[i][j];
            }
        }
        return result;
    }
    
    /// Matrix multiplication
    Matrix operator*(const Matrix& other) const {
        if (cols != other.rows) {
            throw MatrixDimensionException("Inner dimensions must match for multiplication");
        }
        
        Matrix result(rows, other.cols);
        for (size_t i = 0; i < rows; i++) {
            for (size_t j = 0; j < other.cols; j++) {
                result.data[i][j] = T();
                for (size_t k = 0; k < cols; k++) {
                    result.data[i][j] += data[i][k] * other.data[k][j];
                }
            }
        }
        return result;
    }
    
    /// Scalar multiplication
    Matrix operator*(T scalar) const {
        Matrix result(*this);
        for (auto& row : result.data) {
            for (auto& element : row) {
                element *= scalar;
            }
        }
        return result;
    }
    
    /// Prints matrix to output stream
    void print(std::ostream& os = std::cout) const {
        for (size_t i = 0; i < rows; i++) {
            for (size_t j = 0; j < cols; j++) {
                os << data[i][j];
                if (j < cols - 1) os << "\t";
            }
            os << std::endl;
        }
    }
    
    /// Gets matrix trace (sum of diagonal elements)
    T trace() const {
        if (rows != cols) {
            throw MatrixDimensionException("Trace is only defined for square matrices");
        }
        
        T result = T();
        for (size_t i = 0; i < rows; i++) {
            result += data[i][i];
        }
        return result;
    }
    
    /// Checks if matrix is square
    bool is_square() const {
        return rows == cols;
    }
    
    /// Transposes the matrix
    Matrix transpose() const {
        Matrix result(cols, rows);
        for (size_t i = 0; i < rows; i++) {
            for (size_t j = 0; j < cols; j++) {
                result.data[j][i] = data[i][j];
            }
        }
        return result;
    }
};

/// Specialization for double matrices
using DoubleMatrix = Matrix<double>;

/// Specialization for integer matrices
using IntMatrix = Matrix<int>;

/// Square matrix class with additional operations
template<typename T>
class SquareMatrix : public Matrix<T> {
public:
    using Matrix<T>::Matrix;
    
    /// Constructor from general matrix (checks if square)
    SquareMatrix(const Matrix<T>& matrix) {
        if (!matrix.is_square()) {
            throw MatrixDimensionException("Matrix must be square");
        }
        this->data = matrix.data;
        this->rows = matrix.rows;
        this->cols = matrix.cols;
    }
    
    /// Calculates matrix determinant
    T determinant() const {
        if (!this->is_square()) {
            throw MatrixDimensionException("Determinant is only defined for square matrices");
        }
        
        size_t n = this->rows;
        if (n == 1) {
            return this->data[0][0];
        } else if (n == 2) {
            return this->data[0][0] * this->data[1][1] - this->data[0][1] * this->data[1][0];
        }
        
        // For larger matrices, use simple cofactor expansion
        T det = T();
        for (size_t j = 0; j < n; j++) {
            SquareMatrix<T> minor = get_minor(0, j);
            T cofactor = ((j % 2 == 0) ? 1 : -1) * this->data[0][j] * minor.determinant();
            det += cofactor;
        }
        return det;
    }
    
    /// Gets minor matrix (removes specified row and column)
    SquareMatrix<T> get_minor(size_t remove_row, size_t remove_col) const {
        size_t n = this->rows - 1;
        SquareMatrix<T> minor(n);
        
        for (size_t i = 0, minor_i = 0; i < this->rows; i++) {
            if (i == remove_row) continue;
            for (size_t j = 0, minor_j = 0; j < this->cols; j++) {
                if (j == remove_col) continue;
                minor.data[minor_i][minor_j] = this->data[i][j];
                minor_j++;
            }
            minor_i++;
        }
        return minor;
    }
    
    /// Checks if matrix is identity matrix
    bool is_identity() const {
        if (!this->is_square()) return false;
        
        for (size_t i = 0; i < this->rows; i++) {
            for (size_t j = 0; j < this->cols; j++) {
                if (i == j) {
                    if (this->data[i][j] != T(1)) return false;
                } else {
                    if (this->data[i][j] != T(0)) return false;
                }
            }
        }
        return true;
    }
};

/// Matrix calculator utility class
class MatrixCalculator {
private:
    std::unique_ptr<DoubleMatrix> cache;
    
public:
    MatrixCalculator() : cache(nullptr) {}
    
    /// Calculates matrix inverse using Gauss-Jordan elimination
    /// @param matrix Matrix to invert
    /// @returns Inverse matrix
    static DoubleMatrix inverse(const DoubleMatrix& matrix) {
        if (!matrix.is_square()) {
            throw MatrixDimensionException("Can only invert square matrices");
        }
        
        size_t n = std::get<0>(matrix.dimensions());
        DoubleMatrix result(n, n);
        
        // Initialize result as identity matrix
        for (size_t i = 0; i < n; i++) {
            result.at(i, i) = 1.0;
        }
        
        // Create augmented matrix [A|I]
        std::vector<std::vector<double>> augmented(n, std::vector<double>(2*n));
        for (size_t i = 0; i < n; i++) {
            for (size_t j = 0; j < n; j++) {
                augmented[i][j] = matrix.at(i, j);
                augmented[i][j + n] = result.at(i, j);
            }
        }
        
        // Gauss-Jordan elimination
        for (size_t i = 0; i < n; i++) {
            // Find pivot
            double pivot = augmented[i][i];
            if (std::abs(pivot) < 1e-10) {
                throw std::runtime_error("Matrix is singular");
            }
            
            // Normalize pivot row
            for (size_t j = 0; j < 2*n; j++) {
                augmented[i][j] /= pivot;
            }
            
            // Eliminate column
            for (size_t k = 0; k < n; k++) {
                if (k != i) {
                    double factor = augmented[k][i];
                    for (size_t j = 0; j < 2*n; j++) {
                        augmented[k][j] -= factor * augmented[i][j];
                    }
                }
            }
        }
        
        // Extract inverse matrix
        for (size_t i = 0; i < n; i++) {
            for (size_t j = 0; j < n; j++) {
                result.at(i, j) = augmented[i][j + n];
            }
        }
        
        return result;
    }
    
    /// Performs singular value decomposition (simplified)
    /// @param matrix Matrix to decompose
    /// @returns Tuple of (U, S, V^T) matrices
    static std::tuple<DoubleMatrix, DoubleMatrix, DoubleMatrix> svd(const DoubleMatrix& matrix) {
        // Simplified SVD - in practice would use more sophisticated algorithms
        throw std::runtime_error("SVD not implemented in this example");
    }
    
    /// Solves system of linear equations Ax = b
    /// @param A Coefficient matrix
    /// @param b Right-hand side vector
    /// @returns Solution vector
    static std::vector<double> solve_linear_system(const DoubleMatrix& A, const std::vector<double>& b) {
        if (!A.is_square() || std::get<0>(A.dimensions()) != b.size()) {
            throw MatrixDimensionException("Invalid matrix dimensions for linear system");
        }
        
        // Use Gaussian elimination
        size_t n = std::get<0>(A.dimensions());
        DoubleMatrix augmented = A;
        
        // Convert b to matrix form
        for (size_t i = 0; i < n; i++) {
            augmented.data[i].push_back(b[i]);
        }
        
        // Forward elimination
        for (size_t i = 0; i < n; i++) {
            // Find pivot
            size_t max_row = i;
            for (size_t k = i + 1; k < n; k++) {
                if (std::abs(augmented.data[k][i]) > std::abs(augmented.data[max_row][i])) {
                    max_row = k;
                }
            }
            
            // Swap rows
            std::swap(augmented.data[i], augmented.data[max_row]);
            
            // Check for singular matrix
            if (std::abs(augmented.data[i][i]) < 1e-10) {
                throw std::runtime_error("Matrix is singular");
            }
            
            // Eliminate column
            for (size_t k = i + 1; k < n; k++) {
                double factor = augmented.data[k][i] / augmented.data[i][i];
                for (size_t j = i; j <= n; j++) {
                    augmented.data[k][j] -= factor * augmented.data[i][j];
                }
            }
        }
        
        // Back substitution
        std::vector<double> x(n);
        for (int i = n - 1; i >= 0; i--) {
            x[i] = augmented.data[i][n];
            for (size_t j = i + 1; j < n; j++) {
                x[i] -= augmented.data[i][j] * x[j];
            }
            x[i] /= augmented.data[i][i];
        }
        
        return x;
    }
};

/// Example usage and testing
int main() {
    try {
        // Create test matrices
        DoubleMatrix A{{1, 2}, {3, 4}};
        DoubleMatrix B{{5, 6}, {7, 8}};
        
        std::cout << "Matrix A:" << std::endl;
        A.print();
        
        std::cout << "\nMatrix B:" << std::endl;
        B.print();
        
        std::cout << "\nA + B:" << std::endl;
        (A + B).print();
        
        std::cout << "\nA * B:" << std::endl;
        (A * B).print();
        
        // Test square matrix operations
        SquareMatrix<double> S = A;
        std::cout << "\nDeterminant of A: " << S.determinant() << std::endl;
        
        // Test inverse calculation
        DoubleMatrix I = MatrixCalculator::inverse(A);
        std::cout << "\nInverse of A:" << std::endl;
        I.print();
        
        // Test linear system solution
        std::vector<double> b = {5, 11};
        std::vector<double> x = MatrixCalculator::solve_linear_system(A, b);
        
        std::cout << "\nSolution to Ax = b:" << std::endl;
        for (double val : x) {
            std::cout << val << " ";
        }
        std::cout << std::endl;
        
    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return 1;
    }
    
    return 0;
}