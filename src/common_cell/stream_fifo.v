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
// Description:Synchronous fifo with handshake signal,fifo's depth can't be zero.

`timescale 1ns/1ns

module stream_fifo #(
  parameter DATA_WIDTH = 32,
  parameter FIFO_DEPTH = 4  //can't be zero
  )
  (
  input                   clk      ,
  input                   rst_n    ,

  output                  w_ready_o,
  input                   w_valid_i,
  input  [DATA_WIDTH-1:0] w_data_i ,
  
  output                  r_valid_o,
  input                   r_ready_i,
  output [DATA_WIDTH-1:0] r_data_o  
  );

  wire push,pop;
  wire empty,full;

  assign w_ready_o = !full ;
  assign r_valid_o = !empty;

  assign push = (w_valid_i && !full) ;
  assign pop  = (r_ready_i && !empty);

  fifo #(
    .DATA_WIDTH(DATA_WIDTH),
    .FIFO_DEPTH(FIFO_DEPTH)
    ) fifo(
    .clk     (clk     ),
    .rst_n   (rst_n   ),
    .w_en_i  (push    ),
    .r_en_i  (pop     ),
    .w_data_i(w_data_i),
    .r_data_o(r_data_o),
    .full_o  (full    ),
    .empty_o (empty   )
    );

endmodule
