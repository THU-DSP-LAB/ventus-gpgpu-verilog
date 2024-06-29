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

module fadd_s1 #(
  parameter EXPWIDTH  = 8,
  parameter PRECISION = 48,
  parameter OUTPC     = 24
)
(
  input  [EXPWIDTH+PRECISION-1:0] a_i                            ,
  input  [EXPWIDTH+PRECISION-1:0] b_i                            ,
  input  [2:0]                    rm_i                           ,
  input                           b_inter_valid_i                ,
  input                           b_inter_flags_is_nan_i         ,
  input                           b_inter_flags_is_inf_i         ,
  input                           b_inter_flags_is_inv_i         ,
  input                           b_inter_flags_overflow_i       ,
  output [2:0]                    out_rm_o                       ,
  output                          out_far_sign_o                 ,
  output [EXPWIDTH-1:0]           out_far_exp_o                  ,
  output [OUTPC+2:0]              out_far_sig_o                  ,
  output                          out_near_sign_o                ,
  output [EXPWIDTH-1:0]           out_near_exp_o                 ,
  output [OUTPC+2:0]              out_near_sig_o                 ,
  output                          out_special_case_valid_o       ,
  output                          out_special_case_iv_o          ,
  output                          out_special_case_nan_o         ,
  output                          out_special_case_inf_sign_o    ,
  output                          out_small_add_o                ,
  output                          out_far_mul_of_o               ,
  output                          out_near_sig_is_zero_o         ,
  output                          out_sel_far_path_o              
);

  //classify
  wire a_exp_is_zero , b_exp_is_zero  ;
  wire a_exp_is_ones , b_exp_is_ones  ;
  wire a_sig_is_zero , b_sig_is_zero  ;
  //wire a_is_subnormal, b_is_subnormal ;
  wire a_is_inf      , b_is_inf       ;
  //wire a_is_zero     , b_is_zero      ;
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
  //assign a_is_zero      = a_exp_is_zero && a_sig_is_zero               ;
  //assign b_is_zero      = b_exp_is_zero && b_sig_is_zero               ;
  assign a_is_nan       = a_exp_is_ones && !a_sig_is_zero              ;
  assign b_is_nan       = b_exp_is_ones && !b_sig_is_zero              ;
  assign a_is_snan      = a_is_nan && !a_i[PRECISION-2]                ;
  assign b_is_snan      = b_is_nan && !b_i[PRECISION-2]                ;
  //assign a_is_qnan      = a_is_nan && a_i[PRECISION-2]                 ;
  //assign b_is_qnan      = b_is_nan && b_i[PRECISION-2]                 ;

  //sign, exp, sig
  wire                 raw_a_sign ;
  wire                 raw_b_sign ;
  wire [EXPWIDTH-1:0]  raw_a_exp  ;
  wire [EXPWIDTH-1:0]  raw_b_exp  ;
  wire [PRECISION-1:0] raw_a_sig  ;
  wire [PRECISION-1:0] raw_b_sig  ;
  wire                 eff_sub    ;
  wire                 small_add  ;

  assign raw_a_sign = a_i[EXPWIDTH+PRECISION-1]                                                   ;
  assign raw_b_sign = b_i[EXPWIDTH+PRECISION-1]                                                   ;
  assign raw_a_exp  = a_i[EXPWIDTH+PRECISION-2:PRECISION-1] | {{(EXPWIDTH-1){1'b0}},a_exp_is_zero};
  assign raw_b_exp  = b_i[EXPWIDTH+PRECISION-2:PRECISION-1] | {{(EXPWIDTH-1){1'b0}},b_exp_is_zero};
  assign raw_a_sig  = {!a_exp_is_zero,a_i[PRECISION-2:0]}                                         ;
  assign raw_b_sig  = {!b_exp_is_zero,b_i[PRECISION-2:0]}                                         ;
  assign eff_sub    = raw_a_sign ^ raw_b_sign                                                     ;
  assign small_add  = a_exp_is_zero && b_exp_is_zero                                              ;

  //deal special cases
  wire b_isnan             ;
  wire b_issnan            ;
  wire b_isinf             ;
  wire special_path_has_nan ;
  wire special_path_has_snan;
  wire special_path_has_inf ;
  wire special_path_inf_inv ;
  wire special_path_iv      ;
  wire special_case_happen  ;

  assign b_isnan               = b_inter_valid_i ? b_inter_flags_is_nan_i : b_is_nan ;
  assign b_issnan              = b_inter_valid_i ? b_inter_flags_is_inv_i : b_is_snan;
  assign b_isinf               = b_inter_valid_i ? b_inter_flags_is_inf_i : b_is_inf ;
  assign special_path_has_nan  = a_is_nan || b_isnan                                 ;
  assign special_path_has_snan = a_is_snan || b_issnan                               ;
  assign special_path_has_inf  = a_is_inf || b_isinf                                 ;
  assign special_path_inf_iv   = a_is_inf && b_isinf && eff_sub                      ;
  assign special_path_iv       = special_path_has_snan || special_path_inf_iv        ;
  assign special_case_happen   = special_path_has_nan || special_path_has_inf        ;

  //path select
  wire [EXPWIDTH:0]   exp_diff_a_b;
  wire [EXPWIDTH:0]   exp_diff_b_a;
  wire                need_swap   ;
  wire [EXPWIDTH-1:0] ea_minus_eb ;
  wire                sel_far_path;

  assign exp_diff_a_b = {1'b0,raw_a_exp} - {1'b0,raw_b_exp}                                ;
  assign exp_diff_b_a = {1'b0,raw_b_exp} - {1'b0,raw_a_exp}                                ;
  assign need_swap    = exp_diff_a_b[EXPWIDTH] || b_inter_flags_overflow_i                 ;
  assign ea_minus_eb  = need_swap ? exp_diff_b_a[EXPWIDTH-1:0] : exp_diff_a_b[EXPWIDTH-1:0];
  assign sel_far_path = !eff_sub || (ea_minus_eb>1) || b_inter_flags_overflow_i            ;

  //far_path: num=1
  wire                 far_path_in_a_sign  ;
  wire [EXPWIDTH-1:0]  far_path_in_a_exp   ;
  wire [PRECISION-1:0] far_path_in_a_sig   ;
  //wire                 far_path_in_b_sign  ;
  //wire [EXPWIDTH-1:0]  far_path_in_b_exp   ;
  wire [PRECISION-1:0] far_path_in_b_sig   ;
  wire [EXPWIDTH-1:0]  far_path_in_expdiff ;
  wire                 far_path_result_sign;
  wire [EXPWIDTH-1:0]  far_path_result_exp ;
  wire [OUTPC+2:0]     far_path_result_sig ;

  assign far_path_in_a_sign  = !need_swap ? raw_a_sign   : raw_b_sign  ;
  assign far_path_in_a_exp   = !need_swap ? raw_a_exp    : raw_b_exp   ;
  assign far_path_in_a_sig   = !need_swap ? raw_a_sig    : raw_b_sig   ;
  //assign far_path_in_b_sign  = !need_swap ? raw_b_sign   : raw_a_sign  ;
  //assign far_path_in_b_exp   = !need_swap ? raw_b_exp    : raw_a_exp   ;
  assign far_path_in_b_sig   = !need_swap ? raw_b_sig    : raw_a_sig   ;
  assign far_path_in_expdiff = !need_swap ? exp_diff_a_b : exp_diff_b_a;

  far_path #(
    .EXPWIDTH  (EXPWIDTH ),
    .PRECISION (PRECISION),
    .OUTPC     (OUTPC    )
  )
  far_path_mods (
    .a_sign_i      (far_path_in_a_sign  ),
    .a_exp_i       (far_path_in_a_exp   ),
    .a_sig_i       (far_path_in_a_sig   ),
    //.b_sign_i      (far_path_in_b_sign  ),
    //.b_exp_i       (far_path_in_b_exp   ),
    .b_sig_i       (far_path_in_b_sig   ),
    .expdiff_i     (far_path_in_expdiff ),
    .effsub_i      (eff_sub             ),
    .small_add_i   (small_add           ),
    //.rm_i          (rm_i                ),
    .result_sign_o (far_path_result_sign),
    .result_exp_o  (far_path_result_exp ),
    .result_sig_o  (far_path_result_sig )
  );

  //near path: num=2
  wire                 near_path_exp_neq        ;
  wire                 near_path_0_result_sign  ;
  wire [EXPWIDTH-1:0]  near_path_0_result_exp   ;
  wire [OUTPC+2:0]     near_path_0_result_sig   ;
  wire                 near_path_0_sig_is_zero  ;
  wire                 near_path_0_a_lt_b       ;
  wire                 near_path_1_result_sign  ;
  wire [EXPWIDTH-1:0]  near_path_1_result_exp   ;
  wire [OUTPC+2:0]     near_path_1_result_sig   ;
  wire                 near_path_1_a_lt_b       ;
  wire                 near_path_1_sig_is_zero  ;
  wire                 near_path_sel            ;
  wire                 near_path_out_sign       ;
  wire [EXPWIDTH-1:0]  near_path_out_exp        ;
  wire [OUTPC+2:0]     near_path_out_sig        ;
  //wire                 near_path_out_a_lt_b     ;
  wire                 near_path_out_sig_is_zero;
  
  assign near_path_exp_neq = raw_a_exp[1:0] != raw_b_exp[1:0];
  
  near_path #(
    .EXPWIDTH  (EXPWIDTH ),
    .PRECISION (PRECISION),
    .OUTPC     (OUTPC    )
  )
  near_path_mods_0 (
    .a_sign_i       (raw_a_sign             ),
    .a_exp_i        (raw_a_exp              ),
    .a_sig_i        (raw_a_sig              ),
    .b_sign_i       (raw_b_sign             ),
    //.b_exp_i        (raw_b_exp              ),
    .b_sig_i        (raw_b_sig              ),
    .need_shift_b_i (near_path_exp_neq      ),
    //.rm_i           (rm_i                   ),
    .result_sign_o  (near_path_0_result_sign),
    .result_exp_o   (near_path_0_result_exp ),
    .result_sig_o   (near_path_0_result_sig ),
    .sig_is_zero_o  (near_path_0_sig_is_zero),
    .a_lt_b_o       (near_path_0_a_lt_b     )
  );

  near_path #(
    .EXPWIDTH  (EXPWIDTH ),
    .PRECISION (PRECISION),
    .OUTPC     (OUTPC    )
  )
  near_path_mods_1 (
    .a_sign_i       (raw_b_sign             ),
    .a_exp_i        (raw_b_exp              ),
    .a_sig_i        (raw_b_sig              ),
    .b_sign_i       (raw_a_sign             ),
    //.b_exp_i        (raw_a_exp              ),
    .b_sig_i        (raw_a_sig              ),
    .need_shift_b_i (near_path_exp_neq      ),
    //.rm_i           (rm_i                   ),
    .result_sign_o  (near_path_1_result_sign),
    .result_exp_o   (near_path_1_result_exp ),
    .result_sig_o   (near_path_1_result_sig ),
    .sig_is_zero_o  (near_path_1_sig_is_zero),
    .a_lt_b_o       (near_path_1_a_lt_b     )
  );

  assign near_path_sel             = (need_swap || (!near_path_exp_neq&&near_path_0_a_lt_b))          ;
  assign near_path_out_sign        = near_path_sel ? near_path_1_result_sign : near_path_0_result_sign;
  assign near_path_out_exp         = near_path_sel ? near_path_1_result_exp  : near_path_0_result_exp ;
  assign near_path_out_sig         = near_path_sel ? near_path_1_result_sig  : near_path_0_result_sig ;
  //assign near_path_out_a_lt_b      = near_path_sel ? near_path_1_a_lt_b      : near_path_0_a_lt_b     ;
  assign near_path_out_sig_is_zero = near_path_sel ? near_path_1_sig_is_zero : near_path_0_sig_is_zero;

  //outputs
  assign out_rm_o                    = rm_i                                                   ;
  assign out_far_sign_o              = far_path_result_sign                                   ;
  assign out_far_exp_o               = far_path_result_exp                                    ;
  assign out_far_sig_o               = far_path_result_sig                                    ;
  assign out_near_sign_o             = near_path_out_sign                                     ;
  assign out_near_exp_o              = near_path_out_exp                                      ;
  assign out_near_sig_o              = near_path_out_sig                                      ;
  assign out_special_case_valid_o    = special_case_happen                                    ;
  assign out_special_case_iv_o       = special_path_iv                                        ;
  assign out_special_case_nan_o      = special_path_has_nan || special_path_inf_iv            ;
  assign out_special_case_inf_sign_o = a_is_inf ? raw_a_sign : raw_b_sign                     ;
  assign out_small_add_o             = small_add                                              ;
  assign out_far_mul_of_o            = b_inter_flags_overflow_i || (b_exp_is_ones && !eff_sub);
  assign out_near_sig_is_zero_o      = near_path_out_sig_is_zero                              ;
  assign out_sel_far_path_o          = sel_far_path                                           ;

endmodule

