`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/16/2025 06:37:13 AM
// Design Name: 
// Module Name: spectral_cnn_layer
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


module spectral_cnn_layer (
    input clk, reset,
    input top_start, input load_kernel_en,
    // Kernel Loading Interface
    input [15:0] kernel_data_in_bus, input [7:0] kernel_load_addr_bus, // V1 change: addr width 7->8
    // Raw Input Data Interface
    input [15:0] raw_input_data_0,  raw_input_data_1,  raw_input_data_2,  raw_input_data_3,
    input [15:0] raw_input_data_4,  raw_input_data_5,  raw_input_data_6,  raw_input_data_7,
    input [15:0] raw_input_data_8,  raw_input_data_9,  raw_input_data_10, raw_input_data_11,
    input [15:0] raw_input_data_12, raw_input_data_13, raw_input_data_14, raw_input_data_15,
    // Output SRAM Readback Interface for Verification
    input output_sram_read_en,
    input [7:0] output_sram_read_addr, // V1 change: addr width 7->8
    output [31:0] output_sram_data_out, // V1 change: data width 64->32
    // Top Level Status
    output wire top_layer_done
);
    // V1 changes: Data and address wire widths adjusted for new SRAM sizes
    wire fft_start_cmd_w; wire fft_overall_done_w;
    wire [15:0] fft_din0_w, fft_din1_w, fft_din2_w, fft_din3_w;
    wire [15:0] r0_fft,r1_fft,r2_fft,r3_fft,r4_fft,r5_fft,r6_fft,r7_fft,r8_fft,r9_fft,r10_fft,r11_fft,r12_fft,r13_fft,r14_fft,r15_fft;
    wire [15:0] i0_fft,i1_fft,i2_fft,i3_fft,i4_fft,i5_fft,i6_fft,i7_fft,i8_fft,i9_fft,i10_fft,i11_fft,i12_fft,i13_fft,i14_fft,i15_fft;

    wire fft_sram_we_w, fft_sram_re_from_ewm; wire [4:0] fft_sram_addr_from_cu, fft_sram_addr_from_ewm; wire [4:0] fft_sram_addr_final;
    wire [15:0] fft_sram_data_to_sram_w, fft_sram_data_from_sram;

    wire kernel_sram_we_w; wire kernel_sram_re_from_ewm; wire [7:0] kernel_sram_addr_from_cu, kernel_sram_addr_from_ewm; wire [7:0] kernel_sram_addr_final;
    wire [15:0] kernel_sram_data_to_sram_w, kernel_sram_data_from_sram;

    wire ewm_start_cmd_w, ewm_overall_done_w, ewm_data_out_valid_w;
    wire signed [31:0] ewm_res_real_w, ewm_res_imag_w;

    wire output_sram_we_w; wire [7:0] output_sram_addr_from_cu; wire [31:0] output_sram_data_to_sram_w;
    wire output_sram_we_final; wire [7:0] output_sram_addr_final;

    // Address Bus Arbitration Logic
    assign fft_sram_addr_final = fft_sram_we_w ? fft_sram_addr_from_cu : fft_sram_addr_from_ewm;
    assign kernel_sram_addr_final = kernel_sram_we_w ? kernel_sram_addr_from_cu : kernel_sram_addr_from_ewm;
    assign output_sram_addr_final = output_sram_read_en ? output_sram_read_addr : output_sram_addr_from_cu;
    assign output_sram_we_final = output_sram_we_w & !output_sram_read_en;

    // Instantiate FFT Block (unchanged)
    fft_4x4_2d fft_inst_top_level ( .clk(clk), .reset(reset), .start(fft_start_cmd_w), .din_real_0(fft_din0_w), .din_real_1(fft_din1_w), .din_real_2(fft_din2_w), .din_real_3(fft_din3_w), .dout_real_0(r0_fft), .dout_real_1(r1_fft), .dout_real_2(r2_fft), .dout_real_3(r3_fft), .dout_real_4(r4_fft), .dout_real_5(r5_fft), .dout_real_6(r6_fft), .dout_real_7(r7_fft), .dout_real_8(r8_fft), .dout_real_9(r9_fft), .dout_real_10(r10_fft), .dout_real_11(r11_fft), .dout_real_12(r12_fft), .dout_real_13(r13_fft), .dout_real_14(r14_fft), .dout_real_15(r15_fft), .dout_imag_0(i0_fft), .dout_imag_1(i1_fft), .dout_imag_2(i2_fft), .dout_imag_3(i3_fft), .dout_imag_4(i4_fft), .dout_imag_5(i5_fft), .dout_imag_6(i6_fft), .dout_imag_7(i7_fft), .dout_imag_8(i8_fft), .dout_imag_9(i9_fft), .dout_imag_10(i10_fft), .dout_imag_11(i11_fft), .dout_imag_12(i12_fft), .dout_imag_13(i13_fft), .dout_imag_14(i14_fft), .dout_imag_15(i15_fft), .done(fft_overall_done_w) );
    
    // *** V1 HIGHLIGHTED CHANGE: SRAM instantiations updated for new data/address widths ***
    // FFT SRAM: Stores 16 complex FFT results. 16*2=32 locations of 16-bit data.
    sram_sync_single_port #(.DATA_WIDTH(16), .ADDR_WIDTH(5), .DEPTH(32)) fft_output_sram_inst_top_level ( .clk(clk), .reset(reset), .write_enable(fft_sram_we_w), .read_enable(fft_sram_re_from_ewm), .address(fft_sram_addr_final), .data_in(fft_sram_data_to_sram_w), .data_out(fft_sram_data_from_sram) );
    // KERNEL SRAM: Stores 6 filters * 16 complex values = 96 complex values. 96*2=192 locations of 16-bit data.
    sram_sync_single_port #(.DATA_WIDTH(16), .ADDR_WIDTH(8), .DEPTH(192)) kernel_sram_inst_top_level ( .clk(clk), .reset(reset), .write_enable(kernel_sram_we_w), .read_enable(kernel_sram_re_from_ewm), .address(kernel_sram_addr_final), .data_in(kernel_sram_data_to_sram_w), .data_out(kernel_sram_data_from_sram) );
    // OUTPUT SRAM: Stores 96 complex results. 96*2=192 locations of 32-bit data (results are wider).
    sram_sync_single_port #(.DATA_WIDTH(32), .ADDR_WIDTH(8), .DEPTH(192)) output_sram_inst_top_level ( .clk(clk), .reset(reset), .write_enable(output_sram_we_final), .read_enable(output_sram_read_en), .address(output_sram_addr_final), .data_in(output_sram_data_to_sram_w), .data_out(output_sram_data_out) );
    
    // Instantiate EWM Block (interface updated for 16-bit SRAM data)
    ewm_block ewm_inst_top_level ( .clk(clk), .reset(reset), .start_ewm_process(ewm_start_cmd_w), .fft_sram_read_en(fft_sram_re_from_ewm), .fft_sram_addr(fft_sram_addr_from_ewm), .fft_sram_data_in(fft_sram_data_from_sram), .kernel_sram_read_en(kernel_sram_re_from_ewm), .kernel_sram_addr(kernel_sram_addr_from_ewm), .kernel_sram_data_in(kernel_sram_data_from_sram), .ewm_data_out_valid(ewm_data_out_valid_w), .ewm_result_real_out(ewm_res_real_w), .ewm_result_imag_out(ewm_res_imag_w), .ewm_overall_done(ewm_overall_done_w) );
    
    // Instantiate Control Unit (interface updated for new data/address widths)
    control_unit control_inst_top_level (
        .clk(clk), .reset(reset), .top_start(top_start), .load_kernel_en(load_kernel_en), .kernel_data_in_bus(kernel_data_in_bus), .kernel_load_addr_bus(kernel_load_addr_bus),
        .raw_in_0(raw_input_data_0),   .raw_in_1(raw_input_data_1),   .raw_in_2(raw_input_data_2),   .raw_in_3(raw_input_data_3),
        .raw_in_4(raw_input_data_4),   .raw_in_5(raw_input_data_5),   .raw_in_6(raw_input_data_6),   .raw_in_7(raw_input_data_7),
        .raw_in_8(raw_input_data_8),   .raw_in_9(raw_input_data_9),   .raw_in_10(raw_input_data_10), .raw_in_11(raw_input_data_11),
        .raw_in_12(raw_input_data_12), .raw_in_13(raw_input_data_13), .raw_in_14(raw_input_data_14), .raw_in_15(raw_input_data_15),
        .fft_start_cmd(fft_start_cmd_w), .fft_overall_done(fft_overall_done_w),
        .fft_din0(fft_din0_w), .fft_din1(fft_din1_w), .fft_din2(fft_din2_w), .fft_din3(fft_din3_w),
        .fft_out_r0(r0_fft),   .fft_out_r1(r1_fft),   .fft_out_r2(r2_fft),   .fft_out_r3(r3_fft),
        .fft_out_r4(r4_fft),   .fft_out_r5(r5_fft),   .fft_out_r6(r6_fft),   .fft_out_r7(r7_fft),
        .fft_out_r8(r8_fft),   .fft_out_r9(r9_fft),   .fft_out_r10(r10_fft), .fft_out_r11(r11_fft),
        .fft_out_r12(r12_fft), .fft_out_r13(r13_fft), .fft_out_r14(r14_fft), .fft_out_r15(r15_fft),
        .fft_out_i0(i0_fft),   .fft_out_i1(i1_fft),   .fft_out_i2(i2_fft),   .fft_out_i3(i3_fft),
        .fft_out_i4(i4_fft),   .fft_out_i5(i5_fft),   .fft_out_i6(i6_fft),   .fft_out_i7(i7_fft),
        .fft_out_i8(i8_fft),   .fft_out_i9(i9_fft),   .fft_out_i10(i10_fft), .fft_out_i11(i11_fft),
        .fft_out_i12(i12_fft), .fft_out_i13(i13_fft), .fft_out_i14(i14_fft), .fft_out_i15(i15_fft),
        .fft_sram_we(fft_sram_we_w), .fft_sram_addr(fft_sram_addr_from_cu), .fft_sram_data_out(fft_sram_data_to_sram_w),
        .kernel_sram_we(kernel_sram_we_w), .kernel_sram_addr(kernel_sram_addr_from_cu), .kernel_sram_data_out(kernel_sram_data_to_sram_w),
        .ewm_start_cmd(ewm_start_cmd_w), .ewm_overall_done_sig(ewm_overall_done_w),
        .ewm_data_out_valid_sig(ewm_data_out_valid_w),
        .ewm_result_real_from_ewm(ewm_res_real_w), .ewm_result_imag_from_ewm(ewm_res_imag_w),
        .output_sram_we(output_sram_we_w), .output_sram_addr(output_sram_addr_from_cu), .output_sram_data_out(output_sram_data_to_sram_w),
        .top_layer_done(top_layer_done)
    );
endmodule
