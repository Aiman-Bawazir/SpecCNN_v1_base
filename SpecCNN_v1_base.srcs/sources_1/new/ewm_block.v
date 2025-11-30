`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/16/2025 06:37:13 AM
// Design Name: 
// Module Name: ewm_block
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


module ewm_block (
    input clk, reset,
    input start_ewm_process,
    // V1 change: address and data widths updated
    output reg fft_sram_read_en,
    output reg [4:0] fft_sram_addr,
    input signed [15:0] fft_sram_data_in,
    output reg kernel_sram_read_en,
    output reg [7:0] kernel_sram_addr,
    input signed [15:0] kernel_sram_data_in,
    output reg ewm_data_out_valid,
    output reg signed [31:0] ewm_result_real_out,
    output reg signed [31:0] ewm_result_imag_out,
    output reg ewm_overall_done
);
    parameter NUM_FILTERS_PARAM = 6;
    parameter KERNEL_VALUES_PARAM = 16;
    reg [3:0] element_idx;
    reg [2:0] kernel_idx;
    reg signed [15:0] current_fft_real_op, current_fft_imag_op;
    reg signed [15:0] current_kernel_real_op, current_kernel_imag_op;

    // *** V1 HIGHLIGHTED CHANGE: Expanded FSM for separate real/imag reads ***
    parameter IDLE_EWM = 4'd0, READ_FFT_REAL = 4'd1, WAIT_FFT_REAL = 4'd2,
              READ_FFT_IMAG = 4'd3, WAIT_FFT_IMAG = 4'd4, READ_KERN_REAL = 4'd5,
              WAIT_KERN_REAL = 4'd6, READ_KERN_IMAG = 4'd7, WAIT_KERN_IMAG = 4'd8,
              START_COMPLEX_MULT = 4'd9, WAIT_COMPLEX_MULT = 4'd10, OUTPUT_VALID_EWM = 4'd11;
    reg [3:0] current_ewm_state, next_ewm_state;
    
    reg mult_start_signal;
    wire mult_done_signal;
    wire signed [31:0] mult_res_real_32b, mult_res_imag_32b;

    fixed_point_complex_multiplier_16b_32b_out complex_mult_inst (.clk(clk), .reset(reset), .start(mult_start_signal), .a_real_in(current_fft_real_op), .a_imag_in(current_fft_imag_op), .b_real_in(current_kernel_real_op), .b_imag_in(current_kernel_imag_op), .result_real_out(mult_res_real_32b), .result_imag_out(mult_res_imag_32b), .done_out(mult_done_signal));
    
    always @(posedge clk or posedge reset) begin if (reset) current_ewm_state <= IDLE_EWM; else current_ewm_state <= next_ewm_state; end
    
    always @(*) begin
        next_ewm_state = current_ewm_state; fft_sram_read_en = 1'b0; fft_sram_addr = 5'd0;
        kernel_sram_read_en = 1'b0; kernel_sram_addr = 8'd0; mult_start_signal = 1'b0;
        ewm_data_out_valid = 1'b0; ewm_result_real_out = 32'sd0; ewm_result_imag_out = 32'sd0;
        ewm_overall_done = 1'b0;
        case (current_ewm_state)
            IDLE_EWM: if (start_ewm_process) next_ewm_state = READ_FFT_REAL;
            READ_FFT_REAL: begin fft_sram_read_en = 1'b1; fft_sram_addr = {element_idx, 1'b0}; next_ewm_state = WAIT_FFT_REAL; end
            WAIT_FFT_REAL: next_ewm_state = READ_FFT_IMAG;
            READ_FFT_IMAG: begin fft_sram_read_en = 1'b1; fft_sram_addr = {element_idx, 1'b1}; next_ewm_state = WAIT_FFT_IMAG; end
            WAIT_FFT_IMAG: next_ewm_state = READ_KERN_REAL;
            READ_KERN_REAL: begin kernel_sram_read_en = 1'b1; kernel_sram_addr = {(kernel_idx * KERNEL_VALUES_PARAM) + element_idx, 1'b0}; next_ewm_state = WAIT_KERN_REAL; end
            WAIT_KERN_REAL: next_ewm_state = READ_KERN_IMAG;
            READ_KERN_IMAG: begin kernel_sram_read_en = 1'b1; kernel_sram_addr = {(kernel_idx * KERNEL_VALUES_PARAM) + element_idx, 1'b1}; next_ewm_state = WAIT_KERN_IMAG; end
            WAIT_KERN_IMAG: next_ewm_state = START_COMPLEX_MULT;
            START_COMPLEX_MULT: begin mult_start_signal = 1'b1; next_ewm_state = WAIT_COMPLEX_MULT; end
            WAIT_COMPLEX_MULT: if (mult_done_signal) next_ewm_state = OUTPUT_VALID_EWM;
            OUTPUT_VALID_EWM: begin
                ewm_data_out_valid = 1'b1; ewm_result_real_out = mult_res_real_32b; ewm_result_imag_out = mult_res_imag_32b;
                if (kernel_idx == (NUM_FILTERS_PARAM-1) && element_idx == (KERNEL_VALUES_PARAM-1)) begin
                    ewm_overall_done = 1'b1; next_ewm_state = IDLE_EWM;
                end else
                    next_ewm_state = READ_FFT_REAL; // Loop to next element/filter
            end
            default: next_ewm_state = IDLE_EWM;
        endcase
    end
    
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            current_fft_real_op <= 16'sd0; current_fft_imag_op <= 16'sd0;
            current_kernel_real_op <= 16'sd0; current_kernel_imag_op <= 16'sd0;
        end else begin
            // V1 change: Latch data from 16-bit bus in the correct state
            if (current_ewm_state == WAIT_FFT_REAL)   current_fft_real_op <= fft_sram_data_in;
            if (current_ewm_state == WAIT_FFT_IMAG)   current_fft_imag_op <= fft_sram_data_in;
            if (current_ewm_state == WAIT_KERN_REAL)  current_kernel_real_op <= kernel_sram_data_in;
            if (current_ewm_state == WAIT_KERN_IMAG)  current_kernel_imag_op <= kernel_sram_data_in;
        end
    end
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            element_idx <= 4'd0; kernel_idx <= 3'd0;
        end else if (current_ewm_state == OUTPUT_VALID_EWM) begin
            if (element_idx == (KERNEL_VALUES_PARAM-1)) begin
                element_idx <= 4'd0;
                if (kernel_idx == (NUM_FILTERS_PARAM-1))
                    kernel_idx <= 3'd0;
                else
                    kernel_idx <= kernel_idx + 1;
            end else
                element_idx <= element_idx + 1;
        end else if (start_ewm_process && current_ewm_state == IDLE_EWM && next_ewm_state == READ_FFT_REAL) begin
            element_idx <= 4'd0; kernel_idx <= 3'd0;
        end
    end
endmodule

