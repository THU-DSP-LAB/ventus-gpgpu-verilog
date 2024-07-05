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
// Description:receive data from main memory

`timescale 1ns/1ns
`include "define.v"
//`include "L2cache_define.v"

module sinkD (
  input                                       clk          ,
  input                                       rst_n        ,

  input       [`OP_BITS-1:0]                  d_opcode_i   ,
  input       [`SOURCE_BITS-1:0]              d_source_i   ,
  input       [`DATA_BITS-1:0]                d_data_i     ,
  input                                       d_valid_i    ,
  output                                      d_ready_o    ,

  //input       [`PUT_BITS-1:0]                 put_i        ,
  //output      [`PUT_BITS-1:0]                 index_o      ,
  output      [`SOURCE_BITS-1:0]              source_o     ,

  output      [`OP_BITS-1:0]                  resp_opcode_o,
  output      [`SOURCE_BITS-1:0]              resp_source_o,
  output      [`DATA_BITS-1:0]                resp_data_o  ,
  output                                      resp_valid_o 
  );
  reg         [`SOURCE_BITS-1:0]              d_source_reg   ;
  reg         [`SOURCE_BITS-1:0]              d_source_reg_en;
  reg         [`OP_BITS-1:0]                  d_opcode_reg   ;
  reg         [`DATA_BITS-1:0]                d_data_reg     ;
  reg                                         d_fire_reg     ;

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      d_source_reg <= 'd0;
      d_opcode_reg <= 'd0;
      d_data_reg   <= 'd0;
      d_fire_reg   <= 'd0;
    end
    else begin
      d_source_reg <= d_source_i           ;
      d_opcode_reg <= d_opcode_i           ;
      d_data_reg   <= d_data_i             ;
      d_fire_reg   <= d_valid_i & d_ready_o;
    end
  end

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      d_source_reg_en <= 'd0;
    end
    else if(d_valid_i) begin
      d_source_reg_en <= d_source_i;
    end
    else begin
      d_source_reg_en <= d_source_reg_en;
    end
  end

  //assign index_o  = put_i;
  assign source_o = d_valid_i ? d_source_i : d_source_reg_en;

  assign resp_valid_o  = d_fire_reg  ;
  assign resp_opcode_o = d_opcode_reg;
  assign resp_source_o = d_source_reg;
  assign resp_data_o   = d_data_reg  ;
  assign d_ready_o     = 1'b1        ;

endmodule


