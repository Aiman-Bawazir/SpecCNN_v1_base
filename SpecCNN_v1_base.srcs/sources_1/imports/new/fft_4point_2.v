`timescale 1ns / 1ps

module fft_4point_2 (
    input [15:0] a0_real, a1_real, a2_real, a3_real, // Real inputs
    input [15:0] a0_imag, a1_imag, a2_imag, a3_imag, // Imaginary inputs
    output wire [15:0] G0_real, G1_real, G2_real, G3_real, // Real outputs
    output wire [15:0] G0_imag, G1_imag, G2_imag, G3_imag  // Imaginary outputs
);
    // Internal wires to store intermediate butterfly results
    wire signed [15:0] B0_real, B1_real, B2_real, B3_real;
    wire signed [15:0] B0_imag, B1_imag, B2_imag, B3_imag;

    // Butterfly computations for the real parts
    assign B0_real = a0_real + a2_real;
    assign B1_real = a0_real - a2_real;
    assign B2_real = a1_real + a3_real;
    assign B3_real = a1_real - a3_real;

    // Butterfly computations for the imaginary parts
    assign B0_imag = a0_imag + a2_imag;
    assign B1_imag = a0_imag - a2_imag;
    assign B2_imag = a1_imag + a3_imag;
    assign B3_imag = a1_imag - a3_imag;

    assign G0_real = B0_real + B2_real;
    assign G1_real = B1_real + B3_imag;
    assign G2_real = B0_real - B2_real;
    assign G3_real = B1_real - B3_imag;

    assign G0_imag = B0_imag + B2_imag;
    assign G1_imag = B1_imag - B3_real;
    assign G2_imag = B0_imag - B2_imag;
    assign G3_imag = B1_imag + B3_real;
endmodule