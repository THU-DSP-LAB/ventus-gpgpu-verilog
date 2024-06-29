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

//`include "fpu_ops.v"
`include "define.v"

//`define CTRLGEN

module fadd_pipe_no_ctrl #(
  parameter EXPWIDTH  = 8 ,
  parameter PRECISION = 24,
  parameter SOFTTHREAD= 4 ,
  parameter HARDTHREAD= 4 
)
(
  input                                clk                       ,
  input                                rst_n                     ,
  input                                in_valid_i                ,
  output                               in_ready_o                ,
  input  [2:0]                         in_op_i                   ,
  input  [EXPWIDTH+PRECISION-1:0]      in_a_i                    ,
  input  [EXPWIDTH+PRECISION-1:0]      in_b_i                    ,
  //input  [EXPWIDTH+PRECISION-1:0]      in_c_i                    ,
  input  [2:0]                         in_rm_i                   ,
  input                                from_mul_fp_prod_sign_i   ,
  input  [EXPWIDTH-1:0]                from_mul_fp_prod_exp_i    ,
  input  [2*PRECISION-2:0]             from_mul_fp_prod_sig_i    ,
  input                                from_mul_is_nan_i         ,
  input                                from_mul_is_inf_i         ,
  input                                from_mul_is_inv_i         ,
  input                                from_mul_overflow_i       ,
  input  [EXPWIDTH+PRECISION-1:0]      from_mul_add_another_i    ,
  //input  [2:0]                         from_mul_op_i             ,
/*`ifdef CTRLGEN
  input  [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] in_reg_index_i        ,
  input  [`DEPTH_WARP-1:0]                 in_warp_id_i          ,
  input  [SOFTTHREAD-1:0]                  in_vec_mask_i         ,
  input                                    in_wvd_i              ,
  input                                    in_wxd_i              ,
  output [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] out_reg_index_o       ,
  output [`DEPTH_WARP-1:0]                 out_warp_id_o         ,
  output [SOFTTHREAD-1:0]                  out_vec_mask_o        ,
  output                                   out_wvd_o             ,
  output                                   out_wxd_o             ,
`endif*/
  output                               out_valid_o               ,
  input                                out_ready_i               ,
  output [EXPWIDTH+PRECISION-1:0]      out_result_o              ,
  output [4:0]                         out_fflags_o               
);

  parameter LEN = EXPWIDTH + PRECISION;  

  //for pipeline reg valid: latency = 1
  reg  in_valid_reg1;
  wire reg_en1      ;

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      in_valid_reg1 <= 'd0 ;
    end
    else begin
      if(!(!out_ready_i && in_valid_reg1)) begin
        in_valid_reg1 <= in_valid_i   ;
      end
      else begin
        in_valid_reg1 <= in_valid_reg1;
      end
    end
  end

  assign reg_en1 = in_valid_i && !(!out_ready_i && in_valid_reg1);

  //for valid and ready
  assign in_ready_o  = !(!out_ready_i && in_valid_reg1);
  assign out_valid_o = in_valid_reg1                   ;

  //is FMA
  wire is_fma;

  assign is_fma = in_op_i[2] == 1'b1;

  //operation num
  wire [EXPWIDTH+PRECISION-1:0] src_a           ;
  wire [EXPWIDTH+PRECISION-1:0] src_b           ;
  wire                          inv_add         ;
  wire [LEN+PRECISION-1:0]      from_mul_fp_prod;
  wire [LEN+PRECISION-1:0]      add1            ;
  wire [LEN+PRECISION-1:0]      add2            ;

  assign src_a            = in_a_i                                                                      ;
  assign src_b            = is_fma ? from_mul_add_another_i : in_b_i                                    ;
  assign inv_add          = in_op_i[0] == 1'b1                                                          ;
  assign from_mul_fp_prod = {from_mul_fp_prod_sign_i,from_mul_fp_prod_exp_i,from_mul_fp_prod_sig_i/*,1'b0*/};
  assign add1             = is_fma ? from_mul_fp_prod : {src_a[LEN-1:0],{PRECISION{1'b0}}}              ;
  assign add2             = {(inv_add ? {~src_b[LEN-1],src_b[LEN-2:0]} : src_b),{PRECISION{1'b0}}}      ;

  //fadd_s1
  wire [2:0]           s1_out_rm                    ;
  wire                 s1_out_far_sign              ;
  wire [EXPWIDTH-1:0]  s1_out_far_exp               ;
  wire [PRECISION+2:0] s1_out_far_sig               ;
  wire                 s1_out_near_sign             ;
  wire [EXPWIDTH-1:0]  s1_out_near_exp              ;
  wire [PRECISION+2:0] s1_out_near_sig              ;
  wire                 s1_out_special_case_valid    ;
  wire                 s1_out_special_case_iv       ;
  wire                 s1_out_special_case_nan      ;
  wire                 s1_out_special_case_inf_sign ;
  wire                 s1_out_small_add             ;
  wire                 s1_out_far_mul_of            ;
  wire                 s1_out_near_sig_is_zero      ;
  wire                 s1_out_sel_far_path          ;
  wire                 b_inter_flags_is_nan         ;
  wire                 b_inter_flags_is_inf         ;
  wire                 b_inter_flags_is_inv         ;
  wire                 b_inter_flags_overflow       ;

  assign b_inter_flags_is_nan   = is_fma ? from_mul_is_nan_i   : 'd0 ;
  assign b_inter_flags_is_inf   = is_fma ? from_mul_is_inf_i   : 'd0 ;
  assign b_inter_flags_is_inv   = is_fma ? from_mul_is_inv_i   : 'd0 ;
  assign b_inter_flags_overflow = is_fma ? from_mul_overflow_i : 'd0 ;

  fadd_s1 #(
    .EXPWIDTH  (EXPWIDTH   ),
    .PRECISION (PRECISION*2),
    .OUTPC     (PRECISION  )
  )
  s1 (
    .a_i                         (add1                        ),
    .b_i                         (add2                        ),
    .rm_i                        (in_rm_i                     ),
    .b_inter_valid_i             (is_fma                      ),
    .b_inter_flags_is_nan_i      (b_inter_flags_is_nan        ),
    .b_inter_flags_is_inf_i      (b_inter_flags_is_inf        ),
    .b_inter_flags_is_inv_i      (b_inter_flags_is_inv        ),
    .b_inter_flags_overflow_i    (b_inter_flags_overflow      ),
    .out_rm_o                    (s1_out_rm                   ),
    .out_far_sign_o              (s1_out_far_sign             ),
    .out_far_exp_o               (s1_out_far_exp              ),
    .out_far_sig_o               (s1_out_far_sig              ),
    .out_near_sign_o             (s1_out_near_sign            ),
    .out_near_exp_o              (s1_out_near_exp             ),
    .out_near_sig_o              (s1_out_near_sig             ),
    .out_special_case_valid_o    (s1_out_special_case_valid   ),
    .out_special_case_iv_o       (s1_out_special_case_iv      ),
    .out_special_case_nan_o      (s1_out_special_case_nan     ),
    .out_special_case_inf_sign_o (s1_out_special_case_inf_sign),
    .out_small_add_o             (s1_out_small_add            ),
    .out_far_mul_of_o            (s1_out_far_mul_of           ),
    .out_near_sig_is_zero_o      (s1_out_near_sig_is_zero     ),
    .out_sel_far_path_o          (s1_out_sel_far_path         )
  );

  //pipeline reg: stage1 to stage2
  reg [2:0]           s1_to_s2_rm                   ;
  reg                 s1_to_s2_far_sign             ;
  reg [EXPWIDTH-1:0]  s1_to_s2_far_exp              ;
  reg [PRECISION+2:0] s1_to_s2_far_sig              ;
  reg                 s1_to_s2_near_sign            ;
  reg [EXPWIDTH-1:0]  s1_to_s2_near_exp             ;
  reg [PRECISION+2:0] s1_to_s2_near_sig             ;
  reg                 s1_to_s2_special_case_valid   ;
  reg                 s1_to_s2_special_case_iv      ;
  reg                 s1_to_s2_special_case_nan     ;
  reg                 s1_to_s2_special_case_inf_sign;
  reg                 s1_to_s2_small_add            ;
  reg                 s1_to_s2_far_mul_of           ;
  reg                 s1_to_s2_near_sig_is_zero     ;
  reg                 s1_to_s2_sel_far_path         ;

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      s1_to_s2_rm                    <= 'd0 ;
      s1_to_s2_far_sign              <= 'd0 ;
      s1_to_s2_far_exp               <= 'd0 ;
      s1_to_s2_far_sig               <= 'd0 ;
      s1_to_s2_near_sign             <= 'd0 ;
      s1_to_s2_near_exp              <= 'd0 ;
      s1_to_s2_near_sig              <= 'd0 ;
      s1_to_s2_special_case_valid    <= 'd0 ;
      s1_to_s2_special_case_iv       <= 'd0 ;
      s1_to_s2_special_case_nan      <= 'd0 ;
      s1_to_s2_special_case_inf_sign <= 'd0 ;
      s1_to_s2_small_add             <= 'd0 ;
      s1_to_s2_far_mul_of            <= 'd0 ;
      s1_to_s2_near_sig_is_zero      <= 'd0 ;
      s1_to_s2_sel_far_path          <= 'd0 ;
    end
    else begin
      if(reg_en1) begin
        s1_to_s2_rm                    <= s1_out_rm                    ;
        s1_to_s2_far_sign              <= s1_out_far_sign              ;
        s1_to_s2_far_exp               <= s1_out_far_exp               ;
        s1_to_s2_far_sig               <= s1_out_far_sig               ;
        s1_to_s2_near_sign             <= s1_out_near_sign             ;
        s1_to_s2_near_exp              <= s1_out_near_exp              ;
        s1_to_s2_near_sig              <= s1_out_near_sig              ;
        s1_to_s2_special_case_valid    <= s1_out_special_case_valid    ;
        s1_to_s2_special_case_iv       <= s1_out_special_case_iv       ;
        s1_to_s2_special_case_nan      <= s1_out_special_case_nan      ;
        s1_to_s2_special_case_inf_sign <= s1_out_special_case_inf_sign ;
        s1_to_s2_small_add             <= s1_out_small_add             ;
        s1_to_s2_far_mul_of            <= s1_out_far_mul_of            ;
        s1_to_s2_near_sig_is_zero      <= s1_out_near_sig_is_zero      ;
        s1_to_s2_sel_far_path          <= s1_out_sel_far_path          ;
      end
      else begin
        s1_to_s2_rm                    <= s1_to_s2_rm                    ;
        s1_to_s2_far_sign              <= s1_to_s2_far_sign              ;
        s1_to_s2_far_exp               <= s1_to_s2_far_exp               ;
        s1_to_s2_far_sig               <= s1_to_s2_far_sig               ;
        s1_to_s2_near_sign             <= s1_to_s2_near_sign             ;
        s1_to_s2_near_exp              <= s1_to_s2_near_exp              ;
        s1_to_s2_near_sig              <= s1_to_s2_near_sig              ;
        s1_to_s2_special_case_valid    <= s1_to_s2_special_case_valid    ;
        s1_to_s2_special_case_iv       <= s1_to_s2_special_case_iv       ;
        s1_to_s2_special_case_nan      <= s1_to_s2_special_case_nan      ;
        s1_to_s2_special_case_inf_sign <= s1_to_s2_special_case_inf_sign ;
        s1_to_s2_small_add             <= s1_to_s2_small_add             ;
        s1_to_s2_far_mul_of            <= s1_to_s2_far_mul_of            ;
        s1_to_s2_near_sig_is_zero      <= s1_to_s2_near_sig_is_zero      ;
        s1_to_s2_sel_far_path          <= s1_to_s2_sel_far_path          ;
      end
    end
  end

  //fadd_s2
  fadd_s2 #(
    .EXPWIDTH  (EXPWIDTH ),
    .PRECISION (PRECISION)
  )
  s2 (
    .in_rm_i                    (s1_to_s2_rm                   ),
    .in_far_sign_i              (s1_to_s2_far_sign             ),
    .in_far_exp_i               (s1_to_s2_far_exp              ),
    .in_far_sig_i               (s1_to_s2_far_sig              ),
    .in_near_sign_i             (s1_to_s2_near_sign            ),
    .in_near_exp_i              (s1_to_s2_near_exp             ),
    .in_near_sig_i              (s1_to_s2_near_sig             ),
    .in_special_case_valid_i    (s1_to_s2_special_case_valid   ),
    .in_special_case_iv_i       (s1_to_s2_special_case_iv      ),
    .in_special_case_nan_i      (s1_to_s2_special_case_nan     ),
    //.in_special_case_inf_sign_i (s1_to_s2_special_case_inf_sign),
    //.in_small_add_i             (s1_to_s2_small_add            ),
    .in_far_mul_of_i            (s1_to_s2_far_mul_of           ),
    .in_near_sig_is_zero_i      (s1_to_s2_near_sig_is_zero     ),
    .in_sel_far_path_i          (s1_to_s2_sel_far_path         ),
    .out_result_o               (out_result_o                  ),
    .out_fflags_o               (out_fflags_o                  )
  );

  //CTRLGEN
/*`ifdef CTRLGEN
  reg [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] reg_index_reg1;
  reg [`DEPTH_WARP-1:0]                 warp_id_reg1  ;
  reg [SOFTTHREAD-1:0]                  vec_mask_reg1 ;
  reg                                   wvd_reg1      ;
  reg                                   wxd_reg1      ;

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      reg_index_reg1 <= 'd0 ;
      warp_id_reg1   <= 'd0 ;
      vec_mask_reg1  <= 'd0 ;
      wvd_reg1       <= 'd0 ;
      wxd_reg1       <= 'd0 ;
    end
    else begin
      if(reg_en1) begin
        reg_index_reg1 <= in_reg_index_i ;
        warp_id_reg1   <= in_warp_id_i   ;
        vec_mask_reg1  <= in_vec_mask_i  ;
        wvd_reg1       <= in_wvd_i       ;
        wxd_reg1       <= in_wxd_i       ;
      end
      else begin
        reg_index_reg1 <= reg_index_reg1 ;
        warp_id_reg1   <= warp_id_reg1   ;
        vec_mask_reg1  <= vec_mask_reg1  ;
        wvd_reg1       <= wvd_reg1       ;
        wxd_reg1       <= wxd_reg1       ;
      end
    end
  end

  assign out_reg_index_o = reg_index_reg1 ;
  assign out_warp_id_o   = warp_id_reg1   ;
  assign out_vec_mask_o  = vec_mask_reg1  ;
  assign out_wvd_o       = wvd_reg1       ;
  assign out_wxd_o       = wxd_reg1       ;
`endif*/

endmodule

