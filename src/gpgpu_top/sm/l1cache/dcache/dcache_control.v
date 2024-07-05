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
// Description: classify lsu req
`timescale 1ns/1ns

module dcache_control (
  input  [2:0] opcode       ,
  input  [3:0] param        ,
  output       is_read      ,
  output       is_write     ,
  output       is_lr        ,
  output       is_sc        ,
  output       is_amo       ,
  output       is_flush     ,
  output       is_invalidate,
  output       is_wait_mshr 
);

  assign is_read       = ((opcode==3'b000) && (param==4'b0000)) ? 'd1 : 'd0;
  assign is_write      = ((opcode==3'b001) && (param==4'b0000)) ? 'd1 : 'd0;
  assign is_lr         = ((opcode==3'b000) && (param==4'b0001)) ? 'd1 : 'd0;
  assign is_sc         = ((opcode==3'b001) && (param==4'b0001)) ? 'd1 : 'd0;
  assign is_amo        = (opcode==3'b010)                                  ;
  assign is_flush      = ((opcode==3'b011) && (param==4'b0001)) ? 'd1 : 'd0;
  assign is_invalidate = ((opcode==3'b011) && (param==4'b0000)) ? 'd1 : 'd0;
  assign is_wait_mshr  = ((opcode==3'b011) && (param==4'b0010)) ? 'd1 : 'd0;

endmodule

