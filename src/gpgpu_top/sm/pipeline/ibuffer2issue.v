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
// Author: TangYao
// Description: According the prior warp, decide the corresponding ibuffer will output its control_signals first.
`timescale 1ns/1ns
`include "define.v"
//`include "decode_df_para.v"

module ibuffer2issue(
  //8 sets of input signals from 8 buffers
  //ibuffer2issue.io.in(i).valid:=ibuffer.io.out(i).valid & warp_sche.io.warp_ready(i)
  //ibuffer.io.out(i).ready:=ibuffer2issue.io.in(i).ready & warp_sche.io.warp_ready(i)      
  input                                                    clk                                                          ,
  input                                                    rst_n                                                        ,
  //input [`NUM_WARP-1:0]                                    ibuffer_valid_i                                              ,  //no flush, no full ibuffer  connect to ibuffer_valid_o
  //output [`NUM_WARP-1:0]                                   ibuffer_ready_o                                              ,  //no flush, no full ibuffer  connect to ibuffer_ready_o    warp_sche_warp_ready_i,  //connect to warp_sche_warp_ready_i
  
  //control signals from 8 input ibuffers               
  input [`NUM_WARP*`INSTLEN-1:0]                            ibuffer_warps_control_Signals_inst_i                         ,
  input [`NUM_WARP*`DEPTH_WARP-1:0]                         ibuffer_warps_control_Signals_wid_i                          ,
  input [`NUM_WARP-1:0]                                     ibuffer_warps_control_Signals_fp_i                           ,
  input [`NUM_WARP*2-1:0]                                   ibuffer_warps_control_Signals_branch_i                       ,
  input [`NUM_WARP-1:0]                                     ibuffer_warps_control_Signals_simt_stack_i                   ,
  input [`NUM_WARP-1:0]                                     ibuffer_warps_control_Signals_simt_stack_op_i                ,
  input [`NUM_WARP-1:0]                                     ibuffer_warps_control_Signals_barrier_i                      ,
  input [`NUM_WARP*2-1:0]                                   ibuffer_warps_control_Signals_csr_i                          ,
  input [`NUM_WARP-1:0]                                     ibuffer_warps_control_Signals_reverse_i                      ,
  input [`NUM_WARP*2-1:0]                                   ibuffer_warps_control_Signals_sel_alu2_i                     ,
  input [`NUM_WARP*2-1:0]                                   ibuffer_warps_control_Signals_sel_alu1_i                     ,
  input [`NUM_WARP*2-1:0]                                   ibuffer_warps_control_Signals_sel_alu3_i                     ,
  input [`NUM_WARP-1:0]                                     ibuffer_warps_control_Signals_isvec_i                        ,
  input [`NUM_WARP-1:0]                                     ibuffer_warps_control_Signals_mask_i                         ,
  input [`NUM_WARP*4-1:0]                                   ibuffer_warps_control_Signals_sel_imm_i                      ,
  input [`NUM_WARP*2-1:0]                                   ibuffer_warps_control_Signals_mem_whb_i                      ,
  input [`NUM_WARP-1:0]                                     ibuffer_warps_control_Signals_mem_unsigned_i                 ,
  input [`NUM_WARP*6-1:0]                                   ibuffer_warps_control_Signals_alu_fn_i                       ,
  input [`NUM_WARP-1:0]                                     ibuffer_warps_control_Signals_force_rm_rtz_i                 ,
  input [`NUM_WARP-1:0]                                     ibuffer_warps_control_Signals_is_vls12_i                     ,
  input [`NUM_WARP-1:0]                                     ibuffer_warps_control_Signals_mem_i                          ,
  input [`NUM_WARP-1:0]                                     ibuffer_warps_control_Signals_mul_i                          ,
  input [`NUM_WARP-1:0]                                     ibuffer_warps_control_Signals_tc_i                           ,
  input [`NUM_WARP-1:0]                                     ibuffer_warps_control_Signals_disable_mask_i                 ,
  input [`NUM_WARP-1:0]                                     ibuffer_warps_control_Signals_custom_signal_0_i              ,
  input [`NUM_WARP*2-1:0]                                   ibuffer_warps_control_Signals_mem_cmd_i                      ,
  input [`NUM_WARP*2-1:0]                                   ibuffer_warps_control_Signals_mop_i                          ,
  input [`NUM_WARP*(`REGEXT_WIDTH + `REGIDX_WIDTH)-1:0]     ibuffer_warps_control_Signals_reg_idx1_i                     ,
  input [`NUM_WARP*(`REGEXT_WIDTH + `REGIDX_WIDTH)-1:0]     ibuffer_warps_control_Signals_reg_idx2_i                     ,
  input [`NUM_WARP*(`REGEXT_WIDTH + `REGIDX_WIDTH)-1:0]     ibuffer_warps_control_Signals_reg_idx3_i                     ,
  input [`NUM_WARP*(`REGEXT_WIDTH + `REGIDX_WIDTH)-1:0]     ibuffer_warps_control_Signals_reg_idxw_i                     ,
  input [`NUM_WARP-1:0]                                     ibuffer_warps_control_Signals_wvd_i                          ,
  input [`NUM_WARP-1:0]                                     ibuffer_warps_control_Signals_fence_i                        ,
  input [`NUM_WARP-1:0]                                     ibuffer_warps_control_Signals_sfu_i                          ,
  input [`NUM_WARP-1:0]                                     ibuffer_warps_control_Signals_readmask_i                     ,
  //input [`NUM_WARP-1:0]                                     ibuffer_warps_control_Signals_writemask_i                    ,
  input [`NUM_WARP-1:0]                                     ibuffer_warps_control_Signals_wxd_i                          ,
  input [`NUM_WARP*`INSTLEN-1:0]                            ibuffer_warps_control_Signals_pc_i                           ,
  input [`NUM_WARP*6-1:0]                                   ibuffer_warps_control_Signals_imm_ext_i                      ,
  input [`NUM_WARP-1:0]                                     ibuffer_warps_control_Signals_atomic_i                       ,
  input [`NUM_WARP-1:0]                                     ibuffer_warps_control_Signals_aq_i                           ,
  input [`NUM_WARP-1:0]                                     ibuffer_warps_control_Signals_rl_i                           ,
  input [`NUM_WARP*3-1:0]									                  ibuffer_warps_control_Signals_rm_i							             ,//for static rm
  input [`NUM_WARP-1:0]									                    ibuffer_warps_control_Signals_rm_is_static_i				         ,
  //input [`NUM_WARP-1:0]                                    ibuffer_warps_control_Signals_spike_info_i                   ,
  //output is chosen by a set of control signals 
  //from 8 input above.
  input [`NUM_WARP-1:0]                                    ibuffer2issue_in_valid_i                                     ,
  output [`NUM_WARP-1:0]                                   ibuffer2issue_in_ready_o                                     ,  //connect to ibuffer2issue_in_valid_i with warp_sche.io.warp_ready(i)ibuffer2issue_in_ready_o,   //connect to ibuffer_out_ready_i with warp_sche.io.warp_ready(i)
  
  output [`INSTLEN-1:0]                                    ibuffer2issue_warps_control_Signals_inst_o                   ,
  output [`DEPTH_WARP-1:0]                                 ibuffer2issue_warps_control_Signals_wid_o                    ,
  output                                                   ibuffer2issue_warps_control_Signals_fp_o                     ,
  output [1:0]                                             ibuffer2issue_warps_control_Signals_branch_o                 ,
  output                                                   ibuffer2issue_warps_control_Signals_simt_stack_o             ,
  output                                                   ibuffer2issue_warps_control_Signals_simt_stack_op_o          ,
  output                                                   ibuffer2issue_warps_control_Signals_barrier_o                ,
  output [1:0]                                             ibuffer2issue_warps_control_Signals_csr_o                    ,
  output                                                   ibuffer2issue_warps_control_Signals_reverse_o                ,
  output [1:0]                                             ibuffer2issue_warps_control_Signals_sel_alu2_o               ,
  output [1:0]                                             ibuffer2issue_warps_control_Signals_sel_alu1_o               ,
  output [1:0]                                             ibuffer2issue_warps_control_Signals_sel_alu3_o               ,
  output                                                   ibuffer2issue_warps_control_Signals_isvec_o                  ,
  output                                                   ibuffer2issue_warps_control_Signals_mask_o                   ,
  output [3:0]                                             ibuffer2issue_warps_control_Signals_sel_imm_o                ,
  output [1:0]                                             ibuffer2issue_warps_control_Signals_mem_whb_o                ,
  output                                                   ibuffer2issue_warps_control_Signals_mem_unsigned_o           ,
  output [5:0]                                             ibuffer2issue_warps_control_Signals_alu_fn_o                 ,
  output                                                   ibuffer2issue_warps_control_Signals_force_rm_rtz_o           ,
  output                                                   ibuffer2issue_warps_control_Signals_is_vls12_o               ,
  output                                                   ibuffer2issue_warps_control_Signals_mem_o                    ,
  output                                                   ibuffer2issue_warps_control_Signals_mul_o                    ,
  output                                                   ibuffer2issue_warps_control_Signals_tc_o                     ,
  output                                                   ibuffer2issue_warps_control_Signals_disable_mask_o           ,
  output                                                   ibuffer2issue_warps_control_Signals_custom_signal_0_o        ,
  output [1:0]                                             ibuffer2issue_warps_control_Signals_mem_cmd_o                ,
  output [1:0]                                             ibuffer2issue_warps_control_Signals_mop_o                    ,
  output [(`REGEXT_WIDTH + `REGIDX_WIDTH)-1:0]             ibuffer2issue_warps_control_Signals_reg_idx1_o               ,
  output [(`REGEXT_WIDTH + `REGIDX_WIDTH)-1:0]             ibuffer2issue_warps_control_Signals_reg_idx2_o               ,
  output [(`REGEXT_WIDTH + `REGIDX_WIDTH)-1:0]             ibuffer2issue_warps_control_Signals_reg_idx3_o               ,
  output [(`REGEXT_WIDTH + `REGIDX_WIDTH)-1:0]             ibuffer2issue_warps_control_Signals_reg_idxw_o               ,
  output                                                   ibuffer2issue_warps_control_Signals_wvd_o                    ,
  output                                                   ibuffer2issue_warps_control_Signals_fence_o                  ,
  output                                                   ibuffer2issue_warps_control_Signals_sfu_o                    ,
  output                                                   ibuffer2issue_warps_control_Signals_readmask_o               ,
  //output                                                   ibuffer2issue_warps_control_Signals_writemask_o              ,
  output                                                   ibuffer2issue_warps_control_Signals_wxd_o                    ,
  output [`INSTLEN-1:0]                                    ibuffer2issue_warps_control_Signals_pc_o                     ,
  output [5:0]                                             ibuffer2issue_warps_control_Signals_imm_ext_o                ,
  output                                                   ibuffer2issue_warps_control_Signals_atomic_o                 ,
  output                                                   ibuffer2issue_warps_control_Signals_aq_o                     ,
  output                                                   ibuffer2issue_warps_control_Signals_rl_o                     ,
  output [2:0]											                       ibuffer2issue_warps_control_Signals_rm_o						          ,//for static rm
  output												                           ibuffer2issue_warps_control_Signals_rm_is_static_o			      ,
  //output                                                   ibuffer2issue_warps_control_Signals_spike_info_o            ,
  //output [`DEPTH_WARP-1:0]                                 out_sel 
  output                                                   ibuffer2issue_out_valid_o                                    ,
  input                                                    ibuffer2issue_out_ready_i                                    ,
  output [`NUM_WARP-1:0]                                   grant                                                          
  );
  
  //reg  [`NUM_WARP-1:0]   pre_valid ; //pre_valid is used to record the valid signal of previous cycle, used to decide whether to issue or not.
  //wire [2*`NUM_WARP-1:0] grant_ext ;
  wire [`NUM_WARP-1:0]   ibuffer2issue_in_fire ;
  wire                   ibuffer2issue_out_fire;
/*  
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      pre_valid <= {{(`NUM_WARP-1){1'b0}},1'b1};
    end 
    else if(|ibuffer2issue_in_valid_i) begin
      pre_valid <= {grant[`NUM_WARP-2:0],grant[`NUM_WARP-1]};
    end 
    else begin      
      pre_valid <= pre_valid;
    end
  end
  
  assign grant_ext = {ibuffer2issue_in_valid_i,ibuffer2issue_in_valid_i} & ~({ibuffer2issue_in_valid_i,ibuffer2issue_in_valid_i} - pre_valid);
  assign grant = grant_ext[`NUM_WARP-1:0] | grant_ext[2*`NUM_WARP-1:`NUM_WARP];   //invert the binary code ibuffer2issue_in_valid_i to onehot code grant, and then select the first  warps to issue.
  //grant is a onehot code , and need to be converted to binary code.
  */
  round_robin_arb #(
  .ARB_WIDTH (`NUM_WARP)
  ) 
  U_round_robin_arb
  (
   .clk      (clk                       ),
   .rst_n    (rst_n                     ),
   .req      (ibuffer2issue_in_valid_i  ),
   .grant    (grant                     )
  );

  wire [`DEPTH_WARP-1:0] grant_bin; //convert grant(one hot) to binary code
   one2bin #(
   .ONE_WIDTH(`NUM_WARP),
   .BIN_WIDTH(`DEPTH_WARP)
   )
   U_one2bin
   (
   .oh(grant),
   .bin(grant_bin)
   );
  
  //assign   ibuffer2issue_in_ready_o                              =  grant       ;//it is a input value come from other module, so it is always ready.
  //assign ibuffer2issue_in_ready_o = (ibuffer2issue_out_ready_i) ? grant : 'h0;
  //only one ready will be pull up,and the others will be pull down according to grant.
  assign   ibuffer2issue_in_fire =   ibuffer2issue_in_ready_o ;
  assign   ibuffer2issue_out_fire = ibuffer2issue_out_valid_o & ibuffer2issue_out_ready_i;
  
  wire  [`NUM_WARP*`INSTLEN-1:0]                                     arbiter_warps_control_Signals_inst                   ;
  wire  [`NUM_WARP*`DEPTH_WARP-1:0]                                  arbiter_warps_control_Signals_wid                    ;
  wire  [`NUM_WARP-1:0]                                              arbiter_warps_control_Signals_fp                     ;
  wire  [`NUM_WARP*2-1:0]                                            arbiter_warps_control_Signals_branch                 ;
  wire  [`NUM_WARP-1:0]                                              arbiter_warps_control_Signals_simt_stack             ;
  wire  [`NUM_WARP-1:0]                                              arbiter_warps_control_Signals_simt_stack_op          ;
  wire  [`NUM_WARP-1:0]                                              arbiter_warps_control_Signals_barrier                ;
  wire  [`NUM_WARP*2-1:0]                                            arbiter_warps_control_Signals_csr                    ;
  wire  [`NUM_WARP-1:0]                                              arbiter_warps_control_Signals_reverse                ;
  wire  [`NUM_WARP*2-1:0]                                            arbiter_warps_control_Signals_sel_alu2               ;
  wire  [`NUM_WARP*2-1:0]                                            arbiter_warps_control_Signals_sel_alu1               ;
  wire  [`NUM_WARP*2-1:0]                                            arbiter_warps_control_Signals_sel_alu3               ;
  wire  [`NUM_WARP-1:0]                                              arbiter_warps_control_Signals_isvec                  ;
  wire  [`NUM_WARP-1:0]                                              arbiter_warps_control_Signals_mask                   ;
  wire  [`NUM_WARP*4-1:0]                                            arbiter_warps_control_Signals_sel_imm                ;
  wire  [`NUM_WARP*2-1:0]                                            arbiter_warps_control_Signals_mem_whb                ;
  wire  [`NUM_WARP-1:0]                                              arbiter_warps_control_Signals_mem_unsigned           ;
  wire  [`NUM_WARP*6-1:0]                                            arbiter_warps_control_Signals_alu_fn                 ;
  wire  [`NUM_WARP-1:0]                                              arbiter_warps_control_Signals_force_rm_rtz           ;
  wire  [`NUM_WARP-1:0]                                              arbiter_warps_control_Signals_is_vls12               ;
  wire  [`NUM_WARP-1:0]                                              arbiter_warps_control_Signals_mem                    ;
  wire  [`NUM_WARP-1:0]                                              arbiter_warps_control_Signals_mul                    ;
  wire  [`NUM_WARP-1:0]                                              arbiter_warps_control_Signals_tc                     ;
  wire  [`NUM_WARP-1:0]                                              arbiter_warps_control_Signals_disable_mask           ;
  wire  [`NUM_WARP-1:0]                                              arbiter_warps_control_Signals_custom_signal_0        ;
  wire  [`NUM_WARP*2-1:0]                                            arbiter_warps_control_Signals_mem_cmd                ;
  wire  [`NUM_WARP*2-1:0]                                            arbiter_warps_control_Signals_mop                    ;
  wire  [`NUM_WARP*(`REGEXT_WIDTH + `REGIDX_WIDTH)-1:0]              arbiter_warps_control_Signals_reg_idx1               ;
  wire  [`NUM_WARP*(`REGEXT_WIDTH + `REGIDX_WIDTH)-1:0]              arbiter_warps_control_Signals_reg_idx2               ;
  wire  [`NUM_WARP*(`REGEXT_WIDTH + `REGIDX_WIDTH)-1:0]              arbiter_warps_control_Signals_reg_idx3               ;
  wire  [`NUM_WARP*(`REGEXT_WIDTH + `REGIDX_WIDTH)-1:0]              arbiter_warps_control_Signals_reg_idxw               ;
  wire  [`NUM_WARP-1:0]                                              arbiter_warps_control_Signals_wvd                    ;
  wire  [`NUM_WARP-1:0]                                              arbiter_warps_control_Signals_fence                  ;
  wire  [`NUM_WARP-1:0]                                              arbiter_warps_control_Signals_sfu                    ;
  wire  [`NUM_WARP-1:0]                                              arbiter_warps_control_Signals_readmask               ;
  //wire  [`NUM_WARP-1:0]                                              arbiter_warps_control_Signals_writemask              ;
  wire  [`NUM_WARP-1:0]                                              arbiter_warps_control_Signals_wxd                    ;
  wire  [`NUM_WARP*`INSTLEN-1:0]                                     arbiter_warps_control_Signals_pc                     ;
  wire  [`NUM_WARP*6-1:0]                                            arbiter_warps_control_Signals_imm_ext                ;
  wire  [`NUM_WARP-1:0]                                              arbiter_warps_control_Signals_atomic                 ;
  wire  [`NUM_WARP-1:0]                                              arbiter_warps_control_Signals_aq                     ;
  wire  [`NUM_WARP-1:0]                                              arbiter_warps_control_Signals_rl                     ;
  wire  [`NUM_WARP*3-1:0]											                       arbiter_warps_control_Signals_rm					            ;//for static rm
  wire  [`NUM_WARP-1:0]												                       arbiter_warps_control_Signals_rm_is_static			      ;
  
  
  
  genvar p;
  generate 
    for(p=0;p<`NUM_WARP;p=p+1)
    begin: arbiters_by_ibuffer2issue_in
      
       assign  ibuffer2issue_in_ready_o[p] =  ibuffer2issue_out_ready_i;
        
       assign  arbiter_warps_control_Signals_inst                [p*`INSTLEN+:`INSTLEN]                                                       = (ibuffer2issue_in_fire [p]) ?  ibuffer_warps_control_Signals_inst_i             [p*`INSTLEN+:`INSTLEN]                                              :'b0;
       assign  arbiter_warps_control_Signals_wid                 [p*`DEPTH_WARP+:`DEPTH_WARP]                                                 = (ibuffer2issue_in_fire [p]) ?  ibuffer_warps_control_Signals_wid_i              [p*`DEPTH_WARP+:`DEPTH_WARP]                                        :'b0;
       assign  arbiter_warps_control_Signals_fp                  [p+:1]                                                                       = (ibuffer2issue_in_fire [p]) ?  ibuffer_warps_control_Signals_fp_i               [p+:1]                                                              :'b0;
       assign  arbiter_warps_control_Signals_branch              [p*2+:2]                                                                     = (ibuffer2issue_in_fire [p]) ?  ibuffer_warps_control_Signals_branch_i           [p*2+:2]                                                            :'b0;
       assign  arbiter_warps_control_Signals_simt_stack          [p*1+:1]                                                                     = (ibuffer2issue_in_fire [p]) ?  ibuffer_warps_control_Signals_simt_stack_i       [p*1+:1]                                                            :'b0;
       assign  arbiter_warps_control_Signals_simt_stack_op       [p*1+:1]                                                                     = (ibuffer2issue_in_fire [p]) ?  ibuffer_warps_control_Signals_simt_stack_op_i    [p*1+:1]                                                            :'b0;
       assign  arbiter_warps_control_Signals_barrier             [p*1+:1]                                                                     = (ibuffer2issue_in_fire [p]) ?  ibuffer_warps_control_Signals_barrier_i          [p*1+:1]                                                            :'b0;
       assign  arbiter_warps_control_Signals_csr                 [p*2+:2]                                                                     = (ibuffer2issue_in_fire [p]) ?  ibuffer_warps_control_Signals_csr_i              [p*2+:2]                                                            :'b0;
       assign  arbiter_warps_control_Signals_reverse             [p*1+:1]                                                                     = (ibuffer2issue_in_fire [p]) ?  ibuffer_warps_control_Signals_reverse_i          [p*1+:1]                                                            :'b0;
       assign  arbiter_warps_control_Signals_sel_alu2            [p*2+:2]                                                                     = (ibuffer2issue_in_fire [p]) ?  ibuffer_warps_control_Signals_sel_alu2_i         [p*2+:2]                                                            :'b0;
       assign  arbiter_warps_control_Signals_sel_alu1            [p*2+:2]                                                                     = (ibuffer2issue_in_fire [p]) ?  ibuffer_warps_control_Signals_sel_alu1_i         [p*2+:2]                                                            :'b0;
       assign  arbiter_warps_control_Signals_sel_alu3            [p*2+:2]                                                                     = (ibuffer2issue_in_fire [p]) ?  ibuffer_warps_control_Signals_sel_alu3_i         [p*2+:2]                                                            :'b0;
       assign  arbiter_warps_control_Signals_isvec               [p*1+:1]                                                                     = (ibuffer2issue_in_fire [p]) ?  ibuffer_warps_control_Signals_isvec_i            [p*1+:1]                                                            :'b0;
       assign  arbiter_warps_control_Signals_mask                [p*1+:1]                                                                     = (ibuffer2issue_in_fire [p]) ?  ibuffer_warps_control_Signals_mask_i             [p*1+:1]                                                            :'b0;
       assign  arbiter_warps_control_Signals_sel_imm             [p*4+:4]                                                                     = (ibuffer2issue_in_fire [p]) ?  ibuffer_warps_control_Signals_sel_imm_i          [p*4+:4]                                                            :'b0;
       assign  arbiter_warps_control_Signals_mem_whb             [p*2+:2]                                                                     = (ibuffer2issue_in_fire [p]) ?  ibuffer_warps_control_Signals_mem_whb_i          [p*2+:2]                                                            :'b0;
       assign  arbiter_warps_control_Signals_mem_unsigned        [p*1+:1]                                                                     = (ibuffer2issue_in_fire [p]) ?  ibuffer_warps_control_Signals_mem_unsigned_i     [p*1+:1]                                                            :'b0;
       assign  arbiter_warps_control_Signals_alu_fn              [p*6+:6]                                                                     = (ibuffer2issue_in_fire [p]) ?  ibuffer_warps_control_Signals_alu_fn_i           [p*6+:6]                                                            :'b0;
       assign  arbiter_warps_control_Signals_force_rm_rtz        [p*1+:1]                                                                     = (ibuffer2issue_in_fire [p]) ?  ibuffer_warps_control_Signals_force_rm_rtz_i     [p*1+:1]                                                            :'b0;
       assign  arbiter_warps_control_Signals_is_vls12            [p*1+:1]                                                                     = (ibuffer2issue_in_fire [p]) ?  ibuffer_warps_control_Signals_is_vls12_i         [p*1+:1]                                                            :'b0;
       assign  arbiter_warps_control_Signals_mem                 [p*1+:1]                                                                     = (ibuffer2issue_in_fire [p]) ?  ibuffer_warps_control_Signals_mem_i              [p*1+:1]                                                            :'b0;
       assign  arbiter_warps_control_Signals_mul                 [p*1+:1]                                                                     = (ibuffer2issue_in_fire [p]) ?  ibuffer_warps_control_Signals_mul_i              [p*1+:1]                                                            :'b0;
       assign  arbiter_warps_control_Signals_tc                  [p*1+:1]                                                                     = (ibuffer2issue_in_fire [p]) ?  ibuffer_warps_control_Signals_tc_i               [p*1+:1]                                                            :'b0;
       assign  arbiter_warps_control_Signals_disable_mask        [p*1+:1]                                                                     = (ibuffer2issue_in_fire [p]) ?  ibuffer_warps_control_Signals_disable_mask_i     [p*1+:1]                                                            :'b0;
       assign  arbiter_warps_control_Signals_custom_signal_0     [p*1+:1]                                                                     = (ibuffer2issue_in_fire [p]) ?  ibuffer_warps_control_Signals_custom_signal_0_i  [p*1+:1]                                                            :'b0;
       assign  arbiter_warps_control_Signals_mem_cmd             [p*2+:2]                                                                     = (ibuffer2issue_in_fire [p]) ?  ibuffer_warps_control_Signals_mem_cmd_i          [p*2+:2]                                                            :'b0;
       assign  arbiter_warps_control_Signals_mop                 [p*2+:2]                                                                     = (ibuffer2issue_in_fire [p]) ?  ibuffer_warps_control_Signals_mop_i              [p*2+:2]                                                            :'b0;
       assign  arbiter_warps_control_Signals_reg_idx1            [p*(`REGEXT_WIDTH + `REGIDX_WIDTH)+:(`REGEXT_WIDTH + `REGIDX_WIDTH)]         = (ibuffer2issue_in_fire [p]) ?  ibuffer_warps_control_Signals_reg_idx1_i         [p*(`REGEXT_WIDTH + `REGIDX_WIDTH)+:(`REGEXT_WIDTH + `REGIDX_WIDTH)]:'b0;
       assign  arbiter_warps_control_Signals_reg_idx2            [p*(`REGEXT_WIDTH + `REGIDX_WIDTH)+:(`REGEXT_WIDTH + `REGIDX_WIDTH)]         = (ibuffer2issue_in_fire [p]) ?  ibuffer_warps_control_Signals_reg_idx2_i         [p*(`REGEXT_WIDTH + `REGIDX_WIDTH)+:(`REGEXT_WIDTH + `REGIDX_WIDTH)]:'b0;
       assign  arbiter_warps_control_Signals_reg_idx3            [p*(`REGEXT_WIDTH + `REGIDX_WIDTH)+:(`REGEXT_WIDTH + `REGIDX_WIDTH)]         = (ibuffer2issue_in_fire [p]) ?  ibuffer_warps_control_Signals_reg_idx3_i         [p*(`REGEXT_WIDTH + `REGIDX_WIDTH)+:(`REGEXT_WIDTH + `REGIDX_WIDTH)]:'b0;
       assign  arbiter_warps_control_Signals_reg_idxw            [p*(`REGEXT_WIDTH + `REGIDX_WIDTH)+:(`REGEXT_WIDTH + `REGIDX_WIDTH)]         = (ibuffer2issue_in_fire [p]) ?  ibuffer_warps_control_Signals_reg_idxw_i         [p*(`REGEXT_WIDTH + `REGIDX_WIDTH)+:(`REGEXT_WIDTH + `REGIDX_WIDTH)]:'b0;
       assign  arbiter_warps_control_Signals_wvd                 [p*1+:1]                                                                     = (ibuffer2issue_in_fire [p]) ?  ibuffer_warps_control_Signals_wvd_i              [p*1+:1]                                                            :'b0;
       assign  arbiter_warps_control_Signals_fence               [p*1+:1]                                                                     = (ibuffer2issue_in_fire [p]) ?  ibuffer_warps_control_Signals_fence_i            [p*1+:1]                                                            :'b0;
       assign  arbiter_warps_control_Signals_sfu                 [p*1+:1]                                                                     = (ibuffer2issue_in_fire [p]) ?  ibuffer_warps_control_Signals_sfu_i              [p*1+:1]                                                            :'b0;
       assign  arbiter_warps_control_Signals_readmask            [p*1+:1]                                                                     = (ibuffer2issue_in_fire [p]) ?  ibuffer_warps_control_Signals_readmask_i         [p*1+:1]                                                            :'b0;
       //assign  arbiter_warps_control_Signals_writemask           [p*1+:1]                                                                     = (ibuffer2issue_in_fire [p]) ?  ibuffer_warps_control_Signals_writemask_i        [p*1+:1]                                                            :'b0;
       assign  arbiter_warps_control_Signals_wxd                 [p*1+:1]                                                                     = (ibuffer2issue_in_fire [p]) ?  ibuffer_warps_control_Signals_wxd_i              [p*1+:1]                                                            :'b0;
       assign  arbiter_warps_control_Signals_pc                  [p*`INSTLEN+:`INSTLEN]                                                       = (ibuffer2issue_in_fire [p]) ?  ibuffer_warps_control_Signals_pc_i               [p*`INSTLEN+:`INSTLEN]                                              :'b0;
       assign  arbiter_warps_control_Signals_imm_ext             [p*6+:6]                                                                     = (ibuffer2issue_in_fire [p]) ?  ibuffer_warps_control_Signals_imm_ext_i          [p*6+:6]                                                            :'b0;
       assign  arbiter_warps_control_Signals_atomic              [p*1+:1]                                                                     = (ibuffer2issue_in_fire [p]) ?  ibuffer_warps_control_Signals_atomic_i           [p*1+:1]                                                            :'b0;
       assign  arbiter_warps_control_Signals_aq                  [p*1+:1]                                                                     = (ibuffer2issue_in_fire [p]) ?  ibuffer_warps_control_Signals_aq_i               [p*1+:1]                                                            :'b0;
       assign  arbiter_warps_control_Signals_rl                  [p*1+:1]                                                                     = (ibuffer2issue_in_fire [p]) ?  ibuffer_warps_control_Signals_rl_i               [p*1+:1]                                                            :'b0;
	   assign  arbiter_warps_control_Signals_rm					           [p*3+:3]																	                                    = (ibuffer2issue_in_fire [p]) ?  ibuffer_warps_control_Signals_rm_i    			      [p*3+:3]															                              :'b0;
	   assign  arbiter_warps_control_Signals_rm_is_static      	   [p*1+:1]																	                                    = (ibuffer2issue_in_fire [p]) ?  ibuffer_warps_control_Signals_rm_is_static_i 	  [p*1+:1]															                              :'b0;
    end
  endgenerate
  
  assign  ibuffer2issue_warps_control_Signals_inst_o           =(grant!=8'h00  && ibuffer2issue_out_fire)?  arbiter_warps_control_Signals_inst             [grant_bin*`INSTLEN+:`INSTLEN]                                                      :    0;
  assign  ibuffer2issue_warps_control_Signals_wid_o            =(grant!=8'h00  && ibuffer2issue_out_fire)?  arbiter_warps_control_Signals_wid              [grant_bin*`DEPTH_WARP+:`DEPTH_WARP]                                                :    0;
  assign  ibuffer2issue_warps_control_Signals_fp_o             =(grant!=8'h00  && ibuffer2issue_out_fire)?  arbiter_warps_control_Signals_fp               [grant_bin+:1]                                                                      :    0;
  assign  ibuffer2issue_warps_control_Signals_branch_o         =(grant!=8'h00  && ibuffer2issue_out_fire)?  arbiter_warps_control_Signals_branch           [grant_bin*2+:2]                                                                    :    0;
  assign  ibuffer2issue_warps_control_Signals_simt_stack_o     =(grant!=8'h00  && ibuffer2issue_out_fire)?  arbiter_warps_control_Signals_simt_stack       [grant_bin*1+:1]                                                                    :    0;
  assign  ibuffer2issue_warps_control_Signals_simt_stack_op_o  =(grant!=8'h00  && ibuffer2issue_out_fire)?  arbiter_warps_control_Signals_simt_stack_op    [grant_bin*1+:1]                                                                    :    0;
  assign  ibuffer2issue_warps_control_Signals_barrier_o        =(grant!=8'h00  && ibuffer2issue_out_fire)?  arbiter_warps_control_Signals_barrier          [grant_bin*1+:1]                                                                    :    0;
  assign  ibuffer2issue_warps_control_Signals_csr_o            =(grant!=8'h00  && ibuffer2issue_out_fire)?  arbiter_warps_control_Signals_csr              [grant_bin*2+:2]                                                                    :    0;
  assign  ibuffer2issue_warps_control_Signals_reverse_o        =(grant!=8'h00  && ibuffer2issue_out_fire)?  arbiter_warps_control_Signals_reverse          [grant_bin*1+:1]                                                                    :    0;
  assign  ibuffer2issue_warps_control_Signals_sel_alu2_o       =(grant!=8'h00  && ibuffer2issue_out_fire)?  arbiter_warps_control_Signals_sel_alu2         [grant_bin*2+:2]                                                                    :    0;
  assign  ibuffer2issue_warps_control_Signals_sel_alu1_o       =(grant!=8'h00  && ibuffer2issue_out_fire)?  arbiter_warps_control_Signals_sel_alu1         [grant_bin*2+:2]                                                                    :    0;
  assign  ibuffer2issue_warps_control_Signals_sel_alu3_o       =(grant!=8'h00  && ibuffer2issue_out_fire)?  arbiter_warps_control_Signals_sel_alu3         [grant_bin*2+:2]                                                                    :    0;
  assign  ibuffer2issue_warps_control_Signals_isvec_o          =(grant!=8'h00  && ibuffer2issue_out_fire)?  arbiter_warps_control_Signals_isvec            [grant_bin*1+:1]                                                                    :    0;
  assign  ibuffer2issue_warps_control_Signals_mask_o           =(grant!=8'h00  && ibuffer2issue_out_fire)?  arbiter_warps_control_Signals_mask             [grant_bin*1+:1]                                                                    :    0;
  assign  ibuffer2issue_warps_control_Signals_sel_imm_o        =(grant!=8'h00  && ibuffer2issue_out_fire)?  arbiter_warps_control_Signals_sel_imm          [grant_bin*4+:4]                                                                    :    0;
  assign  ibuffer2issue_warps_control_Signals_mem_whb_o        =(grant!=8'h00  && ibuffer2issue_out_fire)?  arbiter_warps_control_Signals_mem_whb          [grant_bin*2+:2]                                                                    :    0;
  assign  ibuffer2issue_warps_control_Signals_mem_unsigned_o   =(grant!=8'h00  && ibuffer2issue_out_fire)?  arbiter_warps_control_Signals_mem_unsigned     [grant_bin*1+:1]                                                                    :    0;
  assign  ibuffer2issue_warps_control_Signals_alu_fn_o         =(grant!=8'h00  && ibuffer2issue_out_fire)?  arbiter_warps_control_Signals_alu_fn           [grant_bin*6+:6]                                                                    :    0;
  assign  ibuffer2issue_warps_control_Signals_force_rm_rtz_o   =(grant!=8'h00  && ibuffer2issue_out_fire)?  arbiter_warps_control_Signals_force_rm_rtz     [grant_bin*1+:1]                                                                    :    0;
  assign  ibuffer2issue_warps_control_Signals_is_vls12_o       =(grant!=8'h00  && ibuffer2issue_out_fire)?  arbiter_warps_control_Signals_is_vls12         [grant_bin*1+:1]                                                                    :    0;
  assign  ibuffer2issue_warps_control_Signals_mem_o            =(grant!=8'h00  && ibuffer2issue_out_fire)?  arbiter_warps_control_Signals_mem              [grant_bin*1+:1]                                                                    :    0;
  assign  ibuffer2issue_warps_control_Signals_mul_o            =(grant!=8'h00  && ibuffer2issue_out_fire)?  arbiter_warps_control_Signals_mul              [grant_bin*1+:1]                                                                    :    0;
  assign  ibuffer2issue_warps_control_Signals_tc_o             =(grant!=8'h00  && ibuffer2issue_out_fire)?  arbiter_warps_control_Signals_tc               [grant_bin*1+:1]                                                                    :    0;
  assign  ibuffer2issue_warps_control_Signals_disable_mask_o   =(grant!=8'h00  && ibuffer2issue_out_fire)?  arbiter_warps_control_Signals_disable_mask     [grant_bin*1+:1]                                                                    :    0;
  assign  ibuffer2issue_warps_control_Signals_custom_signal_0_o=(grant!=8'h00  && ibuffer2issue_out_fire)?  arbiter_warps_control_Signals_custom_signal_0  [grant_bin*1+:1]                                                                    :    0;
  assign  ibuffer2issue_warps_control_Signals_mem_cmd_o        =(grant!=8'h00  && ibuffer2issue_out_fire)?  arbiter_warps_control_Signals_mem_cmd          [grant_bin*2+:2]                                                                    :    0;
  assign  ibuffer2issue_warps_control_Signals_mop_o            =(grant!=8'h00  && ibuffer2issue_out_fire)?  arbiter_warps_control_Signals_mop              [grant_bin*2+:2]                                                                    :    0;
  assign  ibuffer2issue_warps_control_Signals_reg_idx1_o       =(grant!=8'h00  && ibuffer2issue_out_fire)?  arbiter_warps_control_Signals_reg_idx1         [grant_bin*(`REGEXT_WIDTH + `REGIDX_WIDTH)+:(`REGEXT_WIDTH + `REGIDX_WIDTH)]        :    0;
  assign  ibuffer2issue_warps_control_Signals_reg_idx2_o       =(grant!=8'h00  && ibuffer2issue_out_fire)?  arbiter_warps_control_Signals_reg_idx2         [grant_bin*(`REGEXT_WIDTH + `REGIDX_WIDTH)+:(`REGEXT_WIDTH + `REGIDX_WIDTH)]        :    0;
  assign  ibuffer2issue_warps_control_Signals_reg_idx3_o       =(grant!=8'h00  && ibuffer2issue_out_fire)?  arbiter_warps_control_Signals_reg_idx3         [grant_bin*(`REGEXT_WIDTH + `REGIDX_WIDTH)+:(`REGEXT_WIDTH + `REGIDX_WIDTH)]        :    0;
  assign  ibuffer2issue_warps_control_Signals_reg_idxw_o       =(grant!=8'h00  && ibuffer2issue_out_fire)?  arbiter_warps_control_Signals_reg_idxw         [grant_bin*(`REGEXT_WIDTH + `REGIDX_WIDTH)+:(`REGEXT_WIDTH + `REGIDX_WIDTH)]        :    0;
  assign  ibuffer2issue_warps_control_Signals_wvd_o            =(grant!=8'h00  && ibuffer2issue_out_fire)?  arbiter_warps_control_Signals_wvd              [grant_bin*1+:1]                                                                    :    0;
  assign  ibuffer2issue_warps_control_Signals_fence_o          =(grant!=8'h00  && ibuffer2issue_out_fire)?  arbiter_warps_control_Signals_fence            [grant_bin*1+:1]                                                                    :    0;
  assign  ibuffer2issue_warps_control_Signals_sfu_o            =(grant!=8'h00  && ibuffer2issue_out_fire)?  arbiter_warps_control_Signals_sfu              [grant_bin*1+:1]                                                                    :    0;
  assign  ibuffer2issue_warps_control_Signals_readmask_o       =(grant!=8'h00  && ibuffer2issue_out_fire)?  arbiter_warps_control_Signals_readmask         [grant_bin*1+:1]                                                                    :    0;
  //assign  ibuffer2issue_warps_control_Signals_writemask_o      =(grant!=8'h00  && ibuffer2issue_out_fire)?  arbiter_warps_control_Signals_writemask        [grant_bin*1+:1]                                                                    :    0;
  assign  ibuffer2issue_warps_control_Signals_wxd_o            =(grant!=8'h00  && ibuffer2issue_out_fire)?  arbiter_warps_control_Signals_wxd              [grant_bin*1+:1]                                                                    :    0;
  assign  ibuffer2issue_warps_control_Signals_pc_o             =(grant!=8'h00  && ibuffer2issue_out_fire)?  arbiter_warps_control_Signals_pc               [grant_bin*`INSTLEN+:`INSTLEN]                                                      :    0;
  assign  ibuffer2issue_warps_control_Signals_imm_ext_o        =(grant!=8'h00  && ibuffer2issue_out_fire)?  arbiter_warps_control_Signals_imm_ext          [grant_bin*6+:6]                                                                    :    0;
  assign  ibuffer2issue_warps_control_Signals_atomic_o         =(grant!=8'h00  && ibuffer2issue_out_fire)?  arbiter_warps_control_Signals_atomic           [grant_bin*1+:1]                                                                    :    0;
  assign  ibuffer2issue_warps_control_Signals_aq_o             =(grant!=8'h00  && ibuffer2issue_out_fire)?  arbiter_warps_control_Signals_aq               [grant_bin*1+:1]                                                                    :    0;
  assign  ibuffer2issue_warps_control_Signals_rl_o             =(grant!=8'h00  && ibuffer2issue_out_fire)?  arbiter_warps_control_Signals_rl               [grant_bin*1+:1]                                                                    :    0;
  assign  ibuffer2issue_warps_control_Signals_rm_o			       =(grant!=8'h00  && ibuffer2issue_out_fire)?  arbiter_warps_control_Signals_rm			         [grant_bin*3+:3]																	                                   :    0;
  assign  ibuffer2issue_warps_control_Signals_rm_is_static_o   =(grant!=8'h00  && ibuffer2issue_out_fire)?  arbiter_warps_control_Signals_rm_is_static	   [grant_bin*1+:1]																	                                   :    0;
    //      assign  ibuffer2issue_warps_control_Signals_spike_info_o     =(grant!=8'h00  && ibuffer2issue_out_fire)?  arbiter_ibuffer_warps_control_Signals_spike_info                    [p]                       :     0;
  //assign  ibuffer2issue_out_valid_o                            = | ibuffer2issue_in_valid_i;
  assign  ibuffer2issue_out_valid_o                            = (| ibuffer2issue_in_valid_i) & ibuffer2issue_out_ready_i;
  
  
endmodule 
