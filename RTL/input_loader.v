`timescale 1ns / 1ps

// Memory input loader reading HEX values from IN.txt and WB.txt
module input_loader #(
    parameter M = 4, 
    parameter N = 4, 
    parameter DATA_WIDTH = 8
) (
    input clk,
    input rst_n,
    input load_en,
    input stream_en,
    
    // External flattened matrices (Mapped internally)
    input  [2047:0] a_matrix_flat,  
    input  [2047:0] b_matrix_flat,  
    
    // Core vectors routed to PEs
    output reg [(M*N*DATA_WIDTH)-1:0] bias_matrix_flat,
    
    output reg [M*DATA_WIDTH-1:0] a_row_data_flat,
    output reg [M-1:0] a_row_valid,
    output reg [N*DATA_WIDTH-1:0] b_col_data_flat,
    output reg [N-1:0] b_col_valid,
    output reg [15:0] stream_cycle_dbg
);

    reg [7:0] MEM_IN [0:15];     // Matrix A memory limits
    reg [7:0] MEM_WB [0:31];     // Matrix B (0-15) and Bias C (16-31) limits

    reg [M*N*DATA_WIDTH-1:0] a_matrix_reg; 
    reg [N*N*DATA_WIDTH-1:0] b_matrix_reg;

    integer row_idx, col_idx, load_idx;
    integer a_elem_idx, b_elem_idx;

    // Initialize memories from text files (Files must be in simulation root directory)
    initial begin 
        $readmemh("IN.txt", MEM_IN); 
        $readmemh("WB.txt", MEM_WB);
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_matrix_reg      <= 0;
            b_matrix_reg      <= 0;
            bias_matrix_flat  <= 0; 
            
            a_row_data_flat   <= 0;
            a_row_valid       <= 0;
            b_col_data_flat   <= 0;
            b_col_valid       <= 0;
            stream_cycle_dbg  <= 16'd0;
        end else begin
            
            // Map read data to core registers dynamically (Row-Major)
            if (load_en) begin
                for(load_idx = 0; load_idx < (M * N); load_idx = load_idx + 1) begin
                    a_matrix_reg[(load_idx*8) +: 8]      <= MEM_IN[load_idx];
                    b_matrix_reg[(load_idx*8) +: 8]      <= MEM_WB[load_idx];
                    bias_matrix_flat[(load_idx*8) +: 8]  <= MEM_WB[16+load_idx]; 
                end 
                stream_cycle_dbg <= 16'd0;
            end

            // Apply pipeline skew delays for correct data streaming
            if (stream_en) begin
                
                // Route stream arrays sequentially by dimension bounds
                for (row_idx = 0; row_idx < M; row_idx = row_idx + 1) begin
                    if ((stream_cycle_dbg >= row_idx) && ((stream_cycle_dbg - row_idx) < N)) begin
                        a_elem_idx = (row_idx * N) + (stream_cycle_dbg - row_idx);
                        a_row_data_flat[(row_idx*DATA_WIDTH) +: DATA_WIDTH] <= a_matrix_reg[(a_elem_idx*DATA_WIDTH) +: DATA_WIDTH];
                        a_row_valid[row_idx] <= 1'b1;
                    end else begin
                        a_row_data_flat[(row_idx*DATA_WIDTH) +: DATA_WIDTH] <= 0;
                        a_row_valid[row_idx] <= 1'b0;
                    end
                end

                for (col_idx = 0; col_idx < N; col_idx = col_idx + 1) begin
                    if ((stream_cycle_dbg >= col_idx) && ((stream_cycle_dbg - col_idx) < N)) begin
                        b_elem_idx = ((stream_cycle_dbg - col_idx) * N) + col_idx; 
                        b_col_data_flat[(col_idx*DATA_WIDTH) +: DATA_WIDTH] <= b_matrix_reg[(b_elem_idx*DATA_WIDTH) +: DATA_WIDTH];
                        b_col_valid[col_idx] <= 1'b1;
                    end else begin
                        b_col_data_flat[(col_idx*DATA_WIDTH) +: DATA_WIDTH] <= 0;
                        b_col_valid[col_idx] <= 1'b0;
                    end
                end

                stream_cycle_dbg <= stream_cycle_dbg + 16'd1;
            end else begin
                a_row_data_flat <= 0;
                a_row_valid     <= 0;
                b_col_data_flat <= 0;
                b_col_valid     <= 0;
            end
            
        end
    end
endmodule