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

module tc_mul_pipe #(
  parameter EXPWIDTH  = 8,
  parameter PRECISION = 24,
  parameter LATENCY   = 2
)(
  input                                 clk               ,
  input                                 rst_n             ,

  //input   [2:0]                         op_i              ,
  input   [EXPWIDTH+PRECISION-1:0]      a_i               ,
  input   [EXPWIDTH+PRECISION-1:0]      b_i               ,
  //input   [EXPWIDTH+PRECISION-1:0]      c_i               ,
  input   [2:0]                         rm_i              ,
  input   [EXPWIDTH+PRECISION-1:0]      ctrl_c_i          ,
  input   [2:0]                         ctrl_rm_i         ,
  input   [7:0]                         ctrl_reg_idxw_i   ,
  input   [`DEPTH_WARP-1:0]             ctrl_warpid_i     ,

  input                                 in_valid_i        ,
  input                                 out_ready_i       ,

  output                                in_ready_o        ,
  output                                out_valid_o       ,

  output  [EXPWIDTH+PRECISION-1:0]      result_o          ,
  output  [4:0]                         fflags_o          ,
  output  [EXPWIDTH+PRECISION-1:0]      ctrl_c_o          ,
  output  [2:0]                         ctrl_rm_o         ,
  output  [7:0]                         ctrl_reg_idxw_o   ,
  output  [`DEPTH_WARP-1:0]             ctrl_warpid_o     
);

  //ctrl reg
  reg  [EXPWIDTH+PRECISION-1:0]ctrl_c_reg1          ;
  reg  [2:0]                   ctrl_rm_reg1         ;
  reg  [7:0]                   ctrl_reg_idxw_reg1   ;
  reg  [`DEPTH_WARP-1:0]       ctrl_warpid_reg1     ;
  reg  [EXPWIDTH+PRECISION-1:0]ctrl_c_reg2          ;
  reg  [2:0]                   ctrl_rm_reg2         ;
  reg  [7:0]                   ctrl_reg_idxw_reg2   ;
  reg  [`DEPTH_WARP-1:0]       ctrl_warpid_reg2     ;
  //for pipeline reg valid: latency = 2
  reg                           in_valid_reg1;
  reg                           in_valid_reg2;
  wire                          reg_en1      ;
  wire                          reg_en2      ;
  //s1 output
  wire                          s1_out_special_case_valid      ; 
  wire                          s1_out_special_case_nan        ;
  wire                          s1_out_special_case_inf        ;
  wire                          s1_out_special_case_inv        ;
  wire                          s1_out_special_case_haszero    ;
  wire                          s1_out_earyl_overflow          ;
  wire                          s1_out_prod_sign               ;
  wire [EXPWIDTH:0]             s1_out_shift_amt               ;
  wire [EXPWIDTH:0]             s1_out_exp_shifted             ;
  wire                          s1_out_may_be_subnormal        ;
  wire [2:0]                    s1_out_rm                      ;
  //s1 output reg
  reg                           s1_out_special_case_valid_reg  ; 
  reg                           s1_out_special_case_nan_reg    ;
  reg                           s1_out_special_case_inf_reg    ;
  reg                           s1_out_special_case_inv_reg    ;
  reg                           s1_out_special_case_haszero_reg;
  reg                           s1_out_earyl_overflow_reg      ;
  reg                           s1_out_prod_sign_reg           ;
  reg  [EXPWIDTH:0]             s1_out_shift_amt_reg           ;
  reg  [EXPWIDTH:0]             s1_out_exp_shifted_reg         ;
  reg                           s1_out_may_be_subnormal_reg    ;
  reg  [2:0]                    s1_out_rm_reg                  ;
  //naivemultiplier
  wire                          a_exp_is_zero                  ;
  wire                          b_exp_is_zero                  ;
  //wire                          raw_a_sign                     ;
  //wire                          raw_b_sign                     ;
  //wire [EXPWIDTH-1:0]           raw_a_exp                      ;
  //wire [EXPWIDTH-1:0]           raw_b_exp                      ;
  wire [PRECISION-1:0]          raw_a_sig                      ;
  wire [PRECISION-1:0]          raw_b_sig                      ;
  wire [2*PRECISION-1:0]        naivemultiplier_result         ;
  //s2 output
  wire                          s2_out_special_case_valid      ;
  wire                          s2_out_special_case_nan        ;
  wire                          s2_out_special_case_inf        ;
  wire                          s2_out_special_case_inv        ;
  wire                          s2_out_special_case_haszero    ;
  wire                          s2_out_earyl_overflow          ;
  wire [PRECISION*2-1:0]        s2_out_prod                    ;
  wire                          s2_out_prod_sign               ;
  wire [EXPWIDTH:0]             s2_out_shift_amt               ;
  wire [EXPWIDTH:0]             s2_out_exp_shifted             ;
  wire                          s2_out_may_be_subnormal        ;
  wire [2:0]                    s2_out_rm                      ;
  //s2 output reg
  reg                           s2_out_special_case_valid_reg  ;
  reg                           s2_out_special_case_nan_reg    ;
  reg                           s2_out_special_case_inf_reg    ;
  reg                           s2_out_special_case_inv_reg    ;
  reg                           s2_out_special_case_haszero_reg;
  reg                           s2_out_earyl_overflow_reg      ;
  reg  [PRECISION*2-1:0]        s2_out_prod_reg                ;
  reg                           s2_out_prod_sign_reg           ;
  reg  [EXPWIDTH:0]             s2_out_shift_amt_reg           ;
  reg  [EXPWIDTH:0]             s2_out_exp_shifted_reg         ;
  reg                           s2_out_may_be_subnormal_reg    ;
  reg  [2:0]                    s2_out_rm_reg                  ;

  wire                          s3_out_to_fadd_fp_prod_sign    ; 
  wire [EXPWIDTH-1:0]           s3_out_to_fadd_fp_prod_exp     ; 
  wire [2*PRECISION-2:0]        s3_out_to_fadd_fp_prod_sig     ; 
  wire                          s3_out_to_fadd_is_nan          ; 
  wire                          s3_out_to_fadd_is_inf          ; 
  wire                          s3_out_to_fadd_is_inv          ; 
  wire                          s3_out_to_fadd_overflow        ;  


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

  //例化fmul_s1
  fmul_s1 #(
    .EXPWIDTH  (EXPWIDTH ),
    .PRECISION (PRECISION)
  )
  U_fmul_s1 (
    .a_i                       (a_i                        ), 
    .b_i                       (b_i                        ),
    .rm_i                      (rm_i                       ),
    .out_special_case_valid_o  (s1_out_special_case_valid  ),
    .out_special_case_nan_o    (s1_out_special_case_nan    ),
    .out_special_case_inf_o    (s1_out_special_case_inf    ),
    .out_special_case_inv_o    (s1_out_special_case_inv    ),
    .out_special_case_haszero_o(s1_out_special_case_haszero),
    .out_earyl_overflow_o      (s1_out_earyl_overflow      ),
    .out_prod_sign_o           (s1_out_prod_sign           ),
    .out_shift_amt_o           (s1_out_shift_amt           ),
    .out_exp_shifted_o         (s1_out_exp_shifted         ),
    .out_may_be_subnormal_o    (s1_out_may_be_subnormal    ),
    .out_rm_o                  (s1_out_rm                  )
  );

  //寄存s1的输出
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      s1_out_special_case_valid_reg   <= 'd0;   
      s1_out_special_case_nan_reg     <= 'd0;
      s1_out_special_case_inf_reg     <= 'd0;
      s1_out_special_case_inv_reg     <= 'd0;
      s1_out_special_case_haszero_reg <= 'd0;
      s1_out_earyl_overflow_reg       <= 'd0;
      s1_out_prod_sign_reg            <= 'd0;
      s1_out_shift_amt_reg            <= 'd0;
      s1_out_exp_shifted_reg          <= 'd0;
      s1_out_may_be_subnormal_reg     <= 'd0;
      s1_out_rm_reg                   <= 'd0;
      ctrl_c_reg1                     <= 'd0;
      ctrl_rm_reg1                    <= 'd0;
      ctrl_reg_idxw_reg1              <= 'd0;
      ctrl_warpid_reg1                <= 'd0;
    end
    else if(reg_en1) begin
      s1_out_special_case_valid_reg   <= s1_out_special_case_valid  ;  
      s1_out_special_case_nan_reg     <= s1_out_special_case_nan    ;
      s1_out_special_case_inf_reg     <= s1_out_special_case_inf    ;
      s1_out_special_case_inv_reg     <= s1_out_special_case_inv    ;
      s1_out_special_case_haszero_reg <= s1_out_special_case_haszero;
      s1_out_earyl_overflow_reg       <= s1_out_earyl_overflow      ;
      s1_out_prod_sign_reg            <= s1_out_prod_sign           ;
      s1_out_shift_amt_reg            <= s1_out_shift_amt           ;
      s1_out_exp_shifted_reg          <= s1_out_exp_shifted         ;
      s1_out_may_be_subnormal_reg     <= s1_out_may_be_subnormal    ;
      s1_out_rm_reg                   <= s1_out_rm                  ;
      ctrl_c_reg1                     <= ctrl_c_i                   ; 
      ctrl_rm_reg1                    <= ctrl_rm_i                  ;
      ctrl_reg_idxw_reg1              <= ctrl_reg_idxw_i            ;
      ctrl_warpid_reg1                <= ctrl_warpid_i              ;
    end
    else begin
      s1_out_special_case_valid_reg   <= s1_out_special_case_valid_reg  ;   
      s1_out_special_case_nan_reg     <= s1_out_special_case_nan_reg    ;
      s1_out_special_case_inf_reg     <= s1_out_special_case_inf_reg    ;
      s1_out_special_case_inv_reg     <= s1_out_special_case_inv_reg    ;
      s1_out_special_case_haszero_reg <= s1_out_special_case_haszero_reg;
      s1_out_earyl_overflow_reg       <= s1_out_earyl_overflow_reg      ;
      s1_out_prod_sign_reg            <= s1_out_prod_sign_reg           ;
      s1_out_shift_amt_reg            <= s1_out_shift_amt_reg           ;
      s1_out_exp_shifted_reg          <= s1_out_exp_shifted_reg         ;
      s1_out_may_be_subnormal_reg     <= s1_out_may_be_subnormal_reg    ;
      s1_out_rm_reg                   <= s1_out_rm_reg                  ;
      ctrl_c_reg1                     <= ctrl_c_reg1                    ;
      ctrl_rm_reg1                    <= ctrl_rm_reg1                   ;
      ctrl_reg_idxw_reg1              <= ctrl_reg_idxw_reg1             ;
      ctrl_warpid_reg1                <= ctrl_warpid_reg1               ;
    end
  end

  //例化naivemultiplier
  assign a_exp_is_zero   = a_i[EXPWIDTH+PRECISION-2:PRECISION-1] == 'd0                                ;
  assign b_exp_is_zero   = b_i[EXPWIDTH+PRECISION-2:PRECISION-1] == 'd0                                ;
  //assign raw_a_sign      = a_i[EXPWIDTH+PRECISION-1]                                                   ;
  //assign raw_b_sign      = b_i[EXPWIDTH+PRECISION-1]                                                   ;
  //assign raw_a_exp       = a_i[EXPWIDTH+PRECISION-2:PRECISION-1] | {{(EXPWIDTH-1){1'b0}},a_exp_is_zero};
  //assign raw_b_exp       = b_i[EXPWIDTH+PRECISION-2:PRECISION-1] | {{(EXPWIDTH-1){1'b0}},b_exp_is_zero};
  assign raw_a_sig       = {!a_exp_is_zero,a_i[PRECISION-2:0]}                                         ;
  assign raw_b_sig       = {!b_exp_is_zero,b_i[PRECISION-2:0]}                                         ; 
  naivemultiplier #(
    .LEN(PRECISION)
  )
  U_naivemultiplier (
    .clk      (clk                   ),
    .rst_n    (rst_n                 ),
    .regenable(reg_en1               ),
    .a        (raw_a_sig             ),
    .b        (raw_b_sig             ),
    .result   (naivemultiplier_result)
  );

  //例化fmul_s2
  fmul_s2 #(
    .EXPWIDTH (EXPWIDTH ),
    .PRECISION(PRECISION)
  )
  U_fmul_s2 (
    .in_special_case_valid_i   (s1_out_special_case_valid_reg  ),  
    .in_special_case_nan_i     (s1_out_special_case_nan_reg    ),
    .in_special_case_inf_i     (s1_out_special_case_inf_reg    ),
    .in_special_case_inv_i     (s1_out_special_case_inv_reg    ),
    .in_special_case_haszero_i (s1_out_special_case_haszero_reg),
    .in_earyl_overflow_i       (s1_out_earyl_overflow_reg      ),
    .in_prod_sign_i            (s1_out_prod_sign_reg           ),
    .in_shift_amt_i            (s1_out_shift_amt_reg           ),
    .in_exp_shifted_i          (s1_out_exp_shifted_reg         ),
    .in_may_be_subnormal_i     (s1_out_may_be_subnormal_reg    ),
    .in_rm_i                   (s1_out_rm_reg                  ),
    .prod_i                    (naivemultiplier_result         ),
    .out_special_case_valid_o  (s2_out_special_case_valid      ),   
    .out_special_case_nan_o    (s2_out_special_case_nan        ),  
    .out_special_case_inf_o    (s2_out_special_case_inf        ),  
    .out_special_case_inv_o    (s2_out_special_case_inv        ),  
    .out_special_case_haszero_o(s2_out_special_case_haszero    ),  
    .out_earyl_overflow_o      (s2_out_earyl_overflow          ),  
    .out_prod_o                (s2_out_prod                    ),  
    .out_prod_sign_o           (s2_out_prod_sign               ),  
    .out_shift_amt_o           (s2_out_shift_amt               ),  
    .out_exp_shifted_o         (s2_out_exp_shifted             ),  
    .out_may_be_subnormal_o    (s2_out_may_be_subnormal        ),  
    .out_rm_o                  (s2_out_rm                      )
  );

  //寄存s2的输出
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      s2_out_special_case_valid_reg   <= 'd0;    
      s2_out_special_case_nan_reg     <= 'd0;
      s2_out_special_case_inf_reg     <= 'd0;
      s2_out_special_case_inv_reg     <= 'd0;
      s2_out_special_case_haszero_reg <= 'd0;
      s2_out_earyl_overflow_reg       <= 'd0; 
      s2_out_prod_reg                 <= 'd0;
      s2_out_prod_sign_reg            <= 'd0;
      s2_out_shift_amt_reg            <= 'd0;
      s2_out_exp_shifted_reg          <= 'd0;
      s2_out_may_be_subnormal_reg     <= 'd0;
      s2_out_rm_reg                   <= 'd0;
      ctrl_c_reg2                     <= 'd0;
      ctrl_rm_reg2                    <= 'd0;
      ctrl_reg_idxw_reg2              <= 'd0;
      ctrl_warpid_reg2                <= 'd0;
    end
    else if(reg_en2) begin
      s2_out_special_case_valid_reg   <= s2_out_special_case_valid  ;   
      s2_out_special_case_nan_reg     <= s2_out_special_case_nan    ;
      s2_out_special_case_inf_reg     <= s2_out_special_case_inf    ;
      s2_out_special_case_inv_reg     <= s2_out_special_case_inv    ;
      s2_out_special_case_haszero_reg <= s2_out_special_case_haszero;
      s2_out_earyl_overflow_reg       <= s2_out_earyl_overflow      ;
      s2_out_prod_reg                 <= s2_out_prod                ;
      s2_out_prod_sign_reg            <= s2_out_prod_sign           ;
      s2_out_shift_amt_reg            <= s2_out_shift_amt           ;
      s2_out_exp_shifted_reg          <= s2_out_exp_shifted         ;
      s2_out_may_be_subnormal_reg     <= s2_out_may_be_subnormal    ;
      s2_out_rm_reg                   <= s2_out_rm                  ;
      ctrl_c_reg2                     <= ctrl_c_reg1                ; 
      ctrl_rm_reg2                    <= ctrl_rm_reg1               ;
      ctrl_reg_idxw_reg2              <= ctrl_reg_idxw_reg1         ;
      ctrl_warpid_reg2                <= ctrl_warpid_reg1           ;
    end
    else begin
      s2_out_special_case_valid_reg   <= s2_out_special_case_valid_reg  ;  
      s2_out_special_case_nan_reg     <= s2_out_special_case_nan_reg    ;
      s2_out_special_case_inf_reg     <= s2_out_special_case_inf_reg    ;
      s2_out_special_case_inv_reg     <= s2_out_special_case_inv_reg    ;
      s2_out_special_case_haszero_reg <= s2_out_special_case_haszero_reg;
      s2_out_earyl_overflow_reg       <= s2_out_earyl_overflow_reg      ;
      s2_out_prod_reg                 <= s2_out_prod_reg                ;
      s2_out_prod_sign_reg            <= s2_out_prod_sign_reg           ;
      s2_out_shift_amt_reg            <= s2_out_shift_amt_reg           ;
      s2_out_exp_shifted_reg          <= s2_out_exp_shifted_reg         ;
      s2_out_may_be_subnormal_reg     <= s2_out_may_be_subnormal_reg    ;
      s2_out_rm_reg                   <= s2_out_rm_reg                  ;
      ctrl_c_reg2                     <= ctrl_c_reg2                    ;
      ctrl_rm_reg2                    <= ctrl_rm_reg2                   ;
      ctrl_reg_idxw_reg2              <= ctrl_reg_idxw_reg2             ;
      ctrl_warpid_reg2                <= ctrl_warpid_reg2               ;
    end
  end

  //例化fmul_s3
  fmul_s3 #(
    .EXPWIDTH (EXPWIDTH ),
    .PRECISION(PRECISION)
  )
  U_fmul_s3 (
    .in_special_case_valid_i  (s2_out_special_case_valid_reg  ),  
    .in_special_case_nan_i    (s2_out_special_case_nan_reg    ),
    .in_special_case_inf_i    (s2_out_special_case_inf_reg    ),
    .in_special_case_inv_i    (s2_out_special_case_inv_reg    ),
    .in_special_case_haszero_i(s2_out_special_case_haszero_reg),
    .in_earyl_overflow_i      (s2_out_earyl_overflow_reg      ),
    .in_prod_i                (s2_out_prod_reg                ),
    .in_prod_sign_i           (s2_out_prod_sign_reg           ),
    .in_shift_amt_i           (s2_out_shift_amt_reg           ),
    .in_exp_shifted_i         (s2_out_exp_shifted_reg         ),
    .in_may_be_subnormal_i    (s2_out_may_be_subnormal_reg    ),
    .in_rm_i                  (s2_out_rm_reg                  ),
    .result_o                 (result_o                       ),
    .fflags_o                 (fflags_o                       ),
    .to_fadd_fp_prod_sign_o   (s3_out_to_fadd_fp_prod_sign    ),                          
    .to_fadd_fp_prod_exp_o    (s3_out_to_fadd_fp_prod_exp     ),                          
    .to_fadd_fp_prod_sig_o    (s3_out_to_fadd_fp_prod_sig     ),                          
    .to_fadd_is_nan_o         (s3_out_to_fadd_is_nan          ),                          
    .to_fadd_is_inf_o         (s3_out_to_fadd_is_inf          ),                          
    .to_fadd_is_inv_o         (s3_out_to_fadd_is_inv          ),                          
    .to_fadd_overflow_o       (s3_out_to_fadd_overflow        )                          
  );

  assign  ctrl_c_o        = ctrl_c_reg2       ;
  assign  ctrl_rm_o       = ctrl_rm_reg2      ;
  assign  ctrl_reg_idxw_o = ctrl_reg_idxw_reg2;
  assign  ctrl_warpid_o   = ctrl_warpid_reg2  ;

endmodule
