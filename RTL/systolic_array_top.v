`timescale 1ns / 1ps

// Top-level systolic array module
module systolic_array_top (
    clk,
    rst_n,
    start,
    busy,
    done,
    out_valid,
    out_addr,
    out_data
);

    // System parameters
    parameter m = 4;           // Number of rows (m=1 for 1 output, m=4 for full array)
    parameter n = 4;           // Inner dimension & output columns
    parameter DATA_WIDTH = 8;  // 8-bit signed input data
    parameter ACC_WIDTH = 18;  // 18-bit signed accumulator output

    // I/O ports
    input wire clk;
    input wire rst_n;
    input wire start;
    output wire busy;
    output wire done;
    output wire out_valid;
    output wire [3:0] out_addr;      
    output wire [17:0] out_data;     

    // Internal FSM control signals
    wire ctrl_load_en;
    wire ctrl_stream_en;
    wire ctrl_compute_en;
    wire ctrl_clear_acc;
    wire ctrl_collect_en;
    wire ctrl_writeback;

    // Flattened internal memory buses
    wire [(m*n*DATA_WIDTH)-1:0] internal_a_mem_flat; 
    wire [(n*n*DATA_WIDTH)-1:0] internal_b_mem_flat; 
    wire [(m*n*DATA_WIDTH)-1:0] internal_bias_flat; // Bias matrix data bus
    
    // Internal data routing signals
    wire [m*DATA_WIDTH-1:0] loader_a_row_data_flat;
    wire [m-1:0] loader_a_row_valid;
    wire [n*DATA_WIDTH-1:0] loader_b_col_data_flat;
    wire [n-1:0] loader_b_col_valid;
    wire [(m*n*ACC_WIDTH)-1:0] array_c_psum_flat;
    wire collector_c_valid; 

    // System FSM controller
    controller #(
        .M(m),
        .N(n)
    ) u_controller (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .busy(busy),
        .done(done),
        .writeback(ctrl_writeback),    
        .load_en(ctrl_load_en),
        .stream_en(ctrl_stream_en),
        .compute_en(ctrl_compute_en),
        .clear_acc(ctrl_clear_acc),
        .collect_en(ctrl_collect_en)
    );

    // Input data loader for routing matrices
    input_loader #(
        .M(m),
        .N(n),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_input_loader (
        .clk(clk),
        .rst_n(rst_n),
        .load_en(ctrl_load_en),
        .stream_en(ctrl_stream_en),
        
        .a_matrix_flat(internal_a_mem_flat), 
        .b_matrix_flat(internal_b_mem_flat),
        .bias_matrix_flat(internal_bias_flat), // Links bias matrix from memory
        
        .a_row_data_flat(loader_a_row_data_flat),
        .a_row_valid(loader_a_row_valid),
        .b_col_data_flat(loader_b_col_data_flat),
        .b_col_valid(loader_b_col_valid)
    );

    // Core systolic processing elements (PE) array
    systolic_array #(
        .M(m),
        .N(n),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) u_systolic_array (
        .clk(clk),
        .rst_n(rst_n),
        .clear_acc(ctrl_clear_acc),
        .enable(ctrl_compute_en),
        .a_row_data_flat(loader_a_row_data_flat),
        .a_row_valid(loader_a_row_valid),
        .b_col_data_flat(loader_b_col_data_flat),
        .b_col_valid(loader_b_col_valid),
        
        .bias_matrix_flat(internal_bias_flat), // Direct assignment to PEs
        .c_psum_flat(array_c_psum_flat) 
    );

    // Output collector for results serialization
    output_collector #(
        .M(m),
        .N(n),
        .ACC_WIDTH(ACC_WIDTH)
    ) u_output_collector (
        .clk(clk),
        .rst_n(rst_n),
        .writeback(ctrl_writeback),     
        .c_psum_flat_in(array_c_psum_flat),
        
        .out_valid(out_valid),
        .out_addr(out_addr),
        .out_data(out_data)
    );

endmodule