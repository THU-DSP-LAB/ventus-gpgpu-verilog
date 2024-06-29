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
// Description:Get set id
`timescale 1ns/1ns

module get_setid #(
  parameter DATA_WIDTH       = 32,
  parameter XLEN             = 32,
  parameter SETIDXBITS       = 5 ,
  parameter BLOCK_OFFSETBITS = 1 ,
  parameter WORD_OFFSETBITS  = 1 ,
  parameter BA_BITS          = 6   
  )
  (
  input  [DATA_WIDTH-1:0] data_i,
  output [SETIDXBITS-1:0] data_o
  );

  assign data_o = (DATA_WIDTH == XLEN) ? data_i[SETIDXBITS+BLOCK_OFFSETBITS+WORD_OFFSETBITS-1:BLOCK_OFFSETBITS+WORD_OFFSETBITS] : 
                  ((DATA_WIDTH == BA_BITS) ? data_i[SETIDXBITS-1:0] : {DATA_WIDTH{1'h1}});
endmodule
