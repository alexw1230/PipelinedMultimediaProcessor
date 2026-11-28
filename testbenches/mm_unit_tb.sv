`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/26/2026 10:50:38 PM
// Design Name: 
// Module Name: mm_unit_tb
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

module mm_unit_tb import pipeline_consts_pkg::*;;

    //base name of the test, the only line that changes between tests
    parameter string PROG = "main";

    // DUT signals
    logic clk;
    logic rst;
    logic done;

    mm_unit dut (
        .clk(clk),
        .rst(rst),
        .done(done)
    );

    //10ns clock
    initial clk = 1'b0;
    always #5 clk = ~clk;

    //expected registers and the results file
    logic [127:0] exp_regs [0:31];
    int fd;

    //counters
    int cycle;
    int errors;

    string R4_NAMES [0:7] = '{"SIMALS", "SIMAHS", "SIMSLS", "SIMSHS",
        "SLMALS", "SLMAHS", "SLMSLS", "SLMSHS"};
    string R3_NAMES [0:15] = '{"NOP", "ABSDB", "AU", "CNT1W", "AHS", "AND", "BCW", "MAXWS",
        "MINWS", "MLHU", "MLHCU", "OR", "CNTLZ", "ROTW", "SFWU", "SFHS"};

    //turn an instruction back into assembly, testbench only
    function automatic string disasm(input logic [24:0] i);
        logic [3:0] op;
        op = i[18:15];
        if (!i[24]) begin
            return $sformatf("LI $%0d, %0d, 0x%04h", i[4:0], i[23:21], i[20:5]);
        end
        if (!i[23]) begin
            return $sformatf("%s $%0d, $%0d, $%0d, $%0d", R4_NAMES[i[22:20]], i[4:0], i[9:5], i[14:10], i[19:15]);
        end
        if (op == 4'd0) begin
            return "NOP";
        end
        if (op == 4'd3 || op == 4'd6 || op == 4'd12) begin
            return $sformatf("%s $%0d, $%0d", R3_NAMES[op], i[4:0], i[9:5]);
        end
        if (op == 4'd10) begin
            return $sformatf("MLHCU $%0d, $%0d, %0d", i[4:0], i[9:5], i[14:10]);
        end
        return $sformatf("%s $%0d, $%0d, $%0d", R3_NAMES[op], i[4:0], i[9:5], i[14:10]);
    endfunction

    //128 bits as hex with an underscore between halfwords
    function automatic string hx(input logic [127:0] v);
        return $sformatf("%h_%h_%h_%h_%h_%h_%h_%h", v[127:112], v[111:96], v[95:80], v[79:64],
            v[63:48], v[47:32], v[31:16], v[15:0]);
    endfunction

    //one source line, a dash when the instruction does not read it
    task automatic src_line(
        input string name,
        input logic uses,
        input logic [4:0] addr,
        input string flag_name,
        input logic flag,
        input string val_name,
        input logic [127:0] val
    );
        if (uses) begin
            $fdisplay(fd, "    %s=$%0d  %s=%b %s=%s", name, addr, flag_name, flag, val_name, hx(val));
        end else begin
            $fdisplay(fd, "    %s=-", name);
        end
    endtask

    //one block per cycle, sampled at the falling edge
    task automatic log_cycle();
        $fdisplay(fd, "==== Cycle %0d  done=%b ====", cycle, done);
        $fdisplay(fd, "IF  pc=%0d instr=%h  %s", dut.if_pc, dut.if_instr, disasm(dut.if_instr));
        $fdisplay(fd, "ID  pc=%0d instr=%h  %s", dut.id_pc, dut.id_instr, disasm(dut.id_instr));
        src_line("rs1", dut.id_uses_rs1, dut.id_rs1_addr, "byp", dut.id_rs1_byp, "data", dut.id_rs1_data);
        src_line("rs2", dut.id_uses_rs2, dut.id_rs2_addr, "byp", dut.id_rs2_byp, "data", dut.id_rs2_data);
        src_line("rs3", dut.id_uses_rs3, dut.id_rs3_addr, "byp", dut.id_rs3_byp, "data", dut.id_rs3_data);
        $fdisplay(fd, "EX  pc=%0d instr=%h  %s", dut.ex_pc, dut.ex_instr, disasm(dut.ex_instr));
        src_line("rs1", dut.ex_uses_rs1, dut.ex_rs1_addr, "fwd", dut.fwd_rs1, "in", dut.u_ex.ex_alu_rs1);
        src_line("rs2", dut.ex_uses_rs2, dut.ex_rs2_addr, "fwd", dut.fwd_rs2, "in", dut.u_ex.ex_alu_rs2);
        src_line("rs3", dut.ex_uses_rs3, dut.ex_rs3_addr, "fwd", dut.fwd_rs3, "in", dut.u_ex.ex_alu_rs3);
        $fdisplay(fd, "    result=%s write_en=%b dest=$%0d", hx(dut.ex_result), dut.ex_write_en, dut.ex_dest_reg);
        $fdisplay(fd, "WB  pc=%0d instr=%h  %s", dut.wb_pc, dut.wb_instr, disasm(dut.wb_instr));
        $fdisplay(fd, "    write_en=%b dest=$%0d data=%s", dut.wb_wr_en, dut.wb_wr_addr, hx(dut.wb_wr_data));
        $fdisplay(fd, "");
    endtask

    // Test run
    initial begin
        string prog_file;
        string exp_file;
        string res_file;
        int chk;
        logic [127:0] got;

        prog_file = {PROG, ".mem"};
        exp_file = {PROG, "_exp.mem"};
        res_file = {PROG, "_results.txt"};

        //stop early if either input file is missing
        chk = $fopen(prog_file, "r");
        if (chk == 0) begin
            $fatal(1, "Cannot open %s, is it added as a simulation source", prog_file);
        end
        $fclose(chk);
        chk = $fopen(exp_file, "r");
        if (chk == 0) begin
            $fatal(1, "Cannot open %s, is it added as a simulation source", exp_file);
        end
        $fclose(chk);

        //fill the buffer with NOP, then load the program over it
        for (int k = 0; k < 64; k++) begin
            dut.u_if.u_buf.mem[k] = NOP_INSTR;
        end
        $readmemb(prog_file, dut.u_if.u_buf.mem);
        $readmemh(exp_file, exp_regs);

        fd = $fopen(res_file, "w");
        $fdisplay(fd, "Results for %s", prog_file);
        $fdisplay(fd, "");

        //two reset edges, release on a falling edge
        rst = 1'b1;
        repeat (2) @(posedge clk);
        @(negedge clk);
        rst = 1'b0;

        //cycle 1 has slot 0 in IF, log every cycle until done
        cycle = 1;
        while (!done) begin
            log_cycle();
            if (cycle == 200) begin
                $fatal(1, "done never set after 200 cycles");
            end
            @(negedge clk);
            cycle++;
        end

        //slot 63 is in ID now, log it through EX and WB
        repeat (2) begin
            log_cycle();
            @(negedge clk);
            cycle++;
        end
        log_cycle();

        //the edge that ends WB writes the last result
        @(posedge clk);
        #1;

        //compare all 32 registers, report every mismatch
        errors = 0;
        $fdisplay(fd, "==== Final registers ====");
        for (int n = 0; n < 32; n++) begin
            got = dut.u_id.u_rf.regs[n];
            if (got !== exp_regs[n]) begin
                errors++;
                $display("MISMATCH $%0d got %s exp %s", n, hx(got), hx(exp_regs[n]));
                $fdisplay(fd, "$%0d %s  MISMATCH, expected %s", n, hx(got), hx(exp_regs[n]));
            end else begin
                $fdisplay(fd, "$%0d %s", n, hx(got));
            end
        end

        $fdisplay(fd, "%s: %0d registers do not match %s", (errors == 0) ? "PASS" : "FAIL", errors, exp_file);
        $fclose(fd);

        // Summary
        $display("------------------------------------------------");
        $display("%s: 32 registers, %0d errors after %0d cycles -> %s", PROG, errors, cycle,
                 (errors == 0) ? "ALL PASSED" : "FAILURES");
        $display("results in %s", res_file);
        $display("------------------------------------------------");
        if (errors != 0) begin
            $fatal(1, "Stopping: %0d registers do not match %s", errors, exp_file);
        end
        $finish;
    end

endmodule