`timescale 1ns / 1ps

module activation_block_32b (
    input signed [31:0] data_in_real,
    input signed [31:0] data_in_imag,
    output wire signed [31:0] data_out_real,
    output wire signed [31:0] data_out_imag
);
    assign data_out_real = data_in_real[31] ? 32'sd0 : data_in_real;
    assign data_out_imag = data_in_imag[31] ? 32'sd0 : data_in_imag;
endmodule