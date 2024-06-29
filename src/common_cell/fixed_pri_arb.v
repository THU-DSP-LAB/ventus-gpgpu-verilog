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
// Author: Zhang, Qi
// Description:Fixed Priority Arbiter

`timescale 1ns/1ns

module fixed_pri_arb #(
  parameter ARB_WIDTH = 4
  ) 
  (
  input  [ARB_WIDTH-1:0] req  ,
  output [ARB_WIDTH-1:0] grant
  );

  wire [ARB_WIDTH-1:0] pre_req;

  assign pre_req = {(req[ARB_WIDTH-2:0] | pre_req[ARB_WIDTH-2:0]),1'h0};
  assign grant = req & (~pre_req);

endmodule
