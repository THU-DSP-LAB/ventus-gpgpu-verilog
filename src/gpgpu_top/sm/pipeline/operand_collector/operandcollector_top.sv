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

module operandcollector_top(
  input                                         clk                                        ,
  input                                         rst_n                                      ,
  
  // ibuffer2issue interface
  input                                         in_valid_i                                 ,
  output                                        in_ready_o                                 ,
  input [`DEPTH_WARP-1:0]                       in_wid_i                                   ,
  input [32-1:0]                                in_inst_i                                  ,
  input [6-1:0]                                 in_imm_ext_i                               ,
  input [4-1:0]                                 in_sel_imm_i                               ,
  input [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0]       in_reg_idx1_i                              ,
  input [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0]       in_reg_idx2_i                              ,
  input [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0]       in_reg_idx3_i                              ,
  input [2-1:0]                                 in_branch_i                                ,
  input                                         in_custom_signal_0_i                       ,
  input                                         in_isvec_i                                 ,
  input                                         in_readmask_i                              ,
  input [2-1:0]                                 in_sel_alu1_i                              ,
  input [2-1:0]                                 in_sel_alu2_i                              ,
  input [2-1:0]                                 in_sel_alu3_i                              ,
  input [32-1:0]                                in_pc_i                                    ,
  input                                         in_mask_i                                  ,
  input                                         in_fp_i                                    ,
  input                                         in_simt_stack_i                            ,
  input                                         in_simt_stack_op_i                         ,
  input                                         in_barrier_i                               ,
  input [2-1:0]                                 in_csr_i                                   ,
  input                                         in_reverse_i                               ,
  input [2-1:0]                                 in_mem_whb_i                               ,
  input                                         in_mem_unsigned_i                          ,
  input [6-1:0]                                 in_alu_fn_i                                ,
  input                                         in_force_rm_rtz_i                          ,
  input                                         in_is_vls12_i                              ,
  input                                         in_mem_i                                   ,
  input                                         in_mul_i                                   ,
  input                                         in_tc_i                                    ,
  input                                         in_disable_mask_i                          ,
  input [2-1:0]                                 in_mem_cmd_i                               ,
  input [2-1:0]                                 in_mop_i                                   ,
  input [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0]       in_reg_idxw_i                              ,
  input                                         in_wvd_i                                   ,
  input                                         in_fence_i                                 ,
  input                                         in_sfu_i                                   ,
  //input                                         in_writemask_i                             ,
  input                                         in_wxd_i                                   ,
  input                                         in_atomic_i                                ,
  input                                         in_aq_i                                    ,
  input                                         in_rl_i                                    ,
  input [2:0]									                  in_rm_i									                   ,
  input											                    in_rm_is_static_i						               ,

  // writeback interface
  input                                         writeScalar_valid_i                        ,
  output                                        writeScalar_ready_o                        ,
  input [`XLEN-1:0]                             writeScalar_rd_i                           ,
  input                                         writeScalar_wxd_i                          ,
  input [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0]       writeScalar_idxw_i                         ,
  input [`DEPTH_WARP-1:0]                       writeScalar_wid_i                          ,

  input                                         writeVector_valid_i                        ,
  output                                        writeVector_ready_o                        ,
  input [`XLEN*`NUM_THREAD-1:0]                 writeVector_rd_i                           ,
  input [`NUM_THREAD-1:0]                       writeVector_wvd_mask_i                     ,
  input                                         writeVector_wvd_i                          ,
  input [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0]       writeVector_idxw_i                         ,
  input [`DEPTH_WARP-1:0]                       writeVector_wid_i                          ,

  // csrfile interface
  input [(`SGPR_ID_WIDTH+1)*`NUM_WARP-1:0]      sgpr_base_i                                ,
  input [(`VGPR_ID_WIDTH+1)*`NUM_WARP-1:0]      vgpr_base_i                                ,

  // to exe_data
  output reg                                    out_valid_o                                ,
  input                                         out_ready_i                                ,
  output reg [`DEPTH_WARP-1:0]                  out_wid_o                                  ,
  output reg [32-1:0]                           out_inst_o                                 ,
  //output reg    [6-1:0]                            out_imm_ext_o                              ,
  //output reg    [4-1:0]                            out_sel_imm_o                              ,
  //output reg    [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0]  out_reg_idx1_o                             ,
  //output reg    [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0]  out_reg_idx2_o                             ,
  //output reg    [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0]  out_reg_idx3_o                             ,
  output reg [2-1:0]                            out_branch_o                               ,
  output reg                                    out_custom_signal_0_o                      ,
  output reg                                    out_isvec_o                                ,
  //output reg                                       out_readmask_o                             ,
  //output reg    [2-1:0]                            out_sel_alu1_o                             ,
  //output reg    [2-1:0]                            out_sel_alu2_o                             ,
  //output reg    [2-1:0]                            out_sel_alu3_o                             ,
  output reg [32-1:0]                           out_pc_o                                   ,
  //output reg                                       out_mask_o                                 ,
  output reg                                    out_fp_o                                   ,
  output reg                                    out_simt_stack_o                           ,
  output reg                                    out_simt_stack_op_o                        ,
  output reg                                    out_barrier_o                              ,
  output reg [2-1:0]                            out_csr_o                                  ,
  output reg                                    out_reverse_o                              ,
  output reg [2-1:0]                            out_mem_whb_o                              ,
  output reg                                    out_mem_unsigned_o                         ,
  output reg [6-1:0]                            out_alu_fn_o                               ,
  output reg                                    out_force_rm_rtz_o                         ,
  output reg                                    out_is_vls12_o                             ,
  output reg                                    out_mem_o                                  ,
  output reg                                    out_mul_o                                  ,
  output reg                                    out_tc_o                                   ,
  output reg                                    out_disable_mask_o                         ,
  output reg [2-1:0]                            out_mem_cmd_o                              ,
  output reg [2-1:0]                            out_mop_o                                  ,
  output reg [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0]  out_reg_idxw_o                             ,
  output reg                                    out_wvd_o                                  ,
  output reg                                    out_fence_o                                ,
  output reg                                    out_sfu_o                                  ,
  //output reg                                       out_writemask_o                            ,
  output reg                                    out_wxd_o                                  ,
  output reg                                    out_atomic_o                               ,
  output reg                                    out_aq_o                                   ,
  output reg                                    out_rl_o                                   ,  
  output reg [2:0]								              out_rm_o								                   ,
  output reg 								                    out_rm_is_static_o						             ,

  output reg [`XLEN*`NUM_THREAD-1:0]           out_alu_src1_o                              ,
  output reg [`XLEN*`NUM_THREAD-1:0]           out_alu_src2_o                              ,
  output reg [`XLEN*`NUM_THREAD-1:0]           out_alu_src3_o                              ,
  output reg [`NUM_THREAD-1:0]                 out_active_mask_o                           
);

  parameter DEPTH_4_COLLECTORUNIT = $clog2(4*`NUM_COLLECTORUNIT);
  
  // connecting demux and cu
  wire [`NUM_COLLECTORUNIT-1:0]                              demux_out_valid            ;
  wire [`NUM_COLLECTORUNIT-1:0]                              demux_out_ready            ;
  wire [`DEPTH_WARP*`NUM_COLLECTORUNIT-1:0]                  demux_out_wid              ;
  wire [32*`NUM_COLLECTORUNIT-1:0]                           demux_out_inst             ;
  wire [6*`NUM_COLLECTORUNIT-1:0]                            demux_out_imm_ext          ;
  wire [4*`NUM_COLLECTORUNIT-1:0]                            demux_out_sel_imm          ;
  wire [(`REGIDX_WIDTH+`REGEXT_WIDTH)*`NUM_COLLECTORUNIT-1:0]demux_out_reg_idx1         ;
  wire [(`REGIDX_WIDTH+`REGEXT_WIDTH)*`NUM_COLLECTORUNIT-1:0]demux_out_reg_idx2         ;
  wire [(`REGIDX_WIDTH+`REGEXT_WIDTH)*`NUM_COLLECTORUNIT-1:0]demux_out_reg_idx3         ;
  wire [2*`NUM_COLLECTORUNIT-1:0]                            demux_out_branch           ;
  wire [`NUM_COLLECTORUNIT-1:0]                              demux_out_custom_signal_0  ;
  wire [`NUM_COLLECTORUNIT-1:0]                              demux_out_isvec            ;
  wire [`NUM_COLLECTORUNIT-1:0]                              demux_out_readmask         ;
  wire [2*`NUM_COLLECTORUNIT-1:0]                            demux_out_sel_alu1         ;
  wire [2*`NUM_COLLECTORUNIT-1:0]                            demux_out_sel_alu2         ;
  wire [2*`NUM_COLLECTORUNIT-1:0]                            demux_out_sel_alu3         ;
  wire [32*`NUM_COLLECTORUNIT-1:0]                           demux_out_pc               ;
  wire [`NUM_COLLECTORUNIT-1:0]                              demux_out_mask             ;
  wire [`NUM_COLLECTORUNIT-1:0]                              demux_out_fp               ;
  wire [`NUM_COLLECTORUNIT-1:0]                              demux_out_simt_stack       ;
  wire [`NUM_COLLECTORUNIT-1:0]                              demux_out_simt_stack_op    ;
  wire [`NUM_COLLECTORUNIT-1:0]                              demux_out_barrier          ;
  wire [2*`NUM_COLLECTORUNIT-1:0]                            demux_out_csr              ;
  wire [`NUM_COLLECTORUNIT-1:0]                              demux_out_reverse          ;
  wire [2*`NUM_COLLECTORUNIT-1:0]                            demux_out_mem_whb          ;
  wire [`NUM_COLLECTORUNIT-1:0]                              demux_out_mem_unsigned     ;
  wire [6*`NUM_COLLECTORUNIT-1:0]                            demux_out_alu_fn           ;
  wire [`NUM_COLLECTORUNIT-1:0]                              demux_out_force_rm_rtz     ;
  wire [`NUM_COLLECTORUNIT-1:0]                              demux_out_is_vls12         ;
  wire [`NUM_COLLECTORUNIT-1:0]                              demux_out_mem              ;
  wire [`NUM_COLLECTORUNIT-1:0]                              demux_out_mul              ;
  wire [`NUM_COLLECTORUNIT-1:0]                              demux_out_tc               ;
  wire [`NUM_COLLECTORUNIT-1:0]                              demux_out_disable_mask     ;
  wire [2*`NUM_COLLECTORUNIT-1:0]                            demux_out_mem_cmd          ;
  wire [2*`NUM_COLLECTORUNIT-1:0]                            demux_out_mop              ;
  wire [(`REGIDX_WIDTH+`REGEXT_WIDTH)*`NUM_COLLECTORUNIT-1:0]demux_out_reg_idxw         ;
  wire [`NUM_COLLECTORUNIT-1:0]                              demux_out_wvd              ;
  wire [`NUM_COLLECTORUNIT-1:0]                              demux_out_fence            ;
  wire [`NUM_COLLECTORUNIT-1:0]                              demux_out_sfu              ;
  //wire [`NUM_COLLECTORUNIT-1:0]                              demux_out_writemask        ;
  wire [`NUM_COLLECTORUNIT-1:0]                              demux_out_wxd              ;
  wire [`NUM_COLLECTORUNIT-1:0]                              demux_out_atomic           ;
  wire [`NUM_COLLECTORUNIT-1:0]                              demux_out_aq               ;
  wire [`NUM_COLLECTORUNIT-1:0]                              demux_out_rl               ;
  wire [3*`NUM_COLLECTORUNIT-1:0]							               demux_out_rm				        ;
  wire [`NUM_COLLECTORUNIT-1:0]								               demux_out_rm_is_static		  ;

  wire [(`SGPR_ID_WIDTH+1)*`NUM_WARP-1:0]                    demux_out_sgpr_base        ;
  wire [(`VGPR_ID_WIDTH+1)*`NUM_WARP-1:0]                    demux_out_vgpr_base        ;

  // connecting cu and Arbiters
  wire [4*`NUM_COLLECTORUNIT-1:0]                            arbiter_in_valid           ;
  //wire [4*`NUM_COLLECTORUNIT-1:0]                            arbiter_in_ready           ;
  wire [`DEPTH_BANK*4*`NUM_COLLECTORUNIT-1:0]                arbiter_in_bankID          ;
  wire [2*4*`NUM_COLLECTORUNIT-1:0]                          arbiter_in_rsType          ;
  wire [`DEPTH_REGBANK*4*`NUM_COLLECTORUNIT-1:0]             arbiter_in_rsAddr          ;

  // connecting Arbiters and banks
  wire [DEPTH_4_COLLECTORUNIT*`NUM_BANK-1:0]                 arbiter_out_chosen_scalar  ;
  wire [DEPTH_4_COLLECTORUNIT*`NUM_BANK-1:0]                 arbiter_out_chosen_vector  ;
  wire [`NUM_BANK-1:0]                                       arbiter_out_scalar_valid   ;
  wire [`NUM_BANK-1:0]                                       arbiter_out_vector_valid   ;
  wire [`DEPTH_REGBANK*`NUM_BANK-1:0]                        arbiter_out_scalar_rsAddr  ;
  wire [`DEPTH_REGBANK*`NUM_BANK-1:0]                        arbiter_out_vector_rsAddr  ;
  //wire [`DEPTH_BANK*`NUM_BANK-1:0]                           arbiter_out_scalar_bankID  ;
  //wire [`DEPTH_BANK*`NUM_BANK-1:0]                           arbiter_out_vector_bankID  ;
  //wire [2*`NUM_BANK-1:0]                                     arbiter_out_scalar_rsType  ;
  //wire [2*`NUM_BANK-1:0]                                     arbiter_out_vector_rsType  ;

  // connecting banks and crossbar
  //wire [`XLEN*`NUM_BANK-1:0]                                 crossbar_in_scalar_rs      ;
  //wire [`XLEN*`NUM_THREAD*`NUM_BANK-1:0]                     crossbar_in_vector_rs      ;
  //wire [`XLEN*`NUM_THREAD*`NUM_BANK-1:0]                     crossbar_in_vector_v0      ;
  wire [`XLEN-1:0]                              crossbar_in_scalar_rs [`NUM_BANK-1:0]     ;
  wire [`XLEN*`NUM_THREAD-1:0]                  crossbar_in_vector_rs [`NUM_BANK-1:0]     ;
  wire [`XLEN*`NUM_THREAD-1:0]                  crossbar_in_vector_v0 [`NUM_BANK-1:0]     ;

  // connecting crossbar and cu
  //wire [4*`NUM_COLLECTORUNIT-1:0]                            crossbar_out_valid         ; 
  ////wire [4*`NUM_COLLECTORUNIT-1:0]                            crossbar_out_ready         ; 
  //wire [2*4*`NUM_COLLECTORUNIT-1:0]                          crossbar_out_regOrder      ; 
  //wire [`XLEN*`NUM_THREAD*4*`NUM_COLLECTORUNIT-1:0]          crossbar_out_data          ; 
  //wire [`XLEN*`NUM_THREAD*4*`NUM_COLLECTORUNIT-1:0]          crossbar_out_v0            ; 
  wire [4-1:0]                            crossbar_out_valid    [`NUM_COLLECTORUNIT-1:0]     ; 
  wire [2*4-1:0]                          crossbar_out_regOrder [`NUM_COLLECTORUNIT-1:0]     ; 
  wire [`XLEN*`NUM_THREAD*4-1:0]          crossbar_out_data     [`NUM_COLLECTORUNIT-1:0]     ; 
  wire [`XLEN*`NUM_THREAD*4-1:0]          crossbar_out_v0       [`NUM_COLLECTORUNIT-1:0]     ; 
  
  wire [2-1:0]              wb_vector_bankID  ;
  wire [2-1:0]              wb_scalar_bankID  ;
  wire [`DEPTH_REGBANK-1:0] wb_vector_rsAddr  ;
  wire [`DEPTH_REGBANK-1:0] wb_scalar_rsAddr  ;
  reg  [`NUM_BANK-1:0]      vector_bank_rdwen ;
  reg  [`NUM_BANK-1:0]      scalar_bank_rdwen ;
  
  wire [`NUM_COLLECTORUNIT-1:0]                                  issue_arbiter_valid              ;    
  wire [`NUM_COLLECTORUNIT-1:0]                                  issue_arbiter_ready              ;                    
  wire [`DEPTH_WARP*`NUM_COLLECTORUNIT-1:0]                      issue_arbiter_wid                ; 
  wire [32*`NUM_COLLECTORUNIT-1:0]                               issue_arbiter_inst               ; 
  //wire [6*`NUM_COLLECTORUNIT-1:0]                                issue_arbiter_imm_ext            ; 
  //wire [4*`NUM_COLLECTORUNIT-1:0]                                issue_arbiter_sel_imm            ; 
  //wire [(`REGIDX_WIDTH+`REGEXT_WIDTH)*`NUM_COLLECTORUNIT-1:0]    issue_arbiter_reg_idx1           ; 
  //wire [(`REGIDX_WIDTH+`REGEXT_WIDTH)*`NUM_COLLECTORUNIT-1:0]    issue_arbiter_reg_idx2           ; 
  //wire [(`REGIDX_WIDTH+`REGEXT_WIDTH)*`NUM_COLLECTORUNIT-1:0]    issue_arbiter_reg_idx3           ; 
  wire [2*`NUM_COLLECTORUNIT-1:0]                                issue_arbiter_branch             ; 
  wire [`NUM_COLLECTORUNIT-1:0]                                  issue_arbiter_custom_signal_0    ; 
  wire [`NUM_COLLECTORUNIT-1:0]                                  issue_arbiter_isvec              ; 
  wire [`NUM_COLLECTORUNIT-1:0]                                  issue_arbiter_readmask           ; 
  //wire [2*`NUM_COLLECTORUNIT-1:0]                                issue_arbiter_sel_alu1           ; 
  //wire [2*`NUM_COLLECTORUNIT-1:0]                                issue_arbiter_sel_alu2           ; 
  //wire [2*`NUM_COLLECTORUNIT-1:0]                                issue_arbiter_sel_alu3           ; 
  wire [32*`NUM_COLLECTORUNIT-1:0]                               issue_arbiter_pc                 ; 
  wire [`NUM_COLLECTORUNIT-1:0]                                  issue_arbiter_mask               ; 
  wire [`NUM_COLLECTORUNIT-1:0]                                  issue_arbiter_fp                 ;
  wire [`NUM_COLLECTORUNIT-1:0]                                  issue_arbiter_simt_stack         ;
  wire [`NUM_COLLECTORUNIT-1:0]                                  issue_arbiter_simt_stack_op      ;
  wire [`NUM_COLLECTORUNIT-1:0]                                  issue_arbiter_barrier            ;
  wire [2*`NUM_COLLECTORUNIT-1:0]                                issue_arbiter_csr                ;
  wire [`NUM_COLLECTORUNIT-1:0]                                  issue_arbiter_reverse            ;
  wire [2*`NUM_COLLECTORUNIT-1:0]                                issue_arbiter_mem_whb            ;
  wire [`NUM_COLLECTORUNIT-1:0]                                  issue_arbiter_mem_unsigned       ;
  wire [6*`NUM_COLLECTORUNIT-1:0]                                issue_arbiter_alu_fn             ;
  wire [`NUM_COLLECTORUNIT-1:0]                                  issue_arbiter_force_rm_rtz       ;
  wire [`NUM_COLLECTORUNIT-1:0]                                  issue_arbiter_is_vls12           ;
  wire [`NUM_COLLECTORUNIT-1:0]                                  issue_arbiter_mem                ;
  wire [`NUM_COLLECTORUNIT-1:0]                                  issue_arbiter_mul                ;
  wire [`NUM_COLLECTORUNIT-1:0]                                  issue_arbiter_tc                 ;
  wire [`NUM_COLLECTORUNIT-1:0]                                  issue_arbiter_disable_mask       ;
  wire [2*`NUM_COLLECTORUNIT-1:0]                                issue_arbiter_mem_cmd            ;
  wire [2*`NUM_COLLECTORUNIT-1:0]                                issue_arbiter_mop                ;
  wire [(`REGIDX_WIDTH+`REGEXT_WIDTH)*`NUM_COLLECTORUNIT-1:0]    issue_arbiter_reg_idxw           ;
  wire [`NUM_COLLECTORUNIT-1:0]                                  issue_arbiter_wvd                ;
  wire [`NUM_COLLECTORUNIT-1:0]                                  issue_arbiter_fence              ;
  wire [`NUM_COLLECTORUNIT-1:0]                                  issue_arbiter_sfu                ;
  wire [`NUM_COLLECTORUNIT-1:0]                                  issue_arbiter_writemask          ;
  wire [`NUM_COLLECTORUNIT-1:0]                                  issue_arbiter_wxd                ;
  wire [`NUM_COLLECTORUNIT-1:0]                                  issue_arbiter_atomic             ;
  wire [`NUM_COLLECTORUNIT-1:0]                                  issue_arbiter_aq                 ;
  wire [`NUM_COLLECTORUNIT-1:0]                                  issue_arbiter_rl                 ;
  wire [3*`NUM_COLLECTORUNIT-1:0]								                 issue_arbiter_rm				          ;
  wire [`NUM_COLLECTORUNIT-1:0]									                 issue_arbiter_rm_is_static		    ;

  wire [`XLEN*`NUM_THREAD*`NUM_COLLECTORUNIT-1:0]                issue_arbiter_alu_src1           ; 
  wire [`XLEN*`NUM_THREAD*`NUM_COLLECTORUNIT-1:0]                issue_arbiter_alu_src2           ;           
  wire [`XLEN*`NUM_THREAD*`NUM_COLLECTORUNIT-1:0]                issue_arbiter_alu_src3           ;         
  wire [`NUM_THREAD*`NUM_COLLECTORUNIT-1:0]                      issue_arbiter_active_mask        ;               

  wire [`NUM_COLLECTORUNIT-1:0]                                  issue_arbiter_valid_oh           ;    
  wire [`DEPTH_COLLECTORUNIT-1:0]                                issue_arbiter_valid_bin          ;    
  
  wire [`NUM_COLLECTORUNIT-1:0]                                  widCmp                           ;
  
  //assign issue_arbiter_ready[0]   = out_ready_i;
  //genvar n;
  //generate
  //  for (n=0; n<`NUM_COLLECTORUNIT-1; n=n+1) begin:cu_loop_1
  //    assign issue_arbiter_ready[n+1] = issue_arbiter_ready[n] && !issue_arbiter_valid[n];
  //  end
  //endgenerate
  
  genvar n;
  generate
    for (n=0; n<`NUM_COLLECTORUNIT; n=n+1) begin:cu_loop_1
      assign issue_arbiter_ready[n] = (n==issue_arbiter_valid_bin) ? out_ready_i : 1'b0;
    end
  endgenerate
  

  genvar k;
  generate
    for (k=0; k<`NUM_COLLECTORUNIT; k=k+1) begin:cu_loop_2
      //assign widCmp[k] = in_wid_i==out_wid_o[`DEPTH_WARP*(k+1)-1-:`DEPTH_WARP];
      assign widCmp[k] = 1'b0;
    end
  endgenerate

  always @(*) begin
    if (issue_arbiter_valid_oh[issue_arbiter_valid_bin])begin        
      out_valid_o           = issue_arbiter_valid          [issue_arbiter_valid_bin]                                                                    ;
      out_wid_o             = issue_arbiter_wid            [`DEPTH_WARP*(issue_arbiter_valid_bin+1)-1-:`DEPTH_WARP]                                     ;
      out_inst_o            = issue_arbiter_inst           [32*(issue_arbiter_valid_bin+1)-1-:32]                                                       ;
      //assign out_imm_ext_o         = issue_arbiter_imm_ext        [6*(issue_arbiter_valid_bin+1)-1-:6]                                                         ;
      //assign out_sel_imm_o         = issue_arbiter_sel_imm        [4*(issue_arbiter_valid_bin+1)-1-:4]                                                         ;
      //assign out_reg_idx1_o        = issue_arbiter_reg_idx1       [(`REGIDX_WIDTH+`REGEXT_WIDTH)*(issue_arbiter_valid_bin+1)-1-:(`REGIDX_WIDTH+`REGEXT_WIDTH)] ;
      //assign out_reg_idx2_o        = issue_arbiter_reg_idx2       [(`REGIDX_WIDTH+`REGEXT_WIDTH)*(issue_arbiter_valid_bin+1)-1-:(`REGIDX_WIDTH+`REGEXT_WIDTH)] ;
      //assign out_reg_idx3_o        = issue_arbiter_reg_idx3       [(`REGIDX_WIDTH+`REGEXT_WIDTH)*(issue_arbiter_valid_bin+1)-1-:(`REGIDX_WIDTH+`REGEXT_WIDTH)] ;
      out_branch_o          = issue_arbiter_branch         [2*(issue_arbiter_valid_bin+1)-1-:2]                                                         ;
      out_custom_signal_0_o = issue_arbiter_custom_signal_0[issue_arbiter_valid_bin]                                                                    ;
      out_isvec_o           = issue_arbiter_isvec          [issue_arbiter_valid_bin]                                                                    ;
      //assign out_readmask_o        = issue_arbiter_readmask       [issue_arbiter_valid_bin]                                                                    ;
      //assign out_sel_alu1_o        = issue_arbiter_sel_alu1       [2*(issue_arbiter_valid_bin+1)-1-:2]                                                         ;
      //assign out_sel_alu2_o        = issue_arbiter_sel_alu2       [2*(issue_arbiter_valid_bin+1)-1-:2]                                                         ;
      //assign out_sel_alu3_o        = issue_arbiter_sel_alu3       [2*(issue_arbiter_valid_bin+1)-1-:2]                                                         ;
      out_pc_o              = issue_arbiter_pc             [32*(issue_arbiter_valid_bin+1)-1-:32]                                                       ;
      //assign out_mask_o            = issue_arbiter_mask           [issue_arbiter_valid_bin]                                                                    ;
      out_fp_o              = issue_arbiter_fp             [issue_arbiter_valid_bin]                                                                    ;                       
      out_simt_stack_o      = issue_arbiter_simt_stack     [issue_arbiter_valid_bin]                                                                    ;                       
      out_simt_stack_op_o   = issue_arbiter_simt_stack_op  [issue_arbiter_valid_bin]                                                                    ;                       
      out_barrier_o         = issue_arbiter_barrier        [issue_arbiter_valid_bin]                                                                    ;                       
      out_csr_o             = issue_arbiter_csr            [2*(issue_arbiter_valid_bin+1)-1-:2]                                                         ;                       
      out_reverse_o         = issue_arbiter_reverse        [issue_arbiter_valid_bin]                                                                    ;                       
      out_mem_whb_o         = issue_arbiter_mem_whb        [2*(issue_arbiter_valid_bin+1)-1-:2]                                                         ;                       
      out_mem_unsigned_o    = issue_arbiter_mem_unsigned   [issue_arbiter_valid_bin]                                                                    ;                       
      out_alu_fn_o          = issue_arbiter_alu_fn         [6*(issue_arbiter_valid_bin+1)-1-:6]                                                         ;                       
      out_force_rm_rtz_o    = issue_arbiter_force_rm_rtz   [issue_arbiter_valid_bin]                                                                    ;                       
      out_is_vls12_o        = issue_arbiter_is_vls12       [issue_arbiter_valid_bin]                                                                    ;                       
      out_mem_o             = issue_arbiter_mem            [issue_arbiter_valid_bin]                                                                    ;                       
      out_mul_o             = issue_arbiter_mul            [issue_arbiter_valid_bin]                                                                    ;                       
      out_tc_o              = issue_arbiter_tc             [issue_arbiter_valid_bin]                                                                    ;                       
      out_disable_mask_o    = issue_arbiter_disable_mask   [issue_arbiter_valid_bin]                                                                    ;                       
      out_mem_cmd_o         = issue_arbiter_mem_cmd        [2*(issue_arbiter_valid_bin+1)-1-:2]                                                         ;                       
      out_mop_o             = issue_arbiter_mop            [2*(issue_arbiter_valid_bin+1)-1-:2]                                                         ;                       
      out_reg_idxw_o        = issue_arbiter_reg_idxw       [(`REGIDX_WIDTH+`REGEXT_WIDTH)*(issue_arbiter_valid_bin+1)-1-:(`REGIDX_WIDTH+`REGEXT_WIDTH)] ;                       
      out_wvd_o             = issue_arbiter_wvd            [issue_arbiter_valid_bin]                                                                    ;                       
      out_fence_o           = issue_arbiter_fence          [issue_arbiter_valid_bin]                                                                    ;                       
      out_sfu_o             = issue_arbiter_sfu            [issue_arbiter_valid_bin]                                                                    ;                       
      //assign out_writemask_o       = issue_arbiter_writemask      [issue_arbiter_valid_bin]                                                                    ;                       
      out_wxd_o             = issue_arbiter_wxd            [issue_arbiter_valid_bin]                                                                    ;                       
      out_atomic_o          = issue_arbiter_atomic         [issue_arbiter_valid_bin]                                                                    ;                       
      out_aq_o              = issue_arbiter_aq             [issue_arbiter_valid_bin]                                                                    ;                       
      out_rl_o              = issue_arbiter_rl             [issue_arbiter_valid_bin]                                                                    ;
	    out_rm_o			        = issue_arbiter_rm			       [3*(issue_arbiter_valid_bin+1)-1-:3]															                            ;
	    out_rm_is_static_o    = issue_arbiter_rm_is_static   [issue_arbiter_valid_bin]																	                                  ;

      out_alu_src1_o        = issue_arbiter_alu_src1       [`XLEN*`NUM_THREAD*(issue_arbiter_valid_bin+1)-1-:`XLEN*`NUM_THREAD]                         ;
      out_alu_src2_o        = issue_arbiter_alu_src2       [`XLEN*`NUM_THREAD*(issue_arbiter_valid_bin+1)-1-:`XLEN*`NUM_THREAD]                         ;
      out_alu_src3_o        = issue_arbiter_alu_src3       [`XLEN*`NUM_THREAD*(issue_arbiter_valid_bin+1)-1-:`XLEN*`NUM_THREAD]                         ;
      out_active_mask_o     = issue_arbiter_active_mask    [`NUM_THREAD*(issue_arbiter_valid_bin+1)-1-:`NUM_THREAD]                                     ;
    end else begin
      out_valid_o           = 'b0;   
      out_wid_o             = 'b0;   
      out_inst_o            = 'b0;   
      //out_imm_ext_o         = 'b0;   
      //out_sel_imm_o         = 'b0;   
      //out_reg_idx1_o        = 'b0;   
      //out_reg_idx2_o        = 'b0;   
      //out_reg_idx3_o        = 'b0;   
      out_branch_o          = 'b0;   
      out_custom_signal_0_o = 'b0;
      out_isvec_o           = 'b0;   
      //out_readmask_o        = 'b0;   
      //out_sel_alu1_o        = 'b0;   
      //out_sel_alu2_o        = 'b0;   
      //out_sel_alu3_o        = 'b0;   
      out_pc_o              = 'b0;   
      //out_mask_o            = 'b0;   
      out_fp_o              = 'b0;                       
      out_simt_stack_o      = 'b0;                       
      out_simt_stack_op_o   = 'b0;                       
      out_barrier_o         = 'b0;                       
      out_csr_o             = 'b0;                       
      out_reverse_o         = 'b0;                       
      out_mem_whb_o         = 'b0;                       
      out_mem_unsigned_o    = 'b0;                       
      out_alu_fn_o          = 'b0;                       
      out_force_rm_rtz_o    = 'b0;                       
      out_is_vls12_o        = 'b0;                       
      out_mem_o             = 'b0;                       
      out_mul_o             = 'b0;                       
      out_tc_o              = 'b0;                       
      out_disable_mask_o    = 'b0;                       
      out_mem_cmd_o         = 'b0;                       
      out_mop_o             = 'b0;                       
      out_reg_idxw_o        = 'b0;                       
      out_wvd_o             = 'b0;                       
      out_fence_o           = 'b0;                       
      out_sfu_o             = 'b0;                       
      //out_writemask_o       = 'b0;                       
      out_wxd_o             = 'b0;                       
      out_atomic_o          = 'b0;                       
      out_aq_o              = 'b0;                       
      out_rl_o              = 'b0;
	    out_rm_o				      = 'b0;
	    out_rm_is_static_o	  = 'b0;

      out_alu_src1_o        = 'b0;   
      out_alu_src2_o        = 'b0;   
      out_alu_src3_o        = 'b0;   
      out_active_mask_o     = 'b0;
    end
  end

  reg [DEPTH_4_COLLECTORUNIT*`NUM_BANK-1:0]         chosen_scalar_q ;
  reg [DEPTH_4_COLLECTORUNIT*`NUM_BANK-1:0]         chosen_vector_q ;
  reg [`NUM_BANK-1:0]                               scalar_valid_q  ;
  reg [`NUM_BANK-1:0]                               vector_valid_q  ;
  
  wire [$clog2(4*`NUM_COLLECTORUNIT)-1:0]         chosen_scalar_tmp [`NUM_BANK-1:0];
  wire [$clog2(4*`NUM_COLLECTORUNIT)-1:0]         chosen_vector_tmp [`NUM_BANK-1:0];
  wire                                            scalar_valid_tmp  [`NUM_BANK-1:0];
  wire                                            vector_valid_tmp  [`NUM_BANK-1:0];


  // Readchosen needs to delay one tick to match bank reading
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      chosen_scalar_q <= 'b0;
      chosen_vector_q <= 'b0;
      scalar_valid_q  <= 'b0;
      vector_valid_q  <= 'b0;        
    end else begin
      chosen_scalar_q <= arbiter_out_chosen_scalar ;
      chosen_vector_q <= arbiter_out_chosen_vector ;
      scalar_valid_q  <= arbiter_out_scalar_valid  ;
      vector_valid_q  <= arbiter_out_vector_valid  ;        
    end
  end

  genvar t;
  generate
    for (t=0; t<`NUM_BANK; t=t+1) begin:tmp
      assign chosen_scalar_tmp  [t] = chosen_scalar_q [DEPTH_4_COLLECTORUNIT*(t+1)-1-:DEPTH_4_COLLECTORUNIT] ;
      assign chosen_vector_tmp  [t] = chosen_vector_q [DEPTH_4_COLLECTORUNIT*(t+1)-1-:DEPTH_4_COLLECTORUNIT] ;
      assign scalar_valid_tmp   [t] = scalar_valid_q  [t]                       ;
      assign vector_valid_tmp   [t] = vector_valid_q  [t]                       ;
    end
  endgenerate

  assign wb_vector_bankID = writeVector_wid_i[`DEPTH_BANK-1:0] + writeVector_idxw_i[`DEPTH_BANK-1:0];
  //assign wb_vector_rsAddr = (vgpr_base_i[(`VGPR_ID_WIDTH+1)*(writeVector_wid_i+1)-1-:(`VGPR_ID_WIDTH+1)] >> `DEPTH_BANK) + (writeVector_idxw_i >> `DEPTH_BANK);
  assign wb_vector_rsAddr = {{`DEPTH_BANK{1'b0}},vgpr_base_i[(`VGPR_ID_WIDTH+1)*(writeVector_wid_i+1)-1-:(`VGPR_ID_WIDTH+1-`DEPTH_BANK)]}
                          + {{`DEPTH_BANK{1'b0}},writeVector_idxw_i[`REGIDX_WIDTH+`REGEXT_WIDTH-1:`DEPTH_BANK]};
  
  assign wb_scalar_bankID = writeScalar_wid_i[`DEPTH_BANK-1:0] + writeScalar_idxw_i[`DEPTH_BANK-1:0];
  //assign wb_scalar_rsAddr = (sgpr_base_i[(`SGPR_ID_WIDTH+1)*(writeScalar_wid_i+1)-1-:(`SGPR_ID_WIDTH+1)] >> `DEPTH_BANK) + (writeScalar_idxw_i >> `DEPTH_BANK);
  assign wb_scalar_rsAddr = {{`DEPTH_BANK{1'b0}},sgpr_base_i[(`SGPR_ID_WIDTH+1)*(writeScalar_wid_i+1)-1-:(`SGPR_ID_WIDTH+1-`DEPTH_BANK)]} 
                          + {{`DEPTH_BANK{1'b0}},writeScalar_idxw_i[`REGIDX_WIDTH+`REGEXT_WIDTH-1:`DEPTH_BANK]};  

  assign writeVector_ready_o = 1'b1; 
  assign writeScalar_ready_o = 1'b1; 

  genvar m;
  generate
    for (m=0; m<`NUM_BANK; m=m+1) begin:bank_rdwen
      always@(*) begin
        if(m==wb_vector_bankID && writeVector_wvd_i && writeVector_valid_i) begin
          vector_bank_rdwen[m] = 1'b1;
          //scalar_bank_rdwen[m] = 1'b0;
        end else begin
          //scalar_bank_rdwen[m] = 1'b0;
          vector_bank_rdwen[m] = 1'b0;
        end
      end
      always@(*) begin
        if(m==wb_scalar_bankID && writeScalar_wxd_i && writeScalar_valid_i && (|writeScalar_idxw_i)) begin
          scalar_bank_rdwen[m] = 1'b1;
        end else begin
          scalar_bank_rdwen[m] = 1'b0;
        end
      end
    end
  endgenerate

  genvar i;
  generate
    for (i=0; i<`NUM_COLLECTORUNIT; i=i+1) begin:collector_units
      collector_unit U_collector_unit(
        .clk                       (clk                                                                                                    ),
        .rst_n                     (rst_n                                                                                                  ),
        .control_valid_i           (demux_out_valid           [i]                                                                          ),
        .control_ready_o           (demux_out_ready           [i]                                                                          ),
        .control_wid_i             (demux_out_wid             [`DEPTH_WARP*(i+1)-1-:`DEPTH_WARP]                                           ),
        .control_inst_i            (demux_out_inst            [32*(i+1)-1-:32]                                                             ),
        .control_imm_ext_i         (demux_out_imm_ext         [6*(i+1)-1-:6]                                                               ),
        .control_sel_imm_i         (demux_out_sel_imm         [4*(i+1)-1-:4]                                                               ),
        .control_reg_idx1_i        (demux_out_reg_idx1        [(`REGIDX_WIDTH+`REGEXT_WIDTH)*(i+1)-1-:(`REGIDX_WIDTH+`REGEXT_WIDTH)]       ),
        .control_reg_idx2_i        (demux_out_reg_idx2        [(`REGIDX_WIDTH+`REGEXT_WIDTH)*(i+1)-1-:(`REGIDX_WIDTH+`REGEXT_WIDTH)]       ),
        .control_reg_idx3_i        (demux_out_reg_idx3        [(`REGIDX_WIDTH+`REGEXT_WIDTH)*(i+1)-1-:(`REGIDX_WIDTH+`REGEXT_WIDTH)]       ),
        .control_branch_i          (demux_out_branch          [2*(i+1)-1-:2]                                                               ),
        .control_custom_signal_0_i (demux_out_custom_signal_0 [i]                                                                          ),
        .control_isvec_i           (demux_out_isvec           [i]                                                                          ),
        .control_readmask_i        (demux_out_readmask        [i]                                                                          ),
        .control_sel_alu1_i        (demux_out_sel_alu1        [2*(i+1)-1-:2]                                                               ),
        .control_sel_alu2_i        (demux_out_sel_alu2        [2*(i+1)-1-:2]                                                               ),
        .control_sel_alu3_i        (demux_out_sel_alu3        [2*(i+1)-1-:2]                                                               ),
        .control_pc_i              (demux_out_pc              [32*(i+1)-1-:32]                                                             ),
        .control_mask_i            (demux_out_mask            [i]                                                                          ),
        .control_fp_i              (demux_out_fp              [i]                                                                          ),
        .control_simt_stack_i      (demux_out_simt_stack      [i]                                                                          ),
        .control_simt_stack_op_i   (demux_out_simt_stack_op   [i]                                                                          ),
        .control_barrier_i         (demux_out_barrier         [i]                                                                          ),
        .control_csr_i             (demux_out_csr             [2*(i+1)-1-:2]                                                               ),
        .control_reverse_i         (demux_out_reverse         [i]                                                                          ),
        .control_mem_whb_i         (demux_out_mem_whb         [2*(i+1)-1-:2]                                                               ),
        .control_mem_unsigned_i    (demux_out_mem_unsigned    [i]                                                                          ),
        .control_alu_fn_i          (demux_out_alu_fn          [6*(i+1)-1-:6]                                                               ),
        .control_force_rm_rtz_i    (demux_out_force_rm_rtz    [i]                                                                          ),
        .control_is_vls12_i        (demux_out_is_vls12        [i]                                                                          ),
        .control_mem_i             (demux_out_mem             [i]                                                                          ),
        .control_mul_i             (demux_out_mul             [i]                                                                          ),
        .control_tc_i              (demux_out_tc              [i]                                                                          ),
        .control_disable_mask_i    (demux_out_disable_mask    [i]                                                                          ),
        .control_mem_cmd_i         (demux_out_mem_cmd         [2*(i+1)-1-:2]                                                               ),
        .control_mop_i             (demux_out_mop             [2*(i+1)-1-:2]                                                               ),
        .control_reg_idxw_i        (demux_out_reg_idxw        [(`REGIDX_WIDTH+`REGEXT_WIDTH)*(i+1)-1-:(`REGIDX_WIDTH+`REGEXT_WIDTH)]       ),
        .control_wvd_i             (demux_out_wvd             [i]                                                                          ),
        .control_fence_i           (demux_out_fence           [i]                                                                          ),
        .control_sfu_i             (demux_out_sfu             [i]                                                                          ),
        //.control_writemask_i       (demux_out_writemask       [i]                                                                          ),
        .control_wxd_i             (demux_out_wxd             [i]                                                                          ),
        .control_atomic_i          (demux_out_atomic          [i]                                                                          ),
        .control_aq_i              (demux_out_aq              [i]                                                                          ),
        .control_rl_i              (demux_out_rl              [i]                                                                          ),
		    .control_rm_i			         (demux_out_rm			        [3*(i+1)-1-:3]															                                 ),
		    .control_rm_is_static_i	   (demux_out_rm_is_static    [i]																		                                       ),

        //.bankIn_valid_i            (crossbar_out_valid        [4*(i+1)-1-:4]                                                            ),
        .bankIn_valid_i            (crossbar_out_valid        [i]                                                            ),
        //.bankIn_ready_o            (crossbar_out_ready        [4*(i+1)-1-:4]                                                            ), // no use
        //.bankIn_regOrder_i         (crossbar_out_regOrder     [2*4*(i+1)-1-:2*4]                                                        ),
        //.bankIn_data_i             (crossbar_out_data         [`XLEN*`NUM_THREAD*4*(i+1)-1-:`XLEN*`NUM_THREAD*4]                        ),
        //.bankIn_v0_i               (crossbar_out_v0           [`XLEN*`NUM_THREAD*4*(i+1)-1-:`XLEN*`NUM_THREAD*4]                        ),
        .bankIn_regOrder_i         (crossbar_out_regOrder     [i]                                                        ),
        .bankIn_data_i             (crossbar_out_data         [i]                        ),
        .bankIn_v0_i               (crossbar_out_v0           [i]                        ),
        //.sgpr_base_i               (demux_out_sgpr_base       [(`SGPR_ID_WIDTH+1)*(i+1)-1-:(`SGPR_ID_WIDTH+1)]),
        .sgpr_base_i               (demux_out_sgpr_base                                                                                 ),
        //.vgpr_base_i               (demux_out_vgpr_base       [(`VGPR_ID_WIDTH+1)*(i+1)-1-:(`VGPR_ID_WIDTH+1)]),
        .vgpr_base_i               (demux_out_vgpr_base                                                                                 ),
        .issue_valid_o             (issue_arbiter_valid          [i]                                                                    ),
        .issue_ready_i             (issue_arbiter_ready          [i]                                                                    ),
        //.issue_ready_i             (1'b1                              ),
        .issue_wid_o               (issue_arbiter_wid            [`DEPTH_WARP*(i+1)-1-:`DEPTH_WARP]                                     ),
        .issue_inst_o              (issue_arbiter_inst           [32*(i+1)-1-:32]                                                       ),
        //.issue_imm_ext_o           (issue_arbiter_imm_ext        [6*(i+1)-1-:6]                                                         ),
        //.issue_sel_imm_o           (issue_arbiter_sel_imm        [4*(i+1)-1-:4]                                                         ),
        //.issue_reg_idx1_o          (issue_arbiter_reg_idx1       [(`REGIDX_WIDTH+`REGEXT_WIDTH)*(i+1)-1-:(`REGIDX_WIDTH+`REGEXT_WIDTH)] ),
        //.issue_reg_idx2_o          (issue_arbiter_reg_idx2       [(`REGIDX_WIDTH+`REGEXT_WIDTH)*(i+1)-1-:(`REGIDX_WIDTH+`REGEXT_WIDTH)] ),
        //.issue_reg_idx3_o          (issue_arbiter_reg_idx3       [(`REGIDX_WIDTH+`REGEXT_WIDTH)*(i+1)-1-:(`REGIDX_WIDTH+`REGEXT_WIDTH)] ),
        .issue_branch_o            (issue_arbiter_branch         [2*(i+1)-1-:2]                                                         ),
        .issue_custom_signal_0_o   (issue_arbiter_custom_signal_0[i]                                                                    ),
        .issue_isvec_o             (issue_arbiter_isvec          [i]                                                                    ),
        //.issue_readmask_o          (issue_arbiter_readmask       [i]                                                                    ),
        //.issue_sel_alu1_o          (issue_arbiter_sel_alu1       [2*(i+1)-1-:2]                                                         ),
        //.issue_sel_alu2_o          (issue_arbiter_sel_alu2       [2*(i+1)-1-:2]                                                         ),
        //.issue_sel_alu3_o          (issue_arbiter_sel_alu3       [2*(i+1)-1-:2]                                                         ),
        .issue_pc_o                (issue_arbiter_pc             [32*(i+1)-1-:32]                                                       ),
        //.issue_mask_o              (issue_arbiter_mask           [i]                                                                    ),
        .issue_fp_o                (issue_arbiter_fp             [i]                                                                    ),                     
        .issue_simt_stack_o        (issue_arbiter_simt_stack     [i]                                                                    ),                     
        .issue_simt_stack_op_o     (issue_arbiter_simt_stack_op  [i]                                                                    ),                     
        .issue_barrier_o           (issue_arbiter_barrier        [i]                                                                    ),                     
        .issue_csr_o               (issue_arbiter_csr            [2*(i+1)-1-:2]                                                         ),                     
        .issue_reverse_o           (issue_arbiter_reverse        [i]                                                                    ),                     
        .issue_mem_whb_o           (issue_arbiter_mem_whb        [2*(i+1)-1-:2]                                                         ),                     
        .issue_mem_unsigned_o      (issue_arbiter_mem_unsigned   [i]                                                                    ),                     
        .issue_alu_fn_o            (issue_arbiter_alu_fn         [6*(i+1)-1-:6]                                                         ),                     
        .issue_force_rm_rtz_o      (issue_arbiter_force_rm_rtz   [i]                                                                    ),                     
        .issue_is_vls12_o          (issue_arbiter_is_vls12       [i]                                                                    ),                     
        .issue_mem_o               (issue_arbiter_mem            [i]                                                                    ),                     
        .issue_mul_o               (issue_arbiter_mul            [i]                                                                    ),                     
        .issue_tc_o                (issue_arbiter_tc             [i]                                                                    ),                     
        .issue_disable_mask_o      (issue_arbiter_disable_mask   [i]                                                                    ),                     
        .issue_mem_cmd_o           (issue_arbiter_mem_cmd        [2*(i+1)-1-:2]                                                         ),                     
        .issue_mop_o               (issue_arbiter_mop            [2*(i+1)-1-:2]                                                         ),                     
        .issue_reg_idxw_o          (issue_arbiter_reg_idxw       [(`REGIDX_WIDTH+`REGEXT_WIDTH)*(i+1)-1-:(`REGIDX_WIDTH+`REGEXT_WIDTH)] ),                     
        .issue_wvd_o               (issue_arbiter_wvd            [i]                                                                    ),                     
        .issue_fence_o             (issue_arbiter_fence          [i]                                                                    ),                     
        .issue_sfu_o               (issue_arbiter_sfu            [i]                                                                    ),                     
        //.issue_writemask_o         (issue_arbiter_writemask      [i]                                                                    ),                     
        .issue_wxd_o               (issue_arbiter_wxd            [i]                                                                    ),                     
        .issue_atomic_o            (issue_arbiter_atomic         [i]                                                                    ),                     
        .issue_aq_o                (issue_arbiter_aq             [i]                                                                    ),                     
        .issue_rl_o                (issue_arbiter_rl             [i]                                                                    ),   
		    .issue_rm_o				         (issue_arbiter_rm			       [3*(i+1)-1-:3]															                            ),
		    .issue_rm_is_static_o	     (issue_arbiter_rm_is_static	 [i]																	                                  ),

        .issue_alu_src1_o          (issue_arbiter_alu_src1       [`XLEN*`NUM_THREAD*(i+1)-1-:`XLEN*`NUM_THREAD]                         ),
        .issue_alu_src2_o          (issue_arbiter_alu_src2       [`XLEN*`NUM_THREAD*(i+1)-1-:`XLEN*`NUM_THREAD]                         ),
        .issue_alu_src3_o          (issue_arbiter_alu_src3       [`XLEN*`NUM_THREAD*(i+1)-1-:`XLEN*`NUM_THREAD]                         ),
        .issue_active_mask_o       (issue_arbiter_active_mask    [`NUM_THREAD*(i+1)-1-:`NUM_THREAD]                                     ),

        .outArbiter_valid_o        (arbiter_in_valid             [4*(i+1)-1-:4]                                                         ),
        //.outArbiter_ready_i        (arbiter_in_ready             [4*(i+1)-1-:4]                                                         ),
        .outArbiter_bankID_o       (arbiter_in_bankID            [`DEPTH_BANK*4*(i+1)-1-:`DEPTH_BANK*4]                                 ),
        .outArbiter_rsType_o       (arbiter_in_rsType            [2*4*(i+1)-1-:2*4]                                                     ),
        .outArbiter_rsAddr_o       (arbiter_in_rsAddr            [`DEPTH_REGBANK*4*(i+1)-1-:`DEPTH_REGBANK*4]                           )
      );
    end
  endgenerate


  operand_arbiter U_operand_arbiter(
    .clk                       (clk),
    .rst_n                     (rst_n),
    .arbiter_valid_i           (arbiter_in_valid ),
    //.arbiter_ready_o           (arbiter_in_ready ),
    .arbiter_bankID_i          (arbiter_in_bankID), 
    .arbiter_rsType_i          (arbiter_in_rsType), 
    .arbiter_rsAddr_i          (arbiter_in_rsAddr),
    .scalar_valid_o            (arbiter_out_scalar_valid),
    //.scalar_ready_i            ({`NUM_BANK{1'b1}}),
    //.scalar_bankID_o           (arbiter_out_scalar_bankID), // no use 
    //.scalar_rsType_o           (arbiter_out_scalar_rsType), // no use
    .scalar_rsAddr_o           (arbiter_out_scalar_rsAddr),
    .vector_valid_o            (arbiter_out_vector_valid),
    //.vector_ready_i            ({`NUM_BANK{1'b1}}),
    //.vector_bankID_o           (arbiter_out_vector_bankID), // no use
    //.vector_rsType_o           (arbiter_out_vector_rsType), // no use
    .vector_rsAddr_o           (arbiter_out_vector_rsAddr),
    .chosen_scalar_o           (arbiter_out_chosen_scalar), 
    .chosen_vector_o           (arbiter_out_chosen_vector)  
  );

  genvar j;
  generate
    for (j=0; j<`NUM_BANK; j=j+1) begin:regfile_banks
      vector_regfile_bank U_vector_regfile_bank(
        .clk               (clk),
        .rst_n             (rst_n),
        .rsidx_i           (arbiter_out_vector_rsAddr[`DEPTH_REGBANK*(j+1)-1-:`DEPTH_REGBANK]),
        .rsren_i           (arbiter_out_vector_valid[j]),                    
        .rd_i              (writeVector_rd_i),
        .rdidx_i           (wb_vector_rsAddr),
        .rdwen_i           (vector_bank_rdwen[j]),
        .rdwmask_i         (writeVector_wvd_mask_i),
        //.rs_o              (crossbar_in_vector_rs[`XLEN*`NUM_THREAD*(j+1)-1-:`XLEN*`NUM_THREAD]),
        //.v0_o              (crossbar_in_vector_v0[`XLEN*`NUM_THREAD*(j+1)-1-:`XLEN*`NUM_THREAD])  
        .rs_o              (crossbar_in_vector_rs[j]),
        .v0_o              (crossbar_in_vector_v0[j])  
      );

      scalar_regfile_bank U_scalar_regfile_bank(
        .clk               (clk),
        .rst_n             (rst_n),
        .rsidx_i           (arbiter_out_scalar_rsAddr[`DEPTH_REGBANK*(j+1)-1-:`DEPTH_REGBANK]),
        .rsren_i           (arbiter_out_scalar_valid[j]),                    
        .rd_i              (writeScalar_rd_i),
        .rdidx_i           (wb_scalar_rsAddr),
        .rdwen_i           (scalar_bank_rdwen[j]),
        //.rs_o              (crossbar_in_scalar_rs[`XLEN*(j+1)-1-:`XLEN])  
        .rs_o              (crossbar_in_scalar_rs[j])  
      );
    end
  endgenerate

  crossbar U_crossbar(
    //.clk                       (clk),
    //.rst_n                     (rst_n),
    .chosen_scalar_i         (chosen_scalar_tmp      ), 
    .chosen_vector_i         (chosen_vector_tmp      ),
    .valid_arbiter_scalar_i  (scalar_valid_tmp       ),
    .valid_arbiter_vector_i  (vector_valid_tmp       ),
    .data_scalar_rs_i        (crossbar_in_scalar_rs       ),
    .data_vector_rs_i        (crossbar_in_vector_rs       ),
    .data_vector_v0_i        (crossbar_in_vector_v0       ),
    //.in_valid_i              (in_valid_i                  ),
    .out_valid_o             (crossbar_out_valid          ),
    //.out_ready_i             (crossbar_out_ready          ),
    .out_regOrder_o          (crossbar_out_regOrder       ),
    .out_data_o              (crossbar_out_data           ),
    .out_v0_o                (crossbar_out_v0             )
  );


  //parameter DEPTH_4_COLLECTORUNIT = $clog2(4*`NUM_COLLECTORUNIT);  

  //reg [`DEPTH_COLLECTORUNIT*`NUM_BANK-1:0]  cu_id_scalar    ;
  //reg [`DEPTH_COLLECTORUNIT*`NUM_BANK-1:0]  cu_id_vector    ;
  //reg [2*`NUM_BANK-1:0]                     regOrder_scalar ;
  //reg [2*`NUM_BANK-1:0]                     regOrder_vector ;
  //
  //reg [4*`NUM_COLLECTORUNIT*`NUM_BANK-1:0]                       out_valid_tmp             ;
  //reg [2*4*`NUM_COLLECTORUNIT*`NUM_BANK-1:0]                     out_regOrder_tmp          ;
  //reg [`XLEN*`NUM_THREAD*4*`NUM_COLLECTORUNIT*`NUM_BANK-1:0]     out_data_tmp              ;
  //reg [`XLEN*`NUM_THREAD*4*`NUM_COLLECTORUNIT*`NUM_BANK-1:0]     out_v0_tmp                ;

  //reg [4*`NUM_COLLECTORUNIT*(`NUM_BANK-1)-1:0]                       out_valid_and             ;
  //reg [2*4*`NUM_COLLECTORUNIT*(`NUM_BANK-1)-1:0]                     out_regOrder_and          ;
  //reg [`XLEN*`NUM_THREAD*4*`NUM_COLLECTORUNIT*(`NUM_BANK-1)-1:0]     out_data_and              ;
  //reg [`XLEN*`NUM_THREAD*4*`NUM_COLLECTORUNIT*(`NUM_BANK-1)-1:0]     out_v0_and                ;
  //
  //genvar n;
  //generate
  //  for (n=0; n<`NUM_BANK; n=n+1) begin:cuId_and_regOrder
  //    always @(*) begin
  //      // cu_id    = chosen / 4 
  //      // regOrder = chosen % 4 
  //      cu_id_scalar[`DEPTH_COLLECTORUNIT*(n+1)-1-:`DEPTH_COLLECTORUNIT] = chosen_scalar_q[DEPTH_4_COLLECTORUNIT*(n+1)-1-:DEPTH_4_COLLECTORUNIT] >> 2'h2;
  //      cu_id_vector[`DEPTH_COLLECTORUNIT*(n+1)-1-:`DEPTH_COLLECTORUNIT] = chosen_vector_q[DEPTH_4_COLLECTORUNIT*(n+1)-1-:DEPTH_4_COLLECTORUNIT] >> 2'h2;
  //      regOrder_scalar[2*(n+1)-1-:2] = chosen_scalar_q[DEPTH_4_COLLECTORUNIT*n+2-1-:2];
  //      regOrder_vector[2*(n+1)-1-:2] = chosen_vector_q[DEPTH_4_COLLECTORUNIT*n+2-1-:2];
  //    end
  //  end
  //endgenerate
  //
  //genvar i,j,k;
  //generate
  //  for (i=0; i<`NUM_BANK; i=i+1) begin:bank_loop
  //    for (j=0; j<`NUM_COLLECTORUNIT; j=j+1) begin:cu_loop
  //      for (k=0; k<4; k=k+1) begin:operand_loop
  //        always @(*) begin
  //          if(cu_id_scalar[`DEPTH_COLLECTORUNIT*(i+1)-1-:`DEPTH_COLLECTORUNIT]==j && valid_arbiter_scalar_i[i] && regOrder_scalar[2*(i+1)-1-:2]==k) begin
  //            out_data_tmp    [`XLEN*`NUM_THREAD*4*`NUM_COLLECTORUNIT*i+`XLEN*`NUM_THREAD*(j*4+k+1)-1-:`XLEN*`NUM_THREAD] = {`NUM_THREAD{data_scalar_rs_i[`XLEN*(i+1)-1-:`XLEN]}};
  //            out_v0_tmp      [`XLEN*`NUM_THREAD*4*`NUM_COLLECTORUNIT*i+`XLEN*`NUM_THREAD*(j*4+k+1)-1-:`XLEN*`NUM_THREAD] =  'b0;
  //            out_valid_tmp   [4*`NUM_COLLECTORUNIT*i+j*4+k]                                                              = 1'b1;
  //            out_regOrder_tmp[2*4*`NUM_COLLECTORUNIT*i+2*(j*4+k+1)-1-:2]                                                 = regOrder_scalar[2*(i+1)-1-:2];            
  //          end else if(cu_id_vector[`DEPTH_COLLECTORUNIT*(i+1)-1-:`DEPTH_COLLECTORUNIT]==j && vector_valid_q[i] && regOrder_vector[2*(i+1)-1-:2]==k) begin
  //            out_data_tmp    [`XLEN*`NUM_THREAD*4*`NUM_COLLECTORUNIT*i+`XLEN*`NUM_THREAD*(j*4+k+1)-1-:`XLEN*`NUM_THREAD] = data_vector_rs_i[`XLEN*`NUM_THREAD*(i+1)-1-:`XLEN*`NUM_THREAD];
  //            out_v0_tmp      [`XLEN*`NUM_THREAD*4*`NUM_COLLECTORUNIT*i+`XLEN*`NUM_THREAD*(j*4+k+1)-1-:`XLEN*`NUM_THREAD] = data_vector_v0_i[`XLEN*`NUM_THREAD*(i+1)-1-:`XLEN*`NUM_THREAD];
  //            out_valid_tmp   [4*`NUM_COLLECTORUNIT*i+j*4+k]                                                              = 1'b1;
  //            out_regOrder_tmp[2*4*`NUM_COLLECTORUNIT*i+2*(j*4+k+1)-1-:2]                                                 = regOrder_vector[2*(i+1)-1-:2];                      
  //          end else begin
  //            out_data_tmp    [`XLEN*`NUM_THREAD*4*`NUM_COLLECTORUNIT*i+`XLEN*`NUM_THREAD*(j*4+k+1)-1-:`XLEN*`NUM_THREAD] =  'b0;
  //            out_v0_tmp      [`XLEN*`NUM_THREAD*4*`NUM_COLLECTORUNIT*i+`XLEN*`NUM_THREAD*(j*4+k+1)-1-:`XLEN*`NUM_THREAD] =  'b0;
  //            out_valid_tmp   [4*`NUM_COLLECTORUNIT*i+j*4+k]                                                              = 1'b0;
  //            out_regOrder_tmp[2*4*`NUM_COLLECTORUNIT*i+2*(j*4+k+1)-1-:2]                                                 = 2'b0;            
  //          end
  //        end
  //      end
  //    end
  //  end
  //endgenerate
  //
  //genvar m;
  //generate
  //  for (m=0; m<`NUM_BANK-1; m=m+1) begin:output_loop
  //    always @(*) begin
  //      if(m==0) begin
  //        out_valid_and     [4*`NUM_COLLECTORUNIT*(m+1)-1-:4*`NUM_COLLECTORUNIT]                                      = out_valid_tmp     [4*`NUM_COLLECTORUNIT*(m+1)-1-:4*`NUM_COLLECTORUNIT]                                     + out_valid_tmp     [4*`NUM_COLLECTORUNIT*(m+2)-1-:4*`NUM_COLLECTORUNIT]                                     ;
  //        out_regOrder_and  [2*4*`NUM_COLLECTORUNIT*(m+1)-1-:2*4*`NUM_COLLECTORUNIT]                                  = out_regOrder_tmp  [2*4*`NUM_COLLECTORUNIT*(m+1)-1-:2*4*`NUM_COLLECTORUNIT]                                 + out_regOrder_tmp  [2*4*`NUM_COLLECTORUNIT*(m+2)-1-:2*4*`NUM_COLLECTORUNIT]                                 ;
  //        out_data_and      [`XLEN*`NUM_THREAD*4*`NUM_COLLECTORUNIT*(m+1)-1-:`XLEN*`NUM_THREAD*4*`NUM_COLLECTORUNIT]  = out_data_tmp      [`XLEN*`NUM_THREAD*4*`NUM_COLLECTORUNIT*(m+1)-1-:`XLEN*`NUM_THREAD*4*`NUM_COLLECTORUNIT] + out_data_tmp      [`XLEN*`NUM_THREAD*4*`NUM_COLLECTORUNIT*(m+2)-1-:`XLEN*`NUM_THREAD*4*`NUM_COLLECTORUNIT] ;
  //        out_v0_and        [`XLEN*`NUM_THREAD*4*`NUM_COLLECTORUNIT*(m+1)-1-:`XLEN*`NUM_THREAD*4*`NUM_COLLECTORUNIT]  = out_v0_tmp        [`XLEN*`NUM_THREAD*4*`NUM_COLLECTORUNIT*(m+1)-1-:`XLEN*`NUM_THREAD*4*`NUM_COLLECTORUNIT] + out_v0_tmp        [`XLEN*`NUM_THREAD*4*`NUM_COLLECTORUNIT*(m+2)-1-:`XLEN*`NUM_THREAD*4*`NUM_COLLECTORUNIT] ;
  //      end else begin
  //        out_valid_and     [4*`NUM_COLLECTORUNIT*(m+1)-1-:4*`NUM_COLLECTORUNIT]                                      = out_valid_and     [4*`NUM_COLLECTORUNIT*m-1-:4*`NUM_COLLECTORUNIT]                                     + out_valid_tmp     [4*`NUM_COLLECTORUNIT*(m+2)-1-:4*`NUM_COLLECTORUNIT]                                     ;
  //        out_regOrder_and  [2*4*`NUM_COLLECTORUNIT*(m+1)-1-:2*4*`NUM_COLLECTORUNIT]                                  = out_regOrder_and  [2*4*`NUM_COLLECTORUNIT*m-1-:2*4*`NUM_COLLECTORUNIT]                                 + out_regOrder_tmp  [2*4*`NUM_COLLECTORUNIT*(m+2)-1-:2*4*`NUM_COLLECTORUNIT]                                 ;
  //        out_data_and      [`XLEN*`NUM_THREAD*4*`NUM_COLLECTORUNIT*(m+1)-1-:`XLEN*`NUM_THREAD*4*`NUM_COLLECTORUNIT]  = out_data_and      [`XLEN*`NUM_THREAD*4*`NUM_COLLECTORUNIT*m-1-:`XLEN*`NUM_THREAD*4*`NUM_COLLECTORUNIT] + out_data_tmp      [`XLEN*`NUM_THREAD*4*`NUM_COLLECTORUNIT*(m+2)-1-:`XLEN*`NUM_THREAD*4*`NUM_COLLECTORUNIT] ;
  //        out_v0_and        [`XLEN*`NUM_THREAD*4*`NUM_COLLECTORUNIT*(m+1)-1-:`XLEN*`NUM_THREAD*4*`NUM_COLLECTORUNIT]  = out_v0_and        [`XLEN*`NUM_THREAD*4*`NUM_COLLECTORUNIT*m-1-:`XLEN*`NUM_THREAD*4*`NUM_COLLECTORUNIT] + out_v0_tmp        [`XLEN*`NUM_THREAD*4*`NUM_COLLECTORUNIT*(m+2)-1-:`XLEN*`NUM_THREAD*4*`NUM_COLLECTORUNIT] ;
  //      end
  //    end
  //  end
  //endgenerate


  //assign  out_valid_o      = out_valid_and    [4*`NUM_COLLECTORUNIT*(`NUM_BANK-1)-1-:4*`NUM_COLLECTORUNIT]                                    ;       
  //assign  out_regOrder_o   = out_regOrder_and [2*4*`NUM_COLLECTORUNIT*(`NUM_BANK-1)-1-:2*4*`NUM_COLLECTORUNIT]                                ;       
  //assign  out_data_o       = out_data_and     [`XLEN*`NUM_THREAD*4*`NUM_COLLECTORUNIT*(`NUM_BANK-1)-1-:`XLEN*`NUM_THREAD*4*`NUM_COLLECTORUNIT];       
  //assign  out_v0_o         = out_v0_and       [`XLEN*`NUM_THREAD*4*`NUM_COLLECTORUNIT*(`NUM_BANK-1)-1-:`XLEN*`NUM_THREAD*4*`NUM_COLLECTORUNIT];       
  

  inst_demux U_inst_demux(
    .in_valid_i                                    (in_valid_i          ),
    .in_ready_o                                    (in_ready_o          ),
    .in_wid_i                                      (in_wid_i            ),
    .in_inst_i                                     (in_inst_i           ),
    .in_imm_ext_i                                  (in_imm_ext_i        ),
    .in_sel_imm_i                                  (in_sel_imm_i        ),
    .in_reg_idx1_i                                 (in_reg_idx1_i       ),
    .in_reg_idx2_i                                 (in_reg_idx2_i       ),
    .in_reg_idx3_i                                 (in_reg_idx3_i       ),
    .in_branch_i                                   (in_branch_i         ),
    .in_custom_signal_0_i                          (in_custom_signal_0_i),
    .in_isvec_i                                    (in_isvec_i          ),
    .in_readmask_i                                 (in_readmask_i       ),
    .in_sel_alu1_i                                 (in_sel_alu1_i       ),
    .in_sel_alu2_i                                 (in_sel_alu2_i       ),
    .in_sel_alu3_i                                 (in_sel_alu3_i       ),
    .in_pc_i                                       (in_pc_i             ),
    .in_mask_i                                     (in_mask_i           ),

    .in_fp_i                                       (in_fp_i           ),
    .in_simt_stack_i                               (in_simt_stack_i   ),
    .in_simt_stack_op_i                            (in_simt_stack_op_i),
    .in_barrier_i                                  (in_barrier_i      ),
    .in_csr_i                                      (in_csr_i          ),
    .in_reverse_i                                  (in_reverse_i      ),
    .in_mem_whb_i                                  (in_mem_whb_i      ),
    .in_mem_unsigned_i                             (in_mem_unsigned_i ),
    .in_alu_fn_i                                   (in_alu_fn_i       ),
    .in_force_rm_rtz_i                             (in_force_rm_rtz_i ),
    .in_is_vls12_i                                 (in_is_vls12_i     ),
    .in_mem_i                                      (in_mem_i          ),
    .in_mul_i                                      (in_mul_i          ),
    .in_tc_i                                       (in_tc_i           ),
    .in_disable_mask_i                             (in_disable_mask_i ),
    .in_mem_cmd_i                                  (in_mem_cmd_i      ),
    .in_mop_i                                      (in_mop_i          ),
    .in_reg_idxw_i                                 (in_reg_idxw_i     ),
    .in_wvd_i                                      (in_wvd_i          ),
    .in_fence_i                                    (in_fence_i        ),
    .in_sfu_i                                      (in_sfu_i          ),
    //.in_writemask_i                                (in_writemask_i    ),
    .in_wxd_i                                      (in_wxd_i          ),
    .in_atomic_i                                   (in_atomic_i       ),
    .in_aq_i                                       (in_aq_i           ),
    .in_rl_i                                       (in_rl_i           ),
	  .in_rm_i									                     (in_rm_i			      ),
	  .in_rm_is_static_i							               (in_rm_is_static_i ),

    .sgpr_base_i                                   (sgpr_base_i),
    .vgpr_base_i                                   (vgpr_base_i),
    .widCmp_i                                      (widCmp),
    .out_valid_o                                   (demux_out_valid          ),
    .out_ready_i                                   (demux_out_ready          ),
    .out_wid_o                                     (demux_out_wid            ),
    .out_inst_o                                    (demux_out_inst           ),
    .out_imm_ext_o                                 (demux_out_imm_ext        ),
    .out_sel_imm_o                                 (demux_out_sel_imm        ),
    .out_reg_idx1_o                                (demux_out_reg_idx1       ),
    .out_reg_idx2_o                                (demux_out_reg_idx2       ),
    .out_reg_idx3_o                                (demux_out_reg_idx3       ),
    .out_branch_o                                  (demux_out_branch         ),
    .out_custom_signal_0_o                         (demux_out_custom_signal_0),
    .out_isvec_o                                   (demux_out_isvec          ),
    .out_readmask_o                                (demux_out_readmask       ),
    .out_sel_alu1_o                                (demux_out_sel_alu1       ),
    .out_sel_alu2_o                                (demux_out_sel_alu2       ),
    .out_sel_alu3_o                                (demux_out_sel_alu3       ),
    .out_pc_o                                      (demux_out_pc             ),
    .out_mask_o                                    (demux_out_mask           ),

    .out_fp_o                                      (demux_out_fp            ),
    .out_simt_stack_o                              (demux_out_simt_stack    ),
    .out_simt_stack_op_o                           (demux_out_simt_stack_op ),
    .out_barrier_o                                 (demux_out_barrier       ),
    .out_csr_o                                     (demux_out_csr           ),
    .out_reverse_o                                 (demux_out_reverse       ),
    .out_mem_whb_o                                 (demux_out_mem_whb       ),
    .out_mem_unsigned_o                            (demux_out_mem_unsigned  ),
    .out_alu_fn_o                                  (demux_out_alu_fn        ),
    .out_force_rm_rtz_o                            (demux_out_force_rm_rtz  ),
    .out_is_vls12_o                                (demux_out_is_vls12      ),
    .out_mem_o                                     (demux_out_mem           ),
    .out_mul_o                                     (demux_out_mul           ),
    .out_tc_o                                      (demux_out_tc            ),
    .out_disable_mask_o                            (demux_out_disable_mask  ),
    .out_mem_cmd_o                                 (demux_out_mem_cmd       ),
    .out_mop_o                                     (demux_out_mop           ),
    .out_reg_idxw_o                                (demux_out_reg_idxw      ),
    .out_wvd_o                                     (demux_out_wvd           ),
    .out_fence_o                                   (demux_out_fence         ),
    .out_sfu_o                                     (demux_out_sfu           ),
    //.out_writemask_o                               (demux_out_writemask     ),
    .out_wxd_o                                     (demux_out_wxd           ),
    .out_atomic_o                                  (demux_out_atomic        ),
    .out_aq_o                                      (demux_out_aq            ),
    .out_rl_o                                      (demux_out_rl            ),
	  .out_rm_o									                     (demux_out_rm   			    ),
	  .out_rm_is_static_o							               (demux_out_rm_is_static	),

    .sgpr_base_o                                   (demux_out_sgpr_base     ),
    .vgpr_base_o                                   (demux_out_vgpr_base     )
  );


  fixed_pri_arb #(
    .ARB_WIDTH(`NUM_COLLECTORUNIT)
  )
  U_fixed_pri_arb
  (
    .req  (issue_arbiter_valid),
    .grant(issue_arbiter_valid_oh)
  );

  one2bin #(
    .ONE_WIDTH(`NUM_COLLECTORUNIT),
    .BIN_WIDTH(`DEPTH_COLLECTORUNIT)
  )
  U_one2bin
  (
    .oh(issue_arbiter_valid_oh),
    .bin(issue_arbiter_valid_bin)    
  );

endmodule
