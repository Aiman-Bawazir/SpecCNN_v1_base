`timescale 1ns / 1ps

module sram_sync_single_port #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 5,
    parameter DEPTH = 1 << ADDR_WIDTH,
    parameter INIT_FILE = "" // Optional for file-based initialization
) (
    input clk,
    input reset,
    input write_enable,
    input read_enable,
    input [ADDR_WIDTH-1:0] address,
    input [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out
);
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR_WIDTH-1:0] read_addr_reg;

    initial begin
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, mem);
        end
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            read_addr_reg <= {ADDR_WIDTH{1'b0}};
        end else if (read_enable) begin
            read_addr_reg <= address;
        end
    end

    always @(posedge clk) begin
        if (write_enable) begin
            mem[address] <= data_in;
        end
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            data_out <= {DATA_WIDTH{1'b0}};
        end else if (read_enable) begin
            data_out <= mem[read_addr_reg];
        end
    end
endmodule