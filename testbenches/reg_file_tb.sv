`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/24/2026 10:57:41 AM
// Design Name: 
// Module Name: reg_file_tb
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

module reg_file_tb;

    // DUT signals
    logic clk;
    logic rst;
    logic [4:0] rs1_addr, rs2_addr, rs3_addr;
    logic wr_en;
    logic [4:0] wr_addr;
    logic [127:0] wr_data;
    logic [127:0] rs1_data, rs2_data, rs3_data;
    logic rs1_byp, rs2_byp, rs3_byp;

    reg_file dut (
        .clk(clk),
        .rst(rst),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .rs3_addr(rs3_addr),
        .wr_en(wr_en),
        .wr_addr(wr_addr),
        .wr_data(wr_data),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .rs3_data(rs3_data),
        .rs1_byp(rs1_byp),
        .rs2_byp(rs2_byp),
        .rs3_byp(rs3_byp)
    );

    //counters
    int num_tests = 0;
    int num_errors = 0;

    //test values, each halfword is {reg number, lane}
    localparam logic [127:0] V1 = 128'h0107_0106_0105_0104_0103_0102_0101_0100;
    localparam logic [127:0] V5 = 128'h0507_0506_0505_0504_0503_0502_0501_0500;
    localparam logic [127:0] V30 = 128'h1E07_1E06_1E05_1E04_1E03_1E02_1E01_1E00;
    //second value for $1, and data that must never be written
    localparam logic [127:0] N1 = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
    localparam logic [127:0] JUNK = 128'hBAD7_BAD6_BAD5_BAD4_BAD3_BAD2_BAD1_BAD0;

    //one clock cycle per call: apply inputs, check the reads before the edge, then clock
    task automatic check(
        input string name,
        input logic r, // rst
        input logic we, // wr_en
        input logic [4:0] wa, // wr_addr
        input logic [127:0] wd, // wr_data
        input logic [4:0] a1, // rs1_addr
        input logic [4:0] a2, // rs2_addr
        input logic [4:0] a3, // rs3_addr
        input logic [127:0] exp1,
        input logic [127:0] exp2,
        input logic [127:0] exp3,
        input logic [2:0] exp_byp // {rs1, rs2, rs3}
    );
        logic ok;

        rst = r;
        wr_en = we;
        wr_addr = wa;
        wr_data = wd;
        rs1_addr = a1;
        rs2_addr = a2;
        rs3_addr = a3;
        #5;//reads settle before the edge

        num_tests++;

        //check if res is correct
        ok = (rs1_data === exp1) &&
             (rs2_data === exp2) &&
             (rs3_data === exp3) &&
             ({rs1_byp, rs2_byp, rs3_byp} === exp_byp);

        if (ok) begin
            $display("PASS %-8s r%0d r%0d r%0d byp=%b", name, a1, a2, a3, {rs1_byp, rs2_byp, rs3_byp});
        end else begin
            num_errors++;
            $display("FAIL %-8s read r%0d r%0d r%0d", name, a1, a2, a3);
            $display("    rst=%b wr_en=%b wr_addr=r%0d wr_data=%h", r, we, wa, wd);
            $display("    got %h %h %h byp=%b", rs1_data, rs2_data, rs3_data, {rs1_byp, rs2_byp, rs3_byp});
            $display("    exp %h %h %h byp=%b", exp1, exp2, exp3, exp_byp);

            // stop on the first failure so the waveform ends at the bad test
            $fatal(1, "Stopping: test '%s' failed (%0d of %0d run so far passed)",
                   name, num_tests - 1, num_tests);
        end

        //the clock edge, writes and reset land here
        clk = 1'b1;
        #5;
        clk = 1'b0;
    endtask

    // Test cases
    initial begin
        clk = 1'b0;
        rst = 1'b1;
        wr_en = 1'b0;
        wr_addr = '0;
        wr_data = '0;
        rs1_addr = '0;
        rs2_addr = '0;
        rs3_addr = '0;
        //one reset edge before the tests
        #5;
        clk = 1'b1;
        #5;
        clk = 1'b0;
        #1;

        //RESET

        // a) edge: the lowest, a middle and the highest register all read 0 after reset
        check("RST 1", 1'b0, 1'b0, 5'd0, '0, 5'd0, 5'd17, 5'd31,
            '0, '0, '0, 3'b000);

        //WRITE AND READ BACK

        // a) normal: write $1 while the ports read other registers, nothing bypasses
        check("RW 1", 1'b0, 1'b1, 5'd1, V1, 5'd2, 5'd3, 5'd4,
            '0, '0, '0, 3'b000);

        // b) normal: write $30, and the $1 written last cycle reads back on all three ports
        check("RW 2", 1'b0, 1'b1, 5'd30, V30, 5'd1, 5'd1, 5'd1,
            V1, V1, V1, 3'b000);

        // c) edge: $1 = 00001 and $30 = 11110 use every address bit both ways
        // a stuck or swapped address bit would land one on the other or on $31
        check("RW 3", 1'b0, 1'b0, 5'd0, '0, 5'd30, 5'd1, 5'd31,
            V30, V1, '0, 3'b000);

        //WRITE BYPASS

        // a) normal: write $5 while all three ports read $5, the new value comes out before the edge
        check("BYP 1", 1'b0, 1'b1, 5'd5, V5, 5'd5, 5'd5, 5'd5,
            V5, V5, V5, 3'b111);

        // b) edge: overwrite $1 while only port 3 reads it, ports 1 and 2 read stored values
        check("BYP 2", 1'b0, 1'b1, 5'd1, N1, 5'd30, 5'd5, 5'd1,
            V30, V5, N1, 3'b001);

        // c) edge: both bypassed writes also landed at the edge, $1 keeps the newest value
        check("BYP 3", 1'b0, 1'b0, 5'd0, '0, 5'd1, 5'd1, 5'd5,
            N1, N1, V5, 3'b000);

        //WRITE ENABLE OFF

        // a) edge: wr_en 0 with a matching address gives no bypass
        check("WE0 1", 1'b0, 1'b0, 5'd1, JUNK, 5'd1, 5'd1, 5'd1,
            N1, N1, N1, 3'b000);

        // b) edge: and nothing was written at the edge
        check("WE0 2", 1'b0, 1'b0, 5'd0, '0, 5'd1, 5'd1, 5'd1,
            N1, N1, N1, 3'b000);

        //SYNC RESET

        // a) edge: reset is synchronous, the values hold until the edge
        check("RST 2", 1'b1, 1'b0, 5'd0, '0, 5'd30, 5'd5, 5'd1,
            V30, V5, N1, 3'b000);

        // b) edge: after the edge every written register reads 0
        check("RST 3", 1'b0, 1'b0, 5'd0, '0, 5'd30, 5'd5, 5'd1,
            '0, '0, '0, 3'b000);

        // Summary (only reached if every test passed)
        $display("------------------------------------------------");
        $display("%0d tests, %0d errors -> %s", num_tests, num_errors,
                 (num_errors == 0) ? "ALL PASSED" : "FAILURES");
        $display("------------------------------------------------");
        $finish;
    end

endmodule