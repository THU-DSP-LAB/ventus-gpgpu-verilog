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

module near_path #(
  parameter EXPWIDTH  = 8,
  parameter PRECISION = 48,
  parameter OUTPC     = 24
)
(
  input                  a_sign_i      ,
  input  [EXPWIDTH-1:0]  a_exp_i       ,
  input  [PRECISION-1:0] a_sig_i       ,
  input                  b_sign_i      ,
  //input  [EXPWIDTH-1:0]  b_exp_i       ,
  input  [PRECISION-1:0] b_sig_i       ,
  input                  need_shift_b_i,
  //input  [2:0]           rm_i          ,
  output                 result_sign_o ,
  output [EXPWIDTH-1:0]  result_exp_o  ,
  output [OUTPC+2:0]     result_sig_o  ,
  output                 sig_is_zero_o ,
  output                 a_lt_b_o       
);

  parameter MASK_WIDTH = $clog2(PRECISION+1);

  wire [PRECISION:0]   a_sig       ;
  wire [PRECISION:0]   b_sig       ;
  wire [PRECISION:0]   b_neg       ;
  wire [PRECISION+1:0] a_minus_b   ;
  wire                 a_lt_b      ;
  wire [PRECISION:0]   sig_raw     ;
  wire [PRECISION:0]   lza_str     ;
  wire                 lza_str_zero;

  assign a_sig     = {a_sig_i,1'b0}                  ;
  assign b_sig     = {b_sig_i,1'b0} >> need_shift_b_i;
  assign b_neg     = ~b_sig                          ;
  assign a_minus_b = {1'b0,a_sig} + {1'b1,b_neg} + 1 ;
  assign a_lt_b    = a_minus_b[PRECISION+1]          ;
  assign sig_raw   = a_minus_b[PRECISION:0]          ;

  lza #(
    .LEN (PRECISION+1)
  ) 
  lza_ab (
    .a (a_sig  ),
    .b (b_neg  ),
    .c (lza_str)
  );

  assign lza_str_zero = !(|lza_str) ;

  wire                           need_shift_lim     ;
  wire [PRECISION+1:0]           shift_lim_mask_raw1;
  wire [PRECISION:0]             shift_lim_mask_raw ;
  wire [PRECISION:0]             shift_lim_mask     ;
  wire [PRECISION:0]             shift_lim_bit      ;
  wire [PRECISION:0]             lzc_str            ;
  wire [$clog2(PRECISION+1)-1:0] lzc                ;
  
  assign need_shift_lim      = a_exp_i < (PRECISION+1)                                ;
  assign shift_lim_mask_raw1 = {1'b1,{(PRECISION+1){1'b0}}} >> a_exp_i[MASK_WIDTH-1:0];
  assign shift_lim_mask_raw  = shift_lim_mask_raw1[PRECISION:0]                       ;
  assign shift_lim_mask      = need_shift_lim ? shift_lim_mask_raw : 'd0              ;
  assign shift_lim_bit       = |(shift_lim_mask_raw & sig_raw)                        ;
  assign lzc_str             = shift_lim_mask | lza_str                               ;

  /*
  clz #(
    .LEN (PRECISION+1)
  )
  for_lzc (
    .in  (lzc_str),
    .out (lzc    )
  );
  */

  wire lzc_zero; 

  lzc #(
    .WIDTH     (PRECISION+1        ),
    .MODE      (1'b1               ),
    .CNT_WIDTH ($clog2(PRECISION+1))
  )
  for_lzc (
    .in_i    (lzc_str ),
    .cnt_o   (lzc     ),
    .empty_o (lzc_zero)
  );

  wire [PRECISION:0] int_bit_mask;
  
  assign int_bit_mask[PRECISION] = lzc_str[PRECISION];
  
  genvar i;
  generate for(i=0;i<PRECISION;i=i+1) begin: INT_BIT_MASK
    assign int_bit_mask[i] = lzc_str[i] && !(|(lzc_str[PRECISION:i+1]));
  end
  endgenerate

  wire int_bit_predicted;
  wire int_bit_rshift_1 ;
  
  assign int_bit_predicted = |((int_bit_mask | {{PRECISION{1'b0}},lza_str_zero}) & sig_raw);
  assign int_bit_rshift_1  = |((int_bit_mask >> 1'b1) & sig_raw)                           ;

  wire [PRECISION:0] exceed_lim_mask;
  
  assign exceed_lim_mask[PRECISION] = 'd0 ;
  
  genvar j;
  generate for(j=0;j<PRECISION;j=j+1) begin: EXCEED_LIM_MASK
    assign exceed_lim_mask[j] = |(lza_str[PRECISION:j+1]);
  end
  endgenerate

  wire                exceed_lim    ;
  wire                int_bit       ;
  wire                lza_error     ;
  wire [EXPWIDTH-1:0] exp_s1        ;
  wire [EXPWIDTH-1:0] exp_s2        ;
  wire [PRECISION:0]  sig_s1        ;
  wire [PRECISION:0]  sig_s2        ;
  wire [PRECISION:0]  near_path_sig ;
  wire [EXPWIDTH-1:0] near_path_exp ;
  wire                near_path_sign;

  assign exceed_lim     = need_shift_lim && !(|(exceed_lim_mask & shift_lim_mask_raw))             ;
  assign int_bit        = exceed_lim ? shift_lim_bit : (int_bit_rshift_1||int_bit_predicted)       ;
  assign lza_error      = !int_bit_predicted && !exceed_lim                                        ;
  assign exp_s1         = a_exp_i - lzc                                                            ;
  assign exp_s2         = exp_s1 -lza_error                                                        ;
  assign sig_s1         = sig_raw << lzc                                                           ;
  assign sig_s2         = lza_error ? {sig_s1[PRECISION-1:0],1'b0} : sig_s1                        ;
  //assign near_path_sig  = ((OUTPC+3)>(PRECISION+1)) ? {sig_s2,{(OUTPC-PRECISION+2){1'b0}}} : sig_s2;
  assign near_path_sig  = sig_s2                                                                   ;
  assign near_path_exp  = int_bit ? exp_s2 : 'd0                                                   ;
  assign near_path_sign = a_lt_b ? b_sign_i : a_sign_i                                             ;

  //outputs
  assign result_sign_o = near_path_sign                                                                    ;
  assign result_exp_o  = near_path_exp                                                                     ;
  assign result_sig_o  = {near_path_sig[PRECISION:PRECISION-OUTPC-1],|(near_path_sig[PRECISION-OUTPC-2:0])};
  assign sig_is_zero_o = lza_str_zero && !sig_raw[0]                                                       ;
  assign a_lt_b_o      = a_lt_b                                                                            ;

endmodule

