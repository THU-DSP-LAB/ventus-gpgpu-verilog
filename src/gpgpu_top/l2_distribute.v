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
// Description:

`timescale 1ns/1ns
`include "define.v"
//`include "L2cache_define.v"

module l2_distribute (
  //mem_req_in
  input                                     mem_req_in_valid_i       ,
  output                                    mem_req_in_ready_o       ,
  input   [`OP_BITS-1:0]                    mem_req_in_opcode_i      ,
  input   [`SIZE_BITS-1:0]                  mem_req_in_size_i        ,
  input   [`CLUSTER_SOURCE-1:0]             mem_req_in_source_i      ,
  input   [`ADDRESS_BITS-1:0]               mem_req_in_address_i     ,
  input   [`MASK_BITS-1:0]                  mem_req_in_mask_i        ,
  input   [`DATA_BITS-1:0]                  mem_req_in_data_i        ,
  input   [2:0]                             mem_req_in_param_i       ,
  //mem_req_vec_out
  output  [`NUM_L2CACHE-1:0]                mem_req_vec_out_valid_o  ,
  input   [`NUM_L2CACHE-1:0]                mem_req_vec_out_ready_i  ,
  output  [`NUM_L2CACHE*`OP_BITS-1:0]       mem_req_vec_out_opcode_o ,
  output  [`NUM_L2CACHE*`SIZE_BITS-1:0]     mem_req_vec_out_size_o   ,
  output  [`NUM_L2CACHE*`CLUSTER_SOURCE-1:0]mem_req_vec_out_source_o ,
  output  [`NUM_L2CACHE*`ADDRESS_BITS-1:0]  mem_req_vec_out_address_o,
  output  [`NUM_L2CACHE*`MASK_BITS-1:0]     mem_req_vec_out_mask_o   ,
  output  [`NUM_L2CACHE*`DATA_BITS-1:0]     mem_req_vec_out_data_o   ,
  output  [`NUM_L2CACHE*3-1:0]              mem_req_vec_out_param_o  ,
  //mem_rsp_vec_in
  input   [`NUM_L2CACHE-1:0]                mem_rsp_vec_in_valid_i   ,
  output  [`NUM_L2CACHE-1:0]                mem_rsp_vec_in_ready_o   ,
  input   [`NUM_L2CACHE*`ADDRESS_BITS-1:0]  mem_rsp_vec_in_address_i ,
  input   [`NUM_L2CACHE*`OP_BITS-1:0]       mem_rsp_vec_in_opcode_i  ,
  input   [`NUM_L2CACHE*`SIZE_BITS-1:0]     mem_rsp_vec_in_size_i    ,
  input   [`NUM_L2CACHE*`CLUSTER_SOURCE-1:0]mem_rsp_vec_in_source_i  ,
  input   [`NUM_L2CACHE*`DATA_BITS-1:0]     mem_rsp_vec_in_data_i    ,
  input   [`NUM_L2CACHE*3-1:0]              mem_rsp_vec_in_param_i   ,
  //mem_rsp_out
  output                                    mem_rsp_out_valid_o      ,
  input                                     mem_rsp_out_ready_i      ,
  output  [`ADDRESS_BITS-1:0]               mem_rsp_out_address_o    ,
  output  [`OP_BITS-1:0]                    mem_rsp_out_opcode_o     ,
  output  [`SIZE_BITS-1:0]                  mem_rsp_out_size_o       ,
  output  [`CLUSTER_SOURCE-1:0]             mem_rsp_out_source_o     ,
  output  [`DATA_BITS-1:0]                  mem_rsp_out_data_o       ,
  output  [2:0]                             mem_rsp_out_param_o       
  );
  localparam L2CACHE_BITS = (`NUM_L2CACHE == 1) ? 1 : $clog2(`NUM_L2CACHE);
  
  wire    [`NUM_L2CACHE:0]                  mem_rsp_vec_in_valid_oh  ;
  wire    [`NUM_L2CACHE-1:0]                mem_rsp_vec_in_valid_oh_r;
  wire    [L2CACHE_BITS-1:0]                mem_rsp_vec_in_valid_bin ;
  wire    [L2CACHE_BITS-1:0]                valid_index              ;

  fixed_pri_arb #(
    .ARB_WIDTH(`NUM_L2CACHE+1)
  )
  mem_rsp_arb (
    .req  ({1'b0,mem_rsp_vec_in_valid_i}),
    .grant(mem_rsp_vec_in_valid_oh      )
    );

  assign mem_rsp_vec_in_valid_oh_r = mem_rsp_vec_in_valid_oh[`NUM_L2CACHE-1:0];

  one2bin #(
    .ONE_WIDTH(`NUM_L2CACHE),
    .BIN_WIDTH(L2CACHE_BITS)
  )
  U_one2bin (
    .oh (mem_rsp_vec_in_valid_oh_r),
    .bin(mem_rsp_vec_in_valid_bin )
  );

  genvar i;
  generate for(i=0;i<`NUM_L2CACHE;i=i+1) begin : A1
   assign  mem_req_vec_out_valid_o[i]                                         = (`L2C_BITS != 0) ? (mem_req_in_valid_i && (i == mem_req_in_address_i[`ADDRESS_BITS-`TAG_BITS-1-:L2CACHE_BITS])) : mem_req_in_valid_i;
   assign  mem_req_vec_out_opcode_o[(i+1)*`OP_BITS-1-:`OP_BITS]               = mem_req_in_opcode_i                                                                                                                 ; 
   assign  mem_req_vec_out_size_o[(i+1)*`SIZE_BITS-1-:`SIZE_BITS]             = mem_req_in_size_i                                                                                                                   ;
   assign  mem_req_vec_out_source_o[(i+1)*`CLUSTER_SOURCE-1-:`CLUSTER_SOURCE] = mem_req_in_source_i                                                                                                                 ;
   assign  mem_req_vec_out_address_o[(i+1)*`ADDRESS_BITS-1-:`ADDRESS_BITS]    = mem_req_in_address_i                                                                                                                ;
   assign  mem_req_vec_out_mask_o[(i+1)*`MASK_BITS-1-:`MASK_BITS]             = mem_req_in_mask_i                                                                                                                   ;
   assign  mem_req_vec_out_data_o[(i+1)*`DATA_BITS-1-:`DATA_BITS]             = mem_req_in_data_i                                                                                                                   ;
   assign  mem_req_vec_out_param_o[(i+1)*3-1-:3]                              = mem_req_in_param_i                                                                                                                  ;
  end
  endgenerate

  assign mem_rsp_out_valid_o       = mem_rsp_vec_in_valid_i[mem_rsp_vec_in_valid_bin]                                        ;
  assign mem_rsp_out_address_o     = mem_rsp_vec_in_address_i[(mem_rsp_vec_in_valid_bin+1)*`ADDRESS_BITS-1-:`ADDRESS_BITS]   ;
  assign mem_rsp_out_opcode_o      = mem_rsp_vec_in_opcode_i[(mem_rsp_vec_in_valid_bin+1)*`OP_BITS-1-:`OP_BITS]              ;
  assign mem_rsp_out_size_o        = mem_rsp_vec_in_size_i[(mem_rsp_vec_in_valid_bin+1)*`SIZE_BITS-1-:`SIZE_BITS]            ;
  assign mem_rsp_out_source_o      = mem_rsp_vec_in_source_i[(mem_rsp_vec_in_valid_bin+1)*`CLUSTER_SOURCE-1-:`CLUSTER_SOURCE];
  assign mem_rsp_out_data_o        = mem_rsp_vec_in_data_i[(mem_rsp_vec_in_valid_bin+1)*`DATA_BITS-1-:`DATA_BITS]            ;
  assign mem_rsp_out_param_o       = mem_rsp_vec_in_param_i[(mem_rsp_vec_in_valid_bin+1)*3-1-:3]                             ;
  assign mem_rsp_vec_in_ready_o[0] = mem_rsp_out_ready_i                                                                     ;

  genvar j;
  generate
    for(j=1;j<`NUM_L2CACHE;j=j+1) begin: A2
      assign mem_rsp_vec_in_ready_o[j] = !(|mem_rsp_vec_in_ready_o[j-1:0]) && mem_rsp_out_ready_i;
    end
  endgenerate

  assign valid_index        = (`L2C_BITS != 0) ? mem_req_in_address_i[`ADDRESS_BITS-`TAG_BITS-1-:L2CACHE_BITS] : 0;
  assign mem_req_in_ready_o = (`L2C_BITS != 0) ? mem_req_vec_out_ready_i[valid_index] : mem_req_vec_out_ready_i   ;

endmodule

  
  
  
