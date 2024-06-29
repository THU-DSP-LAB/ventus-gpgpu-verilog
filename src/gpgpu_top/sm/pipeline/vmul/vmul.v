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
// Author: Gu, Zihan
// Description:vector multiplier
`timescale 1ns/1ns
`include "define.v"
//`include "IDecode_define.v"

module vmul #(
  parameter SOFT_THREAD = `NUM_THREAD,
  parameter HARD_THREAD = `NUM_THREAD
  )(
  input                                     clk              ,
  input                                     rst_n            ,

  input                                     in_valid_i       ,
  input                                     outx_ready_i     ,
  input                                     outv_ready_i     ,

  input   [SOFT_THREAD*`XLEN-1:0]           in1_i            ,
  input   [SOFT_THREAD*`XLEN-1:0]           in2_i            ,
  input   [SOFT_THREAD*`XLEN-1:0]           in3_i            ,
  input   [SOFT_THREAD-1:0]                 mask_i           ,
  input   [5:0]                             ctrl_alu_fn_i    ,
  input                                     ctrl_reverse_i   ,
  input   [`DEPTH_WARP-1:0]                 ctrl_wid_i       ,
  input   [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] ctrl_reg_idxw_i  ,
  input                                     ctrl_wvd_i       ,
  input                                     ctrl_wxd_i       ,

  output                                    in_ready_o       ,
  output                                    outx_valid_o     ,
  output                                    outv_valid_o     ,
  
  //scalar output
  output  [`XLEN-1:0]                       outx_wb_wxd_rd_o ,
  output                                    outx_wxd_o       ,
  output  [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] outx_reg_idwx_o  ,
  output  [`DEPTH_WARP-1:0]                 outx_warp_id_o   ,

  //vector output
  output  [SOFT_THREAD*`XLEN-1:0]           outv_wb_wxd_rd_o ,
  output  [SOFT_THREAD-1:0]                 outv_wvd_mask_o  ,
  output                                    outv_wvd_o       ,
  output  [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] outv_reg_idxw_o  ,
  output  [`DEPTH_WARP-1:0]                 outv_warp_id_o   
  );

  //result_x输入数据
  wire   [`XLEN+1+`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP-1:0]  result_x_data_in     ;
  wire   [`XLEN+1+`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP-1:0]  result_x_data_out    ;
  wire                                                          result_x_in_valid    ;
  wire                                                          result_x_in_ready    ;
  wire                                                          result_x_out_valid   ;
  wire                                                          result_x_out_ready   ;


  //result_v输入数据
  wire   [SOFT_THREAD*`XLEN+SOFT_THREAD+1+`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP-1:0] result_v_data_in     ;
  wire   [SOFT_THREAD*`XLEN+SOFT_THREAD+1+`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP-1:0] result_v_data_out    ;
  wire                                                                                 result_v_in_valid    ;
  wire                                                                                 result_v_in_ready    ;
  wire                                                                                 result_v_out_valid   ;
  wire                                                                                 result_v_out_ready   ;

  //mul端口
  wire   [`XLEN-1:0]                          mul_in1         [0:SOFT_THREAD-1];
  wire   [`XLEN-1:0]                          mul_in2         [0:SOFT_THREAD-1];
  wire   [`XLEN-1:0]                          mul_in3         [0:SOFT_THREAD-1];
  wire   [`XLEN-1:0]                          mul_result      [0:SOFT_THREAD-1];
  wire                                        mul_out_ready   [0:SOFT_THREAD-1];
  wire                                        mul_out_valid   [0:SOFT_THREAD-1];
  wire                                        mul_in_ready    [0:SOFT_THREAD-1];
  wire   [SOFT_THREAD-1:0]                    mul_out_mask    [0:SOFT_THREAD-1];
  wire   [5:0]                                mul_out_alu_fn  [0:SOFT_THREAD-1];
  wire   [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0]    mul_out_reg_idxw[0:SOFT_THREAD-1];
  wire   [`DEPTH_WARP-1:0]                    mul_out_wid     [0:SOFT_THREAD-1];
  wire                                        mul_out_wvd     [0:SOFT_THREAD-1];
  wire                                        mul_out_wxd     [0:SOFT_THREAD-1];
  wire   [SOFT_THREAD*`XLEN-1:0]              wb_wvd_rd_comb                   ;
  
  genvar i;
  generate
    for(i=0;i<HARD_THREAD;i=i+1) begin : A1
      array_multiplier U_mul(
                        .clk            (clk                ),   
                        .rst_n          (rst_n              ), 
                                                         
                        .mask_i         (mask_i             ), 
                        .a_i            (mul_in1[i]         ), 
                        .b_i            (mul_in2[i]         ), 
                        .c_i            (mul_in3[i]         ), 
                        .ctrl_alu_fn_i  (ctrl_alu_fn_i      ), 
                        .ctrl_reg_idxw_i(ctrl_reg_idxw_i    ), 
                        .ctrl_wid_i     (ctrl_wid_i         ), 
                        .ctrl_wvd_i     (ctrl_wvd_i         ), 
                        .ctrl_wxd_i     (ctrl_wxd_i         ), 
                                                         
                        .in_valid_i     (in_valid_i         ), 
                        .out_ready_i    (mul_out_ready[i]   ), 
                                                         
                        .in_ready_o     (mul_in_ready[i]    ), 
                        .out_valid_o    (mul_out_valid[i]   ), 
                                                         
                        .mask_o         (mul_out_mask[i]    ), 
                        .ctrl_alu_fn_o  (mul_out_alu_fn[i]  ), 
                        .ctrl_reg_idxw_o(mul_out_reg_idxw[i]), 
                        .ctrl_wid_o     (mul_out_wid[i]     ), 
                        .ctrl_wvd_o     (mul_out_wvd[i]     ), 
                        .ctrl_wxd_o     (mul_out_wxd[i]     ), 
                        .result_o       (mul_result[i]      )
                        );
      
      assign mul_in1[i] = ctrl_reverse_i ? in2_i[(i+1)*`XLEN-1-:`XLEN] : in1_i[(i+1)*`XLEN-1-:`XLEN];
      assign mul_in2[i] = ctrl_reverse_i ? in1_i[(i+1)*`XLEN-1-:`XLEN] : in2_i[(i+1)*`XLEN-1-:`XLEN];
      assign mul_in3[i] = in3_i[(i+1)*`XLEN-1-:`XLEN];
      assign mul_out_ready[i] = mul_out_wxd[i] ? result_x_in_ready : result_v_in_ready;
      assign wb_wvd_rd_comb[(i+1)*`XLEN-1-:`XLEN] = mul_result[i];
    end
  endgenerate

  stream_fifo_pipe_true #(.DATA_WIDTH(`XLEN+1+`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP),
                          .FIFO_DEPTH(1)
    ) U_result_x(
              .clk        (clk               ),
              .rst_n      (rst_n             ),
              .w_valid_i  (result_x_in_valid ),
              .w_data_i   (result_x_data_in  ),
              .r_ready_i  (result_x_out_ready),

              .w_ready_o  (result_x_in_ready ),
              .r_data_o   (result_x_data_out ),
              .r_valid_o  (result_x_out_valid)
            );

  stream_fifo_pipe_true #(.DATA_WIDTH(SOFT_THREAD*`XLEN+SOFT_THREAD+1+`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP),
                          .FIFO_DEPTH(1)
    ) U_result_v(
              .clk        (clk               ),
              .rst_n      (rst_n             ),
              .w_valid_i  (result_v_in_valid ),
              .w_data_i   (result_v_data_in  ),
              .r_ready_i  (result_v_out_ready),

              .w_ready_o  (result_v_in_ready ),
              .r_data_o   (result_v_data_out ),
              .r_valid_o  (result_v_out_valid)
            );

  //result_x端口赋值
  assign  result_x_data_in   = {mul_out_wid[0],mul_out_reg_idxw[0],mul_out_wxd[0],mul_result[0]};
  assign  result_x_in_valid  = mul_out_valid[0] & mul_out_wxd[0];
  assign  result_x_out_ready = outx_ready_i;

  //result_v端口赋值
  assign  result_v_data_in   = {mul_out_wid[0],mul_out_reg_idxw[0],mul_out_wvd[0],mul_out_mask[0],wb_wvd_rd_comb};
  assign  result_v_in_valid  = mul_out_valid[0] & mul_out_wvd[0];
  assign  result_v_out_ready = outv_ready_i;

  //result_x输出拆分
  assign  outx_warp_id_o     = result_x_data_out[`XLEN+1+`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP-1-:`DEPTH_WARP];
  assign  outx_reg_idwx_o    = result_x_data_out[`XLEN+`REGIDX_WIDTH+`REGEXT_WIDTH-:`REGIDX_WIDTH+`REGEXT_WIDTH];
  assign  outx_wxd_o         = result_x_data_out[`XLEN];
  assign  outx_wb_wxd_rd_o   = result_x_data_out[`XLEN-1:0];
  assign  outx_valid_o       = result_x_out_valid;

  //result_v输出拆分
  assign  outv_warp_id_o     = result_v_data_out[SOFT_THREAD*`XLEN+SOFT_THREAD+1+`REGIDX_WIDTH+`REGEXT_WIDTH+`DEPTH_WARP-1-:`DEPTH_WARP];
  assign  outv_reg_idxw_o    = result_v_data_out[SOFT_THREAD*`XLEN+SOFT_THREAD+`REGIDX_WIDTH+`REGEXT_WIDTH-:`REGIDX_WIDTH+`REGEXT_WIDTH];
  assign  outv_wvd_o         = result_v_data_out[SOFT_THREAD*`XLEN+SOFT_THREAD];
  assign  outv_wvd_mask_o    = result_v_data_out[SOFT_THREAD*`XLEN+SOFT_THREAD-1-:SOFT_THREAD];
  assign  outv_wb_wxd_rd_o   = result_v_data_out[SOFT_THREAD*`XLEN-1:0];
  assign  outv_valid_o       = result_v_out_valid;

  assign  in_ready_o         = mul_in_ready[0];

endmodule
