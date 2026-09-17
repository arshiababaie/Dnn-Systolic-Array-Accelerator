`timescale 1ns / 1ps

// Core systolic array interconnecting processing elements (PEs)
module systolic_array #(
    parameter M = 4,   
    parameter N = 4,   
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH  = 18 
) (
    input clk,
    input rst_n,
    input clear_acc,
    input enable,
    
    input [(M*DATA_WIDTH)-1:0] a_row_data_flat,
    input [M-1:0] a_row_valid,
    input [(N*DATA_WIDTH)-1:0] b_col_data_flat,
    input [N-1:0] b_col_valid,
    
    // Flattened bias matrix C distributed to individual PEs
    input [(M*N*DATA_WIDTH)-1:0] bias_matrix_flat,
    
    output [(M*N*ACC_WIDTH)-1:0] c_psum_flat
);

    genvar row;
    genvar col;

    // Routing buses for matrices and valid signals
    wire signed [DATA_WIDTH-1:0] a_bus [0:M-1][0:N];
    wire                         a_valid_bus [0:M-1][0:N];

    wire signed [DATA_WIDTH-1:0] b_bus [0:M][0:N-1];
    wire                         b_valid_bus [0:M][0:N-1];

    wire signed [ACC_WIDTH-1:0]  pe_psum [0:M-1][0:N-1];

    generate
        // Map incoming flattened A rows to the left edge
        for (row = 0; row < M; row = row + 1) begin : GEN_A_EDGE
            assign a_bus[row][0] = a_row_data_flat[(row*DATA_WIDTH) +: DATA_WIDTH];
            assign a_valid_bus[row][0] = a_row_valid[row];
        end

        // Map incoming flattened B columns to the top edge
        for (col = 0; col < N; col = col + 1) begin : GEN_B_EDGE
            assign b_bus[0][col] = b_col_data_flat[(col*DATA_WIDTH) +: DATA_WIDTH];
            assign b_valid_bus[0][col] = b_col_valid[col];
        end

        // Generate NxM grid of processing elements
        for (row = 0; row < M; row = row + 1) begin : GEN_ROWS
            for (col = 0; col < N; col = col + 1) begin : GEN_COLS
                
                pe #(
                    .DATA_WIDTH(DATA_WIDTH),
                    .ACC_WIDTH(ACC_WIDTH)
                ) u_pe (
                    .clk(clk),
                    .rst_n(rst_n),
                    .clear_acc(clear_acc),
                    .enable(enable),
                    .a_in(a_bus[row][col]),
                    .b_in(b_bus[row][col]),
                    
                    // Extract 8-bit bias mapped exclusively to this PE
                    .bias_in(bias_matrix_flat[((row*N + col)*DATA_WIDTH) +: DATA_WIDTH]), 
                    
                    .a_valid_in(a_valid_bus[row][col]),
                    .b_valid_in(b_valid_bus[row][col]),
                    .a_out(a_bus[row][col+1]),
                    .b_out(b_bus[row+1][col]),
                    .a_valid_out(a_valid_bus[row][col+1]),
                    .b_valid_out(b_valid_bus[row+1][col]),
                    
                    .psum_out(pe_psum[row][col]) 
                );

                // Flatten partial sum outputs for serialization
                assign c_psum_flat[((row*N + col)*ACC_WIDTH) +: ACC_WIDTH] = pe_psum[row][col];
            end
        end
    endgenerate

endmodule