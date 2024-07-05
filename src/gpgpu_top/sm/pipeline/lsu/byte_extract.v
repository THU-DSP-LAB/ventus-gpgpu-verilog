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
// Description: Byte selection

`timescale 1ns/1ns

module byte_extract (
  input                       is_uint ,
  input  [`BYTESOFWORD-1:0]   sel     ,
  input  [`XLEN-1:0]          in      ,
  output [`XLEN-1:0]          result
);

  reg  [`XLEN-1:0] result_tmp;
  always@(*) begin
    case(sel)
      4'hf:    result_tmp = in;
      4'hc:    result_tmp = (!in[31] || is_uint) ? {16'h0000,in[31:16]}   : {16'hffff,in[31:16]}  ;
      4'h3:    result_tmp = (!in[15] || is_uint) ? {16'h0000,in[15:0] }   : {16'hffff,in[15:0] }  ;
      4'h8:    result_tmp = (!in[31] || is_uint) ? {24'h000000,in[31:24]} : {24'hffffff,in[31:24]};
      4'h4:    result_tmp = (!in[23] || is_uint) ? {24'h000000,in[23:16]} : {24'hffffff,in[23:16]};
      4'h2:    result_tmp = (!in[15] || is_uint) ? {24'h000000,in[15:8] } : {24'hffffff,in[15:8] };
      4'h1:    result_tmp = (!in[7]  || is_uint) ? {24'h000000,in[7:0]}   : {24'hffffff,in[7:0]  };
      default: result_tmp = in;
    endcase
  end

  assign result = result_tmp ;

endmodule

