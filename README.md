🚀 Spectral CNN Layer Hardware Accelerator (Verilog)

This project implements a Spectral Convolutional Neural Network (CNN) Layer using Verilog HDL.
The design accelerates convolution by executing the computation entirely in the frequency domain, following the standard:

FFT
→
Element-Wise Multiplication (EWM)
→
Activation
→
Store
FFT→Element-Wise Multiplication (EWM)→Activation→Store

The layer processes a 4×4 real input matrix against six complex filters.

🛠️ Key Design Specifications
Parameter	Value	Description
Input Size	4×4 (16 real values)	Raw input spatial-domain matrix
Number of Filters	6	Layer computes convolution with 6 complex kernels
Data Width (FFT/Kernel)	16-bit	Width of the data exchanged with FFT and filter memories
Data Width (Output/EWM)	32-bit	Precision of EWM results and final activated output
Total Output Size	
16
×
6
=
96
16×6=96 complex results	Number of complex elements stored in Output SRAM
🏗️ Architecture & Data Flow

The layer is a sequential hardware pipeline, managed by a centralized Control Unit FSM that orchestrates data movement and computation.

1. 🧠 Control Unit — control_unit.v

The Finite State Machine (FSM) coordinates the full workflow, including memory writes, FFT start, EWM execution, activation, and output storage.

State Name	Purpose	Duration
KERNEL_LOAD_CTRL	Load 6 filters into Kernel SRAM	Variable
FFT_PROVIDE_IN0–3	Provide 16 raw inputs to FFT block over 4 cycles	4 Cycles
FFT_STORE_CTRL	Store 16 complex FFT outputs (Real/Imag) into FFT SRAM	32 Cycles (16 × 2)
EWM_EXEC / WAIT	Execute Element-Wise Multiplication and wait for valid output	Sequential
OUTPUT_STORE_*	Store 32-bit activated EWM outputs to Output SRAM	192 Cycles (96 × 2)
LAYER_DONE_CTRL	Assert top_layer_done and return to IDLE	1 Cycle
2. 🧮 Calculation Pipeline
Component	Source File(s)	Function
Input FFT Block	fft_4x4_2d.v	Converts 4×4 real input to frequency domain
EWM Block	ewm_block.v	Performs complex element-wise multiplication using fixed_point_complex_multiplier_16b_32b_out.v
Activation	activation_block_32b.v	Applies non-linear activation to 32-bit complex results
Memories	sram_sync_single_port.v	Single-port SRAM for FFT output, filters, and final output
💻 Running the Simulation

You can simulate this project using Vivado, ModelSim, or any standard Verilog simulator.

✔️ Steps

Load Source Files
Import all .v modules into your simulator.

Run Testbench
Execute the full-layer testbench (e.g., tb_spectral_cnn_layer.v).

Monitor Completion
Track the top_layer_done signal — it asserts when the pipeline finishes:
Input Load → FFT → EWM → Activation → Output Store
