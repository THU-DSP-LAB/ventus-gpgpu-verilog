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
// Description: Count leading zeros

`timescale 1ns/1ns

module clz #(
  parameter LEN = 24
)(
  input  [LEN-1:0]         in,
  output [$clog2(LEN)-1:0] out
);

  wire [LEN-1:0]         in_reverse;
  wire [$clog2(LEN)-1:0] out_wire  ;

  genvar i;
  generate for(i=0;i<LEN;i=i+1) begin: IN_REVERSE
    assign in_reverse[i] = in[LEN-1-i];
  end
  endgenerate

  wire [LEN-1:0] out_oh;

  fixed_pri_arb #(
    .ARB_WIDTH (LEN)
  )
  clz_oh (
    .req    (in_reverse),
    .grant  (out_oh    )
  );

  //assign out_oh = in_reverse & (~(in_reverse - 1));

  one2bin #(
    .ONE_WIDTH (LEN        ),
    .BIN_WIDTH ($clog2(LEN))
  )
  clz_bin (
    .oh  (out_oh  ),
    .bin (out_wire)
  );

  assign out = (in=='d0) ? (LEN-1) : out_wire;
  

endmodule

