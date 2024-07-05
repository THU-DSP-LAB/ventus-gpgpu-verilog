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
// Description:one hot to binary module

`timescale 1ns/1ns

module one2bin #(
  parameter ONE_WIDTH = 4,
  parameter BIN_WIDTH = 2
  )
  (
  input  [ONE_WIDTH-1:0] oh ,
  output [BIN_WIDTH-1:0] bin    
  );
  
  wire [BIN_WIDTH-1:0] bin_temp1 [0:ONE_WIDTH-1];
  wire [ONE_WIDTH-1:0] bin_temp2 [0:BIN_WIDTH-1];

  genvar i,j,k;
  generate for(i=0;i<ONE_WIDTH;i=i+1) begin:B1
    assign bin_temp1[i] = oh[i] ? i : 'b0;
  end
  endgenerate

  generate for(i=0;i<ONE_WIDTH;i=i+1) begin:B2
    for(j=0;j<BIN_WIDTH;j=j+1) begin:B3
      assign bin_temp2[j][i] = bin_temp1[i][j];
    end 
  end
  endgenerate

  generate for(k=0;k<BIN_WIDTH;k=k+1) begin:B4
    assign bin[k] = |bin_temp2[k];
  end 
  endgenerate

endmodule
