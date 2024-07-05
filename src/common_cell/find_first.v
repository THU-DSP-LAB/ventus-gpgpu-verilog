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
// Description:find first one or zero,MSB->LSB

`timescale 1ns/1ns

module find_first #(
  parameter DATA_WIDTH = 8,
  parameter DATA_DEPTH = 3
  )
  (
  input  [DATA_WIDTH-1:0] data_i,
  input                   target,//fine one or zero
  output [DATA_DEPTH-1:0] data_o    
  );

  wire [DATA_DEPTH-1:0] data_range [0:DATA_WIDTH];

  assign data_range[0] = 'h0;

  genvar i;
  generate for(i=0;i<DATA_WIDTH;i=i+1) begin:B1
    assign data_range[i+1] = (data_i[i] == target) ? DATA_WIDTH-1-i : data_range[i];
  end 
  endgenerate

  assign data_o = data_range[DATA_WIDTH];

endmodule
