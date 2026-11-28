`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/24/2026 10:59:32 AM
// Design Name: 
// Module Name: fwd_unit
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

//forward the EX/WB result when WB writes a register that EX really reads
module fwd_unit(
    input logic wb_write_en,
    input logic [4:0] wb_dest_reg,
    input logic [4:0] ex_rs1_addr, ex_rs2_addr, ex_rs3_addr,
    input logic ex_uses_rs1, ex_uses_rs2, ex_uses_rs3,
    output logic fwd_rs1, fwd_rs2, fwd_rs3
);
    assign fwd_rs1 = wb_write_en && ex_uses_rs1 && (wb_dest_reg == ex_rs1_addr);
    assign fwd_rs2 = wb_write_en && ex_uses_rs2 && (wb_dest_reg == ex_rs2_addr);
    assign fwd_rs3 = wb_write_en && ex_uses_rs3 && (wb_dest_reg == ex_rs3_addr);
endmodule