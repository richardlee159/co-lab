`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/05/25 18:46:25
// Design Name: 
// Module Name: cpu_multicycle
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

// `include "function_units.v"
module cpu_multicycle(
    input clk,
    input rst
    );

    /* ---------- CONTROL ---------- */

    reg PCwe, IorD, MemWrite, MemtoReg, IRWrite, RegDst,
        RegWrite, ALUSrcA, ALUSrcB, PCSource;
    reg [2:0] ALUm;
    wire Zero;
    
    

    /* ---------- DATA PATH ---------- */
    
    wire [31:0] pc, nextpc, a, b, aluout, address, memdata,
                ir, mdr, rd1, rd2, wd, addrext,
                alua, alub, aluresult, jumpaddr;
    wire [4:0] wa;
    
    assign jumpaddr = {pc[31:28], ir[25:0], 2'b00};
    mux4 PC_MUX(.y(nextpc), .x0(aluresult), .x1(aluout), .x2(jumpaddr), .s(PCSource));
    register PC(.q(pc), .d(nextpc), .clk(clk), .rst(rst), .en(PCwe));
    
    mux2 ADDR_MUX(.y(address), .x0(pc), .x1(aluout), .s(IorD));
    dist_mem_gen_512x32 MEM(
        .a(address[31:2]),
        .d(aluout),
        .spo(memdata),
        .clk(clk),
        .we(MemWrite)
    );
    register IR(.q(ir), .d(memdata), .clk(clk), .rst(rst), .en(IRWrite));
    register MDR(.q(mdr), .d(memdata), .clk(clk), .rst(rst), .en(1));
    
    mux2 #(5) WA_MUX(.y(wa), .x0(ir[20:16]), .x1(ir[15:11]), .s(RegDst));
    mux2 WD_MUX(.y(wd), .x0(aluout), .x1(mdr), .s(MemtoReg));
    register_file REGFILE(
        .rd1(rd1), .rd2(rd2), .wd(wd),
        .ra1(ir[25:21]), .ra2(ir[20:16]), .wa(wa),
        .clk(clk), .we(RegWrite)
    );
    register A(.q(a), .d(rd1), .clk(clk), .rst(rst), .en(1));
    register B(.q(b), .d(rd2), .clk(clk), .rst(rst), .en(1));
    
    signext SEXT(.dout(addrext), .din(ir[15:0]));
    mux2 ALUA_MUX(.y(alua), .x0(pc), .x1(a), .s(ALUSrcA));
    mux4 ALUB_MUX(.y(alub), .x0(b), .x1(32'd4), .x2(addrext), .x3({addrext[29:0],2'b00}), .s(ALUSrcB));
    alu ALU(.y(aluresult), .zf(Zero), .a(alua), .b(alub), .m(ALUm));
    register ALUOUT(.q(aluout), .d(aluresult), .clk(clk), .rst(rst), .en(1));

endmodule