`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/24/2026 10:53:41 AM
// Design Name: 
// Module Name: reg_file
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

//32 x 128 register file, 3 combinational reads, 1 write on the rising edge
//a read of the register being written this cycle gets the new value
module reg_file(
    input logic clk, rst,
    input logic [4:0] rs1_addr, rs2_addr, rs3_addr,
    input logic wr_en,
    input logic [4:0] wr_addr,
    input logic [127:0] wr_data,
    output logic [127:0] rs1_data, rs2_data, rs3_data,
    output logic rs1_byp, rs2_byp, rs3_byp
);
    logic [31:0][127:0] regs;

    always_ff @(posedge clk) begin
        if (rst) begin
            regs <= '0;
        end else if (wr_en) begin
            regs[wr_addr] <= wr_data;
        end
    end

    assign rs1_byp = wr_en && (wr_addr == rs1_addr);
    assign rs2_byp = wr_en && (wr_addr == rs2_addr);
    assign rs3_byp = wr_en && (wr_addr == rs3_addr);
    assign rs1_data = rs1_byp ? wr_data : regs[rs1_addr];
    assign rs2_data = rs2_byp ? wr_data : regs[rs2_addr];
    assign rs3_data = rs3_byp ? wr_data : regs[rs3_addr];
endmodule