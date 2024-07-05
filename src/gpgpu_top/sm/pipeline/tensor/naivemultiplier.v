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

module naivemultiplier #(
  parameter LEN = 32
)(
  input              clk       ,
  input              rst_n     ,
  input              regenable ,
  input  [LEN-1:0]   a         ,
  input  [LEN-1:0]   b         ,
  output [LEN*2-1:0] result    
);

  reg [LEN-1:0] reg_a ;
  reg [LEN-1:0] reg_b ;

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      reg_a <= 'd0 ;
      reg_b <= 'd0 ;
    end
    else begin
      if(regenable) begin
        reg_a <= a ;
        reg_b <= b ;
      end
      else begin
        reg_a <= reg_a ;
        reg_b <= reg_b ;
      end
    end
  end

  assign result = reg_a * reg_b ;

endmodule

