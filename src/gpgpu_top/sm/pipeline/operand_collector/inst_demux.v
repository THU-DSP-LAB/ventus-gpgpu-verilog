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
`include "define.v"

`timescale 1ns/1ps

module inst_demux(

  // input interface
  input                                         in_valid_i                                  ,
  output                                        in_ready_o                                  ,
  input [`DEPTH_WARP-1:0]                       in_wid_i                                    ,
  input [32-1:0]                                in_inst_i                                   ,
  input [6-1:0]                                 in_imm_ext_i                                ,
  input [4-1:0]                                 in_sel_imm_i                                ,
  input [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0]       in_reg_idx1_i                               ,
  input [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0]       in_reg_idx2_i                               ,
  input [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0]       in_reg_idx3_i                               ,
  input [2-1:0]                                 in_branch_i                                 ,
  input                                         in_custom_signal_0_i                        ,
  input                                         in_isvec_i                                  ,
  input                                         in_readmask_i                               ,
  input [2-1:0]                                 in_sel_alu1_i                               ,
  input [2-1:0]                                 in_sel_alu2_i                               ,
  input [2-1:0]                                 in_sel_alu3_i                               ,
  input [32-1:0]                                in_pc_i                                     ,
  input                                         in_mask_i                                   ,

  input                                         in_fp_i                                     ,
  input                                         in_simt_stack_i                             ,
  input                                         in_simt_stack_op_i                          ,
  input                                         in_barrier_i                                ,
  input [2-1:0]                                 in_csr_i                                    ,
  input                                         in_reverse_i                                ,
  input [2-1:0]                                 in_mem_whb_i                                ,
  input                                         in_mem_unsigned_i                           ,
  input [6-1:0]                                 in_alu_fn_i                                 ,
  input                                         in_force_rm_rtz_i                           ,
  input                                         in_is_vls12_i                               ,
  input                                         in_mem_i                                    ,
  input                                         in_mul_i                                    ,
  input                                         in_tc_i                                     ,
  input                                         in_disable_mask_i                           ,
  input [2-1:0]                                 in_mem_cmd_i                                ,
  input [2-1:0]                                 in_mop_i                                    ,
  input [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0]       in_reg_idxw_i                               ,
  input                                         in_wvd_i                                    ,
  input                                         in_fence_i                                  ,
  input                                         in_sfu_i                                    ,
  //input                                         in_writemask_i                              ,
  input                                         in_wxd_i                                    ,
  input                                         in_atomic_i                                 ,
  input                                         in_aq_i                                     ,
  input                                         in_rl_i                                     ,
  input [2:0]									                  in_rm_i										                  ,
  input											                    in_rm_is_static_i							              ,

  input [(`SGPR_ID_WIDTH+1)*`NUM_WARP-1:0]      sgpr_base_i                                 ,
  input [(`VGPR_ID_WIDTH+1)*`NUM_WARP-1:0]      vgpr_base_i                                 ,

  input [`NUM_COLLECTORUNIT-1:0]                widCmp_i                                    ,

  // output interface
  output  [`NUM_COLLECTORUNIT-1:0]                               out_valid_o                ,
  input   [`NUM_COLLECTORUNIT-1:0]                               out_ready_i                ,
  output  [`DEPTH_WARP*`NUM_COLLECTORUNIT-1:0]                   out_wid_o                  ,
  output  [32*`NUM_COLLECTORUNIT-1:0]                            out_inst_o                 ,
  output  [6*`NUM_COLLECTORUNIT-1:0]                             out_imm_ext_o              ,
  output  [4*`NUM_COLLECTORUNIT-1:0]                             out_sel_imm_o              ,
  output  [(`REGIDX_WIDTH+`REGEXT_WIDTH)*`NUM_COLLECTORUNIT-1:0] out_reg_idx1_o             ,
  output  [(`REGIDX_WIDTH+`REGEXT_WIDTH)*`NUM_COLLECTORUNIT-1:0] out_reg_idx2_o             ,
  output  [(`REGIDX_WIDTH+`REGEXT_WIDTH)*`NUM_COLLECTORUNIT-1:0] out_reg_idx3_o             ,
  output  [2*`NUM_COLLECTORUNIT-1:0]                             out_branch_o               ,
  output  [`NUM_COLLECTORUNIT-1:0]                               out_custom_signal_0_o      ,
  output  [`NUM_COLLECTORUNIT-1:0]                               out_isvec_o                ,
  output  [`NUM_COLLECTORUNIT-1:0]                               out_readmask_o             ,
  output  [2*`NUM_COLLECTORUNIT-1:0]                             out_sel_alu1_o             ,
  output  [2*`NUM_COLLECTORUNIT-1:0]                             out_sel_alu2_o             ,
  output  [2*`NUM_COLLECTORUNIT-1:0]                             out_sel_alu3_o             ,
  output  [32*`NUM_COLLECTORUNIT-1:0]                            out_pc_o                   ,
  output  [`NUM_COLLECTORUNIT-1:0]                               out_mask_o                 ,

  output  [`NUM_COLLECTORUNIT-1:0]                               out_fp_o                   ,
  output  [`NUM_COLLECTORUNIT-1:0]                               out_simt_stack_o           ,
  output  [`NUM_COLLECTORUNIT-1:0]                               out_simt_stack_op_o        ,
  output  [`NUM_COLLECTORUNIT-1:0]                               out_barrier_o              ,
  output  [2*`NUM_COLLECTORUNIT-1:0]                             out_csr_o                  ,
  output  [`NUM_COLLECTORUNIT-1:0]                               out_reverse_o              ,
  output  [2*`NUM_COLLECTORUNIT-1:0]                             out_mem_whb_o              ,
  output  [`NUM_COLLECTORUNIT-1:0]                               out_mem_unsigned_o         ,
  output  [6*`NUM_COLLECTORUNIT-1:0]                             out_alu_fn_o               ,
  output  [`NUM_COLLECTORUNIT-1:0]                               out_force_rm_rtz_o         ,
  output  [`NUM_COLLECTORUNIT-1:0]                               out_is_vls12_o             ,
  output  [`NUM_COLLECTORUNIT-1:0]                               out_mem_o                  ,
  output  [`NUM_COLLECTORUNIT-1:0]                               out_mul_o                  ,
  output  [`NUM_COLLECTORUNIT-1:0]                               out_tc_o                   ,
  output  [`NUM_COLLECTORUNIT-1:0]                               out_disable_mask_o         ,
  output  [2*`NUM_COLLECTORUNIT-1:0]                             out_mem_cmd_o              ,
  output  [2*`NUM_COLLECTORUNIT-1:0]                             out_mop_o                  ,
  output  [(`REGIDX_WIDTH+`REGEXT_WIDTH)*`NUM_COLLECTORUNIT-1:0] out_reg_idxw_o             ,
  output  [`NUM_COLLECTORUNIT-1:0]                               out_wvd_o                  ,
  output  [`NUM_COLLECTORUNIT-1:0]                               out_fence_o                ,
  output  [`NUM_COLLECTORUNIT-1:0]                               out_sfu_o                  ,
  //output  [`NUM_COLLECTORUNIT-1:0]                               out_writemask_o            ,
  output  [`NUM_COLLECTORUNIT-1:0]                               out_wxd_o                  ,
  output  [`NUM_COLLECTORUNIT-1:0]                               out_atomic_o               ,
  output  [`NUM_COLLECTORUNIT-1:0]                               out_aq_o                   ,
  output  [`NUM_COLLECTORUNIT-1:0]                               out_rl_o                   ,
  output  [3*`NUM_COLLECTORUNIT-1:0]							               out_rm_o					          ,
  output  [`NUM_COLLECTORUNIT-1:0]								               out_rm_is_static_o			    ,

  output [(`SGPR_ID_WIDTH+1)*`NUM_WARP-1:0]                      sgpr_base_o                ,
  output [(`VGPR_ID_WIDTH+1)*`NUM_WARP-1:0]                      vgpr_base_o           

);

  wire [`NUM_COLLECTORUNIT-1:0]   outReady_oh;
  wire [`DEPTH_COLLECTORUNIT-1:0] outReady_bin;

  genvar i;
  generate
    for (i=0; i<`NUM_COLLECTORUNIT; i=i+1) begin:cu_loop
     // Each data on out port is identical
     assign out_wid_o               [(i+1)*`DEPTH_WARP-1-:`DEPTH_WARP]                                     = in_wid_i             ;
     assign out_inst_o              [(i+1)*32-1-:32]                                                       = in_inst_i            ;
     assign out_imm_ext_o           [(i+1)*6-1-:6]                                                         = in_imm_ext_i         ;
     assign out_sel_imm_o           [(i+1)*4-1-:4]                                                         = in_sel_imm_i         ;
     assign out_reg_idx1_o          [(i+1)*(`REGIDX_WIDTH+`REGEXT_WIDTH)-1-:(`REGIDX_WIDTH+`REGEXT_WIDTH)] = in_reg_idx1_i        ;
     assign out_reg_idx2_o          [(i+1)*(`REGIDX_WIDTH+`REGEXT_WIDTH)-1-:(`REGIDX_WIDTH+`REGEXT_WIDTH)] = in_reg_idx2_i        ;
     assign out_reg_idx3_o          [(i+1)*(`REGIDX_WIDTH+`REGEXT_WIDTH)-1-:(`REGIDX_WIDTH+`REGEXT_WIDTH)] = in_reg_idx3_i        ;
     assign out_branch_o            [(i+1)*2-1-:2]                                                         = in_branch_i          ;
     assign out_custom_signal_0_o   [i]                                                                    = in_custom_signal_0_i ;
     assign out_isvec_o             [i]                                                                    = in_isvec_i           ;
     assign out_readmask_o          [i]                                                                    = in_readmask_i        ;
     assign out_sel_alu1_o          [(i+1)*2-1-:2]                                                         = in_sel_alu1_i        ;
     assign out_sel_alu2_o          [(i+1)*2-1-:2]                                                         = in_sel_alu2_i        ;
     assign out_sel_alu3_o          [(i+1)*2-1-:2]                                                         = in_sel_alu3_i        ;
     assign out_pc_o                [(i+1)*32-1-:32]                                                       = in_pc_i              ;
     assign out_mask_o              [i]                                                                    = in_mask_i            ;
     assign out_fp_o                [i]                                                                    = in_fp_i              ;
     assign out_simt_stack_o        [i]                                                                    = in_simt_stack_i      ;
     assign out_simt_stack_op_o     [i]                                                                    = in_simt_stack_op_i   ;
     assign out_barrier_o           [i]                                                                    = in_barrier_i         ;
     assign out_csr_o               [2*(i+1)-1-:2]                                                         = in_csr_i             ;
     assign out_reverse_o           [i]                                                                    = in_reverse_i         ;
     assign out_mem_whb_o           [2*(i+1)-1-:2]                                                         = in_mem_whb_i         ;
     assign out_mem_unsigned_o      [i]                                                                    = in_mem_unsigned_i    ;
     assign out_alu_fn_o            [6*(i+1)-1-:6]                                                         = in_alu_fn_i          ;
     assign out_force_rm_rtz_o      [i]                                                                    = in_force_rm_rtz_i    ;
     assign out_is_vls12_o          [i]                                                                    = in_is_vls12_i        ;
     assign out_mem_o               [i]                                                                    = in_mem_i             ;
     assign out_mul_o               [i]                                                                    = in_mul_i             ;
     assign out_tc_o                [i]                                                                    = in_tc_i              ;
     assign out_disable_mask_o      [i]                                                                    = in_disable_mask_i    ;
     assign out_mem_cmd_o           [2*(i+1)-1-:2]                                                         = in_mem_cmd_i         ;
     assign out_mop_o               [2*(i+1)-1-:2]                                                         = in_mop_i             ;
     assign out_reg_idxw_o          [(`REGIDX_WIDTH+`REGEXT_WIDTH)*(i+1)-1-:(`REGIDX_WIDTH+`REGEXT_WIDTH)] = in_reg_idxw_i        ;
     assign out_wvd_o               [i]                                                                    = in_wvd_i             ;
     assign out_fence_o             [i]                                                                    = in_fence_i           ;
     assign out_sfu_o               [i]                                                                    = in_sfu_i             ;
     //assign out_writemask_o         [i]                                                                    = in_writemask_i       ;
     assign out_wxd_o               [i]                                                                    = in_wxd_i             ;
     assign out_atomic_o            [i]                                                                    = in_atomic_i          ;
     assign out_aq_o                [i]                                                                    = in_aq_i              ;
     assign out_rl_o                [i]                                                                    = in_rl_i              ;
	   assign out_rm_o			          [3*(i+1)-1-:3]														                             = in_rm_i			        ;
	   assign out_rm_is_static_o		  [i]																	                                   = in_rm_is_static_i    ;

     assign out_valid_o[i] = (outReady_bin==i ? 1'b1 : 1'b0) && in_valid_i;// outReady_bin from PriorityEncoder
    end
  endgenerate

  assign in_ready_o  = !(|widCmp_i) && (|out_ready_i);
  assign sgpr_base_o = sgpr_base_i;
  assign vgpr_base_o = vgpr_base_i;

  fixed_pri_arb #(
    .ARB_WIDTH(`NUM_COLLECTORUNIT)
  )
  U_fixed_pri_arb
  (
    .req(out_ready_i),
    .grant(outReady_oh)
  );

  one2bin #(
    .ONE_WIDTH(`NUM_COLLECTORUNIT),
    .BIN_WIDTH(`DEPTH_COLLECTORUNIT)
  )
  U_one2bin
  (
    .oh(outReady_oh),
    .bin(outReady_bin)    
  );


endmodule
