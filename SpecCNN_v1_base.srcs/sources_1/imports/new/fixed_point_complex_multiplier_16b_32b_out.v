`timescale 1ns / 1ps

module fixed_point_complex_multiplier_16b_32b_out (
    input clk,
    input reset,
    input start,
    input signed [15:0] a_real_in,
    input signed [15:0] a_imag_in,
    input signed [15:0] b_real_in,
    input signed [15:0] b_imag_in,
    output wire signed [31:0] result_real_out,
    output wire signed [31:0] result_imag_out,
    output wire done_out
);
    localparam TOTAL_LATENCY = 3;
    localparam LATENCY_COUNTER_WIDTH = 2;

    // Pipeline Stage 0: Input Registers
    reg signed [15:0] a_r_s0, a_i_s0, b_r_s0, b_i_s0;

    // Stage 1 Products
    wire signed [31:0] p_ar_br_s1 = a_r_s0 * b_r_s0;
    wire signed [31:0] p_ai_bi_s1 = a_i_s0 * b_i_s0;
    wire signed [31:0] p_ar_bi_s1 = a_r_s0 * b_i_s0;
    wire signed [31:0] p_ai_br_s1 = a_i_s0 * b_r_s0;

    // Stage 1 Registers
    reg signed [31:0] p_ar_br_reg_s1, p_ai_bi_reg_s1, p_ar_bi_reg_s1, p_ai_br_reg_s1;

    // Stage 2: Output computation
    wire signed [32:0] res_real_full_s2 = {p_ar_br_reg_s1[31], p_ar_br_reg_s1} - {p_ai_bi_reg_s1[31], p_ai_bi_reg_s1};
    wire signed [32:0] res_imag_full_s2 = {p_ar_bi_reg_s1[31], p_ar_bi_reg_s1} + {p_ai_br_reg_s1[31], p_ai_br_reg_s1};

    reg signed [31:0] res_real_reg, res_imag_reg;

    // Control logic
    reg done_reg;
    reg [LATENCY_COUNTER_WIDTH-1:0] latency_counter;
    reg busy_flag;

    // Stage 0: Latch Inputs
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            a_r_s0 <= 16'sd0; a_i_s0 <= 16'sd0; b_r_s0 <= 16'sd0; b_i_s0 <= 16'sd0;
        end else if (start && !busy_flag) begin
            a_r_s0 <= a_real_in; a_i_s0 <= a_imag_in;
            b_r_s0 <= b_real_in; b_i_s0 <= b_imag_in;
        end
    end

    // Stage 1: Latch Products
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            p_ar_br_reg_s1 <= 32'sd0; p_ai_bi_reg_s1 <= 32'sd0;
            p_ar_bi_reg_s1 <= 32'sd0; p_ai_br_reg_s1 <= 32'sd0;
        end else if (busy_flag && latency_counter == 2'd0) begin
            p_ar_br_reg_s1 <= p_ar_br_s1;
            p_ai_bi_reg_s1 <= p_ai_bi_s1;
            p_ar_bi_reg_s1 <= p_ar_bi_s1;
            p_ai_br_reg_s1 <= p_ai_br_s1;
        end
    end

    // Stage 2: Latch Final Results
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            res_real_reg <= 32'sd0; res_imag_reg <= 32'sd0;
        end else if (busy_flag && latency_counter == 2'd1) begin
            res_real_reg <= res_real_full_s2[31:0];
            res_imag_reg <= res_imag_full_s2[31:0];
        end
    end

    // FSM for done and pipeline control
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            latency_counter <= 2'd0;
            busy_flag <= 1'b0;
            done_reg <= 1'b0;
        end else begin
            if (start && !busy_flag) begin
                busy_flag <= 1'b1;
                latency_counter <= 2'd0;
                done_reg <= 1'b0;
            end else if (busy_flag) begin
                if (latency_counter == TOTAL_LATENCY - 1) begin // TOTAL_LATENCY - 1 is 2
                    busy_flag <= 1'b0;
                    latency_counter <= 2'd0;
                    done_reg <= 1'b1;
                end else begin
                    latency_counter <= latency_counter + 1;
                    done_reg <= 1'b0;
                end
            end else begin // if !start && !busy_flag (i.e. idle)
                done_reg <= 1'b0;
            end
        end
    end

    assign result_real_out = res_real_reg;
    assign result_imag_out = res_imag_reg;
    assign done_out = done_reg;
endmodule