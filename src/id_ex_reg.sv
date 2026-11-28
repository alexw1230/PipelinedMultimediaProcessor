`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/24/2026 11:29:41 AM
// Design Name: 
// Module Name: id_ex_reg
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

//ID/EX pipeline register
module id_ex_reg import pipeline_consts_pkg::*;(
    input logic clk, rst,
    input logic [24:0] id_instr,
    input logic [5:0] id_pc,
    input logic [127:0] id_rs1_data, id_rs2_data, id_rs3_data,
    input logic [4:0] id_rs1_addr, id_rs2_addr, id_rs3_addr,
    input logic id_uses_rs1, id_uses_rs2, id_uses_rs3,
    output logic [24:0] ex_instr,
    output logic [5:0] ex_pc,
    output logic [127:0] ex_rs1_data, ex_rs2_data, ex_rs3_data,
    output logic [4:0] ex_rs1_addr, ex_rs2_addr, ex_rs3_addr,
    output logic ex_uses_rs1, ex_uses_rs2, ex_uses_rs3
);
    always_ff @(posedge clk) begin
        if (rst) begin
            ex_instr <= NOP_INSTR;
            ex_pc <= 6'd0;
            ex_rs1_data <= '0;
            ex_rs2_data <= '0;
            ex_rs3_data <= '0;
            ex_rs1_addr <= 5'd0;
            ex_rs2_addr <= 5'd0;
            ex_rs3_addr <= 5'd0;
            ex_uses_rs1 <= 1'b0;
            ex_uses_rs2 <= 1'b0;
            ex_uses_rs3 <= 1'b0;
        end else begin
            ex_instr <= id_instr;
            ex_pc <= id_pc;
            ex_rs1_data <= id_rs1_data;
            ex_rs2_data <= id_rs2_data;
            ex_rs3_data <= id_rs3_data;
            ex_rs1_addr <= id_rs1_addr;
            ex_rs2_addr <= id_rs2_addr;
            ex_rs3_addr <= id_rs3_addr;
            ex_uses_rs1 <= id_uses_rs1;
            ex_uses_rs2 <= id_uses_rs2;
            ex_uses_rs3 <= id_uses_rs3;
        end
    end
endmodule