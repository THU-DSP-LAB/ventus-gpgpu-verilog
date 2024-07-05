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
// Author: Zhang, Qi
// Description:
`timescale 1ns/1ns

`include "define.v"

module l1cache_arb (
  output [`NUM_CACHE_IN_SM-1:0]                                   mem_req_in_ready_o    ,
  input  [`NUM_CACHE_IN_SM-1:0]                                   mem_req_in_valid_i    ,
  input  [(`NUM_CACHE_IN_SM*3)-1:0]                               mem_req_in_a_opcode_i ,
  input  [(`NUM_CACHE_IN_SM*3)-1:0]                               mem_req_in_a_param_i  ,
  input  [(`NUM_CACHE_IN_SM*`XLEN)-1:0]                           mem_req_in_a_addr_i   ,
  input  [(`NUM_CACHE_IN_SM*`DCACHE_BLOCKWORDS*`XLEN)-1:0]        mem_req_in_a_data_i   ,
  input  [(`NUM_CACHE_IN_SM*`DCACHE_BLOCKWORDS*`BYTESOFWORD)-1:0] mem_req_in_a_mask_i   ,
  input  [(`NUM_CACHE_IN_SM*`A_SOURCE)-1:0]                       mem_req_in_a_source_i ,

  input                                                           mem_req_out_ready_i   ,
  output                                                          mem_req_out_valid_o   ,
  output [2:0]                                                    mem_req_out_a_opcode_o,
  output [2:0]                                                    mem_req_out_a_param_o ,
  output [`XLEN-1:0]                                              mem_req_out_a_addr_o  ,
  output [(`DCACHE_BLOCKWORDS*`XLEN)-1:0]                         mem_req_out_a_data_o  ,
  output [(`DCACHE_BLOCKWORDS*`BYTESOFWORD)-1:0]                  mem_req_out_a_mask_o  ,
  output [`D_SOURCE-1:0]                                          mem_req_out_a_source_o,

  output                                                          mem_rsp_in_ready_o    ,
  input                                                           mem_rsp_in_valid_i    ,
  input  [2:0]                                                    mem_rsp_in_d_opcode_i ,
  input  [`XLEN-1:0]                                              mem_rsp_in_d_addr_i   ,
  input  [(`DCACHE_BLOCKWORDS*`XLEN)-1:0]                         mem_rsp_in_d_data_i   ,
  input  [`D_SOURCE-1:0]                                          mem_rsp_in_d_source_i ,

  input  [`NUM_CACHE_IN_SM-1:0]                                   mem_rsp_out_ready_i   ,
  output [`NUM_CACHE_IN_SM-1:0]                                   mem_rsp_out_valid_o   ,
  output [(`NUM_CACHE_IN_SM*3)-1:0]                               mem_rsp_out_d_opcode_o,
  output [(`NUM_CACHE_IN_SM*`XLEN)-1:0]                           mem_rsp_out_d_addr_o  ,
  output [(`NUM_CACHE_IN_SM*`DCACHE_BLOCKWORDS*`XLEN)-1:0]        mem_rsp_out_d_data_o  ,
  output [(`NUM_CACHE_IN_SM*`A_SOURCE)-1:0]                       mem_rsp_out_d_source_o 
  );

  wire [`NUM_CACHE_IN_SM-1:0] mem_req_in_valid_oh;
  wire [`NUM_CACHE_DEPTH-1:0] mem_req_in_valid_bin;
  wire [`NUM_CACHE_IN_SM*`D_SOURCE-1:0] mem_req_arb_a_source;

  genvar i;
  generate for(i=0;i<`NUM_CACHE_IN_SM;i=i+1) begin:B1
    assign mem_req_arb_a_source[(`D_SOURCE*(i+1)-1)-:`D_SOURCE] = {i,mem_req_in_a_source_i[(`A_SOURCE*(i+1)-1)-:`A_SOURCE]};
    //assign mem_req_in_ready_o[i] = (i == mem_req_in_valid_bin) ? mem_req_out_ready_i : 1'h0;
    assign mem_rsp_out_valid_o[i] = (i == mem_rsp_in_d_source_i[(`D_SOURCE-1)-:`NUM_CACHE_DEPTH]) ? mem_rsp_in_valid_i : 1'h0;
  end
  endgenerate 

  assign mem_req_in_ready_o[0] = mem_req_out_ready_i;

  genvar j;
  generate
    for(j=1;j<`NUM_CACHE_IN_SM;j=j+1) begin:B2
      assign mem_req_in_ready_o[j] = !(|mem_req_in_valid_i[j-1:0]) && mem_req_out_ready_i;
    end
  endgenerate
  
  assign mem_req_out_valid_o = mem_req_in_valid_i[mem_req_in_valid_bin];
  assign mem_req_out_a_opcode_o = mem_req_in_a_opcode_i[(3*(mem_req_in_valid_bin+1)-1)-:3];
  assign mem_req_out_a_param_o = mem_req_in_a_param_i[(3*(mem_req_in_valid_bin+1)-1)-:3];
  assign mem_req_out_a_addr_o = mem_req_in_a_addr_i[(`XLEN*(mem_req_in_valid_bin+1)-1)-:`XLEN];
  assign mem_req_out_a_data_o = mem_req_in_a_data_i[(`DCACHE_BLOCKWORDS*`XLEN*(mem_req_in_valid_bin+1)-1)-:(`DCACHE_BLOCKWORDS*`XLEN)];
  assign mem_req_out_a_mask_o = mem_req_in_a_mask_i[(`DCACHE_BLOCKWORDS*`BYTESOFWORD*(mem_req_in_valid_bin+1)-1)-:(`DCACHE_BLOCKWORDS*`BYTESOFWORD)];
  assign mem_req_out_a_source_o = mem_req_arb_a_source[(`D_SOURCE*(mem_req_in_valid_bin+1)-1)-:`D_SOURCE];

  assign mem_rsp_out_d_opcode_o = {`NUM_CACHE_IN_SM{mem_rsp_in_d_opcode_i}};
  assign mem_rsp_out_d_addr_o = {`NUM_CACHE_IN_SM{mem_rsp_in_d_addr_i}};
  assign mem_rsp_out_d_data_o = {`NUM_CACHE_IN_SM{mem_rsp_in_d_data_i}};
  assign mem_rsp_out_d_source_o = {`NUM_CACHE_IN_SM{mem_rsp_in_d_source_i[`A_SOURCE-1:0]}};

  assign mem_rsp_in_ready_o = mem_rsp_out_ready_i[mem_rsp_in_d_source_i[`D_SOURCE-1-:`NUM_CACHE_DEPTH]];

  fixed_pri_arb #(
    .ARB_WIDTH(`NUM_CACHE_IN_SM)
    ) mem_req_arb(
    .req  (mem_req_in_valid_i ),
    .grant(mem_req_in_valid_oh)
    );

  one2bin #(
    .ONE_WIDTH(`NUM_CACHE_IN_SM),
    .BIN_WIDTH(`NUM_CACHE_DEPTH)
    ) one2bin(
    .oh (mem_req_in_valid_oh ),
    .bin(mem_req_in_valid_bin)
    );

endmodule
