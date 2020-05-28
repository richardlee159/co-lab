`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/05/27 19:00:48
// Design Name: 
// Module Name: cpu_multicycle_db
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


`define RTYPE 6'b000000
`define ADDI  6'b001000
`define LW    6'b100011
`define SW    6'b101011
`define BEQ   6'b000100
`define J     6'b000010

`define FUNCT_ADD 6'b100000

`define IF       0
`define DE       1
`define LWSW_EX  2
`define LW_MEM   3
`define LW_WB    4
`define SW_MEM   5
`define RT_EX    6
`define RT_WB    7
`define BEQ_EX   8
`define J_EX     9
`define ADDI_EX  10
`define ADDI_WB  11

`define ALU_ADD 3'b000
`define ALU_SUB 3'b001
`define ALU_AND 3'b010
`define ALU_OR  3'b011
`define ALU_XOR 3'b100

`define PC     31:0
`define IR     63:32
`define MD     95:64
`define A      127:96
`define B      159:128
`define ALUOUT 191:160
`define CTRL   207:192

module cpu_multicycle_db(
    input clk,
    input rst,
    input [7:0] m_rf_addr,
    output [31:0] m_data, rf_data,
    output [207:0] status
    );
    wire [31:0] ir;

    /* ---------- CONTROL ---------- */

    // State Register
    reg [3:0] curr_state, next_state;
    always @(posedge clk, posedge rst) begin
        if (rst) curr_state <= `IF;
        else curr_state <= next_state;
    end

    // Next State Logic
    always @(*) begin
        case (curr_state)
            `IF     : next_state = `DE;
            `DE     : 
                begin
                    case (ir[31:26])
                        `RTYPE : next_state = `RT_EX;
                        `ADDI  : next_state = `ADDI_EX;
                        `LW    : next_state = `LWSW_EX;
                        `SW    : next_state = `LWSW_EX;
                        `BEQ   : next_state = `BEQ_EX;
                        `J     : next_state = `J_EX;
                        default: next_state = `IF;
                    endcase
                end
            `LWSW_EX: next_state = (ir[31:26] == `LW) ? `LW_MEM : `SW_MEM;
            `LW_MEM : next_state = `LW_WB;
            `LW_WB  : next_state = `IF;
            `SW_MEM : next_state = `IF;
            `RT_EX  : next_state = `RT_WB;
            `RT_WB  : next_state = `IF;
            `BEQ_EX : next_state = `IF;
            `J_EX   : next_state = `IF;
            `ADDI_EX: next_state = `ADDI_WB;
            `ADDI_WB: next_state = `IF;
            default : next_state = `IF;
        endcase
    end

    // Output Logic
    reg PCwe, IorD, MemWrite, MemtoReg, IRWrite, RegDst,
        RegWrite, ALUSrcA;
    reg [1:0] ALUSrcB, PCSource;
    reg [2:0] ALUm;
    wire Zero;

    always @(*) begin
        {PCwe, IorD, MemWrite, MemtoReg, IRWrite, RegDst,
        RegWrite, ALUSrcA, ALUSrcB, PCSource, ALUm} = 15'b0;
        case (curr_state)
            `IF     : {PCwe, IRWrite, ALUSrcB, ALUm} = {4'b1101, `ALU_ADD};
            `DE     : {ALUSrcB, ALUm} = {2'b11, `ALU_ADD};
            `LWSW_EX: {ALUSrcA, ALUSrcB, ALUm} = {3'b110, `ALU_ADD};
            `LW_MEM : {IorD} = 1'b1;
            `LW_WB  : {MemtoReg, RegWrite} = 2'b11;
            `SW_MEM : {IorD, MemWrite} = 2'b11;
            `RT_EX  : 
                begin
                    ALUSrcA = 1'b1;
                    if (ir[5:0] == `FUNCT_ADD) ALUm = `ALU_ADD;
                end
            `RT_WB  : {RegDst, RegWrite} = 2'b11;
            `BEQ_EX : {PCwe, ALUSrcA, PCSource, ALUm} = {Zero, 3'b101, `ALU_XOR};
            `J_EX   : {PCwe, PCSource} = 3'b110;
            `ADDI_EX: {ALUSrcA, ALUSrcB, ALUm} = {3'b110, `ALU_ADD};
            `ADDI_WB: {RegWrite} = 1'b1;
        endcase
    end
    
    assign status[`CTRL] = {PCSource, PCwe, IorD, MemWrite, IRWrite, RegDst,
                            MemtoReg, RegWrite, ALUm, ALUSrcA, ALUSrcB, Zero};

    /* ---------- DATA PATH ---------- */
    
    wire [31:0] pc, nextpc, a, b, aluout, address, memdata,
                mdr, rd1, rd2, wd, addrext,
                alua, alub, aluresult, jumpaddr;
    wire [4:0] wa;
    
    assign jumpaddr = {pc[31:28], ir[25:0], 2'b00};
    mux4 PC_MUX(.y(nextpc), .x0(aluresult), .x1(aluout), .x2(jumpaddr), .s(PCSource));
    register PC(.q(pc), .d(nextpc), .clk(clk), .rst(rst), .en(PCwe));
    
    mux2 ADDR_MUX(.y(address), .x0(pc), .x1(aluout), .s(IorD));
    dist_mem_gen_512x32 MEM(
        .a(address[31:2]), .d(b), .spo(memdata),
        .clk(clk), .we(MemWrite),
        .dpra({1'b0, m_rf_addr}), .dpo(m_data)
    );
    register IR(.q(ir), .d(memdata), .clk(clk), .rst(rst), .en(IRWrite));
    register MDR(.q(mdr), .d(memdata), .clk(clk), .rst(rst), .en(1'b1));
    
    mux2 #(5) WA_MUX(.y(wa), .x0(ir[20:16]), .x1(ir[15:11]), .s(RegDst));
    mux2 WD_MUX(.y(wd), .x0(aluout), .x1(mdr), .s(MemtoReg));
    register_file_db REGFILE(
        .rd1(rd1), .rd2(rd2), .wd(wd),
        .ra1(ir[25:21]), .ra2(ir[20:16]), .wa(wa),
        .clk(clk), .we(RegWrite),
        .rax(m_rf_addr[4:0]), .rdx(rf_data)
    );
    register A(.q(a), .d(rd1), .clk(clk), .rst(rst), .en(1'b1));
    register B(.q(b), .d(rd2), .clk(clk), .rst(rst), .en(1'b1));
    
    signext SEXT(.dout(addrext), .din(ir[15:0]));
    mux2 ALUA_MUX(.y(alua), .x0(pc), .x1(a), .s(ALUSrcA));
    mux4 ALUB_MUX(.y(alub), .x0(b), .x1(32'd4), .x2(addrext), .x3({addrext[29:0],2'b00}), .s(ALUSrcB));
    alu ALU(.y(aluresult), .zf(Zero), .a(alua), .b(alub), .m(ALUm));
    register ALUOUT(.q(aluout), .d(aluresult), .clk(clk), .rst(rst), .en(1'b1));
    
    assign status[`PC] = pc;
    assign status[`IR] = ir;
    assign status[`MD] = mdr;
    assign status[`A] = a;
    assign status[`B] = b;
    assign status[`ALUOUT] = aluout;
endmodule
