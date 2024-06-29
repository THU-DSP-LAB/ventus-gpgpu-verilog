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
// Description:
`timescale 1ns/1ns

module get_entry_status #(
  parameter NUM_ENTRY   = 4,
  parameter ENTRY_DEPTH = 2,
  parameter FIND_SEL    = 0
  )
  (
  input  [NUM_ENTRY-1:0]   valid_list_i,
  output                   full_o      ,
  output [ENTRY_DEPTH-1:0] next_o      
  //output [ENTRY_DEPTH:0]   used_o 
  );
  
  wire [NUM_ENTRY-1:0] valid_list_reverse;

  assign full_o = &valid_list_i;
      
  //pop_cnt #(
  //  .DATA_LEN(NUM_ENTRY)
  //  ) pop_cnt(
  //  .data_i(valid_list_i),
  //  .data_o(used_o      )
  //  ); 

  input_reverse #(
    .DATA_WIDTH(NUM_ENTRY) 
    ) input_reverse(
    .data_i(valid_list_i),
    .data_o(valid_list_reverse)
    );

  find_first #(
    .DATA_WIDTH(NUM_ENTRY  ),
    .DATA_DEPTH(ENTRY_DEPTH)
    ) find_first_zero(
    .data_i(valid_list_reverse),
    .target(FIND_SEL          ),
    .data_o(next_o            )
    );

endmodule
