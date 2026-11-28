`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/24/2026 11:28:39 AM
// Design Name: 
// Module Name: if_id_reg
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

//IF/ID pipeline register
module if_id_reg import pipeline_consts_pkg::*;(
    input logic clk, rst,
    input logic [24:0] if_instr,
    input logic [5:0] if_pc,
    output logic [24:0] id_instr,
    output logic [5:0] id_pc
);
    always_ff @(posedge clk) begin
        if (rst) begin
            id_instr <= NOP_INSTR;
            id_pc <= 6'd0;
        end else begin
            id_instr <= if_instr;
            id_pc <= if_pc;
        end
    end
endmodule