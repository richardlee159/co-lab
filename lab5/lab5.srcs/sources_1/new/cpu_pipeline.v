`timescale 1ns / 1ps

// `include "function_units.v"

module cpu_pipeline(
    input clk,
    input rst
    );
 
    /* ---------- CONTROL ---------- */

    wire [1:0] ALUOp, IDEX_ALUOp;
    wire ALUSrc, RegDst, Branch, Jump, MemRead, MemWrite, MemtoReg, RegWrite,
        IDEX_ALUSrc, IDEX_RegDst,
            IDEX_Branch, IDEX_MemRead, IDEX_MemWrite,
                IDEX_MemtoReg, IDEX_RegWrite,
            EXMEM_Branch, EXMEM_MemRead, EXMEM_MemWrite,
                EXMEM_MemtoReg, EXMEM_RegWrite,
                MEMWB_MemtoReg, MEMWB_RegWrite;

    register #(9) IDEX_CTRL(
        .q({IDEX_ALUOp,IDEX_ALUSrc,IDEX_RegDst,IDEX_Branch,IDEX_MemRead,IDEX_MemWrite,IDEX_MemtoReg,IDEX_RegWrite}),
        .d({ALUOp,ALUSrc,RegDst,Branch,Jump,MemRead,MemWrite,MemtoReg,RegWrite}),
        .clk(clk), .rst(rst), .en(1'b1)
    );
    register #(5) EXMEM_CTRL(
        .q({EXMEM_Branch,EXMEM_MemRead,EXMEM_MemWrite,EXMEM_MemtoReg,EXMEM_RegWrite}),
        .d({IDEX_Branch,IDEX_MemRead,IDEX_MemWrite,IDEX_MemtoReg,IDEX_RegWrite}),
        .clk(clk), .rst(rst), .en(1'b1)
    );
    register #(2) MEMWB_CTRL(
        .q({MEMWB_MemtoReg,MEMWB_RegWrite}),
        .d({EXMEM_MemtoReg,EXMEM_RegWrite}),
        .clk(clk), .rst(rst), .en(1'b1)
    );
    
    /* ---------- DATAPATH ---------- */

    wire [31:0] IFID_ir, IFID_npc,
            IDEX_a, IDEX_b, IDEX_imm, IDEX_npc, IDEX_jaddr,
            EXMEM_b, EXMEM_aluout, EXMEM_npc,
            MEMWB_memout, MEMWB_aluout;
    wire [4:0] IDEX_rs, IDEX_rt, IDEX_rd,
            EXMEM_wa,
            MEMWB_wa;
    wire EXMEM_zero;

    wire [31:0] pc, nextpc, imemout, rfrd1, rfrd2, aluout, dmemout;
    wire [2:0] alum;
    wire zero, PCSrc;
    
    assign nextpc = PCSrc ? EXMEM_npc : (Jump ? {IFID_npc[31:28],IFID_ir[25:0],2'b00} : pc + 4);
    register PC(.q(pc), .d(nextpc), .clk(clk), .rst(rst), .en(1'b1));
    
    // IF
    imem_256x32 IMEM(.a(pc[9:2]), .spo(imemout));
    register IFID_IR(.q(IFID_ir), .d(imemout), .clk(clk), .rst(rst), .en(1'b1));
    register IFID_NPC(.q(IFID_npc), .d(pc + 4), .clk(clk), .rst(rst), .en(1'b1));

    // ID & WB
    register_file REGFILE(
        .rd1(rfrd1), .rd2(rfrd2), .wd(MEMWB_MemtoReg ? MEMWB_memout : MEMWB_aluout),
        .ra1(IFID_ir[25:21]), .ra2(IFID_ir[20:16]), .wa(MEMWB_wa),
        .clk(clk), .we(MEMWB_RegWrite)
    );
    register IDEX_A(.q(IDEX_a), .d(rfrd1), .clk(clk), .rst(rst), .en(1'b1));
    register IDEX_B(.q(IDEX_b), .d(rfrd2), .clk(clk), .rst(rst), .en(1'b1));
    register IDEX_IMM(
        .q(IDEX_imm), .d({{16{IFID_ir[15]}},IFID_ir[15:0]}),
        .clk(clk), .rst(rst), .en(1'b1)
    );
    register #(15) IDEX_RS(
        .q({IDEX_rs,IDEX_rt,IDEX_rd}), .d(IFID_ir[25:11]),
        .clk(clk), .rst(rst), .en(1'b1)
    );
    register IDEX_NPC(.q(IDEX_npc), .d(IFID_npc), .clk(clk), .rst(rst), .en(1'b1));
//    register IDEX_JADDR(
//        .q(IDEX_jaddr), .d({IFID_npc[31:28],IFID_ir[25:0],2'b00}),
//        .clk(clk), .rst(rst), .en(1'b1)
//    );

    control CONTROL(
        .opcode(IFID_ir[31:26]),
        .ALUOp(ALUOp), .ALUSrc(ALUSrc), .RegDst(RegDst),
        .Branch(Branch), .Jump(Jump), .MemRead(MemRead), .MemWrite(MemWrite),
        .MemtoReg(MemtoReg), .RegWrite(RegWrite)
    );

    // EX
    alu ALU(
        .y(aluout),
        .zf(zero),
        .a(IDEX_a),
        .b(IDEX_ALUSrc ? IDEX_imm : IDEX_b),
        .m(alum)
    );
    register EXMEM_ALUOut(.q(EXMEM_aluout), .d(aluout), .clk(clk), .rst(rst), .en(1'b1));
    register #(1) EXMEM_Zero(.q(EXMEM_zero), .d(zero), .clk(clk), .rst(rst), .en(1'b1));
    register EXMEM_B(.q(EXMEM_b), .d(IDEX_b), .clk(clk), .rst(rst), .en(1'b1));
    register #(5) EXMEM_WA(
        .q(EXMEM_wa), .d(IDEX_RegDst ? IDEX_rd : IDEX_rt),
        .clk(clk), .rst(rst), .en(1'b1)
    );
    register EXMEM_NPC(
        .q(EXMEM_npc), .d(IDEX_npc + IDEX_imm << 2),
        .clk(clk), .rst(rst), .en(1'b1)
    );

    alucontrol ALUCTRL(.ALUOp(IDEX_ALUOp), .funct(IDEX_imm[5:0]), .ALUm(alum));

    // MEM
    assign PCSrc = EXMEM_Branch & EXMEM_zero;
    dmem_256x32 DMEM(
        .a(EXMEM_aluout[9:2]), .d(EXMEM_b),
        .clk(clk), .we(EXMEM_MemWrite), .spo(dmemout)
    );
    register MEMWB_MEMOut(.q(MEMWB_memout), .d(dmemout), .clk(clk), .rst(rst), .en(1'b1));
    register MEMWB_ALUOut(.q(MEMWB_aluout), .d(EXMEM_aluout), .clk(clk), .rst(rst), .en(1'b1));
    register #(5) MEMWB_WA(.q(MEMWB_wa), .d(EXMEM_wa), .clk(clk), .rst(rst), .en(1'b1));    

endmodule
/*
register NAME(.q(), .d(), .clk(clk), .rst(rst), .en(1'b1));
*/

`define RTYPE 6'b000000
`define ADDI  6'b001000
`define LW    6'b100011
`define SW    6'b101011
`define BEQ   6'b000100
`define J     6'b000010

module control(
    input [5:0] opcode,
    output reg [1:0] ALUOp,
    output reg ALUSrc, RegDst, Branch, Jump, MemRead, MemWrite, MemtoReg, RegWrite
    );
    always @(*) begin
        {ALUOp,ALUSrc,RegDst,Branch,Jump,MemRead,MemWrite,MemtoReg,RegWrite} = 10'b0;
        case (opcode)
            `RTYPE: {ALUOp[1],RegDst,RegWrite} = 3'b111;
            `ADDI : {ALUSrc,RegWrite} = 2'b11;
            `LW   : {ALUSrc,MemRead,MemtoReg,RegWrite} = 4'b1111;
            `SW   : {ALUSrc,MemWrite} = 2'b11;
            `BEQ  : {ALUOp[0],Branch} = 2'b11;
            `J    : {Jump} = 1'b1;
        endcase
    end
endmodule

`define FUNCT_ADD 6'b100000
`define FUNCT_SUB 6'b100010
`define FUNCT_AND 6'b100100
`define FUNCT_OR  6'b100101
`define FUNCT_XOR 6'b100110

`define ALU_ADD 3'b000
`define ALU_SUB 3'b001
`define ALU_AND 3'b010
`define ALU_OR  3'b011
`define ALU_XOR 3'b100
`define ALU_DEF 3'b111

module alucontrol(
    input [1:0] ALUOp,
    input [5:0] funct,
    output reg [2:0] ALUm
    );
    always @(*)
    case (ALUOp)
        2'b00: ALUm = `ALU_ADD;
        2'b01: ALUm = `ALU_XOR;
        2'b10: 
        case (funct)
            `FUNCT_ADD: ALUm = `ALU_ADD;
            `FUNCT_SUB: ALUm = `ALU_SUB;
            `FUNCT_AND: ALUm = `ALU_AND;
            `FUNCT_OR : ALUm = `ALU_OR;
            `FUNCT_XOR: ALUm = `ALU_XOR;
            default: ALUm = `ALU_DEF;
        endcase
        2'b11: ALUm = `ALU_DEF;
    endcase
endmodule