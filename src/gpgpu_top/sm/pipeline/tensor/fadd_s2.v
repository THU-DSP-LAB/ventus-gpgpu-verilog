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

module fadd_s2 #(
  parameter EXPWIDTH  = 8,
  parameter PRECISION = 24
)
(
  input  [2:0]                    in_rm_i                       ,
  input                           in_far_sign_i                 ,
  input  [EXPWIDTH-1:0]           in_far_exp_i                  ,
  input  [PRECISION+2:0]          in_far_sig_i                  ,
  input                           in_near_sign_i                ,
  input  [EXPWIDTH-1:0]           in_near_exp_i                 ,
  input  [PRECISION+2:0]          in_near_sig_i                 ,
  input                           in_special_case_valid_i       ,
  input                           in_special_case_iv_i          ,
  input                           in_special_case_nan_i         ,
  //input                           in_special_case_inf_sign_i    ,
  //input                           in_small_add_i                ,
  input                           in_far_mul_of_i               ,
  input                           in_near_sig_is_zero_i         ,
  input                           in_sel_far_path_i             ,
  output [EXPWIDTH+PRECISION-1:0] out_result_o                  ,
  output [4:0]                    out_fflags_o                   
);

  parameter NEAR_INV    = (1<<EXPWIDTH)-2              ;
  parameter INV         = (1<<EXPWIDTH)-1              ;

  //special output
  wire [EXPWIDTH+PRECISION-1:0] special_path_result;
  wire [4:0]                    special_path_fflags;

  assign special_path_result = in_special_case_nan_i ? {1'b0,{(EXPWIDTH+1){1'b1}},{(PRECISION-2){1'b0}}} : {1'b0,{EXPWIDTH{1'b1}},{(PRECISION-1){1'b0}}};
  assign special_path_fflags = {in_special_case_iv_i,4'b0000};

  //far_path
  wire [PRECISION+1:0] far_path_rounder_0_in     ;
  wire [PRECISION-2:0] far_path_rounder_0_out    ;
  wire                 far_path_rounder_0_inexact;
  wire                 far_path_rounder_0_cout   ;
  wire                 far_path_rounder_0_r_up   ;
  wire                 far_path_tininess         ;

  assign far_path_rounder_0_in = {in_far_sig_i[PRECISION:0],1'b0} ;

  rounding #(
    .WIDTH (PRECISION-1)
  )
  far_path_rounder_0 (
    .in       (far_path_rounder_0_in[PRECISION+1:3]),   
    .sign     (in_far_sign_i                       ),
    .roundin  (far_path_rounder_0_in[2]            ),
    .stickyin (|far_path_rounder_0_in[1:0]         ),
    .rm       (in_rm_i                             ),
    .out      (far_path_rounder_0_out              ),
    .inexact  (far_path_rounder_0_inexact          ),
    .cout     (far_path_rounder_0_cout             ),
    .r_up     (far_path_rounder_0_r_up             )
  );

  assign far_path_tininess = (in_far_sig_i[PRECISION+2:PRECISION+1]==2'b00) || ((in_far_sig_i[PRECISION+2:PRECISION+1]==2'b01)&&!far_path_rounder_0_cout) ;


  wire [PRECISION+1:0] far_path_rounder_1_in     ;
  wire [PRECISION-2:0] far_path_rounder_1_out    ;
  wire                 far_path_rounder_1_inexact;
  wire                 far_path_rounder_1_cout   ;
  wire                 far_path_rounder_1_r_up   ;

  assign far_path_rounder_1_in = in_far_sig_i[PRECISION+1:0] ;

  rounding #(
    .WIDTH (PRECISION-1)
  )
  far_path_rounder_1 (
    .in       (far_path_rounder_1_in[PRECISION+1:3]),   
    .sign     (in_far_sign_i                       ),
    .roundin  (far_path_rounder_1_in[2]            ),
    .stickyin (|far_path_rounder_1_in[1:0]         ),
    .rm       (in_rm_i                             ),
    .out      (far_path_rounder_1_out              ),
    .inexact  (far_path_rounder_1_inexact          ),
    .cout     (far_path_rounder_1_cout             ),
    .r_up     (far_path_rounder_1_r_up             )
  );

  wire [EXPWIDTH-1:0]           far_path_exp_rounded      ;
  wire [PRECISION-2:0]          far_path_sig_rounded      ;
  wire                          far_path_mul_of           ;
  wire                          far_path_may_uf           ;
  wire                          far_path_of_before_rounded;
  wire                          far_path_of_after_rounded ;
  wire                          far_path_of               ;
  wire                          far_path_ix               ;
  wire                          far_path_uf               ;
  wire [EXPWIDTH+PRECISION-1:0] far_path_result           ;

  assign far_path_exp_rounded       = far_path_rounder_1_cout + in_far_exp_i                                    ;
  assign far_path_sig_rounded       = far_path_rounder_1_out                                                    ;
  assign far_path_mul_of            = in_far_mul_of_i                                                           ;
  assign far_path_may_uf            = far_path_tininess && !far_path_mul_of                                     ;
  assign far_path_of_before_rounded = in_far_exp_i == INV                                                       ;
  assign far_path_of_after_rounded  = far_path_rounder_1_cout && (in_far_exp_i==NEAR_INV)                       ;
  assign far_path_of                = far_path_of_before_rounded || far_path_of_after_rounded || in_far_mul_of_i;
  assign far_path_ix                = far_path_rounder_1_inexact || far_path_of                                 ;
  assign far_path_uf                = far_path_may_uf && far_path_ix                                            ;
  assign far_path_result            = {in_far_sign_i,far_path_exp_rounded,far_path_sig_rounded}                 ;

  //near path
  wire near_path_is_zero;

  assign near_path_is_zero = (in_near_exp_i=='d0) && in_near_sig_is_zero_i;

  wire [PRECISION+1:0] near_path_rounder_0_in     ;
  wire [PRECISION-2:0] near_path_rounder_0_out    ;
  wire                 near_path_rounder_0_inexact;
  wire                 near_path_rounder_0_cout   ;
  wire                 near_path_rounder_0_r_up   ;
  wire                 near_path_tininess         ;

  assign near_path_rounder_0_in = {in_near_sig_i[PRECISION:0],1'b0} ;

  rounding #(
    .WIDTH (PRECISION-1)
  )
  near_path_rounder_0 (
    .in       (near_path_rounder_0_in[PRECISION+1:3]),   
    .sign     (in_near_sign_i                       ),
    .roundin  (near_path_rounder_0_in[2]            ),
    .stickyin (|near_path_rounder_0_in[1:0]         ),
    .rm       (in_rm_i                              ),
    .out      (near_path_rounder_0_out              ),
    .inexact  (near_path_rounder_0_inexact          ),
    .cout     (near_path_rounder_0_cout             ),
    .r_up     (near_path_rounder_0_r_up             )
  );

  assign near_path_tininess = (in_near_sig_i[PRECISION+2:PRECISION+1]==2'b00) || ((in_near_sig_i[PRECISION+2:PRECISION+1]==2'b01)&&!near_path_rounder_0_cout) ;


  wire [PRECISION+1:0] near_path_rounder_1_in     ;
  wire [PRECISION-2:0] near_path_rounder_1_out    ;
  wire                 near_path_rounder_1_inexact;
  wire                 near_path_rounder_1_cout   ;
  wire                 near_path_rounder_1_r_up   ;

  assign near_path_rounder_1_in = in_near_sig_i[PRECISION+1:0] ;

  rounding #(
    .WIDTH (PRECISION-1)
  )
  near_path_rounder_1 (
    .in       (near_path_rounder_1_in[PRECISION+1:3]),   
    .sign     (in_near_sign_i                       ),
    .roundin  (near_path_rounder_1_in[2]            ),
    .stickyin (|near_path_rounder_1_in[1:0]         ),
    .rm       (in_rm_i                              ),
    .out      (near_path_rounder_1_out              ),
    .inexact  (near_path_rounder_1_inexact          ),
    .cout     (near_path_rounder_1_cout             ),
    .r_up     (near_path_rounder_1_r_up             )
  );

  wire [EXPWIDTH-1:0]           near_path_exp_rounded;
  wire [PRECISION-2:0]          near_path_sig_rounded;
  wire                          near_path_zero_sign  ;
  wire                          near_path_sign       ;
  wire [EXPWIDTH+PRECISION-1:0] near_path_result     ;
  wire                          near_path_of         ;
  wire                          near_path_ix         ;
  wire                          near_path_uf         ;

  assign near_path_exp_rounded = near_path_rounder_1_cout + in_near_exp_i                                            ;
  assign near_path_sig_rounded = near_path_rounder_1_out                                                             ;
  assign near_path_zero_sign   = in_rm_i == `RDN                                                                     ;
  assign near_path_sign        = (in_near_sign_i && !near_path_is_zero) || (near_path_zero_sign && near_path_is_zero);
  assign near_path_result      = {near_path_sign,near_path_exp_rounded,near_path_sig_rounded}                        ;
  assign near_path_of          = near_path_exp_rounded == {EXPWIDTH{1'b1}}                                           ;
  assign near_path_ix          = near_path_rounder_1_inexact || near_path_of                                         ;
  assign near_path_uf          = near_path_tininess && near_path_ix                                                  ;

  //common output
  wire                          common_overflow       ;
  wire                          common_overflow_sign  ;
  wire                          rmin                  ;
  wire [EXPWIDTH-1:0]           common_overflow_exp   ;
  wire [PRECISION-2:0]          common_overflow_sig   ;
  wire                          common_underflow      ;
  wire                          common_inexact        ;
  wire [4:0]                    common_fflags         ;
  wire [EXPWIDTH+PRECISION-1:0] common_overflow_result;

  assign common_overflow        = (in_sel_far_path_i&&far_path_of) || (!in_sel_far_path_i&&near_path_of)                  ;
  assign common_overflow_sign   = in_sel_far_path_i ? in_far_sign_i : in_near_sign_i                                      ;
  assign rmin                   = (in_rm_i==`RTZ) || (in_rm_i==`RDN && !in_far_sign_i) || (in_rm_i==`RUP && in_far_sign_i);
  assign common_overflow_exp    = rmin ? NEAR_INV : INV                                                                   ;
  assign common_overflow_sig    = rmin ? {(PRECISION-1){1'b1}} : {(PRECISION-1){1'b0}}                                    ;
  assign common_underflow       = (in_sel_far_path_i&&far_path_uf) || (!in_sel_far_path_i&&near_path_uf)                  ;
  assign common_inexact         = (in_sel_far_path_i&&far_path_ix) || (!in_sel_far_path_i&&near_path_ix)                  ;
  assign common_fflags          = {1'b0,1'b0,common_overflow,common_underflow,common_inexact}                             ;
  assign common_overflow_result = {common_overflow_sign,common_overflow_exp,common_overflow_sig}                          ;

  //outputs
  assign out_result_o = in_special_case_valid_i ? special_path_result : (common_overflow ? common_overflow_result : (in_sel_far_path_i ? far_path_result : near_path_result)) ;
  assign out_fflags_o = in_special_case_valid_i ? special_path_fflags : common_fflags ;

endmodule

