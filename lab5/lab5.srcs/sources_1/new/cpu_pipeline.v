`timescale 1ns / 1ps


// `include "function_units.v"
// `include "control_units.v"
// `include "../ip/imem_256x32/imem_256x32_stub.v"
// `include "../ip/dmem_256x32/dmem_256x32_stub.v"

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
    wire PCWrite, IFIDWrite, noBubble, IFIDFlush, IDEXFlush, EXMEMFlush;

    register #(9) IDEX_CTRL(
        .q({IDEX_ALUOp,IDEX_ALUSrc,IDEX_RegDst,IDEX_Branch,IDEX_MemRead,IDEX_MemWrite,IDEX_MemtoReg,IDEX_RegWrite}),
        .d(noBubble ? {ALUOp,ALUSrc,RegDst,Branch,MemRead,MemWrite,MemtoReg,RegWrite} : 9'b0),
        .clk(clk), .rst(rst || IDEXFlush), .en(1'b1)
    );
    register #(5) EXMEM_CTRL(
        .q({EXMEM_Branch,EXMEM_MemRead,EXMEM_MemWrite,EXMEM_MemtoReg,EXMEM_RegWrite}),
        .d({IDEX_Branch,IDEX_MemRead,IDEX_MemWrite,IDEX_MemtoReg,IDEX_RegWrite}),
        .clk(clk), .rst(rst || EXMEMFlush), .en(1'b1)
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

    wire [31:0] pc, nextpc, imemout, rfrd1, rfrd2, rfwd,
                reala, realb, aluout, dmemout;
    wire [2:0] alum;
    wire [1:0] ForwardA, ForwardB;
    wire ForwardB_MEM;
    wire zero, PCSrc;
    
    assign nextpc = PCSrc ? EXMEM_npc : (Jump ? {IFID_npc[31:28],IFID_ir[25:0],2'b00} : pc + 4);
    register PC(.q(pc), .d(nextpc), .clk(clk), .rst(rst), .en(PCWrite));
    
    // IF Stage
    imem_256x32 IMEM(.a(pc[9:2]), .spo(imemout));
    register IFID_IR(.q(IFID_ir), .d(imemout), .clk(clk), .rst(rst || IFIDFlush), .en(IFIDWrite));
    register IFID_NPC(.q(IFID_npc), .d(pc + 4), .clk(clk), .rst(rst || IFIDFlush), .en(IFIDWrite));

    // ID & WB Stage
    register_file REGFILE(
        .rd1(rfrd1), .rd2(rfrd2), .wd(rfwd),
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

    // EX Stage
    mux4 FAMUX(.y(reala), .x0(IDEX_a), .x1(rfwd), .x2(EXMEM_aluout), .x3(), .s(ForwardA));
    mux4 FBMUX(.y(realb), .x0(IDEX_b), .x1(rfwd), .x2(EXMEM_aluout), .x3(), .s(ForwardB));

    alu ALU(
        .y(aluout), .zf(zero), .m(alum),
        .a(reala), .b(IDEX_ALUSrc ? IDEX_imm : realb)
    );
    register EXMEM_ALUOut(.q(EXMEM_aluout), .d(aluout), .clk(clk), .rst(rst), .en(1'b1));
    register #(1) EXMEM_Zero(.q(EXMEM_zero), .d(zero), .clk(clk), .rst(rst), .en(1'b1));
    register EXMEM_B(.q(EXMEM_b), .d(realb), .clk(clk), .rst(rst), .en(1'b1));
    register #(5) EXMEM_WA(
        .q(EXMEM_wa), .d(IDEX_RegDst ? IDEX_rd : IDEX_rt),
        .clk(clk), .rst(rst), .en(1'b1)
    );
    register EXMEM_NPC(
        .q(EXMEM_npc), .d(IDEX_npc + (IDEX_imm << 2)),
        .clk(clk), .rst(rst), .en(1'b1)
    );

    alucontrol ALUCTRL(.ALUOp(IDEX_ALUOp), .funct(IDEX_imm[5:0]), .ALUm(alum));

    // MEM Stage
    assign PCSrc = EXMEM_Branch & EXMEM_zero;
    dmem_256x32 DMEM(
        .a(EXMEM_aluout[9:2]), .d(ForwardB_MEM ? rfwd : EXMEM_b),
        .clk(clk), .we(EXMEM_MemWrite), .spo(dmemout)
    );
    register MEMWB_MEMOut(.q(MEMWB_memout), .d(dmemout), .clk(clk), .rst(rst), .en(1'b1));
    register MEMWB_ALUOut(.q(MEMWB_aluout), .d(EXMEM_aluout), .clk(clk), .rst(rst), .en(1'b1));
    register #(5) MEMWB_WA(.q(MEMWB_wa), .d(EXMEM_wa), .clk(clk), .rst(rst), .en(1'b1));    

    // WB Stage
    assign rfwd = MEMWB_MemtoReg ? MEMWB_memout : MEMWB_aluout;

    // Forwarding Unit
    forward FORWARD(
        ForwardA, ForwardB, ForwardB_MEM,
        IDEX_rs, IDEX_rt, EXMEM_wa, MEMWB_wa,
        EXMEM_RegWrite, MEMWB_RegWrite
    );

    // Hazard Detection Unit
    hazard HAZARD(
        .PCWrite(PCWrite), .IFIDWrite(IFIDWrite), .noBubble(noBubble),
        .IFIDFlush(IFIDFlush), .IDEXFlush(IDEXFlush), .EXMEMFlush(EXMEMFlush),
        .IFID_rs(IFID_ir[25:21]), .IFID_rt(IFID_ir[20:16]), .IDEX_rt(IDEX_rt),
        .IDEX_MemRead(IDEX_MemRead), .ExUseRs(Jump == 1'b0), .ExUseRt(ALUSrc == 1'b0),
        .Jump(Jump), .Brtaken(PCSrc)
    );
endmodule
/*
register NAME(.q(), .d(), .clk(clk), .rst(rst), .en(1'b1));
mux4 MUX(.y(), .x0(), .x1(), .x2(), .x3(), .s());
*/