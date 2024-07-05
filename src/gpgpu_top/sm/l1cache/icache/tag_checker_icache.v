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
// Description:Check whether the tag matches
`timescale 1ns/1ns

module tag_checker_icache #(
  parameter  TAG_WIDTH = 7,
  parameter  NUM_WAY   = 2, 
  parameter  WAY_DEPTH = 1 
  )
  (
  input                          r_req_valid_i  ,
  input  [NUM_WAY*TAG_WIDTH-1:0] tag_of_set_i   ,
  input  [TAG_WIDTH-1:0]         tag_from_pipe_i,
  input  [NUM_WAY-1:0]           way_valid_i    ,//whether there is valid data
  output [WAY_DEPTH-1:0]         wayid_o        ,//bin
  output                         cache_hit_o     
  );
  
  wire [NUM_WAY-1:0] wayid_oh; //wayid_one_hot
  
  genvar i;
  generate for(i=0;i<NUM_WAY;i=i+1) begin:B1
    assign wayid_oh[i] = (r_req_valid_i && (tag_of_set_i[TAG_WIDTH*(i+1)-1 -: TAG_WIDTH] == tag_from_pipe_i) && way_valid_i[i]) ? 'h1 : 'h0;
  end 
  endgenerate

  assign cache_hit_o = |wayid_oh;
  
  one2bin #(
    .ONE_WIDTH(NUM_WAY  ),
    .BIN_WIDTH(WAY_DEPTH)
    ) o2b(
    .oh (wayid_oh),
    .bin(wayid_o )
    );

endmodule
