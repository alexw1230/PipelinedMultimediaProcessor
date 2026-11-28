`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/24/2026 11:30:28 AM
// Design Name: 
// Module Name: ex_wb_reg
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

//EX/WB pipeline register
module ex_wb_reg import pipeline_consts_pkg::*;(
    input logic clk, rst,
    input logic [24:0] ex_instr,
    input logic [5:0] ex_pc,
    input logic [127:0] ex_result,
    input logic ex_write_en,
    input logic [4:0] ex_dest_reg,
    output logic [24:0] wb_instr,
    output logic [5:0] wb_pc,
    output logic [127:0] wb_result,
    output logic wb_write_en,
    output logic [4:0] wb_dest_reg
);
    always_ff @(posedge clk) begin
        if (rst) begin
            wb_instr <= NOP_INSTR;
            wb_pc <= 6'd0;
            wb_result <= '0;
            wb_write_en <= 1'b0;
            wb_dest_reg <= 5'd0;
        end else begin
            wb_instr <= ex_instr;
            wb_pc <= ex_pc;
            wb_result <= ex_result;
            wb_write_en <= ex_write_en;
            wb_dest_reg <= ex_dest_reg;
        end
    end
endmodule