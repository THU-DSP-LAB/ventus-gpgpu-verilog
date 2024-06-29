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
// Description:Count the number of 1 in data_i

`timescale 1ns/1ns

module pop_cnt #(
  parameter DATA_LEN = 4,
  parameter DATA_WID = 3
  )
  (
  input  [DATA_LEN-1:0] data_i,
  output [DATA_WID-1:0] data_o 
  );
  
  reg [(DATA_LEN-1)*DATA_WID-1:0] count;

  genvar i;
  generate for(i=0;i<DATA_LEN-1;i=i+1) begin:B1
    always @(*) begin
      if(i == 0) begin
        count[DATA_WID*(i+1)-1 -: DATA_WID] = data_i[i] + data_i[i+1];
      end 
      else begin
        count[DATA_WID*(i+1)-1 -: DATA_WID] = count[DATA_WID*i-1 -: DATA_WID] + data_i[i+1];
      end 
    end 
  end 
  endgenerate

  assign data_o = count[(DATA_LEN-1)*DATA_WID-1 -: DATA_WID];

endmodule
