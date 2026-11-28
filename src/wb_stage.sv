`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/24/2026 11:37:09 AM
// Design Name: 
// Module Name: wb_stage
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

//stage 4: drive the register file write port, the write lands at the edge that ends WB
module wb_stage(
    input logic [127:0] wb_result,
    input logic wb_write_en,
    input logic [4:0] wb_dest_reg,
    output logic wb_wr_en,
    output logic [4:0] wb_wr_addr,
    output logic [127:0] wb_wr_data
);
    assign wb_wr_en = wb_write_en;
    assign wb_wr_addr = wb_dest_reg;
    assign wb_wr_data = wb_result;
endmodule