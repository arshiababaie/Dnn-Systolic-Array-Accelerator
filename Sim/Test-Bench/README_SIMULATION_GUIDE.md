README
4x4 Systolic Array Matrix Multiplication Accelerator

This folder contains the RTL source codes, automated testbench, and formatted memory data for the 4x4 matrix multiplication accelerator project. 

The accelerator core inherently computes:
C = A × B + Bias

----------------------------------------------------
Files in this folder:
----------------------------------------------------
1. Hardware RTL (Verilog Modules):
   - systolic_array_top.v : The top-level integration module.
   - controller.v         : System FSM managing load, stream, compute, and writeback.
   - input_loader.v       : Memory reader, reads [IN.txt, WB.txt] and skews streams dynamically.
   - systolic_array.v     : Core 4x4 interconnect logic mesh.
   - pe.v                 : Processing Element including low-latency Wallace Tree + CLA MAC unit.
   - output_collector.v   : Sequential readout synchronizer indexing specific bounds logically.

2. Testbench and Vectors:
   - tb_systolic_top.v    : Advanced automated validation environment.
   - IN.txt               : Input vector file containing Matrix A.
   - WB.txt               : Weights/Bias file containing Matrix B (first 16) & Bias (next 16).

----------------------------------------------------
Data format:
----------------------------------------------------
- Data files (IN.txt, WB.txt) contain vectors formatted as 2-digit HEX values per line.
- Input (A), weights (B), and bias values are signed 8-bit integers.
- Hardware Output/Accumulation is 18-bit signed precision strictly avoiding overflow cases.
- All core architectures act as 4x4 limits bounds (Row-Major format loading structure).

----------------------------------------------------
How to use (Simulation Steps):
----------------------------------------------------
1. Keep all `.v` files along with `IN.txt` and `WB.txt` inside your Simulation Working Directory (Important: Memory loader dynamically reads these text bounds from root).
2. Load/Compile all Verilog RTL components.
3. Select `tb_systolic_top.v` as your main testing component module.
4. Run the accelerator test in your simulator (QuestaSim/ModelSim/Vivado/Quartus , e.g.).
5. Open your software Console/Transcript panel! The fully automated testbench will print the system cycles output evaluation sequentially, dynamically cross-referencing math values and generating [PASSED/FAILED] results exactly!

----------------------------------------------------
Notes & Advanced Implementations implemented:
----------------------------------------------------
- Standard Delay Pipelines: Skew/propagation timing rules matching architectural constraints have been met flawlessly. 
- Processing Nodes: Designed with optimized Carry-Save Adder Wallace-Tree + Carry-Lookahead (CLA).
- Automated test framework inside the tb module triggers the top structure independently without needing forcing clocks or input signals manually.