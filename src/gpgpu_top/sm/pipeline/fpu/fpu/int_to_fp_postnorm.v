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
// Description:对尾数进行舍入，并根据是否进位得到浮点数的指数，再和符号位一起拼接成浮点数格式
module int_to_fp_postnorm #(parameter EXPWIDTH  = 8,
                            parameter PRECISION = 24
)(
  input   [62:0]                    norm_int_i    ,
  input   [5:0]                     lzc_i         ,
  input                             is_zero_i     ,
  input                             sign_i        ,
  input   [2:0]                     rm_i          ,
  output  [EXPWIDTH+PRECISION-1:0]  result_o      ,
  output  [4:0]                     fflags_o      
  );

  localparam EXPBIAS = (1 << (EXPWIDTH-1)) - 1;

  wire    [EXPWIDTH-1:0]            exp_raw     ;
  wire    [PRECISION-2:0]           sig_raw     ;
  wire                              round_bit   ;
  wire                              sticky_bit  ;

  //rounding output
  wire    [PRECISION-2:0]           rounder_out    ;
  wire                              rounder_inexact;
  wire                              rounder_cout   ;
  wire                              rounder_r_up   ;

  
  wire                              ix          ;
  wire    [EXPWIDTH-1:0]            exp         ;
  wire    [PRECISION-2:0]           sig         ;

  assign exp_raw    = 63 + EXPBIAS - lzc_i         ;
  assign sig_raw    = norm_int_i[62:64-PRECISION]  ;
  assign round_bit  = norm_int_i[63-PRECISION]     ;
  assign sticky_bit = |(norm_int_i[62-PRECISION:0]);

  //例化rounding
  rounding #(
    .WIDTH(PRECISION-1)
  )
  U_rounding (
    .in      (sig_raw        ),
    .sign    (sign_i         ),
    .roundin (round_bit      ),
    .stickyin(sticky_bit     ),
    .rm      (rm_i           ),
    .out     (rounder_out    ),
    .inexact (rounder_inexact),
    .cout    (rounder_cout   ),
    .r_up    (rounder_r_up   )
    );

  assign ix  = rounder_inexact                           ;
  assign exp = is_zero_i ? 'd0 : (exp_raw + rounder_cout);
  assign sig = rounder_out                               ;

  assign result_o = {sign_i,exp,sig};
  assign fflags_o = {4'd0,ix}       ;

endmodule
