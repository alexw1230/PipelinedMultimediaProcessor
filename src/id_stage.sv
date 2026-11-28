`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/24/2026 11:13:53 AM
// Design Name: 
// Module Name: id_stage
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

//stage 2: decode the source registers and read them from the register file
module id_stage(
    input logic clk, rst,
    input logic [24:0] id_instr,
    input logic wb_wr_en,
    input logic [4:0] wb_wr_addr,
    input logic [127:0] wb_wr_data,
    output logic [4:0] id_rs1_addr, id_rs2_addr, id_rs3_addr,
    output logic id_uses_rs1, id_uses_rs2, id_uses_rs3,
    output logic [127:0] id_rs1_data, id_rs2_data, id_rs3_data,
    output logic id_rs1_byp, id_rs2_byp, id_rs3_byp
);
    logic is_li, is_r4, is_r3;
    logic [3:0] r3_op;
    logic rf_rs1_byp, rf_rs2_byp, rf_rs3_byp;

    //0x is LI, 10 is R4, 11 is R3, only bits 18:15 pick the R3 op
    assign is_li = ~id_instr[24];
    assign is_r4 = (id_instr[24:23] == 2'b10);
    assign is_r3 = (id_instr[24:23] == 2'b11);
    assign r3_op = id_instr[18:15];

    //LI reads its own rd through rs1, rs2 and rs3 are the raw fields
    assign id_rs1_addr = is_li ? id_instr[4:0] : id_instr[9:5];
    assign id_rs2_addr = id_instr[14:10];
    assign id_rs3_addr = id_instr[19:15];

    //everything but NOP reads rs1
    assign id_uses_rs1 = ~(is_r3 && (r3_op == 4'b0000));
    //only R4 reads rs3
    assign id_uses_rs3 = is_r4;

    //rs2 is read by every R4 op and the two-source R3 ops
    always_comb begin
        id_uses_rs2 = 1'b0;
        if (is_r4) begin
            id_uses_rs2 = 1'b1;
        end else if (is_r3) begin
            case (r3_op)
                4'b0000: id_uses_rs2 = 1'b0; // NOP
                4'b0001: id_uses_rs2 = 1'b1; // ABSDB
                4'b0010: id_uses_rs2 = 1'b1; // AU
                4'b0011: id_uses_rs2 = 1'b0; // CNT1W
                4'b0100: id_uses_rs2 = 1'b1; // AHS
                4'b0101: id_uses_rs2 = 1'b1; // AND
                4'b0110: id_uses_rs2 = 1'b0; // BCW
                4'b0111: id_uses_rs2 = 1'b1; // MAXWS
                4'b1000: id_uses_rs2 = 1'b1; // MINWS
                4'b1001: id_uses_rs2 = 1'b1; // MLHU
                4'b1010: id_uses_rs2 = 1'b0; // MLHCU, rs2 field is a constant
                4'b1011: id_uses_rs2 = 1'b1; // OR
                4'b1100: id_uses_rs2 = 1'b0; // CNTLZ
                4'b1101: id_uses_rs2 = 1'b1; // ROTW
                4'b1110: id_uses_rs2 = 1'b1; // SFWU
                4'b1111: id_uses_rs2 = 1'b1; // SFHS
            endcase
        end
    end

    reg_file u_rf(.clk(clk), .rst(rst),
        .rs1_addr(id_rs1_addr), .rs2_addr(id_rs2_addr), .rs3_addr(id_rs3_addr),
        .wr_en(wb_wr_en), .wr_addr(wb_wr_addr), .wr_data(wb_wr_data),
        .rs1_data(id_rs1_data), .rs2_data(id_rs2_data), .rs3_data(id_rs3_data),
        .rs1_byp(rf_rs1_byp), .rs2_byp(rf_rs2_byp), .rs3_byp(rf_rs3_byp));

    //a bypass only counts on a source the instruction really reads
    assign id_rs1_byp = rf_rs1_byp && id_uses_rs1;
    assign id_rs2_byp = rf_rs2_byp && id_uses_rs2;
    assign id_rs3_byp = rf_rs3_byp && id_uses_rs3;
endmodule