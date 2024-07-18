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
// Description: All inst has been arbitered will be issued to its correspond
// executing Unit here. 
`timescale  1ns/1ns
`include "define.v"
//`include "decode_df_para.v"

module issue(
  //input part of issue
  output                                                  issue_in_ready_o                                        ,
  input                                                   issue_in_valid_i                                        ,
  input [`NUM_THREAD*`XLEN-1:0]                           issue_in_vExeData_in1_i                                 ,
  input [`NUM_THREAD*`XLEN-1:0]                           issue_in_vExeData_in2_i                                 ,
  input [`NUM_THREAD*`XLEN-1:0]                           issue_in_vExeData_in3_i                                 ,
  input [`NUM_THREAD-1:0]                                 issue_in_vExeData_mask_i                                ,
  //control signals
  input [`INSTLEN-1:0]                                    issue_in_warps_control_Signals_inst_i                   ,
  input [`DEPTH_WARP-1:0]                                 issue_in_warps_control_Signals_wid_i                    ,
  input                                                   issue_in_warps_control_Signals_fp_i                     ,
  input [1:0]                                             issue_in_warps_control_Signals_branch_i                 ,
  input                                                   issue_in_warps_control_Signals_simt_stack_i             ,
  input                                                   issue_in_warps_control_Signals_simt_stack_op_i          ,
  input                                                   issue_in_warps_control_Signals_barrier_i                ,
  input [1:0]                                             issue_in_warps_control_Signals_csr_i                    ,
  input                                                   issue_in_warps_control_Signals_reverse_i                ,
  //input [1:0]                                             issue_in_warps_control_Signals_sel_alu2_i               ,
  //input [1:0]                                             issue_in_warps_control_Signals_sel_alu1_i               ,
  //input [1:0]                                             issue_in_warps_control_Signals_sel_alu3_i               ,
  input                                                   issue_in_warps_control_Signals_isvec_i                  ,
  //input                                                   issue_in_warps_control_Signals_mask_i                   ,
  //input [3:0]                                             issue_in_warps_control_Signals_sel_imm_i                ,
  input [1:0]                                             issue_in_warps_control_Signals_mem_whb_i                ,
  input                                                   issue_in_warps_control_Signals_mem_unsigned_i           ,
  input [5:0]                                             issue_in_warps_control_Signals_alu_fn_i                 ,
  input                                                   issue_in_warps_control_Signals_force_rm_rtz_i           ,
  input                                                   issue_in_warps_control_Signals_is_vls12_i               ,
  input                                                   issue_in_warps_control_Signals_mem_i                    ,
  input                                                   issue_in_warps_control_Signals_mul_i                    ,
  input                                                   issue_in_warps_control_Signals_tc_i                     ,
  input                                                   issue_in_warps_control_Signals_disable_mask_i           ,
  input                                                   issue_in_warps_control_Signals_custom_signal_0_i        ,
  input [1:0]                                             issue_in_warps_control_Signals_mem_cmd_i                ,
  input [1:0]                                             issue_in_warps_control_Signals_mop_i                    ,
  //input [(`REGEXT_WIDTH + `REGIDX_WIDTH)-1:0]             issue_in_warps_control_Signals_reg_idx1_i               ,
  //input [(`REGEXT_WIDTH + `REGIDX_WIDTH)-1:0]             issue_in_warps_control_Signals_reg_idx2_i               ,
  //input [(`REGEXT_WIDTH + `REGIDX_WIDTH)-1:0]             issue_in_warps_control_Signals_reg_idx3_i               ,
  input [(`REGEXT_WIDTH + `REGIDX_WIDTH)-1:0]             issue_in_warps_control_Signals_reg_idxw_i               ,
  input                                                   issue_in_warps_control_Signals_wvd_i                    ,
  input                                                   issue_in_warps_control_Signals_fence_i                  ,
  input                                                   issue_in_warps_control_Signals_sfu_i                    ,
  //input                                                   issue_in_warps_control_Signals_readmask_i               ,
  //input                                                   issue_in_warps_control_Signals_writemask_i              ,
  input                                                   issue_in_warps_control_Signals_wxd_i                    ,
  input [`INSTLEN-1:0]                                    issue_in_warps_control_Signals_pc_i                     ,
  //input [5:0]                                             issue_in_warps_control_Signals_imm_ext_i                ,
  input                                                   issue_in_warps_control_Signals_atomic_i                 ,
  input                                                   issue_in_warps_control_Signals_aq_i                     ,
  input                                                   issue_in_warps_control_Signals_rl_i                     ,
  input [2:0]											  	                    issue_in_warps_control_Signals_rm_i						          ,
  input												 	                          issue_in_warps_control_Signals_rm_is_static_i			      ,
  //input                                                   issue_in_warps_control_Signals_spike_info_i             ,
  
  // output part of issue
  //OUT_sALU valid and ready
  output reg                                              issue_out_sALU_valid_o                                  ,
  input                                                   issue_out_sALU_ready_i                                  ,
  //OUT_sALU control signals
  output [`XLEN-1:0]                                      issue_out_sALU_sExeData_in1_o                           ,
  output [`XLEN-1:0]                                      issue_out_sALU_sExeData_in2_o                           ,
  output [`XLEN-1:0]                                      issue_out_sALU_sExeData_in3_o                           ,
  output [`DEPTH_WARP-1:0]                                issue_out_sALU_warps_control_Signals_wid_o              ,
  output [1:0]                                            issue_out_sALU_warps_control_Signals_branch_o           ,
  output [5:0]                                            issue_out_sALU_warps_control_Signals_alu_fn_o           ,
  output [(`REGEXT_WIDTH + `REGIDX_WIDTH)-1:0]            issue_out_sALU_warps_control_Signals_reg_idxw_o         ,
  output                                                  issue_out_sALU_warps_control_Signals_wxd_o              ,
  
  //OUT_vALU valid and ready
  output reg                                              issue_out_vALU_valid_o                                  ,
  input                                                   issue_out_vALU_ready_i                                  ,
  //OUT_vALU control signals
  output [`NUM_THREAD*`XLEN-1:0]                          issue_out_vALU_vExeData_in1_o                           ,
  output [`NUM_THREAD*`XLEN-1:0]                          issue_out_vALU_vExeData_in2_o                           ,
  output [`NUM_THREAD*`XLEN-1:0]                          issue_out_vALU_vExeData_in3_o                           ,
  output [`NUM_THREAD-1:0]                                issue_out_vALU_vExeData_mask_o                          ,
  output [`DEPTH_WARP-1:0]                                issue_out_vALU_warps_control_Signals_wid_o              ,
  output                                                  issue_out_vALU_warps_control_Signals_simt_stack_o       ,
  output                                                  issue_out_vALU_warps_control_Signals_reverse_o          ,
  output [5:0]                                            issue_out_vALU_warps_control_Signals_alu_fn_o           ,
  output [(`REGEXT_WIDTH + `REGIDX_WIDTH)-1:0]            issue_out_vALU_warps_control_Signals_reg_idxw_o         ,
  output                                                  issue_out_vALU_warps_control_Signals_wvd_o              ,
  
  //OUT_vFPU valid and ready
  output reg                                              issue_out_vFPU_valid_o                                  ,
  input                                                   issue_out_vFPU_ready_i                                  ,
  //OUT_vFPU control signals 
  output [`NUM_THREAD*`XLEN-1:0]                          issue_out_vFPU_vExeData_in1_o                           ,
  output [`NUM_THREAD*`XLEN-1:0]                          issue_out_vFPU_vExeData_in2_o                           ,
  output [`NUM_THREAD*`XLEN-1:0]                          issue_out_vFPU_vExeData_in3_o                           ,
  output [`NUM_THREAD-1:0]                                issue_out_vFPU_vExeData_mask_o                          ,
  output [`DEPTH_WARP-1:0]                                issue_out_vFPU_warps_control_Signals_wid_o              ,
  output                                                  issue_out_vFPU_warps_control_Signals_reverse_o          ,
  output [5:0]                                            issue_out_vFPU_warps_control_Signals_alu_fn_o           ,
  output                                                  issue_out_vFPU_warps_control_Signals_force_rm_rtz_o     ,
  output [(`REGEXT_WIDTH + `REGIDX_WIDTH)-1:0]            issue_out_vFPU_warps_control_Signals_reg_idxw_o         ,
  output                                                  issue_out_vFPU_warps_control_Signals_wvd_o              ,
  output                                                  issue_out_vFPU_warps_control_Signals_wxd_o              ,
  output [2:0]										                        issue_out_vFPU_warps_control_Signals_rm_o				        ,
  output													                        issue_out_vFPU_warps_control_Signals_rm_is_static_o     ,
  //output                                                  issue_out_vFPU_warps_control_Signals_spike_info_o       ,
  
  //OUT_LSU valid and ready
  output reg                                              issue_out_LSU_valid_o                                  ,
  input                                                   issue_out_LSU_ready_i                                  ,
  //OUT_LSU control signals
  output [`NUM_THREAD*`XLEN-1:0]                          issue_out_LSU_vExeData_in1_o                           ,
  output [`NUM_THREAD*`XLEN-1:0]                          issue_out_LSU_vExeData_in2_o                           ,
  output [`NUM_THREAD*`XLEN-1:0]                          issue_out_LSU_vExeData_in3_o                           ,
  output [`NUM_THREAD-1:0]                                issue_out_LSU_vExeData_mask_o                          ,
  output [`DEPTH_WARP-1:0]                                issue_out_LSU_warps_control_Signals_wid_o              ,
  output                                                  issue_out_LSU_warps_control_Signals_isvec_o            ,
  output [1:0]                                            issue_out_LSU_warps_control_Signals_mem_whb_o          ,
  output                                                  issue_out_LSU_warps_control_Signals_mem_unsigned_o     ,
  output [5:0]                                            issue_out_LSU_warps_control_Signals_alu_fn_o           ,
  output                                                  issue_out_LSU_warps_control_Signals_is_vls12_o         ,
  output                                                  issue_out_LSU_warps_control_Signals_disable_mask_o     ,
  output [1:0]                                            issue_out_LSU_warps_control_Signals_mem_cmd_o          ,
  output [1:0]                                            issue_out_LSU_warps_control_Signals_mop_o              ,
  output [(`REGEXT_WIDTH + `REGIDX_WIDTH)-1:0]            issue_out_LSU_warps_control_Signals_reg_idxw_o         ,
  output                                                  issue_out_LSU_warps_control_Signals_wvd_o              ,
  output                                                  issue_out_LSU_warps_control_Signals_fence_o            ,
  output                                                  issue_out_LSU_warps_control_Signals_wxd_o              ,
  output                                                  issue_out_LSU_warps_control_Signals_atomic_o           ,
  output                                                  issue_out_LSU_warps_control_Signals_aq_o               ,
  output                                                  issue_out_LSU_warps_control_Signals_rl_o               ,
  
  
  //OUT_SFU valid and ready
  output reg                                              issue_out_SFU_valid_o                                  ,
  input                                                   issue_out_SFU_ready_i                                  ,
  //OUT_SFU control signals
  output [`NUM_THREAD*`XLEN-1:0]                          issue_out_SFU_vExeData_in1_o                           ,
  output [`NUM_THREAD*`XLEN-1:0]                          issue_out_SFU_vExeData_in2_o                           ,
  output [`NUM_THREAD*`XLEN-1:0]                          issue_out_SFU_vExeData_in3_o                           ,
  output [`NUM_THREAD-1:0]                                issue_out_SFU_vExeData_mask_o                          ,
  output [`DEPTH_WARP-1:0]                                issue_out_SFU_warps_control_Signals_wid_o              ,
  output                                                  issue_out_SFU_warps_control_Signals_fp_o               ,
  output                                                  issue_out_SFU_warps_control_Signals_reverse_o          ,
  output                                                  issue_out_SFU_warps_control_Signals_isvec_o            ,
  output [5:0]                                            issue_out_SFU_warps_control_Signals_alu_fn_o           ,
  output [(`REGEXT_WIDTH + `REGIDX_WIDTH)-1:0]            issue_out_SFU_warps_control_Signals_reg_idxw_o         ,
  output                                                  issue_out_SFU_warps_control_Signals_wvd_o              ,
  output                                                  issue_out_SFU_warps_control_Signals_wxd_o              ,
  
  //OUT_warp_sche valid and ready
  output reg                                              issue_out_warps_valid_o                                ,
  input                                                   issue_out_warps_ready_i                                ,
  //OUT_warp_sche control signals
  output [`DEPTH_WARP-1:0]                                issue_out_warps_control_Signals_wid_o                  ,
  output                                                  issue_out_warps_control_Signals_simt_stack_op_o        ,
  
  //OUT_CSR valid and ready
  output reg                                              issue_out_CSR_valid_o                                  ,
  input                                                   issue_out_CSR_ready_i                                  ,
  //OUT_CSR control signals
  output [`XLEN-1:0]                                      issue_out_CSR_csrExeData_in1_o                         ,
  
  output [`INSTLEN-1:0]                                   issue_out_CSR_warps_control_Signals_inst_o             ,
  output [`DEPTH_WARP-1:0]                                issue_out_CSR_warps_control_Signals_wid_o              ,
  output [1:0]                                            issue_out_CSR_warps_control_Signals_csr_o              ,
  output                                                  issue_out_CSR_warps_control_Signals_isvec_o            ,
  output                                                  issue_out_CSR_warps_control_Signals_custom_signal_0_o  ,
  output [(`REGEXT_WIDTH + `REGIDX_WIDTH)-1:0]            issue_out_CSR_warps_control_Signals_reg_idxw_o         ,
  output                                                  issue_out_CSR_warps_control_Signals_wxd_o              ,
  
  //OUT_MUL valid and ready
  output  reg                                             issue_out_MUL_valid_o                                  ,
  input                                                   issue_out_MUL_ready_i                                  ,
  //OUT_MUL control signals
  output [`NUM_THREAD*`XLEN-1:0]                          issue_out_MUL_vExeData_in1_o                           ,
  output [`NUM_THREAD*`XLEN-1:0]                          issue_out_MUL_vExeData_in2_o                           ,
  output [`NUM_THREAD*`XLEN-1:0]                          issue_out_MUL_vExeData_in3_o                           ,
  output [`NUM_THREAD-1:0]                                issue_out_MUL_vExeData_mask_o                          ,
  output [`DEPTH_WARP-1:0]                                issue_out_MUL_warps_control_Signals_wid_o              ,
  output                                                  issue_out_MUL_warps_control_Signals_reverse_o          ,
  output [5:0]                                            issue_out_MUL_warps_control_Signals_alu_fn_o           ,
  output [(`REGEXT_WIDTH + `REGIDX_WIDTH)-1:0]            issue_out_MUL_warps_control_Signals_reg_idxw_o         ,
  output                                                  issue_out_MUL_warps_control_Signals_wvd_o              ,
  output                                                  issue_out_MUL_warps_control_Signals_wxd_o              ,
  
  //OUT_TC valid and ready
  output reg                                              issue_out_TC_valid_o                                   ,
  input                                                   issue_out_TC_ready_i                                   ,
  //OUT_TC control signals 
  output [`NUM_THREAD*`XLEN-1:0]                          issue_out_TC_vExeData_in1_o                            ,
  output [`NUM_THREAD*`XLEN-1:0]                          issue_out_TC_vExeData_in2_o                            ,
  output [`NUM_THREAD*`XLEN-1:0]                          issue_out_TC_vExeData_in3_o                            ,
  output [`DEPTH_WARP-1:0]                                issue_out_TC_warps_control_Signals_wid_o               ,
  output [(`REGEXT_WIDTH + `REGIDX_WIDTH)-1:0]            issue_out_TC_warps_control_Signals_reg_idxw_o          ,
  
  //out_SIMT
  output reg                                              issue_simtExeData_valid_o                              ,
  input                                                   issue_simtExeData_ready_i                              ,
  output                                                  issue_simtExeData_opcode_o                             ,
  output [`DEPTH_WARP-1:0]                                issue_simtExeData_wid_o                                ,
  output [31:0]                                           issue_simtExeData_PC_branch_o                          ,
  output [31:0]                                           issue_simtExeData_PC_execute_o                         ,
  output [`NUM_THREAD-1:0]                                issue_simtExeData_mask_init_o                          
  
  );
  /*
    io.out_sALU.bits.in1:=inputBuf.bits.in1(0)
    io.out_sALU.bits.in2:=inputBuf.bits.in2(0)
    io.out_sALU.bits.in3:=inputBuf.bits.in3(0)
    io.out_sALU.bits.ctrl:=inputBuf.bits.ctrl
  */
  
  //inputBuf valid and ready and control signals
  wire                                                  inputBuf_valid                                   ;
  //this valid val is  default 1'b1
  reg                                                   inputBuf_ready                                   ;
  //OUT_TC control signals 
  wire [`NUM_THREAD*`XLEN-1:0]                          inputBuf_vExeData_in1                            ;
  wire [`NUM_THREAD*`XLEN-1:0]                          inputBuf_vExeData_in2                            ;
  wire [`NUM_THREAD*`XLEN-1:0]                          inputBuf_vExeData_in3                            ;
  wire [`NUM_THREAD-1:0]                                inputBuf_vExeData_mask                           ;
  wire [`INSTLEN-1:0]                                   inputBuf_warps_control_Signals_inst              ;
  wire [`DEPTH_WARP-1:0]                                inputBuf_warps_control_Signals_wid               ;
  wire                                                  inputBuf_warps_control_Signals_fp                ;
  wire [1:0]                                            inputBuf_warps_control_Signals_branch            ;
  wire                                                  inputBuf_warps_control_Signals_simt_stack        ;
  wire                                                  inputBuf_warps_control_Signals_simt_stack_op     ;
  wire                                                  inputBuf_warps_control_Signals_barrier           ;
  wire [1:0]                                            inputBuf_warps_control_Signals_csr               ;
  wire                                                  inputBuf_warps_control_Signals_reverse           ;
  wire                                                  inputBuf_warps_control_Signals_isvec             ;
  wire [1:0]                                            inputBuf_warps_control_Signals_mem_whb           ;
  wire                                                  inputBuf_warps_control_Signals_mem_unsigned      ;
  wire [5:0]                                            inputBuf_warps_control_Signals_alu_fn            ;
  wire                                                  inputBuf_warps_control_Signals_force_rm_rtz      ;
  wire                                                  inputBuf_warps_control_Signals_is_vls12          ;
  wire                                                  inputBuf_warps_control_Signals_mem               ;
  wire                                                  inputBuf_warps_control_Signals_mul               ;
  wire                                                  inputBuf_warps_control_Signals_tc                ;
  wire                                                  inputBuf_warps_control_Signals_disable_mask      ;
  wire                                                  inputBuf_warps_control_Signals_custom_signal_0   ;
  wire [1:0]                                            inputBuf_warps_control_Signals_mem_cmd           ;
  wire [1:0]                                            inputBuf_warps_control_Signals_mop               ;
  wire [(`REGEXT_WIDTH + `REGIDX_WIDTH)-1:0]            inputBuf_warps_control_Signals_reg_idxw          ;
  wire                                                  inputBuf_warps_control_Signals_wvd               ;
  wire                                                  inputBuf_warps_control_Signals_fence             ;
  wire                                                  inputBuf_warps_control_Signals_sfu               ;
  wire                                                  inputBuf_warps_control_Signals_wxd               ;
  wire [`INSTLEN-1:0]                                   inputBuf_warps_control_Signals_pc                ;
  wire                                                  inputBuf_warps_control_Signals_atomic            ;
  wire                                                  inputBuf_warps_control_Signals_aq                ;
  wire                                                  inputBuf_warps_control_Signals_rl                ;
  wire [2:0]											                      inputBuf_warps_control_Signals_rm				         ;
  wire												                          inputBuf_warps_control_Signals_rm_is_static	     ;
  wire                                                  inputBuf_warps_control_Signals_spike_info        ;
  
  //wire in_fire;
  //wire out_sALU_fire;
  //wire out_vALU_fire;
  //wire out_vFPU_fire;
  //wire out_LSU_fire;
  //wire out_SFU_fire;
  //wire out_SIMT_fire;
  //wire out_warp_sche_fire;
  //wire out_CSR_fire;
  //wire out_MUL_fire;
  //wire out_TC_fire;
  
  //assign inputBuf_valid = 1'b1;
  //assign issue_in_ready_o = 1'b1;
  assign inputBuf_valid = issue_in_valid_i;
  assign issue_in_ready_o = inputBuf_ready;
  //assign inputBuf_ready = 1'b0;//default 1'b0 but
  //assign in_fire            = issue_in_ready_o       & issue_in_valid_i;
  //assign out_sALU_fire      = issue_out_sALU_valid_o & issue_out_sALU_ready_i; 
  //assign out_vALU_fire      = issue_out_vALU_valid_o & issue_out_vALU_ready_i; 
  //assign out_vFPU_fire      = issue_out_vFPU_valid_o & issue_out_vFPU_ready_i; 
  //assign out_LSU_fire       = issue_out_LSU_valid_o  & issue_out_LSU_ready_i; 
  //assign out_SFU_fire       = issue_out_SFU_valid_o  & issue_out_SFU_ready_i; 
  //assign out_SIMT_fire      = issue_simtExeData_valid_o & issue_simtExeData_ready_i;  //issue_simtExeData_valid_o
  //assign out_warp_sche_fire = issue_out_warps_valid_o& issue_out_warps_ready_i; //issue_out_warps_valid_o
  //assign out_CSR_fire       = issue_out_CSR_valid_o  & issue_out_CSR_ready_i; 
  //assign out_MUL_fire       = issue_out_MUL_valid_o  & issue_out_MUL_ready_i; 
  //assign out_TC_fire        = issue_out_TC_valid_o   & issue_out_TC_ready_i; 
  
  //inputBuf comes from issue_in
  assign    inputBuf_vExeData_in1                                   = issue_in_vExeData_in1_i                         ;
  assign    inputBuf_vExeData_in2                                   = issue_in_vExeData_in2_i                         ;
  assign    inputBuf_vExeData_in3                                   = issue_in_vExeData_in3_i                         ;
  assign    inputBuf_vExeData_mask                                  = issue_in_vExeData_mask_i                        ;
  assign    inputBuf_warps_control_Signals_inst                     = issue_in_warps_control_Signals_inst_i           ;
  assign    inputBuf_warps_control_Signals_wid                      = issue_in_warps_control_Signals_wid_i            ;
  assign    inputBuf_warps_control_Signals_fp                       = issue_in_warps_control_Signals_fp_i             ;
  assign    inputBuf_warps_control_Signals_branch                   = issue_in_warps_control_Signals_branch_i         ;
  assign    inputBuf_warps_control_Signals_simt_stack               = issue_in_warps_control_Signals_simt_stack_i     ;
  assign    inputBuf_warps_control_Signals_simt_stack_op            = issue_in_warps_control_Signals_simt_stack_op_i  ;
  assign    inputBuf_warps_control_Signals_barrier                  = issue_in_warps_control_Signals_barrier_i        ;
  assign    inputBuf_warps_control_Signals_csr                      = issue_in_warps_control_Signals_csr_i            ;
  assign    inputBuf_warps_control_Signals_reverse                  = issue_in_warps_control_Signals_reverse_i        ;
  assign    inputBuf_warps_control_Signals_isvec                    = issue_in_warps_control_Signals_isvec_i          ;
  assign    inputBuf_warps_control_Signals_mem_whb                  = issue_in_warps_control_Signals_mem_whb_i        ;
  assign    inputBuf_warps_control_Signals_mem_unsigned             = issue_in_warps_control_Signals_mem_unsigned_i   ;
  assign    inputBuf_warps_control_Signals_alu_fn                   = issue_in_warps_control_Signals_alu_fn_i         ;
  assign    inputBuf_warps_control_Signals_force_rm_rtz             = issue_in_warps_control_Signals_force_rm_rtz_i   ;
  assign    inputBuf_warps_control_Signals_is_vls12                 = issue_in_warps_control_Signals_is_vls12_i       ;
  assign    inputBuf_warps_control_Signals_mem                      = issue_in_warps_control_Signals_mem_i            ;
  assign    inputBuf_warps_control_Signals_mul                      = issue_in_warps_control_Signals_mul_i            ;
  assign    inputBuf_warps_control_Signals_tc                       = issue_in_warps_control_Signals_tc_i             ;
  assign    inputBuf_warps_control_Signals_disable_mask             = issue_in_warps_control_Signals_disable_mask_i   ;
  assign    inputBuf_warps_control_Signals_custom_signal_0          = issue_in_warps_control_Signals_custom_signal_0_i;
  assign    inputBuf_warps_control_Signals_mem_cmd                  = issue_in_warps_control_Signals_mem_cmd_i        ;
  assign    inputBuf_warps_control_Signals_mop                      = issue_in_warps_control_Signals_mop_i            ;
  assign    inputBuf_warps_control_Signals_reg_idxw                 = issue_in_warps_control_Signals_reg_idxw_i       ;
  assign    inputBuf_warps_control_Signals_wvd                      = issue_in_warps_control_Signals_wvd_i            ;
  assign    inputBuf_warps_control_Signals_fence                    = issue_in_warps_control_Signals_fence_i          ;
  assign    inputBuf_warps_control_Signals_sfu                      = issue_in_warps_control_Signals_sfu_i            ;
  assign    inputBuf_warps_control_Signals_wxd                      = issue_in_warps_control_Signals_wxd_i            ;
  assign    inputBuf_warps_control_Signals_pc                       = issue_in_warps_control_Signals_pc_i             ;
  assign    inputBuf_warps_control_Signals_atomic                   = issue_in_warps_control_Signals_atomic_i         ;
  assign    inputBuf_warps_control_Signals_aq                       = issue_in_warps_control_Signals_aq_i             ;
  assign    inputBuf_warps_control_Signals_rl                       = issue_in_warps_control_Signals_rl_i             ;
  assign    inputBuf_warps_control_Signals_rm						            = issue_in_warps_control_Signals_rm_i				      ;
  assign    inputBuf_warps_control_Signals_rm_is_static			        = issue_in_warps_control_Signals_rm_is_static_i	  ;
  
  //out_sALU comes from inputBuf in out_sALU_fire condition
  assign    issue_out_sALU_sExeData_in1_o                           = inputBuf_vExeData_in1[`XLEN-1:0];
  assign    issue_out_sALU_sExeData_in2_o                           = inputBuf_vExeData_in2[`XLEN-1:0];
  assign    issue_out_sALU_sExeData_in3_o                           = inputBuf_vExeData_in3[`XLEN-1:0];
  assign    issue_out_sALU_warps_control_Signals_wid_o              = inputBuf_warps_control_Signals_wid;
  assign    issue_out_sALU_warps_control_Signals_branch_o           = inputBuf_warps_control_Signals_branch;
  assign    issue_out_sALU_warps_control_Signals_alu_fn_o           = inputBuf_warps_control_Signals_alu_fn;
  assign    issue_out_sALU_warps_control_Signals_reg_idxw_o         = inputBuf_warps_control_Signals_reg_idxw;
  assign    issue_out_sALU_warps_control_Signals_wxd_o              = inputBuf_warps_control_Signals_wxd;
   
  //out_vALU comes from inputBuf in out_vALU_fire condition
  assign    issue_out_vALU_vExeData_in1_o                           = inputBuf_vExeData_in1                         ;
  assign    issue_out_vALU_vExeData_in2_o                           = inputBuf_vExeData_in2                         ;
  assign    issue_out_vALU_vExeData_in3_o                           = inputBuf_vExeData_in3                         ;
  assign    issue_out_vALU_vExeData_mask_o                          = inputBuf_vExeData_mask                        ;
  assign    issue_out_vALU_warps_control_Signals_wid_o              = inputBuf_warps_control_Signals_wid            ;
  assign    issue_out_vALU_warps_control_Signals_simt_stack_o       = inputBuf_warps_control_Signals_simt_stack     ;
  assign    issue_out_vALU_warps_control_Signals_reverse_o          = inputBuf_warps_control_Signals_reverse        ;
  assign    issue_out_vALU_warps_control_Signals_alu_fn_o           = inputBuf_warps_control_Signals_alu_fn         ;
  assign    issue_out_vALU_warps_control_Signals_reg_idxw_o         = inputBuf_warps_control_Signals_reg_idxw       ;
  assign    issue_out_vALU_warps_control_Signals_wvd_o              = inputBuf_warps_control_Signals_wvd            ;
   
  //out_vFPU comes from inputBuf in out_sALU_fire condition
  assign    issue_out_vFPU_vExeData_in1_o                           = inputBuf_vExeData_in1                         ;
  assign    issue_out_vFPU_vExeData_in2_o                           = inputBuf_vExeData_in2                         ;
  assign    issue_out_vFPU_vExeData_in3_o                           = inputBuf_vExeData_in3                         ;
  assign    issue_out_vFPU_vExeData_mask_o                          = inputBuf_vExeData_mask                        ;
  assign    issue_out_vFPU_warps_control_Signals_wid_o              = inputBuf_warps_control_Signals_wid            ;
  assign    issue_out_vFPU_warps_control_Signals_reverse_o          = inputBuf_warps_control_Signals_reverse        ;
  assign    issue_out_vFPU_warps_control_Signals_alu_fn_o           = inputBuf_warps_control_Signals_alu_fn         ;
  assign    issue_out_vFPU_warps_control_Signals_force_rm_rtz_o     = inputBuf_warps_control_Signals_force_rm_rtz   ;
  assign    issue_out_vFPU_warps_control_Signals_reg_idxw_o         = inputBuf_warps_control_Signals_reg_idxw       ;
  assign    issue_out_vFPU_warps_control_Signals_wvd_o              = inputBuf_warps_control_Signals_wvd            ;
  assign    issue_out_vFPU_warps_control_Signals_wxd_o              = inputBuf_warps_control_Signals_wxd            ;
  assign    issue_out_vFPU_warps_control_Signals_rm_o				        = inputBuf_warps_control_Signals_rm			        ;
  assign    issue_out_vFPU_warps_control_Signals_rm_is_static_o	    = inputBuf_warps_control_Signals_rm_is_static	  ;
  
  //out_MUL comes from inputBuf in out_sALU_fire condition
  assign    issue_out_MUL_vExeData_in1_o                            = inputBuf_vExeData_in1                         ;
  assign    issue_out_MUL_vExeData_in2_o                            = inputBuf_vExeData_in2                         ;
  assign    issue_out_MUL_vExeData_in3_o                            = inputBuf_vExeData_in3                         ;
  assign    issue_out_MUL_vExeData_mask_o                           = inputBuf_vExeData_mask                        ;
  assign    issue_out_MUL_warps_control_Signals_wid_o               = inputBuf_warps_control_Signals_wid            ;
  assign    issue_out_MUL_warps_control_Signals_reverse_o           = inputBuf_warps_control_Signals_reverse        ;
  assign    issue_out_MUL_warps_control_Signals_alu_fn_o            = inputBuf_warps_control_Signals_alu_fn         ;
  assign    issue_out_MUL_warps_control_Signals_reg_idxw_o          = inputBuf_warps_control_Signals_reg_idxw       ;
  assign    issue_out_MUL_warps_control_Signals_wvd_o               = inputBuf_warps_control_Signals_wvd            ;
  assign    issue_out_MUL_warps_control_Signals_wxd_o               = inputBuf_warps_control_Signals_wxd            ;
   
  //out_SFU comes from inputBuf in out_sALU_fire condition
  assign    issue_out_SFU_vExeData_in1_o                            = inputBuf_vExeData_in1                         ;
  assign    issue_out_SFU_vExeData_in2_o                            = inputBuf_vExeData_in2                         ;
  assign    issue_out_SFU_vExeData_in3_o                            = inputBuf_vExeData_in3                         ;
  assign    issue_out_SFU_vExeData_mask_o                           = inputBuf_vExeData_mask                        ;
  assign    issue_out_SFU_warps_control_Signals_wid_o               = inputBuf_warps_control_Signals_wid            ;
  assign    issue_out_SFU_warps_control_Signals_fp_o                = inputBuf_warps_control_Signals_fp             ;
  assign    issue_out_SFU_warps_control_Signals_reverse_o           = inputBuf_warps_control_Signals_reverse        ;
  assign    issue_out_SFU_warps_control_Signals_isvec_o             = inputBuf_warps_control_Signals_isvec          ;
  assign    issue_out_SFU_warps_control_Signals_alu_fn_o            = inputBuf_warps_control_Signals_alu_fn         ;
  assign    issue_out_SFU_warps_control_Signals_reg_idxw_o          = inputBuf_warps_control_Signals_reg_idxw       ;
  assign    issue_out_SFU_warps_control_Signals_wvd_o               = inputBuf_warps_control_Signals_wvd            ;
  assign    issue_out_SFU_warps_control_Signals_wxd_o               = inputBuf_warps_control_Signals_wxd            ;
  
  //out_LSU comes from inputBuf in out_sALU_fire condition
  assign    issue_out_LSU_vExeData_in1_o                            = inputBuf_vExeData_in1                         ;
  assign    issue_out_LSU_vExeData_in2_o                            = inputBuf_vExeData_in2                         ;
  assign    issue_out_LSU_vExeData_in3_o                            = inputBuf_vExeData_in3                         ;
  assign    issue_out_LSU_vExeData_mask_o                           = inputBuf_vExeData_mask                        ;
  assign    issue_out_LSU_warps_control_Signals_wid_o               = inputBuf_warps_control_Signals_wid            ;
  assign    issue_out_LSU_warps_control_Signals_isvec_o             = inputBuf_warps_control_Signals_isvec          ;
  assign    issue_out_LSU_warps_control_Signals_mem_whb_o           = inputBuf_warps_control_Signals_mem_whb        ;
  assign    issue_out_LSU_warps_control_Signals_mem_unsigned_o      = inputBuf_warps_control_Signals_mem_unsigned   ;
  assign    issue_out_LSU_warps_control_Signals_alu_fn_o            = inputBuf_warps_control_Signals_alu_fn         ;
  assign    issue_out_LSU_warps_control_Signals_is_vls12_o          = inputBuf_warps_control_Signals_is_vls12       ;
  assign    issue_out_LSU_warps_control_Signals_disable_mask_o      = inputBuf_warps_control_Signals_disable_mask   ;
  assign    issue_out_LSU_warps_control_Signals_mem_cmd_o           = inputBuf_warps_control_Signals_mem_cmd        ;
  assign    issue_out_LSU_warps_control_Signals_mop_o               = inputBuf_warps_control_Signals_mop            ;
  assign    issue_out_LSU_warps_control_Signals_reg_idxw_o          = inputBuf_warps_control_Signals_reg_idxw       ;
  assign    issue_out_LSU_warps_control_Signals_wvd_o               = inputBuf_warps_control_Signals_wvd            ;
  assign    issue_out_LSU_warps_control_Signals_fence_o             = inputBuf_warps_control_Signals_fence          ;
  assign    issue_out_LSU_warps_control_Signals_wxd_o               = inputBuf_warps_control_Signals_wxd            ;
  assign    issue_out_LSU_warps_control_Signals_atomic_o            = inputBuf_warps_control_Signals_atomic         ;
  assign    issue_out_LSU_warps_control_Signals_aq_o                = inputBuf_warps_control_Signals_aq             ;
  assign    issue_out_LSU_warps_control_Signals_rl_o                = inputBuf_warps_control_Signals_rl             ;
  
  //out_TC comes from inputBuf in out_sALU_fire condition
  assign    issue_out_TC_vExeData_in1_o                            = inputBuf_vExeData_in1                         ;
  assign    issue_out_TC_vExeData_in2_o                            = inputBuf_vExeData_in2                         ;
  assign    issue_out_TC_vExeData_in3_o                            = inputBuf_vExeData_in3                         ;
  assign    issue_out_TC_warps_control_Signals_wid_o               = inputBuf_warps_control_Signals_wid            ;
  assign    issue_out_TC_warps_control_Signals_reg_idxw_o          = inputBuf_warps_control_Signals_reg_idxw       ;
  
  assign    issue_simtExeData_PC_branch_o                          = inputBuf_vExeData_in3[`XLEN-1:0]             ;
  assign    issue_simtExeData_PC_execute_o                         = inputBuf_warps_control_Signals_pc            ;
  assign    issue_simtExeData_wid_o                                = inputBuf_warps_control_Signals_wid           ;
  assign    issue_simtExeData_opcode_o                             = inputBuf_warps_control_Signals_simt_stack_op ;
  assign    issue_simtExeData_mask_init_o                          = inputBuf_vExeData_mask                       ;
  
  //warpscheduler
  assign    issue_out_warps_control_Signals_wid_o               = inputBuf_warps_control_Signals_wid            ;
  assign    issue_out_warps_control_Signals_simt_stack_op_o     = inputBuf_warps_control_Signals_simt_stack_op  ;
  
  //issue_out_CSR_warps_control_Signals_inst_o
  //CSR
  assign    issue_out_CSR_warps_control_Signals_inst_o            = inputBuf_warps_control_Signals_inst           ;
  assign    issue_out_CSR_warps_control_Signals_wid_o             = inputBuf_warps_control_Signals_wid            ;
  assign    issue_out_CSR_warps_control_Signals_csr_o             = inputBuf_warps_control_Signals_csr            ;
  assign    issue_out_CSR_warps_control_Signals_isvec_o           = inputBuf_warps_control_Signals_isvec          ;
  assign    issue_out_CSR_warps_control_Signals_custom_signal_0_o = inputBuf_warps_control_Signals_custom_signal_0;
  assign    issue_out_CSR_warps_control_Signals_reg_idxw_o        = inputBuf_warps_control_Signals_reg_idxw       ;
  assign    issue_out_CSR_warps_control_Signals_wxd_o             = inputBuf_warps_control_Signals_wxd            ;
  assign    issue_out_CSR_csrExeData_in1_o                        = inputBuf_vExeData_in1[`XLEN-1:0]              ;
  
  always @(*)
    begin
      if(inputBuf_warps_control_Signals_tc)
        begin
          issue_out_TC_valid_o = inputBuf_valid;
          inputBuf_ready = issue_out_TC_ready_i;
          issue_out_sALU_valid_o     = 1'b0;
          issue_out_vALU_valid_o     = 1'b0;
          issue_simtExeData_valid_o  = 1'b0;
          issue_out_LSU_valid_o      = 1'b0;
          issue_out_vFPU_valid_o     = 1'b0;
          issue_out_MUL_valid_o      = 1'b0;
          issue_out_warps_valid_o    = 1'b0;
          issue_out_CSR_valid_o      = 1'b0;
          issue_out_SFU_valid_o      = 1'b0;
        end
      else if(inputBuf_warps_control_Signals_sfu)
        begin
          issue_out_TC_valid_o = 1'b0;
          issue_out_SFU_valid_o= inputBuf_valid;
          inputBuf_ready = issue_out_SFU_ready_i;
          issue_out_sALU_valid_o     = 1'b0;
          issue_out_vALU_valid_o     = 1'b0;
          issue_simtExeData_valid_o  = 1'b0;
          issue_out_LSU_valid_o      = 1'b0;
          issue_out_vFPU_valid_o     = 1'b0;
          issue_out_MUL_valid_o      = 1'b0;
          issue_out_warps_valid_o    = 1'b0;
          issue_out_CSR_valid_o      = 1'b0;
        end
      else if(inputBuf_warps_control_Signals_fp)
        begin
          issue_out_TC_valid_o = 1'b0;
          issue_out_SFU_valid_o = 1'b0;
          issue_out_vFPU_valid_o= inputBuf_valid;
          inputBuf_ready = issue_out_vFPU_ready_i;
          issue_out_sALU_valid_o     = 1'b0;
          issue_out_vALU_valid_o     = 1'b0;
          issue_simtExeData_valid_o  = 1'b0;
          issue_out_LSU_valid_o      = 1'b0;
          issue_out_MUL_valid_o      = 1'b0;
          issue_out_warps_valid_o    = 1'b0;
          issue_out_CSR_valid_o      = 1'b0;
        end
      else if(|inputBuf_warps_control_Signals_csr)
        begin
          issue_out_TC_valid_o = 1'b0;
          issue_out_vFPU_valid_o = 1'b0;
          issue_out_CSR_valid_o= inputBuf_valid;
          inputBuf_ready = issue_out_CSR_ready_i;
          issue_out_sALU_valid_o     = 1'b0;
          issue_out_vALU_valid_o     = 1'b0;
          issue_simtExeData_valid_o  = 1'b0;
          issue_out_LSU_valid_o      = 1'b0;
          issue_out_MUL_valid_o      = 1'b0;
          issue_out_warps_valid_o    = 1'b0;
          issue_out_SFU_valid_o      = 1'b0;
        end
      else if(inputBuf_warps_control_Signals_mul)
        begin
          issue_out_TC_valid_o = 1'b0;
          issue_out_CSR_valid_o = 1'b0;
          issue_out_MUL_valid_o= inputBuf_valid;
          inputBuf_ready = issue_out_MUL_ready_i;
          issue_out_sALU_valid_o     = 1'b0;
          issue_out_vALU_valid_o     = 1'b0;
          issue_simtExeData_valid_o  = 1'b0;
          issue_out_LSU_valid_o      = 1'b0;
          issue_out_vFPU_valid_o     = 1'b0;
          issue_out_warps_valid_o    = 1'b0;
          issue_out_SFU_valid_o      = 1'b0;
        end
      else if(inputBuf_warps_control_Signals_mem)
        begin
          issue_out_TC_valid_o = 1'b0;
          issue_out_MUL_valid_o = 1'b0;
          issue_out_LSU_valid_o= inputBuf_valid;
          inputBuf_ready = issue_out_LSU_ready_i;
          issue_out_sALU_valid_o     = 1'b0;
          issue_out_vALU_valid_o     = 1'b0;
          issue_simtExeData_valid_o  = 1'b0;
          issue_out_vFPU_valid_o     = 1'b0;
          issue_out_warps_valid_o    = 1'b0;
          issue_out_CSR_valid_o      = 1'b0;
          issue_out_SFU_valid_o      = 1'b0;
        end
      else if(inputBuf_warps_control_Signals_isvec)
        begin
          if(inputBuf_warps_control_Signals_simt_stack)
            begin
              if(issue_simtExeData_opcode_o == 'b0)
                begin
                  issue_out_TC_valid_o       = 1'b0;
                  issue_out_vALU_valid_o = inputBuf_valid & issue_simtExeData_ready_i & issue_out_vALU_ready_i ;
                  issue_simtExeData_valid_o = inputBuf_valid & issue_simtExeData_ready_i & issue_out_vALU_ready_i ;
                  inputBuf_ready = issue_simtExeData_ready_i & issue_out_vALU_ready_i;
                  issue_out_sALU_valid_o     = 1'b0;
                  issue_out_LSU_valid_o      = 1'b0;
                  issue_out_vFPU_valid_o     = 1'b0;
                  issue_out_MUL_valid_o      = 1'b0;
                  issue_out_warps_valid_o    = 1'b0;
                  issue_out_CSR_valid_o      = 1'b0;
                  issue_out_SFU_valid_o      = 1'b0;
                end
              else if(issue_simtExeData_opcode_o != 'b0)
                begin
                  issue_out_TC_valid_o       = 1'b0;
                  issue_out_vALU_valid_o = 1'b0;
                  issue_simtExeData_valid_o = inputBuf_valid;
                  inputBuf_ready = issue_simtExeData_ready_i;
                  issue_out_sALU_valid_o     = 1'b0;
                  issue_out_LSU_valid_o      = 1'b0;
                  issue_out_vFPU_valid_o     = 1'b0;
                  issue_out_MUL_valid_o      = 1'b0;
                  issue_out_warps_valid_o    = 1'b0;
                  issue_out_CSR_valid_o      = 1'b0;
                  issue_out_SFU_valid_o      = 1'b0;
                end
              else 
                begin
                  issue_out_TC_valid_o       = 1'b0;
                  issue_out_vALU_valid_o     = 1'b0;
                  issue_simtExeData_valid_o  = 1'b0;
                  inputBuf_ready             = 1'b0;
                  issue_out_sALU_valid_o     = 1'b0;
                  issue_out_LSU_valid_o      = 1'b0;
                  issue_out_vFPU_valid_o     = 1'b0;
                  issue_out_MUL_valid_o      = 1'b0;
                  issue_out_warps_valid_o    = 1'b0;
                  issue_out_CSR_valid_o      = 1'b0;
                  issue_out_SFU_valid_o      = 1'b0;
                end
            end
          else
            begin
              issue_out_TC_valid_o = 1'b0;
              issue_out_vALU_valid_o = inputBuf_valid;
              issue_simtExeData_valid_o = 1'b0;
              inputBuf_ready = issue_out_vALU_ready_i;
              issue_out_sALU_valid_o     = 1'b0;
              issue_out_LSU_valid_o      = 1'b0;
              issue_out_vFPU_valid_o     = 1'b0;
              issue_out_MUL_valid_o      = 1'b0;
              issue_out_warps_valid_o    = 1'b0;
              issue_out_CSR_valid_o      = 1'b0;
              issue_out_SFU_valid_o      = 1'b0;
            end
        end
      else if(inputBuf_warps_control_Signals_barrier)
        begin
          issue_out_TC_valid_o = 1'b0;
          issue_out_vALU_valid_o = 1'b0;
          issue_out_warps_valid_o = inputBuf_valid; //issue_out_warp_valid_o
          inputBuf_ready = issue_out_warps_ready_i;
          issue_out_sALU_valid_o     = 1'b0;
          issue_simtExeData_valid_o  = 1'b0;
          issue_out_LSU_valid_o      = 1'b0;
          issue_out_vFPU_valid_o     = 1'b0;
          issue_out_MUL_valid_o      = 1'b0;
          issue_out_CSR_valid_o      = 1'b0;
          issue_out_SFU_valid_o      = 1'b0;
        end
      else if(!inputBuf_warps_control_Signals_barrier)
        begin
          issue_out_TC_valid_o = 1'b0;
          issue_out_vALU_valid_o  = 1'b0;
          issue_out_warps_valid_o = 1'b0;
          issue_out_sALU_valid_o  = inputBuf_valid;
          inputBuf_ready = issue_out_sALU_ready_i;
          //issue_out_sALU_valid_o     = 1'b0;
          issue_simtExeData_valid_o  = 1'b0;
          issue_out_LSU_valid_o      = 1'b0;
          issue_out_vFPU_valid_o     = 1'b0;
          issue_out_MUL_valid_o      = 1'b0;
          issue_out_CSR_valid_o      = 1'b0;
          issue_out_SFU_valid_o      = 1'b0;
        end
      else 
        begin
          issue_out_TC_valid_o       = 1'b0;
          issue_out_sALU_valid_o     = 1'b0;
          issue_out_vALU_valid_o     = 1'b0;
          issue_simtExeData_valid_o  = 1'b0;
          issue_out_LSU_valid_o      = 1'b0;
          issue_out_vFPU_valid_o     = 1'b0;
          issue_out_MUL_valid_o      = 1'b0;
          issue_out_warps_valid_o    = 1'b0;
          issue_out_CSR_valid_o      = 1'b0;
          issue_out_SFU_valid_o      = 1'b0;
          inputBuf_ready             = issue_out_sALU_ready_i;
        end
    end
  //attention :区分优先级顺序

endmodule
