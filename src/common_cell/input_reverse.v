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
// Description:input reverse

`timescale 1ns/1ns

module input_reverse #(
  parameter DATA_WIDTH = 8
  )
  (
  input  [DATA_WIDTH-1:0] data_i,
  output [DATA_WIDTH-1:0] data_o
  );

  genvar i;
  generate for(i=0;i<DATA_WIDTH;i=i+1) begin:B1
    assign data_o[DATA_WIDTH-1-i] = data_i[i];
  end 
  endgenerate

endmodule
