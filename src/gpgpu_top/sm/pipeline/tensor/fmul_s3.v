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

`include "define.v"
//`include "fpu_ops.v"

module fmul_s3 #(
  parameter EXPWIDTH  = 8,
  parameter PRECISION = 24
)(
  input                           in_special_case_valid_i  ,
  input                           in_special_case_nan_i    ,
  input                           in_special_case_inf_i    ,
  input                           in_special_case_inv_i    ,
  input                           in_special_case_haszero_i,
  input                           in_earyl_overflow_i      ,
  input  [PRECISION*2-1:0]        in_prod_i                ,
  input                           in_prod_sign_i           ,
  input  [EXPWIDTH:0]             in_shift_amt_i           ,
  input  [EXPWIDTH:0]             in_exp_shifted_i         ,
  input                           in_may_be_subnormal_i    ,
  input  [2:0]                    in_rm_i                  ,
  output [EXPWIDTH+PRECISION-1:0] result_o                 ,
  output [4:0]                    fflags_o                 ,
  output                          to_fadd_fp_prod_sign_o   ,
  output [EXPWIDTH-1:0]           to_fadd_fp_prod_exp_o    ,
  output [2*PRECISION-2:0]        to_fadd_fp_prod_sig_o    ,
  output                          to_fadd_is_nan_o         ,
  output                          to_fadd_is_inf_o         ,
  output                          to_fadd_is_inv_o         ,
  output                          to_fadd_overflow_o       
);

  parameter PADDINGBITS = PRECISION+2                  ;
  parameter SHIFTED     = (PRECISION*3+2)+(1<<EXPWIDTH);
  parameter NEAR_INV    = (1<<EXPWIDTH)-2              ;
  parameter INV         = (1<<EXPWIDTH)-1              ;

  wire [PRECISION*3+1:0] sig_shifter_in   ;
  wire [SHIFTED-1:0]     sig_shifted_long ;
  wire [PRECISION*3+1:0] sig_shifted_raw  ;
  wire                   exp_is_subnormal ;
  wire                   no_extra_shift   ;
  wire [EXPWIDTH:0]      exp_pre_round    ;
  wire [PRECISION*3+1:0] sig_shifted      ;

  assign sig_shifter_in   = {{PADDINGBITS{1'b0}},in_prod_i}                                                    ;
  assign sig_shifted_long = (sig_shifter_in<<in_shift_amt_i)                                                   ;
  assign sig_shifted_raw  = sig_shifted_long[PRECISION*3+1:0]                                                  ; 
  assign exp_is_subnormal = in_may_be_subnormal_i && !sig_shifted_raw[PRECISION*3+1]                           ;
  assign no_extra_shift   = sig_shifted_raw[PRECISION*3+1] || exp_is_subnormal                                 ;
  assign exp_pre_round    = exp_is_subnormal ? 'd0 : (no_extra_shift ? in_exp_shifted_i : (in_exp_shifted_i-1));
  assign sig_shifted      = no_extra_shift ? sig_shifted_raw : {sig_shifted_raw[PRECISION*3:0],1'b0}           ;

  wire                   raw_in_sign;
  wire [EXPWIDTH-1:0]    raw_in_exp ;
  wire [PRECISION+2:0]   raw_in_sig ;

  assign raw_in_sign = in_prod_sign_i                                                       ;
  assign raw_in_exp  = exp_pre_round                                                        ;
  assign raw_in_sig  = {sig_shifted[PRECISION*3+1:PRECISION*2],|sig_shifted[PRECISION+1:0]} ;

  wire [PRECISION-2:0] rounder_0_out    ;
  wire                 rounder_0_inexact;
  wire                 rounder_0_cout   ;
  wire                 rounder_0_r_up   ;
  wire                 tininess         ;
  wire [PRECISION+1:0] rounder_0_in     ;

  assign rounder_0_in = {raw_in_sig[PRECISION:0],1'b0} ;

  rounding #(
    .WIDTH (PRECISION-1)
  )
  rounder_0 (
    .in       (rounder_0_in[PRECISION+1:3]),   
    .sign     (raw_in_sign                ),
    .roundin  (rounder_0_in[2]            ),
    .stickyin (|rounder_0_in[1:0]         ),
    .rm       (in_rm_i                    ),
    .out      (rounder_0_out              ),
    .inexact  (rounder_0_inexact          ),
    .cout     (rounder_0_cout             ),
    .r_up     (rounder_0_r_up             )
  );

  assign tininess = (raw_in_sig[PRECISION+2:PRECISION+1]==2'b00) || ((raw_in_sig[PRECISION+2:PRECISION+1]==2'b01)&&!rounder_0_cout) ;

  wire [PRECISION-2:0] rounder_1_out    ;
  wire                 rounder_1_inexact;
  wire                 rounder_1_cout   ;
  wire                 rounder_1_r_up   ;
  wire [PRECISION+1:0] rounder_1_in     ;

  assign rounder_1_in = raw_in_sig[PRECISION+1:0];
                       
  rounding #(
    .WIDTH (PRECISION-1)
  )
  rounder_1 (
    .in       (rounder_1_in[PRECISION+1:3]),   
    .sign     (raw_in_sign                ),
    .roundin  (rounder_1_in[2]            ),
    .stickyin (|rounder_1_in[1:0]         ),
    .rm       (in_rm_i                    ),
    .out      (rounder_1_out              ),
    .inexact  (rounder_1_inexact          ),
    .cout     (rounder_1_cout             ),
    .r_up     (rounder_1_r_up             )
  );

  //common cases
  wire [EXPWIDTH-1:0]           exp_rounded   ;
  wire [PRECISION-2:0]          sig_rounded   ;
  wire                          common_of     ;
  wire                          common_ix     ;
  wire                          common_uf     ;
  wire                          rmin          ;
  wire [EXPWIDTH-1:0]           of_exp        ;
  wire [EXPWIDTH-1:0]           common_exp    ;
  wire [PRECISION-2:0]          common_sig    ;
  wire [EXPWIDTH+PRECISION-1:0] common_result ;
  wire [4:0]                    common_fflags ;

  assign exp_rounded   = rounder_1_cout + raw_in_exp                                                         ;
  assign sig_rounded   = rounder_1_out                                                                       ;
  assign common_of     = (rounder_1_cout ? raw_in_exp==NEAR_INV : raw_in_exp==INV) || in_earyl_overflow_i    ;
  assign common_ix     = rounder_1_inexact | common_of                                                       ;
  assign common_uf     = tininess & common_ix                                                                ;
  assign rmin          = (in_rm_i==`RTZ) || (in_rm_i==`RDN && !raw_in_sign) || (in_rm_i==`RUP && raw_in_sign);
  assign of_exp        = rmin ? NEAR_INV : INV                                                               ;
  assign common_exp    = common_of ? of_exp : exp_rounded                                                    ;
  assign common_sig    = common_of ? (rmin ? {(PRECISION-1){1'b1}} : {(PRECISION-1){1'b0}}) : sig_rounded    ;
  assign common_result = {raw_in_sign,common_exp,common_sig}                                                 ;
  assign common_fflags = {1'b0,1'b0,common_of,common_uf,common_ix}                                           ;

  //special cases
  wire                          special_case_valid   ;
  wire                          special_case_nan     ;
  wire                          special_case_inf     ;
  wire                          special_case_inv     ;
  wire                          special_case_haszero ;
  wire [EXPWIDTH-1:0]           special_exp          ;
  wire [PRECISION-2:0]          special_sig          ;
  wire [EXPWIDTH+PRECISION-1:0] special_result       ;
  wire [4:0]                    special_fflags       ;

  assign special_case_valid   = in_special_case_valid_i                ;
  assign special_case_nan     = in_special_case_nan_i                  ;
  assign special_case_inf     = in_special_case_inf_i                  ;
  assign special_case_inv     = in_special_case_inv_i                  ;
  assign special_case_haszero = in_special_case_haszero_i              ;
  assign special_exp           = special_case_inf ? INV : 'd0          ;
  assign special_sig           = 'd0                                   ;
  assign special_result        = {raw_in_sign,special_exp,special_sig} ;
  assign special_fflags        = {special_case_inv,1'b0,1'b0,1'b0,1'b0};

  //outputs
  assign result_o               = special_case_valid ? special_result : common_result                                                                          ;
  assign fflags_o               = special_case_valid ? special_fflags : common_fflags                                                                          ;
  assign to_fadd_fp_prod_sign_o = in_prod_sign_i                                                                                                               ;
  assign to_fadd_fp_prod_exp_o  = special_case_haszero ? 'd0 : exp_pre_round                                                                                   ;
  assign to_fadd_fp_prod_sig_o  = special_case_haszero ? 'd0 : (sig_shifted[PRECISION*3:PRECISION+2] | {{(2*PRECISION-2){1'b0}},(|sig_shifted[PRECISION+1:0])});
  assign to_fadd_is_nan_o       = special_case_nan                                                                                                             ;
  assign to_fadd_is_inf_o       = special_case_inf && !special_case_nan                                                                                        ;
  assign to_fadd_is_inv_o       = special_case_inv                                                                                                             ;
  assign to_fadd_overflow_o     = exp_pre_round > {EXPWIDTH{1'b1}}                                                                                             ;

endmodule

