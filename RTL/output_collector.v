`timescale 1ns / 1ps

// Sequential output collector for serialized readout
module output_collector #(
    parameter M = 4, 
    parameter N = 4,
    parameter ACC_WIDTH  = 18 
) (
    input clk,
    input rst_n,
    input writeback,                               // FSM writeback trigger
    
    input [(M*N*ACC_WIDTH)-1:0] c_psum_flat_in,    // Parallel snapshot of array results
    
    // Serialized output ports
    output reg out_valid,
    output reg [3:0] out_addr, 
    output reg [17:0] out_data 
);

    reg [(M*N*ACC_WIDTH)-1:0] buffered_results;
    reg flag_buffered_once; 
    
    integer flat_counter; // Internal address counter

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_addr           <= 4'd0;
            out_valid          <= 1'b0;
            out_data           <= 18'd0;
            buffered_results   <= 0;
            flag_buffered_once <= 1'b0;
            flat_counter       <= 0;
        end else begin
            
            // Reset tracking flags when idle
            if (!writeback) begin 
                flag_buffered_once <= 1'b0;
                flat_counter       <= 0; 
                out_valid          <= 1'b0;
            end

            // Cycle-by-cycle sequential extraction
            if (writeback) begin
                // Lock accumulated results on the first cycle
                if (!flag_buffered_once) begin 
                   buffered_results <= c_psum_flat_in; 
                   flag_buffered_once <= 1'b1;
                   out_valid <= 1'b0; 
                end 
                else if (flat_counter < (M * N)) begin
                   out_valid <= 1'b1;
                   out_addr  <= flat_counter[3:0]; // Set output address
                   
                   // Route specific PE result to output pin
                   out_data  <= buffered_results[(flat_counter*ACC_WIDTH) +: ACC_WIDTH];
                   flat_counter <= flat_counter + 1;
                end 
                else begin 
                   // End of transmission
                   out_valid <= 1'b0;
                end 
            end

        end
    end

endmodule