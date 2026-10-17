# VHDL Component for Differential Filtering from RAM

This repository implements a VHDL hardware module developed for the **Digital Logic Design (Reti Logiche)** final project at **Politecnico di Milano** (A.Y. 2024/2025). The component is designed to autonomously read a sequence of numerical data from an external RAM, apply a configurable differential filter, and write the processed results back into memory.

---

## Project Description

The core functionality is to read a 17-byte configuration header followed by a sequence of *K* signed 8-bit words (*W_i* in `[-128, +127]`) from a RAM, starting from a specified base address (`i_add`). Based on the configuration header, the component's task is to:

1. **Parse filter parameters**: Read the sequence length *K*, the filter selector byte *S* (Order 3 or Order 5), and the corresponding filter coefficients from memory.
2. **Apply a 7-sample sliding window**: Convolve each sample *W_i* and its neighbors with 7 filter coefficients, automatically inserting zero-padding (`0`) when window positions fall outside the sequence boundaries.
3. **Normalize and saturate**: Approximate division (`1/12` for Order 3, `1/60` for Order 5) via arithmetic right shifts with negative truncation compensation, clamping the final 8-bit result *R_i* to `[-128, +127]` before writing it sequentially to RAM.

---

## Features

- **Modular FSM-driven architecture** implemented in VHDL.
- **Configurable differential filtering** supporting both 3rd-order and 5th-order filters.
- **Automatic boundary padding** using a 7-byte FIFO sliding window with zero-injection.
- **Single-cycle MAC & combinational normalization** using shift-and-add arithmetic.
- **Synchronous design** with clock (`i_clk`), asynchronous reset (`i_rst`), and automatic internal reset between consecutive runs (`i_start`).
- **Synthesizable & timing-verified** on Xilinx Artix-7 FPGA (`+6.237 ns` positive slack at 50 MHz, 0 latches).

---

## Architecture

The component's architecture is structured around a central **Finite State Machine (`fsm`)** that coordinates five datapath submodules:

- **FSM States**: `IDLE`, `READ_MEM`, `READ_K1`, `READ_K2`, `READ_S`, `READ_COEFFS`, `INIT_WINDOW`, `APPLY_FILTER`, `WRITE_OUT`, `DONE`.
- **`sliding_window`**: 56-bit (7-byte) shift register storing the active sample window and handling zero-padding.
- **`mac_unit`**: 18-bit signed Multiply-Accumulate unit computing the convolution between the window and the 7 filter coefficients.
- **`normalization_unit`**: Combinational block performing shift-add division approximation, negative rounding correction, and `[-128, +127]` saturation.
- **`counter`**: 16-bit counter tracking the memory offset (`i_data_count`) across read and write phases.
- **`address_calculator`**: Combinational module computing read addresses (`i_add + count`) and write addresses (`i_add + 17 + K + count - 21`).

---

## Interface

The top-level VHDL entity `project_reti_logiche` defines the component's interface:

**Inputs**:
- `i_clk`: Clock signal.
- `i_rst`: Asynchronous reset signal.
- `i_start`: Start signal to initiate processing.
- `i_add`: 16-bit input vector for the starting RAM address.
- `i_mem_data`: 8-bit input vector read from RAM memory.

**Outputs**:
- `o_done`: 1-bit output signal indicating the completion of the processing sequence.
- `o_mem_addr`: 16-bit output vector for the target RAM address.
- `o_mem_data`: 8-bit output vector for filtered data to be written to RAM.
- `o_mem_we`: 1-bit output signal for RAM write enable (active high for write).
- `o_mem_en`: 1-bit output signal for RAM enable.

---

## Testing & Verification

The design was synthesized with **Xilinx Vivado 2018.1** and validated through behavioral and post-synthesis simulations covering standard operations and corner cases:

- **Header & Coefficient Selection**: Verifies *K* assembly, filter order selection (*S*), and automatic zeroing of outer coefficients (*C_0*, *C_6*) when Order 3 is active.
- **Minimum Sequence (K = 7) & Saturation**: Tests Order 3 filtering, negative number normalization, and clamping at boundary limits (`-128` / `+127`).
- **Short Sequences (K = 3) & Intensive Padding**: Stress-tests sequences shorter than the 7-sample window with Order 5 filtering.
- **Multiple Executions & Reset Handling**:
  - Back-to-back runs triggered solely by toggling `i_start` without an explicit `i_rst`.
  - Asynchronous `i_rst` asserted mid-computation to verify immediate recovery to `IDLE`.

---

## Repository Structure

```text
.
├── 10842662.vhd    # Complete VHDL implementation (project_reti_logiche + submodules)
├── 10842662.pdf    # Project report (Italian) with block diagrams, FSM, and synthesis results
└── README.md       # Project documentation
