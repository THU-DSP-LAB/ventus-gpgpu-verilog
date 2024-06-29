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
// Description:
`timescale 1ns/1ns
`include "define.v"
//`include "fpu_ops.v"
module fp_to_int_core #(
  parameter EXPWIDTH  = 8,
  parameter PRECISION = 24
)(
  input   [EXPWIDTH+PRECISION-1:0]        a_i     ,
  input   [2:0]                           rm_i    ,
  input   [1:0]                           op_i    ,
  output  [63:0]                          result_o,
  output  [4:0]                           fflags_o
  );

  localparam EXPBIAS = (1<<(EXPWIDTH-1))-1;
  localparam LPATH_MAX_SHAMT = 63 - (PRECISION - 1);
  localparam LPATH_MAX_SHAMT_WIDTH = $clog2(LPATH_MAX_SHAMT + 1);

  wire                                    is_signed_int  ;
  wire                                    is_long_int    ;

  wire                                    a_exp_is_zero  ;
  wire                                    a_exp_is_ones  ;
  wire                                    a_sig_is_zero  ;
  //wire                                    a_is_subnormal ;
  //wire                                    a_is_inf       ;
  //wire                                    a_is_zero      ;
  wire                                    a_is_nan       ;
  //wire                                    a_is_snan      ;
  //wire                                    a_is_qnan      ;

  wire                                    raw_a_sign     ;
  wire    [EXPWIDTH-1:0]                  raw_a_exp      ;
  wire    [PRECISION-1:0]                 raw_a_sig      ;

  wire    [EXPWIDTH-1:0]                  max_int_exp    ;
  wire                                    exp_of         ;

  //left shift path
  wire    [EXPWIDTH-1:0]                  lpath_shamt      ;
  wire    [63:0]                          lpath_sig_shifted;
  wire                                    lpath_iv         ;
  wire                                    lpath_may_of     ;
  wire                                    lpath_pos_of     ;
  wire                                    lpath_neg_of     ;
  wire                                    lpath_of         ;

  //right shift path
  wire    [EXPWIDTH-1:0]                  rpath_shamt           ;
  wire    [PRECISION:0]                   rpath_sig_shifted     ;
  wire                                    rpath_sticky          ;
  wire    [PRECISION-1:0]                 rpath_rounder_in      ;
  wire                                    rpath_rounder_sign    ;
  wire                                    rpath_rounder_roundin ;
  wire                                    rpath_rounder_stickyin;
  wire    [2:0]                           rpath_rounder_rm      ;
  wire    [PRECISION-1:0]                 rpath_rounder_out     ;
  wire                                    rpath_rounder_cout    ;
  wire                                    rpath_rounder_inexact ;
  wire                                    rpath_rounder_r_up    ;
  wire    [63:0]                          rpath_sig             ;
  wire                                    rpath_ix              ;
  wire                                    rpath_iv              ;
  wire                                    rpath_of              ;
  wire                                    rpath_exp_inc         ;
  wire                                    rpath_exp_eq_31       ;
  wire                                    rpath_exp_eq_30       ;
  wire                                    rpath_pos_of          ;
  wire                                    rpath_neg_of          ;

  //select result
  wire                                    sel_lpath             ;
  wire                                    of                    ;
  wire                                    iv                    ;
  wire                                    ix                    ;
  wire    [63:0]                          int_abs               ;
  wire    [63:0]                          int_result            ;
  wire    [63:0]                          max_int64             ;
  wire    [63:0]                          min_int64             ;
  wire    [63:0]                          max_int32             ;
  wire    [63:0]                          min_int32             ;

  assign is_signed_int = op_i[0];
  assign is_long_int   = op_i[1];

  //decode
  assign a_exp_is_zero  = a_i[EXPWIDTH+PRECISION-2:PRECISION-1] == 'd0 ;
  assign a_exp_is_ones  = &a_i[EXPWIDTH+PRECISION-2:PRECISION-1]       ;
  assign a_sig_is_zero  = a_i[PRECISION-2:0] == 'd0                    ;
  //assign a_is_subnormal = a_exp_is_zero && !a_sig_is_zero              ;
  //assign a_is_inf       = a_exp_is_ones && a_sig_is_zero               ;
  //assign a_is_zero      = a_exp_is_zero && a_sig_is_zero               ;
  assign a_is_nan       = a_exp_is_ones && !a_sig_is_zero              ;
  //assign a_is_snan      = a_is_nan && !a_i[PRECISION-2]                ;
  //assign a_is_qnan      = a_is_nan && a_i[PRECISION-2]                 ;
  
  //raw_a 
  assign raw_a_sign = a_i[EXPWIDTH+PRECISION-1]                                                   ;
  assign raw_a_exp  = a_i[EXPWIDTH+PRECISION-2:PRECISION-1] | {{(EXPWIDTH-1){1'b0}},a_exp_is_zero};
  assign raw_a_sig  = {!a_exp_is_zero,a_i[PRECISION-2:0]}                                         ;

  assign max_int_exp = EXPBIAS + (is_long_int ? 63 : 31);
  assign exp_of      = raw_a_exp > max_int_exp          ;

  //left shift path
  assign lpath_shamt       = raw_a_exp - (EXPBIAS + PRECISION - 1)                      ;
  assign lpath_sig_shifted = raw_a_sig << (lpath_shamt[LPATH_MAX_SHAMT_WIDTH-1:0])      ; 
  assign lpath_iv          = !is_signed_int && raw_a_sign                               ;
  assign lpath_may_of      = is_signed_int && (raw_a_exp == max_int_exp)                ;
  assign lpath_pos_of      = lpath_may_of && !raw_a_sign                                ;
  assign lpath_neg_of      = lpath_may_of && raw_a_sign && (|raw_a_sig[PRECISION-2:0])  ;
  assign lpath_of          = lpath_pos_of || lpath_neg_of                               ;

  //right shift path
  assign rpath_shamt            = (EXPBIAS + PRECISION - 1) - raw_a_exp                              ;
  assign rpath_rounder_in       = rpath_sig_shifted[PRECISION:1]                                     ;
  assign rpath_rounder_roundin  = rpath_sig_shifted[0]                                               ;
  assign rpath_rounder_stickyin = rpath_sticky                                                       ;
  assign rpath_rounder_sign     = raw_a_sign                                                         ;
  assign rpath_rounder_rm       = rm_i                                                               ;
  assign rpath_sig              = {{(64 - PRECISION - 1){1'b0}},rpath_rounder_cout,rpath_rounder_out};
  assign rpath_exp_inc          = rpath_rounder_r_up && (&rpath_rounder_in)                          ;
  assign rpath_exp_eq_31        = raw_a_exp == (EXPBIAS + 31)                                        ;
  assign rpath_exp_eq_30        = raw_a_exp == (EXPBIAS + 30)                                        ;
  assign rpath_pos_of           = !raw_a_sign && (is_signed_int ? (rpath_exp_eq_31 || (rpath_exp_eq_30 && rpath_exp_inc)) : rpath_exp_eq_31 && rpath_exp_inc);
  assign rpath_neg_of           = raw_a_sign && rpath_exp_eq_31 && ((|rpath_rounder_in) || rpath_rounder_r_up);
  assign rpath_of               = (PRECISION >= 32) ? (!is_long_int && (rpath_pos_of || rpath_neg_of)) : 1'b0;
  assign rpath_ix               = rpath_rounder_inexact                                              ;
  assign rpath_iv               = !is_signed_int && raw_a_sign && (|rpath_sig)                       ;
  
  shift_right_jam #(
    .LEN(PRECISION+1),
    .EXP(EXPWIDTH   )
  )
  U_shift_right_jam (
    .in    ({raw_a_sig,1'b0} ),
    .shamt (rpath_shamt      ),
    .out   (rpath_sig_shifted),
    .sticky(rpath_sticky     )
    );

  rounding #(
    .WIDTH(PRECISION)
  )
  U_rounding (
    .in      (rpath_rounder_in      ),
    .sign    (rpath_rounder_sign    ),
    .roundin (rpath_rounder_roundin ),
    .stickyin(rpath_rounder_stickyin),
    .rm      (rpath_rounder_rm      ),
    .out     (rpath_rounder_out     ),
    .inexact (rpath_rounder_inexact ),
    .cout    (rpath_rounder_cout    ),
    .r_up    (rpath_rounder_r_up    )
    );

  //select result
  assign sel_lpath = raw_a_exp >= (EXPBIAS + PRECISION - 1)                       ;
  assign of        = exp_of || (sel_lpath && lpath_of) || (!sel_lpath && rpath_of);
  assign iv        = of || (sel_lpath && lpath_iv) || (!sel_lpath && rpath_iv)    ;
  assign ix        = !iv && !sel_lpath && rpath_ix                                ;
  assign int_abs   = sel_lpath ? lpath_sig_shifted : rpath_sig                    ;
  assign int_result= (raw_a_sign && is_signed_int ? (-int_abs) : int_abs) & {{32{is_long_int}},32'hffff_ffff};
  assign max_int64 = {!is_signed_int,{63{1'b1}}};
  assign min_int64 = {is_signed_int,{63{1'b0}}};
  assign max_int32 = {32'd0,max_int64[63:32]};
  assign min_int32 = {32'd0,min_int64[63:32]};

  assign result_o  = iv ? ((a_is_nan || !raw_a_sign) ? (is_long_int ? max_int64 : max_int32) : (is_long_int ? min_int64 : min_int32)) : int_result;
  assign fflags_o  = {iv,1'b0,1'b0,1'b0,ix};

endmodule
  
