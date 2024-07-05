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

module get_entry_status_req #(
  parameter NUM_ENTRY = 4
)(
  input  [NUM_ENTRY-1:0]         valid_list_i,
  output                         alm_full_o  ,
  output                         full_o      ,
  output [$clog2(NUM_ENTRY)-1:0] next_o      
);

  localparam ENTRY_WIDTH = $clog2(NUM_ENTRY) + 1;

  wire [ENTRY_WIDTH-1:0] used;
  wire [NUM_ENTRY-1:0]   valid_list_reverse;
  
  pop_cnt #(
    .DATA_LEN (NUM_ENTRY  ),
    .DATA_WID (ENTRY_WIDTH)
  )
  used_count (
    .data_i (valid_list_i),
    .data_o (used        )
  );

  assign alm_full_o = used == (NUM_ENTRY - 1);
  assign full_o     = &valid_list_i          ;

  input_reverse #(
    .DATA_WIDTH (NUM_ENTRY)
  )
  reverse_list (
    .data_i (valid_list_i      ),
    .data_o (valid_list_reverse)
  );

  find_first #(
    .DATA_WIDTH (NUM_ENTRY        ),
    .DATA_DEPTH ($clog2(NUM_ENTRY))
  )
  find_next (
    .data_i (valid_list_reverse),
    .target (1'b0              ),
    .data_o (next_o            )
  );

endmodule

