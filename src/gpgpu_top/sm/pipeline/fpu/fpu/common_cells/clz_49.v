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
// Description: Count leading zeros,for 49bit

 `timescale 1ns/1ns

module clz_49(
  input     [48:0]              in,
  output    [5:0]               out
);

  wire  [48:0]          in_reverse;
  reg   [5:0]           out_reg   ;

  genvar i;
  generate for(i=0;i<49;i=i+1) begin: IN_REVERSE
    assign in_reverse[i] = in[48-i];
  end
  endgenerate

  always@(*) begin
    casez(in_reverse)
      49'b?_????_????_????_????_????_????_????_????_????_????_????_???1 : out_reg <= 0;
      49'b?_????_????_????_????_????_????_????_????_????_????_????_??10 : out_reg <= 1;
      49'b?_????_????_????_????_????_????_????_????_????_????_????_?100 : out_reg <= 2;
      49'b?_????_????_????_????_????_????_????_????_????_????_????_1000 : out_reg <= 3;
      49'b?_????_????_????_????_????_????_????_????_????_????_???1_0000 : out_reg <= 4;
      49'b?_????_????_????_????_????_????_????_????_????_????_??10_0000 : out_reg <= 5;
      49'b?_????_????_????_????_????_????_????_????_????_????_?100_0000 : out_reg <= 6;
      49'b?_????_????_????_????_????_????_????_????_????_????_1000_0000 : out_reg <= 7;
      49'b?_????_????_????_????_????_????_????_????_????_???1_0000_0000 : out_reg <= 8;
      49'b?_????_????_????_????_????_????_????_????_????_??10_0000_0000 : out_reg <= 9;
      49'b?_????_????_????_????_????_????_????_????_????_?100_0000_0000 : out_reg <= 10;
      49'b?_????_????_????_????_????_????_????_????_????_1000_0000_0000 : out_reg <= 11;
      49'b?_????_????_????_????_????_????_????_????_???1_0000_0000_0000 : out_reg <= 12;
      49'b?_????_????_????_????_????_????_????_????_??10_0000_0000_0000 : out_reg <= 13;
      49'b?_????_????_????_????_????_????_????_????_?100_0000_0000_0000 : out_reg <= 14;
      49'b?_????_????_????_????_????_????_????_????_1000_0000_0000_0000 : out_reg <= 15;
      49'b?_????_????_????_????_????_????_????_???1_0000_0000_0000_0000 : out_reg <= 16;
      49'b?_????_????_????_????_????_????_????_??10_0000_0000_0000_0000 : out_reg <= 17;
      49'b?_????_????_????_????_????_????_????_?100_0000_0000_0000_0000 : out_reg <= 18;
      49'b?_????_????_????_????_????_????_????_1000_0000_0000_0000_0000 : out_reg <= 19;
      49'b?_????_????_????_????_????_????_???1_0000_0000_0000_0000_0000 : out_reg <= 20;
      49'b?_????_????_????_????_????_????_??10_0000_0000_0000_0000_0000 : out_reg <= 21;
      49'b?_????_????_????_????_????_????_?100_0000_0000_0000_0000_0000 : out_reg <= 22;
      49'b?_????_????_????_????_????_????_1000_0000_0000_0000_0000_0000 : out_reg <= 23;
      49'b?_????_????_????_????_????_???1_0000_0000_0000_0000_0000_0000 : out_reg <= 24;
      49'b?_????_????_????_????_????_??10_0000_0000_0000_0000_0000_0000 : out_reg <= 25;
      49'b?_????_????_????_????_????_?100_0000_0000_0000_0000_0000_0000 : out_reg <= 26;
      49'b?_????_????_????_????_????_1000_0000_0000_0000_0000_0000_0000 : out_reg <= 27;
      49'b?_????_????_????_????_???1_0000_0000_0000_0000_0000_0000_0000 : out_reg <= 28;
      49'b?_????_????_????_????_??10_0000_0000_0000_0000_0000_0000_0000 : out_reg <= 29;
      49'b?_????_????_????_????_?100_0000_0000_0000_0000_0000_0000_0000 : out_reg <= 30;
      49'b?_????_????_????_????_1000_0000_0000_0000_0000_0000_0000_0000 : out_reg <= 31;
      49'b?_????_????_????_???1_0000_0000_0000_0000_0000_0000_0000_0000 : out_reg <= 32;
      49'b?_????_????_????_??10_0000_0000_0000_0000_0000_0000_0000_0000 : out_reg <= 33;
      49'b?_????_????_????_?100_0000_0000_0000_0000_0000_0000_0000_0000 : out_reg <= 34;
      49'b?_????_????_????_1000_0000_0000_0000_0000_0000_0000_0000_0000 : out_reg <= 35;
      49'b?_????_????_???1_0000_0000_0000_0000_0000_0000_0000_0000_0000 : out_reg <= 36;
      49'b?_????_????_??10_0000_0000_0000_0000_0000_0000_0000_0000_0000 : out_reg <= 37;
      49'b?_????_????_?100_0000_0000_0000_0000_0000_0000_0000_0000_0000 : out_reg <= 38;
      49'b?_????_????_1000_0000_0000_0000_0000_0000_0000_0000_0000_0000 : out_reg <= 39;
      49'b?_????_???1_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000 : out_reg <= 40;
      49'b?_????_??10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000 : out_reg <= 41;
      49'b?_????_?100_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000 : out_reg <= 42;
      49'b?_????_1000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000 : out_reg <= 43;
      49'b?_???1_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000 : out_reg <= 44;
      49'b?_??10_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000 : out_reg <= 45;
      49'b?_?100_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000 : out_reg <= 46;
      49'b?_1000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000 : out_reg <= 47;
      49'b1_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000 : out_reg <= 48;
      default                                                           : out_reg <= 0;
    endcase
  end

  assign out = out_reg;

endmodule