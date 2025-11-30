`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/16/2025 06:50:34 AM
// Design Name: 
// Module Name: tb_spectral_cnn_layer_v1_base
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


module tb_spectral_cnn_layer_v1_base;

    //------------------------------------------------------------------
    // Parameters
    //------------------------------------------------------------------
    parameter CLK_PERIOD = 10; // ns
    // V1 Change: Total 16-bit words to load into Kernel SRAM (6 filters * 16 complex * 2 parts)
    parameter NUM_KERNEL_WORDS = 192;
    // V1 Change: Total 32-bit words to expect in Output SRAM (6 filters * 16 complex * 2 parts)
    parameter NUM_OUTPUT_WORDS = 192;
    // CYCLE COUNTER: Timeout value for the main processing loop
    parameter PROCESSING_TIMEOUT_CYCLES = 3000;

    //------------------------------------------------------------------
    // Testbench Signals
    //------------------------------------------------------------------
    reg clk;
    reg reset;
    reg top_start_tb;
    reg load_kernel_en_tb;
    reg [15:0] kernel_data_in_bus_tb;
    reg [7:0] kernel_load_addr_bus_tb; // V1 Change: Width 7->8

    // Individual raw input data signals for the DUT
    reg [15:0] raw_tb_0,  raw_tb_1,  raw_tb_2,  raw_tb_3;
    reg [15:0] raw_tb_4,  raw_tb_5,  raw_tb_6,  raw_tb_7;
    reg [15:0] raw_tb_8,  raw_tb_9,  raw_tb_10, raw_tb_11;
    reg [15:0] raw_tb_12, raw_tb_13, raw_tb_14, raw_tb_15;

    // Signals for output SRAM readback interface
    reg output_sram_read_en_tb;
    reg [7:0] output_sram_read_addr_tb;
    wire [31:0] output_sram_data_out_dut; // V1 Change: Width 64->32

    // DUT Output
    wire top_layer_done_dut;

    // CYCLE COUNTER: Add a global, free-running cycle counter register
    reg [31:0] cycle_counter_g;

    integer start_cycle, end_cycle;
    //------------------------------------------------------------------
    // Instantiate the DUT (Device Under Test)
    //------------------------------------------------------------------
    spectral_cnn_layer dut (
        .clk(clk),
        .reset(reset),
        .top_start(top_start_tb),
        .load_kernel_en(load_kernel_en_tb),
        .kernel_data_in_bus(kernel_data_in_bus_tb),
        .kernel_load_addr_bus(kernel_load_addr_bus_tb),
        .raw_input_data_0(raw_tb_0),   .raw_input_data_1(raw_tb_1),
        .raw_input_data_2(raw_tb_2),   .raw_input_data_3(raw_tb_3),
        .raw_input_data_4(raw_tb_4),   .raw_input_data_5(raw_tb_5),
        .raw_input_data_6(raw_tb_6),   .raw_input_data_7(raw_tb_7),
        .raw_input_data_8(raw_tb_8),   .raw_input_data_9(raw_tb_9),
        .raw_input_data_10(raw_tb_10), .raw_input_data_11(raw_tb_11),
        .raw_input_data_12(raw_tb_12), .raw_input_data_13(raw_tb_13),
        .raw_input_data_14(raw_tb_14), .raw_input_data_15(raw_tb_15),
        // Connect output readback interface
        .output_sram_read_en(output_sram_read_en_tb),
        .output_sram_read_addr(output_sram_read_addr_tb),
        .output_sram_data_out(output_sram_data_out_dut),
        .top_layer_done(top_layer_done_dut)
    );

    //------------------------------------------------------------------
    // Clock Generation
    //------------------------------------------------------------------
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    //------------------------------------------------------------------
    // CYCLE COUNTER: Logic for the global cycle counter
    //------------------------------------------------------------------
    always @(posedge clk or posedge reset) begin
        if (reset)
            cycle_counter_g <= 32'd0;
        else
            cycle_counter_g <= cycle_counter_g + 1;
    end

    //------------------------------------------------------------------
    // Test Sequence Tasks
    //------------------------------------------------------------------

    task load_kernels_procedurally;
        integer i;
        reg signed [15:0] kernel_part;
        begin
            $display("[%0t ns] TB: Starting Kernel Load (%0d 16-bit words)...", $time, NUM_KERNEL_WORDS);
            load_kernel_en_tb = 1'b1;
            for (i = 0; i < NUM_KERNEL_WORDS; i = i + 1) begin
                kernel_load_addr_bus_tb = i;

                // Simple, non-zero values for testing the data path
                if (i % 2 == 0)
                    kernel_part = $signed((i/2) + 50);  // Real Part
                else
                    kernel_part = $signed((i/2) + 150); // Imaginary Part
                
                kernel_data_in_bus_tb = kernel_part;
                @(posedge clk); // CU performs the 16-bit write on this clock edge.
            end
            load_kernel_en_tb = 1'b0; // De-assert after the loop
            kernel_load_addr_bus_tb = 8'd0;
            kernel_data_in_bus_tb = 16'sd0;
            @(posedge clk);
            $display("[%0t ns] TB: Kernel Load Finished.", $time);
        end
    endtask

    task apply_input_stimulus;
        begin
            $display("[%0t ns] TB: Applying Raw Input Data...", $time);
            raw_tb_0  = 1; raw_tb_1  = 2; raw_tb_2  = 3; raw_tb_3  = 4;
            raw_tb_4  = 5; raw_tb_5  = 6; raw_tb_6  = 7; raw_tb_7  = 8;
            raw_tb_8  = 9; raw_tb_9  = 10; raw_tb_10 = 11; raw_tb_11 = 12;
            raw_tb_12 = 13; raw_tb_13 = 14; raw_tb_14 = 15; raw_tb_15 = 16;
            $display("[%0t ns] TB: Raw Input Data Applied.", $time);
        end
    endtask

    //------------------------------------------------------------------
    // Main Simulation Sequence
    //------------------------------------------------------------------
    initial begin
        // CYCLE COUNTER: Variables to store start/end cycle counts for timing phases


        $display("====================================================");
        $display("[%0t ns] Starting V1_Base Top-Level Testbench", $time);
        $display("====================================================");

        // 1. Initialize all testbench registers
        reset = 1'b1;
        top_start_tb = 1'b0;
        load_kernel_en_tb = 1'b0;
        kernel_data_in_bus_tb = 16'sd0;
        kernel_load_addr_bus_tb = 8'd0;
        output_sram_read_en_tb = 1'b0;
        output_sram_read_addr_tb = 8'd0;
        raw_tb_0=0; raw_tb_1=0; raw_tb_2=0; raw_tb_3=0; raw_tb_4=0; raw_tb_5=0; raw_tb_6=0; raw_tb_7=0;
        raw_tb_8=0; raw_tb_9=0; raw_tb_10=0;raw_tb_11=0;raw_tb_12=0;raw_tb_13=0;raw_tb_14=0;raw_tb_15=0;

        // 2. Apply reset
        #(CLK_PERIOD * 5);
        reset = 1'b0;
        @(posedge clk); // Align to a clock edge before releasing reset
        $display("[%0t ns] TB: Reset Released.", $time);

        // 3. Load Kernel SRAM procedurally and measure duration
        start_cycle = cycle_counter_g;
        load_kernels_procedurally();
        end_cycle = cycle_counter_g;
        $display("    -> Kernel Load Time: %0d cycles.", end_cycle - start_cycle);
        #(CLK_PERIOD * 5); // Wait a few cycles after loading

        // 4. Apply the raw input stimulus
        apply_input_stimulus();
        #(CLK_PERIOD * 2);

        // 5. Start the layer processing
        $display("[%0t ns] TB: Asserting top_start_tb for one cycle.", $time);
        top_start_tb = 1'b1;
        @(posedge clk);
        top_start_tb = 1'b0;
        
        // CYCLE COUNTER: Capture start cycle for processing
        start_cycle = cycle_counter_g;
        $display("[%0t ns] TB: Waiting for layer completion (Timeout: %0d cycles)...", $time, PROCESSING_TIMEOUT_CYCLES);

        // 6. Wait for the 'done' signal or a timeout
        // CYCLE COUNTER: The while loop now uses the global counter for timeout
        while (!top_layer_done_dut && (cycle_counter_g - start_cycle < PROCESSING_TIMEOUT_CYCLES)) begin
            @(posedge clk);
        end

        // CYCLE COUNTER: Capture end cycle for processing
        end_cycle = cycle_counter_g;

        // 7. Report final status
        if (top_layer_done_dut) begin
            $display("[%0t ns] TB: *** TEST PASSED! *** top_layer_done asserted.", $time);
            $display("    -> Processing Time: %0d cycles.", end_cycle - start_cycle);
            #(CLK_PERIOD); // Wait one cycle for final values to be stable
            
            // Display first and last values from output SRAM
            $display("--- Output SRAM Spot Check ---");
            $display("Output SRAM Addr 0   (Res 0 Real): Data=0x%h", dut.output_sram_inst_top_level.mem[0]);
            $display("Output SRAM Addr 1   (Res 0 Imag): Data=0x%h", dut.output_sram_inst_top_level.mem[1]);
            $display("Output SRAM Addr 190 (Res 95 Real): Data=0x%h", dut.output_sram_inst_top_level.mem[190]);
            $display("Output SRAM Addr 191 (Res 95 Imag): Data=0x%h", dut.output_sram_inst_top_level.mem[191]);
        end else begin
            $error("[%0t ns] TB: *** TEST FAILED! *** TIMEOUT after %0d cycles.", $time, end_cycle - start_cycle);
        end

        #(CLK_PERIOD * 10);
        $display("====================================================");
        $display("[%0t ns] V1_Base Testbench Finished.", $time);
        // CYCLE COUNTER: Report total simulation cycles
        $display("    -> Total Simulation Time: %0d cycles.", cycle_counter_g);
        $display("====================================================");
        $finish;
    end

endmodule

