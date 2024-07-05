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
// Description:send branch information to warp_scheduler
`timescale 1ns/1ns

`include "define.v"

module branch_back (
  output                       v_ready_o   ,
  input                        v_valid_i   ,
  input      [`DEPTH_WARP-1:0] v_wid_i     ,
  input                        v_jump_i    ,
  input      [31:0]            v_new_pc_i  ,

  output                       s_ready_o   ,
  input                        s_valid_i   ,
  input      [`DEPTH_WARP-1:0] s_wid_i     ,
  input                        s_jump_i    ,
  input      [31:0]            s_new_pc_i  ,

  input                        out_ready_i ,
  output reg                   out_valid_o ,
  output reg [`DEPTH_WARP-1:0] out_wid_o   ,
  output reg                   out_jump_o  ,
  output reg [31:0]            out_new_pc_o 
  );

  assign s_ready_o = s_valid_i ? out_ready_i : 'h0;
  assign v_ready_o = s_valid_i ? 'h0 : out_ready_i;

  always @(*) begin
    if(s_valid_i) begin
      out_valid_o = s_valid_i;
      out_wid_o = s_wid_i;
      out_jump_o = s_jump_i;
      out_new_pc_o = s_new_pc_i;
    end
    else if(v_valid_i) begin
      out_valid_o = v_valid_i;
      out_wid_o = v_wid_i;
      out_jump_o = v_jump_i;
      out_new_pc_o = v_new_pc_i;
    end 
    else begin
      out_valid_o = 'h0;
      out_wid_o = 'h0;
      out_jump_o = 'h0;
      out_new_pc_o = 'h0;
    end 
  end 

endmodule
