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