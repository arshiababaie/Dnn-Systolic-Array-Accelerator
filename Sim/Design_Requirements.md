README
Matrix Multiplication Accelerator Test Vectors

This folder contains test vectors and expected outputs for a 4x4 matrix multiplication accelerator.
The accelerator computes:
C = A × B + Bias

Files in this folder:
- README.txt: brief usage instructions
- ALL_TESTS_SUMMARY.txt: summary of all test cases
- combined_test_vectors.txt  you should prepare the final test vector in proper format (BIN or HEX) from this data. 

Data format:
- Input and weight values are signed 8-bit integers
- Output values are signed 18-bit signed integers
- All matrices are 4x4. (For testing the bonus section, you are required to design the test scenarios yourself.)
- Values are stored in row-major order

How to use:

1. convert each test-vector into two txt file for loading to MEM_IN and MEM_WB. 
2. Load files into memories.
3. Run the accelerator in simulation.
4. Compare the produced 4x4 output with the results.
5. Use ALL_TESTS_SUMMARY.txt for a quick overview of the test cases.

Notes:
- Some tests include negative values.
- One test is designed to verify the need for 18-bit output width.
- One test includes a row of zeros in the expected output.
