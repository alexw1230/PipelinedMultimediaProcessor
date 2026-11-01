`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 10/16/2026 08:22:25 PM
// Design Name:
// Module Name: alu_tb
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

module alu_tb;

    // DUT signals
    logic [24:0] instruction;
    logic [127:0] rs1, rs2, rs3;
    logic [127:0] rd;
    logic write_en;
    logic [4:0] dest_reg;

    alu dut (
        .instruction(instruction),
        .rs1(rs1),
        .rs2(rs2),
        .rs3(rs3),
        .rd(rd),
        .write_en(write_en),
        .dest_reg(dest_reg)
    );

    //counters
    int num_tests = 0;
    int num_errors = 0;

    //apply inputs and check outputs against known
    task automatic check(
        input string name,
        input logic [24:0] instr,
        input logic [127:0] a, // rs1
        input logic [127:0] b, // rs2
        input logic [127:0] c, // rs3
        input logic [127:0] exp_rd,
        input logic exp_we
    );
        logic ok;

        instruction = instr;
        rs1 = a;
        rs2 = b;
        rs3 = c;
        #10;//wait 10 between cases

        num_tests++;

        //check if res is correct
        ok = (write_en === exp_we) &&
             (dest_reg === instr[4:0]) &&
             (!exp_we || rd === exp_rd);

        if (ok) begin
            $display("PASS %-8s rd=%h we=%b dest=r%0d", name, rd, write_en, dest_reg);
        end else begin
            num_errors++;
            $display("FAIL %-8s instr=%h", name, instr);
            $display("    rs1=%h rs2=%h rs3=%h", a, b, c);
            $display("    got rd=%h we=%b dest=r%0d", rd, write_en, dest_reg);
            $display("    exp rd=%h we=%b dest=r%0d", exp_rd, exp_we, instr[4:0]);

            // stop on the first failure so the waveform ends at the bad test
            $fatal(1, "Stopping: test '%s' failed (%0d of %0d run so far passed)",
                   name, num_tests - 1, num_tests);
        end
    endtask

    // Test cases
    initial begin
        instruction = '0;
        rs1 = '0;
        rs2 = '0;
        rs3 = '0;
        #1;

        //LI

        // a) normal: idx 2 writes bits [47:32], the other 7 halfwords are kept
        // rs1 BBDC_79EF_C388_D17B_3DEF_D3CF_4E46_65D2, idx 2, imm FEED
        // -> BBDC_79EF_C388_D17B_3DEF_FEED_4E46_65D2
        check("LI 1", {1'b0, 3'd2, 16'hFEED, 5'd1},
            128'hBBDC_79EF_C388_D17B_3DEF_D3CF_4E46_65D2,
            '0, '0,
            128'hBBDC_79EF_C388_D17B_3DEF_FEED_4E46_65D2, 1'b1);

        // b) edge: lowest index (0) writes bits [15:0]
        // rs1 0123_4567_89AB_CDEF_FEDC_BA98_7654_3210, idx 0, imm FEED -> 0123_4567_89AB_CDEF_FEDC_BA98_7654_FEED
        check("LI 2", {1'b0, 3'd0, 16'hFEED, 5'd2},
            128'h0123_4567_89AB_CDEF_FEDC_BA98_7654_3210, '0, '0,
            128'h0123_4567_89AB_CDEF_FEDC_BA98_7654_FEED, 1'b1);

        // c) edge: highest index (7) writes bits [127:112]
        // rs1 0123_4567_89AB_CDEF_FEDC_BA98_7654_3210, idx 7, imm FEED -> FEED_4567_89AB_CDEF_FEDC_BA98_7654_3210
        check("LI 3", {1'b0, 3'd7, 16'hFEED, 5'd3},
            128'h0123_4567_89AB_CDEF_FEDC_BA98_7654_3210, '0, '0,
            128'hFEED_4567_89AB_CDEF_FEDC_BA98_7654_3210, 1'b1);


        //SIMALS

        // a) normal: random values, mixed-sign products from the low halves
        // Word 3: 269834574 + (-379)*(-18626) = 276893828 -> 1081_1084
        // Word 2: -380548514 + (29601)*(-28491) = -1223910605 -> B70C_9B33
        // Word 1: -449106871 + (-3779)*(2691) = -459276160 -> E4A0_0080
        // Word 0: -88609278 + (-11989)*(-2811) = -54908199 -> FCBA_2AD9
        check("SIMALS 1", {2'b10, 3'b000, 5'd3, 5'd2, 5'd1, 5'd4},
            128'h1015_594E_E951_4A5E_E53B_2C49_FAB7_EE02,
            128'h0000_B73E_0000_90B5_0000_0A83_0000_F505,
            128'h0000_FE85_0000_73A1_0000_F13D_0000_D12B,
            128'h1081_1084_B70C_9B33_E4A0_0080_FCBA_2AD9, 1'b1);

        // b) positive saturation: overflow clamps to 7FFF_FFFF, close values are not clamped
        // Word 3: 3FFF_8000 + (-32768)(-32768) -> 7FFF_8000 (close, not clamped)
        // Word 2: 4000_0000 + (-32768)(-32768) = 2^31 -> 7FFF_FFFF (over by one)
        // Word 1: 7000_0000 + (-32768)(-32768) -> 7FFF_FFFF
        // Word 0: 7FFF_FFFF + 1*1 -> 7FFF_FFFF (over by one)
        check("SIMALS 2", {2'b10, 3'b000, 5'd3, 5'd2, 5'd1, 5'd5},
            128'h3FFF_8000_4000_0000_7000_0000_7FFF_FFFF,
            128'h0000_8000_0000_8000_0000_8000_0000_0001,
            128'h0000_8000_0000_8000_0000_8000_0000_0001,
            128'h7FFF_8000_7FFF_FFFF_7FFF_FFFF_7FFF_FFFF, 1'b1);

        // c) negative saturation: overflow clamps to 8000_0000, close values are not clamped
        // Word 3: -2 + 1*(-1) -> FFFF_FFFD (ordinary negative)
        // Word 2: C000_0000 + 32767*(-32768) -> 8000_8000 (close, not clamped)
        // Word 1: 9000_0000 + 32767*(-32768) -> 8000_0000
        // Word 0: 8000_0000 + 1*(-1) -> 8000_0000 (over by one)
        check("SIMALS 3", {2'b10, 3'b000, 5'd3, 5'd2, 5'd1, 5'd6},
            128'hFFFF_FFFE_C000_0000_9000_0000_8000_0000,
            128'h0000_FFFF_0000_8000_0000_8000_0000_FFFF,
            128'h0000_0001_0000_7FFF_0000_7FFF_0000_0001,
            128'hFFFF_FFFD_8000_8000_8000_0000_8000_0000, 1'b1);

        // d) exactly max/min (not clamped), positive -> negative, negative -> positive
        // Word 3: 5 + 4*(-3) -> FFFF_FFF9 (positive -> negative)
        // Word 2: -5 + 4*3 -> 0000_0007 (negative -> positive)
        // Word 1: 8000_0001 + 1*(-1) -> 8000_0000 (exactly min)
        // Word 0: 7FFF_FFFE + 1*1 -> 7FFF_FFFF (exactly max)
        check("SIMALS 4", {2'b10, 3'b000, 5'd3, 5'd2, 5'd1, 5'd7},
            128'h0000_0005_FFFF_FFFB_8000_0001_7FFF_FFFE,
            128'h0000_FFFD_0000_0003_0000_FFFF_0000_0001,
            128'h0000_0004_0000_0004_0000_0001_0000_0001,
            128'hFFFF_FFF9_0000_0007_8000_0000_7FFF_FFFF, 1'b1);


        //SIMAHS

        // a) normal: random values, mixed-sign products from the HIGH halves
        // Word 3: -367029274 + (16777)*(-27270) = -824538064 -> CEDA_8C30
        // Word 2: -45383374 + (14372)*(22735) = 281364046 -> 10C5_464E
        // Word 1: 483318570 + (-1360)*(-11885) = 499482170 -> 1DC5_7E3A
        // Word 0: -144613422 + (-18868)*(21619) = -552520714 -> DF11_33F6
        check("SIMAHS 1", {2'b10, 3'b001, 5'd3, 5'd2, 5'd1, 5'd8},
            128'hEA1F_93E6_FD4B_8132_1CCE_DB2A_F761_5FD2,
            128'h957A_0000_58CF_0000_D193_0000_5473_0000,
            128'h4189_0000_3824_0000_FAB0_0000_B64C_0000,
            128'hCEDA_8C30_10C5_464E_1DC5_7E3A_DF11_33F6, 1'b1);

        // b) positive saturation: overflow clamps to 7FFF_FFFF, close values are not clamped (factors in the HIGH halves)
        // Word 3: 3FFF_8000 + (-32768)(-32768) -> 7FFF_8000 (close, not clamped)
        // Word 2: 4000_0000 + (-32768)(-32768) = 2^31 -> 7FFF_FFFF (over by one)
        // Word 1: 7000_0000 + (-32768)(-32768) -> 7FFF_FFFF
        // Word 0: 7FFF_FFFF + 1*1 -> 7FFF_FFFF (over by one)
        check("SIMAHS 2", {2'b10, 3'b001, 5'd3, 5'd2, 5'd1, 5'd9},
            128'h3FFF_8000_4000_0000_7000_0000_7FFF_FFFF,
            128'h8000_0000_8000_0000_8000_0000_0001_0000,
            128'h8000_0000_8000_0000_8000_0000_0001_0000,
            128'h7FFF_8000_7FFF_FFFF_7FFF_FFFF_7FFF_FFFF, 1'b1);

        // c) negative saturation: overflow clamps to 8000_0000, close values are not clamped (factors in the HIGH halves)
        // Word 3: -2 + 1*(-1) -> FFFF_FFFD (ordinary negative)
        // Word 2: C000_0000 + 32767*(-32768) -> 8000_8000 (close, not clamped)
        // Word 1: 9000_0000 + 32767*(-32768) -> 8000_0000
        // Word 0: 8000_0000 + 1*(-1) -> 8000_0000 (over by one)
        check("SIMAHS 3", {2'b10, 3'b001, 5'd3, 5'd2, 5'd1, 5'd10},
            128'hFFFF_FFFE_C000_0000_9000_0000_8000_0000,
            128'hFFFF_0000_8000_0000_8000_0000_FFFF_0000,
            128'h0001_0000_7FFF_0000_7FFF_0000_0001_0000,
            128'hFFFF_FFFD_8000_8000_8000_0000_8000_0000, 1'b1);

        // d) exactly max/min (not clamped), positive -> negative, negative -> positive, the unused half holds large values so using the wrong half changes the result (factors in the HIGH halves)
        // Word 3: 5 + 4*(-3) -> FFFF_FFF9 (positive -> negative)
        // Word 2: -5 + 4*3 -> 0000_0007 (negative -> positive)
        // Word 1: 8000_0001 + 1*(-1) -> 8000_0000 (exactly min)
        // Word 0: 7FFF_FFFE + 1*1 -> 7FFF_FFFF (exactly max)
        check("SIMAHS 4", {2'b10, 3'b001, 5'd3, 5'd2, 5'd1, 5'd11},
            128'h0000_0005_FFFF_FFFB_8000_0001_7FFF_FFFE,
            128'hFFFD_8000_0003_8000_FFFF_8000_0001_7FFF,
            128'h0004_8000_0004_8000_0001_8000_0001_8000,
            128'hFFFF_FFF9_0000_0007_8000_0000_7FFF_FFFF, 1'b1);


        //SIMSLS

        // a) normal: random values, mixed-sign products from the low halves
        // Word 3: 513825261 - (18024)*(-17434) = 828055677 -> 315B_207D
        // Word 2: 175132705 - (16178)*(231) = 171395587 -> 0A37_4A03
        // Word 1: 440216159 - (18967)*(-8435) = 600202804 -> 23C6_5E34
        // Word 0: 244041532 - (15443)*(-27056) = 661867340 -> 2773_4B4C
        check("SIMSLS 1", {2'b10, 3'b010, 5'd3, 5'd2, 5'd1, 5'd12},
            128'h1EA0_59ED_0A70_5021_1A3D_2A5F_0E8B_C73C,
            128'h0000_BBE6_0000_00E7_0000_DF0D_0000_9650,
            128'h0000_4668_0000_3F32_0000_4A17_0000_3C53,
            128'h315B_207D_0A37_4A03_23C6_5E34_2773_4B4C, 1'b1);

        // b) positive saturation: overflow clamps to 7FFF_FFFF, close values are not clamped
        // Word 3: 4000_0000 - 32767*(-32768) -> 7FFF_8000 (close, not clamped)
        // Word 2: 7000_0000 - 32767*(-32768) -> 7FFF_FFFF
        // Word 1: 7FFF_FFFF - 1*(-1) -> 7FFF_FFFF (over by one)
        // Word 0: 4000_8000 - 32767*(-32768) = 2^31 -> 7FFF_FFFF (over by one)
        check("SIMSLS 2", {2'b10, 3'b010, 5'd3, 5'd2, 5'd1, 5'd13},
            128'h4000_0000_7000_0000_7FFF_FFFF_4000_8000,
            128'h0000_8000_0000_8000_0000_FFFF_0000_8000,
            128'h0000_7FFF_0000_7FFF_0000_0001_0000_7FFF,
            128'h7FFF_8000_7FFF_FFFF_7FFF_FFFF_7FFF_FFFF, 1'b1);

        // c) negative saturation: overflow clamps to 8000_0000, close values are not clamped
        // Word 3: C000_0000 - 32767*32767 -> 8000_FFFF (close, not clamped)
        // Word 2: BFFF_FFFF - (-32768)(-32768) -> 8000_0000 (over by one)
        // Word 1: 8000_0000 - 1*1 -> 8000_0000 (over by one)
        // Word 0: 9000_0000 - 32767*32767 -> 8000_0000
        check("SIMSLS 3", {2'b10, 3'b010, 5'd3, 5'd2, 5'd1, 5'd14},
            128'hC000_0000_BFFF_FFFF_8000_0000_9000_0000,
            128'h0000_7FFF_0000_8000_0000_0001_0000_7FFF,
            128'h0000_7FFF_0000_8000_0000_0001_0000_7FFF,
            128'h8000_FFFF_8000_0000_8000_0000_8000_0000, 1'b1);

        // d) exactly max/min (not clamped), positive -> negative, negative -> positive, the unused half holds large values so using the wrong half changes the result
        // Word 3: 4000_7FFF - 32767*(-32768) -> 7FFF_FFFF (exactly max)
        // Word 2: C000_0000 - (-32768)(-32768) -> 8000_0000 (exactly min)
        // Word 1: -5 - 4*(-3) -> 0000_0007 (negative -> positive)
        // Word 0: 5 - 4*3 -> FFFF_FFF9 (positive -> negative)
        check("SIMSLS 4", {2'b10, 3'b010, 5'd3, 5'd2, 5'd1, 5'd15},
            128'h4000_7FFF_C000_0000_FFFF_FFFB_0000_0005,
            128'h7FFF_8000_7FFF_8000_7FFF_FFFD_7FFF_0003,
            128'h7FFF_7FFF_7FFF_8000_7FFF_0004_7FFF_0004,
            128'h7FFF_FFFF_8000_0000_0000_0007_FFFF_FFF9, 1'b1);


        //SIMSHS

        // a) normal: random values, mixed-sign products from the HIGH halves
        // Word 3: -8720500 - (15861)*(10381) = -173373541 -> F5AA_879B
        // Word 2: -344787711 - (19905)*(-8172) = -182124051 -> F525_01ED
        // Word 1: -496805227 - (-3526)*(-4164) = -511487491 -> E183_51FD
        // Word 0: -2785295 - (-21297)*(27218) = 576876451 -> 2262_6FA3
        check("SIMSHS 1", {2'b10, 3'b011, 5'd3, 5'd2, 5'd1, 5'd16},
            128'hFF7A_EF8C_EB72_F501_E263_5A95_FFD5_7FF1,
            128'h288D_0000_E014_0000_EFBC_0000_6A52_0000,
            128'h3DF5_0000_4DC1_0000_F23A_0000_ACCF_0000,
            128'hF5AA_879B_F525_01ED_E183_51FD_2262_6FA3, 1'b1);

        // b) positive saturation: overflow clamps to 7FFF_FFFF, close values are not clamped (factors in the HIGH halves)
        // Word 3: 4000_0000 - 32767*(-32768) -> 7FFF_8000 (close, not clamped)
        // Word 2: 7000_0000 - 32767*(-32768) -> 7FFF_FFFF
        // Word 1: 7FFF_FFFF - 1*(-1) -> 7FFF_FFFF (over by one)
        // Word 0: 4000_8000 - 32767*(-32768) = 2^31 -> 7FFF_FFFF (over by one)
        check("SIMSHS 2", {2'b10, 3'b011, 5'd3, 5'd2, 5'd1, 5'd17},
            128'h4000_0000_7000_0000_7FFF_FFFF_4000_8000,
            128'h8000_0000_8000_0000_FFFF_0000_8000_0000,
            128'h7FFF_0000_7FFF_0000_0001_0000_7FFF_0000,
            128'h7FFF_8000_7FFF_FFFF_7FFF_FFFF_7FFF_FFFF, 1'b1);

        // c) negative saturation: overflow clamps to 8000_0000, close values are not clamped (factors in the HIGH halves)
        // Word 3: C000_0000 - 32767*32767 -> 8000_FFFF (close, not clamped)
        // Word 2: BFFF_FFFF - (-32768)(-32768) -> 8000_0000 (over by one)
        // Word 1: 8000_0000 - 1*1 -> 8000_0000 (over by one)
        // Word 0: 9000_0000 - 32767*32767 -> 8000_0000
        check("SIMSHS 3", {2'b10, 3'b011, 5'd3, 5'd2, 5'd1, 5'd18},
            128'hC000_0000_BFFF_FFFF_8000_0000_9000_0000,
            128'h7FFF_0000_8000_0000_0001_0000_7FFF_0000,
            128'h7FFF_0000_8000_0000_0001_0000_7FFF_0000,
            128'h8000_FFFF_8000_0000_8000_0000_8000_0000, 1'b1);

        // d) exactly max/min (not clamped), positive -> negative, negative -> positive, the unused half holds large values so using the wrong half changes the result (factors in the HIGH halves)
        // Word 3: 4000_7FFF - 32767*(-32768) -> 7FFF_FFFF (exactly max)
        // Word 2: C000_0000 - (-32768)(-32768) -> 8000_0000 (exactly min)
        // Word 1: -5 - 4*(-3) -> 0000_0007 (negative -> positive)
        // Word 0: 5 - 4*3 -> FFFF_FFF9 (positive -> negative)
        check("SIMSHS 4", {2'b10, 3'b011, 5'd3, 5'd2, 5'd1, 5'd19},
            128'h4000_7FFF_C000_0000_FFFF_FFFB_0000_0005,
            128'h8000_7FFF_8000_7FFF_FFFD_7FFF_0003_7FFF,
            128'h7FFF_7FFF_8000_7FFF_0004_7FFF_0004_7FFF,
            128'h7FFF_FFFF_8000_0000_0000_0007_FFFF_FFF9, 1'b1);


        //SLMALS

        // a) normal: random values, mixed-sign products from the low 32s
        // Long 1: E6F4_DE88_95DF_CFF4 + 31D3_B50E*9963_258C -> D2FB_FCDD_D13B_D99C
        // Long 0: 15CE_7523_DEDC_AFB5 + 8FB8_7D8A*90D9_D054 -> 468E_363A_F760_00FD
        check("SLMALS 1", {2'b10, 3'b100, 5'd3, 5'd2, 5'd1, 5'd20},
            128'hE6F4_DE88_95DF_CFF4_15CE_7523_DEDC_AFB5,
            128'h0000_0000_9963_258C_0000_0000_90D9_D054,
            128'h0000_0000_31D3_B50E_0000_0000_8FB8_7D8A,
            128'hD2FB_FCDD_D13B_D99C_468E_363A_F760_00FD, 1'b1);

        // b) positive saturation: overflow clamps to 7FFF_FFFF_FFFF_FFFF, close values are not clamped
        // Long 1: 2^62 + (-2^31)(-2^31) = 2^63 -> 7FFF_FFFF_FFFF_FFFF (over by one)
        // Long 0: 2^62 + (2^31-1)^2 -> 7FFF_FFFF_0000_0001 (close, not clamped)
        check("SLMALS 2", {2'b10, 3'b100, 5'd3, 5'd2, 5'd1, 5'd21},
            128'h4000_0000_0000_0000_4000_0000_0000_0000,
            128'h0000_0000_8000_0000_0000_0000_7FFF_FFFF,
            128'h0000_0000_8000_0000_0000_0000_7FFF_FFFF,
            128'h7FFF_FFFF_FFFF_FFFF_7FFF_FFFF_0000_0001, 1'b1);

        // c) negative saturation: overflow clamps to 8000_0000_0000_0000, close values are not clamped
        // Long 1: -2^62 + (2^31-1)(-2^31) -> 8000_0000_8000_0000 (close, not clamped)
        // Long 0: 8000_0000_0000_0000 + 1*(-1) -> 8000_0000_0000_0000 (over by one)
        check("SLMALS 3", {2'b10, 3'b100, 5'd3, 5'd2, 5'd1, 5'd22},
            128'hC000_0000_0000_0000_8000_0000_0000_0000,
            128'h0000_0000_8000_0000_0000_0000_FFFF_FFFF,
            128'h0000_0000_7FFF_FFFF_0000_0000_0000_0001,
            128'h8000_0000_8000_0000_8000_0000_0000_0000, 1'b1);

        // d) exactly max/min (not clamped), the unused half holds large values so using the wrong half changes the result
        // Long 1: 8000_0000_0000_0001 + 1*(-1) -> 8000_0000_0000_0000 (exactly min)
        // Long 0: 7FFF_FFFF_FFFF_FFFE + 1*1 -> 7FFF_FFFF_FFFF_FFFF (exactly max)
        check("SLMALS 4", {2'b10, 3'b100, 5'd3, 5'd2, 5'd1, 5'd23},
            128'h8000_0000_0000_0001_7FFF_FFFF_FFFF_FFFE,
            128'h8000_0000_FFFF_FFFF_7FFF_FFFF_0000_0001,
            128'h8000_0000_0000_0001_8000_0000_0000_0001,
            128'h8000_0000_0000_0000_7FFF_FFFF_FFFF_FFFF, 1'b1);


        //SLMAHS

        // a) normal: random values, mixed-sign products from the HIGH 32s
        // Long 1: F95B_8F23_DAB6_D37C + CA2E_29BB*ACF6_C7FC -> 0AD0_87C3_804A_4490
        // Long 0: FE97_1376_5F13_FC41 + CC4E_2619*33CF_FF6E -> F420_A4A9_C9D2_41FF
        check("SLMAHS 1", {2'b10, 3'b101, 5'd3, 5'd2, 5'd1, 5'd24},
            128'hF95B_8F23_DAB6_D37C_FE97_1376_5F13_FC41,
            128'hACF6_C7FC_0000_0000_33CF_FF6E_0000_0000,
            128'hCA2E_29BB_0000_0000_CC4E_2619_0000_0000,
            128'h0AD0_87C3_804A_4490_F420_A4A9_C9D2_41FF, 1'b1);

        // b) positive saturation: overflow clamps to 7FFF_FFFF_FFFF_FFFF, close values are not clamped (factors in the HIGH 32s)
        // Long 1: 2^62 + (-2^31)(-2^31) = 2^63 -> 7FFF_FFFF_FFFF_FFFF (over by one)
        // Long 0: 2^62 + (2^31-1)^2 -> 7FFF_FFFF_0000_0001 (close, not clamped)
        check("SLMAHS 2", {2'b10, 3'b101, 5'd3, 5'd2, 5'd1, 5'd25},
            128'h4000_0000_0000_0000_4000_0000_0000_0000,
            128'h8000_0000_0000_0000_7FFF_FFFF_0000_0000,
            128'h8000_0000_0000_0000_7FFF_FFFF_0000_0000,
            128'h7FFF_FFFF_FFFF_FFFF_7FFF_FFFF_0000_0001, 1'b1);

        // c) negative saturation: overflow clamps to 8000_0000_0000_0000, close values are not clamped (factors in the HIGH 32s)
        // Long 1: -2^62 + (2^31-1)(-2^31) -> 8000_0000_8000_0000 (close, not clamped)
        // Long 0: 8000_0000_0000_0000 + 1*(-1) -> 8000_0000_0000_0000 (over by one)
        check("SLMAHS 3", {2'b10, 3'b101, 5'd3, 5'd2, 5'd1, 5'd26},
            128'hC000_0000_0000_0000_8000_0000_0000_0000,
            128'h8000_0000_0000_0000_FFFF_FFFF_0000_0000,
            128'h7FFF_FFFF_0000_0000_0000_0001_0000_0000,
            128'h8000_0000_8000_0000_8000_0000_0000_0000, 1'b1);

        // d) exactly max/min (not clamped), the unused half holds large values so using the wrong half changes the result (factors in the HIGH 32s)
        // Long 1: 8000_0000_0000_0001 + 1*(-1) -> 8000_0000_0000_0000 (exactly min)
        // Long 0: 7FFF_FFFF_FFFF_FFFE + 1*1 -> 7FFF_FFFF_FFFF_FFFF (exactly max)
        check("SLMAHS 4", {2'b10, 3'b101, 5'd3, 5'd2, 5'd1, 5'd27},
            128'h8000_0000_0000_0001_7FFF_FFFF_FFFF_FFFE,
            128'hFFFF_FFFF_8000_0000_0000_0001_7FFF_FFFF,
            128'h0000_0001_8000_0000_0000_0001_8000_0000,
            128'h8000_0000_0000_0000_7FFF_FFFF_FFFF_FFFF, 1'b1);


        //SLMSLS

        // a) normal: random values, mixed-sign products from the low 32s
        // Long 1: 0100_9E36_BA4E_B0DF - C01D_8D7E*FC40_CED0 -> 0011_40A5_72F0_567F
        // Long 0: FA54_7710_3863_DB3D - 5646_2A99*BBF7_FAD8 -> 1141_CE4F_0AF7_8025
        check("SLMSLS 1", {2'b10, 3'b110, 5'd3, 5'd2, 5'd1, 5'd28},
            128'h0100_9E36_BA4E_B0DF_FA54_7710_3863_DB3D,
            128'h0000_0000_FC40_CED0_0000_0000_BBF7_FAD8,
            128'h0000_0000_C01D_8D7E_0000_0000_5646_2A99,
            128'h0011_40A5_72F0_567F_1141_CE4F_0AF7_8025, 1'b1);

        // b) positive saturation: overflow clamps to 7FFF_FFFF_FFFF_FFFF, close values are not clamped
        // Long 1: 2^62 - (2^31-1)(-2^31) -> 7FFF_FFFF_8000_0000 (close, not clamped)
        // Long 0: 7FFF_FFFF_FFFF_FFFF - 1*(-1) -> 7FFF_FFFF_FFFF_FFFF (over by one)
        check("SLMSLS 2", {2'b10, 3'b110, 5'd3, 5'd2, 5'd1, 5'd29},
            128'h4000_0000_0000_0000_7FFF_FFFF_FFFF_FFFF,
            128'h0000_0000_8000_0000_0000_0000_FFFF_FFFF,
            128'h0000_0000_7FFF_FFFF_0000_0000_0000_0001,
            128'h7FFF_FFFF_8000_0000_7FFF_FFFF_FFFF_FFFF, 1'b1);

        // c) negative saturation: overflow clamps to 8000_0000_0000_0000, close values are not clamped
        // Long 1: -2^62 - (2^31-1)^2 -> 8000_0000_FFFF_FFFF (close, not clamped)
        // Long 0: (-2^62 - 1) - (-2^31)(-2^31) -> 8000_0000_0000_0000 (over by one)
        check("SLMSLS 3", {2'b10, 3'b110, 5'd3, 5'd2, 5'd1, 5'd30},
            128'hC000_0000_0000_0000_BFFF_FFFF_FFFF_FFFF,
            128'h0000_0000_7FFF_FFFF_0000_0000_8000_0000,
            128'h0000_0000_7FFF_FFFF_0000_0000_8000_0000,
            128'h8000_0000_FFFF_FFFF_8000_0000_0000_0000, 1'b1);

        // d) exactly max/min (not clamped), the unused half holds large values so using the wrong half changes the result
        // Long 1: 4000_0000_7FFF_FFFF - (2^31-1)(-2^31) -> 7FFF_FFFF_FFFF_FFFF (exactly max)
        // Long 0: -2^62 - (-2^31)(-2^31) -> 8000_0000_0000_0000 (exactly min)
        check("SLMSLS 4", {2'b10, 3'b110, 5'd3, 5'd2, 5'd1, 5'd31},
            128'h4000_0000_7FFF_FFFF_C000_0000_0000_0000,
            128'h8000_0000_8000_0000_7FFF_FFFF_8000_0000,
            128'h8000_0000_7FFF_FFFF_7FFF_FFFF_8000_0000,
            128'h7FFF_FFFF_FFFF_FFFF_8000_0000_0000_0000, 1'b1);


        //SLMSHS

        // a) normal: random values, mixed-sign products from the HIGH 32s
        // Long 1: F3E5_17A8_9FD1_8638 - 8BC7_CBD7*50EE_FCE7 -> 18A3_2706_1FFE_F337
        // Long 0: FC22_1135_5814_7D60 - F2E1_62E7*D175_8D40 -> F9BF_7898_B1AF_88A0
        check("SLMSHS 1", {2'b10, 3'b111, 5'd3, 5'd2, 5'd1, 5'd1},
            128'hF3E5_17A8_9FD1_8638_FC22_1135_5814_7D60,
            128'h50EE_FCE7_0000_0000_D175_8D40_0000_0000,
            128'h8BC7_CBD7_0000_0000_F2E1_62E7_0000_0000,
            128'h18A3_2706_1FFE_F337_F9BF_7898_B1AF_88A0, 1'b1);

        // b) positive saturation: overflow clamps to 7FFF_FFFF_FFFF_FFFF, close values are not clamped (factors in the HIGH 32s)
        // Long 1: 2^62 - (2^31-1)(-2^31) -> 7FFF_FFFF_8000_0000 (close, not clamped)
        // Long 0: 7FFF_FFFF_FFFF_FFFF - 1*(-1) -> 7FFF_FFFF_FFFF_FFFF (over by one)
        check("SLMSHS 2", {2'b10, 3'b111, 5'd3, 5'd2, 5'd1, 5'd2},
            128'h4000_0000_0000_0000_7FFF_FFFF_FFFF_FFFF,
            128'h8000_0000_0000_0000_FFFF_FFFF_0000_0000,
            128'h7FFF_FFFF_0000_0000_0000_0001_0000_0000,
            128'h7FFF_FFFF_8000_0000_7FFF_FFFF_FFFF_FFFF, 1'b1);

        // c) negative saturation: overflow clamps to 8000_0000_0000_0000, close values are not clamped (factors in the HIGH 32s)
        // Long 1: -2^62 - (2^31-1)^2 -> 8000_0000_FFFF_FFFF (close, not clamped)
        // Long 0: (-2^62 - 1) - (-2^31)(-2^31) -> 8000_0000_0000_0000 (over by one)
        check("SLMSHS 3", {2'b10, 3'b111, 5'd3, 5'd2, 5'd1, 5'd3},
            128'hC000_0000_0000_0000_BFFF_FFFF_FFFF_FFFF,
            128'h7FFF_FFFF_0000_0000_8000_0000_0000_0000,
            128'h7FFF_FFFF_0000_0000_8000_0000_0000_0000,
            128'h8000_0000_FFFF_FFFF_8000_0000_0000_0000, 1'b1);

        // d) exactly max/min (not clamped), the unused half holds large values so using the wrong half changes the result (factors in the HIGH 32s)
        // Long 1: 4000_0000_7FFF_FFFF - (2^31-1)(-2^31) -> 7FFF_FFFF_FFFF_FFFF (exactly max)
        // Long 0: -2^62 - (-2^31)(-2^31) -> 8000_0000_0000_0000 (exactly min)
        check("SLMSHS 4", {2'b10, 3'b111, 5'd3, 5'd2, 5'd1, 5'd4},
            128'h4000_0000_7FFF_FFFF_C000_0000_0000_0000,
            128'h8000_0000_8000_0000_8000_0000_7FFF_FFFF,
            128'h7FFF_FFFF_8000_0000_8000_0000_7FFF_FFFF,
            128'h7FFF_FFFF_FFFF_FFFF_8000_0000_0000_0000, 1'b1);


        //NOP

        // a) normal: random don't-care bits (1100), register fields and data -> no write
        // any inputs -> write_en 0
        check("NOP 1", {2'b11, 4'b1100, 4'b0000, 5'd10, 5'd1, 5'd5},
            128'h3044_15EB_1A10_D3D5_68F9_CFFB_FFE2_7F90,
            128'hA636_BEB2_F4BD_2EEA_B0C9_2377_5E24_D383,
            128'h64E0_75F4_4806_AA98_FBA4_CD3B_2647_74E1,
            '0, 1'b0);


        //ABSDB

        // a) normal: random bytes (rs1 > rs2, rs1 < rs2 and one equal pair)
        // rs1: 51 A3 B0 D6 BE F5 5E D4 EE 9F 5E 18 DD 59 DB 2B
        // rs2: 51 02 A7 9B 4A 7A B0 B0 02 0E 80 08 B8 C7 C6 9F
        // -> 00 A1 09 3B 74 7B 52 24 EC 91 22 10 25 6E 15 74
        check("ABSDB 1", {2'b11, 4'b0000, 4'b0001, 5'd2, 5'd1, 5'd6},
            128'h51A3_B0D6_BEF5_5ED4_EE9F_5E18_DD59_DB2B,
            128'h5102_A79B_4A7A_B0B0_020E_8008_B8C7_C69F,
            '0,
            128'h00A1_093B_747B_5224_EC91_2210_256E_1574, 1'b1);

        // b) unsigned: answers only right for unsigned bytes, don't-care 1111
        // 00 vs FF -> FF (signed: 01) | 80 vs 7F -> 01 (signed: FF)
        // FF vs FF, 00 vs 00 -> 00 | 01 vs FE -> FD
        check("ABSDB 2", {2'b11, 4'b1111, 4'b0001, 5'd2, 5'd1, 5'd7},
            128'h00FF_807F_FF00_7F80_FFFF_0000_01FE_FE01,
            128'hFF00_7F80_00FF_807F_FFFF_0000_FE01_01FE,
            '0,
            128'hFFFF_0101_FFFF_0101_0000_0000_FDFD_FDFD, 1'b1);


        //AU

        // a) normal: random words, no carries out of any lane
        // Word 3: 3F55_4031 + 63B0_2103 -> A305_6134
        // Word 2: E0F4_00E9 + 123C_D32D -> F330_D416
        // Word 1: 2102_610F + 0E37_458B -> 2F39_A69A
        // Word 0: AE8C_74FA + 4C56_90B4 -> FAE3_05AE
        check("AU 1", {2'b11, 4'b0000, 4'b0010, 5'd2, 5'd1, 5'd8},
            128'h3F55_4031_E0F4_00E9_2102_610F_AE8C_74FA,
            128'h63B0_2103_123C_D32D_0E37_458B_4C56_90B4,
            '0,
            128'hA305_6134_F330_D416_2F39_A69A_FAE3_05AE, 1'b1);

        // b) wrap: no saturation of either kind
        // Word 3: FFFF_FFFF + 1 -> 0000_0000 (unsigned sat: FFFF_FFFF)
        // Word 2: FFFF_FFFF + FFFF_FFFF -> FFFF_FFFE
        // Word 1: 8000_0000 + 8000_0000 -> 0000_0000
        // Word 0: 7FFF_FFFF + 1 -> 8000_0000 (signed sat: 7FFF_FFFF)
        check("AU 2", {2'b11, 4'b0000, 4'b0010, 5'd2, 5'd1, 5'd9},
            128'hFFFF_FFFF_FFFF_FFFF_8000_0000_7FFF_FFFF,
            128'h0000_0001_FFFF_FFFF_8000_0000_0000_0001,
            '0,
            128'h0000_0000_FFFF_FFFE_0000_0000_8000_0000, 1'b1);

        // c) lane isolation: carries out of Word 0, Word 1, Word 2 must not reach the next lane
        // Word 2, Word 1, Word 0: FFFF_FFFF + 1 -> 0
        // Word 3: 0 + 0 -> 0 (a 128-bit add gives 1s)
        check("AU 3", {2'b11, 4'b0000, 4'b0010, 5'd2, 5'd1, 5'd10},
            128'h0000_0000_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF,
            128'h0000_0000_0000_0001_0000_0001_0000_0001,
            '0,
            '0, 1'b1);

        // d) carry ripple inside a lane, don't-care 1111
        // Word 3: 0000_FFFF + 1 -> 0001_0000
        // Word 2: 00FF_FFFF + 1 -> 0100_0000
        // Word 1: 0000_00FF + 1 -> 0000_0100
        // Word 0: 1234_5678 + EDCB_A988 -> 0000_0000
        check("AU 4", {2'b11, 4'b1111, 4'b0010, 5'd2, 5'd1, 5'd11},
            128'h0000_FFFF_00FF_FFFF_0000_00FF_1234_5678,
            128'h0000_0001_0000_0001_0000_0001_EDCB_A988,
            '0,
            128'h0001_0000_0100_0000_0000_0100_0000_0000, 1'b1);


        //CNT1W

        // a) normal: random words
        // Word 3: 8983_E197 -> 15
        // Word 2: 4389_DF2C -> 16
        // Word 1: FE72_68AA -> 18
        // Word 0: 9F68_CC14 -> 15
        check("CNT1W 1", {2'b11, 4'b0000, 4'b0011, 5'd2, 5'd1, 5'd12},
            128'h8983_E197_4389_DF2C_FE72_68AA_9F68_CC14,
            '0, '0,
            128'h0000_000F_0000_0010_0000_0012_0000_000F, 1'b1);

        // b) edge: extremes (32 needs 6 bits)
        // Word 3: 0000_0000 -> 0
        // Word 2: FFFF_FFFF -> 32 (0x20)
        // Word 1: 8000_0000 -> 1
        // Word 0: 0000_0001 -> 1
        check("CNT1W 2", {2'b11, 4'b0000, 4'b0011, 5'd2, 5'd1, 5'd13},
            128'h0000_0000_FFFF_FFFF_8000_0000_0000_0001,
            '0, '0,
            128'h0000_0000_0000_0020_0000_0001_0000_0001, 1'b1);


        //AHS

        // a) normal: random halfwords, mixed signs, no saturation
        // Half 7: -2305 + 16204 = 13899 -> 364B
        // Half 6: 1673 + 6053 = 7726 -> 1E2E
        // Half 5: 6195 + -1556 = 4639 -> 121F
        // Half 4: -15672 + -7861 = -23533 -> A413
        // Half 3: -12309 + 4702 = -7607 -> E249
        // Half 2: 2977 + -9141 = -6164 -> E7EC
        // Half 1: -4441 + -6568 = -11009 -> D4FF
        // Half 0: -12323 + 4059 = -8264 -> DFB8
        check("AHS 1", {2'b11, 4'b0000, 4'b0100, 5'd2, 5'd1, 5'd14},
            128'hF6FF_0689_1833_C2C8_CFEB_0BA1_EEA7_CFDD,
            128'h3F4C_17A5_F9EC_E14B_125E_DC4B_E658_0FDB,
            '0,
            128'h364B_1E2E_121F_A413_E249_E7EC_D4FF_DFB8, 1'b1);

        // b) positive saturation: overflow clamps to 7FFF, close values are not clamped
        // Half 7: 7FFF+0001 -> 7FFF (over by one)
        // Half 6: 7FFF+7FFF -> 7FFF
        // Half 5: 4000+4000 -> 7FFF (over by one)
        // Half 4: 7000+0FFE -> 7FFE (close, not clamped)
        // Half 3: 3FFF+3FFF -> 7FFE (close, not clamped)
        // Half 2: 7F00+00FE -> 7FFE (close, not clamped)
        // Half 1: 7FFF+FFFF -> 7FFE (mixed signs can't overflow)
        // Half 0: 0001+7FFF -> 7FFF (over by one)
        check("AHS 2", {2'b11, 4'b0000, 4'b0100, 5'd2, 5'd1, 5'd15},
            128'h7FFF_7FFF_4000_7000_3FFF_7F00_7FFF_0001,
            128'h0001_7FFF_4000_0FFE_3FFF_00FE_FFFF_7FFF,
            '0,
            128'h7FFF_7FFF_7FFF_7FFE_7FFE_7FFE_7FFE_7FFF, 1'b1);

        // c) negative saturation: overflow clamps to 8000, close values are not clamped
        // Half 7: 8000+FFFF -> 8000 (over by one)
        // Half 6: 8000+8000 -> 8000
        // Half 5: C000+BFFF -> 8000 (over by one)
        // Half 4: C001+C000 -> 8001 (close, not clamped)
        // Half 3: 8002+FFFF -> 8001 (close, not clamped)
        // Half 2: 8100+FF01 -> 8001 (close, not clamped)
        // Half 1: 8000+7FFF -> FFFF (mixed signs can't overflow)
        // Half 0: 8000+0001 -> 8001
        check("AHS 3", {2'b11, 4'b0000, 4'b0100, 5'd2, 5'd1, 5'd16},
            128'h8000_8000_C000_C001_8002_8100_8000_8000,
            128'hFFFF_8000_BFFF_C000_FFFF_FF01_7FFF_0001,
            '0,
            128'h8000_8000_8000_8001_8001_8001_FFFF_8001, 1'b1);

        // d) exactly max/min (not clamped), positive -> negative, negative -> positive, carries don't cross halfwords
        // Half 7: FFFF+0001 -> 0000 (carry out dropped)
        // Half 6: 7FFE+0001 -> 7FFF (exactly max)
        // Half 5: 3FFF+4000 -> 7FFF (exactly max)
        // Half 4: 0005+FFF0 -> FFF5 (positive -> negative)
        // Half 3: FFF0+0020 -> 0010 (negative -> positive)
        // Half 2: C000+C000 -> 8000 (exactly min)
        // Half 1: 8001+FFFF -> 8000 (exactly min)
        // Half 0: FFFF+FFFF -> FFFE (carry out dropped)
        check("AHS 4", {2'b11, 4'b1111, 4'b0100, 5'd2, 5'd1, 5'd17},
            128'hFFFF_7FFE_3FFF_0005_FFF0_C000_8001_FFFF,
            128'h0001_0001_4000_FFF0_0020_C000_FFFF_FFFF,
            '0,
            128'h0000_7FFF_7FFF_FFF5_0010_8000_8000_FFFE, 1'b1);


        //AND

        // a) normal: random values, the lowest nibble is C (1100) & A (1010), which covers all 4 input combinations
        // C697_CD0B_90B1_9163_1FB5_6EB0_F429_766C
        // & B0A7_5901_1D9D_0637_45B1_64C5_5BC1_7D3A
        // -> 8087_4901_1091_0023_05B1_6480_5001_7428
        check("AND 1", {2'b11, 4'b0000, 4'b0101, 5'd2, 5'd1, 5'd18},
            128'hC697_CD0B_90B1_9163_1FB5_6EB0_F429_766C,
            128'hB0A7_5901_1D9D_0637_45B1_64C5_5BC1_7D3A,
            '0,
            128'h8087_4901_1091_0023_05B1_6480_5001_7428, 1'b1);


        //BCW

        // a) normal: random words in rs1
        // rs1[31:0] = 7222_15B6 -> 7222_15B6 in all 4 words
        check("BCW 1", {2'b11, 4'b0000, 4'b0110, 5'd2, 5'd1, 5'd19},
            128'h9AAE_91EC_4117_D868_FD64_E04D_7222_15B6,
            '0, '0,
            128'h7222_15B6_7222_15B6_7222_15B6_7222_15B6, 1'b1);


        //MAXWS

        // a) normal: random signed words, the larger value comes from rs1 in some words and rs2 in others
        // Word 3: max(13491325, 977660184) -> 3A45_E918
        // Word 2: max(-1720928492, -1691345920) -> 9B30_1C00
        // Word 1: max(-1522055417, -1346757899) -> AFBA_1AF5
        // Word 0: max(1208956063, -1423190723) -> 480F_349F
        check("MAXWS 1", {2'b11, 4'b0000, 4'b0111, 5'd2, 5'd1, 5'd20},
            128'h00CD_DC7D_996C_B714_A547_4707_480F_349F,
            128'h3A45_E918_9B30_1C00_AFBA_1AF5_AB2B_D53D,
            '0,
            128'h3A45_E918_9B30_1C00_AFBA_1AF5_480F_349F, 1'b1);

        // b) signed compare: only right if the compare is signed
        // Word 3: max(8000_0000, 7FFF_FFFF) -> 7FFF_FFFF
        // Word 2: max(FFFF_FFFF, 0) -> 0
        // Word 1: max(8000_0000, 8000_0001) -> 8000_0001
        // Word 0: max(7FFF_FFFF, 7FFF_FFFE) -> 7FFF_FFFF
        check("MAXWS 2", {2'b11, 4'b0000, 4'b0111, 5'd2, 5'd1, 5'd21},
            128'h8000_0000_FFFF_FFFF_8000_0000_7FFF_FFFF,
            128'h7FFF_FFFF_0000_0000_8000_0001_7FFF_FFFE,
            '0,
            128'h7FFF_FFFF_0000_0000_8000_0001_7FFF_FFFF, 1'b1);


        //MINWS

        // a) normal: random signed words, the smaller value comes from rs1 in some words and rs2 in others
        // Word 3: min(-1326401758, -291982505) -> B0F0_B722
        // Word 2: min(1727125884, -1372137643) -> AE36_D755
        // Word 1: min(996675331, 1838545266) -> 3B68_0F03
        // Word 0: min(1201817482, 1522772494) -> 47A2_478A
        check("MINWS 1", {2'b11, 4'b0000, 4'b1000, 5'd2, 5'd1, 5'd22},
            128'hB0F0_B722_66F1_D97C_3B68_0F03_47A2_478A,
            128'hEE98_B357_AE36_D755_6D95_F972_5AC3_AA0E,
            '0,
            128'hB0F0_B722_AE36_D755_3B68_0F03_47A2_478A, 1'b1);

        // b) signed compare, don't-care 0001 (bit 19 set, must still decode as MINWS)
        // Word 3: min(8000_0000, 7FFF_FFFF) -> 8000_0000
        // Word 2: min(FFFF_FFFF, 0) -> FFFF_FFFF
        // Word 1: min(8000_0000, 8000_0001) -> 8000_0000
        // Word 0: min(7FFF_FFFF, 7FFF_FFFE) -> 7FFF_FFFE
        check("MINWS 2", {2'b11, 4'b0001, 4'b1000, 5'd2, 5'd1, 5'd23},
            128'h8000_0000_FFFF_FFFF_8000_0000_7FFF_FFFF,
            128'h7FFF_FFFF_0000_0000_8000_0001_7FFF_FFFE,
            '0,
            128'h8000_0000_FFFF_FFFF_8000_0000_7FFF_FFFE, 1'b1);


        //MLHU

        // a) normal: random low halves
        // Word 3: 2D01*5805 -> 0F79_3905
        // Word 2: D2A4*34F3 -> 2B91_41AC
        // Word 1: 9F4F*2974 -> 19CB_D6CC
        // Word 0: 9B03*1928 -> 0F3B_8378
        check("MLHU 1", {2'b11, 4'b0000, 4'b1001, 5'd2, 5'd1, 5'd24},
            128'h0000_2D01_0000_D2A4_0000_9F4F_0000_9B03,
            128'h0000_5805_0000_34F3_0000_2974_0000_1928,
            '0,
            128'h0F79_3905_2B91_41AC_19CB_D6CC_0F3B_8378, 1'b1);

        // b) unsigned: every lane is wrong if the multiply is signed
        // Word 3: FFFF*FFFF -> FFFE_0001
        // Word 2: 8000*0002 -> 0001_0000
        // Word 1: FFFF*0001 -> 0000_FFFF
        // Word 0: FFFF*0002 -> 0001_FFFE
        check("MLHU 2", {2'b11, 4'b0000, 4'b1001, 5'd2, 5'd1, 5'd25},
            128'h0000_FFFF_0000_8000_0000_FFFF_0000_FFFF,
            128'h0000_FFFF_0000_0002_0000_0001_0000_0002,
            '0,
            128'hFFFE_0001_0001_0000_0000_FFFF_0001_FFFE, 1'b1);


        //MLHCU

        // a) normal: C = instruction[14:10] = 25
        // Word 3: B4B6*25 -> 0011_A5C6
        // Word 2: 0FF2*25 -> 0001_8EA2
        // Word 1: A9BD*25 -> 0010_9375
        // Word 0: D529*25 -> 0014_D101
        check("MLHCU 1", {2'b11, 4'b0000, 4'b1010, 5'd25, 5'd7, 5'd26},
            128'h0000_B4B6_0000_0FF2_0000_A9BD_0000_D529,
            '0, '0,
            128'h0011_A5C6_0001_8EA2_0010_9375_0014_D101, 1'b1);


        //OR

        // a) normal: random values, the lowest nibble is C (1100) | A (1010), which covers all 4 input combinations
        // A2FA_3C6B_8193_EB5F_48D7_9B64_5FB6_469C
        // | DD43_91F5_0D25_A55D_D9FB_3219_D96E_A88A
        // -> FFFB_BDFF_8DB7_EF5F_D9FF_BB7D_DFFE_EE9E
        check("OR 1", {2'b11, 4'b0000, 4'b1011, 5'd2, 5'd1, 5'd27},
            128'hA2FA_3C6B_8193_EB5F_48D7_9B64_5FB6_469C,
            128'hDD43_91F5_0D25_A55D_D9FB_3219_D96E_A88A,
            '0,
            128'hFFFB_BDFF_8DB7_EF5F_D9FF_BB7D_DFFE_EE9E, 1'b1);


        //CNTLZ

        // a) normal: random words, highest 1 bit at random positions
        // Word 3: 0000_1ED4 -> 19
        // Word 2: 0000_07A2 -> 21
        // Word 1: 0BF8_8085 -> 4
        // Word 0: 0000_005A -> 25
        check("CNTLZ 1", {2'b11, 4'b0000, 4'b1100, 5'd2, 5'd1, 5'd28},
            128'h0000_1ED4_0000_07A2_0BF8_8085_0000_005A,
            '0, '0,
            128'h0000_0013_0000_0015_0000_0004_0000_0019, 1'b1);

        // b) edge: extremes (32 needs 6 bits)
        // Word 3: 0000_0000 -> 32 (0x20)
        // Word 2: 8000_0000 -> 0
        // Word 1: 0000_0001 -> 31 (0x1F)
        // Word 0: FFFF_FFFF -> 0
        check("CNTLZ 2", {2'b11, 4'b0000, 4'b1100, 5'd2, 5'd1, 5'd29},
            128'h0000_0000_8000_0000_0000_0001_FFFF_FFFF,
            '0, '0,
            128'h0000_0020_0000_0000_0000_001F_0000_0000, 1'b1);

        // c) edge: 1s below the leading 1 don't count, don't-care 1111
        // Word 3: 0000_0003 -> 30 (0x1E)
        // Word 2: 0001_FFFF -> 15
        // Word 1: 07FF_FFFF -> 5
        // Word 0: 1000_0001 -> 3
        check("CNTLZ 3", {2'b11, 4'b1111, 4'b1100, 5'd2, 5'd1, 5'd30},
            128'h0000_0003_0001_FFFF_07FF_FFFF_1000_0001,
            '0, '0,
            128'h0000_001E_0000_000F_0000_0005_0000_0003, 1'b1);


        //ROTW

        // a) normal: random data, a different amount in every word
        // Word 3: 65C6_FFFC ror 5 -> E32E_37FF
        // Word 2: 42EA_A048 ror 13 -> 0242_1755
        // Word 1: BE0B_A014 ror 6 -> 52F8_2E80
        // Word 0: E775_55C2 ror 29 -> 3BAA_AE17
        check("ROTW 1", {2'b11, 4'b0000, 4'b1101, 5'd2, 5'd1, 5'd31},
            128'h65C6_FFFC_42EA_A048_BE0B_A014_E775_55C2,
            128'h0000_0005_0000_000D_0000_0006_0000_001D,
            '0,
            128'hE32E_37FF_0242_1755_52F8_2E80_3BAA_AE17, 1'b1);

        // b) edge: amount extremes (0, 31, 16) and the LSB wrapping to the MSB
        // Word 3: CAFE_F00D ror 0 -> CAFE_F00D
        // Word 2: 8000_0001 ror 31 -> 0000_0003
        // Word 1: 1234_ABCD ror 16 -> ABCD_1234
        // Word 0: 0000_0001 ror 1 -> 8000_0000
        check("ROTW 2", {2'b11, 4'b0000, 4'b1101, 5'd2, 5'd1, 5'd1},
            128'hCAFE_F00D_8000_0001_1234_ABCD_0000_0001,
            128'h0000_0000_0000_001F_0000_0010_0000_0001,
            '0,
            128'hCAFE_F00D_0000_0003_ABCD_1234_8000_0000, 1'b1);

        // c) edge: only the low 5 bits of each rs2 word are the amount
        // Word 3: 0F0F_00FF ror 0x24 (4) -> F0F0_F00F
        // Word 2: A5A5_0F0F ror FFFF_FFE0 (0) -> A5A5_0F0F
        // Word 1: 0000_0001 ror 0x3F (31) -> 0000_0002
        // Word 0: 1122_3344 ror 1234_5688 (8) -> 4411_2233
        check("ROTW 3", {2'b11, 4'b0000, 4'b1101, 5'd2, 5'd1, 5'd2},
            128'h0F0F_00FF_A5A5_0F0F_0000_0001_1122_3344,
            128'h0000_0024_FFFF_FFE0_0000_003F_1234_5688,
            '0,
            128'hF0F0_F00F_A5A5_0F0F_0000_0002_4411_2233, 1'b1);


        //SFWU

        // a) normal: random words, rs2 > rs1 (no wrap), lines show rs2 - rs1
        // Word 3: 237F_4DEF - 1C6C_31C7 -> 0713_1C28
        // Word 2: EA3B_992C - 6C09_1150 -> 7E32_87DC
        // Word 1: A4E3_03AF - 60CA_53F1 -> 4418_AFBE
        // Word 0: 1723_EE6C - 01AC_0FEB -> 1577_DE81
        check("SFWU 1", {2'b11, 4'b0000, 4'b1110, 5'd2, 5'd1, 5'd3},
            128'h1C6C_31C7_6C09_1150_60CA_53F1_01AC_0FEB,
            128'h237F_4DEF_EA3B_992C_A4E3_03AF_1723_EE6C,
            '0,
            128'h0713_1C28_7E32_87DC_4418_AFBE_1577_DE81, 1'b1);

        // b) wrap and lane isolation: rs1 > rs2, borrows must not leak upward
        // Word 3: DEAD_BEEF - DEAD_BEEF -> 0
        // Word 2: 0 - 1 -> FFFF_FFFF
        // Word 1: 5 - A -> FFFF_FFFB
        // Word 0: 0 - 8000_0000 -> 8000_0000
        check("SFWU 2", {2'b11, 4'b0000, 4'b1110, 5'd2, 5'd1, 5'd4},
            128'hDEAD_BEEF_0000_0001_0000_000A_8000_0000,
            128'hDEAD_BEEF_0000_0000_0000_0005_0000_0000,
            '0,
            128'h0000_0000_FFFF_FFFF_FFFF_FFFB_8000_0000, 1'b1);


        //SFHS

        // a) normal: random halfwords, mixed signs, no saturation, lines show rs2 - rs1
        // Half 7: -3609 - 7473 = -11082 -> D4B6
        // Half 6: -4567 - 6498 = -11065 -> D4C7
        // Half 5: -6508 - -12343 = 5835 -> 16CB
        // Half 4: -7704 - -483 = -7221 -> E3CB
        // Half 3: 11940 - -14887 = 26827 -> 68CB
        // Half 2: -9826 - -1939 = -7887 -> E131
        // Half 1: -6627 - -15964 = 9337 -> 2479
        // Half 0: 12650 - -14896 = 27546 -> 6B9A
        check("SFHS 1", {2'b11, 4'b0000, 4'b1111, 5'd2, 5'd1, 5'd5},
            128'h1D31_1962_CFC9_FE1D_C5D9_F86D_C1A4_C5D0,
            128'hF1E7_EE29_E694_E1E8_2EA4_D99E_E61D_316A,
            '0,
            128'hD4B6_D4C7_16CB_E3CB_68CB_E131_2479_6B9A, 1'b1);

        // b) saturation in every lane, alternating directions
        // Half 7: 7FFF-FFFF -> 7FFF
        // Half 6: 8000-0001 -> 8000
        // Half 5: 0000-8000 -> 7FFF (rs2 + (-rs1) gets this wrong)
        // Half 4: 8000-7FFF -> 8000
        // Half 3: 7FFF-8000 -> 7FFF
        // Half 2: 4000-C000 -> 7FFF
        // Half 1: BFFF-4000 -> 8000
        // Half 0: 1000-9000 -> 7FFF
        check("SFHS 2", {2'b11, 4'b0000, 4'b1111, 5'd2, 5'd1, 5'd6},
            128'hFFFF_0001_8000_7FFF_8000_C000_4000_9000,
            128'h7FFF_8000_0000_8000_7FFF_4000_BFFF_1000,
            '0,
            128'h7FFF_8000_7FFF_8000_7FFF_7FFF_8000_7FFF, 1'b1);

        // c) exact limits (must not saturate) and zeros
        // Half 7: 7FFE-FFFF -> 7FFF exactly
        // Half 6: 8001-0001 -> 8000 exactly
        // Half 5: FFFF-8000 -> 7FFF exactly
        // Half 4: C000-4000 -> 8000 exactly
        // Half 3: 0000-7FFF -> 8001
        // Half 2: 8000-8000 -> 0
        // Half 1: 7FFF-7FFF -> 0
        // Half 0: FFFF-0000 -> FFFF
        check("SFHS 3", {2'b11, 4'b0000, 4'b1111, 5'd2, 5'd1, 5'd7},
            128'hFFFF_0001_8000_4000_7FFF_8000_7FFF_0000,
            128'h7FFE_8001_FFFF_C000_0000_8000_7FFF_FFFF,
            '0,
            128'h7FFF_8000_7FFF_8000_8001_0000_0000_FFFF, 1'b1);

        // Summary (only reached if every test passed)
        $display("------------------------------------------------");
        $display("%0d tests, %0d errors -> %s", num_tests, num_errors,
                 (num_errors == 0) ? "ALL PASSED" : "FAILURES");
        $display("------------------------------------------------");
        $finish;
    end

endmodule