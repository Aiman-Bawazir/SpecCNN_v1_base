`timescale 1ns / 1ps

module fft_4point_1 (
    input [15:0] a0_real, a1_real, a2_real, a3_real, // Real inputs
    output wire [15:0] G0_real, G1_real, G2_real, G3_real, // Real outputs
    output wire [15:0] G0_imag, G1_imag, G2_imag, G3_imag  // Imaginary outputs
);
    // Internal wires to store intermediate butterfly results
    wire signed [15:0] B0_real, B1_real, B2_real, B3_real;

    // Butterfly computations for the real parts
    assign B0_real = a0_real + a2_real;
    assign B1_real = a0_real - a2_real;
    assign B2_real = a1_real + a3_real;
    assign B3_real = a1_real - a3_real;

    // FFT outputs G0 to G3 (complex valued)
    assign G0_real = B0_real + B2_real;
    assign G1_real = B1_real;
    assign G2_real = B0_real - B2_real;
    assign G3_real = B1_real;

    assign G0_imag = 16'sd0;       // Use 16'sd0 for signed zero
    assign G1_imag = -B3_real;
    assign G2_imag = 16'sd0;       // Use 16'sd0 for signed zero
    assign G3_imag = B3_real;
endmodule