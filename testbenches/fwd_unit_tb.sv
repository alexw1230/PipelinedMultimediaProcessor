`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/24/2026 11:00:34 AM
// Design Name: 
// Module Name: fwd_unit_tb
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

module fwd_unit_tb;

    // DUT signals
    logic wb_write_en;
    logic [4:0] wb_dest_reg;
    logic [4:0] ex_rs1_addr, ex_rs2_addr, ex_rs3_addr;
    logic ex_uses_rs1, ex_uses_rs2, ex_uses_rs3;
    logic fwd_rs1, fwd_rs2, fwd_rs3;

    fwd_unit dut (
        .wb_write_en(wb_write_en),
        .wb_dest_reg(wb_dest_reg),
        .ex_rs1_addr(ex_rs1_addr),
        .ex_rs2_addr(ex_rs2_addr),
        .ex_rs3_addr(ex_rs3_addr),
        .ex_uses_rs1(ex_uses_rs1),
        .ex_uses_rs2(ex_uses_rs2),
        .ex_uses_rs3(ex_uses_rs3),
        .fwd_rs1(fwd_rs1),
        .fwd_rs2(fwd_rs2),
        .fwd_rs3(fwd_rs3)
    );

    //counters
    int num_tests = 0;
    int num_errors = 0;

    //apply inputs and check outputs against known
    task automatic check(
        input string name,
        input logic we, // wb_write_en
        input logic [4:0] dest, // wb_dest_reg
        input logic [4:0] a1, // ex_rs1_addr
        input logic [4:0] a2, // ex_rs2_addr
        input logic [4:0] a3, // ex_rs3_addr
        input logic [2:0] uses, // {rs1, rs2, rs3}
        input logic [2:0] exp_fwd // {rs1, rs2, rs3}
    );
        logic ok;

        wb_write_en = we;
        wb_dest_reg = dest;
        ex_rs1_addr = a1;
        ex_rs2_addr = a2;
        ex_rs3_addr = a3;
        {ex_uses_rs1, ex_uses_rs2, ex_uses_rs3} = uses;
        #10;//wait 10 between cases

        num_tests++;

        //check if res is correct
        ok = ({fwd_rs1, fwd_rs2, fwd_rs3} === exp_fwd);

        if (ok) begin
            $display("PASS %-8s fwd=%b", name, {fwd_rs1, fwd_rs2, fwd_rs3});
        end else begin
            num_errors++;
            $display("FAIL %-8s", name);
            $display("    we=%b dest=r%0d src=r%0d r%0d r%0d uses=%b", we, dest, a1, a2, a3, uses);
            $display("    got fwd=%b", {fwd_rs1, fwd_rs2, fwd_rs3});
            $display("    exp fwd=%b", exp_fwd);

            // stop on the first failure so the waveform ends at the bad test
            $fatal(1, "Stopping: test '%s' failed (%0d of %0d run so far passed)",
                   name, num_tests - 1, num_tests);
        end
    endtask

    // Test cases
    initial begin
        wb_write_en = 1'b0;
        wb_dest_reg = '0;
        ex_rs1_addr = '0;
        ex_rs2_addr = '0;
        ex_rs3_addr = '0;
        {ex_uses_rs1, ex_uses_rs2, ex_uses_rs3} = '0;
        #1;

        //FORWARD

        // a) normal: SIMALS $4, $9, $14, $27 in EX, WB writes $14 -> forward rs2 only
        check("FWD 1", 1'b1, 5'd14, 5'd9, 5'd14, 5'd27, 3'b111, 3'b010);

        // b) normal: same SIMALS, WB writes $6 which EX does not read -> no forward
        check("FWD 2", 1'b1, 5'd6, 5'd9, 5'd14, 5'd27, 3'b111, 3'b000);

        // c) edge: match on rs1 only, rs2 $24 and rs3 $27 are each one bit away from $25
        // a compare that skips a bit would forward them too
        check("FWD 3", 1'b1, 5'd25, 5'd25, 5'd24, 5'd27, 3'b111, 3'b100);

        // d) edge: match on rs3 only, rs1 $3 and rs2 $5 share bits with $7
        check("FWD 4", 1'b1, 5'd7, 5'd3, 5'd5, 5'd7, 3'b111, 3'b001);

        // e) edge: all three sources match at once
        check("FWD 5", 1'b1, 5'd31, 5'd31, 5'd31, 5'd31, 3'b111, 3'b111);

        //NOT A REAL WRITE OR NOT A REAL SOURCE

        // a) edge: write_en 0 (a NOP in WB) with every source matching -> no forward
        check("NOFWD 1", 1'b0, 5'd9, 5'd9, 5'd9, 5'd9, 3'b111, 3'b000);

        // b) edge: MLHCU $5, $8, 5 in EX, the constant 5 sits in the rs2 field and equals the WB dest
        // only rs1 is a real source -> no forward
        check("NOFWD 2", 1'b1, 5'd5, 5'd8, 5'd5, 5'd0, 3'b100, 3'b000);

        // c) edge: AU $2, $2, $2 in EX, its rs3 slot holds opcode bits 00010 = $2 = the WB dest
        // rs1 and rs2 forward, rs3 is not a real source
        check("NOFWD 3", 1'b1, 5'd2, 5'd2, 5'd2, 5'd2, 3'b110, 3'b110);

        // Summary (only reached if every test passed)
        $display("------------------------------------------------");
        $display("%0d tests, %0d errors -> %s", num_tests, num_errors,
                 (num_errors == 0) ? "ALL PASSED" : "FAILURES");
        $display("------------------------------------------------");
        $finish;
    end

endmodule