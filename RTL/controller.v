`timescale 1ns / 1ps

// Main FSM controller for the systolic array
module controller #(
    parameter M = 4,   
    parameter N = 4    
) (
    input clk,
    input rst_n,
    input start,
    output reg busy,
    output reg done,
    output reg writeback,     
    output reg load_en,
    output reg stream_en,
    output reg compute_en,
    output reg clear_acc,
    output reg collect_en,
    output reg [2:0] state_dbg,
    output reg [15:0] cycle_count_dbg
);

    // FSM state encoding
    localparam [2:0] IDLE       = 3'd0;
    localparam [2:0] LOAD       = 3'd1;
    localparam [2:0] COMPUTE    = 3'd2;
    localparam [2:0] WRITEBACK  = 3'd3;
    localparam [2:0] DONE       = 3'd4;

    // Execution cycle lengths
    localparam [15:0] STREAM_CYCLES = M + N - 1;          
    localparam [15:0] DRAIN_CYCLES  = N;                  
    localparam [15:0] COMPUTE_TOTAL = STREAM_CYCLES + DRAIN_CYCLES;
    
    // Output serialization duration
    localparam [15:0] SERIAL_WRITEBACK = M * N + 2;           

    reg [2:0] state_reg;
    reg [15:0] phase_count_reg;

    // FSM state and phase transitions
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_reg       <= IDLE;
            phase_count_reg <= 16'd0;
        end else begin
            case (state_reg)
                IDLE: begin
                    phase_count_reg <= 16'd0;
                    if (start) state_reg <= LOAD;
                end

                LOAD: begin
                    // 2-cycle load delay to ensure SRAM data sets onto bus
                    if (phase_count_reg == 1) begin
                       state_reg       <= COMPUTE;
                       phase_count_reg <= 16'd0;
                    end else begin
                       phase_count_reg <= phase_count_reg + 16'd1;
                    end
                end

                COMPUTE: begin
                    if (phase_count_reg == (COMPUTE_TOTAL - 1)) begin
                        state_reg       <= WRITEBACK;
                        phase_count_reg <= 16'd0;
                    end else begin
                        phase_count_reg <= phase_count_reg + 16'd1;
                    end
                end

                WRITEBACK: begin
                    if (phase_count_reg == (SERIAL_WRITEBACK - 1)) begin
                        state_reg       <= DONE;
                        phase_count_reg <= 16'd0;
                    end else begin
                        phase_count_reg <= phase_count_reg + 16'd1;
                    end
                end

                DONE: begin
                    state_reg       <= IDLE;
                    phase_count_reg <= 16'd0;
                end
                
                default: begin 
                    state_reg <= IDLE;
                    phase_count_reg <= 16'd0;
                end 
            endcase
        end
    end

    // Cycle counter for debugging
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)          cycle_count_dbg <= 16'd0;
        else if (start)      cycle_count_dbg <= 16'd0;
        else if (busy)       cycle_count_dbg <= cycle_count_dbg + 16'd1;
    end

    // FSM outputs definition
    always @(*) begin
        busy       = 1'b0;
        done       = 1'b0;
        load_en    = 1'b0;
        stream_en  = 1'b0;
        compute_en = 1'b0;
        clear_acc  = 1'b0;
        collect_en = 1'b0;
        writeback  = 1'b0;
        state_dbg  = state_reg;

        case (state_reg)
            IDLE:      busy       = 1'b0;
            LOAD: begin 
                       busy       = 1'b1;
                       load_en    = 1'b1;
                       clear_acc  = 1'b1;
            end
            COMPUTE: begin 
                       busy       = 1'b1;
                       compute_en = 1'b1;
                       if (phase_count_reg < STREAM_CYCLES) stream_en = 1'b1;
            end
            WRITEBACK: begin
                       busy       = 1'b1;
                       collect_en = 1'b1; 
                       writeback  = 1'b1; 
            end
            DONE:      done       = 1'b1;
        endcase
    end
endmodule