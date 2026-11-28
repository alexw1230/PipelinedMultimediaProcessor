`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/24/2026 11:20:09 AM
// Design Name: 
// Module Name: if_stage
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

//stage 1: fetch at pc, then pc + 1
//after slot 63 is fetched done sets, pc holds at 63 and fetch gives NOP
module if_stage import pipeline_consts_pkg::*;(
    input logic clk, rst,
    output logic [5:0] if_pc,
    output logic [24:0] if_instr,
    output logic done
);
    logic [24:0] buf_instr;

    instr_buffer u_buf(.addr(if_pc), .instr(buf_instr));

    always_ff @(posedge clk) begin
        if (rst) begin
            if_pc <= 6'd0;
            done <= 1'b0;
        end else if (if_pc == 6'd63) begin
            done <= 1'b1;
        end else begin
            if_pc <= if_pc + 6'd1;
        end
    end

    assign if_instr = done ? NOP_INSTR : buf_instr;
endmodule