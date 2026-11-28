`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/24/2026 11:34:49 AM
// Design Name: 
// Module Name: ex_stage
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

//stage 3: forwarding muxes in front of the ALU
module ex_stage(
    input logic [24:0] ex_instr,
    input logic [127:0] ex_rs1_data, ex_rs2_data, ex_rs3_data,
    input logic fwd_rs1, fwd_rs2, fwd_rs3,
    input logic [127:0] wb_result,
    output logic [127:0] ex_result,
    output logic ex_write_en,
    output logic [4:0] ex_dest_reg
);
    logic [127:0] ex_alu_rs1, ex_alu_rs2, ex_alu_rs3;
    logic alu_write_en;

    assign ex_alu_rs1 = fwd_rs1 ? wb_result : ex_rs1_data;
    assign ex_alu_rs2 = fwd_rs2 ? wb_result : ex_rs2_data;
    assign ex_alu_rs3 = fwd_rs3 ? wb_result : ex_rs3_data;

    alu u_alu(.instruction(ex_instr), .rs1(ex_alu_rs1), .rs2(ex_alu_rs2), .rs3(ex_alu_rs3),
        .rd(ex_result), .write_en(alu_write_en), .dest_reg(ex_dest_reg));

    //r0 is hardwired to 0, so a write to it is dropped
    assign ex_write_en = alu_write_en && (ex_dest_reg != 5'd0);
endmodule