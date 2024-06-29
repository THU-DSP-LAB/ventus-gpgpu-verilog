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
// Description: connect SMs and L2 Cache

`timescale 1ns/1ns

`include "define.v"
//`include "L2cache_define.v"

module cluster_to_l2_arb (
  //memReqVecIn
  input  [`NUM_CLUSTER-1:0]                mem_req_vec_in_valid_i   ,
  output [`NUM_CLUSTER-1:0]                mem_req_vec_in_ready_o   ,
  input  [`NUM_CLUSTER*`OP_BITS-1:0]       mem_req_vec_in_opcode_i  ,
  input  [`NUM_CLUSTER*`SIZE_BITS-1:0]     mem_req_vec_in_size_i    ,
  input  [`NUM_CLUSTER*`SOURCE_BITS-1:0]   mem_req_vec_in_source_i  ,
  input  [`NUM_CLUSTER*`ADDRESS_BITS-1:0]  mem_req_vec_in_address_i ,
  input  [`NUM_CLUSTER*`MASK_BITS-1:0]     mem_req_vec_in_mask_i    ,
  input  [`NUM_CLUSTER*`DATA_BITS-1:0]     mem_req_vec_in_data_i    ,
  input  [`NUM_CLUSTER*`PARAM_BITS-1:0]    mem_req_vec_in_param_i   ,
  //memReqOut
  output                                   mem_req_out_valid_o      ,
  input                                    mem_req_out_ready_i      ,
  output [`OP_BITS-1:0]                    mem_req_out_opcode_o     ,
  output [`SIZE_BITS-1:0]                  mem_req_out_size_o       ,
  output [`SOURCE_BITS-1:0]                mem_req_out_source_o     ,
  output [`ADDRESS_BITS-1:0]               mem_req_out_address_o    ,
  output [`MASK_BITS-1:0]                  mem_req_out_mask_o       ,
  output [`DATA_BITS-1:0]                  mem_req_out_data_o       ,
  output [`PARAM_BITS-1:0]                 mem_req_out_param_o      ,
  //memRspIn
  input                                    mem_rsp_in_valid_i       ,
  output                                   mem_rsp_in_ready_o       ,
  input  [`OP_BITS-1:0]                    mem_rsp_in_opcode_i      ,
  input  [`SIZE_BITS-1:0]                  mem_rsp_in_size_i        ,
  input  [`SOURCE_BITS-1:0]                mem_rsp_in_source_i      ,
  input  [`ADDRESS_BITS-1:0]               mem_rsp_in_address_i     ,
  input  [`DATA_BITS-1:0]                  mem_rsp_in_data_i        ,
  input  [`PARAM_BITS-1:0]                 mem_rsp_in_param_i       ,
  //memRspVecOut
  output [`NUM_CLUSTER-1:0]                mem_rsp_vec_out_valid_o  ,
  input  [`NUM_CLUSTER-1:0]                mem_rsp_vec_out_ready_i  ,
  output [`NUM_CLUSTER*`OP_BITS-1:0]       mem_rsp_vec_out_opcode_o ,
  output [`NUM_CLUSTER*`SIZE_BITS-1:0]     mem_rsp_vec_out_size_o   ,
  output [`NUM_CLUSTER*`SOURCE_BITS-1:0]   mem_rsp_vec_out_source_o ,
  output [`NUM_CLUSTER*`ADDRESS_BITS-1:0]  mem_rsp_vec_out_address_o,
  output [`NUM_CLUSTER*`DATA_BITS-1:0]     mem_rsp_vec_out_data_o   ,
  output [`NUM_CLUSTER*`PARAM_BITS-1:0]    mem_rsp_vec_out_param_o  
);

  localparam CLUSTER_BITS = (`NUM_CLUSTER==1) ? 1 : $clog2(`NUM_CLUSTER);

  /*
  wire [`NUM_CLUSTER-1:0] mem_req_vec_in_valid_oh ;
  wire [CLUSTER_BITS-1:0] mem_req_vec_in_valid_bin;

  fixed_pri_arb #(
    .ARB_WIDTH (`NUM_CLUSTER)
  )
  in_valid_arb (
    .req   (mem_req_vec_in_valid_i ),
    .grant (mem_req_vec_in_valid_oh)
  );

  one2bin #(
    .ONE_WIDTH (`NUM_CLUSTER),
    .BIN_WIDTH (CLUSTER_BITS)
  )
  in_valid_one2bin (
    .oh  (mem_req_vec_in_valid_oh ),
    .bin (mem_req_vec_in_valid_bin)
  );
  */

  wire [`NUM_CLUSTER-1:0] mem_req_vec_in_valid_reverse;
  wire [CLUSTER_BITS-1:0] mem_req_vec_in_valid_bin    ;

  input_reverse #(
    .DATA_WIDTH (`NUM_CLUSTER)
  )
  in_valid_reverse (
    .data_i (mem_req_vec_in_valid_i      ),
    .data_o (mem_req_vec_in_valid_reverse)
  );

  find_first #(
    .DATA_WIDTH (`NUM_CLUSTER),
    .DATA_DEPTH (CLUSTER_BITS)
  )
  in_valid_arb (
    .data_i (mem_req_vec_in_valid_reverse),
    .target (1'b1                        ),
    .data_o (mem_req_vec_in_valid_bin    )
  );

  assign mem_req_out_valid_o   = |mem_req_vec_in_valid_i;
  assign mem_req_out_size_o    = mem_req_vec_in_size_i[`SIZE_BITS*(mem_req_vec_in_valid_bin+1)-1-:`SIZE_BITS]         ;
  assign mem_req_out_opcode_o  = mem_req_vec_in_opcode_i[`OP_BITS*(mem_req_vec_in_valid_bin+1)-1-:`OP_BITS]           ;
  assign mem_req_out_address_o = mem_req_vec_in_address_i[`ADDRESS_BITS*(mem_req_vec_in_valid_bin+1)-1-:`ADDRESS_BITS];
  assign mem_req_out_mask_o    = mem_req_vec_in_mask_i[`MASK_BITS*(mem_req_vec_in_valid_bin+1)-1-:`MASK_BITS]         ;
  assign mem_req_out_data_o    = mem_req_vec_in_data_i[`DATA_BITS*(mem_req_vec_in_valid_bin+1)-1-:`DATA_BITS]         ;
  assign mem_req_out_param_o   = mem_req_vec_in_param_i[`PARAM_BITS*(mem_req_vec_in_valid_bin+1)-1-:`PARAM_BITS]      ;
  assign mem_req_out_source_o  = (`NUM_CLUSTER==1) ? 
    mem_req_vec_in_source_i[`SOURCE_BITS*(mem_req_vec_in_valid_bin+1)-1-:`SOURCE_BITS] : 
    {mem_req_vec_in_valid_bin,mem_req_vec_in_source_i[`SOURCE_BITS*(mem_req_vec_in_valid_bin+1)-1-:`SOURCE_BITS]} ;

  //mem_req_vec_in_ready_o
  assign mem_req_vec_in_ready_o[0] = mem_req_out_ready_i;

  genvar i;
  generate
    for(i=1;i<`NUM_CLUSTER;i=i+1) begin: MEM_REQ
      assign mem_req_vec_in_ready_o[i] = !(|mem_req_vec_in_ready_o[i-1:0]) && mem_req_out_ready_i;
    end
  endgenerate

  genvar j;
  generate
    for(j=0;j<`NUM_CLUSTER;j=j+1) begin: MEM_RSP
      assign mem_rsp_vec_out_valid_o[j] = (`NUM_CLUSTER==1) ? mem_rsp_in_valid_i : 
        ((j==mem_rsp_in_source_i[`SOURCE_BITS-1-:CLUSTER_BITS]) && mem_rsp_in_valid_i);
        //((j==mem_rsp_in_source_i[`SOURCE_BITS-1-:$clog2(`NUM_CLUSTER)]) && mem_rsp_in_valid_i);
      
      assign mem_rsp_vec_out_opcode_o[`OP_BITS*(j+1)-1-:`OP_BITS]             = mem_rsp_in_opcode_i ;
      assign mem_rsp_vec_out_size_o[`SIZE_BITS*(j+1)-1-:`SIZE_BITS]           = mem_rsp_in_size_i   ;
      assign mem_rsp_vec_out_address_o[`ADDRESS_BITS*(j+1)-1-:`ADDRESS_BITS]  = mem_rsp_in_address_i;
      assign mem_rsp_vec_out_data_o[`DATA_BITS*(j+1)-1-:`DATA_BITS]           = mem_rsp_in_data_i   ;
      assign mem_rsp_vec_out_param_o[`PARAM_BITS*(j+1)-1-:`PARAM_BITS]        = mem_rsp_in_param_i  ;
      assign mem_rsp_vec_out_source_o[`SOURCE_BITS*(j+1)-1-:`SOURCE_BITS]     = mem_rsp_in_source_i[`SOURCE_BITS-1:0];
    end
  endgenerate
 
  //mem_rsp_in_ready_o
  wire [CLUSTER_BITS-1:0] valid_index;

  assign valid_index = mem_rsp_in_source_i[`SOURCE_BITS-1-:CLUSTER_BITS];
  //assign valid_index = mem_rsp_in_source_i[`SOURCE_BITS-1-:$clog2(`NUM_CLUSTER)];
  
  assign mem_rsp_in_ready_o = (`NUM_CLUSTER==1) ? mem_rsp_vec_out_ready_i[0] : mem_rsp_vec_out_ready_i[valid_index];

endmodule

