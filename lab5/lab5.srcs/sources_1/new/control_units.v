`timescale 1ns / 1ps


`include "macros.v"

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

module forward(
    output reg [1:0] ForwardA, ForwardB,
    output reg ForwardB_MEM,
    input [4:0] IDEX_rs, IDEX_rt, EXMEM_wa, MEMWB_wa,
    input EXMEM_RegWrite, MEMWB_RegWrite
    );
    always @(*) begin
        ForwardA = 2'b00;
        ForwardB = 2'b00;
        ForwardB_MEM = 1'b0;
        if (MEMWB_RegWrite && (MEMWB_wa != 5'b0)) begin
            if (MEMWB_wa == IDEX_rs) ForwardA = 2'b01;
            if (MEMWB_wa == IDEX_rt) ForwardB = 2'b01;
            if (MEMWB_wa == EXMEM_wa) ForwardB_MEM = 1'b1;
        end
        if (EXMEM_RegWrite && (EXMEM_wa != 5'b0)) begin
            if (EXMEM_wa == IDEX_rs) ForwardA = 2'b10;
            if (EXMEM_wa == IDEX_rt) ForwardB = 2'b10;
        end
    end
endmodule

module hazard(
    output reg PCWrite, IFIDWrite, noBubble,
    input [4:0] IFID_rs, IFID_rt, IDEX_rt,
    input IDEX_MemRead, ExUseRt
    );
    always @(*) begin
        {PCWrite,IFIDWrite,noBubble} = 3'b111;
        if (IDEX_MemRead && (IDEX_rt != 5'b0) && (
                (IDEX_rt == IFID_rs) || 
                ((IDEX_rt == IFID_rt) && ExUseRt)
            )
        ) begin
            {PCWrite,IFIDWrite,noBubble} = 3'b000;
        end
    end
endmodule