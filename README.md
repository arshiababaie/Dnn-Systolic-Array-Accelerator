# High-Performance Parameterized Systolic MAC Array Hardware Accelerator for Deep Neural Networks

A fully parameterized, pipelined hardware accelerator designed in synthesizable Verilog for accelerating matrix multiplication and bias accumulation ($D = A \times B + C$) in Deep Neural Networks (DNNs). The architecture integrates high-speed signed Wallace Tree multipliers, 18-bit Carry Lookahead Adders (CLA), and an autonomous 5-stage FSM controller.

---

## 🚀 Key Architectural Features

- **Matrix Computation Pipeline:** Computes $D_{M \times N} = (A_{M \times K} \times B_{K \times N}) + C_{M \times N}$ in real-time.
- **Hardware-Level Precision & Overflow Protection:**
  - **Inputs & Weights:** 8-bit signed Two's Complement ($[-128, 127]$).
  - **Multiplication Output:** 16-bit signed with dynamic sign extension.
  - **Accumulator & Output Bus:** 18-bit signed ($[-131,072, +131,071]$), analytically proven to guarantee zero overflow for peak accumulations ($[-65,152, +65,663]$).
- **Optimized Processing Element (PE):**
  - **Multiplier:** Tree-structured signed 8-bit **Wallace Tree Multiplier** using 16-bit Carry-Save Adders (CSA), achieving logarithmic delay $\mathcal{O}(\log_{3/2} N)$.
  - **Accumulator:** 18-bit **Carry Lookahead Adder (CLA)**, breaking ripple carry chains for minimal critical path delay.
- **Dataflow Strategy:** Pipelined Output-Stationary (OS) variant with skewed diagonal data feeding and direct bias pre-loading.
- **Scalable Parameterized Design:**
  - Configurable grid dimensions ($M, N \in \{1, 2, 4\}$) via Verilog `generate` statements.
  - Seamlessly reconfigures into a 1D vector dot-product engine for Fully Connected (FC) layers when $M = 1$.

---

## ⏱️ Performance & Timing Metrics

Based on the default $4 \times 4$ array configuration ($M = 4, N = 4$):

| Metric | Cycle Count / Formula | Description |
| :--- | :--- | :--- |
| **Memory Load Latency ($T_{LOAD}$)** | $2 \text{ cycles}$ | Memory interface synchronization and spatial flattening |
| **Compute Cycles ($T_{COMPUTE}$)** | $(M + 2N - 1) = 11 \text{ cycles}$ | Skewed stream injection ($M+N-1$) + array drain ($N$) |
| **Output Setup Latency ($T_{LATCH}$)** | $2 \text{ cycles}$ | Output buffer snapshot and bus capture |
| **Total Processing Latency** | $\mathbf{15 \text{ clock cycles}}$ | From `start` trigger to the first valid output (`out_valid`) |
| **Sustained Readout Throughput** | $\mathbf{1 \text{ valid data / cycle}}$ | Continuous 18-bit data streaming across sequential addresses |
| **Total Block Execution Time** | $\mathbf{31 \text{ clock cycles}}$ | Total operation window until `done` flag asserts |

---

## 🔄 Finite State Machine (FSM)

The hardware pipeline is orchestrated by a 5-state synchronous controller:
$$\text{IDLE} \longrightarrow \text{LOAD} \longrightarrow \text{COMPUTE} \longrightarrow \text{WRITEBACK} \longrightarrow \text{DONE}$$

1. **IDLE:** Waits for `start` pulse with low power consumption.
2. **LOAD (2 cycles):** Reads `IN.txt` and `WB.txt`, loads biases into accumulators, and prepares skewed data busses.
3. **COMPUTE (11 cycles):** Streams data diagonally through PEs with systolic neighbor-to-neighbor propagation.
4. **WRITEBACK (17 cycles):** Latches the $4 \times 4$ matrix and serializes 18-bit outputs with corresponding 4-bit addresses (`out_addr: 0 to 15`).
5. **DONE (1 cycle):** Asserts `done` pulse to signal downstream processing completion.

---

## 📁 Directory Layout

- `rtl/` : Synthesizable Verilog modules (`systolic_array_top.v`, `pe.v`, `wallace_tree_8bit_signed.v`, `cla_18bit.v`, etc.).
- `docs/` : Technical report (`Systolic_MAC_Accelerator_Final_Report.pdf`), specifications, and reference papers.
- `waveforms/` : Simulation waveforms verifying latency, throughput, and state transitions.

---

## 🧪 Simulation & Verification

The accelerator has been verified using **Mentor Graphics QuestaSim / ModelSim** across 5 distinct test vectors covering random, signed, boundary, and corner cases:
- Clock Frequency: $100 \text{ MHz}$ ($T = 10 \text{ ns}$)
- 100% test vector match against pre-calculated golden outputs.
