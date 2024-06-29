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
// Description:sm's pipeline module
`timescale 1ns/1ns

`include "define.v"
//`include "decode_df_para.v"
//`include "fpu_ops.v"
//`include "IDecode_define.v"

module pipe (

  input                                            clk                                     ,
  input                                            rst_n                                   ,

  //input                                            icache_req_ready_i                      ,
  output                                           icache_req_valid_o                      ,
  output [`XLEN-1:0]                               icache_req_addr_o                       ,
  output [`NUM_FETCH-1:0]                          icache_req_mask_o                       ,
  output [`DEPTH_WARP-1:0]                         icache_req_wid_o                        ,

  input                                            icache_rsp_valid_i                      ,
  input  [`XLEN-1:0]                               icache_rsp_addr_i                       ,
  input  [`NUM_FETCH*`XLEN-1:0]                    icache_rsp_data_i                       ,
  input  [`NUM_FETCH-1:0]                          icache_rsp_mask_i                       ,
  input  [`DEPTH_WARP-1:0]                         icache_rsp_wid_i                        ,
  input                                            icache_rsp_status_i                     , //0 is hit, 1 is miss

  output                                           dcache_req_valid_o                      ,
  input                                            dcache_req_ready_i                      ,
  output [`DEPTH_WARP-1:0]                         dcache_req_instrid_o                    ,
  output [`DCACHE_SETIDXBITS-1:0]                  dcache_req_setidx_o                     ,
  output [`DCACHE_TAGBITS-1:0]                     dcache_req_tag_o                        ,
  output [`NUM_THREAD-1:0]                         dcache_req_activemask_o                 ,
  output [`NUM_THREAD*`DCACHE_BLOCKOFFSETBITS-1:0] dcache_req_blockoffset_o                ,
  output [`NUM_THREAD*`BYTESOFWORD-1:0]            dcache_req_wordoffset1h_o               ,
  output [`NUM_THREAD*`XLEN-1:0]                   dcache_req_data_o                       ,
  output [2:0]                                     dcache_req_opcode_o                     ,
  output [3:0]                                     dcache_req_param_o                      ,

  input                                            dcache_rsp_valid_i                      ,
  output                                           dcache_rsp_ready_o                      ,
  input  [`DEPTH_WARP-1:0]                         dcache_rsp_instrid_i                    ,
  input  [`XLEN*`NUM_THREAD-1:0]                   dcache_rsp_data_i                       ,
  input  [`NUM_THREAD-1:0]                         dcache_rsp_activemask_i                 ,
  
  output                                           shared_req_valid_o                      ,
  input                                            shared_req_ready_i                      ,
  output [`DEPTH_WARP-1:0]                         shared_req_instrid_o                    ,
  output                                           shared_req_iswrite_o                    ,
  output [`DCACHE_TAGBITS-1:0]                     shared_req_tag_o                        ,
  output [`DCACHE_SETIDXBITS-1:0]                  shared_req_setidx_o                     ,
  output [`NUM_THREAD-1:0]                         shared_req_activemask_o                 ,
  output [`NUM_THREAD*`DCACHE_BLOCKOFFSETBITS-1:0] shared_req_blockoffset_o                ,
  output [`NUM_THREAD*`BYTESOFWORD-1:0]            shared_req_wordoffset1h_o               ,
  output [`NUM_THREAD*`XLEN-1:0]                   shared_req_data_o                       ,

  input                                            shared_rsp_valid_i                      ,
  output                                           shared_rsp_ready_o                      ,
  input  [$clog2(`LSU_NMSHRENTRY)-1:0]             shared_rsp_instrid_i                    ,
  input  [`XLEN*`NUM_THREAD-1:0]                   shared_rsp_data_i                       ,
  input  [`NUM_THREAD-1:0]                         shared_rsp_activemask_i                 ,

  output                                           flush_pipe_valid_o                      ,
  output [`DEPTH_WARP-1:0]                         flush_pipe_wid_o                        ,

  input                                            warpReq_valid_i                         , 
  input  [`WF_COUNT_WIDTH-1:0]                     warpReq_dispatch2cu_wg_wf_count_i       , //sum of warp in a workgroup
  input  [`WAVE_ITEM_WIDTH-1:0]                    warpReq_dispatch2cu_wf_size_dispatch_i  ,
  input  [`SGPR_ID_WIDTH:0]                        warpReq_dispatch2cu_sgpr_base_dispatch_i,
  input  [`VGPR_ID_WIDTH:0]                        warpReq_dispatch2cu_vgpr_base_dispatch_i,
  input  [`TAG_WIDTH-1:0]                          warpReq_dispatch2cu_wf_tag_dispatch_i   , //tag of the workgroup
  input  [`LDS_ID_WIDTH:0]                         warpReq_dispatch2cu_lds_base_dispatch_i ,
  input  [`MEM_ADDR_WIDTH-1:0]                     warpReq_dispatch2cu_start_pc_dispatch_i , //the start pc
  input  [`MEM_ADDR_WIDTH-1:0]                     warpReq_dispatch2cu_pds_base_dispatch_i ,
  //input  [`MEM_ADDR_WIDTH-1:0]                     warpReq_dispatch2cu_gds_base_dispatch_i ,
  input  [`MEM_ADDR_WIDTH-1:0]                     warpReq_dispatch2cu_csr_knl_dispatch_i  ,
  input  [`WG_SIZE_X_WIDTH-1:0]                    warpReq_dispatch2cu_wgid_x_dispatch_i   ,
  input  [`WG_SIZE_Y_WIDTH-1:0]                    warpReq_dispatch2cu_wgid_y_dispatch_i   ,
  input  [`WG_SIZE_Z_WIDTH-1:0]                    warpReq_dispatch2cu_wgid_z_dispatch_i   ,
  input  [31:0]                                    warpReq_dispatch2cu_wg_id_i             ,
  input  [`DEPTH_WARP-1:0]                         warpReq_wid_i                           , //warp id
            
  input                                            warpRsp_ready_i                         ,
  output                                           warpRsp_valid_o                         , 
  output [`DEPTH_WARP-1:0]                         warpRsp_wid_o                           , //the id of the warp that have ended execution
           
  output [`DEPTH_WARP-1:0]                         wg_id_lookup_o                          , //wid
  input  [`TAG_WIDTH-1:0]                          wg_id_tag_i                             , //workgroup's tag

  //for dcache invalidate
  output                                           lsu_mshr_is_empty_o                     
  );
  localparam NUM_X = 6,
             NUM_V = 6;
  
  wire warp_sche_status;
  wire warp_sche_flush_valid,warp_sche_flushCache_valid;
  wire [`DEPTH_WARP-1:0] warp_sche_flush_wid,warp_sche_flushCache_wid;
  wire [`NUM_WARP-1:0] warp_sche_warp_ready;
  wire warp_sche_warp_control_ready;                     
  wire warp_sche_warp_control_fire;
  wire warp_sche_branch_out_ready;
  wire warp_sche_branch_fire;

  wire [`XLEN-1:0] decode_in_inst0,decode_in_inst1;
  wire decode_inst_mask_0,decode_inst_mask_1;
  wire decode_control_mask_0,decode_control_mask_1;
  wire [`INSTLEN-1:0] decode_control_Signals_inst_0,decode_control_Signals_inst_1;           
  wire [`DEPTH_WARP-1:0] decode_control_Signals_wid_0,decode_control_Signals_wid_1;            
  wire decode_control_Signals_fp_0,decode_control_Signals_fp_1;             
  wire [1:0] decode_control_Signals_branch_0,decode_control_Signals_branch_1;         
  wire decode_control_Signals_simt_stack_0,decode_control_Signals_simt_stack_1;     
  wire decode_control_Signals_simt_stack_op_0,decode_control_Signals_simt_stack_op_1;  
  wire decode_control_Signals_barrier_0 ,decode_control_Signals_barrier_1;        
  wire [1:0] decode_control_Signals_csr_0,decode_control_Signals_csr_1;            
  wire decode_control_Signals_reverse_0,decode_control_Signals_reverse_1;        
  wire [1:0] decode_control_Signals_sel_alu2_0,decode_control_Signals_sel_alu2_1;       
  wire [1:0] decode_control_Signals_sel_alu1_0,decode_control_Signals_sel_alu1_1;       
  wire [1:0] decode_control_Signals_sel_alu3_0,decode_control_Signals_sel_alu3_1;       
  wire decode_control_Signals_isvec_0,decode_control_Signals_isvec_1;          
  wire decode_control_Signals_mask_0,decode_control_Signals_mask_1;           
  wire [3:0] decode_control_Signals_sel_imm_0,decode_control_Signals_sel_imm_1;       
  wire [1:0] decode_control_Signals_mem_whb_0,decode_control_Signals_mem_whb_1;        
  wire decode_control_Signals_mem_unsigned_0,decode_control_Signals_mem_unsigned_1;   
  wire [5:0] decode_control_Signals_alu_fn_0,decode_control_Signals_alu_fn_1;         
  wire decode_control_Signals_force_rm_rtz_0,decode_control_Signals_force_rm_rtz_1;   
  wire decode_control_Signals_is_vls12_0,decode_control_Signals_is_vls12_1;       
  wire decode_control_Signals_mem_0,decode_control_Signals_mem_1;           
  wire decode_control_Signals_mul_0,decode_control_Signals_mul_1;            
  wire decode_control_Signals_tc_0,decode_control_Signals_tc_1;             
  wire decode_control_Signals_disable_mask_0,decode_control_Signals_disable_mask_1;   
  wire decode_control_Signals_custom_signal_0_0,decode_control_Signals_custom_signal_0_1;
  wire [1:0] decode_control_Signals_mem_cmd_0,decode_control_Signals_mem_cmd_1;        
  wire [1:0] decode_control_Signals_mop_0,decode_control_Signals_mop_1;            
  wire [`REGEXT_WIDTH + `REGIDX_WIDTH -1:0] decode_control_Signals_reg_idx1_0,decode_control_Signals_reg_idx1_1;       
  wire [`REGEXT_WIDTH + `REGIDX_WIDTH -1:0] decode_control_Signals_reg_idx2_0,decode_control_Signals_reg_idx2_1;       
  wire [`REGEXT_WIDTH + `REGIDX_WIDTH -1:0] decode_control_Signals_reg_idx3_0,decode_control_Signals_reg_idx3_1;       
  wire [`REGEXT_WIDTH + `REGIDX_WIDTH -1:0] decode_control_Signals_reg_idxw_0,decode_control_Signals_reg_idxw_1;       
  wire decode_control_Signals_wvd_0,decode_control_Signals_wvd_1;            
  wire decode_control_Signals_fence_0,decode_control_Signals_fence_1;          
  wire decode_control_Signals_sfu_0,decode_control_Signals_sfu_1;            
  wire decode_control_Signals_readmask_0,decode_control_Signals_readmask_1;       
  wire decode_control_Signals_writemask_0,decode_control_Signals_writemask_1;      
  wire decode_control_Signals_wxd_0,decode_control_Signals_wxd_1;            
  wire [`INSTLEN-1:0] decode_control_Signals_pc_0,decode_control_Signals_pc_1;             
  wire [6:0] decode_control_Signals_imm_ext_0,decode_control_Signals_imm_ext_1;        
  wire decode_control_Signals_atomic_0,decode_control_Signals_atomic_1;         
  wire decode_control_Signals_aq_0,decode_control_Signals_aq_1;             
  wire decode_control_Signals_rl_0,decode_control_Signals_rl_1;    
  wire [2:0] decode_rm_0,decode_rm_1;
  wire decode_rm_is_static_0,decode_rm_is_static_1;

  wire ibuffer_in_valid;
  wire ibuffer_in_ready; 
  wire [`NUM_FETCH-1:0]                                  ibuffer_in_control_mask                   ;
  wire [`NUM_FETCH*`INSTLEN-1:0]                         ibuffer_in_control_Signals_inst           ;
  wire [`NUM_FETCH*`DEPTH_WARP-1:0]                      ibuffer_in_control_Signals_wid            ;
  wire [`NUM_FETCH-1:0]                                  ibuffer_in_control_Signals_fp             ;
  wire [`NUM_FETCH*2-1:0]                                ibuffer_in_control_Signals_branch         ;
  wire [`NUM_FETCH-1:0]                                  ibuffer_in_control_Signals_simt_stack     ;
  wire [`NUM_FETCH-1:0]                                  ibuffer_in_control_Signals_simt_stack_op  ;
  wire [`NUM_FETCH-1:0]                                  ibuffer_in_control_Signals_barrier        ;
  wire [`NUM_FETCH*2-1:0]                                ibuffer_in_control_Signals_csr            ;
  wire [`NUM_FETCH-1:0]                                  ibuffer_in_control_Signals_reverse        ;
  wire [`NUM_FETCH*2-1:0]                                ibuffer_in_control_Signals_sel_alu2       ;
  wire [`NUM_FETCH*2-1:0]                                ibuffer_in_control_Signals_sel_alu1       ;
  wire [`NUM_FETCH*2-1:0]                                ibuffer_in_control_Signals_sel_alu3       ;
  wire [`NUM_FETCH-1:0]                                  ibuffer_in_control_Signals_isvec          ;
  wire [`NUM_FETCH-1:0]                                  ibuffer_in_control_Signals_mask           ;
  wire [`NUM_FETCH*4-1:0]                                ibuffer_in_control_Signals_sel_imm        ;
  wire [`NUM_FETCH*2-1:0]                                ibuffer_in_control_Signals_mem_whb        ;
  wire [`NUM_FETCH-1:0]                                  ibuffer_in_control_Signals_mem_unsigned   ;
  wire [`NUM_FETCH*6-1:0]                                ibuffer_in_control_Signals_alu_fn         ;
  wire [`NUM_FETCH-1:0]                                  ibuffer_in_control_Signals_force_rm_rtz   ;
  wire [`NUM_FETCH-1:0]                                  ibuffer_in_control_Signals_is_vls12       ;
  wire [`NUM_FETCH-1:0]                                  ibuffer_in_control_Signals_mem            ;
  wire [`NUM_FETCH-1:0]                                  ibuffer_in_control_Signals_mul            ;
  wire [`NUM_FETCH-1:0]                                  ibuffer_in_control_Signals_tc             ;
  wire [`NUM_FETCH-1:0]                                  ibuffer_in_control_Signals_disable_mask   ;
  wire [`NUM_FETCH-1:0]                                  ibuffer_in_control_Signals_custom_signal_0;
  wire [`NUM_FETCH*2-1:0]                                ibuffer_in_control_Signals_mem_cmd        ;
  wire [`NUM_FETCH*2-1:0]                                ibuffer_in_control_Signals_mop            ;
  wire [`NUM_FETCH*(`REGEXT_WIDTH + `REGIDX_WIDTH) -1:0] ibuffer_in_control_Signals_reg_idx1       ;
  wire [`NUM_FETCH*(`REGEXT_WIDTH + `REGIDX_WIDTH) -1:0] ibuffer_in_control_Signals_reg_idx2       ;
  wire [`NUM_FETCH*(`REGEXT_WIDTH + `REGIDX_WIDTH) -1:0] ibuffer_in_control_Signals_reg_idx3       ;
  wire [`NUM_FETCH*(`REGEXT_WIDTH + `REGIDX_WIDTH) -1:0] ibuffer_in_control_Signals_reg_idxw       ;
  wire [`NUM_FETCH-1:0]                                  ibuffer_in_control_Signals_wvd            ;
  wire [`NUM_FETCH-1:0]                                  ibuffer_in_control_Signals_fence          ;
  wire [`NUM_FETCH-1:0]                                  ibuffer_in_control_Signals_sfu            ;
  wire [`NUM_FETCH-1:0]                                  ibuffer_in_control_Signals_readmask       ;
  wire [`NUM_FETCH-1:0]                                  ibuffer_in_control_Signals_writemask      ;
  wire [`NUM_FETCH-1:0]                                  ibuffer_in_control_Signals_wxd            ;
  wire [`NUM_FETCH*`INSTLEN-1:0]                         ibuffer_in_control_Signals_pc             ;
  wire [`NUM_FETCH*6-1:0]                                ibuffer_in_control_Signals_imm_ext        ;
  wire [`NUM_FETCH-1:0]                                  ibuffer_in_control_Signals_atomic         ;
  wire [`NUM_FETCH-1:0]                                  ibuffer_in_control_Signals_aq             ;
  wire [`NUM_FETCH-1:0]                                  ibuffer_in_control_Signals_rl             ;
  wire [`NUM_FETCH*3-1:0]                                ibuffer_in_control_Signals_rm             ;
  wire [`NUM_FETCH-1:0]                                  ibuffer_in_control_Signals_rm_is_static   ;

  wire [`NUM_WARP*`INSTLEN-1:0] ibuffer_warps_control_Signals_inst;
  wire [`NUM_WARP*`DEPTH_WARP-1:0] ibuffer_warps_control_Signals_wid;
  wire [`NUM_WARP-1:0] ibuffer_warps_control_Signals_fp;
  wire [`NUM_WARP*2-1:0] ibuffer_warps_control_Signals_branch;
  wire [`NUM_WARP-1:0] ibuffer_warps_control_Signals_simt_stack;
  wire [`NUM_WARP-1:0] ibuffer_warps_control_Signals_simt_stack_op;
  wire [`NUM_WARP-1:0] ibuffer_warps_control_Signals_barrier;
  wire [`NUM_WARP*2-1:0] ibuffer_warps_control_Signals_csr;
  wire [`NUM_WARP-1:0] ibuffer_warps_control_Signals_reverse;

  wire [`NUM_WARP*2-1:0] ibuffer_warps_control_Signals_sel_alu2;
  wire [`NUM_WARP*2-1:0] ibuffer_warps_control_Signals_sel_alu1;
  wire [`NUM_WARP*2-1:0] ibuffer_warps_control_Signals_sel_alu3;
  wire [`NUM_WARP-1:0] ibuffer_warps_control_Signals_isvec;
  wire [`NUM_WARP-1:0] ibuffer_warps_control_Signals_mask;
  wire [`NUM_WARP*4-1:0] ibuffer_warps_control_Signals_sel_imm;
  wire [`NUM_WARP*2-1:0] ibuffer_warps_control_Signals_mem_whb;
  wire [`NUM_WARP-1:0] ibuffer_warps_control_Signals_mem_unsigned;
  wire [`NUM_WARP*6-1:0] ibuffer_warps_control_Signals_alu_fn;
  wire [`NUM_WARP-1:0] ibuffer_warps_control_Signals_force_rm_rtz;
  wire [`NUM_WARP-1:0] ibuffer_warps_control_Signals_is_vls12;
  wire [`NUM_WARP-1:0] ibuffer_warps_control_Signals_mem;
  wire [`NUM_WARP-1:0] ibuffer_warps_control_Signals_mul;
  wire [`NUM_WARP-1:0] ibuffer_warps_control_Signals_tc;
  wire [`NUM_WARP-1:0] ibuffer_warps_control_Signals_disable_mask;
  wire [`NUM_WARP-1:0] ibuffer_warps_control_Signals_custom_signal_0;
  wire [`NUM_WARP*2-1:0] ibuffer_warps_control_Signals_mem_cmd;
  wire [`NUM_WARP*2-1:0] ibuffer_warps_control_Signals_mop;
  wire [`NUM_WARP*(`REGEXT_WIDTH + `REGIDX_WIDTH)-1:0] ibuffer_warps_control_Signals_reg_idx1;
  wire [`NUM_WARP*(`REGEXT_WIDTH + `REGIDX_WIDTH)-1:0] ibuffer_warps_control_Signals_reg_idx2;
  wire [`NUM_WARP*(`REGEXT_WIDTH + `REGIDX_WIDTH)-1:0] ibuffer_warps_control_Signals_reg_idx3;
  wire [`NUM_WARP*(`REGEXT_WIDTH + `REGIDX_WIDTH)-1:0] ibuffer_warps_control_Signals_reg_idxw;
  wire [`NUM_WARP-1:0] ibuffer_warps_control_Signals_wvd;
  wire [`NUM_WARP-1:0] ibuffer_warps_control_Signals_fence;
  wire [`NUM_WARP-1:0] ibuffer_warps_control_Signals_sfu;
  wire [`NUM_WARP-1:0] ibuffer_warps_control_Signals_readmask;
  //wire [`NUM_WARP-1:0] ibuffer_warps_control_Signals_writemask;
  wire [`NUM_WARP-1:0] ibuffer_warps_control_Signals_wxd;
  wire [`NUM_WARP*`INSTLEN-1:0] ibuffer_warps_control_Signals_pc;
  wire [`NUM_WARP*6-1:0] ibuffer_warps_control_Signals_imm_ext;
  wire [`NUM_WARP-1:0] ibuffer_warps_control_Signals_atomic;
  wire [`NUM_WARP-1:0] ibuffer_warps_control_Signals_aq;
  wire [`NUM_WARP-1:0] ibuffer_warps_control_Signals_rl;
  wire [`NUM_WARP*3-1:0] ibuffer_warps_control_Signals_rm;
  wire [`NUM_WARP-1:0] ibuffer_warps_control_Signals_rm_is_static;

  wire [`NUM_WARP-1:0] ibuffer_ready; 
  wire [`NUM_WARP-1:0] ibuffer_out_valid;

  wire [`NUM_WARP-1:0] ibuffer2issue_in_valid;
  wire [`NUM_WARP-1:0] ibuffer2issue_in_ready;
  wire ibuffer2issue_out_valid;
  reg  reg_ibuffer2issue_out_valid;
  wire ibuffer2issue_out_fire;
  wire [`INSTLEN-1:0] ibuffer2issue_warps_control_Signals_inst;
  wire [`DEPTH_WARP-1:0] ibuffer2issue_warps_control_Signals_wid;
  wire ibuffer2issue_warps_control_Signals_fp;
  wire [1:0] ibuffer2issue_warps_control_Signals_branch;
  wire ibuffer2issue_warps_control_Signals_simt_stack;
  wire ibuffer2issue_warps_control_Signals_simt_stack_op;
  wire ibuffer2issue_warps_control_Signals_barrier;
  wire [1:0] ibuffer2issue_warps_control_Signals_csr;
  wire ibuffer2issue_warps_control_Signals_reverse;
  wire [1:0] ibuffer2issue_warps_control_Signals_sel_alu2;
  wire [1:0] ibuffer2issue_warps_control_Signals_sel_alu1;
  wire [1:0] ibuffer2issue_warps_control_Signals_sel_alu3;
  wire ibuffer2issue_warps_control_Signals_isvec;
  wire ibuffer2issue_warps_control_Signals_mask;
  wire [3:0] ibuffer2issue_warps_control_Signals_sel_imm;
  wire [1:0] ibuffer2issue_warps_control_Signals_mem_whb;
  wire ibuffer2issue_warps_control_Signals_mem_unsigned;
  wire [5:0] ibuffer2issue_warps_control_Signals_alu_fn;
  wire ibuffer2issue_warps_control_Signals_force_rm_rtz;
  wire ibuffer2issue_warps_control_Signals_is_vls12;
  wire ibuffer2issue_warps_control_Signals_mem;
  wire ibuffer2issue_warps_control_Signals_mul;
  wire ibuffer2issue_warps_control_Signals_tc;
  wire ibuffer2issue_warps_control_Signals_disable_mask;
  wire ibuffer2issue_warps_control_Signals_custom_signal_0;
  wire [1:0] ibuffer2issue_warps_control_Signals_mem_cmd;
  wire [1:0] ibuffer2issue_warps_control_Signals_mop;
  wire [(`REGEXT_WIDTH + `REGIDX_WIDTH)-1:0] ibuffer2issue_warps_control_Signals_reg_idx1;
  wire [(`REGEXT_WIDTH + `REGIDX_WIDTH)-1:0] ibuffer2issue_warps_control_Signals_reg_idx2;
  wire [(`REGEXT_WIDTH + `REGIDX_WIDTH)-1:0] ibuffer2issue_warps_control_Signals_reg_idx3;
  wire [(`REGEXT_WIDTH + `REGIDX_WIDTH)-1:0] ibuffer2issue_warps_control_Signals_reg_idxw;
  wire ibuffer2issue_warps_control_Signals_wvd;
  wire ibuffer2issue_warps_control_Signals_fence;
  wire ibuffer2issue_warps_control_Signals_sfu;
  wire ibuffer2issue_warps_control_Signals_readmask;
  //wire ibuffer2issue_warps_control_Signals_writemask;
  wire ibuffer2issue_warps_control_Signals_wxd;
  wire [`INSTLEN-1:0] ibuffer2issue_warps_control_Signals_pc;
  wire [5:0] ibuffer2issue_warps_control_Signals_imm_ext;
  wire ibuffer2issue_warps_control_Signals_atomic;
  wire ibuffer2issue_warps_control_Signals_aq;
  wire ibuffer2issue_warps_control_Signals_rl;
  wire [2:0] ibuffer2issue_warps_control_Signals_rm;
  wire ibuffer2issue_warps_control_Signals_rm_is_static;
  wire [`NUM_WARP-1:0] ibuffer2issue_grant;

  reg [`INSTLEN-1:0] reg_ibuffer2issue_warps_control_Signals_inst;
  reg [`DEPTH_WARP-1:0] reg_ibuffer2issue_warps_control_Signals_wid;
  reg reg_ibuffer2issue_warps_control_Signals_fp;
  reg [1:0] reg_ibuffer2issue_warps_control_Signals_branch;
  reg reg_ibuffer2issue_warps_control_Signals_simt_stack;
  reg reg_ibuffer2issue_warps_control_Signals_simt_stack_op;
  reg reg_ibuffer2issue_warps_control_Signals_barrier;
  reg [1:0] reg_ibuffer2issue_warps_control_Signals_csr;
  reg reg_ibuffer2issue_warps_control_Signals_reverse;
  reg [1:0] reg_ibuffer2issue_warps_control_Signals_sel_alu2;
  reg [1:0] reg_ibuffer2issue_warps_control_Signals_sel_alu1;
  reg [1:0] reg_ibuffer2issue_warps_control_Signals_sel_alu3;
  reg reg_ibuffer2issue_warps_control_Signals_isvec;
  reg reg_ibuffer2issue_warps_control_Signals_mask;
  reg [3:0] reg_ibuffer2issue_warps_control_Signals_sel_imm;
  reg [1:0] reg_ibuffer2issue_warps_control_Signals_mem_whb;
  reg reg_ibuffer2issue_warps_control_Signals_mem_unsigned;
  reg [5:0] reg_ibuffer2issue_warps_control_Signals_alu_fn;
  reg reg_ibuffer2issue_warps_control_Signals_force_rm_rtz;
  reg reg_ibuffer2issue_warps_control_Signals_is_vls12;
  reg reg_ibuffer2issue_warps_control_Signals_mem;
  reg reg_ibuffer2issue_warps_control_Signals_mul;
  reg reg_ibuffer2issue_warps_control_Signals_tc;
  reg reg_ibuffer2issue_warps_control_Signals_disable_mask;
  reg reg_ibuffer2issue_warps_control_Signals_custom_signal_0;
  reg [1:0] reg_ibuffer2issue_warps_control_Signals_mem_cmd;
  reg [1:0] reg_ibuffer2issue_warps_control_Signals_mop;
  reg [(`REGEXT_WIDTH + `REGIDX_WIDTH)-1:0] reg_ibuffer2issue_warps_control_Signals_reg_idx1;
  reg [(`REGEXT_WIDTH + `REGIDX_WIDTH)-1:0] reg_ibuffer2issue_warps_control_Signals_reg_idx2;
  reg [(`REGEXT_WIDTH + `REGIDX_WIDTH)-1:0] reg_ibuffer2issue_warps_control_Signals_reg_idx3;
  reg [(`REGEXT_WIDTH + `REGIDX_WIDTH)-1:0] reg_ibuffer2issue_warps_control_Signals_reg_idxw;
  reg reg_ibuffer2issue_warps_control_Signals_wvd;
  reg reg_ibuffer2issue_warps_control_Signals_fence;
  reg reg_ibuffer2issue_warps_control_Signals_sfu;
  reg reg_ibuffer2issue_warps_control_Signals_readmask;
  //reg reg_ibuffer2issue_warps_control_Signals_writemask;
  reg reg_ibuffer2issue_warps_control_Signals_wxd;
  reg [`INSTLEN-1:0] reg_ibuffer2issue_warps_control_Signals_pc;
  reg [5:0] reg_ibuffer2issue_warps_control_Signals_imm_ext;
  reg reg_ibuffer2issue_warps_control_Signals_atomic;
  reg reg_ibuffer2issue_warps_control_Signals_aq;
  reg reg_ibuffer2issue_warps_control_Signals_rl;
  reg [2:0] reg_ibuffer2issue_warps_control_Signals_rm;
  reg reg_ibuffer2issue_warps_control_Signals_rm_is_static;

  wire [`NUM_WARP-1:0] scoreb_delay;
  wire [`NUM_WARP-1:0] scoreb_if_fire;
  wire [`NUM_WARP-1:0] scoreb_op_col_in_fire;
  wire [`NUM_WARP-1:0] scoreb_op_col_out_fire;
  wire [`NUM_WARP-1:0] scoreb_wb_x_fire,scoreb_wb_v_fire;
  wire [`NUM_WARP-1:0] scoreb_br_ctrl;
  wire [`NUM_WARP*(`REGEXT_WIDTH + `REGIDX_WIDTH)-1:0] scoreb_ibuffer2issue_warps_control_Signals_reg_idxw;
  wire [`NUM_WARP-1:0] scoreb_ibuffer2issue_warps_control_Signals_wvd;           
  wire [`NUM_WARP-1:0] scoreb_ibuffer2issue_warps_control_Signals_wxd;           
  wire [`NUM_WARP*2-1:0] scoreb_ibuffer2issue_warps_control_Signals_branch; 
  wire [`NUM_WARP-1:0] scoreb_ibuffer2issue_warps_control_Signals_barrier; 
  wire [`NUM_WARP-1:0] scoreb_ibuffer2issue_warps_control_Signals_fence;   
  wire [`NUM_WARP*(`REGIDX_WIDTH+`REGEXT_WIDTH)-1:0] scoreb_wb_out_v_reg_idxw;
  wire [`NUM_WARP*(`REGIDX_WIDTH+`REGEXT_WIDTH)-1:0] scoreb_wb_out_x_reg_idxw ;
  wire [`NUM_WARP-1:0] scoreb_wb_out_v_wvd;
  wire [`NUM_WARP-1:0] scoreb_wb_out_x_wxd;

  wire operand_collector_control_ready;//in ready
  wire operand_collector_out_valid,operand_collector_out_fire;   
  wire operand_collector_writeScalar_ready,operand_collector_writeVector_ready;
  wire [`DEPTH_WARP-1:0] operand_collector_out_wid;
  wire [32-1:0] operand_collector_out_inst;
  //wire [6-1:0] operand_collector_out_imm_ext;
  //wire [4-1:0] operand_collector_out_sel_imm;
  //wire [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] operand_collector_out_reg_idx1;
  //wire [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] operand_collector_out_reg_idx2;
  //wire [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] operand_collector_out_reg_idx3;
  wire [2-1:0] operand_collector_out_branch;
  wire  operand_collector_out_custom_signal_0;
  wire  operand_collector_out_isvec;
  //wire  operand_collector_out_readmask;
  //wire [2-1:0] operand_collector_out_sel_alu1;
  //wire [2-1:0] operand_collector_out_sel_alu2;
  //wire [2-1:0] operand_collector_out_sel_alu3;
  wire [32-1:0] operand_collector_out_pc;
  //wire operand_collector_out_mask;
  wire operand_collector_out_fp;
  wire operand_collector_out_simt_stack;
  wire operand_collector_out_simt_stack_op;
  wire operand_collector_out_barrier;
  wire [2-1:0] operand_collector_out_csr;
  wire operand_collector_out_reverse;
  wire [2-1:0] operand_collector_out_mem_whb;
  wire operand_collector_out_mem_unsigned;
  wire [6-1:0] operand_collector_out_alu_fn;
  wire operand_collector_out_force_rm_rtz;
  wire operand_collector_out_is_vls12;
  wire operand_collector_out_mem;
  wire operand_collector_out_mul;
  wire operand_collector_out_tc;
  wire operand_collector_out_disable_mask;
  wire [2-1:0] operand_collector_out_mem_cmd;
  wire [2-1:0] operand_collector_out_mop;
  wire [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] operand_collector_out_reg_idxw;
  wire operand_collector_out_wvd;
  wire operand_collector_out_fence;
  wire operand_collector_out_sfu;
  //wire operand_collector_out_writemask;
  wire operand_collector_out_wxd;
  wire operand_collector_out_atomic;
  wire operand_collector_out_aq;
  wire operand_collector_out_rl;
  wire [2:0] operand_collector_out_rm;
  wire operand_collector_out_rm_is_static;
  wire [`XLEN*`NUM_THREAD-1:0] operand_collector_out_alu_src1;
  wire [`XLEN*`NUM_THREAD-1:0] operand_collector_out_alu_src2;
  wire [`XLEN*`NUM_THREAD-1:0] operand_collector_out_alu_src3;
  wire [`NUM_THREAD-1:0] operand_collector_out_active_mask;

  wire issue_in_ready;
  wire [`NUM_THREAD-1:0] issue_in_mask;
  wire issue_out_warps_valid;                  
  wire issue_out_warps_Signals_simt_stack_op; 
  wire [`DEPTH_WARP-1:0] issue_out_warps_Signals_wid;  

  wire issue_out_vALU_valid;
  wire [`NUM_THREAD*`XLEN-1:0] issue_out_vALU_vExeData_in1;
  wire [`NUM_THREAD*`XLEN-1:0] issue_out_vALU_vExeData_in2;
  wire [`NUM_THREAD*`XLEN-1:0] issue_out_vALU_vExeData_in3;
  wire [`NUM_THREAD-1:0] issue_out_vALU_vExeData_mask;
  wire [5:0] issue_out_vALU_warps_control_Signals_alu_fn;    
  wire issue_out_vALU_warps_control_Signals_reverse;   
  //wire issue_out_vALU_warps_control_Signals_writemask; 
  //wire issue_out_vALU_warps_control_Signals_readmask;  
  wire issue_out_vALU_warps_control_Signals_simt_stack;
  wire [`DEPTH_WARP-1:0] issue_out_vALU_warps_control_Signals_wid;       
  wire [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] issue_out_vALU_warps_control_Signals_reg_idxw;  
  wire issue_out_vALU_warps_control_Signals_wvd;       

  wire issue_out_LSU_valid;
  wire [`XLEN*`NUM_THREAD-1:0] issue_out_LSU_vExeData_in1;
  wire [`XLEN*`NUM_THREAD-1:0] issue_out_LSU_vExeData_in2;
  wire [`XLEN*`NUM_THREAD-1:0] issue_out_LSU_vExeData_in3;
  wire [`NUM_THREAD-1:0] issue_out_LSU_vExeData_mask;
  wire [`DEPTH_WARP-1:0] issue_out_LSU_warps_control_Signals_wid; 
  wire issue_out_LSU_warps_control_Signals_isvec; 
  wire [1:0] issue_out_LSU_warps_control_Signals_mem_whb; 
  wire issue_out_LSU_warps_control_Signals_mem_unsigned; 
  wire [5:0] issue_out_LSU_warps_control_Signals_alu_fn; 
  wire issue_out_LSU_warps_control_Signals_is_vls12; 
  wire issue_out_LSU_warps_control_Signals_disable_mask; 
  wire [1:0] issue_out_LSU_warps_control_Signals_mem_cmd; 
  wire [1:0] issue_out_LSU_warps_control_Signals_mop; 
  wire [(`REGEXT_WIDTH + `REGIDX_WIDTH)-1:0] issue_out_LSU_warps_control_Signals_reg_idxw; 
  wire issue_out_LSU_warps_control_Signals_wvd; 
  wire issue_out_LSU_warps_control_Signals_fence; 
  wire [6:0] issue_out_LSU_warps_control_Signals_imm_ext; 
  wire issue_out_LSU_warps_control_Signals_atomic; 
  wire issue_out_LSU_warps_control_Signals_aq; 
  wire issue_out_LSU_warps_control_Signals_rl; 

  wire issue_out_sALU_valid;
  wire [`XLEN-1:0]  issue_out_sALU_sExeData_in1;                    
  wire [`XLEN-1:0]  issue_out_sALU_sExeData_in2;                    
  wire [`XLEN-1:0]  issue_out_sALU_sExeData_in3;                    
  wire [`DEPTH_WARP-1:0]  issue_out_sALU_warps_control_Signals_wid; 
  wire [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] issue_out_sALU_warps_control_Signals_reg_idxw;
  wire issue_out_sALU_warps_control_Signals_wxd;
  wire [5:0] issue_out_sALU_warps_control_Signals_alu_fn; 
  wire [1:0] issue_out_sALU_warps_control_Signals_branch;

  wire issue_out_CSR_valid;
  wire [`XLEN-1:0] issue_out_CSR_csrExeData_in1;                       
  wire [`INSTLEN-1:0] issue_out_CSR_warps_control_Signals_inst;           
  wire [1:0] issue_out_CSR_warps_control_Signals_csr;            
  wire issue_out_CSR_warps_control_Signals_isvec;         
  wire issue_out_CSR_warps_control_Signals_custom_signal_0;
  wire [`DEPTH_WARP-1:0] issue_out_CSR_warps_control_Signals_wid;
  wire [(`REGEXT_WIDTH + `REGIDX_WIDTH)-1:0] issue_out_CSR_warps_control_Signals_reg_idxw;       
  wire issue_out_CSR_warps_control_Signals_wxd;            

  wire issue_out_SIMT_valid;
  wire issue_out_SIMT_opcode;
  wire [`DEPTH_WARP-1:0] issue_out_SIMT_wid;
  wire [31:0] issue_out_SIMT_PC_branch;
  wire [31:0] issue_out_SIMT_PC_execute;
  wire [`NUM_THREAD-1:0] issue_out_SIMT_mask_init;

  wire issue_out_SFU_valid;
  wire [`XLEN*`NUM_THREAD-1:0] issue_out_SFU_vExeData_in1;         
  wire [`XLEN*`NUM_THREAD-1:0] issue_out_SFU_vExeData_in2;         
  wire [`XLEN*`NUM_THREAD-1:0] issue_out_SFU_vExeData_in3;         
  wire [`NUM_THREAD-1:0] issue_out_SFU_vExeData_mask;        
  wire [`DEPTH_WARP-1:0] issue_out_SFU_warps_control_Signals_wid; 
  wire issue_out_SFU_warps_control_Signals_fp;
  wire issue_out_SFU_warps_control_Signals_reverse;
  wire issue_out_SFU_warps_control_Signals_isvec;
  wire [5:0] issue_out_SFU_warps_control_Signals_alu_fn;
  wire [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] issue_out_SFU_warps_control_Signals_reg_idxw;
  wire issue_out_SFU_warps_control_Signals_wvd;
  wire issue_out_SFU_warps_control_Signals_wxd;

  wire issue_out_MUL_valid;
  wire [`NUM_THREAD*`XLEN-1:0] issue_out_MUL_vExeData_in1;
  wire [`NUM_THREAD*`XLEN-1:0] issue_out_MUL_vExeData_in2;
  wire [`NUM_THREAD*`XLEN-1:0] issue_out_MUL_vExeData_in3;
  wire [`NUM_THREAD-1:0] issue_out_MUL_vExeData_mask;
  wire [5:0] issue_out_MUL_warps_control_Signals_alu_fn;   
  wire issue_out_MUL_warps_control_Signals_reverse; 
  wire [`DEPTH_WARP-1:0] issue_out_MUL_warps_control_Signals_wid;     
  wire [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] issue_out_MUL_warps_control_Signals_reg_idxw;
  wire issue_out_MUL_warps_control_Signals_wvd;
  wire issue_out_MUL_warps_control_Signals_wxd;

  wire issue_out_TC_valid;
  wire [`NUM_THREAD*`XLEN-1:0] issue_out_TC_vExeData_in1;
  wire [`NUM_THREAD*`XLEN-1:0] issue_out_TC_vExeData_in2;
  wire [`NUM_THREAD*`XLEN-1:0] issue_out_TC_vExeData_in3;
  //wire [`NUM_THREAD-1:0] issue_out_TC_vExeData_mask;
  wire [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] issue_out_TC_warps_control_Signals_reg_idxw;
  wire [`DEPTH_WARP-1:0] issue_out_TC_warps_control_Signals_wid;

  wire issue_out_vFPU_valid;
  wire [`NUM_THREAD*`XLEN-1:0] issue_out_vFPU_vExeData_in1;
  wire [`NUM_THREAD*`XLEN-1:0] issue_out_vFPU_vExeData_in2;
  wire [`NUM_THREAD*`XLEN-1:0] issue_out_vFPU_vExeData_in3;
  wire [`NUM_THREAD-1:0] issue_out_vFPU_vExeData_mask;
  wire [5:0] issue_out_vFPU_warps_control_Signals_alu_fn;
  wire issue_out_vFPU_warps_control_Signals_force_rm_rt;
  wire [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] issue_out_vFPU_warps_control_Signals_reg_idxw;
  wire issue_out_vFPU_warps_control_Signals_reverse;
  wire [`DEPTH_WARP-1:0] issue_out_vFPU_warps_control_Signals_wid;
  wire issue_out_vFPU_warps_control_Signals_wvd;
  wire issue_out_vFPU_warps_control_Signals_wxd;
  wire [2:0] issue_out_vFPU_warps_control_Signals_rm;
  wire issue_out_vFPU_warps_control_Signals_rm_is_static;

  wire valu_in_ready;
  wire valu_out2simt_valid;
  wire [`NUM_THREAD-1:0] valu_out2simt_if_mask;
  wire [`DEPTH_WARP-1:0] valu_out2simt_wid    ;
  wire valu_out_valid;
  wire [`NUM_THREAD*`XLEN-1:0] valu_out_wb_wvd_rd;
  wire [`NUM_THREAD-1:0] valu_out_wvd_mask;
  wire valu_out_wvd;
  wire [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] valu_out_reg_idxw;
  wire [`DEPTH_WARP-1:0] valu_out_warp_id;

  wire [`NUM_WARP-1:0] lsu_fence_end;
  wire lsu_req_ready;
  wire [`DEPTH_WARP-1:0] lsu_csr_wid;
  wire lsu_rsp_valid;
  wire [`DEPTH_WARP-1:0] lsu_rsp_warp_id;
  wire lsu_rsp_wfd; 
  wire lsu_rsp_wxd;
  //wire lsu_rsp_isvec;
  wire [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] lsu_rsp_reg_idxw;
  wire [`NUM_THREAD-1:0] lsu_rsp_mask;
  //wire lsu_rsp_unsigned;    
  //wire [`BYTESOFWORD*`NUM_THREAD-1:0] lsu_rsp_wordoffset1h;
  wire  lsu_rsp_iswrite;     
  wire [`XLEN*`NUM_THREAD-1:0] lsu_rsp_data;        

  wire lsu2wb_rsp_ready;
  wire lsu2wb_out_x_valid; 
  wire [`DEPTH_WARP-1:0] lsu2wb_out_x_warp_id;   
  wire lsu2wb_out_x_wxd;       
  wire [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] lsu2wb_out_x_reg_idxw;  
  wire [`XLEN-1:0] lsu2wb_out_x_wb_wxd_rd; 

  wire lsu2wb_out_v_valid;     
  wire [`DEPTH_WARP-1:0] lsu2wb_out_v_warp_id;   
  wire lsu2wb_out_v_wvd;       
  wire [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] lsu2wb_out_v_reg_idxw;  
  wire [`NUM_THREAD-1:0] lsu2wb_out_v_wvd_mask;  
  wire [`XLEN*`NUM_THREAD-1:0] lsu2wb_out_v_wb_wvd_rd; 

  wire salu_in_ready;       
  wire salu_out2br_valid; 
  wire [`DEPTH_WARP-1:0] salu_out2br_wid;    
  wire salu_out2br_jump;   
  wire [31:0] salu_out2br_new_pc; 
  wire salu_out_valid;
  wire [`XLEN-1:0] salu_out_wb_wxd_rd; 
  wire salu_out_wxd;
  wire [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] salu_out_reg_idxw;
  wire [`DEPTH_WARP-1:0] salu_out_warp_id;

  wire csrfile_in_ready;
  wire [`NUM_WARP*(`SGPR_ID_WIDTH+1)-1:0] csrfile_sgpr_base;
  wire [`NUM_WARP*(`VGPR_ID_WIDTH+1)-1:0] csrfile_vgpr_base;
  wire [`XLEN-1:0] csrfile_lsu_tid; 
  wire [`XLEN-1:0] csrfile_lsu_pds; 
  wire [`XLEN-1:0] csrfile_lsu_numw;
  wire [8:0] csrfile_rm;
  wire [`DEPTH_WARP*3-1:0] csrfile_rm_wid;
  wire [`XLEN-1:0] csrfile_simt_rpc;
  wire csrfile_out_valid;
  wire [`XLEN-1:0] csrfile_wb_wxd_rd;
  wire csrfile_wxd;
  wire [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] csrfile_reg_idxw;
  wire [`DEPTH_WARP-1:0] csrfile_warp_id;

  wire simt_stack_complete_valid;
  wire [`DEPTH_WARP-1:0] simt_stack_complete_wid;
  wire simt_stack_branch_ctl_ready;
  wire [`NUM_THREAD-1:0] simt_stack_out_mask;
  wire simt_stack_if_mask_ready;
  wire simt_stack_fetch_ctl_valid;
  wire [`DEPTH_WARP-1:0] simt_stack_fetch_ctl_wid; 
  wire simt_stack_fetch_ctl_jump;
  wire [31:0] simt_stack_fetch_ctl_new_pc;

  wire sfu_in_ready;
  wire sfu_out_x_valid;
  wire [`DEPTH_WARP-1:0] sfu_out_x_warp_id; 
  wire sfu_out_x_wxd; 
  wire [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] sfu_out_x_reg_idxw;
  wire [`XLEN-1:0] sfu_out_x_wb_wxd_rd;

  wire sfu_out_v_valid;
  wire [`DEPTH_WARP-1:0] sfu_out_v_warp_id; 
  wire sfu_out_v_wvd; 
  wire [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] sfu_out_v_reg_idxw;
  wire [`NUM_THREAD-1:0] sfu_out_v_wvd_mask;
  wire [`XLEN*`NUM_THREAD-1:0] sfu_out_v_wb_wvd_rd;

  wire mul_in_ready;
  wire mul_out_x_valid;
  wire [`XLEN-1:0] mul_out_x_wb_wxd_rd;
  wire mul_out_x_wxd;
  wire [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] mul_out_x_reg_idwx;
  wire [`DEPTH_WARP-1:0] mul_out_x_warp_id;

  wire mul_out_v_valid;
  wire [`NUM_THREAD*`XLEN-1:0] mul_out_v_wb_wxd_rd;
  wire [`NUM_THREAD-1:0] mul_out_v_wvd_mask;
  wire mul_out_v_wvd;
  wire [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] mul_out_v_reg_idxw;
  wire [`DEPTH_WARP-1:0] mul_out_v_warp_id;

  wire tensorcore_in_ready;
  wire tensorcore_out_v_valid;
  wire [`NUM_THREAD*`XLEN-1:0] tensorcore_out_v_wb_wvd_rd;
  wire [`NUM_THREAD-1:0] tensorcore_out_v_wvd_mask; 
  wire tensorcore_out_v_wvd; 
  wire [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] tensorcore_out_v_reg_idxw;
  wire [`DEPTH_WARP-1:0] tensorcore_out_v_warp_id;

  wire fpu_in_ready;
  wire fpu_out_x_valid;
  wire [`XLEN-1:0] fpu_out_x_wb_wxd_rd;
  wire fpu_out_x_wxd;
  wire [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] fpu_out_x_reg_idxw;
  wire [`DEPTH_WARP-1:0] fpu_out_x_warp_id;

  wire fpu_out_v_valid;
  wire [`NUM_THREAD*`XLEN-1:0] fpu_out_v_wb_wvd_rd;
  wire [`NUM_THREAD-1:0] fpu_out_v_wvd_mask;
  wire fpu_out_v_wvd;
  wire [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] fpu_out_v_reg_idxw;
  wire [`DEPTH_WARP-1:0] fpu_out_v_warp_id;
  wire [2:0] fpu_rm;

  wire branch_back_salu_ready;
  wire branch_back_out_valid;
  wire [`DEPTH_WARP-1:0] branch_back_out_wid;
  wire branch_back_out_jump;
  wire [`XLEN-1:0] branch_back_out_new_pc;

  wire branch_back_valu_ready;

  wire [NUM_X-1:0] writeback_in_x_valid; 
  wire [NUM_X-1:0] writeback_in_x_ready;
  wire [`DEPTH_WARP*NUM_X-1:0] writeback_in_x_warp_id;
  wire [NUM_X-1:0] writeback_in_x_wxd;
  wire [(`REGIDX_WIDTH+`REGEXT_WIDTH)*NUM_X-1:0] writeback_in_x_reg_idxw;
  wire [`XLEN*NUM_X-1:0] writeback_in_x_wb_wxd_rd;

  wire [NUM_V-1:0] writeback_in_v_valid;
  wire [NUM_V-1:0] writeback_in_v_ready;
  wire [`DEPTH_WARP*NUM_V-1:0] writeback_in_v_warp_id;
  wire [NUM_V-1:0] writeback_in_v_wvd;
  wire [(`REGIDX_WIDTH+`REGEXT_WIDTH)*NUM_V-1:0] writeback_in_v_reg_idxw;
  wire [`NUM_THREAD*NUM_V-1:0] writeback_in_v_wvd_mask;
  wire [`XLEN*`NUM_THREAD*NUM_V-1:0] writeback_in_v_wb_wvd_rd;

  wire wb_out_x_valid;
  wire [`DEPTH_WARP-1:0] wb_out_x_warp_id  ;
  wire wb_out_x_wxd;
  wire [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] wb_out_x_reg_idxw ;
  wire [`XLEN-1:0] wb_out_x_wb_wxd_rd;
  wire wb_out_v_valid;
  wire [`DEPTH_WARP-1:0] wb_out_v_warp_id;
  wire  wb_out_v_wvd;
  wire [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] wb_out_v_reg_idxw;
  wire [`NUM_THREAD-1:0] wb_out_v_wvd_mask;
  wire [`XLEN*`NUM_THREAD-1:0] wb_out_v_wb_wvd_rd;
  wire wb_out_x_fire,wb_out_v_fire;
  
  assign {decode_in_inst1,decode_in_inst0} = icache_rsp_data_i;

  assign warp_sche_warp_control_fire = warp_sche_warp_control_ready && issue_out_warps_valid;
  assign warp_sche_branch_fire = warp_sche_branch_out_ready && branch_back_out_valid;     
  assign warp_sche_status = ibuffer_in_ready ? icache_rsp_status_i : 1'b1; 

  assign {decode_inst_mask_1,decode_inst_mask_0} = (icache_rsp_valid_i && (!icache_rsp_status_i)) ? icache_rsp_mask_i : 'b0;

  assign ibuffer_in_valid = icache_rsp_valid_i && (!icache_rsp_status_i);
  assign ibuffer_in_control_mask = {decode_control_mask_1,decode_control_mask_0};                  
  assign ibuffer_in_control_Signals_inst = {decode_control_Signals_inst_1,decode_control_Signals_inst_0};          
  assign ibuffer_in_control_Signals_wid = {decode_control_Signals_wid_1,decode_control_Signals_wid_0};           
  assign ibuffer_in_control_Signals_fp = {decode_control_Signals_fp_1,decode_control_Signals_fp_0};            
  assign ibuffer_in_control_Signals_branch = {decode_control_Signals_branch_1,decode_control_Signals_branch_0};        
  assign ibuffer_in_control_Signals_simt_stack = {decode_control_Signals_simt_stack_1,decode_control_Signals_simt_stack_0};    
  assign ibuffer_in_control_Signals_simt_stack_op = {decode_control_Signals_simt_stack_op_1,decode_control_Signals_simt_stack_op_0};
  assign ibuffer_in_control_Signals_barrier = {decode_control_Signals_barrier_1,decode_control_Signals_barrier_0};       
  assign ibuffer_in_control_Signals_csr = {decode_control_Signals_csr_1,decode_control_Signals_csr_0}; 
  assign ibuffer_in_control_Signals_reverse = {decode_control_Signals_reverse_1,decode_control_Signals_reverse_0};
  assign ibuffer_in_control_Signals_sel_alu2 = {decode_control_Signals_sel_alu2_1,decode_control_Signals_sel_alu2_0};      
  assign ibuffer_in_control_Signals_sel_alu1 = {decode_control_Signals_sel_alu1_1,decode_control_Signals_sel_alu1_0};      
  assign ibuffer_in_control_Signals_sel_alu3 = {decode_control_Signals_sel_alu3_1,decode_control_Signals_sel_alu3_0};      
  assign ibuffer_in_control_Signals_isvec = {decode_control_Signals_isvec_1,decode_control_Signals_isvec_0};         
  assign ibuffer_in_control_Signals_mask = {decode_control_Signals_mask_1,decode_control_Signals_mask_0};
  assign ibuffer_in_control_Signals_sel_imm = {decode_control_Signals_sel_imm_1,decode_control_Signals_sel_imm_0};
  assign ibuffer_in_control_Signals_mem_whb = {decode_control_Signals_mem_whb_1,decode_control_Signals_mem_whb_0};
  assign ibuffer_in_control_Signals_mem_unsigned = {decode_control_Signals_mem_unsigned_1,decode_control_Signals_mem_unsigned_0};
  assign ibuffer_in_control_Signals_alu_fn = {decode_control_Signals_alu_fn_1,decode_control_Signals_alu_fn_0};
  assign ibuffer_in_control_Signals_force_rm_rtz = {decode_control_Signals_force_rm_rtz_1,decode_control_Signals_force_rm_rtz_0};
  assign ibuffer_in_control_Signals_is_vls12 = {decode_control_Signals_is_vls12_1,decode_control_Signals_is_vls12_0};
  assign ibuffer_in_control_Signals_mem = {decode_control_Signals_mem_1,decode_control_Signals_mem_0};
  assign ibuffer_in_control_Signals_mul = {decode_control_Signals_mul_1,decode_control_Signals_mul_0};
  assign ibuffer_in_control_Signals_tc = {decode_control_Signals_tc_1,decode_control_Signals_tc_0};
  assign ibuffer_in_control_Signals_disable_mask = {decode_control_Signals_disable_mask_1,decode_control_Signals_disable_mask_0};
  assign ibuffer_in_control_Signals_custom_signal_0 = {decode_control_Signals_custom_signal_0_1,decode_control_Signals_custom_signal_0_0};
  assign ibuffer_in_control_Signals_mem_cmd = {decode_control_Signals_mem_cmd_1,decode_control_Signals_mem_cmd_0};
  assign ibuffer_in_control_Signals_mop = {decode_control_Signals_mop_1,decode_control_Signals_mop_0};
  assign ibuffer_in_control_Signals_reg_idx1 = {decode_control_Signals_reg_idx1_1,decode_control_Signals_reg_idx1_0};
  assign ibuffer_in_control_Signals_reg_idx2 = {decode_control_Signals_reg_idx2_1,decode_control_Signals_reg_idx2_0};
  assign ibuffer_in_control_Signals_reg_idx3 = {decode_control_Signals_reg_idx3_1,decode_control_Signals_reg_idx3_0};
  assign ibuffer_in_control_Signals_reg_idxw = {decode_control_Signals_reg_idxw_1,decode_control_Signals_reg_idxw_0};
  assign ibuffer_in_control_Signals_wvd = {decode_control_Signals_wvd_1,decode_control_Signals_wvd_0};
  assign ibuffer_in_control_Signals_fence = {decode_control_Signals_fence_1,decode_control_Signals_fence_0};
  assign ibuffer_in_control_Signals_sfu = {decode_control_Signals_sfu_1,decode_control_Signals_sfu_0};
  assign ibuffer_in_control_Signals_readmask = {decode_control_Signals_readmask_1,decode_control_Signals_readmask_0};
  assign ibuffer_in_control_Signals_writemask = {decode_control_Signals_writemask_1,decode_control_Signals_writemask_0};
  assign ibuffer_in_control_Signals_wxd = {decode_control_Signals_wxd_1,decode_control_Signals_wxd_0};
  assign ibuffer_in_control_Signals_pc = {decode_control_Signals_pc_1,decode_control_Signals_pc_0};
  assign ibuffer_in_control_Signals_imm_ext = {decode_control_Signals_imm_ext_1,decode_control_Signals_imm_ext_0};
  assign ibuffer_in_control_Signals_atomic = {decode_control_Signals_atomic_1,decode_control_Signals_atomic_0};
  assign ibuffer_in_control_Signals_aq = {decode_control_Signals_aq_1,decode_control_Signals_aq_0};
  assign ibuffer_in_control_Signals_rl = {decode_control_Signals_rl_1,decode_control_Signals_rl_0};
  assign ibuffer_in_control_Signals_rm = {decode_rm_1,decode_rm_0};
  assign ibuffer_in_control_Signals_rm_is_static = {decode_rm_is_static_1,decode_rm_is_static_0};

  assign ibuffer2issue_in_valid = ibuffer_out_valid & warp_sche_warp_ready;
  assign ibuffer2issue_out_fire = operand_collector_control_ready && ibuffer2issue_out_valid;

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      reg_ibuffer2issue_out_valid                             <= 'd0;  
      reg_ibuffer2issue_warps_control_Signals_wid             <= 'd0;
      reg_ibuffer2issue_warps_control_Signals_inst            <= 'd0;
      reg_ibuffer2issue_warps_control_Signals_imm_ext         <= 'd0;
      reg_ibuffer2issue_warps_control_Signals_sel_imm         <= 'd0;
      reg_ibuffer2issue_warps_control_Signals_reg_idx1        <= 'd0;
      reg_ibuffer2issue_warps_control_Signals_reg_idx2        <= 'd0;
      reg_ibuffer2issue_warps_control_Signals_reg_idx3        <= 'd0;
      reg_ibuffer2issue_warps_control_Signals_branch          <= 'd0;
      reg_ibuffer2issue_warps_control_Signals_custom_signal_0 <= 'd0;
      reg_ibuffer2issue_warps_control_Signals_isvec           <= 'd0;
      reg_ibuffer2issue_warps_control_Signals_readmask        <= 'd0;
      reg_ibuffer2issue_warps_control_Signals_sel_alu1        <= 'd0;
      reg_ibuffer2issue_warps_control_Signals_sel_alu2        <= 'd0;
      reg_ibuffer2issue_warps_control_Signals_sel_alu3        <= 'd0;
      reg_ibuffer2issue_warps_control_Signals_pc              <= 'd0;
      reg_ibuffer2issue_warps_control_Signals_mask            <= 'd0;
      reg_ibuffer2issue_warps_control_Signals_fp              <= 'd0;
      reg_ibuffer2issue_warps_control_Signals_simt_stack      <= 'd0;
      reg_ibuffer2issue_warps_control_Signals_simt_stack_op   <= 'd0;
      reg_ibuffer2issue_warps_control_Signals_barrier         <= 'd0;
      reg_ibuffer2issue_warps_control_Signals_csr             <= 'd0;
      reg_ibuffer2issue_warps_control_Signals_reverse         <= 'd0;
      reg_ibuffer2issue_warps_control_Signals_mem_whb         <= 'd0;
      reg_ibuffer2issue_warps_control_Signals_mem_unsigned    <= 'd0;
      reg_ibuffer2issue_warps_control_Signals_alu_fn          <= 'd0;
      reg_ibuffer2issue_warps_control_Signals_force_rm_rtz    <= 'd0;
      reg_ibuffer2issue_warps_control_Signals_is_vls12        <= 'd0;
      reg_ibuffer2issue_warps_control_Signals_mem             <= 'd0;
      reg_ibuffer2issue_warps_control_Signals_mul             <= 'd0;
      reg_ibuffer2issue_warps_control_Signals_tc              <= 'd0;
      reg_ibuffer2issue_warps_control_Signals_disable_mask    <= 'd0;
      reg_ibuffer2issue_warps_control_Signals_mem_cmd         <= 'd0;
      reg_ibuffer2issue_warps_control_Signals_mop             <= 'd0;
      reg_ibuffer2issue_warps_control_Signals_reg_idxw        <= 'd0;
      reg_ibuffer2issue_warps_control_Signals_wvd             <= 'd0;
      reg_ibuffer2issue_warps_control_Signals_fence           <= 'd0;
      reg_ibuffer2issue_warps_control_Signals_sfu             <= 'd0;
      reg_ibuffer2issue_warps_control_Signals_wxd             <= 'd0;
      reg_ibuffer2issue_warps_control_Signals_atomic          <= 'd0;
      reg_ibuffer2issue_warps_control_Signals_aq              <= 'd0;
      reg_ibuffer2issue_warps_control_Signals_rl              <= 'd0;
      reg_ibuffer2issue_warps_control_Signals_rm              <= 'd0;
      reg_ibuffer2issue_warps_control_Signals_rm_is_static    <= 'd0;
    end
    else begin
      reg_ibuffer2issue_out_valid                             <= ibuffer2issue_out_valid                            ; 
      reg_ibuffer2issue_warps_control_Signals_wid             <= ibuffer2issue_warps_control_Signals_wid            ;
      reg_ibuffer2issue_warps_control_Signals_inst            <= ibuffer2issue_warps_control_Signals_inst           ;
      reg_ibuffer2issue_warps_control_Signals_imm_ext         <= ibuffer2issue_warps_control_Signals_imm_ext        ;
      reg_ibuffer2issue_warps_control_Signals_sel_imm         <= ibuffer2issue_warps_control_Signals_sel_imm        ;
      reg_ibuffer2issue_warps_control_Signals_reg_idx1        <= ibuffer2issue_warps_control_Signals_reg_idx1       ;
      reg_ibuffer2issue_warps_control_Signals_reg_idx2        <= ibuffer2issue_warps_control_Signals_reg_idx2       ;
      reg_ibuffer2issue_warps_control_Signals_reg_idx3        <= ibuffer2issue_warps_control_Signals_reg_idx3       ;
      reg_ibuffer2issue_warps_control_Signals_branch          <= ibuffer2issue_warps_control_Signals_branch         ;
      reg_ibuffer2issue_warps_control_Signals_custom_signal_0 <= ibuffer2issue_warps_control_Signals_custom_signal_0;
      reg_ibuffer2issue_warps_control_Signals_isvec           <= ibuffer2issue_warps_control_Signals_isvec          ;
      reg_ibuffer2issue_warps_control_Signals_readmask        <= ibuffer2issue_warps_control_Signals_readmask       ;
      reg_ibuffer2issue_warps_control_Signals_sel_alu1        <= ibuffer2issue_warps_control_Signals_sel_alu1       ;
      reg_ibuffer2issue_warps_control_Signals_sel_alu2        <= ibuffer2issue_warps_control_Signals_sel_alu2       ;
      reg_ibuffer2issue_warps_control_Signals_sel_alu3        <= ibuffer2issue_warps_control_Signals_sel_alu3       ;
      reg_ibuffer2issue_warps_control_Signals_pc              <= ibuffer2issue_warps_control_Signals_pc             ;
      reg_ibuffer2issue_warps_control_Signals_mask            <= ibuffer2issue_warps_control_Signals_mask           ;
      reg_ibuffer2issue_warps_control_Signals_fp              <= ibuffer2issue_warps_control_Signals_fp             ;
      reg_ibuffer2issue_warps_control_Signals_simt_stack      <= ibuffer2issue_warps_control_Signals_simt_stack     ;
      reg_ibuffer2issue_warps_control_Signals_simt_stack_op   <= ibuffer2issue_warps_control_Signals_simt_stack_op  ;
      reg_ibuffer2issue_warps_control_Signals_barrier         <= ibuffer2issue_warps_control_Signals_barrier        ;
      reg_ibuffer2issue_warps_control_Signals_csr             <= ibuffer2issue_warps_control_Signals_csr            ;
      reg_ibuffer2issue_warps_control_Signals_reverse         <= ibuffer2issue_warps_control_Signals_reverse        ;
      reg_ibuffer2issue_warps_control_Signals_mem_whb         <= ibuffer2issue_warps_control_Signals_mem_whb        ;
      reg_ibuffer2issue_warps_control_Signals_mem_unsigned    <= ibuffer2issue_warps_control_Signals_mem_unsigned   ;
      reg_ibuffer2issue_warps_control_Signals_alu_fn          <= ibuffer2issue_warps_control_Signals_alu_fn         ;
      reg_ibuffer2issue_warps_control_Signals_force_rm_rtz    <= ibuffer2issue_warps_control_Signals_force_rm_rtz   ;
      reg_ibuffer2issue_warps_control_Signals_is_vls12        <= ibuffer2issue_warps_control_Signals_is_vls12       ;
      reg_ibuffer2issue_warps_control_Signals_mem             <= ibuffer2issue_warps_control_Signals_mem            ;
      reg_ibuffer2issue_warps_control_Signals_mul             <= ibuffer2issue_warps_control_Signals_mul            ;
      reg_ibuffer2issue_warps_control_Signals_tc              <= ibuffer2issue_warps_control_Signals_tc             ;
      reg_ibuffer2issue_warps_control_Signals_disable_mask    <= ibuffer2issue_warps_control_Signals_disable_mask   ;
      reg_ibuffer2issue_warps_control_Signals_mem_cmd         <= ibuffer2issue_warps_control_Signals_mem_cmd        ;
      reg_ibuffer2issue_warps_control_Signals_mop             <= ibuffer2issue_warps_control_Signals_mop            ;
      reg_ibuffer2issue_warps_control_Signals_reg_idxw        <= ibuffer2issue_warps_control_Signals_reg_idxw       ;
      reg_ibuffer2issue_warps_control_Signals_wvd             <= ibuffer2issue_warps_control_Signals_wvd            ;
      reg_ibuffer2issue_warps_control_Signals_fence           <= ibuffer2issue_warps_control_Signals_fence          ;
      reg_ibuffer2issue_warps_control_Signals_sfu             <= ibuffer2issue_warps_control_Signals_sfu            ;
      reg_ibuffer2issue_warps_control_Signals_wxd             <= ibuffer2issue_warps_control_Signals_wxd            ;
      reg_ibuffer2issue_warps_control_Signals_atomic          <= ibuffer2issue_warps_control_Signals_atomic         ;
      reg_ibuffer2issue_warps_control_Signals_aq              <= ibuffer2issue_warps_control_Signals_aq             ;
      reg_ibuffer2issue_warps_control_Signals_rl              <= ibuffer2issue_warps_control_Signals_rl             ;
      reg_ibuffer2issue_warps_control_Signals_rm              <= ibuffer2issue_warps_control_Signals_rm             ;
      reg_ibuffer2issue_warps_control_Signals_rm_is_static    <= ibuffer2issue_warps_control_Signals_rm_is_static   ;
    end
  end

  assign scoreb_ibuffer2issue_warps_control_Signals_reg_idxw = {`NUM_WARP{ibuffer2issue_warps_control_Signals_reg_idxw}};
  assign scoreb_ibuffer2issue_warps_control_Signals_wvd      = {`NUM_WARP{ibuffer2issue_warps_control_Signals_wvd     }};
  assign scoreb_ibuffer2issue_warps_control_Signals_wxd      = {`NUM_WARP{ibuffer2issue_warps_control_Signals_wxd     }};
  assign scoreb_ibuffer2issue_warps_control_Signals_branch   = {`NUM_WARP{ibuffer2issue_warps_control_Signals_branch  }};
  assign scoreb_ibuffer2issue_warps_control_Signals_barrier  = {`NUM_WARP{ibuffer2issue_warps_control_Signals_barrier }};
  assign scoreb_ibuffer2issue_warps_control_Signals_fence    = {`NUM_WARP{ibuffer2issue_warps_control_Signals_fence   }};
  assign scoreb_wb_out_v_reg_idxw = {`NUM_WARP{wb_out_v_reg_idxw}};
  assign scoreb_wb_out_x_reg_idxw = {`NUM_WARP{wb_out_x_reg_idxw}};
  assign scoreb_wb_out_v_wvd = {`NUM_WARP{wb_out_v_wvd}};
  assign scoreb_wb_out_x_wxd = {`NUM_WARP{wb_out_x_wxd}};  

  assign operand_collector_out_fire = issue_in_ready && operand_collector_out_valid;

  assign flush_pipe_valid_o = warp_sche_flush_valid | warp_sche_flushCache_valid;
  assign flush_pipe_wid_o = warp_sche_flush_valid ? warp_sche_flush_wid : warp_sche_flushCache_wid;

  assign wb_out_x_fire = operand_collector_writeScalar_ready && wb_out_x_valid;
  assign wb_out_v_fire = operand_collector_writeVector_ready && wb_out_v_valid;

  assign issue_in_mask = operand_collector_out_isvec ? (operand_collector_out_active_mask & simt_stack_out_mask) : operand_collector_out_active_mask; 

  assign writeback_in_x_valid = {mul_out_x_valid,sfu_out_x_valid,csrfile_out_valid,lsu2wb_out_x_valid,fpu_out_x_valid,salu_out_valid};
  assign writeback_in_x_warp_id = {mul_out_x_warp_id,sfu_out_x_warp_id,csrfile_warp_id,lsu2wb_out_x_warp_id,fpu_out_x_warp_id,salu_out_warp_id}; 
  assign writeback_in_x_wxd =  {mul_out_x_wxd,sfu_out_x_wxd,csrfile_wxd,lsu2wb_out_x_wxd,fpu_out_x_wxd,salu_out_wxd};
  assign writeback_in_x_reg_idxw = {mul_out_x_reg_idwx,sfu_out_x_reg_idxw,csrfile_reg_idxw,lsu2wb_out_x_reg_idxw,fpu_out_x_reg_idxw,salu_out_reg_idxw}; 
  assign writeback_in_x_wb_wxd_rd = {mul_out_x_wb_wxd_rd,sfu_out_x_wb_wxd_rd,csrfile_wb_wxd_rd,lsu2wb_out_x_wb_wxd_rd,fpu_out_x_wb_wxd_rd,salu_out_wb_wxd_rd};

  assign writeback_in_v_valid = {tensorcore_out_v_valid,mul_out_v_valid,sfu_out_v_valid,lsu2wb_out_v_valid,fpu_out_v_valid,valu_out_valid};
  assign writeback_in_v_warp_id = {tensorcore_out_v_warp_id,mul_out_v_warp_id,sfu_out_v_warp_id,lsu2wb_out_v_warp_id,fpu_out_v_warp_id,valu_out_warp_id}; 
  assign writeback_in_v_wvd = {tensorcore_out_v_wvd,mul_out_v_wvd,sfu_out_v_wvd,lsu2wb_out_v_wvd,fpu_out_v_wvd,valu_out_wvd};
  assign writeback_in_v_reg_idxw = {tensorcore_out_v_reg_idxw,mul_out_v_reg_idxw,sfu_out_v_reg_idxw,lsu2wb_out_v_reg_idxw,fpu_out_v_reg_idxw,valu_out_reg_idxw};
  assign writeback_in_v_wvd_mask = {tensorcore_out_v_wvd_mask,mul_out_v_wvd_mask,sfu_out_v_wvd_mask,lsu2wb_out_v_wvd_mask,fpu_out_v_wvd_mask,valu_out_wvd_mask};
  assign writeback_in_v_wb_wvd_rd = {tensorcore_out_v_wb_wvd_rd,mul_out_v_wb_wxd_rd,sfu_out_v_wb_wvd_rd,lsu2wb_out_v_wb_wvd_rd,fpu_out_v_wb_wvd_rd,valu_out_wb_wvd_rd};

  assign csrfile_rm_wid = {issue_out_TC_warps_control_Signals_wid,issue_out_SFU_warps_control_Signals_wid,issue_out_vFPU_warps_control_Signals_wid};//{TC,sfu,fpu}
  
  assign fpu_rm = issue_out_vFPU_warps_control_Signals_force_rm_rt ? 'h1 : (issue_out_vFPU_warps_control_Signals_rm_is_static ? issue_out_vFPU_warps_control_Signals_rm : csrfile_rm[2:0]);//csrfile_rm[0] 

  warp_scheduler warp_sche(
    .clk                                    (clk                                    ),
    .rst_n                                  (rst_n                                  ),

    .warpReq_valid_i                        (warpReq_valid_i                        ),
    .warpReq_dispatch2cu_wf_tag_dispatch_i  (warpReq_dispatch2cu_wf_tag_dispatch_i  ),
    //.warpReq_dispatch2cu_wg_wf_count_i      (warpReq_dispatch2cu_wg_wf_count_i      ),
    .warpReq_wid_i                          (warpReq_wid_i                          ),
    .warpReq_dispatch2cu_start_pc_dispatch_i(warpReq_dispatch2cu_start_pc_dispatch_i),

    .warpRsp_ready_i                        (warpRsp_ready_i                        ),
    .warpRsp_valid_o                        (warpRsp_valid_o                        ),
    .warpRsp_wid_o                          (warpRsp_wid_o                          ),
                                                                                    
    .wg_id_lookup_o                         (wg_id_lookup_o                         ),
    .wg_id_tag_i                            (wg_id_tag_i                            ),

    //.pc_req_ready_i                         (icache_req_ready_i                     ),
    .pc_req_valid_o                         (icache_req_valid_o                     ),
    .pc_req_addr_o                          (icache_req_addr_o                      ),
    .pc_req_mask_o                          (icache_req_mask_o                      ),
    .pc_req_wid_o                           (icache_req_wid_o                       ),
                                                                                    
    .pc_rsp_valid_i                         (icache_rsp_valid_i                     ),
    .pc_rsp_addr_i                          (icache_rsp_addr_i                      ),
    .pc_rsp_mask_i                          (icache_rsp_mask_i                      ),
    .pc_rsp_wid_i                           (icache_rsp_wid_i                       ),
    .pc_rsp_status_i                        (warp_sche_status                       ),
                                                                 
    .branch_ready_o                         (warp_sche_branch_out_ready             ),
    .branch_valid_i                         (branch_back_out_valid                  ),
    .branch_wid_i                           (branch_back_out_wid                    ),
    .branch_jump_i                          (branch_back_out_jump                   ),
    .branch_new_pc_i                        (branch_back_out_new_pc                 ),

    .warp_control_ready_o                   (warp_sche_warp_control_ready           ),
    .warp_control_valid_i                   (issue_out_warps_valid                  ),
    .warp_control_simt_stack_op_i           (issue_out_warps_Signals_simt_stack_op  ),
    .warp_control_wid_i                     (issue_out_warps_Signals_wid            ),

    .scoreboard_busy_i                      (scoreb_delay                           ),
    .ibuffer_ready_i                        (ibuffer_ready                          ),
    .warp_ready_o                           (warp_sche_warp_ready                   ),

    .flush_valid_o                          (warp_sche_flush_valid                  ),
    .flush_wid_o                            (warp_sche_flush_wid                    ),

    .flushCache_valid_o                     (warp_sche_flushCache_valid             ),
    .flushCache_wid_o                       (warp_sche_flushCache_wid               )
    );

   decodeUnit decode(
     .clk                                (clk                                     ),
     .rst_n                              (rst_n                                   ),
     .inst_0_i                           (decode_in_inst0                         ),//[31:0]
     .inst_1_i                           (decode_in_inst1                         ),//[63:32]
     .inst_mask_0_i                      (decode_inst_mask_0                      ),
     .inst_mask_1_i                      (decode_inst_mask_1                      ),
     .pc_i                               (icache_rsp_addr_i                       ),
     .wid_i                              (icache_rsp_wid_i                        ),
     .flush_wid_i                        (warp_sche_flush_wid                     ),
     .flush_wid_valid_i                  (warp_sche_flush_valid                   ),
                                        
     .ibuffer_ready_i                    (ibuffer_ready                           ),
                                        
     .control_mask_0_o                   (decode_control_mask_0                   ),
     .control_mask_1_o                   (decode_control_mask_1                   ),
     .control_Signals_inst_0_o           (decode_control_Signals_inst_0           ),
     .control_Signals_wid_0_o            (decode_control_Signals_wid_0            ),
     .control_Signals_fp_0_o             (decode_control_Signals_fp_0             ),
     .control_Signals_branch_0_o         (decode_control_Signals_branch_0         ),
     .control_Signals_simt_stack_0_o     (decode_control_Signals_simt_stack_0     ),
     .control_Signals_simt_stack_op_0_o  (decode_control_Signals_simt_stack_op_0  ),
     .control_Signals_barrier_0_o        (decode_control_Signals_barrier_0        ),
     .control_Signals_csr_0_o            (decode_control_Signals_csr_0            ),
     .control_Signals_reverse_0_o        (decode_control_Signals_reverse_0        ),
     .control_Signals_sel_alu2_0_o       (decode_control_Signals_sel_alu2_0       ),
     .control_Signals_sel_alu1_0_o       (decode_control_Signals_sel_alu1_0       ),
     .control_Signals_sel_alu3_0_o       (decode_control_Signals_sel_alu3_0       ),
     .control_Signals_isvec_0_o          (decode_control_Signals_isvec_0          ),
     .control_Signals_mask_0_o           (decode_control_Signals_mask_0           ),
     .control_Signals_sel_imm_0_o        (decode_control_Signals_sel_imm_0        ),
     .control_Signals_mem_whb_0_o        (decode_control_Signals_mem_whb_0        ),
     .control_Signals_mem_unsigned_0_o   (decode_control_Signals_mem_unsigned_0   ),
     .control_Signals_alu_fn_0_o         (decode_control_Signals_alu_fn_0         ),
     .control_Signals_force_rm_rtz_0_o   (decode_control_Signals_force_rm_rtz_0   ),
     .control_Signals_is_vls12_0_o       (decode_control_Signals_is_vls12_0       ),
     .control_Signals_mem_0_o            (decode_control_Signals_mem_0            ),
     .control_Signals_mul_0_o            (decode_control_Signals_mul_0            ),
     .control_Signals_tc_0_o             (decode_control_Signals_tc_0             ),
     .control_Signals_disable_mask_0_o   (decode_control_Signals_disable_mask_0   ),
     .control_Signals_custom_signal_0_0_o(decode_control_Signals_custom_signal_0_0),
     .control_Signals_mem_cmd_0_o        (decode_control_Signals_mem_cmd_0        ),
     .control_Signals_mop_0_o            (decode_control_Signals_mop_0            ),
     .control_Signals_reg_idx1_0_o       (decode_control_Signals_reg_idx1_0       ),
     .control_Signals_reg_idx2_0_o       (decode_control_Signals_reg_idx2_0       ),
     .control_Signals_reg_idx3_0_o       (decode_control_Signals_reg_idx3_0       ),
     .control_Signals_reg_idxw_0_o       (decode_control_Signals_reg_idxw_0       ),
     .control_Signals_wvd_0_o            (decode_control_Signals_wvd_0            ),
     .control_Signals_fence_0_o          (decode_control_Signals_fence_0          ),
     .control_Signals_sfu_0_o            (decode_control_Signals_sfu_0            ),
     .control_Signals_readmask_0_o       (decode_control_Signals_readmask_0       ),
     .control_Signals_writemask_0_o      (decode_control_Signals_writemask_0      ),
     .control_Signals_wxd_0_o            (decode_control_Signals_wxd_0            ),
     .control_Signals_pc_0_o             (decode_control_Signals_pc_0             ),
     .control_Signals_imm_ext_0_o        (decode_control_Signals_imm_ext_0        ),
     .control_Signals_atomic_0_o         (decode_control_Signals_atomic_0         ),
     .control_Signals_aq_0_o             (decode_control_Signals_aq_0             ),
     .control_Signals_rl_0_o             (decode_control_Signals_rl_0             ),
     .rm_0_o                             (decode_rm_0                             ),//for static rm
     .rm_is_static_0_o                   (decode_rm_is_static_0                   ),
                                        
     .control_Signals_inst_1_o           (decode_control_Signals_inst_1           ),
     .control_Signals_wid_1_o            (decode_control_Signals_wid_1            ),
     .control_Signals_fp_1_o             (decode_control_Signals_fp_1             ),
     .control_Signals_branch_1_o         (decode_control_Signals_branch_1         ),
     .control_Signals_simt_stack_1_o     (decode_control_Signals_simt_stack_1     ),
     .control_Signals_simt_stack_op_1_o  (decode_control_Signals_simt_stack_op_1  ),
     .control_Signals_barrier_1_o        (decode_control_Signals_barrier_1        ),
     .control_Signals_csr_1_o            (decode_control_Signals_csr_1            ),
     .control_Signals_reverse_1_o        (decode_control_Signals_reverse_1        ),
     .control_Signals_sel_alu2_1_o       (decode_control_Signals_sel_alu2_1       ),
     .control_Signals_sel_alu1_1_o       (decode_control_Signals_sel_alu1_1       ),
     .control_Signals_sel_alu3_1_o       (decode_control_Signals_sel_alu3_1       ),
     .control_Signals_isvec_1_o          (decode_control_Signals_isvec_1          ),
     .control_Signals_mask_1_o           (decode_control_Signals_mask_1           ),
     .control_Signals_sel_imm_1_o        (decode_control_Signals_sel_imm_1        ),
     .control_Signals_mem_whb_1_o        (decode_control_Signals_mem_whb_1        ),
     .control_Signals_mem_unsigned_1_o   (decode_control_Signals_mem_unsigned_1   ),
     .control_Signals_alu_fn_1_o         (decode_control_Signals_alu_fn_1         ),
     .control_Signals_force_rm_rtz_1_o   (decode_control_Signals_force_rm_rtz_1   ),
     .control_Signals_is_vls12_1_o       (decode_control_Signals_is_vls12_1       ),
     .control_Signals_mem_1_o            (decode_control_Signals_mem_1            ),
     .control_Signals_mul_1_o            (decode_control_Signals_mul_1            ),
     .control_Signals_tc_1_o             (decode_control_Signals_tc_1             ),
     .control_Signals_disable_mask_1_o   (decode_control_Signals_disable_mask_1   ),
     .control_Signals_custom_signal_0_1_o(decode_control_Signals_custom_signal_0_1),
     .control_Signals_mem_cmd_1_o        (decode_control_Signals_mem_cmd_1        ),
     .control_Signals_mop_1_o            (decode_control_Signals_mop_1            ),
     .control_Signals_reg_idx1_1_o       (decode_control_Signals_reg_idx1_1       ),
     .control_Signals_reg_idx2_1_o       (decode_control_Signals_reg_idx2_1       ),
     .control_Signals_reg_idx3_1_o       (decode_control_Signals_reg_idx3_1       ),
     .control_Signals_reg_idxw_1_o       (decode_control_Signals_reg_idxw_1       ),
     .control_Signals_wvd_1_o            (decode_control_Signals_wvd_1            ),
     .control_Signals_fence_1_o          (decode_control_Signals_fence_1          ),
     .control_Signals_sfu_1_o            (decode_control_Signals_sfu_1            ),
     .control_Signals_readmask_1_o       (decode_control_Signals_readmask_1       ),
     .control_Signals_writemask_1_o      (decode_control_Signals_writemask_1      ),
     .control_Signals_wxd_1_o            (decode_control_Signals_wxd_1            ),
     .control_Signals_pc_1_o             (decode_control_Signals_pc_1             ),
     .control_Signals_imm_ext_1_o        (decode_control_Signals_imm_ext_1        ),
     .control_Signals_atomic_1_o         (decode_control_Signals_atomic_1         ),
     .control_Signals_aq_1_o             (decode_control_Signals_aq_1             ),
     .control_Signals_rl_1_o             (decode_control_Signals_rl_1             ),
     .rm_1_o                             (decode_rm_1                             ),//for static rm
     .rm_is_static_1_o                   (decode_rm_is_static_1                   )
     ); 

    ibuffer #(
      .BUFFER_WIDTH(159          ),
      .SIZE_IBUFFER(`SIZE_IBUFFER),      
      .NUM_FETCH   (`NUM_FETCH   )
      ) ibuffer(
      .clk                                            (clk                                          ),
      .rst_n                                          (rst_n                                        ),

      .ibuffer_in_valid_i                             (ibuffer_in_valid                             ),
      .ibuffer_in_ready_o                             (ibuffer_in_ready                             ),

      .ibuffer_in_control_mask_i                      (ibuffer_in_control_mask                      ),
      .ibuffer_in_control_Signals_inst_i              (ibuffer_in_control_Signals_inst              ),
      .ibuffer_in_control_Signals_wid_i               (ibuffer_in_control_Signals_wid               ),
      .ibuffer_in_control_Signals_fp_i                (ibuffer_in_control_Signals_fp                ),
      .ibuffer_in_control_Signals_branch_i            (ibuffer_in_control_Signals_branch            ),
      .ibuffer_in_control_Signals_simt_stack_i        (ibuffer_in_control_Signals_simt_stack        ),
      .ibuffer_in_control_Signals_simt_stack_op_i     (ibuffer_in_control_Signals_simt_stack_op     ),
      .ibuffer_in_control_Signals_barrier_i           (ibuffer_in_control_Signals_barrier           ),
      .ibuffer_in_control_Signals_csr_i               (ibuffer_in_control_Signals_csr               ),
      .ibuffer_in_control_Signals_reverse_i           (ibuffer_in_control_Signals_reverse           ),
      .ibuffer_in_control_Signals_sel_alu2_i          (ibuffer_in_control_Signals_sel_alu2          ),
      .ibuffer_in_control_Signals_sel_alu1_i          (ibuffer_in_control_Signals_sel_alu1          ),
      .ibuffer_in_control_Signals_sel_alu3_i          (ibuffer_in_control_Signals_sel_alu3          ),
      .ibuffer_in_control_Signals_isvec_i             (ibuffer_in_control_Signals_isvec             ),
      .ibuffer_in_control_Signals_mask_i              (ibuffer_in_control_Signals_mask              ),
      .ibuffer_in_control_Signals_sel_imm_i           (ibuffer_in_control_Signals_sel_imm           ),
      .ibuffer_in_control_Signals_mem_whb_i           (ibuffer_in_control_Signals_mem_whb           ),
      .ibuffer_in_control_Signals_mem_unsigned_i      (ibuffer_in_control_Signals_mem_unsigned      ),
      .ibuffer_in_control_Signals_alu_fn_i            (ibuffer_in_control_Signals_alu_fn            ),
      .ibuffer_in_control_Signals_force_rm_rtz_i      (ibuffer_in_control_Signals_force_rm_rtz      ),
      .ibuffer_in_control_Signals_is_vls12_i          (ibuffer_in_control_Signals_is_vls12          ),
      .ibuffer_in_control_Signals_mem_i               (ibuffer_in_control_Signals_mem               ),
      .ibuffer_in_control_Signals_mul_i               (ibuffer_in_control_Signals_mul               ),
      .ibuffer_in_control_Signals_tc_i                (ibuffer_in_control_Signals_tc                ),
      .ibuffer_in_control_Signals_disable_mask_i      (ibuffer_in_control_Signals_disable_mask      ),
      .ibuffer_in_control_Signals_custom_signal_0_i   (ibuffer_in_control_Signals_custom_signal_0   ),
      .ibuffer_in_control_Signals_mem_cmd_i           (ibuffer_in_control_Signals_mem_cmd           ),
      .ibuffer_in_control_Signals_mop_i               (ibuffer_in_control_Signals_mop               ),
      .ibuffer_in_control_Signals_reg_idx1_i          (ibuffer_in_control_Signals_reg_idx1          ),
      .ibuffer_in_control_Signals_reg_idx2_i          (ibuffer_in_control_Signals_reg_idx2          ),
      .ibuffer_in_control_Signals_reg_idx3_i          (ibuffer_in_control_Signals_reg_idx3          ),
      .ibuffer_in_control_Signals_reg_idxw_i          (ibuffer_in_control_Signals_reg_idxw          ),
      .ibuffer_in_control_Signals_wvd_i               (ibuffer_in_control_Signals_wvd               ),
      .ibuffer_in_control_Signals_fence_i             (ibuffer_in_control_Signals_fence             ),
      .ibuffer_in_control_Signals_sfu_i               (ibuffer_in_control_Signals_sfu               ),
      .ibuffer_in_control_Signals_readmask_i          (ibuffer_in_control_Signals_readmask          ),
      .ibuffer_in_control_Signals_writemask_i         (ibuffer_in_control_Signals_writemask         ),
      .ibuffer_in_control_Signals_wxd_i               (ibuffer_in_control_Signals_wxd               ),
      .ibuffer_in_control_Signals_pc_i                (ibuffer_in_control_Signals_pc                ),
      .ibuffer_in_control_Signals_imm_ext_i           (ibuffer_in_control_Signals_imm_ext           ),
      .ibuffer_in_control_Signals_atomic_i            (ibuffer_in_control_Signals_atomic            ),
      .ibuffer_in_control_Signals_aq_i                (ibuffer_in_control_Signals_aq                ),
      .ibuffer_in_control_Signals_rl_i                (ibuffer_in_control_Signals_rl                ),
      .ibuffer_in_control_Signals_rm_i                (ibuffer_in_control_Signals_rm                ),
      .ibuffer_in_control_Signals_rm_is_static_i      (ibuffer_in_control_Signals_rm_is_static      ),

      .ibuffer_flush_wid_valid_i                      (warp_sche_flush_valid                        ),
      .ibuffer_flush_wid_i                            (warp_sche_flush_wid                          ),

      .ibuffer_warps_control_Signals_inst_o           (ibuffer_warps_control_Signals_inst           ),
      .ibuffer_warps_control_Signals_wid_o            (ibuffer_warps_control_Signals_wid            ),
      .ibuffer_warps_control_Signals_fp_o             (ibuffer_warps_control_Signals_fp             ),
      .ibuffer_warps_control_Signals_branch_o         (ibuffer_warps_control_Signals_branch         ),
      .ibuffer_warps_control_Signals_simt_stack_o     (ibuffer_warps_control_Signals_simt_stack     ),
      .ibuffer_warps_control_Signals_simt_stack_op_o  (ibuffer_warps_control_Signals_simt_stack_op  ),
      .ibuffer_warps_control_Signals_barrier_o        (ibuffer_warps_control_Signals_barrier        ),
      .ibuffer_warps_control_Signals_csr_o            (ibuffer_warps_control_Signals_csr            ),
      .ibuffer_warps_control_Signals_reverse_o        (ibuffer_warps_control_Signals_reverse        ),
      .ibuffer_warps_control_Signals_sel_alu2_o       (ibuffer_warps_control_Signals_sel_alu2       ),
      .ibuffer_warps_control_Signals_sel_alu1_o       (ibuffer_warps_control_Signals_sel_alu1       ),
      .ibuffer_warps_control_Signals_sel_alu3_o       (ibuffer_warps_control_Signals_sel_alu3       ),
      .ibuffer_warps_control_Signals_isvec_o          (ibuffer_warps_control_Signals_isvec          ),
      .ibuffer_warps_control_Signals_mask_o           (ibuffer_warps_control_Signals_mask           ),
      .ibuffer_warps_control_Signals_sel_imm_o        (ibuffer_warps_control_Signals_sel_imm        ),
      .ibuffer_warps_control_Signals_mem_whb_o        (ibuffer_warps_control_Signals_mem_whb        ),
      .ibuffer_warps_control_Signals_mem_unsigned_o   (ibuffer_warps_control_Signals_mem_unsigned   ),
      .ibuffer_warps_control_Signals_alu_fn_o         (ibuffer_warps_control_Signals_alu_fn         ),
      .ibuffer_warps_control_Signals_force_rm_rtz_o   (ibuffer_warps_control_Signals_force_rm_rtz   ),
      .ibuffer_warps_control_Signals_is_vls12_o       (ibuffer_warps_control_Signals_is_vls12       ),
      .ibuffer_warps_control_Signals_mem_o            (ibuffer_warps_control_Signals_mem            ),
      .ibuffer_warps_control_Signals_mul_o            (ibuffer_warps_control_Signals_mul            ),
      .ibuffer_warps_control_Signals_tc_o             (ibuffer_warps_control_Signals_tc             ),
      .ibuffer_warps_control_Signals_disable_mask_o   (ibuffer_warps_control_Signals_disable_mask   ),
      .ibuffer_warps_control_Signals_custom_signal_0_o(ibuffer_warps_control_Signals_custom_signal_0),
      .ibuffer_warps_control_Signals_mem_cmd_o        (ibuffer_warps_control_Signals_mem_cmd        ),
      .ibuffer_warps_control_Signals_mop_o            (ibuffer_warps_control_Signals_mop            ),
      .ibuffer_warps_control_Signals_reg_idx1_o       (ibuffer_warps_control_Signals_reg_idx1       ),
      .ibuffer_warps_control_Signals_reg_idx2_o       (ibuffer_warps_control_Signals_reg_idx2       ),
      .ibuffer_warps_control_Signals_reg_idx3_o       (ibuffer_warps_control_Signals_reg_idx3       ),
      .ibuffer_warps_control_Signals_reg_idxw_o       (ibuffer_warps_control_Signals_reg_idxw       ),
      .ibuffer_warps_control_Signals_wvd_o            (ibuffer_warps_control_Signals_wvd            ),
      .ibuffer_warps_control_Signals_fence_o          (ibuffer_warps_control_Signals_fence          ),
      .ibuffer_warps_control_Signals_sfu_o            (ibuffer_warps_control_Signals_sfu            ),
      .ibuffer_warps_control_Signals_readmask_o       (ibuffer_warps_control_Signals_readmask       ),
      //.ibuffer_warps_control_Signals_writemask_o      (ibuffer_warps_control_Signals_writemask      ),
      .ibuffer_warps_control_Signals_wxd_o            (ibuffer_warps_control_Signals_wxd            ),
      .ibuffer_warps_control_Signals_pc_o             (ibuffer_warps_control_Signals_pc             ),
      .ibuffer_warps_control_Signals_imm_ext_o        (ibuffer_warps_control_Signals_imm_ext        ),
      .ibuffer_warps_control_Signals_atomic_o         (ibuffer_warps_control_Signals_atomic         ),
      .ibuffer_warps_control_Signals_aq_o             (ibuffer_warps_control_Signals_aq             ),
      .ibuffer_warps_control_Signals_rl_o             (ibuffer_warps_control_Signals_rl             ),
      .ibuffer_warps_control_Signals_rm_o             (ibuffer_warps_control_Signals_rm             ),
      .ibuffer_warps_control_Signals_rm_is_static_o   (ibuffer_warps_control_Signals_rm_is_static   ),

      .ibuffer2issue_io_in_ready_i                    (ibuffer2issue_in_ready                       ),
      .warp_sche_io_warp_ready_i                      (warp_sche_warp_ready                         ),
                                                                                                    
      .ibuffer_ready_o                                (ibuffer_ready                                ),
      .ibuffer_out_valid_o                            (ibuffer_out_valid                            ), 
      .ibuffer2issue_grant_i                          (ibuffer2issue_grant                          )
      );

    ibuffer2issue ibuffer2issue(
      .clk                                                  (clk                                                ),
      .rst_n                                                (rst_n                                              ),
                                                           
      .ibuffer_warps_control_Signals_inst_i                 (ibuffer_warps_control_Signals_inst                 ),
      .ibuffer_warps_control_Signals_wid_i                  (ibuffer_warps_control_Signals_wid                  ),
      .ibuffer_warps_control_Signals_fp_i                   (ibuffer_warps_control_Signals_fp                   ),
      .ibuffer_warps_control_Signals_branch_i               (ibuffer_warps_control_Signals_branch               ),
      .ibuffer_warps_control_Signals_simt_stack_i           (ibuffer_warps_control_Signals_simt_stack           ),
      .ibuffer_warps_control_Signals_simt_stack_op_i        (ibuffer_warps_control_Signals_simt_stack_op        ),
      .ibuffer_warps_control_Signals_barrier_i              (ibuffer_warps_control_Signals_barrier              ),
      .ibuffer_warps_control_Signals_csr_i                  (ibuffer_warps_control_Signals_csr                  ),
      .ibuffer_warps_control_Signals_reverse_i              (ibuffer_warps_control_Signals_reverse              ),
      .ibuffer_warps_control_Signals_sel_alu2_i             (ibuffer_warps_control_Signals_sel_alu2             ),
      .ibuffer_warps_control_Signals_sel_alu1_i             (ibuffer_warps_control_Signals_sel_alu1             ),
      .ibuffer_warps_control_Signals_sel_alu3_i             (ibuffer_warps_control_Signals_sel_alu3             ),
      .ibuffer_warps_control_Signals_isvec_i                (ibuffer_warps_control_Signals_isvec                ),
      .ibuffer_warps_control_Signals_mask_i                 (ibuffer_warps_control_Signals_mask                 ),
      .ibuffer_warps_control_Signals_sel_imm_i              (ibuffer_warps_control_Signals_sel_imm              ),
      .ibuffer_warps_control_Signals_mem_whb_i              (ibuffer_warps_control_Signals_mem_whb              ),
      .ibuffer_warps_control_Signals_mem_unsigned_i         (ibuffer_warps_control_Signals_mem_unsigned         ),
      .ibuffer_warps_control_Signals_alu_fn_i               (ibuffer_warps_control_Signals_alu_fn               ),
      .ibuffer_warps_control_Signals_force_rm_rtz_i         (ibuffer_warps_control_Signals_force_rm_rtz         ),
      .ibuffer_warps_control_Signals_is_vls12_i             (ibuffer_warps_control_Signals_is_vls12             ),
      .ibuffer_warps_control_Signals_mem_i                  (ibuffer_warps_control_Signals_mem                  ),
      .ibuffer_warps_control_Signals_mul_i                  (ibuffer_warps_control_Signals_mul                  ),
      .ibuffer_warps_control_Signals_tc_i                   (ibuffer_warps_control_Signals_tc                   ),
      .ibuffer_warps_control_Signals_disable_mask_i         (ibuffer_warps_control_Signals_disable_mask         ),
      .ibuffer_warps_control_Signals_custom_signal_0_i      (ibuffer_warps_control_Signals_custom_signal_0      ),
      .ibuffer_warps_control_Signals_mem_cmd_i              (ibuffer_warps_control_Signals_mem_cmd              ),
      .ibuffer_warps_control_Signals_mop_i                  (ibuffer_warps_control_Signals_mop                  ),
      .ibuffer_warps_control_Signals_reg_idx1_i             (ibuffer_warps_control_Signals_reg_idx1             ),
      .ibuffer_warps_control_Signals_reg_idx2_i             (ibuffer_warps_control_Signals_reg_idx2             ),
      .ibuffer_warps_control_Signals_reg_idx3_i             (ibuffer_warps_control_Signals_reg_idx3             ),
      .ibuffer_warps_control_Signals_reg_idxw_i             (ibuffer_warps_control_Signals_reg_idxw             ),
      .ibuffer_warps_control_Signals_wvd_i                  (ibuffer_warps_control_Signals_wvd                  ),
      .ibuffer_warps_control_Signals_fence_i                (ibuffer_warps_control_Signals_fence                ),
      .ibuffer_warps_control_Signals_sfu_i                  (ibuffer_warps_control_Signals_sfu                  ),
      .ibuffer_warps_control_Signals_readmask_i             (ibuffer_warps_control_Signals_readmask             ),
      //.ibuffer_warps_control_Signals_writemask_i            (ibuffer_warps_control_Signals_writemask            ),
      .ibuffer_warps_control_Signals_wxd_i                  (ibuffer_warps_control_Signals_wxd                  ),
      .ibuffer_warps_control_Signals_pc_i                   (ibuffer_warps_control_Signals_pc                   ),
      .ibuffer_warps_control_Signals_imm_ext_i              (ibuffer_warps_control_Signals_imm_ext              ),
      .ibuffer_warps_control_Signals_atomic_i               (ibuffer_warps_control_Signals_atomic               ),
      .ibuffer_warps_control_Signals_aq_i                   (ibuffer_warps_control_Signals_aq                   ),
      .ibuffer_warps_control_Signals_rl_i                   (ibuffer_warps_control_Signals_rl                   ),
      .ibuffer_warps_control_Signals_rm_i                   (ibuffer_warps_control_Signals_rm                   ),
      .ibuffer_warps_control_Signals_rm_is_static_i         (ibuffer_warps_control_Signals_rm_is_static         ),
                                                           
      .ibuffer2issue_in_valid_i                             (ibuffer2issue_in_valid                             ),
      .ibuffer2issue_in_ready_o                             (ibuffer2issue_in_ready                             ),

      .ibuffer2issue_warps_control_Signals_inst_o           (ibuffer2issue_warps_control_Signals_inst           ),
      .ibuffer2issue_warps_control_Signals_wid_o            (ibuffer2issue_warps_control_Signals_wid            ),
      .ibuffer2issue_warps_control_Signals_fp_o             (ibuffer2issue_warps_control_Signals_fp             ),
      .ibuffer2issue_warps_control_Signals_branch_o         (ibuffer2issue_warps_control_Signals_branch         ),
      .ibuffer2issue_warps_control_Signals_simt_stack_o     (ibuffer2issue_warps_control_Signals_simt_stack     ),
      .ibuffer2issue_warps_control_Signals_simt_stack_op_o  (ibuffer2issue_warps_control_Signals_simt_stack_op  ),
      .ibuffer2issue_warps_control_Signals_barrier_o        (ibuffer2issue_warps_control_Signals_barrier        ),
      .ibuffer2issue_warps_control_Signals_csr_o            (ibuffer2issue_warps_control_Signals_csr            ),
      .ibuffer2issue_warps_control_Signals_reverse_o        (ibuffer2issue_warps_control_Signals_reverse        ),
      .ibuffer2issue_warps_control_Signals_sel_alu2_o       (ibuffer2issue_warps_control_Signals_sel_alu2       ),
      .ibuffer2issue_warps_control_Signals_sel_alu1_o       (ibuffer2issue_warps_control_Signals_sel_alu1       ),
      .ibuffer2issue_warps_control_Signals_sel_alu3_o       (ibuffer2issue_warps_control_Signals_sel_alu3       ),
      .ibuffer2issue_warps_control_Signals_isvec_o          (ibuffer2issue_warps_control_Signals_isvec          ),
      .ibuffer2issue_warps_control_Signals_mask_o           (ibuffer2issue_warps_control_Signals_mask           ),
      .ibuffer2issue_warps_control_Signals_sel_imm_o        (ibuffer2issue_warps_control_Signals_sel_imm        ),
      .ibuffer2issue_warps_control_Signals_mem_whb_o        (ibuffer2issue_warps_control_Signals_mem_whb        ),
      .ibuffer2issue_warps_control_Signals_mem_unsigned_o   (ibuffer2issue_warps_control_Signals_mem_unsigned   ),
      .ibuffer2issue_warps_control_Signals_alu_fn_o         (ibuffer2issue_warps_control_Signals_alu_fn         ),
      .ibuffer2issue_warps_control_Signals_force_rm_rtz_o   (ibuffer2issue_warps_control_Signals_force_rm_rtz   ),
      .ibuffer2issue_warps_control_Signals_is_vls12_o       (ibuffer2issue_warps_control_Signals_is_vls12       ),
      .ibuffer2issue_warps_control_Signals_mem_o            (ibuffer2issue_warps_control_Signals_mem            ),
      .ibuffer2issue_warps_control_Signals_mul_o            (ibuffer2issue_warps_control_Signals_mul            ),
      .ibuffer2issue_warps_control_Signals_tc_o             (ibuffer2issue_warps_control_Signals_tc             ),
      .ibuffer2issue_warps_control_Signals_disable_mask_o   (ibuffer2issue_warps_control_Signals_disable_mask   ),
      .ibuffer2issue_warps_control_Signals_custom_signal_0_o(ibuffer2issue_warps_control_Signals_custom_signal_0),
      .ibuffer2issue_warps_control_Signals_mem_cmd_o        (ibuffer2issue_warps_control_Signals_mem_cmd        ),
      .ibuffer2issue_warps_control_Signals_mop_o            (ibuffer2issue_warps_control_Signals_mop            ),
      .ibuffer2issue_warps_control_Signals_reg_idx1_o       (ibuffer2issue_warps_control_Signals_reg_idx1       ),
      .ibuffer2issue_warps_control_Signals_reg_idx2_o       (ibuffer2issue_warps_control_Signals_reg_idx2       ),
      .ibuffer2issue_warps_control_Signals_reg_idx3_o       (ibuffer2issue_warps_control_Signals_reg_idx3       ),
      .ibuffer2issue_warps_control_Signals_reg_idxw_o       (ibuffer2issue_warps_control_Signals_reg_idxw       ),
      .ibuffer2issue_warps_control_Signals_wvd_o            (ibuffer2issue_warps_control_Signals_wvd            ),
      .ibuffer2issue_warps_control_Signals_fence_o          (ibuffer2issue_warps_control_Signals_fence          ),
      .ibuffer2issue_warps_control_Signals_sfu_o            (ibuffer2issue_warps_control_Signals_sfu            ),
      .ibuffer2issue_warps_control_Signals_readmask_o       (ibuffer2issue_warps_control_Signals_readmask       ),
      //.ibuffer2issue_warps_control_Signals_writemask_o      (ibuffer2issue_warps_control_Signals_writemask      ),
      .ibuffer2issue_warps_control_Signals_wxd_o            (ibuffer2issue_warps_control_Signals_wxd            ),
      .ibuffer2issue_warps_control_Signals_pc_o             (ibuffer2issue_warps_control_Signals_pc             ),
      .ibuffer2issue_warps_control_Signals_imm_ext_o        (ibuffer2issue_warps_control_Signals_imm_ext        ),
      .ibuffer2issue_warps_control_Signals_atomic_o         (ibuffer2issue_warps_control_Signals_atomic         ),
      .ibuffer2issue_warps_control_Signals_aq_o             (ibuffer2issue_warps_control_Signals_aq             ),
      .ibuffer2issue_warps_control_Signals_rl_o             (ibuffer2issue_warps_control_Signals_rl             ),
      .ibuffer2issue_warps_control_Signals_rm_o             (ibuffer2issue_warps_control_Signals_rm             ),
      .ibuffer2issue_warps_control_Signals_rm_is_static_o   (ibuffer2issue_warps_control_Signals_rm_is_static   ),
      .ibuffer2issue_out_valid_o                            (ibuffer2issue_out_valid                            ),
      .ibuffer2issue_out_ready_i                            (operand_collector_control_ready                    ),
      .grant                                                (ibuffer2issue_grant                                )
      ); 

    genvar i;
    generate for(i=0;i<`NUM_WARP;i=i+1) begin:B1
      assign scoreb_if_fire[i] = (i == ibuffer2issue_warps_control_Signals_wid) ? ibuffer2issue_out_fire : 'b0; 
      assign scoreb_op_col_in_fire[i] = (i == ibuffer2issue_warps_control_Signals_wid) ? ibuffer2issue_out_fire : 'b0; 
      assign scoreb_op_col_out_fire[i] = (i == operand_collector_out_wid) ? operand_collector_out_fire : 'b0;
      assign scoreb_wb_x_fire[i] = (i == wb_out_x_warp_id) ? wb_out_x_fire : 'b0;
      assign scoreb_wb_v_fire[i] = (i == wb_out_v_warp_id) ? wb_out_v_fire : 'b0;
      assign scoreb_br_ctrl[i] = ((warp_sche_branch_fire && (i == branch_back_out_wid)) || 
                                  (warp_sche_warp_control_fire && (i == issue_out_warps_Signals_wid)) ||
                                  (simt_stack_complete_valid && (i == simt_stack_complete_wid))) ? 'b1 : 'b0;  

      scoreboard scoreb(
        .clk                  (clk                                                                                                                          ), 
        .rst_n                (rst_n                                                                                                                        ), 
                              
        .ibuffer_if_sel_alu1_i(ibuffer_warps_control_Signals_sel_alu1[(((i+1)*2)-1)-:2]                                                                     ), 
        .ibuffer_if_sel_alu2_i(ibuffer_warps_control_Signals_sel_alu2[(((i+1)*2)-1)-:2]                                                                     ), 
        .ibuffer_if_sel_alu3_i(ibuffer_warps_control_Signals_sel_alu3[(((i+1)*2)-1)-:2]                                                                     ), 
        .ibuffer_if_reg_idx1_i(ibuffer_warps_control_Signals_reg_idx1[(((i+1)*(`REGEXT_WIDTH+`REGIDX_WIDTH))-1)-:(`REGEXT_WIDTH+`REGIDX_WIDTH)]             ), 
        .ibuffer_if_reg_idx2_i(ibuffer_warps_control_Signals_reg_idx2[(((i+1)*(`REGEXT_WIDTH+`REGIDX_WIDTH))-1)-:(`REGEXT_WIDTH+`REGIDX_WIDTH)]             ), 
        .ibuffer_if_reg_idx3_i(ibuffer_warps_control_Signals_reg_idx3[(((i+1)*(`REGEXT_WIDTH+`REGIDX_WIDTH))-1)-:(`REGEXT_WIDTH+`REGIDX_WIDTH)]             ), 
        .ibuffer_if_reg_idxw_i(ibuffer_warps_control_Signals_reg_idxw[(((i+1)*(`REGEXT_WIDTH+`REGIDX_WIDTH))-1)-:(`REGEXT_WIDTH+`REGIDX_WIDTH)]             ), 
        .ibuffer_if_isvec_i   (ibuffer_warps_control_Signals_isvec[i]                                                                                       ), 
        .ibuffer_if_readmask_i(ibuffer_warps_control_Signals_readmask[i]                                                                                    ), 
        .ibuffer_if_branch_i  (ibuffer_warps_control_Signals_branch[(((i+1)*2)-1)-:2]                                                                       ), 
        .ibuffer_if_mask_i    (ibuffer_warps_control_Signals_mask[i]                                                                                        ), 
        .ibuffer_if_wxd_i     (ibuffer_warps_control_Signals_wxd[i]                                                                                         ), 
        .ibuffer_if_wvd_i     (ibuffer_warps_control_Signals_wvd[i]                                                                                         ), 
        .ibuffer_if_mem_i     (ibuffer_warps_control_Signals_mem[i]                                                                                         ), 
        //.ibuffer_if_valid_i   (ibuffer_ready[i]                                                                                         ), 
                              
        .if_reg_idxw_i        (scoreb_ibuffer2issue_warps_control_Signals_reg_idxw[(((i+1)*(`REGEXT_WIDTH+`REGIDX_WIDTH))-1)-:(`REGEXT_WIDTH+`REGIDX_WIDTH)]), 
        .if_wvd_i             (scoreb_ibuffer2issue_warps_control_Signals_wvd[i]                                                                            ), 
        .if_wxd_i             (scoreb_ibuffer2issue_warps_control_Signals_wxd[i]                                                                            ), 
        .if_branch_i          (scoreb_ibuffer2issue_warps_control_Signals_branch[(((i+1)*2)-1)-:2]                                                          ), 
        .if_barrier_i         (scoreb_ibuffer2issue_warps_control_Signals_barrier[i]                                                                        ), 
        .if_fence_i           (scoreb_ibuffer2issue_warps_control_Signals_fence[i]                                                                          ), 
        .if_fire_i            (scoreb_if_fire[i]                                                                                                            ), 
                              
        .wb_v_reg_idxw_i      (scoreb_wb_out_v_reg_idxw[(((i+1)*(`REGEXT_WIDTH+`REGIDX_WIDTH))-1)-:(`REGEXT_WIDTH+`REGIDX_WIDTH)]                           ), 
        .wb_v_wvd_i           (scoreb_wb_out_v_wvd[i]                                                                                                       ), 
        .wb_v_fire_i          (scoreb_wb_v_fire[i]                                                                                                          ), 
        .wb_x_reg_idxw_i      (scoreb_wb_out_x_reg_idxw[(((i+1)*(`REGEXT_WIDTH+`REGIDX_WIDTH))-1)-:(`REGEXT_WIDTH+`REGIDX_WIDTH)]                           ), 
        .wb_x_wxd_i           (scoreb_wb_out_x_wxd[i]                                                                                                       ), 
        .wb_x_fire_i          (scoreb_wb_x_fire[i]                                                                                                          ), 
                               
        //.if_reg_idxw_i        (ibuffer2issue_warps_control_Signals_reg_idxw                                                                    ), 
        //.if_wvd_i             (ibuffer2issue_warps_control_Signals_wvd                                                                         ), 
        //.if_wxd_i             (ibuffer2issue_warps_control_Signals_wxd                                                                         ), 
        //.if_branch_i          (ibuffer2issue_warps_control_Signals_branch                                                                      ), 
        //.if_barrier_i         (ibuffer2issue_warps_control_Signals_barrier                                                                     ), 
        //.if_fence_i           (ibuffer2issue_warps_control_Signals_fence                                                                       ), 
        //.if_fire_i            (scoreb_if_fire[i]                                                                                               ), 
                              
        //.wb_v_reg_idxw_i      (wb_out_v_reg_idxw                                                                                               ), 
        //.wb_v_wvd_i           (wb_out_v_wvd                                                                                                    ), 
        //.wb_v_fire_i          (scoreb_wb_v_fire[i]                                                                                             ), 
        //.wb_x_reg_idxw_i      (wb_out_x_reg_idxw                                                                                               ), 
        //.wb_x_wxd_i           (wb_out_x_wxd                                                                                                    ), 
        //.wb_x_fire_i          (scoreb_wb_x_fire[i]                                                                                             ), 
        
        .br_ctrl_i            (scoreb_br_ctrl[i]                                                                                                            ), 
        .fence_end_i          (lsu_fence_end[i]                                                                                                             ), 
        .op_col_in_fire_i     (scoreb_op_col_in_fire[i]                                                                                                     ), 
        .op_col_out_fire_i    (scoreb_op_col_out_fire[i]                                                                                                    ), 
        
        .delay_o              (scoreb_delay[i]                                                                                                              ) 
      );
    end 
    endgenerate

    operandcollector_top operand_collector(
      .clk                    (clk                                                    ),  
      .rst_n                  (rst_n                                                  ),  
                               
      .in_valid_i             (reg_ibuffer2issue_out_valid                            ),  
      .in_ready_o             (operand_collector_control_ready                        ),  
      .in_wid_i               (reg_ibuffer2issue_warps_control_Signals_wid            ),  
      .in_inst_i              (reg_ibuffer2issue_warps_control_Signals_inst           ),  
      .in_imm_ext_i           (reg_ibuffer2issue_warps_control_Signals_imm_ext        ),  
      .in_sel_imm_i           (reg_ibuffer2issue_warps_control_Signals_sel_imm        ),  
      .in_reg_idx1_i          (reg_ibuffer2issue_warps_control_Signals_reg_idx1       ),  
      .in_reg_idx2_i          (reg_ibuffer2issue_warps_control_Signals_reg_idx2       ),  
      .in_reg_idx3_i          (reg_ibuffer2issue_warps_control_Signals_reg_idx3       ),  
      .in_branch_i            (reg_ibuffer2issue_warps_control_Signals_branch         ),  
      .in_custom_signal_0_i   (reg_ibuffer2issue_warps_control_Signals_custom_signal_0),  
      .in_isvec_i             (reg_ibuffer2issue_warps_control_Signals_isvec          ),  
      .in_readmask_i          (reg_ibuffer2issue_warps_control_Signals_readmask       ),  
      .in_sel_alu1_i          (reg_ibuffer2issue_warps_control_Signals_sel_alu1       ),  
      .in_sel_alu2_i          (reg_ibuffer2issue_warps_control_Signals_sel_alu2       ),  
      .in_sel_alu3_i          (reg_ibuffer2issue_warps_control_Signals_sel_alu3       ),  
      .in_pc_i                (reg_ibuffer2issue_warps_control_Signals_pc             ),  
      .in_mask_i              (reg_ibuffer2issue_warps_control_Signals_mask           ),  
      .in_fp_i                (reg_ibuffer2issue_warps_control_Signals_fp             ),
      .in_simt_stack_i        (reg_ibuffer2issue_warps_control_Signals_simt_stack     ),
      .in_simt_stack_op_i     (reg_ibuffer2issue_warps_control_Signals_simt_stack_op  ),
      .in_barrier_i           (reg_ibuffer2issue_warps_control_Signals_barrier        ),
      .in_csr_i               (reg_ibuffer2issue_warps_control_Signals_csr            ),
      .in_reverse_i           (reg_ibuffer2issue_warps_control_Signals_reverse        ),
      .in_mem_whb_i           (reg_ibuffer2issue_warps_control_Signals_mem_whb        ),
      .in_mem_unsigned_i      (reg_ibuffer2issue_warps_control_Signals_mem_unsigned   ),
      .in_alu_fn_i            (reg_ibuffer2issue_warps_control_Signals_alu_fn         ),
      .in_force_rm_rtz_i      (reg_ibuffer2issue_warps_control_Signals_force_rm_rtz   ),
      .in_is_vls12_i          (reg_ibuffer2issue_warps_control_Signals_is_vls12       ),
      .in_mem_i               (reg_ibuffer2issue_warps_control_Signals_mem            ),
      .in_mul_i               (reg_ibuffer2issue_warps_control_Signals_mul            ),
      .in_tc_i                (reg_ibuffer2issue_warps_control_Signals_tc             ),
      .in_disable_mask_i      (reg_ibuffer2issue_warps_control_Signals_disable_mask   ),
      .in_mem_cmd_i           (reg_ibuffer2issue_warps_control_Signals_mem_cmd        ),
      .in_mop_i               (reg_ibuffer2issue_warps_control_Signals_mop            ),
      .in_reg_idxw_i          (reg_ibuffer2issue_warps_control_Signals_reg_idxw       ),
      .in_wvd_i               (reg_ibuffer2issue_warps_control_Signals_wvd            ),
      .in_fence_i             (reg_ibuffer2issue_warps_control_Signals_fence          ),
      .in_sfu_i               (reg_ibuffer2issue_warps_control_Signals_sfu            ),
      //.in_writemask_i         (reg_ibuffer2issue_warps_control_Signals_writemask      ),
      .in_wxd_i               (reg_ibuffer2issue_warps_control_Signals_wxd            ),
      .in_atomic_i            (reg_ibuffer2issue_warps_control_Signals_atomic         ),
      .in_aq_i                (reg_ibuffer2issue_warps_control_Signals_aq             ),
      .in_rl_i                (reg_ibuffer2issue_warps_control_Signals_rl             ),
      .in_rm_i                (reg_ibuffer2issue_warps_control_Signals_rm             ),
      .in_rm_is_static_i      (reg_ibuffer2issue_warps_control_Signals_rm_is_static   ),

      .writeScalar_valid_i    (wb_out_x_valid                                     ),  
      .writeScalar_ready_o    (operand_collector_writeScalar_ready                ),  
      .writeScalar_rd_i       (wb_out_x_wb_wxd_rd                                 ),  
      .writeScalar_wxd_i      (wb_out_x_wxd                                       ),  
      .writeScalar_idxw_i     (wb_out_x_reg_idxw                                  ),  
      .writeScalar_wid_i      (wb_out_x_warp_id                                   ),  
                               
      .writeVector_valid_i    (wb_out_v_valid                                     ),  
      .writeVector_ready_o    (operand_collector_writeVector_ready                ),  
      .writeVector_rd_i       (wb_out_v_wb_wvd_rd                                 ),  
      .writeVector_wvd_mask_i (wb_out_v_wvd_mask                                  ),  
      .writeVector_wvd_i      (wb_out_v_wvd                                       ),  
      .writeVector_idxw_i     (wb_out_v_reg_idxw                                  ),  
      .writeVector_wid_i      (wb_out_v_warp_id                                   ),  
                               
      .sgpr_base_i            (csrfile_sgpr_base                                  ),  
      .vgpr_base_i            (csrfile_vgpr_base                                  ),  
                               
      .out_valid_o            (operand_collector_out_valid                        ), 
      .out_ready_i            (issue_in_ready                                     ), 
      .out_wid_o              (operand_collector_out_wid                          ),    
      .out_inst_o             (operand_collector_out_inst                         ), 
      //.out_imm_ext_o          (operand_collector_out_imm_ext                      ), 
      //.out_sel_imm_o          (operand_collector_out_sel_imm                      ), 
      //.out_reg_idx1_o         (operand_collector_out_reg_idx1                     ), 
      //.out_reg_idx2_o         (operand_collector_out_reg_idx2                     ),    
      //.out_reg_idx3_o         (operand_collector_out_reg_idx3                     ),
      .out_branch_o           (operand_collector_out_branch                       ),
      .out_custom_signal_0_o  (operand_collector_out_custom_signal_0              ),
      .out_isvec_o            (operand_collector_out_isvec                        ),
      //.out_readmask_o         (operand_collector_out_readmask                     ),
      //.out_sel_alu1_o         (operand_collector_out_sel_alu1                     ),
      //.out_sel_alu2_o         (operand_collector_out_sel_alu2                     ),
      //.out_sel_alu3_o         (operand_collector_out_sel_alu3                     ),
      .out_pc_o               (operand_collector_out_pc                           ),
      //.out_mask_o             (operand_collector_out_mask                         ),
      .out_fp_o               (operand_collector_out_fp                           ),
      .out_simt_stack_o       (operand_collector_out_simt_stack                   ),
      .out_simt_stack_op_o    (operand_collector_out_simt_stack_op                ),
      .out_barrier_o          (operand_collector_out_barrier                      ),
      .out_csr_o              (operand_collector_out_csr                          ),
      .out_reverse_o          (operand_collector_out_reverse                      ),
      .out_mem_whb_o          (operand_collector_out_mem_whb                      ),
      .out_mem_unsigned_o     (operand_collector_out_mem_unsigned                 ),
      .out_alu_fn_o           (operand_collector_out_alu_fn                       ),
      .out_force_rm_rtz_o     (operand_collector_out_force_rm_rtz                 ),
      .out_is_vls12_o         (operand_collector_out_is_vls12                     ),
      .out_mem_o              (operand_collector_out_mem                          ),
      .out_mul_o              (operand_collector_out_mul                          ),
      .out_tc_o               (operand_collector_out_tc                           ),
      .out_disable_mask_o     (operand_collector_out_disable_mask                 ),
      .out_mem_cmd_o          (operand_collector_out_mem_cmd                      ),
      .out_mop_o              (operand_collector_out_mop                          ),
      .out_reg_idxw_o         (operand_collector_out_reg_idxw                     ),
      .out_wvd_o              (operand_collector_out_wvd                          ),
      .out_fence_o            (operand_collector_out_fence                        ),
      .out_sfu_o              (operand_collector_out_sfu                          ),
      //.out_writemask_o        (operand_collector_out_writemask                    ),
      .out_wxd_o              (operand_collector_out_wxd                          ),
      .out_atomic_o           (operand_collector_out_atomic                       ),
      .out_aq_o               (operand_collector_out_aq                           ),
      .out_rl_o               (operand_collector_out_rl                           ),
      .out_rm_o               (operand_collector_out_rm                           ),
      .out_rm_is_static_o     (operand_collector_out_rm_is_static                 ),
      .out_alu_src1_o         (operand_collector_out_alu_src1                     ),
      .out_alu_src2_o         (operand_collector_out_alu_src2                     ),
      .out_alu_src3_o         (operand_collector_out_alu_src3                     ),
      .out_active_mask_o      (operand_collector_out_active_mask                  )
      );

    issue issue(
      //.clk                                                   (clk                                                ),
      //.rst_n                                                 (rst_n                                              ),
                                                            
      .issue_in_ready_o                                      (issue_in_ready                                     ),
      .issue_in_valid_i                                      (operand_collector_out_valid                        ),
      .issue_in_vExeData_in1_i                               (operand_collector_out_alu_src1                     ),
      .issue_in_vExeData_in2_i                               (operand_collector_out_alu_src2                     ),
      .issue_in_vExeData_in3_i                               (operand_collector_out_alu_src3                     ),
      .issue_in_vExeData_mask_i                              (issue_in_mask                                      ),
      .issue_in_warps_control_Signals_inst_i                 (operand_collector_out_inst                         ),
      .issue_in_warps_control_Signals_wid_i                  (operand_collector_out_wid                          ),
      .issue_in_warps_control_Signals_fp_i                   (operand_collector_out_fp                           ),
      .issue_in_warps_control_Signals_branch_i               (operand_collector_out_branch                       ),
      .issue_in_warps_control_Signals_simt_stack_i           (operand_collector_out_simt_stack                   ),
      .issue_in_warps_control_Signals_simt_stack_op_i        (operand_collector_out_simt_stack_op                ),
      .issue_in_warps_control_Signals_barrier_i              (operand_collector_out_barrier                      ),
      .issue_in_warps_control_Signals_csr_i                  (operand_collector_out_csr                          ),
      .issue_in_warps_control_Signals_reverse_i              (operand_collector_out_reverse                      ),
      //.issue_in_warps_control_Signals_sel_alu2_i             (operand_collector_out_sel_alu2                     ),
      //.issue_in_warps_control_Signals_sel_alu1_i             (operand_collector_out_sel_alu1                     ),
      //.issue_in_warps_control_Signals_sel_alu3_i             (operand_collector_out_sel_alu3                     ),
      .issue_in_warps_control_Signals_isvec_i                (operand_collector_out_isvec                        ),
      //.issue_in_warps_control_Signals_mask_i                 (operand_collector_out_mask                         ),
      //.issue_in_warps_control_Signals_sel_imm_i              (operand_collector_out_sel_imm                      ),
      .issue_in_warps_control_Signals_mem_whb_i              (operand_collector_out_mem_whb                      ),
      .issue_in_warps_control_Signals_mem_unsigned_i         (operand_collector_out_mem_unsigned                 ),
      .issue_in_warps_control_Signals_alu_fn_i               (operand_collector_out_alu_fn                       ),
      .issue_in_warps_control_Signals_force_rm_rtz_i         (operand_collector_out_force_rm_rtz                 ),
      .issue_in_warps_control_Signals_is_vls12_i             (operand_collector_out_is_vls12                     ),
      .issue_in_warps_control_Signals_mem_i                  (operand_collector_out_mem                          ),
      .issue_in_warps_control_Signals_mul_i                  (operand_collector_out_mul                          ),
      .issue_in_warps_control_Signals_tc_i                   (operand_collector_out_tc                           ),
      .issue_in_warps_control_Signals_disable_mask_i         (operand_collector_out_disable_mask                 ),
      .issue_in_warps_control_Signals_custom_signal_0_i      (operand_collector_out_custom_signal_0              ),
      .issue_in_warps_control_Signals_mem_cmd_i              (operand_collector_out_mem_cmd                      ),
      .issue_in_warps_control_Signals_mop_i                  (operand_collector_out_mop                          ),
      //.issue_in_warps_control_Signals_reg_idx1_i             (operand_collector_out_reg_idx1                     ),
      //.issue_in_warps_control_Signals_reg_idx2_i             (operand_collector_out_reg_idx2                     ),
      //.issue_in_warps_control_Signals_reg_idx3_i             (operand_collector_out_reg_idx3                     ),
      .issue_in_warps_control_Signals_reg_idxw_i             (operand_collector_out_reg_idxw                     ),
      .issue_in_warps_control_Signals_wvd_i                  (operand_collector_out_wvd                          ),
      .issue_in_warps_control_Signals_fence_i                (operand_collector_out_fence                        ),
      .issue_in_warps_control_Signals_sfu_i                  (operand_collector_out_sfu                          ),
      //.issue_in_warps_control_Signals_readmask_i             (operand_collector_out_readmask                     ),
      //.issue_in_warps_control_Signals_writemask_i            (operand_collector_out_writemask                    ),
      .issue_in_warps_control_Signals_wxd_i                  (operand_collector_out_wxd                          ),
      .issue_in_warps_control_Signals_pc_i                   (operand_collector_out_pc                           ),
      //.issue_in_warps_control_Signals_imm_ext_i              (operand_collector_out_imm_ext                      ),
      .issue_in_warps_control_Signals_atomic_i               (operand_collector_out_atomic                       ),
      .issue_in_warps_control_Signals_aq_i                   (operand_collector_out_aq                           ),
      .issue_in_warps_control_Signals_rl_i                   (operand_collector_out_rl                           ),
      .issue_in_warps_control_Signals_rm_i                   (operand_collector_out_rm                           ),
      .issue_in_warps_control_Signals_rm_is_static_i         (operand_collector_out_rm_is_static                 ),
                                                            
      .issue_out_sALU_valid_o                                (issue_out_sALU_valid                               ),
      .issue_out_sALU_ready_i                                (salu_in_ready                                      ),
      .issue_out_sALU_sExeData_in1_o                         (issue_out_sALU_sExeData_in1                        ),
      .issue_out_sALU_sExeData_in2_o                         (issue_out_sALU_sExeData_in2                        ),
      .issue_out_sALU_sExeData_in3_o                         (issue_out_sALU_sExeData_in3                        ),
      .issue_out_sALU_warps_control_Signals_wid_o            (issue_out_sALU_warps_control_Signals_wid           ),
      .issue_out_sALU_warps_control_Signals_branch_o         (issue_out_sALU_warps_control_Signals_branch        ),
      .issue_out_sALU_warps_control_Signals_alu_fn_o         (issue_out_sALU_warps_control_Signals_alu_fn        ),
      .issue_out_sALU_warps_control_Signals_reg_idxw_o       (issue_out_sALU_warps_control_Signals_reg_idxw      ),
      .issue_out_sALU_warps_control_Signals_wxd_o            (issue_out_sALU_warps_control_Signals_wxd           ),
                                                            
      .issue_out_vALU_valid_o                                (issue_out_vALU_valid                               ),
      .issue_out_vALU_ready_i                                (valu_in_ready                                      ),
      .issue_out_vALU_vExeData_in1_o                         (issue_out_vALU_vExeData_in1                        ),
      .issue_out_vALU_vExeData_in2_o                         (issue_out_vALU_vExeData_in2                        ),
      .issue_out_vALU_vExeData_in3_o                         (issue_out_vALU_vExeData_in3                        ),
      .issue_out_vALU_vExeData_mask_o                        (issue_out_vALU_vExeData_mask                       ),
      .issue_out_vALU_warps_control_Signals_wid_o            (issue_out_vALU_warps_control_Signals_wid           ),
      .issue_out_vALU_warps_control_Signals_simt_stack_o     (issue_out_vALU_warps_control_Signals_simt_stack    ),
      .issue_out_vALU_warps_control_Signals_reverse_o        (issue_out_vALU_warps_control_Signals_reverse       ),
      .issue_out_vALU_warps_control_Signals_alu_fn_o         (issue_out_vALU_warps_control_Signals_alu_fn        ),
      .issue_out_vALU_warps_control_Signals_reg_idxw_o       (issue_out_vALU_warps_control_Signals_reg_idxw      ),
      .issue_out_vALU_warps_control_Signals_wvd_o            (issue_out_vALU_warps_control_Signals_wvd           ),
                                                            
      .issue_out_vFPU_valid_o                                (issue_out_vFPU_valid                               ),
      .issue_out_vFPU_ready_i                                (fpu_in_ready                                       ),
      .issue_out_vFPU_vExeData_in1_o                         (issue_out_vFPU_vExeData_in1                        ),
      .issue_out_vFPU_vExeData_in2_o                         (issue_out_vFPU_vExeData_in2                        ),
      .issue_out_vFPU_vExeData_in3_o                         (issue_out_vFPU_vExeData_in3                        ),
      .issue_out_vFPU_vExeData_mask_o                        (issue_out_vFPU_vExeData_mask                       ),
      .issue_out_vFPU_warps_control_Signals_wid_o            (issue_out_vFPU_warps_control_Signals_wid           ),
      .issue_out_vFPU_warps_control_Signals_reverse_o        (issue_out_vFPU_warps_control_Signals_reverse       ),
      .issue_out_vFPU_warps_control_Signals_alu_fn_o         (issue_out_vFPU_warps_control_Signals_alu_fn        ),
      .issue_out_vFPU_warps_control_Signals_force_rm_rtz_o   (issue_out_vFPU_warps_control_Signals_force_rm_rt   ),
      .issue_out_vFPU_warps_control_Signals_reg_idxw_o       (issue_out_vFPU_warps_control_Signals_reg_idxw      ),
      .issue_out_vFPU_warps_control_Signals_wvd_o            (issue_out_vFPU_warps_control_Signals_wvd           ),
      .issue_out_vFPU_warps_control_Signals_wxd_o            (issue_out_vFPU_warps_control_Signals_wxd           ),
      .issue_out_vFPU_warps_control_Signals_rm_o             (issue_out_vFPU_warps_control_Signals_rm            ),
      .issue_out_vFPU_warps_control_Signals_rm_is_static_o   (issue_out_vFPU_warps_control_Signals_rm_is_static  ),
                                                            
      .issue_out_LSU_valid_o                                 (issue_out_LSU_valid                                ),
      .issue_out_LSU_ready_i                                 (lsu_req_ready                                      ),
      .issue_out_LSU_vExeData_in1_o                          (issue_out_LSU_vExeData_in1                         ),
      .issue_out_LSU_vExeData_in2_o                          (issue_out_LSU_vExeData_in2                         ),
      .issue_out_LSU_vExeData_in3_o                          (issue_out_LSU_vExeData_in3                         ),
      .issue_out_LSU_vExeData_mask_o                         (issue_out_LSU_vExeData_mask                        ),
      .issue_out_LSU_warps_control_Signals_wid_o             (issue_out_LSU_warps_control_Signals_wid            ),
      .issue_out_LSU_warps_control_Signals_isvec_o           (issue_out_LSU_warps_control_Signals_isvec          ),
      .issue_out_LSU_warps_control_Signals_mem_whb_o         (issue_out_LSU_warps_control_Signals_mem_whb        ),
      .issue_out_LSU_warps_control_Signals_mem_unsigned_o    (issue_out_LSU_warps_control_Signals_mem_unsigned   ),
      .issue_out_LSU_warps_control_Signals_alu_fn_o          (issue_out_LSU_warps_control_Signals_alu_fn         ),
      .issue_out_LSU_warps_control_Signals_is_vls12_o        (issue_out_LSU_warps_control_Signals_is_vls12       ),
      .issue_out_LSU_warps_control_Signals_disable_mask_o    (issue_out_LSU_warps_control_Signals_disable_mask   ),
      .issue_out_LSU_warps_control_Signals_mem_cmd_o         (issue_out_LSU_warps_control_Signals_mem_cmd        ),
      .issue_out_LSU_warps_control_Signals_mop_o             (issue_out_LSU_warps_control_Signals_mop            ),
      .issue_out_LSU_warps_control_Signals_reg_idxw_o        (issue_out_LSU_warps_control_Signals_reg_idxw       ),
      .issue_out_LSU_warps_control_Signals_wvd_o             (issue_out_LSU_warps_control_Signals_wvd            ),
      .issue_out_LSU_warps_control_Signals_fence_o           (issue_out_LSU_warps_control_Signals_fence          ),
      .issue_out_LSU_warps_control_Signals_wxd_o             (issue_out_LSU_warps_control_Signals_wxd            ),
      .issue_out_LSU_warps_control_Signals_atomic_o          (issue_out_LSU_warps_control_Signals_atomic         ),
      .issue_out_LSU_warps_control_Signals_aq_o              (issue_out_LSU_warps_control_Signals_aq             ),
      .issue_out_LSU_warps_control_Signals_rl_o              (issue_out_LSU_warps_control_Signals_rl             ),
                                                            
      .issue_out_SFU_valid_o                                 (issue_out_SFU_valid                                ),
      .issue_out_SFU_ready_i                                 (sfu_in_ready                                       ),
      .issue_out_SFU_vExeData_in1_o                          (issue_out_SFU_vExeData_in1                         ),
      .issue_out_SFU_vExeData_in2_o                          (issue_out_SFU_vExeData_in2                         ),
      .issue_out_SFU_vExeData_in3_o                          (issue_out_SFU_vExeData_in3                         ),
      .issue_out_SFU_vExeData_mask_o                         (issue_out_SFU_vExeData_mask                        ),
      .issue_out_SFU_warps_control_Signals_wid_o             (issue_out_SFU_warps_control_Signals_wid            ),
      .issue_out_SFU_warps_control_Signals_fp_o              (issue_out_SFU_warps_control_Signals_fp             ),
      .issue_out_SFU_warps_control_Signals_reverse_o         (issue_out_SFU_warps_control_Signals_reverse        ),
      .issue_out_SFU_warps_control_Signals_isvec_o           (issue_out_SFU_warps_control_Signals_isvec          ),
      .issue_out_SFU_warps_control_Signals_alu_fn_o          (issue_out_SFU_warps_control_Signals_alu_fn         ),
      .issue_out_SFU_warps_control_Signals_reg_idxw_o        (issue_out_SFU_warps_control_Signals_reg_idxw       ),
      .issue_out_SFU_warps_control_Signals_wvd_o             (issue_out_SFU_warps_control_Signals_wvd            ),
      .issue_out_SFU_warps_control_Signals_wxd_o             (issue_out_SFU_warps_control_Signals_wxd            ),
                                                            
      .issue_out_warps_valid_o                               (issue_out_warps_valid                              ),
      .issue_out_warps_ready_i                               (warp_sche_warp_control_ready                       ),
      .issue_out_warps_control_Signals_wid_o                 (issue_out_warps_Signals_wid                        ),
      .issue_out_warps_control_Signals_simt_stack_op_o       (issue_out_warps_Signals_simt_stack_op              ),
                                                            
      .issue_out_CSR_valid_o                                 (issue_out_CSR_valid                                ),
      .issue_out_CSR_ready_i                                 (csrfile_in_ready                                   ),
      .issue_out_CSR_csrExeData_in1_o                        (issue_out_CSR_csrExeData_in1                       ),
      .issue_out_CSR_warps_control_Signals_inst_o            (issue_out_CSR_warps_control_Signals_inst           ),
      .issue_out_CSR_warps_control_Signals_wid_o             (issue_out_CSR_warps_control_Signals_wid            ),
      .issue_out_CSR_warps_control_Signals_csr_o             (issue_out_CSR_warps_control_Signals_csr            ),
      .issue_out_CSR_warps_control_Signals_isvec_o           (issue_out_CSR_warps_control_Signals_isvec          ),
      .issue_out_CSR_warps_control_Signals_custom_signal_0_o (issue_out_CSR_warps_control_Signals_custom_signal_0),
      .issue_out_CSR_warps_control_Signals_reg_idxw_o        (issue_out_CSR_warps_control_Signals_reg_idxw       ),
      .issue_out_CSR_warps_control_Signals_wxd_o             (issue_out_CSR_warps_control_Signals_wxd            ),
                                                            
      .issue_out_MUL_valid_o                                 (issue_out_MUL_valid                                ),
      .issue_out_MUL_ready_i                                 (mul_in_ready                                       ),
      .issue_out_MUL_vExeData_in1_o                          (issue_out_MUL_vExeData_in1                         ),
      .issue_out_MUL_vExeData_in2_o                          (issue_out_MUL_vExeData_in2                         ),
      .issue_out_MUL_vExeData_in3_o                          (issue_out_MUL_vExeData_in3                         ),
      .issue_out_MUL_vExeData_mask_o                         (issue_out_MUL_vExeData_mask                        ),
      .issue_out_MUL_warps_control_Signals_wid_o             (issue_out_MUL_warps_control_Signals_wid            ),
      .issue_out_MUL_warps_control_Signals_reverse_o         (issue_out_MUL_warps_control_Signals_reverse        ),
      .issue_out_MUL_warps_control_Signals_alu_fn_o          (issue_out_MUL_warps_control_Signals_alu_fn         ),
      .issue_out_MUL_warps_control_Signals_reg_idxw_o        (issue_out_MUL_warps_control_Signals_reg_idxw       ),
      .issue_out_MUL_warps_control_Signals_wvd_o             (issue_out_MUL_warps_control_Signals_wvd            ),
      .issue_out_MUL_warps_control_Signals_wxd_o             (issue_out_MUL_warps_control_Signals_wxd            ),
                                                            
      .issue_out_TC_valid_o                                  (issue_out_TC_valid                                 ),
      .issue_out_TC_ready_i                                  (tensorcore_in_ready                                ),
      .issue_out_TC_vExeData_in1_o                           (issue_out_TC_vExeData_in1                          ),
      .issue_out_TC_vExeData_in2_o                           (issue_out_TC_vExeData_in2                          ),
      .issue_out_TC_vExeData_in3_o                           (issue_out_TC_vExeData_in3                          ),
      .issue_out_TC_warps_control_Signals_wid_o              (issue_out_TC_warps_control_Signals_wid             ),
      .issue_out_TC_warps_control_Signals_reg_idxw_o         (issue_out_TC_warps_control_Signals_reg_idxw        ),
                                                            
      .issue_simtExeData_valid_o                             (issue_out_SIMT_valid                               ),
      .issue_simtExeData_ready_i                             (simt_stack_branch_ctl_ready                        ),
      .issue_simtExeData_opcode_o                            (issue_out_SIMT_opcode                              ),
      .issue_simtExeData_wid_o                               (issue_out_SIMT_wid                                 ),
      .issue_simtExeData_PC_branch_o                         (issue_out_SIMT_PC_branch                           ),
      .issue_simtExeData_PC_execute_o                        (issue_out_SIMT_PC_execute                          ),
      .issue_simtExeData_mask_init_o                         (issue_out_SIMT_mask_init                           )
    );

    valu_top #(
    .SOFT_THREAD(`NUM_THREAD),
    .HARD_THREAD(`NUMBER_ALU),
    .MAX_ITER   (`NUM_THREAD/`NUMBER_ALU) //SOFT/HARD
    ) alu(
    .clk              (clk                                            ),
    .rst_n            (rst_n                                          ),
                   
    .in_valid_i       (issue_out_vALU_valid                           ),
    .out_ready_i      (writeback_in_v_ready[0]                        ),
    .out2simt_ready_i (simt_stack_if_mask_ready                       ),
                   
    .in1_i            (issue_out_vALU_vExeData_in1                    ),
    .in2_i            (issue_out_vALU_vExeData_in2                    ),
    .in3_i            (issue_out_vALU_vExeData_in3                    ),
    .mask_i           (issue_out_vALU_vExeData_mask                   ),
    .ctrl_alu_fn_i    (issue_out_vALU_warps_control_Signals_alu_fn    ),
    .ctrl_reverse_i   (issue_out_vALU_warps_control_Signals_reverse   ),
    //.ctrl_writemask_i (issue_out_vALU_warps_control_Signals_writemask ),
    //.ctrl_readmask_i  (issue_out_vALU_warps_control_Signals_readmask  ),
    .ctrl_simt_stack_i(issue_out_vALU_warps_control_Signals_simt_stack),
    .ctrl_wid_i       (issue_out_vALU_warps_control_Signals_wid       ),
    .ctrl_reg_idxw_i  (issue_out_vALU_warps_control_Signals_reg_idxw  ),
    .ctrl_wvd_i       (issue_out_vALU_warps_control_Signals_wvd       ),
                    
    .in_ready_o       (valu_in_ready                                  ),
    .out_valid_o      (valu_out_valid                                 ),
    .out2simt_valid_o (valu_out2simt_valid                            ),
                    
    .wb_wvd_rd_o      (valu_out_wb_wvd_rd                             ),
    .wvd_mask_o       (valu_out_wvd_mask                              ),
    .wvd_o            (valu_out_wvd                                   ),
    .reg_idxw_o       (valu_out_reg_idxw                              ),
    .warp_id_o        (valu_out_warp_id                               ),
                    
    .if_mask_o        (valu_out2simt_if_mask                          ),
    .wid_o            (valu_out2simt_wid                              )
    ); 

    lsu_exe lsu(
      .clk                       (clk                                             ),
      .rst_n                     (rst_n                                           ),

      .lsu_req_valid_i           (issue_out_LSU_valid                             ),
      .lsu_req_ready_o           (lsu_req_ready                                   ),
      .lsu_req_in1_i             (issue_out_LSU_vExeData_in1                      ),
      .lsu_req_in2_i             (issue_out_LSU_vExeData_in2                      ),
      .lsu_req_in3_i             (issue_out_LSU_vExeData_in3                      ),
      .lsu_req_mask_i            (issue_out_LSU_vExeData_mask                     ),
      .lsu_req_wid_i             (issue_out_LSU_warps_control_Signals_wid         ),
      .lsu_req_isvec_i           (issue_out_LSU_warps_control_Signals_isvec       ),
      .lsu_req_mem_whb_i         (issue_out_LSU_warps_control_Signals_mem_whb     ),
      .lsu_req_mem_unsigned_i    (issue_out_LSU_warps_control_Signals_mem_unsigned),
      .lsu_req_alu_fn_i          (issue_out_LSU_warps_control_Signals_alu_fn      ),
      .lsu_req_is_vls12_i        (issue_out_LSU_warps_control_Signals_is_vls12    ),
      .lsu_req_disable_mask_i    (issue_out_LSU_warps_control_Signals_disable_mask),
      .lsu_req_mem_cmd_i         (issue_out_LSU_warps_control_Signals_mem_cmd     ),
      .lsu_req_mop_i             (issue_out_LSU_warps_control_Signals_mop         ),
      .lsu_req_reg_idxw_i        (issue_out_LSU_warps_control_Signals_reg_idxw    ),
      .lsu_req_wvd_i             (issue_out_LSU_warps_control_Signals_wvd         ),
      .lsu_req_fence_i           (issue_out_LSU_warps_control_Signals_fence       ),
      .lsu_req_wxd_i             (issue_out_LSU_warps_control_Signals_wxd         ),
      .lsu_req_atomic_i          (issue_out_LSU_warps_control_Signals_atomic      ),
      .lsu_req_aq_i              (issue_out_LSU_warps_control_Signals_aq          ),
      .lsu_req_rl_i              (issue_out_LSU_warps_control_Signals_rl          ),

      .lsu_rsp_valid_o           (lsu_rsp_valid                                   ),
      .lsu_rsp_ready_i           (lsu2wb_rsp_ready                                ),
      .lsu_rsp_warp_id_o         (lsu_rsp_warp_id                                 ),
      .lsu_rsp_wfd_o             (lsu_rsp_wfd                                     ),
      .lsu_rsp_wxd_o             (lsu_rsp_wxd                                     ),
      //.lsu_rsp_isvec_o           (lsu_rsp_isvec                                   ),
      .lsu_rsp_reg_idxw_o        (lsu_rsp_reg_idxw                                ),
      .lsu_rsp_mask_o            (lsu_rsp_mask                                    ),
      //.lsu_rsp_unsigned_o        (lsu_rsp_unsigned                                ),
      //.lsu_rsp_wordoffset1h_o    (lsu_rsp_wordoffset1h                            ),
      .lsu_rsp_iswrite_o         (lsu_rsp_iswrite                                 ),
      .lsu_rsp_data_o            (lsu_rsp_data                                    ),

      .dcache_req_valid_o        (dcache_req_valid_o                              ),
      .dcache_req_ready_i        (dcache_req_ready_i                              ),
      .dcache_req_instrid_o      (dcache_req_instrid_o                            ),
      .dcache_req_setidx_o       (dcache_req_setidx_o                             ),
      .dcache_req_tag_o          (dcache_req_tag_o                                ),
      .dcache_req_activemask_o   (dcache_req_activemask_o                         ),
      .dcache_req_blockoffset_o  (dcache_req_blockoffset_o                        ),
      .dcache_req_wordoffset1h_o (dcache_req_wordoffset1h_o                       ),
      .dcache_req_data_o         (dcache_req_data_o                               ),
      .dcache_req_opcode_o       (dcache_req_opcode_o                             ),
      .dcache_req_param_o        (dcache_req_param_o                              ),

      .dcache_rsp_valid_i        (dcache_rsp_valid_i                              ),
      .dcache_rsp_ready_o        (dcache_rsp_ready_o                              ),
      .dcache_rsp_instrid_i      (dcache_rsp_instrid_i                            ),
      .dcache_rsp_data_i         (dcache_rsp_data_i                               ),
      .dcache_rsp_activemask_i   (dcache_rsp_activemask_i                         ),

      .shared_req_valid_o        (shared_req_valid_o                              ),
      .shared_req_ready_i        (shared_req_ready_i                              ),
      .shared_req_instrid_o      (shared_req_instrid_o                            ),
      .shared_req_iswrite_o      (shared_req_iswrite_o                            ),
      .shared_req_tag_o          (shared_req_tag_o                                ),
      .shared_req_setidx_o       (shared_req_setidx_o                             ),
      .shared_req_activemask_o   (shared_req_activemask_o                         ),
      .shared_req_blockoffset_o  (shared_req_blockoffset_o                        ),
      .shared_req_wordoffset1h_o (shared_req_wordoffset1h_o                       ),
      .shared_req_data_o         (shared_req_data_o                               ),

      .shared_rsp_valid_i        (shared_rsp_valid_i                              ),
      .shared_rsp_ready_o        (shared_rsp_ready_o                              ),
      .shared_rsp_instrid_i      (shared_rsp_instrid_i                            ),
      .shared_rsp_data_i         (shared_rsp_data_i                               ),
      .shared_rsp_activemask_i   (shared_rsp_activemask_i                         ),

      .fence_end_o               (lsu_fence_end                                   ),

      .csr_pds_i                 (csrfile_lsu_pds                                 ),
      .csr_numw_i                (csrfile_lsu_numw                                ),
      .csr_tid_i                 (csrfile_lsu_tid                                 ),
      .csr_wid_o                 (lsu_csr_wid                                     )
      );

    lsu2wb lsu2wb(
      .lsu_rsp_valid_i       (lsu_rsp_valid       ),
      .lsu_rsp_ready_o       (lsu2wb_rsp_ready    ),
      .lsu_rsp_warp_id_i     (lsu_rsp_warp_id     ),
      .lsu_rsp_wfd_i         (lsu_rsp_wfd         ),
      .lsu_rsp_wxd_i         (lsu_rsp_wxd         ),
      //.lsu_rsp_isvec_i       (lsu_rsp_isvec       ),
      .lsu_rsp_reg_idxw_i    (lsu_rsp_reg_idxw    ),
      .lsu_rsp_mask_i        (lsu_rsp_mask        ),
      //.lsu_rsp_unsigned_i    (lsu_rsp_unsigned    ),
      //.lsu_rsp_wordoffset1h_i(lsu_rsp_wordoffset1h),
      .lsu_rsp_iswrite_i     (lsu_rsp_iswrite     ),
      .lsu_rsp_data_i        (lsu_rsp_data        ),
                            
      .out_x_valid_o         (lsu2wb_out_x_valid     ),
      .out_x_ready_i         (writeback_in_x_ready[2]),
      .out_x_warp_id_o       (lsu2wb_out_x_warp_id   ),
      .out_x_wxd_o           (lsu2wb_out_x_wxd       ),
      .out_x_reg_idxw_o      (lsu2wb_out_x_reg_idxw  ),
      .out_x_wb_wxd_rd_o     (lsu2wb_out_x_wb_wxd_rd ),
                            
      .out_v_valid_o         (lsu2wb_out_v_valid     ),
      .out_v_ready_i         (writeback_in_v_ready[2]),
      .out_v_warp_id_o       (lsu2wb_out_v_warp_id   ),
      .out_v_wvd_o           (lsu2wb_out_v_wvd       ),
      .out_v_reg_idxw_o      (lsu2wb_out_v_reg_idxw  ),
      .out_v_wvd_mask_o      (lsu2wb_out_v_wvd_mask  ),
      .out_v_wb_wvd_rd_o     (lsu2wb_out_v_wb_wvd_rd )
      );

    aluexe salu(
      .clk            (clk                                          ),
      .rst_n          (rst_n                                        ),
      .in_valid_i     (issue_out_sALU_valid                         ),
      .out_ready_i    (writeback_in_x_ready[0]                      ),
      .out2br_ready_i (branch_back_salu_ready                       ),
          
      .in1_i          (issue_out_sALU_sExeData_in1                  ),
      .in2_i          (issue_out_sALU_sExeData_in2                  ),
      .in3_i          (issue_out_sALU_sExeData_in3                  ),
      .ctrl_wid_i     (issue_out_sALU_warps_control_Signals_wid     ),
      .ctrl_reg_idxw_i(issue_out_sALU_warps_control_Signals_reg_idxw),
      .ctrl_wxd_i     (issue_out_sALU_warps_control_Signals_wxd     ),
      .ctrl_alu_fn_i  (issue_out_sALU_warps_control_Signals_alu_fn  ),
      .ctrl_branch_i  (issue_out_sALU_warps_control_Signals_branch  ),
                    
      .in_ready_o     (salu_in_ready                                ),
      .out_valid_o    (salu_out_valid                               ),
      .out2br_valid_o (salu_out2br_valid                            ),
                     
      .wb_wxd_rd_o    (salu_out_wb_wxd_rd                           ),
      .wxd_o          (salu_out_wxd                                 ),
      .reg_idxw_o     (salu_out_reg_idxw                            ),
      .warp_id_o      (salu_out_warp_id                             ),
                     
      .br_wid_o       (salu_out2br_wid                              ),
      .br_jump_o      (salu_out2br_jump                             ),
      .br_new_pc_o    (salu_out2br_new_pc                           )
      );

    csrexe csrfile(
      .clk                             (clk                                                ),
      .rst_n                           (rst_n                                              ),
                                      
      .ctrl_inst_i                     (issue_out_CSR_warps_control_Signals_inst           ),
      .ctrl_csr_i                      (issue_out_CSR_warps_control_Signals_csr            ),
      .ctrl_custom_signal_0_i          (issue_out_CSR_warps_control_Signals_custom_signal_0),
      .ctrl_isvec_i                    (issue_out_CSR_warps_control_Signals_isvec          ),
      .ctrl_reg_idxw_i                 (issue_out_CSR_warps_control_Signals_reg_idxw       ),
      .ctrl_wxd_i                      (issue_out_CSR_warps_control_Signals_wxd            ),
      .ctrl_wid_i                      (issue_out_CSR_warps_control_Signals_wid            ),
                                      
      .in_valid_i                      (issue_out_CSR_valid                                ),
      .out_ready_i                     (writeback_in_x_ready[3]                            ),
                                      
      .in1_i                           (issue_out_CSR_csrExeData_in1                       ),
      .rm_wid_i                        (csrfile_rm_wid                                     ),
      .lsu_wid_i                       (lsu_csr_wid                                        ),
      .simt_wid_i                      (operand_collector_out_wid                          ),
                                      
      .CTA2csr_valid_i                 (warpReq_valid_i                                    ),      
      .dispatch2cu_wg_wf_count_i       (warpReq_dispatch2cu_wg_wf_count_i                  ),
      .dispatch2cu_wf_size_dispatch_i  (warpReq_dispatch2cu_wf_size_dispatch_i             ),
      .dispatch2cu_sgpr_base_dispatch_i(warpReq_dispatch2cu_sgpr_base_dispatch_i           ),
      .dispatch2cu_vgpr_base_dispatch_i(warpReq_dispatch2cu_vgpr_base_dispatch_i           ),
      .dispatch2cu_wf_tag_dispatch_i   (warpReq_dispatch2cu_wf_tag_dispatch_i              ),
      .dispatch2cu_lds_base_dispatch_i (warpReq_dispatch2cu_lds_base_dispatch_i            ),
      //.dispatch2cu_start_pc_dispatch_i (warpReq_dispatch2cu_start_pc_dispatch_i            ),
      .dispatch2cu_pds_base_dispatch_i (warpReq_dispatch2cu_pds_base_dispatch_i            ),
      //.dispatch2cu_gds_base_dispatch_i (warpReq_dispatch2cu_gds_base_dispatch_i            ),
      .dispatch2cu_csr_knl_dispatch_i  (warpReq_dispatch2cu_csr_knl_dispatch_i             ),
      .dispatch2cu_wgid_x_dispatch_i   (warpReq_dispatch2cu_wgid_x_dispatch_i              ),
      .dispatch2cu_wgid_y_dispatch_i   (warpReq_dispatch2cu_wgid_y_dispatch_i              ),
      .dispatch2cu_wgid_z_dispatch_i   (warpReq_dispatch2cu_wgid_z_dispatch_i              ),
      .dispatch2cu_wg_id_i             (warpReq_dispatch2cu_wg_id_i                        ),
      .wid_i                           (warpReq_wid_i                                      ),
                                      
      .in_ready_o                      (csrfile_in_ready                                   ),
      .out_valid_o                     (csrfile_out_valid                                  ),
                                      
      .wb_wxd_rd_o                     (csrfile_wb_wxd_rd                                  ),
      .wxd_o                           (csrfile_wxd                                        ),
      .reg_idxw_o                      (csrfile_reg_idxw                                   ),
      .warp_id_o                       (csrfile_warp_id                                    ),
      .rm_o                            (csrfile_rm                                         ),
      .sgpr_base_o                     (csrfile_sgpr_base                                  ),
      .vgpr_base_o                     (csrfile_vgpr_base                                  ),
      .lsu_tid_o                       (csrfile_lsu_tid                                    ),
      .lsu_pds_o                       (csrfile_lsu_pds                                    ),
      .lsu_numw_o                      (csrfile_lsu_numw                                   ),
      .simt_rpc_o                      (csrfile_simt_rpc                                   )
      );

    simt_stack simt_stack(
      .clk                    (clk                        ),
      .rst_n                  (rst_n                      ),

      .branch_ctl_ready_o     (simt_stack_branch_ctl_ready),
      .branch_ctl_valid_i     (issue_out_SIMT_valid       ),
      .branch_ctl_opcode_i    (issue_out_SIMT_opcode      ),
      .branch_ctl_wid_i       (issue_out_SIMT_wid         ),
      .branch_ctl_pc_branch_i (issue_out_SIMT_PC_branch   ),
      .branch_ctl_pc_execute_i(issue_out_SIMT_PC_execute  ),
      .branch_ctl_mask_init_i (issue_out_SIMT_mask_init   ),

      .if_mask_ready_o        (simt_stack_if_mask_ready   ),
      .if_mask_valid_i        (valu_out2simt_valid        ),
      .if_mask_mask_i         (valu_out2simt_if_mask      ),
      .if_mask_wid_i          (valu_out2simt_wid          ),

      .pc_reconv_valid_i      (issue_out_SIMT_valid       ),
      .pc_reconv_i            (csrfile_simt_rpc           ),

      .input_wid_i            (operand_collector_out_wid  ),
      .out_mask_o             (simt_stack_out_mask        ),

      .complete_valid_o       (simt_stack_complete_valid  ),
      .complete_wid_o         (simt_stack_complete_wid    ),

      .fetch_ctl_ready_i      (branch_back_valu_ready     ),      
      .fetch_ctl_valid_o      (simt_stack_fetch_ctl_valid ),
      .fetch_ctl_wid_o        (simt_stack_fetch_ctl_wid   ),
      .fetch_ctl_jump_o       (simt_stack_fetch_ctl_jump  ),
      .fetch_ctl_new_pc_o     (simt_stack_fetch_ctl_new_pc)    
      );

    sfu_exe sfu(
      .clk              (clk                                         ), 
      .rst_n            (rst_n                                       ), 
                   
      .in_valid_i       (issue_out_SFU_valid                         ), 
      .in_ready_o       (sfu_in_ready                                ), 
      .in_in1_i         (issue_out_SFU_vExeData_in1                  ), 
      .in_in2_i         (issue_out_SFU_vExeData_in2                  ), 
      .in_in3_i         (issue_out_SFU_vExeData_in3                  ), 
      .in_mask_i        (issue_out_SFU_vExeData_mask                 ), 
      .in_wid_i         (issue_out_SFU_warps_control_Signals_wid     ), 
      .in_fp_i          (issue_out_SFU_warps_control_Signals_fp      ), 
      .in_reverse_i     (issue_out_SFU_warps_control_Signals_reverse ), 
      .in_isvec_i       (issue_out_SFU_warps_control_Signals_isvec   ), 
      .in_alu_fn_i      (issue_out_SFU_warps_control_Signals_alu_fn  ), 
      .in_reg_idxw_i    (issue_out_SFU_warps_control_Signals_reg_idxw), 
      .in_wvd_i         (issue_out_SFU_warps_control_Signals_wvd     ), 
      .in_wxd_i         (issue_out_SFU_warps_control_Signals_wxd     ), 

      .in_rm_i          (csrfile_rm[5:3]                             ), 

      .out_x_valid_o    (sfu_out_x_valid                             ), 
      .out_x_ready_i    (writeback_in_x_ready[4]                     ), 
      .out_x_warp_id_o  (sfu_out_x_warp_id                           ), 
      .out_x_wxd_o      (sfu_out_x_wxd                               ), 
      .out_x_reg_idxw_o (sfu_out_x_reg_idxw                          ), 
      .out_x_wb_wxd_rd_o(sfu_out_x_wb_wxd_rd                         ), 

      .out_v_valid_o    (sfu_out_v_valid                             ), 
      .out_v_ready_i    (writeback_in_v_ready[3]                     ), 
      .out_v_warp_id_o  (sfu_out_v_warp_id                           ), 
      .out_v_wvd_o      (sfu_out_v_wvd                               ), 
      .out_v_reg_idxw_o (sfu_out_v_reg_idxw                          ), 
      .out_v_wvd_mask_o (sfu_out_v_wvd_mask                          ), 
      .out_v_wb_wvd_rd_o(sfu_out_v_wb_wvd_rd                         ) 
      );

    vmul_top #(
      .SOFT_THREAD(`NUM_THREAD),
      .HARD_THREAD(`NUMBER_MUL),
      .MAX_ITER   (`NUM_THREAD/`NUMBER_MUL) //SOFT/HARD
      ) mul(
      .clk             (clk                                         ),
      .rst_n           (rst_n                                       ),
                      
      .in_valid_i      (issue_out_MUL_valid                         ),
      .outx_ready_i    (writeback_in_x_ready[5]                     ),
      .outv_ready_i    (writeback_in_v_ready[4]                     ),
                      
      .in1_i           (issue_out_MUL_vExeData_in1                  ),
      .in2_i           (issue_out_MUL_vExeData_in2                  ),
      .in3_i           (issue_out_MUL_vExeData_in3                  ),
      .mask_i          (issue_out_MUL_vExeData_mask                 ),
      .ctrl_alu_fn_i   (issue_out_MUL_warps_control_Signals_alu_fn  ),
      .ctrl_reverse_i  (issue_out_MUL_warps_control_Signals_reverse ),
      .ctrl_wid_i      (issue_out_MUL_warps_control_Signals_wid     ),
      .ctrl_reg_idxw_i (issue_out_MUL_warps_control_Signals_reg_idxw),
      .ctrl_wvd_i      (issue_out_MUL_warps_control_Signals_wvd     ),
      .ctrl_wxd_i      (issue_out_MUL_warps_control_Signals_wxd     ),
                      
      .in_ready_o      (mul_in_ready                                ),
      .outx_valid_o    (mul_out_x_valid                             ),
      .outv_valid_o    (mul_out_v_valid                             ),
                      
      .outx_wb_wxd_rd_o(mul_out_x_wb_wxd_rd                         ),
      .outx_wxd_o      (mul_out_x_wxd                               ),
      .outx_reg_idwx_o (mul_out_x_reg_idwx                          ),
      .outx_warp_id_o  (mul_out_x_warp_id                           ),
                      
      .outv_wb_wxd_rd_o(mul_out_v_wb_wxd_rd                         ),
      .outv_wvd_mask_o (mul_out_v_wvd_mask                          ),
      .outv_wvd_o      (mul_out_v_wvd                               ),
      .outv_reg_idxw_o (mul_out_v_reg_idxw                          ),
      .outv_warp_id_o  (mul_out_v_warp_id                           )
      );

    tensor_core_exe #(
      .VL       (`NUM_THREAD),
      .DIM_M    (2          ),  // M*N/N*K/M*K < NUM_THREAD
      .DIM_N    (2          ),  
      .DIM_K    (2          ),
      .EXPWIDTH (8          ),  //single precision
      .PRECISION(24         )
      ) tensorcore(
      .clk            (clk                                        ),  
      .rst_n          (rst_n                                      ),        
       
      .in1_i          (issue_out_TC_vExeData_in1                  ),  
      .in2_i          (issue_out_TC_vExeData_in2                  ),  
      .in3_i          (issue_out_TC_vExeData_in3                  ),  
      //.mask_i         (issue_out_TC_vExeData_mask                 ),  
      .ctrl_reg_idxw_i(issue_out_TC_warps_control_Signals_reg_idxw),  
      .ctrl_wid_i     (issue_out_TC_warps_control_Signals_wid     ),  

      .rm_i           (csrfile_rm[8:6]                            ),  
      
      .in_valid_i     (issue_out_TC_valid                         ),  
      .out_ready_i    (writeback_in_v_ready[5]                    ),  
    
      .in_ready_o     (tensorcore_in_ready                        ),  
      .out_valid_o    (tensorcore_out_v_valid                     ),  
    
      .wb_wvd_rd_o    (tensorcore_out_v_wb_wvd_rd                 ),  
      .wvd_mask_o     (tensorcore_out_v_wvd_mask                  ),  
      .wvd_o          (tensorcore_out_v_wvd                       ),  
      .reg_idxw_o     (tensorcore_out_v_reg_idxw                  ),  
      .warp_id_o      (tensorcore_out_v_warp_id                   )  
      );

    fpuexe #(
      //.EXPWIDTH   (8          ),
      //.PRECISION  (24         ),
      //.LEN        (32         ),
      .SOFT_THREAD(`NUM_THREAD),
      .HARD_THREAD(`NUMBER_FPU)
      //.MAX_ITER   (1          )
      ) fpu(
      .clk              (clk                                             ),
      .rst_n            (rst_n                                           ),

      .in1_i            (issue_out_vFPU_vExeData_in1                     ),
      .in2_i            (issue_out_vFPU_vExeData_in2                     ),
      .in3_i            (issue_out_vFPU_vExeData_in3                     ),
      .mask_i           (issue_out_vFPU_vExeData_mask                    ),
      .rm_i             (fpu_rm                                          ),
      .ctrl_alu_fn_i    (issue_out_vFPU_warps_control_Signals_alu_fn     ),
      //.ctrl_force_rm_rtz(issue_out_vFPU_warps_control_Signals_force_rm_rt),
      .ctrl_reg_idxw_i  (issue_out_vFPU_warps_control_Signals_reg_idxw   ),
      .ctrl_reverse_i   (issue_out_vFPU_warps_control_Signals_reverse    ),
      .ctrl_wid_i       (issue_out_vFPU_warps_control_Signals_wid        ),
      .ctrl_wvd_i       (issue_out_vFPU_warps_control_Signals_wvd        ),
      .ctrl_wxd_i       (issue_out_vFPU_warps_control_Signals_wxd        ),

      .in_valid_i       (issue_out_vFPU_valid                            ),
      .out_x_ready_i    (writeback_in_x_ready[1]                         ),
      .out_v_ready_i    (writeback_in_v_ready[1]                         ),

      .in_ready_o       (fpu_in_ready                                    ),
      .out_x_valid_o    (fpu_out_x_valid                                 ),
      .out_v_valid_o    (fpu_out_v_valid                                 ),

      .out_x_wb_wxd_rd_o(fpu_out_x_wb_wxd_rd                             ),
      .out_x_wxd_o      (fpu_out_x_wxd                                   ),
      .out_x_reg_idxw_o (fpu_out_x_reg_idxw                              ),
      .out_x_warp_id_o  (fpu_out_x_warp_id                               ),

      .out_v_wb_wvd_rd_o(fpu_out_v_wb_wvd_rd                             ),
      .out_v_wvd_mask_o (fpu_out_v_wvd_mask                              ),
      .out_v_wvd_o      (fpu_out_v_wvd                                   ),
      .out_v_reg_idxw_o (fpu_out_v_reg_idxw                              ),
      .out_v_warp_id_o  (fpu_out_v_warp_id                               ) 
      );

    branch_back branch_back(
      .v_ready_o   (branch_back_valu_ready     ),
      .v_valid_i   (simt_stack_fetch_ctl_valid ),
      .v_wid_i     (simt_stack_fetch_ctl_wid   ),
      .v_jump_i    (simt_stack_fetch_ctl_jump  ),
      .v_new_pc_i  (simt_stack_fetch_ctl_new_pc),

      .s_ready_o   (branch_back_salu_ready     ),
      .s_valid_i   (salu_out2br_valid          ),
      .s_wid_i     (salu_out2br_wid            ),
      .s_jump_i    (salu_out2br_jump           ),
      .s_new_pc_i  (salu_out2br_new_pc         ),

      .out_ready_i (warp_sche_branch_out_ready ),
      .out_valid_o (branch_back_out_valid      ),
      .out_wid_o   (branch_back_out_wid        ),
      .out_jump_o  (branch_back_out_jump       ),
      .out_new_pc_o(branch_back_out_new_pc     )     
      );

  writeback #(
    .NUM_X(6),
    .NUM_V(6)
    ) wb(
    .in_x_valid_i     (writeback_in_x_valid               ),
    .in_x_ready_o     (writeback_in_x_ready               ),
    .in_x_warp_id_i   (writeback_in_x_warp_id             ),
    .in_x_wxd_i       (writeback_in_x_wxd                 ),
    .in_x_reg_idxw_i  (writeback_in_x_reg_idxw            ),
    .in_x_wb_wxd_rd_i (writeback_in_x_wb_wxd_rd           ),
                     
    .in_v_valid_i     (writeback_in_v_valid               ),
    .in_v_ready_o     (writeback_in_v_ready               ),
    .in_v_warp_id_i   (writeback_in_v_warp_id             ),
    .in_v_wvd_i       (writeback_in_v_wvd                 ),
    .in_v_reg_idxw_i  (writeback_in_v_reg_idxw            ),
    .in_v_wvd_mask_i  (writeback_in_v_wvd_mask            ),
    .in_v_wb_wvd_rd_i (writeback_in_v_wb_wvd_rd           ),
                     
    .out_x_valid_o    (wb_out_x_valid                     ),
    .out_x_ready_i    (operand_collector_writeScalar_ready),
    .out_x_warp_id_o  (wb_out_x_warp_id                   ),
    .out_x_wxd_o      (wb_out_x_wxd                       ),
    .out_x_reg_idxw_o (wb_out_x_reg_idxw                  ),
    .out_x_wb_wxd_rd_o(wb_out_x_wb_wxd_rd                 ),
                     
    .out_v_valid_o    (wb_out_v_valid                     ),
    .out_v_ready_i    (operand_collector_writeVector_ready),
    .out_v_warp_id_o  (wb_out_v_warp_id                   ),
    .out_v_wvd_o      (wb_out_v_wvd                       ),
    .out_v_reg_idxw_o (wb_out_v_reg_idxw                  ),
    .out_v_wvd_mask_o (wb_out_v_wvd_mask                  ),
    .out_v_wb_wvd_rd_o(wb_out_v_wb_wvd_rd                 )
    );

  assign lsu_mshr_is_empty_o = &lsu_fence_end;

endmodule
