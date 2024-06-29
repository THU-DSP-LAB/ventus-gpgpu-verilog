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
// Description:例化int_to_fp_prenorm和int_to_fp_postnorm并加两级寄存器
`include "define.v"
`define CTRLGEN
module int_to_fp #(
  parameter EXPWIDTH    = 8,
  parameter PRECISION   = 24,
  parameter SOFT_THREAD = 4
)(
  input                                     clk            ,
  input                                     rst_n          ,

  input   [2:0]                             op_i           ,
  input   [63:0]                            a_i            ,
  input   [2:0]                             rm_i           ,
`ifdef CTRLGEN
  input   [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] ctrl_regindex_i,
  input   [`DEPTH_WARP-1:0]                 ctrl_warpid_i  ,
  input   [SOFT_THREAD-1:0]                 ctrl_vecmask_i ,
  input                                     ctrl_wvd_i     ,
  input                                     ctrl_wxd_i     ,
`endif 
  input                                     in_valid_i     ,
  input                                     out_ready_i    ,

  output                                    in_ready_o     ,
  output                                    out_valid_o    ,
  
  output  [63:0]                            result_o       ,
  output  [4:0]                             fflags_o       
`ifdef CTRLGEN
                                                           ,
  output  [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] ctrl_regindex_o,
  output  [`DEPTH_WARP-1:0]                 ctrl_warpid_o  ,
  output  [SOFT_THREAD-1:0]                 ctrl_vecmask_o ,
  output                                    ctrl_wvd_o     ,
  output                                    ctrl_wxd_o     
`endif 
  );

  //for pipeline reg valid: latency = 2
  reg                          in_valid_reg1;
  reg                          in_valid_reg2;
  wire                         reg_en1      ;
  wire                         reg_en2      ;

  wire                         is_single     ;
  reg                          is_single_reg1;
  reg                          is_single_reg2;

  //prenorm input
  wire  [63:0]                 prenorm_int_in ;
  wire                         prenorm_sign_in;
  wire                         prenorm_long_in;
  
  //prenorm output
  wire  [62:0]                 prenorm_int_out    ;
  wire  [5:0]                  prenorm_lzc_out    ;
  wire                         prenorm_sign_out   ;
  wire                         prenorm_is_zero_out;

  //s1_reg
  reg   [62:0]                 prenorm_int_out_reg    ;
  reg   [5:0]                  prenorm_lzc_out_reg    ;
  reg                          prenorm_sign_out_reg   ;
  reg                          prenorm_is_zero_out_reg;
  reg   [2:0]                  rm_reg                 ;
`ifdef CTRLGEN
  reg   [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] ctrl_regindex_reg1     ;
  reg   [`DEPTH_WARP-1:0]                 ctrl_warpid_reg1       ;
  reg   [SOFT_THREAD-1:0]                 ctrl_vecmask_reg1      ;
  reg                                     ctrl_wvd_reg1          ;
  reg                                     ctrl_wxd_reg1          ;
