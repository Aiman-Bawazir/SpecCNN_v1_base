`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/12/2025 02:35:13 AM
// Design Name: 
// Module Name: fft_4x4_2d
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module fft_4x4_2d (
    input clk, reset, start,
    input [15:0] din_real_0, din_real_1, din_real_2, din_real_3,
    output wire [15:0] dout_real_0, dout_real_1, dout_real_2, dout_real_3, dout_real_4, dout_real_5, dout_real_6, dout_real_7,
                         dout_real_8, dout_real_9, dout_real_10, dout_real_11, dout_real_12, dout_real_13, dout_real_14, dout_real_15,
    output wire [15:0] dout_imag_0, dout_imag_1, dout_imag_2, dout_imag_3, dout_imag_4, dout_imag_5, dout_imag_6, dout_imag_7,
                         dout_imag_8, dout_imag_9, dout_imag_10, dout_imag_11, dout_imag_12, dout_imag_13, dout_imag_14, dout_imag_15,
    output wire done
);
    wire data_valid_internal;  wire fft_done_internal; 
    wire enable_block1_internal, enable_block2_internal, enable_block3_internal, enable_block4_internal;

    fft_control_unit CU_inst (
        .clk(clk), .reset(reset), .start(start), .fft_done(fft_done_internal),
        .data_valid(data_valid_internal), 
        .enable_block1(enable_block1_internal), .enable_block2(enable_block2_internal),
        .enable_block3(enable_block3_internal), .enable_block4(enable_block4_internal),
        .done(done)
    ); 

    fft_data_unit DU_inst (
        .clk(clk), .reset(reset),
        .data_valid(data_valid_internal), 
        .enable_block1(enable_block1_internal), .enable_block2(enable_block2_internal),
        .enable_block3(enable_block3_internal), .enable_block4(enable_block4_internal),
        .din_real_0(din_real_0), .din_real_1(din_real_1), .din_real_2(din_real_2), .din_real_3(din_real_3),
        .dout_real_0(dout_real_0), .dout_real_1(dout_real_1), .dout_real_2(dout_real_2), .dout_real_3(dout_real_3),
        .dout_real_4(dout_real_4), .dout_real_5(dout_real_5), .dout_real_6(dout_real_6), .dout_real_7(dout_real_7),
        .dout_real_8(dout_real_8), .dout_real_9(dout_real_9), .dout_real_10(dout_real_10), .dout_real_11(dout_real_11),
        .dout_real_12(dout_real_12), .dout_real_13(dout_real_13), .dout_real_14(dout_real_14), .dout_real_15(dout_real_15),
        .dout_imag_0(dout_imag_0), .dout_imag_1(dout_imag_1), .dout_imag_2(dout_imag_2), .dout_imag_3(dout_imag_3),
        .dout_imag_4(dout_imag_4), .dout_imag_5(dout_imag_5), .dout_imag_6(dout_imag_6), .dout_imag_7(dout_imag_7),
        .dout_imag_8(dout_imag_8), .dout_imag_9(dout_imag_9), .dout_imag_10(dout_imag_10), .dout_imag_11(dout_imag_11),
        .dout_imag_12(dout_imag_12), .dout_imag_13(dout_imag_13), .dout_imag_14(dout_imag_14), .dout_imag_15(dout_imag_15),
        .fft_done(fft_done_internal)
    );
endmodule
