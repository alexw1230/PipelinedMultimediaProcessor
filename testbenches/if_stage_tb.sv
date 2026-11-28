`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/24/2026 11:23:54 AM
// Design Name: 
// Module Name: if_stage_tb
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

module if_stage_tb import pipeline_consts_pkg::*;;

    // DUT signals
    logic clk;
    logic rst;
    logic [5:0] if_pc;
    logic [24:0] if_instr;
    logic done;

    if_stage dut (
        .clk(clk),
        .rst(rst),
        .if_pc(if_pc),
        .if_instr(if_instr),
        .done(done)
    );

    //counters
    int num_tests = 0;
    int num_errors = 0;

    //the four lines of if_test.mem, loaded into slots 0 to 3
    localparam logic [24:0] F0 = 25'b0_000_0000000000000011_00001;
    localparam logic [24:0] F1 = 25'b11_00000010_00010_00001_00110;
    localparam logic [24:0] F2 = 25'b11_00000000_00000_00000_00000;
    localparam logic [24:0] F3 = 25'b11_00000011_00000_00001_00011;

    //filler for slots 4 to 63, slot number at both ends, never a NOP
    function automatic logic [24:0] fill(input logic [5:0] k);
        return {1'b0, k, 12'hABC, k};
    endfunction

    //run some clock edges with rst held, then check the fetch outputs
    task automatic check(
        input string name,
        input logic r, // rst during those edges
        input int edges, // clock edges before the check
        input logic [5:0] exp_pc,
        input logic [24:0] exp_instr,
        input logic exp_done
    );
        logic ok;

        rst = r;
        repeat (edges) begin
            #5;
            clk = 1'b1;
            #5;
            clk = 1'b0;
        end
        #1;//outputs settle after the last edge

        num_tests++;

        //check if res is correct
        ok = (if_pc === exp_pc) &&
             (if_instr === exp_instr) &&
             (done === exp_done);

        if (ok) begin
            $display("PASS %-8s pc=%0d instr=%h done=%b", name, if_pc, if_instr, done);
        end else begin
            num_errors++;
            $display("FAIL %-8s after %0d edges with rst=%b", name, edges, r);
            $display("    got pc=%0d instr=%h done=%b", if_pc, if_instr, done);
            $display("    exp pc=%0d instr=%h done=%b", exp_pc, exp_instr, exp_done);

            // stop on the first failure so the waveform ends at the bad test
            $fatal(1, "Stopping: test '%s' failed (%0d of %0d run so far passed)",
                   name, num_tests - 1, num_tests);
        end
    endtask

    // Test cases
    initial begin
        clk = 1'b0;
        rst = 1'b0;
        //filler first, then the file overwrites slots 0 to 3, testbench only so a loop is fine here
        for (int k = 0; k < 64; k++) begin
            dut.u_buf.mem[k] = fill(k[5:0]);
        end
        $readmemb("if_test.mem", dut.u_buf.mem);
        #1;

        //RESET

        // a) edge: one edge of reset gives pc 0, done 0 and slot 0 from the file
        // if this gets the filler instead of F0, if_test.mem was not found
        check("RST 1", 1'b1, 1, 6'd0, F0, 1'b0);

        //FETCH

        // a) normal: reset released, one edge later slot 1 is fetched
        check("SLOT 1", 1'b0, 1, 6'd1, F1, 1'b0);

        // b) normal: two more edges, slot 3 is the last line of if_test.mem
        check("SLOT 3", 1'b0, 2, 6'd3, F3, 1'b0);

        // c) normal: the middle of the buffer, pc is still counting one per edge
        check("SLOT 32", 1'b0, 29, 6'd32, fill(6'd32), 1'b0);

        // d) edge: slot 63 is fetched like any other, done is still 0
        check("SLOT 63", 1'b0, 31, 6'd63, fill(6'd63), 1'b0);

        //END OF BUFFER

        // a) edge: done sets one edge after slot 63, pc holds and fetch gives NOP
        check("DONE 1", 1'b0, 1, 6'd63, NOP_INSTR, 1'b1);

        // b) edge: five edges later it still holds, the pc never wraps back to 0
        check("DONE 2", 1'b0, 5, 6'd63, NOP_INSTR, 1'b1);

        //RESET AFTER DONE

        // a) edge: reset clears done and the pc
        check("RST 2", 1'b1, 1, 6'd0, F0, 1'b0);

        // b) edge: fetch restarts from slot 1
        check("RST 3", 1'b0, 1, 6'd1, F1, 1'b0);

        // Summary (only reached if every test passed)
        $display("------------------------------------------------");
        $display("%0d tests, %0d errors -> %s", num_tests, num_errors,
                 (num_errors == 0) ? "ALL PASSED" : "FAILURES");
        $display("------------------------------------------------");
        $finish;
    end

endmodule