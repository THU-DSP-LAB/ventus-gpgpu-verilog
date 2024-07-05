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

`include "define.v"

module wf_done_interface_single (
  input                     clk                 ,
  input                     rst_n               ,
  input                     wf_done_i           ,
  input  [`WG_ID_WIDTH-1:0] wf_done_wg_id_i     ,
  input                     host_wf_done_ready_i,
  output                    host_wf_done_valid_o,
  output [`WG_ID_WIDTH-1:0] host_wf_done_wg_id_o
);

  //wire buffer_w_ready_o;  

  stream_fifo #(
    .DATA_WIDTH (`WG_ID_WIDTH),
    .FIFO_DEPTH (`WG_NUM_MAX )
  )
  buffer (
    .clk       (clk                 ),
    .rst_n     (rst_n               ),
    //.w_ready_o (buffer_w_ready_o    ),
    .w_ready_o (                    ),
    .w_valid_i (wf_done_i           ),
    .w_data_i  (wf_done_wg_id_i     ),
    .r_valid_o (host_wf_done_valid_o),
    .r_ready_i (host_wf_done_ready_i),
    .r_data_o  (host_wf_done_wg_id_o)
  );

endmodule

