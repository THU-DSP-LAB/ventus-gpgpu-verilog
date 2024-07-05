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
// Description:FiFO for every set of control_signals which has been decoded.

`timescale 1ns/1ns

`include "define.v"
//`include "decode_df_para.v"

module ibuffer #(
  parameter BUFFER_WIDTH = 159,// not include 1bit control_mask width, and not include 2bit control spike_info width,add rm(3bit) and rm_is_static(1bit)
  parameter SIZE_IBUFFER =2,
  parameter NUM_FETCH    =2
  )
  (
  input                                                  clk                                                    ,
  input                                                  rst_n                                                  ,
  input                                                  ibuffer_in_valid_i                                     ,
  output                                                 ibuffer_in_ready_o                                     ,
  //以下两个ibuffer_in_control_mask是和REGEXT拓展有关，并非译码而来。        
  /*  
  input                                                  ibuffer_in_control_mask_0_i                            ,
  input                                                  ibuffer_in_control_mask_1_i                            ,        //control信号的mask,功能在于抑制发射EXT类指令
 */
  input [NUM_FETCH-1:0]                                                   ibuffer_in_control_mask_i                            ,
  //以下是译码得来的控制信号
  input [NUM_FETCH*`INSTLEN-1:0]                                          ibuffer_in_control_Signals_inst_i                    ,
  input [NUM_FETCH*`DEPTH_WARP-1:0]                                       ibuffer_in_control_Signals_wid_i                     ,
  input [NUM_FETCH-1:0]                                                   ibuffer_in_control_Signals_fp_i                      ,
  input [NUM_FETCH*2-1:0]                                                 ibuffer_in_control_Signals_branch_i                  ,
  input [NUM_FETCH-1:0]                                                   ibuffer_in_control_Signals_simt_stack_i              ,
  input [NUM_FETCH-1:0]                                                   ibuffer_in_control_Signals_simt_stack_op_i           ,
  input [NUM_FETCH-1:0]                                                   ibuffer_in_control_Signals_barrier_i                 ,
  input [NUM_FETCH*2-1:0]                                                 ibuffer_in_control_Signals_csr_i                     ,
  input [NUM_FETCH-1:0]                                                   ibuffer_in_control_Signals_reverse_i                 ,
  input [NUM_FETCH*2-1:0]                                                 ibuffer_in_control_Signals_sel_alu2_i                ,
  input [NUM_FETCH*2-1:0]                                                 ibuffer_in_control_Signals_sel_alu1_i                ,
  input [NUM_FETCH*2-1:0]                                                 ibuffer_in_control_Signals_sel_alu3_i                ,
  input [NUM_FETCH-1:0]                                                   ibuffer_in_control_Signals_isvec_i                   ,
  input [NUM_FETCH-1:0]                                                   ibuffer_in_control_Signals_mask_i                    ,
  input [NUM_FETCH*4-1:0]                                                 ibuffer_in_control_Signals_sel_imm_i                 ,
  input [NUM_FETCH*2-1:0]                                                 ibuffer_in_control_Signals_mem_whb_i                 ,
  input [NUM_FETCH-1:0]                                                   ibuffer_in_control_Signals_mem_unsigned_i            ,
  input [NUM_FETCH*6-1:0]                                                 ibuffer_in_control_Signals_alu_fn_i                  ,
  input [NUM_FETCH-1:0]                                                   ibuffer_in_control_Signals_force_rm_rtz_i            ,
  input [NUM_FETCH-1:0]                                                   ibuffer_in_control_Signals_is_vls12_i                ,
  input [NUM_FETCH-1:0]                                                   ibuffer_in_control_Signals_mem_i                     ,
  input [NUM_FETCH-1:0]                                                   ibuffer_in_control_Signals_mul_i                     ,
  input [NUM_FETCH-1:0]                                                   ibuffer_in_control_Signals_tc_i                      ,
  input [NUM_FETCH-1:0]                                                   ibuffer_in_control_Signals_disable_mask_i            ,
  input [NUM_FETCH-1:0]                                                   ibuffer_in_control_Signals_custom_signal_0_i         ,
  input [NUM_FETCH*2-1:0]                                                 ibuffer_in_control_Signals_mem_cmd_i                 ,
  input [NUM_FETCH*2-1:0]                                                 ibuffer_in_control_Signals_mop_i                     ,
  input [NUM_FETCH*(`REGEXT_WIDTH + `REGIDX_WIDTH) -1:0]                  ibuffer_in_control_Signals_reg_idx1_i                ,
  input [NUM_FETCH*(`REGEXT_WIDTH + `REGIDX_WIDTH) -1:0]                  ibuffer_in_control_Signals_reg_idx2_i                ,
  input [NUM_FETCH*(`REGEXT_WIDTH + `REGIDX_WIDTH) -1:0]                  ibuffer_in_control_Signals_reg_idx3_i                ,
  input [NUM_FETCH*(`REGEXT_WIDTH + `REGIDX_WIDTH) -1:0]                  ibuffer_in_control_Signals_reg_idxw_i                ,
  input [NUM_FETCH-1:0]                                                   ibuffer_in_control_Signals_wvd_i                     ,
  input [NUM_FETCH-1:0]                                                   ibuffer_in_control_Signals_fence_i                   ,
  input [NUM_FETCH-1:0]                                                   ibuffer_in_control_Signals_sfu_i                     ,
  input [NUM_FETCH-1:0]                                                   ibuffer_in_control_Signals_readmask_i                ,
  input [NUM_FETCH-1:0]                                                   ibuffer_in_control_Signals_writemask_i               ,
  input [NUM_FETCH-1:0]                                                   ibuffer_in_control_Signals_wxd_i                     ,
  input [NUM_FETCH*`INSTLEN-1:0]                                          ibuffer_in_control_Signals_pc_i                      ,
  input [NUM_FETCH*6-1:0]                                                 ibuffer_in_control_Signals_imm_ext_i                 ,
  input [NUM_FETCH-1:0]                                                   ibuffer_in_control_Signals_atomic_i                  ,
  input [NUM_FETCH-1:0]                                                   ibuffer_in_control_Signals_aq_i                      ,
  input [NUM_FETCH-1:0]                                                   ibuffer_in_control_Signals_rl_i                      ,
  input [NUM_FETCH*3-1:0]													                        ibuffer_in_control_Signals_rm_i						           ,
  input [NUM_FETCH-1:0]													                          ibuffer_in_control_Signals_rm_is_static_i			       ,
  //input [NUM_FETCH-1:0]                                                 ibuffer_in_control_Signals_spike_info_i             ,
  //flush_wid和valid信号来自warp_sche,ibuffer根据flush_wid的valid进行flush
  input                                                  ibuffer_flush_wid_valid_i                              ,
  //useless  output                                        ibuffer_flush_wid_ready       ,
  //only ibuffer_flush_wid_valid works for flush
  input  [`DEPTH_WARP-1:0]                               ibuffer_flush_wid_i                                    ,
  
  //flag for empty or full ibuffer
  //output [`NUM_WARP-1:0]                                 ibuffer_out_valid                                      ,
  //input  [`NUM_WARP-1:0]                                 ibuffer_out_ready                                      ,
  //ibuffer_out的ready信号，是来自于ibuffre2issue //ibuffer.io.out(i).ready:=ibuffer2issue.io.in(i).ready & !scoreb(i).delay
  
  //
  //    output [`NUM_WARP-1:0]                             ibuffer_warps_control_mask_o                           ,
  //    output [`NUM_WARP-1:0]                             ibuffer_warps_control_mask_1_o                           ,
  //以下是译码得来的控制信号            
  output [`NUM_WARP*`INSTLEN-1:0]                             ibuffer_warps_control_Signals_inst_o                   ,
  output [`NUM_WARP*`DEPTH_WARP-1:0]                          ibuffer_warps_control_Signals_wid_o                    ,
  output [`NUM_WARP-1:0]                                      ibuffer_warps_control_Signals_fp_o                     ,
  output [`NUM_WARP*2-1:0]                                    ibuffer_warps_control_Signals_branch_o                 ,
  output [`NUM_WARP-1:0]                                      ibuffer_warps_control_Signals_simt_stack_o             ,
  output [`NUM_WARP-1:0]                                      ibuffer_warps_control_Signals_simt_stack_op_o          ,
  output [`NUM_WARP-1:0]                                      ibuffer_warps_control_Signals_barrier_o                ,
  output [`NUM_WARP*2-1:0]                                    ibuffer_warps_control_Signals_csr_o                    ,
  output [`NUM_WARP-1:0]                                      ibuffer_warps_control_Signals_reverse_o                ,
  output [`NUM_WARP*2-1:0]                                    ibuffer_warps_control_Signals_sel_alu2_o               ,
  output [`NUM_WARP*2-1:0]                                    ibuffer_warps_control_Signals_sel_alu1_o               ,
  output [`NUM_WARP*2-1:0]                                    ibuffer_warps_control_Signals_sel_alu3_o               ,
  output [`NUM_WARP-1:0]                                      ibuffer_warps_control_Signals_isvec_o                  ,
  output [`NUM_WARP-1:0]                                      ibuffer_warps_control_Signals_mask_o                   ,
  output [`NUM_WARP*4-1:0]                                    ibuffer_warps_control_Signals_sel_imm_o                ,
  output [`NUM_WARP*2-1:0]                                    ibuffer_warps_control_Signals_mem_whb_o                ,
  output [`NUM_WARP-1:0]                                      ibuffer_warps_control_Signals_mem_unsigned_o           ,
  output [`NUM_WARP*6-1:0]                                    ibuffer_warps_control_Signals_alu_fn_o                 ,
  output [`NUM_WARP-1:0]                                      ibuffer_warps_control_Signals_force_rm_rtz_o           ,
  output [`NUM_WARP-1:0]                                      ibuffer_warps_control_Signals_is_vls12_o               ,
  output [`NUM_WARP-1:0]                                      ibuffer_warps_control_Signals_mem_o                    ,
  output [`NUM_WARP-1:0]                                      ibuffer_warps_control_Signals_mul_o                    ,
  output [`NUM_WARP-1:0]                                      ibuffer_warps_control_Signals_tc_o                     ,
  output [`NUM_WARP-1:0]                                      ibuffer_warps_control_Signals_disable_mask_o           ,
  output [`NUM_WARP-1:0]                                      ibuffer_warps_control_Signals_custom_signal_0_o        ,
  output [`NUM_WARP*2-1:0]                                    ibuffer_warps_control_Signals_mem_cmd_o                ,
  output [`NUM_WARP*2-1:0]                                    ibuffer_warps_control_Signals_mop_o                    ,
  output [`NUM_WARP*(`REGEXT_WIDTH + `REGIDX_WIDTH)-1:0]      ibuffer_warps_control_Signals_reg_idx1_o               ,
  output [`NUM_WARP*(`REGEXT_WIDTH + `REGIDX_WIDTH)-1:0]      ibuffer_warps_control_Signals_reg_idx2_o               ,
  output [`NUM_WARP*(`REGEXT_WIDTH + `REGIDX_WIDTH)-1:0]      ibuffer_warps_control_Signals_reg_idx3_o               ,
  output [`NUM_WARP*(`REGEXT_WIDTH + `REGIDX_WIDTH)-1:0]      ibuffer_warps_control_Signals_reg_idxw_o               ,
  output [`NUM_WARP-1:0]                                      ibuffer_warps_control_Signals_wvd_o                    ,
  output [`NUM_WARP-1:0]                                      ibuffer_warps_control_Signals_fence_o                  ,
  output [`NUM_WARP-1:0]                                      ibuffer_warps_control_Signals_sfu_o                    ,
  output [`NUM_WARP-1:0]                                      ibuffer_warps_control_Signals_readmask_o               ,
  //output [`NUM_WARP-1:0]                                      ibuffer_warps_control_Signals_writemask_o              ,
  output [`NUM_WARP-1:0]                                      ibuffer_warps_control_Signals_wxd_o                    ,
  output [`NUM_WARP*`INSTLEN-1:0]                             ibuffer_warps_control_Signals_pc_o                     ,
  output [`NUM_WARP*6-1:0]                                    ibuffer_warps_control_Signals_imm_ext_o                ,
  output [`NUM_WARP-1:0]                                      ibuffer_warps_control_Signals_atomic_o                 ,
  output [`NUM_WARP-1:0]                                      ibuffer_warps_control_Signals_aq_o                     ,
  output [`NUM_WARP-1:0]                                      ibuffer_warps_control_Signals_rl_o                     ,
  output [`NUM_WARP*3-1:0]									                  ibuffer_warps_control_Signals_rm_o					           ,
  output [`NUM_WARP-1:0]									                    ibuffer_warps_control_Signals_rm_is_static_o		       ,
//  output [`NUM_WARP-1:0]                                 ibuffer_warps_control_Signals__spike_info_o            ,
                                                              
//来自ibuffer2issue和warp_sche的ready信号,和ibuffer 的读使能相关
  input  [`NUM_WARP-1:0]                                           ibuffer2issue_io_in_ready_i                       ,
  input  [`NUM_WARP-1:0]                                           warp_sche_io_warp_ready_i                         ,

//output this ready signals to other modules, decodeUnit, warp_sche
  output [`NUM_WARP-1:0]                                           ibuffer_ready_o                                   ,
//output this valid signals to other modules, show this (8)warp is not empty
  output [`NUM_WARP-1:0]                                           ibuffer_out_valid_o                               , 
//  input  [`NUM_WARP-1:0]                                           ibuffer_out_ready_i                                    
  input  [`NUM_WARP-1:0]                                           ibuffer2issue_grant_i                                    
  );
  wire io_in_fire ;
  wire [NUM_FETCH*BUFFER_WIDTH-1:0] control_signals     ;
  wire [NUM_FETCH-1:0] control_mask_signals;
  wire [`NUM_WARP-1:0] wr_en,rd_en; // 写使能信号和读使能信号
  wire  [`NUM_WARP-1:0] full; // 满标志
  wire  [`NUM_WARP-1:0] empty; // 空标志
  //reg  [`NUM_WARP-1:0] empty1;//empty hit 1 beat


  wire [`DEPTH_WARP-1:0] ibuffer_in_control_Signals_wid_0_i;
  assign ibuffer_in_control_Signals_wid_0_i = ibuffer_in_control_Signals_wid_i[`DEPTH_WARP-1:0];

  assign ibuffer_in_ready_o = ~full[ibuffer_in_control_Signals_wid_0_i]; //ready or not depends on the input wid 
  assign io_in_fire = ~ full [ibuffer_in_control_Signals_wid_0_i] && ibuffer_in_valid_i ;

  genvar i;
  generate 
    for (i=0;i<NUM_FETCH;i=i+1) begin : gen_for_ctl_signals_divided
      //assign control_signals[i*BUFFER_WIDTH+:BUFFER_WIDTH] = io_in_fire ?      //and not include 2bit control spike_info width
      assign control_signals[i*BUFFER_WIDTH+:BUFFER_WIDTH] = 
              {
                  ibuffer_in_control_Signals_inst_i                [i*`INSTLEN+:`INSTLEN]                                               ,
                  ibuffer_in_control_Signals_wid_i                 [i*`DEPTH_WARP+:`DEPTH_WARP]                                         ,
                  ibuffer_in_control_Signals_fp_i                  [i]                                                                  ,
                  ibuffer_in_control_Signals_branch_i              [i*2+:2]                                                             ,
                  ibuffer_in_control_Signals_simt_stack_i          [i]                                                                  ,
                  ibuffer_in_control_Signals_simt_stack_op_i       [i]                                                                  ,
                  ibuffer_in_control_Signals_barrier_i             [i]                                                                  ,
                  ibuffer_in_control_Signals_csr_i                 [i*2+:2]                                                             ,
                  ibuffer_in_control_Signals_reverse_i             [i]                                                                  ,
                  ibuffer_in_control_Signals_sel_alu2_i            [i*2+:2]                                                             ,
                  ibuffer_in_control_Signals_sel_alu1_i            [i*2+:2]                                                             ,
                  ibuffer_in_control_Signals_sel_alu3_i            [i*2+:2]                                                             ,
                  ibuffer_in_control_Signals_isvec_i               [i]                                                                  ,
                  ibuffer_in_control_Signals_mask_i                [i]                                                                  ,
                  ibuffer_in_control_Signals_sel_imm_i             [i*4+:4]                                                             ,
                  ibuffer_in_control_Signals_mem_whb_i             [i*2+:2]                                                             ,
                  ibuffer_in_control_Signals_mem_unsigned_i        [i]                                                                  ,
                  ibuffer_in_control_Signals_alu_fn_i              [i*6+:6]                                                             ,
                  ibuffer_in_control_Signals_force_rm_rtz_i        [i]                                                                  ,
                  ibuffer_in_control_Signals_is_vls12_i            [i]                                                                  ,
                  ibuffer_in_control_Signals_mem_i                 [i]                                                                  ,
                  ibuffer_in_control_Signals_mul_i                 [i]                                                                  ,
                  ibuffer_in_control_Signals_tc_i                  [i]                                                                  ,
                  ibuffer_in_control_Signals_disable_mask_i        [i]                                                                  ,
                  ibuffer_in_control_Signals_custom_signal_0_i     [i]                                                                  ,
                  ibuffer_in_control_Signals_mem_cmd_i             [i*2+:2]                                                             ,
                  ibuffer_in_control_Signals_mop_i                 [i*2+:2]                                                             ,
                  ibuffer_in_control_Signals_reg_idx1_i            [i*(`REGEXT_WIDTH+`REGIDX_WIDTH)+:(`REGEXT_WIDTH + `REGIDX_WIDTH)]   ,
                  ibuffer_in_control_Signals_reg_idx2_i            [i*(`REGEXT_WIDTH+`REGIDX_WIDTH)+:(`REGEXT_WIDTH + `REGIDX_WIDTH)]   ,
                  ibuffer_in_control_Signals_reg_idx3_i            [i*(`REGEXT_WIDTH+`REGIDX_WIDTH)+:(`REGEXT_WIDTH + `REGIDX_WIDTH)]   ,
                  ibuffer_in_control_Signals_reg_idxw_i            [i*(`REGEXT_WIDTH+`REGIDX_WIDTH)+:(`REGEXT_WIDTH + `REGIDX_WIDTH)]   ,
                  ibuffer_in_control_Signals_wvd_i                 [i]                                                                  ,
                  ibuffer_in_control_Signals_fence_i               [i]                                                                  ,
                  ibuffer_in_control_Signals_sfu_i                 [i]                                                                  ,
                  ibuffer_in_control_Signals_readmask_i            [i]                                                                  ,
                  ibuffer_in_control_Signals_writemask_i           [i]                                                                  ,
                  ibuffer_in_control_Signals_wxd_i                 [i]                                                                  ,
                  ibuffer_in_control_Signals_pc_i                  [i*`INSTLEN+:`INSTLEN]                                               ,
                  ibuffer_in_control_Signals_imm_ext_i             [i*6+:6]                                                             ,
                  ibuffer_in_control_Signals_atomic_i              [i]                                                                  ,
                  ibuffer_in_control_Signals_aq_i                  [i]                                                                  ,
                  ibuffer_in_control_Signals_rl_i                  [i]     																                              ,
				          ibuffer_in_control_Signals_rm_i				           [i*3+:3]																                              ,
				          ibuffer_in_control_Signals_rm_is_static_i        [i]																		
                  //ibuffer_in_control_Signals__spike_info_0_i               
              }
              /*:'b0*/;
    assign control_mask_signals[i] = /*io_in_fire ?*/ 
          {
          ibuffer_in_control_mask_i[i]
          }     /*: 'b0*/;
    end
  endgenerate

  wire  [`NUM_WARP-1:0]                         flush                         ;
  wire  [`NUM_WARP*`NUM_FETCH*BUFFER_WIDTH-1:0] slowdown_in_control_in        ;
  wire  [`NUM_WARP*`NUM_FETCH-1:0]              slowdown_in_control_mask_in   ;
  wire  [`NUM_WARP*BUFFER_WIDTH-1:0]            slowdown_out_control_signals_o;
  wire  [`NUM_WARP-1:0]                         stream_fifo_out_ready         ;
  
  assign wr_en = io_in_fire  ?  (8'b1 << ibuffer_in_control_Signals_wid_0_i ) : 'b0;
  assign rd_en = ibuffer2issue_io_in_ready_i & warp_sche_io_warp_ready_i /*& (~empty)*/ ;
  assign flush = ibuffer_flush_wid_valid_i ? (1'b1 << ibuffer_flush_wid_i  ): 'b0;
  
  genvar j; //we need num_warp ibuffer.
  generate
    for(j=0;j<`NUM_WARP;j=j+1)
      begin :ibuffer_for_every_warp_ctl_sigs
          stream_fifo_hasflush_true #(
         .DATA_WIDTH(BUFFER_WIDTH*NUM_FETCH),
         .FIFO_DEPTH(SIZE_IBUFFER)
         )
         stream_fifo_hasflush_true (
         .clk(clk),
         .rst_n(rst_n),
         .flush(flush[j]),
         .w_valid_i(wr_en[j]),
  //       .r_ready_i(rd_en[j]),
         .r_ready_i(stream_fifo_out_ready[j]),
         .w_data_i(control_signals),     // [NUM_FETCH*BUFFER_WIDTH-1:0] control_signals     ;
         .full_o(full[j]),
         .empty_o(empty[j]),
         .r_data_o(slowdown_in_control_in[(j+1)*BUFFER_WIDTH*NUM_FETCH-1-:BUFFER_WIDTH*NUM_FETCH])//slowdown_in_control[(k+1)*BUFFER_WIDTH-1-:BUFFER_WIDTH] 
        );                               // [BUFFER_WIDTH*`NUM_WARP-1:0] slowdown_in_control;
      end
  endgenerate
  
  genvar q; //we need num_warp ibuffer for control mask
  generate
    for(q=0;q<`NUM_WARP;q=q+1)
      begin :ibuffer_for_every_warp_ctl_mask_sigs
          stream_fifo_hasflush_true_no_empty_full #(
         .DATA_WIDTH(NUM_FETCH),
         .FIFO_DEPTH(SIZE_IBUFFER)
         )
         stream_fifo_hasflush_true_no_empty_full  (
         .clk                (clk                                                      ),
         .rst_n              (rst_n                                                    ),
         .flush              (flush[q]                                                 ),
         .w_valid_i          (wr_en[q]                                                 ),
   //      .r_ready_i          (rd_en[q]                                                 ),
         .r_ready_i          (stream_fifo_out_ready[q]                                 ),
         .w_data_i           (control_mask_signals                                     ),
         //.full_o           (mask_full[q]                                             ),
         //.empty_o          (mask_empty[q]                                            ),
         .r_data_o           (slowdown_in_control_mask_in[(q+1)*NUM_FETCH-1-:NUM_FETCH])
        );                               
      end
  endgenerate
  
  genvar k;
  generate
    for(k=0;k<`NUM_WARP;k=k+1)
      begin :ibuffer_in_slowdown_ctl_sigs
  slowdown #(
  .NUM_FETCH   (NUM_FETCH    ),
  .BUFFER_WIDTH(BUFFER_WIDTH )
  )slowdown_for_ibuffers_in (
  .clk                                  (clk                                                                           ),
  .rst_n                                (rst_n                                                                         ),
  .slowdown_in_control_mask_i           (slowdown_in_control_mask_in[(k+1)*NUM_FETCH-1-:NUM_FETCH]                     ),
  .slowdown_in_control_signals_i        (slowdown_in_control_in[(k+1)*BUFFER_WIDTH*NUM_FETCH-1-:BUFFER_WIDTH*NUM_FETCH]),
  .flush_i                              (flush[k]                                                                      ),
  .slowdown_out_control_signals_o       (slowdown_out_control_signals_o[k*BUFFER_WIDTH+:BUFFER_WIDTH]                  ),
  .slowdown_in_control_valid_i          (~empty[k]                                                                     ),
  .slowdown_in_control_ready_o          (stream_fifo_out_ready[k]                                                      ),
  .slowdown_out_control_ready_i         (rd_en[k]                                                                      ),
  .slowdown_out_control_valid_o         (ibuffer_out_valid_o[k]                                                        ),
  .slowdown_out_grant_i                 (ibuffer2issue_grant_i[k]                                                      )
  );
      end
  endgenerate
  
  //wire [BUFFER_WIDTH-1:0] slowdown_out_control_signals_o;
  genvar p;
    generate
      for(p=0;p<`NUM_WARP;p=p+1)
        begin:gen_for_buffer_out_all_warps                                                                                                        //wire  [`NUM_WARP*BUFFER_WIDTH-1:0]  slowdown_out_control_signals_o;
          assign   ibuffer_warps_control_Signals_inst_o               [p*`INSTLEN+:`INSTLEN]                                                  =   slowdown_out_control_signals_o [(p+1)*BUFFER_WIDTH-1  -:`INSTLEN]             ;
          assign   ibuffer_warps_control_Signals_wid_o                [p*`DEPTH_WARP+:`DEPTH_WARP]                                            =   slowdown_out_control_signals_o [(p+1)*BUFFER_WIDTH-33 -:`DEPTH_WARP]           ;
          assign   ibuffer_warps_control_Signals_fp_o                 [p+:1]                                                                  =   slowdown_out_control_signals_o [(p+1)*BUFFER_WIDTH-36 -:1]           ;
          assign   ibuffer_warps_control_Signals_branch_o             [p*2+:2]                                                                =   slowdown_out_control_signals_o [(p+1)*BUFFER_WIDTH-37 -:2]           ;
          assign   ibuffer_warps_control_Signals_simt_stack_o         [p*1+:1]                                                                =   slowdown_out_control_signals_o [(p+1)*BUFFER_WIDTH-39 -:1]           ;
          assign   ibuffer_warps_control_Signals_simt_stack_op_o      [p*1+:1]                                                                =   slowdown_out_control_signals_o [(p+1)*BUFFER_WIDTH-40 -:1]           ;
          assign   ibuffer_warps_control_Signals_barrier_o            [p*1+:1]                                                                =   slowdown_out_control_signals_o [(p+1)*BUFFER_WIDTH-41 -:1]           ;
          assign   ibuffer_warps_control_Signals_csr_o                [p*2+:2]                                                                =   slowdown_out_control_signals_o [(p+1)*BUFFER_WIDTH-42 -:2]           ;
          assign   ibuffer_warps_control_Signals_reverse_o            [p*1+:1]                                                                =   slowdown_out_control_signals_o [(p+1)*BUFFER_WIDTH-44 -:1]           ;
          assign   ibuffer_warps_control_Signals_sel_alu2_o           [p*2+:2]                                                                =   slowdown_out_control_signals_o [(p+1)*BUFFER_WIDTH-45 -:2]           ;
          assign   ibuffer_warps_control_Signals_sel_alu1_o           [p*2+:2]                                                                =   slowdown_out_control_signals_o [(p+1)*BUFFER_WIDTH-47 -:2]           ;
          assign   ibuffer_warps_control_Signals_sel_alu3_o           [p*2+:2]                                                                =   slowdown_out_control_signals_o [(p+1)*BUFFER_WIDTH-49 -:2]           ;
          assign   ibuffer_warps_control_Signals_isvec_o              [p*1+:1]                                                                =   slowdown_out_control_signals_o [(p+1)*BUFFER_WIDTH-51 -:1]           ;
          assign   ibuffer_warps_control_Signals_mask_o               [p*1+:1]                                                                =   slowdown_out_control_signals_o [(p+1)*BUFFER_WIDTH-52 -:1]           ;
          assign   ibuffer_warps_control_Signals_sel_imm_o            [p*4+:4]                                                                =   slowdown_out_control_signals_o [(p+1)*BUFFER_WIDTH-53 -:4]           ;
          assign   ibuffer_warps_control_Signals_mem_whb_o            [p*2+:2]                                                                =   slowdown_out_control_signals_o [(p+1)*BUFFER_WIDTH-57 -:2]           ;
          assign   ibuffer_warps_control_Signals_mem_unsigned_o       [p*1+:1]                                                                =   slowdown_out_control_signals_o [(p+1)*BUFFER_WIDTH-59 -:1]           ;
          assign   ibuffer_warps_control_Signals_alu_fn_o             [p*6+:6]                                                                =   slowdown_out_control_signals_o [(p+1)*BUFFER_WIDTH-60 -:6]           ;
          assign   ibuffer_warps_control_Signals_force_rm_rtz_o       [p*1+:1]                                                                =   slowdown_out_control_signals_o [(p+1)*BUFFER_WIDTH-66 -:1]           ;
          assign   ibuffer_warps_control_Signals_is_vls12_o           [p*1+:1]                                                                =   slowdown_out_control_signals_o [(p+1)*BUFFER_WIDTH-67 -:1]           ;
          assign   ibuffer_warps_control_Signals_mem_o                [p*1+:1]                                                                =   slowdown_out_control_signals_o [(p+1)*BUFFER_WIDTH-68 -:1]           ;
          assign   ibuffer_warps_control_Signals_mul_o                [p*1+:1]                                                                =   slowdown_out_control_signals_o [(p+1)*BUFFER_WIDTH-69 -:1]           ;
          assign   ibuffer_warps_control_Signals_tc_o                 [p*1+:1]                                                                =   slowdown_out_control_signals_o [(p+1)*BUFFER_WIDTH-70 -:1]           ;
          assign   ibuffer_warps_control_Signals_disable_mask_o       [p*1+:1]                                                                =   slowdown_out_control_signals_o [(p+1)*BUFFER_WIDTH-71 -:1]           ;
          assign   ibuffer_warps_control_Signals_custom_signal_0_o    [p*1+:1]                                                                =   slowdown_out_control_signals_o [(p+1)*BUFFER_WIDTH-72 -:1]           ;
          assign   ibuffer_warps_control_Signals_mem_cmd_o            [p*2+:2]                                                                =   slowdown_out_control_signals_o [(p+1)*BUFFER_WIDTH-73 -:2]           ;
          assign   ibuffer_warps_control_Signals_mop_o                [p*2+:2]                                                                =   slowdown_out_control_signals_o [(p+1)*BUFFER_WIDTH-75 -:2]           ;
          assign   ibuffer_warps_control_Signals_reg_idx1_o           [p*(`REGEXT_WIDTH + `REGIDX_WIDTH)+:(`REGEXT_WIDTH + `REGIDX_WIDTH)]    =   slowdown_out_control_signals_o [(p+1)*BUFFER_WIDTH-77 -:8]           ;
          assign   ibuffer_warps_control_Signals_reg_idx2_o           [p*(`REGEXT_WIDTH + `REGIDX_WIDTH)+:(`REGEXT_WIDTH + `REGIDX_WIDTH)]    =   slowdown_out_control_signals_o [(p+1)*BUFFER_WIDTH-85 -:8]           ;
          assign   ibuffer_warps_control_Signals_reg_idx3_o           [p*(`REGEXT_WIDTH + `REGIDX_WIDTH)+:(`REGEXT_WIDTH + `REGIDX_WIDTH)]    =   slowdown_out_control_signals_o [(p+1)*BUFFER_WIDTH-93 -:8]           ;
          assign   ibuffer_warps_control_Signals_reg_idxw_o           [p*(`REGEXT_WIDTH + `REGIDX_WIDTH)+:(`REGEXT_WIDTH + `REGIDX_WIDTH)]    =   slowdown_out_control_signals_o [(p+1)*BUFFER_WIDTH-101-:8]           ;
          assign   ibuffer_warps_control_Signals_wvd_o                [p*1+:1]                                                                =   slowdown_out_control_signals_o [(p+1)*BUFFER_WIDTH-109-:1]           ;
          assign   ibuffer_warps_control_Signals_fence_o              [p*1+:1]                                                                =   slowdown_out_control_signals_o [(p+1)*BUFFER_WIDTH-110-:1]           ;
          assign   ibuffer_warps_control_Signals_sfu_o                [p*1+:1]                                                                =   slowdown_out_control_signals_o [(p+1)*BUFFER_WIDTH-111-:1]           ;
          assign   ibuffer_warps_control_Signals_readmask_o           [p*1+:1]                                                                =   slowdown_out_control_signals_o [(p+1)*BUFFER_WIDTH-112-:1]           ;
          //assign   ibuffer_warps_control_Signals_writemask_o          [p*1+:1]                                                                =   slowdown_out_control_signals_o [(p+1)*BUFFER_WIDTH-113-:1]           ;
          assign   ibuffer_warps_control_Signals_wxd_o                [p*1+:1]                                                                =   slowdown_out_control_signals_o [(p+1)*BUFFER_WIDTH-114-:1]           ;
          assign   ibuffer_warps_control_Signals_pc_o                 [p*`INSTLEN+:`INSTLEN]                                                  =   slowdown_out_control_signals_o [(p+1)*BUFFER_WIDTH-115-:32]          ;
          assign   ibuffer_warps_control_Signals_imm_ext_o            [p*6+:6]                                                                =   slowdown_out_control_signals_o [(p+1)*BUFFER_WIDTH-147-:6]           ;
          assign   ibuffer_warps_control_Signals_atomic_o             [p*1+:1]                                                                =   slowdown_out_control_signals_o [(p+1)*BUFFER_WIDTH-153-:1]           ;
          assign   ibuffer_warps_control_Signals_aq_o                 [p*1+:1]                                                                =   slowdown_out_control_signals_o [(p+1)*BUFFER_WIDTH-154-:1]           ;
          assign   ibuffer_warps_control_Signals_rl_o                 [p*1+:1]                                                                =   slowdown_out_control_signals_o [(p+1)*BUFFER_WIDTH-155-:1]           ;
  		    assign   ibuffer_warps_control_Signals_rm_o					        [p*3+:3]																                                =   slowdown_out_control_signals_o [(p+1)*BUFFER_WIDTH-156-:3]			     ;
  		    assign   ibuffer_warps_control_Signals_rm_is_static_o		    [p*1+:1]																                                =   slowdown_out_control_signals_o [(p+1)*BUFFER_WIDTH-159-:1]			     ;
        end
      endgenerate
  
  //always @(posedge clk or negedge rst_n)
  //  begin
  //     if(!rst_n)
  //      begin
  //        empty1 <= 'b0; // 空标志
  //      end
  //      else empty1 <= empty;
  //  end
    assign   ibuffer_ready_o                                                 = ~full                                      ;
  
endmodule
