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
// Author: Gu, Zihan
// Description:浮点数比较模块
`timescale 1ns/1ns
`include "define.v"
module fcmp_core #(
  parameter EXPWIDTH  = 8,
  parameter PRECISION = 24
)(
  input   [EXPWIDTH+PRECISION-1:0]               a_i        ,
  input   [EXPWIDTH+PRECISION-1:0]               b_i        ,
  input                                          signaling_i,
  output                                         eq_o       ,
  output                                         le_o       ,
  output                                         lt_o       ,
  output  [4:0]                                  fflags_o   
  );
  //classify
  wire  a_exp_is_zero , b_exp_is_zero  ;
  wire  a_exp_is_ones , b_exp_is_ones  ;
  wire  a_sig_is_zero , b_sig_is_zero  ;
  //wire  a_is_subnormal, b_is_subnormal ;
  //wire  a_is_inf      , b_is_inf       ;
  wire  a_is_zero     , b_is_zero      ;
  wire  a_is_nan      , b_is_nan       ;
  wire  a_is_snan     , b_is_snan      ;
  //wire  a_is_qnan     , b_is_qnan      ;
  wire  has_nan                        ;
  wire  has_snan                       ;
  wire  both_zero                      ;
  wire  same_sign                      ;

  wire  [EXPWIDTH+PRECISION:0]  a_minus_b;
  wire                          uint_eq  ;
  wire                          uint_less;
  wire                          invalid  ;

  assign a_exp_is_zero  = a_i[EXPWIDTH+PRECISION-2:PRECISION-1] == 'd0 ;
  assign b_exp_is_zero  = b_i[EXPWIDTH+PRECISION-2:PRECISION-1] == 'd0 ;
  assign a_exp_is_ones  = &a_i[EXPWIDTH+PRECISION-2:PRECISION-1]       ;
  assign b_exp_is_ones  = &b_i[EXPWIDTH+PRECISION-2:PRECISION-1]       ;
  assign a_sig_is_zero  = a_i[PRECISION-2:0] == 'd0                    ;
  assign b_sig_is_zero  = b_i[PRECISION-2:0] == 'd0                    ;
  //assign a_is_subnormal = a_exp_is_zero && !a_sig_is_zero              ;
  //assign b_is_subnormal = b_exp_is_zero && !b_sig_is_zero              ;
  //assign a_is_inf       = a_exp_is_ones && a_sig_is_zero               ;
  //assign b_is_inf       = b_exp_is_ones && b_sig_is_zero               ;
  assign a_is_zero      = a_exp_is_zero && a_sig_is_zero               ;
  assign b_is_zero      = b_exp_is_zero && b_sig_is_zero               ;
  assign a_is_nan       = a_exp_is_ones && !a_sig_is_zero              ;
  assign b_is_nan       = b_exp_is_ones && !b_sig_is_zero              ;
  assign a_is_snan      = a_is_nan && !a_i[PRECISION-2]                ;
  assign b_is_snan      = b_is_nan && !b_i[PRECISION-2]                ;
  //assign a_is_qnan      = a_is_nan && a_i[PRECISION-2]                 ;
  //assign b_is_qnan      = b_is_nan && b_i[PRECISION-2]                 ;

  assign has_nan        = a_is_nan || b_is_nan                         ;
  assign has_snan       = a_is_snan || b_is_snan                       ;
  assign both_zero      = a_is_zero && b_is_zero                       ;
  
  assign same_sign      = a_i[EXPWIDTH+PRECISION-1] == b_i[EXPWIDTH+PRECISION-1];
  assign a_minus_b      = {1'b0,a_i}-{1'b0,b_i};
  assign uint_eq        = a_minus_b[EXPWIDTH+PRECISION-1:0] == 'd0;
  assign uint_less      = a_i[EXPWIDTH+PRECISION-1] ^ a_minus_b[EXPWIDTH+PRECISION];
  assign invalid        = has_snan || (signaling_i && has_nan);//TODO signaling_i logic

  assign eq_o           = !has_nan && (uint_eq || both_zero);
  assign le_o           = !has_nan && (same_sign ? (uint_less || uint_eq) : (a_i[EXPWIDTH+PRECISION-1] || both_zero));
  assign lt_o           = !has_nan && (same_sign ? (uint_less && !uint_eq) : (a_i[EXPWIDTH+PRECISION-1] && !both_zero));
  assign fflags_o       = {invalid,4'b0000};
endmodule


  

