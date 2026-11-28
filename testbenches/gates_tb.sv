`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/16/2026 07:54:48 PM
// Design Name: 
// Module Name: gates_tb
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



module gates_tb;

    // Signals that connect to the design under test (DUT)
    logic a, b;
    logic y_and, y_or;

    int errors = 0;

    // Instantiate the design
    gates dut (
        .a     (a),
        .b     (b),
        .y_and (y_and),
        .y_or  (y_or)
    );

    // Apply one input combination and check it against the expected outputs
    task automatic test(input logic a_in, b_in, exp_and, exp_or);
        a = a_in;
        b = b_in;
        #10;  // wait for the outputs to settle

        if (y_and !== exp_and || y_or !== exp_or) begin
            $error("FAIL: a=%b b=%b | y_and=%b (expected %b)  y_or=%b (expected %b)",
                   a, b, y_and, exp_and, y_or, exp_or);
            errors++;
        end else begin
            $display("PASS: a=%b b=%b | y_and=%b  y_or=%b", a, b, y_and, y_or);
        end
    endtask

    initial begin
        $display("---- Starting gates test ----");

        //    a  b  AND OR   <- full truth table, written out by hand
        test(0, 0,  0,  0);
        test(0, 1,  0,  1);
        test(1, 0,  0,  1);
        test(1, 1,  1,  1);

        if (errors == 0)
            $display("==== ALL TESTS PASSED ====");
        else
            $display("==== %0d TEST(S) FAILED ====", errors);

        $finish;
    end

endmodule
