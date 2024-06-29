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
// Description:

`timescale 1ns/1ns
`include "define.v"
//`include "fpu_ops.v"

module rounding #(
  parameter WIDTH = 24
)(
  input  [WIDTH-1:0] in      ,
  input              sign    ,
  input              roundin ,
  input              stickyin,
  input  [2:0]       rm      ,
  output [WIDTH-1:0] out     ,
  output             inexact ,
  output             cout    ,
  output             r_up    
);
  
  reg rounding_up;

  always@(*) begin
    case(rm)
      `RNE    : rounding_up = ((roundin&&stickyin) || (roundin&&!stickyin&&in[0]));
      `RTZ    : rounding_up = 'd0                                                 ;
      `RUP    : rounding_up = inexact && !sign                                    ;
      `RDN    : rounding_up = inexact && sign                                     ;
      `RMM    : rounding_up = roundin                                             ;
      default : rounding_up = 'd0                                                 ;
    endcase
  end

  assign out     = rounding_up? in+1 : in ;
  assign inexact = roundin || stickyin    ;
  assign cout    = rounding_up && (&in)   ;
  assign r_up    = rounding_up            ;

endmodule

