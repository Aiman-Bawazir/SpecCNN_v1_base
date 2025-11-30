# 🚀 Spectral CNN Layer Hardware Accelerator (Verilog)

Welcome to the **Spectral CNN Layer Hardware Accelerator** project!  
This repository showcases the implementation of a **single Spectral Convolutional Neural Network (CNN) Layer** using **Verilog HDL**, designed to accelerate convolution by operating fully in the **frequency domain**. ⚡🧠

---

## 🧩 Project Objective

To design and implement a fully synthesizable **Spectral CNN Layer** that performs:

**FFT → Element-Wise Multiplication (EWM) → Activation → Output Storage**

The layer processes a **4×4 real input matrix** against **six complex filters**, optimized for hardware execution on FPGA or ASIC platforms.

---

## 🛠️ Key Design Specifications

| Parameter | Value | Description |
|----------|--------|-------------|
| **Input Size** | 4×4 (16 real values) | Spatial-domain input matrix |
| **Number of Filters** | 6 | Complex convolution filters |
| **Data Width (FFT/Kernel)** | 16-bit | Data transferred to/from FFT and filter SRAM |
| **Data Width (Output/EWM)** | 32-bit | High-precision EWM + activated output |
| **Total Output Size** | \(16 \times 6 = 96\) complex results | Stored in Output SRAM |

---

## 🏛️ Architecture Overview

The Spectral CNN Layer is built as a **sequential hardware pipeline** controlled by a centralized **Finite State Machine (FSM)**. Each module operates in sync to ensure correct data preparation, processing, and storage.

---

## 🧠 Control Unit FSM

The **control_unit.v** module acts as the “brain” of the layer, orchestrating memory access, FFT execution, EWM sequencing, and final result storage.

| FSM State | Purpose | Duration |
|-----------|----------|----------|
| `KERNEL_LOAD_CTRL` | Load 6 filters into Kernel SRAM | Variable |
| `FFT_PROVIDE_IN0–3` | Send 16 raw inputs to FFT block (4 per cycle) | **4 cycles** |
| `FFT_STORE_CTRL` | Store 16 complex FFT outputs (Real & Imag) | **32 cycles** |
| `EWM_EXEC / WAIT` | Perform complex EWM and wait for valid output | Sequential |
| `OUTPUT_STORE_*` | Store 96 activated complex outputs | **192 cycles** |
| `LAYER_DONE_CTRL` | Assert `top_layer_done` and return to IDLE | **1 cycle** |

---

## 🧮 Processing Pipeline Components

| Component | File(s) | Function |
|-----------|---------|----------|
| **2D FFT Engine** | `fft_4x4_2d.v` | Converts real input to frequency domain |
| **EWM Block** | `ewm_block.v` | Uses `fixed_point_complex_multiplier_16b_32b_out.v` for complex multiplications |
| **Activation Unit** | `activation_block_32b.v` | Applies non-linear activation (32-bit) |
| **SRAM Modules** | `sram_sync_single_port.v` | Stores FFT results, filters, and final outputs |

---

## 🛠️ Software & Tools

- **Vivado**, **ModelSim**, or any Verilog simulator  
- Verilog HDL (synthesizable design)  
- Single-port synchronous SRAM modules  
- Custom testbenches for end-to-end verification  

---

## 🧪 Simulation Procedure

1. Load all `.v` source files into your simulator.  
2. Run the full-layer testbench (e.g., `tb_spectral_cnn_layer.v`).  
3. Monitor the `top_layer_done` signal — it asserts when the full pipeline finishes:  
   **Input Load → FFT → EWM → Activation → Output Storage**


