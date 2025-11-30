`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/16/2025 06:37:13 AM
// Design Name: 
// Module Name: control_unit
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


module control_unit (
    input clk, reset,
    input top_start, input load_kernel_en,
    input [15:0] kernel_data_in_bus, input [7:0] kernel_load_addr_bus, // V1 change: addr width
    input [15:0] raw_in_0,  raw_in_1,  raw_in_2,  raw_in_3, input [15:0] raw_in_4,  raw_in_5,  raw_in_6,  raw_in_7,
    input [15:0] raw_in_8,  raw_in_9,  raw_in_10, raw_in_11, input [15:0] raw_in_12, raw_in_13, raw_in_14, raw_in_15,
    output reg fft_start_cmd, input fft_overall_done,
    output reg [15:0] fft_din0, fft_din1, fft_din2, fft_din3,
    input signed [15:0] fft_out_r0, fft_out_r1, fft_out_r2, fft_out_r3, input signed [15:0] fft_out_r4, fft_out_r5, fft_out_r6, fft_out_r7,
    input signed [15:0] fft_out_r8, fft_out_r9, fft_out_r10,fft_out_r11,input signed [15:0] fft_out_r12,fft_out_r13,fft_out_r14,fft_out_r15,
    input signed [15:0] fft_out_i0, fft_out_i1, fft_out_i2, fft_out_i3, input signed [15:0] fft_out_i4, fft_out_i5, fft_out_i6, fft_out_i7,
    input signed [15:0] fft_out_i8, fft_out_i9, fft_out_i10,fft_out_i11,input signed [15:0] fft_out_i12,fft_out_i13,fft_out_i14,fft_out_i15,
    // V1 change: address and data widths updated
    output reg fft_sram_we, output reg [4:0] fft_sram_addr, output reg [15:0] fft_sram_data_out,
    output reg kernel_sram_we, output reg [7:0] kernel_sram_addr, output reg [15:0] kernel_sram_data_out,
    output reg ewm_start_cmd, input ewm_overall_done_sig, input ewm_data_out_valid_sig,
    input signed [31:0] ewm_result_real_from_ewm, input signed [31:0] ewm_result_imag_from_ewm,
    output reg output_sram_we, output reg [7:0] output_sram_addr, output reg [31:0] output_sram_data_out,
    output reg top_layer_done
);
    // *** V1 HIGHLIGHTED CHANGE: FSM states modified for new I/O scheme ***
    parameter IDLE_CTRL           = 5'd0, KERNEL_LOAD_CTRL    = 5'd1, FFT_PROVIDE_IN0     = 5'd2,
              FFT_PROVIDE_IN1     = 5'd3, FFT_PROVIDE_IN2     = 5'd4, FFT_PROVIDE_IN3     = 5'd5,
              FFT_WAIT_CTRL       = 5'd6, FFT_STORE_CTRL      = 5'd7, EWM_EXEC_CTRL       = 5'd8,
              EWM_WAIT_CTRL       = 5'd9, OUTPUT_STORE_REAL_CTRL = 5'd10, LAYER_DONE_CTRL = 5'd11,
              OUTPUT_STORE_IMAG_CTRL = 5'd12;
    
    reg [4:0] current_ctrl_state, next_ctrl_state;
    reg [3:0] fft_store_idx_counter; reg [6:0] output_store_idx_counter;
    reg fft_store_part; // 0 for real, 1 for imag

    wire signed [31:0] activated_real_w, activated_imag_w;
    reg ewm_output_valid_prev_reg;
    wire ewm_output_posedge_w = ewm_data_out_valid_sig & ~ewm_output_valid_prev_reg;

    reg signed [31:0] ewm_res_real_reg, ewm_res_imag_reg;

    localparam KERNEL_VALUES_PER_FILTER_COMPLEX_CU = 16;
    localparam NUM_FILTERS_CU = 6;
    localparam TOTAL_OUTPUT_LOCATIONS_CU = KERNEL_VALUES_PER_FILTER_COMPLEX_CU * NUM_FILTERS_CU; // 96

    activation_block_32b act_inst_ctrl (.data_in_real(ewm_res_real_reg), .data_in_imag(ewm_res_imag_reg), .data_out_real(activated_real_w), .data_out_imag(activated_imag_w));

    always @(posedge clk or posedge reset) begin
        if (reset) current_ctrl_state <= IDLE_CTRL;
        else current_ctrl_state <= next_ctrl_state;
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            ewm_output_valid_prev_reg <= 1'b0;
            ewm_res_real_reg <= 32'sd0; ewm_res_imag_reg <= 32'sd0;
        end else begin
            ewm_output_valid_prev_reg <= ewm_data_out_valid_sig;
            // Latch EWM data when it's valid to hold it for the two-cycle SRAM write
            if (ewm_data_out_valid_sig) begin
                ewm_res_real_reg <= ewm_result_real_from_ewm;
                ewm_res_imag_reg <= ewm_result_imag_from_ewm;
            end
        end
    end

    always @(*) begin
        next_ctrl_state = current_ctrl_state; fft_start_cmd = 1'b0; fft_din0 = 16'sd0; fft_din1 = 16'sd0; fft_din2 = 16'sd0; fft_din3 = 16'sd0; fft_sram_we = 1'b0; fft_sram_addr = 5'd0; fft_sram_data_out = 16'sd0; kernel_sram_we = 1'b0; kernel_sram_addr = 8'd0; kernel_sram_data_out = 16'sd0; ewm_start_cmd = 1'b0; output_sram_we = 1'b0; output_sram_addr = 8'd0; output_sram_data_out = 32'sd0; top_layer_done = 1'b0;
        case (current_ctrl_state)
            IDLE_CTRL: if (load_kernel_en) next_ctrl_state = KERNEL_LOAD_CTRL; else if (top_start) next_ctrl_state = FFT_PROVIDE_IN0;
            // V1 change: Simplified kernel loading for 16-bit SRAM
            KERNEL_LOAD_CTRL: begin kernel_sram_we = 1'b1; kernel_sram_addr = kernel_load_addr_bus; kernel_sram_data_out = kernel_data_in_bus; if (!load_kernel_en) next_ctrl_state = IDLE_CTRL; end
            FFT_PROVIDE_IN0: begin fft_din0 = raw_in_0; fft_din1 = raw_in_1; fft_din2 = raw_in_2; fft_din3 = raw_in_3; fft_start_cmd = 1'b1; next_ctrl_state = FFT_PROVIDE_IN1; end
            FFT_PROVIDE_IN1: begin fft_din0 = raw_in_4; fft_din1 = raw_in_5; fft_din2 = raw_in_6; fft_din3 = raw_in_7; next_ctrl_state = FFT_PROVIDE_IN2; end
            FFT_PROVIDE_IN2: begin fft_din0 = raw_in_8; fft_din1 = raw_in_9; fft_din2 = raw_in_10; fft_din3 = raw_in_11; next_ctrl_state = FFT_PROVIDE_IN3; end
            FFT_PROVIDE_IN3: begin fft_din0 = raw_in_12; fft_din1 = raw_in_13; fft_din2 = raw_in_14; fft_din3 = raw_in_15; next_ctrl_state = FFT_WAIT_CTRL; end
            FFT_WAIT_CTRL: if (fft_overall_done) next_ctrl_state = FFT_STORE_CTRL;
            // V1 change: FFT store writes real and imag parts in two cycles
            FFT_STORE_CTRL: begin
                fft_sram_we = 1'b1;
                if (fft_store_part == 0) begin // Write Real Part
                    fft_sram_addr = {fft_store_idx_counter, 1'b0}; // Addr = index * 2
                    case (fft_store_idx_counter)
                        4'd0: fft_sram_data_out = fft_out_r0; 4'd1: fft_sram_data_out = fft_out_r1; 4'd2: fft_sram_data_out = fft_out_r2; 4'd3: fft_sram_data_out = fft_out_r3;
                        4'd4: fft_sram_data_out = fft_out_r4; 4'd5: fft_sram_data_out = fft_out_r5; 4'd6: fft_sram_data_out = fft_out_r6; 4'd7: fft_sram_data_out = fft_out_r7;
                        4'd8: fft_sram_data_out = fft_out_r8; 4'd9: fft_sram_data_out = fft_out_r9; 4'd10: fft_sram_data_out = fft_out_r10; 4'd11: fft_sram_data_out = fft_out_r11;
                        4'd12: fft_sram_data_out = fft_out_r12; 4'd13: fft_sram_data_out = fft_out_r13; 4'd14: fft_sram_data_out = fft_out_r14; 4'd15: fft_sram_data_out = fft_out_r15;
                        default: fft_sram_data_out = 16'sd0;
                    endcase
                end else begin // Write Imaginary Part
                    fft_sram_addr = {fft_store_idx_counter, 1'b1}; // Addr = index * 2 + 1
                    case (fft_store_idx_counter)
                        4'd0: fft_sram_data_out = fft_out_i0; 4'd1: fft_sram_data_out = fft_out_i1; 4'd2: fft_sram_data_out = fft_out_i2; 4'd3: fft_sram_data_out = fft_out_i3;
                        4'd4: fft_sram_data_out = fft_out_i4; 4'd5: fft_sram_data_out = fft_out_i5; 4'd6: fft_sram_data_out = fft_out_i6; 4'd7: fft_sram_data_out = fft_out_i7;
                        4'd8: fft_sram_data_out = fft_out_i8; 4'd9: fft_sram_data_out = fft_out_i9; 4'd10: fft_sram_data_out = fft_out_i10; 4'd11: fft_sram_data_out = fft_out_i11;
                        4'd12: fft_sram_data_out = fft_out_i12; 4'd13: fft_sram_data_out = fft_out_i13; 4'd14: fft_sram_data_out = fft_out_i14; 4'd15: fft_sram_data_out = fft_out_i15;
                        default: fft_sram_data_out = 16'sd0;
                    endcase
                end
                if (fft_store_part == 1 && fft_store_idx_counter == (KERNEL_VALUES_PER_FILTER_COMPLEX_CU-1))
                    next_ctrl_state = EWM_EXEC_CTRL;
            end
            EWM_EXEC_CTRL: begin ewm_start_cmd = 1'b1; next_ctrl_state = EWM_WAIT_CTRL; end
            EWM_WAIT_CTRL: if (ewm_output_posedge_w) next_ctrl_state = OUTPUT_STORE_REAL_CTRL;
            // V1 change: Output store is now a two-stage process for real and imag parts
            OUTPUT_STORE_REAL_CTRL: begin output_sram_we = 1'b1; output_sram_addr = {output_store_idx_counter, 1'b0}; output_sram_data_out = activated_real_w; next_ctrl_state = OUTPUT_STORE_IMAG_CTRL; end
            OUTPUT_STORE_IMAG_CTRL: begin output_sram_we = 1'b1; output_sram_addr = {output_store_idx_counter, 1'b1}; output_sram_data_out = activated_imag_w; if (output_store_idx_counter == (TOTAL_OUTPUT_LOCATIONS_CU-1)) next_ctrl_state = LAYER_DONE_CTRL; else next_ctrl_state = EWM_WAIT_CTRL; end
            LAYER_DONE_CTRL: begin top_layer_done = 1'b1; next_ctrl_state = IDLE_CTRL; end
            default: next_ctrl_state = IDLE_CTRL;
        endcase
    end
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            fft_store_idx_counter <= 4'd0;
            output_store_idx_counter <= 7'd0;
            fft_store_part <= 1'b0;
        end else begin
            // V1 change: Counter logic adapted for two-part writes
            if (current_ctrl_state == FFT_STORE_CTRL) begin
                fft_store_part <= ~fft_store_part;
                if (fft_store_part == 1'b1) begin // After writing imag part
                    if (fft_store_idx_counter == (KERNEL_VALUES_PER_FILTER_COMPLEX_CU-1))
                        fft_store_idx_counter <= 4'd0;
                    else
                        fft_store_idx_counter <= fft_store_idx_counter + 1;
                end
            end
            
            if (current_ctrl_state == OUTPUT_STORE_IMAG_CTRL) begin // After writing imag part
                if (output_store_idx_counter == (TOTAL_OUTPUT_LOCATIONS_CU-1))
                    output_store_idx_counter <= 7'd0;
                else
                    output_store_idx_counter <= output_store_idx_counter + 1;
            end

            if (current_ctrl_state == LAYER_DONE_CTRL && next_ctrl_state == IDLE_CTRL) begin
                fft_store_idx_counter <= 4'd0;
                output_store_idx_counter <= 7'd0;
                fft_store_part <= 1'b0;
            end
        end
    end
endmodule
