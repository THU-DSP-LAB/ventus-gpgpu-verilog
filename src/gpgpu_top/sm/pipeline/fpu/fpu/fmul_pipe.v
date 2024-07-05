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

`define CTRLGEN

module fmul_pipe #(
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
  input  [EXPWIDTH+PRECISION-1:0]      in_c_i                    ,
  input  [2:0]                         in_rm_i                   ,
`ifdef CTRLGEN
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
`endif
  output                               out_valid_o               ,
  input                                out_ready_i               ,
  output [EXPWIDTH+PRECISION-1:0]      out_result_o              ,
  output [4:0]                         out_fflags_o              ,
  output                               mul_output_fp_prod_sign_o ,
  output [EXPWIDTH-1:0]                mul_output_fp_prod_exp_o  ,
  output [2*PRECISION-2:0]             mul_output_fp_prod_sig_o  ,
  output                               mul_output_is_nan_o       ,
  output                               mul_output_is_inf_o       ,
  output                               mul_output_is_inv_o       ,
  output                               mul_output_overflow_o     ,
  output [EXPWIDTH+PRECISION-1:0]      add_another_o             ,
  output [2:0]                         op_o                       
);

  //for pipeline reg valid: latency = 2
  reg      in_valid_reg1;
  reg      in_valid_reg2;
  wire     reg_en1      ;
  wire     reg_en2      ;

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      in_valid_reg1 <= 'd0 ;
      in_valid_reg2 <= 'd0 ;
    end
    else begin
      if(!(!out_ready_i && in_valid_reg1 && in_valid_reg2)) begin
        in_valid_reg1 <= in_valid_i   ;
      end
      else begin
        in_valid_reg1 <= in_valid_reg1;
      end
      if(!(!out_ready_i && in_valid_reg2)) begin        
        in_valid_reg2 <= in_valid_reg1;
      end
      else begin
        in_valid_reg2 <= in_valid_reg2;
      end
    end
  end
  
  assign reg_en1 = in_valid_i && !(in_valid_reg1 && in_valid_reg2 && !out_ready_i) ;
  assign reg_en2 = in_valid_reg1 && !(in_valid_reg2 && !out_ready_i)               ;

  //for valid and ready
  assign in_ready_o  = !(!out_ready_i && in_valid_reg1 && in_valid_reg2) ;
  assign out_valid_o = in_valid_reg2                                     ;

  //fmul_s1
  wire                          inv_prod;
  wire [EXPWIDTH+PRECISION-1:0] s1_b    ;
  assign inv_prod = (in_op_i==3'b110) || (in_op_i==3'b111) ; //op==(FN_FNMADD||FN_FNMSUB)
  assign s1_b     = inv_prod ? {!in_b_i[EXPWIDTH+PRECISION-1],in_b_i[EXPWIDTH+PRECISION-2:0]} : in_b_i ;

  wire              s1_out_special_case_valid  ;
  wire              s1_out_special_case_nan    ;
  wire              s1_out_special_case_inf    ;
  wire              s1_out_special_case_inv    ;
  wire              s1_out_special_case_haszero;
  wire              s1_out_earyl_overflow      ;
  wire              s1_out_prod_sign           ;
  wire [EXPWIDTH:0] s1_out_shift_amt           ;
  wire [EXPWIDTH:0] s1_out_exp_shifted         ;
  wire              s1_out_may_be_subnormal    ;
  wire [2:0]        s1_out_rm                  ;

  fmul_s1 #(
    .EXPWIDTH  (EXPWIDTH ),
    .PRECISION (PRECISION)
  )
  s1 (
    .a_i                        (in_a_i                     ),
    .b_i                        (s1_b                       ),
    .rm_i                       (in_rm_i                    ),
    .out_special_case_valid_o   (s1_out_special_case_valid  ),
    .out_special_case_nan_o     (s1_out_special_case_nan    ),
    .out_special_case_inf_o     (s1_out_special_case_inf    ),
    .out_special_case_inv_o     (s1_out_special_case_inv    ),
    .out_special_case_haszero_o (s1_out_special_case_haszero),
    .out_earyl_overflow_o       (s1_out_earyl_overflow      ),
    .out_prod_sign_o            (s1_out_prod_sign           ),
    .out_shift_amt_o            (s1_out_shift_amt           ),
    .out_exp_shifted_o          (s1_out_exp_shifted         ),
    .out_may_be_subnormal_o     (s1_out_may_be_subnormal    ),
    .out_rm_o                   (s1_out_rm                  )
  );

  //pipeline reg: stage1 to stage2
  reg              s1_to_s2_special_case_valid  ;
  reg              s1_to_s2_special_case_nan    ;
  reg              s1_to_s2_special_case_inf    ;
  reg              s1_to_s2_special_case_inv    ;
  reg              s1_to_s2_special_case_haszero;
  reg              s1_to_s2_earyl_overflow      ;
  reg              s1_to_s2_prod_sign           ;
  reg [EXPWIDTH:0] s1_to_s2_shift_amt           ;
  reg [EXPWIDTH:0] s1_to_s2_exp_shifted         ;
  reg              s1_to_s2_may_be_subnormal    ;
  reg [2:0]        s1_to_s2_rm                  ;

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      s1_to_s2_special_case_valid   <= 'd0 ;
      s1_to_s2_special_case_nan     <= 'd0 ;
      s1_to_s2_special_case_inf     <= 'd0 ;
      s1_to_s2_special_case_inv     <= 'd0 ;
      s1_to_s2_special_case_haszero <= 'd0 ;
      s1_to_s2_earyl_overflow       <= 'd0 ;
      s1_to_s2_prod_sign            <= 'd0 ;
      s1_to_s2_shift_amt            <= 'd0 ;
      s1_to_s2_exp_shifted          <= 'd0 ;
      s1_to_s2_may_be_subnormal     <= 'd0 ;
      s1_to_s2_rm                   <= 'd0 ;
    end
    else begin
      if(reg_en1) begin
        s1_to_s2_special_case_valid   <= s1_out_special_case_valid   ;
        s1_to_s2_special_case_nan     <= s1_out_special_case_nan     ;
        s1_to_s2_special_case_inf     <= s1_out_special_case_inf     ;
        s1_to_s2_special_case_inv     <= s1_out_special_case_inv     ;
        s1_to_s2_special_case_haszero <= s1_out_special_case_haszero ;
        s1_to_s2_earyl_overflow       <= s1_out_earyl_overflow       ;
        s1_to_s2_prod_sign            <= s1_out_prod_sign            ;
        s1_to_s2_shift_amt            <= s1_out_shift_amt            ;
        s1_to_s2_exp_shifted          <= s1_out_exp_shifted          ;
        s1_to_s2_may_be_subnormal     <= s1_out_may_be_subnormal     ;
        s1_to_s2_rm                   <= s1_out_rm                   ;
      end
      else begin
        s1_to_s2_special_case_valid   <= s1_to_s2_special_case_valid  ;
        s1_to_s2_special_case_nan     <= s1_to_s2_special_case_nan    ;
        s1_to_s2_special_case_inf     <= s1_to_s2_special_case_inf    ;
        s1_to_s2_special_case_inv     <= s1_to_s2_special_case_inv    ;
        s1_to_s2_special_case_haszero <= s1_to_s2_special_case_haszero;
        s1_to_s2_earyl_overflow       <= s1_to_s2_earyl_overflow      ;
        s1_to_s2_prod_sign            <= s1_to_s2_prod_sign           ;
        s1_to_s2_shift_amt            <= s1_to_s2_shift_amt           ;
        s1_to_s2_exp_shifted          <= s1_to_s2_exp_shifted         ;
        s1_to_s2_may_be_subnormal     <= s1_to_s2_may_be_subnormal    ;
        s1_to_s2_rm                   <= s1_to_s2_rm                  ;
      end
    end
  end

  //naivemultiplier
  wire                   a_exp_isnot_zero, b_exp_isnot_zero;
  wire [PRECISION:0]     raw_a_sig       , raw_b_sig       ;
  wire [PRECISION*2+1:0] multiplier_out                    ;
  wire [PRECISION*2-1:0] multiplier_out_rm2                ;

  assign a_exp_isnot_zero = |in_a_i[EXPWIDTH+PRECISION-2:PRECISION-1];
  assign b_exp_isnot_zero = |in_b_i[EXPWIDTH+PRECISION-2:PRECISION-1];
  assign raw_a_sig        = {a_exp_isnot_zero,in_a_i[PRECISION-2:0]} ;
  assign raw_b_sig        = {b_exp_isnot_zero,in_b_i[PRECISION-2:0]} ;

  naivemultiplier #(
    .LEN (PRECISION+1)
  )
  multiplier (
    .clk       (clk           ),
    .rst_n     (rst_n         ),
    .regenable (reg_en1       ),
    .a         (raw_a_sig     ),
    .b         (raw_b_sig     ),
    .result    (multiplier_out)
  );

  //multiplier rm 2 bit
  assign multiplier_out_rm2 = multiplier_out[PRECISION*2-1:0];

  //fmul_s2
  wire                          s2_out_special_case_valid  ;
  wire                          s2_out_special_case_nan    ;
  wire                          s2_out_special_case_inf    ;
  wire                          s2_out_special_case_inv    ;
  wire                          s2_out_special_case_haszero;
  wire                          s2_out_earyl_overflow      ;
  wire [PRECISION*2-1:0]        s2_out_prod                ;
  wire                          s2_out_prod_sign           ;
  wire [EXPWIDTH:0]             s2_out_shift_amt           ;
  wire [EXPWIDTH:0]             s2_out_exp_shifted         ;
  wire                          s2_out_may_be_subnormal    ;
  wire [2:0]                    s2_out_rm                  ;

  fmul_s2 #(
    .EXPWIDTH  (EXPWIDTH ),
    .PRECISION (PRECISION)
  )
  s2 (
    .in_special_case_valid_i    (s1_to_s2_special_case_valid  ),
    .in_special_case_nan_i      (s1_to_s2_special_case_nan    ),
    .in_special_case_inf_i      (s1_to_s2_special_case_inf    ),
    .in_special_case_inv_i      (s1_to_s2_special_case_inv    ),
    .in_special_case_haszero_i  (s1_to_s2_special_case_haszero),
    .in_earyl_overflow_i        (s1_to_s2_earyl_overflow      ),
    .in_prod_sign_i             (s1_to_s2_prod_sign           ),
    .in_shift_amt_i             (s1_to_s2_shift_amt           ),
    .in_exp_shifted_i           (s1_to_s2_exp_shifted         ),
    .in_may_be_subnormal_i      (s1_to_s2_may_be_subnormal    ),
    .in_rm_i                    (s1_to_s2_rm                  ),
    .prod_i                     (multiplier_out_rm2           ),
    .out_special_case_valid_o   (s2_out_special_case_valid    ),
    .out_special_case_nan_o     (s2_out_special_case_nan      ),
    .out_special_case_inf_o     (s2_out_special_case_inf      ),
    .out_special_case_inv_o     (s2_out_special_case_inv      ),
    .out_special_case_haszero_o (s2_out_special_case_haszero  ),
    .out_earyl_overflow_o       (s2_out_earyl_overflow        ),
    .out_prod_o                 (s2_out_prod                  ),
    .out_prod_sign_o            (s2_out_prod_sign             ),
    .out_shift_amt_o            (s2_out_shift_amt             ),
    .out_exp_shifted_o          (s2_out_exp_shifted           ),
    .out_may_be_subnormal_o     (s2_out_may_be_subnormal      ),
    .out_rm_o                   (s2_out_rm                    )
  );

  //pipeline reg: stage2 to stage3
  reg                          s2_to_s3_special_case_valid  ;
  reg                          s2_to_s3_special_case_nan    ;
  reg                          s2_to_s3_special_case_inf    ;
  reg                          s2_to_s3_special_case_inv    ;
  reg                          s2_to_s3_special_case_haszero;
  reg                          s2_to_s3_earyl_overflow      ;
  reg [PRECISION*2-1:0]        s2_to_s3_prod                ;
  reg                          s2_to_s3_prod_sign           ;
  reg [EXPWIDTH:0]             s2_to_s3_shift_amt           ;
  reg [EXPWIDTH:0]             s2_to_s3_exp_shifted         ;
  reg                          s2_to_s3_may_be_subnormal    ;
  reg [2:0]                    s2_to_s3_rm                  ;

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      s2_to_s3_special_case_valid   <= 'd0 ;
      s2_to_s3_special_case_nan     <= 'd0 ;
      s2_to_s3_special_case_inf     <= 'd0 ;
      s2_to_s3_special_case_inv     <= 'd0 ;
      s2_to_s3_special_case_haszero <= 'd0 ;
      s2_to_s3_earyl_overflow       <= 'd0 ;
      s2_to_s3_prod                 <= 'd0 ;
      s2_to_s3_prod_sign            <= 'd0 ;
      s2_to_s3_shift_amt            <= 'd0 ;
      s2_to_s3_exp_shifted          <= 'd0 ;
      s2_to_s3_may_be_subnormal     <= 'd0 ;
      s2_to_s3_rm                   <= 'd0 ;
    end
    else begin
      if(reg_en2) begin
        s2_to_s3_special_case_valid   <= s2_out_special_case_valid   ;
        s2_to_s3_special_case_nan     <= s2_out_special_case_nan     ;
        s2_to_s3_special_case_inf     <= s2_out_special_case_inf     ;
        s2_to_s3_special_case_inv     <= s2_out_special_case_inv     ;
        s2_to_s3_special_case_haszero <= s2_out_special_case_haszero ;
        s2_to_s3_earyl_overflow       <= s2_out_earyl_overflow       ;
        s2_to_s3_prod                 <= s2_out_prod                 ;
        s2_to_s3_prod_sign            <= s2_out_prod_sign            ;
        s2_to_s3_shift_amt            <= s2_out_shift_amt            ;
        s2_to_s3_exp_shifted          <= s2_out_exp_shifted          ;
        s2_to_s3_may_be_subnormal     <= s2_out_may_be_subnormal     ;
        s2_to_s3_rm                   <= s2_out_rm                   ;
      end
      else begin
        s2_to_s3_special_case_valid   <= s2_to_s3_special_case_valid   ;
        s2_to_s3_special_case_nan     <= s2_to_s3_special_case_nan     ;
        s2_to_s3_special_case_inf     <= s2_to_s3_special_case_inf     ;
        s2_to_s3_special_case_inv     <= s2_to_s3_special_case_inv     ;
        s2_to_s3_special_case_haszero <= s2_to_s3_special_case_haszero ;
        s2_to_s3_earyl_overflow       <= s2_to_s3_earyl_overflow       ;
        s2_to_s3_prod                 <= s2_to_s3_prod                 ;
        s2_to_s3_prod_sign            <= s2_to_s3_prod_sign            ;
        s2_to_s3_shift_amt            <= s2_to_s3_shift_amt            ;
        s2_to_s3_exp_shifted          <= s2_to_s3_exp_shifted          ;
        s2_to_s3_may_be_subnormal     <= s2_to_s3_may_be_subnormal     ;
        s2_to_s3_rm                   <= s2_to_s3_rm                   ;
      end
    end
  end

  //fmul_s3
  fmul_s3 #(
    .EXPWIDTH  (EXPWIDTH ),
    .PRECISION (PRECISION)
  )
  s3 (
    .in_special_case_valid_i   (s2_to_s3_special_case_valid  ),
    .in_special_case_nan_i     (s2_to_s3_special_case_nan    ),
    .in_special_case_inf_i     (s2_to_s3_special_case_inf    ),
    .in_special_case_inv_i     (s2_to_s3_special_case_inv    ),
    .in_special_case_haszero_i (s2_to_s3_special_case_haszero),
    .in_earyl_overflow_i       (s2_to_s3_earyl_overflow      ),
    .in_prod_i                 (s2_to_s3_prod                ),
    .in_prod_sign_i            (s2_to_s3_prod_sign           ),
    .in_shift_amt_i            (s2_to_s3_shift_amt           ),
    .in_exp_shifted_i          (s2_to_s3_exp_shifted         ),
    .in_may_be_subnormal_i     (s2_to_s3_may_be_subnormal    ),
    .in_rm_i                   (s2_to_s3_rm                  ),
    .result_o                  (out_result_o                 ),
    .fflags_o                  (out_fflags_o                 ),
    .to_fadd_fp_prod_sign_o    (mul_output_fp_prod_sign_o    ),
    .to_fadd_fp_prod_exp_o     (mul_output_fp_prod_exp_o     ),
    .to_fadd_fp_prod_sig_o     (mul_output_fp_prod_sig_o     ),
    .to_fadd_is_nan_o          (mul_output_is_nan_o          ),
    .to_fadd_is_inf_o          (mul_output_is_inf_o          ),
    .to_fadd_is_inv_o          (mul_output_is_inv_o          ),
    .to_fadd_overflow_o        (mul_output_overflow_o        )
  );

  //c, op
  reg [2:0]                    op_reg1, op_reg2;
  reg [EXPWIDTH+PRECISION-1:0] c_reg1 , c_reg2 ;

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      op_reg1 <= 'd0 ;
      op_reg2 <= 'd0 ;
      c_reg1  <= 'd0 ;
      c_reg2  <= 'd0 ;
    end
    else begin
      if(reg_en1) begin
        op_reg1 <= in_op_i ;
        c_reg1  <= in_c_i  ;
      end
      else begin
        op_reg1 <= op_reg1 ;
        c_reg1  <= c_reg1  ;
      end
      if(reg_en2) begin
        op_reg2 <= op_reg1 ;
        c_reg2  <= c_reg1  ;
      end
      else begin
        op_reg2 <= op_reg2 ;
        c_reg2  <= c_reg2  ;
      end
    end
  end

  assign op_o          = op_reg2 ;
  assign add_another_o = c_reg2  ;

  //with ctrl
`ifdef CTRLGEN
  reg [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] reg_index_reg1, reg_index_reg2;
  reg [`DEPTH_WARP-1:0]                 warp_id_reg1  , warp_id_reg2  ;
  reg [SOFTTHREAD-1:0]                  vec_mask_reg1 , vec_mask_reg2 ;
  reg                                   wvd_reg1      , wvd_reg2      ;
  reg                                   wxd_reg1      , wxd_reg2      ;

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      reg_index_reg1 <= 'd0 ;
      warp_id_reg1   <= 'd0 ;
      vec_mask_reg1  <= 'd0 ;
      wvd_reg1       <= 'd0 ;
      wxd_reg1       <= 'd0 ;
      reg_index_reg2 <= 'd0 ;
      warp_id_reg2   <= 'd0 ;
      vec_mask_reg2  <= 'd0 ;
      wvd_reg2       <= 'd0 ;
      wxd_reg2       <= 'd0 ;
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
      if(reg_en2) begin
        reg_index_reg2 <= reg_index_reg1 ;
        warp_id_reg2   <= warp_id_reg1   ;
        vec_mask_reg2  <= vec_mask_reg1  ;
        wvd_reg2       <= wvd_reg1       ;
        wxd_reg2       <= wxd_reg1       ;
      end
      else begin
        reg_index_reg2 <= reg_index_reg2 ;
        warp_id_reg2   <= warp_id_reg2   ;
        vec_mask_reg2  <= vec_mask_reg2  ;
        wvd_reg2       <= wvd_reg2       ;
        wxd_reg2       <= wxd_reg2       ;
      end
    end
  end

  assign out_reg_index_o = reg_index_reg2 ;
  assign out_warp_id_o   = warp_id_reg2   ;
  assign out_vec_mask_o  = vec_mask_reg2  ;
  assign out_wvd_o       = wvd_reg2       ;
  assign out_wxd_o       = wxd_reg2       ;
`endif

endmodule

`undef CTRLGEN

