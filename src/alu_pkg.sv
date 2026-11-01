`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/17/2026 12:57:18 PM
// Design Name: 
// Module Name: alu_pkg
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

//Various Helper Functions
package alu_pkg;

    //sat32(acc + x*y), signed 16x16 multiply
    function automatic logic [31:0] madd_int_sat(
        input logic [31:0] z,     // rs1 word
        input logic [15:0] x,       // rs3 half
        input logic [15:0] y        // rs2 half
    );
        logic [31:0] prod;
        logic [32:0] sum;

        prod = $signed(x) * $signed(y);
        sum  = {z[31], z} + {prod[31], prod};

        if (sum[32] != sum[31])
            return sum[32] ? 32'h8000_0000 : 32'h7FFF_FFFF;
        else
            return sum[31:0];
    endfunction

    //sat32(acc - x*y), signed 16x16 multiply
    function automatic logic [31:0] msub_int_sat(
        input logic [31:0] acc,     // rs1 word
        input logic [15:0] x,       // rs3 half
        input logic [15:0] y        // rs2 half
    );
        logic [31:0] prod;
        logic [32:0] diff;

        prod = $signed(x) * $signed(y);
        diff = {acc[31], acc} - {prod[31], prod};

        if (diff[32] != diff[31])
            return diff[32] ? 32'h8000_0000 : 32'h7FFF_FFFF;
        else
            return diff[31:0];
    endfunction

    //sat64(acc + x*y), signed 32x32 multiply
    function automatic logic [63:0] madd_long_sat(
        input logic [63:0] acc,     // rs1 long
        input logic [31:0] x,       // rs3 word
        input logic [31:0] y        // rs2 word
    );
        logic [63:0] prod;
        logic [64:0] sum;

        prod = $signed(x) * $signed(y);
        sum  = {acc[63], acc} + {prod[63], prod};

        if (sum[64] != sum[63])
            return sum[64] ? 64'h8000_0000_0000_0000 : 64'h7FFF_FFFF_FFFF_FFFF;
        else
            return sum[63:0];
    endfunction

    //sat64(acc - x*y), signed 32x32 multiply
    function automatic logic [63:0] msub_long_sat(
        input logic [63:0] acc,     // rs1 long
        input logic [31:0] x,       // rs3 word
        input logic [31:0] y        // rs2 word
    );
        logic [63:0] prod;
        logic [64:0] diff;

        prod = $signed(x) * $signed(y);
        diff = {acc[63], acc} - {prod[63], prod};

        if (diff[64] != diff[63])
            return diff[64] ? 64'h8000_0000_0000_0000 : 64'h7FFF_FFFF_FFFF_FFFF;
        else
            return diff[63:0];
    endfunction

    //abs diff unsigned
    function automatic logic [7:0] absdiff_u8(
        input logic [7:0] a,        // rs1 byte
        input logic [7:0] b         // rs2 byte
    );
        if (a >= b)
            return a - b;
        else
            return b - a;
    endfunction

    //count 1s
    function automatic logic [31:0] count32(
        input logic [31:0] x        // rs1 word
    );
        return $countones(x);
    endfunction

    //sat16(a + b), signed
    function automatic logic [15:0] add_sat16(
        input logic [15:0] a,       // rs1 half
        input logic [15:0] b        // rs2 half
    );
        logic [16:0] sum;

        sum = {a[15], a} + {b[15], b};

        if (sum[16] != sum[15])
            return sum[16] ? 16'h8000 : 16'h7FFF;
        else
            return sum[15:0];
    endfunction

    //signed max two words
    function automatic logic [31:0] max_s32(
        input logic [31:0] a,       // rs1 word
        input logic [31:0] b        // rs2 word
    );
        if ($signed(a) > $signed(b))
            return a;
        else
            return b;
    endfunction

    //signed min of two words
    function automatic logic [31:0] min_s32(
        input logic [31:0] a,       // rs1 word
        input logic [31:0] b        // rs2 word
    );
        if ($signed(a) < $signed(b))
            return a;
        else
            return b;
    endfunction

    //unsigned 16x16 multiply
    function automatic logic [31:0] mul_u16(
        input logic [15:0] a,       // rs1 low half
        input logic [15:0] b        // rs2 low half or constant
    );
        logic [31:0] prod;          // 32-bit target keeps the full product

        prod = a * b;
        return prod;
    endfunction

    //count leading zeroes (binary search since there isnt a built in for this)
    function automatic logic [31:0] clz32(
        input logic [31:0] x        // rs1 word
    );
        logic [31:0] v;
        logic [5:0]  n;

        if (x == 32'd0)
            return 32'd32;

        v = x;
        n = 6'd0;
        if (v[31:16] == 16'd0) begin n = n + 6'd16; v = v << 16; end
        if (v[31:24] ==  8'd0) begin n = n + 6'd8;  v = v << 8;  end
        if (v[31:28] ==  4'd0) begin n = n + 6'd4;  v = v << 4;  end
        if (v[31:30] ==  2'd0) begin n = n + 6'd2;  v = v << 2;  end
        if (v[31]    ==  1'b0) begin n = n + 6'd1;               end
        return {26'd0, n};
    endfunction

    //rotate right by s
    function automatic logic [31:0] rotr32(
        input logic [31:0] x,       // word
        input logic [4:0]  s        // rotate val
    );
        return (x >> s) | (x << (6'd32 - s));   // s = 0: x << 32 is 0
    endfunction

    //sat16(a - b), signed; called as sub_sat16(rs2, rs1)
    function automatic logic [15:0] sub_sat16(
        input logic [15:0] a,       // rs2 half
        input logic [15:0] b        // rs1 half
    );
        logic [16:0] diff;

        diff = {a[15], a} - {b[15], b};

        if (diff[16] != diff[15])
            return diff[16] ? 16'h8000 : 16'h7FFF;
        else
            return diff[15:0];
    endfunction

endpackage