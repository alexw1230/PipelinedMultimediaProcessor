`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/24/2026 11:19:38 AM
// Design Name: 
// Module Name: instr_buffer
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

//64 x 25 instruction buffer, combinational read, filled by the testbench
module instr_buffer(
    input logic [5:0] addr,
    output logic [24:0] instr
);
    logic [24:0] mem [0:63];
    assign instr = mem[addr];
endmodule