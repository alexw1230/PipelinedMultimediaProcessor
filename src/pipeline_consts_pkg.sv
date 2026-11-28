`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/24/2026 10:51:16 AM
// Design Name: 
// Module Name: pipeline_consts_pkg
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

package pipeline_consts_pkg;
    //R3 with opcode 0000, never writes
    localparam logic [24:0] NOP_INSTR = 25'h1800000;
endpackage