`endif 

  //postnorm output
  wire  [EXPWIDTH+PRECISION-1:0]  postnorm_result_out    ;
  wire  [4:0]                     postnorm_fflags_out    ;

  //s1_reg
  reg   [EXPWIDTH+PRECISION-1:0]  postnorm_result_out_reg;
  reg   [4:0]                     postnorm_fflags_out_reg;
`ifdef CTRLGEN
  reg   [`REGIDX_WIDTH+`REGEXT_WIDTH-1:0] ctrl_regindex_reg2     ;
  reg   [`DEPTH_WARP-1:0]                 ctrl_warpid_reg2       ;
  reg   [SOFT_THREAD-1:0]                 ctrl_vecmask_reg2      ;
  reg                                     ctrl_wvd_reg2          ;
  reg                                     ctrl_wxd_reg2          ;
`endif 

  assign is_single = !op_i[2];

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

  //例化int_to_fp_prenorm
  assign prenorm_int_in  = is_single ? a_i : 'd0;
  assign prenorm_sign_in = op_i[0] && is_single   ;
  assign prenorm_long_in = op_i[1] && is_single   ;
 
  int_to_fp_prenorm U_int_to_fp_prenorm (
    .int_i     (prenorm_int_in     ),
    .sign_i    (prenorm_sign_in    ),
    .long_i    (prenorm_long_in    ),
    .norm_int_o(prenorm_int_out    ),
    .lzc_o     (prenorm_lzc_out    ),
    .is_zero_o (prenorm_is_zero_out),
    .sign_o    (prenorm_sign_out   )
    );

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      is_single_reg1          <= 'd0;
      prenorm_int_out_reg     <= 'd0;
      prenorm_lzc_out_reg     <= 'd0;
      prenorm_is_zero_out_reg <= 'd0;
      prenorm_sign_out_reg    <= 'd0;
      rm_reg                  <= 'd0;
      `ifdef CTRLGEN
      ctrl_regindex_reg1      <= 'd0;   
      ctrl_warpid_reg1        <= 'd0;
      ctrl_vecmask_reg1       <= 'd0;
      ctrl_wvd_reg1           <= 'd0;
      ctrl_wxd_reg1           <= 'd0;
      `endif 
    end
    else if(reg_en1) begin
      is_single_reg1          <= is_single          ;
      prenorm_int_out_reg     <= prenorm_int_out    ;
      prenorm_lzc_out_reg     <= prenorm_lzc_out    ;
      prenorm_is_zero_out_reg <= prenorm_is_zero_out;
      prenorm_sign_out_reg    <= prenorm_sign_out   ;
      rm_reg                  <= rm_i               ;
      `ifdef CTRLGEN
      ctrl_regindex_reg1      <= ctrl_regindex_i    ;   
      ctrl_warpid_reg1        <= ctrl_warpid_i      ;
      ctrl_vecmask_reg1       <= ctrl_vecmask_i     ;
      ctrl_wvd_reg1           <= ctrl_wvd_i         ;
      ctrl_wxd_reg1           <= ctrl_wxd_i         ;
      `endif 
    end
    else begin
      is_single_reg1          <= is_single_reg1         ;
      prenorm_int_out_reg     <= prenorm_int_out_reg    ;
      prenorm_lzc_out_reg     <= prenorm_lzc_out_reg    ;
      prenorm_is_zero_out_reg <= prenorm_is_zero_out_reg;
      prenorm_sign_out_reg    <= prenorm_sign_out_reg   ;
      rm_reg                  <= rm_reg                 ;
      `ifdef CTRLGEN
      ctrl_regindex_reg1      <= ctrl_regindex_reg1     ;   
      ctrl_warpid_reg1        <= ctrl_warpid_reg1       ;
      ctrl_vecmask_reg1       <= ctrl_vecmask_reg1      ;
      ctrl_wvd_reg1           <= ctrl_wvd_reg1          ;
      ctrl_wxd_reg1           <= ctrl_wxd_reg1          ;
      `endif 
    end
  end

  //例化int_to_fp_postnorm
  int_to_fp_postnorm U_int_to_fp_postnorm (
    .norm_int_i(prenorm_int_out_reg    ),
    .lzc_i     (prenorm_lzc_out_reg    ),
    .is_zero_i (prenorm_is_zero_out_reg),    
    .sign_i    (prenorm_sign_out_reg   ), 
    .rm_i      (rm_reg                 ),
    .result_o  (postnorm_result_out    ),
    .fflags_o  (postnorm_fflags_out    )
    );

  //将输出寄存一拍
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      `ifdef CTRLGEN
      ctrl_regindex_reg2      <= 'd0; 
      ctrl_warpid_reg2        <= 'd0;
      ctrl_vecmask_reg2       <= 'd0;
      ctrl_wvd_reg2           <= 'd0;
      ctrl_wxd_reg2           <= 'd0;
      `endif 
      postnorm_result_out_reg <= 'd0;
      postnorm_fflags_out_reg <= 'd0;
      is_single_reg2          <= 'd0;
    end
    else if(reg_en2) begin
      `ifdef CTRLGEN
      ctrl_regindex_reg2      <= ctrl_regindex_reg1 ;  
      ctrl_warpid_reg2        <= ctrl_warpid_reg1   ;
      ctrl_vecmask_reg2       <= ctrl_vecmask_reg1  ;
      ctrl_wvd_reg2           <= ctrl_wvd_reg1      ;
      ctrl_wxd_reg2           <= ctrl_wxd_reg1      ;
      `endif 
      postnorm_result_out_reg <= postnorm_result_out;
      postnorm_fflags_out_reg <= postnorm_fflags_out;
      is_single_reg2          <= is_single_reg1     ;
    end
    else begin
      `ifdef CTRLGEN
      ctrl_regindex_reg2      <= ctrl_regindex_reg2     ;
      ctrl_warpid_reg2        <= ctrl_warpid_reg2       ;
      ctrl_vecmask_reg2       <= ctrl_vecmask_reg2      ;
      ctrl_wvd_reg2           <= ctrl_wvd_reg2          ;
      ctrl_wxd_reg2           <= ctrl_wxd_reg2          ;
      `endif
      postnorm_result_out_reg <= postnorm_result_out_reg;
      postnorm_fflags_out_reg <= postnorm_fflags_out_reg;
      is_single_reg2          <= is_single_reg2         ;
    end
  end

  assign result_o = is_single_reg2 ? postnorm_result_out_reg : 'd0;
  assign fflags_o = is_single_reg2 ? postnorm_fflags_out_reg : 'd0;
  `ifdef CTRLGEN
  assign ctrl_regindex_o = ctrl_regindex_reg2;
  assign ctrl_warpid_o   = ctrl_warpid_reg2  ;
  assign ctrl_vecmask_o  = ctrl_vecmask_reg2 ;
  assign ctrl_wvd_o      = ctrl_wvd_reg2     ;
  assign ctrl_wxd_o      = ctrl_wxd_reg2     ;
  `endif 

endmodule




