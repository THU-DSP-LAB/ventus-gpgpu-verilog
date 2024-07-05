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

module get_entry_status_rsp #(
  parameter NUM_ENTRY = 4
)(
  input  [NUM_ENTRY-1:0]         valid_list_i ,
  output [$clog2(NUM_ENTRY)-1:0] next2cancel_o,
  output [$clog2(NUM_ENTRY):0]   used_o       
);

  wire [NUM_ENTRY-1:0] valid_list_reverse;

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
    .target (1'b1              ),
    .data_o (next2cancel_o     )
  );

  pop_cnt #(
    .DATA_LEN (NUM_ENTRY          ),
    .DATA_WID ($clog2(NUM_ENTRY)+1)
  )
  used_count (
    .data_i (valid_list_i),
    .data_o (used_o      )
  );

endmodule

