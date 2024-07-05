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
// Description: save lsu requests
`timescale 1ns/1ns

`include "define.v"

module input_fifo (
  input                                     clk                 ,
  input                                     rst_n               ,

  //from pipe(vExeData)
  input                                     enq_valid_i         ,
  output                                    enq_ready_o         ,
  input   [`XLEN*`NUM_THREAD-1:0]           enq_in1_i           ,
  input   [`XLEN*`NUM_THREAD-1:0]           enq_in2_i           ,
  input   [`XLEN*`NUM_THREAD-1:0]           enq_in3_i           ,
  input   [`NUM_THREAD-1:0]                 enq_mask_i          ,
  //control signals
  input   [`DEPTH_WARP-1:0]                 enq_wid_i           ,
  input                                     enq_isvec_i         ,
  input   [1:0]                             enq_mem_whb_i       ,
  input                                     enq_mem_unsigned_i  ,
  input   [5:0]                             enq_alu_fn_i        ,
  input                                     enq_is_vls12_i      ,
  input                                     enq_disable_mask_i  ,
  input   [1:0]                             enq_mem_cmd_i       ,
  input   [1:0]                             enq_mop_i           ,
  input   [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] enq_reg_idxw_i      ,
  input                                     enq_wvd_i           ,
  input                                     enq_fence_i         ,
  input                                     enq_wxd_i           ,
  input                                     enq_atomic_i        ,
  input                                     enq_aq_i            ,
  input                                     enq_rl_i            ,

  //output vExeData
  output                                    deq_valid_o         ,
  input                                     deq_ready_i         ,
  output  [`XLEN*`NUM_THREAD-1:0]           deq_in1_o           ,
  output  [`XLEN*`NUM_THREAD-1:0]           deq_in2_o           ,
  output  [`XLEN*`NUM_THREAD-1:0]           deq_in3_o           ,
  output  [`NUM_THREAD-1:0]                 deq_mask_o          ,
  //control signals
  output  [`DEPTH_WARP-1:0]                 deq_wid_o           ,
  output                                    deq_isvec_o         ,
  output  [1:0]                             deq_mem_whb_o       ,
  output                                    deq_mem_unsigned_o  ,
  output  [5:0]                             deq_alu_fn_o        ,
  output                                    deq_is_vls12_o      ,
  output                                    deq_disable_mask_o  ,
  output  [1:0]                             deq_mem_cmd_o       ,
  output  [1:0]                             deq_mop_o           ,
  output  [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] deq_reg_idxw_o      ,
  output                                    deq_wvd_o           ,
  output                                    deq_fence_o         ,
  output                                    deq_wxd_o           ,
  output                                    deq_atomic_o        ,
  output                                    deq_aq_o            ,
  output                                    deq_rl_o            
);

  localparam FIFO_DEPTH = 1;
  wire [3*`XLEN*`NUM_THREAD+`NUM_THREAD+`DEPTH_WARP+`REGIDX_WIDTH+`REGEXT_WIDTH+22-1:0] enq_bits;
  wire [3*`XLEN*`NUM_THREAD+`NUM_THREAD+`DEPTH_WARP+`REGIDX_WIDTH+`REGEXT_WIDTH+22-1:0] deq_bits;

  assign enq_bits = {enq_in1_i          ,
                     enq_in2_i          ,
                     enq_in3_i          ,
                     enq_mask_i         ,                             
                     enq_wid_i          ,
                     enq_isvec_i        ,
                     enq_mem_whb_i      ,
                     enq_mem_unsigned_i ,
                     enq_alu_fn_i       ,
                     enq_is_vls12_i     ,
                     enq_disable_mask_i ,
                     enq_mem_cmd_i      ,
                     enq_mop_i          ,
                     enq_reg_idxw_i     ,
                     enq_wvd_i          ,
                     enq_fence_i        ,
                     enq_wxd_i          ,
                     enq_atomic_i       ,
                     enq_aq_i           ,
                     enq_rl_i           
                    };
  assign deq_in1_o         = deq_bits[3*`XLEN*`NUM_THREAD+`NUM_THREAD+`DEPTH_WARP+`REGIDX_WIDTH+`REGEXT_WIDTH+22-1:2*`XLEN*`NUM_THREAD+`NUM_THREAD+`DEPTH_WARP+`REGIDX_WIDTH+`REGEXT_WIDTH+22] ;
  assign deq_in2_o         = deq_bits[2*`XLEN*`NUM_THREAD+`NUM_THREAD+`DEPTH_WARP+`REGIDX_WIDTH+`REGEXT_WIDTH+22-1:`XLEN*`NUM_THREAD+`NUM_THREAD+`DEPTH_WARP+`REGIDX_WIDTH+`REGEXT_WIDTH+22]   ;
  assign deq_in3_o         = deq_bits[`XLEN*`NUM_THREAD+`NUM_THREAD+`DEPTH_WARP+`REGIDX_WIDTH+`REGEXT_WIDTH+22-1  :`NUM_THREAD+`DEPTH_WARP+`REGIDX_WIDTH+`REGEXT_WIDTH+22]                     ;
  assign deq_mask_o        = deq_bits[`NUM_THREAD+`DEPTH_WARP+`REGIDX_WIDTH+`REGEXT_WIDTH+22-1                    :`DEPTH_WARP+`REGIDX_WIDTH+`REGEXT_WIDTH+22]                                 ;
  assign deq_wid_o         = deq_bits[`DEPTH_WARP+`REGIDX_WIDTH+`REGEXT_WIDTH+22-1                                :`REGIDX_WIDTH+`REGEXT_WIDTH+22]                                             ;
  assign deq_isvec_o       = deq_bits[`REGIDX_WIDTH+`REGEXT_WIDTH+22-1]                                                                                                                        ;
  assign deq_mem_whb_o     = deq_bits[`REGIDX_WIDTH+`REGEXT_WIDTH+22-2                                            :`REGIDX_WIDTH+`REGEXT_WIDTH+22-3]                                           ;
  assign deq_mem_unsigned_o= deq_bits[`REGIDX_WIDTH+`REGEXT_WIDTH+22-4]                                                                                                                        ;
  assign deq_alu_fn_o      = deq_bits[`DEPTH_WARP+`REGIDX_WIDTH+`REGEXT_WIDTH+22-5                                :`REGIDX_WIDTH+`REGEXT_WIDTH+22-10]                                          ;
  assign deq_is_vls12_o    = deq_bits[`REGIDX_WIDTH+`REGEXT_WIDTH+22-11]                                                                                                                       ;
  assign deq_disable_mask_o= deq_bits[`REGIDX_WIDTH+`REGEXT_WIDTH+22-12]                                                                                                                       ;
  assign deq_mem_cmd_o     = deq_bits[`REGIDX_WIDTH+`REGEXT_WIDTH+22-13                                           :`REGIDX_WIDTH+`REGEXT_WIDTH+22-14]                                          ;
  assign deq_mop_o         = deq_bits[`REGIDX_WIDTH+`REGEXT_WIDTH+22-15                                           :`REGIDX_WIDTH+`REGEXT_WIDTH+22-16]                                          ;
  assign deq_reg_idxw_o    = deq_bits[`REGIDX_WIDTH+`REGEXT_WIDTH+22-17                                           :22-16]                                                                      ;
  assign deq_wvd_o         = deq_bits[22-17]                                                                                                                                                   ;
  assign deq_fence_o       = deq_bits[22-18]                                                                                                                                                   ;
  assign deq_wxd_o         = deq_bits[22-19]                                                                                                                                                   ;
  assign deq_atomic_o      = deq_bits[22-20]                                                                                                                                                   ;
  assign deq_aq_o          = deq_bits[22-21]                                                                                                                                                   ;
  assign deq_rl_o          = deq_bits[22-22]                                                                                                                                                   ;

  stream_fifo_pipe_true #(
    .DATA_WIDTH (3*`XLEN*`NUM_THREAD+`NUM_THREAD+`DEPTH_WARP+`REGIDX_WIDTH+`REGEXT_WIDTH+22),
    .FIFO_DEPTH (FIFO_DEPTH)
  )
  inputfifo (
    .clk       (clk               ),
    .rst_n     (rst_n             ),
    .w_ready_o (enq_ready_o       ),
    .w_valid_i (enq_valid_i       ),
    .w_data_i  (enq_bits          ),
    .r_valid_o (deq_valid_o       ),
    .r_ready_i (deq_ready_i       ),
    .r_data_o  (deq_bits          )
  );

endmodule

