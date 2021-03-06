`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/05/28 19:46:05
// Design Name: 
// Module Name: Bypath_Unit\
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


module Bypath_Unit( 
    input [2:0] ID_JumpBranch,
    input [4:0] ID_rsAddr, ID_rtAddr, 
    input [4:0] EX_rsAddr, EX_rtAddr,
    input [4:0] MEM_rtAddr, MEM_wrAddr,
    input [4:0] WB_wrAddr,
    input EX_RegWrite, EX_MemWrite, 
    input [2:0] EX_JumpBranch,
    input MEM_RegWrite, MEM_MemWrite, MEM_MemtoReg, 
    input [2:0] MEM_JumpBranch,
    input WB_RegWrite, WB_MemtoReg,
    output ID_Forward1, ID_Forward2, 
    output reg [1:0] EX_ForwardA, EX_ForwardB,
    output MEM_Forwardwm
    );
    
    parameter BEQ = 3'd1, BNE = 3'd2, JR = 3'd3, J = 3'd4, JAL = 3'd7, OTHERS = 3'd0;
    
    wire EX_RILwSw = (EX_RegWrite | EX_MemWrite) && (EX_JumpBranch == OTHERS);
    wire ID_BranchJr = (ID_JumpBranch == BEQ) || (ID_JumpBranch == BNE) || (ID_JumpBranch == JR);
    wire MEM_Sw = MEM_MemWrite;
    wire MEM_RI = (MEM_RegWrite & ~MEM_MemWrite & ~MEM_MemtoReg) && (MEM_JumpBranch == OTHERS);
    wire MEM_RIJal = (MEM_RegWrite & ~MEM_MemWrite & ~MEM_MemtoReg);
    wire WB_Lw = WB_MemtoReg;
    wire WB_RILwJal = WB_RegWrite;
    
    wire MEMw_equ_IDs = (MEM_wrAddr != 0) && (MEM_wrAddr == ID_rsAddr);
    wire MEMw_equ_IDt = (MEM_wrAddr != 0) && (MEM_wrAddr == ID_rtAddr);
    wire MEMw_equ_EXs = (MEM_wrAddr != 0) && (MEM_wrAddr == EX_rsAddr);
    wire MEMw_equ_EXt = (MEM_wrAddr != 0) && (MEM_wrAddr == EX_rtAddr); 
    wire WBw_equ_EXs = (WB_wrAddr != 0) && (WB_wrAddr == EX_rsAddr);
    wire WBw_equ_EXt = (WB_wrAddr != 0) && (WB_wrAddr == EX_rtAddr);
    wire WBw_equ_MEMt = (WB_wrAddr != 0) && (WB_wrAddr == MEM_rtAddr);
   
    
    // ID_Forward
    // MEM(R / I / Jal)  -->  ID(beq / bne / jr)
    //     --- wr ---            - rs/rt -   rs
    assign ID_Forward1 = MEM_RIJal & ID_BranchJr & MEMw_equ_IDs;
    assign ID_Forward2 = MEM_RIJal & ID_BranchJr & MEMw_equ_IDt;

    // EX_Forward
    // 1. MEM(R / I)  -->  EX(R / sw / I / lw)    (higher priority)
    //       - wr -    =      -rs/rt-  --rs--
    // 2. WB(R / I / lw / Jal)  -->  EX(R / sw / I / lw)
    //       ------ wr ------    =      -rs/rt-  --rs--
    always @(*)
        begin
            // EX_ForwardA
            if(MEM_RI & EX_RILwSw & MEMw_equ_EXs)  EX_ForwardA <= 2'd1;
            else if(WB_RILwJal & EX_RILwSw & WBw_equ_EXs)  EX_ForwardA <= 2'd2;
            else EX_ForwardA <= 2'd0;
            //EX_ForwardB
            if(MEM_RI & EX_RILwSw & MEMw_equ_EXt)  EX_ForwardB <= 2'd1;
            else if(WB_RILwJal & EX_RILwSw & WBw_equ_EXt)  EX_ForwardB <= 2'd2;
            else EX_ForwardB <= 2'd0;
        end
    
    // MEM_Forwardrm
    // WB(lw)  -->  MEM(sw)    (wr = rt)
    //    wr    =       rt
    assign MEM_Forwardwm = WB_Lw & MEM_Sw & WBw_equ_MEMt;
        
endmodule
