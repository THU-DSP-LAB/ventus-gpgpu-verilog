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
`timescale 1ns/1ps

module tag_checker #(
  parameter NUM_WAY   = 24   ,
  parameter TAG_BITS  = 2     
)
(
  //input                           clk                 ,
  //input                           rst_n               ,
  input   [TAG_BITS*NUM_WAY-1:0]  tag_of_set_i        ,
  input   [TAG_BITS-1:0]          tag_from_pipe_i     ,
  input   [NUM_WAY-1:0]           valid_of_way_i      ,
  output  [NUM_WAY-1:0]           waymask_o           , //  onehot
  output                          cache_hit_o          

);

  genvar i;
  generate
    for(i=0; i<NUM_WAY; i=i+1) begin:way_loop
      assign waymask_o[i] = tag_of_set_i[TAG_BITS*(i+1)-1-:TAG_BITS]==tag_from_pipe_i && valid_of_way_i[i];
    end
  endgenerate

  assign  cache_hit_o = |waymask_o;


endmodule
