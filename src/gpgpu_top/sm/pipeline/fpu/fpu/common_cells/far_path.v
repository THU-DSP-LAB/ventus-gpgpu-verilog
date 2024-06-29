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
// Description: far_path add: expdiff >= 2

`timescale 1ns/1ns

module far_path #(
  parameter EXPWIDTH  = 8,
  parameter PRECISION = 48,
  parameter OUTPC     = 24
)
(
  input                  a_sign_i     ,
  input  [EXPWIDTH-1:0]  a_exp_i      ,
  input  [PRECISION-1:0] a_sig_i      ,
  //input                  b_sign_i     ,
  //input  [EXPWIDTH-1:0]  b_exp_i      ,
  input  [PRECISION-1:0] b_sig_i      ,
  input  [EXPWIDTH-1:0]  expdiff_i    ,
  input                  effsub_i     ,
  input                  small_add_i  ,
  //input  [2:0]           rm_i         ,
  output                 result_sign_o,
  output [EXPWIDTH-1:0]  result_exp_o ,
  output [OUTPC+2:0]     result_sig_o  
);

  wire [PRECISION+1:0] sig_b_main  ;
  wire                 sig_b_sticky;

  shift_right_jam #(
    .LEN (PRECISION+2),
    .EXP (EXPWIDTH   )
  )
  sig_b (
    .in     ({b_sig_i,2'b00}),
    .shamt  (expdiff_i      ),
    .out    (sig_b_main     ),
    .sticky (sig_b_sticky   )
  );

  wire [PRECISION+3:0] addr_in_sig_a;
  wire [PRECISION+3:0] addr_in_sig_b;
  wire [PRECISION+3:0] addr_result  ;
  wire [EXPWIDTH-1:0]  exp_a_plus_1 ;
  wire [EXPWIDTH+1:0]  exp_a_minus_1;

  assign addr_in_sig_b = {1'b0,sig_b_main,sig_b_sticky}                                         ;
  assign addr_in_sig_a = {1'b0,a_sig_i,3'b000}                                                  ;
  assign addr_result   = addr_in_sig_a + (effsub_i ? ~addr_in_sig_b : addr_in_sig_b) + effsub_i ;
  assign exp_a_plus_1  = a_exp_i + 1                                                            ;
  assign exp_a_minus_1 = a_exp_i - 1                                                            ;

  wire                cout        ;
  wire                keep        ;
  wire                cancellation;
  reg  [OUTPC+2:0]    far_path_sig;
  reg  [EXPWIDTH-1:0] far_path_exp;

  assign cout         = addr_result[PRECISION+3]                      ;
  assign keep         = addr_result[PRECISION+3:PRECISION+2] == 2'b01 ;
  assign cancellation = addr_result[PRECISION+3:PRECISION+2] == 2'b00 ;

  always@(*) begin
    if(cout) begin
      far_path_sig = {addr_result[PRECISION+3:PRECISION-OUTPC+2],&addr_result[PRECISION-OUTPC+1:0]};
    end
    else if(keep || small_add_i) begin
      far_path_sig = {addr_result[PRECISION+2:PRECISION-OUTPC+1],&addr_result[PRECISION-OUTPC:0]}  ;
    end
    else if(cancellation && !small_add_i)begin
      far_path_sig = {addr_result[PRECISION+1:PRECISION-OUTPC]  ,&addr_result[PRECISION-OUTPC-1:0]};
    end
    else begin
      far_path_sig = 'd0                                                                           ;
    end
  end

  always@(*) begin
    if(cout) begin
      far_path_exp = exp_a_plus_1 ;
    end
    else if(keep) begin
      far_path_exp = a_exp_i      ;
    end
    else if(cancellation) begin
      far_path_exp = exp_a_minus_1;
    end
    else begin
      far_path_exp = 'd0          ;
    end
  end

  assign result_sign_o = a_sign_i    ;
  assign result_exp_o  = far_path_exp;
  assign result_sig_o  = far_path_sig;

endmodule

