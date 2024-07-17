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
//`include "L2cache_define.v"

module sm2cluster_arb (
  input                                                           clk                       ,
  input                                                           rst_n                     ,

  output [`NUM_SM_IN_CLUSTER-1:0]                                 mem_req_vec_in_ready_o    ,
  input  [`NUM_SM_IN_CLUSTER-1:0]                                 mem_req_vec_in_valid_i    ,
  input  [`NUM_SM_IN_CLUSTER*3-1:0]                               mem_req_vec_in_a_opcode_i ,
  input  [`NUM_SM_IN_CLUSTER*3-1:0]                               mem_req_vec_in_a_param_i  ,
  input  [`NUM_SM_IN_CLUSTER*`XLEN-1:0]                           mem_req_vec_in_a_addr_i   ,
  input  [`NUM_SM_IN_CLUSTER*`DCACHE_BLOCKWORDS*`XLEN-1:0]        mem_req_vec_in_a_data_i   , 
  input  [`NUM_SM_IN_CLUSTER*`DCACHE_BLOCKWORDS*`BYTESOFWORD-1:0] mem_req_vec_in_a_mask_i   ,
  input  [`NUM_SM_IN_CLUSTER*`D_SOURCE-1:0]                       mem_req_vec_in_a_source_i ,

  input                                                           mem_req_out_ready_i       ,
  output                                                          mem_req_out_valid_o       ,
  output [`OP_BITS-1:0]                                           mem_req_out_opcode_o      ,
  output [`SIZE_BITS-1:0]                                         mem_req_out_size_o        ,
  output [`CLUSTER_SOURCE-1:0]                                    mem_req_out_source_o      ,
  output [`ADDRESS_BITS-1:0]                                      mem_req_out_address_o     ,
  output [`MASK_BITS-1:0]                                         mem_req_out_mask_o        ,
  output [`DATA_BITS-1:0]                                         mem_req_out_data_o        ,
  output [2:0]                                                    mem_req_out_param_o       ,

  output                                                          mem_rsp_in_ready_o        ,
  input                                                           mem_rsp_in_valid_i        ,
  input  [`OP_BITS-1:0]                                           mem_rsp_in_opcode_i       ,
  input  [`SIZE_BITS-1:0]                                         mem_rsp_in_size_i         ,
  input  [`CLUSTER_SOURCE-1:0]                                    mem_rsp_in_source_i       ,
  input  [`DATA_BITS-1:0]                                         mem_rsp_in_data_i         ,
  input  [2:0]                                                    mem_rsp_in_param_i        ,
  input  [`ADDRESS_BITS-1:0]                                      mem_rsp_in_address_i      ,

  input  [`NUM_SM_IN_CLUSTER-1:0]                                 mem_rsp_vec_out_ready_i   ,
  output [`NUM_SM_IN_CLUSTER-1:0]                                 mem_rsp_vec_out_valid_o   ,
  output [`NUM_SM_IN_CLUSTER*3-1:0]                               mem_rsp_vec_out_d_opcode_o, 
  output [`NUM_SM_IN_CLUSTER*`WORDLENGTH-1:0]                     mem_rsp_vec_out_d_addr_o  ,
  output [`NUM_SM_IN_CLUSTER*`DCACHE_BLOCKWORDS*`WORDLENGTH-1:0]  mem_rsp_vec_out_d_data_o  ,
  output [`NUM_SM_IN_CLUSTER*`D_SOURCE-1:0]                       mem_rsp_vec_out_d_source_o   
  );

  localparam FIFO_WIDTH = `OP_BITS+`SIZE_BITS+`CLUSTER_SOURCE+`ADDRESS_BITS+`MASK_BITS+`DATA_BITS+3;

  wire memReqBuf_w_ready;
  wire [FIFO_WIDTH-1:0] memReqBuf_data_in,memReqBuf_out_data;

  wire [`NUM_SM_IN_CLUSTER-1:0] in_valid_grant_oh;
  wire [`NUM_CLUSTER_DEPTH-1:0] in_valid_grant_bin;

  wire [`OP_BITS-1:0] memReqBuf_in_opcode;
  wire [`SIZE_BITS-1:0] memReqBuf_in_size;
  wire [`CLUSTER_SOURCE-1:0] memReqBuf_in_source;
  wire [`ADDRESS_BITS-1:0] memReqBuf_in_address;
  wire [`MASK_BITS-1:0] memReqBuf_in_mask;
  wire [`DATA_BITS-1:0] memReqBuf_in_data;
  wire [2:0] memReqBuf_in_param;

  genvar i;
  generate for(i=0;i<`NUM_SM_IN_CLUSTER;i=i+1) begin:B1
    //assign mem_req_vec_in_ready_o[i] = (i == in_valid_grant_bin) ? memReqBuf_w_ready : 'h0;
    assign mem_req_vec_in_ready_o[i] = memReqBuf_w_ready;
    assign mem_rsp_vec_out_d_data_o[`DCACHE_BLOCKWORDS*`WORDLENGTH*(i+1)-1-:`DCACHE_BLOCKWORDS*`WORDLENGTH] = mem_rsp_in_data_i;
    assign mem_rsp_vec_out_d_source_o[`D_SOURCE*(i+1)-1-:`D_SOURCE] = (`NUM_SM_IN_CLUSTER==1) ? mem_rsp_in_source_i : mem_rsp_in_source_i[`D_SOURCE-1:0];
    assign mem_rsp_vec_out_d_addr_o[`WORDLENGTH*(i+1)-1-:`WORDLENGTH] = mem_rsp_in_address_i;
    assign mem_rsp_vec_out_d_opcode_o[3*(i+1)-1-:3] = mem_rsp_in_opcode_i;
    assign mem_rsp_vec_out_valid_o[i] = (`NUM_SM_IN_CLUSTER==1) ? mem_rsp_in_valid_i : (mem_rsp_in_source_i[`CLUSTER_SOURCE-1-:`NUM_CLUSTER_DEPTH]==i) && mem_rsp_in_valid_i;
  end 
  endgenerate

  assign mem_rsp_in_ready_o = (`NUM_SM_IN_CLUSTER==1) ? mem_rsp_vec_out_ready_i[0] : mem_rsp_vec_out_ready_i[mem_rsp_in_source_i[`CLUSTER_SOURCE-1-:`NUM_CLUSTER_DEPTH]];

  assign memReqBuf_in_opcode = mem_req_vec_in_a_opcode_i[(3*(in_valid_grant_bin+1)-1)-:3];
  assign memReqBuf_in_source = (`NUM_SM_IN_CLUSTER==1) ? mem_req_vec_in_a_source_i[`CLUSTER_SOURCE*(in_valid_grant_bin+1)-1-:`CLUSTER_SOURCE] : 
                                                         {in_valid_grant_bin,mem_req_vec_in_a_source_i[`D_SOURCE*(in_valid_grant_bin+1)-1-:`D_SOURCE]};
  assign memReqBuf_in_size = 'h0;
  assign memReqBuf_in_address = mem_req_vec_in_a_addr_i[(`XLEN*(in_valid_grant_bin+1)-1)-:`XLEN];
  assign memReqBuf_in_mask = mem_req_vec_in_a_mask_i[`DCACHE_BLOCKWORDS*`BYTESOFWORD*(in_valid_grant_bin+1)-1-:`DCACHE_BLOCKWORDS*`BYTESOFWORD];
  assign memReqBuf_in_data = mem_req_vec_in_a_data_i[`DCACHE_BLOCKWORDS*`XLEN*(in_valid_grant_bin+1)-1-:`DCACHE_BLOCKWORDS*`XLEN];
  assign memReqBuf_in_param = mem_req_vec_in_a_param_i[(3*(in_valid_grant_bin+1)-1)-:3];

  assign memReqBuf_data_in = {memReqBuf_in_opcode,memReqBuf_in_size,memReqBuf_in_source,memReqBuf_in_address,memReqBuf_in_mask,memReqBuf_in_data,memReqBuf_in_param};

  assign {mem_req_out_opcode_o,mem_req_out_size_o,mem_req_out_source_o,mem_req_out_address_o,mem_req_out_mask_o,mem_req_out_data_o,mem_req_out_param_o} = memReqBuf_out_data;

  fixed_pri_arb #(
    .ARB_WIDTH(`NUM_SM_IN_CLUSTER)
    ) memReqArb(
    .req  (mem_req_vec_in_valid_i       ),
    .grant(in_valid_grant_oh            )
    );

  one2bin #(
    .ONE_WIDTH(`NUM_SM_IN_CLUSTER),
    .BIN_WIDTH(`NUM_CLUSTER_DEPTH)
    ) one_to_bin(
    .oh (in_valid_grant_oh ),
    .bin(in_valid_grant_bin)
    );

  stream_fifo #(
    .DATA_WIDTH(FIFO_WIDTH),
    .FIFO_DEPTH(2         )
    ) memReqBuf(
    .clk      (clk                ),
    .rst_n    (rst_n              ),

    .w_ready_o(memReqBuf_w_ready  ),
    .w_valid_i(|in_valid_grant_oh ),
    .w_data_i (memReqBuf_data_in  ),
 
    .r_valid_o(mem_req_out_valid_o),
    .r_ready_i(mem_req_out_ready_i),
    .r_data_o (memReqBuf_out_data )
    );

endmodule
