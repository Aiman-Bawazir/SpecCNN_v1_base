`timescale 1ns / 1ps

module fft_control_unit (
    input clk,
    input reset,
    input start,
    output reg data_valid,
    output reg done,
    input fft_done,         // input to receive completion signal from DU
    output reg enable_block1,
    output reg enable_block2,
    output reg enable_block3,
    output reg enable_block4
);

    // State definition using parameters (can use `include "fft_definitions.vh"` or define locally)
    parameter IDLE     = 3'b000,
              INPUT1   = 3'b001,
              INPUT2   = 3'b010,
              INPUT3   = 3'b011,
              INPUT4   = 3'b100,
              FINALIZE = 3'b101; 

    reg [2:0] state, next_state;

    // Sequential block for state transition
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // State transition logic
    always @(*) begin
        // Default values for outputs
        data_valid    = 1'b0;
        done          = 1'b0;
        enable_block1 = 1'b0;
        enable_block2 = 1'b0;
        enable_block3 = 1'b0;
        enable_block4 = 1'b0;
        next_state    = state; // Default to same state

        case (state)
            IDLE: begin
                if (start) begin
                    next_state    = INPUT1;
                    enable_block1 = 1'b1;
                    data_valid    = 1'b1;
                end
            end
            INPUT1: begin // Corresponds to enable_block1 being active in DU for loading
                data_valid    = 1'b1;
                enable_block2 = 1'b1; // CU asserts this to enable DU's block2 for next cycle
                next_state    = INPUT2;
            end
            INPUT2: begin // Corresponds to enable_block2 being active in DU
                data_valid    = 1'b1;
                enable_block3 = 1'b1;
                next_state    = INPUT3;
            end
            INPUT3: begin // Corresponds to enable_block3 being active in DU
                data_valid    = 1'b1;
                enable_block4 = 1'b1; // CU asserts this for DU's block4 loading
                next_state    = INPUT4;
            end
            INPUT4: begin // Corresponds to enable_block4 being active in DU
                          // DU's fft_done is set at the end of this cycle's processing of enable_block4
                data_valid    = 1'b1; // Keep data_valid high for DU's fft_done clear condition
                next_state    = FINALIZE;
            end
            FINALIZE: begin
                if (fft_done) begin     // Check DU's completion signal
                    done       = 1'b1;  // Assert top-level done: dout_* are valid
                    next_state = IDLE;  // Return to idle state
                end else begin
                    // This case should ideally not be hit if DU operates as expected
                    // and fft_done is asserted promptly.
                    next_state = FINALIZE; // Remain in FINALIZE waiting for fft_done
                end
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end
endmodule