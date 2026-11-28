`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/24/2026 11:43:18 AM
// Design Name: 
// Module Name: mm_unit
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

//top level of the 4-stage pipelined multimedia unit
//IF -> IF/ID -> ID -> ID/EX -> EX -> EX/WB -> WB
//instances and wires only
module mm_unit(
    input logic clk, rst,
    output logic done
);
    //IF
    logic [5:0] if_pc;
    logic [24:0] if_instr;

    //ID
    logic [24:0] id_instr;
    logic [5:0] id_pc;
    logic [4:0] id_rs1_addr, id_rs2_addr, id_rs3_addr;
    logic id_uses_rs1, id_uses_rs2, id_uses_rs3;
    logic [127:0] id_rs1_data, id_rs2_data, id_rs3_data;
    logic id_rs1_byp, id_rs2_byp, id_rs3_byp;

    //EX
    logic [24:0] ex_instr;
    logic [5:0] ex_pc;
    logic [127:0] ex_rs1_data, ex_rs2_data, ex_rs3_data;
    logic [4:0] ex_rs1_addr, ex_rs2_addr, ex_rs3_addr;
    logic ex_uses_rs1, ex_uses_rs2, ex_uses_rs3;
    logic fwd_rs1, fwd_rs2, fwd_rs3;
    logic [127:0] ex_result;
    logic ex_write_en;
    logic [4:0] ex_dest_reg;

    //WB
    logic [24:0] wb_instr;
    logic [5:0] wb_pc;
    logic [127:0] wb_result;
    logic wb_write_en;
    logic [4:0] wb_dest_reg;
    logic wb_wr_en;
    logic [4:0] wb_wr_addr;
    logic [127:0] wb_wr_data;

    //stage 1
    if_stage u_if (
        .clk(clk), .rst(rst),
        .if_pc(if_pc), .if_instr(if_instr), .done(done)
    );

    if_id_reg u_if_id (
        .clk(clk), .rst(rst),
        .if_instr(if_instr), .if_pc(if_pc),
        .id_instr(id_instr), .id_pc(id_pc)
    );

    //stage 2, written by WB through the wb_wr port
    id_stage u_id (
        .clk(clk), .rst(rst),
        .id_instr(id_instr),
        .wb_wr_en(wb_wr_en), .wb_wr_addr(wb_wr_addr), .wb_wr_data(wb_wr_data),
        .id_rs1_addr(id_rs1_addr), .id_rs2_addr(id_rs2_addr), .id_rs3_addr(id_rs3_addr),
        .id_uses_rs1(id_uses_rs1), .id_uses_rs2(id_uses_rs2), .id_uses_rs3(id_uses_rs3),
        .id_rs1_data(id_rs1_data), .id_rs2_data(id_rs2_data), .id_rs3_data(id_rs3_data),
        .id_rs1_byp(id_rs1_byp), .id_rs2_byp(id_rs2_byp), .id_rs3_byp(id_rs3_byp)
    );

    id_ex_reg u_id_ex (
        .clk(clk), .rst(rst),
        .id_instr(id_instr), .id_pc(id_pc),
        .id_rs1_data(id_rs1_data), .id_rs2_data(id_rs2_data), .id_rs3_data(id_rs3_data),
        .id_rs1_addr(id_rs1_addr), .id_rs2_addr(id_rs2_addr), .id_rs3_addr(id_rs3_addr),
        .id_uses_rs1(id_uses_rs1), .id_uses_rs2(id_uses_rs2), .id_uses_rs3(id_uses_rs3),
        .ex_instr(ex_instr), .ex_pc(ex_pc),
        .ex_rs1_data(ex_rs1_data), .ex_rs2_data(ex_rs2_data), .ex_rs3_data(ex_rs3_data),
        .ex_rs1_addr(ex_rs1_addr), .ex_rs2_addr(ex_rs2_addr), .ex_rs3_addr(ex_rs3_addr),
        .ex_uses_rs1(ex_uses_rs1), .ex_uses_rs2(ex_uses_rs2), .ex_uses_rs3(ex_uses_rs3)
    );

    //forwarding from EX/WB into EX
    fwd_unit u_fwd (
        .wb_write_en(wb_write_en), .wb_dest_reg(wb_dest_reg),
        .ex_rs1_addr(ex_rs1_addr), .ex_rs2_addr(ex_rs2_addr), .ex_rs3_addr(ex_rs3_addr),
        .ex_uses_rs1(ex_uses_rs1), .ex_uses_rs2(ex_uses_rs2), .ex_uses_rs3(ex_uses_rs3),
        .fwd_rs1(fwd_rs1), .fwd_rs2(fwd_rs2), .fwd_rs3(fwd_rs3)
    );

    //stage 3
    ex_stage u_ex (
        .ex_instr(ex_instr),
        .ex_rs1_data(ex_rs1_data), .ex_rs2_data(ex_rs2_data), .ex_rs3_data(ex_rs3_data),
        .fwd_rs1(fwd_rs1), .fwd_rs2(fwd_rs2), .fwd_rs3(fwd_rs3),
        .wb_result(wb_result),
        .ex_result(ex_result), .ex_write_en(ex_write_en), .ex_dest_reg(ex_dest_reg)
    );

    ex_wb_reg u_ex_wb (
        .clk(clk), .rst(rst),
        .ex_instr(ex_instr), .ex_pc(ex_pc),
        .ex_result(ex_result), .ex_write_en(ex_write_en), .ex_dest_reg(ex_dest_reg),
        .wb_instr(wb_instr), .wb_pc(wb_pc),
        .wb_result(wb_result), .wb_write_en(wb_write_en), .wb_dest_reg(wb_dest_reg)
    );

    //stage 4
    wb_stage u_wb (
        .wb_result(wb_result), .wb_write_en(wb_write_en), .wb_dest_reg(wb_dest_reg),
        .wb_wr_en(wb_wr_en), .wb_wr_addr(wb_wr_addr), .wb_wr_data(wb_wr_data)
    );
endmodule