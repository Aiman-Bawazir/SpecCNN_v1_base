`timescale 1ns / 1ps

module fft_data_unit (
    input clk,
    input reset,
    input enable_block1, enable_block2, enable_block3, enable_block4,
    input data_valid, 
    // Real Input data
    input [15:0] din_real_0, din_real_1, din_real_2, din_real_3,

    // Real Output data
    output reg [15:0] dout_real_0, dout_real_1, dout_real_2, dout_real_3, dout_real_4, dout_real_5, dout_real_6, dout_real_7,
                        dout_real_8, dout_real_9, dout_real_10, dout_real_11, dout_real_12, dout_real_13, dout_real_14, dout_real_15,
    // Imaginary Output data
    output reg [15:0] dout_imag_0, dout_imag_1, dout_imag_2, dout_imag_3, dout_imag_4, dout_imag_5, dout_imag_6, dout_imag_7,
                        dout_imag_8, dout_imag_9, dout_imag_10, dout_imag_11, dout_imag_12, dout_imag_13, dout_imag_14, dout_imag_15,

    output reg fft_done // fft_done signal to indicate FFT completion
);
    // Internal storage for FFT stages
    reg [15:0] stage1_real [0:15];
    wire [15:0] stage2_real [0:15], stage2_imag [0:15];
    wire [15:0] wire_output_real [0:15], wire_output_imag [0:15];

    integer i;   // Integer variables for loops

    // Load data into the correct registers based on enable signals
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset all input stage registers to 0
            for (i = 0; i < 16; i = i + 1) begin
                stage1_real[i] <= 16'sd0;
            end
            fft_done <= 1'b0;

            // Reset all output registers to 0
            dout_real_0 <= 16'sd0; dout_imag_0 <= 16'sd0; dout_real_1 <= 16'sd0; dout_imag_1 <= 16'sd0;
            dout_real_2 <= 16'sd0; dout_imag_2 <= 16'sd0; dout_real_3 <= 16'sd0; dout_imag_3 <= 16'sd0;
            dout_real_4 <= 16'sd0; dout_imag_4 <= 16'sd0; dout_real_5 <= 16'sd0; dout_imag_5 <= 16'sd0;
            dout_real_6 <= 16'sd0; dout_imag_6 <= 16'sd0; dout_real_7 <= 16'sd0; dout_imag_7 <= 16'sd0;
            dout_real_8 <= 16'sd0; dout_imag_8 <= 16'sd0; dout_real_9 <= 16'sd0; dout_imag_9 <= 16'sd0;
            dout_real_10 <= 16'sd0; dout_imag_10 <= 16'sd0; dout_real_11 <= 16'sd0; dout_imag_11 <= 16'sd0;
            dout_real_12 <= 16'sd0; dout_imag_12 <= 16'sd0; dout_real_13 <= 16'sd0; dout_imag_13 <= 16'sd0;
            dout_real_14 <= 16'sd0; dout_imag_14 <= 16'sd0; dout_real_15 <= 16'sd0; dout_imag_15 <= 16'sd0;

        end else begin

            if (data_valid) begin
                case ({enable_block1, enable_block2, enable_block3, enable_block4})
                    4'b1000: begin
                        stage1_real[0] <= din_real_0;
                        stage1_real[1] <= din_real_1;
                        stage1_real[2] <= din_real_2;
                        stage1_real[3] <= din_real_3;
                        // Clear subsequent blocks as per original implied logic
                        for (i = 4; i < 16; i = i + 1) begin
                            stage1_real[i] <= 16'sd0;
                        end
                    end
                    4'b0100: begin
                        // stage1_real[0-3] retain their values from previous cycle
                        stage1_real[4] <= din_real_0;
                        stage1_real[5] <= din_real_1;
                        stage1_real[6] <= din_real_2;
                        stage1_real[7] <= din_real_3;
                        // Clear subsequent blocks
                        for (i = 8; i < 16; i = i + 1) begin
                            stage1_real[i] <= 16'sd0;
                        end
                    end
                    4'b0010: begin
                        // stage1_real[0-7] retain their values
                        stage1_real[8] <= din_real_0;
                        stage1_real[9] <= din_real_1;
                        stage1_real[10] <= din_real_2;
                        stage1_real[11] <= din_real_3;
                        // Clear subsequent blocks
                        for (i = 12; i < 16; i = i + 1) begin
                            stage1_real[i] <= 16'sd0;
                        end
                    end
                    4'b0001: begin
                        // stage1_real[0-11] retain their values
                        stage1_real[12] <= din_real_0;
                        stage1_real[13] <= din_real_1;
                        stage1_real[14] <= din_real_2;
                        stage1_real[15] <= din_real_3;
                        fft_done <= 1'b1; // All inputs loaded, FFT computation results will be ready
                    end
                    default: begin
                        // If no enable is active but data_valid is high, stage1_real holds values.
                        // fft_done also holds its value. This is implicit.
                    end
                endcase
            // If data_valid is false, stage1_real and fft_done hold their values (unless fft_done is cleared below)
            end

            if (fft_done && !data_valid) begin // Condition to clear fft_done for next run
                fft_done <= 1'b0;
            end

            // Latch outputs when fft_done is asserted (meaning results from combinatorial path are ready)
            // This happens one cycle after fft_done register is set.
            if (fft_done) begin // Note: This is the DU's internal fft_done register
                dout_real_0 <= wire_output_real[0]; dout_real_1 <= wire_output_real[1]; dout_imag_0 <= wire_output_imag[0]; dout_imag_1 <= wire_output_imag[1];
                dout_real_2 <= wire_output_real[2]; dout_real_3 <= wire_output_real[3]; dout_imag_2 <= wire_output_imag[2]; dout_imag_3 <= wire_output_imag[3];
                dout_real_4 <= wire_output_real[4]; dout_real_5 <= wire_output_real[5]; dout_imag_4 <= wire_output_imag[4]; dout_imag_5 <= wire_output_imag[5];
                dout_real_6 <= wire_output_real[6]; dout_real_7 <= wire_output_real[7]; dout_imag_6 <= wire_output_imag[6]; dout_imag_7 <= wire_output_imag[7];
                dout_real_8 <= wire_output_real[8]; dout_real_9 <= wire_output_real[9]; dout_imag_8 <= wire_output_imag[8]; dout_imag_9 <= wire_output_imag[9];
                dout_real_10 <= wire_output_real[10]; dout_real_11 <= wire_output_real[11]; dout_imag_10 <= wire_output_imag[10]; dout_imag_11 <= wire_output_imag[11];
                dout_real_12 <= wire_output_real[12]; dout_real_13 <= wire_output_real[13]; dout_imag_12 <= wire_output_imag[12]; dout_imag_13 <= wire_output_imag[13];
                dout_real_14 <= wire_output_real[14]; dout_real_15 <= wire_output_real[15]; dout_imag_14 <= wire_output_imag[14]; dout_imag_15 <= wire_output_imag[15];
            end
        end
    end

    // First stage FFT using fft_4point_1
    fft_4point_1 stage1_0 (
        .a0_real(stage1_real[0]), .a1_real(stage1_real[1]),
        .a2_real(stage1_real[2]), .a3_real(stage1_real[3]),
        .G0_real(stage2_real[0]), .G1_real(stage2_real[1]),
        .G2_real(stage2_real[2]), .G3_real(stage2_real[3]),
        .G0_imag(stage2_imag[0]), .G1_imag(stage2_imag[1]),
        .G2_imag(stage2_imag[2]), .G3_imag(stage2_imag[3])
    );

    fft_4point_1 stage1_1 (
        .a0_real(stage1_real[4]), .a1_real(stage1_real[5]),
        .a2_real(stage1_real[6]), .a3_real(stage1_real[7]),
        .G0_real(stage2_real[4]), .G1_real(stage2_real[5]),
        .G2_real(stage2_real[6]), .G3_real(stage2_real[7]),
        .G0_imag(stage2_imag[4]), .G1_imag(stage2_imag[5]),
        .G2_imag(stage2_imag[6]), .G3_imag(stage2_imag[7])
    );

    fft_4point_1 stage1_2 (
        .a0_real(stage1_real[8]), .a1_real(stage1_real[9]),
        .a2_real(stage1_real[10]), .a3_real(stage1_real[11]),
        .G0_real(stage2_real[8]), .G1_real(stage2_real[9]),
        .G2_real(stage2_real[10]), .G3_real(stage2_real[11]),
        .G0_imag(stage2_imag[8]), .G1_imag(stage2_imag[9]),
        .G2_imag(stage2_imag[10]), .G3_imag(stage2_imag[11])
    );

    fft_4point_1 stage1_3 (
        .a0_real(stage1_real[12]), .a1_real(stage1_real[13]),
        .a2_real(stage1_real[14]), .a3_real(stage1_real[15]),
        .G0_real(stage2_real[12]), .G1_real(stage2_real[13]),
        .G2_real(stage2_real[14]), .G3_real(stage2_real[15]),
        .G0_imag(stage2_imag[12]), .G1_imag(stage2_imag[13]),
        .G2_imag(stage2_imag[14]), .G3_imag(stage2_imag[15])
    );

    // Second stage FFT using fft_4point_2
    fft_4point_2 stage2_0 (
        .a0_real(stage2_real[0]), .a1_real(stage2_real[4]),
        .a2_real(stage2_real[8]), .a3_real(stage2_real[12]),
        .a0_imag(stage2_imag[0]), .a1_imag(stage2_imag[4]),
        .a2_imag(stage2_imag[8]), .a3_imag(stage2_imag[12]),
        .G0_real(wire_output_real[0]), .G1_real(wire_output_real[4]),
        .G2_real(wire_output_real[8]), .G3_real(wire_output_real[12]),
        .G0_imag(wire_output_imag[0]), .G1_imag(wire_output_imag[4]),
        .G2_imag(wire_output_imag[8]), .G3_imag(wire_output_imag[12])
    );

    fft_4point_2 stage2_1 (
        .a0_real(stage2_real[1]), .a1_real(stage2_real[5]),
        .a2_real(stage2_real[9]), .a3_real(stage2_real[13]),
        .a0_imag(stage2_imag[1]), .a1_imag(stage2_imag[5]),
        .a2_imag(stage2_imag[9]), .a3_imag(stage2_imag[13]),
        .G0_real(wire_output_real[1]), .G1_real(wire_output_real[5]),
        .G2_real(wire_output_real[9]), .G3_real(wire_output_real[13]),
        .G0_imag(wire_output_imag[1]), .G1_imag(wire_output_imag[5]),
        .G2_imag(wire_output_imag[9]), .G3_imag(wire_output_imag[13])
    );

    fft_4point_2 stage2_2 (
        .a0_real(stage2_real[2]), .a1_real(stage2_real[6]),
        .a2_real(stage2_real[10]), .a3_real(stage2_real[14]),
        .a0_imag(stage2_imag[2]), .a1_imag(stage2_imag[6]),
        .a2_imag(stage2_imag[10]), .a3_imag(stage2_imag[14]),
        .G0_real(wire_output_real[2]), .G1_real(wire_output_real[6]),
        .G2_real(wire_output_real[10]), .G3_real(wire_output_real[14]),
        .G0_imag(wire_output_imag[2]), .G1_imag(wire_output_imag[6]),
        .G2_imag(wire_output_imag[10]), .G3_imag(wire_output_imag[14])
    );

    fft_4point_2 stage2_3 (
        .a0_real(stage2_real[3]), .a1_real(stage2_real[7]),
        .a2_real(stage2_real[11]), .a3_real(stage2_real[15]),
        .a0_imag(stage2_imag[3]), .a1_imag(stage2_imag[7]),
        .a2_imag(stage2_imag[11]), .a3_imag(stage2_imag[15]),
        .G0_real(wire_output_real[3]), .G1_real(wire_output_real[7]),
        .G2_real(wire_output_real[11]), .G3_real(wire_output_real[15]),
        .G0_imag(wire_output_imag[3]), .G1_imag(wire_output_imag[7]),
        .G2_imag(wire_output_imag[11]), .G3_imag(wire_output_imag[15])
    );

endmodule