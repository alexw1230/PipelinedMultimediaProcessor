`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/16/2026 08:15:40 PM
// Design Name: 
// Module Name: alu
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

module alu import alu_pkg::*;(
    input logic [24:0] instruction,
    input logic [127:0] rs1,
    input logic [127:0] rs2,
    input logic [127:0] rs3,
    output logic [127:0] rd,
    output logic write_en,
    output logic [4:0] dest_reg
);
    //dest reg is always the last 5 bits of the instruction
    assign dest_reg = instruction[4:0];
    always_comb begin
        //default vals
        rd = '0;
        write_en = 1'b0;

        //format instruction[24:23]
        //0x  -> LI
        //10  -> R4
        //11  -> R3
        casez (instruction[24:23])
            2'b0?: begin // LI
                rd = rs1; // start from the old rd value
                write_en = 1'b1;

                case (instruction[23:21]) // overwrite halfword
                    3'd0: rd[15:0] = instruction[20:5];
                    3'd1: rd[31:16] = instruction[20:5];
                    3'd2: rd[47:32] = instruction[20:5];
                    3'd3: rd[63:48] = instruction[20:5];
                    3'd4: rd[79:64] = instruction[20:5];
                    3'd5: rd[95:80] = instruction[20:5];
                    3'd6: rd[111:96] = instruction[20:5];
                    3'd7: rd[127:112] = instruction[20:5];
                endcase
            end

            2'b10: begin // R4
            // opcode = instruction[22:20]
                case (instruction[22:20])
                    3'b000: begin // SIMALS: signed int multiply add low, saturated
                        // handle each 32 bits in parallel
                        rd[31:0] = madd_int_sat(rs1[31:0], rs3[15:0], rs2[15:0]);
                        rd[63:32] = madd_int_sat(rs1[63:32], rs3[47:32], rs2[47:32]);
                        rd[95:64] = madd_int_sat(rs1[95:64], rs3[79:64], rs2[79:64]);
                        rd[127:96] = madd_int_sat(rs1[127:96], rs3[111:96], rs2[111:96]);
                        write_en = 1'b1;
                    end

                    3'b001: begin // SIMAHS: signed int multiply add high, saturated
                        // carbon copy just high
                        rd[31:0] = madd_int_sat(rs1[31:0], rs3[31:16], rs2[31:16]);
                        rd[63:32] = madd_int_sat(rs1[63:32], rs3[63:48], rs2[63:48]);
                        rd[95:64] = madd_int_sat(rs1[95:64], rs3[95:80], rs2[95:80]);
                        rd[127:96] = madd_int_sat(rs1[127:96], rs3[127:112], rs2[127:112]);
                        write_en = 1'b1;
                    end
                    3'b010: begin // SIMSLS: signed int multiply subtract low, saturated
                        rd[31:0] = msub_int_sat(rs1[31:0], rs3[15:0], rs2[15:0]);
                        rd[63:32] = msub_int_sat(rs1[63:32], rs3[47:32], rs2[47:32]);
                        rd[95:64] = msub_int_sat(rs1[95:64], rs3[79:64], rs2[79:64]);
                        rd[127:96] = msub_int_sat(rs1[127:96], rs3[111:96], rs2[111:96]);
                        write_en = 1'b1;
                    end
                    3'b011: begin // SIMSHS: signed int multiply subtract high, saturated
                        // carbon copy just high
                        rd[31:0] = msub_int_sat(rs1[31:0], rs3[31:16], rs2[31:16]);
                        rd[63:32] = msub_int_sat(rs1[63:32], rs3[63:48], rs2[63:48]);
                        rd[95:64] = msub_int_sat(rs1[95:64], rs3[95:80], rs2[95:80]);
                        rd[127:96] = msub_int_sat(rs1[127:96], rs3[127:112], rs2[127:112]);
                        write_en = 1'b1;
                    end
                    3'b100: begin // SLMALS: signed long multiply add low, saturated
                        // handle each half in parallel
                        rd[63:0] = madd_long_sat(rs1[63:0], rs3[31:0], rs2[31:0]);
                        rd[127:64] = madd_long_sat(rs1[127:64], rs3[95:64], rs2[95:64]);
                        write_en = 1'b1;
                    end
                    3'b101: begin // SLMAHS: signed long multiply add high, saturated
                        //carbon copy just high
                        rd[63:0] = madd_long_sat(rs1[63:0], rs3[63:32], rs2[63:32]);
                        rd[127:64] = madd_long_sat(rs1[127:64], rs3[127:96], rs2[127:96]);
                        write_en = 1'b1;
                    end
                    3'b110: begin // SLMSLS: signed long multiply subtract low, saturated
                        rd[63:0] = msub_long_sat(rs1[63:0], rs3[31:0], rs2[31:0]);
                        rd[127:64] = msub_long_sat(rs1[127:64], rs3[95:64], rs2[95:64]);
                        write_en = 1'b1;
                    end
                    3'b111: begin // SLMSHS: signed long multiply subtract high, saturated
                        // carbon copy just high
                        rd[63:0] = msub_long_sat(rs1[63:0], rs3[63:32], rs2[63:32]);
                        rd[127:64] = msub_long_sat(rs1[127:64], rs3[127:96], rs2[127:96]);
                        write_en = 1'b1;
                    end

                endcase
            end

            2'b11: begin // R3
                // opcode = instruction[22:15] but we only care abt the low 4 bits [18:15]
                case (instruction[18:15])
                    4'b0000: begin // NOP, no write
                        write_en = 1'b0;
                    end
                    4'b0001: begin // ABSDB
                        // split into bytes |a-b|
                        rd[7:0] = absdiff_u8(rs1[7:0], rs2[7:0]);
                        rd[15:8] = absdiff_u8(rs1[15:8], rs2[15:8]);
                        rd[23:16] = absdiff_u8(rs1[23:16], rs2[23:16]);
                        rd[31:24] = absdiff_u8(rs1[31:24], rs2[31:24]);
                        rd[39:32] = absdiff_u8(rs1[39:32], rs2[39:32]);
                        rd[47:40] = absdiff_u8(rs1[47:40], rs2[47:40]);
                        rd[55:48] = absdiff_u8(rs1[55:48], rs2[55:48]);
                        rd[63:56] = absdiff_u8(rs1[63:56], rs2[63:56]);
                        rd[71:64] = absdiff_u8(rs1[71:64], rs2[71:64]);
                        rd[79:72] = absdiff_u8(rs1[79:72], rs2[79:72]);
                        rd[87:80] = absdiff_u8(rs1[87:80], rs2[87:80]);
                        rd[95:88] = absdiff_u8(rs1[95:88], rs2[95:88]);
                        rd[103:96] = absdiff_u8(rs1[103:96], rs2[103:96]);
                        rd[111:104] = absdiff_u8(rs1[111:104], rs2[111:104]);
                        rd[119:112] = absdiff_u8(rs1[119:112], rs2[119:112]);
                        rd[127:120] = absdiff_u8(rs1[127:120], rs2[127:120]);
                        write_en = 1'b1;
                    end
                    4'b0010: begin // AU: add word unsigned
                        //rd = rs1 + rs2, carry out of the lane dropped
                        rd[31:0] = rs1[31:0] + rs2[31:0];
                        rd[63:32] = rs1[63:32] + rs2[63:32];
                        rd[95:64] = rs1[95:64] + rs2[95:64];
                        rd[127:96] = rs1[127:96] + rs2[127:96];
                        write_en = 1'b1;
                    end
                    4'b0011: begin // CNT1W: count ones in words
                        rd[31:0] = count32(rs1[31:0]);
                        rd[63:32] = count32(rs1[63:32]);
                        rd[95:64] = count32(rs1[95:64]);
                        rd[127:96] = count32(rs1[127:96]);
                        write_en = 1'b1;
                    end

                    4'b0100: begin // AHS: add halfword saturated (signed)
                        rd[15:0] = add_sat16(rs1[15:0], rs2[15:0]);
                        rd[31:16] = add_sat16(rs1[31:16], rs2[31:16]);
                        rd[47:32] = add_sat16(rs1[47:32], rs2[47:32]);
                        rd[63:48] = add_sat16(rs1[63:48], rs2[63:48]);
                        rd[79:64] = add_sat16(rs1[79:64], rs2[79:64]);
                        rd[95:80] = add_sat16(rs1[95:80], rs2[95:80]);
                        rd[111:96] = add_sat16(rs1[111:96], rs2[111:96]);
                        rd[127:112] = add_sat16(rs1[127:112], rs2[127:112]);
                        write_en = 1'b1;
                    end
                    4'b0101: begin // AND: and
                        rd = rs1 & rs2;
                        write_en = 1'b1;
                    end
                    4'b0110: begin // BCW: broadcast word
                        rd = {4{rs1[31:0]}};
                        write_en = 1'b1;
                    end
                    4'b0111: begin // MAXWS: max signed word
                        //max(rs1,rs2) for each word
                        rd[31:0] = max_s32(rs1[31:0], rs2[31:0]);
                        rd[63:32] = max_s32(rs1[63:32], rs2[63:32]);
                        rd[95:64] = max_s32(rs1[95:64], rs2[95:64]);
                        rd[127:96] = max_s32(rs1[127:96], rs2[127:96]);
                        write_en = 1'b1;
                    end
                    4'b1000: begin // MINWS: minimum signed word (opcode xxxx1000)
                        // min
                        rd[31:0] = min_s32(rs1[31:0], rs2[31:0]);
                        rd[63:32] = min_s32(rs1[63:32], rs2[63:32]);
                        rd[95:64] = min_s32(rs1[95:64], rs2[95:64]);
                        rd[127:96] = min_s32(rs1[127:96], rs2[127:96]);
                        write_en = 1'b1;
                    end
                    4'b1001: begin // MLHU: multiply low unsigned
                        //16 * 16 = 32bit max
                        rd[31:0] = mul_u16(rs1[15:0], rs2[15:0]);
                        rd[63:32] = mul_u16(rs1[47:32], rs2[47:32]);
                        rd[95:64] = mul_u16(rs1[79:64], rs2[79:64]);
                        rd[127:96] = mul_u16(rs1[111:96], rs2[111:96]);
                        write_en = 1'b1;
                    end
                    4'b1010: begin // MLHCU: multiply low by constant unsigned
                        //same mult w/ const from ins
                        rd[31:0] = mul_u16(rs1[15:0], {11'b0, instruction[14:10]});
                        rd[63:32] = mul_u16(rs1[47:32], {11'b0, instruction[14:10]});
                        rd[95:64] = mul_u16(rs1[79:64], {11'b0, instruction[14:10]});
                        rd[127:96] = mul_u16(rs1[111:96], {11'b0, instruction[14:10]});
                        write_en = 1'b1;
                    end
                    4'b1011: begin // OR: or
                        rd = rs1 | rs2;
                        write_en = 1'b1;
                    end
                    4'b1100: begin // CNTLZ: count leading zeros
                        //count leading 0s in words
                        rd[31:0] = clz32(rs1[31:0]);
                        rd[63:32] = clz32(rs1[63:32]);
                        rd[95:64] = clz32(rs1[95:64]);
                        rd[127:96] = clz32(rs1[127:96]);
                        write_en = 1'b1;
                    end
                    4'b1101: begin // ROTW: rotate bits in words
                        //rotate right by low 5 in rs2
                        rd[31:0] = rotr32(rs1[31:0], rs2[4:0]);
                        rd[63:32] = rotr32(rs1[63:32], rs2[36:32]);
                        rd[95:64] = rotr32(rs1[95:64], rs2[68:64]);
                        rd[127:96] = rotr32(rs1[127:96], rs2[100:96]);
                        write_en = 1'b1;
                    end
                    4'b1110: begin // SFWU: subtract from word unsigned
                        //wraparound
                        // rd = rs2 - rs1
                        // borrow out of the lane is dropped, so 0 - 1 = FFFF_FFFF
                        rd[31:0] = rs2[31:0] - rs1[31:0];
                        rd[63:32] = rs2[63:32] - rs1[63:32];
                        rd[95:64] = rs2[95:64] - rs1[95:64];
                        rd[127:96] = rs2[127:96] - rs1[127:96];
                        write_en = 1'b1;
                    end
                    4'b1111: begin // SFHS: subtract from halfword saturated (signed)
                        rd[15:0] = sub_sat16(rs2[15:0], rs1[15:0]);
                        rd[31:16] = sub_sat16(rs2[31:16], rs1[31:16]);
                        rd[47:32] = sub_sat16(rs2[47:32], rs1[47:32]);
                        rd[63:48] = sub_sat16(rs2[63:48], rs1[63:48]);
                        rd[79:64] = sub_sat16(rs2[79:64], rs1[79:64]);
                        rd[95:80] = sub_sat16(rs2[95:80], rs1[95:80]);
                        rd[111:96] = sub_sat16(rs2[111:96], rs1[111:96]);
                        rd[127:112] = sub_sat16(rs2[127:112], rs1[127:112]);
                        write_en = 1'b1;
                    end
                endcase
            end

            default: begin
            end
        endcase
    end
endmodule