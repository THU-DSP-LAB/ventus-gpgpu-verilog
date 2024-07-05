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
// Description: SFU main module

`timescale 1ns/1ns

`include "define.v"
//`include "fpu_ops.v"

module sfu_exe (
  input                                     clk               ,
  input                                     rst_n             ,
  input                                     in_valid_i        ,
  output                                    in_ready_o        ,
  input   [`XLEN*`NUM_THREAD-1:0]           in_in1_i          ,
  input   [`XLEN*`NUM_THREAD-1:0]           in_in2_i          ,
  input   [`XLEN*`NUM_THREAD-1:0]           in_in3_i          ,
  input   [`NUM_THREAD-1:0]                 in_mask_i         ,
  //from fifo: control signals
  //input   [`XLEN-1:0]                       in_inst_i         ,
  input   [`DEPTH_WARP-1:0]                 in_wid_i          ,
  input                                     in_fp_i           ,
  input                                     in_reverse_i      ,
  input                                     in_isvec_i        ,
  input   [5:0]                             in_alu_fn_i       ,
  //input                                     in_force_rm_rtz_i ,
  input   [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] in_reg_idxw_i     ,
  input                                     in_wvd_i          ,
  //input                                     in_sfu_i          ,
  input                                     in_wxd_i          ,
  //input                                     in_pc_i           ,
  //rm
  input   [2:0]                             in_rm_i           ,
  //out_x
  output                                    out_x_valid_o     ,
  input                                     out_x_ready_i     ,
  output [`DEPTH_WARP-1:0]                  out_x_warp_id_o   ,
  output                                    out_x_wxd_o       ,
  output [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0]  out_x_reg_idxw_o  ,
  output [`XLEN-1:0]                        out_x_wb_wxd_rd_o ,
  //out_v
  output                                    out_v_valid_o     ,
  input                                     out_v_ready_i     ,
  output [`DEPTH_WARP-1:0]                  out_v_warp_id_o   ,
  output                                    out_v_wvd_o       ,
  output [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0]  out_v_reg_idxw_o  ,
  output [`NUM_THREAD-1:0]                  out_v_wvd_mask_o  ,
  output [`XLEN*`NUM_THREAD-1:0]            out_v_wb_wvd_rd_o 
);

  
  parameter NUM_GRP   = `NUM_THREAD/`NUM_SFU;
  parameter EXPWIDTH  = 8    ;
  parameter PRECISION = 24   ;
  parameter S_IDLE    = 2'b00,
            S_BUSY    = 2'b01,
            S_FINISH  = 2'b10;

  reg [1:0] c_state,n_state;

  //data_buffer(for input)
  wire data_buffer_deq_valid;
  wire data_buffer_deq_ready;
  wire [`XLEN*`NUM_THREAD*3+`NUM_THREAD+`DEPTH_WARP+`REGIDX_WIDTH+`REGEXT_WIDTH+13:0] data_buffer_enq_bits;
  wire [`XLEN*`NUM_THREAD*3+`NUM_THREAD+`DEPTH_WARP+`REGIDX_WIDTH+`REGEXT_WIDTH+13:0] data_buffer_deq_bits;

  assign data_buffer_enq_bits = {in_in1_i     ,
                                 in_in2_i     ,
                                 in_in3_i     ,
                                 in_mask_i    ,
                                 in_wid_i     ,
                                 in_fp_i      ,
                                 in_reverse_i ,
                                 in_isvec_i   ,
                                 in_alu_fn_i  ,
                                 in_reg_idxw_i,
                                 in_wvd_i     ,
                                 in_wxd_i     ,
                                 in_rm_i      };

  stream_fifo #(
    .DATA_WIDTH (`XLEN*`NUM_THREAD*3+`NUM_THREAD+`DEPTH_WARP+`REGIDX_WIDTH+`REGEXT_WIDTH+14),
    .FIFO_DEPTH (1)
  )
  data_buffer (
    .clk       (clk                  ),
    .rst_n     (rst_n                ),
    .w_ready_o (in_ready_o           ),
    .w_valid_i (in_valid_i           ),
    .w_data_i  (data_buffer_enq_bits ),
    .r_valid_o (data_buffer_deq_valid),
    .r_ready_i (data_buffer_deq_ready),
    .r_data_o  (data_buffer_deq_bits )
  );

  wire [`XLEN*`NUM_THREAD-1:0]           data_buffer_in1     ;
  wire [`XLEN*`NUM_THREAD-1:0]           data_buffer_in2     ;
  //wire [`XLEN*`NUM_THREAD-1:0]           data_buffer_in3     ;
  wire [`NUM_THREAD-1:0]                 data_buffer_mask    ;
  wire [`DEPTH_WARP-1:0]                 data_buffer_wid     ;
  wire                                   data_buffer_fp      ;
  wire                                   data_buffer_reverse ;
  wire                                   data_buffer_isvec   ;
  wire [5:0]                             data_buffer_alu_fn  ;
  wire [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] data_buffer_reg_idxw;
  wire                                   data_buffer_wvd     ;
  wire                                   data_buffer_wxd     ;
  //wire [2:0]                             data_buffer_rm      ;

  assign data_buffer_in1      = data_buffer_deq_bits[`XLEN*`NUM_THREAD*3+`NUM_THREAD+`DEPTH_WARP+`REGIDX_WIDTH+`REGEXT_WIDTH+13:`XLEN*`NUM_THREAD*2+`NUM_THREAD+`DEPTH_WARP+`REGIDX_WIDTH+`REGEXT_WIDTH+14];
  assign data_buffer_in2      = data_buffer_deq_bits[`XLEN*`NUM_THREAD*2+`NUM_THREAD+`DEPTH_WARP+`REGIDX_WIDTH+`REGEXT_WIDTH+13:`XLEN*`NUM_THREAD+`NUM_THREAD+`DEPTH_WARP+`REGIDX_WIDTH+`REGEXT_WIDTH+14];
  //assign data_buffer_in3      = data_buffer_deq_bits[`XLEN*`NUM_THREAD+`NUM_THREAD+`DEPTH_WARP+`REGIDX_WIDTH+`REGEXT_WIDTH+13:`NUM_THREAD+`DEPTH_WARP+`REGIDX_WIDTH+`REGEXT_WIDTH+14];
  assign data_buffer_mask     = data_buffer_deq_bits[`NUM_THREAD+`DEPTH_WARP+`REGIDX_WIDTH+`REGEXT_WIDTH+13:`DEPTH_WARP+`REGIDX_WIDTH+`REGEXT_WIDTH+14];
  assign data_buffer_wid      = data_buffer_deq_bits[`DEPTH_WARP+`REGIDX_WIDTH+`REGEXT_WIDTH+13:`REGIDX_WIDTH+`REGEXT_WIDTH+14];
  assign data_buffer_fp       = data_buffer_deq_bits[`REGIDX_WIDTH+`REGEXT_WIDTH+13];
  assign data_buffer_reverse  = data_buffer_deq_bits[`REGIDX_WIDTH+`REGEXT_WIDTH+12];
  assign data_buffer_isvec    = data_buffer_deq_bits[`REGIDX_WIDTH+`REGEXT_WIDTH+11];
  assign data_buffer_alu_fn   = data_buffer_deq_bits[`REGIDX_WIDTH+`REGEXT_WIDTH+10:`REGIDX_WIDTH+`REGEXT_WIDTH+5];
  assign data_buffer_reg_idxw = data_buffer_deq_bits[`REGIDX_WIDTH+`REGEXT_WIDTH+4:5];
  assign data_buffer_wvd      = data_buffer_deq_bits[4];
  assign data_buffer_wxd      = data_buffer_deq_bits[3];
  //assign data_buffer_rm       = data_buffer_deq_bits[2:0];

  reg  [`NUM_THREAD-1:0] mask     ;
  wire [NUM_GRP-1:0]     mask_grp ;
  wire [`NUM_THREAD-1:0] next_mask;
  wire                   o_ready  ;

  genvar i;
  generate for(i=0;i<NUM_GRP;i=i+1) begin: MASK_GRP_GEN
    assign mask_grp[i] = |mask[`NUM_SFU*(i+1)-1:`NUM_SFU*i];
  end
  endgenerate

  //initialize the reg(out_data), and cat it
  reg  [`XLEN*`NUM_THREAD-1:0] out_data     ;
  wire [`XLEN*`NUM_SFU-1:0]    arb_out_cat  ;
  wire [NUM_GRP-1:0]           mask_grp_oh  ;
  wire [$clog2(NUM_GRP)-1:0]   i_cnt        ;
  wire                         sfu_out_fire ;

  wire [`XLEN-1:0]  arb_out   [0:`NUM_SFU-1];
  
  genvar k;
  generate for(k=0;k<NUM_GRP;k=k+1) begin: INIT_OUT_DATA
    always@(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        out_data[`XLEN*`NUM_SFU*(k+1)-1:`XLEN*`NUM_SFU*k] <= 'd0;
      end
      else if((c_state==S_FINISH) && o_ready) begin
        out_data[`XLEN*`NUM_SFU*(k+1)-1:`XLEN*`NUM_SFU*k] <= 'd0;
      end
      else if(c_state==S_BUSY) begin
        if(data_buffer_isvec && sfu_out_fire) begin
          if(!(|mask)) begin
            out_data[`XLEN*`NUM_SFU*(k+1)-1:`XLEN*`NUM_SFU*k] <= out_data[`XLEN*`NUM_SFU*(k+1)-1:`XLEN*`NUM_SFU*k];
          end
          else begin
            out_data[`XLEN*`NUM_SFU*(k+1)-1:`XLEN*`NUM_SFU*k] <= (k==i_cnt) ? arb_out_cat : out_data[`XLEN*`NUM_SFU*(k+1)-1:`XLEN*`NUM_SFU*k];
          end
        end
        else if(sfu_out_fire) begin
          out_data[`XLEN*`NUM_SFU*(k+1)-1:`XLEN*`NUM_SFU*k] <= (k=='d0) ? {out_data[`XLEN*`NUM_SFU*(k+1)-1 -:`XLEN],arb_out[0]} : out_data[`XLEN*`NUM_SFU*(k+1)-1:`XLEN*`NUM_SFU*k];
        end
        else begin
          out_data[`XLEN*`NUM_SFU*(k+1)-1:`XLEN*`NUM_SFU*k] <= out_data[`XLEN*`NUM_SFU*(k+1)-1:`XLEN*`NUM_SFU*k];
        end
      end
      else begin
        out_data[`XLEN*`NUM_SFU*(k+1)-1:`XLEN*`NUM_SFU*k] <= out_data[`XLEN*`NUM_SFU*(k+1)-1:`XLEN*`NUM_SFU*k];
      end
    end
  end
  endgenerate

  //wire [NUM_GRP-1:0]         mask_grp_oh;
  //wire [$clog2(NUM_GRP)-1:0] i_cnt      ;
  
  fixed_pri_arb #(
    .ARB_WIDTH (NUM_GRP)
  )
  mask_grp_pri_oh (
    .req   (mask_grp   ),
    .grant (mask_grp_oh)
  );

  one2bin #(
    .ONE_WIDTH (NUM_GRP        ),
    .BIN_WIDTH ($clog2(NUM_GRP))
  )
  mask_grp_pri_bin (
    .oh  (mask_grp_oh),
    .bin (i_cnt      )
  );

  reg                                    i_valid   ;
  wire [`DEPTH_WARP-1:0]                 i_wid     ;
  wire                                   i_fp      ;
  wire                                   i_reverse ;
  wire                                   i_isvec   ;
  wire [5:0]                             i_alu_fn  ;
  wire [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] i_reg_idxw;
  wire                                   i_wvd     ;
  wire                                   i_wxd     ;
  wire [`XLEN*`NUM_SFU-1:0]              i_data_1  ;
  wire [`XLEN*`NUM_SFU-1:0]              i_data_2  ;
  //wire [`XLEN*`NUM_SFU-1:0]              i_data_3  ;
  //wire [`NUM_SFU-1:0]                    i_mask    ;
  wire [`XLEN*`NUM_SFU-1:0]              i_1       ;
  wire [`XLEN*`NUM_SFU-1:0]              i_2       ;

  assign i_wid      = data_buffer_wid     ;
  assign i_fp       = data_buffer_fp      ;
  assign i_reverse  = data_buffer_reverse ;
  assign i_isvec    = data_buffer_isvec   ;
  assign i_alu_fn   = data_buffer_alu_fn  ;
  assign i_reg_idxw = data_buffer_reg_idxw;
  assign i_wvd      = data_buffer_wvd     ;
  assign i_wxd      = data_buffer_wxd     ;

  assign i_1      = data_buffer_in1[`NUM_SFU*`XLEN*(i_cnt+1)-1 -:`NUM_SFU*`XLEN];
  assign i_2      = data_buffer_in2[`NUM_SFU*`XLEN*(i_cnt+1)-1 -:`NUM_SFU*`XLEN];
  assign i_data_1 = i_reverse ? i_2 : i_1                                       ;
  assign i_data_2 = i_reverse ? i_1 : i_2                                       ;
  //assign i_data_3 = data_buffer_in3[`NUM_SFU*`XLEN*(i_cnt+1)-1 -:`NUM_SFU*`XLEN];
  //assign i_mask   = mask[`NUM_SFU*(i_cnt+1)-1 -:`NUM_SFU]                       ;
  /*
  genvar j;
  generate for(j=0;j<NUM_GRP;j=j+1) begin: I_DATA
    always@(*) begin
      if(j==i_cnt) begin
        i_1      = data_buffer_in1[`NUM_SFU*`XLEN*(j+1)-1:`NUM_SFU*`XLEN*j];
        i_2      = data_buffer_in2[`NUM_SFU*`XLEN*(j+1)-1:`NUM_SFU*`XLEN*j];
        i_data_1 = i_reverse ? i_2 : i_1                                   ;
        i_data_2 = i_reverse ? i_1 : i_2                                   ;
        i_data_3 = data_buffer_in3[`NUM_SFU*`XLEN*(j+1)-1:`NUM_SFU*`XLEN*j];
        i_mask   = mask[`NUM_SFU*(j+1)-1:`NUM_SFU*j]                       ;
      end
    end
  end
  endgenerate
  */

  //int_div, float_div_sqrt, arbiter
  wire [`XLEN-1:0]    intdiv_a         [0:`NUM_SFU-1];
  wire [`XLEN-1:0]    intdiv_d         [0:`NUM_SFU-1];
  wire [`NUM_SFU-1:0] intdiv_sign_bit                ;
  wire [`NUM_SFU-1:0] intdiv_in_valid                ;
  wire [`NUM_SFU-1:0] intdiv_out_ready               ;
  wire [`NUM_SFU-1:0] intdiv_in_ready                ;
  wire [`NUM_SFU-1:0] intdiv_out_valid               ;
  wire [`XLEN-1:0]    intdiv_q         [0:`NUM_SFU-1];
  wire [`XLEN-1:0]    intdiv_r         [0:`NUM_SFU-1];

  wire [`NUM_SFU-1:0]           float_in_valid                 ;
  wire [`NUM_SFU-1:0]           float_in_ready                 ;
  wire [`NUM_SFU-1:0]           float_out_valid                ;
  wire [`NUM_SFU-1:0]           float_out_ready                ;
  wire [`NUM_SFU-1:0]           float_div_start                ;
  wire [`NUM_SFU-1:0]           float_sqrt_start               ;
  wire [`NUM_SFU-1:0]           float_ready_s0                 ;
  wire [`NUM_SFU-1:0]           float_done_s0                  ;
  wire [EXPWIDTH+PRECISION-1:0] float_in_a       [0:`NUM_SFU-1];  
  wire [EXPWIDTH+PRECISION-1:0] float_in_b       [0:`NUM_SFU-1];
  wire [2:0]                    float_in_rm      [0:`NUM_SFU-1];
  wire [EXPWIDTH+PRECISION-1:0] float_out_result [0:`NUM_SFU-1];
  //wire [4:0]                    float_out_fflags [0:`NUM_SFU-1];
  wire [EXPWIDTH+PRECISION-1:0] float_result     [0:`NUM_SFU-1];
  wire [4:0]                    float_fflags     [0:`NUM_SFU-1];

  reg  [`NUM_SFU-1:0]                      float_done_reg  ;
  reg  [(EXPWIDTH+PRECISION)*`NUM_SFU-1:0] float_result_reg;
  reg  [5*`NUM_SFU-1:0]                    float_fflags_reg;

  wire [`XLEN-1:0]    arb_in_0       [0:`NUM_SFU-1];
  wire [`XLEN-1:0]    arb_in_1       [0:`NUM_SFU-1];
  wire                arb_in_valid_0 [0:`NUM_SFU-1];
  wire                arb_in_ready_0 [0:`NUM_SFU-1];
  wire                arb_in_valid_1 [0:`NUM_SFU-1];
  wire                arb_in_ready_1 [0:`NUM_SFU-1];
  //wire [`XLEN-1:0]    arb_out        [0:`NUM_SFU-1];
  wire                arb_out_valid  [0:`NUM_SFU-1];
  wire                arb_out_ready  [0:`NUM_SFU-1];
  wire [`NUM_SFU-1:0] arb_out_valid_cat            ;
  
  //result_v, result_x
  wire                                   result_x_enq_valid;
  wire                                   result_x_enq_ready;
  wire                                   result_x_deq_valid;
  wire                                   result_x_deq_ready;
  wire [`DEPTH_WARP-1:0]                 result_x_warp_id  ;
  wire                                   result_x_wxd      ;
  wire [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] result_x_reg_idxw ;
  wire [`XLEN-1:0]                       result_x_wb_wxd_rd;
  wire [`DEPTH_WARP+`REGIDX_WIDTH+`REGEXT_WIDTH+`XLEN:0] result_x_enq_bits;
  wire [`DEPTH_WARP+`REGIDX_WIDTH+`REGEXT_WIDTH+`XLEN:0] result_x_deq_bits;

  wire                                   result_v_enq_valid;
  wire                                   result_v_enq_ready;
  wire                                   result_v_deq_valid;
  wire                                   result_v_deq_ready;
  wire [`DEPTH_WARP-1:0]                 result_v_warp_id  ;
  wire                                   result_v_wvd      ;
  wire [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] result_v_reg_idxw ;
  wire [`NUM_THREAD-1:0]                 result_v_wvd_mask ;
  wire [`XLEN*`NUM_THREAD-1:0]           result_v_wb_wvd_rd;
  wire [`DEPTH_WARP+`REGIDX_WIDTH+`REGEXT_WIDTH+`NUM_THREAD+`XLEN*`NUM_THREAD:0] result_v_enq_bits;
  wire [`DEPTH_WARP+`REGIDX_WIDTH+`REGEXT_WIDTH+`NUM_THREAD+`XLEN*`NUM_THREAD:0] result_v_deq_bits;

  wire [`XLEN-1:0] unused_reasult [0:`NUM_SFU-1];

  assign result_x_enq_bits = {i_wid               ,
                              i_wxd               ,
                              i_reg_idxw          ,
                              out_data[`XLEN-1:0]};


  assign result_v_enq_bits = {i_wid           ,
                              i_wvd           ,
                              i_reg_idxw      ,
                              data_buffer_mask,
                              out_data        };

  assign result_x_enq_valid = (c_state==S_FINISH) && i_wxd;
  assign result_x_deq_ready = out_x_ready_i               ;
  assign result_v_enq_valid = (c_state==S_FINISH) && i_wvd;
  assign result_v_deq_ready = out_v_ready_i               ;
  assign o_ready            = (i_isvec && result_v_enq_ready) || (!i_isvec && result_x_enq_ready);

  stream_fifo_pipe_true #(
    .DATA_WIDTH (`DEPTH_WARP+`REGIDX_WIDTH+`REGEXT_WIDTH+`XLEN+1),
    .FIFO_DEPTH (1)
  )
  result_x (
    .clk       (clk               ),
    .rst_n     (rst_n             ),
    .w_ready_o (result_x_enq_ready),
    .w_valid_i (result_x_enq_valid),
    .w_data_i  (result_x_enq_bits ),
    .r_valid_o (result_x_deq_valid),
    .r_ready_i (result_x_deq_ready),
    .r_data_o  (result_x_deq_bits )
  );

  stream_fifo_pipe_true #(
    .DATA_WIDTH (`DEPTH_WARP+`REGIDX_WIDTH+`REGEXT_WIDTH+`NUM_THREAD+`XLEN*`NUM_THREAD+1),
    .FIFO_DEPTH (1)
  )
  result_v (
    .clk       (clk               ),
    .rst_n     (rst_n             ),
    .w_ready_o (result_v_enq_ready),
    .w_valid_i (result_v_enq_valid),
    .w_data_i  (result_v_enq_bits ),
    .r_valid_o (result_v_deq_valid),
    .r_ready_i (result_v_deq_ready),
    .r_data_o  (result_v_deq_bits )
  );

  assign result_x_warp_id   = result_x_deq_bits[`DEPTH_WARP+`REGIDX_WIDTH+`REGEXT_WIDTH+`XLEN:`REGIDX_WIDTH+`REGEXT_WIDTH+`XLEN+1];
  assign result_x_wxd       = result_x_deq_bits[`REGIDX_WIDTH+`REGEXT_WIDTH+`XLEN];
  assign result_x_reg_idxw  = result_x_deq_bits[`REGIDX_WIDTH+`REGEXT_WIDTH+`XLEN-1:`XLEN];
  assign result_x_wb_wxd_rd = result_x_deq_bits[`XLEN-1:0];

  assign result_v_warp_id   = result_v_deq_bits[`DEPTH_WARP+`REGIDX_WIDTH+`REGEXT_WIDTH+`NUM_THREAD+`XLEN*`NUM_THREAD:`REGIDX_WIDTH+`REGEXT_WIDTH+`NUM_THREAD+`XLEN*`NUM_THREAD+1];
  assign result_v_wvd       = result_v_deq_bits[`REGIDX_WIDTH+`REGEXT_WIDTH+`NUM_THREAD+`XLEN*`NUM_THREAD];
  assign result_v_reg_idxw  = result_v_deq_bits[`REGIDX_WIDTH+`REGEXT_WIDTH+`NUM_THREAD+`XLEN*`NUM_THREAD-1:`NUM_THREAD+`XLEN*`NUM_THREAD];
  assign result_v_wvd_mask  = result_v_deq_bits[`NUM_THREAD+`XLEN*`NUM_THREAD-1:`XLEN*`NUM_THREAD];
  assign result_v_wb_wvd_rd = result_v_deq_bits[`XLEN*`NUM_THREAD-1:0];

  //module: inv_div, float_sqrt_div(`NUM_SFU)
  genvar n;
  generate for(n=0;n<`NUM_SFU;n=n+1) begin: CONNECTION
    assign arb_out_valid_cat[n] = arb_out_valid[n]                            ;
    assign arb_out_ready[n]     = &arb_out_valid_cat                          ;

    assign intdiv_a[n]          = i_data_1[`XLEN*(n+1)-1:`XLEN*n]             ;
    assign intdiv_d[n]          = i_data_2[`XLEN*(n+1)-1:`XLEN*n]             ;
    assign intdiv_sign_bit[n]   = !i_alu_fn[1]                                ;
    assign intdiv_in_valid[n]   = !i_fp && i_valid                            ;
    assign intdiv_out_ready[n]  = arb_in_ready_0[n]                           ;

    assign float_in_valid[n]    = i_fp && i_valid                             ;
    assign float_div_start[n]   = float_in_valid[n] && (i_alu_fn[2:0] == 'd0 );
    assign float_sqrt_start[n]  = float_in_valid[n] && (i_alu_fn[2:0] != 'd0) ;
    assign float_in_ready[n]    = float_ready_s0[n] && !float_done_s0[n]      ;
    assign float_out_valid[n]   = float_done_s0[n] || float_done_reg[n]       ;
    assign float_out_ready[n]   = arb_in_ready_1[n]                           ;
    assign float_in_a[n]        = i_data_1[`XLEN*(n+1)-1:`XLEN*n]             ;
    assign float_in_b[n]        = i_data_2[`XLEN*(n+1)-1:`XLEN*n]             ;
    assign float_in_rm[n]       = in_rm_i                                     ;
    assign float_out_result[n]  = float_done_s0[n] ? float_result[n] : float_result_reg[`NUM_SFU*(n+1)-1:`NUM_SFU*n];
    //assign float_out_fflags[n]  = float_done_s0[n] ? float_fflags[n] : float_fflags_reg[`NUM_SFU*(n+1)-1:`NUM_SFU*n];

    always@(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        float_done_reg[n] <= 'd0;
      end
      else begin
        if(float_out_valid[n] && float_out_ready[n]) begin
          float_done_reg[n] <= 'd0;
        end
        else begin
          float_done_reg[n] <= float_done_s0[n] || float_done_reg[n];
        end
      end
    end

    always@(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        float_result_reg[(EXPWIDTH+PRECISION)*(n+1)-1:(EXPWIDTH+PRECISION)*n] <= 'd0;
        float_fflags_reg[5*(n+1)-1:5*n] <= 'd0;
      end
      else begin
        if(float_done_s0) begin
          float_result_reg[(EXPWIDTH+PRECISION)*(n+1)-1:(EXPWIDTH+PRECISION)*n] <= float_result[n];
          float_fflags_reg[5*(n+1)-1:5*n] <= float_fflags[n];
        end
        else begin
          float_result_reg[(EXPWIDTH+PRECISION)*(n+1)-1:(EXPWIDTH+PRECISION)*n] <= float_result_reg[(EXPWIDTH+PRECISION)*(n+1)-1:(EXPWIDTH+PRECISION)*n];
          float_fflags_reg[5*(n+1)-1:5*n] <= float_fflags_reg[5*(n+1)-1:5*n];
        end
      end
    end
 
    int_div invdiv( 
      .clk         (clk                ),
      .rst_n       (rst_n              ),
      .a_i         (intdiv_a[n]        ),
      .d_i         (intdiv_d[n]        ),
      .sign_bit    (intdiv_sign_bit[n] ),
      .in_valid_i  (intdiv_in_valid[n] ),
      .out_ready_i (intdiv_out_ready[n]),
      .in_ready_o  (intdiv_in_ready[n] ),
      .out_valid_o (intdiv_out_valid[n]),
      .q_o         (intdiv_q[n]        ),
      .r_o         (intdiv_r[n]        )
    );

    div_sqrt_top_mvp flaot_div_sqrt(
      .Clk_CI           (clk                                ),
      .Rst_RBI          (rst_n                              ),
      .Div_start_SI     (float_div_start[n]                 ),
      .Sqrt_start_SI    (float_sqrt_start[n]                ),
      .Operand_a_DI     ({32'h0,float_in_a[n]}              ),
      .Operand_b_DI     ({32'h0,float_in_b[n]}              ),
      .RM_SI            (float_in_rm[n]                     ),
      .Precision_ctl_SI (6'h00                              ), //full precision
      .Format_sel_SI    (2'b00                              ), //FP32
      .Kill_SI          (1'b0                               ),
      .Result_DO        ({unused_reasult[n],float_result[n]}),
      .Fflags_SO        (float_fflags[n]                    ),
      .Ready_SO         (float_ready_s0[n]                  ),
      .Done_SO          (float_done_s0[n]                   )
    );
    
    assign arb_in_0[n]       = i_alu_fn[0] ? intdiv_r[n] : intdiv_q[n]      ;
    assign arb_in_1[n]       = float_out_result[n]                          ;
    assign arb_in_valid_0[n] = intdiv_out_valid[n]                          ;
    assign arb_in_valid_1[n] = float_out_valid[n]                           ;
    assign arb_out_valid[n]  = arb_in_valid_0[n] || arb_in_valid_1[n]       ;
    assign arb_in_ready_0[n] = arb_out_ready[n]                             ;
    assign arb_in_ready_1[n] = arb_out_ready[n] && !arb_in_valid_0[n]       ;
    assign arb_out[n]        = arb_in_valid_0[n] ? arb_in_0[n] : arb_in_1[n];
    assign arb_out_cat[`XLEN*(n+1)-1:`XLEN*n] = arb_out[n]                  ;
  end
  endgenerate

  wire i_ready         ;
  //wire sfu_out_fire    ;

  assign i_ready               = i_fp ? float_in_ready[0] : intdiv_in_ready[0];
  assign data_buffer_deq_ready = (c_state==S_FINISH) && o_ready               ;
  assign sfu_out_fire          = arb_out_valid[0] && arb_out_ready[0]         ;

  //fsm
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      c_state <= 'd0;
    end
    else begin
      c_state <= n_state;
    end
  end

  always@(*) begin
    case(c_state)
      S_IDLE  : begin
        if(in_valid_i && in_ready_o) begin
          n_state = S_BUSY;
        end
        else begin
          n_state = S_IDLE;
        end
      end
      S_BUSY  : begin
        if(data_buffer_isvec && sfu_out_fire) begin
          if(!(|next_mask)) begin
            n_state = S_FINISH;
          end
          else begin
            n_state = S_BUSY;
          end
        end
        else if(sfu_out_fire) begin
          n_state = S_FINISH;
        end
        else begin
          n_state = S_BUSY;
        end
      end
      S_FINISH: begin
        if(o_ready) begin
          n_state = S_IDLE;
        end
        else begin
          n_state = S_FINISH;
        end
      end
      default : begin
        n_state = S_IDLE;
      end
    endcase
  end

  //fsm operations
  assign next_mask = mask & {{(`NUM_THREAD-`NUM_SFU){1'b1}},{`NUM_SFU{1'b0}}} << (i_cnt*`NUM_SFU);

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      i_valid <= 'd0;
      mask    <= 'd0;
    end
    else begin
      case(c_state)
        S_IDLE  : begin
          if(in_valid_i && in_ready_o) begin
            i_valid <= 1'b1     ;
            mask    <= in_mask_i;
          end
          else begin
            i_valid <= 'd0;
            mask    <= 'd0;
          end
        end
        S_BUSY  : begin
          if(data_buffer_isvec && sfu_out_fire) begin
            if(!(|mask)) begin
              i_valid <= 'd0;
            end
            else begin
              i_valid                    <= (|next_mask) ? 1'b1 : 1'b0;
              mask                       <= next_mask                 ;
            end
          end
          else if(sfu_out_fire) begin
            i_valid     <= 'd0       ;
          end
          else if(i_valid && i_ready) begin
            i_valid <= 'd0;
          end
          else begin
            i_valid <= i_valid;
            mask    <= mask   ;
          end
        end
        default : begin
          i_valid <= i_valid;
          mask    <= mask   ;
        end
      endcase
    end
  end

  //outputs
  assign out_x_valid_o     = result_x_deq_valid;
  assign out_x_warp_id_o   = result_x_warp_id  ;
  assign out_x_wxd_o       = result_x_wxd      ;
  assign out_x_reg_idxw_o  = result_x_reg_idxw ;
  assign out_x_wb_wxd_rd_o = result_x_wb_wxd_rd;
                                                
  assign out_v_valid_o     = result_v_deq_valid;
  assign out_v_warp_id_o   = result_v_warp_id  ;
  assign out_v_wvd_o       = result_v_wvd      ;
  assign out_v_reg_idxw_o  = result_v_reg_idxw ;
  assign out_v_wvd_mask_o  = result_v_wvd_mask ;
  assign out_v_wb_wvd_rd_o = result_v_wb_wvd_rd;
                                                
endmodule

