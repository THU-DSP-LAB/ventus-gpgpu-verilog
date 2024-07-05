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
// Description:One of the number of num_warp collector_unit, instantiating this module in operand_collector for num_warps
`include "define.v"

`timescale 1ns/1ps

module collector_unit(
  input                                   clk                                             ,
  input                                   rst_n                                           ,

  // input interface
  input                                   control_valid_i                                 ,
  output                                  control_ready_o                                 ,
  input [`DEPTH_WARP-1:0]                 control_wid_i                                   ,
  input [32-1:0]                          control_inst_i                                  ,
  input [6-1:0]                           control_imm_ext_i                               ,
  input [4-1:0]                           control_sel_imm_i                               ,
  input [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] control_reg_idx1_i                              ,
  input [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] control_reg_idx2_i                              ,
  input [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] control_reg_idx3_i                              ,
  input [2-1:0]                           control_branch_i                                ,
  input                                   control_custom_signal_0_i                       ,
  input                                   control_isvec_i                                 ,
  input                                   control_readmask_i                              ,
  input [2-1:0]                           control_sel_alu1_i                              ,
  input [2-1:0]                           control_sel_alu2_i                              ,
  input [2-1:0]                           control_sel_alu3_i                              ,
  input [32-1:0]                          control_pc_i                                    ,
  input                                   control_mask_i                                  ,
  input                                   control_fp_i                                    ,
  input                                   control_simt_stack_i                            ,
  input                                   control_simt_stack_op_i                         ,
  input                                   control_barrier_i                               ,
  input [2-1:0]                           control_csr_i                                   ,
  input                                   control_reverse_i                               ,
  input [2-1:0]                           control_mem_whb_i                               ,
  input                                   control_mem_unsigned_i                          ,
  input [6-1:0]                           control_alu_fn_i                                ,
  input                                   control_force_rm_rtz_i                          ,
  input                                   control_is_vls12_i                              ,
  input                                   control_mem_i                                   ,
  input                                   control_mul_i                                   ,
  input                                   control_tc_i                                    ,
  input                                   control_disable_mask_i                          ,
  input [2-1:0]                           control_mem_cmd_i                               ,
  input [2-1:0]                           control_mop_i                                   ,
  input [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] control_reg_idxw_i                              ,
  input                                   control_wvd_i                                   ,
  input                                   control_fence_i                                 ,
  input                                   control_sfu_i                                   ,
  //input                                   control_writemask_i                             ,
  input                                   control_wxd_i                                   ,
  input                                   control_atomic_i                                ,
  input                                   control_aq_i                                    ,
  input                                   control_rl_i                                    ,
  input [2:0]                                                                   control_rm_i                                                                                      ,
  input                                                                                   control_rm_is_static_i                                                  ,

  input [4-1:0]                           bankIn_valid_i                                  ,
  //output[4-1:0]                           bankIn_ready_o                                  ,
  input [2*4-1:0]                         bankIn_regOrder_i                               ,
  input [`XLEN*`NUM_THREAD*4-1:0]         bankIn_data_i                                   , // bankIn_data_i[XLEN*Thread(3),XLEN*Thread(2),XLEN*Thread(1),XLEN*Thread(0)]
  input [`XLEN*`NUM_THREAD*4-1:0]         bankIn_v0_i                                     ,

  input [(`SGPR_ID_WIDTH+1)*`NUM_WARP-1:0]sgpr_base_i                                     ,
  input [(`VGPR_ID_WIDTH+1)*`NUM_WARP-1:0]vgpr_base_i                                     ,

  // output interface
  output                                  issue_valid_o                                   ,
  input                                   issue_ready_i                                   ,
  output [`DEPTH_WARP-1:0]                issue_wid_o                                     ,
  output [32-1:0]                         issue_inst_o                                    ,
  //output [6-1:0]                          issue_imm_ext_o                                 ,
  //output [4-1:0]                          issue_sel_imm_o                                 ,
  //output [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0]issue_reg_idx1_o                                ,
  //output [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0]issue_reg_idx2_o                                ,
  //output [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0]issue_reg_idx3_o                                ,
  output [2-1:0]                          issue_branch_o                                  ,
  output                                  issue_custom_signal_0_o                         ,
  output                                  issue_isvec_o                                   ,
  //output                                  issue_readmask_o                                ,
  //output [2-1:0]                          issue_sel_alu1_o                                ,
  //output [2-1:0]                          issue_sel_alu2_o                                ,
  //output [2-1:0]                          issue_sel_alu3_o                                ,
  output [32-1:0]                         issue_pc_o                                      ,
  //output                                  issue_mask_o                                    ,
  output                                  issue_fp_o                                      ,
  output                                  issue_simt_stack_o                              ,
  output                                  issue_simt_stack_op_o                           ,
  output                                  issue_barrier_o                                 ,
  output [2-1:0]                          issue_csr_o                                     ,
  output                                  issue_reverse_o                                 ,
  output [2-1:0]                          issue_mem_whb_o                                 ,
  output                                  issue_mem_unsigned_o                            ,
  output [6-1:0]                          issue_alu_fn_o                                  ,
  output                                  issue_force_rm_rtz_o                            ,
  output                                  issue_is_vls12_o                                ,
  output                                  issue_mem_o                                     ,
  output                                  issue_mul_o                                     ,
  output                                  issue_tc_o                                      ,
  output                                  issue_disable_mask_o                            ,
  output [2-1:0]                          issue_mem_cmd_o                                 ,
  output [2-1:0]                          issue_mop_o                                     ,
  output [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0]issue_reg_idxw_o                                ,
  output                                  issue_wvd_o                                     ,
  output                                  issue_fence_o                                   ,
  output                                  issue_sfu_o                                     ,
  //output                                  issue_writemask_o                               ,
  output                                  issue_wxd_o                                     ,
  output                                  issue_atomic_o                                  ,
  output                                  issue_aq_o                                      ,
  output                                  issue_rl_o                                      ,
  output [2:0]                                                          issue_rm_o                                                                                          ,
  output                                                                                  issue_rm_is_static_o                                                                ,

  output [`XLEN*`NUM_THREAD-1:0]          issue_alu_src1_o                                ,
  output [`XLEN*`NUM_THREAD-1:0]          issue_alu_src2_o                                ,
  output [`XLEN*`NUM_THREAD-1:0]          issue_alu_src3_o                                ,
  output [`NUM_THREAD-1:0]                issue_active_mask_o                             ,

  output reg [4-1:0]                      outArbiter_valid_o                              ,
  //input      [4-1:0]                      outArbiter_ready_i                              ,
  output     [`DEPTH_BANK*4-1:0]          outArbiter_bankID_o                             ,
  output     [2*4-1:0]                    outArbiter_rsType_o                             ,
  output reg [`DEPTH_REGBANK*4-1:0]       outArbiter_rsAddr_o                             

);

  // handshake signals
  wire       control_fire     ;
  wire [3:0] bankIn_fire      ;
  wire       issue_fire       ;
  //wire [3:0] outArbiter_fire  ; // no use

  // for CtrlSigs bits
  reg [`DEPTH_WARP-1:0]                 controlReg_wid                                    ;
  reg [32-1:0]                          controlReg_inst                                   ;
  reg [6-1:0]                           controlReg_imm_ext                                ;
  reg [4-1:0]                           controlReg_sel_imm                                ;
  //reg [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] controlReg_reg_idx1                               ;
  //reg [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] controlReg_reg_idx2                               ;
  //reg [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] controlReg_reg_idx3                               ;
  reg [2-1:0]                           controlReg_branch                                 ;
  reg                                   controlReg_custom_signal_0                        ;
  reg                                   controlReg_isvec                                  ;
  //reg                                   controlReg_readmask                               ;
  //reg [2-1:0]                           controlReg_sel_alu1                               ;
  //reg [2-1:0]                           controlReg_sel_alu2                               ;
  reg [2-1:0]                           controlReg_sel_alu3                               ;
  reg [32-1:0]                          controlReg_pc                                     ;
  //reg                                   controlReg_mask                                   ;
  reg                                   controlReg_fp                                     ;
  reg                                   controlReg_simt_stack                             ;
  reg                                   controlReg_simt_stack_op                          ;
  reg                                   controlReg_barrier                                ;
  reg [2-1:0]                           controlReg_csr                                    ;
  reg                                   controlReg_reverse                                ;
  reg [2-1:0]                           controlReg_mem_whb                                ;
  reg                                   controlReg_mem_unsigned                           ;
  reg [6-1:0]                           controlReg_alu_fn                                 ;
  reg                                   controlReg_force_rm_rtz                           ;
  reg                                   controlReg_is_vls12                               ;
  reg                                   controlReg_mem                                    ;
  reg                                   controlReg_mul                                    ;
  reg                                   controlReg_tc                                     ;
  reg                                   controlReg_disable_mask                           ;
  reg [2-1:0]                           controlReg_mem_cmd                                ;
  reg [2-1:0]                           controlReg_mop                                    ;
  reg [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] controlReg_reg_idxw                               ;
  reg                                   controlReg_wvd                                    ;
  reg                                   controlReg_fence                                  ;
  reg                                   controlReg_sfu                                    ;
  //reg                                   controlReg_writemask                              ;
  reg                                   controlReg_wxd                                    ;
  reg                                   controlReg_atomic                                 ;
  reg                                   controlReg_aq                                     ;
  reg                                   controlReg_rl                                     ;
  reg [2:0]                                                                           controlReg_rm                                                                                         ;
  reg                                                                                     controlReg_rm_is_static                                                                     ;

  // set reg signal
  reg [2*4-1:0]                                 rsType_reg      ; // rsType == 0: PC or mask(for op4); 1: scalar; 2: Vec; 3: Imm;
  reg [4-1:0]                                   ready_reg       ;
  reg [4-1:0]                                   valid_reg       ;
  reg [(`REGIDX_WIDTH+`REGEXT_WIDTH)*4-1:0]     regIdx_reg      ;
  reg [`XLEN*`NUM_THREAD*3-1:0]                 rs_reg          ;
  reg [`NUM_THREAD-1:0]                         mask_reg        ;
  reg                                           customCtrl_reg  ;
  // set wire signal
  reg [2*4-1:0]                                 rsType_wire     ;
  reg [4-1:0]                                   ready_wire      ;
  //reg [4-1:0]                                   valid_wire      ; // unused
  reg [(`REGIDX_WIDTH+`REGEXT_WIDTH)*4-1:0]     regIdx_wire     ;
  reg [`XLEN*`NUM_THREAD-1:0]                   rsRead_wire     ; // only use for rs_reg(0)
  reg                                           customCtrl_wire ;

  // for gen_imm module signals
  reg   [31:0]  imm_inst  ;
  reg   [3:0]   imm_sel   ;
  reg   [6:0]   imm_ext   ;
  wire  [31:0]  imm_out   ;

  wire  [4-1:0]      bankIn_ready_o;
  parameter S_IDLE = 2'b00;
  parameter S_ADD  = 2'b01;
  parameter S_OUT  = 2'b10;
  reg [1:0] current_state,next_state;

  // fire = valid & ready
  assign        control_fire     = control_valid_i & control_ready_o      ;
  //assign        bankIn_fire      = bankIn_valid_i                         ;
  assign        bankIn_fire      = bankIn_valid_i & bankIn_ready_o        ;
  assign        issue_fire       = issue_valid_o & issue_ready_i          ;
  //assign        outArbiter_fire  = outArbiter_valid_o & outArbiter_ready_i;
  
  assign bankIn_ready_o = {3'd4{(current_state==S_ADD)}};
  
  assign issue_wid_o             = controlReg_wid                                ;
  assign issue_inst_o            = controlReg_inst                               ;
  //assign issue_imm_ext_o         = controlReg_imm_ext                            ;
  //assign issue_sel_imm_o         = controlReg_sel_imm                            ;
  //assign issue_reg_idx1_o        = controlReg_reg_idx1                           ;
  //assign issue_reg_idx2_o        = controlReg_reg_idx2                           ;
  //assign issue_reg_idx3_o        = controlReg_reg_idx3                           ;
  assign issue_branch_o          = controlReg_branch                             ;
  assign issue_custom_signal_0_o = controlReg_custom_signal_0                    ;
  assign issue_isvec_o           = controlReg_isvec                              ;
  //assign issue_readmask_o        = controlReg_readmask                           ;
  //assign issue_sel_alu1_o        = controlReg_sel_alu1                           ;
  //assign issue_sel_alu2_o        = controlReg_sel_alu2                           ;
  //assign issue_sel_alu3_o        = controlReg_sel_alu3                           ;
  assign issue_pc_o              = controlReg_pc                                 ;
  //assign issue_mask_o            = controlReg_mask                               ;
  assign issue_fp_o              = controlReg_fp                                 ;
  assign issue_simt_stack_o      = controlReg_simt_stack                         ;
  assign issue_simt_stack_op_o   = controlReg_simt_stack_op                      ;
  assign issue_barrier_o         = controlReg_barrier                            ;
  assign issue_csr_o             = controlReg_csr                                ;
  assign issue_reverse_o         = controlReg_reverse                            ;
  assign issue_mem_whb_o         = controlReg_mem_whb                            ;
  assign issue_mem_unsigned_o    = controlReg_mem_unsigned                       ;
  assign issue_alu_fn_o          = controlReg_alu_fn                             ;
  assign issue_force_rm_rtz_o    = controlReg_force_rm_rtz                       ;
  assign issue_is_vls12_o        = controlReg_is_vls12                           ;
  assign issue_mem_o             = controlReg_mem                                ;
  assign issue_mul_o             = controlReg_mul                                ;
  assign issue_tc_o              = controlReg_tc                                 ;
  assign issue_disable_mask_o    = controlReg_disable_mask                       ;
  assign issue_mem_cmd_o         = controlReg_mem_cmd                            ;
  assign issue_mop_o             = controlReg_mop                                ;
  assign issue_reg_idxw_o        = controlReg_reg_idxw                           ;
  assign issue_wvd_o             = controlReg_wvd                                ;
  assign issue_fence_o           = controlReg_fence                              ;
  assign issue_sfu_o             = controlReg_sfu                                ;
  //assign issue_writemask_o       = controlReg_writemask                          ;
  assign issue_wxd_o             = controlReg_wxd                                ;
  assign issue_atomic_o          = controlReg_atomic                             ;
  assign issue_aq_o              = controlReg_aq                                 ;
  assign issue_rl_o              = controlReg_rl                                 ;
  assign issue_rm_o                                    = controlReg_rm                                                                           ;
  assign issue_rm_is_static_o      = controlReg_rm_is_static                                                       ;

  // FSM
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
      current_state <= S_IDLE;
    end else begin
      current_state <= next_state;
    end
  end

  always @(*) begin
    case(current_state)
      S_IDLE: next_state = control_fire ? (!(&ready_wire) ? S_ADD : S_OUT) : S_IDLE;
      S_ADD:  next_state = valid_reg!=ready_reg ? S_ADD : S_OUT;
      S_OUT:  next_state = issue_fire ? S_IDLE : S_OUT;
      default:next_state = S_IDLE;
    endcase
  end

  // for gen_imm module
  always @(*) begin
    case(current_state)
      S_IDLE: begin
        imm_inst  = control_inst_i;
        imm_ext   = control_imm_ext_i;
        imm_sel   = control_sel_imm_i;
      end
      S_ADD:  begin        
        imm_inst  = controlReg_inst;   
        imm_ext   = controlReg_imm_ext;
        imm_sel   = controlReg_sel_imm;
      end
      default:begin
        imm_inst  = 32'b0;   
        imm_ext   = 7'b0;
        imm_sel   = 4'b0;        
      end
    endcase
  end

  // status ouput controlReg
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin      
      controlReg_wid             <=  'b0 ;
      controlReg_inst            <=  'b0 ;
      controlReg_imm_ext         <=  'b0 ;
      controlReg_sel_imm         <=  'b0 ;
      //controlReg_reg_idx1        <=  'b0 ;
      //controlReg_reg_idx2        <=  'b0 ;
      //controlReg_reg_idx3        <=  'b0 ;
      controlReg_branch          <=  'b0 ;
      controlReg_custom_signal_0 <=  'b0 ;
      controlReg_isvec           <=  'b0 ;
      //controlReg_readmask        <=  'b0 ;
      //controlReg_sel_alu1        <=  'b0 ;
      //controlReg_sel_alu2        <=  'b0 ;
      controlReg_sel_alu3        <=  'b0 ;
      controlReg_pc              <=  'b0 ;
      //controlReg_mask            <=  'b0 ;
      controlReg_fp              <=  'b0 ;
      controlReg_simt_stack      <=  'b0 ;
      controlReg_simt_stack_op   <=  'b0 ;
      controlReg_barrier         <=  'b0 ;
      controlReg_csr             <=  'b0 ;
      controlReg_reverse         <=  'b0 ;
      controlReg_mem_whb         <=  'b0 ;
      controlReg_mem_unsigned    <=  'b0 ;
      controlReg_alu_fn          <=  'b0 ;
      controlReg_force_rm_rtz    <=  'b0 ;
      controlReg_is_vls12        <=  'b0 ;
      controlReg_mem             <=  'b0 ;
      controlReg_mul             <=  'b0 ;
      controlReg_tc              <=  'b0 ;
      controlReg_disable_mask    <=  'b0 ;
      controlReg_mem_cmd         <=  'b0 ;
      controlReg_mop             <=  'b0 ;
      controlReg_reg_idxw        <=  'b0 ;
      controlReg_wvd             <=  'b0 ;
      controlReg_fence           <=  'b0 ;
      controlReg_sfu             <=  'b0 ;
      //controlReg_writemask       <=  'b0 ;
      controlReg_wxd             <=  'b0 ;
      controlReg_atomic          <=  'b0 ;
      controlReg_aq              <=  'b0 ;
      controlReg_rl              <=  'b0 ;
            controlReg_rm                                      <=  'b0 ;
            controlReg_rm_is_static    <=  'b0 ;
    end else if(current_state==S_IDLE && control_fire) begin
      controlReg_wid             <=  control_wid_i             ;
      controlReg_inst            <=  control_inst_i            ;
      controlReg_imm_ext         <=  control_imm_ext_i         ;
      controlReg_sel_imm         <=  control_sel_imm_i         ;
      //controlReg_reg_idx1        <=  control_reg_idx1_i        ;
      //controlReg_reg_idx2        <=  control_reg_idx2_i        ;
      //controlReg_reg_idx3        <=  control_reg_idx3_i        ;
      controlReg_branch          <=  control_branch_i          ;
      controlReg_custom_signal_0 <=  control_custom_signal_0_i ;
      controlReg_isvec           <=  control_isvec_i           ;
      //controlReg_readmask        <=  control_readmask_i        ;
      //controlReg_sel_alu1        <=  control_sel_alu1_i        ;
      //controlReg_sel_alu2        <=  control_sel_alu2_i        ;
      controlReg_sel_alu3        <=  control_sel_alu3_i        ;
      controlReg_pc              <=  control_pc_i              ;
      //controlReg_mask            <=  control_mask_i            ;
      controlReg_fp              <=  control_fp_i              ;
      controlReg_simt_stack      <=  control_simt_stack_i      ;
      controlReg_simt_stack_op   <=  control_simt_stack_op_i   ;
      controlReg_barrier         <=  control_barrier_i         ;
      controlReg_csr             <=  control_csr_i             ;
      controlReg_reverse         <=  control_reverse_i         ;
      controlReg_mem_whb         <=  control_mem_whb_i         ;
      controlReg_mem_unsigned    <=  control_mem_unsigned_i    ;
      controlReg_alu_fn          <=  control_alu_fn_i          ;
      controlReg_force_rm_rtz    <=  control_force_rm_rtz_i    ;
      controlReg_is_vls12        <=  control_is_vls12_i        ;
      controlReg_mem             <=  control_mem_i             ;
      controlReg_mul             <=  control_mul_i             ;
      controlReg_tc              <=  control_tc_i              ;
      controlReg_disable_mask    <=  control_disable_mask_i    ;
      controlReg_mem_cmd         <=  control_mem_cmd_i         ;
      controlReg_mop             <=  control_mop_i             ;
      controlReg_reg_idxw        <=  control_reg_idxw_i        ;
      controlReg_wvd             <=  control_wvd_i             ;
      controlReg_fence           <=  control_fence_i           ;
      controlReg_sfu             <=  control_sfu_i             ;
      //controlReg_writemask       <=  control_writemask_i       ;
      controlReg_wxd             <=  control_wxd_i             ;
      controlReg_atomic          <=  control_atomic_i          ;
      controlReg_aq              <=  control_aq_i              ;
      controlReg_rl              <=  control_rl_i              ;
            controlReg_rm                                      <=  control_rm_i                          ;
            controlReg_rm_is_static    <=  control_rm_is_static_i          ;
    end else begin
      controlReg_wid             <=  controlReg_wid              ; 
      controlReg_inst            <=  controlReg_inst             ; 
      controlReg_imm_ext         <=  controlReg_imm_ext          ; 
      controlReg_sel_imm         <=  controlReg_sel_imm          ; 
      //controlReg_reg_idx1        <=  controlReg_reg_idx1         ; 
      //controlReg_reg_idx2        <=  controlReg_reg_idx2         ; 
      //controlReg_reg_idx3        <=  controlReg_reg_idx3         ;
      controlReg_branch          <=  controlReg_branch           ; 
      controlReg_custom_signal_0 <=  controlReg_custom_signal_0  ; 
      controlReg_isvec           <=  controlReg_isvec            ; 
      //controlReg_readmask        <=  controlReg_readmask         ; 
      //controlReg_sel_alu1        <=  controlReg_sel_alu1         ; 
      //controlReg_sel_alu2        <=  controlReg_sel_alu2         ; 
      controlReg_sel_alu3        <=  controlReg_sel_alu3         ; 
      controlReg_pc              <=  controlReg_pc               ; 
      //controlReg_mask            <=  controlReg_mask             ;
      controlReg_fp              <=  controlReg_fp               ;
      controlReg_simt_stack      <=  controlReg_simt_stack       ;
      controlReg_simt_stack_op   <=  controlReg_simt_stack_op    ;
      controlReg_barrier         <=  controlReg_barrier          ;
      controlReg_csr             <=  controlReg_csr              ;
      controlReg_reverse         <=  controlReg_reverse          ;
      controlReg_mem_whb         <=  controlReg_mem_whb          ;
      controlReg_mem_unsigned    <=  controlReg_mem_unsigned     ;
      controlReg_alu_fn          <=  controlReg_alu_fn           ;
      controlReg_force_rm_rtz    <=  controlReg_force_rm_rtz     ;
      controlReg_is_vls12        <=  controlReg_is_vls12         ;
      controlReg_mem             <=  controlReg_mem              ;
      controlReg_mul             <=  controlReg_mul              ;
      controlReg_tc              <=  controlReg_tc               ;
      controlReg_disable_mask    <=  controlReg_disable_mask     ;
      controlReg_mem_cmd         <=  controlReg_mem_cmd          ;
      controlReg_mop             <=  controlReg_mop              ;
      controlReg_reg_idxw        <=  controlReg_reg_idxw         ;
      controlReg_wvd             <=  controlReg_wvd              ;
      controlReg_fence           <=  controlReg_fence            ;
      controlReg_sfu             <=  controlReg_sfu              ;
      //controlReg_writemask       <=  controlReg_writemask        ;
      controlReg_wxd             <=  controlReg_wxd              ;
      controlReg_atomic          <=  controlReg_atomic           ;
      controlReg_aq              <=  controlReg_aq               ;
      controlReg_rl              <=  controlReg_rl               ;
            controlReg_rm                                      <=  controlReg_rm                                       ;
            controlReg_rm_is_static        <=  controlReg_rm_is_static     ;
    end
  end

  // operand1
  always @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        rs_reg[`XLEN*`NUM_THREAD*(0+1)-1-:`XLEN*`NUM_THREAD]  <=  'b0;
        ready_reg[0]                                          <= 1'b0;
      end else if(bankIn_fire[0] && bankIn_regOrder_i[2*(0+1)-1-:2]==2'b00) begin
        if(control_fire ? customCtrl_wire : customCtrl_reg) begin
          rs_reg[`XLEN*`NUM_THREAD*(0+1)-1-:`XLEN*`NUM_THREAD] <= {`NUM_THREAD{rsRead_wire[`XLEN*(0+1)-1-:`XLEN]+imm_out}};
        end else begin 
          rs_reg[`XLEN*`NUM_THREAD*(0+1)-1-:`XLEN*`NUM_THREAD] <= rsRead_wire;
        end
        ready_reg[0] <= 1'b1;
      end else if(bankIn_fire[1] && bankIn_regOrder_i[2*(1+1)-1-:2]==2'b00) begin
        if(control_fire ? customCtrl_wire : customCtrl_reg) begin
          rs_reg[`XLEN*`NUM_THREAD*(0+1)-1-:`XLEN*`NUM_THREAD] <= {`NUM_THREAD{rsRead_wire[`XLEN*(0+1)-1-:`XLEN]+imm_out}};
        end else begin 
          rs_reg[`XLEN*`NUM_THREAD*(0+1)-1-:`XLEN*`NUM_THREAD] <= rsRead_wire;
        end
        ready_reg[0] <= 1'b1;
      end else if(bankIn_fire[2] && bankIn_regOrder_i[2*(2+1)-1-:2]==2'b00) begin
        if(control_fire ? customCtrl_wire : customCtrl_reg) begin
          rs_reg[`XLEN*`NUM_THREAD*(0+1)-1-:`XLEN*`NUM_THREAD] <= {`NUM_THREAD{rsRead_wire[`XLEN*(0+1)-1-:`XLEN]+imm_out}};
        end else begin 
          rs_reg[`XLEN*`NUM_THREAD*(0+1)-1-:`XLEN*`NUM_THREAD] <= rsRead_wire[`XLEN*`NUM_THREAD*(0+1)-1-:`XLEN*`NUM_THREAD];
        end
        ready_reg[0] <= 1'b1;
      end else if(bankIn_fire[3] && bankIn_regOrder_i[2*(3+1)-1-:2]==2'b00) begin
        if(control_fire ? customCtrl_wire : customCtrl_reg) begin
          rs_reg[`XLEN*`NUM_THREAD*(0+1)-1-:`XLEN*`NUM_THREAD] <= {`NUM_THREAD{rsRead_wire[`XLEN*(0+1)-1-:`XLEN]+imm_out}};
        end else begin 
          rs_reg[`XLEN*`NUM_THREAD*(0+1)-1-:`XLEN*`NUM_THREAD] <= rsRead_wire[`XLEN*`NUM_THREAD*(0+1)-1-:`XLEN*`NUM_THREAD];
        end
        ready_reg[0] <= 1'b1;
      end else if(current_state==S_IDLE && control_fire) begin
        if(control_sel_alu1_i==`A1_IMM) begin
          rs_reg[`XLEN*`NUM_THREAD*(0+1)-1-:`XLEN*`NUM_THREAD] <= {`NUM_THREAD{imm_out}};
          ready_reg[0]  <= 1'b1;
        end else if(control_sel_alu1_i==`A1_PC) begin
          rs_reg[`XLEN*`NUM_THREAD*(0+1)-1-:`XLEN*`NUM_THREAD] <= {`NUM_THREAD{control_pc_i}};
          ready_reg[0]  <= 1'b1;
        end else begin
          rs_reg[`XLEN*`NUM_THREAD*(0+1)-1-:`XLEN*`NUM_THREAD] <= rs_reg[`XLEN*`NUM_THREAD*(0+1)-1-:`XLEN*`NUM_THREAD];
          ready_reg[0]  <= 1'b0;
        end
      end else if(current_state==S_OUT) begin
        rs_reg[`XLEN*`NUM_THREAD*(0+1)-1-:`XLEN*`NUM_THREAD] <= rs_reg[`XLEN*`NUM_THREAD*(0+1)-1-:`XLEN*`NUM_THREAD];
        ready_reg[0] <= 1'b0;
      end else begin
        rs_reg[`XLEN*`NUM_THREAD*(0+1)-1-:`XLEN*`NUM_THREAD] <= rs_reg[`XLEN*`NUM_THREAD*(0+1)-1-:`XLEN*`NUM_THREAD];
        ready_reg[0] <= ready_reg[0];
      end
  end

  // operand2
  always @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        rs_reg[`XLEN*`NUM_THREAD*(1+1)-1-:`XLEN*`NUM_THREAD]  <=  'b0;
        ready_reg[1]                                          <= 1'b0;
      end else if(bankIn_fire[0] && bankIn_regOrder_i[2*(0+1)-1-:2]==2'b01) begin
        case(control_fire ? rsType_wire[3:2] : rsType_reg[3:2])
          `A2_RS2:   rs_reg[`XLEN*`NUM_THREAD*(1+1)-1-:`XLEN*`NUM_THREAD] <= {`NUM_THREAD{bankIn_data_i[`XLEN*`NUM_THREAD*0+`XLEN-1-:`XLEN]}};
          `A2_VRS2:  rs_reg[`XLEN*`NUM_THREAD*(1+1)-1-:`XLEN*`NUM_THREAD] <= {bankIn_data_i[`XLEN*`NUM_THREAD*(0+1)-1-:`XLEN*`NUM_THREAD]};
          default:   rs_reg[`XLEN*`NUM_THREAD*(1+1)-1-:`XLEN*`NUM_THREAD] <= {`XLEN*`NUM_THREAD{1'b0}};
        endcase
        ready_reg[1] <= 1'b1;
      end else if(bankIn_fire[1] && bankIn_regOrder_i[2*(1+1)-1-:2]==2'b01) begin
        case(control_fire ? rsType_wire[3:2] : rsType_reg[3:2])
          `A2_RS2:   rs_reg[`XLEN*`NUM_THREAD*(1+1)-1-:`XLEN*`NUM_THREAD] <= {`NUM_THREAD{bankIn_data_i[`XLEN*`NUM_THREAD*1+`XLEN-1-:`XLEN]}};
          `A2_VRS2:  rs_reg[`XLEN*`NUM_THREAD*(1+1)-1-:`XLEN*`NUM_THREAD] <= {bankIn_data_i[`XLEN*`NUM_THREAD*(1+1)-1-:`XLEN*`NUM_THREAD]};
          default:   rs_reg[`XLEN*`NUM_THREAD*(1+1)-1-:`XLEN*`NUM_THREAD] <= {`XLEN*`NUM_THREAD{1'b0}};
        endcase
        ready_reg[1] <= 1'b1;
      end else if(bankIn_fire[2] && bankIn_regOrder_i[2*(2+1)-1-:2]==2'b01) begin
        case(control_fire ? rsType_wire[3:2] : rsType_reg[3:2])
          `A2_RS2:   rs_reg[`XLEN*`NUM_THREAD*(1+1)-1-:`XLEN*`NUM_THREAD] <= {`NUM_THREAD{bankIn_data_i[`XLEN*`NUM_THREAD*2+`XLEN-1-:`XLEN]}};
          `A2_VRS2:  rs_reg[`XLEN*`NUM_THREAD*(1+1)-1-:`XLEN*`NUM_THREAD] <= {bankIn_data_i[`XLEN*`NUM_THREAD*(2+1)-1-:`XLEN*`NUM_THREAD]};
          default:   rs_reg[`XLEN*`NUM_THREAD*(1+1)-1-:`XLEN*`NUM_THREAD] <= {`XLEN*`NUM_THREAD{1'b0}};
        endcase
        ready_reg[1] <= 1'b1;
      end else if(bankIn_fire[3] && bankIn_regOrder_i[2*(3+1)-1-:2]==2'b01) begin
        case(control_fire ? rsType_wire[3:2] : rsType_reg[3:2])
          `A2_RS2:   rs_reg[`XLEN*`NUM_THREAD*(1+1)-1-:`XLEN*`NUM_THREAD] <= {`NUM_THREAD{bankIn_data_i[`XLEN*`NUM_THREAD*3+`XLEN-1-:`XLEN]}};
          `A2_VRS2:  rs_reg[`XLEN*`NUM_THREAD*(1+1)-1-:`XLEN*`NUM_THREAD] <= {bankIn_data_i[`XLEN*`NUM_THREAD*(3+1)-1-:`XLEN*`NUM_THREAD]};
          default:   rs_reg[`XLEN*`NUM_THREAD*(1+1)-1-:`XLEN*`NUM_THREAD] <= {`XLEN*`NUM_THREAD{1'b0}};
        endcase
        ready_reg[1] <= 1'b1;
      end else if(current_state==S_IDLE && control_fire) begin
        if(control_sel_alu2_i==`A2_IMM) begin 
          rs_reg[`XLEN*`NUM_THREAD*(1+1)-1-:`XLEN*`NUM_THREAD] <= {`NUM_THREAD{imm_out}};
          ready_reg[1]  <= 1'b1;
        end else if(control_sel_alu2_i==`A2_SIZE) begin
          rs_reg[`XLEN*`NUM_THREAD*(1+1)-1-:`XLEN*`NUM_THREAD] <= {`NUM_THREAD{{28{1'b0}},4'b0100}};
          ready_reg[1]  <= 1'b1;
        end else begin
          rs_reg[`XLEN*`NUM_THREAD*(1+1)-1-:`XLEN*`NUM_THREAD] <= rs_reg[`XLEN*`NUM_THREAD*(1+1)-1-:`XLEN*`NUM_THREAD];
          ready_reg[1]  <= 1'b0;
        end
      end else if(current_state==S_OUT) begin
        rs_reg[`XLEN*`NUM_THREAD*(1+1)-1-:`XLEN*`NUM_THREAD] <= rs_reg[`XLEN*`NUM_THREAD*(1+1)-1-:`XLEN*`NUM_THREAD];
        ready_reg[1] <= 1'b0;
      end else begin
        rs_reg[`XLEN*`NUM_THREAD*(1+1)-1-:`XLEN*`NUM_THREAD] <= rs_reg[`XLEN*`NUM_THREAD*(1+1)-1-:`XLEN*`NUM_THREAD];
        ready_reg[1] <= ready_reg[1];
      end
  end
  
  // operand3
  always @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        rs_reg[`XLEN*`NUM_THREAD*(2+1)-1-:`XLEN*`NUM_THREAD]  <=  'b0;
        ready_reg[2]                                          <= 1'b0;
      end else if(bankIn_fire[0] && bankIn_regOrder_i[2*(0+1)-1-:2]==2'b10) begin
        case(controlReg_sel_alu3)
          `A3_PC:    rs_reg[`XLEN*`NUM_THREAD*(2+1)-1-:`XLEN*`NUM_THREAD] <= {`NUM_THREAD{bankIn_data_i[`XLEN*`NUM_THREAD*0+`XLEN-1-:`XLEN] + imm_out}};
          `A3_VRS3:  rs_reg[`XLEN*`NUM_THREAD*(2+1)-1-:`XLEN*`NUM_THREAD] <= {bankIn_data_i[`XLEN*`NUM_THREAD*(0+1)-1-:`XLEN*`NUM_THREAD]};
          `A3_SD:    rs_reg[`XLEN*`NUM_THREAD*(2+1)-1-:`XLEN*`NUM_THREAD] <= controlReg_isvec ? bankIn_data_i[`XLEN*`NUM_THREAD*(0+1)-1-:`XLEN*`NUM_THREAD] : {`NUM_THREAD{bankIn_data_i[`XLEN*`NUM_THREAD*0+`XLEN-1-:`XLEN]}};
          `A3_FRS3:  rs_reg[`XLEN*`NUM_THREAD*(2+1)-1-:`XLEN*`NUM_THREAD] <= {`NUM_THREAD{bankIn_data_i[`XLEN*`NUM_THREAD*0+`XLEN-1-:`XLEN]}};
          default:   rs_reg[`XLEN*`NUM_THREAD*(2+1)-1-:`XLEN*`NUM_THREAD] <= {`XLEN*`NUM_THREAD{1'b0}};
        endcase
        ready_reg[2] <= 1'b1;
      end else if(bankIn_fire[1] && bankIn_regOrder_i[2*(1+1)-1-:2]==2'b10) begin
        case(controlReg_sel_alu3)
          `A3_PC:    rs_reg[`XLEN*`NUM_THREAD*(2+1)-1-:`XLEN*`NUM_THREAD] <= {`NUM_THREAD{bankIn_data_i[`XLEN*`NUM_THREAD*1+`XLEN-1-:`XLEN] + imm_out}};
          `A3_VRS3:  rs_reg[`XLEN*`NUM_THREAD*(2+1)-1-:`XLEN*`NUM_THREAD] <= {bankIn_data_i[`XLEN*`NUM_THREAD*(1+1)-1-:`XLEN*`NUM_THREAD]};
          `A3_SD:    rs_reg[`XLEN*`NUM_THREAD*(2+1)-1-:`XLEN*`NUM_THREAD] <= controlReg_isvec ? bankIn_data_i[`XLEN*`NUM_THREAD*(1+1)-1-:`XLEN*`NUM_THREAD] : {`NUM_THREAD{bankIn_data_i[`XLEN*`NUM_THREAD*1+`XLEN-1-:`XLEN]}};
          `A3_FRS3:  rs_reg[`XLEN*`NUM_THREAD*(2+1)-1-:`XLEN*`NUM_THREAD] <= {`NUM_THREAD{bankIn_data_i[`XLEN*`NUM_THREAD*1+`XLEN-1-:`XLEN]}};
          default:   rs_reg[`XLEN*`NUM_THREAD*(2+1)-1-:`XLEN*`NUM_THREAD] <= {`XLEN*`NUM_THREAD{1'b0}};
        endcase
        ready_reg[2] <= 1'b1;          
      end else if(bankIn_fire[2] && bankIn_regOrder_i[2*(2+1)-1-:2]==2'b10) begin
        case(controlReg_sel_alu3)
          `A3_PC:    rs_reg[`XLEN*`NUM_THREAD*(2+1)-1-:`XLEN*`NUM_THREAD] <= {`NUM_THREAD{bankIn_data_i[`XLEN*`NUM_THREAD*2+`XLEN-1-:`XLEN] + imm_out}};
          `A3_VRS3:  rs_reg[`XLEN*`NUM_THREAD*(2+1)-1-:`XLEN*`NUM_THREAD] <= {bankIn_data_i[`XLEN*`NUM_THREAD*(2+1)-1-:`XLEN*`NUM_THREAD]};
          `A3_SD:    rs_reg[`XLEN*`NUM_THREAD*(2+1)-1-:`XLEN*`NUM_THREAD] <= controlReg_isvec ? bankIn_data_i[`XLEN*`NUM_THREAD*(2+1)-1-:`XLEN*`NUM_THREAD] : {`NUM_THREAD{bankIn_data_i[`XLEN*`NUM_THREAD*2+`XLEN-1-:`XLEN]}};
          `A3_FRS3:  rs_reg[`XLEN*`NUM_THREAD*(2+1)-1-:`XLEN*`NUM_THREAD] <= {`NUM_THREAD{bankIn_data_i[`XLEN*`NUM_THREAD*2+`XLEN-1-:`XLEN]}};
          default:   rs_reg[`XLEN*`NUM_THREAD*(2+1)-1-:`XLEN*`NUM_THREAD] <= {`XLEN*`NUM_THREAD{1'b0}};
        endcase
        ready_reg[2] <= 1'b1;          
      end else if(bankIn_fire[3] && bankIn_regOrder_i[2*(3+1)-1-:2]==2'b10) begin
        case(controlReg_sel_alu3)
          `A3_PC:    rs_reg[`XLEN*`NUM_THREAD*(2+1)-1-:`XLEN*`NUM_THREAD] <= {`NUM_THREAD{bankIn_data_i[`XLEN*`NUM_THREAD*3+`XLEN-1-:`XLEN] + imm_out}};
          `A3_VRS3:  rs_reg[`XLEN*`NUM_THREAD*(2+1)-1-:`XLEN*`NUM_THREAD] <= {bankIn_data_i[`XLEN*`NUM_THREAD*(3+1)-1-:`XLEN*`NUM_THREAD]};
          `A3_SD:    rs_reg[`XLEN*`NUM_THREAD*(2+1)-1-:`XLEN*`NUM_THREAD] <= controlReg_isvec ? bankIn_data_i[`XLEN*`NUM_THREAD*(3+1)-1-:`XLEN*`NUM_THREAD] : {`NUM_THREAD{bankIn_data_i[`XLEN*`NUM_THREAD*3+`XLEN-1-:`XLEN]}};
          `A3_FRS3:  rs_reg[`XLEN*`NUM_THREAD*(2+1)-1-:`XLEN*`NUM_THREAD] <= {`NUM_THREAD{bankIn_data_i[`XLEN*`NUM_THREAD*3+`XLEN-1-:`XLEN]}};
          default:   rs_reg[`XLEN*`NUM_THREAD*(2+1)-1-:`XLEN*`NUM_THREAD] <= {`XLEN*`NUM_THREAD{1'b0}};
        endcase
        ready_reg[2] <= 1'b1;
      end else if(current_state==S_IDLE && control_fire) begin
        if(control_sel_alu3_i==`A3_PC && control_branch_i!=`B_R) begin
          rs_reg[`XLEN*`NUM_THREAD*(2+1)-1-:`XLEN*`NUM_THREAD] <= {`NUM_THREAD{imm_out + control_pc_i}};
          ready_reg[2]  <= 1'b1;
        end else begin
          rs_reg[`XLEN*`NUM_THREAD*(2+1)-1-:`XLEN*`NUM_THREAD] <= rs_reg[`XLEN*`NUM_THREAD*(2+1)-1-:`XLEN*`NUM_THREAD];
          ready_reg[2]  <= 1'b0;
        end
      end else if(current_state==S_OUT) begin
        rs_reg[`XLEN*`NUM_THREAD*(2+1)-1-:`XLEN*`NUM_THREAD] <= rs_reg[`XLEN*`NUM_THREAD*(2+1)-1-:`XLEN*`NUM_THREAD];
        ready_reg[2]  <= 1'b0;
      end else begin
        rs_reg[`XLEN*`NUM_THREAD*(2+1)-1-:`XLEN*`NUM_THREAD] <= rs_reg[`XLEN*`NUM_THREAD*(2+1)-1-:`XLEN*`NUM_THREAD];
        ready_reg[2] <= ready_reg[2];
      end
  end

  // this instruction is an Vector with mask, the mask is read from vector register bank
  always @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        ready_reg[3]  <= 1'b0;
      end else if(bankIn_fire[0] && bankIn_regOrder_i[2*(0+1)-1-:2]==2'b11) begin 
        ready_reg[3]  <= 1'b1;
      end else if(bankIn_fire[1] && bankIn_regOrder_i[2*(1+1)-1-:2]==2'b11) begin 
        ready_reg[3]  <= 1'b1;
      end else if(bankIn_fire[2] && bankIn_regOrder_i[2*(2+1)-1-:2]==2'b11) begin 
        ready_reg[3]  <= 1'b1;
      end else if(bankIn_fire[3] && bankIn_regOrder_i[2*(3+1)-1-:2]==2'b11) begin 
        ready_reg[3]  <= 1'b1;
      end else if(current_state==S_IDLE && control_fire && (!control_mask_i)) begin
        ready_reg[3]  <= 1'b1;
      end else if(current_state==S_OUT) begin
        ready_reg[3]  <= 1'b0;
      end else begin
        ready_reg[3]  <= ready_reg[3];
      end
  end

  genvar j;
  generate
    for(j=0; j<`NUM_THREAD; j=j+1) begin:thread_loop
      always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
          mask_reg[j]      <= 1'b0;
        end else if(bankIn_fire[0] && bankIn_regOrder_i[2*(0+1)-1-:2]==2'b11) begin 
          mask_reg[j]      <= bankIn_v0_i[`XLEN*j];
        end else if(bankIn_fire[1] && bankIn_regOrder_i[2*(1+1)-1-:2]==2'b11) begin 
          mask_reg[j]      <= bankIn_v0_i[`XLEN*`NUM_THREAD*1+`XLEN*j];
        end else if(bankIn_fire[2] && bankIn_regOrder_i[2*(2+1)-1-:2]==2'b11) begin 
          mask_reg[j]      <= bankIn_v0_i[`XLEN*`NUM_THREAD*2+`XLEN*j];
        end else if(bankIn_fire[3] && bankIn_regOrder_i[2*(3+1)-1-:2]==2'b11) begin 
          mask_reg[j]      <= bankIn_v0_i[`XLEN*`NUM_THREAD*3+`XLEN*j];
        end else if(current_state==S_IDLE && control_fire && (!control_mask_i)) begin
          mask_reg[j]      <= control_isvec_i ? 1'b1 : (j==0 ? 1'b1 : 1'b0);
        end else if(current_state==S_OUT) begin
          mask_reg[j]      <= mask_reg[j];
        end else begin
          mask_reg[j]      <= mask_reg[j];
        end
      end
    end
  endgenerate


  always @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        rsType_reg      <=  'b0 ;
        valid_reg       <=  'b0 ;
        regIdx_reg      <=  'b0 ;
        customCtrl_reg  <=  'b0 ;
      end else if(current_state==S_IDLE && control_fire) begin
        regIdx_reg      <= {{(`REGIDX_WIDTH+`REGEXT_WIDTH){1'b0}},regIdx_wire[(`REGIDX_WIDTH+`REGEXT_WIDTH)*3-1:0]};
        valid_reg       <= 4'b1111;
        rsType_reg      <= rsType_wire;
        customCtrl_reg  <= customCtrl_wire;
      end else if(current_state==S_OUT) begin
        valid_reg       <= 4'b0;
      end else begin
        rsType_reg      <=  rsType_reg      ;
        valid_reg       <=  valid_reg       ;
        regIdx_reg      <=  regIdx_reg      ;
        customCtrl_reg  <=  customCtrl_reg  ;
      end
  end
  
  // status output wire signal
  always @(*) begin
    case(current_state)
      S_IDLE: begin
        if(control_fire) begin
          // using an iterable variable to indicate reg_idx signals
          regIdx_wire[`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] = control_reg_idx1_i;
          regIdx_wire[(`REGIDX_WIDTH+`REGEXT_WIDTH)*2-1:`REGIDX_WIDTH+`REGEXT_WIDTH] = control_reg_idx2_i;
          case(control_sel_alu3_i)
            `A3_PC:    regIdx_wire[(`REGIDX_WIDTH+`REGEXT_WIDTH)*3-1:(`REGIDX_WIDTH+`REGEXT_WIDTH)*2] = control_branch_i==`B_R ? control_reg_idx1_i : control_reg_idx3_i;
            `A3_VRS3:  regIdx_wire[(`REGIDX_WIDTH+`REGEXT_WIDTH)*3-1:(`REGIDX_WIDTH+`REGEXT_WIDTH)*2] = control_reg_idx3_i;
            `A3_SD:    regIdx_wire[(`REGIDX_WIDTH+`REGEXT_WIDTH)*3-1:(`REGIDX_WIDTH+`REGEXT_WIDTH)*2] = control_isvec_i & !control_readmask_i ? control_reg_idx3_i : control_reg_idx2_i;
            `A3_FRS3:  regIdx_wire[(`REGIDX_WIDTH+`REGEXT_WIDTH)*3-1:(`REGIDX_WIDTH+`REGEXT_WIDTH)*2] = control_reg_idx3_i;
            default:   regIdx_wire[(`REGIDX_WIDTH+`REGEXT_WIDTH)*3-1:(`REGIDX_WIDTH+`REGEXT_WIDTH)*2] =  'b0;
          endcase
          regIdx_wire[(`REGIDX_WIDTH+`REGEXT_WIDTH)*4-1:(`REGIDX_WIDTH+`REGEXT_WIDTH)*3] =  'b0; // mask of vector instructions
          //valid_wire  = 4'b1111;

          // using an iterable variable to indicate sel_alu signals
          rsType_wire[1:0] = control_sel_alu1_i;
          rsType_wire[3:2] = control_sel_alu2_i;
          case(control_sel_alu3_i)
            `A3_PC:    rsType_wire[5:4] = control_branch_i==`B_R ? 2'b01 : 2'b11;
            `A3_VRS3:  rsType_wire[5:4] = 2'b10;
            `A3_SD:    rsType_wire[5:4] = control_isvec_i ? 2'b10 : 2'b01;
            `A3_FRS3:  rsType_wire[5:4] = 2'b01;
            default:   rsType_wire[5:4] = 2'b00;
          endcase
          rsType_wire[7:6] = 2'b00; // rsType == 0: mask (for op4);
          customCtrl_wire = control_custom_signal_0_i;

          // if the operand1 or operand2 is an immediate, elaborate it and enable the ready bit
          ready_wire[0] = control_sel_alu1_i==`A1_IMM ? 1'b1 : (control_sel_alu1_i==`A1_PC    ? 1'b1 : 1'b0);
          ready_wire[1] = control_sel_alu2_i==`A2_IMM ? 1'b1 : (control_sel_alu2_i==`A2_SIZE  ? 1'b1 : 1'b0);
          ready_wire[2] = (control_sel_alu3_i==`A3_PC && control_branch_i!=`B_R) ? 1'b1 : 1'b0;
          ready_wire[3] = !control_mask_i ? 1'b1 : 1'b0;
        end else begin
          rsType_wire     = 'b0;
          ready_wire      = 'b0;
          //valid_wire      = 'b0;
          regIdx_wire     = 'b0;
          customCtrl_wire = 'b0;
        end
      end
      S_OUT:  begin        
        //valid_wire      = 'b0;
        rsType_wire     = 'b0;
        ready_wire      = 'b0;
        regIdx_wire     = 'b0;
        customCtrl_wire = 'b0;
      end
      default:begin
        rsType_wire     = 'b0;
        ready_wire      = 'b0;
        //valid_wire      = 'b0;
        regIdx_wire     = 'b0;
        customCtrl_wire = 'b0;
      end
    endcase
  end
  
  // reading the register bank for those operand which type is not an immediate
  genvar i;
  generate
    for (i=0; i<4; i=i+1) begin:wire_loop  
      // bankID = (wid + regIdx) % num_bank
      assign  outArbiter_bankID_o[`DEPTH_BANK*(i+1)-1:`DEPTH_BANK*i] = control_fire & current_state==S_IDLE ? 
              control_wid_i[`DEPTH_BANK-1:0] + regIdx_wire[(`REGIDX_WIDTH+`REGEXT_WIDTH)*i+`DEPTH_BANK-1:(`REGIDX_WIDTH+`REGEXT_WIDTH)*i] : 
              controlReg_wid[`DEPTH_BANK-1:0] + regIdx_reg[(`REGIDX_WIDTH+`REGEXT_WIDTH)*i+`DEPTH_BANK-1:(`REGIDX_WIDTH+`REGEXT_WIDTH)*i] ;
      assign  outArbiter_rsType_o[2*(i+1)-1:2*i] = control_fire & current_state==S_IDLE ? 
              rsType_wire[2*(i+1)-1:2*i] : rsType_reg[2*(i+1)-1:2*i];

      //assign  bankIn_ready_o[i] = (current_state==S_ADD && ready_reg[i]==1'b0) || (control_fire && ready_wire[i]==1'b0);
      
      always @(*) begin
        // rsAddr =  [gpr_base(i) + regIdx] / num_bank
        if(outArbiter_rsType_o[2*(i+1)-1-:2]==2'b01) begin
          if(control_fire & current_state==S_IDLE) begin
            outArbiter_rsAddr_o[`DEPTH_REGBANK*(i+1)-1-:`DEPTH_REGBANK] =  (sgpr_base_i[(`SGPR_ID_WIDTH+1)*(control_wid_i+1)-1-:(`SGPR_ID_WIDTH+1)] >> `DEPTH_BANK) + 
                                                                            (regIdx_wire[(`REGIDX_WIDTH+`REGEXT_WIDTH)*(i+1)-1:(`REGIDX_WIDTH+`REGEXT_WIDTH)*i]   >> `DEPTH_BANK);
          end else begin
            outArbiter_rsAddr_o[`DEPTH_REGBANK*(i+1)-1-:`DEPTH_REGBANK] =  (sgpr_base_i[(`SGPR_ID_WIDTH+1)*(controlReg_wid+1)-1-:(`SGPR_ID_WIDTH+1)] >> `DEPTH_BANK) + 
                                                                            (regIdx_reg[(`REGIDX_WIDTH+`REGEXT_WIDTH)*(i+1)-1:(`REGIDX_WIDTH+`REGEXT_WIDTH)*i]      >> `DEPTH_BANK);        
          end
        end else if(outArbiter_rsType_o[2*(i+1)-1-:2]==2'b10) begin
          if(control_fire & current_state==S_IDLE) begin
            outArbiter_rsAddr_o[`DEPTH_REGBANK*(i+1)-1-:`DEPTH_REGBANK] =  (vgpr_base_i[(`VGPR_ID_WIDTH+1)*(control_wid_i+1)-1-:(`VGPR_ID_WIDTH+1)] >> `DEPTH_BANK) + 
                                                                            (regIdx_wire[(`REGIDX_WIDTH+`REGEXT_WIDTH)*(i+1)-1:(`REGIDX_WIDTH+`REGEXT_WIDTH)*i]   >> `DEPTH_BANK);
          end else begin
            outArbiter_rsAddr_o[`DEPTH_REGBANK*(i+1)-1-:`DEPTH_REGBANK] =  (vgpr_base_i[(`VGPR_ID_WIDTH+1)*(controlReg_wid+1)-1-:(`VGPR_ID_WIDTH+1)] >> `DEPTH_BANK) + 
                                                                            (regIdx_reg[(`REGIDX_WIDTH+`REGEXT_WIDTH)*(i+1)-1:(`REGIDX_WIDTH+`REGEXT_WIDTH)*i]      >> `DEPTH_BANK);        
          end
        end else begin
          if(control_fire & current_state==S_IDLE) begin
            outArbiter_rsAddr_o[`DEPTH_REGBANK*(i+1)-1-:`DEPTH_REGBANK] =  (sgpr_base_i[(`SGPR_ID_WIDTH+1)*(control_wid_i+1)-1-:(`SGPR_ID_WIDTH+1)] >> `DEPTH_BANK) + 
                                                                            (regIdx_wire[(`REGIDX_WIDTH+`REGEXT_WIDTH)*(i+1)-1:(`REGIDX_WIDTH+`REGEXT_WIDTH)*i]   >> `DEPTH_BANK);
          end else begin
            outArbiter_rsAddr_o[`DEPTH_REGBANK*(i+1)-1-:`DEPTH_REGBANK] =  (sgpr_base_i[(`SGPR_ID_WIDTH+1)*(controlReg_wid+1)-1-:(`SGPR_ID_WIDTH+1)] >> `DEPTH_BANK) + 
                                                                            (regIdx_reg[(`REGIDX_WIDTH+`REGEXT_WIDTH)*(i+1)-1:(`REGIDX_WIDTH+`REGEXT_WIDTH)*i]      >> `DEPTH_BANK);
          end
        end

        // outArbiter_valid
        case(current_state)
          S_IDLE: outArbiter_valid_o[i] = control_fire && ready_wire[i]==1'b0;
          S_ADD:  outArbiter_valid_o[i] = valid_reg[i]==1'b1 && ready_reg[i]==1'b0;
          default:outArbiter_valid_o[i] = 1'b0;
        endcase
      end
    end
  endgenerate
      
  always@(*) begin
    // operand_wire
    if(bankIn_fire[0] && bankIn_regOrder_i[2*(0+1)-1-:2]==2'b00) begin
        case(control_fire ? rsType_wire[1:0] : rsType_reg[1:0])
          `A1_RS1:   rsRead_wire = {`NUM_THREAD{bankIn_data_i[`XLEN*`NUM_THREAD*0+`XLEN-1-:`XLEN]}};
          `A1_VRS1:  rsRead_wire = {bankIn_data_i[`XLEN*`NUM_THREAD*(0+1)-1-:`XLEN*`NUM_THREAD]};
          default:   rsRead_wire = {`XLEN*`NUM_THREAD{1'b0}};
        endcase
    end else if(bankIn_fire[1] && bankIn_regOrder_i[2*(1+1)-1-:2]==2'b00) begin
        case(control_fire ? rsType_wire[1:0] : rsType_reg[1:0])
          `A1_RS1:   rsRead_wire = {`NUM_THREAD{bankIn_data_i[`XLEN*`NUM_THREAD*1+`XLEN-1-:`XLEN]}};
          `A1_VRS1:  rsRead_wire = {bankIn_data_i[`XLEN*`NUM_THREAD*(1+1)-1-:`XLEN*`NUM_THREAD]};
          default:   rsRead_wire = {`XLEN*`NUM_THREAD{1'b0}};
        endcase
    end else if(bankIn_fire[2] && bankIn_regOrder_i[2*(2+1)-1-:2]==2'b00) begin
        case(control_fire ? rsType_wire[1:0] : rsType_reg[1:0])
          `A1_RS1:   rsRead_wire = {`NUM_THREAD{bankIn_data_i[`XLEN*`NUM_THREAD*2+`XLEN-1-:`XLEN]}};
          `A1_VRS1:  rsRead_wire = {bankIn_data_i[`XLEN*`NUM_THREAD*(2+1)-1-:`XLEN*`NUM_THREAD]};
          default:   rsRead_wire = {`XLEN*`NUM_THREAD{1'b0}};
        endcase
    end else if(bankIn_fire[3] && bankIn_regOrder_i[2*(3+1)-1-:2]==2'b00) begin
        case(control_fire ? rsType_wire[1:0] : rsType_reg[1:0])
          `A1_RS1:   rsRead_wire = {`NUM_THREAD{bankIn_data_i[`XLEN*`NUM_THREAD*3+`XLEN-1-:`XLEN]}};
          `A1_VRS1:  rsRead_wire = {bankIn_data_i[`XLEN*`NUM_THREAD*(3+1)-1-:`XLEN*`NUM_THREAD]};
          default:   rsRead_wire = {`XLEN*`NUM_THREAD{1'b0}};
        endcase
    end else begin
      rsRead_wire = 'b0;
    end
  end

  assign issue_alu_src1_o     = rs_reg[`XLEN*`NUM_THREAD-1:0];
  assign issue_alu_src2_o     = rs_reg[`XLEN*`NUM_THREAD*2-1:`XLEN*`NUM_THREAD*1];
  assign issue_alu_src3_o     = rs_reg[`XLEN*`NUM_THREAD*3-1:`XLEN*`NUM_THREAD*2];
  assign issue_active_mask_o  = mask_reg;
  
  assign issue_valid_o   = current_state==S_OUT;
  assign control_ready_o = current_state==S_IDLE && !(|valid_reg);


gen_imm U_gen_imm(
  .inst_i     (imm_inst)    ,
  .sel_i      (imm_sel)     ,
  .imm_ext_i  (imm_ext) , 
  .out_o      (imm_out)  
);

endmodule

