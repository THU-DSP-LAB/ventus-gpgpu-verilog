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

module tc_add_pipe #(
  parameter EXPWIDTH  = 8,
  parameter PRECISION = 24,
  parameter LATENCY   = 2
)
(
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

  reg     [EXPWIDTH+PRECISION-1:0]      a_reg       ;
  reg     [EXPWIDTH+PRECISION-1:0]      b_reg       ;
  reg     [2:0]                         rm_reg      ;
  wire    [EXPWIDTH+2*PRECISION-1:0]    s1_in_a     ;
  wire    [EXPWIDTH+2*PRECISION-1:0]    s1_in_b     ;
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
  reg                          in_valid_reg1;
  reg                          in_valid_reg2;
  wire                         reg_en1      ;
  wire                         reg_en2      ;
  //s1 output
  wire [2:0]                   s1_out_rm                      ; 
  wire                         s1_out_far_sign                ; 
  wire [EXPWIDTH-1:0]          s1_out_far_exp                 ; 
  wire [PRECISION+2:0]         s1_out_far_sig                 ; 
  wire                         s1_out_near_sign               ; 
  wire [EXPWIDTH-1:0]          s1_out_near_exp                ; 
  wire [PRECISION+2:0]         s1_out_near_sig                ; 
  wire                         s1_out_special_case_valid      ; 
  wire                         s1_out_special_case_iv         ; 
  wire                         s1_out_special_case_nan        ; 
  wire                         s1_out_special_case_inf_sign   ; 
  wire                         s1_out_small_add               ; 
  wire                         s1_out_far_mul_of              ; 
  wire                         s1_out_near_sig_is_zero        ; 
  wire                         s1_out_sel_far_path            ;   
  //s1 output reg
  reg  [2:0]                   s1_out_rm_reg                      ; 
  reg                          s1_out_far_sign_reg                ; 
  reg  [EXPWIDTH-1:0]          s1_out_far_exp_reg                 ; 
  reg  [PRECISION+2:0]         s1_out_far_sig_reg                 ; 
  reg                          s1_out_near_sign_reg               ; 
  reg  [EXPWIDTH-1:0]          s1_out_near_exp_reg                ; 
  reg  [PRECISION+2:0]         s1_out_near_sig_reg                ; 
  reg                          s1_out_special_case_valid_reg      ; 
  reg                          s1_out_special_case_iv_reg         ; 
  reg                          s1_out_special_case_nan_reg        ; 
  //reg                          s1_out_special_case_inf_sign_reg   ; 
  //reg                          s1_out_small_add_reg               ; 
  reg                          s1_out_far_mul_of_reg              ; 
  reg                          s1_out_near_sig_is_zero_reg        ; 
  reg                          s1_out_sel_far_path_reg            ;
  //s2 output
  wire [EXPWIDTH+PRECISION-1:0]s2_out_result                  ;
  wire [4:0]                   s2_out_fflags                  ;

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

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      a_reg              <= 'd0;
      b_reg              <= 'd0;
      rm_reg             <= 'd0;
      ctrl_c_reg1        <= 'd0;
      ctrl_rm_reg1       <= 'd0;
      ctrl_reg_idxw_reg1 <= 'd0;
      ctrl_warpid_reg1   <= 'd0;
    end
    else if(reg_en1) begin
      a_reg              <= a_i            ;
      b_reg              <= b_i            ;
      rm_reg             <= rm_i           ;
      ctrl_c_reg1        <= ctrl_c_i       ;
      ctrl_rm_reg1       <= ctrl_rm_i      ;
      ctrl_reg_idxw_reg1 <= ctrl_reg_idxw_i;
      ctrl_warpid_reg1   <= ctrl_warpid_i  ;
    end
    else begin
      a_reg  <= a_reg                         ;
      b_reg  <= b_reg                         ;
      rm_reg <= rm_reg                        ;
      ctrl_c_reg1        <= ctrl_c_reg1       ;
      ctrl_rm_reg1       <= ctrl_rm_reg1      ;
      ctrl_reg_idxw_reg1 <= ctrl_reg_idxw_reg1;
      ctrl_warpid_reg1   <= ctrl_warpid_reg1  ;
    end
  end

  assign  s1_in_a = {a_reg,{PRECISION{1'b0}}};
  assign  s1_in_b = {b_reg,{PRECISION{1'b0}}};

  //例化fadd_s1
  fadd_s1 #(
    .EXPWIDTH  (EXPWIDTH  ),
    .PRECISION (2*PRECISION ),
    .OUTPC     (PRECISION )
  )
  U_fadd_s1 (
    .a_i                        (s1_in_a                     ),  
    .b_i                        (s1_in_b                     ), 
    .rm_i                       (rm_reg                      ),
    .b_inter_valid_i            (1'd0                        ),
    .b_inter_flags_is_nan_i     (1'd0                        ),
    .b_inter_flags_is_inf_i     (1'd0                        ),
    .b_inter_flags_is_inv_i     (1'd0                        ),
    .b_inter_flags_overflow_i   (1'd0                        ),
    .out_rm_o                   (s1_out_rm                   ),
    .out_far_sign_o             (s1_out_far_sign             ),
    .out_far_exp_o              (s1_out_far_exp              ),
    .out_far_sig_o              (s1_out_far_sig              ),
    .out_near_sign_o            (s1_out_near_sign            ),
    .out_near_exp_o             (s1_out_near_exp             ),
    .out_near_sig_o             (s1_out_near_sig             ),
    .out_special_case_valid_o   (s1_out_special_case_valid   ),
    .out_special_case_iv_o      (s1_out_special_case_iv      ),
    .out_special_case_nan_o     (s1_out_special_case_nan     ),
    .out_special_case_inf_sign_o(s1_out_special_case_inf_sign),
    .out_small_add_o            (s1_out_small_add            ),
    .out_far_mul_of_o           (s1_out_far_mul_of           ),
    .out_near_sig_is_zero_o     (s1_out_near_sig_is_zero     ),
    .out_sel_far_path_o         (s1_out_sel_far_path         )
  );  

  //寄存s1的输出
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      s1_out_rm_reg                    <= 'd0;   
      s1_out_far_sign_reg              <= 'd0;
      s1_out_far_exp_reg               <= 'd0;
      s1_out_far_sig_reg               <= 'd0;
      s1_out_near_sign_reg             <= 'd0;
      s1_out_near_exp_reg              <= 'd0;
      s1_out_near_sig_reg              <= 'd0;
      s1_out_special_case_valid_reg    <= 'd0;
      s1_out_special_case_iv_reg       <= 'd0;
      s1_out_special_case_nan_reg      <= 'd0;
      //s1_out_special_case_inf_sign_reg <= 'd0;
      //s1_out_small_add_reg             <= 'd0;
      s1_out_far_mul_of_reg            <= 'd0;
      s1_out_near_sig_is_zero_reg      <= 'd0;
      s1_out_sel_far_path_reg          <= 'd0;
      ctrl_c_reg2                      <= 'd0;
      ctrl_rm_reg2                     <= 'd0;
      ctrl_reg_idxw_reg2               <= 'd0;
      ctrl_warpid_reg2                 <= 'd0;
    end
    else if(reg_en2) begin
      s1_out_rm_reg                    <= s1_out_rm                   ;  
      s1_out_far_sign_reg              <= s1_out_far_sign             ;
      s1_out_far_exp_reg               <= s1_out_far_exp              ;
      s1_out_far_sig_reg               <= s1_out_far_sig              ;
      s1_out_near_sign_reg             <= s1_out_near_sign            ;
      s1_out_near_exp_reg              <= s1_out_near_exp             ;
      s1_out_near_sig_reg              <= s1_out_near_sig             ;
      s1_out_special_case_valid_reg    <= s1_out_special_case_valid   ;
      s1_out_special_case_iv_reg       <= s1_out_special_case_iv      ;
      s1_out_special_case_nan_reg      <= s1_out_special_case_nan     ;
      //s1_out_special_case_inf_sign_reg <= s1_out_special_case_inf_sign;
      //s1_out_small_add_reg             <= s1_out_small_add            ;
      s1_out_far_mul_of_reg            <= s1_out_far_mul_of           ;
      s1_out_near_sig_is_zero_reg      <= s1_out_near_sig_is_zero     ;
      s1_out_sel_far_path_reg          <= s1_out_sel_far_path         ;
      ctrl_c_reg2                      <= ctrl_c_reg1                 ;
      ctrl_rm_reg2                     <= ctrl_rm_reg1                ;
      ctrl_reg_idxw_reg2               <= ctrl_reg_idxw_reg1          ;
      ctrl_warpid_reg2                 <= ctrl_warpid_reg1            ;
    end
    else begin
      s1_out_rm_reg                    <= s1_out_rm_reg                   ;
      s1_out_far_sign_reg              <= s1_out_far_sign_reg             ;  
      s1_out_far_exp_reg               <= s1_out_far_exp_reg              ;
      s1_out_far_sig_reg               <= s1_out_far_sig_reg              ;
      s1_out_near_sign_reg             <= s1_out_near_sign_reg            ;
      s1_out_near_exp_reg              <= s1_out_near_exp_reg             ;
      s1_out_near_sig_reg              <= s1_out_near_sig_reg             ;
      s1_out_special_case_valid_reg    <= s1_out_special_case_valid_reg   ;
      s1_out_special_case_iv_reg       <= s1_out_special_case_iv_reg      ;
      s1_out_special_case_nan_reg      <= s1_out_special_case_nan_reg     ;
      //s1_out_special_case_inf_sign_reg <= s1_out_special_case_inf_sign_reg;
      //s1_out_small_add_reg             <= s1_out_small_add_reg            ;
      s1_out_far_mul_of_reg            <= s1_out_far_mul_of_reg           ;
      s1_out_near_sig_is_zero_reg      <= s1_out_near_sig_is_zero_reg     ;
      s1_out_sel_far_path_reg          <= s1_out_sel_far_path_reg         ;
      ctrl_c_reg2                      <= ctrl_c_reg2                     ;
      ctrl_rm_reg2                     <= ctrl_rm_reg2                    ;
      ctrl_reg_idxw_reg2               <= ctrl_reg_idxw_reg2              ;
      ctrl_warpid_reg2                 <= ctrl_warpid_reg2                ;
    end
  end

  //例化fadd_s2
  fadd_s2 #(
    .EXPWIDTH  (EXPWIDTH  ),
    .PRECISION (PRECISION )
  )
  U_fadd_s2 ( 
    .in_rm_i                   (s1_out_rm_reg                   ),                        
    .in_far_sign_i             (s1_out_far_sign_reg             ),
    .in_far_exp_i              (s1_out_far_exp_reg              ),
    .in_far_sig_i              (s1_out_far_sig_reg              ),
    .in_near_sign_i            (s1_out_near_sign_reg            ),
    .in_near_exp_i             (s1_out_near_exp_reg             ),
    .in_near_sig_i             (s1_out_near_sig_reg             ),
    .in_special_case_valid_i   (s1_out_special_case_valid_reg   ),
    .in_special_case_iv_i      (s1_out_special_case_iv_reg      ),
    .in_special_case_nan_i     (s1_out_special_case_nan_reg     ),
    //.in_special_case_inf_sign_i(s1_out_special_case_inf_sign_reg),
    //.in_small_add_i            (s1_out_small_add_reg            ),
    .in_far_mul_of_i           (s1_out_far_mul_of_reg           ),
    .in_near_sig_is_zero_i     (s1_out_near_sig_is_zero_reg     ),
    .in_sel_far_path_i         (s1_out_sel_far_path_reg         ),
    .out_result_o              (result_o                        ), 
    .out_fflags_o              (fflags_o                        )
  );

  assign  ctrl_c_o        = ctrl_c_reg2       ;
  assign  ctrl_rm_o       = ctrl_rm_reg2      ;
  assign  ctrl_reg_idxw_o = ctrl_reg_idxw_reg2;
  assign  ctrl_warpid_o   = ctrl_warpid_reg2  ;

endmodule
