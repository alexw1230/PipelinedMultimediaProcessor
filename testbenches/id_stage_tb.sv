`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/24/2026 11:16:29 AM
// Design Name: 
// Module Name: id_stage_tb
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

module id_stage_tb;

    // DUT signals
    logic clk;
    logic rst;
    logic [24:0] id_instr;
    logic wb_wr_en;
    logic [4:0] wb_wr_addr;
    logic [127:0] wb_wr_data;
    logic [4:0] id_rs1_addr, id_rs2_addr, id_rs3_addr;
    logic id_uses_rs1, id_uses_rs2, id_uses_rs3;
    logic [127:0] id_rs1_data, id_rs2_data, id_rs3_data;
    logic id_rs1_byp, id_rs2_byp, id_rs3_byp;

    id_stage dut (
        .clk(clk),
        .rst(rst),
        .id_instr(id_instr),
        .wb_wr_en(wb_wr_en),
        .wb_wr_addr(wb_wr_addr),
        .wb_wr_data(wb_wr_data),
        .id_rs1_addr(id_rs1_addr),
        .id_rs2_addr(id_rs2_addr),
        .id_rs3_addr(id_rs3_addr),
        .id_uses_rs1(id_uses_rs1),
        .id_uses_rs2(id_uses_rs2),
        .id_uses_rs3(id_uses_rs3),
        .id_rs1_data(id_rs1_data),
        .id_rs2_data(id_rs2_data),
        .id_rs3_data(id_rs3_data),
        .id_rs1_byp(id_rs1_byp),
        .id_rs2_byp(id_rs2_byp),
        .id_rs3_byp(id_rs3_byp)
    );

    //counters
    int num_tests = 0;
    int num_errors = 0;

    //bypass values, chosen so they cannot be mistaken for a preload value
    localparam logic [127:0] W1 = 128'hAAAA_AAAA_AAAA_AAAA_AAAA_AAAA_AAAA_AAAA;
    localparam logic [127:0] W2 = 128'h5555_5555_5555_5555_5555_5555_5555_5555;
    localparam logic [127:0] W3 = 128'h1234_5678_9ABC_DEF0_0FED_CBA9_8765_4321;
    localparam logic [127:0] JUNK = 128'hBAD7_BAD6_BAD5_BAD4_BAD3_BAD2_BAD1_BAD0;

    //preload value of register n, n in every byte
    function automatic logic [127:0] val(input logic [4:0] n);
        return {16{3'b000, n}};
    endfunction

    //what a read port should return: the write data on a bypass, else the preload ($0 is 0)
    function automatic logic [127:0] port_data(input logic [4:0] a);
        if (wb_wr_en && (wb_wr_addr == a)) begin
            return wb_wr_data;
        end
        if (a == 5'd0) begin
            return '0;
        end
        return val(a);
    endfunction

    //apply inputs and check outputs against known
    task automatic check(
        input string name,
        input logic [24:0] instr,
        input logic we, // wb_wr_en
        input logic [4:0] wa, // wb_wr_addr
        input logic [127:0] wd, // wb_wr_data
        input logic [4:0] exp_a1,
        input logic [4:0] exp_a2,
        input logic [4:0] exp_a3,
        input logic [2:0] exp_uses, // {rs1, rs2, rs3}
        input logic [2:0] exp_byp // {rs1, rs2, rs3}
    );
        logic [127:0] exp_d1, exp_d2, exp_d3;
        logic ok;

        id_instr = instr;
        wb_wr_en = we;
        wb_wr_addr = wa;
        wb_wr_data = wd;
        #10;//wait 10 between cases

        num_tests++;

        exp_d1 = port_data(exp_a1);
        exp_d2 = port_data(exp_a2);
        exp_d3 = port_data(exp_a3);

        //check if res is correct
        ok = (id_rs1_addr === exp_a1) &&
             (id_rs2_addr === exp_a2) &&
             (id_rs3_addr === exp_a3) &&
             ({id_uses_rs1, id_uses_rs2, id_uses_rs3} === exp_uses) &&
             (id_rs1_data === exp_d1) &&
             (id_rs2_data === exp_d2) &&
             (id_rs3_data === exp_d3) &&
             ({id_rs1_byp, id_rs2_byp, id_rs3_byp} === exp_byp);

        if (ok) begin
            $display("PASS %-8s src=r%0d r%0d r%0d uses=%b byp=%b", name, id_rs1_addr, id_rs2_addr, id_rs3_addr,
                     {id_uses_rs1, id_uses_rs2, id_uses_rs3}, {id_rs1_byp, id_rs2_byp, id_rs3_byp});
        end else begin
            num_errors++;
            $display("FAIL %-8s instr=%b", name, instr);
            $display("    wr_en=%b wr_addr=r%0d wr_data=%h", we, wa, wd);
            $display("    got src=r%0d r%0d r%0d uses=%b byp=%b", id_rs1_addr, id_rs2_addr, id_rs3_addr,
                     {id_uses_rs1, id_uses_rs2, id_uses_rs3}, {id_rs1_byp, id_rs2_byp, id_rs3_byp});
            $display("    exp src=r%0d r%0d r%0d uses=%b byp=%b", exp_a1, exp_a2, exp_a3, exp_uses, exp_byp);
            $display("    got data %h %h %h", id_rs1_data, id_rs2_data, id_rs3_data);
            $display("    exp data %h %h %h", exp_d1, exp_d2, exp_d3);

            // stop on the first failure so the waveform ends at the bad test
            $fatal(1, "Stopping: test '%s' failed (%0d of %0d run so far passed)",
                   name, num_tests - 1, num_tests);
        end
    endtask

    // Test cases
    initial begin
        clk = 1'b0;
        rst = 1'b1;
        id_instr = '0;
        wb_wr_en = 1'b0;
        wb_wr_addr = '0;
        wb_wr_data = '0;
        //one reset edge, then preload $1 to $31 through the write port
        //testbench only so a loop is fine here
        #5;
        clk = 1'b1;
        #5;
        clk = 1'b0;
        rst = 1'b0;
        for (int n = 1; n < 32; n++) begin
            wb_wr_en = 1'b1;
            wb_wr_addr = n[4:0];
            wb_wr_data = val(n[4:0]);
            #5;
            clk = 1'b1;
            #5;
            clk = 1'b0;
        end
        wb_wr_en = 1'b0;
        #1;

        //DECODE BY FORMAT

        // a) normal: LI $6, 3, 0x1234, rd goes on rs1, rs2 and rs3 are raw immediate bits
        check("FMT 1", {1'b0, 3'd3, 16'h1234, 5'd6}, 1'b0, 5'd0, '0,
            5'd6, 5'd17, 5'd4, 3'b100, 3'b000);

        // b) normal: R4 SLMSHS $20, $9, $14, $27 reads all three sources
        check("FMT 2", {2'b10, 3'b111, 5'd27, 5'd14, 5'd9, 5'd20}, 1'b0, 5'd0, '0,
            5'd9, 5'd14, 5'd27, 3'b111, 3'b000);

        // c) edge: LI $13, 7, 0xFFFF, idx 7 sets bit 23 and it is still an LI
        // rs1 must be rd 13, not the 31 in bits 9:5
        check("FMT 3", {1'b0, 3'd7, 16'hFFFF, 5'd13}, 1'b0, 5'd0, '0,
            5'd13, 5'd31, 5'd31, 3'b100, 3'b000);

        // d) edge: the all-zero instruction is LI $0, 0, 0, not a NOP, so it reads rs1
        check("FMT 4", {1'b0, 3'd0, 16'h0000, 5'd0}, 1'b0, 5'd0, '0,
            5'd0, 5'd0, 5'd0, 3'b100, 3'b000);

        // e) edge: AND $5, $6, $7 with opcode bits 22:19 set decodes like a clean AND
        // only bits 18:15 pick the op, the rs3 slot is {1, 0101} = 21
        check("FMT 5", {2'b11, 4'b1111, 4'b0101, 5'd7, 5'd6, 5'd5}, 1'b0, 5'd0, '0,
            5'd6, 5'd7, 5'd21, 3'b110, 3'b000);

        //R3 OPCODES

        //every opcode with rd $11, rs1 $9, rs2 $10, each row of the uses_rs2 case once
        //one-source ops keep a nonzero rs2 field so only the flag changes
        check("NOP", {2'b11, 4'b0000, 4'b0000, 5'd10, 5'd9, 5'd11}, 1'b0, 5'd0, '0,
            5'd9, 5'd10, 5'd0, 3'b000, 3'b000);
        check("ABSDB", {2'b11, 4'b0000, 4'b0001, 5'd10, 5'd9, 5'd11}, 1'b0, 5'd0, '0,
            5'd9, 5'd10, 5'd1, 3'b110, 3'b000);
        check("AU", {2'b11, 4'b0000, 4'b0010, 5'd10, 5'd9, 5'd11}, 1'b0, 5'd0, '0,
            5'd9, 5'd10, 5'd2, 3'b110, 3'b000);
        check("CNT1W", {2'b11, 4'b0000, 4'b0011, 5'd10, 5'd9, 5'd11}, 1'b0, 5'd0, '0,
            5'd9, 5'd10, 5'd3, 3'b100, 3'b000);
        check("AHS", {2'b11, 4'b0000, 4'b0100, 5'd10, 5'd9, 5'd11}, 1'b0, 5'd0, '0,
            5'd9, 5'd10, 5'd4, 3'b110, 3'b000);
        check("AND", {2'b11, 4'b0000, 4'b0101, 5'd10, 5'd9, 5'd11}, 1'b0, 5'd0, '0,
            5'd9, 5'd10, 5'd5, 3'b110, 3'b000);
        check("BCW", {2'b11, 4'b0000, 4'b0110, 5'd10, 5'd9, 5'd11}, 1'b0, 5'd0, '0,
            5'd9, 5'd10, 5'd6, 3'b100, 3'b000);
        check("MAXWS", {2'b11, 4'b0000, 4'b0111, 5'd10, 5'd9, 5'd11}, 1'b0, 5'd0, '0,
            5'd9, 5'd10, 5'd7, 3'b110, 3'b000);
        check("MINWS", {2'b11, 4'b0000, 4'b1000, 5'd10, 5'd9, 5'd11}, 1'b0, 5'd0, '0,
            5'd9, 5'd10, 5'd8, 3'b110, 3'b000);
        check("MLHU", {2'b11, 4'b0000, 4'b1001, 5'd10, 5'd9, 5'd11}, 1'b0, 5'd0, '0,
            5'd9, 5'd10, 5'd9, 3'b110, 3'b000);
        check("MLHCU", {2'b11, 4'b0000, 4'b1010, 5'd10, 5'd9, 5'd11}, 1'b0, 5'd0, '0,
            5'd9, 5'd10, 5'd10, 3'b100, 3'b000);
        check("OR", {2'b11, 4'b0000, 4'b1011, 5'd10, 5'd9, 5'd11}, 1'b0, 5'd0, '0,
            5'd9, 5'd10, 5'd11, 3'b110, 3'b000);
        check("CNTLZ", {2'b11, 4'b0000, 4'b1100, 5'd10, 5'd9, 5'd11}, 1'b0, 5'd0, '0,
            5'd9, 5'd10, 5'd12, 3'b100, 3'b000);
        check("ROTW", {2'b11, 4'b0000, 4'b1101, 5'd10, 5'd9, 5'd11}, 1'b0, 5'd0, '0,
            5'd9, 5'd10, 5'd13, 3'b110, 3'b000);
        check("SFWU", {2'b11, 4'b0000, 4'b1110, 5'd10, 5'd9, 5'd11}, 1'b0, 5'd0, '0,
            5'd9, 5'd10, 5'd14, 3'b110, 3'b000);
        check("SFHS", {2'b11, 4'b0000, 4'b1111, 5'd10, 5'd9, 5'd11}, 1'b0, 5'd0, '0,
            5'd9, 5'd10, 5'd15, 3'b110, 3'b000);

        //BYPASS FLAGS

        // a) normal: LI $13, 0, 1 while WB writes $13, LI gets the new old value
        check("BYP 1", {1'b0, 3'd0, 16'h0001, 5'd13}, 1'b1, 5'd13, W2,
            5'd13, 5'd0, 5'd0, 3'b100, 3'b100);

        // b) edge: AU $7, $2, $5 while WB writes $2, the unused rs3 slot (2) also matches
        // the rs3 flag stays 0 but its data is still bypassed, only the flag is gated
        check("BYP 2", {2'b11, 4'b0000, 4'b0010, 5'd5, 5'd2, 5'd7}, 1'b1, 5'd2, W1,
            5'd2, 5'd5, 5'd2, 3'b110, 3'b100);

        // c) edge: SIMALS $1, $20, $20, $20 while WB writes $20, all three ports hit
        check("BYP 3", {2'b10, 3'b000, 5'd20, 5'd20, 5'd20, 5'd1}, 1'b1, 5'd20, W3,
            5'd20, 5'd20, 5'd20, 3'b111, 3'b111);

        // d) edge: the same with wr_en 0, stored value and no flags
        check("BYP 4", {2'b10, 3'b000, 5'd20, 5'd20, 5'd20, 5'd1}, 1'b0, 5'd20, JUNK,
            5'd20, 5'd20, 5'd20, 3'b111, 3'b000);

        // Summary (only reached if every test passed)
        $display("------------------------------------------------");
        $display("%0d tests, %0d errors -> %s", num_tests, num_errors,
                 (num_errors == 0) ? "ALL PASSED" : "FAILURES");
        $display("------------------------------------------------");
        $finish;
    end

endmodule