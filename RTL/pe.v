`timescale 1ns / 1ps

// 8-bit signed Wallace tree multiplier

// 16-bit Carry-Save Adder (CSA)
module csa_16bit (  
    input  [15:0] a,
    input  [15:0] b,
    input  [15:0] cin,
    output [15:0] sum,
    output [15:0] carry
);
    assign sum   = a ^ b ^ cin;
    assign carry = (a & b) | (a & cin) | (b & cin); 
endmodule

// Wallace tree construction module
module wallace_tree_8bit_signed (
    input signed [7:0] a,
    input signed [7:0] b,
    output signed [15:0] prod
);
    // Sign-extend multiplicand
    wire signed [15:0] a_ext = {{8{a[7]}}, a}; 

    // Generate partial products
    wire [15:0] pp0 = b[0] ? (a_ext) : 16'd0;
    wire [15:0] pp1 = b[1] ? (a_ext << 1) : 16'd0;
    wire [15:0] pp2 = b[2] ? (a_ext << 2) : 16'd0;
    wire [15:0] pp3 = b[3] ? (a_ext << 3) : 16'd0;
    wire [15:0] pp4 = b[4] ? (a_ext << 4) : 16'd0;
    wire [15:0] pp5 = b[5] ? (a_ext << 5) : 16'd0;
    wire [15:0] pp6 = b[6] ? (a_ext << 6) : 16'd0;
    
    // MSB partial product (2's complement subtraction)
    wire [15:0] a_ext_neg = -a_ext;
    wire [15:0] pp7 = b[7] ? (a_ext_neg << 7) : 16'd0;

    // Stage 1: Compress 8 to 6 terms
    wire [15:0] s1_1, c1_1;
    wire [15:0] s1_2, c1_2;
    csa_16bit CSA1_1 (pp0, pp1, pp2, s1_1, c1_1);
    csa_16bit CSA1_2 (pp3, pp4, pp5, s1_2, c1_2);

    // Stage 2: Compress 6 to 4 terms
    wire [15:0] s2_1, c2_1;
    wire [15:0] s2_2, c2_2;
    csa_16bit CSA2_1 (s1_1, (c1_1 << 1), s1_2, s2_1, c2_1);
    csa_16bit CSA2_2 ((c1_2 << 1), pp6, pp7, s2_2, c2_2);

    // Stage 3: Compress 4 to 3 terms
    wire [15:0] s3_1, c3_1;
    csa_16bit CSA3_1 (s2_1, (c2_1 << 1), s2_2, s3_1, c3_1);

    // Stage 4: Compress 3 to 2 terms
    wire [15:0] s4_1, c4_1;
    csa_16bit CSA4_1 (s3_1, (c3_1 << 1), (c2_2 << 1), s4_1, c4_1);

    // Stage 5: Final addition
    assign prod = s4_1 + (c4_1 << 1); 

endmodule


// 18-bit Carry Lookahead Adder (CLA)
module cla_18bit (
    input [17:0] a,
    input [17:0] b,
    output [17:0] sum
);
    wire [17:0] gen = a & b;       
    wire [17:0] prop = a ^ b;      
    wire [18:0] carry;
    assign carry[0] = 1'b0;

    genvar i;
    generate
        for(i = 0; i < 18; i = i + 1) begin: carry_lookahead
            assign carry[i+1] = gen[i] | (prop[i] & carry[i]);
            assign sum[i] = prop[i] ^ carry[i];
        end
    endgenerate
endmodule


// Processing Element (PE) module
module pe #(
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH  = 18    
) (
    input clk,
    input rst_n,
    input clear_acc,
    input enable,
    
    input signed [DATA_WIDTH-1:0] a_in,    
    input signed [DATA_WIDTH-1:0] b_in,    
    input signed [DATA_WIDTH-1:0] bias_in,   
    input a_valid_in,
    input b_valid_in,
    
    output reg signed [DATA_WIDTH-1:0] a_out,
    output reg signed [DATA_WIDTH-1:0] b_out,
    output reg a_valid_out,
    output reg b_valid_out,
    
    output reg signed [ACC_WIDTH-1:0] psum_out,
    output wire mac_fire
);

    wire signed [15:0] mult_result;      
    wire signed [ACC_WIDTH-1:0] mult_ext; 
    wire signed [ACC_WIDTH-1:0] cla_sum_res; 

    assign mac_fire = enable && a_valid_in && b_valid_in;
    
    // Multiplication via Wallace tree
    wallace_tree_8bit_signed VLSI_MAC_MULTIPLIER (
        .a(a_in), 
        .b(b_in), 
        .prod(mult_result)
    );

    // Sign-extend multiplier output to accumulator width
    assign mult_ext = {{(ACC_WIDTH-16){mult_result[15]}}, mult_result};

    // Addition via Carry Lookahead Adder (CLA)
    cla_18bit VLSI_MAC_ADDER(
        .a(psum_out),
        .b(mult_ext),
        .sum(cla_sum_res)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_out       <= 0;
            b_out       <= 0;
            a_valid_out <= 0;
            b_valid_out <= 0;
            psum_out    <= 0;
        end else begin
            a_out       <= a_in;
            b_out       <= b_in;
            a_valid_out <= a_valid_in;
            b_valid_out <= b_valid_in;

            if (clear_acc) begin
                // Initialize accumulator with sign-extended bias
                psum_out <= {{(ACC_WIDTH-DATA_WIDTH){bias_in[DATA_WIDTH-1]}}, bias_in}; 
            end else if (mac_fire) begin
                psum_out <= cla_sum_res;  
            end
        end
    end
endmodule