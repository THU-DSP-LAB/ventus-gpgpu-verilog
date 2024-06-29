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

module fmul_s1 #(
  parameter EXPWIDTH  = 8,
  parameter PRECISION = 24
)(
  input  [EXPWIDTH+PRECISION-1:0] a_i                       ,
  input  [EXPWIDTH+PRECISION-1:0] b_i                       ,
  input  [2:0]                    rm_i                      ,
  output                          out_special_case_valid_o  ,
  output                          out_special_case_nan_o    ,
  output                          out_special_case_inf_o    ,
  output                          out_special_case_inv_o    ,
  output                          out_special_case_haszero_o,
  output                          out_earyl_overflow_o      ,
  output                          out_prod_sign_o           ,
  output [EXPWIDTH:0]             out_shift_amt_o           ,
  output [EXPWIDTH:0]             out_exp_shifted_o         ,
  output                          out_may_be_subnormal_o    ,
  output [2:0]                    out_rm_o
);

  parameter PADDINGBITS = PRECISION+2        ;
  parameter BIASINT     = (1<<(EXPWIDTH-1))-1;
  parameter MAXNORMEXP  = (1<<EXPWIDTH)-2    ;

  //classify
  wire a_exp_is_zero , b_exp_is_zero  ;
  wire a_exp_is_ones , b_exp_is_ones  ;
  wire a_sig_is_zero , b_sig_is_zero  ;
  //wire a_is_subnormal, b_is_subnormal ;
  wire a_is_inf      , b_is_inf       ;
  wire a_is_zero     , b_is_zero      ;
  wire a_is_nan      , b_is_nan       ;
  wire a_is_snan     , b_is_snan      ;
  //wire a_is_qnan     , b_is_qnan      ;

  assign a_exp_is_zero  = a_i[EXPWIDTH+PRECISION-2:PRECISION-1] == 'd0 ;
  assign b_exp_is_zero  = b_i[EXPWIDTH+PRECISION-2:PRECISION-1] == 'd0 ;
  assign a_exp_is_ones  = &a_i[EXPWIDTH+PRECISION-2:PRECISION-1]       ;
  assign b_exp_is_ones  = &b_i[EXPWIDTH+PRECISION-2:PRECISION-1]       ;
  assign a_sig_is_zero  = a_i[PRECISION-2:0] == 'd0                    ;
  assign b_sig_is_zero  = b_i[PRECISION-2:0] == 'd0                    ;
  //assign a_is_subnormal = a_exp_is_zero && !a_sig_is_zero              ;
  //assign b_is_subnormal = b_exp_is_zero && !b_sig_is_zero              ;
  assign a_is_inf       = a_exp_is_ones && a_sig_is_zero               ;
  assign b_is_inf       = b_exp_is_ones && b_sig_is_zero               ;
  assign a_is_zero      = a_exp_is_zero && a_sig_is_zero               ;
  assign b_is_zero      = b_exp_is_zero && b_sig_is_zero               ;
  assign a_is_nan       = a_exp_is_ones && !a_sig_is_zero              ;
  assign b_is_nan       = b_exp_is_ones && !b_sig_is_zero              ;
  assign a_is_snan      = a_is_nan && !a_i[PRECISION-2]                ;
  assign b_is_snan      = b_is_nan && !b_i[PRECISION-2]                ;
  //assign a_is_qnan      = a_is_nan && a_i[PRECISION-2]                 ;
  //assign b_is_qnan      = b_is_nan && b_i[PRECISION-2]                 ;

  //sign, exp, sig
  wire                 raw_a_sign   ;
  wire                 raw_b_sign   ;
  wire [EXPWIDTH-1:0]  raw_a_exp    ;
  wire [EXPWIDTH-1:0]  raw_b_exp    ;
  wire [PRECISION-1:0] raw_a_sig    ;
  wire [PRECISION-1:0] raw_b_sig    ;
  wire                 prod_sign    ;

  assign raw_a_sign      = a_i[EXPWIDTH+PRECISION-1]                                                   ;
  assign raw_b_sign      = b_i[EXPWIDTH+PRECISION-1]                                                   ;
  assign raw_a_exp       = a_i[EXPWIDTH+PRECISION-2:PRECISION-1] | {{(EXPWIDTH-1){1'b0}},a_exp_is_zero};
  assign raw_b_exp       = b_i[EXPWIDTH+PRECISION-2:PRECISION-1] | {{(EXPWIDTH-1){1'b0}},b_exp_is_zero};
  assign raw_a_sig       = {!a_exp_is_zero,a_i[PRECISION-2:0]}                                         ;
  assign raw_b_sig       = {!b_exp_is_zero,b_i[PRECISION-2:0]}                                         ; 

  //output sign
  assign prod_sign       = raw_a_sign ^ raw_b_sign                              ; 

  //shift calculation
  wire [EXPWIDTH:0]                exp_sum       ;
  wire [EXPWIDTH:0]                prod_exp      ;
  wire [EXPWIDTH+1:0]              shift_lim_sub ;
  wire                             prod_exp_uf   ;
  wire [EXPWIDTH:0]                shift_lim     ;
  wire                             prod_exp_ov   ;
  wire [PRECISION-1:0]             subnormal_sig ;
  wire [$clog2(PRECISION*2+2)-1:0] lzc           ;
  wire                             exceed_lim    ;
  wire [$clog2(PRECISION*2+2)-1:0] shift_amt     ;
  wire [EXPWIDTH:0]                exp_shifted   ;

  assign exp_sum       = raw_a_exp + raw_b_exp                              ;
  assign prod_exp      = exp_sum - (BIASINT-(PADDINGBITS+1))                ;
  assign shift_lim_sub = {1'b0,exp_sum} - (BIASINT-PADDINGBITS)             ;
  assign prod_exp_uf   = shift_lim_sub[EXPWIDTH+1]                          ;
  assign shift_lim     = shift_lim_sub[EXPWIDTH:0]                          ;
  assign prod_exp_ov   = exp_sum > (MAXNORMEXP+BIASINT)                     ;
  assign subnormal_sig = a_exp_is_zero ? raw_a_sig : raw_b_sig              ;
  
  /*clz #(
    .LEN (PRECISION*2+2)
  )
  for_lzc (
    .in  ({{(PRECISION+2){1'd0}},subnormal_sig}),
    .out (lzc                                  )
  );*/
  wire lzc_zero; 

  lzc #(
    .WIDTH     (PRECISION*2+2        ),
    .MODE      (1'b1                 ),
    .CNT_WIDTH ($clog2(PRECISION*2+2))
  )
  for_lzc (
    .in_i    ({{(PRECISION+2){1'd0}},subnormal_sig}),
    .cnt_o   (lzc                                  ),
    .empty_o (lzc_zero                             )
  );

  assign exceed_lim    = shift_lim <= {{(EXPWIDTH-$clog2(PRECISION*2+2)){1'b0}},lzc};
  assign shift_amt     = prod_exp_uf ? 'd0 : (exceed_lim ? shift_lim : lzc)         ;
  assign exp_shifted   = prod_exp - shift_amt                                       ;

  //outputs
  assign out_earyl_overflow_o   = prod_exp_ov               ;
  assign out_prod_sign_o        = prod_sign                 ;
  assign out_shift_amt_o        = shift_amt                 ;
  assign out_exp_shifted_o      = exp_shifted               ;
  assign out_may_be_subnormal_o = exceed_lim || prod_exp_uf ;
  assign out_rm_o               = rm_i                      ;

  //special cases
  wire has_zero           ;
  wire has_nan            ;
  wire has_snan           ;
  wire has_inf            ;
  wire special_case_happen;

  assign has_zero = a_is_zero || b_is_zero ;
  assign has_nan  = a_is_nan  || b_is_nan  ;
  assign has_snan = a_is_snan || b_is_snan ;
  assign has_inf  = a_is_inf  || b_is_inf  ;
  assign special_case_happen = has_zero || has_nan || has_inf ;

  wire zero_mul_inf;
  wire nan_result  ;
  wire special_iv  ;

  assign zero_mul_inf = has_zero && has_inf      ;
  assign nan_result   = has_nan  || zero_mul_inf ;
  assign special_iv    = has_snan || zero_mul_inf;

  assign out_special_case_valid_o   = special_case_happen;
  assign out_special_case_nan_o     = nan_result         ;
  assign out_special_case_inf_o     = has_inf            ;
  assign out_special_case_inv_o     = special_iv         ;
  assign out_special_case_haszero_o = has_zero           ;

endmodule

