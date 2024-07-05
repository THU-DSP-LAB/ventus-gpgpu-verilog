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
// Author:TangYao 
// Description:Transmitting info to Main memory

`timescale  1ns/1ns
`include "define.v"
//`include "L2cache_define.v"

module SourceA(
  //flip Decoupled FullRequest
  output                               sourceA_req_ready_o      ,
  input                                sourceA_req_valid_i      ,

  //sourceA req part handshake signals
  input  [`SET_BITS-1:0]               sourceA_req_set_i        ,
  //input  [`L2C_BITS-1:0]               sourceA_req_l2cidx_i     ,
  input  [`OP_BITS-1:0]                sourceA_req_opcode_i     ,
  input  [`SIZE_BITS-1:0]              sourceA_req_size_i       ,
  input  [`SOURCE_BITS-1:0]            sourceA_req_source_i     ,
  input  [`TAG_BITS-1:0]               sourceA_req_tag_i        ,
  input  [`OFFSET_BITS-1:0]            sourceA_req_offset_i     ,
  //input  [`PUT_BITS-1:0]               sourceA_req_put_i        ,
  input  [`DATA_BITS-1:0]              sourceA_req_data_i       ,
  input  [`MASK_BITS-1:0]              sourceA_req_mask_i       ,
  //input  [`PARAM_BITS-1:0]             sourceA_req_param_i      ,

  input                                sourceA_a_ready_i        ,
  output                               sourceA_a_valid_o        ,
  //a part decoupled 
  output  [`OP_BITS-1:0]               sourceA_a_opcode_o       ,
  output  [`SIZE_BITS-1:0]             sourceA_a_size_o         ,
  output  [`SOURCE_BITS-1:0]           sourceA_a_source_o       ,
  output  [`ADDRESS_BITS-1:0]          sourceA_a_address_o      ,
  output  [`MASK_BITS-1:0]             sourceA_a_mask_o         ,
  output  [`DATA_BITS-1:0]             sourceA_a_data_o         ,
  output  [`PARAM_BITS-1:0]            sourceA_a_param_o        
  
  );
  
  assign sourceA_req_ready_o = sourceA_a_ready_i     ;
  assign sourceA_a_valid_o   = sourceA_req_valid_i   ;
  assign sourceA_a_opcode_o  = sourceA_req_opcode_i  ;
  assign sourceA_a_source_o  = sourceA_req_source_i  ;
  //assign sourceA_a_address_o = {sourceA_req_tag_i[`TAG_BITS-1:0], sourceA_req_l2cidx_i[`L2C_BITS-1:0],sourceA_req_set_i[`SET_BITS-1:0],sourceA_req_offset_i[`OFFSET_BITS-1:0]};
  assign sourceA_a_address_o = {sourceA_req_tag_i[`TAG_BITS-1:0],sourceA_req_set_i[`SET_BITS-1:0],sourceA_req_offset_i[`OFFSET_BITS-1:0]};
  assign sourceA_a_mask_o    = sourceA_req_mask_i    ;
  assign sourceA_a_data_o    = sourceA_req_data_i    ;
  assign sourceA_a_size_o    = sourceA_req_size_i    ;
  assign sourceA_a_param_o   = {`PARAM_BITS{1'b0}}   ;

endmodule
