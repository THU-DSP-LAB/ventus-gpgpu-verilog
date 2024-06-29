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

module fmul_s2 #(
  parameter EXPWIDTH  = 8,
  parameter PRECISION = 24
)(
  input                           in_special_case_valid_i   ,
  input                           in_special_case_nan_i     ,
  input                           in_special_case_inf_i     ,
  input                           in_special_case_inv_i     ,
  input                           in_special_case_haszero_i ,
  input                           in_earyl_overflow_i       ,
  input                           in_prod_sign_i            ,
  input  [EXPWIDTH:0]             in_shift_amt_i            ,
  input  [EXPWIDTH:0]             in_exp_shifted_i          ,
  input                           in_may_be_subnormal_i     ,
  input  [2:0]                    in_rm_i                   ,
  input  [PRECISION*2-1:0]        prod_i                    ,
  output                          out_special_case_valid_o  ,
  output                          out_special_case_nan_o    ,
  output                          out_special_case_inf_o    ,
  output                          out_special_case_inv_o    ,
  output                          out_special_case_haszero_o,
  output                          out_earyl_overflow_o      ,
  output [PRECISION*2-1:0]        out_prod_o                ,
  output                          out_prod_sign_o           ,
  output [EXPWIDTH:0]             out_shift_amt_o           ,
  output [EXPWIDTH:0]             out_exp_shifted_o         ,
  output                          out_may_be_subnormal_o    ,
  output [2:0]                    out_rm_o                  
);


  assign out_special_case_valid_o   = in_special_case_valid_i  ;
  assign out_special_case_nan_o     = in_special_case_nan_i    ;
  assign out_special_case_inf_o     = in_special_case_inf_i    ;
  assign out_special_case_inv_o     = in_special_case_inv_i    ;
  assign out_special_case_haszero_o = in_special_case_haszero_i;
  assign out_earyl_overflow_o       = in_earyl_overflow_i      ;
  assign out_prod_sign_o            = in_prod_sign_i           ;
  assign out_shift_amt_o            = in_shift_amt_i           ;
  assign out_exp_shifted_o          = in_exp_shifted_i         ;
  assign out_may_be_subnormal_o     = in_may_be_subnormal_i    ;
  assign out_rm_o                   = in_rm_i                  ;
  assign out_prod_o                 = prod_i                   ;

endmodule

