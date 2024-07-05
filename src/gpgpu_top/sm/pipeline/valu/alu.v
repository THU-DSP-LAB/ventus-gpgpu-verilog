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
// Author: Gu, Zihan
// Description:scalar alu
`timescale 1ns/1ns
`include "define.v"
module  alu #(
  parameter DATA_WIDTH    = 32,
  parameter OPCODE_WIDTH  = 5
  )
  (
  //input                         clk,
  //input                         rst_n,
  input     [OPCODE_WIDTH-1:0]  op_i,
  input     [`XLEN-1:0]    in1_i,
  input     [`XLEN-1:0]    in2_i,
  //input     [`XLEN-1:0]    in3_i,

  output    [`XLEN-1:0]    out_o,
  output                        cmp_o
  );

  localparam  FN_ADD    = 5'd0;
  localparam  FN_SL     = 5'd1;
  localparam  FN_SEQ    = 5'd2;
  localparam  FN_SNE    = 5'd3;
  localparam  FN_XOR    = 5'd4;
  localparam  FN_SR     = 5'd5;
  localparam  FN_OR     = 5'd6;
  localparam  FN_AND    = 5'd7;
  localparam  FN_SUB    = 5'd10;
  localparam  FN_SRA    = 5'd11;
  localparam  FN_SLT    = 5'd12;
  localparam  FN_SGE    = 5'd13;
  localparam  FN_SLTU   = 5'd14;
  localparam  FN_SGEU   = 5'd15;
  localparam  FN_MAX    = 5'd16;
  localparam  FN_MIN    = 5'd17;
  localparam  FN_MAXU   = 5'd18;
  localparam  FN_MINU   = 5'd19;
  localparam  FN_A1ZERO = 5'd8;
  localparam  FN_A2ZERO = 5'd9;
  localparam  FN_MUL    = 5'd20;
  localparam  FN_MULH   = 5'd21;
  localparam  FN_MULHU  = 5'd22;
  localparam  FN_MULHSU = 5'd23;
  localparam  FN_MACC   = 5'd24;
  localparam  FN_NMSAC  = 5'd25;
  localparam  FN_MADD   = 5'd26;
  localparam  FN_NMSUB  = 5'd27;

  wire        isSub;
  wire        isCmp;
  wire        cmpUnsigned;
  wire        cmpInverted;//>
  wire        cmpEq;
  wire        isMIN;
  //wire        isMUL;
  //wire        isMAC;//Multiply Accumulate
  
  wire  [`XLEN-1:0]    in1_rev;
  wire  [`XLEN-1:0]    in2_inv;
  wire  [`XLEN-1:0]    adder_out;//result of add/sub
  wire  [`XLEN-1:0]    in1_xor_in2;
  wire                 slt;//result of slt/sltu
  wire                 sge;//result of sge/sgeu
  wire  [OPCODE_WIDTH-1:0]  shamt;
  wire  [`XLEN-1:0]    shin;
  wire  [`XLEN-1:0]    shout;//result of sll/srl/sra
  wire  [`XLEN-1:0]    shout_l;//result of sll
  wire  [`XLEN-1:0]    shout_r;//result of srl/sra
  wire  [2*`XLEN-1:0]  shout_r64;
  wire  [`XLEN-1:0]    and_or_xor;//result of and/or/xor
  wire  [`XLEN-1:0]    shift_logic_cmp;//shift:sll/srl/sra       logic:and/or/xor      cmp:slt/sltu/sge/sgeu
  wire  [`XLEN-1:0]    out;//reslut of shift/logic/cmp/seq/sne/add/sub
  wire  [`XLEN-1:0]    minu;//unsigned min
  wire  [`XLEN-1:0]    maxu;//unsigned max
  wire  [`XLEN-1:0]    in1s;//signed in1
  wire  [`XLEN-1:0]    in2s;//signed in2
  wire  [`XLEN-1:0]    mins;//signed min
  wire  [`XLEN-1:0]    maxs;//signed max
  wire  [`XLEN-1:0]    minmaxout;//result of min/max
  wire                 signed_flag;
    

  assign  isSub = (op_i >= FN_SUB) & (op_i <= FN_SGEU);
  assign  isCmp = (op_i >= FN_SLT) & (op_i <= FN_SGEU);
  assign  cmpUnsigned = op_i[1];
  assign  cmpInverted = op_i[0];
  assign  cmpEq = ~op_i[3];
  assign  isMIN = (op_i[4:2] == 3'b100);
  //assign  isMUL = (op_i[4:2] == 3'b101);
  //assign  isMAC = (op_i[4:2] == 3'b110);

  //ADD,SUB
  assign  in2_inv = isSub ? (~in2_i) : in2_i;
  assign  adder_out = in1_i + in2_inv + isSub;
  assign  in1_xor_in2 = in1_i ^ in2_inv;

  //SLT,SLTU
  assign  slt = (in1_i[`XLEN-1] == in2_i[`XLEN-1]) ? adder_out[`XLEN-1] : 
                (cmpUnsigned ? in2_i[`XLEN-1] : in1_i[`XLEN-1]);
  assign  sge = ~slt;
  assign  cmp_o = cmpInverted ^ (cmpEq ? (in1_xor_in2 == 0) : slt);

  //SLL,SRL,SRA
  assign  shamt = in2_i[4:0];

  genvar i;
  generate
    for(i=0;i<`XLEN;i=i+1) begin : reverse1
      assign in1_rev[i] = in1_i[`XLEN-1-i];
    end
  endgenerate

  assign  shin = (op_i == FN_SR | op_i == FN_SRA) ? in1_i : in1_rev;
  assign  shout_r64 = ({{`XLEN{isSub & shin[`XLEN-1]}},shin} >> shamt);
  assign  shout_r = shout_r64[`XLEN-1:0];

  genvar j;
  generate
    for(j=0;j<`XLEN;j=j+1) begin : reverse2
      assign  shout_l[j] = shout_r[`XLEN-1-j];
    end
  endgenerate
  
  assign  shout = ((op_i == FN_SR | op_i == FN_SRA) ? shout_r : 0) | 
                  (op_i == FN_SL ? shout_l : 0);

  //AND,OR,XOR
  assign  and_or_xor = (op_i == FN_XOR) ? in1_i ^ in2_i :
                       ((op_i == FN_OR) ? in1_i | in2_i :
                       ((op_i == FN_AND) ? in1_i & in2_i : 0));
  
  assign  shift_logic_cmp = ({{(`XLEN-1){1'b0}},isCmp} & ((op_i == FN_SLT || op_i == FN_SLTU) ? {{(`XLEN-1){1'b0}},slt} : {{(`XLEN-1){1'b0}},sge})) | and_or_xor | shout;

  assign  out = (op_i == FN_ADD | op_i == FN_SUB) ? adder_out :
                (op_i == FN_SEQ ? in1_i == in2_i : 
                (op_i == FN_SNE ? in1_i != in2_i : shift_logic_cmp));
  
  assign mins = ($signed(in1_i) > $signed(in2_i)) ? in2_i : in1_i;
  assign maxs = ($signed(in1_i) > $signed(in2_i)) ? in1_i : in2_i;
  assign minu = (in1_i > in2_i) ? in2_i : in1_i;
  assign maxu = (in1_i > in2_i) ? in1_i : in2_i;
  
  assign minmaxout = op_i == FN_MIN ? mins : 
                    (op_i == FN_MAX ? maxs : 
                    (op_i == FN_MINU ? minu : maxu));

  assign out_o =  op_i == FN_A1ZERO ? in2_i : 
                  (op_i == FN_A2ZERO ? in1_i : 
                  (isMIN ? minmaxout : out));

endmodule


        


