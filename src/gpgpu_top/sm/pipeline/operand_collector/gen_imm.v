/*
 * Copyright (c) 2023-2024 C*Core Technology Co.,Ltd,Suzhou.
 * Ventus-RTL is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
 * EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
 * MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 * See the Mulan PSL v2 for more details. */
// Author: Chen, Qixiang
// Description:
//`include "IDecode_define.v"
`include "define.v"
`timescale 1ns/1ps

module gen_imm(
  input       [31:0]  inst_i      ,
  input       [3:0]   sel_i       ,
  input       [6:0]   imm_ext_i   , // exti_valid is packed at MSB of imm_ext
  output reg  [31:0]  out_o  
);

  /*
  wire [11:0] imm_I; // load, arithmetic, logic, jalr
  wire [11:0] imm_S; // store
  wire [12:0] imm_B; // branch
  wire [31:0] imm_U; // lui, auipc
  wire [20:0] imm_J; // jal
  wire [31:0] imm_Z; // CSR I
  wire [4:0]  imm_2; // for rs2 as imm2               
  wire [4:0]  imm_V;
  wire [10:0] imm_I_11L;
  wire [10:0] imm_I_11S;
  */
/*
  always @(*) begin
    case(sel_i)
      `IMM_I:    out_o = inst_i[31] ? {{20{1'b1}},inst_i[31:20]} : {20'b0,inst_i[31:20]};                                                                                   // load, arithmetic, logic, jalr
      `IMM_S:    out_o = inst_i[31] ? {{20{1'b1}},inst_i[31:25],inst_i[11:7]} : {20'b0,inst_i[31:25],inst_i[11:7]};                                                         // store
      `IMM_B:    out_o = inst_i[31] ? {{19{1'b1}},inst_i[31],inst_i[7],inst_i[30:25],inst_i[11:8],1'b0} : {19'b0,inst_i[31],inst_i[7],inst_i[30:25],inst_i[11:8],1'b0};     // branch
      `IMM_U:    out_o = {inst_i[31:12],12'b0};                                                                                                                             // lui, auipc
      `IMM_J:    out_o = inst_i[31] ? {{11{1'b1}},inst_i[31],inst_i[19:12],inst_i[20],inst_i[30:21],1'b0} : {11'b0,inst_i[31],inst_i[19:12],inst_i[20],inst_i[30:21],1'b0}; // jal
      `IMM_Z:    out_o = {27'b0,inst_i[19:15]};                                                                                                                             // CSR I
      `IMM_2:    out_o = inst_i[24] ? {{27{1'b1}},inst_i[24:20]} : {27'b0,inst_i[24:20]};                                                                                   // for rs2 as imm2               
      `IMM_V:    out_o = imm_ext_i[6] ? imm_ext_i[5] ? {{21{1'b1}},imm_ext_i[5:0],inst_i[19:15]} : {21'b0,imm_ext_i[5:0],inst_i[19:15]} : inst_i[19] ? {{27{1'b1}},inst_i[19:15]} : {27'b0,inst_i[19:15]};
      `IMM_L11:  out_o = inst_i[30] ? {{21{1'b1}},inst_i[30:20]} : {21'b0,inst_i[30:20]};
      `IMM_S11:  out_o = inst_i[30] ? {{21{1'b1}},inst_i[30:25],inst_i[11:7]} : {21'b0,inst_i[30:25],inst_i[11:7]};
      default:   out_o = (inst_i[31] ? {{20{1'b1}},inst_i[31:20]} : {20'b0,inst_i[31:20]}) & 32'hfffffffe;
    endcase
  end*/
  wire [31:0] imm_result_inst_1;
  wire [31:0] imm_result_inst_0;
  wire [31:0] imm_default_result_inst_0;
  assign imm_result_inst_1 = {{20{1'b1}},inst_i[31:20]};
  assign imm_result_inst_0 = {20'b0,inst_i[31:20]};
  assign imm_default_result_inst_0 = imm_result_inst_0  &  32'hfffffffe;




  always @(*) begin
    casex({sel_i,inst_i[31]})
       {`IMM_I,1'b1}: out_o = imm_result_inst_1;             //`IMM_I ,inst_i[31] == 1'b1
       {`IMM_I,1'b0}: out_o = {20'b0,inst_i[31:20]};                  //`IMM_I ,inst_i[31] == 1'b0
       // load, arithmetic, logic, jalr
       {`IMM_S,1'b1}: out_o = {{20{1'b1}},inst_i[31:25],inst_i[11:7]};//`IMM_S,inst_i[31] == 1'b1
       {`IMM_S,1'b0}: out_o = {20'b0,inst_i[31:25],inst_i[11:7]};     //`IMM_S,inst_i[31] == 1'b0
       // store
       {`IMM_B,1'b1}: out_o = {{19{1'b1}},inst_i[31],inst_i[7],inst_i[30:25],inst_i[11:8],1'b0}; //`IMM_B,inst_i[31] == 1'b1
       {`IMM_B,1'b0}: out_o = {19'b0,inst_i[31],inst_i[7],inst_i[30:25],inst_i[11:8],1'b0}; //`IMM_B,inst_i[31] == 1'b0
           // branch
       {`IMM_U,1'bx}: out_o = {inst_i[31:12],12'b0};                                                                                                                             // lui, auipc
      
       {`IMM_J,1'b1}: out_o = {{11{1'b1}},inst_i[31],inst_i[19:12],inst_i[20],inst_i[30:21],1'b0};
       {`IMM_J,1'b0}: out_o = {11'b0,inst_i[31],inst_i[19:12],inst_i[20],inst_i[30:21],1'b0}; // jal
       {`IMM_Z,1'bx}: out_o = {27'b0,inst_i[19:15]};                                                                                                                             // CSR I
       {`IMM_2,1'bx}: out_o = inst_i[24] ? {{27{1'b1}},inst_i[24:20]} : {27'b0,inst_i[24:20]};                                                                                   // for rs2 as imm2               
       {`IMM_V,1'bx}: out_o = imm_ext_i[6] ? imm_ext_i[5] ? {{21{1'b1}},imm_ext_i[5:0],inst_i[19:15]} : {21'b0,imm_ext_i[5:0],inst_i[19:15]} : inst_i[19] ? {{27{1'b1}},inst_i[19:15]} : {27'b0,inst_i[19:15]};
       {`IMM_L11,1'bx}: out_o = inst_i[30] ? {{21{1'b1}},inst_i[30:20]} : {21'b0,inst_i[30:20]};
       {`IMM_S11,1'bx}: out_o = inst_i[30] ? {{21{1'b1}},inst_i[30:25],inst_i[11:7]} : {21'b0,inst_i[30:25],inst_i[11:7]};
       {4'b1010,1'b1} : out_o =imm_result_inst_1;
       {4'b1010,1'b0} : out_o = imm_default_result_inst_0;
       {4'b1011,1'b1} : out_o = imm_result_inst_1;
       {4'b1011,1'b0} : out_o = imm_default_result_inst_0;
       {4'b1100,1'b1} : out_o = imm_result_inst_1;
       {4'b1100,1'b0} : out_o = imm_default_result_inst_0;
       {4'b1101,1'b1} : out_o = imm_result_inst_1;
       {4'b1101,1'b0} : out_o = imm_default_result_inst_0;
       {4'b1110,1'b1} : out_o = imm_result_inst_1;
       {4'b1110,1'b0} : out_o = imm_default_result_inst_0;
       {4'b1111,1'b1} : out_o = imm_result_inst_1;
       {4'b1111,1'b0} : out_o = imm_default_result_inst_0;      
      //default:   out_o = (inst_i[31] ? {{20{1'b1}},inst_i[31:20]} : {20'b0,inst_i[31:20]}) & 32'hfffffffe;
    endcase
  end



endmodule
