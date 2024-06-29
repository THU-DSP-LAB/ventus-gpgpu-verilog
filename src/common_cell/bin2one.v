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

module bin2one #(
  parameter ONE_WIDTH = 4,
  parameter BIN_WIDTH = 2
  )
  (
  input  [BIN_WIDTH-1:0] bin ,
  output [ONE_WIDTH-1:0] oh
  );

  assign oh = ({{(ONE_WIDTH-1){1'b0}},1'b1}<<bin);

endmodule
