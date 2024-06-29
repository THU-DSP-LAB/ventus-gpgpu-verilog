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
// Description: Connect lsu and write_back

`timescale 1ns/1ns

`include "define.v"
//`include "IDecode_define.v"

module lsu2wb (
  //lsu rsp: isvec, unsigned, wordoffset1h(unused)
  input                                    lsu_rsp_valid_i        ,
  output                                   lsu_rsp_ready_o        ,
  input  [`DEPTH_WARP-1:0]                 lsu_rsp_warp_id_i      ,
  input                                    lsu_rsp_wfd_i          ,
  input                                    lsu_rsp_wxd_i          ,
  //input                                    lsu_rsp_isvec_i        ,
  input  [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] lsu_rsp_reg_idxw_i     ,
  input  [`NUM_THREAD-1:0]                 lsu_rsp_mask_i         ,
  //input                                    lsu_rsp_unsigned_i     ,
  //input  [`BYTESOFWORD*`NUM_THREAD-1:0]    lsu_rsp_wordoffset1h_i ,
  input                                    lsu_rsp_iswrite_i      ,
  input  [`XLEN*`NUM_THREAD-1:0]           lsu_rsp_data_i         ,

  //out_x
  output                                   out_x_valid_o          ,
  input                                    out_x_ready_i          ,
  output [`DEPTH_WARP-1:0]                 out_x_warp_id_o        ,
  output                                   out_x_wxd_o            ,
  output [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] out_x_reg_idxw_o       ,
  output [`XLEN-1:0]                       out_x_wb_wxd_rd_o      ,

  //out_v
  output                                   out_v_valid_o          ,
  input                                    out_v_ready_i          ,
  output [`DEPTH_WARP-1:0]                 out_v_warp_id_o        ,
  output                                   out_v_wvd_o            ,
  output [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] out_v_reg_idxw_o       ,
  output [`NUM_THREAD-1:0]                 out_v_wvd_mask_o       ,
  output [`XLEN*`NUM_THREAD-1:0]           out_v_wb_wvd_rd_o      
);

  //connect bits
  assign out_x_warp_id_o   = lsu_rsp_warp_id_i         ;
  assign out_x_wxd_o       = lsu_rsp_wxd_i             ;
  assign out_x_reg_idxw_o  = lsu_rsp_reg_idxw_i        ;
  assign out_x_wb_wxd_rd_o = lsu_rsp_data_i[`XLEN-1:0] ;
  assign out_v_warp_id_o   = lsu_rsp_warp_id_i         ;
  assign out_v_wvd_o       = lsu_rsp_wfd_i             ;
  assign out_v_reg_idxw_o  = lsu_rsp_reg_idxw_i        ;
  assign out_v_wvd_mask_o  = lsu_rsp_mask_i            ;
  assign out_v_wb_wvd_rd_o = lsu_rsp_data_i            ;

  //output valid and ready
  reg out_x_valid   ;
  reg out_v_valid   ;
  reg lsu_rsp_ready ;

  always@(*) begin
    if(lsu_rsp_wxd_i) begin
      out_x_valid   = lsu_rsp_valid_i  ;
      out_v_valid   = 'b0              ;
      lsu_rsp_ready = out_x_ready_i    ;
    end
    else if(lsu_rsp_wfd_i) begin
      out_x_valid   = 'b0              ;
      out_v_valid   = lsu_rsp_valid_i  ;
      lsu_rsp_ready = out_v_ready_i    ;
    end
    else begin
      out_x_valid   = 'b0              ;
      out_v_valid   = 'b0              ;
      lsu_rsp_ready = 1'b1             ;//lsu_rsp_iswrite_i;
    end
  end

  assign out_x_valid_o   = out_x_valid   ;
  assign out_v_valid_o   = out_v_valid   ;
  assign lsu_rsp_ready_o = lsu_rsp_ready ;

endmodule

