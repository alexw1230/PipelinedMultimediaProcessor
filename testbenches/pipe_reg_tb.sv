`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/24/2026 11:31:28 AM
// Design Name: 
// Module Name: pipe_reg_tb
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

module pipe_reg_tb import pipeline_consts_pkg::*;;

    // DUT signals
    logic clk;
    logic rst;
    logic [24:0] if_instr, id_instr, ex_instr, wb_instr;
    logic [5:0] if_pc, id_pc, ex_pc, wb_pc;
    logic [127:0] id_rs1_data, id_rs2_data, id_rs3_data;
    logic [4:0] id_rs1_addr, id_rs2_addr, id_rs3_addr;
    logic id_uses_rs1, id_uses_rs2, id_uses_rs3;
    logic [127:0] ex_rs1_data, ex_rs2_data, ex_rs3_data;
    logic [4:0] ex_rs1_addr, ex_rs2_addr, ex_rs3_addr;
    logic ex_uses_rs1, ex_uses_rs2, ex_uses_rs3;
    logic [127:0] ex_result, wb_result;
    logic ex_write_en, wb_write_en;
    logic [4:0] ex_dest_reg, wb_dest_reg;

    //the three registers chained like in mm_unit, instr and pc go IF -> ID -> EX -> WB
    if_id_reg u_if_id (
        .clk(clk),
        .rst(rst),
        .if_instr(if_instr),
        .if_pc(if_pc),
        .id_instr(id_instr),
        .id_pc(id_pc)
    );

    id_ex_reg u_id_ex (
        .clk(clk),
        .rst(rst),
        .id_instr(id_instr),
        .id_pc(id_pc),
        .id_rs1_data(id_rs1_data),
        .id_rs2_data(id_rs2_data),
        .id_rs3_data(id_rs3_data),
        .id_rs1_addr(id_rs1_addr),
        .id_rs2_addr(id_rs2_addr),
        .id_rs3_addr(id_rs3_addr),
        .id_uses_rs1(id_uses_rs1),
        .id_uses_rs2(id_uses_rs2),
        .id_uses_rs3(id_uses_rs3),
        .ex_instr(ex_instr),
        .ex_pc(ex_pc),
        .ex_rs1_data(ex_rs1_data),
        .ex_rs2_data(ex_rs2_data),
        .ex_rs3_data(ex_rs3_data),
        .ex_rs1_addr(ex_rs1_addr),
        .ex_rs2_addr(ex_rs2_addr),
        .ex_rs3_addr(ex_rs3_addr),
        .ex_uses_rs1(ex_uses_rs1),
        .ex_uses_rs2(ex_uses_rs2),
        .ex_uses_rs3(ex_uses_rs3)
    );

    ex_wb_reg u_ex_wb (
        .clk(clk),
        .rst(rst),
        .ex_instr(ex_instr),
        .ex_pc(ex_pc),
        .ex_result(ex_result),
        .ex_write_en(ex_write_en),
        .ex_dest_reg(ex_dest_reg),
        .wb_instr(wb_instr),
        .wb_pc(wb_pc),
        .wb_result(wb_result),
        .wb_write_en(wb_write_en),
        .wb_dest_reg(wb_dest_reg)
    );

    //counters
    int num_tests = 0;
    int num_errors = 0;

    //instructions and pcs, B is A inverted
    localparam logic [24:0] IA = 25'b0_101_0101010101010101_01010;
    localparam logic [24:0] IB = ~IA;
    localparam logic [24:0] IC = 25'h0123456;
    localparam logic [5:0] PA = 6'd21;
    localparam logic [5:0] PB = 6'd42;
    localparam logic [5:0] PC = 6'd7;

    //ID/EX fields {rs1_data, rs2_data, rs3_data, rs1_addr, rs2_addr, rs3_addr, uses_rs1, uses_rs2, uses_rs3}
    //set B is set A with every bit flipped, so each bit is seen at 0 and 1
    localparam logic [401:0] EX_A = {128'h1111_1111_1111_1111_1111_1111_1111_1111,
        128'h2222_2222_2222_2222_2222_2222_2222_2222, 128'h3333_3333_3333_3333_3333_3333_3333_3333,
        5'd9, 5'd18, 5'd27, 3'b101};
    localparam logic [401:0] EX_B = ~EX_A;
    //EX/WB fields {result, write_en, dest_reg}
    localparam logic [133:0] WB_A = {128'hAAAA_AAAA_AAAA_AAAA_AAAA_AAAA_AAAA_AAAA, 1'b1, 5'd21};
    localparam logic [133:0] WB_B = ~WB_A;

    //apply inputs, one clock edge, then check every register output
    task automatic check(
        input string name,
        input logic r, // rst
        input logic [24:0] instr, // if_instr
        input logic [5:0] pc, // if_pc
        input logic [401:0] ex_in, // ID/EX fields in
        input logic [133:0] wb_in, // EX/WB fields in
        input logic [24:0] exp_id_instr,
        input logic [24:0] exp_ex_instr,
        input logic [24:0] exp_wb_instr,
        input logic [5:0] exp_id_pc,
        input logic [5:0] exp_ex_pc,
        input logic [5:0] exp_wb_pc,
        input logic [401:0] exp_ex, // ID/EX fields out
        input logic [133:0] exp_wb // EX/WB fields out
    );
        logic ok;

        rst = r;
        if_instr = instr;
        if_pc = pc;
        {id_rs1_data, id_rs2_data, id_rs3_data, id_rs1_addr, id_rs2_addr, id_rs3_addr,
            id_uses_rs1, id_uses_rs2, id_uses_rs3} = ex_in;
        {ex_result, ex_write_en, ex_dest_reg} = wb_in;
        #5;
        clk = 1'b1;
        #5;
        clk = 1'b0;
        #1;//outputs settle after the edge

        num_tests++;

        //check if res is correct
        ok = (id_instr === exp_id_instr) &&
             (ex_instr === exp_ex_instr) &&
             (wb_instr === exp_wb_instr) &&
             (id_pc === exp_id_pc) &&
             (ex_pc === exp_ex_pc) &&
             (wb_pc === exp_wb_pc) &&
             ({ex_rs1_data, ex_rs2_data, ex_rs3_data, ex_rs1_addr, ex_rs2_addr, ex_rs3_addr,
                 ex_uses_rs1, ex_uses_rs2, ex_uses_rs3} === exp_ex) &&
             ({wb_result, wb_write_en, wb_dest_reg} === exp_wb);

        if (ok) begin
            $display("PASS %-8s id=%h ex=%h wb=%h", name, id_instr, ex_instr, wb_instr);
        end else begin
            num_errors++;
            $display("FAIL %-8s rst=%b", name, r);
            $display("    got instr %h %h %h pc %0d %0d %0d", id_instr, ex_instr, wb_instr, id_pc, ex_pc, wb_pc);
            $display("    exp instr %h %h %h pc %0d %0d %0d", exp_id_instr, exp_ex_instr, exp_wb_instr,
                     exp_id_pc, exp_ex_pc, exp_wb_pc);
            $display("    got ID/EX fields %h", {ex_rs1_data, ex_rs2_data, ex_rs3_data, ex_rs1_addr,
                     ex_rs2_addr, ex_rs3_addr, ex_uses_rs1, ex_uses_rs2, ex_uses_rs3});
            $display("    exp ID/EX fields %h", exp_ex);
            $display("    got EX/WB fields %h", {wb_result, wb_write_en, wb_dest_reg});
            $display("    exp EX/WB fields %h", exp_wb);

            // stop on the first failure so the waveform ends at the bad test
            $fatal(1, "Stopping: test '%s' failed (%0d of %0d run so far passed)",
                   name, num_tests - 1, num_tests);
        end
    endtask

    // Test cases
    initial begin
        clk = 1'b0;
        rst = 1'b0;
        if_instr = '0;
        if_pc = '0;
        #1;

        //RESET

        // a) edge: reset with nonzero inputs gives NOP and zeros in all three registers
        check("RST 1", 1'b1, IC, PC, EX_A, WB_A,
            NOP_INSTR, NOP_INSTR, NOP_INSTR, 6'd0, 6'd0, 6'd0, '0, '0);

        //CAPTURE

        // a) normal: set A is captured, instr A enters ID
        check("CAP 1", 1'b0, IA, PA, EX_A, WB_A,
            IA, NOP_INSTR, NOP_INSTR, PA, 6'd0, 6'd0, EX_A, WB_A);

        // b) normal: set B flips every bit, instr A moves on to EX
        check("CAP 2", 1'b0, IB, PB, EX_B, WB_B,
            IB, IA, NOP_INSTR, PB, PA, 6'd0, EX_B, WB_B);

        // c) edge: instr A reaches WB three edges after it left IF, exactly one stage per edge
        check("CAP 3", 1'b0, IC, PC, EX_A, WB_A,
            IC, IB, IA, PC, PB, PA, EX_A, WB_A);

        //RESET MID RUN

        // a) edge: reset clears all three at the next edge
        check("RST 2", 1'b1, IA, PA, EX_B, WB_B,
            NOP_INSTR, NOP_INSTR, NOP_INSTR, 6'd0, 6'd0, 6'd0, '0, '0);

        // Summary (only reached if every test passed)
        $display("------------------------------------------------");
        $display("%0d tests, %0d errors -> %s", num_tests, num_errors,
                 (num_errors == 0) ? "ALL PASSED" : "FAILURES");
        $display("------------------------------------------------");
        $finish;
    end

endmodule