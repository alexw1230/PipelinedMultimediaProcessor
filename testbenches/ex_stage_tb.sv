`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/24/2026 11:36:16 AM
// Design Name: 
// Module Name: ex_stage_tb
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

module ex_stage_tb;

    // DUT signals
    logic [24:0] ex_instr;
    logic [127:0] ex_rs1_data, ex_rs2_data, ex_rs3_data;
    logic fwd_rs1, fwd_rs2, fwd_rs3;
    logic [127:0] wb_result;
    logic [127:0] ex_result;
    logic ex_write_en;
    logic [4:0] ex_dest_reg;

    ex_stage dut (
        .ex_instr(ex_instr),
        .ex_rs1_data(ex_rs1_data),
        .ex_rs2_data(ex_rs2_data),
        .ex_rs3_data(ex_rs3_data),
        .fwd_rs1(fwd_rs1),
        .fwd_rs2(fwd_rs2),
        .fwd_rs3(fwd_rs3),
        .wb_result(wb_result),
        .ex_result(ex_result),
        .ex_write_en(ex_write_en),
        .ex_dest_reg(ex_dest_reg)
    );

    //counters
    int num_tests = 0;
    int num_errors = 0;

    //ID/EX values and the WB result, the same in every word
    localparam logic [127:0] D1 = {4{32'd10}};
    localparam logic [127:0] D2 = {4{32'd2}};
    localparam logic [127:0] D3 = {4{32'd3}};
    localparam logic [127:0] W = {4{32'd5}};

    //apply inputs and check outputs against known
    task automatic check(
        input string name,
        input logic [24:0] instr,
        input logic [2:0] fwd, // {rs1, rs2, rs3}
        input logic [127:0] exp_in1, // ALU rs1 after the mux
        input logic [127:0] exp_in2, // ALU rs2 after the mux
        input logic [127:0] exp_in3, // ALU rs3 after the mux
        input logic [127:0] exp_res,
        input logic exp_we,
        input logic [4:0] exp_dest
    );
        logic ok;

        ex_instr = instr;
        {fwd_rs1, fwd_rs2, fwd_rs3} = fwd;
        #10;//wait 10 between cases

        num_tests++;

        //check if res is correct
        ok = (dut.ex_alu_rs1 === exp_in1) &&
             (dut.ex_alu_rs2 === exp_in2) &&
             (dut.ex_alu_rs3 === exp_in3) &&
             (ex_result === exp_res) &&
             (ex_write_en === exp_we) &&
             (ex_dest_reg === exp_dest);

        if (ok) begin
            $display("PASS %-8s result=%h we=%b dest=r%0d", name, ex_result, ex_write_en, ex_dest_reg);
        end else begin
            num_errors++;
            $display("FAIL %-8s instr=%h fwd=%b", name, instr, fwd);
            $display("    got in %h %h %h", dut.ex_alu_rs1, dut.ex_alu_rs2, dut.ex_alu_rs3);
            $display("    exp in %h %h %h", exp_in1, exp_in2, exp_in3);
            $display("    got result=%h we=%b dest=r%0d", ex_result, ex_write_en, ex_dest_reg);
            $display("    exp result=%h we=%b dest=r%0d", exp_res, exp_we, exp_dest);

            // stop on the first failure so the waveform ends at the bad test
            $fatal(1, "Stopping: test '%s' failed (%0d of %0d run so far passed)",
                   name, num_tests - 1, num_tests);
        end
    endtask

    // Test cases
    initial begin
        ex_instr = '0;
        ex_rs1_data = D1;
        ex_rs2_data = D2;
        ex_rs3_data = D3;
        wb_result = W;
        {fwd_rs1, fwd_rs2, fwd_rs3} = '0;
        #1;

        //FORWARDING MUXES

        //SIMALS $4, $1, $2, $3, each word is rs1 + rs3.lo * rs2.lo
        //ID/EX gives 10, 2, 3 and WB gives 5, so every select pattern has its own sum

        // a) normal: no forwarding, 10 + 3*2 = 16
        check("FWD 1", {2'b10, 3'b000, 5'd3, 5'd2, 5'd1, 5'd4}, 3'b000,
            D1, D2, D3, {4{32'h10}}, 1'b1, 5'd4);

        // b) normal: rs1 forwarded, 5 + 3*2 = 11
        check("FWD 2", {2'b10, 3'b000, 5'd3, 5'd2, 5'd1, 5'd4}, 3'b100,
            W, D2, D3, {4{32'h0B}}, 1'b1, 5'd4);

        // c) edge: rs2 forwarded alone, 10 + 3*5 = 25, a select wired to the wrong mux shows here
        check("FWD 3", {2'b10, 3'b000, 5'd3, 5'd2, 5'd1, 5'd4}, 3'b010,
            D1, W, D3, {4{32'h19}}, 1'b1, 5'd4);

        // d) edge: rs3 forwarded alone, 10 + 5*2 = 20
        check("FWD 4", {2'b10, 3'b000, 5'd3, 5'd2, 5'd1, 5'd4}, 3'b001,
            D1, D2, W, {4{32'h14}}, 1'b1, 5'd4);

        // e) edge: all three forwarded, 5 + 5*5 = 30
        check("FWD 5", {2'b10, 3'b000, 5'd3, 5'd2, 5'd1, 5'd4}, 3'b111,
            W, W, W, {4{32'h1E}}, 1'b1, 5'd4);

        //R0 HARDWIRED

        // a) normal: AU $16, $1, $2 writes, 10 + 2 = 12
        // dest 16 = 10000, so a check on only the low dest bits would wrongly block it
        check("R0 1", {2'b11, 4'b0000, 4'b0010, 5'd2, 5'd1, 5'd16}, 3'b000,
            D1, D2, D3, {4{32'h0C}}, 1'b1, 5'd16);

        // b) edge: AU $0, $1, $2 still computes 12 but must not write
        check("R0 2", {2'b11, 4'b0000, 4'b0010, 5'd2, 5'd1, 5'd0}, 3'b000,
            D1, D2, D3, {4{32'h0C}}, 1'b0, 5'd0);

        // c) edge: NOP with rd field 5, the ALU write_en 0 must pass through even with a nonzero dest
        check("R0 3", {2'b11, 4'b0000, 4'b0000, 5'd0, 5'd0, 5'd5}, 3'b000,
            D1, D2, D3, '0, 1'b0, 5'd5);

        // Summary (only reached if every test passed)
        $display("------------------------------------------------");
        $display("%0d tests, %0d errors -> %s", num_tests, num_errors,
                 (num_errors == 0) ? "ALL PASSED" : "FAILURES");
        $display("------------------------------------------------");
        $finish;
    end

endmodule