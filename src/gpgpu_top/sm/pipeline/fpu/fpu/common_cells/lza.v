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
// Description: Leading zero anticipation

`timescale 1ns/1ns

module lza #(
  parameter LEN = 24
)(
  input  [LEN-1:0] a ,
  input  [LEN-1:0] b ,
  output [LEN-1:0] c
);
  
  wire [LEN-1:0] p;
  wire [LEN-1:0] k;

  assign p[0] = a[0] ^ b[0]      ;
  assign k[0] = (!a[0]) & (!b[0]);
  assign c[0] = 1'b0             ;

  genvar i;
  generate for(i=1;i<LEN;i=i+1) begin: CARRY
    assign p[i] = a[i] ^ b[i]      ;
    assign k[i] = (!a[i]) & (!b[i]);
    assign c[i] = p[i] ^ (!k[i-1]) ;
  end
  endgenerate

endmodule

