`timescale 1ns / 1ps

// Testbench for systolic array MAC operations and validation
module tb_systolic_top;

    reg clk;
    reg rst_n;
    reg start;

    wire busy;
    wire done;
    wire out_valid;
    wire [3:0] out_addr;
    wire signed [17:0] out_data; // Signed for proper decimal rendering

    // Expected output matrix for validation
    reg signed [17:0] expected_matrix [0:15];
    integer correct_tests;

    // Instantiate top-level module
    systolic_array_top u_sys_top (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        
        .busy(busy),
        .done(done),
        .out_valid(out_valid),
        .out_addr(out_addr),
        .out_data(out_data)
    );

    always #5 clk = ~clk; 

    initial begin
        clk = 0;
        rst_n = 0;
        start = 0;
        correct_tests = 0;

        // Load predefined expected mathematical results
        expected_matrix[0] = -18'd2020;   expected_matrix[1] = 18'd2152;  
        expected_matrix[2] = -18'd2284;   expected_matrix[3] = 18'd2416;
        
        expected_matrix[4] = 18'd4227;    expected_matrix[5] = -18'd4428;    
        expected_matrix[6] = 18'd4629;    expected_matrix[7] = -18'd4830;
        
        expected_matrix[8] = -18'd5779;   expected_matrix[9] = 18'd6016;  
        expected_matrix[10]= -18'd6253;   expected_matrix[11]= 18'd6490;
        
        expected_matrix[12]= 18'd2434;    expected_matrix[13]= -18'd2536;   
        expected_matrix[14]= 18'd2638;    expected_matrix[15]= -18'd2740;
        
        #25 rst_n = 1;
        #15 start = 1; 
        
        $display("---------------------------------------------------------");
        $display("   Systolic Mesh HW Initialization! Firing System FSM    ");
        $display("---------------------------------------------------------");
        
        #10 start = 0;

        // Wait until FSM signals process completion
        wait(done);

        #10 $display("\nAll 16 results completed properly inside System Core Output Reg Logic bounds Limits.");
        $display("Matched Tests Rate Result Finalized Evaluation : [%d / 16 PASSED].", correct_tests);
        
        if(correct_tests == 16)
            $display("-> FANTASTIC ! MAC PE Arrays & Bias loading passed flawlessly accurately bounds.");
        else
            $display("-> Errors mapped dynamically outputing. Requires re-sync mapping parameters validation logic check !");

        $finish;
    end

    // Monitor and validate output results sequentially
    always @(posedge clk) begin
        if (out_valid) begin
            $display("\nClock Output Check Index Address[%d]:", out_addr);
            $display("- Computed HW Systolic Output Matrix Value : %d", out_data);
            $display("- Exact Mathematical Document Value        : %d", expected_matrix[out_addr]);
            
            // Compare hardware output with expected values
            if (out_data === expected_matrix[out_addr]) begin
                correct_tests = correct_tests + 1;
                $display("       -->> Verdict : OK  ");
            end else begin
                 $display("       -->> Verdict : ** FAILED HW VALUE CHECK ! **");
            end
        end
    end

endmodule