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
// Author: Tan, Zhiyuan
// Description: Connect L1$D/Sharemem and MSHR

`timescale 1ns/1ns

`include "define.v"

module rsp_arb (
  //from dcache
  input                                 in0_valid_i       ,
  output                                in0_ready_o       ,
  input   [$clog2(`LSU_NMSHRENTRY)-1:0] in0_instrid_i     ,
  input   [`XLEN*`NUM_THREAD-1:0]       in0_data_i        ,
  input   [`NUM_THREAD-1:0]             in0_activemask_i  ,

  //from shared
  input                                 in1_valid_i       ,
  output                                in1_ready_o       ,
  input   [$clog2(`LSU_NMSHRENTRY)-1:0] in1_instrid_i     ,
  input   [`XLEN*`NUM_THREAD-1:0]       in1_data_i        ,
  input   [`NUM_THREAD-1:0]             in1_activemask_i  ,

  //output
  output                                out_valid_o       ,
  input                                 out_ready_i       ,
  output  [$clog2(`LSU_NMSHRENTRY)-1:0] out_instrid_o     ,
  output  [`XLEN*`NUM_THREAD-1:0]       out_data_o        ,
  output  [`NUM_THREAD-1:0]             out_activemask_o
);

  assign in0_ready_o      = out_ready_i                 ;
  assign in1_ready_o      = !in0_valid_i && out_ready_i ;
  assign out_valid_o      = in0_valid_i | in1_valid_i   ;

  assign out_instrid_o    = in0_valid_i ? in0_instrid_i    : in1_instrid_i    ;
  assign out_data_o       = in0_valid_i ? in0_data_i       : in1_data_i       ;
  assign out_activemask_o = in0_valid_i ? in0_activemask_i : in1_activemask_i ;

endmodule

