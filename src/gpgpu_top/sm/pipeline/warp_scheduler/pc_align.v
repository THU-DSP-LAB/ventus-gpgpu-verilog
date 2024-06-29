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
// Description:pc alignment module
`timescale 1ns/1ns

`include "define.v"

module pc_align (
  input  [31:0]           pc_i        ,
  output [31:0]           pc_aligned_o,
  output [`NUM_FETCH-1:0] pc_mask_o   
  );

  wire [31:0] offset_mask;

  assign offset_mask = `ICACHE_ALIGN - 1; //e.g. num_fetch=2(8B align)  
                                          //     => offset_mask = 0111

  assign pc_aligned_o = pc_i & (~offset_mask);

  genvar i;
  generate for(i=0;i<`NUM_FETCH;i=i+1) begin:B1                          //e.g. num_fetch=2,pc_i=28=00011100
    assign pc_mask_o[i] = (pc_aligned_o + (i<<2) >= pc_i) ? 1'h1 : 1'h0; //     => pc_aligned_o = 24 = 00011000,
  end                                                                    //     => pc_mask_o = 10;
  endgenerate

endmodule
