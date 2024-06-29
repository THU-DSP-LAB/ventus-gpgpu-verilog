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
// Description: Right shift module

`timescale 1ns/1ns

module shift_right_jam #(
  parameter LEN = 24,
  parameter EXP = 8
)(
  input  [LEN-1:0] in    ,
  input  [EXP-1:0] shamt ,
  output [LEN-1:0] out   ,
  output           sticky
);
  
  wire           exceed_max_shift;
  wire [LEN-1:0] shamt_shift     ;
  wire [LEN-1:0] sticy_mask      ;

  wire [$clog2(LEN+1)-1:0] shamt_real;
  assign shamt_real = shamt[$clog2(LEN+1)-1:0];

  assign exceed_max_shift = shamt > LEN                          ;
  //assign shamt_shift      = (1'b1 << shamt) - 1                  ;
  //assign sticy_mask       = shamt_shift | {LEN{exceed_max_shift}};
  assign sticy_mask       = exceed_max_shift ? {LEN{1'b1}} : ((1'b1 << shamt_real)-1);
  assign out              = exceed_max_shift ? 'd0 : (in>>shamt) ;
  assign sticky           = |(in & sticy_mask)                   ;

endmodule

