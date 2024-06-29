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
// Description: Connect excution units and operand collector

`timescale 1ns/1ns

`include "define.v"

module writeback #(
  parameter NUM_X = 6 ,
  parameter NUM_V = 6
  )
  (
  //input                                            clk               ,
  //input                                            rst_n             ,
  //in_x
  input  [NUM_X-1:0]                               in_x_valid_i      ,
  output [NUM_X-1:0]                               in_x_ready_o      ,
  input  [`DEPTH_WARP*NUM_X-1:0]                   in_x_warp_id_i    ,
  input  [NUM_X-1:0]                               in_x_wxd_i        ,
  input  [(`REGIDX_WIDTH+`REGEXT_WIDTH)*NUM_X-1:0] in_x_reg_idxw_i   ,
  input  [`XLEN*NUM_X-1:0]                         in_x_wb_wxd_rd_i  ,
                                                                   
  //in_v
  input  [NUM_V-1:0]                               in_v_valid_i      ,
  output [NUM_V-1:0]                               in_v_ready_o      ,
  input  [`DEPTH_WARP*NUM_V-1:0]                   in_v_warp_id_i    ,
  input  [NUM_V-1:0]                               in_v_wvd_i        ,
  input  [(`REGIDX_WIDTH+`REGEXT_WIDTH)*NUM_V-1:0] in_v_reg_idxw_i   ,
  input  [`NUM_THREAD*NUM_V-1:0]                   in_v_wvd_mask_i   ,
  input  [`XLEN*`NUM_THREAD*NUM_V-1:0]             in_v_wb_wvd_rd_i  ,

  //out_x
  output                                           out_x_valid_o     ,
  input                                            out_x_ready_i     ,
  output [`DEPTH_WARP-1:0]                         out_x_warp_id_o   ,
  output                                           out_x_wxd_o       ,
  output [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0]         out_x_reg_idxw_o  ,
  output [`XLEN-1:0]                               out_x_wb_wxd_rd_o ,
                                                                      
  //out_v
  output                                           out_v_valid_o     ,
  input                                            out_v_ready_i     ,
  output [`DEPTH_WARP-1:0]                         out_v_warp_id_o   ,
  output                                           out_v_wvd_o       ,
  output [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0]         out_v_reg_idxw_o  ,
  output [`NUM_THREAD-1:0]                         out_v_wvd_mask_o  ,
  output [`XLEN*`NUM_THREAD-1:0]                   out_v_wb_wvd_rd_o 
);

  //wire [NUM_X-1:0]         choose_x_oh  ;
  //wire [NUM_V-1:0]         choose_v_oh  ;
  wire [$clog2(NUM_X)-1:0] choose_x_bin ;
  wire [$clog2(NUM_V)-1:0] choose_v_bin ;

  wire x_zero;
  wire v_zero;

  /*
  fixed_pri_arb #(
    .ARB_WIDTH (NUM_X)
  )
  arbiter_x (
    .req   (in_x_valid_i),
    .grant (choose_x_oh )
  );

  fixed_pri_arb #(
    .ARB_WIDTH (NUM_X)
  )
  arbiter_v (
    .req   (in_v_valid_i),
    .grant (choose_v_oh )
  );

  one2bin #(
    .ONE_WIDTH (NUM_X       ),
    .BIN_WIDTH ($clog2(NUM_X))
  )
  x_bin (
    .oh  (choose_x_oh ),
    .bin (choose_x_bin)
  );

  one2bin #(
    .ONE_WIDTH (NUM_V       ),
    .BIN_WIDTH ($clog2(NUM_V))
  )
  v_bin (
    .oh  (choose_v_oh ),
    .bin (choose_v_bin)
  );
  */

  lzc #(
    .WIDTH     (NUM_X        ),
    .MODE      (1'b0         ),
    .CNT_WIDTH ($clog2(NUM_X))
  )
  x_bin (
    .in_i    (in_x_valid_i),
    .cnt_o   (choose_x_bin),
    .empty_o (x_zero      )
  );

  lzc #(
    .WIDTH     (NUM_V        ),
    .MODE      (1'b0         ),
    .CNT_WIDTH ($clog2(NUM_V))
  )
  y_bin (
    .in_i    (in_v_valid_i),
    .cnt_o   (choose_v_bin),
    .empty_o (v_zero      )
  );

  //handle in_ready out_valid
  assign in_x_ready_o[0] = out_x_ready_i;
  assign in_v_ready_o[0] = out_v_ready_i;

  genvar i;
  generate for(i=1;i<NUM_X;i=i+1) begin: IN_READY_X
    assign in_x_ready_o[i] = (in_x_valid_i[i-1:0] == 'b0) && out_x_ready_i;
  end
  endgenerate

  genvar j;
  generate for(j=1;j<NUM_V;j=j+1) begin: IN_READY_V
    assign in_v_ready_o[j] = (in_v_valid_i[j-1:0] == 'b0) && out_v_ready_i;
  end
  endgenerate

  assign out_x_valid_o = |in_x_valid_i;
  assign out_v_valid_o = |in_v_valid_i;

  //handle output bits
  wire [`DEPTH_WARP-1:0]                   in_x_warp_id    [0:NUM_X-1] ;
  wire [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0]   in_x_reg_idxw   [0:NUM_X-1] ;
  wire [`XLEN-1:0]                         in_x_wb_wxd_rd  [0:NUM_X-1] ;
  wire [`DEPTH_WARP-1:0]                   in_v_warp_id    [0:NUM_V-1] ;
  wire [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0]   in_v_reg_idxw   [0:NUM_V-1] ;
  wire [`NUM_THREAD-1:0]                   in_v_wvd_mask   [0:NUM_V-1] ;
  wire [`XLEN*`NUM_THREAD-1:0]             in_v_wb_wvd_rd  [0:NUM_V-1] ;

  genvar n;
  generate for(n=0;n<NUM_X;n=n+1) begin: IN_BITS_X
    assign in_x_warp_id[n]   = in_x_warp_id_i[`DEPTH_WARP*(n+1)-1:`DEPTH_WARP*n]                                     ;
    assign in_x_reg_idxw[n]  = in_x_reg_idxw_i[(`REGIDX_WIDTH+`REGEXT_WIDTH)*(n+1)-1:(`REGIDX_WIDTH+`REGEXT_WIDTH)*n];
    assign in_x_wb_wxd_rd[n] = in_x_wb_wxd_rd_i[`XLEN*(n+1)-1:`XLEN*n]                                               ;
  end
  endgenerate

  genvar m;
  generate for(m=0;m<NUM_V;m=m+1) begin: IN_BITS_V
    assign in_v_warp_id[m]   = in_v_warp_id_i[`DEPTH_WARP*(m+1)-1:`DEPTH_WARP*m]                                     ;
    assign in_v_reg_idxw[m]  = in_v_reg_idxw_i[(`REGIDX_WIDTH+`REGEXT_WIDTH)*(m+1)-1:(`REGIDX_WIDTH+`REGEXT_WIDTH)*m];
    assign in_v_wvd_mask[m]  = in_v_wvd_mask_i[`NUM_THREAD*(m+1)-1:`NUM_THREAD*m]                                    ;
    assign in_v_wb_wvd_rd[m] = in_v_wb_wvd_rd_i[`XLEN*`NUM_THREAD*(m+1)-1:`XLEN*`NUM_THREAD*m]                       ;
  end
  endgenerate

  assign out_x_warp_id_o   = in_x_warp_id[choose_x_bin]   ;
  assign out_x_wxd_o       = in_x_wxd_i[choose_x_bin]     ;
  assign out_x_reg_idxw_o  = in_x_reg_idxw[choose_x_bin]  ;
  assign out_x_wb_wxd_rd_o = in_x_wb_wxd_rd[choose_x_bin] ;
  assign out_v_warp_id_o   = in_v_warp_id[choose_v_bin]   ;
  assign out_v_wvd_o       = in_v_wvd_i[choose_v_bin]     ;
  assign out_v_reg_idxw_o  = in_v_reg_idxw[choose_v_bin]  ;
  assign out_v_wvd_mask_o  = in_v_wvd_mask[choose_v_bin]  ;
  assign out_v_wb_wvd_rd_o = in_v_wb_wvd_rd[choose_v_bin] ;

endmodule

